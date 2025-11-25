## PrisonersPanel - Panel zarządzania więźniami
## Wyświetla listę więźniów i umożliwia spawnowanie nowych
class_name PrisonersPanel
extends PanelContainer

# =============================================================================
# REFERENCJE DO WĘZŁÓW
# =============================================================================
@onready var count_label: Label = $VBoxContainer/Header/CountLabel
@onready var mood_label: Label = $VBoxContainer/Header/MoodLabel
@onready var category_filter: OptionButton = $VBoxContainer/FilterRow/CategoryFilter
@onready var prisoners_list: VBoxContainer = $VBoxContainer/ScrollContainer/PrisonersList
@onready var spawn_button: Button = $VBoxContainer/ButtonsRow/SpawnButton
@onready var close_button: Button = $VBoxContainer/CloseButton

# Wybrany więzień
var selected_prisoner_id: int = -1


# =============================================================================
# INICJALIZACJA
# =============================================================================
func _ready() -> void:
	_connect_signals()
	_setup_category_filter()
	visible = false


func _connect_signals() -> void:
	Signals.prisoner_arrived.connect(_on_prisoner_arrived)
	Signals.prisoner_released.connect(_on_prisoner_removed)
	Signals.prisoner_escaped.connect(_on_prisoner_removed)
	Signals.prisoner_died.connect(_on_prisoner_removed)

	if spawn_button:
		spawn_button.pressed.connect(_on_spawn_pressed)
	if close_button:
		close_button.pressed.connect(hide_panel)
	if category_filter:
		category_filter.item_selected.connect(_on_filter_changed)


func _setup_category_filter() -> void:
	if not category_filter:
		return

	category_filter.clear()
	category_filter.add_item("Wszyscy", -1)
	category_filter.add_item("Niskie zagrożenie", Enums.SecurityCategory.LOW)
	category_filter.add_item("Średnie zagrożenie", Enums.SecurityCategory.MEDIUM)
	category_filter.add_item("Wysokie zagrożenie", Enums.SecurityCategory.HIGH)
	category_filter.add_item("Maksymalne", Enums.SecurityCategory.MAXIMUM)


# =============================================================================
# AKTUALIZACJA WYŚWIETLANIA
# =============================================================================
func _update_display() -> void:
	_update_header()
	_update_prisoners_list()


func _update_header() -> void:
	var total := PrisonerManager.get_prisoner_count()
	var capacity := _get_total_capacity()

	if count_label:
		count_label.text = "Więźniowie: %d/%d" % [total, capacity]

	if mood_label:
		var avg_mood := PrisonerManager.get_average_mood()
		mood_label.text = "Średni nastrój: %.0f%%" % avg_mood

		if avg_mood < 30:
			mood_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		elif avg_mood < 60:
			mood_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
		else:
			mood_label.remove_theme_color_override("font_color")


func _update_prisoners_list() -> void:
	if not prisoners_list:
		return

	# Wyczyść listę
	for child in prisoners_list.get_children():
		child.queue_free()

	# Pobierz filtr kategorii
	var filter_category: int = -1
	if category_filter and category_filter.selected >= 0:
		filter_category = category_filter.get_item_id(category_filter.selected)

	# Pobierz więźniów
	var prisoners: Array = PrisonerManager.get_all_prisoners()

	for prisoner in prisoners:
		# Filtruj po kategorii
		if filter_category >= 0 and prisoner.security_category != filter_category:
			continue

		_create_prisoner_row(prisoner)


