## EconomyManager - System ekonomiczny
## Autoload singleton dostępny jako EconomyManager
##
## Odpowiada za:
## - Zarządzanie kapitałem
## - Tracking przychodów i wydatków
## - Obliczanie dziennego bilansu
## - Obsługa bankructwa i pożyczek
## - Automatyczne naliczanie co godzinę in-game
extends Node

# =============================================================================
# ZMIENNE
# =============================================================================
var capital: int = Constants.STARTING_CAPITAL

# Liczniki dla symulacji (tymczasowe, dopóki nie ma PrisonerManager/StaffManager)
var prisoner_count: int = 0
var prisoners_by_category: Dictionary = {
	Enums.SecurityCategory.LOW: 0,
	Enums.SecurityCategory.MEDIUM: 0,
	Enums.SecurityCategory.HIGH: 0,
	Enums.SecurityCategory.MAXIMUM: 0
}
var staff_counts: Dictionary = {
	Enums.StaffType.GUARD: 0,
	Enums.StaffType.COOK: 0,
	Enums.StaffType.MEDIC: 0,
	Enums.StaffType.PSYCHOLOGIST: 0,
	Enums.StaffType.JANITOR: 0,
	Enums.StaffType.PRIEST: 0
}

# Flaga lockdownu (tray service = droższe jedzenie)
var is_lockdown: bool = false

# Śledzenie przychodów (dzienny)
var daily_revenue: Dictionary = {
	"subsidies": 0,      # Subwencje za więźniów
	"workshop": 0,       # Przychód z warsztatów
	"contracts": 0,      # Kontrakty rządowe
	"bonuses": 0         # Bonusy za bezpieczeństwo
}

# Śledzenie wydatków (dzienny)
var daily_expenses: Dictionary = {
	"salaries": 0,       # Pensje personelu
	"food": 0,           # Jedzenie
	"utilities": 0,      # Media
	"construction": 0,   # Budowa
	"repairs": 0,        # Naprawy
	"loan_interest": 0   # Odsetki od pożyczki
}

# Historia (ostatnie 30 dni)
var balance_history: Array[int] = []
const MAX_HISTORY_DAYS: int = 30

# Pożyczka
var has_loan: bool = false
var loan_amount: int = 0
var days_in_debt: int = 0

# =============================================================================
# FUNKCJE GODOT
# =============================================================================
func _ready() -> void:
	Signals.day_changed.connect(_on_day_changed)
	Signals.hour_changed.connect(_on_hour_changed)


# =============================================================================
# ZARZĄDZANIE KAPITAŁEM
# =============================================================================
func add_capital(amount: int, category: String = "") -> void:
	var old_capital := capital
	capital += amount

	if category != "" and daily_revenue.has(category):
		daily_revenue[category] += amount

	Signals.capital_changed.emit(old_capital, capital)


func subtract_capital(amount: int, category: String = "") -> bool:
	if capital < amount:
		return false  # Nie stać

	var old_capital := capital
	capital -= amount

	if category != "" and daily_expenses.has(category):
		daily_expenses[category] += amount

	Signals.capital_changed.emit(old_capital, capital)
	return true


func can_afford(amount: int) -> bool:
	return capital >= amount


func get_capital() -> int:
	return capital


# =============================================================================
# SUBWENCJE
# =============================================================================
func calculate_daily_subsidies(prisoners_by_category: Dictionary) -> int:
	var total: int = 0

	if prisoners_by_category.has(Enums.SecurityCategory.LOW):
		total += prisoners_by_category[Enums.SecurityCategory.LOW] * Constants.SUBSIDY_LOW_SECURITY
	if prisoners_by_category.has(Enums.SecurityCategory.MEDIUM):
		total += prisoners_by_category[Enums.SecurityCategory.MEDIUM] * Constants.SUBSIDY_MEDIUM_SECURITY
	if prisoners_by_category.has(Enums.SecurityCategory.HIGH):
		total += prisoners_by_category[Enums.SecurityCategory.HIGH] * Constants.SUBSIDY_HIGH_SECURITY
	if prisoners_by_category.has(Enums.SecurityCategory.MAXIMUM):
		total += prisoners_by_category[Enums.SecurityCategory.MAXIMUM] * Constants.SUBSIDY_MAXIMUM_SECURITY

	return total


# =============================================================================
# WYDATKI DZIENNE
# =============================================================================
func calculate_daily_salaries(staff_counts: Dictionary) -> int:
	var total: int = 0

	if staff_counts.has(Enums.StaffType.GUARD):
		total += staff_counts[Enums.StaffType.GUARD] * Constants.SALARY_GUARD
	if staff_counts.has(Enums.StaffType.COOK):
		total += staff_counts[Enums.StaffType.COOK] * Constants.SALARY_COOK
	if staff_counts.has(Enums.StaffType.MEDIC):
		total += staff_counts[Enums.StaffType.MEDIC] * Constants.SALARY_MEDIC
	if staff_counts.has(Enums.StaffType.PSYCHOLOGIST):
		total += staff_counts[Enums.StaffType.PSYCHOLOGIST] * Constants.SALARY_PSYCHOLOGIST
	if staff_counts.has(Enums.StaffType.JANITOR):
		total += staff_counts[Enums.StaffType.JANITOR] * Constants.SALARY_JANITOR
	if staff_counts.has(Enums.StaffType.PRIEST):
		total += staff_counts[Enums.StaffType.PRIEST] * Constants.SALARY_PRIEST

	return total


