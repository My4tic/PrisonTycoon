## FightSystem - System zarządzania bójkami
## Autoload singleton dostępny jako FightSystem
##
## Odpowiada za:
## - Wykrywanie warunków rozpoczęcia bójki
## - Zarządzanie aktywnymi bójkami
## - Aplikowanie obrażeń
## - Rozwiązywanie bójek
extends Node

# =============================================================================
# KLASA DANYCH BÓJKI
# =============================================================================
class FightData:
	var id: int
	var location: Vector2i
	var participants: Array = []  # Array of Prisoner references
	var participant_ids: Array[int] = []
	var start_time: Dictionary
	var duration: float = 0.0
	var is_resolved: bool = false
	var injuries: int = 0
	var event_id: int = -1

	func _init(p_id: int, p_location: Vector2i) -> void:
		id = p_id
		location = p_location
		start_time = {
			"day": GameManager.current_day,
			"hour": GameManager.current_hour,
			"minute": GameManager.current_minute
		}


# =============================================================================
# ZMIENNE
# =============================================================================
# Aktywne bójki
var active_fights: Array[FightData] = []
var _next_fight_id: int = 1

# Timer sprawdzania warunków bójek
var _check_timer: float = 0.0
const CHECK_INTERVAL: float = 3.0  # Sprawdzaj co 3 sekundy

# Parametry bójek
const MIN_PRISONERS_FOR_FIGHT: int = 2
const MAX_FIGHT_PARTICIPANTS: int = 6
const FIGHT_DAMAGE_PER_SECOND: float = 2.0
const FIGHT_SPREAD_CHANCE: float = 0.1  # Szansa na dołączenie pobliskiego więźnia
const FIGHT_SPREAD_RADIUS: float = 3.0 * Constants.TILE_SIZE  # 3 tile'y


# =============================================================================
# FUNKCJE GODOT
# =============================================================================
func _ready() -> void:
	Signals.fight_started.connect(_on_external_fight_started)
	Signals.prisoner_pacified.connect(_on_prisoner_pacified)


func _process(delta: float) -> void:
	if not GameManager.is_playing() or GameManager.is_paused:
		return

	# Sprawdzaj warunki rozpoczęcia bójki
	_check_timer += delta
	if _check_timer >= CHECK_INTERVAL:
		_check_timer = 0.0
		_check_fight_conditions()

	# Aktualizuj aktywne bójki
	_update_active_fights(delta)


# =============================================================================
# SPRAWDZANIE WARUNKÓW BÓJKI
# =============================================================================
func _check_fight_conditions() -> void:
	var all_prisoners: Array = PrisonerManager.get_all_prisoners()

	if all_prisoners.size() < MIN_PRISONERS_FOR_FIGHT:
		return

	# Sprawdź każdego więźnia
	for prisoner in all_prisoners:
		if prisoner == null or not is_instance_valid(prisoner):
			continue

		# Pomiń jeśli już walczy lub jest w izolatce
		if prisoner.current_state == Enums.PrisonerState.FIGHTING:
			continue
		if prisoner.current_state == Enums.PrisonerState.IN_SOLITARY:
			continue
		if prisoner.current_state == Enums.PrisonerState.SLEEPING:
			continue

		# Oblicz ryzyko bójki
		var fight_risk: float = prisoner.get_fight_risk()

		# Rzut kostką
		if randf() < fight_risk * (CHECK_INTERVAL / 3600.0):  # Normalizacja do godziny
			_try_start_fight(prisoner)


func _try_start_fight(instigator) -> void:
	# Znajdź potencjalnych przeciwników w pobliżu
	var nearby_prisoners: Array = _get_nearby_prisoners(instigator, FIGHT_SPREAD_RADIUS * 2)

	if nearby_prisoners.is_empty():
		return  # Brak przeciwników

	# Wybierz losowego przeciwnika
	var opponent = nearby_prisoners[randi() % nearby_prisoners.size()]

	# Sprawdź czy przeciwnik może walczyć
	if opponent.current_state == Enums.PrisonerState.FIGHTING:
		return
	if opponent.current_state == Enums.PrisonerState.IN_SOLITARY:
		return
	if opponent.current_state == Enums.PrisonerState.SLEEPING:
		return

	# Rozpocznij bójkę
	var location := GridManager.world_to_grid(instigator.global_position)
	start_fight(location, [instigator, opponent])


