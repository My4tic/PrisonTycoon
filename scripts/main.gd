## Main - Główna scena gry
## Zarządza UI i integruje systemy
extends Node2D

# =============================================================================
# PRELOAD
# =============================================================================
const BuildGhostScene := preload("res://scenes/buildings/build_ghost.tscn")
const BuildMenuScene := preload("res://scenes/ui/build_menu.tscn")
const BuildModeControllerScript := preload("res://scripts/controllers/build_mode_controller.gd")
const EconomyPanelScene := preload("res://scenes/ui/economy_panel.tscn")

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

# UI References - nowa struktura z SafeArea
@onready var safe_area: MarginContainer = $UI/SafeArea
@onready var hud: Control = $UI/SafeArea/HUD
@onready var panels_container: Control = $UI/SafeArea/HUD/Panels

# Build Mode
var build_mode_controller = null  # BuildModeController
var build_ghost = null  # BuildGhost
var build_menu = null  # BuildMenu

# Economy Panel
var economy_panel = null  # EconomyPanel

# Top Bar
@onready var day_label: Label = $UI/SafeArea/HUD/TopBar/MarginContainer/HBoxContainer/TimeContainer/DayLabel
@onready var time_label: Label = $UI/SafeArea/HUD/TopBar/MarginContainer/HBoxContainer/TimeContainer/TimeLabel
@onready var capital_label: Label = $UI/SafeArea/HUD/TopBar/MarginContainer/HBoxContainer/StatsContainer/CapitalContainer/CapitalLabel
@onready var prisoner_count_label: Label = $UI/SafeArea/HUD/TopBar/MarginContainer/HBoxContainer/StatsContainer/PrisonersContainer/PrisonerCountLabel

# Speed buttons
@onready var pause_button: Button = $UI/SafeArea/HUD/TopBar/MarginContainer/HBoxContainer/SpeedControls/PauseButton
@onready var speed1_button: Button = $UI/SafeArea/HUD/TopBar/MarginContainer/HBoxContainer/SpeedControls/Speed1Button
@onready var speed2_button: Button = $UI/SafeArea/HUD/TopBar/MarginContainer/HBoxContainer/SpeedControls/Speed2Button
@onready var speed4_button: Button = $UI/SafeArea/HUD/TopBar/MarginContainer/HBoxContainer/SpeedControls/Speed4Button
@onready var settings_button: Button = $UI/SafeArea/HUD/TopBar/MarginContainer/HBoxContainer/SettingsButton

# Bottom menu buttons
@onready var build_button: Button = $UI/SafeArea/HUD/BottomBar/MarginContainer/ScrollContainer/MenuButtons/BuildButton
@onready var prisoners_button: Button = $UI/SafeArea/HUD/BottomBar/MarginContainer/ScrollContainer/MenuButtons/PrisonersButton
@onready var schedule_button: Button = $UI/SafeArea/HUD/BottomBar/MarginContainer/ScrollContainer/MenuButtons/ScheduleButton
@onready var staff_button: Button = $UI/SafeArea/HUD/BottomBar/MarginContainer/ScrollContainer/MenuButtons/StaffButton
@onready var stats_button: Button = $UI/SafeArea/HUD/BottomBar/MarginContainer/ScrollContainer/MenuButtons/StatsButton
@onready var alerts_button: Button = $UI/SafeArea/HUD/BottomBar/MarginContainer/ScrollContainer/MenuButtons/AlertsButton
@onready var alert_badge: Label = $UI/SafeArea/HUD/BottomBar/MarginContainer/ScrollContainer/MenuButtons/AlertsButton/AlertBadge

# =============================================================================
# ZMIENNE KAMERY
# =============================================================================
var _is_dragging: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _camera_start_pos: Vector2 = Vector2.ZERO

# Touch/pinch zoom
var _touch_points: Dictionary = {}  # touch_index -> position
var _initial_pinch_distance: float = 0.0
var _initial_zoom: float = 1.0

# Double-tap detection
var _last_tap_time: float = 0.0
var _last_tap_position: Vector2 = Vector2.ZERO
const DOUBLE_TAP_TIME: float = 0.3  # Max czas między tapnięciami
const DOUBLE_TAP_DISTANCE: float = 50.0  # Max odległość między tapnięciami

