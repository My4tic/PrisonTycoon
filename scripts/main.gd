## Main - Główna scena gry
## Zarządza UI i integruje systemy
extends Node2D

# =============================================================================
# REFERENCJE DO WĘZŁÓW
# =============================================================================
@onready var camera: Camera2D = $Camera2D
@onready var world: Node2D = $World
@onready var tilemap: TileMap = $World/TileMap
@onready var buildings_container: Node2D = $World/Buildings
@onready var prisoners_container: Node2D = $World/Entities/Prisoners
@onready var staff_container: Node2D = $World/Entities/Staff
@onready var navigation_region: NavigationRegion2D = $World/NavigationRegion2D

# UI References
@onready var hud: Control = $UI/HUD
@onready var day_label: Label = $UI/HUD/TopBar/HBoxContainer/DayLabel
@onready var capital_label: Label = $UI/HUD/TopBar/HBoxContainer/CapitalLabel
@onready var prisoner_count_label: Label = $UI/HUD/TopBar/HBoxContainer/PrisonerCount
@onready var alert_badge: Label = $UI/HUD/BottomMenu/HBoxContainer/AlertsButton/AlertBadge

# Speed buttons
@onready var pause_button: Button = $UI/HUD/TopBar/HBoxContainer/SpeedControls/PauseButton
@onready var speed1_button: Button = $UI/HUD/TopBar/HBoxContainer/SpeedControls/Speed1Button
@onready var speed2_button: Button = $UI/HUD/TopBar/HBoxContainer/SpeedControls/Speed2Button
@onready var speed4_button: Button = $UI/HUD/TopBar/HBoxContainer/SpeedControls/Speed4Button

# Bottom menu buttons
@onready var build_button: Button = $UI/HUD/BottomMenu/HBoxContainer/BuildButton
@onready var prisoners_button: Button = $UI/HUD/BottomMenu/HBoxContainer/PrisonersButton
@onready var schedule_button: Button = $UI/HUD/BottomMenu/HBoxContainer/ScheduleButton
@onready var staff_button: Button = $UI/HUD/BottomMenu/HBoxContainer/StaffButton
@onready var stats_button: Button = $UI/HUD/BottomMenu/HBoxContainer/StatsButton
@onready var alerts_button: Button = $UI/HUD/BottomMenu/HBoxContainer/AlertsButton

# =============================================================================
# ZMIENNE KAMERY
# =============================================================================
var _is_dragging: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _camera_start_pos: Vector2 = Vector2.ZERO

# =============================================================================
# FUNKCJE GODOT
# =============================================================================
func _ready() -> void:
	_connect_signals()
	_connect_buttons()
	_setup_camera()

	# Rozpocznij nową grę (tymczasowo - docelowo z menu)
	GameManager.start_new_game(Enums.GameMode.SANDBOX)
	_update_ui()


func _process(_delta: float) -> void:
	if GameManager.is_playing():
		_update_time_display()


func _unhandled_input(event: InputEvent) -> void:
	_handle_camera_input(event)


# =============================================================================
# PODŁĄCZANIE SYGNAŁÓW
# =============================================================================
func _connect_signals() -> void:
	Signals.capital_changed.connect(_on_capital_changed)
	Signals.day_changed.connect(_on_day_changed)
	Signals.hour_changed.connect(_on_hour_changed)
	Signals.game_paused.connect(_on_game_paused)
	Signals.game_speed_changed.connect(_on_game_speed_changed)
	Signals.alert_triggered.connect(_on_alert_triggered)
	Signals.alert_dismissed.connect(_on_alert_dismissed)


func _connect_buttons() -> void:
	pause_button.pressed.connect(_on_pause_pressed)
	speed1_button.pressed.connect(_on_speed1_pressed)
	speed2_button.pressed.connect(_on_speed2_pressed)
	speed4_button.pressed.connect(_on_speed4_pressed)

	build_button.pressed.connect(_on_build_pressed)
	prisoners_button.pressed.connect(_on_prisoners_pressed)
	schedule_button.pressed.connect(_on_schedule_pressed)
	staff_button.pressed.connect(_on_staff_pressed)
	stats_button.pressed.connect(_on_stats_pressed)
	alerts_button.pressed.connect(_on_alerts_pressed)


# =============================================================================
# KAMERA
# =============================================================================
func _setup_camera() -> void:
	camera.position = Vector2(
		Constants.GRID_WIDTH * Constants.TILE_SIZE / 2.0,
		Constants.GRID_HEIGHT * Constants.TILE_SIZE / 2.0
	)
	camera.zoom = Vector2(1.0, 1.0)


