extends Node2D
## Main game manager handling game state, physics, and level progression.

# Game phases
enum Phase { SURFACE, CHARGING, FLYING, WIN }

# Singleton-like level tracking
var _level_manager: Node = null

@onready var game_container: Node2D = get_node("../GameContainer")
@onready var planets_container: Node2D = get_node("../GameContainer/PlanetsContainer")
@onready var asteroids_container: Node2D = get_node_or_null("../GameContainer/Asteroids")
@onready var ship_visuals: Node2D = get_node("../GameContainer/ShipVisuals")
@onready var ship: Node2D = get_node("../GameContainer/ShipVisuals/ShipRenderer")
@onready var trail_renderer: Node2D = get_node("../GameContainer/ShipVisuals/TrailRenderer")
@onready var launch_preview: Node2D = get_node("../GameContainer/ShipVisuals/LaunchPreview")
@onready var input_manager: Node = get_node("../InputManager")

var current_phase: Phase = Phase.SURFACE
var ui_manager: Node
var left_button: Button
var right_button: Button
var launch_button: Button

var start_planet: Node2D = null
var goal_planet: Node2D = null
var blocker_planets: Array = []
var asteroid_blocks: Array = []  # Destructive obstacles that crash on contact
var current_planet: Node2D = null  # Planet ship is currently on
var ship_rotation: float = 0.0  # 0 = up, π/2 = right, π = down, -π/2 = left
var last_preview_power: float = -1.0  # Track power changes for preview updates

# Keyboard input tracking for continuous rotation
var key_left_held: bool = false  # Track A key
var key_right_held: bool = false  # Track D key


func _ready() -> void:
	"""Initialize game - find planets and set up UI."""
	_setup_level_manager()
	_find_planets()
	await _find_ui_manager()
	_setup_ui()
	reset_level()
	


func _setup_level_manager() -> void:
	"""Setup or get the level manager singleton."""
	# Try to find existing LevelManager in the tree
	_level_manager = get_tree().root.get_node_or_null("LevelManager")
	
	if not _level_manager:
		# Detect current level from scene name
		var scene_path = get_tree().current_scene.get_scene_file_path()
		var level_num = 1
		
		if "Level" in scene_path:
			# Extract number from "LevelX.tscn"
			var parts = scene_path.split("Level")
			if parts.size() > 1:
				var num_str = parts[1].split(".")[0]
				level_num = int(num_str) if num_str.is_valid_int() else 1
		
		# Create LevelManager
		_level_manager = Node.new()
		_level_manager.set_script(load("res://GameManager/LevelManager.gd"))
		_level_manager.name = "LevelManager"
		_level_manager.current_level = level_num
		get_tree().root.add_child(_level_manager)
		print("Created LevelManager. Starting at Level %d" % level_num)
	else:
		print("Using existing LevelManager at Level %d" % _level_manager.current_level)


func _process(delta: float) -> void:
	match current_phase:
		Phase.SURFACE:
			# Update hold button states before processing input
			input_manager.update_hold_states()
			_update_surface_phase()
		Phase.CHARGING:
			# Update hold button states before processing input
			input_manager.update_hold_states()
			_update_charging_phase()
		Phase.FLYING:
			_update_flying_phase(delta)
		Phase.WIN:
			_update_win_phase()


func _find_planets() -> void:
	"""Locate and categorize planets from the scene tree."""
	blocker_planets.clear()
	asteroid_blocks.clear()
	
	# Search in PlanetsContainer
	for child in planets_container.get_children():
		if child.script:
			var script_name = child.script.get_path()
			print("Found planet: %s with script: %s" % [child.name, script_name])
			
			if script_name.ends_with("start_planet.gd"):
				start_planet = child
				print("  → Set as StartPlanet")
			elif script_name.ends_with("goal_planet.gd"):
				goal_planet = child
				print("  → Set as GoalPlanet")
			elif script_name.ends_with("blocker_planet.gd"):
				blocker_planets.append(child)
				print("  → Added as BlockerPlanet #%d" % blocker_planets.size())
	
	# Search in Asteroids container if it exists
	if asteroids_container:
		for child in asteroids_container.get_children():
			if child.script:
				var script_name = child.script.get_path()
				print("Found asteroid: %s with script: %s" % [child.name, script_name])
				
				if script_name.ends_with("asteroid_blocker.gd"):
					blocker_planets.append(child)
					asteroid_blocks.append(child)
					print("  → Added as AsteroidBlocker #%d" % asteroid_blocks.size())
	
	print("=== PLANETS FOUND ===")
	print("Start: %s" % start_planet.name if start_planet else "Start: NOT FOUND")
	print("Goal: %s" % goal_planet.name if goal_planet else "Goal: NOT FOUND")
	print("Blockers: %d found" % blocker_planets.size())
	for i in range(blocker_planets.size()):
		print("  [%d] %s at pos %v with radius %.1f" % [i, blocker_planets[i].name, blocker_planets[i].global_position, blocker_planets[i].radius])
	print("Asteroids: %d found" % asteroid_blocks.size())


