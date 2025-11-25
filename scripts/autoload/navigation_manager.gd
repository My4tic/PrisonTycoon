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
	navigation_region.navigation_polygon = _navigation_polygon


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
