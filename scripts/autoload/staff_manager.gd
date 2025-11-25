## StaffManager - Zarządzanie personelem
## Autoload singleton dostępny jako StaffManager
##
## Odpowiada za:
## - Zatrudnianie i zwalnianie personelu
## - Zarządzanie zmianami
## - Statystyki personelu
extends Node

# =============================================================================
# SCENY PERSONELU
# =============================================================================
const GuardScene := preload("res://scenes/entities/guard.tscn")
const StaffScene := preload("res://scenes/entities/staff.tscn")

# =============================================================================
# ZMIENNE
# =============================================================================
var staff_members: Dictionary = {}  # staff_id -> Staff node
var _next_staff_id: int = 1

# Kontener na personel w scenie
var _staff_container: Node2D = null

# Generator imion
const FIRST_NAMES: Array[String] = [
	"Anna", "Maria", "Katarzyna", "Agnieszka", "Barbara", "Ewa", "Krystyna",
	"Jan", "Piotr", "Andrzej", "Krzysztof", "Tomasz", "Paweł", "Michał",
	"Marcin", "Grzegorz", "Adam", "Stanisław", "Marek", "Łukasz", "Robert"
]

const LAST_NAMES: Array[String] = [
	"Nowak", "Kowalski", "Wiśniewski", "Wójcik", "Kowalczyk", "Kamiński",
	"Lewandowski", "Zieliński", "Szymański", "Woźniak", "Dąbrowski",
	"Kozłowski", "Jankowski", "Mazur", "Kwiatkowski", "Krawczyk"
]


# =============================================================================
# INICJALIZACJA
# =============================================================================
func _ready() -> void:
	Signals.hour_changed.connect(_on_hour_changed)
	Signals.day_changed.connect(_on_day_changed)


func set_container(container: Node2D) -> void:
	_staff_container = container


# =============================================================================
# ZATRUDNIANIE PERSONELU
# =============================================================================
func hire_staff(staff_type: Enums.StaffType, shift: Enums.Shift = Enums.Shift.MORNING) -> int:
	if _staff_container == null:
		push_error("StaffManager: Brak kontenera na personel!")
		return -1

	# Generuj dane
	var data := _generate_staff_data(staff_type, shift)

	# Przydziel ID
	var staff_id: int = _next_staff_id
	_next_staff_id += 1
	data["id"] = staff_id

	# Wybierz scenę na podstawie typu
	var staff_scene = GuardScene if staff_type == Enums.StaffType.GUARD else StaffScene
	var staff = staff_scene.instantiate()
	staff.initialize(data)

	# Pozycja startowa (posterunek lub recepcja)
	var spawn_pos: Vector2 = _get_spawn_position(staff_type)
	staff.position = spawn_pos

	# Dodaj do sceny i słownika
	_staff_container.add_child(staff)
	staff_members[staff_id] = staff

	# Aktualizuj EconomyManager
	EconomyManager.hire_staff(staff_type)

	# Emituj sygnał
	Signals.staff_hired.emit(staff_id, staff_type)

	return staff_id


func _generate_staff_data(staff_type: Enums.StaffType, shift: Enums.Shift) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var first_name: String = FIRST_NAMES[rng.randi() % FIRST_NAMES.size()]
	var last_name: String = LAST_NAMES[rng.randi() % LAST_NAMES.size()]

	return {
		"name": first_name + " " + last_name,
		"type": staff_type,
		"shift": shift,
		"morale": 100.0
	}


func _get_spawn_position(staff_type: Enums.StaffType) -> Vector2:
	# Znajdź odpowiedni budynek
	var spawn_building_type := Enums.BuildingType.GUARD_ROOM if staff_type == Enums.StaffType.GUARD else Enums.BuildingType.RECEPTION

	var buildings := BuildingManager.get_buildings_by_type(spawn_building_type)
	if buildings.size() > 0:
		var pos: Vector2i = buildings[0].position
		return GridManager.grid_to_world(pos)

	# Brak budynku - spawn na środku mapy
	return Vector2(
		Constants.GRID_WIDTH * Constants.TILE_SIZE / 2.0,
		Constants.GRID_HEIGHT * Constants.TILE_SIZE / 2.0
	)


