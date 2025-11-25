## CampaignManager - System kampanii i celów
## Autoload singleton dostępny jako CampaignManager
##
## Odpowiada za:
## - Zarządzanie rozdziałami kampanii
## - Śledzenie celów (objectives)
## - System tutoriala
## - Progres gracza
extends Node

# =============================================================================
# KLASY DANYCH
# =============================================================================
class Objective:
	var id: int
	var type: Enums.ObjectiveType
	var description: String
	var target_value: int
	var current_value: int = 0
	var is_completed: bool = false
	var is_hidden: bool = false  # Ukryty dopóki nie spełniony warunek
	var building_type: int = -1  # Dla celów budowlanych
	var staff_type: int = -1     # Dla celów personalnych

	func _init(p_id: int, p_type: Enums.ObjectiveType, p_desc: String, p_target: int) -> void:
		id = p_id
		type = p_type
		description = p_desc
		target_value = p_target

	func update_progress(value: int) -> bool:
		var old_completed := is_completed
		current_value = value
		is_completed = current_value >= target_value
		return is_completed and not old_completed  # Zwróć true jeśli właśnie ukończono


class Chapter:
	var id: int
	var title: String
	var description: String
	var status: Enums.ChapterStatus = Enums.ChapterStatus.LOCKED
	var objectives: Array[Objective] = []
	var starting_capital: int = 30000
	var starting_prisoners: int = 0
	var starting_buildings: Array = []  # Array of {type, position}
	var starting_staff: Array = []      # Array of {type, shift}
	var unlock_categories: Array = []   # Dostępne kategorie więźniów
	var is_tutorial: bool = false
	var tutorial_steps: Array = []      # Array of {id, message, trigger}
	var time_limit_days: int = -1       # -1 = bez limitu
	var fail_conditions: Array = []     # Warunki przegranej


# =============================================================================
# ZMIENNE
# =============================================================================
var chapters: Array[Chapter] = []
var current_chapter: Chapter = null
var current_chapter_id: int = -1

# Śledzenie postępu
var completed_chapters: Array[int] = []
var chapter_progress: Dictionary = {}  # chapter_id -> {objectives_completed, time_spent, etc.}

# Aktywne cele
var active_objectives: Array[Objective] = []
var _objective_check_timer: float = 0.0
const OBJECTIVE_CHECK_INTERVAL: float = 1.0

# Tutorial
var current_tutorial_step: int = 0
var tutorial_active: bool = false

# Statystyki rozdziału
var chapter_start_day: int = 0
var chapter_escapes: int = 0
var chapter_deaths: int = 0


# =============================================================================
# FUNKCJE GODOT
# =============================================================================
func _ready() -> void:
	_load_campaign_data()
	_connect_signals()


func _process(delta: float) -> void:
	if current_chapter == null:
		return

	if not GameManager.is_playing() or GameManager.is_paused:
		return

	# Sprawdzaj postęp celów
	_objective_check_timer += delta
	if _objective_check_timer >= OBJECTIVE_CHECK_INTERVAL:
		_objective_check_timer = 0.0
		_check_objectives()
		_check_fail_conditions()


# =============================================================================
# ŁADOWANIE DANYCH KAMPANII
# =============================================================================
func _load_campaign_data() -> void:
	var file := FileAccess.open("res://data/campaign.json", FileAccess.READ)
	if file == null:
		push_warning("CampaignManager: Brak pliku campaign.json, tworzę domyślną kampanię")
		_create_default_campaign()
		return

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("CampaignManager: Błąd parsowania campaign.json: " + json.get_error_message())
		_create_default_campaign()
		return

	var data: Dictionary = json.data
	_parse_campaign_data(data)


