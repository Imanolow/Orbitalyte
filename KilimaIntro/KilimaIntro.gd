extends Node2D


func _ready() -> void:
	# If intro already shown in this session, go directly to menu
	if IntroManager.intro_shown:
		get_tree().change_scene_to_file("res://MainScenes/MainMenu.tscn")
		return
	
	# Mark intro as shown
	IntroManager.intro_shown = true
	
	# Wait 1.5 seconds (splash screen visible without fade)
	await get_tree().create_timer(1.5).timeout
	
	# Fade transition to main menu
	FadeTransitions.transition()
	await FadeTransitions.on_transition_finished
	
	get_tree().change_scene_to_file("res://MainScenes/MainMenu.tscn")
