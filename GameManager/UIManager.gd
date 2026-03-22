extends CanvasLayer
## Centralized UI manager - creates and manages all UI elements independently.
## This script handles all UI creation and state, making it reusable across levels.

class_name UIManager

var left_button: Button
var right_button: Button
var launch_button: Button
var ui_panel: Control
var win_overlay: Panel
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


func show_win_screen() -> void:
	"""Display victory screen."""
	if not win_overlay:
		_create_win_overlay()
	
	win_overlay.visible = true


func hide_win_screen() -> void:
	"""Hide victory screen."""
	if win_overlay:
		win_overlay.visible = false


func _create_win_overlay() -> void:
	"""Create the victory overlay dynamically."""
	win_overlay = Panel.new()
	win_overlay.name = "WinOverlay"
	win_overlay.anchor_left = 0.25
	win_overlay.anchor_top = 0.25
	win_overlay.anchor_right = 0.75
	win_overlay.anchor_bottom = 0.75
	win_overlay.modulate = Color(1, 1, 1, 1)
	
	# Style - darker background for the modal box
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.1, 0.95)
	style.border_color = Color(1, 0.85, 0.2, 0.8)
	win_overlay.add_theme_stylebox_override("panel", style)
	
	# Create VBox for layout
	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.0
	vbox.anchor_top = 0.0
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.add_theme_constant_override("separation", 12)
	vbox.add_theme_constant_override("margin_left", 20)
	vbox.add_theme_constant_override("margin_top", 20)
	vbox.add_theme_constant_override("margin_right", 20)
	vbox.add_theme_constant_override("margin_bottom", 20)
	win_overlay.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "✦ VICTORY ✦"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	# Next button
	var next_btn = Button.new()
	next_btn.name = "NextButton"
	next_btn.text = "NEXT LEVEL"
	next_btn.custom_minimum_size = Vector2(150, 54)
	_style_launch_button(next_btn)
	next_btn.pressed.connect(_on_next_level_pressed)
	vbox.add_child(next_btn)
	
	add_child(win_overlay)
	win_overlay.visible = false


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
