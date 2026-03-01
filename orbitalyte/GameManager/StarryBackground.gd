extends Node2D
## Generates and renders starry background.

class_name StarryBackground

var stars: Array = []


func _ready() -> void:
	generate_stars()
	queue_redraw()


func generate_stars() -> void:
	"""Generate random stars filling the viewport."""
	stars.clear()
	
	var viewport_size: Vector2 = get_viewport_rect().size
	var star_count: int = 250
	
	randomize()
	for _i in range(star_count):
		var star_pos: Vector2 = Vector2(
			randf() * viewport_size.x,
			randf() * viewport_size.y
		)
		var star_size: float = randf_range(0.5, 2.0)
		var star_opacity: float = randf_range(0.3, 1.0)
		
		stars.append({
			"position": star_pos,
			"size": star_size,
			"opacity": star_opacity
		})


func _draw() -> void:
	for star in stars:
		var color: Color = Color.WHITE * star["opacity"]
		draw_circle(star["position"], star["size"], color)
