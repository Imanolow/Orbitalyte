@tool
extends Node2D
## Level design tool: Simple trajectory preview.

class_name LevelToolNew

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

var trajectory_points: Array[Vector2] = []
var can_reach_goal: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		await get_tree().process_frame
		_recalculate_trajectory()


func _recalculate_trajectory() -> void:
	if not Engine.is_editor_hint():
		return
	
	trajectory_points.clear()
	can_reach_goal = false
	
	# Get planets
	var start_planet = get_node_or_null("../../PlanetsContainer/StartPlanet")
	var goal_planet = get_node_or_null("../../PlanetsContainer/GoalPlanet")
	var planets_container = get_node_or_null("../../PlanetsContainer")
	
	if not start_planet or not goal_planet or not planets_container or not PhysicsConfig:
		queue_redraw()
		return
	
	# Get blockers (only these affect gravity)
	var blockers: Array = []
	for child in planets_container.get_children():
		if "BlockerPlanet" in child.name:
			blockers.append(child)
	
	# Initial position and velocity
	var pos = start_planet.global_position + Vector2.UP * (start_planet.radius + PhysicsConfig.GAP)
	var angle_rad = deg_to_rad(launch_angle_degrees)
	var power_multiplier = PhysicsConfig.LAUNCH_BASE + (launch_power / 100.0) * PhysicsConfig.LAUNCH_MAX
	var velocity = Vector2.UP.rotated(angle_rad) * power_multiplier
	
	trajectory_points.append(pos)
	
	# Simulate
	for i in range(1000):
		# Apply ONLY blocker gravity
		for blocker in blockers:
			var to_blocker = blocker.global_position - pos
			var dist = to_blocker.length()
			
			# Only apply gravity within orbital radius
			if dist > blocker.radius * blocker.orbital_multiplier or dist < 1.0:
				continue
			
			var force = blocker.gravity / (dist * dist)
			velocity += to_blocker.normalized() * force
		
		# Clamp velocity
		if velocity.length() > PhysicsConfig.MAX_SPEED:
			velocity = velocity.normalized() * PhysicsConfig.MAX_SPEED
		
		# Move
		pos += velocity
		trajectory_points.append(pos)
		
		# Check goal
		if pos.distance_to(goal_planet.global_position) < goal_planet.radius + PhysicsConfig.GAP:
			can_reach_goal = true
			break
		
		# Out of bounds
		if pos.x < -500 or pos.x > 2500 or pos.y < -500 or pos.y > 1700:
			break
		
		# Hit blocker
		var hit = false
		for blocker in blockers:
			if pos.distance_to(blocker.global_position) < blocker.radius + PhysicsConfig.GAP:
				hit = true
				break
		if hit:
			break
	
	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint() or trajectory_points.is_empty():
		return
	
	# Draw trajectory
	var color = Color.GREEN if can_reach_goal else Color.SKY_BLUE
	for i in range(trajectory_points.size() - 1):
		draw_line(trajectory_points[i], trajectory_points[i + 1], color, 2.0)
	
	# Draw start point
	draw_circle(trajectory_points[0], 4.0, Color.GREEN)
	
	# Draw end point
	draw_circle(trajectory_points[-1], 4.0, Color.RED)
