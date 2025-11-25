## Staff - Bazowa klasa personelu
## CharacterBody2D z systemem zmian i nawigacją
class_name Staff
extends CharacterBody2D

# =============================================================================
# SYGNAŁY
# =============================================================================
signal state_changed(old_state: Enums.StaffState, new_state: Enums.StaffState)
signal morale_changed(old_value: float, new_value: float)
signal shift_ended()

# =============================================================================
# IDENTYFIKACJA
# =============================================================================
@export var staff_id: int = -1
@export var staff_name: String = "Pracownik"
@export var staff_type: Enums.StaffType = Enums.StaffType.GUARD
@export var shift: Enums.Shift = Enums.Shift.MORNING

# =============================================================================
# STATYSTYKI
# =============================================================================
var morale: float = 100.0  # 0-100
var salary: int = 100  # Dzienna pensja

# Stan
var current_state: Enums.StaffState = Enums.StaffState.IDLE
var is_on_duty: bool = false

# Szkolenia
var trainings: Array[String] = []

# =============================================================================
# NAWIGACJA
# =============================================================================
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
var target_position: Vector2 = Vector2.ZERO
var current_target_building_id: int = -1
var move_speed: float = 120.0  # pikseli/sekundę

# =============================================================================
# WIZUALIZACJA
# =============================================================================
@onready var color_rect: ColorRect = $ColorRect  # Placeholder

# Kolory dla typów personelu
const STAFF_COLORS: Dictionary = {
	Enums.StaffType.GUARD: Color(0.2, 0.4, 0.2),      # Ciemno zielony
	Enums.StaffType.COOK: Color(0.8, 0.8, 0.8),       # Biały
	Enums.StaffType.MEDIC: Color(0.8, 0.2, 0.2),      # Czerwony (krzyż)
	Enums.StaffType.PSYCHOLOGIST: Color(0.6, 0.4, 0.6), # Fioletowy
	Enums.StaffType.JANITOR: Color(0.5, 0.5, 0.3),    # Brązowy
	Enums.StaffType.PRIEST: Color(0.1, 0.1, 0.1),     # Czarny
	Enums.StaffType.SNIPER: Color(0.3, 0.3, 0.3),     # Szary
	Enums.StaffType.WARDEN: Color(0.8, 0.6, 0.2)      # Złoty
}

# Pensje bazowe dla typów (pobierane z Constants)
static func get_base_salary(type: Enums.StaffType) -> int:
	return Constants.STAFF_SALARIES.get(type, 100)

# =============================================================================
# ZMIANY (SHIFTS)
# =============================================================================
const SHIFT_HOURS: Dictionary = {
	Enums.Shift.MORNING: [6, 14],    # 06:00 - 14:00
	Enums.Shift.AFTERNOON: [14, 22], # 14:00 - 22:00
	Enums.Shift.NIGHT: [22, 6]       # 22:00 - 06:00
}


# =============================================================================
# FUNKCJE GODOT
# =============================================================================
func _ready() -> void:
	_setup_visuals()
	_connect_signals()
	add_to_group("staff")


func _physics_process(delta: float) -> void:
	# Ruch do celu - tylko dla stanów które wymagają ruchu
	# Uwaga: Stan PATROLLING jest obsługiwany przez podklasy (Guard)
	if current_state == Enums.StaffState.RESPONDING:
		_process_movement(delta)


# =============================================================================
# INICJALIZACJA
# =============================================================================
func initialize(data: Dictionary) -> void:
	staff_id = data.get("id", -1)
	staff_name = data.get("name", "Pracownik")
	staff_type = data.get("type", Enums.StaffType.GUARD)
	shift = data.get("shift", Enums.Shift.MORNING)
	morale = data.get("morale", 100.0)

	# Ustaw pensję bazową
	salary = Staff.get_base_salary(staff_type)

	# Bonus za nocną zmianę
	if shift == Enums.Shift.NIGHT:
		salary = int(salary * 1.2)  # +20%

	_setup_visuals()
	_check_shift_status()


func _setup_visuals() -> void:
	var color: Color = STAFF_COLORS.get(staff_type, Color.WHITE)

	if color_rect:
		color_rect.color = color
		color_rect.size = Vector2(28, 28)
		color_rect.position = Vector2(-14, -14)

	z_index = 21  # Renderuj nad więźniami


func _connect_signals() -> void:
	Signals.hour_changed.connect(_on_hour_changed)
	Signals.fight_started.connect(_on_fight_started)
	Signals.lockdown_started.connect(_on_lockdown_started)


