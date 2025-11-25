## SchedulePanel - Panel harmonogramów dla więźniów
## Wyświetla i pozwala edytować harmonogramy dla każdej kategorii
class_name SchedulePanel
extends PanelContainer

# =============================================================================
# REFERENCJE DO WĘZŁÓW
# =============================================================================
@onready var category_dropdown: OptionButton = $VBoxContainer/HeaderRow/CategoryDropdown
@onready var lockdown_button: Button = $VBoxContainer/HeaderRow/LockdownButton
@onready var schedule_grid: GridContainer = $VBoxContainer/ScrollContainer/ScheduleGrid
@onready var reset_button: Button = $VBoxContainer/ButtonsRow/ResetButton
@onready var copy_button: Button = $VBoxContainer/ButtonsRow/CopyButton
@onready var close_button: Button = $VBoxContainer/CloseButton

# Wyświetlana kategoria
var current_category: Enums.SecurityCategory = Enums.SecurityCategory.LOW

# Słownik przycisków aktywności dla każdej godziny
var hour_buttons: Dictionary = {}  # hour -> Button


# =============================================================================
# INICJALIZACJA
# =============================================================================
func _ready() -> void:
	_connect_signals()
	_setup_category_dropdown()
	_build_schedule_grid()
	visible = false


func _connect_signals() -> void:
	Signals.schedule_activity_changed.connect(_on_schedule_activity_changed)
	Signals.lockdown_started.connect(_on_lockdown_started)
	Signals.lockdown_ended.connect(_on_lockdown_ended)

	if category_dropdown:
		category_dropdown.item_selected.connect(_on_category_selected)
	if lockdown_button:
		lockdown_button.pressed.connect(_on_lockdown_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	if copy_button:
		copy_button.pressed.connect(_on_copy_pressed)
	if close_button:
		close_button.pressed.connect(hide_panel)


func _setup_category_dropdown() -> void:
	if not category_dropdown:
		return

	category_dropdown.clear()
	category_dropdown.add_item("Niskie zagrożenie", Enums.SecurityCategory.LOW)
	category_dropdown.add_item("Średnie zagrożenie", Enums.SecurityCategory.MEDIUM)
	category_dropdown.add_item("Wysokie zagrożenie", Enums.SecurityCategory.HIGH)
	category_dropdown.add_item("Maksymalne", Enums.SecurityCategory.MAXIMUM)


# =============================================================================
# BUDOWANIE SIATKI HARMONOGRAMU
# =============================================================================
func _build_schedule_grid() -> void:
	if not schedule_grid:
		return

	# Wyczyść istniejące
	for child in schedule_grid.get_children():
		child.queue_free()
	hour_buttons.clear()

	# Nagłówki kolumn
	var header_hour := Label.new()
	header_hour.text = "Godz."
	header_hour.add_theme_font_size_override("font_size", 14)
	header_hour.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	schedule_grid.add_child(header_hour)

	var header_activity := Label.new()
	header_activity.text = "Aktywność"
	header_activity.add_theme_font_size_override("font_size", 14)
	header_activity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_activity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	schedule_grid.add_child(header_activity)

	# Wiersze dla każdej godziny
	for hour in range(24):
		_create_hour_row(hour)

	_update_schedule_display()


func _create_hour_row(hour: int) -> void:
	# Label godziny
	var hour_label := Label.new()
	hour_label.text = "%02d:00" % hour
	hour_label.add_theme_font_size_override("font_size", 14)
	hour_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hour_label.custom_minimum_size = Vector2(60, 36)
	schedule_grid.add_child(hour_label)

	# Przycisk aktywności (dropdown-like)
	var activity_btn := Button.new()
	activity_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	activity_btn.custom_minimum_size = Vector2(0, 36)
	activity_btn.add_theme_font_size_override("font_size", 14)
	activity_btn.pressed.connect(_on_activity_button_pressed.bind(hour))
	schedule_grid.add_child(activity_btn)

	hour_buttons[hour] = activity_btn


func _update_schedule_display() -> void:
	var schedule_data := ScheduleManager.get_schedule_for_display(current_category)

	for item in schedule_data:
		var hour: int = item["hour"]
		var activity: Enums.ScheduleActivity = item["activity"]
		var activity_name: String = item["activity_name"]

		if hour_buttons.has(hour):
			var btn: Button = hour_buttons[hour]
			btn.text = activity_name
			btn.modulate = _get_activity_color(activity)

	# Update lockdown button
	_update_lockdown_button()


func _get_activity_color(activity: Enums.ScheduleActivity) -> Color:
	match activity:
		Enums.ScheduleActivity.SLEEP:
			return Color(0.4, 0.4, 0.6)  # niebieski/fioletowy
		Enums.ScheduleActivity.EATING:
			return Color(0.6, 0.5, 0.3)  # brązowy
		Enums.ScheduleActivity.HYGIENE:
			return Color(0.4, 0.6, 0.8)  # jasnoniebieski
		Enums.ScheduleActivity.WORK:
			return Color(0.7, 0.5, 0.2)  # pomarańczowy
		Enums.ScheduleActivity.RECREATION:
			return Color(0.4, 0.7, 0.4)  # zielony
		Enums.ScheduleActivity.FREE_TIME:
			return Color(0.8, 0.8, 0.8)  # szary
		Enums.ScheduleActivity.LOCKDOWN:
			return Color(0.8, 0.3, 0.3)  # czerwony
		_:
			return Color.WHITE


func _update_lockdown_button() -> void:
	if not lockdown_button:
		return

	if ScheduleManager.is_lockdown:
		lockdown_button.text = "Zakończ lockdown"
		lockdown_button.modulate = Color(0.3, 0.8, 0.3)
	else:
		lockdown_button.text = "Ogłoś lockdown"
		lockdown_button.modulate = Color(0.8, 0.3, 0.3)


# =============================================================================
# POPUP WYBORU AKTYWNOŚCI
# =============================================================================
func _on_activity_button_pressed(hour: int) -> void:
	# Utwórz popup z dostępnymi aktywnościami
	var popup := PopupMenu.new()
	popup.name = "ActivityPopup"

	popup.add_item("Sen", Enums.ScheduleActivity.SLEEP)
	popup.add_item("Posiłek", Enums.ScheduleActivity.EATING)
	popup.add_item("Higiena", Enums.ScheduleActivity.HYGIENE)
	popup.add_item("Praca", Enums.ScheduleActivity.WORK)
	popup.add_item("Rekreacja", Enums.ScheduleActivity.RECREATION)
	popup.add_item("Czas wolny", Enums.ScheduleActivity.FREE_TIME)
	popup.add_item("Lockdown", Enums.ScheduleActivity.LOCKDOWN)

	popup.id_pressed.connect(_on_activity_selected.bind(hour))

	add_child(popup)

	# Pozycja popup przy przycisku
	var btn: Button = hour_buttons[hour]
	var btn_rect := btn.get_global_rect()
	popup.position = Vector2i(int(btn_rect.position.x), int(btn_rect.end.y))
	popup.popup()


func _on_activity_selected(activity_id: int, hour: int) -> void:
	var activity := activity_id as Enums.ScheduleActivity
	ScheduleManager.set_activity(current_category, hour, activity)
	_update_schedule_display()


# =============================================================================
# OBSŁUGA SYGNAŁÓW
# =============================================================================
func _on_category_selected(index: int) -> void:
	current_category = category_dropdown.get_item_id(index) as Enums.SecurityCategory
	_update_schedule_display()


func _on_lockdown_pressed() -> void:
	ScheduleManager.toggle_lockdown()


func _on_reset_pressed() -> void:
	ScheduleManager.reset_schedule(current_category)
	_update_schedule_display()


func _on_copy_pressed() -> void:
	# Kopiuj harmonogram do innych kategorii
	var popup := PopupMenu.new()
	popup.name = "CopyPopup"

	for category in Enums.SecurityCategory.values():
		if category != current_category:
			var name: String = _get_category_name(category)
			popup.add_item("Kopiuj do: " + name, category)

	popup.id_pressed.connect(_on_copy_target_selected)
	add_child(popup)

	var btn_rect := copy_button.get_global_rect()
	popup.position = Vector2i(int(btn_rect.position.x), int(btn_rect.end.y))
	popup.popup()


func _on_copy_target_selected(target_category: int) -> void:
	ScheduleManager.copy_schedule(current_category, target_category as Enums.SecurityCategory)


func _get_category_name(category: Enums.SecurityCategory) -> String:
	match category:
		Enums.SecurityCategory.LOW:
			return "Niskie"
		Enums.SecurityCategory.MEDIUM:
			return "Średnie"
		Enums.SecurityCategory.HIGH:
			return "Wysokie"
		Enums.SecurityCategory.MAXIMUM:
			return "Maksymalne"
		_:
			return "Nieznane"


func _on_schedule_activity_changed(_category: int, _hour: int, _activity: int) -> void:
	if visible and _category == current_category:
		_update_schedule_display()


func _on_lockdown_started(_reason: String) -> void:
	_update_lockdown_button()
	if visible:
		_update_schedule_display()


func _on_lockdown_ended() -> void:
	_update_lockdown_button()
	if visible:
		_update_schedule_display()


# =============================================================================
# API PUBLICZNE
# =============================================================================
func show_panel() -> void:
	_update_schedule_display()
	visible = true


func hide_panel() -> void:
	visible = false


func toggle_panel() -> void:
	if visible:
		hide_panel()
	else:
		show_panel()
