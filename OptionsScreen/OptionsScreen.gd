extends Node2D

# Botones
@onready var resume_button = $ResumeButton
@onready var menu_button = $MenuButton
@onready var exit_button = $ExitButton

# Señales
signal resume_pressed
signal menu_pressed
signal exit_pressed


func _ready():
	print("OptionsScreen._ready() - Conectando botones...")
	# Conectar botones
	resume_button.pressed.connect(_on_resume_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	print("OptionsScreen._ready() - Botones conectados")
	
	# Centrar en la pantalla
	global_position = get_viewport().get_visible_rect().get_center() - Vector2(200, 0)
	
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
	# Asegurar que está centrado
	global_position = get_viewport().get_visible_rect().get_center() - Vector2(200, 0)
	
	visible = true


func _close_menu() -> void:
	"""Cierra el menú y vuelve al juego"""
	print("OptionsScreen._close_menu() - Cerrando menú")
	visible = false
	emit_signal("resume_pressed")


func _on_resume_pressed():
	"""Se ejecuta cuando se presiona el botón Resume - volver al juego"""
	print("OptionsScreen._on_resume_pressed() - Resume presionado")
	_close_menu()


func _on_menu_pressed():
	"""Se ejecuta cuando se presiona el botón Menu"""
	print("OptionsScreen._on_menu_pressed() - EMITIENDO SEÑAL")
	emit_signal("menu_pressed")
	visible = false


func _on_exit_pressed():
	"""Se ejecuta cuando se presiona el botón Exit"""
	print("OptionsScreen._on_exit_pressed() - EMITIENDO SEÑAL")
	emit_signal("exit_pressed")
	visible = false
