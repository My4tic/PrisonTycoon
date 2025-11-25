## EscapeSystem - System zarządzania ucieczkami
## Autoload singleton dostępny jako EscapeSystem
##
## Odpowiada za:
## - Wykrywanie warunków próby ucieczki
## - Zarządzanie aktywnymi próbami ucieczek
## - Wykrywanie przez strażników
## - Pościgi i rozwiązywanie ucieczek
extends Node

# =============================================================================
# KLASA DANYCH UCIECZKI
# =============================================================================
class EscapeAttemptData:
	var id: int
	var prisoner_id: int
	var prisoner_ref  # Reference to Prisoner
	var start_location: Vector2i
	var escape_route: Array[Vector2i] = []
	var current_route_index: int = 0
	var start_time: Dictionary
	var duration: float = 0.0
	var is_detected: bool = false
	var is_resolved: bool = false
	var success: bool = false
	var event_id: int = -1

	func _init(p_id: int, p_prisoner_id: int, p_location: Vector2i) -> void:
		id = p_id
		prisoner_id = p_prisoner_id
		start_location = p_location
		start_time = {
			"day": GameManager.current_day,
			"hour": GameManager.current_hour,
			"minute": GameManager.current_minute
		}


# =============================================================================
# ZMIENNE
# =============================================================================
# Aktywne próby ucieczek
var active_escapes: Array[EscapeAttemptData] = []
var _next_escape_id: int = 1

# Timer sprawdzania warunków
var _check_timer: float = 0.0
const CHECK_INTERVAL: float = 5.0  # Sprawdzaj co 5 sekund

# Parametry ucieczek
const ESCAPE_DETECTION_CHANCE_BASE: float = 0.3  # Bazowa szansa wykrycia/sekundę
const ESCAPE_SUCCESS_DISTANCE: float = 10.0 * Constants.TILE_SIZE  # Dystans do granicy mapy
const ESCAPE_MOVE_SPEED_MULTIPLIER: float = 1.3  # Uciekający poruszają się szybciej

# Punkty ucieczki (krawędzie mapy)
var escape_points: Array[Vector2i] = []


# =============================================================================
# FUNKCJE GODOT
# =============================================================================
func _ready() -> void:
	Signals.prisoner_pacified.connect(_on_prisoner_pacified)
	Signals.escape_attempt_detected.connect(_on_external_escape_detected)
	_calculate_escape_points()


func _process(delta: float) -> void:
	if not GameManager.is_playing() or GameManager.is_paused:
		return

	# Sprawdzaj warunki rozpoczęcia ucieczki
	_check_timer += delta
	if _check_timer >= CHECK_INTERVAL:
		_check_timer = 0.0
		_check_escape_conditions()

	# Aktualizuj aktywne ucieczki
	_update_active_escapes(delta)


# =============================================================================
# OBLICZANIE PUNKTÓW UCIECZKI
# =============================================================================
func _calculate_escape_points() -> void:
	escape_points.clear()

	# Punkty na krawędziach mapy
	var width: int = Constants.GRID_WIDTH
	var height: int = Constants.GRID_HEIGHT

	# Górna krawędź
	for x in range(0, width, 10):
		escape_points.append(Vector2i(x, 0))

	# Dolna krawędź
	for x in range(0, width, 10):
		escape_points.append(Vector2i(x, height - 1))

	# Lewa krawędź
	for y in range(0, height, 10):
		escape_points.append(Vector2i(0, y))

	# Prawa krawędź
	for y in range(0, height, 10):
		escape_points.append(Vector2i(width - 1, y))


# =============================================================================
# SPRAWDZANIE WARUNKÓW UCIECZKI
# =============================================================================
func _check_escape_conditions() -> void:
	var all_prisoners: Array = PrisonerManager.get_all_prisoners()

	for prisoner in all_prisoners:
		if prisoner == null or not is_instance_valid(prisoner):
			continue

		# Pomiń jeśli już ucieka lub jest w nieodpowiednim stanie
		if prisoner.current_state == Enums.PrisonerState.ESCAPING:
			continue
		if prisoner.current_state == Enums.PrisonerState.FIGHTING:
			continue
		if prisoner.current_state == Enums.PrisonerState.IN_SOLITARY:
			continue
		if prisoner.current_state == Enums.PrisonerState.IN_INFIRMARY:
			continue
		if prisoner.current_state == Enums.PrisonerState.SLEEPING:
			continue

		# Oblicz ryzyko ucieczki
		var escape_risk: float = prisoner.get_escape_risk()

		# Rzut kostką (normalizacja do godziny)
		if randf() < escape_risk * (CHECK_INTERVAL / 3600.0):
			_try_start_escape(prisoner)