func _find_ui_manager() -> void:
	"""Find or create UI manager."""
	# Wait for scene tree to be ready
	await get_tree().process_frame
	
	# Try to find existing UIManager
	ui_manager = get_tree().root.get_node_or_null("Main/UILayer")
	if not ui_manager:
		# Try alternate path
		ui_manager = get_tree().root.get_node_or_null("Main/UIManager")
	
	if not ui_manager:
		# Create UIManager if it doesn't exist using call_deferred to avoid parent setup conflict
		var canvas_layer = CanvasLayer.new()
		canvas_layer.name = "UILayer"
		canvas_layer.set_script(load("res://GameManager/UIManager.gd"))
		var main = get_tree().root.get_node("Main")
		main.add_child.call_deferred(canvas_layer)
		# Wait multiple frames for UIManager to initialize
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		ui_manager = canvas_layer
	
	# Wait for UIManager to be ready
	await get_tree().process_frame
	
	# Get button references from UIManager
	if ui_manager and ui_manager.has_method("get_buttons"):
		var buttons = ui_manager.get_buttons()
		left_button = buttons["left"]
		right_button = buttons["right"]
		launch_button = buttons["launch"]
		if left_button:
			print("✓ Buttons found from UIManager")
		else:
			push_error("UIManager buttons are null")
	else:
		push_error("Failed to create or find UIManager")


func _setup_ui() -> void:
	"""Connect UI buttons to game actions."""
	if not left_button or not right_button or not launch_button:
		push_error("UI buttons not found. Make sure UIManager is in the scene.")
		return
	
	# Left button
	left_button.button_down.connect(_on_left_button_pressed)
	left_button.button_up.connect(_on_left_button_released)
	# Right button
	right_button.button_down.connect(_on_right_button_pressed)
	right_button.button_up.connect(_on_right_button_released)
	# Launch button
	launch_button.pressed.connect(_on_launch_button_pressed)


func reset_level() -> void:
	"""Reset the current level to initial state."""
	current_phase = Phase.SURFACE
	ship_rotation = 0.0
	last_preview_power = -1.0
	input_manager.reset()
	
	# Reset the power meter triangle display
	var power_bar_triangle = get_tree().root.get_node_or_null("Main/UIMain/PowerBarTriangleFill")
	if power_bar_triangle and power_bar_triangle.has_method("reset"):
		power_bar_triangle.reset()
	
	key_left_held = false
	key_right_held = false
	current_planet = start_planet
	
	# Hide win screen if it's showing
	if ui_manager and ui_manager.has_method("hide_win_screen"):
		ui_manager.hide_win_screen()
	
	if start_planet and ship:
		var surface_pos: Vector2 = start_planet.get_surface_position(ship_rotation)
		ship.reset_ship(surface_pos)
		ship.angle = ship_rotation
	
	launch_preview.hide_preview()


func _update_surface_phase() -> void:
	"""Handle surface phase - waiting for launch."""
	# Apply continuous rotation while held down (slower: 1 degree per frame)
	if input_manager.left_held or key_left_held:
		ship_rotation -= PI / 180.0  # 1 degree per frame for smooth hold
		if current_planet and ship and current_phase == Phase.SURFACE:
			var surface_pos: Vector2 = current_planet.get_surface_position(ship_rotation)
			ship.position_ = surface_pos
			ship.global_position = surface_pos
			ship.angle = ship_rotation
			ship.queue_redraw()
		_update_trajectory_preview_static()
	elif input_manager.right_held or key_right_held:
		ship_rotation += PI / 180.0  # 1 degree per frame for smooth hold
		if current_planet and ship and current_phase == Phase.SURFACE:
			var surface_pos: Vector2 = current_planet.get_surface_position(ship_rotation)
			ship.position_ = surface_pos
			ship.global_position = surface_pos
			ship.angle = ship_rotation
			ship.queue_redraw()
		_update_trajectory_preview_static()
	
	# Show preview with current direction at minimum power
	launch_preview.show_preview()
	_update_trajectory_preview_static()


