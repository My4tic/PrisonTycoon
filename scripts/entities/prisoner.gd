## Prisoner - Klasa więźnia
## CharacterBody2D z systemem potrzeb, AI i nawigacją
class_name Prisoner
extends CharacterBody2D

# =============================================================================
# SYGNAŁY
# =============================================================================
signal need_changed(need_type: Enums.PrisonerNeed, old_value: float, new_value: float)
signal state_changed(old_state: Enums.PrisonerState, new_state: Enums.PrisonerState)
signal died(cause: String)

# =============================================================================
# IDENTYFIKACJA
# =============================================================================
@export var prisoner_id: int = -1
@export var prisoner_name: String = "Więzień"
@export var age: int = 30
@export var crime_type: Enums.CrimeType = Enums.CrimeType.THEFT
@export var sentence_days: int = 365
@export var days_served: int = 0
@export var security_category: Enums.SecurityCategory = Enums.SecurityCategory.LOW

# =============================================================================
# CECHY (TRAITS)
# =============================================================================
var traits: Array[Enums.PrisonerTrait] = []

# =============================================================================
# POTRZEBY (0-100, 100 = pełne zaspokojenie)
# =============================================================================
var needs: Dictionary = {
	Enums.PrisonerNeed.HUNGER: 100.0,
	Enums.PrisonerNeed.SLEEP: 100.0,
	Enums.PrisonerNeed.HYGIENE: 100.0,
	Enums.PrisonerNeed.FREEDOM: 100.0,
	Enums.PrisonerNeed.SAFETY: 100.0,
	Enums.PrisonerNeed.ENTERTAINMENT: 100.0
}

# Szybkość degradacji potrzeb (per godzinę in-game)
const NEED_DECAY_RATES: Dictionary = {
	Enums.PrisonerNeed.HUNGER: 4.0,      # ~25 godzin do zera
	Enums.PrisonerNeed.SLEEP: 2.5,       # ~40 godzin do zera
	Enums.PrisonerNeed.HYGIENE: 2.0,     # ~50 godzin do zera
	Enums.PrisonerNeed.FREEDOM: 1.5,     # ~66 godzin do zera
	Enums.PrisonerNeed.SAFETY: 1.0,      # ~100 godzin do zera
	Enums.PrisonerNeed.ENTERTAINMENT: 3.0 # ~33 godzin do zera
}

# Progi ostrzeżeń
const NEED_WARNING_THRESHOLD: float = 30.0
const NEED_CRITICAL_THRESHOLD: float = 10.0

# =============================================================================
# STAN I ZDROWIE
# =============================================================================
var current_state: Enums.PrisonerState = Enums.PrisonerState.IDLE
var health: float = 100.0
var mood: float = 50.0  # 0-100, obliczane z potrzeb

# Przypisania
var assigned_cell_id: int = -1
var assigned_work_id: int = -1

# =============================================================================
# NAWIGACJA
# =============================================================================
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
var target_position: Vector2 = Vector2.ZERO
var current_target_building_id: int = -1
var move_speed: float = 100.0  # pikseli/sekundę

# =============================================================================
# WIZUALIZACJA
# =============================================================================
@onready var sprite: Sprite2D = $Sprite2D

# Mapowanie kategorii na pliki sprite'ów
const CATEGORY_SPRITES: Dictionary = {
	Enums.SecurityCategory.LOW: "res://assets/sprites/characters/prisoner_low.png",
	Enums.SecurityCategory.MEDIUM: "res://assets/sprites/characters/prisoner_medium.png",
	Enums.SecurityCategory.HIGH: "res://assets/sprites/characters/prisoner_high.png",
	Enums.SecurityCategory.MAXIMUM: "res://assets/sprites/characters/prisoner_max.png"
}

# =============================================================================
# TIMERY
# =============================================================================
var _need_update_timer: float = 0.0
const NEED_UPDATE_INTERVAL: float = 1.0  # Aktualizuj potrzeby co sekundę


