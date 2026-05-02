extends Node
## Manages game save data across 3 slots with world progression and attempt tracking.
## Singleton - autoload from project settings.

const SAVE_PATH = "user://saves/"
const SAVE_FILE_PREFIX = "save_slot_"
const TOTAL_WORLDS = 10  # Total number of worlds (planets)
const LEVELS_PER_WORLD = 8  # 8 levels per world

var current_slot: int = 0  # Currently active slot (0, 1, 2)


func _ready() -> void:
	"""Initialize save directory."""
	if not DirAccess.dir_exists_absolute(SAVE_PATH):
		DirAccess.make_dir_absolute(SAVE_PATH)


func get_save_path(slot: int) -> String:
	"""Get file path for a save slot."""
	return SAVE_PATH + SAVE_FILE_PREFIX + str(slot) + ".json"


func slot_exists(slot: int) -> bool:
	"""Check if a save slot has data."""
	var file = FileAccess.open(get_save_path(slot), FileAccess.READ)
	return file != null


func _create_default_attempts_dict() -> Dictionary:
	"""Create default attempts dictionary for all worlds/levels."""
	var attempts = {}
	for world in range(1, TOTAL_WORLDS + 1):
		for level in range(1, LEVELS_PER_WORLD + 1):
			var key = "%d-%d" % [world, level]
			attempts[key] = 0
	return attempts


