## ContrabandSystem - System zarządzania kontrabandą
## Autoload singleton dostępny jako ContrabandSystem
##
## Odpowiada za:
## - Generowanie kontrabandy u więźniów
## - System przeszukań
## - Wykrywanie przez detektory metalu
## - Efekty kontrabandy na więźniów
extends Node

# =============================================================================
# KLASA DANYCH KONTRABANDY
# =============================================================================
class ContrabandItem:
	var type: Enums.ContrabandType
	var owner_id: int  # ID więźnia
	var found: bool = false
	var confiscated: bool = false
	var acquisition_time: Dictionary

	func _init(p_type: Enums.ContrabandType, p_owner_id: int) -> void:
		type = p_type
		owner_id = p_owner_id
		acquisition_time = {
			"day": GameManager.current_day,
			"hour": GameManager.current_hour
		}


# =============================================================================
# ZMIENNE
# =============================================================================
# Kontrabanda u więźniów (prisoner_id -> Array[ContrabandItem])
var prisoner_contraband: Dictionary = {}

# Statystyki
var total_contraband_found: int = 0
var contraband_by_type: Dictionary = {
	Enums.ContrabandType.PHONE: 0,
	Enums.ContrabandType.DRUGS: 0,
	Enums.ContrabandType.KNIFE: 0,
	Enums.ContrabandType.ALCOHOL: 0,
	Enums.ContrabandType.TOOLS: 0
}

# Timer generowania kontrabandy
var _generation_timer: float = 0.0
const GENERATION_INTERVAL: float = 60.0  # Co minutę (game time)

# Parametry
const CONTRABAND_GENERATION_CHANCE: float = 0.05  # 5% na więźnia na interwał
const SEARCH_DETECTION_CHANCE: float = 0.6  # 60% szans na znalezienie przy przeszukaniu
const METAL_DETECTOR_CHANCE: float = 0.8  # 80% dla metalowych przedmiotów

# Przedmioty metalowe
const METAL_ITEMS: Array[Enums.ContrabandType] = [
	Enums.ContrabandType.PHONE,
	Enums.ContrabandType.KNIFE,
	Enums.ContrabandType.TOOLS
]


# =============================================================================
# FUNKCJE GODOT
# =============================================================================
func _ready() -> void:
	Signals.prisoner_arrived.connect(_on_prisoner_arrived)
	Signals.prisoner_released.connect(_on_prisoner_released)
	Signals.prisoner_died.connect(_on_prisoner_died)


func _process(delta: float) -> void:
	if not GameManager.is_playing() or GameManager.is_paused:
		return

	# Generuj kontrabandę
	_generation_timer += delta * GameManager.get_speed_multiplier()
	if _generation_timer >= GENERATION_INTERVAL:
		_generation_timer = 0.0
		_generate_contraband()


# =============================================================================
# GENEROWANIE KONTRABANDY
# =============================================================================
func _generate_contraband() -> void:
	var all_prisoners: Array = PrisonerManager.get_all_prisoners()

	for prisoner in all_prisoners:
		if prisoner == null or not is_instance_valid(prisoner):
			continue

		# Pomiń więźniów w izolatce
		if prisoner.current_state == Enums.PrisonerState.IN_SOLITARY:
			continue

		# Oblicz szansę na zdobycie kontrabandy
		var chance: float = CONTRABAND_GENERATION_CHANCE

		# Modyfikatory
		if prisoner.has_trait(Enums.PrisonerTrait.ADDICT):
			chance *= 2.0  # Uzależnieni szukają więcej

		if prisoner.has_trait(Enums.PrisonerTrait.ESCAPIST):
			chance *= 1.5  # Planujący ucieczkę szukają narzędzi

		if prisoner.get_need(Enums.PrisonerNeed.FREEDOM) < 30:
			chance *= 1.3  # Niska wolność = więcej prób

		# Rzut kostką
		if randf() < chance:
			var contraband_type := _select_contraband_type(prisoner)
			_give_contraband(prisoner.prisoner_id, contraband_type)


