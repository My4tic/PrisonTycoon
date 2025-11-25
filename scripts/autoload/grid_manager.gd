## GridManager - Zarządzanie siatką i TileMap
## Autoload singleton dostępny jako GridManager
##
## Odpowiada za:
## - Operacje na TileMap (teren, podłogi, ściany)
## - Konwersja współrzędnych świat ↔ siatka
## - Rysowanie terenu i podłóg
## - Zarządzanie warstwami
extends Node

# =============================================================================
# STAŁE WARSTW
# =============================================================================
enum TileLayer {
	TERRAIN = 0,    # Trawa, ziemia, beton zewnętrzny
	FLOOR = 1,      # Podłogi wewnątrz budynków
	WALLS = 2,      # Ściany
	OBJECTS = 3     # Obiekty na podłodze (meble, sprzęt)
}

# ID źródeł w TileSet
enum TileSource {
	TERRAIN = 0,
	FLOOR = 1,
	WALLS = 2
}

# ID atlas coords dla różnych typów
const TERRAIN_GRASS := Vector2i(0, 0)
const TERRAIN_DIRT := Vector2i(1, 0)
const TERRAIN_CONCRETE := Vector2i(2, 0)

const FLOOR_CONCRETE := Vector2i(0, 0)
const FLOOR_WOOD := Vector2i(1, 0)
const FLOOR_TILE := Vector2i(2, 0)
const FLOOR_CELL := Vector2i(3, 0)

const WALL_WOOD := Vector2i(0, 0)
const WALL_BRICK := Vector2i(1, 0)
const WALL_CONCRETE := Vector2i(2, 0)
const WALL_STEEL := Vector2i(3, 0)

# Kolory dla placeholder tiles
const TILE_COLORS: Dictionary = {
	"terrain": [
		Color(0.35, 0.55, 0.25),  # Trawa - zielona
		Color(0.45, 0.35, 0.25),  # Ziemia - brązowa
		Color(0.5, 0.5, 0.5),     # Beton - szara
	],
	"floor": [
		Color(0.6, 0.6, 0.6),     # Beton - jasnoszara
		Color(0.55, 0.4, 0.25),   # Drewno - brązowa
		Color(0.8, 0.8, 0.75),    # Płytki - kremowa
		Color(0.4, 0.45, 0.5),    # Cela - ciemnoszara
	],
	"walls": [
		Color(0.5, 0.35, 0.2),    # Drewno - ciemnobrązowa
		Color(0.7, 0.35, 0.3),    # Cegła - czerwona
		Color(0.55, 0.55, 0.55),  # Beton - szara
		Color(0.4, 0.45, 0.5),    # Stal - metaliczna
	]
}

# =============================================================================
# ZMIENNE
# =============================================================================
var tilemap: TileMap = null
var _map_width: int = Constants.GRID_WIDTH
var _map_height: int = Constants.GRID_HEIGHT
var _tileset: TileSet = null

# Cache dla szybkiego sprawdzania
var _walkable_cache: Dictionary = {}  # Vector2i -> bool


# =============================================================================
# INICJALIZACJA
# =============================================================================
func _ready() -> void:
	Signals.building_placed.connect(_on_building_placed)
	Signals.building_removed.connect(_on_building_removed)


func initialize(map: TileMap) -> void:
	tilemap = map
	if tilemap == null:
		push_error("GridManager: TileMap is null!")
		return

	# Utwórz TileSet jeśli nie ma
	if tilemap.tile_set == null:
		_create_placeholder_tileset()
	else:
		_tileset = tilemap.tile_set

	# Upewnij się że mamy wystarczająco warstw
	_ensure_layers()

	_setup_initial_terrain()
	_rebuild_walkable_cache()


func _create_placeholder_tileset() -> void:
	_tileset = TileSet.new()
	_tileset.tile_size = Vector2i(Constants.TILE_SIZE, Constants.TILE_SIZE)

	# Utwórz źródła dla każdego typu
	_create_tile_source(TileSource.TERRAIN, TILE_COLORS["terrain"])
	_create_tile_source(TileSource.FLOOR, TILE_COLORS["floor"])
	_create_tile_source(TileSource.WALLS, TILE_COLORS["walls"])

	tilemap.tile_set = _tileset
	print("GridManager: Created placeholder TileSet")


