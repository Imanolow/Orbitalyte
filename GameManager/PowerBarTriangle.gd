extends CanvasItem
## Draws a triangle progress bar with color gradient (green → red) based on power level.

class_name PowerBarTriangle

# Triangle vertices (relative to this node's position)
# Right triangle: 292x180 pixels
# Punta en esquina superior derecha, se llena de izquierda a derecha
var triangle_points: Array[Vector2] = [
	Vector2(292, 0),    # Top right (punta)
	Vector2(292, 180),  # Bottom right
	Vector2(0, 180)     # Bottom left
]

# Color gradient points for the power meter
var color_stops: Array = [
	{"power": 0.0, "color": Color.GREEN},
	{"power": 25.0, "color": Color.YELLOW},
	{"power": 75.0, "color": Color.ORANGE},
	{"power": 100.0, "color": Color.RED}
]

var input_manager: InputManager = null
var last_fill_percent: float = 0.0  # Mantiene el último poder mostrado


func _ready() -> void:
	# InputManager is a direct child of Main
	input_manager = get_tree().root.get_node_or_null("Main/InputManager")
	
	if not input_manager:
		# Fallback: relative path from UIPanel/PowerBarTriangleFill
		input_manager = get_node_or_null("../../InputManager")
	
	if input_manager:
		print("PowerBarTriangle: Found InputManager")
	else:
		print("PowerBarTriangle: WARNING - Could not find InputManager!")
		print("Tree structure - looking for InputManager at: Main/InputManager")
	
	set_process(true)


func _process(_delta: float) -> void:
	if not input_manager:
		return
	
	# Si estamos cargando, actualiza el fill_percent
	if input_manager.is_charging:
		last_fill_percent = input_manager.power / 100.0
		queue_redraw()
	# Si no estamos cargando pero hay poder, mantén el triángulo visible
	elif last_fill_percent > 0:
		# No redibujar pero mantener visible el último estado
		pass


func _draw() -> void:
	if not input_manager:
		return
	
	var fill_percent = last_fill_percent  # Usar el último poder capturado
	
	# Only draw if power > 0
	if fill_percent <= 0:
		return
	
	# Draw with strips for gradient effect
	# The triangle fills from right (full) to left (empty) with a diagonal boundary
	var strips = 30
	
	var top_right = triangle_points[0]    # (292, 0)
	var bottom_right = triangle_points[1]  # (292, 180)
	var bottom_left = triangle_points[2]   # (0, 180)
	
	# Draw vertical strips - fill from RIGHT (punta) to LEFT
	# Calculate how many strips to skip on the left (empty area)
	var empty_strips = int((1.0 - fill_percent) * strips)
	
	for i in range(empty_strips, strips):
		var strip_ratio = float(i) / strips
		var next_strip_ratio = float(i + 1) / strips
		
		# Points on the diagonal line
		var p1_diagonal = top_right.lerp(bottom_left, strip_ratio)
		var p2_diagonal = top_right.lerp(bottom_left, next_strip_ratio)
		
		# Points on the bottom line
		var p1_bottom = bottom_right.lerp(bottom_left, strip_ratio)
		var p2_bottom = bottom_right.lerp(bottom_left, next_strip_ratio)
		
		# Create trapezoid strip
		var strip_points = PackedVector2Array([p1_diagonal, p2_diagonal, p2_bottom, p1_bottom])
		
		# Color: izquierda (bajo) = verde, derecha (alto) = rojo
		var color_ratio = 1.0 - (strip_ratio + next_strip_ratio) / 2.0
		var power_at_position = color_ratio * 100.0
		var strip_color = get_color_for_power(power_at_position)
		
		draw_colored_polygon(strip_points, strip_color)
	
	# Draw right triangle if fill is complete (extra visualization)
	if fill_percent >= 1.0:
		var final_triangle = PackedVector2Array([top_right, bottom_right, bottom_left])
		draw_colored_polygon(final_triangle, Color.RED)


func reset() -> void:
	"""Reset the triangle when game resets."""
	last_fill_percent = 0.0
	queue_redraw()


func get_color_for_power(power: float) -> Color:
	"""Get interpolated color based on current power level."""
	# Find the two color stops we're between
	for i in range(color_stops.size() - 1):
		var current_stop = color_stops[i]
		var next_stop = color_stops[i + 1]
		
		if power >= current_stop["power"] and power <= next_stop["power"]:
			# Interpolate between the two colors
			var range_size = next_stop["power"] - current_stop["power"]
			var position_in_range = power - current_stop["power"]
			var t = position_in_range / range_size if range_size > 0 else 0.0
			
			return current_stop["color"].lerp(next_stop["color"], t)
	
	# If power is at max, return the last color
	return color_stops[-1]["color"]
