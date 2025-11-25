## StaffPanel - Panel zarządzania personelem
## Wyświetla listę personelu i umożliwia zatrudnianie/zwalnianie
class_name StaffPanel
extends PanelContainer

# =============================================================================
# REFERENCJE DO WĘZŁÓW
# =============================================================================
@onready var type_dropdown: OptionButton = $VBoxContainer/HeaderRow/TypeDropdown
@onready var staff_count_label: Label = $VBoxContainer/Header/CountLabel
@onready var salary_label: Label = $VBoxContainer/Header/SalaryLabel
@onready var staff_list: VBoxContainer = $VBoxContainer/ScrollContainer/StaffList
@onready var hire_button: Button = $VBoxContainer/ButtonsRow/HireButton
@onready var close_button: Button = $VBoxContainer/CloseButton

# Aktualnie wyświetlany typ personelu
var current_type_filter: int = -1  # -1 = wszyscy


# =============================================================================
# INICJALIZACJA
# =============================================================================
func _ready() -> void:
	_connect_signals()
	_setup_type_dropdown()
	visible = false


func _connect_signals() -> void:
	Signals.staff_hired.connect(_on_staff_hired)
	Signals.staff_fired.connect(_on_staff_fired)

	if type_dropdown:
		type_dropdown.item_selected.connect(_on_type_selected)
	if hire_button:
		hire_button.pressed.connect(_on_hire_pressed)
	if close_button:
		close_button.pressed.connect(hide_panel)


func _setup_type_dropdown() -> void:
	if not type_dropdown:
		return

	type_dropdown.clear()
	type_dropdown.add_item("Wszyscy", -1)
	type_dropdown.add_item("Strażnicy", Enums.StaffType.GUARD)
	type_dropdown.add_item("Kucharze", Enums.StaffType.COOK)
	type_dropdown.add_item("Medycy", Enums.StaffType.MEDIC)
	type_dropdown.add_item("Psycholodzy", Enums.StaffType.PSYCHOLOGIST)
	type_dropdown.add_item("Sprzątacze", Enums.StaffType.JANITOR)


# =============================================================================
# AKTUALIZACJA WYŚWIETLANIA
# =============================================================================
func _update_display() -> void:
	_update_header()
	_update_staff_list()


func _update_header() -> void:
	var total := StaffManager.get_staff_count()
	var daily_cost := StaffManager.get_daily_salary_cost()

	if staff_count_label:
		staff_count_label.text = "Personel: %d" % total

	if salary_label:
		salary_label.text = "Koszty dzienne: $%d" % daily_cost


func _update_staff_list() -> void:
	if not staff_list:
		return

	# Wyczyść listę
	for child in staff_list.get_children():
		child.queue_free()

	# Pobierz personel
	var all_staff: Array = StaffManager.get_all_staff()

	for staff in all_staff:
		# Filtruj po typie
		if current_type_filter >= 0 and staff.staff_type != current_type_filter:
			continue

		_create_staff_row(staff)


func _create_staff_row(staff) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Kolor typu
	var color_rect := ColorRect.new()
	color_rect.custom_minimum_size = Vector2(8, 50)
	color_rect.color = Staff.STAFF_COLORS.get(staff.staff_type, Color.WHITE)
	row.add_child(color_rect)

	# Spacer
	var spacer1 := Control.new()
	spacer1.custom_minimum_size = Vector2(8, 0)
	row.add_child(spacer1)

	# Informacje
	var info_container := VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = "%s (#%d)" % [staff.staff_name, staff.staff_id]
	name_label.add_theme_font_size_override("font_size", 16)
	info_container.add_child(name_label)

	var details_label := Label.new()
	details_label.text = "%s | %s" % [staff.get_type_name(), staff.get_shift_name()]
	details_label.add_theme_font_size_override("font_size", 12)
	details_label.modulate = Color(0.7, 0.7, 0.7)
	info_container.add_child(details_label)

	# Status
	var status_row := HBoxContainer.new()
	var morale_label := Label.new()
	morale_label.text = "Morale: %.0f%%" % staff.morale
	morale_label.add_theme_font_size_override("font_size", 12)

	if staff.morale < 30:
		morale_label.modulate = Color(1.0, 0.3, 0.3)
	elif staff.morale < 60:
		morale_label.modulate = Color(1.0, 0.8, 0.3)
	else:
		morale_label.modulate = Color(0.3, 0.8, 0.3)

	status_row.add_child(morale_label)

	var duty_label := Label.new()
	duty_label.text = " | Na służbie" if staff.is_on_duty else " | Po służbie"
	duty_label.add_theme_font_size_override("font_size", 12)
	duty_label.modulate = Color(0.3, 0.8, 0.3) if staff.is_on_duty else Color(0.5, 0.5, 0.5)
	status_row.add_child(duty_label)

	info_container.add_child(status_row)
	row.add_child(info_container)

	# Przycisk zwolnienia
	var fire_btn := Button.new()
	fire_btn.text = "Zwolnij"
	fire_btn.custom_minimum_size = Vector2(80, 40)
	fire_btn.pressed.connect(_on_fire_pressed.bind(staff.staff_id))
	row.add_child(fire_btn)

	staff_list.add_child(row)