func _parse_campaign_data(data: Dictionary) -> void:
	chapters.clear()

	var chapters_data: Array = data.get("chapters", [])
	for ch_data in chapters_data:
		var chapter := Chapter.new()
		chapter.id = ch_data.get("id", chapters.size())
		chapter.title = ch_data.get("title", "Rozdział %d" % chapter.id)
		chapter.description = ch_data.get("description", "")
		chapter.starting_capital = ch_data.get("starting_capital", 30000)
		chapter.starting_prisoners = ch_data.get("starting_prisoners", 0)
		chapter.starting_buildings = ch_data.get("starting_buildings", [])
		chapter.starting_staff = ch_data.get("starting_staff", [])
		chapter.unlock_categories = ch_data.get("unlock_categories", [0, 1, 2, 3])
		chapter.is_tutorial = ch_data.get("is_tutorial", false)
		chapter.tutorial_steps = ch_data.get("tutorial_steps", [])
		chapter.time_limit_days = ch_data.get("time_limit_days", -1)
		chapter.fail_conditions = ch_data.get("fail_conditions", [])

		# Parsuj cele
		var objectives_data: Array = ch_data.get("objectives", [])
		for obj_data in objectives_data:
			var obj_type: int = obj_data.get("type", 0)
			var obj := Objective.new(
				obj_data.get("id", chapter.objectives.size()),
				obj_type as Enums.ObjectiveType,
				obj_data.get("description", ""),
				obj_data.get("target", 1)
			)
			obj.is_hidden = obj_data.get("hidden", false)
			obj.building_type = obj_data.get("building_type", -1)
			obj.staff_type = obj_data.get("staff_type", -1)
			chapter.objectives.append(obj)

		# Pierwszy rozdział dostępny od razu
		if chapter.id == 0:
			chapter.status = Enums.ChapterStatus.AVAILABLE

		chapters.append(chapter)


