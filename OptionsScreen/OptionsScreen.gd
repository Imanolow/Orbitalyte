extends Node2D

# Botones
@onready var resume_button = $ResumeButton
@onready var menu_button = $MenuButton
@onready var exit_button = $ExitButton

# Señales
signal resume_pressed
signal menu_pressed
signal exit_pressed

# Offset adicional en X (usado por WorldLevel)
var offset_x: int = 0


func _ready():
	print("OptionsScreen._ready() - Conectando botones...")
	# Conectar botones
	resume_button.pressed.connect(_on_resume_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	print("OptionsScreen._ready() - Botones conectados")
	
	# Centrar en la pantalla
	global_position = get_viewport().get_visible_rect().get_center() - Vector2(200, 0)
	
	# Aplicar offset adicional si existe (para WorldLevel)
	global_position.x += offset_x
	
	# Inicialmente oculto
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	"""Handle Esc key to open/close options menu."""
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if visible:
			# Si está abierto, cerrar (volver al juego)
			_close_menu()
		else:
			# Si está cerrado, abrir
			show_options_menu()
		get_tree().root.set_input_as_handled()


func show_options_menu():
	"""Muestra el menú de opciones"""
	visible = true


func _close_menu() -> void:
	"""Cierra el menú y vuelve al juego"""
	print("OptionsScreen._close_menu() - Cerrando menú")
	visible = false
	emit_signal("resume_pressed")


func _on_resume_pressed():
	"""Se ejecuta cuando se presiona el botón Resume - volver al juego"""
	# Play button click sound
	var audio_manager = get_tree().root.get_node_or_null("AudioManager")
	if audio_manager:
		audio_manager.play_button_click()
	
	print("OptionsScreen._on_resume_pressed() - Resume presionado")
	_close_menu()


func _on_menu_pressed():
	"""Se ejecuta cuando se presiona el botón Menu"""
	# Play button click sound
	var audio_manager = get_tree().root.get_node_or_null("AudioManager")
	if audio_manager:
		audio_manager.play_button_click()
	
	print("OptionsScreen._on_menu_pressed() - EMITIENDO SEÑAL")
	emit_signal("menu_pressed")
	visible = false


func _on_exit_pressed():
	"""Se ejecuta cuando se presiona el botón Exit"""
	# Play button click sound
	var audio_manager = get_tree().root.get_node_or_null("AudioManager")
	if audio_manager:
		audio_manager.play_button_click()
	
	print("OptionsScreen._on_exit_pressed() - EMITIENDO SEÑAL")
	emit_signal("exit_pressed")
	visible = false
