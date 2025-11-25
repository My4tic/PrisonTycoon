## PrisonerManager - Zarządzanie więźniami
## Autoload singleton dostępny jako PrisonerManager
##
## Odpowiada za:
## - Tworzenie i usuwanie więźniów
## - Generowanie losowych więźniów
## - Przydzielanie cel i pracy
## - Statystyki więźniów
extends Node

# =============================================================================
# SCENA WIĘŹNIA
# =============================================================================
const PrisonerScene := preload("res://scenes/entities/prisoner.tscn")

# =============================================================================
# ZMIENNE
# =============================================================================
var prisoners: Dictionary = {}  # prisoner_id -> Prisoner node
var _next_prisoner_id: int = 1

# Kontener na więźniów w scenie
var _prisoners_container: Node2D = null

# Generator imion
const FIRST_NAMES: Array[String] = [
	"Jan", "Piotr", "Andrzej", "Krzysztof", "Tomasz", "Paweł", "Michał",
	"Marcin", "Grzegorz", "Józef", "Adam", "Stanisław", "Marek", "Łukasz",
	"Zbigniew", "Jerzy", "Tadeusz", "Wojciech", "Robert", "Mateusz",
	"Dariusz", "Mariusz", "Rafał", "Jacek", "Henryk", "Karol", "Stefan"
]

const LAST_NAMES: Array[String] = [
	"Nowak", "Kowalski", "Wiśniewski", "Wójcik", "Kowalczyk", "Kamiński",
	"Lewandowski", "Zieliński", "Szymański", "Woźniak", "Dąbrowski",
	"Kozłowski", "Jankowski", "Mazur", "Kwiatkowski", "Krawczyk",
	"Piotrowski", "Grabowski", "Nowakowski", "Pawłowski", "Michalski",
	"Nowicki", "Adamczyk", "Dudek", "Zając", "Wieczorek", "Jabłoński"
]


# =============================================================================
# INICJALIZACJA
# =============================================================================
func _ready() -> void:
	Signals.day_changed.connect(_on_day_changed)
	Signals.prisoner_died.connect(_on_prisoner_died)


func set_container(container: Node2D) -> void:
	_prisoners_container = container


# =============================================================================
# TWORZENIE WIĘŹNIÓW
# =============================================================================
func spawn_prisoner(data: Dictionary = {}) -> int:
	if _prisoners_container == null:
		push_error("PrisonerManager: Brak kontenera na więźniów!")
		return -1

	# Generuj dane jeśli nie podano
	if data.is_empty():
		data = generate_random_prisoner_data()

	# Przydziel ID
	var prisoner_id: int = _next_prisoner_id
	_next_prisoner_id += 1
	data["id"] = prisoner_id

	# Utwórz instancję
	var prisoner = PrisonerScene.instantiate()
	prisoner.initialize(data)

	# Znajdź pozycję startową (recepcja lub losowa)
	var spawn_pos: Vector2 = _get_spawn_position()
	prisoner.position = spawn_pos

	# Dodaj do sceny i słownika
	_prisoners_container.add_child(prisoner)
	prisoners[prisoner_id] = prisoner

	# Przydziel celę
	_auto_assign_cell(prisoner)

	# Aktualizuj EconomyManager
	EconomyManager.add_prisoner(prisoner.security_category)

	# Emituj sygnał
	Signals.prisoner_arrived.emit(prisoner_id, prisoner.security_category)

	# Powiadom więźnia o bieżącej aktywności harmonogramu
	# Używamy call_deferred aby dać czas na połączenie sygnałów w _ready()
	ScheduleManager.call_deferred("notify_entity_spawned", prisoner.security_category)

	return prisoner_id


func generate_random_prisoner_data() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# Losowe imię
	var first_name: String = FIRST_NAMES[rng.randi() % FIRST_NAMES.size()]
	var last_name: String = LAST_NAMES[rng.randi() % LAST_NAMES.size()]
	var full_name: String = first_name + " " + last_name

	# Losowy wiek (18-65)
	var age: int = rng.randi_range(18, 65)

	# Losowe przestępstwo
	var crime: Enums.CrimeType = rng.randi() % Enums.CrimeType.size() as Enums.CrimeType

	# Wyrok zależny od przestępstwa
	var sentence: int = _get_sentence_for_crime(crime, rng)

	# Kategoria bezpieczeństwa zależna od przestępstwa
	var category: Enums.SecurityCategory = _get_category_for_crime(crime)

	# Losowe cechy (1-3)
	var trait_count: int = rng.randi_range(1, 3)
	var available_traits: Array = Enums.PrisonerTrait.values().duplicate()
	var selected_traits: Array = []

	for i in range(trait_count):
		if available_traits.size() > 0:
			var idx: int = rng.randi() % available_traits.size()
			selected_traits.append(available_traits[idx])
			available_traits.remove_at(idx)

	return {
		"name": full_name,
		"age": age,
		"crime_type": crime,
		"sentence_days": sentence,
		"security_category": category,
		"traits": selected_traits
	}