func _create_default_campaign() -> void:
	# Twórz domyślną kampanię jeśli brak pliku JSON
	chapters.clear()

	# Rozdział 1: Tutorial - Podstawy
	var ch1 := Chapter.new()
	ch1.id = 0
	ch1.title = "Nowy Początek"
	ch1.description = "Zbuduj swoje pierwsze więzienie. Naucz się podstaw zarządzania."
	ch1.starting_capital = 50000
	ch1.is_tutorial = true
	ch1.status = Enums.ChapterStatus.AVAILABLE
	ch1.unlock_categories = [Enums.SecurityCategory.LOW]

	var obj1 := Objective.new(0, Enums.ObjectiveType.BUILD_BUILDING, "Zbuduj Recepcję", 1)
	obj1.building_type = Enums.BuildingType.RECEPTION
	ch1.objectives.append(obj1)

	var obj2 := Objective.new(1, Enums.ObjectiveType.BUILD_BUILDING_COUNT, "Zbuduj 4 cele pojedyncze", 4)
	obj2.building_type = Enums.BuildingType.CELL_SINGLE
	ch1.objectives.append(obj2)

	var obj3 := Objective.new(2, Enums.ObjectiveType.HIRE_STAFF, "Zatrudnij 2 strażników", 2)
	obj3.staff_type = Enums.StaffType.GUARD
	ch1.objectives.append(obj3)

	var obj4 := Objective.new(3, Enums.ObjectiveType.REACH_PRISONER_COUNT, "Przyjmij 4 więźniów", 4)
	ch1.objectives.append(obj4)

	ch1.tutorial_steps = [
		{"id": "welcome", "message": "Witaj w Prison Tycoon! Zbudujmy twoje pierwsze więzienie."},
		{"id": "build_reception", "message": "Najpierw zbuduj Recepcję - tu będą przybywać więźniowie."},
		{"id": "build_cells", "message": "Teraz zbuduj cele dla więźniów."},
		{"id": "hire_guards", "message": "Zatrudnij strażników do pilnowania porządku."},
		{"id": "accept_prisoners", "message": "Możesz teraz przyjąć pierwszych więźniów!"}
	]
	chapters.append(ch1)

	# Rozdział 2: Wyżywienie
	var ch2 := Chapter.new()
	ch2.id = 1
	ch2.title = "Głodne Żołądki"
	ch2.description = "Więźniowie potrzebują jedzenia. Zbuduj kuchnię i kantynę."
	ch2.starting_capital = 40000
	ch2.starting_prisoners = 4
	ch2.unlock_categories = [Enums.SecurityCategory.LOW, Enums.SecurityCategory.MEDIUM]

	var obj2_1 := Objective.new(0, Enums.ObjectiveType.BUILD_BUILDING, "Zbuduj Kuchnię", 1)
	obj2_1.building_type = Enums.BuildingType.KITCHEN
	ch2.objectives.append(obj2_1)

	var obj2_2 := Objective.new(1, Enums.ObjectiveType.BUILD_BUILDING, "Zbuduj Kantynę", 1)
	obj2_2.building_type = Enums.BuildingType.CANTEEN
	ch2.objectives.append(obj2_2)

	var obj2_3 := Objective.new(2, Enums.ObjectiveType.HIRE_STAFF, "Zatrudnij kucharza", 1)
	obj2_3.staff_type = Enums.StaffType.COOK
	ch2.objectives.append(obj2_3)

	var obj2_4 := Objective.new(3, Enums.ObjectiveType.REACH_PRISONER_COUNT, "Miej 10 więźniów", 10)
	ch2.objectives.append(obj2_4)

	var obj2_5 := Objective.new(4, Enums.ObjectiveType.SURVIVE_DAYS, "Przetrwaj 7 dni", 7)
	ch2.objectives.append(obj2_5)

	chapters.append(ch2)

	# Rozdział 3: Bezpieczeństwo
	var ch3 := Chapter.new()
	ch3.id = 2
	ch3.title = "Utrzymać Porządek"
	ch3.description = "Więźniowie zaczynają sprawiać problemy. Zadbaj o bezpieczeństwo."
	ch3.starting_capital = 35000
	ch3.starting_prisoners = 10
	ch3.unlock_categories = [Enums.SecurityCategory.LOW, Enums.SecurityCategory.MEDIUM, Enums.SecurityCategory.HIGH]

	var obj3_1 := Objective.new(0, Enums.ObjectiveType.BUILD_BUILDING, "Zbuduj Posterunek Strażników", 1)
	obj3_1.building_type = Enums.BuildingType.GUARD_ROOM
	ch3.objectives.append(obj3_1)

	var obj3_2 := Objective.new(1, Enums.ObjectiveType.HIRE_STAFF, "Zatrudnij 4 strażników", 4)
	obj3_2.staff_type = Enums.StaffType.GUARD
	ch3.objectives.append(obj3_2)

	var obj3_3 := Objective.new(2, Enums.ObjectiveType.BUILD_BUILDING, "Zbuduj Izolatkę", 1)
	obj3_3.building_type = Enums.BuildingType.SOLITARY
	ch3.objectives.append(obj3_3)

	var obj3_4 := Objective.new(3, Enums.ObjectiveType.NO_ESCAPES, "Zero ucieczek przez 14 dni", 14)
	ch3.objectives.append(obj3_4)

	var obj3_5 := Objective.new(4, Enums.ObjectiveType.REACH_PRISONER_COUNT, "Miej 20 więźniów", 20)
	ch3.objectives.append(obj3_5)

	chapters.append(ch3)

	# Rozdział 4: Rekreacja i Praca
	var ch4 := Chapter.new()
	ch4.id = 3
	ch4.title = "Zajęci Więźniowie"
	ch4.description = "Szczęśliwi więźniowie to spokojni więźniowie. Daj im zajęcie."
	ch4.starting_capital = 45000
	ch4.starting_prisoners = 20
	ch4.unlock_categories = [0, 1, 2, 3]  # Wszystkie kategorie

	var obj4_1 := Objective.new(0, Enums.ObjectiveType.BUILD_BUILDING, "Zbuduj Podwórko", 1)
	obj4_1.building_type = Enums.BuildingType.YARD
	ch4.objectives.append(obj4_1)

	var obj4_2 := Objective.new(1, Enums.ObjectiveType.BUILD_BUILDING, "Zbuduj Warsztat", 1)
	obj4_2.building_type = Enums.BuildingType.WORKSHOP_CARPENTRY
	ch4.objectives.append(obj4_2)

	var obj4_3 := Objective.new(2, Enums.ObjectiveType.PRISONER_MOOD_ABOVE, "Średni nastrój > 60%", 60)
	ch4.objectives.append(obj4_3)

	var obj4_4 := Objective.new(3, Enums.ObjectiveType.DAILY_PROFIT, "Dzienny zysk > $500", 500)
	ch4.objectives.append(obj4_4)

	var obj4_5 := Objective.new(4, Enums.ObjectiveType.REACH_PRISONER_COUNT, "Miej 30 więźniów", 30)
	ch4.objectives.append(obj4_5)

	chapters.append(ch4)

	# Rozdział 5: Prawdziwe Wyzwanie
	var ch5 := Chapter.new()
	ch5.id = 4
	ch5.title = "Pełna Skala"
	ch5.description = "Prowadź pełnoprawne więzienie z więźniami wszystkich kategorii."
	ch5.starting_capital = 60000
	ch5.starting_prisoners = 30
	ch5.unlock_categories = [0, 1, 2, 3]

	var obj5_1 := Objective.new(0, Enums.ObjectiveType.REACH_PRISONER_COUNT, "Miej 50 więźniów", 50)
	ch5.objectives.append(obj5_1)

	var obj5_2 := Objective.new(1, Enums.ObjectiveType.REACH_CAPITAL, "Zgromadź $100,000", 100000)
	ch5.objectives.append(obj5_2)

	var obj5_3 := Objective.new(2, Enums.ObjectiveType.PRISONER_MOOD_ABOVE, "Średni nastrój > 50%", 50)
	ch5.objectives.append(obj5_3)

	var obj5_4 := Objective.new(3, Enums.ObjectiveType.NO_DEATHS, "Zero śmierci przez 30 dni", 30)
	ch5.objectives.append(obj5_4)

	var obj5_5 := Objective.new(4, Enums.ObjectiveType.SURVIVE_DAYS, "Przetrwaj 60 dni", 60)
	ch5.objectives.append(obj5_5)

	ch5.fail_conditions = [
		{"type": "bankruptcy", "message": "Zbankrutowałeś!"},
		{"type": "escapes", "count": 5, "message": "Zbyt wiele ucieczek!"}
	]

	chapters.append(ch5)