func _handle_camera_input(event: InputEvent) -> void:
	# Obsługa drag (pan)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_dragging = true
				_drag_start_pos = event.position
				_camera_start_pos = camera.position
			else:
				_is_dragging = false

		# Zoom kółkiem myszy
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(Constants.CAMERA_ZOOM_SPEED)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(-Constants.CAMERA_ZOOM_SPEED)

	elif event is InputEventMouseMotion and _is_dragging:
		var drag_delta := event.position - _drag_start_pos
		camera.position = _camera_start_pos - drag_delta / camera.zoom

	# Obsługa dotyku (pinch zoom) - będzie rozbudowane
	elif event is InputEventScreenDrag:
		# Single finger drag
		camera.position -= event.relative / camera.zoom


func _zoom_camera(delta: float) -> void:
	var new_zoom := camera.zoom.x + delta
	new_zoom = clampf(new_zoom, Constants.CAMERA_ZOOM_MIN, Constants.CAMERA_ZOOM_MAX)
	camera.zoom = Vector2(new_zoom, new_zoom)
	Signals.camera_zoom_changed.emit(new_zoom)


# =============================================================================
# AKTUALIZACJA UI
# =============================================================================
func _update_ui() -> void:
	_update_time_display()
	_update_capital_display()
	_update_prisoner_count()
	_update_alert_badge()
	_update_speed_buttons()


func _update_time_display() -> void:
	day_label.text = GameManager.get_full_time_string()


func _update_capital_display() -> void:
	capital_label.text = "$%s" % _format_number(EconomyManager.capital)


func _update_prisoner_count() -> void:
	# TODO: Pobierz rzeczywistą liczbę więźniów
	var current := 0
	var max_capacity := BuildingManager.get_total_capacity(Enums.BuildingType.CELL_SINGLE)
	max_capacity += BuildingManager.get_total_capacity(Enums.BuildingType.CELL_DOUBLE)
	max_capacity += BuildingManager.get_total_capacity(Enums.BuildingType.DORMITORY)
	prisoner_count_label.text = "%d/%d" % [current, max_capacity]


func _update_alert_badge() -> void:
	var count := EventManager.get_alert_count()
	alert_badge.text = str(count)
	alert_badge.visible = count > 0


func _update_speed_buttons() -> void:
	pause_button.button_pressed = GameManager.is_paused
	speed1_button.button_pressed = GameManager.speed_index == 1 and not GameManager.is_paused
	speed2_button.button_pressed = GameManager.speed_index == 2
	speed4_button.button_pressed = GameManager.speed_index == 3


func _format_number(value: int) -> String:
	var str_value := str(abs(value))
	var result := ""
	var count := 0

	for i in range(str_value.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = str_value[i] + result
		count += 1

	if value < 0:
		result = "-" + result

	return result


# =============================================================================
# OBSŁUGA SYGNAŁÓW
# =============================================================================
func _on_capital_changed(_old_value: int, _new_value: int) -> void:
	_update_capital_display()


func _on_day_changed(_day: int) -> void:
	_update_time_display()


func _on_hour_changed(_hour: int) -> void:
	_update_time_display()


func _on_game_paused(_is_paused: bool) -> void:
	_update_speed_buttons()


func _on_game_speed_changed(_speed_index: int, _speed_multiplier: float) -> void:
	_update_speed_buttons()


func _on_alert_triggered(_priority: int, _title: String, _message: String, _location: Vector2i) -> void:
	_update_alert_badge()


func _on_alert_dismissed(_alert_id: int) -> void:
	_update_alert_badge()


# =============================================================================
# OBSŁUGA PRZYCISKÓW PRĘDKOŚCI
# =============================================================================
func _on_pause_pressed() -> void:
	GameManager.toggle_pause()


func _on_speed1_pressed() -> void:
	GameManager.set_speed(1)


func _on_speed2_pressed() -> void:
	GameManager.set_speed(2)


func _on_speed4_pressed() -> void:
	GameManager.set_speed(3)


# =============================================================================
# OBSŁUGA PRZYCISKÓW MENU
# =============================================================================
func _on_build_pressed() -> void:
	# TODO: Otwórz panel budowania
	print("Build menu pressed")


func _on_prisoners_pressed() -> void:
	# TODO: Otwórz panel więźniów
	print("Prisoners panel pressed")


func _on_schedule_pressed() -> void:
	# TODO: Otwórz panel harmonogramu
	print("Schedule panel pressed")


func _on_staff_pressed() -> void:
	# TODO: Otwórz panel personelu
	print("Staff panel pressed")


func _on_stats_pressed() -> void:
	# TODO: Otwórz panel statystyk
	print("Stats panel pressed")


func _on_alerts_pressed() -> void:
	# TODO: Otwórz panel alertów
	print("Alerts panel pressed")
