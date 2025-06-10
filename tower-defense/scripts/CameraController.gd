extends Camera2D

@export var pan_speed: float = 400.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var map_bounds: Rect2 = Rect2(-500, -500, 3560, 2440)  # Extended bounds for scrolling beyond map
@export var enable_limits: bool = false  # Allow disabling limits for free scrolling

var is_panning: bool = false
var pan_start_mouse_pos: Vector2
var pan_start_cam_pos: Vector2

func _ready() -> void:
	# Set initial position to center of default view
	position = Vector2(640, 360)
	
	# Only set limits if enabled
	if enable_limits:
		limit_left = int(map_bounds.position.x)
		limit_top = int(map_bounds.position.y)
		limit_right = int(map_bounds.position.x + map_bounds.size.x)
		limit_bottom = int(map_bounds.position.y + map_bounds.size.y)
	else:
		# Set very loose limits to allow scrolling beyond map
		limit_left = -2000
		limit_top = -2000
		limit_right = 4560
		limit_bottom = 3440
	
	# Set initial zoom
	zoom = Vector2(1, 1)

func _input(event: InputEvent) -> void:
	# Handle mouse wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()
		
		# Middle mouse button panning
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_panning = true
				pan_start_mouse_pos = event.position
				pan_start_cam_pos = position
			else:
				is_panning = false
	
	# Handle mouse motion for panning
	elif event is InputEventMouseMotion and is_panning:
		var mouse_delta = event.position - pan_start_mouse_pos
		position = pan_start_cam_pos - mouse_delta / zoom

func _process(delta: float) -> void:
	var input_vector = Vector2.ZERO
	
	# WASD movement
	if Input.is_action_pressed("camera_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("camera_right"):
		input_vector.x += 1
	if Input.is_action_pressed("camera_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("camera_down"):
		input_vector.y += 1
	
	# Apply movement
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		position += input_vector * pan_speed * delta / zoom.x

func zoom_in() -> void:
	var new_zoom = zoom.x + zoom_speed
	new_zoom = clamp(new_zoom, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)

func zoom_out() -> void:
	var new_zoom = zoom.x - zoom_speed
	new_zoom = clamp(new_zoom, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)