func calculate_daily_food(prisoner_count: int, using_tray_service: bool = false) -> int:
	var cost_per_prisoner := Constants.FOOD_COST_PER_PRISONER
	if using_tray_service:
		cost_per_prisoner = Constants.FOOD_COST_TRAY_SERVICE
	return prisoner_count * cost_per_prisoner


func calculate_daily_utilities(building_count: int) -> int:
	# Bazowy koszt + dodatek za każdy budynek
	return Constants.UTILITY_BASE_COST + (building_count * 10)


# =============================================================================
# POŻYCZKI
# =============================================================================
func can_take_loan() -> bool:
	return not has_loan


func take_loan() -> bool:
	if has_loan:
		return false

	has_loan = true
	loan_amount = Constants.EMERGENCY_LOAN_AMOUNT
	add_capital(loan_amount, "")

	Signals.loan_taken.emit(loan_amount)
	return true


func get_loan_daily_interest() -> int:
	if not has_loan:
		return 0
	# Dzienna rata odsetkowa
	return int(loan_amount * Constants.EMERGENCY_LOAN_INTEREST / Constants.DAYS_PER_MONTH)


func repay_loan(amount: int) -> bool:
	if not has_loan:
		return false

	if not can_afford(amount):
		return false

	subtract_capital(amount, "")
	loan_amount -= amount

	if loan_amount <= 0:
		has_loan = false
		loan_amount = 0

	return true


# =============================================================================
# BILANS DZIENNY
# =============================================================================
func get_total_daily_revenue() -> int:
	var total: int = 0
	for key in daily_revenue:
		total += daily_revenue[key]
	return total


func get_total_daily_expenses() -> int:
	var total: int = 0
	for key in daily_expenses:
		total += daily_expenses[key]
	return total


func get_daily_balance() -> int:
	return get_total_daily_revenue() - get_total_daily_expenses()


func _reset_daily_tracking() -> void:
	for key in daily_revenue:
		daily_revenue[key] = 0
	for key in daily_expenses:
		daily_expenses[key] = 0


# =============================================================================
# BANKRUCTWO
# =============================================================================
func _check_bankruptcy() -> void:
	if capital < 0:
		days_in_debt += 1
		Signals.low_capital_warning.emit(capital, days_in_debt)

		if days_in_debt >= Constants.BANKRUPTCY_DAYS:
			Signals.bankruptcy.emit()
	else:
		days_in_debt = 0


# =============================================================================
# HISTORIA
# =============================================================================
func add_to_history(balance: int) -> void:
	balance_history.append(balance)
	if balance_history.size() > MAX_HISTORY_DAYS:
		balance_history.pop_front()


func get_balance_history() -> Array[int]:
	return balance_history


func get_balance_trend() -> float:
	if balance_history.size() < 7:
		return 0.0

	var recent: Array = balance_history.slice(-7)
	var avg_recent: float = 0.0
	for val in recent:
		avg_recent += val
	avg_recent /= recent.size()

	if balance_history.size() >= 14:
		var older: Array = balance_history.slice(-14, -7)
		var avg_older: float = 0.0
		for val in older:
			avg_older += val
		avg_older /= older.size()
		return avg_recent - avg_older

	return avg_recent


# =============================================================================
# EVENTY
# =============================================================================
func _on_day_changed(_day: int) -> void:
	# Zapisz bilans do historii
	add_to_history(get_daily_balance())

	# Emituj podsumowanie
	Signals.daily_balance_calculated.emit(
		get_total_daily_revenue(),
		get_total_daily_expenses(),
		get_daily_balance()
	)

	# Sprawdź bankructwo
	_check_bankruptcy()

	# Reset trackingu na nowy dzień
	_reset_daily_tracking()


func _on_hour_changed(hour: int) -> void:
	# Odsetki od pożyczki naliczane o północy
	if has_loan and hour == 0:
		var interest := get_loan_daily_interest()
		if interest > 0:
			subtract_capital(interest, "loan_interest")

	# Naliczaj przychody i wydatki co godzinę (1/24 dziennego)
	_process_hourly_economy()


