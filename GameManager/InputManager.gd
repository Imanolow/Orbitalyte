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
var inputs_blocked: bool = false  # Block all input during sequences

@onready var power_meter = get_tree().root.get_node_or_null("Main/UIPanel/PowerMeter")


func _ready() -> void:
	if not power_meter:
		power_meter = get_tree().root.get_node("Main/UIPanel/PowerMeter")


func _process(delta: float) -> void:
	if not is_charging:
		return
	
	# Oscillate power between 0 and 100 (medium speed)
	power += power_direction * 125.0 * delta
	
	if power >= 100.0:
		power = 100.0
		power_direction = -1.0
	elif power <= 0.0:
		power = 0.0
		power_direction = 1.0
	
	# Update visual power meter
	if power_meter:
		var num_str = str(int(power))
		while num_str.length() < 3:
			num_str = " " + num_str
		power_meter.text = num_str + "%"


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
	# Keep the power meter display showing the launch power
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
	# Update visual power meter to zero with proper formatting
	if power_meter:
		power_meter.text = "  0%"


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


func block_inputs() -> void:
	"""Block all player inputs."""
	inputs_blocked = true
	reset()


func unblock_inputs() -> void:
	"""Allow player inputs."""
	inputs_blocked = false


func update_hold_states() -> void:
	"""Update hold states based on press time. Call this each frame."""
	# Don't update if inputs are blocked
	if inputs_blocked:
		return
	
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
