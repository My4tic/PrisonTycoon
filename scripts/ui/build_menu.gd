## BuildMenu - Panel wyboru budynków
## Wyświetla kategorie i dostępne budynki do umieszczenia
class_name BuildMenu
extends PanelContainer

# =============================================================================
# SYGNAŁY
# =============================================================================
signal building_selected(building_type: Enums.BuildingType)
signal menu_closed()

# =============================================================================
# ZMIENNE
# =============================================================================
var selected_category: Enums.BuildingCategory = Enums.BuildingCategory.CELLS
var selected_building: Enums.BuildingType = Enums.BuildingType.CELL_SINGLE

# Mapowanie kategorii na ikony
const CATEGORY_ICONS: Dictionary = {
	Enums.BuildingCategory.CELLS: "🛏",
	Enums.BuildingCategory.FOOD: "🍽",
	Enums.BuildingCategory.RECREATION: "⚽",
	Enums.BuildingCategory.WORK: "🔨",
	Enums.BuildingCategory.INFRASTRUCTURE: "⚡",
	Enums.BuildingCategory.SECURITY: "🔒"
}

const CATEGORY_NAMES: Dictionary = {
	Enums.BuildingCategory.CELLS: "Cele",
	Enums.BuildingCategory.FOOD: "Wyżywienie",
	Enums.BuildingCategory.RECREATION: "Rekreacja",
	Enums.BuildingCategory.WORK: "Praca",
	Enums.BuildingCategory.INFRASTRUCTURE: "Infrastruktura",
	Enums.BuildingCategory.SECURITY: "Bezpieczeństwo"
}

# Referencje do węzłów
@onready var category_container: HBoxContainer = $VBoxContainer/CategoryTabs
@onready var buildings_container: GridContainer = $VBoxContainer/ScrollContainer/BuildingsGrid
@onready var info_panel: PanelContainer = $VBoxContainer/InfoPanel
@onready var info_name: Label = $VBoxContainer/InfoPanel/VBoxContainer/NameLabel
@onready var info_cost: Label = $VBoxContainer/InfoPanel/VBoxContainer/CostLabel
@onready var info_size: Label = $VBoxContainer/InfoPanel/VBoxContainer/SizeLabel
@onready var info_desc: Label = $VBoxContainer/InfoPanel/VBoxContainer/DescLabel
@onready var place_button: Button = $VBoxContainer/ButtonsContainer/PlaceButton
@onready var close_button: Button = $VBoxContainer/ButtonsContainer/CloseButton

# Cache przycisków kategorii
var _category_buttons: Dictionary = {}  # Enums.BuildingCategory -> Button


# =============================================================================
# INICJALIZACJA
# =============================================================================
func _ready() -> void:
	_create_category_tabs()
	_populate_buildings()
	_connect_signals()
	_select_category(Enums.BuildingCategory.CELLS)


func _connect_signals() -> void:
	place_button.pressed.connect(_on_place_pressed)
	close_button.pressed.connect(_on_close_pressed)


# =============================================================================
# TWORZENIE UI
# =============================================================================
func _create_category_tabs() -> void:
	# Wyczyść istniejące
	for child in category_container.get_children():
		child.queue_free()

	# Utwórz przyciski kategorii
	for category in Enums.BuildingCategory.values():
		var btn := Button.new()
		btn.text = CATEGORY_ICONS.get(category, "?")
		btn.tooltip_text = CATEGORY_NAMES.get(category, "")
		btn.custom_minimum_size = Vector2(64, 48)
		btn.toggle_mode = true
		btn.button_group = _get_or_create_category_group()
		btn.pressed.connect(_on_category_pressed.bind(category))

		category_container.add_child(btn)
		_category_buttons[category] = btn


func _get_or_create_category_group() -> ButtonGroup:
	if category_container.get_child_count() > 0:
		var first_btn: Button = category_container.get_child(0) as Button
		if first_btn and first_btn.button_group:
			return first_btn.button_group

	return ButtonGroup.new()


func _populate_buildings() -> void:
	# Wyczyść istniejące
	for child in buildings_container.get_children():
		child.queue_free()

	# Pobierz budynki z wybranej kategorii
	var category_name: String = Enums.BuildingCategory.keys()[selected_category]

	for type_value in Enums.BuildingType.values():
		var type_name: String = Enums.BuildingType.keys()[type_value]
		var info: Dictionary = BuildingManager.building_catalog.get(type_name, {})

		if info.is_empty():
			continue

		if info.get("category", "") != category_name:
			continue

		_create_building_button(type_value, info)


func _create_building_button(building_type: Enums.BuildingType, info: Dictionary) -> void:
	var btn := Button.new()
	var name_text: String = info.get("name", "Budynek")
	var cost: int = info.get("cost", 0)
	var unlocked: bool = info.get("unlocked", true)

	btn.text = "%s\n$%d" % [name_text, cost]
	btn.custom_minimum_size = Vector2(140, 80)
	btn.disabled = not unlocked

	if not unlocked:
		btn.tooltip_text = "Zablokowany"
		btn.modulate = Color(0.5, 0.5, 0.5)

	btn.pressed.connect(_on_building_pressed.bind(building_type))
	buildings_container.add_child(btn)


# =============================================================================
# SELEKCJA
# =============================================================================
func _select_category(category: Enums.BuildingCategory) -> void:
	selected_category = category

	# Zaznacz przycisk kategorii
	if _category_buttons.has(category):
		_category_buttons[category].button_pressed = true

	# Odśwież listę budynków
	_populate_buildings()


func _select_building(building_type: Enums.BuildingType) -> void:
	selected_building = building_type
	_update_info_panel()


func _update_info_panel() -> void:
	var info: Dictionary = BuildingManager.get_building_info(selected_building)

	if info.is_empty():
		info_panel.visible = false
		return

	info_panel.visible = true
	info_name.text = info.get("name", "Budynek")
	info_cost.text = "Koszt: $%d" % info.get("cost", 0)

	var size: Array = info.get("size", [1, 1])
	info_size.text = "Rozmiar: %dx%d" % [size[0], size[1]]

	info_desc.text = info.get("description", "")

	# Sprawdź czy można sobie pozwolić
	var cost: int = info.get("cost", 0)
	var can_afford: bool = EconomyManager.can_afford(cost)
	place_button.disabled = not can_afford

	if not can_afford:
		info_cost.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	else:
		info_cost.remove_theme_color_override("font_color")


# =============================================================================
# OBSŁUGA SYGNAŁÓW
# =============================================================================
func _on_category_pressed(category: Enums.BuildingCategory) -> void:
	_select_category(category)


func _on_building_pressed(building_type: Enums.BuildingType) -> void:
	_select_building(building_type)
	building_selected.emit(building_type)


func _on_place_pressed() -> void:
	building_selected.emit(selected_building)


func _on_close_pressed() -> void:
	menu_closed.emit()


# =============================================================================
# API PUBLICZNE
# =============================================================================
func show_menu() -> void:
	visible = true
	_update_info_panel()


func hide_menu() -> void:
	visible = false


func get_selected_building() -> Enums.BuildingType:
	return selected_building
