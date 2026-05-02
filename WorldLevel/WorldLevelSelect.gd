extends Node2D
## Manages the world level select screen with 8 levels per world

signal closed

var current_world: int = 1
var current_slot: int = 0
var selected_level: int = -1

var save_manager: Node
var folders: Array = []
var hovered_level: int = -1


func _ready() -> void:
	"""Initialize when added to scene."""
	save_manager = get_tree().root.get_node("SaveManager")
	
	# Connect button signals
	var back_button = $BackButton
	var go_button = $GoButton
	
	back_button.pressed.connect(_on_back_pressed)
	go_button.pressed.connect(_on_go_pressed)
	
	# Collect all folder references
	_gather_folders()


func initialize(world: int, slot: int) -> void:
	"""Initialize with world number and save slot."""
	current_world = world
	current_slot = slot
	
	# Update title
	$Number.text = "%02d" % world
	
	# Reload save manager reference (in case it wasn't available)
	save_manager = get_tree().root.get_node("SaveManager")
	
	# IMPORTANT: Hide all selection sprites at start
	for i in range(1, 9):
		var folder = get_node_or_null("FolderWL%d" % i)
		if folder:
			var selected_sprite = folder.get_node_or_null("FolderBaseSelected")
			if selected_sprite:
				selected_sprite.visible = false
	
	# Load attempts for each level
	_load_level_attempts()
	
	# Update appearance (locked = desaturated, unlocked = normal)
	_update_folder_appearance()
	
	# Select Level 1-1 by default
	if folders.size() > 0:
		_select_level(1)


func _gather_folders() -> void:
	"""Collect references to all FolderWL nodes."""
	for i in range(1, 9):
		var folder = get_node_or_null("FolderWL%d" % i)
		if folder:
			folders.append(folder)
			print("Gathered FolderWL%d at index %d" % [i, folders.size() - 1])
			# Connect folder selection signals
			_connect_folder(folder, i)


func _connect_folder(_folder: Node2D, _level_number: int) -> void:
	"""Connect input signals for a folder."""
	# No need to store level_number - it's already known by array index
	pass


func _input(event: InputEvent) -> void:
	"""Handle mouse input for folder clicks and hover."""
	if event is InputEventMouseMotion:
		# Check which folder the mouse is over
		var mouse_over_level = -1
		
		for i in range(folders.size()):
			var folder = folders[i]
			var folder_base = folder.get_node_or_null("FolderBase")
			
			if not folder_base:
				continue
			
			# Check if mouse is over this folder base
			var local_pos = folder_base.get_local_mouse_position()
			if folder_base.get_rect().has_point(local_pos):
				mouse_over_level = i + 1
				break
		
		# Handle hover effects (optional - just for visual feedback)
		hovered_level = mouse_over_level
	
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Check which folder was clicked using global position
		var global_mouse_pos = get_global_mouse_position()
		
		for i in range(folders.size()):
			var folder = folders[i]
			var folder_base = folder.get_node_or_null("FolderBase")
			
			if not folder_base:
				continue
			
			# Calculate the sprite's global rect
			var sprite_size = folder_base.texture.get_size()
			var sprite_offset = Vector2.ZERO
			
			if folder_base.centered:
				sprite_offset = sprite_size / 2
			
			var sprite_global_rect = Rect2(
				folder_base.global_position - sprite_offset,
				sprite_size
			)
			
			# Check if mouse is over this folder base and level is unlocked
			if sprite_global_rect.has_point(global_mouse_pos):
				var level_number = i + 1
				if _is_level_unlocked(level_number):
					_on_folder_clicked(level_number)
				break


func _load_level_attempts() -> void:
	"""Load and display attempts for each level."""
	for i in range(1, 9):
		var level_key = "%d-%d" % [current_world, i]
		var attempts = save_manager.get_level_attempts(current_slot, level_key)
		
		# Update the FolderWL AttemptsNumber label
		if i <= folders.size():
			var folder = folders[i - 1]
			var attempts_label = folder.get_node_or_null("AttemptsNumber")
			if attempts_label:
				if attempts == 0:
					attempts_label.text = "--"
				else:
					attempts_label.text = "%02d" % attempts


