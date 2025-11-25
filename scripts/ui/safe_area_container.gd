## SafeAreaContainer - Kontener z obsługą bezpiecznego obszaru
## Automatycznie dodaje marginesy dla notchy, zaokrąglonych rogów i gesture bar
class_name SafeAreaContainer
extends MarginContainer

## Gdzie zastosować safe area margins
@export_flags("Top", "Bottom", "Left", "Right") var apply_to: int = 15  # Wszystkie strony

## Dodatkowy margines poza safe area (w pikselach bazowych)
@export var extra_margin_top: int = 0
@export var extra_margin_bottom: int = 0
@export var extra_margin_left: int = 0
@export var extra_margin_right: int = 0

## Minimalny margines nawet bez notcha (dla estetyki)
@export var min_margin: int = 8

var _cached_safe_area: Rect2i = Rect2i()


func _ready() -> void:
	_update_margins()
	get_tree().root.size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	_update_margins()


func _update_margins() -> void:
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var screen_size: Vector2i = DisplayServer.screen_get_size()

	# Jeśli safe area jest takie samo jak ekran, użyj domyślnych marginesów
	if safe_area.size == Vector2i.ZERO or safe_area == Rect2i(Vector2i.ZERO, screen_size):
		# Brak notcha - użyj minimalnych marginesów
		_apply_margins(min_margin, min_margin, min_margin, min_margin)
		return

	# Oblicz marginesy z safe area
	var margin_top: int = safe_area.position.y if apply_to & 1 else 0
	var margin_bottom: int = (screen_size.y - safe_area.end.y) if apply_to & 2 else 0
	var margin_left: int = safe_area.position.x if apply_to & 4 else 0
	var margin_right: int = (screen_size.x - safe_area.end.x) if apply_to & 8 else 0

	# Dodaj extra marginesy i zastosuj minimum
	margin_top = maxi(margin_top + extra_margin_top, min_margin)
	margin_bottom = maxi(margin_bottom + extra_margin_bottom, min_margin)
	margin_left = maxi(margin_left + extra_margin_left, min_margin)
	margin_right = maxi(margin_right + extra_margin_right, min_margin)

	_apply_margins(margin_top, margin_bottom, margin_left, margin_right)


func _apply_margins(top: int, bottom: int, left: int, right: int) -> void:
	add_theme_constant_override("margin_top", top)
	add_theme_constant_override("margin_bottom", bottom)
	add_theme_constant_override("margin_left", left)
	add_theme_constant_override("margin_right", right)


## Wymusza ponowne obliczenie marginesów
func refresh_margins() -> void:
	_update_margins()