func _create_tile_source(source_id: int, colors: Array) -> void:
	var tile_count: int = colors.size()
	var atlas_width: int = tile_count * Constants.TILE_SIZE
	var atlas_height: int = Constants.TILE_SIZE

	# Utwórz obraz atlasu
	var atlas_image: Image = Image.create(atlas_width, atlas_height, false, Image.FORMAT_RGBA8)

	for i in range(tile_count):
		var color: Color = colors[i]
		var start_x: int = i * Constants.TILE_SIZE

		# Wypełnij tile kolorem z delikatnym gradientem dla głębi
		for x in range(Constants.TILE_SIZE):
			for y in range(Constants.TILE_SIZE):
				var px: int = start_x + x
				# Dodaj subtelną teksturę
				var noise_value: float = 0.95 + randf() * 0.1
				var edge_darken: float = 1.0

				# Ciemniejsze krawędzie dla efektu 3D
				if x < 2 or y < 2:
					edge_darken = 1.1  # Jaśniejsza krawędź (światło)
				elif x >= Constants.TILE_SIZE - 2 or y >= Constants.TILE_SIZE - 2:
					edge_darken = 0.85  # Ciemniejsza krawędź (cień)

				var final_color: Color = Color(
					clampf(color.r * noise_value * edge_darken, 0.0, 1.0),
					clampf(color.g * noise_value * edge_darken, 0.0, 1.0),
					clampf(color.b * noise_value * edge_darken, 0.0, 1.0),
					1.0
				)
				atlas_image.set_pixel(px, y, final_color)

	# Utwórz teksturę z obrazu
	var atlas_texture: ImageTexture = ImageTexture.create_from_image(atlas_image)

	# Utwórz źródło atlasu
	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = atlas_texture
	source.texture_region_size = Vector2i(Constants.TILE_SIZE, Constants.TILE_SIZE)

	# Dodaj źródło do TileSet
	_tileset.add_source(source, source_id)

	# Utwórz tile dla każdego koloru
	for i in range(tile_count):
		source.create_tile(Vector2i(i, 0))


func _ensure_layers() -> void:
	# Upewnij się że TileMap ma wszystkie potrzebne warstwy
	while tilemap.get_layers_count() < 4:
		tilemap.add_layer(-1)

	# Nazwij warstwy
	tilemap.set_layer_name(TileLayer.TERRAIN, "Terrain")
	tilemap.set_layer_name(TileLayer.FLOOR, "Floor")
	tilemap.set_layer_name(TileLayer.WALLS, "Walls")
	tilemap.set_layer_name(TileLayer.OBJECTS, "Objects")

	# Ustaw Z-index dla warstw
	tilemap.set_layer_z_index(TileLayer.TERRAIN, 0)
	tilemap.set_layer_z_index(TileLayer.FLOOR, 1)
	tilemap.set_layer_z_index(TileLayer.WALLS, 2)
	tilemap.set_layer_z_index(TileLayer.OBJECTS, 3)


func _setup_initial_terrain() -> void:
	if tilemap == null:
		return

	# Wypełnij całą mapę trawą
	for x in range(_map_width):
		for y in range(_map_height):
			set_terrain(Vector2i(x, y), TERRAIN_GRASS)


# =============================================================================
# OPERACJE NA TERENIE
# =============================================================================
func set_terrain(cell: Vector2i, atlas_coords: Vector2i) -> void:
	if tilemap == null:
		return
	tilemap.set_cell(TileLayer.TERRAIN, cell, TileSource.TERRAIN, atlas_coords)


func get_terrain(cell: Vector2i) -> Vector2i:
	if tilemap == null:
		return Vector2i(-1, -1)
	return tilemap.get_cell_atlas_coords(TileLayer.TERRAIN, cell)


func clear_terrain(cell: Vector2i) -> void:
	if tilemap == null:
		return
	tilemap.erase_cell(TileLayer.TERRAIN, cell)