func _update_charging_phase() -> void:
	"""Handle charging phase - power bar oscillating."""
	# Apply continuous rotation while held down (slower: 1 degree per frame)
	if input_manager.left_held or key_left_held:
		ship_rotation -= PI / 180.0  # 1 degree per frame for smooth hold
		if current_planet and ship and current_phase == Phase.CHARGING:
			var surface_pos: Vector2 = current_planet.get_surface_position(ship_rotation)
			ship.position_ = surface_pos
			ship.global_position = surface_pos
			ship.angle = ship_rotation
			ship.queue_redraw()
		_update_trajectory_preview_static()
	elif input_manager.right_held or key_right_held:
		ship_rotation += PI / 180.0  # 1 degree per frame for smooth hold
		if current_planet and ship and current_phase == Phase.CHARGING:
			var surface_pos: Vector2 = current_planet.get_surface_position(ship_rotation)
			ship.position_ = surface_pos
			ship.global_position = surface_pos
			ship.angle = ship_rotation
			ship.queue_redraw()
		_update_trajectory_preview_static()
	
	# Launch preview visible, updated only when power changes significantly
	launch_preview.show_preview()
	
	# Only recalculate trajectory if power changed by 5+ units
	if abs(input_manager.power - last_preview_power) >= 5.0:
		last_preview_power = input_manager.power
		_update_trajectory_preview_static()


func _update_flying_phase(delta: float) -> void:
	"""Handle flying phase - apply gravity and check collisions."""
	if not ship:
		return
	
	# Check if ship is out of bounds
	var screen_size = get_viewport_rect().size
	var pos = ship.global_position

	if pos.x < 0 \
	or pos.x > screen_size.x \
	or pos.y < 0 \
	or pos.y > screen_size.y:
		_on_crash()
		return
	
	# Apply gravity from all blocker planets (except current planet we just launched from)
	for blocker in blocker_planets:
		# Skip gravity from the planet we're currently on to avoid pulling ship back
		if blocker == current_planet:
			continue
		var gravity_force: Vector2 = blocker.apply_gravity(ship.position_, ship.velocity)
		ship.apply_gravity(gravity_force)
	
	# Clamp velocity to max speed
	ship.clamp_velocity()
	
	# Update position
	ship.update_position(delta)
	
	# Check collisions with all planets
	_check_collisions()


func _update_win_phase() -> void:
	"""Handle win phase - show victory screen."""
	pass


func _check_collisions() -> void:
	"""Check if ship collided with any planet."""
	if not ship or (not goal_planet and not start_planet):
		return
	
	# Check collision with goal planet - instant win, no speed check
	if goal_planet:
		var dist_to_goal: float = ship.position_.distance_to(goal_planet.global_position)
		if dist_to_goal < goal_planet.radius + PhysicsConfig.GAP:
			_on_goal_reached()
			return
	
	# Check collision with start planet
	if start_planet:
		var dist_to_start: float = ship.position_.distance_to(start_planet.global_position)
		if dist_to_start < start_planet.radius + PhysicsConfig.GAP:
			_on_crash()
			return
	
	# Check collision with blocker planets
	for blocker in blocker_planets:
		var dist_to_blocker: float = ship.position_.distance_to(blocker.global_position)
		if dist_to_blocker < blocker.radius + PhysicsConfig.GAP:
			# Check if this is an asteroid blocker (always crashes)
			var is_asteroid: bool = false
			if blocker.script:
				var script_name = blocker.script.get_path()
				is_asteroid = script_name.ends_with("asteroid_blocker.gd")
			
			if is_asteroid:
				# Asteroid blocker - always crash
				_on_crash()
			else:
				# Regular blocker - check speed for landing
				var speed: float = ship.velocity.length()
				if speed <= PhysicsConfig.SAFE:
					# Safe landing on blocker planet
					# Calculate radial angle from blocker center to ship position (atan2 + PI/2 for Godot coords)
					var dx: float = ship.position_.x - blocker.global_position.x
					var dy: float = ship.position_.y - blocker.global_position.y
					ship_rotation = atan2(dy, dx) + PI / 2.0
					
					# Position ship on blocker surface
					var surface_pos: Vector2 = blocker.get_surface_position(ship_rotation)
					ship.position_ = surface_pos
					ship.global_position = surface_pos
					ship.angle = ship_rotation
					ship.velocity = Vector2.ZERO
					ship.is_flying = false
					ship.trail.clear()
					current_phase = Phase.SURFACE
					current_planet = blocker
					ship.queue_redraw()
				else:
					# Crash if going too fast
					_on_crash()
			return


func _on_left_button_pressed() -> void:
	"""Handle left button down - start tracking time."""
	input_manager.record_left_press()


