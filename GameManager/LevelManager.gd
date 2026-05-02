extends Node
## Global level manager - tracks current level progression
class_name LevelManager

var is_first_entry: bool = true  # Track if first entry to this level
var attempts: int = 1  # Number of attempts (starts at 1 for first try, increments on each death)


func mark_entry_shown() -> void:
	"""Mark that we've shown the entry sequence for this level."""
	is_first_entry = false


func reset_first_entry() -> void:
	"""Reset for new level."""
	is_first_entry = true


func increment_attempts() -> void:
	"""Increment attempt counter (called on death)."""
	attempts += 1