# =============================================================================
# FUNKCJE GODOT
# =============================================================================
func _ready() -> void:
	_setup_visuals()
	_connect_signals()
	add_to_group("prisoners")


func _physics_process(delta: float) -> void:
	# Aktualizuj potrzeby
	_need_update_timer += delta
	if _need_update_timer >= NEED_UPDATE_INTERVAL:
		_update_needs(_need_update_timer)
		_need_update_timer = 0.0

	# Ruch do celu
	if current_state == Enums.PrisonerState.WALKING:
		_process_movement(delta)

	# AI decision making
	_process_ai(delta)


# =============================================================================
# INICJALIZACJA
# =============================================================================
func initialize(data: Dictionary) -> void:
	prisoner_id = data.get("id", -1)
	prisoner_name = data.get("name", "Więzień")
	age = data.get("age", 30)
	crime_type = data.get("crime_type", Enums.CrimeType.THEFT)
	sentence_days = data.get("sentence_days", 365)
	security_category = data.get("security_category", Enums.SecurityCategory.LOW)

	# Traits
	var trait_array: Array = data.get("traits", [])
	traits.clear()
	for t in trait_array:
		traits.append(t as Enums.PrisonerTrait)

	_setup_visuals()
	_calculate_mood()


func _setup_visuals() -> void:
	# Załaduj odpowiedni sprite dla kategorii bezpieczeństwa
	if sprite:
		var sprite_path: String = str(CATEGORY_SPRITES.get(security_category, "res://assets/sprites/characters/prisoner.png"))
		var texture: Texture2D = load(sprite_path)
		if texture:
			sprite.texture = texture

	# Z-index dla renderowania nad terenem
	z_index = 20


func _connect_signals() -> void:
	Signals.hour_changed.connect(_on_hour_changed)
	Signals.schedule_activity_started.connect(_on_schedule_activity_started)
	Signals.lockdown_started.connect(_on_lockdown_started)
	Signals.lockdown_ended.connect(_on_lockdown_ended)


# =============================================================================
# SYSTEM POTRZEB
# =============================================================================
func _update_needs(delta_time: float) -> void:
	# Przelicz delta na godziny in-game
	# 1 sekunda real = 1 minuta in-game przy x1
	var game_hours: float = delta_time / 60.0 * GameManager.get_current_speed()

	for need_type in needs.keys():
		var old_value: float = needs[need_type]
		var decay_rate: float = NEED_DECAY_RATES.get(need_type, 1.0)

		# Modyfikatory z cech
		decay_rate *= _get_need_decay_modifier(need_type)

		# Modyfikatory ze stanu
		decay_rate *= _get_state_decay_modifier(need_type)

		# Aplikuj degradację
		var new_value: float = maxf(0.0, old_value - decay_rate * game_hours)

		if new_value != old_value:
			needs[need_type] = new_value
			need_changed.emit(need_type, old_value, new_value)

			# Sprawdź progi
			_check_need_thresholds(need_type, old_value, new_value)

	# Przelicz nastrój
	_calculate_mood()


func _get_need_decay_modifier(need_type: Enums.PrisonerNeed) -> float:
	var modifier: float = 1.0

	# Cechy wpływające na potrzeby
	if need_type == Enums.PrisonerNeed.FREEDOM:
		if Enums.PrisonerTrait.ESCAPIST in traits:
			modifier *= 1.5  # Szybciej traci wolność

	if need_type == Enums.PrisonerNeed.ENTERTAINMENT:
		if Enums.PrisonerTrait.INTELLIGENT in traits:
			modifier *= 1.3  # Szybciej się nudzi

	return modifier


