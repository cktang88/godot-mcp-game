extends Control

var input_label: Label
var player_car: RigidBody3D

func _ready() -> void:
	# Create a label for debug info
	input_label = Label.new()
	input_label.position = Vector2(10, 10)
	input_label.size = Vector2(400, 300)
	input_label.add_theme_font_size_override("font_size", 16)
	add_child(input_label)
	
	# Find player car
	await get_tree().process_frame
	var main = get_tree().current_scene
	if main and main.has_node("PlayerCar"):
		player_car = main.get_node("PlayerCar")
		print("DebugUI found player car!")

func _process(_delta: float) -> void:
	var debug_text = "=== CONTROLS ===\n"
	debug_text += "Click+Drag: Rotate camera\n"
	debug_text += "Scroll: Zoom in/out\n"
	debug_text += "R: Reset car\n"
	debug_text += "ESC: Quit\n\n"
	
	debug_text += "=== INPUT ===\n"
	debug_text += "W/Up: " + str(Input.is_action_pressed("accelerate")) + "\n"
	debug_text += "S/Down: " + str(Input.is_action_pressed("brake")) + "\n"
	debug_text += "A/Left: " + str(Input.is_action_pressed("steer_left")) + "\n"
	debug_text += "D/Right: " + str(Input.is_action_pressed("steer_right")) + "\n"
	debug_text += "Space: " + str(Input.is_action_pressed("handbrake")) + "\n"
	
	if player_car:
		debug_text += "\n=== CAR INFO ===\n"
		debug_text += "Speed: %.1f\n" % player_car.linear_velocity.length()
		debug_text += "Rotation: %.1f°\n" % player_car.rotation_degrees.y
	
	input_label.text = debug_text
