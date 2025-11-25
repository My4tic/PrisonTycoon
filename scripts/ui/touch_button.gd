## TouchButton - Przycisk zoptymalizowany pod dotyk
## Zapewnia minimalny obszar dotykowy nawet dla małych wizualnie przycisków
class_name TouchButton
extends Button

## Minimalny rozmiar obszaru dotykowego (w pikselach)
@export var min_touch_size: Vector2 = Vector2(48, 48)

## Czy pokazać obszar dotykowy (debug)
@export var debug_show_touch_area: bool = false


func _ready() -> void:
	_ensure_minimum_size()
	resized.connect(_ensure_minimum_size)


func _ensure_minimum_size() -> void:
	custom_minimum_size = Vector2(
		maxf(custom_minimum_size.x, min_touch_size.x),
		maxf(custom_minimum_size.y, min_touch_size.y)
	)


func _draw() -> void:
	if debug_show_touch_area:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0, 0, 0.3))
