extends Node2D
## Adds CRT effect overlay to the level

var scanline_intensity: float = 0.5
var scanline_thickness: float = 2.0


func _draw() -> void:
	# Draw horizontal scanlines across the viewport
	var viewport_size = get_viewport_rect().size
	var spacing = 4.0  # Space between lines
	
	var y = 0.0
	while y < viewport_size.y:
		var alpha = scanline_intensity * 0.5  # Semi-transparent
		draw_line(Vector2(0, y), Vector2(viewport_size.x, y), Color(0, 0, 0, alpha), scanline_thickness)
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
