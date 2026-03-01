@tool
extends Node2D
## Script to draw the orbital ring (dashed circle and semi-transparent area).

@onready var planet: Node2D = get_parent()


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(true)


func _process(_delta: float) -> void:
	"""Redibuja si el planeta cambió de tamaño/orbital_multiplier."""
	if Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if planet == null:
		return
	
	# Usar orbital_multiplier correcto
	var orbit_radius: float = planet.radius * planet.orbital_multiplier
	
	# Draw dashed circle (orbit visualization)
	draw_dashed_circle(Vector2.ZERO, orbit_radius, Color.WHITE * 0.18, 4, 7)
	
	# Draw semi-transparent circle area
	draw_set_trans_circle(Vector2.ZERO, orbit_radius, Color.WHITE * Color(1, 1, 1, 0.05))


func draw_dashed_circle(center: Vector2, radius: float, color: Color, dash_size: int, gap_size: int) -> void:
	"""Draw a dashed circle using small line segments."""
	var point_count: int = 64
	var circumference: float = TAU * radius
	var dash_length: float = (dash_size / 100.0) * circumference
	var gap_length: float = (gap_size / 100.0) * circumference
	
	var accumulated: float = 0.0
	var is_drawing: bool = true
	var last_point: Vector2 = Vector2.ZERO
	var _first_point: Vector2 = Vector2.ZERO
	
	for i in range(point_count + 1):
		var angle: float = (float(i) / float(point_count)) * TAU
		var current_point: Vector2 = center + Vector2.RIGHT.rotated(angle) * radius
		
		if i == 0:
			last_point = current_point
			continue
		
		accumulated += last_point.distance_to(current_point)
		
		if is_drawing:
			draw_line(last_point, current_point, color, 1.0)
			if accumulated >= dash_length:
				is_drawing = false
				accumulated = 0.0
		else:
			if accumulated >= gap_length:
				is_drawing = true
				accumulated = 0.0
		
		last_point = current_point


func draw_set_trans_circle(center: Vector2, radius: float, color: Color) -> void:
	"""Draw semi-transparent circle area."""
	var points: PackedVector2Array = []
	var point_count: int = 32
	
	for i in range(point_count):
		var angle: float = (float(i) / float(point_count)) * TAU
		points.append(center + Vector2.RIGHT.rotated(angle) * radius)
	
	draw_colored_polygon(points, color)
