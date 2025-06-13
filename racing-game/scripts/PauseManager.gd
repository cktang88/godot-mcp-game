extends Node

var is_paused: bool = false
var pause_menu: Control

func _ready() -> void:
	# Create pause menu UI
	_create_pause_menu()
	
	# Make sure this node processes even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	is_paused = !is_paused
	
	# Pause the game tree
	get_tree().paused = is_paused
	
	# Show/hide pause menu
	if pause_menu:
		pause_menu.visible = is_paused
	
	# Mouse is always visible in this racing game
	# Only ensure it's visible when paused
	if is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _create_pause_menu() -> void:
	# Create canvas layer for UI (so it's always on top)
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "PauseCanvas"
	canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas_layer)
	
	# Create pause menu container
	pause_menu = Control.new()
	pause_menu.name = "PauseMenu"
	pause_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_menu.visible = false
	canvas_layer.add_child(pause_menu)
	
	# Semi-transparent background
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.7)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_menu.add_child(background)
	
	# Pause text
	var pause_label = Label.new()
	pause_label.text = "PAUSED"
	pause_label.add_theme_font_size_override("font_size", 64)
	pause_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pause_label.position.y -= 100
	pause_menu.add_child(pause_label)
	
	# Instructions
	var instructions = Label.new()
	instructions.text = "Press P to resume\nPress ESC to quit"
	instructions.add_theme_font_size_override("font_size", 24)
	instructions.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	instructions.position.y += 50
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_menu.add_child(instructions)