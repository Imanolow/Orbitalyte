extends Node2D
## Manages the world level selection screen with planets
## Shows all 10 planets - locked ones in B&W, unlocked ones in color

@onready var planets_bw = $PlanetsBW
@onready var planets_color = $PlanetsColor

var save_manager: Node
var world_unlocked: int = 1
var current_slot: int = 0
var selected_world: int = -1
var hovered_world: int = -1

# Reference to WorldLevelSelect scene
var world_level_select_scene: PackedScene


func _ready() -> void:
	"""Initialize world level screen."""
	save_manager = get_tree().root.get_node("SaveManager")
	world_level_select_scene = load("res://WorldLevel/WorldLevelSelect.tscn")
	
	current_slot = save_manager.current_slot
	world_unlocked = save_manager.get_world_unlocked(current_slot)
	
	# Update planet visibility based on unlock status
	_update_planet_visibility()


func _update_planet_visibility() -> void:
	"""Show planets in color if unlocked, B&W if locked."""
	for world in range(1, 11):
		var planet_bw = planets_bw.get_node_or_null("Planet%02dbw" % world)
		var planet_color = planets_color.get_node_or_null("Planet%02d" % world)
		
		if not planet_bw or not planet_color:
			continue
		
		var is_unlocked = save_manager.is_world_unlocked(current_slot, world)
		
		# Show color version if unlocked, B&W if locked
		planet_color.visible = is_unlocked
		planet_bw.visible = not is_unlocked


func _connect_planet_inputs() -> void:
	"""Connect input signals to all planets."""
	# Connection is handled in _input() method
	pass


func _input(event: InputEvent) -> void:
	"""Handle mouse input for planet clicks and hover."""
	if event is InputEventMouseMotion:
		# Check which planet the mouse is over
		var mouse_over_world = -1
		
		for world in range(1, 11):
			if not save_manager.is_world_unlocked(current_slot, world):
				continue
			
			var planet = planets_color.get_node_or_null("Planet%02d" % world)
			if not planet:
				continue
			
			# Check if mouse is over this planet
			var local_pos = planet.get_local_mouse_position()
			if planet.get_rect().has_point(local_pos):
				mouse_over_world = world
				break
		
		# Handle hover effects
		if mouse_over_world != hovered_world:
			if hovered_world > 0:
				_on_planet_unhover(hovered_world)
			
			hovered_world = mouse_over_world
			if mouse_over_world > 0:
				_on_planet_hover(mouse_over_world)
	
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Check which planet was clicked
		for world in range(1, 11):
			if not save_manager.is_world_unlocked(current_slot, world):
				continue
			
			var planet = planets_color.get_node_or_null("Planet%02d" % world)
			if not planet:
				continue
			
			# Check if mouse is over this planet
			var local_pos = planet.get_local_mouse_position()
			if planet.get_rect().has_point(local_pos):
				_on_planet_clicked(world)
				break


func _on_planet_hover(world: int) -> void:
	"""Handle planet hover - show outline."""
	if save_manager.is_world_unlocked(current_slot, world):
		var planet = planets_color.get_node("Planet%02d" % world)
		# Add outline effect with brighter modulation
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(planet, "modulate", Color(1.3, 1.3, 1.3, 1.0), 0.15)


func _on_planet_unhover(world: int) -> void:
	"""Handle planet unhover - remove outline."""
	var planet = planets_color.get_node_or_null("Planet%02d" % world)
	if planet:
		# Smooth transition back to normal
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(planet, "modulate", Color.WHITE, 0.15)


func _on_planet_clicked(world: int) -> void:
	"""Handle planet click - open WorldLevelSelect."""
	if save_manager.is_world_unlocked(current_slot, world):
		selected_world = world
		_open_world_level_select(world)


func _open_world_level_select(world: int) -> void:
	"""Open the world level select screen centered on screen."""
	if not world_level_select_scene:
		push_error("WorldLevelSelect scene not found!")
		return
	
	# Create instance
	var world_select_instance = world_level_select_scene.instantiate()
	
	# Find or create canvas layer for UI
	var canvas_layer = get_tree().root.get_node_or_null("CanvasLayer")
	if not canvas_layer:
		canvas_layer = CanvasLayer.new()
		canvas_layer.name = "CanvasLayer"
		get_tree().root.add_child(canvas_layer)
	
	# Add to canvas layer
	canvas_layer.add_child(world_select_instance)
	
	# Position at center of screen (960, 540 for 1920x1080)
	# WorldLevelSelect already has its own visual positioning
	# but we need to ensure it's on top and properly positioned
	
	# Initialize the world select screen
	if world_select_instance.has_method("initialize"):
		world_select_instance.initialize(world, current_slot)
	
	# Connect close signal if available
	if world_select_instance.has_signal("closed"):
		world_select_instance.closed.connect(_on_world_select_closed)


func _on_world_select_closed() -> void:
	"""Handle world select screen closing."""
	selected_world = -1
