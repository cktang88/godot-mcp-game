extends Node

class_name TimeController

# Time scale values
const NORMAL_SPEED = 1.0
const FAST_SPEED = 2.0
const VERY_FAST_SPEED = 4.0

var current_speed: float = NORMAL_SPEED

# UI References
var speed_buttons: Dictionary = {}

signal speed_changed(new_speed: float)

func _ready() -> void:
	# Set initial time scale
	Engine.time_scale = current_speed

func set_speed(speed: float) -> void:
	current_speed = speed
	Engine.time_scale = speed
	speed_changed.emit(speed)
	_update_button_states()

func set_normal_speed() -> void:
	set_speed(NORMAL_SPEED)

func set_fast_speed() -> void:
	set_speed(FAST_SPEED)

func set_very_fast_speed() -> void:
	set_speed(VERY_FAST_SPEED)

func pause_game() -> void:
	get_tree().paused = true

func unpause_game() -> void:
	get_tree().paused = false

func toggle_pause() -> void:
	get_tree().paused = !get_tree().paused

func register_speed_button(speed: float, button: Button) -> void:
	speed_buttons[speed] = button
	_update_button_states()

func _update_button_states() -> void:
	for speed in speed_buttons:
		var button = speed_buttons[speed]
		if button and is_instance_valid(button):
			# Highlight active speed button
			if abs(speed - current_speed) < 0.01:
				button.modulate = Color(1.2, 1.2, 1.2)
				button.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
			else:
				button.modulate = Color(1.0, 1.0, 1.0)
				button.remove_theme_color_override("font_color")