extends Node2D
## Manages save slots selection UI
## Shows 3 save slots with level progress and clear buttons

signal closed

var save_manager: Node
var canvas_layer: CanvasLayer = null
var selected_slot: int = -1
var save_slot_controls: Array = []


func _ready() -> void:
	"""Initialize when added to scene."""
	save_manager = get_tree().root.get_node("SaveManager")
	
	# Collect save slot controls (Save Slot 01, 02, 03)
	for i in range(1, 4):
		var slot_control = get_node_or_null("Save Slot %02d" % i)
		if slot_control:
			save_slot_controls.append(slot_control)
			print("Found Save Slot %02d" % i)
	
	# Connect buttons
	var back_button = get_node_or_null("BackButton")
	var go_button = get_node_or_null("GoButton")
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if go_button:
		go_button.pressed.connect(_on_go_pressed)
	
	# Connect clear buttons and input for each slot
	for i in range(save_slot_controls.size()):
		var slot = save_slot_controls[i]
		
		# Enable input for this control
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		
		var clear_button = slot.get_node_or_null("ClearButton")
		if clear_button:
			clear_button.pressed.connect(_on_clear_slot_pressed.bindv([i]))
	
	# Initialize slot display info
	_update_all_slots()
	
	# Select first slot by default
	_select_slot(0)


func _input(event: InputEvent) -> void:
	"""Handle mouse click on save slots."""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Check which slot was clicked
		for i in range(save_slot_controls.size()):
			var slot = save_slot_controls[i]
			var slot_rect = slot.get_rect()
			var global_pos = slot.get_global_transform().origin
			var slot_global_rect = Rect2(global_pos, slot_rect.size)
			
			if slot_global_rect.has_point(get_global_mouse_position()):
				_select_slot(i)
				var audio = get_tree().root.get_node_or_null("AudioManager")
				if audio:
					audio.play_button_click()
				get_tree().root.set_input_as_handled()
				break


func _update_all_slots() -> void:
	"""Update display for all save slots."""
	for i in range(save_slot_controls.size()):
		_update_slot_display(i)


func _update_slot_display(slot_index: int) -> void:
	"""Update world and level labels for a slot."""
	if slot_index >= save_slot_controls.size():
		return
	
	var slot = save_slot_controls[slot_index]
	var world_label = slot.get_node_or_null("WorldLabel")
	var level_label = slot.get_node_or_null("LevelLabel1")
	
	# Get slot info from SaveManager
	var slot_info = save_manager.get_slot_info(slot_index)
	
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
			var world = parts[0]
			var level = parts[1]
			
			if world_label:
				world_label.text = world
			if level_label:
				level_label.text = level
		else:
			# Fallback if format is wrong
			if world_label:
				world_label.text = "1"
			if level_label:
				level_label.text = "1"


func _select_slot(slot_index: int) -> void:
	"""Select a save slot."""
	selected_slot = slot_index
	
	# Update visual feedback - highlight selected slot sprite
	for i in range(save_slot_controls.size()):
		# Find the sprite for this slot (SaveSlot01, SaveSlot02, SaveSlot03)
		var sprite = get_node_or_null("SaveSlot%02d" % (i + 1))
		if sprite:
			if i == slot_index:
				# Selected: bright outline effect
				sprite.self_modulate = Color(1.5, 1.5, 1.5, 1.0)
			else:
				# Unselected: normal color
				sprite.self_modulate = Color.WHITE
	
	print("Selected slot: %d" % slot_index)


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
	
	if selected_slot < 0 or selected_slot >= save_slot_controls.size():
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
	var audio_manager = get_tree().root.get_node_or_null("AudioManager")
	if audio_manager:
		audio_manager.play_button_click()
	
	save_manager.delete_slot(slot_index)
	
	# Refresh display
	_update_slot_display(slot_index)
	
	# If cleared slot was selected, deselect it
	if selected_slot == slot_index:
		selected_slot = -1