func _get_nearby_prisoners(prisoner, radius: float) -> Array:
	var result: Array = []
	var all_prisoners: Array = PrisonerManager.get_all_prisoners()

	for other in all_prisoners:
		if other == null or not is_instance_valid(other):
			continue
		if other == prisoner:
			continue

		var distance: float = prisoner.global_position.distance_to(other.global_position)
		if distance <= radius:
			result.append(other)

	return result


# =============================================================================
# ROZPOCZYNANIE BÓJKI
# =============================================================================
func start_fight(location: Vector2i, participants: Array) -> int:
	if participants.size() < MIN_PRISONERS_FOR_FIGHT:
		return -1

	# Utwórz dane bójki
	var fight := FightData.new(_next_fight_id, location)
	_next_fight_id += 1

	# Dodaj uczestników
	for prisoner in participants:
		if prisoner == null or not is_instance_valid(prisoner):
			continue

		fight.participants.append(prisoner)
		fight.participant_ids.append(prisoner.prisoner_id)

		# Zmień stan więźnia
		prisoner.change_state(Enums.PrisonerState.FIGHTING)

	# Dodaj do listy aktywnych
	active_fights.append(fight)

	# Utwórz event w EventManager
	fight.event_id = EventManager.create_event(
		Enums.EventType.FIGHT,
		location,
		fight.participant_ids
	)

	# Emituj sygnał (wyślij strażników)
	Signals.fight_started.emit(location, fight.participants)

	# Zwiększ napięcie
	EventManager.add_tension(5.0 * participants.size())

	return fight.id


# =============================================================================
# AKTUALIZACJA BÓJEK
# =============================================================================
func _update_active_fights(delta: float) -> void:
	var game_delta: float = delta * GameManager.get_speed_multiplier()
	var fights_to_remove: Array = []

	for fight in active_fights:
		if fight.is_resolved:
			fights_to_remove.append(fight)
			continue

		fight.duration += game_delta

		# Aplikuj obrażenia
		_apply_fight_damage(fight, game_delta)

		# Sprawdź rozprzestrzenianie
		_check_fight_spread(fight)

		# Sprawdź warunki zakończenia
		if _should_end_fight(fight):
			_end_fight(fight)
			fights_to_remove.append(fight)

	# Usuń rozwiązane bójki
	for fight in fights_to_remove:
		active_fights.erase(fight)


func _apply_fight_damage(fight: FightData, delta: float) -> void:
	var damage: float = FIGHT_DAMAGE_PER_SECOND * delta

	for prisoner in fight.participants:
		if prisoner == null or not is_instance_valid(prisoner):
			continue

		# Modyfikator obrażeń z cech
		var damage_modifier: float = 1.0

		if prisoner.has_trait(Enums.PrisonerTrait.STRONG):
			damage_modifier *= 0.7  # Mniej obrażeń otrzymuje
		if prisoner.has_trait(Enums.PrisonerTrait.WEAK):
			damage_modifier *= 1.5  # Więcej obrażeń otrzymuje

		var final_damage: float = damage * damage_modifier
		prisoner.take_damage(final_damage, "fight")

		# Sprawdź rany
		if prisoner.health < 50 and prisoner.health + final_damage >= 50:
			fight.injuries += 1


func _check_fight_spread(fight: FightData) -> void:
	if fight.participants.size() >= MAX_FIGHT_PARTICIPANTS:
		return

	# Szansa na rozprzestrzenienie
	if randf() > FIGHT_SPREAD_CHANCE:
		return

	# Znajdź centrum bójki
	var center: Vector2 = Vector2.ZERO
	var valid_count: int = 0

	for prisoner in fight.participants:
		if prisoner and is_instance_valid(prisoner):
			center += prisoner.global_position
			valid_count += 1

	if valid_count == 0:
		return

	center /= valid_count

	# Znajdź pobliskich więźniów
	var all_prisoners: Array = PrisonerManager.get_all_prisoners()

	for prisoner in all_prisoners:
		if prisoner == null or not is_instance_valid(prisoner):
			continue

		# Pomiń już uczestniczących
		if prisoner in fight.participants:
			continue

		# Pomiń niezdatnych do walki
		if prisoner.current_state == Enums.PrisonerState.FIGHTING:
			continue
		if prisoner.current_state == Enums.PrisonerState.IN_SOLITARY:
			continue
		if prisoner.current_state == Enums.PrisonerState.SLEEPING:
			continue

		# Sprawdź odległość
		if prisoner.global_position.distance_to(center) > FIGHT_SPREAD_RADIUS:
			continue

		# Sprawdź ryzyko dołączenia (bazowane na nastroju i cechach)
		var join_chance: float = prisoner.get_fight_risk() * 2.0

		if randf() < join_chance:
			# Dołącz do bójki
			fight.participants.append(prisoner)
			fight.participant_ids.append(prisoner.prisoner_id)
			prisoner.change_state(Enums.PrisonerState.FIGHTING)

			# Zwiększ napięcie
			EventManager.add_tension(3.0)

			break  # Jeden na raz