# =============================================================================
# PODŁĄCZANIE SYGNAŁÓW
# =============================================================================
func _connect_signals() -> void:
	Signals.building_placed.connect(_on_building_placed)
	Signals.staff_hired.connect(_on_staff_hired)
	Signals.prisoner_arrived.connect(_on_prisoner_arrived)
	Signals.prisoner_escaped.connect(_on_prisoner_escaped)
	Signals.prisoner_died.connect(_on_prisoner_died)
	Signals.day_changed.connect(_on_day_changed)
	Signals.capital_changed.connect(_on_capital_changed)


# =============================================================================
# ZARZĄDZANIE ROZDZIAŁAMI
# =============================================================================
func start_chapter(chapter_id: int) -> bool:
	if chapter_id < 0 or chapter_id >= chapters.size():
		push_error("CampaignManager: Nieprawidłowy ID rozdziału: %d" % chapter_id)
		return false

	var chapter := chapters[chapter_id]

	if chapter.status == Enums.ChapterStatus.LOCKED:
		push_error("CampaignManager: Rozdział %d jest zablokowany" % chapter_id)
		return false

	current_chapter = chapter
	current_chapter_id = chapter_id
	chapter.status = Enums.ChapterStatus.IN_PROGRESS

	# Reset statystyk
	chapter_start_day = 0
	chapter_escapes = 0
	chapter_deaths = 0

	# Kopiuj cele do aktywnych
	active_objectives.clear()
	for obj in chapter.objectives:
		obj.current_value = 0
		obj.is_completed = false
		active_objectives.append(obj)

	# Ustaw początkowy stan gry
	_setup_chapter_initial_state()

	# Rozpocznij tutorial jeśli jest
	if chapter.is_tutorial and chapter.tutorial_steps.size() > 0:
		tutorial_active = true
		current_tutorial_step = 0
		_show_tutorial_step(0)

	Signals.chapter_started.emit(chapter_id)
	return true


func _setup_chapter_initial_state() -> void:
	if current_chapter == null:
		return

	# Ustaw kapitał
	EconomyManager.set_capital(current_chapter.starting_capital)

	# Zbuduj początkowe budynki
	for building_data in current_chapter.starting_buildings:
		var building_type: int = building_data.get("type", 0)
		var pos_arr: Array = building_data.get("position", [50, 50])
		var position := Vector2i(pos_arr[0], pos_arr[1])
		BuildingManager.place_building(building_type as Enums.BuildingType, position)

	# Zatrudnij początkowy personel
	for staff_data in current_chapter.starting_staff:
		var staff_type: int = staff_data.get("type", 0)
		var shift: int = staff_data.get("shift", 0)
		StaffManager.hire_staff(staff_type as Enums.StaffType, shift as Enums.Shift)

	# Spawn więźniów
	for _i in range(current_chapter.starting_prisoners):
		PrisonerManager.spawn_prisoner()

	# Uruchom grę
	GameManager.start_new_game(Enums.GameMode.CAMPAIGN)


