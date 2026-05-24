extends Node2D

func _ready() -> void:
	"""Center the options menu on screen and setup volume sliders."""
	# Centrar en la pantalla
	global_position = get_viewport().get_visible_rect().get_center()
	
	var audio_manager = get_tree().root.get_node_or_null("AudioManager")
	if not audio_manager:
		return
	
	# Setup Master Volume slider
	var master_slider = $MasterVolumeSlider
	if master_slider:
		master_slider.value = audio_manager.get_master_volume()
		master_slider.value_changed.connect(_on_master_volume_changed)
	
	# Setup Music Volume slider
	var music_slider = $MusicVolumeSlider
	if music_slider:
		music_slider.value = audio_manager.get_music_volume()
		music_slider.value_changed.connect(_on_music_volume_changed)
	
	# Setup SFX Volume slider
	var sfx_slider = $SFXVolumeSlider
	if sfx_slider:
		sfx_slider.value = audio_manager.get_sfx_volume()
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)


func _on_master_volume_changed(value: float) -> void:
	"""Handle master volume slider change."""
	var audio_manager = get_tree().root.get_node_or_null("AudioManager")
	if audio_manager:
		audio_manager.set_master_volume(value)
	
	# Save to config
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("audio", "master_volume", value)
	config.save("user://settings.cfg")


func _on_music_volume_changed(value: float) -> void:
	"""Handle music volume slider change."""
	var audio_manager = get_tree().root.get_node_or_null("AudioManager")
	if audio_manager:
		audio_manager.set_music_volume(value)
	
	# Save to config
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("audio", "music_volume", value)
	config.save("user://settings.cfg")


func _on_sfx_volume_changed(value: float) -> void:
	"""Handle SFX volume slider change."""
	var audio_manager = get_tree().root.get_node_or_null("AudioManager")
	if audio_manager:
		audio_manager.set_sfx_volume(value)
	
	# Save to config
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("audio", "sfx_volume", value)
	config.save("user://settings.cfg")
