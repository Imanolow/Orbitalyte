extends Node2D

# Iconos azules (activos)
@onready var check_blue = $CheckBlue
@onready var star_blue = $StarBlue
@onready var one_blue = $OneBlue

# Botones
@onready var retry_button = $RetryButton
@onready var next_button = $NextButton

# Señales
signal retry_pressed
signal next_level_pressed

# Constantes para animación
const ICON_DELAY = 1.0  # Delay inicial para Check en segundos
const ICON_FADE_DURATION = 0.3  # Duración de la aparición


func _ready():
	# Conectar botones
	retry_button.pressed.connect(_on_retry_pressed)
	next_button.pressed.connect(_on_next_level_pressed)
	
	# Centrar en la pantalla, 200 píxeles a la izquierda
	global_position = get_viewport().get_visible_rect().get_center() - Vector2(180, 0)
	
	# Inicialmente oculto
	visible = false


func show_win_screen(has_one_shot: bool = false, has_star: bool = false):
	"""Muestra la pantalla de victoria con animación progresiva de iconos"""
	# Debug
	print("WIN SCREEN - has_one_shot: ", has_one_shot, " has_star: ", has_star)
	
	# Asegurar que está centrado, 200 píxeles a la izquierda
	global_position = get_viewport().get_visible_rect().get_center() - Vector2(200, 0)
	
	visible = true
	
	# Resetear estado de los iconos azules al inicio
	check_blue.modulate.a = 0.0
	star_blue.modulate.a = 0.0
	one_blue.modulate.a = 0.0
	
	# Activar Check (siempre se activa primero) a 1 segundo
	_activate_icon(check_blue, ICON_DELAY)
	
	# Activar Star si aplica (a los 2 segundos)
	if has_star:
		print("Activando STAR icon")
		_activate_icon(star_blue, ICON_DELAY + 1.0)
	
	# Activar One Shot si aplica (a los 2 o 3 segundos según condiciones)
	if has_one_shot:
		print("Activando ONE SHOT icon")
		var delay = ICON_DELAY + 1.0
		if has_star:
			delay += 1.0  # Si hay Star también, esperar hasta los 3 segundos
		_activate_icon(one_blue, delay)


func _activate_icon(icon: Sprite2D, delay: float):
	"""Activa un icono con fade-in después del delay especificado"""
	await get_tree().create_timer(delay).timeout
	
	# Hacer visible el icono
	icon.visible = true
	
	# Animar la opacidad del 0 al 1
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "modulate:a", 1.0, ICON_FADE_DURATION)


func _on_retry_pressed():
	"""Se ejecuta cuando se presiona el botón Retry - reinicia el nivel actual"""
	# Obtener el nivel actual de la escena
	var current_scene = get_tree().current_scene.get_scene_file_path()
	var current_level = _extract_level_from_path(current_scene)
	
	print("WinScreen RETRY - Current level: ", current_level)
	
	# Resetear estado del juego
	var level_manager = get_tree().root.get_node_or_null("LevelManager")
	if level_manager:
		level_manager.attempts = 1  # Resetear attempts
		level_manager.reset_first_entry()
	
	# Recargar el nivel
	var level_path = "res://MainScenes/Level " + current_level + ".tscn"
	get_tree().change_scene_to_file(level_path)
	
	emit_signal("retry_pressed")
	visible = false


func _on_next_level_pressed():
	"""Se ejecuta cuando se presiona el botón Next Level"""
	emit_signal("next_level_pressed")
	visible = false


func _extract_level_from_path(path: String) -> String:
	"""Extrae el nombre del nivel del path de la escena (ej: 'Level 1-3' de 'res://MainScenes/Level 1-3.tscn')"""
	# El path será algo como: "res://MainScenes/Level 1-3.tscn"
	# Queremos extraer "1-3"
	
	if "Level " in path:
		# Buscar "Level " y tomar lo que sigue hasta .tscn
		var start_index = path.find("Level ") + 6  # 6 es la longitud de "Level "
		var end_index = path.find(".tscn")
		if start_index > 5 and end_index > start_index:
			return path.substr(start_index, end_index - start_index)
	
	# Default si no se puede extraer
	return "1-1"
