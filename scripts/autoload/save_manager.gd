## SaveManager - System zapisu i wczytywania gry
## Autoload singleton dostępny jako SaveManager
##
## Odpowiada za:
## - Serializacja stanu gry do JSON
## - Zapis/odczyt z plików
## - Zarządzanie slotami zapisu
extends Node

# =============================================================================
# STAŁE
# =============================================================================
const SAVE_DIR := "user://saves/"
const SAVE_EXTENSION := ".json"
const MAX_SAVE_SLOTS := 5
const AUTOSAVE_SLOT := 0
const SETTINGS_FILE := "user://settings.json"

# =============================================================================
# ZMIENNE
# =============================================================================
var current_slot: int = -1
var autosave_enabled: bool = true
var autosave_interval_days: int = 1  # Co ile dni w grze autosave

var _last_autosave_day: int = 0

# =============================================================================
# FUNKCJE GODOT
# =============================================================================
func _ready() -> void:
	_ensure_save_directory()
	Signals.day_changed.connect(_on_day_changed)


func _ensure_save_directory() -> void:
	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")


# =============================================================================
# ZAPISYWANIE GRY
# =============================================================================
func save_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		Signals.save_failed.emit("Nieprawidłowy slot zapisu")
		return false

	var save_data := _collect_save_data()
	save_data["meta"] = _create_meta_data(slot)

	var json_string := JSON.stringify(save_data, "\t")
	var file_path := _get_save_path(slot)

	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		var error := FileAccess.get_open_error()
		Signals.save_failed.emit("Nie można otworzyć pliku: " + str(error))
		return false

	file.store_string(json_string)
	file.close()

	current_slot = slot
	Signals.game_saved.emit(slot)
	return true


func autosave() -> bool:
	if not autosave_enabled:
		return false
	return save_game(AUTOSAVE_SLOT)


func _collect_save_data() -> Dictionary:
	return {
		"game_manager": {
			"current_day": GameManager.current_day,
			"current_hour": GameManager.current_hour,
			"current_minute": GameManager.current_minute,
			"speed_index": GameManager.speed_index,
			"game_mode": GameManager.game_mode,
			"difficulty": GameManager.difficulty
		},
		"economy": EconomyManager.get_save_data(),
		"buildings": BuildingManager.get_save_data(),
		"schedule": ScheduleManager.get_save_data(),
		"events": EventManager.get_save_data(),
		# Dodatkowe managery będą dodane w przyszłych fazach
		# "prisoners": PrisonerManager.get_save_data(),
		# "staff": StaffManager.get_save_data(),
	}


func _create_meta_data(slot: int) -> Dictionary:
	return {
		"slot": slot,
		"timestamp": Time.get_datetime_string_from_system(),
		"game_version": ProjectSettings.get_setting("application/config/version", "0.1.0"),
		"day": GameManager.current_day,
		"capital": EconomyManager.capital,
		"playtime_seconds": 0  # TODO: Track total playtime
	}


# =============================================================================
# WCZYTYWANIE GRY
# =============================================================================
func load_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return false

	var file_path := _get_save_path(slot)
	if not FileAccess.file_exists(file_path):
		return false

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("SaveManager: Błąd parsowania zapisu: " + json.get_error_message())
		return false

	var save_data: Dictionary = json.data
	_apply_save_data(save_data)

	current_slot = slot
	Signals.game_loaded.emit(slot)
	return true


func _apply_save_data(data: Dictionary) -> void:
	# Game Manager
	if data.has("game_manager"):
		var gm: Dictionary = data["game_manager"]
		GameManager.current_day = gm.get("current_day", 1)
		GameManager.current_hour = gm.get("current_hour", 6)
		GameManager.current_minute = gm.get("current_minute", 0)
		GameManager.speed_index = gm.get("speed_index", 1)
		GameManager.game_mode = gm.get("game_mode", Enums.GameMode.CAMPAIGN)
		GameManager.difficulty = gm.get("difficulty", Enums.Difficulty.NORMAL)

	# Economy
	if data.has("economy"):
		EconomyManager.load_save_data(data["economy"])

	# Buildings
	if data.has("buildings"):
		BuildingManager.load_save_data(data["buildings"])

	# Schedule
	if data.has("schedule"):
		ScheduleManager.load_save_data(data["schedule"])

	# Events
	if data.has("events"):
		EventManager.load_save_data(data["events"])

	# Dodatkowe managery będą dodane w przyszłych fazach


