## ObjectivesPanel - Panel celów rozdziału
## Wyświetla aktywne cele kampanii i postęp
class_name ObjectivesPanel
extends PanelContainer

# =============================================================================
# REFERENCJE DO WĘZŁÓW
# =============================================================================
@onready var title_label: Label = $VBoxContainer/TitleContainer/TitleLabel
@onready var chapter_label: Label = $VBoxContainer/ChapterLabel
@onready var objectives_container: VBoxContainer = $VBoxContainer/ObjectivesContainer
@onready var collapse_button: Button = $VBoxContainer/TitleContainer/CollapseButton

var _collapsed: bool = false
var _objective_labels: Dictionary = {}  # objective_id -> Label


# =============================================================================
# INICJALIZACJA
# =============================================================================
func _ready() -> void:
	_connect_signals()
	_update_display()
	visible = false


func _connect_signals() -> void:
	Signals.chapter_started.connect(_on_chapter_started)
	Signals.chapter_completed.connect(_on_chapter_completed)
	Signals.chapter_failed.connect(_on_chapter_failed)
	Signals.objective_completed.connect(_on_objective_completed)
	Signals.objective_progress_updated.connect(_on_objective_progress)

	if collapse_button:
		collapse_button.pressed.connect(_on_collapse_pressed)


# =============================================================================
# AKTUALIZACJA WYŚWIETLANIA
# =============================================================================
func _update_display() -> void:
	if not CampaignManager.is_in_campaign():
		visible = false
		return

	visible = true
	var chapter = CampaignManager.current_chapter

	if chapter_label and chapter:
		chapter_label.text = "Rozdział %d: %s" % [chapter.id + 1, chapter.title]

	_update_objectives()


func _update_objectives() -> void:
	# Wyczyść stare
	for child in objectives_container.get_children():
		child.queue_free()
	_objective_labels.clear()

	# Dodaj aktualne cele
	var objectives: Array = CampaignManager.get_active_objectives()
	for obj in objectives:
		if obj.is_hidden and not obj.is_completed:
			continue

		var obj_container := _create_objective_item(obj)
		objectives_container.add_child(obj_container)


func _create_objective_item(obj) -> HBoxContainer:
	var container := HBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Checkbox/ikona
	var status_label := Label.new()
	status_label.custom_minimum_size.x = 30
	if obj.is_completed:
		status_label.text = "✅"
	else:
		status_label.text = "⬜"
	container.add_child(status_label)

	# Opis i postęp
	var text_label := Label.new()
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.add_theme_font_size_override("font_size", 14)

	var progress_text := ""
	if not obj.is_completed and obj.target_value > 1:
		progress_text = " (%d/%d)" % [obj.current_value, obj.target_value]

	text_label.text = obj.description + progress_text

	if obj.is_completed:
		text_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))

	container.add_child(text_label)

	# Zapisz referencję do aktualizacji
	_objective_labels[obj.id] = text_label

	return container


func _update_objective_label(objective_id: int) -> void:
	var objectives: Array = CampaignManager.get_active_objectives()
	for obj in objectives:
		if obj.id == objective_id:
			if objective_id in _objective_labels:
				var label: Label = _objective_labels[objective_id]
				var progress_text := ""
				if not obj.is_completed and obj.target_value > 1:
					progress_text = " (%d/%d)" % [obj.current_value, obj.target_value]
				label.text = obj.description + progress_text

				if obj.is_completed:
					label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
			break


# =============================================================================
# OBSŁUGA SYGNAŁÓW
# =============================================================================
func _on_chapter_started(_chapter_id: int) -> void:
	_update_display()


func _on_chapter_completed(_chapter_id: int) -> void:
	# Pokaż komunikat sukcesu
	if chapter_label:
		chapter_label.text = "ROZDZIAŁ UKOŃCZONY!"
		chapter_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))


func _on_chapter_failed(_chapter_id: int, reason: String) -> void:
	if chapter_label:
		chapter_label.text = "PORAŻKA: " + reason
		chapter_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))


func _on_objective_completed(objective_id: int) -> void:
	# Pełna aktualizacja żeby pokazać checkmark
	_update_objectives()

	# Pokaż powiadomienie
	Signals.alert_triggered.emit(
		Enums.AlertPriority.POSITIVE,
		"Cel ukończony!",
		_get_objective_description(objective_id),
		Vector2i.ZERO
	)


func _on_objective_progress(objective_id: int, _current: int, _target: int) -> void:
	_update_objective_label(objective_id)


func _on_collapse_pressed() -> void:
	_collapsed = not _collapsed
	objectives_container.visible = not _collapsed
	if collapse_button:
		collapse_button.text = "▼" if _collapsed else "▲"


# =============================================================================
# POMOCNICZE
# =============================================================================
func _get_objective_description(objective_id: int) -> String:
	var objectives: Array = CampaignManager.get_active_objectives()
	for obj in objectives:
		if obj.id == objective_id:
			return obj.description
	return ""


# =============================================================================
# API PUBLICZNE
# =============================================================================
func show_panel() -> void:
	_update_display()
	visible = true


func hide_panel() -> void:
	visible = false
