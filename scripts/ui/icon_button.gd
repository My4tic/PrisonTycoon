## IconButton - Przycisk z ikoną i opcjonalną etykietą
## Zoptymalizowany pod mobile z badge'em powiadomień
class_name IconButton
extends Button

## Tekst ikony (emoji lub pojedynczy znak)
@export var icon_text: String = ""

## Etykieta pod ikoną
@export var label_text: String = ""

## Wartość badge'a (0 = ukryty)
@export var badge_value: int = 0:
	set(value):
		badge_value = value
		_update_badge()

## Kolor badge'a
@export var badge_color: Color = Color(0.9, 0.2, 0.2, 1)

## Minimalny rozmiar dotykowy
@export var min_touch_size: Vector2 = Vector2(64, 64)

var _badge_label: Label


func _ready() -> void:
	custom_minimum_size = min_touch_size
	_setup_content()
	_update_badge()


func _setup_content() -> void:
	# Ustaw tekst przycisku
	if icon_text != "" and label_text != "":
		text = icon_text + "\n" + label_text
	elif icon_text != "":
		text = icon_text
	else:
		text = label_text

	# Utwórz badge jeśli nie istnieje
	if _badge_label == null:
		_badge_label = Label.new()
		_badge_label.name = "Badge"
		_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_badge_label.add_theme_font_size_override("font_size", 14)
		_badge_label.add_theme_color_override("font_color", Color.WHITE)
		add_child(_badge_label)


func _update_badge() -> void:
	if _badge_label == null:
		return

	if badge_value <= 0:
		_badge_label.visible = false
		return

	_badge_label.visible = true
	_badge_label.text = str(badge_value) if badge_value < 100 else "99+"

	# Pozycjonuj badge w prawym górnym rogu
	await get_tree().process_frame
	var badge_size: Vector2 = Vector2(24, 20)
	_badge_label.position = Vector2(size.x - badge_size.x - 4, 4)
	_badge_label.size = badge_size


func _draw() -> void:
	# Rysuj tło badge'a
	if _badge_label != null and _badge_label.visible:
		var badge_rect: Rect2 = Rect2(_badge_label.position - Vector2(4, 2), _badge_label.size + Vector2(8, 4))
		draw_rect(badge_rect, badge_color, true)


func set_badge(value: int) -> void:
	badge_value = value
