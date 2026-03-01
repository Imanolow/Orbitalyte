@tool
extends Node2D
## Script for the starting planet where the ship launches from.

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


func get_surface_position(angle: float) -> Vector2:
	"""Get position on planet surface at given angle. Angle adjusted so 0 = top."""
	return global_position + Vector2.UP.rotated(angle) * (radius + 13.0)


func is_start_planet() -> bool:
	return true


func _draw() -> void:
	"""Draw the starting planet."""
	# If sprite exists, it will handle rendering, don't draw circle
	if sprite:
		return
	
	# Main body - greenish color
	draw_circle(Vector2.ZERO, radius, Color(0.2, 0.8, 0.3))
	
	# Darker border
	draw_circle(Vector2.ZERO, radius, Color(0.1, 0.5, 0.15), false, 2.0)
	
	# Glow effect (light circle)
	draw_circle(Vector2.ZERO, radius + 2, Color(0.3, 1.0, 0.4, 0.2))