func _should_end_fight(fight: FightData) -> bool:
	# Usuń nieważnych uczestników
	fight.participants = fight.participants.filter(
		func(p): return p != null and is_instance_valid(p)
	)

	# Sprawdź czy są jeszcze walczący
	var fighting_count: int = 0

	for prisoner in fight.participants:
		if prisoner.current_state == Enums.PrisonerState.FIGHTING:
			fighting_count += 1

	# Bójka kończy się gdy mniej niż 2 walczących
	return fighting_count < 2


func _end_fight(fight: FightData) -> void:
	fight.is_resolved = true

	# Zmień stan pozostałych więźniów
	for prisoner in fight.participants:
		if prisoner == null or not is_instance_valid(prisoner):
			continue

		if prisoner.current_state == Enums.PrisonerState.FIGHTING:
			prisoner.change_state(Enums.PrisonerState.IDLE)

	# Rozwiąż event
	if fight.event_id >= 0:
		EventManager.resolve_event(fight.event_id)

	# Emituj sygnał
	Signals.fight_ended.emit(fight.location, fight.injuries)

	# Zmniejsz napięcie
	EventManager.reduce_tension(2.0)


# =============================================================================
# OBSŁUGA SYGNAŁÓW
# =============================================================================
func _on_external_fight_started(location: Vector2i, prisoner_ids: Array) -> void:
	# Obsługa bójek rozpoczętych z zewnątrz (np. przez EventManager)
	# Sprawdź czy ta bójka już istnieje
	for fight in active_fights:
		if fight.location == location:
			return  # Już śledzona

	# Konwertuj ID na referencje
	var participants: Array = []
	for id in prisoner_ids:
		var prisoner = PrisonerManager.get_prisoner(id)
		if prisoner:
			participants.append(prisoner)

	if participants.size() >= MIN_PRISONERS_FOR_FIGHT:
		start_fight(location, participants)


func _on_prisoner_pacified(prisoner_id: int, _guard_id: int) -> void:
	# Usuń spacyfikowanego więźnia z bójek
	for fight in active_fights:
		for i in range(fight.participants.size() - 1, -1, -1):
			var prisoner = fight.participants[i]
			if prisoner and prisoner.prisoner_id == prisoner_id:
				fight.participants.remove_at(i)
				break


# =============================================================================
# API PUBLICZNE
# =============================================================================
func get_active_fights() -> Array[FightData]:
	return active_fights


func get_fight_count() -> int:
	return active_fights.size()


func has_active_fights() -> bool:
	return not active_fights.is_empty()


func get_fight_at_location(location: Vector2i) -> FightData:
	for fight in active_fights:
		if fight.location == location:
			return fight
	return null


func force_end_all_fights() -> void:
	for fight in active_fights:
		_end_fight(fight)
	active_fights.clear()


# =============================================================================
# SAVE/LOAD
# =============================================================================
func get_save_data() -> Dictionary:
	var fights_data: Array = []

	for fight in active_fights:
		fights_data.append({
			"id": fight.id,
			"location": [fight.location.x, fight.location.y],
			"participant_ids": fight.participant_ids,
			"start_time": fight.start_time,
			"duration": fight.duration,
			"injuries": fight.injuries,
			"event_id": fight.event_id
		})

	return {
		"fights": fights_data,
		"next_fight_id": _next_fight_id
	}


func load_save_data(data: Dictionary) -> void:
	active_fights.clear()
	_next_fight_id = data.get("next_fight_id", 1)

	for f_data in data.get("fights", []):
		var loc_arr: Array = f_data["location"]
		var loc := Vector2i(loc_arr[0], loc_arr[1])

		var fight := FightData.new(f_data["id"], loc)
		fight.participant_ids = f_data.get("participant_ids", [])
		fight.start_time = f_data.get("start_time", {})
		fight.duration = f_data.get("duration", 0.0)
		fight.injuries = f_data.get("injuries", 0)
		fight.event_id = f_data.get("event_id", -1)

		# Odtwórz referencje do więźniów
		for pid in fight.participant_ids:
			var prisoner = PrisonerManager.get_prisoner(pid)
			if prisoner:
				fight.participants.append(prisoner)

		active_fights.append(fight)
