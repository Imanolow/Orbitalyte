@tool
extends Node2D
## Level preview tool - visualizes level layout directly in editor without needing Play

class_name LevelPreviewTool

@export var show_preview: bool = true
@export var show_grid: bool = true
@export var ship_preview_position: Vector2 = Vector2(500, 850)  # Starting position
@export var grid_size: int = 100

var planets: Array[Node2D] = []


func _ready() -> void:
	"""Gather planets for preview."""
	_gather_planets()


func _process(_delta: float) -> void:
	"""Update preview in editor and game."""
	if show_preview:
		queue_redraw()


func _draw() -> void:
	"""Draw the level preview."""
	if not show_preview:
		return
	
	# Draw viewport boundaries
	var viewport_size = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color.WHITE, false, 2.0)
	
	# Draw grid
	if show_grid:
		_draw_grid(viewport_size)
	
	# Draw ship preview at starting position
	_draw_ship_preview(ship_preview_position)
	
	# Draw safe landing zones (SAFE velocity indicator)
	_draw_safe_zones()


func _gather_planets() -> void:
	"""Find all planet nodes in the scene."""
	planets.clear()
	
	var parent = get_parent()
	if parent:
		# Buscar en toda la escena, no solo el padre
		for node in get_tree().get_nodes_in_group("planets"):
			if node is Node2D and node != self:
				planets.append(node)
		
		# Si no hay planets en grupo, buscar por nombre de script
		if planets.is_empty():
			for child in parent.find_children("*", "Node2D"):
				if child is Node2D and child != self:
					var script_path = ""
					if child.get_script():
						script_path = child.get_script().get_path()
					
					if script_path.contains("planet"):
						planets.append(child)


func _draw_grid(viewport_size: Vector2) -> void:
	"""Draw grid overlay."""
	var grid_color = Color(0.3, 0.3, 0.3, 0.3)
	
	# Vertical lines
	for x in range(0, int(viewport_size.x), grid_size):
		draw_line(Vector2(x, 0), Vector2(x, viewport_size.y), grid_color, 1.0)
	
	# Horizontal lines
	for y in range(0, int(viewport_size.y), grid_size):
		draw_line(Vector2(0, y), Vector2(viewport_size.x, y), grid_color, 1.0)


func _draw_ship_preview(pos: Vector2) -> void:
	"""Draw a preview of the ship at given position."""
	draw_set_transform(pos, 0, Vector2.ONE)
	
	# Ship triangle
	var triangle: PackedVector2Array = PackedVector2Array([
		Vector2(0, -10),
		Vector2(-8, 10),
		Vector2(8, 10)
	])
	draw_colored_polygon(triangle, Color(0.8, 0.8, 0.8, 0.6))
	
	# Draw circle around it to show approximate collision radius
	draw_circle(Vector2.ZERO, 13, Color(0.5, 0.5, 1.0, 0.2), false, 1.0)
	
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_safe_zones() -> void:
	"""Draw planets and visual indicators for safe landing zones."""
	const SAFE_SPEED = 8.0
	const GAP = 13.0
	
	for planet in planets:
		if not planet:
			continue
		
		var planet_pos = planet.global_position
		var planet_radius = 0.0
		var script_path = planet.get_script().get_path() if planet.get_script() else ""
		
		# Get planet radius
		if planet.get("radius") != null:
			planet_radius = planet.radius
		else:
			planet_radius = 24.0
		
		if planet_radius > 0:
			# Determine planet type and color
			var planet_color = Color.WHITE
			var planet_type = ""
			
			if script_path.contains("start_planet"):
				planet_color = Color(0, 1, 0, 0.7)  # Green
				planet_type = "START"
			elif script_path.contains("goal_planet"):
				planet_color = Color(0, 0.5, 1, 0.7)  # Blue
				planet_type = "GOAL"
			elif script_path.contains("blocker_planet"):
				planet_color = Color(1, 0.2, 0.2, 0.7)  # Red
				planet_type = "BLOCKER"
			
			# Draw planet circle
			draw_circle(planet_pos, planet_radius, planet_color, false, 2.0)
			
			# Draw filled planet with lower opacity
			draw_circle(planet_pos, planet_radius, Color(planet_color.r, planet_color.g, planet_color.b, 0.2))
			
			# Draw safe landing zone
			draw_circle(planet_pos, planet_radius + GAP, Color(planet_color.r, planet_color.g, planet_color.b, 0.1), false, 1.0)
			
			# Draw planet type label
			var font = ThemeDB.get_project_theme().get_theme_item(Theme.DATA_TYPE_FONT, "font", "Label") if ThemeDB.get_project_theme() else null
			if font:
				draw_string(font, planet_pos + Vector2(-15, 5), planet_type, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
