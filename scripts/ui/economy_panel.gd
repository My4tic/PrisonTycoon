## EconomyPanel - Panel finansów
## Wyświetla szczegółowe informacje o finansach więzienia
class_name EconomyPanel
extends PanelContainer

# =============================================================================
# REFERENCJE DO WĘZŁÓW
# =============================================================================
@onready var capital_label: Label = $VBoxContainer/Header/CapitalLabel
@onready var balance_label: Label = $VBoxContainer/Header/BalanceLabel
@onready var trend_label: Label = $VBoxContainer/Header/TrendLabel

# Revenue section
@onready var revenue_total_label: Label = $VBoxContainer/RevenueSection/RevenueTotalLabel
@onready var subsidies_label: Label = $VBoxContainer/RevenueSection/Details/SubsidiesLabel
@onready var workshop_label: Label = $VBoxContainer/RevenueSection/Details/WorkshopLabel
@onready var contracts_label: Label = $VBoxContainer/RevenueSection/Details/ContractsLabel
@onready var bonuses_label: Label = $VBoxContainer/RevenueSection/Details/BonusesLabel

# Expenses section
@onready var expenses_total_label: Label = $VBoxContainer/ExpensesSection/ExpensesTotalLabel
@onready var salaries_label: Label = $VBoxContainer/ExpensesSection/Details/SalariesLabel
@onready var food_label: Label = $VBoxContainer/ExpensesSection/Details/FoodLabel
@onready var utilities_label: Label = $VBoxContainer/ExpensesSection/Details/UtilitiesLabel
@onready var construction_label: Label = $VBoxContainer/ExpensesSection/Details/ConstructionLabel
@onready var loan_label: Label = $VBoxContainer/ExpensesSection/Details/LoanLabel

# Loan section
@onready var loan_section: VBoxContainer = $VBoxContainer/LoanSection
@onready var loan_status_label: Label = $VBoxContainer/LoanSection/LoanStatusLabel
@onready var loan_button: Button = $VBoxContainer/LoanSection/LoanButton
@onready var repay_button: Button = $VBoxContainer/LoanSection/RepayButton

# Close button
@onready var close_button: Button = $VBoxContainer/CloseButton


# =============================================================================
# INICJALIZACJA
# =============================================================================
func _ready() -> void:
	_connect_signals()
	_update_display()
	visible = false


func _connect_signals() -> void:
	Signals.capital_changed.connect(_on_capital_changed)
	Signals.daily_balance_calculated.connect(_on_daily_balance)
	Signals.hour_changed.connect(_on_hour_changed)

	if close_button:
		close_button.pressed.connect(hide_panel)
	if loan_button:
		loan_button.pressed.connect(_on_loan_pressed)
	if repay_button:
		repay_button.pressed.connect(_on_repay_pressed)


# =============================================================================
# AKTUALIZACJA WYŚWIETLANIA
# =============================================================================
func _update_display() -> void:
	_update_capital()
	_update_revenue()
	_update_expenses()
	_update_loan_section()


func _update_capital() -> void:
	if capital_label:
		capital_label.text = "Kapitał: $%s" % _format_number(EconomyManager.capital)

		# Kolor zależny od stanu
		if EconomyManager.capital < 0:
			capital_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		elif EconomyManager.capital < 5000:
			capital_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
		else:
			capital_label.remove_theme_color_override("font_color")

	if balance_label:
		var predicted := EconomyManager.get_predicted_daily_balance()
		var prefix := "+" if predicted >= 0 else ""
		balance_label.text = "Bilans dzienny: %s$%s" % [prefix, _format_number(predicted)]

		if predicted < 0:
			balance_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		else:
			balance_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))

	if trend_label:
		var trend := EconomyManager.get_balance_trend()
		if trend > 0:
			trend_label.text = "📈 Trend rosnący"
			trend_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		elif trend < 0:
			trend_label.text = "📉 Trend spadkowy"
			trend_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		else:
			trend_label.text = "➡️ Stabilny"
			trend_label.remove_theme_color_override("font_color")


