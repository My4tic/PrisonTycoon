## BuildingManager - System budowania
## Autoload singleton dostępny jako BuildingManager
##
## Odpowiada za:
## - Katalog typów budynków (z JSON)
## - Walidacja i umieszczanie budynków
## - Zarządzanie siatką zajętości
## - Integracja z ekonomią
extends Node

# =============================================================================
# ZMIENNE
# =============================================================================
# Katalog budynków załadowany z JSON
var building_catalog: Dictionary = {}

# Mapa zajętości siatki [Vector2i] -> building_id lub -1
var _grid_occupation: Dictionary = {}

# Lista wszystkich budynków w grze
var buildings: Dictionary = {}  # building_id -> BuildingData
var _next_building_id: int = 1

# Aktualnie wybierany budynek do budowy
var selected_building_type: Enums.BuildingType = Enums.BuildingType.CELL_SINGLE
var is_placing: bool = false

# =============================================================================
# KLASA DANYCH BUDYNKU
# =============================================================================
class BuildingData:
	var id: int
	var type: Enums.BuildingType
	var position: Vector2i  # Lewy górny róg
	var size: Vector2i
	var rotation: int = 0  # 0, 90, 180, 270
	var is_constructed: bool = false
	var current_occupancy: int = 0

	func _init(p_id: int, p_type: Enums.BuildingType, p_pos: Vector2i, p_size: Vector2i) -> void:
		id = p_id
		type = p_type
		position = p_pos
		size = p_size

	func get_cells() -> Array[Vector2i]:
		var cells: Array[Vector2i] = []
		for x in range(size.x):
			for y in range(size.y):
				cells.append(Vector2i(position.x + x, position.y + y))
		return cells


# =============================================================================
# FUNKCJE GODOT
# =============================================================================
func _ready() -> void:
	_load_building_catalog()


# =============================================================================
# ŁADOWANIE KATALOGU
# =============================================================================
func _load_building_catalog() -> void:
	var file_path := "res://data/buildings.json"

	if not FileAccess.file_exists(file_path):
		push_warning("BuildingManager: Brak pliku buildings.json, używam domyślnych wartości")
		_create_default_catalog()
		return

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("BuildingManager: Nie można otworzyć buildings.json")
		_create_default_catalog()
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("BuildingManager: Błąd parsowania JSON: " + json.get_error_message())
		_create_default_catalog()
		return

	building_catalog = json.data


func _create_default_catalog() -> void:
	building_catalog = {
		"CELL_SINGLE": {
			"name": "Cela pojedyncza",
			"category": "CELLS",
			"size": [3, 3],
			"cost": 1500,
			"capacity": 1,
			"effects": {"sleep": 100},
			"requirements": {}
		},
		"CELL_DOUBLE": {
			"name": "Cela podwójna",
			"category": "CELLS",
			"size": [4, 4],
			"cost": 2500,
			"capacity": 2,
			"effects": {"sleep": 100, "mood": 5},
			"requirements": {}
		},
		"DORMITORY": {
			"name": "Dormitorium",
			"category": "CELLS",
			"size": [8, 8],
			"cost": 6000,
			"capacity": 8,
			"effects": {"sleep": 100, "mood": -10},
			"requirements": {}
		},
		"KITCHEN": {
			"name": "Kuchnia",
			"category": "FOOD",
			"size": [6, 6],
			"cost": 3000,
			"capacity": 0,
			"effects": {},
			"requirements": {"staff": "COOK"}
		},
		"CANTEEN": {
			"name": "Kantyna",
			"category": "FOOD",
			"size": [10, 10],
			"cost": 5000,
			"capacity": 40,
			"effects": {"hunger": 30},
			"requirements": {"building": "KITCHEN"}
		},
		"YARD": {
			"name": "Podwórko",
			"category": "RECREATION",
			"size": [10, 10],
			"cost": 2000,
			"capacity": 30,
			"effects": {"freedom": 15, "mood": 10},
			"requirements": {}
		},
		"WORKSHOP_CARPENTRY": {
			"name": "Warsztat stolarski",
			"category": "WORK",
			"size": [8, 8],
			"cost": 8000,
			"capacity": 6,
			"effects": {"entertainment": 10},
			"requirements": {"staff": "GUARD"},
			"revenue": 500
		},
		"INFIRMARY": {
			"name": "Ambulatorium",
			"category": "INFRASTRUCTURE",
			"size": [5, 5],
			"cost": 4000,
			"capacity": 3,
			"effects": {"health": 100},
			"requirements": {"staff": "MEDIC"}
		},
		"SOLITARY": {
			"name": "Izolatka",
			"category": "CELLS",
			"size": [3, 3],
			"cost": 2000,
			"capacity": 1,
			"effects": {"mood": -50},
			"requirements": {}
		},
		"GUARD_ROOM": {
			"name": "Posterunek strażników",
			"category": "INFRASTRUCTURE",
			"size": [4, 4],
			"cost": 2500,
			"capacity": 4,
			"effects": {},
			"requirements": {}
		}
	}


# =============================================================================
# INFORMACJE O BUDYNKACH
# =============================================================================
func get_building_info(building_type: Enums.BuildingType) -> Dictionary:
	var type_name := Enums.BuildingType.keys()[building_type]
	if building_catalog.has(type_name):
		return building_catalog[type_name]
	return {}


func get_building_cost(building_type: Enums.BuildingType) -> int:
	var info := get_building_info(building_type)
	return info.get("cost", 0)


func get_building_size(building_type: Enums.BuildingType) -> Vector2i:
	var info := get_building_info(building_type)
	var size_array: Array = info.get("size", [1, 1])
	return Vector2i(size_array[0], size_array[1])