func _update_folder_appearance() -> void:
	"""Update folder colors based on lock status (locked = desaturated, unlocked = normal)."""
	for i in range(1, 9):
		if i <= folders.size():
			var folder = folders[i - 1]
			var folder_base = folder.get_node_or_null("FolderBase")
			
			if folder_base:
				if _is_level_unlocked(i):
					# Unlocked: normal color
					folder_base.self_modulate = Color.WHITE
				else:
					# Locked: desaturated (grayish)
					folder_base.self_modulate = Color(0.5, 0.5, 0.5, 1.0)


func _is_level_unlocked(level_number: int) -> bool:
	"""Check if a level is unlocked (can be played)."""
	# Level 1-1 is always unlocked
	if level_number == 1:
		return true
	
	# Other levels are unlocked if:
	# - Previous level was played (attempts > 0), OR
	# - Current level was played/completed (attempts > 0)
	var previous_level_key = "%d-%d" % [current_world, level_number - 1]
	var current_level_key = "%d-%d" % [current_world, level_number]
	
	var previous_attempts = save_manager.get_level_attempts(current_slot, previous_level_key)
	var current_attempts = save_manager.get_level_attempts(current_slot, current_level_key)
	
	# Unlocked if previous level was played OR current level has been played/completed
	return previous_attempts > 0 or current_attempts > 0


func _on_folder_clicked(level_number: int) -> void:
	"""Handle folder click - select this level."""
	_select_level(level_number)


func _select_level(level_number: int) -> void:
	"""Select a level and show the selection sprite."""
	print("_select_level called with level_number = %d, folders.size() = %d" % [level_number, folders.size()])
	
	# Hide previous selection if any
	if selected_level > 0 and selected_level <= folders.size():
		var old_folder = folders[selected_level - 1]
		var old_selected_sprite = old_folder.get_node_or_null("FolderBaseSelected")
		if old_selected_sprite:
			old_selected_sprite.visible = false
			print("Hidden FolderWL%d (index %d)" % [selected_level, selected_level - 1])
	
	# Update selected level
	selected_level = level_number
	
	# Show new selection
	if selected_level > 0 and selected_level <= folders.size():
		var new_folder = folders[selected_level - 1]
		var new_selected_sprite = new_folder.get_node_or_null("FolderBaseSelected")
		if new_selected_sprite:
			new_selected_sprite.visible = true
			print("Selected FolderWL%d (index %d) - sprite visible = %s" % [selected_level, selected_level - 1, new_selected_sprite.visible])


func _on_back_pressed() -> void:
	"""Handle back button - close this screen."""
	closed.emit()
	queue_free()


func _on_go_pressed() -> void:
	"""Handle go button - launch selected level."""
	if selected_level <= 0:
		push_error("No level selected!")
		return
	
	var level_name = "%d-%d" % [current_world, selected_level]
	
	# Update save manager's current slot and level
	save_manager.set_current_slot(current_slot)
	
	# DON'T save with attempts=0 here - only save when level is COMPLETED
	# This prevents contaminating the attempts logic
	print("Saved level entry: %s" % level_name)
	
	# Reset level manager for fresh attempt
	var level_manager = get_tree().root.get_node_or_null("LevelManager")
	if level_manager:
		level_manager.attempts = 1
		level_manager.reset_first_entry()
	
	# Load the level scene
	var level_scene = "res://MainScenes/Level %s.tscn" % level_name
	
	# Fade transition
	FadeTransitions.transition()
	await FadeTransitions.on_transition_finished
	
	# Clean up WorldLevelSelect before changing scene
	queue_free()
	
	get_tree().change_scene_to_file(level_scene)