# =============================================================================
# ZWALNIANIE PERSONELU
# =============================================================================
func fire_staff(staff_id: int) -> void:
	if not staff_members.has(staff_id):
		return

	var staff = staff_members[staff_id]

	# Aktualizuj EconomyManager
	EconomyManager.fire_staff(staff.staff_type)

	# Emituj sygnał
	Signals.staff_fired.emit(staff_id, staff.staff_type)

	# Usuń z gry
	staff_members.erase(staff_id)
	staff.queue_free()


# =============================================================================
# GETTERY
# =============================================================================
func get_staff(staff_id: int):
	return staff_members.get(staff_id)


func get_all_staff() -> Array:
	return staff_members.values()


func get_staff_count() -> int:
	return staff_members.size()


func get_staff_by_type(staff_type: Enums.StaffType) -> Array:
	var result: Array = []
	for staff in staff_members.values():
		if staff.staff_type == staff_type:
			result.append(staff)
	return result


func get_staff_by_shift(shift: Enums.Shift) -> Array:
	var result: Array = []
	for staff in staff_members.values():
		if staff.shift == shift:
			result.append(staff)
	return result


func get_on_duty_staff() -> Array:
	var result: Array = []
	for staff in staff_members.values():
		if staff.is_on_duty:
			result.append(staff)
	return result


func get_guards_on_duty() -> Array:
	var result: Array = []
	for staff in staff_members.values():
		if staff.staff_type == Enums.StaffType.GUARD and staff.is_on_duty:
			result.append(staff)
	return result


func get_staff_type_count(staff_type: Enums.StaffType) -> int:
	var count: int = 0
	for staff in staff_members.values():
		if staff.staff_type == staff_type:
			count += 1
	return count


func get_staff_by_type_counts() -> Dictionary:
	var counts: Dictionary = {}
	for t in Enums.StaffType.values():
		counts[t] = 0

	for staff in staff_members.values():
		counts[staff.staff_type] += 1

	return counts


# =============================================================================
# STATYSTYKI
# =============================================================================
func get_average_morale() -> float:
	if staff_members.size() == 0:
		return 100.0

	var total: float = 0.0
	for staff in staff_members.values():
		total += staff.morale

	return total / staff_members.size()


func get_daily_salary_cost() -> int:
	var total: int = 0
	for staff in staff_members.values():
		total += staff.salary
	return total


func get_low_morale_staff() -> Array:
	var result: Array = []
	for staff in staff_members.values():
		if staff.morale < 50.0:
			result.append(staff)
	return result


# =============================================================================
# SYGNAŁY EVENTÓW
# =============================================================================
func _on_hour_changed(_hour: int) -> void:
	# Personel automatycznie sprawdza zmiany
	pass


func _on_day_changed(_day: int) -> void:
	# Zmniejsz morale za każdy dzień pracy
	for staff in staff_members.values():
		staff.modify_morale(-1.0)


# =============================================================================
# WYSYŁANIE DO INCYDENTU
# =============================================================================
func dispatch_guard_to_fight(fight_location: Vector2i, prisoners: Array) -> void:
	var world_pos := GridManager.grid_to_world(fight_location)

	# Znajdź najbliższego wolnego strażnika
	var closest_guard = null
	var closest_distance: float = INF

	for staff in staff_members.values():
		if staff.staff_type != Enums.StaffType.GUARD:
			continue
		if not staff.is_on_duty:
			continue
		if staff.current_state == Enums.StaffState.PACIFYING:
			continue

		var distance := staff.global_position.distance_to(world_pos)
		if distance < closest_distance:
			closest_distance = distance
			closest_guard = staff

	if closest_guard:
		closest_guard.respond_to_fight(world_pos, prisoners)


# =============================================================================
# SAVE/LOAD
# =============================================================================
func get_save_data() -> Dictionary:
	var staff_data: Array = []
	for staff in staff_members.values():
		staff_data.append(staff.get_save_data())

	return {
		"staff": staff_data,
		"next_id": _next_staff_id
	}


func load_save_data(data: Dictionary) -> void:
	# Wyczyść obecny personel
	for staff in staff_members.values():
		staff.queue_free()
	staff_members.clear()

	_next_staff_id = data.get("next_id", 1)

	# Odtwórz personel
	for s_data in data.get("staff", []):
		if _staff_container:
			var staff_type: int = s_data.get("type", Enums.StaffType.GUARD)
			var staff_scene = GuardScene if staff_type == Enums.StaffType.GUARD else StaffScene
			var staff = staff_scene.instantiate()
			staff.load_save_data(s_data)
			_staff_container.add_child(staff)
			staff_members[staff.staff_id] = staff
