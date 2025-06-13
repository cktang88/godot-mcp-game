extends Node3D

# Spring-based chase camera properties
@export var spring_length: float = 15.0  # Distance from car
@export var spring_height: float = 8.0   # Height above car
@export var spring_stiffness: float = 2.5  # Reduced for smoother movement
@export var spring_damping: float = 0.7   # Increased damping to reduce jitter

# Camera look properties
@export var look_ahead_distance: float = 5.0  # How far ahead to look
@export var camera_rotation_speed: float = 2.0  # How fast camera rotates to face forward
@export var fov: float = 60.0  # Field of view

# Mouse control settings
@export var mouse_sensitivity: float = 0.5
@export var zoom_speed: float = 1.0
@export var min_distance: float = 5.0
@export var max_distance: float = 30.0

# SpringArm3D for collision detection
@export var use_collision_detection: bool = true
@export var collision_margin: float = 0.2

@onready var spring_arm: SpringArm3D
@onready var camera: Camera3D

var target: Node3D
var spring_velocity: Vector3 = Vector3.ZERO
var current_rotation: float = 0.0
var is_dragging: bool = false
var manual_rotation: float = 0.0  # Additional rotation from mouse
var smoothed_car_position: Vector3 = Vector3.ZERO  # For interpolation
var position_smoothing: float = 10.0  # How quickly to interpolate car position

func _ready() -> void:
	# Set process mode to pausable
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	# Create SpringArm3D for collision detection
	spring_arm = SpringArm3D.new()
	spring_arm.name = "SpringArm3D"
	spring_arm.spring_length = 0.01  # We'll handle distance ourselves
	spring_arm.margin = collision_margin
	add_child(spring_arm)
	
	# Create camera as child of SpringArm3D
	if not camera:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		spring_arm.add_child(camera)
		
	# Set up camera
	camera.fov = fov
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	
	# The SpringArm3D will automatically use the Camera3D's pyramid shape for collision

func set_target(new_target: Node3D) -> void:
	target = new_target
	if target:
		# Initialize position behind the car
		var car_transform = target.global_transform
		global_position = car_transform.origin - car_transform.basis.z * spring_length + Vector3.UP * spring_height
		smoothed_car_position = car_transform.origin
		
		# Exclude the car from camera collision checks
		if use_collision_detection and target.has_method("get_rid"):
			spring_arm.add_excluded_object(target.get_rid())

func _input(event: InputEvent) -> void:
	# Handle mouse button for drag
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
		# Handle mouse wheel for zoom
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			spring_length -= zoom_speed
			spring_length = clamp(spring_length, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			spring_length += zoom_speed
			spring_length = clamp(spring_length, min_distance, max_distance)
	
	# Handle mouse movement for camera rotation (only when dragging)
	if event is InputEventMouseMotion and is_dragging:
		manual_rotation -= event.relative.x * mouse_sensitivity * 0.01

func _physics_process(delta: float) -> void:
	if not target or not spring_arm:
		return
	
	# Get car's transform
	var car_transform = target.global_transform
	var car_position = car_transform.origin
	
	# Smooth the car position to reduce jitter
	smoothed_car_position = smoothed_car_position.lerp(car_position, position_smoothing * delta)
	
	var car_forward = -car_transform.basis.z  # Forward is -Z in Godot
	var car_rotation = atan2(car_forward.x, car_forward.z)
	
	# Smoothly rotate camera to follow car's rotation
	var target_rotation = car_rotation + manual_rotation
	current_rotation = lerp_angle(current_rotation, target_rotation, camera_rotation_speed * delta)
	
	# Calculate ideal camera position (spring anchor point)
	var ideal_offset = Vector3()
	ideal_offset.x = sin(current_rotation) * spring_length
	ideal_offset.z = cos(current_rotation) * spring_length
	ideal_offset.y = spring_height
	var ideal_position = smoothed_car_position + ideal_offset  # Use smoothed position
	
	# Apply spring physics
	var displacement = ideal_position - global_position
	var spring_force = displacement * spring_stiffness
	spring_velocity += spring_force * delta
	spring_velocity *= (1.0 - spring_damping * delta)  # Apply damping
	global_position += spring_velocity * delta
	
	# Calculate look target with forward prediction
	var look_target = smoothed_car_position  # Use smoothed position
	if target is RigidBody3D:
		var velocity = target.linear_velocity
		if velocity.length() > 0.1:
			# Look ahead based on velocity
			look_target += car_forward * look_ahead_distance
	
	# Set up SpringArm3D for collision detection
	if use_collision_detection:
		# Point SpringArm3D from current position toward the car
		var to_target = car_position - global_position
		if to_target.length() > 0.01:
			spring_arm.look_at(car_position, Vector3.UP)
			# Set spring length to actual distance for collision checking
			spring_arm.spring_length = to_target.length()
	
	# Make camera look at target
	if camera:
		# Camera is child of SpringArm3D, so we need to compensate for SpringArm3D's rotation
		var spring_arm_global_transform = spring_arm.global_transform
		var camera_global_pos = camera.global_position
		camera.set_global_transform(Transform3D())
		camera.global_position = camera_global_pos
		camera.look_at(look_target, Vector3.UP)

func reset_camera() -> void:
	manual_rotation = 0.0
	spring_velocity = Vector3.ZERO
	if target:
		var car_transform = target.global_transform
		current_rotation = atan2(-car_transform.basis.z.x, -car_transform.basis.z.z)
		global_position = car_transform.origin - car_transform.basis.z * spring_length + Vector3.UP * spring_height
