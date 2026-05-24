extends Node2D
## Manages save slots selection UI - same system as WorldLevelSelect
## Shows 3 save slots with level progress and clear buttons

signal closed

var save_manager: Node
var selected_slot: int = -1
var save_slot_sprites: Array = []  # Store sprite references for click detection


func _ready() -> void:
	"""Initialize when added to scene."""
	save_manager = get_tree().root.get_node("SaveManager")
	
	# Collect sprite references for click detection (SaveSlot01, 02, 03 inside each Control)
	for i in range(1, 4):
		# Navigate: Node > Save Slot 01 > SaveSlot01 (sprite)
		var slot_control = get_node_or_null("Save Slot %02d" % i)
		if slot_control:
			var sprite = slot_control.get_node_or_null("SaveSlot%02d" % i)
			if sprite:
				save_slot_sprites.append(sprite)
				print("✓ Found SaveSlot%02d sprite" % i)
			else:
				print("✗ SaveSlot%02d sprite NOT found in Save Slot %02d" % [i, i])
		else:
			print("✗ Save Slot %02d control NOT found" % i)
	
	# Connect buttons
	var back_button = get_node_or_null("BackButton")
	var go_button = get_node_or_null("GoButton")
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if go_button:
		go_button.pressed.connect(_on_go_pressed)
	
	# Connect clear buttons for each slot
	for i in range(1, 4):
		var slot_control = get_node_or_null("Save Slot %02d" % i)
		if slot_control:
			# Build clear button name dynamically (ClearButton, ClearButton2, ClearButton3)
			var clear_button_name = "ClearButton" + ("" if i == 1 else str(i))
			var clear_button = slot_control.get_node_or_null(clear_button_name)
			if clear_button:
				clear_button.pressed.connect(_on_clear_slot_pressed.bindv([i - 1]))
			else:
				print("✗ Clear button '%s' NOT found in Save Slot %02d" % [clear_button_name, i])
	
	# Initialize slot display info
	_update_all_slots()
	
	# Select first slot by default
	_select_slot(0)


func _update_all_slots() -> void:
	"""Update display for all save slots."""
	for i in range(1, 4):
		_update_slot_display(i - 1)


func _update_slot_display(slot_index: int) -> void:
	"""Update world and level labels for a slot."""
	var slot_control = get_node_or_null("Save Slot %02d" % (slot_index + 1))
	if not slot_control:
		print("✗ _update_slot_display: Save Slot %02d NOT found" % (slot_index + 1))
		return
	
	# Build node names dynamically based on slot index
	# Slot 0: WorldLabel, LevelLabel1
	# Slot 1: WorldLabel2, LevelLabel2
	# Slot 2: WorldLabel3, LevelLabel3
	var world_label_name = "WorldLabel" + ("" if slot_index == 0 else str(slot_index + 1))
	var level_label_name = "LevelLabel" + ("1" if slot_index == 0 else str(slot_index + 1))
	
	var world_label = slot_control.get_node_or_null(world_label_name)
	var level_label = slot_control.get_node_or_null(level_label_name)
	
	# Get slot info from SaveManager
	var slot_info = save_manager.get_slot_info(slot_index)
	print("Slot %d - looking for: %s, %s | level: %s, found: %s, %s" % [slot_index, world_label_name, level_label_name, slot_info.get("level", "ERROR"), world_label != null, level_label != null])
	
	if slot_info["empty"]:
		# Empty slot
		if world_label:
			world_label.text = "-"
		if level_label:
			level_label.text = "-"
	else:
		# Parse level string in format "X-Y" (e.g., "1-3" -> world 1, level 3)
		var level_str = slot_info.get("level", "1-1")
		var parts = level_str.split("-")
		
		if parts.size() == 2:
			if world_label:
				world_label.text = parts[0]
				print("  → Set WorldLabel to '%s'" % parts[0])
			if level_label:
				level_label.text = parts[1]
				print("  → Set LevelLabel to '%s'" % parts[1])
		else:
			# Fallback if format is wrong
			if world_label:
				world_label.text = "1"
			if level_label:
				level_label.text = "1"