func _get_state_decay_modifier(need_type: Enums.PrisonerNeed) -> float:
	# Podczas snu - wolniejsza degradacja głodu
	if current_state == Enums.PrisonerState.SLEEPING:
		if need_type == Enums.PrisonerNeed.HUNGER:
			return 0.5
		if need_type == Enums.PrisonerNeed.SLEEP:
			return -2.0  # Regeneracja snu

	# Podczas jedzenia - regeneracja głodu
	if current_state == Enums.PrisonerState.EATING:
		if need_type == Enums.PrisonerNeed.HUNGER:
			return -10.0  # Szybka regeneracja

	# Podczas prysznica - regeneracja higieny
	if current_state == Enums.PrisonerState.SHOWERING:
		if need_type == Enums.PrisonerNeed.HYGIENE:
			return -15.0

	# Podczas rekreacji
	if current_state == Enums.PrisonerState.RECREATION:
		if need_type == Enums.PrisonerNeed.ENTERTAINMENT:
			return -5.0
		if need_type == Enums.PrisonerNeed.FREEDOM:
			return -3.0

	# Podczas pracy
	if current_state == Enums.PrisonerState.WORKING:
		if need_type == Enums.PrisonerNeed.ENTERTAINMENT:
			return -2.0  # Praca też daje trochę zajęcia

	return 1.0


func _check_need_thresholds(need_type: Enums.PrisonerNeed, old_value: float, new_value: float) -> void:
	# Ostrzeżenie
	if old_value > NEED_WARNING_THRESHOLD and new_value <= NEED_WARNING_THRESHOLD:
		Signals.prisoner_need_warning.emit(prisoner_id, need_type, new_value)

	# Krytyczny
	if old_value > NEED_CRITICAL_THRESHOLD and new_value <= NEED_CRITICAL_THRESHOLD:
		Signals.prisoner_need_critical.emit(prisoner_id, need_type, new_value)


func satisfy_need(need_type: Enums.PrisonerNeed, amount: float) -> void:
	var old_value: float = needs[need_type]
	var new_value: float = minf(100.0, old_value + amount)
	needs[need_type] = new_value
	need_changed.emit(need_type, old_value, new_value)
	_calculate_mood()


func get_need(need_type: Enums.PrisonerNeed) -> float:
	return needs.get(need_type, 0.0)


func get_lowest_need() -> Enums.PrisonerNeed:
	var lowest_type: Enums.PrisonerNeed = Enums.PrisonerNeed.HUNGER
	var lowest_value: float = 100.0

	for need_type in needs.keys():
		if needs[need_type] < lowest_value:
			lowest_value = needs[need_type]
			lowest_type = need_type

	return lowest_type


func get_critical_needs() -> Array[Enums.PrisonerNeed]:
	var critical: Array[Enums.PrisonerNeed] = []
	for need_type in needs.keys():
		if needs[need_type] < NEED_CRITICAL_THRESHOLD:
			critical.append(need_type)
	return critical


# =============================================================================
# NASTRÓJ (MOOD)
# =============================================================================
func _calculate_mood() -> void:
	# Nastrój to średnia ważona potrzeb
	var total: float = 0.0
	var weights: float = 0.0

	# Różne wagi dla różnych potrzeb
	var need_weights: Dictionary = {
		Enums.PrisonerNeed.HUNGER: 1.5,
		Enums.PrisonerNeed.SLEEP: 1.3,
		Enums.PrisonerNeed.HYGIENE: 0.8,
		Enums.PrisonerNeed.FREEDOM: 1.2,
		Enums.PrisonerNeed.SAFETY: 1.4,
		Enums.PrisonerNeed.ENTERTAINMENT: 0.8
	}

	for need_type in needs.keys():
		var weight: float = need_weights.get(need_type, 1.0)
		total += needs[need_type] * weight
		weights += weight

	mood = total / weights if weights > 0 else 50.0

	# Modyfikatory z cech
	if Enums.PrisonerTrait.PEACEFUL in traits:
		mood = minf(100.0, mood + 5.0)
	if Enums.PrisonerTrait.AGGRESSIVE in traits:
		mood = maxf(0.0, mood - 5.0)
	if Enums.PrisonerTrait.VOLATILE in traits:
		mood = maxf(0.0, mood - 10.0)


func get_mood() -> float:
	return mood