func _create_prisoner_row(prisoner) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Kolor kategorii
	var color_rect := ColorRect.new()
	color_rect.custom_minimum_size = Vector2(8, 40)
	color_rect.color = _get_category_color(prisoner.security_category)
	row.add_child(color_rect)

	# Spacer
	var spacer1 := Control.new()
	spacer1.custom_minimum_size = Vector2(8, 0)
	row.add_child(spacer1)

	# Informacje
	var info_container := VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = "%s (#%d)" % [prisoner.prisoner_name, prisoner.prisoner_id]
	name_label.add_theme_font_size_override("font_size", 16)
	info_container.add_child(name_label)

	var details_label := Label.new()
	details_label.text = "%s | Nastrój: %.0f%%" % [
		prisoner.get_mood_description(),
		prisoner.get_mood()
	]
	details_label.add_theme_font_size_override("font_size", 12)
	details_label.modulate = Color(0.7, 0.7, 0.7)
	info_container.add_child(details_label)

	row.add_child(info_container)

	# Przycisk szczegółów
	var details_btn := Button.new()
	details_btn.text = "📋"
	details_btn.custom_minimum_size = Vector2(48, 40)
	details_btn.pressed.connect(_on_prisoner_details_pressed.bind(prisoner.prisoner_id))
	row.add_child(details_btn)

	prisoners_list.add_child(row)


func _get_category_color(category: Enums.SecurityCategory) -> Color:
	match category:
		Enums.SecurityCategory.LOW:
			return Color(0.3, 0.5, 0.9)
		Enums.SecurityCategory.MEDIUM:
			return Color(0.9, 0.6, 0.2)
		Enums.SecurityCategory.HIGH:
			return Color(0.9, 0.3, 0.3)
		Enums.SecurityCategory.MAXIMUM:
			return Color(0.2, 0.2, 0.2)
		_:
			return Color.WHITE


func _get_total_capacity() -> int:
	var capacity: int = 0
	var cell_types: Array = [
		Enums.BuildingType.CELL_SINGLE,
		Enums.BuildingType.CELL_DOUBLE,
		Enums.BuildingType.DORMITORY
	]

	for cell_type in cell_types:
		capacity += BuildingManager.get_total_capacity(cell_type)

	return capacity


# =============================================================================
# OBSŁUGA SYGNAŁÓW
# =============================================================================
func _on_prisoner_arrived(_prisoner_id: int, _category: int) -> void:
	if visible:
		_update_display()


func _on_prisoner_removed(_prisoner_id: int, _extra = null) -> void:
	if visible:
		_update_display()


func _on_spawn_pressed() -> void:
	# Sprawdź czy jest miejsce
	var total := PrisonerManager.get_prisoner_count()
	var capacity := _get_total_capacity()

	if total >= capacity:
		Signals.alert_triggered.emit(
			Enums.AlertPriority.IMPORTANT,
			"Brak miejsca",
			"Nie ma wolnych cel dla nowych więźniów!",
			Vector2i.ZERO
		)
		return

	# Spawn losowego więźnia
	var prisoner_id := PrisonerManager.spawn_prisoner()
	if prisoner_id >= 0:
		_update_display()


func _on_filter_changed(_index: int) -> void:
	_update_display()


func _on_prisoner_details_pressed(prisoner_id: int) -> void:
	# TODO: Otwórz szczegółowy panel więźnia
	selected_prisoner_id = prisoner_id
	var prisoner = PrisonerManager.get_prisoner(prisoner_id)
	if prisoner:
		# Na razie pokaż informacje w konsoli
		print("=== Więzień #%d ===" % prisoner_id)
		print("Imię: %s" % prisoner.prisoner_name)
		print("Wiek: %d" % prisoner.age)
		print("Kategoria: %s" % Enums.SecurityCategory.keys()[prisoner.security_category])
		print("Wyrok: %d dni (odsiedział: %d)" % [prisoner.sentence_days, prisoner.days_served])
		print("Nastrój: %.1f%%" % prisoner.get_mood())
		print("Zdrowie: %.1f%%" % prisoner.health)
		print("Potrzeby:")
		for need_type in prisoner.needs.keys():
			print("  - %s: %.1f%%" % [Enums.PrisonerNeed.keys()[need_type], prisoner.needs[need_type]])


# =============================================================================
# API PUBLICZNE
# =============================================================================
func show_panel() -> void:
	_update_display()
	visible = true


func hide_panel() -> void:
	visible = false


func toggle_panel() -> void:
	if visible:
		hide_panel()
	else:
		show_panel()