func _get_sentence_for_crime(crime: Enums.CrimeType, rng: RandomNumberGenerator) -> int:
	match crime:
		Enums.CrimeType.THEFT:
			return rng.randi_range(30, 180)
		Enums.CrimeType.BURGLARY:
			return rng.randi_range(90, 365)
		Enums.CrimeType.FRAUD:
			return rng.randi_range(180, 730)
		Enums.CrimeType.DRUG_DEALING:
			return rng.randi_range(365, 1825)
		Enums.CrimeType.ASSAULT:
			return rng.randi_range(180, 1095)
		Enums.CrimeType.ARMED_ROBBERY:
			return rng.randi_range(730, 3650)
		Enums.CrimeType.MURDER:
			return rng.randi_range(3650, 9125)  # 10-25 lat
		Enums.CrimeType.SERIAL_MURDER:
			return rng.randi_range(9125, 18250)  # 25-50 lat
		Enums.CrimeType.TERRORISM:
			return rng.randi_range(7300, 18250)  # 20-50 lat
		_:
			return rng.randi_range(90, 365)


func _get_category_for_crime(crime: Enums.CrimeType) -> Enums.SecurityCategory:
	match crime:
		Enums.CrimeType.THEFT, Enums.CrimeType.FRAUD:
			return Enums.SecurityCategory.LOW
		Enums.CrimeType.BURGLARY, Enums.CrimeType.DRUG_DEALING:
			return Enums.SecurityCategory.MEDIUM
		Enums.CrimeType.ASSAULT, Enums.CrimeType.ARMED_ROBBERY:
			return Enums.SecurityCategory.HIGH
		Enums.CrimeType.MURDER, Enums.CrimeType.SERIAL_MURDER, \
		Enums.CrimeType.TERRORISM:
			return Enums.SecurityCategory.MAXIMUM
		_:
			return Enums.SecurityCategory.LOW


func _get_spawn_position() -> Vector2:
	# Znajdź recepcję
	var receptions := BuildingManager.get_buildings_by_type(Enums.BuildingType.RECEPTION)
	if receptions.size() > 0:
		var pos: Vector2i = receptions[0].position
		return GridManager.grid_to_world(pos)

	# Brak recepcji - spawn na środku mapy
	return Vector2(
		Constants.GRID_WIDTH * Constants.TILE_SIZE / 2.0,
		Constants.GRID_HEIGHT * Constants.TILE_SIZE / 2.0
	)


# =============================================================================
# PRZYDZIELANIE CEL
# =============================================================================
func _auto_assign_cell(prisoner) -> void:
	# Znajdź wolną celę odpowiednią dla kategorii
	var cell_types: Array = [
		Enums.BuildingType.CELL_SINGLE,
		Enums.BuildingType.CELL_DOUBLE,
		Enums.BuildingType.DORMITORY
	]

	for cell_type in cell_types:
		var cells := BuildingManager.get_buildings_by_type(cell_type)
		for cell in cells:
			var info: Dictionary = BuildingManager.get_building_info(cell.type)
			var capacity: int = info.get("capacity", 1)

			if cell.current_occupancy < capacity:
				assign_cell(prisoner.prisoner_id, cell.id)
				return


func assign_cell(prisoner_id: int, cell_id: int) -> bool:
	if not prisoners.has(prisoner_id):
		return false

	var prisoner = prisoners[prisoner_id]
	var cell = BuildingManager.get_building(cell_id)

	if cell == null:
		return false

	# Sprawdź pojemność
	var info: Dictionary = BuildingManager.get_building_info(cell.type)
	var capacity: int = info.get("capacity", 1)

	if cell.current_occupancy >= capacity:
		return false

	# Zwolnij poprzednią celę
	if prisoner.assigned_cell_id >= 0:
		var old_cell = BuildingManager.get_building(prisoner.assigned_cell_id)
		if old_cell:
			old_cell.current_occupancy -= 1

	# Przydziel nową
	prisoner.assigned_cell_id = cell_id
	cell.current_occupancy += 1

	Signals.prisoner_assigned_cell.emit(prisoner_id, cell_id)
	return true


