## Guard - Strażnik więzienny
## Rozszerza Staff o system patroli i reagowania na incydenty
class_name Guard
extends Staff

# =============================================================================
# SYGNAŁY
# =============================================================================
signal patrol_completed()
signal pacification_started(prisoner_ids: Array)
signal pacification_completed()

# =============================================================================
# PATROL
# =============================================================================
var patrol_route: Array[Vector2i] = []  # Lista punktów patrolu (grid coords)
var current_patrol_index: int = 0
var patrol_wait_time: float = 0.0
const PATROL_WAIT_DURATION: float = 2.0  # Czas postoju na punkcie

# =============================================================================
# REAGOWANIE NA INCYDENTY
# =============================================================================
var detection_range: float = 8.0 * Constants.TILE_SIZE  # 8 tiles
var responding_to_fight: bool = false
var fight_location: Vector2 = Vector2.ZERO
var prisoners_to_pacify: Array = []

# Pacyfikacja
var pacification_progress: float = 0.0
const PACIFICATION_TIME: float = 30.0  # Sekund na 2 więźniów
const MAX_PACIFY_COUNT: int = 2  # Max więźniów jednocześnie

# =============================================================================
# AREA DETEKCJI
# =============================================================================
@onready var detection_area: Area2D = $DetectionArea


# =============================================================================
# FUNKCJE GODOT
# =============================================================================
func _ready() -> void:
	super._ready()
	staff_type = Enums.StaffType.GUARD
	add_to_group("guards")
	_setup_detection_area()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if not is_on_duty:
		return

	match current_state:
		Enums.StaffState.PATROLLING:
			_process_patrol(delta)
		Enums.StaffState.PACIFYING:
			_process_pacification(delta)


# =============================================================================
# KONFIGURACJA OBSZARU DETEKCJI
# =============================================================================
func _setup_detection_area() -> void:
	if detection_area == null:
		detection_area = Area2D.new()
		detection_area.name = "DetectionArea"
		add_child(detection_area)

	# Utwórz kształt detekcji (okrąg)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = detection_range
	collision.shape = shape
	detection_area.add_child(collision)

	# Ustaw warstwy kolizji
	detection_area.collision_layer = 0
	detection_area.collision_mask = 32  # Warstwa więźniów (5)

	# Połącz sygnały
	detection_area.body_entered.connect(_on_detection_area_body_entered)


# =============================================================================
# SYSTEM PATROLI
# =============================================================================
func set_patrol_route(route: Array[Vector2i]) -> void:
	patrol_route = route
	current_patrol_index = 0


func start_patrol() -> void:
	if patrol_route.is_empty():
		_generate_random_patrol()

	if patrol_route.size() > 0:
		change_state(Enums.StaffState.PATROLLING)
		_navigate_to_patrol_point()


func _generate_random_patrol() -> void:
	# Generuj losową trasę patrolu
	patrol_route.clear()

	# Znajdź budynki do patrolowania
	var patrol_buildings: Array[Enums.BuildingType] = [
		Enums.BuildingType.YARD,
		Enums.BuildingType.CANTEEN,
		Enums.BuildingType.GUARD_ROOM,
		Enums.BuildingType.RECEPTION
	]

	for building_type in patrol_buildings:
		var buildings := BuildingManager.get_buildings_by_type(building_type)
		for building in buildings:
			patrol_route.append(building.position)

	# Jeśli brak budynków, patrol wokół środka mapy
	if patrol_route.is_empty():
		var center := Vector2i(Constants.GRID_WIDTH / 2, Constants.GRID_HEIGHT / 2)
		patrol_route.append(center + Vector2i(-5, -5))
		patrol_route.append(center + Vector2i(5, -5))
		patrol_route.append(center + Vector2i(5, 5))
		patrol_route.append(center + Vector2i(-5, 5))


func _navigate_to_patrol_point() -> void:
	if current_patrol_index >= patrol_route.size():
		current_patrol_index = 0
		patrol_completed.emit()

	var grid_pos := patrol_route[current_patrol_index]
	target_position = GridManager.grid_to_world(grid_pos)

	if nav_agent:
		nav_agent.target_position = target_position