func _try_start_escape(prisoner) -> void:
	# Znajdź najbliższy punkt ucieczki
	var best_escape_point: Vector2i = _find_best_escape_point(prisoner)

	if best_escape_point == Vector2i(-1, -1):
		return  # Brak dostępnych punktów

	# Rozpocznij ucieczkę
	var location := GridManager.world_to_grid(prisoner.global_position)
	start_escape(prisoner, location, best_escape_point)


func _find_best_escape_point(prisoner) -> Vector2i:
	if escape_points.is_empty():
		return Vector2i(-1, -1)

	var prisoner_pos := GridManager.world_to_grid(prisoner.global_position)
	var best_point: Vector2i = escape_points[0]
	var best_distance: float = INF

	# Inteligentni więźniowie wybierają mniej patrolowany punkt
	var is_intelligent: bool = prisoner.has_trait(Enums.PrisonerTrait.INTELLIGENT)

	for point in escape_points:
		var distance: float = prisoner_pos.distance_to(point)

		if is_intelligent:
			# Uwzględnij obecność strażników
			var guard_penalty: float = _get_guard_density_at_point(point) * 100.0
			distance += guard_penalty

		if distance < best_distance:
			best_distance = distance
			best_point = point

	return best_point


func _get_guard_density_at_point(point: Vector2i) -> float:
	var world_pos := GridManager.grid_to_world(point)
	var density: float = 0.0
	var guards: Array = StaffManager.get_staff_by_type(Enums.StaffType.GUARD)

	for guard in guards:
		if guard == null or not is_instance_valid(guard):
			continue
		if not guard.is_on_duty:
			continue

		var distance: float = guard.global_position.distance_to(world_pos)
		if distance < Constants.GUARD_DETECTION_RANGE * Constants.TILE_SIZE:
			density += 1.0 - (distance / (Constants.GUARD_DETECTION_RANGE * Constants.TILE_SIZE))

	return density


# =============================================================================
# ROZPOCZYNANIE UCIECZKI
# =============================================================================
func start_escape(prisoner, start_location: Vector2i, escape_point: Vector2i) -> int:
	# Utwórz dane ucieczki
	var escape := EscapeAttemptData.new(_next_escape_id, prisoner.prisoner_id, start_location)
	_next_escape_id += 1

	escape.prisoner_ref = prisoner
	escape.escape_route = _generate_escape_route(start_location, escape_point)

	# Dodaj do listy aktywnych
	active_escapes.append(escape)

	# Zmień stan więźnia
	prisoner.change_state(Enums.PrisonerState.ESCAPING)

	# Zwiększ napięcie (ale nie twórz jeszcze alertu - ucieczka może być niewidoczna)
	EventManager.add_tension(3.0)

	return escape.id


