extends Node
## Manages game save data across 3 slots.
## Singleton - autoload from project settings.

const SAVE_PATH = "user://saves/"
const SAVE_FILE_PREFIX = "save_slot_"

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


func save_game(slot: int, level: String, attempts: int) -> bool:
	"""Save game state to a slot."""
	if slot < 0 or slot > 2:
		return false
	
	var save_data = {
		"level": level,
		"attempts": attempts,
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	var json_string = JSON.stringify(save_data)
	var file = FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for slot %d" % slot)
		return false
	
	file.store_string(json_string)
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
	
	return json.data as Dictionary


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
		"timestamp": data.get("timestamp", "")
	}


func auto_save(level: String, attempts: int) -> void:
	"""Auto-save to current slot when level is completed."""
	save_game(current_slot, level, attempts)


func set_current_slot(slot: int) -> void:
	"""Set which slot is active."""
	if slot >= 0 and slot <= 2:
		current_slot = slot


func load_and_start(slot: int) -> bool:
	"""Load save data and start that level."""
	if not slot_exists(slot):
		return false
	
	var data = load_game(slot)
	current_slot = slot
	
	# Load level scene
	var level_path = "res://MainScenes/Level " + data.get("level", "1-1") + ".tscn"
	
	# Update LevelManager with loaded data
	var level_manager = get_tree().root.get_node_or_null("LevelManager")
	if level_manager:
		level_manager.attempts = data.get("attempts", 0)
	
	get_tree().change_scene_to_file(level_path)
	return true


func delete_slot(slot: int) -> bool:
	"""Delete a save slot."""
	if DirAccess.dir_exists_absolute(SAVE_PATH):
		var dir = DirAccess.open(SAVE_PATH)
		if dir:
			return dir.remove(SAVE_FILE_PREFIX + str(slot) + ".json") == OK
	return false
