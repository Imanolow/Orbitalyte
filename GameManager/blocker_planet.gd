@tool
extends Node2D
## Script for blocking planets (gravity-affected obstacles).

@export var radius: float = 60.0:
	set(value):
		radius = value
		if Engine.is_editor_hint():
			_update_sprite()
			queue_redraw()

@export var gravity: float = 1500.0
@export var orbital_multiplier: float = 2.2:
	set(value):
		orbital_multiplier = value
		if Engine.is_editor_hint():
			queue_redraw()
			if has_node("OrbitalRing"):
				get_node("OrbitalRing").queue_redraw()
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
var pulse_time: float = 0.0


func _ready() -> void:
	if not Engine.is_editor_hint():
		if world_position != Vector2.ZERO:
			global_position = world_position
	
	_update_sprite()


func _process(_delta: float) -> void:
	"""Update animation."""
	queue_redraw()


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


func apply_gravity(ship_pos: Vector2, _ship_vel: Vector2) -> Vector2:
	"""Calculate gravitational force on the ship. Only affects within orbit radius."""
	var dx: float = global_position.x - ship_pos.x
	var dy: float = global_position.y - ship_pos.y
	var distance_squared: float = dx * dx + dy * dy
	var distance: float = sqrt(distance_squared)
	
	# Only apply gravity if within orbital multiplier of the planet radius
	var max_distance: float = radius * orbital_multiplier
	if distance > max_distance:
		return Vector2.ZERO
	
	if distance < 1.0:
		return Vector2.ZERO
	
	var force: float = gravity / distance_squared
	return Vector2(force * dx / distance, force * dy / distance)


func get_orbit_radius() -> float:
	"""Get visual orbit radius (1.1x planet radius)."""
	return radius * 1.1


func get_surface_position(angle: float) -> Vector2:
	"""Get position on planet surface at given angle. Angle adjusted so 0 = top."""
	return global_position + Vector2.UP.rotated(angle) * (radius + 13.0)


func _draw() -> void:
	"""Draw the blocker planet."""
	# If sprite exists, it will handle rendering
	if sprite:
		# But still draw the orbital ring
		draw_orbital_ring()
		return
	
	# Draw orbital ring
	draw_orbital_ring()
	
	# Main body - reddish/orange color
	draw_circle(Vector2.ZERO, radius, Color(0.8, 0.3, 0.2))
	
	# Darker border
	draw_circle(Vector2.ZERO, radius, Color(0.5, 0.15, 0.1), false, 2.5)
	
	# Glow effect (light circle)
	draw_circle(Vector2.ZERO, radius + 3, Color(1.0, 0.4, 0.3, 0.2))
	
	# Add some texture with smaller circles
	for i in range(3):
		var angle: float = (i * TAU / 3.0)
		var offset: Vector2 = Vector2.RIGHT.rotated(angle) * (radius * 0.6)
		draw_circle(offset, radius * 0.2, Color(1.0, 0.5, 0.3, 0.3))


func draw_orbital_ring() -> void:
	"""Draw the orbital boundary visualization."""
	var orbit_radius: float = radius * orbital_multiplier
	
	# Dashed circle - more visible with thicker lines
	var point_count: int = 128
	var accumulated: float = 0.0
	var is_drawing: bool = true
	var last_point: Vector2 = Vector2.ZERO
	var dash_length: float = 1.2
	var gap_length: float = 1.8
	
	for i in range(point_count + 1):
		var angle: float = (float(i) / float(point_count)) * TAU
		var current_point: Vector2 = Vector2.RIGHT.rotated(angle) * orbit_radius
		
		if i == 0:
			last_point = current_point
			continue
		
		accumulated += last_point.distance_to(current_point)
		
		if is_drawing:
			draw_line(last_point, current_point, Color.WHITE * 0.35, 2.0)
			if accumulated >= dash_length:
				is_drawing = false
				accumulated = 0.0
		else:
			if accumulated >= gap_length:
				is_drawing = true
				accumulated = 0.0
		
		last_point = current_point
	
	# Animated pulse traveling from circumference to center
	var pulse_speed: float = 0.4  # Control animation speed here
	var min_opacity: float = 0.005
	var max_opacity: float = 0.15
	var pulse_count: int = 2  # Multiple pulses to allow overlapping
	
	# Use actual time for animation
	var time: float = fmod(Time.get_ticks_msec() / 1000.0, 10.0)
	
	# Draw multiple pulses to allow overlapping
	for pulse_idx in range(pulse_count):
		var wave_phase: float = fmod(time * pulse_speed - float(pulse_idx) * (1.0 / float(pulse_count)), 1.0)
		var wave_pos: float = 1.0 - wave_phase  # Travels from 1.0 (circumference) to 0.0 (center)
		
		# Calculate pulse position and opacity
		var current_radius: float = orbit_radius * wave_pos
		
		# Continuous linear interpolation from min to max opacity
		var current_alpha: float = lerp(max_opacity, min_opacity, wave_pos)
		
		# Draw the visible pulse circle (filled)
		draw_circle(Vector2.ZERO, current_radius, Color.WHITE * Color(1, 1, 1, current_alpha), true)