# =============================================================================
# FUNKCJE GODOT
# =============================================================================
func _ready() -> void:
	_connect_signals()
	_connect_buttons()
	_setup_camera()
	_setup_build_mode()
	_setup_economy_panel()

	# Inicjalizuj managery
	GridManager.initialize(tilemap)
	NavigationManager.initialize(navigation_region)

	# Rozpocznij nową grę (tymczasowo - docelowo z menu)
	GameManager.start_new_game(Enums.GameMode.SANDBOX)
	_update_ui()


func _process(_delta: float) -> void:
	if GameManager.is_playing():
		_update_time_display()


func _unhandled_input(event: InputEvent) -> void:
	# Najpierw sprawdź tryb budowania
	if build_mode_controller and build_mode_controller.handle_input(event):
		return

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
	settings_button.pressed.connect(_on_settings_pressed)

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


func _setup_build_mode() -> void:
	# Utwórz BuildGhost
	build_ghost = BuildGhostScene.instantiate()
	world.add_child(build_ghost)

	# Utwórz BuildMenu
	build_menu = BuildMenuScene.instantiate()
	panels_container.add_child(build_menu)

	# Utwórz kontroler
	build_mode_controller = Node.new()
	build_mode_controller.set_script(BuildModeControllerScript)
	add_child(build_mode_controller)
	build_mode_controller.initialize(build_ghost, build_menu, buildings_container, camera)


func _setup_economy_panel() -> void:
	economy_panel = EconomyPanelScene.instantiate()
	panels_container.add_child(economy_panel)


func _handle_camera_input(event: InputEvent) -> void:
	# Obsługa multi-touch (pinch zoom)
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_touch_points[touch_event.index] = touch_event.position
			if _touch_points.size() == 2:
				_start_pinch_zoom()
			elif _touch_points.size() == 1:
				# Sprawdź double-tap
				_check_double_tap(touch_event.position)
		else:
			_touch_points.erase(touch_event.index)
			if _touch_points.size() < 2:
				_initial_pinch_distance = 0.0
		return

	# Obsługa screen drag (jeden palec lub więcej)
	if event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		_touch_points[drag_event.index] = drag_event.position

		if _touch_points.size() == 2:
			# Pinch zoom
			_handle_pinch_zoom()
		elif _touch_points.size() == 1:
			# Pan kamera
			camera.position -= drag_event.relative / camera.zoom
		return

	# Obsługa myszy (dla testowania na PC)
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				# Sprawdź double-click
				if mouse_event.double_click:
					_focus_camera_at(mouse_event.position)
				else:
					_is_dragging = true
					_drag_start_pos = mouse_event.position
					_camera_start_pos = camera.position
			else:
				_is_dragging = false
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(Constants.CAMERA_ZOOM_SPEED)
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(-Constants.CAMERA_ZOOM_SPEED)
		return

	if event is InputEventMouseMotion and _is_dragging:
		var mouse_motion := event as InputEventMouseMotion
		var drag_delta: Vector2 = mouse_motion.position - _drag_start_pos
		camera.position = _camera_start_pos - drag_delta / camera.zoom


func _start_pinch_zoom() -> void:
	var points: Array = _touch_points.values()
	if points.size() >= 2:
		_initial_pinch_distance = (points[0] as Vector2).distance_to(points[1] as Vector2)
		_initial_zoom = camera.zoom.x


func _handle_pinch_zoom() -> void:
	var points: Array = _touch_points.values()
	if points.size() < 2 or _initial_pinch_distance <= 0:
		return

	var current_distance: float = (points[0] as Vector2).distance_to(points[1] as Vector2)
	var zoom_factor: float = current_distance / _initial_pinch_distance
	var new_zoom: float = clampf(_initial_zoom * zoom_factor, Constants.CAMERA_ZOOM_MIN, Constants.CAMERA_ZOOM_MAX)
	camera.zoom = Vector2(new_zoom, new_zoom)


func _zoom_camera(delta: float) -> void:
	var new_zoom: float = camera.zoom.x + delta
	new_zoom = clampf(new_zoom, Constants.CAMERA_ZOOM_MIN, Constants.CAMERA_ZOOM_MAX)
	camera.zoom = Vector2(new_zoom, new_zoom)
	Signals.camera_zoom_changed.emit(new_zoom)