func _select_contraband_type(prisoner) -> Enums.ContrabandType:
	# Wybór typu zależny od cech i potrzeb
	var weights: Dictionary = {
		Enums.ContrabandType.PHONE: 3.0,
		Enums.ContrabandType.DRUGS: 2.0,
		Enums.ContrabandType.KNIFE: 1.5,
		Enums.ContrabandType.ALCOHOL: 2.0,
		Enums.ContrabandType.TOOLS: 1.0
	}

	# Modyfikatory z cech
	if prisoner.has_trait(Enums.PrisonerTrait.ADDICT):
		weights[Enums.ContrabandType.DRUGS] *= 3.0
		weights[Enums.ContrabandType.ALCOHOL] *= 2.0

	if prisoner.has_trait(Enums.PrisonerTrait.AGGRESSIVE):
		weights[Enums.ContrabandType.KNIFE] *= 2.0

	if prisoner.has_trait(Enums.PrisonerTrait.ESCAPIST):
		weights[Enums.ContrabandType.TOOLS] *= 3.0

	# Losowanie ważone
	var total_weight: float = 0.0
	for w in weights.values():
		total_weight += w

	var roll: float = randf() * total_weight
	var cumulative: float = 0.0

	for type in weights.keys():
		cumulative += weights[type]
		if roll <= cumulative:
			return type as Enums.ContrabandType

	return Enums.ContrabandType.PHONE


func _give_contraband(prisoner_id: int, type: Enums.ContrabandType) -> void:
	if not prisoner_contraband.has(prisoner_id):
		prisoner_contraband[prisoner_id] = []

	# Sprawdź czy więzień już ma ten typ
	var existing: Array = prisoner_contraband[prisoner_id]
	for item in existing:
		if item.type == type:
			return  # Już ma

	# Dodaj kontrabandę
	var item := ContrabandItem.new(type, prisoner_id)
	prisoner_contraband[prisoner_id].append(item)

	# Zastosuj efekty
	_apply_contraband_effects(prisoner_id, type)


# =============================================================================
# EFEKTY KONTRABANDY
# =============================================================================
func _apply_contraband_effects(prisoner_id: int, type: Enums.ContrabandType) -> void:
	var prisoner = PrisonerManager.get_prisoner(prisoner_id)
	if prisoner == null:
		return

	match type:
		Enums.ContrabandType.PHONE:
			# Telefon poprawia nastrój
			prisoner.satisfy_need(Enums.PrisonerNeed.ENTERTAINMENT, 20.0)

		Enums.ContrabandType.DRUGS:
			# Narkotyki - krótkoterminowa euforia, długoterminowe problemy
			prisoner.satisfy_need(Enums.PrisonerNeed.ENTERTAINMENT, 40.0)
			prisoner.satisfy_need(Enums.PrisonerNeed.FREEDOM, 20.0)
			# Ale też damage
			prisoner.take_damage(5.0, "drugs")

		Enums.ContrabandType.KNIFE:
			# Nóż zwiększa poczucie bezpieczeństwa (i agresję)
			prisoner.satisfy_need(Enums.PrisonerNeed.SAFETY, 30.0)

		Enums.ContrabandType.ALCOHOL:
			# Alkohol - podobnie do narkotyków
			prisoner.satisfy_need(Enums.PrisonerNeed.ENTERTAINMENT, 30.0)
			prisoner.take_damage(3.0, "alcohol")

		Enums.ContrabandType.TOOLS:
			# Narzędzia zwiększają szansę ucieczki (efekt w escape_system)
			prisoner.satisfy_need(Enums.PrisonerNeed.FREEDOM, 10.0)


