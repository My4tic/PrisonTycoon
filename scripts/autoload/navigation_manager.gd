## NavigationManager - Zarządzanie nawigacją i pathfindingiem
## Autoload singleton dostępny jako NavigationManager
##
## Odpowiada za:
## - Generowanie siatki nawigacji
## - Obliczanie ścieżek dla jednostek
## - Aktualizacja nawigacji przy zmianach mapy
extends Node

# =============================================================================
# SYGNAŁY
# =============================================================================
signal navigation_updated

# =============================================================================
# ZMIENNE
# =============================================================================
var navigation_region: NavigationRegion2D = null
var _navigation_polygon: NavigationPolygon = null
var _is_dirty: bool = false
var _update_timer: float = 0.0

# Bufor dla aktualizacji - nie aktualizuj co klatkę
const UPDATE_DELAY: float = 0.1
const AGENT_RADIUS: float = 16.0  # Połowa tile dla postaci

# =============================================================================
# INICJALIZACJA
# =============================================================================
func _ready() -> void:
	# Podłącz sygnały do aktualizacji nawigacji
	Signals.building_placed.connect(_on_map_changed)
	Signals.building_removed.connect(_on_map_changed_simple)
	Signals.wall_placed.connect(_on_map_changed_simple)
	Signals.wall_removed.connect(_on_map_changed_simple)


func _process(delta: float) -> void:
	if _is_dirty:
		_update_timer += delta
		if _update_timer >= UPDATE_DELAY:
			_rebuild_navigation()
			_is_dirty = false
			_update_timer = 0.0


func initialize(region: NavigationRegion2D) -> void:
	navigation_region = region
	if navigation_region == null:
		push_error("NavigationManager: NavigationRegion2D is null!")
		return

	# Utwórz nowy NavigationPolygon
	_navigation_polygon = NavigationPolygon.new()
	_navigation_polygon.agent_radius = AGENT_RADIUS

	navigation_region.navigation_polygon = _navigation_polygon

	# Początkowe zbudowanie nawigacji
	_rebuild_navigation()
	print("NavigationManager: Initialized")


# =============================================================================
# BUDOWANIE NAWIGACJI
# =============================================================================
func _rebuild_navigation() -> void:
	if navigation_region == null or _navigation_polygon == null:
		return

	# Wyczyść poprzednią nawigację
	_navigation_polygon.clear()

	# Zbierz wszystkie przechodne komórki
	var walkable_cells: Array[Vector2i] = _get_all_walkable_cells()

	if walkable_cells.is_empty():
		# Jeśli brak przechodnych komórek, utwórz domyślną na terenie
		_create_terrain_navigation()
	else:
		# Utwórz polygony dla przechodnych obszarów
		_create_walkable_polygons(walkable_cells)

	# Wypiecz nawigację
	NavigationServer2D.bake_from_source_geometry_data(
		_navigation_polygon,
		NavigationMeshSourceGeometryData2D.new()
	)

	navigation_updated.emit()


func _get_all_walkable_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var map_bounds: Rect2i = GridManager.get_map_bounds()

	for x in range(map_bounds.size.x):
		for y in range(map_bounds.size.y):
			var cell := Vector2i(x, y)
			if GridManager.is_walkable(cell):
				cells.append(cell)

	return cells


func _create_terrain_navigation() -> void:
	# Domyślna nawigacja na całym terenie (gdy nie ma jeszcze budynków)
	var map_bounds: Rect2i = GridManager.get_map_bounds()
	var tile_size: int = Constants.TILE_SIZE

	var outline: PackedVector2Array = PackedVector2Array([
		Vector2(0, 0),
		Vector2(map_bounds.size.x * tile_size, 0),
		Vector2(map_bounds.size.x * tile_size, map_bounds.size.y * tile_size),
		Vector2(0, map_bounds.size.y * tile_size)
	])

	_navigation_polygon.add_outline(outline)
	_navigation_polygon.make_polygons_from_outlines()