func get_mood_description() -> String:
	if mood >= 80:
		return "Zadowolony"
	elif mood >= 60:
		return "Spokojny"
	elif mood >= 40:
		return "Neutralny"
	elif mood >= 20:
		return "Niezadowolony"
	else:
		return "Wściekły"


# =============================================================================
# MASZYNA STANÓW (AI)
# =============================================================================
func change_state(new_state: Enums.PrisonerState) -> void:
	if new_state == current_state:
		return

	var old_state := current_state
	current_state = new_state

	_on_state_exit(old_state)
	_on_state_enter(new_state)

	state_changed.emit(old_state, new_state)
	Signals.prisoner_state_changed.emit(prisoner_id, old_state, new_state)


func _on_state_enter(state: Enums.PrisonerState) -> void:
	match state:
		Enums.PrisonerState.SLEEPING:
			# Leż w miejscu
			velocity = Vector2.ZERO
		Enums.PrisonerState.FIGHTING:
			# Zatrzymaj się
			velocity = Vector2.ZERO
		Enums.PrisonerState.LOCKDOWN:
			# Idź do celi
			if assigned_cell_id >= 0:
				_navigate_to_building(assigned_cell_id)


func _on_state_exit(_state: Enums.PrisonerState) -> void:
	pass  # Cleanup jeśli potrzebny


# Timer do losowego chodzenia w stanie IDLE
var _idle_wander_timer: float = 0.0
const IDLE_WANDER_INTERVAL: float = 5.0  # Co 5 sekund sprawdź czy iść gdzie indziej


func _process_ai(delta: float) -> void:
	# Proste AI - reaguj na krytyczne potrzeby i losowo chodź
	if current_state == Enums.PrisonerState.IDLE:
		# Sprawdź krytyczne potrzeby
		var critical := get_critical_needs()
		if critical.size() > 0:
			_handle_critical_need(critical[0])
			return

		# Losowe chodzenie w stanie IDLE
		_idle_wander_timer += delta
		if _idle_wander_timer >= IDLE_WANDER_INTERVAL:
			_idle_wander_timer = 0.0
			# 50% szans na pójście gdzieś
			if randf() < 0.5:
				_wander_randomly()


func _handle_critical_need(need_type: Enums.PrisonerNeed) -> void:
	match need_type:
		Enums.PrisonerNeed.HUNGER:
			# Szukaj kantyny
			_navigate_to_activity_building(Enums.BuildingType.CANTEEN)
		Enums.PrisonerNeed.SLEEP:
			# Idź do celi
			if assigned_cell_id >= 0:
				_navigate_to_building(assigned_cell_id)
				change_state(Enums.PrisonerState.WALKING)
			else:
				_navigate_to_any_cell_or_wander()
		Enums.PrisonerNeed.HYGIENE:
			_navigate_to_activity_building(Enums.BuildingType.SHOWER_ROOM)
		Enums.PrisonerNeed.ENTERTAINMENT:
			_navigate_to_random_recreation_building()
		Enums.PrisonerNeed.FREEDOM:
			# Idź na podwórko
			_navigate_to_activity_building(Enums.BuildingType.YARD)
		_:
			# Dla innych potrzeb - chodź losowo
			_wander_randomly()


# =============================================================================
# NAWIGACJA
# =============================================================================
func _navigate_to_building(building_id: int) -> void:
	var building = BuildingManager.get_building(building_id)
	if building == null:
		return

	current_target_building_id = building_id
	var target_grid: Vector2i = building.position
	target_position = GridManager.grid_to_world(target_grid)

	if nav_agent:
		nav_agent.target_position = target_position


func _navigate_to_position(world_pos: Vector2) -> void:
	target_position = world_pos
	current_target_building_id = -1

	if nav_agent:
		nav_agent.target_position = target_position


func _process_movement(_delta: float) -> void:
	if nav_agent == null:
		return

	if nav_agent.is_navigation_finished():
		_on_navigation_finished()
		return

	var next_pos: Vector2 = nav_agent.get_next_path_position()
	var direction: Vector2 = (next_pos - global_position).normalized()

	velocity = direction * move_speed
	move_and_slide()


