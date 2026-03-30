@tool
extends Node2D
## Level design tool: Trajectory preview for launch angle and power.
## EDITOR ONLY - Shows trajectory line affected by blocker planet gravity.
## This is a design helper, NOT part of gameplay.

class_name LevelTool

# Public exports for real-time editing
@export var launch_power: float = 50.0:
	set(value):
		launch_power = clamp(value, 0.0, 100.0)
		if Engine.is_editor_hint():
			_recalculate_trajectory()

@export var launch_angle_degrees: float = 90.0:
	set(value):
		launch_angle_degrees = value
		if Engine.is_editor_hint():
			_recalculate_trajectory()

# Trajectory data
var trajectory_points: Array[Vector2] = []
var can_reach_goal: bool = false


func _ready() -> void:
	"""Initialize on scene load - only in editor."""
	if Engine.is_editor_hint():
		await get_tree().process_frame
		_recalculate_trajectory()


func _recalculate_trajectory() -> void:
	"""Calculate trajectory considering gravity and collisions."""
	if not Engine.is_editor_hint():
		return
	
	trajectory_points.clear()
	can_reach_goal = false
	
	# Get scene references with direct null checks
	var start_planet = get_node_or_null("../../PlanetsContainer/StartPlanet")
	if not start_planet:
		queue_redraw()
		return
	
	var goal_planet = get_node_or_null("../../PlanetsContainer/GoalPlanet")
	if not goal_planet:
		queue_redraw()
		return
	
	var planets_container = get_node_or_null("../../PlanetsContainer")
	if not planets_container:
		queue_redraw()
		return
	
	# Gather blocker planets
	var blockers: Array = []
	for child in planets_container.get_children():
		if "BlockerPlanet" in child.name:
			blockers.append(child)
	
	# Ensure PhysicsConfig is available
	if not PhysicsConfig:
		queue_redraw()
		return
	
	# Calculate initial position and velocity
	var ship_pos = start_planet.global_position + Vector2.UP * (start_planet.radius + PhysicsConfig.GAP)
	var angle_rad = deg_to_rad(launch_angle_degrees)
	var power_multiplier = PhysicsConfig.LAUNCH_BASE + (launch_power / 100.0) * PhysicsConfig.LAUNCH_MAX
	var velocity = Vector2.UP.rotated(angle_rad) * power_multiplier
	
	# Simulate trajectory
	var pos = ship_pos
	trajectory_points.append(pos)
	
	var max_iterations = 500
	
	# Use fixed bounds instead of get_viewport (which can be null in editor)
	var max_x = 2000.0
	var max_y = 1200.0
	var min_x = -100.0
	var min_y = -100.0
	
	for i in range(1, max_iterations):
		# Apply gravity from all blockers
		for blocker in blockers:
			var dx = blocker.global_position.x - pos.x
			var dy = blocker.global_position.y - pos.y
			var distance_sq = dx * dx + dy * dy
			var distance = sqrt(distance_sq)
			
			# Only apply gravity within orbital radius
			var max_distance = blocker.radius * blocker.orbital_multiplier
			if distance > max_distance or distance < 1.0:
				continue
			
			var force = blocker.gravity / distance_sq
			velocity += Vector2(force * dx / distance, force * dy / distance)
		
		# Clamp velocity to max speed
		if velocity.length() > PhysicsConfig.MAX_SPEED:
			velocity = velocity.normalized() * PhysicsConfig.MAX_SPEED
		
		# Update position
		pos += velocity
		trajectory_points.append(pos)
		
		# Check if reached goal
		var dist_to_goal = pos.distance_to(goal_planet.global_position)
		if dist_to_goal < goal_planet.radius + PhysicsConfig.GAP:
			can_reach_goal = true
			break
		
		# Stop if out of bounds
		if pos.x < min_x or pos.x > max_x or pos.y < min_y or pos.y > max_y:
			break
		
		# Stop if hit a blocker planet
		var hit_blocker = false
		for blocker in blockers:
			var dist_to_blocker = pos.distance_to(blocker.global_position)
			if dist_to_blocker < blocker.radius + PhysicsConfig.GAP:
				hit_blocker = true
				break
		if hit_blocker:
			break
		
		# Stop if going back to start planet (after some iterations)
		if i > 10:
			var dist_to_start = pos.distance_to(start_planet.global_position)
			if dist_to_start < start_planet.radius + PhysicsConfig.GAP:
				break
	
	queue_redraw()


func _draw() -> void:
	"""Draw trajectory line in editor only."""
	# Only draw in editor
	if not Engine.is_editor_hint():
		return
	
	# Draw nothing if no trajectory
	if trajectory_points.is_empty():
		return
	
	# Draw the trajectory line
	var line_color = Color.SKY_BLUE
	if can_reach_goal:
		line_color = Color.GREEN
	
	# Draw line connecting all points
	for i in range(trajectory_points.size() - 1):
		draw_line(trajectory_points[i], trajectory_points[i + 1], line_color, 2.0)
	
	# Draw start point (green circle)
	draw_circle(trajectory_points[0], 3.0, Color.GREEN)
	
	# Draw points along path (every 10 points to avoid clutter)
	for i in range(10, trajectory_points.size(), 10):
		draw_circle(trajectory_points[i], 1.5, line_color)
	
	# Draw end point
	var end_color = Color.GREEN if can_reach_goal else Color.RED
	draw_circle(trajectory_points[-1], 3.0, end_color)