func complete_chapter() -> void:
	if current_chapter == null:
		return

	current_chapter.status = Enums.ChapterStatus.COMPLETED

	if current_chapter_id not in completed_chapters:
		completed_chapters.append(current_chapter_id)

	# Odblokuj następny rozdział
	var next_id := current_chapter_id + 1
	if next_id < chapters.size():
		chapters[next_id].status = Enums.ChapterStatus.AVAILABLE

	# Zapisz postęp
	chapter_progress[current_chapter_id] = {
		"days": GameManager.current_day - chapter_start_day,
		"escapes": chapter_escapes,
		"deaths": chapter_deaths
	}

	Signals.chapter_completed.emit(current_chapter_id)


func fail_chapter(reason: String) -> void:
	if current_chapter == null:
		return

	Signals.chapter_failed.emit(current_chapter_id, reason)
	GameManager.end_game(false)


# =============================================================================
# SPRAWDZANIE CELÓW
# =============================================================================
func _check_objectives() -> void:
	if current_chapter == null:
		return

	var all_completed := true

	for obj in active_objectives:
		if obj.is_completed:
			continue

		all_completed = false
		var new_value := _get_objective_current_value(obj)

		if obj.update_progress(new_value):
			Signals.objective_completed.emit(obj.id)
		elif new_value != obj.current_value:
			Signals.objective_progress_updated.emit(obj.id, new_value, obj.target_value)

	if all_completed:
		Signals.all_objectives_completed.emit()
		complete_chapter()


func _get_objective_current_value(obj: Objective) -> int:
	match obj.type:
		Enums.ObjectiveType.REACH_PRISONER_COUNT:
			return PrisonerManager.get_prisoner_count()

		Enums.ObjectiveType.REACH_CAPITAL:
			return EconomyManager.capital

		Enums.ObjectiveType.BUILD_BUILDING:
			if obj.building_type >= 0:
				return BuildingManager.get_buildings_by_type(obj.building_type as Enums.BuildingType).size()
			return 0

		Enums.ObjectiveType.BUILD_BUILDING_COUNT:
			if obj.building_type >= 0:
				return BuildingManager.get_buildings_by_type(obj.building_type as Enums.BuildingType).size()
			return 0

		Enums.ObjectiveType.SURVIVE_DAYS:
			return GameManager.current_day - chapter_start_day

		Enums.ObjectiveType.NO_ESCAPES:
			# Zwróć liczbę dni BEZ ucieczek
			if chapter_escapes == 0:
				return GameManager.current_day - chapter_start_day
			return 0

		Enums.ObjectiveType.NO_DEATHS:
			if chapter_deaths == 0:
				return GameManager.current_day - chapter_start_day
			return 0

		Enums.ObjectiveType.PRISONER_MOOD_ABOVE:
			return int(PrisonerManager.get_average_mood())

		Enums.ObjectiveType.HIRE_STAFF:
			if obj.staff_type >= 0:
				return StaffManager.get_staff_type_count(obj.staff_type as Enums.StaffType)
			return StaffManager.get_staff_count()

		Enums.ObjectiveType.DAILY_PROFIT:
			return EconomyManager.get_daily_balance()

		_:
			return 0


func _check_fail_conditions() -> void:
	if current_chapter == null:
		return

	for condition in current_chapter.fail_conditions:
		var cond_type: String = condition.get("type", "")

		match cond_type:
			"bankruptcy":
				if EconomyManager.is_bankrupt():
					fail_chapter(condition.get("message", "Bankructwo!"))

			"escapes":
				var max_escapes: int = condition.get("count", 10)
				if chapter_escapes >= max_escapes:
					fail_chapter(condition.get("message", "Zbyt wiele ucieczek!"))

			"deaths":
				var max_deaths: int = condition.get("count", 5)
				if chapter_deaths >= max_deaths:
					fail_chapter(condition.get("message", "Zbyt wiele śmierci!"))

			"time_limit":
				var limit: int = condition.get("days", 30)
				if GameManager.current_day - chapter_start_day > limit:
					fail_chapter(condition.get("message", "Czas minął!"))