func _check_double_tap(screen_position: Vector2) -> void:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	var time_since_last: float = current_time - _last_tap_time
	var distance_from_last: float = screen_position.distance_to(_last_tap_position)

	if time_since_last < DOUBLE_TAP_TIME and distance_from_last < DOUBLE_TAP_DISTANCE:
		# Double-tap wykryty!
		_focus_camera_at(screen_position)
		# Reset aby uniknąć triple-tap
		_last_tap_time = 0.0
		_last_tap_position = Vector2.ZERO
	else:
		# Zapisz dla następnego sprawdzenia
		_last_tap_time = current_time
		_last_tap_position = screen_position


func _focus_camera_at(screen_position: Vector2) -> void:
	# Konwertuj pozycję ekranu na pozycję świata
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var viewport_center: Vector2 = viewport_size / 2.0

	# Oblicz offset od środka ekranu
	var offset_from_center: Vector2 = screen_position - viewport_center

	# Zastosuj zoom do offsetu
	var world_offset: Vector2 = offset_from_center / camera.zoom

	# Nowa pozycja kamery
	var target_position: Vector2 = camera.position + world_offset

	# Animuj przesunięcie kamery
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(camera, "position", target_position, 0.3)

	# Zoom in przy double-tap (opcjonalnie)
	var new_zoom: float = clampf(camera.zoom.x * 1.5, Constants.CAMERA_ZOOM_MIN, Constants.CAMERA_ZOOM_MAX)
	tween.parallel().tween_property(camera, "zoom", Vector2(new_zoom, new_zoom), 0.3)

	# Emituj sygnał
	Signals.double_tap.emit(target_position)
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
	day_label.text = "Dzień %d" % GameManager.current_day
	time_label.text = GameManager.get_time_string()


func _update_capital_display() -> void:
	var formatted: String = _format_number(EconomyManager.capital)
	capital_label.text = "$%s" % formatted

	# Zmień kolor przy niskim kapitale
	if EconomyManager.capital < 5000:
		capital_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	elif EconomyManager.capital < 10000:
		capital_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	else:
		capital_label.remove_theme_color_override("font_color")


func _update_prisoner_count() -> void:
	# TODO: Pobierz rzeczywistą liczbę więźniów
	var current: int = 0
	var max_capacity: int = BuildingManager.get_total_capacity(Enums.BuildingType.CELL_SINGLE)
	max_capacity += BuildingManager.get_total_capacity(Enums.BuildingType.CELL_DOUBLE)
	max_capacity += BuildingManager.get_total_capacity(Enums.BuildingType.DORMITORY)
	prisoner_count_label.text = "%d/%d" % [current, max_capacity]


func _update_alert_badge() -> void:
	var count: int = EventManager.get_alert_count()
	alert_badge.text = str(count)
	alert_badge.visible = count > 0


func _update_speed_buttons() -> void:
	# Reset wszystkich przycisków
	pause_button.button_pressed = false
	speed1_button.button_pressed = false
	speed2_button.button_pressed = false
	speed4_button.button_pressed = false

	# Zaznacz aktywny
	if GameManager.is_paused:
		pause_button.button_pressed = true
	else:
		match GameManager.speed_index:
			1: speed1_button.button_pressed = true
			2: speed2_button.button_pressed = true
			3: speed4_button.button_pressed = true


func _format_number(value: int) -> String:
	var str_value: String = str(abs(value))
	var result: String = ""
	var count: int = 0

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


func _on_settings_pressed() -> void:
	# TODO: Otwórz panel ustawień
	print("Settings pressed")


# =============================================================================
# OBSŁUGA PRZYCISKÓW MENU
# =============================================================================
func _on_build_pressed() -> void:
	if build_mode_controller:
		build_mode_controller.toggle_build_mode()


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
	# Otwórz panel ekonomii (statystyki finansowe)
	if economy_panel:
		economy_panel.toggle_panel()


func _on_alerts_pressed() -> void:
	# TODO: Otwórz panel alertów
	print("Alerts panel pressed")
