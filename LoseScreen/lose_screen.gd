extends Node2D

# Botones
@onready var retry_button = $RetryButton
@onready var menu_button = $NextButton

# Señales
signal retry_pressed
signal menu_pressed

func _ready():
	# Conectar botones
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	# Centrar en la pantalla, 200 píxeles a la izquierda
	global_position = get_viewport().get_visible_rect().get_center() - Vector2(180, 0)
	
	# Inicialmente oculto
	visible = false


func show_lose_screen():
	"""Muestra la pantalla de pérdida """
	# Asegurar que está centrado, 200 píxeles a la izquierda
	global_position = get_viewport().get_visible_rect().get_center() - Vector2(200, 0)
	visible = true


func _on_retry_pressed():
	"""Se ejecuta cuando se presiona el botón Retry - va al primer nivel de la zona actual"""
	# Obtener el nivel actual de la escena
	var current_scene = get_tree().current_scene.get_scene_file_path()
	var current_level = _extract_level_from_path(current_scene)
	
	# Extraer la zona del nivel actual (ej: "1-3" -> "1")
	var zone = current_level.split("-")[0]
	
	# Crear el nombre del primer nivel de la zona (ej: zona "1" -> "1-1")
	var first_level_in_zone = zone + "-1"
	
	print("Current level: ", current_level, " - Zone: ", zone, " - Retry to: ", first_level_in_zone)
	
	# Resetear estado del juego
	var level_manager = get_tree().root.get_node_or_null("LevelManager")
	if level_manager:
		level_manager.reset_first_entry()
	
	# Cargar el nivel
	var level_path = "res://MainScenes/Level " + first_level_in_zone + ".tscn"
	get_tree().change_scene_to_file(level_path)
	
	emit_signal("retry_pressed")
	visible = false


func _on_menu_pressed():
	"""Se ejecuta cuando se presiona el botón Menú - vuelve al menú principal"""
	# Resetear estado del juego
	var level_manager = get_tree().root.get_node_or_null("LevelManager")
	if level_manager:
		level_manager.reset_first_entry()
	
	# Volver al menú principal
	get_tree().change_scene_to_file("res://MainScenes/MainMenu.tscn")
	
	emit_signal("menu_pressed")
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
