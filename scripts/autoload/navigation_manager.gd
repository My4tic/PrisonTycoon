## NavigationManager - Zarządzanie nawigacją i pathfindingiem
## Autoload singleton dostępny jako NavigationManager
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

const AGENT_RADIUS: float = 16.0

# =============================================================================
# INICJALIZACJA
# =============================================================================
func _ready() -> void:
	pass


func initialize(region: NavigationRegion2D) -> void:
	navigation_region = region
	if navigation_region == null:
		push_error("NavigationManager: NavigationRegion2D is null!")
		return

	_navigation_polygon = NavigationPolygon.new()
	_navigation_polygon.agent_radius = AGENT_RADIUS

	# Utwórz podstawowy obszar nawigacji pokrywający całą mapę
	_create_initial_navigation_mesh()

	navigation_region.navigation_polygon = _navigation_polygon


## Tworzy początkowy mesh nawigacji pokrywający całą mapę
func _create_initial_navigation_mesh() -> void:
	# Oblicz rozmiar mapy w pikselach
	var map_width: float = Constants.GRID_WIDTH * Constants.TILE_SIZE
	var map_height: float = Constants.GRID_HEIGHT * Constants.TILE_SIZE

	# Margines od krawędzi
	var margin: float = AGENT_RADIUS

	# Utwórz prostokąt pokrywający całą mapę
	var outline: PackedVector2Array = PackedVector2Array([
		Vector2(margin, margin),
		Vector2(map_width - margin, margin),
		Vector2(map_width - margin, map_height - margin),
		Vector2(margin, map_height - margin)
	])

	_navigation_polygon.add_outline(outline)
	_navigation_polygon.make_polygons_from_outlines()


# =============================================================================
# PATHFINDING (placeholder)
# =============================================================================
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	if navigation_region == null:
		return PackedVector2Array()
	var map_rid: RID = navigation_region.get_navigation_map()
	return NavigationServer2D.map_get_path(map_rid, from, to, true)


func is_point_reachable(from: Vector2, to: Vector2) -> bool:
	var path: PackedVector2Array = find_path(from, to)
	return path.size() > 0


func mark_dirty() -> void:
	_is_dirty = true
