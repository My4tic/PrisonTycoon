## GameManager - Zarządzanie stanem gry
## Autoload singleton dostępny jako GameManager
##
## Odpowiada za:
## - Stan gry (menu, gameplay, pauza)
## - System czasu in-game (dzień, godzina, minuty)
## - Prędkość gry (x1, x2, x4, pauza)
## - Przełączanie scen i stanów
extends Node

# =============================================================================
# ZMIENNE STANU
# =============================================================================
var current_state: Enums.GameState = Enums.GameState.MENU
var previous_state: Enums.GameState = Enums.GameState.MENU

# Czas gry
var current_day: int = 1
var current_hour: int = 6  # Start o 6:00
var current_minute: int = 0
var _time_accumulator: float = 0.0

# Prędkość gry
var speed_index: int = Constants.DEFAULT_GAME_SPEED_INDEX
var is_paused: bool = false

# Tryb gry
var game_mode: Enums.GameMode = Enums.GameMode.CAMPAIGN
var difficulty: Enums.Difficulty = Enums.Difficulty.NORMAL

# =============================================================================
# FUNKCJE GODOT
# =============================================================================
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Działa nawet na pauzie


func _process(delta: float) -> void:
	if current_state == Enums.GameState.PLAYING and not is_paused:
		_update_game_time(delta)


# =============================================================================
# ZARZĄDZANIE STANEM
# =============================================================================
func change_state(new_state: Enums.GameState) -> void:
	if new_state == current_state:
		return

	previous_state = current_state
	current_state = new_state
	Signals.game_state_changed.emit(previous_state, current_state)


func start_new_game(mode: Enums.GameMode, diff: Enums.Difficulty = Enums.Difficulty.NORMAL) -> void:
	game_mode = mode
	difficulty = diff

	# Reset czasu
	current_day = 1
	current_hour = 6
	current_minute = 0
	_time_accumulator = 0.0

	# Reset prędkości
	speed_index = Constants.DEFAULT_GAME_SPEED_INDEX
	is_paused = false

	change_state(Enums.GameState.PLAYING)


func end_game(is_victory: bool = false) -> void:
	if is_victory:
		change_state(Enums.GameState.VICTORY)
	else:
		change_state(Enums.GameState.GAME_OVER)


# =============================================================================
# PAUZA I PRĘDKOŚĆ
# =============================================================================
func toggle_pause() -> void:
	set_paused(not is_paused)


func set_paused(paused: bool) -> void:
	is_paused = paused
	Signals.game_paused.emit(is_paused)

	if is_paused:
		get_tree().paused = true
	else:
		get_tree().paused = false


func set_speed(index: int) -> void:
	index = clampi(index, 0, Constants.GAME_SPEEDS.size() - 1)

	if index == 0:
		# Indeks 0 = pauza
		set_paused(true)
	else:
		speed_index = index
		if is_paused:
			set_paused(false)
		Signals.game_speed_changed.emit(speed_index, get_current_speed())


func increase_speed() -> void:
	set_speed(speed_index + 1)


func decrease_speed() -> void:
	set_speed(speed_index - 1)


func get_current_speed() -> float:
	return Constants.GAME_SPEEDS[speed_index]


# =============================================================================
# SYSTEM CZASU
# =============================================================================
func _update_game_time(delta: float) -> void:
	var speed_multiplier := get_current_speed()
	_time_accumulator += delta * speed_multiplier

	# Każda sekunda realna = 1 minuta w grze (przy x1)
	while _time_accumulator >= Constants.SECONDS_PER_GAME_MINUTE:
		_time_accumulator -= Constants.SECONDS_PER_GAME_MINUTE
		_advance_minute()


func _advance_minute() -> void:
	current_minute += 1

	if current_minute >= Constants.MINUTES_PER_HOUR:
		current_minute = 0
		_advance_hour()


func _advance_hour() -> void:
	var old_hour := current_hour
	current_hour += 1

	if current_hour >= Constants.HOURS_PER_DAY:
		current_hour = 0
		_advance_day()

	Signals.hour_changed.emit(current_hour)


func _advance_day() -> void:
	current_day += 1
	Signals.day_changed.emit(current_day)


func get_time_string() -> String:
	return "%02d:%02d" % [current_hour, current_minute]


func get_date_string() -> String:
	return "Dzień %d" % current_day


func get_full_time_string() -> String:
	return "%s - %s" % [get_date_string(), get_time_string()]


# =============================================================================
# TRYB BUDOWANIA
# =============================================================================
func enter_build_mode(building_type: Enums.BuildingType) -> void:
	if current_state == Enums.GameState.PLAYING:
		change_state(Enums.GameState.BUILD_MODE)
		Signals.build_mode_entered.emit(building_type)


func exit_build_mode() -> void:
	if current_state == Enums.GameState.BUILD_MODE:
		change_state(Enums.GameState.PLAYING)
		Signals.build_mode_exited.emit()


# =============================================================================
# UTILITY
# =============================================================================
func is_playing() -> bool:
	return current_state == Enums.GameState.PLAYING or current_state == Enums.GameState.BUILD_MODE


func is_in_build_mode() -> bool:
	return current_state == Enums.GameState.BUILD_MODE


## Konwersja pozycji świata na pozycję siatki
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / Constants.TILE_SIZE),
		floori(world_pos.y / Constants.TILE_SIZE)
	)


## Konwersja pozycji siatki na pozycję świata (środek tile'a)
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0,
		grid_pos.y * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0
	)


## Konwersja pozycji siatki na pozycję świata (lewy górny róg)
func grid_to_world_corner(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * Constants.TILE_SIZE,
		grid_pos.y * Constants.TILE_SIZE
	)
