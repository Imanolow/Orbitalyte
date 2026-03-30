extends Node
## Handles level entry sequence with animated rótulos (labels)

class_name LevelEntrySequence

var label_node: Label = null
var input_manager: InputManager = null
var level_manager: LevelManager = null


func _ready() -> void:
	"""Initialize and run entry sequence if first time."""
	# Small delay to ensure scene is fully loaded
	await get_tree().create_timer(0.1).timeout
	
	await get_tree().process_frame
	
	# Setup references
	var main_node = get_tree().root.get_node_or_null("Main")
	if main_node:
		input_manager = main_node.get_node_or_null("InputManager")
	
	level_manager = get_tree().root.get_node_or_null("LevelManager")
	
	print("InputManager found: ", input_manager != null)
	print("LevelManager found: ", level_manager != null)
	
	if not input_manager:
		push_error("InputManager not found!")
	
	if not level_manager:
		push_error("LevelManager not found!")
		return
	
	# Create label
	_create_label()
	
	# Only show sequence on first entry
	if level_manager.is_first_entry:
		await _show_entry_sequence()
		level_manager.mark_entry_shown()


func _create_label() -> void:
	"""Create the rótulo label."""
	label_node = Label.new()
	add_child(label_node)
	
	label_node.text = ""
	
	# Load and apply Arcade font
	var arcade_font = load("res://Fonts/ARCADE_I.TTF")
	if arcade_font:
		label_node.add_theme_font_override("font", arcade_font)
	
	# Create LabelSettings for outline and font size
	var label_settings = LabelSettings.new()
	label_settings.font_size = 100
	label_settings.outline_size = 10
	label_settings.outline_color = Color.BLACK
	label_node.label_settings = label_settings
	label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Center on screen, full viewport
	label_node.anchor_left = 0.0
	label_node.anchor_top = 0.0
	label_node.anchor_right = 1.0
	label_node.anchor_bottom = 1.0
	label_node.offset_left = 0
	label_node.offset_top = 0
	label_node.offset_right = 0
	label_node.offset_bottom = 0


func _show_entry_sequence() -> void:
	"""Show level name and GO! with animations."""
	# Block inputs
	input_manager.block_inputs()
	
	# Extract level name from scene file path
	var scene_path = get_tree().current_scene.get_scene_file_path()
	# Extract "1-1" from "res://MainScenes/Level 1-1.tscn"
	var level_name = ""
	if "Level " in scene_path:
		var parts = scene_path.split("Level ")
		if parts.size() > 1:
			level_name = parts[1].split(".")[0]  # Get everything until .tscn
	
	var level_text = "LEVEL " + level_name
	
	# Show "LEVEL X-X"
	await _animate_label(level_text)
	
	# Small pause between labels
	await get_tree().create_timer(0.2).timeout
	
	# Show "GO!"
	await _animate_label("GO!")
	
	# Unblock inputs
	input_manager.unblock_inputs()


func _animate_label(text: String) -> void:
	"""Animate label: left → center-100px (zoom) → 0.7s → right."""
	label_node.text = text
	label_node.modulate = Color.WHITE
	label_node.scale = Vector2(0.8, 0.8)
	label_node.position.x = -1920  # Off screen to the left
	
	# Animation from left to center-100px with zoom
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label_node, "position:x", -200, 0.3)
	tween.tween_property(label_node, "scale", Vector2(1.0, 1.0), 0.3)
	
	# Stay for 0.7 seconds
	await get_tree().create_timer(0.7).timeout
	
	# Animate out to right
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label_node, "position:x", 1920, 0.3)
	tween.tween_property(label_node, "scale", Vector2(0.8, 0.8), 0.3)
	
	await tween.finished
	
	label_node.text = ""