func _on_left_button_released() -> void:
	"""Handle left button up - check if it was a quick click."""
	if input_manager.check_left_release():
		# Quick click - rotate 1 degree
		ship_rotation -= PI / 180.0
		if current_planet and ship and current_phase == Phase.SURFACE:
			var surface_pos: Vector2 = current_planet.get_surface_position(ship_rotation)
			ship.position_ = surface_pos
			ship.global_position = surface_pos
			ship.angle = ship_rotation
			ship.queue_redraw()
		if current_phase == Phase.SURFACE or current_phase == Phase.CHARGING:
			_update_trajectory_preview_static()
	input_manager.clear_press_states()


func _on_right_button_pressed() -> void:
	"""Handle right button down - start tracking time."""
	input_manager.record_right_press()


func _on_right_button_released() -> void:
	"""Handle right button up - check if it was a quick click."""
	if input_manager.check_right_release():
		# Quick click - rotate 1 degree
		ship_rotation += PI / 180.0
		if current_planet and ship and current_phase == Phase.SURFACE:
			var surface_pos: Vector2 = current_planet.get_surface_position(ship_rotation)
			ship.position_ = surface_pos
			ship.global_position = surface_pos
			ship.angle = ship_rotation
			ship.queue_redraw()
		if current_phase == Phase.SURFACE or current_phase == Phase.CHARGING:
			_update_trajectory_preview_static()
	input_manager.clear_press_states()


func _on_launch_button_pressed() -> void:
	"""Handle launch button press."""
	if current_phase == Phase.SURFACE:
		# Start charging
		current_phase = Phase.CHARGING
		last_preview_power = -1.0  # Reset preview tracker
		input_manager.start_charging()
	elif current_phase == Phase.CHARGING:
		# Stop charging and launch
		var power: float = input_manager.stop_charging()
		current_phase = Phase.FLYING
		ship.set_launch_velocity(power, ship_rotation)
		launch_preview.hide_preview()


func _unhandled_input(event: InputEvent) -> void:
	"""Handle keyboard input (A, D for rotation, Space for launch)."""
	if event is InputEventKey:
		if event.keycode == KEY_A:
			# Left rotation (A key)
			key_left_held = event.pressed
			if event.pressed:
				get_tree().root.set_input_as_handled()
		
		elif event.keycode == KEY_D:
			# Right rotation (D key)
			key_right_held = event.pressed
			if event.pressed:
				get_tree().root.set_input_as_handled()
		
		elif event.keycode == KEY_SPACE and event.pressed:
			# Launch (Space key)
			_on_launch_button_pressed()
			get_tree().root.set_input_as_handled()


func _update_trajectory_preview_static() -> void:
	"""Update trajectory preview when rotation or power changes (only in SURFACE/CHARGING)."""
	if not ship or not launch_preview:
		return
	
	launch_preview.calculate_trajectory(ship.position_, input_manager.power, ship_rotation, blocker_planets)


func _on_goal_reached() -> void:
	"""Handle reaching the goal planet."""
	current_phase = Phase.WIN
	ship.is_flying = false
	# Show victory screen
	_show_win_screen()


func _on_crash() -> void:
	"""Handle ship crash."""
	current_phase = Phase.SURFACE
	ship.is_flying = false
	ship_rotation = 0.0
	input_manager.reset()
	
	# Reset the power meter triangle display
	var power_bar_triangle = get_tree().root.get_node_or_null("Main/UIMain/PowerBarTriangleFill")
	if power_bar_triangle and power_bar_triangle.has_method("reset"):
		power_bar_triangle.reset()
	
	key_left_held = false
	key_right_held = false
	
	# Handle lives
	if _level_manager.lose_life():
		# Still have lives - reset level
		if ui_manager:
			ui_manager.update_lives()
		reset_level()
	else:
		# Game over - go to Level 1
		print("Game Over! Resetting to Level 1")
		_level_manager.reset_to_level_one()
		_level_manager.reset_lives()
		get_tree().change_scene_to_file("res://MainScenes/Level1.tscn")


func _show_win_screen() -> void:
	"""Display victory overlay screen through UIManager."""
	if ui_manager:
		ui_manager.show_win_screen()
	else:
		push_error("UIManager not available for showing win screen")


func _on_next_level_pressed() -> void:
	"""Load next level."""
	var current_scene_path = get_tree().current_scene.get_scene_file_path()
	print("Current scene: %s" % current_scene_path)
	
	# Detectar qué número de nivel es
	var level_number = 1
	if "Level2" in current_scene_path:
		level_number = 2
	elif "Level3" in current_scene_path:
		level_number = 3
	
	# Ir al siguiente nivel
	var next_level = level_number + 1
	
	# Si pasamos el nivel 3, volver al 1
	if next_level > 3:
		next_level = 1
	
	var next_scene = "res://MainScenes/Level%d.tscn" % next_level
	print("Loading: %s" % next_scene)
	get_tree().change_scene_to_file(next_scene)