func _process_hourly_economy() -> void:
	# Subwencje za więźniów (naliczane co godzinę, 1/24 dziennej kwoty)
	var hourly_subsidies := calculate_daily_subsidies(prisoners_by_category) / 24
	if hourly_subsidies > 0:
		add_capital(hourly_subsidies, "subsidies")

	# Przychód z warsztatów (TODO: integracja z WorkshopManager gdy będzie)
	var hourly_workshop := _calculate_workshop_income() / 24
	if hourly_workshop > 0:
		add_capital(hourly_workshop, "workshop")

	# Wydatki - pensje (1/24 dziennej kwoty)
	var hourly_salaries := calculate_daily_salaries(staff_counts) / 24
	if hourly_salaries > 0:
		subtract_capital(hourly_salaries, "salaries")

	# Wydatki - jedzenie
	var hourly_food := calculate_daily_food(prisoner_count, is_lockdown) / 24
	if hourly_food > 0:
		subtract_capital(hourly_food, "food")

	# Wydatki - media
	var building_count := BuildingManager.count_buildings()
	var hourly_utilities := calculate_daily_utilities(building_count) / 24
	if hourly_utilities > 0:
		subtract_capital(hourly_utilities, "utilities")


func _calculate_workshop_income() -> int:
	# TODO: Prawdziwa kalkulacja gdy będzie WorkshopManager
	# Na razie zakładamy $50/dzień za każdy warsztat z przypisanymi więźniami
	var workshops := BuildingManager.get_buildings_by_type(Enums.BuildingType.WORKSHOP_CARPENTRY)
	var income: int = 0
	for workshop in workshops:
		if workshop.current_occupancy > 0:
			income += workshop.current_occupancy * 50
	return income


# =============================================================================
# ZARZĄDZANIE WIĘŹNIAMI (tymczasowe API)
# =============================================================================
func add_prisoner(category: Enums.SecurityCategory) -> void:
	prisoner_count += 1
	prisoners_by_category[category] += 1
	Signals.prisoner_count_changed.emit(prisoner_count)


func remove_prisoner(category: Enums.SecurityCategory) -> void:
	if prisoner_count > 0:
		prisoner_count -= 1
	if prisoners_by_category[category] > 0:
		prisoners_by_category[category] -= 1
	Signals.prisoner_count_changed.emit(prisoner_count)


func get_prisoner_count() -> int:
	return prisoner_count


# =============================================================================
# ZARZĄDZANIE PERSONELEM (tymczasowe API)
# =============================================================================
func hire_staff(staff_type: Enums.StaffType) -> bool:
	var salary := _get_staff_salary(staff_type)
	# Sprawdź czy stać na pierwszą pensję
	if not can_afford(salary):
		Signals.alert_triggered.emit(
			Enums.AlertPriority.IMPORTANT,
			"Brak środków",
			"Nie stać cię na zatrudnienie tego pracownika",
			Vector2i.ZERO
		)
		return false

	staff_counts[staff_type] += 1
	Signals.staff_hired.emit(staff_type)
	return true


func fire_staff(staff_type: Enums.StaffType) -> bool:
	if staff_counts[staff_type] <= 0:
		return false

	staff_counts[staff_type] -= 1
	Signals.staff_fired.emit(staff_type)
	return true


func get_staff_count(staff_type: Enums.StaffType) -> int:
	return staff_counts.get(staff_type, 0)


func get_total_staff_count() -> int:
	var total: int = 0
	for count in staff_counts.values():
		total += count
	return total


func _get_staff_salary(staff_type: Enums.StaffType) -> int:
	match staff_type:
		Enums.StaffType.GUARD:
			return Constants.SALARY_GUARD
		Enums.StaffType.COOK:
			return Constants.SALARY_COOK
		Enums.StaffType.MEDIC:
			return Constants.SALARY_MEDIC
		Enums.StaffType.PSYCHOLOGIST:
			return Constants.SALARY_PSYCHOLOGIST
		Enums.StaffType.JANITOR:
			return Constants.SALARY_JANITOR
		Enums.StaffType.PRIEST:
			return Constants.SALARY_PRIEST
		_:
			return 100


# =============================================================================
# PREDYKCJA
# =============================================================================
func get_predicted_daily_balance() -> int:
	var revenue := calculate_daily_subsidies(prisoners_by_category) + _calculate_workshop_income()
	var expenses := calculate_daily_salaries(staff_counts) + \
		calculate_daily_food(prisoner_count, is_lockdown) + \
		calculate_daily_utilities(BuildingManager.count_buildings())

	if has_loan:
		expenses += get_loan_daily_interest()

	return revenue - expenses


func get_monthly_staff_cost() -> int:
	return calculate_daily_salaries(staff_counts) * Constants.DAYS_PER_MONTH


# =============================================================================
# SAVE/LOAD
# =============================================================================
func get_save_data() -> Dictionary:
	return {
		"capital": capital,
		"daily_revenue": daily_revenue.duplicate(),
		"daily_expenses": daily_expenses.duplicate(),
		"balance_history": balance_history.duplicate(),
		"has_loan": has_loan,
		"loan_amount": loan_amount,
		"days_in_debt": days_in_debt
	}


func load_save_data(data: Dictionary) -> void:
	capital = data.get("capital", Constants.STARTING_CAPITAL)
	daily_revenue = data.get("daily_revenue", daily_revenue)
	daily_expenses = data.get("daily_expenses", daily_expenses)
	balance_history = data.get("balance_history", [])
	has_loan = data.get("has_loan", false)
	loan_amount = data.get("loan_amount", 0)
	days_in_debt = data.get("days_in_debt", 0)
