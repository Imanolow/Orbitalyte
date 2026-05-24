extends Node2D

var canvas_layer: CanvasLayer = null
var save_slots_scene: PackedScene


func _ready() -> void:
	"""Initialize main menu."""
	# Load SaveSlotsScreen scene
	save_slots_scene = load("res://MainMenuArt/SaveSlots/SaveSlotsScreen.tscn")
	
	# Find or create CanvasLayer for UI overlays (like WinScreen)
	canvas_layer = get_tree().root.get_node_or_null("Main/CanvasLayer")
	if not canvas_layer:
		canvas_layer = get_node_or_null("CanvasLayer")
	
	if not canvas_layer:
		print("ERROR: CanvasLayer not found!")
		return
	
	print("Main menu initialized successfully")


func _on_play_pressed() -> void:
	"""Show SaveSlotsScreen for save slot selection."""
	var audio_manager = get_tree().root.get_node_or_null("AudioManager")
	if audio_manager:
		audio_manager.play_button_click()
	
	if not save_slots_scene:
		push_error("SaveSlotsScreen scene not found!")
		return
	
	# Instantiate SaveSlotsScreen scene
	var save_slots = save_slots_scene.instantiate()
	save_slots.name = "SaveSlotsScreenInstance"
	
	# Connect closed signal
	save_slots.closed.connect(func():
		pass  # Just let it close normally
	)
	
	# Add to canvas layer (as overlay, like WinScreen)
	canvas_layer.add_child(save_slots)


func _on_options_pressed() -> void:
	var audio_manager = get_tree().root.get_node_or_null("AudioManager")
	if audio_manager:
		audio_manager.play_button_click()
	pass


func _on_quit_pressed() -> void:
	var audio_manager = get_tree().root.get_node_or_null("AudioManager")
	if audio_manager:
		audio_manager.play_button_click()
	
	FadeTransitions.transition()
	await FadeTransitions.on_transition_finished
	get_tree().quit()