func _on_navigation_finished() -> void:
	velocity = Vector2.ZERO

	# Zmień stan w zależności od celu
	if current_target_building_id >= 0:
		var building = BuildingManager.get_building(current_target_building_id)
		if building:
			_enter_building(building)
		else:
			change_state(Enums.PrisonerState.IDLE)
	else:
		# Dotarł do losowego punktu - wróć do IDLE
		change_state(Enums.PrisonerState.IDLE)


func _enter_building(building) -> void:
	# Określ stan na podstawie typu budynku
	match building.type:
		Enums.BuildingType.CELL_SINGLE, Enums.BuildingType.CELL_DOUBLE, \
		Enums.BuildingType.DORMITORY:
			change_state(Enums.PrisonerState.SLEEPING)
		Enums.BuildingType.CANTEEN:
			change_state(Enums.PrisonerState.EATING)
		Enums.BuildingType.SHOWER_ROOM:
			change_state(Enums.PrisonerState.SHOWERING)
		Enums.BuildingType.YARD, Enums.BuildingType.GYM, \
		Enums.BuildingType.LIBRARY, Enums.BuildingType.TV_ROOM:
			change_state(Enums.PrisonerState.RECREATION)
		Enums.BuildingType.WORKSHOP_CARPENTRY, Enums.BuildingType.LAUNDRY, \
		Enums.BuildingType.GARDEN:
			change_state(Enums.PrisonerState.WORKING)
		_:
			change_state(Enums.PrisonerState.IDLE)


# =============================================================================
# ZDROWIE
# =============================================================================
func take_damage(amount: float, source: String = "") -> void:
	health = maxf(0.0, health - amount)

	if health <= 0:
		_die(source)


func heal(amount: float) -> void:
	health = minf(100.0, health + amount)


func _die(cause: String) -> void:
	died.emit(cause)
	Signals.prisoner_died.emit(prisoner_id, cause)
	queue_free()


# =============================================================================
# OBSŁUGA SYGNAŁÓW
# =============================================================================
func _on_hour_changed(_hour: int) -> void:
	# Sprawdź czy wyrok się skończył
	# (days_served aktualizowane przez PrisonerManager)
	pass


func _on_schedule_activity_started(category: int, activity: int) -> void:
	if category != security_category:
		return

	# Nie przerywaj aktualnych akcji jeśli więzień walczy lub ucieka
	if current_state == Enums.PrisonerState.FIGHTING or current_state == Enums.PrisonerState.ESCAPING:
		return

	# Reaguj na zmianę harmonogramu
	_follow_schedule_activity(activity as Enums.ScheduleActivity)


func _follow_schedule_activity(activity: Enums.ScheduleActivity) -> void:
	match activity:
		Enums.ScheduleActivity.SLEEP:
			if assigned_cell_id >= 0:
				_navigate_to_building(assigned_cell_id)
				change_state(Enums.PrisonerState.WALKING)
			else:
				# Brak przypisanej celi - szukaj wolnej celi lub chodź losowo
				_navigate_to_any_cell_or_wander()
		Enums.ScheduleActivity.EATING:
			_navigate_to_activity_building(Enums.BuildingType.CANTEEN)
		Enums.ScheduleActivity.HYGIENE:
			_navigate_to_activity_building(Enums.BuildingType.SHOWER_ROOM)
		Enums.ScheduleActivity.WORK:
			if assigned_work_id >= 0:
				_navigate_to_building(assigned_work_id)
				change_state(Enums.PrisonerState.WALKING)
			else:
				_navigate_to_random_work_building()
		Enums.ScheduleActivity.RECREATION:
			_navigate_to_random_recreation_building()
		Enums.ScheduleActivity.FREE_TIME:
			# Wolny czas - idź losowo
			_wander_randomly()
		Enums.ScheduleActivity.LOCKDOWN:
			if assigned_cell_id >= 0:
				_navigate_to_building(assigned_cell_id)
				change_state(Enums.PrisonerState.WALKING)
			else:
				change_state(Enums.PrisonerState.LOCKDOWN)