# =============================================================================
# USUWANIE WIĘŹNIÓW
# =============================================================================
func remove_prisoner(prisoner_id: int, reason: String = "released") -> void:
	if not prisoners.has(prisoner_id):
		return

	var prisoner = prisoners[prisoner_id]

	# Zwolnij celę
	if prisoner.assigned_cell_id >= 0:
		var cell = BuildingManager.get_building(prisoner.assigned_cell_id)
		if cell:
			cell.current_occupancy -= 1

	# Aktualizuj EconomyManager
	EconomyManager.remove_prisoner(prisoner.security_category)

	# Emituj sygnał
	match reason:
		"released":
			Signals.prisoner_released.emit(prisoner_id)
		"escaped":
			Signals.prisoner_escaped.emit(prisoner_id)
		"died":
			pass  # Już emitowany przez Prisoner

	# Usuń z gry
	prisoners.erase(prisoner_id)
	prisoner.queue_free()


func release_prisoner(prisoner_id: int) -> void:
	remove_prisoner(prisoner_id, "released")


# =============================================================================
# GETTERY
# =============================================================================
func get_prisoner(prisoner_id: int):
	return prisoners.get(prisoner_id)


func get_all_prisoners() -> Array:
	return prisoners.values()


func get_prisoner_count() -> int:
	return prisoners.size()


func get_prisoners_by_category(category: Enums.SecurityCategory) -> Array:
	var result: Array = []
	for prisoner in prisoners.values():
		if prisoner.security_category == category:
			result.append(prisoner)
	return result


func get_prisoners_in_state(state: Enums.PrisonerState) -> Array:
	var result: Array = []
	for prisoner in prisoners.values():
		if prisoner.current_state == state:
			result.append(prisoner)
	return result


func get_prisoners_by_category_counts() -> Dictionary:
	var counts: Dictionary = {
		Enums.SecurityCategory.LOW: 0,
		Enums.SecurityCategory.MEDIUM: 0,
		Enums.SecurityCategory.HIGH: 0,
		Enums.SecurityCategory.MAXIMUM: 0
	}

	for prisoner in prisoners.values():
		counts[prisoner.security_category] += 1

	return counts


# =============================================================================
# STATYSTYKI
# =============================================================================
func get_average_mood() -> float:
	if prisoners.size() == 0:
		return 100.0

	var total: float = 0.0
	for prisoner in prisoners.values():
		total += prisoner.get_mood()

	return total / prisoners.size()


func get_average_need(need_type: Enums.PrisonerNeed) -> float:
	if prisoners.size() == 0:
		return 100.0

	var total: float = 0.0
	for prisoner in prisoners.values():
		total += prisoner.get_need(need_type)

	return total / prisoners.size()


func get_prisoners_with_critical_needs() -> Array:
	var result: Array = []
	for prisoner in prisoners.values():
		if prisoner.get_critical_needs().size() > 0:
			result.append(prisoner)
	return result


func get_high_risk_prisoners() -> Array:
	var result: Array = []
	for prisoner in prisoners.values():
		if prisoner.get_fight_risk() > 0.5 or prisoner.get_escape_risk() > 0.5:
			result.append(prisoner)
	return result


# =============================================================================
# EVENTY
# =============================================================================
func _on_day_changed(_day: int) -> void:
	# Aktualizuj dni wyroku
	for prisoner in prisoners.values():
		prisoner.days_served += 1

		# Sprawdź czy wyrok się skończył
		if prisoner.days_served >= prisoner.sentence_days:
			release_prisoner(prisoner.prisoner_id)


func _on_prisoner_died(prisoner_id: int, _cause: String) -> void:
	if prisoners.has(prisoner_id):
		remove_prisoner(prisoner_id, "died")


# =============================================================================
# SAVE/LOAD
# =============================================================================
func get_save_data() -> Dictionary:
	var prisoners_data: Array = []
	for prisoner in prisoners.values():
		prisoners_data.append(prisoner.get_save_data())

	return {
		"prisoners": prisoners_data,
		"next_id": _next_prisoner_id
	}


func load_save_data(data: Dictionary) -> void:
	# Wyczyść obecnych więźniów
	for prisoner in prisoners.values():
		prisoner.queue_free()
	prisoners.clear()

	_next_prisoner_id = data.get("next_id", 1)

	# Odtwórz więźniów
	for p_data in data.get("prisoners", []):
		if _prisoners_container:
			var prisoner = PrisonerScene.instantiate()
			prisoner.load_save_data(p_data)
			_prisoners_container.add_child(prisoner)
			prisoners[prisoner.prisoner_id] = prisoner
