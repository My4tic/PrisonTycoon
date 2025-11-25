## ScheduleManager - System harmonogramów
## Autoload singleton dostępny jako ScheduleManager
##
## Odpowiada za:
## - Harmonogramy dla każdej kategorii więźniów
## - Zarządzanie aktywnościami według godziny
## - System lockdown
extends Node

# =============================================================================
# ZMIENNE
# =============================================================================
# Harmonogramy: [SecurityCategory][hour] = ScheduleActivity
var schedules: Dictionary = {}

# Stan lockdown
var is_lockdown: bool = false
var lockdown_reason: String = ""

# Aktualnie aktywne aktywności per kategoria
var current_activities: Dictionary = {}

# =============================================================================
# FUNKCJE GODOT
# =============================================================================
func _ready() -> void:
	_init_default_schedules()
	Signals.hour_changed.connect(_on_hour_changed)


# =============================================================================
# INICJALIZACJA DOMYŚLNYCH HARMONOGRAMÓW
# =============================================================================
func _init_default_schedules() -> void:
	# Każda kategoria ma własny harmonogram
	for category in Enums.SecurityCategory.values():
		schedules[category] = _create_default_schedule(category)
		current_activities[category] = Enums.ScheduleActivity.SLEEP


func _create_default_schedule(category: Enums.SecurityCategory) -> Dictionary:
	var schedule: Dictionary = {}

	# Domyślny harmonogram (wszystkie godziny)
	for hour in range(24):
		schedule[hour] = _get_default_activity_for_hour(hour, category)

	return schedule


func _get_default_activity_for_hour(hour: int, category: Enums.SecurityCategory) -> Enums.ScheduleActivity:
	# Maximum security ma bardziej restrykcyjny harmonogram
	var is_max_security := category == Enums.SecurityCategory.MAXIMUM

	match hour:
		0, 1, 2, 3, 4, 5:
			return Enums.ScheduleActivity.SLEEP
		6:
			return Enums.ScheduleActivity.HYGIENE
		7:
			return Enums.ScheduleActivity.EATING
		8:
			return Enums.ScheduleActivity.FREE_TIME if not is_max_security else Enums.ScheduleActivity.LOCKDOWN
		9, 10, 11:
			return Enums.ScheduleActivity.WORK
		12:
			return Enums.ScheduleActivity.EATING
		13, 14, 15, 16:
			return Enums.ScheduleActivity.WORK
		17:
			return Enums.ScheduleActivity.FREE_TIME if not is_max_security else Enums.ScheduleActivity.LOCKDOWN
		18:
			return Enums.ScheduleActivity.EATING
		19, 20:
			return Enums.ScheduleActivity.RECREATION
		21:
			return Enums.ScheduleActivity.HYGIENE if not is_max_security else Enums.ScheduleActivity.LOCKDOWN
		22, 23:
			return Enums.ScheduleActivity.SLEEP
		_:
			return Enums.ScheduleActivity.SLEEP


# =============================================================================
# POBIERANIE HARMONOGRAMU
# =============================================================================
func get_schedule(category: Enums.SecurityCategory) -> Dictionary:
	return schedules.get(category, {})


func get_activity(category: Enums.SecurityCategory, hour: int) -> Enums.ScheduleActivity:
	if is_lockdown:
		return Enums.ScheduleActivity.LOCKDOWN

	var schedule := get_schedule(category)
	return schedule.get(hour, Enums.ScheduleActivity.FREE_TIME)


func get_current_activity(category: Enums.SecurityCategory) -> Enums.ScheduleActivity:
	if is_lockdown:
		return Enums.ScheduleActivity.LOCKDOWN
	return current_activities.get(category, Enums.ScheduleActivity.FREE_TIME)


func get_activity_name(activity: Enums.ScheduleActivity) -> String:
	match activity:
		Enums.ScheduleActivity.SLEEP:
			return "Sen"
		Enums.ScheduleActivity.EATING:
			return "Posiłek"
		Enums.ScheduleActivity.HYGIENE:
			return "Higiena"
		Enums.ScheduleActivity.WORK:
			return "Praca"
		Enums.ScheduleActivity.RECREATION:
			return "Rekreacja"
		Enums.ScheduleActivity.FREE_TIME:
			return "Czas wolny"
		Enums.ScheduleActivity.LOCKDOWN:
			return "Lockdown"
		_:
			return "Nieznane"


# =============================================================================
# MODYFIKACJA HARMONOGRAMU
# =============================================================================
func set_activity(category: Enums.SecurityCategory, hour: int, activity: Enums.ScheduleActivity) -> void:
	if not schedules.has(category):
		schedules[category] = {}

	var old_activity: Enums.ScheduleActivity = schedules[category].get(hour, Enums.ScheduleActivity.FREE_TIME)
	schedules[category][hour] = activity

	Signals.schedule_activity_changed.emit(category, hour, activity)

	# Jeśli zmieniona godzina to aktualna, zaktualizuj bieżącą aktywność
	if hour == GameManager.current_hour:
		_update_current_activity(category)


