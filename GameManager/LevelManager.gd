extends Node
## Global level manager - tracks current level progression
class_name LevelManager

var current_level: int = 1  # Start at Level1
var lives: int = 3  # Number of lives player has


func get_current_level_path() -> String:
	"""Get the scene path for the current level."""
	return "res://MainScenes/Level%d.tscn" % current_level


func next_level() -> void:
	"""Advance to next level."""
	current_level += 1


func go_to_level(level_number: int) -> void:
	"""Jump to a specific level."""
	current_level = level_number


func reset_to_level_one() -> void:
	"""Reset to Level 1."""
	current_level = 1


func lose_life() -> bool:
	"""Lose a life. Returns true if player still has lives, false if game over."""
	lives -= 1
	return lives > 0


func reset_lives() -> void:
	"""Reset lives to 3."""
	lives = 3