# =============================================================================
# OPERACJE NA PODŁOGACH
# =============================================================================
func set_floor(cell: Vector2i, atlas_coords: Vector2i) -> void:
	if tilemap == null:
		return
	tilemap.set_cell(TileLayer.FLOOR, cell, TileSource.FLOOR, atlas_coords)
	_walkable_cache[cell] = true


func get_floor(cell: Vector2i) -> Vector2i:
	if tilemap == null:
		return Vector2i(-1, -1)
	return tilemap.get_cell_atlas_coords(TileLayer.FLOOR, cell)


func has_floor(cell: Vector2i) -> bool:
	if tilemap == null:
		return false
	return tilemap.get_cell_source_id(TileLayer.FLOOR, cell) != -1


func clear_floor(cell: Vector2i) -> void:
	if tilemap == null:
		return
	tilemap.erase_cell(TileLayer.FLOOR, cell)
	_walkable_cache.erase(cell)


func fill_floor_rect(top_left: Vector2i, size: Vector2i, atlas_coords: Vector2i) -> void:
	for x in range(size.x):
		for y in range(size.y):
			set_floor(Vector2i(top_left.x + x, top_left.y + y), atlas_coords)


# =============================================================================
# OPERACJE NA ŚCIANACH
# =============================================================================
func set_wall(cell: Vector2i, atlas_coords: Vector2i) -> void:
	if tilemap == null:
		return
	tilemap.set_cell(TileLayer.WALLS, cell, TileSource.WALLS, atlas_coords)
	_walkable_cache[cell] = false


func get_wall(cell: Vector2i) -> Vector2i:
	if tilemap == null:
		return Vector2i(-1, -1)
	return tilemap.get_cell_atlas_coords(TileLayer.WALLS, cell)


func has_wall(cell: Vector2i) -> bool:
	if tilemap == null:
		return false
	return tilemap.get_cell_source_id(TileLayer.WALLS, cell) != -1


func clear_wall(cell: Vector2i) -> void:
	if tilemap == null:
		return
	tilemap.erase_cell(TileLayer.WALLS, cell)
	# Sprawdź czy jest podłoga pod spodem
	_walkable_cache[cell] = has_floor(cell)


func draw_wall_rect(top_left: Vector2i, size: Vector2i, atlas_coords: Vector2i, fill_inside: bool = false) -> void:
	# Rysuj obwód prostokąta
	for x in range(size.x):
		set_wall(Vector2i(top_left.x + x, top_left.y), atlas_coords)  # Góra
		set_wall(Vector2i(top_left.x + x, top_left.y + size.y - 1), atlas_coords)  # Dół

	for y in range(1, size.y - 1):
		set_wall(Vector2i(top_left.x, top_left.y + y), atlas_coords)  # Lewa
		set_wall(Vector2i(top_left.x + size.x - 1, top_left.y + y), atlas_coords)  # Prawa

	# Opcjonalnie wypełnij wnętrze podłogą
	if fill_inside and size.x > 2 and size.y > 2:
		fill_floor_rect(
			Vector2i(top_left.x + 1, top_left.y + 1),
			Vector2i(size.x - 2, size.y - 2),
			FLOOR_CONCRETE
		)


# =============================================================================
# KONWERSJA WSPÓŁRZĘDNYCH
# =============================================================================
func world_to_grid(world_pos: Vector2) -> Vector2i:
	if tilemap == null:
		return Vector2i(
			floori(world_pos.x / Constants.TILE_SIZE),
			floori(world_pos.y / Constants.TILE_SIZE)
		)
	return tilemap.local_to_map(world_pos)


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	if tilemap == null:
		return Vector2(
			grid_pos.x * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0,
			grid_pos.y * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0
		)
	return tilemap.map_to_local(grid_pos)


func grid_to_world_corner(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * Constants.TILE_SIZE,
		grid_pos.y * Constants.TILE_SIZE
	)


# =============================================================================
# SPRAWDZANIE KOMÓREK
# =============================================================================
func is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < _map_width and cell.y >= 0 and cell.y < _map_height


