extends Node2D
## Ship controller handling position, velocity, rotation and trail rendering.

class_name Ship

@onready var sprite: Sprite2D = $Sprite2D

var position_: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var angle: float = 0.0
var trail: Array = []
var is_flying: bool = false


func _ready() -> void:
	position_ = global_position
	# Ensure sprite is at correct position relative to ship
	if sprite:
		sprite.position = Vector2.ZERO
		sprite.offset = Vector2.ZERO


func _process(_delta: float) -> void:
	# Only add to trail when flying
	if is_flying:
		trail.append(position_)
		
		if trail.size() > PhysicsConfig.TMAX:
			trail.pop_front()
		
		update_rotation()
	else:
		# On surface, apply rotation to sprite
		if sprite:
			sprite.rotation = angle
	
	queue_redraw()


func update_rotation() -> void:
	"""Rotate ship towards movement direction."""
	if velocity.length() > 0.0:
		angle = velocity.angle() + PI / 2.0
		if sprite:
			sprite.rotation = angle
	else:
		# On surface, apply rotation to sprite
		if sprite:
			sprite.rotation = angle


func reset_ship(new_position: Vector2) -> void:
	"""Reset ship to surface position."""
	position_ = new_position
	velocity = Vector2.ZERO
	trail.clear()
	is_flying = false
	global_position = position_


func set_launch_velocity(power: float, direction_angle: float) -> void:
	"""Set initial velocity from launch power and angle."""
	velocity = Vector2.UP.rotated(direction_angle) * (PhysicsConfig.LAUNCH_BASE + power * PhysicsConfig.LAUNCH_MAX / 100.0)
	is_flying = true


func apply_gravity(gravity_force: Vector2) -> void:
	"""Apply gravitational acceleration."""
	velocity += gravity_force


func clamp_velocity() -> void:
	"""Limit velocity to max speed."""
	if velocity.length() > PhysicsConfig.MAX_SPEED:
		velocity = velocity.normalized() * PhysicsConfig.MAX_SPEED


func update_position(_delta: float) -> void:
	"""Update ship position based on velocity."""
	position_ += velocity
	global_position = position_


func _draw() -> void:
	# Draw ship triangle if no sprite texture is available
	if not sprite or not sprite.texture:
		# Draw ship triangle - angle is set from ship_rotation (SURFACE) or velocity.angle (FLYING)
		draw_set_transform(Vector2.ZERO, angle, Vector2.ONE)
		
		# Triangle nose pointing up
		var triangle: PackedVector2Array = PackedVector2Array([
			Vector2(0, -20),     # tip
			Vector2(-12, 16),    # left wing
			Vector2(12, 16)      # right wing
		])
		draw_colored_polygon(triangle, Color.WHITE)
		
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	
	# Engine flame if flying - rotates with ship angle
	if is_flying and velocity.length() > 1.0:
		draw_set_transform(Vector2.ZERO, angle, Vector2.ONE)
		
		var flame_length: float = remap(velocity.length(), 1.0, PhysicsConfig.MAX_SPEED, 6.0, 18.0)
		draw_line(Vector2(-6, 16), Vector2(-2, 16 + flame_length), Color.ORANGE, 3.0)
		draw_line(Vector2(0, 16), Vector2(0, 16 + flame_length + 2.0), Color.YELLOW, 4.0)
		draw_line(Vector2(6, 16), Vector2(2, 16 + flame_length), Color.ORANGE, 3.0)
		
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