# =============================================================================
# POPUP ZATRUDNIANIA
# =============================================================================
func _on_hire_pressed() -> void:
	# Utwórz popup z dostępnymi typami personelu
	var popup := PopupMenu.new()
	popup.name = "HirePopup"

	# Pensje bazowe (z Constants)
	popup.add_item("Strażnik ($%d/dzień)" % Constants.STAFF_SALARIES[Enums.StaffType.GUARD], Enums.StaffType.GUARD)
	popup.add_item("Kucharz ($%d/dzień)" % Constants.STAFF_SALARIES[Enums.StaffType.COOK], Enums.StaffType.COOK)
	popup.add_item("Medyk ($%d/dzień)" % Constants.STAFF_SALARIES[Enums.StaffType.MEDIC], Enums.StaffType.MEDIC)
	popup.add_item("Psycholog ($%d/dzień)" % Constants.STAFF_SALARIES[Enums.StaffType.PSYCHOLOGIST], Enums.StaffType.PSYCHOLOGIST)
	popup.add_item("Sprzątacz ($%d/dzień)" % Constants.STAFF_SALARIES[Enums.StaffType.JANITOR], Enums.StaffType.JANITOR)

	popup.id_pressed.connect(_on_hire_type_selected)
	add_child(popup)

	var btn_rect := hire_button.get_global_rect()
	popup.position = Vector2i(int(btn_rect.position.x), int(btn_rect.end.y))
	popup.popup()


func _on_hire_type_selected(staff_type: int) -> void:
	# Pokaż wybór zmiany
	var popup := PopupMenu.new()
	popup.name = "ShiftPopup"

	popup.add_item("Zmiana poranna (06:00-14:00)", Enums.Shift.MORNING)
	popup.add_item("Zmiana popołudniowa (14:00-22:00)", Enums.Shift.AFTERNOON)
	popup.add_item("Zmiana nocna (22:00-06:00) +20%", Enums.Shift.NIGHT)

	popup.id_pressed.connect(_on_shift_selected.bind(staff_type))
	add_child(popup)

	var btn_rect := hire_button.get_global_rect()
	popup.position = Vector2i(int(btn_rect.position.x), int(btn_rect.end.y))
	popup.popup()


func _on_shift_selected(shift: int, staff_type: int) -> void:
	var staff_id := StaffManager.hire_staff(staff_type as Enums.StaffType, shift as Enums.Shift)
	if staff_id >= 0:
		_update_display()


func _on_fire_pressed(staff_id: int) -> void:
	StaffManager.fire_staff(staff_id)
	_update_display()


# =============================================================================
# OBSŁUGA SYGNAŁÓW
# =============================================================================
func _on_type_selected(index: int) -> void:
	current_type_filter = type_dropdown.get_item_id(index)
	_update_staff_list()


func _on_staff_hired(_staff_id: int, _staff_type: int) -> void:
	if visible:
		_update_display()


func _on_staff_fired(_staff_id: int, _staff_type: int) -> void:
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
