## ChapterSelect - Ekran wyboru rozdziału kampanii
## Wyświetla listę rozdziałów z ich statusami
class_name ChapterSelect
extends PanelContainer

# =============================================================================
# SYGNAŁY
# =============================================================================
signal chapter_selected(chapter_id: int)
signal back_pressed

# =============================================================================
# REFERENCJE DO WĘZŁÓW
# =============================================================================
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var chapters_container: VBoxContainer = $VBoxContainer/ScrollContainer/ChaptersContainer
@onready var back_button: Button = $VBoxContainer/BackButton

# Preload ikony statusów
const STATUS_ICONS := {
	"locked": "🔒",
	"available": "▶️",
	"in_progress": "⏳",
	"completed": "✅"
}

var _campaign_manager: Node = null


# =============================================================================
# INICJALIZACJA
# =============================================================================
func _ready() -> void:
	_campaign_manager = get_node_or_null("/root/CampaignManager")

	if back_button:
		back_button.pressed.connect(_on_back_pressed)

	call_deferred("_populate_chapters")
	visible = false


func _populate_chapters() -> void:
	# Wyczyść istniejące elementy
	for child in chapters_container.get_children():
		child.queue_free()

	if _campaign_manager == null:
		_campaign_manager = get_node_or_null("/root/CampaignManager")

	if _campaign_manager == null:
		return

	# Stwórz przycisk dla każdego rozdziału
	var chapters: Array = _campaign_manager.get_all_chapters()
	for chapter in chapters:
		var chapter_button := _create_chapter_button(chapter)
		chapters_container.add_child(chapter_button)


func _create_chapter_button(chapter) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 80)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Tekst z ikoną statusu
	var status_icon: String
	match chapter.status:
		Enums.ChapterStatus.LOCKED:
			status_icon = STATUS_ICONS.locked
			button.disabled = true
		Enums.ChapterStatus.AVAILABLE:
			status_icon = STATUS_ICONS.available
		Enums.ChapterStatus.IN_PROGRESS:
			status_icon = STATUS_ICONS.in_progress
		Enums.ChapterStatus.COMPLETED:
			status_icon = STATUS_ICONS.completed

	button.text = "%s Rozdział %d: %s\n%s" % [
		status_icon,
		chapter.id + 1,
		chapter.title,
		chapter.description
	]

	# Styl
	button.add_theme_font_size_override("font_size", 16)

	# Podłącz sygnał
	button.pressed.connect(_on_chapter_button_pressed.bind(chapter.id))

	return button


# =============================================================================
# OBSŁUGA SYGNAŁÓW
# =============================================================================
func _on_chapter_button_pressed(chapter_id: int) -> void:
	chapter_selected.emit(chapter_id)


func _on_back_pressed() -> void:
	back_pressed.emit()
	hide_panel()


# =============================================================================
# API PUBLICZNE
# =============================================================================
func show_panel() -> void:
	_populate_chapters()  # Odśwież listę
	visible = true


func hide_panel() -> void:
	visible = false


func toggle_panel() -> void:
	if visible:
		hide_panel()
	else:
		show_panel()