func is_walkable(cell: Vector2i) -> bool:
	if not is_valid_cell(cell):
		return false

	if _walkable_cache.has(cell):
		return _walkable_cache[cell]

	# Domyślnie teren jest przechodni
	return true


func is_buildable(cell: Vector2i) -> bool:
	if not is_valid_cell(cell):
		return false

	# Sprawdź czy nie ma ściany ani budynku
	if has_wall(cell):
		return false

	if BuildingManager.is_cell_occupied(cell):
		return false

	return true


func get_cells_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			var cell := Vector2i(x, y)
			if is_valid_cell(cell):
				var distance: float = Vector2(center).distance_to(Vector2(cell))
				if distance <= radius:
					cells.append(cell)

	return cells


func get_neighbors(cell: Vector2i, include_diagonals: bool = false) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []

	# Kardynalne kierunki
	var directions: Array[Vector2i] = [
		Vector2i(0, -1),  # Góra
		Vector2i(1, 0),   # Prawo
		Vector2i(0, 1),   # Dół
		Vector2i(-1, 0)   # Lewo
	]

	if include_diagonals:
		directions.append(Vector2i(-1, -1))  # Góra-lewo
		directions.append(Vector2i(1, -1))   # Góra-prawo
		directions.append(Vector2i(1, 1))    # Dół-prawo
		directions.append(Vector2i(-1, 1))   # Dół-lewo

	for dir in directions:
		var neighbor := cell + dir
		if is_valid_cell(neighbor):
			neighbors.append(neighbor)

	return neighbors


# =============================================================================
# CACHE WALKABLE
# =============================================================================
func _rebuild_walkable_cache() -> void:
	_walkable_cache.clear()

	if tilemap == null:
		return

	# Zaznacz wszystkie komórki z podłogą jako przechodnie
	var floor_cells: Array[Vector2i] = tilemap.get_used_cells(TileLayer.FLOOR)
	for cell in floor_cells:
		_walkable_cache[cell] = true

	# Zaznacz wszystkie komórki ze ścianami jako nieprzechodnie
	var wall_cells: Array[Vector2i] = tilemap.get_used_cells(TileLayer.WALLS)
	for cell in wall_cells:
		_walkable_cache[cell] = false


func invalidate_cache() -> void:
	_rebuild_walkable_cache()


# =============================================================================
# EVENTY
# =============================================================================
func _on_building_placed(building_type: int, position: Vector2i, size: Vector2i) -> void:
	# Gdy budynek zostanie umieszczony, wypełnij podłogę
	var floor_type := _get_floor_for_building(building_type)
	fill_floor_rect(position, size, floor_type)

	# Aktualizuj cache
	for x in range(size.x):
		for y in range(size.y):
			_walkable_cache[Vector2i(position.x + x, position.y + y)] = true


func _on_building_removed(building_type: int, position: Vector2i) -> void:
	# Pobierz rozmiar budynku
	var size: Vector2i = BuildingManager.get_building_size(building_type)

	# Usuń podłogę
	for x in range(size.x):
		for y in range(size.y):
			clear_floor(Vector2i(position.x + x, position.y + y))


func _get_floor_for_building(building_type: int) -> Vector2i:
	# Różne typy podłóg dla różnych budynków
	match building_type:
		Enums.BuildingType.CELL_SINGLE, Enums.BuildingType.CELL_DOUBLE, \
		Enums.BuildingType.DORMITORY, Enums.BuildingType.SOLITARY:
			return FLOOR_CELL
		Enums.BuildingType.WORKSHOP_CARPENTRY, Enums.BuildingType.LAUNDRY:
			return FLOOR_CONCRETE
		Enums.BuildingType.LIBRARY, Enums.BuildingType.CHAPEL:
			return FLOOR_WOOD
		_:
			return FLOOR_TILE


# =============================================================================
# DEBUG
# =============================================================================
func get_map_bounds() -> Rect2i:
	return Rect2i(0, 0, _map_width, _map_height)


func get_walkable_cell_count() -> int:
	var count: int = 0
	for walkable in _walkable_cache.values():
		if walkable:
			count += 1
	return count