func _generate_escape_route(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var route: Array[Vector2i] = []

	# Prosta interpolacja (w przyszłości można użyć A*)
	var steps: int = max(abs(end.x - start.x), abs(end.y - start.y))

	if steps == 0:
		return [end]

	for i in range(1, steps + 1):
		var t: float = float(i) / float(steps)
		var point := Vector2i(
			lerp(start.x, end.x, t),
			lerp(start.y, end.y, t)
		)
		route.append(point)

	return route


# =============================================================================
# AKTUALIZACJA UCIECZEK
# =============================================================================
func _update_active_escapes(delta: float) -> void:
	var game_delta: float = delta * GameManager.get_speed_multiplier()
	var escapes_to_remove: Array = []

	for escape in active_escapes:
		if escape.is_resolved:
			escapes_to_remove.append(escape)
			continue

		escape.duration += game_delta

		# Sprawdź czy więzień jest nadal ważny
		if escape.prisoner_ref == null or not is_instance_valid(escape.prisoner_ref):
			escape.is_resolved = true
			escapes_to_remove.append(escape)
			continue

		# Sprawdź wykrycie
		if not escape.is_detected:
			_check_escape_detection(escape)

		# Aktualizuj ruch uciekiniera
		_update_escape_movement(escape, game_delta)

		# Sprawdź sukces ucieczki
		if _check_escape_success(escape):
			_complete_escape_success(escape)
			escapes_to_remove.append(escape)

	# Usuń rozwiązane
	for escape in escapes_to_remove:
		active_escapes.erase(escape)


func _check_escape_detection(escape: EscapeAttemptData) -> void:
	var prisoner = escape.prisoner_ref

	if prisoner == null:
		return

	# Szansa bazowa na wykrycie
	var detection_chance: float = ESCAPE_DETECTION_CHANCE_BASE

	# Modyfikatory
	if prisoner.has_trait(Enums.PrisonerTrait.INTELLIGENT):
		detection_chance *= 0.6  # Trudniej wykryć

	if prisoner.has_trait(Enums.PrisonerTrait.ESCAPIST):
		detection_chance *= 0.7  # Doświadczony uciekinier

	# Sprawdź strażników w pobliżu
	var guards: Array = StaffManager.get_staff_by_type(Enums.StaffType.GUARD)

	for guard in guards:
		if guard == null or not is_instance_valid(guard):
			continue
		if not guard.is_on_duty:
			continue

		var distance: float = guard.global_position.distance_to(prisoner.global_position)
		var detection_range: float = Constants.GUARD_DETECTION_RANGE * Constants.TILE_SIZE

		if distance <= detection_range:
			# Zwiększona szansa wykrycia w zasięgu strażnika
			var proximity_bonus: float = 1.0 - (distance / detection_range)
			var guard_efficiency: float = guard.get_efficiency()

			var final_chance: float = detection_chance * (1.0 + proximity_bonus) * guard_efficiency

			if randf() < final_chance * 0.1:  # Per-frame check
				_detect_escape(escape, guard)
				return


func _detect_escape(escape: EscapeAttemptData, detector = null) -> void:
	escape.is_detected = true

	var location := GridManager.world_to_grid(escape.prisoner_ref.global_position)

	# Utwórz event
	escape.event_id = EventManager.create_event(
		Enums.EventType.ESCAPE_ATTEMPT,
		location,
		[escape.prisoner_id] as Array[int]
	)

	# Emituj sygnał
	Signals.escape_attempt_detected.emit(escape.prisoner_id, location)

	# Zwiększ napięcie
	EventManager.add_tension(10.0)

	# Wyślij strażników do pościgu
	if detector:
		_dispatch_guards_to_chase(escape, detector)


func _dispatch_guards_to_chase(escape: EscapeAttemptData, first_responder = null) -> void:
	var target_pos: Vector2 = escape.prisoner_ref.global_position
	var guards: Array = StaffManager.get_staff_by_type(Enums.StaffType.GUARD)

	var dispatched_count: int = 0
	const MAX_CHASERS: int = 3

	for guard in guards:
		if guard == null or not is_instance_valid(guard):
			continue
		if not guard.is_on_duty:
			continue
		if guard.current_state == Enums.StaffState.PACIFYING:
			continue
		if dispatched_count >= MAX_CHASERS:
			break

		# Wyślij strażnika
		guard.change_state(Enums.StaffState.RESPONDING)
		guard.navigate_to_position(target_pos)
		dispatched_count += 1


func _update_escape_movement(escape: EscapeAttemptData, delta: float) -> void:
	var prisoner = escape.prisoner_ref

	if prisoner == null or not is_instance_valid(prisoner):
		return

	if escape.escape_route.is_empty():
		return

	if escape.current_route_index >= escape.escape_route.size():
		return

	# Cel ruchu
	var target_grid := escape.escape_route[escape.current_route_index]
	var target_world := GridManager.grid_to_world(target_grid)

	# Ruch w kierunku celu
	var direction: Vector2 = (target_world - prisoner.global_position).normalized()
	var speed: float = prisoner.move_speed * ESCAPE_MOVE_SPEED_MULTIPLIER

	prisoner.velocity = direction * speed
	prisoner.move_and_slide()

	# Sprawdź czy dotarł do punktu
	if prisoner.global_position.distance_to(target_world) < 10.0:
		escape.current_route_index += 1


func _check_escape_success(escape: EscapeAttemptData) -> bool:
	if escape.escape_route.is_empty():
		return false

	# Sprawdź czy dotarł do ostatniego punktu trasy
	return escape.current_route_index >= escape.escape_route.size()


func _complete_escape_success(escape: EscapeAttemptData) -> void:
	escape.is_resolved = true
	escape.success = true

	# Utwórz event sukcesu
	EventManager.create_event(
		Enums.EventType.ESCAPE_SUCCESS,
		escape.escape_route[escape.escape_route.size() - 1],
		[escape.prisoner_id] as Array[int]
	)

	# Emituj sygnał
	Signals.prisoner_escaped.emit(escape.prisoner_id)

	# Kary
	EconomyManager.add_expense(Constants.ESCAPE_PENALTY_MONEY, "escape_penalty")

	# Usuń więźnia z gry
	PrisonerManager.remove_prisoner(escape.prisoner_id, "escaped")

	# Zmniejsz napięcie (incydent rozwiązany, choć negatywnie)
	EventManager.reduce_tension(5.0)

	# Rozwiąż event wykrycia
	if escape.event_id >= 0:
		EventManager.resolve_event(escape.event_id)


func _fail_escape(escape: EscapeAttemptData) -> void:
	escape.is_resolved = true
	escape.success = false

	var prisoner = escape.prisoner_ref

	if prisoner != null and is_instance_valid(prisoner):
		# Więzień trafia do izolatki
		prisoner.change_state(Enums.PrisonerState.IN_SOLITARY)
		Signals.prisoner_sent_to_solitary.emit(prisoner.prisoner_id, 3)  # 3 dni

	# Rozwiąż event
	if escape.event_id >= 0:
		EventManager.resolve_event(escape.event_id)

	# Zmniejsz napięcie
	EventManager.reduce_tension(8.0)


# =============================================================================
# OBSŁUGA SYGNAŁÓW
# =============================================================================
func _on_prisoner_pacified(prisoner_id: int, _guard_id: int) -> void:
	# Sprawdź czy to uciekinier
	for escape in active_escapes:
		if escape.prisoner_id == prisoner_id:
			_fail_escape(escape)
			break


func _on_external_escape_detected(prisoner_id: int, location: Vector2i) -> void:
	# Obsługa wykryć z zewnątrz
	for escape in active_escapes:
		if escape.prisoner_id == prisoner_id:
			if not escape.is_detected:
				escape.is_detected = true
				escape.event_id = EventManager.create_event(
					Enums.EventType.ESCAPE_ATTEMPT,
					location,
					[prisoner_id] as Array[int]
				)
			return


# =============================================================================
# API PUBLICZNE
# =============================================================================
func get_active_escapes() -> Array[EscapeAttemptData]:
	return active_escapes


func get_escape_count() -> int:
	return active_escapes.size()


func has_active_escapes() -> bool:
	return not active_escapes.is_empty()


func get_escape_by_prisoner(prisoner_id: int) -> EscapeAttemptData:
	for escape in active_escapes:
		if escape.prisoner_id == prisoner_id:
			return escape
	return null


func force_end_all_escapes() -> void:
	for escape in active_escapes:
		_fail_escape(escape)
	active_escapes.clear()


# =============================================================================
# SAVE/LOAD
# =============================================================================
func get_save_data() -> Dictionary:
	var escapes_data: Array = []

	for escape in active_escapes:
		var route_data: Array = []
		for point in escape.escape_route:
			route_data.append([point.x, point.y])

		escapes_data.append({
			"id": escape.id,
			"prisoner_id": escape.prisoner_id,
			"start_location": [escape.start_location.x, escape.start_location.y],
			"escape_route": route_data,
			"current_route_index": escape.current_route_index,
			"start_time": escape.start_time,
			"duration": escape.duration,
			"is_detected": escape.is_detected,
			"event_id": escape.event_id
		})

	return {
		"escapes": escapes_data,
		"next_escape_id": _next_escape_id
	}


func load_save_data(data: Dictionary) -> void:
	active_escapes.clear()
	_next_escape_id = data.get("next_escape_id", 1)

	for e_data in data.get("escapes", []):
		var start_loc_arr: Array = e_data["start_location"]
		var start_loc := Vector2i(start_loc_arr[0], start_loc_arr[1])

		var escape := EscapeAttemptData.new(e_data["id"], e_data["prisoner_id"], start_loc)

		# Odtwórz trasę
		for point_arr in e_data.get("escape_route", []):
			escape.escape_route.append(Vector2i(point_arr[0], point_arr[1]))

		escape.current_route_index = e_data.get("current_route_index", 0)
		escape.start_time = e_data.get("start_time", {})
		escape.duration = e_data.get("duration", 0.0)
		escape.is_detected = e_data.get("is_detected", false)
		escape.event_id = e_data.get("event_id", -1)

		# Odtwórz referencję do więźnia
		escape.prisoner_ref = PrisonerManager.get_prisoner(escape.prisoner_id)

		if escape.prisoner_ref != null:
			active_escapes.append(escape)