func copy_schedule(from_category: Enums.SecurityCategory, to_category: Enums.SecurityCategory) -> void:
	if not schedules.has(from_category):
		return

	schedules[to_category] = schedules[from_category].duplicate()

	# Aktualizuj bieżącą aktywność
	_update_current_activity(to_category)


func reset_schedule(category: Enums.SecurityCategory) -> void:
	schedules[category] = _create_default_schedule(category)
	_update_current_activity(category)


# =============================================================================
# LOCKDOWN
# =============================================================================
func start_lockdown(reason: String = "Manual") -> void:
	if is_lockdown:
		return

	is_lockdown = true
	lockdown_reason = reason

	# Ustaw wszystkie kategorie na lockdown
	for category in Enums.SecurityCategory.values():
		current_activities[category] = Enums.ScheduleActivity.LOCKDOWN

	Signals.lockdown_started.emit(reason)


func end_lockdown() -> void:
	if not is_lockdown:
		return

	is_lockdown = false
	lockdown_reason = ""

	# Przywróć normalne aktywności
	for category in Enums.SecurityCategory.values():
		_update_current_activity(category)

	Signals.lockdown_ended.emit()


func toggle_lockdown() -> void:
	if is_lockdown:
		end_lockdown()
	else:
		start_lockdown("Manual")


# =============================================================================
# AKTUALIZACJA AKTYWNOŚCI
# =============================================================================
func _update_current_activity(category: Enums.SecurityCategory) -> void:
	var new_activity := get_activity(category, GameManager.current_hour)
	var old_activity: Enums.ScheduleActivity = current_activities.get(category, Enums.ScheduleActivity.FREE_TIME)

	if new_activity != old_activity:
		current_activities[category] = new_activity
		Signals.schedule_activity_started.emit(category, new_activity)


func _on_hour_changed(hour: int) -> void:
	# Aktualizuj aktywności dla wszystkich kategorii
	for category in Enums.SecurityCategory.values():
		_update_current_activity(category)


# =============================================================================
# POBIERANIE LOKALIZACJI DLA AKTYWNOŚCI
# =============================================================================
func get_activity_building_types(activity: Enums.ScheduleActivity) -> Array[Enums.BuildingType]:
	var types: Array[Enums.BuildingType] = []

	match activity:
		Enums.ScheduleActivity.SLEEP, Enums.ScheduleActivity.LOCKDOWN:
			types.append(Enums.BuildingType.CELL_SINGLE)
			types.append(Enums.BuildingType.CELL_DOUBLE)
			types.append(Enums.BuildingType.DORMITORY)
			types.append(Enums.BuildingType.CELL_LUXURY)
		Enums.ScheduleActivity.EATING:
			types.append(Enums.BuildingType.CANTEEN)
		Enums.ScheduleActivity.HYGIENE:
			types.append(Enums.BuildingType.SHOWER_ROOM)
		Enums.ScheduleActivity.WORK:
			types.append(Enums.BuildingType.WORKSHOP_CARPENTRY)
			types.append(Enums.BuildingType.LAUNDRY)
			types.append(Enums.BuildingType.GARDEN)
			types.append(Enums.BuildingType.CALL_CENTER)
		Enums.ScheduleActivity.RECREATION:
			types.append(Enums.BuildingType.YARD)
			types.append(Enums.BuildingType.GYM)
			types.append(Enums.BuildingType.LIBRARY)
			types.append(Enums.BuildingType.CHAPEL)
			types.append(Enums.BuildingType.TV_ROOM)
		Enums.ScheduleActivity.FREE_TIME:
			# Wolny czas - dowolne miejsce rekreacyjne lub cela
			types.append(Enums.BuildingType.YARD)
			types.append(Enums.BuildingType.CELL_SINGLE)
			types.append(Enums.BuildingType.CELL_DOUBLE)
			types.append(Enums.BuildingType.DORMITORY)

	return types


# =============================================================================
# EKSPORT DO UI
# =============================================================================
func get_schedule_for_display(category: Enums.SecurityCategory) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var schedule := get_schedule(category)

	for hour in range(24):
		var activity: Enums.ScheduleActivity = schedule.get(hour, Enums.ScheduleActivity.FREE_TIME)
		result.append({
			"hour": hour,
			"hour_string": "%02d:00" % hour,
			"activity": activity,
			"activity_name": get_activity_name(activity)
		})

	return result


# =============================================================================
# SAVE/LOAD
# =============================================================================
func get_save_data() -> Dictionary:
	return {
		"schedules": schedules.duplicate(true),
		"is_lockdown": is_lockdown,
		"lockdown_reason": lockdown_reason
	}


func load_save_data(data: Dictionary) -> void:
	schedules = data.get("schedules", {})
	is_lockdown = data.get("is_lockdown", false)
	lockdown_reason = data.get("lockdown_reason", "")

	if schedules.is_empty():
		_init_default_schedules()

	# Aktualizuj bieżące aktywności
	for category in Enums.SecurityCategory.values():
		_update_current_activity(category)