# =============================================================================
# PRZESZUKANIA
# =============================================================================
func search_prisoner(prisoner_id: int, search_type: String = "manual") -> Array[ContrabandItem]:
	var found_items: Array[ContrabandItem] = []

	if not prisoner_contraband.has(prisoner_id):
		return found_items

	var items: Array = prisoner_contraband[prisoner_id]
	var items_to_remove: Array = []

	for item in items:
		var detection_chance: float = SEARCH_DETECTION_CHANCE

		match search_type:
			"manual":
				detection_chance = SEARCH_DETECTION_CHANCE
			"metal_detector":
				if item.type in METAL_ITEMS:
					detection_chance = METAL_DETECTOR_CHANCE
				else:
					detection_chance = 0.1  # Słaba szansa na niemetal
			"dog":
				if item.type == Enums.ContrabandType.DRUGS:
					detection_chance = 0.9  # Psy są świetne do narkotyków
				else:
					detection_chance = 0.3
			"thorough":
				detection_chance = 0.9  # Dokładne przeszukanie

		if randf() < detection_chance:
			item.found = true
			item.confiscated = true
			found_items.append(item)
			items_to_remove.append(item)

			# Aktualizuj statystyki
			total_contraband_found += 1
			contraband_by_type[item.type] += 1

			# Utwórz event
			var prisoner = PrisonerManager.get_prisoner(prisoner_id)
			if prisoner:
				var location := GridManager.world_to_grid(prisoner.global_position)
				EventManager.create_event(
					Enums.EventType.CONTRABAND,
					location,
					[prisoner_id] as Array[int]
				)
				EventManager.active_events[-1].data["contraband_type"] = item.type

			# Emituj sygnał
			Signals.contraband_found.emit(prisoner_id, item.type)

	# Usuń skonfiskowane
	for item in items_to_remove:
		items.erase(item)

	return found_items


func search_all_prisoners(search_type: String = "manual") -> Dictionary:
	var results: Dictionary = {
		"searched": 0,
		"found_count": 0,
		"items": []
	}

	var all_prisoners: Array = PrisonerManager.get_all_prisoners()

	for prisoner in all_prisoners:
		if prisoner == null or not is_instance_valid(prisoner):
			continue

		results["searched"] += 1
		var found := search_prisoner(prisoner.prisoner_id, search_type)

		if not found.is_empty():
			results["found_count"] += found.size()
			results["items"].append_array(found)

	return results


func search_area(location: Vector2i, radius: int, search_type: String = "manual") -> Dictionary:
	var results: Dictionary = {
		"searched": 0,
		"found_count": 0,
		"items": []
	}

	var world_pos := GridManager.grid_to_world(location)
	var search_radius: float = radius * Constants.TILE_SIZE

	var all_prisoners: Array = PrisonerManager.get_all_prisoners()

	for prisoner in all_prisoners:
		if prisoner == null or not is_instance_valid(prisoner):
			continue

		if prisoner.global_position.distance_to(world_pos) <= search_radius:
			results["searched"] += 1
			var found := search_prisoner(prisoner.prisoner_id, search_type)

			if not found.is_empty():
				results["found_count"] += found.size()
				results["items"].append_array(found)

	return results


# =============================================================================
# INFORMATORZY (SNITCH)
# =============================================================================
func check_for_snitch_reports() -> Array:
	var reports: Array = []

	var all_prisoners: Array = PrisonerManager.get_all_prisoners()

	for prisoner in all_prisoners:
		if prisoner == null or not is_instance_valid(prisoner):
			continue

		if not prisoner.has_trait(Enums.PrisonerTrait.SNITCH):
			continue

		# Szansa na donos
		if randf() < 0.3:  # 30% szansa
			# Znajdź więźniów z kontrabandą w pobliżu
			var nearby := _get_nearby_prisoners_with_contraband(prisoner, 5 * Constants.TILE_SIZE)

			if not nearby.is_empty():
				var target = nearby[randi() % nearby.size()]
				reports.append({
					"snitch_id": prisoner.prisoner_id,
					"target_id": target.prisoner_id,
					"location": GridManager.world_to_grid(target.global_position)
				})

	return reports


func _get_nearby_prisoners_with_contraband(snitch, radius: float) -> Array:
	var result: Array = []
	var all_prisoners: Array = PrisonerManager.get_all_prisoners()

	for prisoner in all_prisoners:
		if prisoner == null or not is_instance_valid(prisoner):
			continue
		if prisoner == snitch:
			continue

		if snitch.global_position.distance_to(prisoner.global_position) > radius:
			continue

		if has_contraband(prisoner.prisoner_id):
			result.append(prisoner)

	return result


