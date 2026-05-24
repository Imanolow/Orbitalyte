extends Node

var audio_player: AudioStreamPlayer = null
var current_music_path: String = ""
var music_volume: float = 0.5
var sfx_volume: float = 0.5
var master_volume: float = 0.5

var button_click_players: Array[AudioStreamPlayer] = []
var explosion_players: Array[AudioStreamPlayer] = []
var ship_travel_player: AudioStreamPlayer = null
var star_collect_player: AudioStreamPlayer = null
var victory_player: AudioStreamPlayer = null
var achievement_pop_players: Array[AudioStreamPlayer] = []
var power_bar_player: AudioStreamPlayer = null


func _ready() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "Music")
	
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "SFX")
	
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Master"
	add_child(audio_player)
	
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		master_volume = config.get_value("audio", "master_volume", 0.5)
		music_volume = config.get_value("audio", "music_volume", 0.5)
		sfx_volume = config.get_value("audio", "sfx_volume", 0.5)
	
	_update_volumes()
	_setup_button_click_players()
	_setup_gameplay_players()
	_setup_achievement_pop_players()


func _update_volumes() -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(max(master_volume, 0.01)))
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(max(music_volume, 0.01)))


func _setup_button_click_players() -> void:
	var sounds = [load("res://Sounds/UI/button_click_02.mp3"), load("res://Sounds/UI/button_click_02.mp3")]
	for i in range(2):
		var p = AudioStreamPlayer.new()
		p.volume_db = 0
		p.bus = "SFX"
		p.stream = sounds[i]
		add_child(p)
		button_click_players.append(p)


func _setup_gameplay_players() -> void:
	for i in range(2):
		var p = AudioStreamPlayer.new()
		p.volume_db = 0
		p.bus = "SFX"
		add_child(p)
		explosion_players.append(p)
	
	ship_travel_player = AudioStreamPlayer.new()
	ship_travel_player.volume_db = 0
	ship_travel_player.bus = "SFX"
	ship_travel_player.stream = load("res://Sounds/Gameplay/ship_travel.mp3")
	add_child(ship_travel_player)
	
	power_bar_player = AudioStreamPlayer.new()
	power_bar_player.volume_db = 0
	power_bar_player.bus = "SFX"
	power_bar_player.stream = load("res://Sounds/UI/button_click_02.mp3")
	add_child(power_bar_player)
	
	star_collect_player = AudioStreamPlayer.new()
	star_collect_player.volume_db = 0
	star_collect_player.bus = "SFX"
	star_collect_player.stream = load("res://Sounds/Gameplay/star_collect.mp3")
	add_child(star_collect_player)
	
	victory_player = AudioStreamPlayer.new()
	victory_player.volume_db = 0
	victory_player.bus = "SFX"
	victory_player.stream = load("res://Sounds/Gameplay/victory.mp3")
	add_child(victory_player)


func _setup_achievement_pop_players() -> void:
	var sound = load("res://Sounds/WinScreen/achievement_pop.mp3")
	for i in range(3):
		var p = AudioStreamPlayer.new()
		p.volume_db = 0
		p.bus = "SFX"
		p.stream = sound
		add_child(p)
		achievement_pop_players.append(p)


func play_button_click() -> void:
	if button_click_players.is_empty():
		return
	var avail = button_click_players.filter(func(p): return not p.playing)
	if avail.is_empty():
		button_click_players[0].play()
	else:
		avail[randi() % avail.size()].play()


func play_explosion() -> void:
	for p in explosion_players:
		if not p.playing:
			p.stream = load("res://Sounds/Gameplay/explosion.mp3")
			p.play()
			return


func start_ship_travel() -> void:
	if ship_travel_player:
		ship_travel_player.play()


func stop_ship_travel() -> void:
	if ship_travel_player:
		ship_travel_player.stop()


func play_star_collect() -> void:
	if star_collect_player:
		star_collect_player.play()


func play_victory() -> void:
	if victory_player:
		victory_player.play()


func play_achievement_pop() -> void:
	for p in achievement_pop_players:
		if not p.playing:
			p.play()
			return


func play_music(music_path: String, _loop: bool = true) -> void:
	if audio_player.playing and current_music_path == music_path:
		return
	var stream = load(music_path)
	if stream == null:
		push_error("Failed to load music: " + music_path)
		return
	current_music_path = music_path
	audio_player.stream = stream
	audio_player.bus = "Music"
	audio_player.play()


func stop_music() -> void:
	audio_player.stop()
	current_music_path = ""


func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	var idx = AudioServer.get_bus_index("Master")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(max(master_volume, 0.01)))


func get_master_volume() -> float:
	return master_volume


func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	var idx = AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(max(music_volume, 0.01)))


func get_music_volume() -> float:
	return music_volume


func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	var idx = AudioServer.get_bus_index("SFX")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(max(sfx_volume, 0.01)))


func get_sfx_volume() -> float:
	return sfx_volume


func set_volume(volume: float) -> void:
	set_master_volume(volume)


func get_volume() -> float:
	return get_master_volume()


func is_playing() -> bool:
	return audio_player.playing


func update_power_pitch(power: float) -> void:
	"""Update power bar pitch based on charge amount (0.0 to 1.0)."""
	if not power_bar_player:
		return
	
	# Start playing if not already
	if not power_bar_player.playing:
		power_bar_player.play()
	
	# Pitch scales from 1.0 (low power) to 2.0 (max power)
	power_bar_player.pitch_scale = 1.0 + (power * 1.0)


func stop_power_bar() -> void:
	"""Stop the power bar sound."""
	if power_bar_player and power_bar_player.playing:
		power_bar_player.stop()