func _input(event: InputEvent) -> void:
	"""Handle mouse input for slot selection - same system as WorldLevelSelect."""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Check if clicking on a ClearButton - if so, let the button handle it
		var global_mouse_pos = get_global_mouse_position()
		for i in range(1, 4):
			var slot_control = get_node_or_null("Save Slot %02d" % i)
			if slot_control:
				var clear_button_name = "ClearButton" + ("" if i == 1 else str(i))
				var clear_button = slot_control.get_node_or_null(clear_button_name)
				if clear_button:
					var button_rect = clear_button.get_global_rect()
					if button_rect.has_point(global_mouse_pos):
						# Don't handle this click - let the button's signal handle it
						return
		
		# Check which slot was clicked using sprite detection
		for i in range(save_slot_sprites.size()):
			var sprite = save_slot_sprites[i]
			
			# Calculate sprite's global rect (like WorldLevelSelect)
			var sprite_size = sprite.texture.get_size()
			var sprite_offset = Vector2.ZERO
			
			if sprite.centered:
				sprite_offset = sprite_size / 2
			
			var sprite_global_rect = Rect2(
				sprite.global_position - sprite_offset,
				sprite_size
			)
			
			# Check if mouse is over this sprite
			if sprite_global_rect.has_point(global_mouse_pos):
				_select_slot(i)
				var audio = get_tree().root.get_node_or_null("AudioManager")
				if audio:
					audio.play_button_click()
				get_tree().root.set_input_as_handled()
				break


func _select_slot(slot_index: int) -> void:
	"""Select a save slot and show outline effect."""
	selected_slot = slot_index
	
	# Update visual feedback - highlight selected slot sprite
	for i in range(save_slot_sprites.size()):
		var sprite = save_slot_sprites[i]
		if i == slot_index:
			# Selected: bright outline effect (1.5x brighter)
			sprite.self_modulate = Color(1.5, 1.5, 1.5, 1.0)
		else:
			# Unselected: normal color
			sprite.self_modulate = Color.WHITE



func _on_back_pressed() -> void:
	"""Handle back button - close this screen."""
	var audio_manager = get_tree().root.get_node_or_null("AudioManager")
	if audio_manager:
		audio_manager.play_button_click()
	
	closed.emit()
	queue_free()


func _on_go_pressed() -> void:
	"""Handle go button - load selected slot and go to WorldLevel."""
	var audio_manager = get_tree().root.get_node_or_null("AudioManager")
	if audio_manager:
		audio_manager.play_button_click()
	
	if selected_slot < 0 or selected_slot >= save_slot_sprites.size():
		push_error("No slot selected!")
		return
	
	save_manager.set_current_slot(selected_slot)
	
	# Wait for fade to complete BEFORE changing scene
	FadeTransitions.transition()
	await FadeTransitions.on_transition_finished
	
	# If slot doesn't exist, initialize it with first level
	if not save_manager.slot_exists(selected_slot):
		save_manager.save_game(selected_slot, "1-1", 0)
	
	# Now change scene to WorldLevel
	save_manager.load_and_start_world(selected_slot)


func _on_clear_slot_pressed(slot_index: int) -> void:
	"""Delete a save slot and refresh UI."""
	print("🗑️ Clearing slot %d..." % slot_index)
	
	var audio_manager = get_tree().root.get_node_or_null("AudioManager")
	if audio_manager:
		audio_manager.play_button_click()
	
	# Delete the slot file
	var deleted = save_manager.delete_slot(slot_index)
	print("  Delete result: %s" % deleted)
	
	# Refresh display to show empty
	_update_slot_display(slot_index)
	print("  Display updated for slot %d" % slot_index)
	
	# Deselect if this was selected
	if selected_slot == slot_index:
		selected_slot = -1
		print("  Slot was selected, now deselected")
	
	get_tree().root.set_input_as_handled()
