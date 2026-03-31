extends Node2D
## Script for the optional star collectible (unlocks StarBlue icon in WinScreen).

@export var radius: float = 24.0:
	set(value):
		radius = value
		if Engine.is_editor_hint():
			_update_sprite()
			queue_redraw()

@export var world_position: Vector2 = Vector2.ZERO
@export var sprite_texture: Texture2D = null:
	set(value):
		sprite_texture = value
		if Engine.is_editor_hint():
			_update_sprite()
			queue_redraw()

@export var tint_color: Color = Color.WHITE:
	set(value):
		tint_color = value
		if Engine.is_editor_hint() and sprite:
			sprite.self_modulate = tint_color

var sprite: Sprite2D = null
var initial_position: Vector2 = Vector2.ZERO  # Store original position for reset
var is_collected: bool = false  # Track if star has been collected in this attempt


func _ready() -> void:
	if not Engine.is_editor_hint():
		if world_position != Vector2.ZERO:
			global_position = world_position
		initial_position = global_position
		
		# Connect to level manager signals for reset on death
		_connect_to_level_manager()
	
	_update_sprite()


func _update_sprite() -> void:
	"""Configure existing sprite in the scene."""
	if not sprite:
		sprite = get_node_or_null("Sprite2D")
		if sprite:
			sprite.centered = true
	
	if sprite_texture and sprite:
		sprite.texture = sprite_texture
		sprite.self_modulate = tint_color
		
		# Scale sprite to planet size
		var texture_size = sprite_texture.get_width()
		var target_size = radius * 2.0
		sprite.scale = Vector2(target_size / texture_size, target_size / texture_size)
		sprite.visible = true
	elif sprite:
		sprite.visible = false


func _connect_to_level_manager() -> void:
	"""Connect to level manager to reset star on ship death."""
	var script_manager = get_tree().root.get_node_or_null("Main/ScriptManager")
	if not script_manager:
		# Try to find it in the scene tree
		var main = get_tree().root.get_node_or_null("Main")
		if main:
			for child in main.get_children():
				if child.script and "script_manager" in child.script.get_path():
					script_manager = child
					break
	
	if script_manager:
		# We'll check for reset through the script_manager's reset_level function
		pass


func collect_star() -> void:
	"""Mark star as collected and hide it."""
	if is_collected:
		return
	
	is_collected = true
	
	# Notify the script_manager that star was collected
	var script_manager = get_tree().root.get_node_or_null("Main")
	if script_manager:
		# Find the actual script manager
		for child in script_manager.get_children():
			if child.has_method("_on_star_collected"):
				child._on_star_collected()
				break
	
	# Hide the star
	if sprite:
		sprite.visible = false


func reset_star() -> void:
	"""Reset star to original position and make it visible again."""
	is_collected = false
	global_position = initial_position
	
	if sprite:
		sprite.visible = true


func is_star_collected() -> bool:
	"""Return whether the star has been collected."""
	return is_collected


func _draw() -> void:
	"""Draw the star (mainly for editor preview)."""
	# If sprite exists, it will handle rendering, don't draw here
	if sprite:
		return
	
	# Fallback visual for editor
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.85, 0.2))
	draw_circle(Vector2.ZERO, radius, Color(0.8, 0.65, 0.0), false, 2.0)