func _update_revenue() -> void:
	var rev := EconomyManager.daily_revenue

	if revenue_total_label:
		revenue_total_label.text = "Przychody: $%s/dzień" % _format_number(EconomyManager.get_total_daily_revenue())

	if subsidies_label:
		subsidies_label.text = "  Subwencje: $%s" % _format_number(rev.get("subsidies", 0))
	if workshop_label:
		workshop_label.text = "  Warsztaty: $%s" % _format_number(rev.get("workshop", 0))
	if contracts_label:
		contracts_label.text = "  Kontrakty: $%s" % _format_number(rev.get("contracts", 0))
	if bonuses_label:
		bonuses_label.text = "  Bonusy: $%s" % _format_number(rev.get("bonuses", 0))


func _update_expenses() -> void:
	var exp := EconomyManager.daily_expenses

	if expenses_total_label:
		expenses_total_label.text = "Wydatki: $%s/dzień" % _format_number(EconomyManager.get_total_daily_expenses())

	if salaries_label:
		salaries_label.text = "  Pensje: $%s" % _format_number(exp.get("salaries", 0))
	if food_label:
		food_label.text = "  Jedzenie: $%s" % _format_number(exp.get("food", 0))
	if utilities_label:
		utilities_label.text = "  Media: $%s" % _format_number(exp.get("utilities", 0))
	if construction_label:
		construction_label.text = "  Budowa: $%s" % _format_number(exp.get("construction", 0))
	if loan_label:
		loan_label.text = "  Odsetki: $%s" % _format_number(exp.get("loan_interest", 0))


func _update_loan_section() -> void:
	if not loan_section:
		return

	if EconomyManager.has_loan:
		loan_status_label.text = "Pożyczka: $%s (odsetki: $%s/dzień)" % [
			_format_number(EconomyManager.loan_amount),
			_format_number(EconomyManager.get_loan_daily_interest())
		]
		loan_button.visible = false
		repay_button.visible = true
		repay_button.disabled = not EconomyManager.can_afford(1000)
	else:
		loan_status_label.text = "Brak aktywnej pożyczki"
		loan_button.visible = true
		loan_button.disabled = not EconomyManager.can_take_loan()
		repay_button.visible = false


# =============================================================================
# FORMATOWANIE
# =============================================================================
func _format_number(value: int) -> String:
	var abs_value := absi(value)
	var str_value := str(abs_value)
	var result := ""
	var count := 0

	for i in range(str_value.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = str_value[i] + result
		count += 1

	if value < 0:
		result = "-" + result

	return result


# =============================================================================
# OBSŁUGA SYGNAŁÓW
# =============================================================================
func _on_capital_changed(_old: int, _new: int) -> void:
	_update_display()


func _on_daily_balance(_revenue: int, _expenses: int, _balance: int) -> void:
	_update_display()


func _on_hour_changed(_hour: int) -> void:
	if visible:
		_update_display()


func _on_loan_pressed() -> void:
	if EconomyManager.take_loan():
		_update_display()
		Signals.alert_triggered.emit(
			Enums.AlertPriority.INFO,
			"Pożyczka zaciągnięta",
			"Otrzymałeś $%s. Odsetki: 10%% miesięcznie." % _format_number(Constants.EMERGENCY_LOAN_AMOUNT),
			Vector2i.ZERO
		)


func _on_repay_pressed() -> void:
	# Spłać $1000 za każde kliknięcie
	var repay_amount := mini(1000, EconomyManager.loan_amount)
	if EconomyManager.repay_loan(repay_amount):
		_update_display()
		if not EconomyManager.has_loan:
			Signals.alert_triggered.emit(
				Enums.AlertPriority.POSITIVE,
				"Pożyczka spłacona",
				"Całkowicie spłaciłeś pożyczkę!",
				Vector2i.ZERO
			)


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
