## EventManager - System wydarzeń i kryzysów
## Autoload singleton dostępny jako EventManager
##
## Odpowiada za:
## - Kolejka aktywnych eventów
## - Sprawdzanie warunków triggerów
## - System alertów
## - Zarządzanie stanem kryzysu
extends Node

# =============================================================================
# ZMIENNE
# =============================================================================
# Stan kryzysu
var crisis_state: Enums.CrisisState = Enums.CrisisState.NORMAL
var tension_level: float = 0.0  # 0-100%

# Aktywne eventy
var active_events: Array[EventData] = []
var _next_event_id: int = 1

# Aktywne alerty UI
var active_alerts: Array[AlertData] = []
var _next_alert_id: int = 1

# Timer do sprawdzania warunków
var _check_timer: float = 0.0
const CHECK_INTERVAL: float = 5.0  # Sekundy

# =============================================================================
# KLASY DANYCH
# =============================================================================
class EventData:
	var id: int
	var type: Enums.EventType
	var location: Vector2i
	var participants: Array[int]  # ID więźniów/personelu
	var start_time: Dictionary  # {day, hour, minute}
	var is_resolved: bool = false
	var data: Dictionary = {}  # Dodatkowe dane specyficzne dla typu

	func _init(p_id: int, p_type: Enums.EventType, p_location: Vector2i) -> void:
		id = p_id
		type = p_type
		location = p_location
		start_time = {
			"day": GameManager.current_day,
			"hour": GameManager.current_hour,
			"minute": GameManager.current_minute
		}


class AlertData:
	var id: int
	var priority: Enums.AlertPriority
	var title: String
	var message: String
	var location: Vector2i
	var timestamp: float
	var is_dismissed: bool = false
	var event_id: int = -1  # Powiązany event (jeśli jest)

	func _init(p_id: int, p_priority: Enums.AlertPriority, p_title: String, p_message: String, p_location: Vector2i) -> void:
		id = p_id
		priority = p_priority
		title = p_title
		message = p_message
		location = p_location
		timestamp = Time.get_unix_time_from_system()


# =============================================================================
# FUNKCJE GODOT
# =============================================================================
func _ready() -> void:
	Signals.hour_changed.connect(_on_hour_changed)


func _process(delta: float) -> void:
	if not GameManager.is_playing() or GameManager.is_paused:
		return

	_check_timer += delta
	if _check_timer >= CHECK_INTERVAL:
		_check_timer = 0.0
		_check_event_triggers()
		_update_tension()


# =============================================================================
# TWORZENIE EVENTÓW
# =============================================================================
func create_event(type: Enums.EventType, location: Vector2i, participants: Array[int] = []) -> int:
	var event := EventData.new(_next_event_id, type, location)
	event.participants = participants
	_next_event_id += 1

	active_events.append(event)
	_emit_event_signal(event)
	_create_alert_for_event(event)

	return event.id


func resolve_event(event_id: int) -> void:
	for event in active_events:
		if event.id == event_id:
			event.is_resolved = true
			break

	# Usuń rozwiązane eventy
	active_events = active_events.filter(func(e): return not e.is_resolved)


func _emit_event_signal(event: EventData) -> void:
	match event.type:
		Enums.EventType.FIGHT:
			Signals.fight_started.emit(event.location, event.participants)
		Enums.EventType.ESCAPE_ATTEMPT:
			if event.participants.size() > 0:
				Signals.escape_attempt_detected.emit(event.participants[0], event.location)
		Enums.EventType.RIOT:
			Signals.riot_started.emit(event.participants.size())
		Enums.EventType.CONTRABAND:
			if event.participants.size() > 0:
				var contraband_type: int = event.data.get("contraband_type", 0)
				Signals.contraband_found.emit(event.participants[0], contraband_type)
		Enums.EventType.EPIDEMIC:
			var disease: String = event.data.get("disease", "Unknown")
			Signals.epidemic_started.emit(disease)