# =============================================================================
# TUTORIAL
# =============================================================================
func _show_tutorial_step(step_index: int) -> void:
	if current_chapter == null or not current_chapter.is_tutorial:
		return

	if step_index >= current_chapter.tutorial_steps.size():
		tutorial_active = false
		return

	var step: Dictionary = current_chapter.tutorial_steps[step_index]
	var message_id: String = step.get("id", "")
	var message: String = step.get("message", "")

	# Emituj sygnał do wyświetlenia komunikatu
	Signals.tutorial_message_shown.emit(message_id)

	# TODO: Wyświetl komunikat w UI


func advance_tutorial() -> void:
	if not tutorial_active:
		return

	var step_id: String = ""
	if current_tutorial_step < current_chapter.tutorial_steps.size():
		step_id = current_chapter.tutorial_steps[current_tutorial_step].get("id", "")

	current_tutorial_step += 1
	Signals.tutorial_step_completed.emit(step_id)

	if current_tutorial_step < current_chapter.tutorial_steps.size():
		_show_tutorial_step(current_tutorial_step)
	else:
		tutorial_active = false


# =============================================================================
# OBSŁUGA SYGNAŁÓW
# =============================================================================
func _on_building_placed(_building_type: int, _position: Vector2i, _size: Vector2i) -> void:
	# Sprawdź cele budowlane natychmiast
	_check_objectives()

	# Sprawdź tutorial
	if tutorial_active and current_chapter:
		var step := current_chapter.tutorial_steps[current_tutorial_step] if current_tutorial_step < current_chapter.tutorial_steps.size() else {}
		var trigger: String = step.get("trigger", "")
		if trigger == "build_" + str(_building_type):
			advance_tutorial()


func _on_staff_hired(_staff_id: int, _staff_type: int) -> void:
	_check_objectives()


func _on_prisoner_arrived(_prisoner_id: int, _category: int) -> void:
	_check_objectives()


func _on_prisoner_escaped(_prisoner_id: int) -> void:
	chapter_escapes += 1
	_check_objectives()


func _on_prisoner_died(_prisoner_id: int, _cause: String) -> void:
	chapter_deaths += 1
	_check_objectives()


func _on_day_changed(_day: int) -> void:
	if chapter_start_day == 0:
		chapter_start_day = _day
	_check_objectives()


func _on_capital_changed(_old: int, _new: int) -> void:
	_check_objectives()


# =============================================================================
# API PUBLICZNE
# =============================================================================
func get_chapter(chapter_id: int) -> Chapter:
	if chapter_id >= 0 and chapter_id < chapters.size():
		return chapters[chapter_id]
	return null


func get_all_chapters() -> Array[Chapter]:
	return chapters


func get_active_objectives() -> Array[Objective]:
	return active_objectives


func get_chapter_count() -> int:
	return chapters.size()


func get_completed_chapter_count() -> int:
	return completed_chapters.size()


func is_chapter_available(chapter_id: int) -> bool:
	var chapter := get_chapter(chapter_id)
	if chapter:
		return chapter.status != Enums.ChapterStatus.LOCKED
	return false


func is_in_campaign() -> bool:
	return current_chapter != null


# =============================================================================
# SAVE/LOAD
# =============================================================================
func get_save_data() -> Dictionary:
	return {
		"completed_chapters": completed_chapters.duplicate(),
		"chapter_progress": chapter_progress.duplicate(true),
		"current_chapter_id": current_chapter_id
	}


func load_save_data(data: Dictionary) -> void:
	completed_chapters = data.get("completed_chapters", [])
	chapter_progress = data.get("chapter_progress", {})

	# Aktualizuj statusy rozdziałów
	for chapter in chapters:
		if chapter.id in completed_chapters:
			chapter.status = Enums.ChapterStatus.COMPLETED
		elif chapter.id == 0 or (chapter.id - 1) in completed_chapters:
			chapter.status = Enums.ChapterStatus.AVAILABLE
		else:
			chapter.status = Enums.ChapterStatus.LOCKED