func _process_patrol(delta: float) -> void:
	if nav_agent == null:
		return

	if nav_agent.is_navigation_finished():
		# Poczekaj na punkcie
		patrol_wait_time += delta
		if patrol_wait_time >= PATROL_WAIT_DURATION:
			patrol_wait_time = 0.0
			current_patrol_index += 1
			_navigate_to_patrol_point()
	else:
		# Idź do punktu
		_process_movement(delta)


# =============================================================================
# REAGOWANIE NA INCYDENTY
# =============================================================================
func respond_to_fight(location: Vector2, prisoners: Array) -> void:
	if current_state == Enums.StaffState.PACIFYING:
		return  # Już pacyfikuje

	fight_location = location
	prisoners_to_pacify = prisoners.slice(0, MAX_PACIFY_COUNT)
	responding_to_fight = true

	change_state(Enums.StaffState.RESPONDING)
	navigate_to_position(location)


func _on_detection_area_body_entered(body: Node2D) -> void:
	if not is_on_duty:
		return

	# Sprawdź czy to więzień w stanie walki
	if body is Prisoner:
		var prisoner := body as Prisoner
		if prisoner.current_state == Enums.PrisonerState.FIGHTING:
			# Automatycznie reaguj na bójkę
			if current_state != Enums.StaffState.RESPONDING and current_state != Enums.StaffState.PACIFYING:
				respond_to_fight(prisoner.global_position, [prisoner])


override func _handle_incident_arrival() -> void:
	if responding_to_fight and prisoners_to_pacify.size() > 0:
		# Rozpocznij pacyfikację
		change_state(Enums.StaffState.PACIFYING)
		pacification_progress = 0.0
		pacification_started.emit(prisoners_to_pacify.map(func(p): return p.prisoner_id))


# =============================================================================
# PACYFIKACJA
# =============================================================================
func _process_pacification(delta: float) -> void:
	# Sprawdź czy więźniowie nadal walczą
	var still_fighting: Array = prisoners_to_pacify.filter(
		func(p): return p != null and is_instance_valid(p) and p.current_state == Enums.PrisonerState.FIGHTING
	)

	if still_fighting.is_empty():
		_complete_pacification()
		return

	# Postęp pacyfikacji (zależny od efektywności)
	var efficiency := get_efficiency()
	var pacify_speed := delta / PACIFICATION_TIME * efficiency

	pacification_progress += pacify_speed

	if pacification_progress >= 1.0:
		# Pacyfikacja zakończona - zmień stan więźniów
		for prisoner in still_fighting:
			if prisoner and is_instance_valid(prisoner):
				prisoner.change_state(Enums.PrisonerState.IN_SOLITARY)
				# Wysłanie do izolatki
				Signals.prisoner_pacified.emit(prisoner.prisoner_id, staff_id)

		_complete_pacification()


func _complete_pacification() -> void:
	responding_to_fight = false
	prisoners_to_pacify.clear()
	pacification_progress = 0.0

	pacification_completed.emit()

	# Wróć do patrolu
	if is_on_duty:
		start_patrol()
	else:
		change_state(Enums.StaffState.OFF_DUTY)


# =============================================================================
# OBSŁUGA SYGNAŁÓW
# =============================================================================
override func _on_fight_started(location: Vector2i, prisoners: Array) -> void:
	if not is_on_duty:
		return

	# Sprawdź odległość do bójki
	var world_pos := GridManager.grid_to_world(location)
	var distance := global_position.distance_to(world_pos)

	if distance <= detection_range:
		# W zasięgu - reaguj
		respond_to_fight(world_pos, prisoners)


override func _start_shift() -> void:
	super._start_shift()
	# Rozpocznij patrol po rozpoczęciu zmiany
	start_patrol()


override func _end_shift() -> void:
	# Anuluj bieżące zadania
	responding_to_fight = false
	prisoners_to_pacify.clear()
	super._end_shift()
