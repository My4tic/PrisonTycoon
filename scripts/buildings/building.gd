## Building - Bazowa klasa budynku
## Wizualna reprezentacja umieszczonego budynku
class_name Building
extends Area2D

# =============================================================================
# EKSPORTOWANE ZMIENNE
# =============================================================================
@export var building_id: int = -1
@export var building_type: Enums.BuildingType = Enums.BuildingType.CELL_SINGLE

# =============================================================================
# ZMIENNE
# =============================================================================
var grid_position: Vector2i = Vector2i.ZERO
var grid_size: Vector2i = Vector2i(3, 3)
var is_constructed: bool = false
var current_occupancy: int = 0

# Referencje do węzłów
@onready var sprite: Sprite2D = $Sprite
@onready var color_fallback: ColorRect = $ColorFallback
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var label: Label = $Label

# Mapowanie typów budynków na nazwy plików sprite'ów
const SPRITE_FILES: Dictionary = {
	Enums.BuildingType.CELL_SINGLE: "single_cell.png",
	Enums.BuildingType.CELL_DOUBLE: "double_cell.png",
	Enums.BuildingType.KITCHEN: "kitchen.png",
}

# Kolory dla kategorii budynków (fallback gdy brak sprite'a)
const CATEGORY_COLORS: Dictionary = {
	"CELLS": Color(0.4, 0.6, 0.8, 0.8),        # Niebieski
	"FOOD": Color(0.8, 0.6, 0.4, 0.8),         # Pomarańczowy
	"RECREATION": Color(0.5, 0.7, 0.5, 0.8),   # Zielony
	"WORK": Color(0.7, 0.7, 0.5, 0.8),         # Żółtawy
	"INFRASTRUCTURE": Color(0.6, 0.6, 0.6, 0.8),  # Szary
	"SECURITY": Color(0.7, 0.5, 0.5, 0.8)      # Czerwonawy
}


# =============================================================================
# INICJALIZACJA
# =============================================================================
func _ready() -> void:
	add_to_group("buildings")
	z_index = 10  # Renderuj ponad terenem
	_update_visual()


func initialize(id: int, type: Enums.BuildingType, pos: Vector2i, size: Vector2i) -> void:
	building_id = id
	building_type = type
	grid_position = pos
	grid_size = size

	# Ustaw pozycję w świecie
	position = GridManager.grid_to_world_corner(grid_position)

	# Zaktualizuj wizualizację
	_update_visual()


# =============================================================================
# WIZUALIZACJA
# =============================================================================
func _update_visual() -> void:
	if not is_inside_tree():
		await ready

	var info: Dictionary = BuildingManager.get_building_info(building_type)
	var pixel_size := Vector2(grid_size.x * Constants.TILE_SIZE, grid_size.y * Constants.TILE_SIZE)

	# Próbuj załadować sprite
	var has_sprite := _load_sprite()

	if has_sprite and sprite:
		sprite.visible = true
		color_fallback.visible = false
		# Skaluj sprite do rozmiaru budynku
		var texture_size := sprite.texture.get_size()
		sprite.scale = pixel_size / texture_size
	else:
		# Fallback na ColorRect
		if sprite:
			sprite.visible = false
		if color_fallback:
			color_fallback.visible = true
			color_fallback.size = pixel_size
			var category: String = info.get("category", "INFRASTRUCTURE")
			color_fallback.color = CATEGORY_COLORS.get(category, Color(0.5, 0.5, 0.5, 0.8))

	# Aktualizuj collision shape
	if collision:
		var shape := RectangleShape2D.new()
		shape.size = pixel_size
		collision.shape = shape
		collision.position = pixel_size / 2.0

	# Aktualizuj label
	if label:
		label.text = info.get("name", "Budynek")
		label.size = pixel_size
		label.position = Vector2.ZERO


func _load_sprite() -> bool:
	if not sprite:
		return false

	# Sprawdź czy mamy sprite dla tego typu budynku
	if building_type in SPRITE_FILES:
		var sprite_path: String = "res://assets/sprites/buildings/" + str(SPRITE_FILES[building_type])
		var texture: Texture2D = load(sprite_path)
		if texture:
			sprite.texture = texture
			return true

	return false


func set_constructed(constructed: bool) -> void:
	is_constructed = constructed
	if sprite and sprite.visible:
		sprite.modulate.a = 1.0 if constructed else 0.5
	elif color_fallback:
		color_fallback.color.a = 0.8 if constructed else 0.4


func set_highlighted(highlighted: bool) -> void:
	if sprite and sprite.visible:
		sprite.modulate.a = 1.0 if highlighted else (1.0 if is_constructed else 0.5)
	elif color_fallback:
		if highlighted:
			color_fallback.color.a = 1.0
		else:
			color_fallback.color.a = 0.8 if is_constructed else 0.4


# =============================================================================
# INFORMACJE
# =============================================================================
func get_info() -> Dictionary:
	return BuildingManager.get_building_info(building_type)


func get_capacity() -> int:
	return get_info().get("capacity", 0)


func get_available_slots() -> int:
	return max(0, get_capacity() - current_occupancy)


func is_full() -> bool:
	return current_occupancy >= get_capacity()


func get_center_position() -> Vector2:
	return position + Vector2(grid_size.x * Constants.TILE_SIZE / 2.0, grid_size.y * Constants.TILE_SIZE / 2.0)


# =============================================================================
# SYGNAŁY AREA2D
# =============================================================================
func _on_body_entered(body: Node2D) -> void:
	# Więzień lub personel wszedł do budynku
	if body.is_in_group("prisoners"):
		Signals.object_selected.emit("building", building_id)


func _on_body_exited(body: Node2D) -> void:
	# Więzień lub personel wyszedł z budynku
	pass


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			Signals.object_selected.emit("building", building_id)