func _navigate_to_activity_building(building_type: Enums.BuildingType) -> void:
	var buildings := BuildingManager.get_buildings_by_type(building_type)
	if buildings.size() > 0:
		# Wybierz losowy budynek tego typu
		var building = buildings[randi() % buildings.size()]
		_navigate_to_building(building.id)
		change_state(Enums.PrisonerState.WALKING)
	else:
		# Brak budynku - chodź losowo
		_wander_randomly()


func _navigate_to_random_work_building() -> void:
	var work_types: Array[Enums.BuildingType] = [
		Enums.BuildingType.WORKSHOP_CARPENTRY,
		Enums.BuildingType.LAUNDRY,
		Enums.BuildingType.GARDEN,
		Enums.BuildingType.CALL_CENTER
	]

	for work_type in work_types:
		var buildings := BuildingManager.get_buildings_by_type(work_type)
		if buildings.size() > 0:
			var building = buildings[randi() % buildings.size()]
			_navigate_to_building(building.id)
			change_state(Enums.PrisonerState.WALKING)
			return

	# Brak warsztatów - idź na podwórko
	_navigate_to_activity_building(Enums.BuildingType.YARD)


func _navigate_to_random_recreation_building() -> void:
	var rec_types: Array[Enums.BuildingType] = [
		Enums.BuildingType.YARD,
		Enums.BuildingType.GYM,
		Enums.BuildingType.LIBRARY,
		Enums.BuildingType.CHAPEL,
		Enums.BuildingType.TV_ROOM
	]

	for rec_type in rec_types:
		var buildings := BuildingManager.get_buildings_by_type(rec_type)
		if buildings.size() > 0:
			var building = buildings[randi() % buildings.size()]
			_navigate_to_building(building.id)
			change_state(Enums.PrisonerState.WALKING)
			return

	# Brak budynków rekreacyjnych - idź do celi lub chodź losowo
	if assigned_cell_id >= 0:
		_navigate_to_building(assigned_cell_id)
		change_state(Enums.PrisonerState.WALKING)
	else:
		_wander_randomly()


func _navigate_to_any_cell_or_wander() -> void:
	# Szukaj dowolnej celi
	var cell_types: Array[Enums.BuildingType] = [
		Enums.BuildingType.CELL_SINGLE,
		Enums.BuildingType.CELL_DOUBLE,
		Enums.BuildingType.DORMITORY
	]

	for cell_type in cell_types:
		var cells := BuildingManager.get_buildings_by_type(cell_type)
		if cells.size() > 0:
			var cell = cells[randi() % cells.size()]
			_navigate_to_building(cell.id)
			change_state(Enums.PrisonerState.WALKING)
			return

	# Brak cel - chodź losowo
	_wander_randomly()


func _wander_randomly() -> void:
	# Wybierz losowy punkt w promieniu 10 tile'ów od aktualnej pozycji
	var current_grid := GridManager.world_to_grid(global_position)
	var wander_radius: int = 10

	# Reset celu budynku - to jest losowe chodzenie
	current_target_building_id = -1

	# Próbuj kilka razy znaleźć prawidłowy cel
	for _attempt in range(5):
		var offset := Vector2i(
			randi_range(-wander_radius, wander_radius),
			randi_range(-wander_radius, wander_radius)
		)
		var target_grid := current_grid + offset

		# Sprawdź czy cel jest w granicach mapy
		if GridManager.is_valid_cell(target_grid):
			target_position = GridManager.grid_to_world(target_grid)
			if nav_agent:
				nav_agent.target_position = target_position
			change_state(Enums.PrisonerState.WALKING)
			return

	# Nie udało się - zostań w miejscu
	change_state(Enums.PrisonerState.IDLE)


func _on_lockdown_started(_reason: String) -> void:
	change_state(Enums.PrisonerState.LOCKDOWN)


