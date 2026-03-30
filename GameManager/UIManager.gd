extends CanvasLayer
## Centralized UI manager - creates and manages all UI elements independently.
## This script handles all UI creation and state, making it reusable across levels.

class_name UIManager

var left_button: Button
var right_button: Button
var launch_button: Button
var ui_panel: Control
var win_overlay: Panel
var win_screen: Node2D
var lose_screen: Node2D
var lives_label1: Label
var lives_label2: Label


func _ready() -> void:
	"""Initialize or create the UI."""
	await get_tree().process_frame  # Wait for scene tree to be ready
	
	_find_existing_ui()  # Try to find existing UI
	if not ui_panel:
		_create_ui_from_scratch()
	
	# Ensure lives labels exist and are updated
	_find_lives_labels()
	
	# Update lives display
	_update_lives_display()


func _find_existing_ui() -> bool:
	"""Try to find existing UI in the scene. Returns true if found."""
	var panel = get_tree().root.get_node_or_null("Main/UIPanel")
	if panel:
		ui_panel = panel
		left_button = panel.get_node_or_null("LeftButton")
		right_button = panel.get_node_or_null("RightButton")
		launch_button = panel.get_node_or_null("LaunchButton")
		return left_button and right_button and launch_button
	return false


func _create_ui_from_scratch() -> void:
	"""Create all UI elements programmatically."""
	# Create main UI panel at bottom
	ui_panel = Panel.new()
	ui_panel.name = "UIPanel"
	ui_panel.anchor_left = 0.0
	ui_panel.anchor_top = 1.0
	ui_panel.anchor_right = 1.0
	ui_panel.anchor_bottom = 1.0
	ui_panel.offset_top = -86
	ui_panel.custom_minimum_size = Vector2(0, 86)
	
	# Style the panel
	var panel_stylebox = StyleBoxFlat.new()
	panel_stylebox.bg_color = Color(0.008, 0.008, 0.059)  # #02020f
	ui_panel.add_theme_stylebox_override("panel", panel_stylebox)
	
	# Create HBox for button layout
	var hbox = HBoxContainer.new()
	hbox.name = "ButtonContainer"
	hbox.anchor_left = 0.0
	hbox.anchor_top = 0.0
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	hbox.add_theme_constant_override("separation", 8)
	hbox.custom_minimum_size = Vector2(0, 86)
	ui_panel.add_child(hbox)
	
	# Create left button
	left_button = Button.new()
	left_button.name = "LeftButton"
	left_button.text = "◀"
	left_button.custom_minimum_size = Vector2(54, 54)
	left_button.modulate = Color.WHITE
	_style_direction_button(left_button)
	hbox.add_child(left_button)
	
	# Create right button
	right_button = Button.new()
	right_button.name = "RightButton"
	right_button.text = "▶"
	right_button.custom_minimum_size = Vector2(54, 54)
	right_button.modulate = Color.WHITE
	_style_direction_button(right_button)
	hbox.add_child(right_button)
	
	# Create spacer
	var spacer = Control.new()
	spacer.name = "Spacer"
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	# Create launch button
	launch_button = Button.new()
	launch_button.name = "LaunchButton"
	launch_button.text = "LAUNCH"
	launch_button.custom_minimum_size = Vector2(130, 54)
	_style_launch_button(launch_button)
	hbox.add_child(launch_button)
	
	# Add UI panel to scene (this layer)
	add_child(ui_panel)


func _style_direction_button(btn: Button) -> void:
	"""Apply styling to left/right direction buttons."""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.03)
	style.border_color = Color(1.0, 1.0, 1.0, 0.19)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 27
	style.corner_radius_top_right = 27
	style.corner_radius_bottom_left = 27
	style.corner_radius_bottom_right = 27
	btn.add_theme_stylebox_override("normal", style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(1.0, 1.0, 1.0, 0.15)
	hover_style.border_color = Color(1.0, 1.0, 1.0, 0.5)
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)


