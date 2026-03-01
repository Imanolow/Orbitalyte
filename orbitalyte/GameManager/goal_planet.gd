@tool
extends Node2D
## Script for the goal planet (destination with golden star).

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

var gravity: float = 0.0
var sprite: Sprite2D = null


func _ready() -> void:
	if not Engine.is_editor_hint():
		if world_position != Vector2.ZERO:
			global_position = world_position
	
	_update_sprite()


func _update_sprite() -> void:
	"""Configurar sprite existente en la escena."""
	if not sprite:
		sprite = get_node_or_null("Sprite2D")
		if sprite:
			sprite.centered = true
	
	if sprite_texture and sprite:
		sprite.texture = sprite_texture
		sprite.self_modulate = tint_color
		
		# Escalar sprite al tamaño del planeta
		var texture_size = sprite_texture.get_width()
		var target_size = radius * 2.0
		sprite.scale = Vector2(target_size / texture_size, target_size / texture_size)
		sprite.visible = true
	elif sprite:
		sprite.visible = false


func is_goal_planet() -> bool:
	return true


func _draw() -> void:
	"""Draw the goal planet with golden star."""
	# If sprite exists, it will handle rendering, don't draw circle
	if sprite:
		return
	
	# Main body - blue color
	draw_circle(Vector2.ZERO, radius, Color(0.2, 0.4, 0.9))
	
	# Darker border
	draw_circle(Vector2.ZERO, radius, Color(0.1, 0.2, 0.6), false, 2.0)
	
	# Glow effect (light circle)
	draw_circle(Vector2.ZERO, radius + 2, Color(0.3, 0.6, 1.0, 0.3))
	
	# Goal indicator - golden star
	draw_star_body(Vector2.ZERO, radius - 6, Color(1.0, 0.9, 0.2))


func draw_star_body(center: Vector2, size: float, color: Color) -> void:
	"""Draw a simple 5-pointed star."""
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(10):
		var angle: float = (i * PI / 5.0) - PI / 2.0
		var dist: float = size if i % 2 == 0 else size * 0.4
		points.append(center + Vector2.RIGHT.rotated(angle) * dist)
	draw_colored_polygon(points, color)
