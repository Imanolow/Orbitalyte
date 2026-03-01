extends Node2D
## Handles trail rendering for the ship.

class_name TrailRenderer

@onready var ship: Node2D = get_parent().get_node("ShipRenderer")


func _process(_delta: float) -> void:
	if ship and ship.trail.size() > 1:
		queue_redraw()


func _draw() -> void:
	if not ship or ship.trail.size() < 2:
		return
	
	# Draw trail with gradient
	for i in range(1, ship.trail.size()):
		var t: float = float(i) / float(ship.trail.size())
		var color: Color = Color.SKY_BLUE * (t * 0.6)
		var width: float = t * 6.0
		draw_line(ship.trail[i - 1], ship.trail[i], color, width)
