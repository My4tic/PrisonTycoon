## BuildModeController - Kontroler trybu budowania
## Zarządza interakcją podczas umieszczania budynków
class_name BuildModeController
extends Node

# =============================================================================
# SYGNAŁY
# =============================================================================
signal build_mode_changed(is_active: bool)

# =============================================================================
# ZMIENNE
# =============================================================================
var is_active: bool = false
var selected_building_type: Enums.BuildingType = Enums.BuildingType.CELL_SINGLE

# Referencje
var build_ghost = null  # BuildGhost
var build_menu = null  # BuildMenu
var buildings_container: Node2D = null
var camera: Camera2D = null

# Sceny
var _building_scene: PackedScene = null


# =============================================================================
# INICJALIZACJA
# =============================================================================
func _ready() -> void:
	_building_scene = preload("res://scenes/buildings/building.tscn")
	_connect_signals()


func _connect_signals() -> void:
	Signals.building_placed.connect(_on_building_placed)
	Signals.building_placement_failed.connect(_on_building_placement_failed)


func initialize(ghost, menu, container: Node2D, cam: Camera2D) -> void:
	build_ghost = ghost
	build_menu = menu
	buildings_container = container
	camera = cam

	if build_menu:
		build_menu.building_selected.connect(_on_menu_building_selected)
		build_menu.menu_closed.connect(_on_menu_closed)


# =============================================================================
# TRYB BUDOWANIA
# =============================================================================
func enter_build_mode(building_type: Enums.BuildingType = Enums.BuildingType.CELL_SINGLE) -> void:
	is_active = true
	selected_building_type = building_type

	if build_ghost:
		build_ghost.set_building_type(building_type)
		build_ghost.visible = false  # Pokaż dopiero po ruchu myszy

	if build_menu:
		build_menu.show_menu()

	Signals.build_mode_entered.emit(building_type)
	build_mode_changed.emit(true)


func exit_build_mode() -> void:
	is_active = false

	if build_ghost:
		build_ghost.hide_ghost()

	if build_menu:
		build_menu.hide_menu()

	Signals.build_mode_exited.emit()
	build_mode_changed.emit(false)


func toggle_build_mode() -> void:
	if is_active:
		exit_build_mode()
	else:
		enter_build_mode()


func select_building(building_type: Enums.BuildingType) -> void:
	selected_building_type = building_type

	if build_ghost:
		build_ghost.set_building_type(building_type)


# =============================================================================
# INPUT
# =============================================================================
func handle_input(event: InputEvent) -> bool:
	if not is_active:
		return false

	# Obsługa ruchu myszy/dotyku
	if event is InputEventMouseMotion:
		var mouse_event := event as InputEventMouseMotion
		_update_ghost_position(mouse_event.position)
		return true

	# Obsługa kliknięcia/tapnięcia
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_try_place_building(mouse_event.position)
			return true
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			exit_build_mode()
			return true

	# Obsługa dotyku
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_update_ghost_position(touch_event.position)
		else:
			_try_place_building(touch_event.position)
		return true

	if event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		_update_ghost_position(drag_event.position)
		return true

	# Escape wychodzi z trybu budowania
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_ESCAPE:
			exit_build_mode()
			return true

	return false


func _update_ghost_position(screen_pos: Vector2) -> void:
	if not build_ghost or not camera:
		return

	# Konwertuj pozycję ekranu na pozycję świata
	var world_pos: Vector2 = _screen_to_world(screen_pos)
	build_ghost.update_position(world_pos)


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	if not camera:
		return screen_pos

	# Pobierz viewport
	var viewport: Viewport = camera.get_viewport()
	var viewport_size: Vector2 = viewport.get_visible_rect().size
	var viewport_center: Vector2 = viewport_size / 2.0

	# Oblicz offset od środka
	var offset: Vector2 = screen_pos - viewport_center

	# Zastosuj zoom
	var world_offset: Vector2 = offset / camera.zoom

	# Dodaj pozycję kamery
	return camera.position + world_offset


func _try_place_building(screen_pos: Vector2) -> void:
	if not build_ghost:
		return

	# Aktualizuj pozycję ghost na wszelki wypadek
	var world_pos: Vector2 = _screen_to_world(screen_pos)
	build_ghost.update_position(world_pos)

	# Próbuj umieścić budynek
	if build_ghost.try_place():
		# Sukces - utwórz wizualny budynek
		_spawn_building_visual(
			BuildingManager.buildings.keys().max(),
			selected_building_type,
			build_ghost.grid_position,
			build_ghost.grid_size
		)


func _spawn_building_visual(building_id: int, building_type: Enums.BuildingType, grid_pos: Vector2i, grid_size: Vector2i) -> void:
	if not buildings_container or not _building_scene:
		return

	var building = _building_scene.instantiate()
	building.initialize(building_id, building_type, grid_pos, grid_size)
	building.set_constructed(true)
	buildings_container.add_child(building)


# =============================================================================
# OBSŁUGA SYGNAŁÓW
# =============================================================================
func _on_menu_building_selected(building_type: Enums.BuildingType) -> void:
	select_building(building_type)


func _on_menu_closed() -> void:
	exit_build_mode()


func _on_building_placed(building_type: int, position: Vector2i, size: Vector2i) -> void:
	# Budynek umieszczony pomyślnie
	pass


func _on_building_placement_failed(reason: String) -> void:
	# Pokaż komunikat o błędzie
	print("Nie można zbudować: ", reason)
	Signals.alert_triggered.emit(
		Enums.AlertPriority.INFO,
		"Błąd budowy",
		reason,
		build_ghost.grid_position if build_ghost else Vector2i.ZERO
	)