# =============================================================================
# ZARZĄDZANIE SLOTAMI
# =============================================================================
func get_save_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []

	for i in range(MAX_SAVE_SLOTS):
		var slot_info := get_slot_info(i)
		slots.append(slot_info)

	return slots


func get_slot_info(slot: int) -> Dictionary:
	var file_path := _get_save_path(slot)

	if not FileAccess.file_exists(file_path):
		return {
			"slot": slot,
			"exists": false,
			"is_autosave": slot == AUTOSAVE_SLOT
		}

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {
			"slot": slot,
			"exists": false,
			"is_autosave": slot == AUTOSAVE_SLOT
		}

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) != OK:
		return {
			"slot": slot,
			"exists": false,
			"is_autosave": slot == AUTOSAVE_SLOT
		}

	var save_data: Dictionary = json.data
	var meta: Dictionary = save_data.get("meta", {})

	return {
		"slot": slot,
		"exists": true,
		"is_autosave": slot == AUTOSAVE_SLOT,
		"timestamp": meta.get("timestamp", "Unknown"),
		"day": meta.get("day", 0),
		"capital": meta.get("capital", 0),
		"game_version": meta.get("game_version", "Unknown")
	}


func delete_save(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		return false

	var file_path := _get_save_path(slot)
	if not FileAccess.file_exists(file_path):
		return false

	var dir := DirAccess.open(SAVE_DIR)
	if dir:
		return dir.remove(_get_save_filename(slot)) == OK

	return false


func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(_get_save_path(slot))


func _get_save_path(slot: int) -> String:
	return SAVE_DIR + _get_save_filename(slot)


func _get_save_filename(slot: int) -> String:
	if slot == AUTOSAVE_SLOT:
		return "autosave" + SAVE_EXTENSION
	return "save_" + str(slot) + SAVE_EXTENSION


# =============================================================================
# USTAWIENIA GRY
# =============================================================================
func save_settings(settings: Dictionary) -> bool:
	var json_string := JSON.stringify(settings, "\t")

	var file := FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(json_string)
	file.close()
	return true


func load_settings() -> Dictionary:
	if not FileAccess.file_exists(SETTINGS_FILE):
		return _get_default_settings()

	var file := FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	if file == null:
		return _get_default_settings()

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) != OK:
		return _get_default_settings()

	return json.data


func _get_default_settings() -> Dictionary:
	return {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"language": "pl",
		"autosave_enabled": true,
		"show_tutorial": true,
		"touch_sensitivity": 1.0
	}


# =============================================================================
# EVENTY
# =============================================================================
func _on_day_changed(day: int) -> void:
	# Autosave co X dni
	if autosave_enabled and (day - _last_autosave_day) >= autosave_interval_days:
		_last_autosave_day = day
		autosave()


# =============================================================================
# EKSPORT/IMPORT (opcjonalnie)
# =============================================================================
func export_save_to_string(slot: int) -> String:
	var file_path := _get_save_path(slot)
	if not FileAccess.file_exists(file_path):
		return ""

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return ""

	var content := file.get_as_text()
	file.close()

	# Encode do base64 dla łatwego kopiowania
	return Marshalls.utf8_to_base64(content)


func import_save_from_string(slot: int, encoded_data: String) -> bool:
	var json_string := Marshalls.base64_to_utf8(encoded_data)
	if json_string.is_empty():
		return false

	# Walidacja JSON
	var json := JSON.new()
	if json.parse(json_string) != OK:
		return false

	var file_path := _get_save_path(slot)
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(json_string)
	file.close()
	return true