func save_game(slot: int, level: String, attempts: int) -> bool:
	"""Save game state to a slot."""
	if slot < 0 or slot > 2:
		return false
	
	# Load existing data to preserve world progress
	var existing_data = load_game(slot)
	var world_attempts = existing_data.get("world_attempts", _create_default_attempts_dict())
	var world_unlocked = existing_data.get("world_unlocked", 1)
	
	# Update attempts for this level only if:
	# - It's the first attempt (current == 0) and new attempts > 0, OR
	# - It's a level entry (attempts == 0) and current == 0, OR
	# - It's a new record (attempts > 0 and attempts < current)
	var current_attempts = world_attempts.get(level, 0)
	
	if attempts == 0:
		# Level entry/start: only set if never played before (current == 0)
		if current_attempts == 0:
			world_attempts[level] = 0
	else:
		# Level completion: only update if better record or first time
		if attempts < current_attempts or current_attempts == 0:
			world_attempts[level] = attempts
	
	var save_data = {
		"level": level,
		"attempts": attempts,
		"world_unlocked": world_unlocked,
		"world_attempts": world_attempts,
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	var json_string = JSON.stringify(save_data)
	var file = FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for slot %d" % slot)
		return false
	
	file.store_string(json_string)
	print("SaveManager - save_game guardado: ", level, " with ", world_attempts.get(level, 0), " attempts")
	return true


func load_game(slot: int) -> Dictionary:
	"""Load game state from a slot. Returns empty dict if slot doesn't exist."""
	if not slot_exists(slot):
		return {}
	
	var file = FileAccess.open(get_save_path(slot), FileAccess.READ)
	if file == null:
		return {}
	
	var json_string = file.get_as_text()
	var json = JSON.new()
	if json.parse(json_string) != OK:
		push_error("Failed to parse save file for slot %d" % slot)
		return {}
	
	var data = json.data as Dictionary
	
	# Ensure world_attempts dict exists (for backwards compatibility)
	if not data.has("world_attempts"):
		data["world_attempts"] = _create_default_attempts_dict()
	
	# Ensure world_unlocked exists
	if not data.has("world_unlocked"):
		data["world_unlocked"] = 1
	
	return data


func get_slot_info(slot: int) -> Dictionary:
	"""Get display info for a slot (level name, etc)."""
	var data = load_game(slot)
	if data.is_empty():
		return {"empty": true, "display": "Empty Slot"}
	
	return {
		"empty": false,
		"level": data.get("level", "Unknown"),
		"attempts": data.get("attempts", 0),
		"display": "Level " + data.get("level", "Unknown"),
		"timestamp": data.get("timestamp", ""),
		"world_unlocked": data.get("world_unlocked", 1)
	}


func get_level_attempts(slot: int, level_key: String) -> int:
	"""Get recorded attempts for a specific level (format: '1-1', '1-2', etc)."""
	var data = load_game(slot)
	if data.is_empty():
		return 0
	
	var attempts = data.get("world_attempts", {})
	return attempts.get(level_key, 0)


func update_level_attempts(slot: int, level_key: String, new_attempts: int) -> bool:
	"""Update attempts for a level only if new_attempts is lower than current record."""
	var data = load_game(slot)
	if data.is_empty():
		return false
	
	var world_attempts = data.get("world_attempts", _create_default_attempts_dict())
	var current_attempts = world_attempts.get(level_key, 0)
	
	# Only update if the new record is better (lower)
	if new_attempts < current_attempts or current_attempts == 0:
		world_attempts[level_key] = new_attempts
		data["world_attempts"] = world_attempts
		
		# Save updated data
		var json_string = JSON.stringify(data)
		var file = FileAccess.open(get_save_path(slot), FileAccess.WRITE)
		if file == null:
			push_error("Failed to open save file for slot %d" % slot)
			return false
		
		file.store_string(json_string)
		return true
	
	return false


func get_world_unlocked(slot: int) -> int:
	"""Get the highest unlocked world number for a slot."""
	var data = load_game(slot)
	if data.is_empty():
		return 1  # First world always unlocked
	
	return data.get("world_unlocked", 1)


func unlock_world(slot: int, world_number: int) -> bool:
	"""Unlock a world for a slot (world_number: 1-10)."""
	if world_number < 1 or world_number > TOTAL_WORLDS:
		return false
	
	var data = load_game(slot)
	if data.is_empty():
		return false
	
	var current_world = data.get("world_unlocked", 1)
	
	# Only unlock if it's the next world
	if world_number == current_world + 1:
		data["world_unlocked"] = world_number
		
		var json_string = JSON.stringify(data)
		var file = FileAccess.open(get_save_path(slot), FileAccess.WRITE)
		if file == null:
			push_error("Failed to open save file for slot %d" % slot)
			return false
		
		file.store_string(json_string)
		return true
	
	return false


func is_world_unlocked(slot: int, world_number: int) -> bool:
	"""Check if a world is unlocked."""
	var unlocked_world = get_world_unlocked(slot)
	return world_number <= unlocked_world


func auto_save(level: String, attempts: int) -> void:
	"""Auto-save to current slot when level is completed."""
	save_game(current_slot, level, attempts)
	
	# Check if we should unlock the next world
	# level format: "1-1", "1-8", "2-1", etc.
	var level_parts = level.split("-")
	if level_parts.size() == 2:
		var world = int(level_parts[0])
		var level_num = int(level_parts[1])
		
		# If player completed the last level of a world, unlock next world
		if level_num == LEVELS_PER_WORLD and world < TOTAL_WORLDS:
			unlock_world(current_slot, world + 1)


func set_current_slot(slot: int) -> void:
	"""Set which slot is active."""
	if slot >= 0 and slot <= 2:
		current_slot = slot


func load_and_start_world(slot: int) -> bool:
	"""Load save data and start WorldLevel."""
	if not slot_exists(slot):
		return false
	
	current_slot = slot
	
	# Load WorldLevel scene
	get_tree().change_scene_to_file("res://WorldLevel/WorldLevel.tscn")
	return true


func load_and_start(slot: int) -> bool:
	"""Load save data and start that level (legacy - now goes to WorldLevel)."""
	return load_and_start_world(slot)


func delete_slot(slot: int) -> bool:
	"""Delete a save slot."""
	if DirAccess.dir_exists_absolute(SAVE_PATH):
		var dir = DirAccess.open(SAVE_PATH)
		if dir:
			return dir.remove(SAVE_FILE_PREFIX + str(slot) + ".json") == OK
	return false
