extends Node
## Global audio manager - handles all SFX and music
## Autoload: AudioManager

# Music
var audio_player: AudioStreamPlayer = null
var current_music_path: String = ""
var target_volume: float = 0.5

# UI SFX
var button_click_players: Array[AudioStreamPlayer] = []
var button_click_sounds: Array[AudioStream] = []

# Gameplay SFX
var explosion_players: Array[AudioStreamPlayer] = []  # Max 2
var ship_travel_player: AudioStreamPlayer = null
var star_collect_player: AudioStreamPlayer = null
var victory_player: AudioStreamPlayer = null

# Power Bar (Dinámico)
var power_bar_player: AudioStreamPlayer = null
var power_bar_generator: AudioStreamGenerator = null

# WinScreen SFX
var achievement_pop_players: Array[AudioStreamPlayer] = []  # Max 3
var achievement_pop_sound: AudioStream = null


func _ready() -> void:
	"""Initialize all audio players on startup."""
	# Setup music player
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Master"
	add_child(audio_player)
	set_volume(0.08)
	
	# Setup UI SFX
	_setup_button_click_players()
	
	# Setup Gameplay SFX
	_setup_gameplay_players()
	
	# Setup WinScreen SFX
	_setup_achievement_pop_players()


func _setup_button_click_players() -> void:
	"""Create 2 button click players for variety."""
	button_click_sounds = [
		load("res://Sounds/UI/button_click_02.mp3"),
		load("res://Sounds/UI/button_click_02.mp3")
	]
	
	for i in range(2):
		var player = AudioStreamPlayer.new()
		player.volume_db = -5
		player.stream = button_click_sounds[i]
		add_child(player)
		button_click_players.append(player)


func _setup_gameplay_players() -> void:
	"""Create explosion, ship_travel, star_collect, victory players."""
	# Explosions (Max 2 simultáneas)
	for i in range(2):
		var player = AudioStreamPlayer.new()
		player.volume_db = -5
		add_child(player)
		explosion_players.append(player)
	
	# Ship Travel (Loop - se reemplaza)
	ship_travel_player = AudioStreamPlayer.new()
	ship_travel_player.volume_db = -5
	ship_travel_player.stream = load("res://Sounds/Gameplay/ship_travel.mp3")
	add_child(ship_travel_player)
	
	# Star Collect
	star_collect_player = AudioStreamPlayer.new()
	star_collect_player.volume_db = -5
	star_collect_player.stream = load("res://Sounds/Gameplay/star_collect.mp3")
	add_child(star_collect_player)
	
	# Victory
	victory_player = AudioStreamPlayer.new()
	victory_player.volume_db = -5
	victory_player.stream = load("res://Sounds/Gameplay/victory.mp3")
	add_child(victory_player)


func _setup_power_bar() -> void:
	"""Create dynamic power bar audio with AudioStreamGenerator.
	TODO: Implementar cuando tengamos archivo MP3 para power_bar_charge.
	"""
	pass


func _setup_achievement_pop_players() -> void:
	"""Create 3 achievement pop players for simultaneous pops."""
	achievement_pop_sound = load("res://Sounds/WinScreen/achievement_pop.mp3")
	
	for i in range(3):
		var player = AudioStreamPlayer.new()
		player.volume_db = -5
		player.stream = achievement_pop_sound
		add_child(player)
		achievement_pop_players.append(player)


# ============================================================================
# UI SFX
# ============================================================================

func play_button_click() -> void:
	"""Play a random button click sound."""
	if button_click_players.is_empty():
		return
	
	# Elegir un player aleatorio que no esté sonando
	var available_players = button_click_players.filter(func(p): return not p.playing)
	
	if available_players.is_empty():
		# Si todos están sonando, usar el primero (se solapará)
		button_click_players[0].play()
	else:
		# Elegir uno aleatorio
		var player = available_players[randi() % available_players.size()]
		player.play()


# ============================================================================
# GAMEPLAY SFX
# ============================================================================

func play_explosion() -> void:
	"""Play explosion sound (máx 2 simultáneas)."""
	# Buscar un player disponible
	for player in explosion_players:
		if not player.playing:
			player.stream = load("res://Sounds/Gameplay/explosion.mp3")
			player.play()
			return
	
	# Si todos están sonando, no reproducir otra (evitar spam)


func start_ship_travel() -> void:
	"""Start ship travel loop (reemplaza si ya está sonando)."""
	if ship_travel_player:
		ship_travel_player.play()


func stop_ship_travel() -> void:
	"""Stop ship travel loop."""
	if ship_travel_player:
		ship_travel_player.stop()


func play_star_collect() -> void:
	"""Play star collect sound."""
	if star_collect_player:
		star_collect_player.play()


func play_victory() -> void:
	"""Play victory sound."""
	if victory_player:
		victory_player.play()


# ============================================================================
# POWER BAR (DINÁMICO)
# ============================================================================

func update_power_pitch(_power: float) -> void:
	"""Update power bar pitch based on power (0.0 to 100.0).
	Genera un tono dinámico que sube con la potencia.
	"""
	# TODO: Implementar power bar sound con archivo MP3 cuando esté disponible
	# AudioStreamGenerator en Godot 4 requiere AudioStreamPlayback (API compleja)
	pass


func _generate_power_tone(_frequency: float, _volume: float) -> void:
	"""Placeholder - AudioStreamGenerator push_buffer no existe en Godot 4."""
	pass


func stop_power_bar() -> void:
	"""Stop power bar sound."""
	if power_bar_player:
		power_bar_player.stop()


# ============================================================================
# WINSCREEN SFX
# ============================================================================

func play_achievement_pop() -> void:
	"""Play achievement pop sound (máx 3 simultáneas)."""
	# Buscar un player disponible
	for player in achievement_pop_players:
		if not player.playing:
			player.play()
			return
	
	# Si todos están sonando, no reproducir otro


# ============================================================================
# MUSIC (Funcionalidad Original)
# ============================================================================

func play_music(music_path: String, loop: bool = true) -> void:
	"""Play background music.
	If same music is already playing, continue without restart."""
	# If same music is playing, do nothing
	if audio_player.playing and current_music_path == music_path:
		return
	
	# Load and play new music
	var audio_stream = load(music_path)
	if audio_stream == null:
		push_error("Failed to load music: " + music_path)
		return
	
	current_music_path = music_path
	audio_player.stream = audio_stream
	
	if loop:
		audio_player.bus = "Master"
	
	audio_player.play()


func stop_music() -> void:
	"""Stop background music."""
	audio_player.stop()
	current_music_path = ""


func set_volume(volume: float) -> void:
	"""Set master volume (0.0 to 1.0)."""
	target_volume = clamp(volume, 0.0, 1.0)
	if audio_player:
		audio_player.volume_db = linear_to_db(target_volume)


func get_volume() -> float:
	"""Get current master volume."""
	return target_volume


func is_playing() -> bool:
	"""Check if music is currently playing."""
	return audio_player.playing
