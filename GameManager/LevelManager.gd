extends Node
## Global level manager - tracks current level progression
class_name LevelManager

var is_first_entry: bool = true  # Track if first entry to this level
var lives: int = 3  # Number of lives player has


func mark_entry_shown() -> void:
	"""Mark that we've shown the entry sequence for this level."""
	is_first_entry = false


func reset_first_entry() -> void:
	"""Reset for new level."""
	is_first_entry = true


func lose_life() -> bool:
	"""Lose a life. Returns true if player still has lives, false if game over."""
	lives -= 1
	return lives > 0


func reset_lives() -> void:
	"""Reset lives to 3."""
	lives = 3
