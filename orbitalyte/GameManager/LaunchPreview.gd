extends Node2D
## Draws static trajectory prediction based on launch power and angle.

class_name LaunchPreview

var trajectory_points: Array = []
var is_visible_preview: bool = false


func calculate_trajectory(ship_pos: Vector2, power: float, direction_angle: float, _blockers: Array) -> void:
	"""Calculate trajectory - just a straight line showing launch direction."""
	trajectory_points.clear()
	
	var launch_velocity: Vector2 = Vector2.UP.rotated(direction_angle) * (PhysicsConfig.LAUNCH_BASE + power * PhysicsConfig.LAUNCH_MAX / 100.0)
	
	# Draw straight line in launch direction for 200 pixels
	var direction: Vector2 = launch_velocity.normalized()
	var steps: int = 20
	for i in range(steps + 1):
		var distance: float = (float(i) / float(steps)) * 200.0
		trajectory_points.append(ship_pos + direction * distance)
	
	queue_redraw()
	
	queue_redraw()


func show_preview() -> void:
	"""Enable trajectory preview visibility."""
	is_visible_preview = true
	queue_redraw()


func hide_preview() -> void:
	"""Hide trajectory preview."""
	is_visible_preview = false
	queue_redraw()


func _draw() -> void:
	if not is_visible_preview or trajectory_points.is_empty():
		return
	
	var color: Color = Color.SKY_BLUE * 0.6
	for point in trajectory_points:
		draw_circle(point, 1.5, color)
