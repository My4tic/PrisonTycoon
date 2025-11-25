## AlertPanel - Panel alertów i powiadomień
## Wyświetla aktywne alerty z możliwością interakcji
class_name AlertPanel
extends PanelContainer

# =============================================================================
# REFERENCJE DO WĘZŁÓW
# =============================================================================
@onready var alerts_container: VBoxContainer = $VBoxContainer/ScrollContainer/AlertsContainer
@onready var alert_count_label: Label = $VBoxContainer/Header/CountLabel
@onready var clear_all_button: Button = $VBoxContainer/Header/ClearAllButton
@onready var filter_dropdown: OptionButton = $VBoxContainer/HeaderRow/FilterDropdown
@onready var close_button: Button = $VBoxContainer/CloseButton

# Aktualny filtr
var current_filter: int = -1  # -1 = wszystkie

# Kolory priorytetów
const PRIORITY_COLORS: Dictionary = {
	Enums.AlertPriority.CRITICAL: Color(0.9, 0.2, 0.2),     # Czerwony
	Enums.AlertPriority.IMPORTANT: Color(0.9, 0.6, 0.2),    # Pomarańczowy
	Enums.AlertPriority.INFO: Color(0.9, 0.9, 0.3),         # Żółty
	Enums.AlertPriority.POSITIVE: Color(0.3, 0.8, 0.3)      # Zielony
}


# =============================================================================
# INICJALIZACJA
# =============================================================================
func _ready() -> void:
	_connect_signals()
	_setup_filter_dropdown()
	visible = false


func _connect_signals() -> void:
	Signals.alert_triggered.connect(_on_alert_triggered)
	Signals.alert_dismissed.connect(_on_alert_dismissed)

	if clear_all_button:
		clear_all_button.pressed.connect(_on_clear_all_pressed)
	if filter_dropdown:
		filter_dropdown.item_selected.connect(_on_filter_selected)
	if close_button:
		close_button.pressed.connect(hide_panel)


func _setup_filter_dropdown() -> void:
	if not filter_dropdown:
		return

	filter_dropdown.clear()
	filter_dropdown.add_item("Wszystkie", -1)
	filter_dropdown.add_item("Krytyczne", Enums.AlertPriority.CRITICAL)
	filter_dropdown.add_item("Ważne", Enums.AlertPriority.IMPORTANT)
	filter_dropdown.add_item("Informacje", Enums.AlertPriority.INFO)
	filter_dropdown.add_item("Pozytywne", Enums.AlertPriority.POSITIVE)


# =============================================================================
# AKTUALIZACJA WYŚWIETLANIA
# =============================================================================
func _update_display() -> void:
	_update_header()
	_update_alerts_list()


func _update_header() -> void:
	var total: int = EventManager.get_alert_count()
	var critical: int = EventManager.get_critical_alert_count()

	if alert_count_label:
		if critical > 0:
			alert_count_label.text = "Alerty: %d (⚠️ %d krytycznych)" % [total, critical]
			alert_count_label.modulate = Color(1.0, 0.3, 0.3)
		else:
			alert_count_label.text = "Alerty: %d" % total
			alert_count_label.modulate = Color.WHITE


func _update_alerts_list() -> void:
	if not alerts_container:
		return

	# Wyczyść listę
	for child in alerts_container.get_children():
		child.queue_free()

	# Pobierz alerty
	var alerts: Array = EventManager.get_active_alerts()

	if alerts.is_empty():
		_show_no_alerts_message()
		return

	for alert in alerts:
		# Filtruj
		if current_filter >= 0 and alert.priority != current_filter:
			continue

		_create_alert_row(alert)


func _show_no_alerts_message() -> void:
	var label := Label.new()
	label.text = "Brak aktywnych alertów"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.modulate = Color(0.6, 0.6, 0.6)
	alerts_container.add_child(label)


