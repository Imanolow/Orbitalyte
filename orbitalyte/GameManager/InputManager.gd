extends Node
## Handles input events and power charging mechanics.

class_name InputManager

var power: float = 0.0
var power_direction: float = 1.0	# 1.0 for increasing, -1.0 for decreasing
var is_charging: bool = false
var left_held: bool = false			# Track left button hold
var right_held: bool = false		# Track right button hold
var left_press_time: float = 0.0	# Time when left button was pressed
var right_press_time: float = 0.0	# Time when right button was pressed
var left_clicked: bool = false		# Single click detected on left
var right_clicked: bool = false		# Single click detected on right
var click_threshold: float = 0.15	# Time in seconds to distinguish click from hold

@onready var power_bar = get_tree().root.get_node_or_null("Main/UIPanel/PowerBar")


func _ready() -> void:
	if not power_bar:
		power_bar = get_tree().root.get_node("Main/UIPanel/PowerBar")


func _process(delta: float) -> void:
	if not is_charging:
		return
	
	# Oscillate power between 0 and 100
	power += power_direction * 200.0 * delta
	
	if power >= 100.0:
		power = 100.0
		power_direction = -1.0
	elif power <= 0.0:
		power = 0.0
		power_direction = 1.0
	
	# Update visual progress bar
	if power_bar:
		power_bar.value = power


func start_charging() -> void:
	"""Begin power charging sequence."""
	is_charging = true
	power = 0.0
	power_direction = 1.0


func stop_charging() -> float:
	"""End charging and return final power value."""
	is_charging = false
	var final_power = power
	power = 0.0
	power_direction = 1.0
	# Update visual progress bar to zero
	if power_bar:
		power_bar.value = 0.0
	return final_power


func reset() -> void:
	"""Reset input state."""
	is_charging = false
	power = 0.0
	power_direction = 1.0
	left_held = false
	right_held = false
	left_clicked = false
	right_clicked = false
	# Update visual progress bar to zero
	if power_bar:
		power_bar.value = 0.0


func record_left_press() -> void:
	"""Record when left button is pressed."""
	left_press_time = Time.get_ticks_msec() / 1000.0
	left_held = false  # Don't activate hold yet


func record_right_press() -> void:
	"""Record when right button is pressed."""
	right_press_time = Time.get_ticks_msec() / 1000.0
	right_held = false  # Don't activate hold yet


func check_left_release() -> bool:
	"""Check if left button was released quickly (click). Returns true if it was a click."""
	var elapsed = Time.get_ticks_msec() / 1000.0 - left_press_time
	return elapsed < click_threshold


func check_right_release() -> bool:
	"""Check if right button was released quickly (click). Returns true if it was a click."""
	var elapsed = Time.get_ticks_msec() / 1000.0 - right_press_time
	return elapsed < click_threshold


func update_hold_states() -> void:
	"""Update hold states based on press time. Call this each frame."""
	if left_press_time > 0.0:
		var elapsed = Time.get_ticks_msec() / 1000.0 - left_press_time
		left_held = elapsed >= click_threshold
	
	if right_press_time > 0.0:
		var elapsed = Time.get_ticks_msec() / 1000.0 - right_press_time
		right_held = elapsed >= click_threshold


func clear_press_states() -> void:
	"""Clear press times (call after button release)."""
	left_press_time = 0.0
	right_press_time = 0.0
	left_held = false
	right_held = false
