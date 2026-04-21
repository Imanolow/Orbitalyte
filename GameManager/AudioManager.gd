extends Node
## Global audio manager for background music
## Autoload: AudioManager

var audio_player: AudioStreamPlayer = null
var current_music_path: String = ""
var target_volume: float = 0.5


func _ready() -> void:
	"""Initialize audio player on startup."""
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Master"
	add_child(audio_player)
	# Set volume to 50%
	set_volume(0.2)


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