# =============================================================================
# SYSTEM ALERTÓW
# =============================================================================
func create_alert(priority: Enums.AlertPriority, title: String, message: String, location: Vector2i = Vector2i.ZERO) -> int:
	var alert := AlertData.new(_next_alert_id, priority, title, message, location)
	_next_alert_id += 1

	active_alerts.append(alert)
	Signals.alert_triggered.emit(priority, title, message, location)

	# Sortuj po priorytecie
	active_alerts.sort_custom(func(a, b): return a.priority < b.priority)

	return alert.id


func dismiss_alert(alert_id: int) -> void:
	for alert in active_alerts:
		if alert.id == alert_id:
			alert.is_dismissed = true
			Signals.alert_dismissed.emit(alert_id)
			break

	active_alerts = active_alerts.filter(func(a): return not a.is_dismissed)


func dismiss_all_alerts() -> void:
	for alert in active_alerts:
		Signals.alert_dismissed.emit(alert.id)
	active_alerts.clear()


func get_active_alerts() -> Array[AlertData]:
	return active_alerts


func get_alert_count() -> int:
	return active_alerts.size()


func get_critical_alert_count() -> int:
	var count: int = 0
	for alert in active_alerts:
		if alert.priority == Enums.AlertPriority.CRITICAL:
			count += 1
	return count


func _create_alert_for_event(event: EventData) -> void:
	var priority: Enums.AlertPriority
	var title: String
	var message: String

	match event.type:
		Enums.EventType.FIGHT:
			priority = Enums.AlertPriority.IMPORTANT
			title = "Bójka!"
			message = "Wykryto bójkę. Wysłać strażników."
		Enums.EventType.ESCAPE_ATTEMPT:
			priority = Enums.AlertPriority.CRITICAL
			title = "Próba ucieczki!"
			message = "Więzień próbuje uciec!"
		Enums.EventType.ESCAPE_SUCCESS:
			priority = Enums.AlertPriority.CRITICAL
			title = "Ucieczka!"
			message = "Więzień uciekł z więzienia!"
		Enums.EventType.RIOT:
			priority = Enums.AlertPriority.CRITICAL
			title = "BUNT!"
			message = "Rozpoczął się bunt więźniów!"
		Enums.EventType.CONTRABAND:
			priority = Enums.AlertPriority.INFO
			title = "Kontrabanda"
			message = "Znaleziono kontrabandę."
		Enums.EventType.EPIDEMIC:
			priority = Enums.AlertPriority.CRITICAL
			title = "Epidemia!"
			message = "Wykryto chorobę zakaźną."
		Enums.EventType.DEATH:
			priority = Enums.AlertPriority.CRITICAL
			title = "Śmierć"
			message = "Więzień zmarł."
		Enums.EventType.STAFF_INJURED:
			priority = Enums.AlertPriority.IMPORTANT
			title = "Ranny personel"
			message = "Członek personelu został ranny."
		Enums.EventType.CONTRACT_OFFER:
			priority = Enums.AlertPriority.POSITIVE
			title = "Nowy kontrakt"
			message = "Dostępny nowy kontrakt rządowy."
		_:
			return  # Nie twórz alertu dla nieznanych typów

	var alert_id := create_alert(priority, title, message, event.location)

	# Powiąż alert z eventem
	for alert in active_alerts:
		if alert.id == alert_id:
			alert.event_id = event.id
			break


# =============================================================================
# SPRAWDZANIE WARUNKÓW TRIGGERÓW
# =============================================================================
func _check_event_triggers() -> void:
	# TODO: Implementacja sprawdzania warunków dla różnych eventów
	# Na razie placeholder - będzie rozbudowane w późniejszych fazach
	pass


func _check_fight_conditions() -> void:
	# Sprawdź czy są więźniowie z niskimi potrzebami lub agresywni
	# Jeśli tak, może rozpocząć się bójka
	pass