func _create_alert_row(alert) -> void:
	var row := PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Stylizacja na podstawie priorytetu
	var style := StyleBoxFlat.new()
	var priority_color: Color = PRIORITY_COLORS.get(alert.priority, Color.WHITE)
	style.bg_color = Color(priority_color.r, priority_color.g, priority_color.b, 0.2)
	style.border_color = priority_color
	style.border_width_left = 4
	style.corner_radius_top_left = 4
	style.corner_radius_bottom_left = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	row.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()

	# Ikona priorytetu
	var icon_label := Label.new()
	icon_label.text = _get_priority_icon(alert.priority)
	icon_label.add_theme_font_size_override("font_size", 20)
	hbox.add_child(icon_label)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(8, 0)
	hbox.add_child(spacer)

	# Informacje
	var info_container := VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title_label := Label.new()
	title_label.text = alert.title
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", priority_color)
	info_container.add_child(title_label)

	var message_label := Label.new()
	message_label.text = alert.message
	message_label.add_theme_font_size_override("font_size", 12)
	message_label.modulate = Color(0.8, 0.8, 0.8)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_container.add_child(message_label)

	# Czas i lokalizacja
	var time_label := Label.new()
	var time_ago := _get_time_ago(alert.timestamp)
	var loc_str := ""
	if alert.location != Vector2i.ZERO:
		loc_str = " | Lokacja: (%d, %d)" % [alert.location.x, alert.location.y]
	time_label.text = time_ago + loc_str
	time_label.add_theme_font_size_override("font_size", 10)
	time_label.modulate = Color(0.5, 0.5, 0.5)
	info_container.add_child(time_label)

	hbox.add_child(info_container)

	# Przyciski akcji
	var buttons_container := VBoxContainer.new()

	# Przycisk "Pokaż"
	if alert.location != Vector2i.ZERO:
		var show_btn := Button.new()
		show_btn.text = "Pokaż"
		show_btn.custom_minimum_size = Vector2(70, 30)
		show_btn.pressed.connect(_on_show_location_pressed.bind(alert.location))
		buttons_container.add_child(show_btn)

	# Przycisk "Zamknij"
	var dismiss_btn := Button.new()
	dismiss_btn.text = "Zamknij"
	dismiss_btn.custom_minimum_size = Vector2(70, 30)
	dismiss_btn.pressed.connect(_on_dismiss_pressed.bind(alert.id))
	buttons_container.add_child(dismiss_btn)

	hbox.add_child(buttons_container)

	row.add_child(hbox)
	alerts_container.add_child(row)


func _get_priority_icon(priority: int) -> String:
	match priority:
		Enums.AlertPriority.CRITICAL:
			return "🔴"
		Enums.AlertPriority.IMPORTANT:
			return "🟠"
		Enums.AlertPriority.INFO:
			return "🟡"
		Enums.AlertPriority.POSITIVE:
			return "🟢"
		_:
			return "⚪"


func _get_time_ago(timestamp: float) -> String:
	var now := Time.get_unix_time_from_system()
	var diff := now - timestamp

	if diff < 60:
		return "Przed chwilą"
	elif diff < 3600:
		var minutes := int(diff / 60)
		return "%d min temu" % minutes
	elif diff < 86400:
		var hours := int(diff / 3600)
		return "%d godz. temu" % hours
	else:
		var days := int(diff / 86400)
		return "%d dni temu" % days


# =============================================================================
# OBSŁUGA PRZYCISKÓW
# =============================================================================
func _on_show_location_pressed(location: Vector2i) -> void:
	var world_pos := GridManager.grid_to_world(location)
	Signals.camera_focus_requested.emit(world_pos, 1.0)
	hide_panel()


func _on_dismiss_pressed(alert_id: int) -> void:
	EventManager.dismiss_alert(alert_id)


func _on_clear_all_pressed() -> void:
	EventManager.dismiss_all_alerts()
	_update_display()


func _on_filter_selected(index: int) -> void:
	current_filter = filter_dropdown.get_item_id(index)
	_update_alerts_list()


# =============================================================================
# OBSŁUGA SYGNAŁÓW
# =============================================================================
func _on_alert_triggered(_priority: int, _title: String, _message: String, _location: Vector2i) -> void:
	if visible:
		_update_display()

	# Pokaż panel automatycznie dla krytycznych alertów
	if _priority == Enums.AlertPriority.CRITICAL:
		show_panel()


func _on_alert_dismissed(_alert_id: int) -> void:
	if visible:
		_update_display()


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
