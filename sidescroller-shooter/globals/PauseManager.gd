extends Node

var is_paused: bool = false
var pause_ui_scene = preload("res://ui/PauseUI.tscn")
var pause_ui_instance: CanvasLayer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Create pause UI instance
	pause_ui_instance = pause_ui_scene.instantiate()
	add_child(pause_ui_instance)

func _input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	
	# Show/hide pause UI
	if is_paused:
		pause_ui_instance.show_pause()
	else:
		pause_ui_instance.hide_pause()