func _on_lockdown_ended() -> void:
	if current_state == Enums.PrisonerState.LOCKDOWN:
		change_state(Enums.PrisonerState.IDLE)


# =============================================================================
# CECHY (TRAITS)
# =============================================================================
func has_trait(trait_type: Enums.PrisonerTrait) -> bool:
	return trait_type in traits


func add_trait(trait_type: Enums.PrisonerTrait) -> void:
	if not has_trait(trait_type):
		traits.append(trait_type)


func remove_trait(trait_type: Enums.PrisonerTrait) -> void:
	traits.erase(trait_type)


# =============================================================================
# RYZYKO
# =============================================================================
func get_fight_risk() -> float:
	var risk: float = 0.0

	# Bazowe ryzyko z kategorii
	match security_category:
		Enums.SecurityCategory.LOW:
			risk = 0.1
		Enums.SecurityCategory.MEDIUM:
			risk = 0.3
		Enums.SecurityCategory.HIGH:
			risk = 0.6
		Enums.SecurityCategory.MAXIMUM:
			risk = 0.9

	# Modyfikatory z potrzeb
	if needs[Enums.PrisonerNeed.SAFETY] < 30:
		risk *= 1.5
	if needs[Enums.PrisonerNeed.HUNGER] < 20:
		risk *= 1.3
	if mood < 30:
		risk *= 1.5

	# Modyfikatory z cech
	if has_trait(Enums.PrisonerTrait.AGGRESSIVE):
		risk *= 2.0
	if has_trait(Enums.PrisonerTrait.VOLATILE):
		risk *= 1.5
	if has_trait(Enums.PrisonerTrait.PEACEFUL):
		risk *= 0.3

	return clampf(risk, 0.0, 1.0)


func get_escape_risk() -> float:
	var risk: float = 0.0

	# Bazowe ryzyko z wolności
	if needs[Enums.PrisonerNeed.FREEDOM] < 30:
		risk = 0.3
	if needs[Enums.PrisonerNeed.FREEDOM] < 10:
		risk = 0.6

	# Modyfikatory z cech
	if has_trait(Enums.PrisonerTrait.ESCAPIST):
		risk *= 2.0
	if has_trait(Enums.PrisonerTrait.INTELLIGENT):
		risk *= 1.3

	# Długi wyrok = większe ryzyko
	if sentence_days - days_served > 1000:
		risk *= 1.5

	return clampf(risk, 0.0, 1.0)


# =============================================================================
# SAVE/LOAD
# =============================================================================
func get_save_data() -> Dictionary:
	return {
		"id": prisoner_id,
		"name": prisoner_name,
		"age": age,
		"crime_type": crime_type,
		"sentence_days": sentence_days,
		"days_served": days_served,
		"security_category": security_category,
		"traits": traits.duplicate(),
		"needs": needs.duplicate(),
		"health": health,
		"current_state": current_state,
		"assigned_cell_id": assigned_cell_id,
		"assigned_work_id": assigned_work_id,
		"position": [position.x, position.y]
	}


func load_save_data(data: Dictionary) -> void:
	prisoner_id = data.get("id", -1)
	prisoner_name = data.get("name", "Więzień")
	age = data.get("age", 30)
	crime_type = data.get("crime_type", Enums.CrimeType.THEFT)
	sentence_days = data.get("sentence_days", 365)
	days_served = data.get("days_served", 0)
	security_category = data.get("security_category", Enums.SecurityCategory.LOW)
	traits = data.get("traits", [])
	needs = data.get("needs", needs)
	health = data.get("health", 100.0)
	current_state = data.get("current_state", Enums.PrisonerState.IDLE)
	assigned_cell_id = data.get("assigned_cell_id", -1)
	assigned_work_id = data.get("assigned_work_id", -1)

	var pos_arr: Array = data.get("position", [0, 0])
	position = Vector2(pos_arr[0], pos_arr[1])

	_setup_visuals()
	_calculate_mood()