func _style_launch_button(btn: Button) -> void:
	"""Apply styling to launch button."""
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.85, 0.2, 0.07)
	style.border_color = Color(1.0, 0.85, 0.2, 0.38)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 27
	style.corner_radius_top_right = 27
	style.corner_radius_bottom_left = 27
	style.corner_radius_bottom_right = 27
	btn.add_theme_stylebox_override("normal", style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(1.0, 0.85, 0.2, 0.15)
	hover_style.border_color = Color(1.0, 0.85, 0.2, 0.8)
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("focused", hover_style)


func _find_lives_labels() -> void:
	"""Find the lives labels in the scene (UIPanel/LivesLabel1 and LivesLabel2)."""
	var ui_panel_node = get_tree().root.get_node_or_null("Main/UIPanel")
	if ui_panel_node:
		lives_label1 = ui_panel_node.get_node_or_null("LivesLabel1")
		lives_label2 = ui_panel_node.get_node_or_null("LivesLabel2")


func _update_lives_display() -> void:
	"""Update the lives display with two-digit format."""
	var level_manager = get_tree().root.get_node_or_null("LevelManager")
	if not level_manager:
		return
	
	var lives = level_manager.lives
	var tens = lives / 10
	var ones = lives % 10
	
	if lives_label1:
		lives_label1.text = str(tens)
	if lives_label2:
		lives_label2.text = str(ones)


func show_win_screen(has_one_shot: bool = false, has_star: bool = false) -> void:
	"""Display victory screen with custom parameters."""
	if not win_screen:
		_load_win_screen()
	
	if win_screen:
		# Connect signals if not already connected
		if not win_screen.retry_pressed.is_connected(_on_retry_pressed):
			win_screen.retry_pressed.connect(_on_retry_pressed)
		if not win_screen.next_level_pressed.is_connected(_on_next_level_pressed):
			win_screen.next_level_pressed.connect(_on_next_level_pressed)
		
		# Show the win screen with parameters
		win_screen.show_win_screen(has_one_shot, has_star)


func hide_win_screen() -> void:
	"""Hide victory screen."""
	if win_screen:
		win_screen.visible = false


func _load_win_screen() -> void:
	"""Load the WinScreen scene."""
	var win_screen_scene = load("res://WinScreen/WinScreen.tscn")
	if win_screen_scene:
		win_screen = win_screen_scene.instantiate()
		add_child(win_screen)
	else:
		push_error("Could not load WinScreen scene")



func _on_retry_pressed() -> void:
	"""Handle retry button press."""
	var script_mgr = get_tree().root.get_node_or_null("Main/GameManager")
	if script_mgr and script_mgr.has_method("reset_level"):
		script_mgr.reset_level()
	else:
		push_error("Could not find script_manager to reset level")


func _on_next_level_pressed() -> void:
	"""Handle next level button press."""
	var script_mgr = get_tree().root.get_node_or_null("Main/GameManager")
	if script_mgr and script_mgr.has_method("_on_next_level_pressed"):
		script_mgr._on_next_level_pressed()
	else:
		push_error("Could not find script_manager to call next level")


func get_buttons() -> Dictionary:
	"""Return all buttons for external access."""
	return {
		"left": left_button,
		"right": right_button,
		"launch": launch_button
	}


func update_lives() -> void:
	"""Called when lives change - update the display."""
	_update_lives_display()


func show_lose_screen() -> void:
	"""Display the lose screen."""
	if not lose_screen:
		_load_lose_screen()
	
	if lose_screen:
		# Connect signals if not already connected
		if not lose_screen.retry_pressed.is_connected(_on_lose_retry_pressed):
			lose_screen.retry_pressed.connect(_on_lose_retry_pressed)
		if not lose_screen.menu_pressed.is_connected(_on_lose_menu_pressed):
			lose_screen.menu_pressed.connect(_on_lose_menu_pressed)
		
		# Show the lose screen
		lose_screen.show_lose_screen()


func hide_lose_screen() -> void:
	"""Hide the lose screen."""
	if lose_screen:
		lose_screen.visible = false


func _load_lose_screen() -> void:
	"""Load the LoseScreen scene."""
	var lose_screen_scene = load("res://LoseScreen/LoseScreen.tscn")
	if lose_screen_scene:
		lose_screen = lose_screen_scene.instantiate()
		add_child(lose_screen)
	else:
		push_error("Could not load LoseScreen scene")


func _on_lose_retry_pressed() -> void:
	"""Handle lose screen retry button press - handled by lose_screen.gd itself."""
	# The lose_screen script handles this directly
	pass


func _on_lose_menu_pressed() -> void:
	"""Handle lose screen menu button press - handled by lose_screen.gd itself."""
	# The lose_screen script handles this directly
	pass