# =============================================================================
# API PUBLICZNE
# =============================================================================
func has_contraband(prisoner_id: int) -> bool:
	if not prisoner_contraband.has(prisoner_id):
		return false
	return prisoner_contraband[prisoner_id].size() > 0


func get_contraband(prisoner_id: int) -> Array:
	if not prisoner_contraband.has(prisoner_id):
		return []
	return prisoner_contraband[prisoner_id]


func get_contraband_type_name(type: Enums.ContrabandType) -> String:
	match type:
		Enums.ContrabandType.PHONE:
			return "Telefon"
		Enums.ContrabandType.DRUGS:
			return "Narkotyki"
		Enums.ContrabandType.KNIFE:
			return "Nóż"
		Enums.ContrabandType.ALCOHOL:
			return "Alkohol"
		Enums.ContrabandType.TOOLS:
			return "Narzędzia"
		_:
			return "Nieznane"


func get_total_contraband_count() -> int:
	var count: int = 0
	for items in prisoner_contraband.values():
		count += items.size()
	return count


func get_statistics() -> Dictionary:
	return {
		"total_found": total_contraband_found,
		"by_type": contraband_by_type.duplicate(),
		"current_in_circulation": get_total_contraband_count()
	}


func prisoner_has_tools(prisoner_id: int) -> bool:
	if not prisoner_contraband.has(prisoner_id):
		return false

	for item in prisoner_contraband[prisoner_id]:
		if item.type == Enums.ContrabandType.TOOLS:
			return true

	return false


func prisoner_has_weapon(prisoner_id: int) -> bool:
	if not prisoner_contraband.has(prisoner_id):
		return false

	for item in prisoner_contraband[prisoner_id]:
		if item.type == Enums.ContrabandType.KNIFE:
			return true

	return false


# =============================================================================
# OBSŁUGA SYGNAŁÓW
# =============================================================================
func _on_prisoner_arrived(prisoner_id: int, _security_category: int) -> void:
	# Przeszukanie przy przybyciu
	var incoming_chance: float = 0.1  # 10% szansa na kontrabandę przy wejściu

	if randf() < incoming_chance:
		var type := _select_contraband_type_random()
		_give_contraband(prisoner_id, type)


func _on_prisoner_released(prisoner_id: int) -> void:
	# Wyczyść dane kontrabandy
	prisoner_contraband.erase(prisoner_id)


func _on_prisoner_died(prisoner_id: int, _cause: String) -> void:
	prisoner_contraband.erase(prisoner_id)


func _select_contraband_type_random() -> Enums.ContrabandType:
	var types := Enums.ContrabandType.values()
	return types[randi() % types.size()] as Enums.ContrabandType


# =============================================================================
# SAVE/LOAD
# =============================================================================
func get_save_data() -> Dictionary:
	var contraband_data: Dictionary = {}

	for prisoner_id in prisoner_contraband.keys():
		var items: Array = prisoner_contraband[prisoner_id]
		var items_data: Array = []

		for item in items:
			items_data.append({
				"type": item.type,
				"acquisition_time": item.acquisition_time
			})

		contraband_data[prisoner_id] = items_data

	return {
		"prisoner_contraband": contraband_data,
		"total_found": total_contraband_found,
		"by_type": contraband_by_type.duplicate()
	}


func load_save_data(data: Dictionary) -> void:
	prisoner_contraband.clear()
	total_contraband_found = data.get("total_found", 0)
	contraband_by_type = data.get("by_type", {
		Enums.ContrabandType.PHONE: 0,
		Enums.ContrabandType.DRUGS: 0,
		Enums.ContrabandType.KNIFE: 0,
		Enums.ContrabandType.ALCOHOL: 0,
		Enums.ContrabandType.TOOLS: 0
	})

	var contraband_data: Dictionary = data.get("prisoner_contraband", {})

	for prisoner_id in contraband_data.keys():
		var items_data: Array = contraband_data[prisoner_id]
		var items: Array = []

		for item_data in items_data:
			var item := ContrabandItem.new(
				item_data["type"] as Enums.ContrabandType,
				int(prisoner_id)
			)
			item.acquisition_time = item_data.get("acquisition_time", {})
			items.append(item)

		prisoner_contraband[int(prisoner_id)] = items
