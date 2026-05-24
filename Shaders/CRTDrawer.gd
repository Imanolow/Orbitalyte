extends Control
## Draws CRT scanlines effect

var scanline_intensity: float = 0.5
var scanline_thickness: float = 2.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	# Draw horizontal scanlines across the entire control
	var rect_size = get_rect().size
	var spacing = 4.0  # Space between lines
	
	var y = 0.0
	while y < rect_size.y:
		var alpha = scanline_intensity * 0.5  # Semi-transparent
		draw_line(Vector2(0, y), Vector2(rect_size.x, y), Color(0, 0, 0, alpha), scanline_thickness)
		y += spacing


func _process(_delta: float) -> void:
	# Redraw every frame
	queue_redraw()


func set_scanline_intensity(value: float) -> void:
	"""Adjust scanline intensity (0.0 to 1.0)"""
	scanline_intensity = clamp(value, 0.0, 1.0)
	queue_redraw()


func set_scanline_thickness(value: float) -> void:
	"""Adjust scanline thickness"""
	scanline_thickness = clamp(value, 0.5, 5.0)
	queue_redraw()