func get_building_name(building_type: Enums.BuildingType) -> String:
	var info := get_building_info(building_type)
	return info.get("name", "Nieznany")


# =============================================================================
# WALIDACJA BUDOWY
# =============================================================================
func can_build(building_type: Enums.BuildingType, grid_position: Vector2i) -> bool:
	var size := get_building_size(building_type)
	var cost := get_building_cost(building_type)

	# Sprawdź budżet
	if not EconomyManager.can_afford(cost):
		return false

	# Sprawdź czy wszystkie komórki są wolne
	for x in range(size.x):
		for y in range(size.y):
			var cell := Vector2i(grid_position.x + x, grid_position.y + y)
			if is_cell_occupied(cell):
				return false

			# Sprawdź granice mapy
			if cell.x < 0 or cell.x >= Constants.GRID_WIDTH:
				return false
			if cell.y < 0 or cell.y >= Constants.GRID_HEIGHT:
				return false

	return true


func get_placement_error(building_type: Enums.BuildingType, grid_position: Vector2i) -> String:
	var size := get_building_size(building_type)
	var cost := get_building_cost(building_type)

	if not EconomyManager.can_afford(cost):
		return "Niewystarczające środki ($%d potrzebne)" % cost

	for x in range(size.x):
		for y in range(size.y):
			var cell := Vector2i(grid_position.x + x, grid_position.y + y)
			if cell.x < 0 or cell.x >= Constants.GRID_WIDTH or cell.y < 0 or cell.y >= Constants.GRID_HEIGHT:
				return "Poza granicami mapy"
			if is_cell_occupied(cell):
				return "Teren zajęty"

	return ""


# =============================================================================
# BUDOWANIE
# =============================================================================
func place_building(building_type: Enums.BuildingType, grid_position: Vector2i) -> int:
	if not can_build(building_type, grid_position):
		var error := get_placement_error(building_type, grid_position)
		Signals.building_placement_failed.emit(error)
		return -1

	var cost := get_building_cost(building_type)
	var size := get_building_size(building_type)

	# Pobierz koszt
	EconomyManager.subtract_capital(cost, "construction")

	# Utwórz budynek
	var building_id := _next_building_id
	_next_building_id += 1

	var building := BuildingData.new(building_id, building_type, grid_position, size)
	buildings[building_id] = building

	# Zaznacz komórki jako zajęte
	for cell in building.get_cells():
		_grid_occupation[cell] = building_id

	# Emituj sygnały
	Signals.building_placed.emit(building_type, grid_position, size)
	Signals.navigation_update_required.emit()

	return building_id


func remove_building(building_id: int) -> bool:
	if not buildings.has(building_id):
		return false

	var building: BuildingData = buildings[building_id]

	# Zwolnij komórki
	for cell in building.get_cells():
		_grid_occupation.erase(cell)

	# Usuń budynek
	Signals.building_removed.emit(building.type, building.position)
	buildings.erase(building_id)
	Signals.navigation_update_required.emit()

	return true


func complete_building(building_id: int) -> void:
	if buildings.has(building_id):
		buildings[building_id].is_constructed = true
		Signals.building_completed.emit(building_id)


# =============================================================================
# SIATKA ZAJĘTOŚCI
# =============================================================================
func is_cell_occupied(cell: Vector2i) -> bool:
	return _grid_occupation.has(cell)


func get_building_at_cell(cell: Vector2i) -> int:
	return _grid_occupation.get(cell, -1)


func get_cells_in_rect(top_left: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(size.x):
		for y in range(size.y):
			cells.append(Vector2i(top_left.x + x, top_left.y + y))
	return cells


# =============================================================================
# POBIERANIE BUDYNKÓW
# =============================================================================
func get_building(building_id: int) -> BuildingData:
	return buildings.get(building_id)


func get_buildings_by_type(building_type: Enums.BuildingType) -> Array[BuildingData]:
	var result: Array[BuildingData] = []
	for building in buildings.values():
		if building.type == building_type:
			result.append(building)
	return result


func get_buildings_by_category(category: Enums.BuildingCategory) -> Array[BuildingData]:
	var result: Array[BuildingData] = []
	for building in buildings.values():
		var info := get_building_info(building.type)
		var cat_name := Enums.BuildingCategory.keys()[category]
		if info.get("category", "") == cat_name:
			result.append(building)
	return result


func get_total_capacity(building_type: Enums.BuildingType) -> int:
	var total := 0
	for building in get_buildings_by_type(building_type):
		var info := get_building_info(building.type)
		total += info.get("capacity", 0)
	return total


func count_buildings() -> int:
	return buildings.size()


# =============================================================================
# SAVE/LOAD
# =============================================================================
func get_save_data() -> Dictionary:
	var buildings_data := []
	for building in buildings.values():
		buildings_data.append({
			"id": building.id,
			"type": building.type,
			"position": [building.position.x, building.position.y],
			"size": [building.size.x, building.size.y],
			"is_constructed": building.is_constructed,
			"current_occupancy": building.current_occupancy
		})

	return {
		"buildings": buildings_data,
		"next_id": _next_building_id
	}


func load_save_data(data: Dictionary) -> void:
	buildings.clear()
	_grid_occupation.clear()

	_next_building_id = data.get("next_id", 1)

	for b_data in data.get("buildings", []):
		var pos := Vector2i(b_data["position"][0], b_data["position"][1])
		var size := Vector2i(b_data["size"][0], b_data["size"][1])
		var building := BuildingData.new(b_data["id"], b_data["type"], pos, size)
		building.is_constructed = b_data.get("is_constructed", true)
		building.current_occupancy = b_data.get("current_occupancy", 0)
		buildings[building.id] = building

		for cell in building.get_cells():
			_grid_occupation[cell] = building.id
