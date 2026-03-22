extends Node2D

var save_slots_panel: Control = null
var save_slot_buttons: Array = []
var canvas_layer: CanvasLayer = null


func _ready() -> void:
	"""Initialize and create save slots panel."""
	# Find or create CanvasLayer
	canvas_layer = get_tree().root.get_node_or_null("Main/CanvasLayer")
	if not canvas_layer:
		# Try to find in this scene
		canvas_layer = get_node_or_null("CanvasLayer")
	
	if not canvas_layer:
		print("ERROR: CanvasLayer not found!")
		return
	
	_create_save_slots_ui()


func _create_save_slots_ui() -> void:
	"""Create UI for 3 save slots below the main menu buttons."""
	if not canvas_layer:
		print("ERROR: canvas_layer is null in _create_save_slots_ui")
		return
	
	# Create panel container
	save_slots_panel = Control.new()
	save_slots_panel.name = "SaveSlotsPanel"
	save_slots_panel.anchor_left = 0.0
	save_slots_panel.anchor_top = 0.0
	save_slots_panel.anchor_right = 1.0
	save_slots_panel.anchor_bottom = 1.0
	
	# Create panel bg
	var panel_bg = ColorRect.new()
	panel_bg.color = Color(0, 0, 0, 0.7)
	panel_bg.anchor_left = 0.0
	panel_bg.anchor_top = 0.0
	panel_bg.anchor_right = 1.0
	panel_bg.anchor_bottom = 1.0
	save_slots_panel.add_child(panel_bg)
	
	# Create inner panel
	var inner_panel = Panel.new()
	inner_panel.anchor_left = 0.5
	inner_panel.anchor_top = 0.5
	inner_panel.anchor_right = 0.5
	inner_panel.anchor_bottom = 0.5
	inner_panel.offset_left = -400
	inner_panel.offset_top = -150
	inner_panel.offset_right = 400
	inner_panel.offset_bottom = 200
	save_slots_panel.add_child(inner_panel)
	
	# Add label title
	var title_label = Label.new()
	title_label.text = "SAVED GAMES"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.anchor_left = 0.0
	title_label.anchor_right = 1.0
	title_label.offset_top = 20
	title_label.offset_bottom = 50
	inner_panel.add_child(title_label)
	
	# Create 3 save slot buttons
	for i in range(3):
		# Container for slot and clear button
		var slot_container = HBoxContainer.new()
		slot_container.anchor_left = 0.1
		slot_container.anchor_right = 0.9
		slot_container.offset_top = 60 + (i * 50)
		slot_container.offset_bottom = 100 + (i * 50)
		
		# Main slot button
		var slot_button = Button.new()
		slot_button.name = "SaveSlot%d" % i
		slot_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		_update_slot_button(slot_button, i)
		
		slot_button.pressed.connect(_on_save_slot_pressed.bindv([i]))
		slot_container.add_child(slot_button)
		save_slot_buttons.append(slot_button)
		
		# Clear button
		var clear_button = Button.new()
		clear_button.text = "CLEAR"
		clear_button.custom_minimum_size = Vector2(80, 0)
		clear_button.pressed.connect(_on_clear_slot_pressed.bindv([i]))
		slot_container.add_child(clear_button)
		
		inner_panel.add_child(slot_container)
	
	# Add cancel button
	var cancel_button = Button.new()
	cancel_button.text = "BACK"
	cancel_button.anchor_left = 0.5
	cancel_button.anchor_right = 0.5
	cancel_button.offset_left = -100
	cancel_button.offset_top = 230
	cancel_button.offset_right = 100
	cancel_button.offset_bottom = 270
	cancel_button.pressed.connect(func(): save_slots_panel.visible = false)
	inner_panel.add_child(cancel_button)
	
	# Start hidden
	save_slots_panel.visible = false
	canvas_layer.add_child(save_slots_panel)
	print("Save slots panel created successfully")


func _update_slot_button(button: Button, slot: int) -> void:
	"""Update button text to show save slot info."""
	var save_manager = get_tree().root.get_node("SaveManager")
	var slot_info = save_manager.get_slot_info(slot)
	
	if slot_info["empty"]:
		button.text = "SLOT %d - [EMPTY]" % (slot + 1)
	else:
		button.text = "SLOT %d - %s" % [slot + 1, slot_info["display"]]


func _on_save_slot_pressed(slot: int) -> void:
	"""Handle save slot button press."""
	var save_manager = get_tree().root.get_node("SaveManager")
	save_manager.set_current_slot(slot)
	
	# Wait for fade to complete BEFORE changing scene
	FadeTransitions.transition()
	await FadeTransitions.on_transition_finished
	
	# Now change scene (which will show its own entry sequence)
	if save_manager.slot_exists(slot):
		save_manager.load_and_start(slot)
	else:
		# Start new game with this slot
		get_tree().change_scene_to_file("res://MainScenes/Level 1-1.tscn")


func _on_clear_slot_pressed(slot: int) -> void:
	"""Delete a save slot and refresh UI."""
	var save_manager = get_tree().root.get_node("SaveManager")
	save_manager.delete_slot(slot)
	
	# Refresh the button display
	_update_slot_button(save_slot_buttons[slot], slot)


func _on_play_pressed() -> void:
	"""Show save slots instead of starting directly."""
	save_slots_panel.visible = true
	for i in range(3):
		_update_slot_button(save_slot_buttons[i], i)


func _on_options_pressed() -> void:
	pass


func _on_quit_pressed() -> void:
	FadeTransitions.transition()
	await FadeTransitions.on_transition_finished
	get_tree().quit()