func _check_escape_conditions() -> void:
	# Sprawdź czy są więźniowie z bardzo niską potrzebą wolności
	# i czy mają możliwość ucieczki
	pass


func _check_riot_conditions() -> void:
	# Sprawdź czy nastrój więźniów jest poniżej progu
	# i czy jest wystarczająco dużo niezadowolonych
	pass


# =============================================================================
# SYSTEM NAPIĘCIA (TENSION)
# =============================================================================
func _update_tension() -> void:
	# TODO: Oblicz napięcie na podstawie:
	# - Średniego nastroju więźniów
	# - Ostatnich incydentów
	# - Stanu personelu
	# - Przeludnienia

	var old_tension := tension_level

	# Placeholder - będzie rozbudowane
	# tension_level = calculate_tension()

	if tension_level != old_tension:
		Signals.tension_rising.emit(tension_level)

	_update_crisis_state()


func _update_crisis_state() -> void:
	var new_state := crisis_state

	if tension_level < 30.0:
		new_state = Enums.CrisisState.NORMAL
	elif tension_level < 60.0:
		new_state = Enums.CrisisState.TENSION
	elif tension_level < 90.0:
		new_state = Enums.CrisisState.CRISIS
	else:
		new_state = Enums.CrisisState.EMERGENCY

	if new_state != crisis_state:
		crisis_state = new_state


func add_tension(amount: float) -> void:
	tension_level = clampf(tension_level + amount, 0.0, 100.0)
	_update_crisis_state()


func reduce_tension(amount: float) -> void:
	tension_level = clampf(tension_level - amount, 0.0, 100.0)
	_update_crisis_state()


func get_tension_level() -> float:
	return tension_level


func get_crisis_state() -> Enums.CrisisState:
	return crisis_state


# =============================================================================
# EVENTY
# =============================================================================
func _on_hour_changed(_hour: int) -> void:
	# Naturalne zmniejszanie napięcia w spokojnych godzinach
	if crisis_state == Enums.CrisisState.NORMAL:
		reduce_tension(1.0)


# =============================================================================
# POBIERANIE EVENTÓW
# =============================================================================
func get_active_events() -> Array[EventData]:
	return active_events


func get_events_by_type(type: Enums.EventType) -> Array[EventData]:
	var result: Array[EventData] = []
	for event in active_events:
		if event.type == type:
			result.append(event)
	return result


func has_active_crisis() -> bool:
	for event in active_events:
		match event.type:
			Enums.EventType.RIOT, Enums.EventType.EPIDEMIC, Enums.EventType.ESCAPE_ATTEMPT:
				return true
	return false


# =============================================================================
# SAVE/LOAD
# =============================================================================
func get_save_data() -> Dictionary:
	var events_data: Array = []
	for event in active_events:
		events_data.append({
			"id": event.id,
			"type": event.type,
			"location": [event.location.x, event.location.y],
			"participants": event.participants,
			"start_time": event.start_time,
			"data": event.data
		})

	return {
		"crisis_state": crisis_state,
		"tension_level": tension_level,
		"events": events_data,
		"next_event_id": _next_event_id,
		"next_alert_id": _next_alert_id
	}


func load_save_data(data: Dictionary) -> void:
	crisis_state = data.get("crisis_state", Enums.CrisisState.NORMAL)
	tension_level = data.get("tension_level", 0.0)
	_next_event_id = data.get("next_event_id", 1)
	_next_alert_id = data.get("next_alert_id", 1)

	active_events.clear()
	for e_data in data.get("events", []):
		var loc_arr: Array = e_data["location"]
		var loc: Vector2i = Vector2i(loc_arr[0], loc_arr[1])
		var event: EventData = EventData.new(e_data["id"], e_data["type"], loc)
		event.participants = e_data.get("participants", [])
		event.start_time = e_data.get("start_time", {})
		event.data = e_data.get("data", {})
		active_events.append(event)
