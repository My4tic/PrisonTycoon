## BuildGhost - Podgląd budynku podczas umieszczania
## Pokazuje gdzie zostanie umieszczony budynek i czy pozycja jest poprawna
class_name BuildGhost
extends Node2D

# =============================================================================
# ZMIENNE
# =============================================================================
var building_type: Enums.BuildingType = Enums.BuildingType.CELL_SINGLE
var grid_position: Vector2i = Vector2i.ZERO
var grid_size: Vector2i = Vector2i(3, 3)
var is_valid: bool = false

# Referencje do węzłów
@onready var sprite: ColorRect = $Sprite
@onready var cost_label: Label = $CostLabel

# Kolory walidacji
const COLOR_VALID := Color(0.3, 0.8, 0.3, 0.5)     # Zielony - można zbudować
const COLOR_INVALID := Color(0.8, 0.3, 0.3, 0.5)   # Czerwony - nie można


# =============================================================================
# INICJALIZACJA
# =============================================================================
func _ready() -> void:
	visible = false
	_update_visual()


# =============================================================================
# USTAWIANIE TYPU BUDYNKU
# =============================================================================
func set_building_type(type: Enums.BuildingType) -> void:
	building_type = type
	grid_size = BuildingManager.get_building_size(type)
	_update_visual()


# =============================================================================
# AKTUALIZACJA POZYCJI
# =============================================================================
func update_position(world_pos: Vector2) -> void:
	# Konwertuj pozycję świata na siatkę
	grid_position = GridManager.world_to_grid(world_pos)

	# Ustaw pozycję ghost na rogu siatki
	position = GridManager.grid_to_world_corner(grid_position)

	# Sprawdź czy można tu budować
	is_valid = BuildingManager.can_build(building_type, grid_position)

	# Zaktualizuj kolor
	_update_color()

	visible = true


func hide_ghost() -> void:
	visible = false


# =============================================================================
# WIZUALIZACJA
# =============================================================================
func _update_visual() -> void:
	if not is_inside_tree():
		await ready

	var pixel_size := Vector2(grid_size.x * Constants.TILE_SIZE, grid_size.y * Constants.TILE_SIZE)

	# Aktualizuj sprite
	if sprite:
		sprite.size = pixel_size

	# Aktualizuj label z kosztem
	if cost_label:
		var cost: int = BuildingManager.get_building_cost(building_type)
		cost_label.text = "$%d" % cost
		cost_label.position = Vector2(0, pixel_size.y + 4)
		cost_label.size = Vector2(pixel_size.x, 24)


func _update_color() -> void:
	if sprite:
		sprite.color = COLOR_VALID if is_valid else COLOR_INVALID

	if cost_label:
		cost_label.add_theme_color_override("font_color", Color.WHITE if is_valid else Color(1.0, 0.5, 0.5))


# =============================================================================
# AKCJE
# =============================================================================
func try_place() -> bool:
	if not is_valid:
		var error: String = BuildingManager.get_placement_error(building_type, grid_position)
		Signals.building_placement_failed.emit(error)
		return false

	var building_id: int = BuildingManager.place_building(building_type, grid_position)
	return building_id != -1


func get_current_cost() -> int:
	return BuildingManager.get_building_cost(building_type)


func get_placement_error() -> String:
	return BuildingManager.get_placement_error(building_type, grid_position)