# =============================================================================
# SYSTEM ZMIAN
# =============================================================================
func _check_shift_status() -> void:
	var current_hour: int = GameManager.current_hour
	var shift_hours: Array = SHIFT_HOURS[shift]
	var start_hour: int = shift_hours[0]
	var end_hour: int = shift_hours[1]

	var was_on_duty := is_on_duty

	# Sprawdź czy jest na zmianie
	if shift == Enums.Shift.NIGHT:
		# Nocna zmiana przechodzi przez północ
		is_on_duty = current_hour >= start_hour or current_hour < end_hour
	else:
		is_on_duty = current_hour >= start_hour and current_hour < end_hour

	# Zmiana stanu pracy
	if is_on_duty and not was_on_duty:
		_start_shift()
	elif not is_on_duty and was_on_duty:
		_end_shift()


func _start_shift() -> void:
	change_state(Enums.StaffState.IDLE)
	# Personel zaczyna pracę


func _end_shift() -> void:
	change_state(Enums.StaffState.OFF_DUTY)
	shift_ended.emit()


# =============================================================================
# MORALE
# =============================================================================
func modify_morale(amount: float) -> void:
	var old_morale := morale
	morale = clampf(morale + amount, 0.0, 100.0)

	if morale != old_morale:
		morale_changed.emit(old_morale, morale)


func get_efficiency() -> float:
	# Efektywność spada przy niskim morale
	if morale >= 80:
		return 1.0
	elif morale >= 50:
		return 0.8
	elif morale >= 30:
		return 0.6
	else:
		return 0.4


# =============================================================================
# MASZYNA STANÓW
# =============================================================================
func change_state(new_state: Enums.StaffState) -> void:
	if new_state == current_state:
		return

	var old_state := current_state
	current_state = new_state

	_on_state_exit(old_state)
	_on_state_enter(new_state)

	state_changed.emit(old_state, new_state)
	Signals.staff_state_changed.emit(staff_id, old_state, new_state)


func _on_state_enter(state: Enums.StaffState) -> void:
	match state:
		Enums.StaffState.RESPONDING:
			# Przyspiesz podczas reagowania
			move_speed = 180.0
		Enums.StaffState.OFF_DUTY:
			velocity = Vector2.ZERO


func _on_state_exit(_state: Enums.StaffState) -> void:
	# Reset prędkości
	move_speed = 120.0


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


func navigate_to_position(world_pos: Vector2) -> void:
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

	# Zmień stan w zależności od kontekstu
	if current_state == Enums.StaffState.RESPONDING:
		# Dotarł do miejsca incydentu
		_handle_incident_arrival()


func _handle_incident_arrival() -> void:
	# Bazowa implementacja - podklasy mogą nadpisać
	change_state(Enums.StaffState.IDLE)


# =============================================================================
# OBSŁUGA SYGNAŁÓW
# =============================================================================
func _on_hour_changed(_hour: int) -> void:
	_check_shift_status()


func _on_fight_started(_location: Vector2i, _prisoners: Array) -> void:
	# Bazowa implementacja - Guards reagują
	pass


func _on_lockdown_started(_reason: String) -> void:
	# Podczas lockdownu wszyscy pozostają na miejscu
	pass


# =============================================================================
# POMOCNICZE
# =============================================================================
func get_type_name() -> String:
	match staff_type:
		Enums.StaffType.GUARD:
			return "Strażnik"
		Enums.StaffType.COOK:
			return "Kucharz"
		Enums.StaffType.MEDIC:
			return "Medyk"
		Enums.StaffType.PSYCHOLOGIST:
			return "Psycholog"
		Enums.StaffType.JANITOR:
			return "Sprzątacz"
		Enums.StaffType.PRIEST:
			return "Kapłan"
		Enums.StaffType.SNIPER:
			return "Snajper"
		Enums.StaffType.WARDEN:
			return "Naczelnik"
		_:
			return "Pracownik"


func get_shift_name() -> String:
	match shift:
		Enums.Shift.MORNING:
			return "Poranna (06:00-14:00)"
		Enums.Shift.AFTERNOON:
			return "Popołudniowa (14:00-22:00)"
		Enums.Shift.NIGHT:
			return "Nocna (22:00-06:00)"
		_:
			return "Nieznana"


# =============================================================================
# SAVE/LOAD
# =============================================================================
func get_save_data() -> Dictionary:
	return {
		"id": staff_id,
		"name": staff_name,
		"type": staff_type,
		"shift": shift,
		"morale": morale,
		"current_state": current_state,
		"trainings": trainings.duplicate(),
		"position": [position.x, position.y]
	}


func load_save_data(data: Dictionary) -> void:
	staff_id = data.get("id", -1)
	staff_name = data.get("name", "Pracownik")
	staff_type = data.get("type", Enums.StaffType.GUARD)
	shift = data.get("shift", Enums.Shift.MORNING)
	morale = data.get("morale", 100.0)
	current_state = data.get("current_state", Enums.StaffState.IDLE)
	trainings = data.get("trainings", [])

	var pos_arr: Array = data.get("position", [0, 0])
	position = Vector2(pos_arr[0], pos_arr[1])

	salary = Staff.get_base_salary(staff_type)
	if shift == Enums.Shift.NIGHT:
		salary = int(salary * 1.2)

	_setup_visuals()
	_check_shift_status()