func _create_walkable_polygons(walkable_cells: Array[Vector2i]) -> void:
	# Grupuj przylegające komórki w regiony
	var regions: Array[Array] = _group_connected_cells(walkable_cells)

	for region in regions:
		var polygon: PackedVector2Array = _cells_to_polygon(region)
		if polygon.size() >= 3:
			_navigation_polygon.add_outline(polygon)

	_navigation_polygon.make_polygons_from_outlines()


func _group_connected_cells(cells: Array[Vector2i]) -> Array[Array]:
	var regions: Array[Array] = []
	var visited: Dictionary = {}

	for cell in cells:
		if visited.has(cell):
			continue

		# BFS aby znaleźć wszystkie połączone komórki
		var region: Array[Vector2i] = []
		var queue: Array[Vector2i] = [cell]

		while not queue.is_empty():
			var current: Vector2i = queue.pop_front()
			if visited.has(current):
				continue

			visited[current] = true
			region.append(current)

			# Sprawdź sąsiadów (tylko kardynalne)
			for neighbor in GridManager.get_neighbors(current, false):
				if not visited.has(neighbor) and GridManager.is_walkable(neighbor):
					queue.append(neighbor)

		if not region.is_empty():
			regions.append(region)

	return regions


func _cells_to_polygon(cells: Array[Vector2i]) -> PackedVector2Array:
	# Konwertuj grupę komórek na zewnętrzny kontur
	# Używamy prostego podejścia: bounding box regionu
	# W przyszłości można zaimplementować marching squares dla dokładniejszych konturów

	if cells.is_empty():
		return PackedVector2Array()

	var min_x: int = cells[0].x
	var max_x: int = cells[0].x
	var min_y: int = cells[0].y
	var max_y: int = cells[0].y

	for cell in cells:
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_y = maxi(max_y, cell.y)

	var tile_size: int = Constants.TILE_SIZE

	# Utwórz kontur dla bounding box
	return PackedVector2Array([
		Vector2(min_x * tile_size, min_y * tile_size),
		Vector2((max_x + 1) * tile_size, min_y * tile_size),
		Vector2((max_x + 1) * tile_size, (max_y + 1) * tile_size),
		Vector2(min_x * tile_size, (max_y + 1) * tile_size)
	])


# =============================================================================
# PATHFINDING
# =============================================================================
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	if navigation_region == null:
		return PackedVector2Array()

	var map_rid: RID = navigation_region.get_navigation_map()
	return NavigationServer2D.map_get_path(map_rid, from, to, true)


func get_closest_point(point: Vector2) -> Vector2:
	if navigation_region == null:
		return point

	var map_rid: RID = navigation_region.get_navigation_map()
	return NavigationServer2D.map_get_closest_point(map_rid, point)


func is_point_reachable(from: Vector2, to: Vector2) -> bool:
	var path: PackedVector2Array = find_path(from, to)
	return path.size() > 0


func get_random_reachable_point(from: Vector2, max_distance: float = 500.0) -> Vector2:
	# Zwraca losowy osiągalny punkt w zadanym promieniu
	if navigation_region == null:
		return from

	var map_rid: RID = navigation_region.get_navigation_map()

	for _attempt in range(10):
		var random_offset: Vector2 = Vector2(
			randf_range(-max_distance, max_distance),
			randf_range(-max_distance, max_distance)
		)
		var target: Vector2 = from + random_offset
		var closest: Vector2 = NavigationServer2D.map_get_closest_point(map_rid, target)

		if is_point_reachable(from, closest):
			return closest

	return from


# =============================================================================
# EVENTY
# =============================================================================
func _on_map_changed(_building_type: int, _position: Vector2i, _size: Vector2i) -> void:
	mark_dirty()


func _on_map_changed_simple(_param1: Variant = null, _param2: Variant = null) -> void:
	mark_dirty()


func mark_dirty() -> void:
	_is_dirty = true


func force_update() -> void:
	_rebuild_navigation()
	_is_dirty = false
	_update_timer = 0.0


# =============================================================================
# DEBUG
# =============================================================================
func get_navigation_polygon() -> NavigationPolygon:
	return _navigation_polygon


func is_navigation_valid() -> bool:
	return navigation_region != null and _navigation_polygon != null
