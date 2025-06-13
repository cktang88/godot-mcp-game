extends Node3D

@onready var player_car: VehicleBody3D
@onready var camera_controller: Node3D
@onready var race_ui: Control
@onready var directional_light: DirectionalLight3D
@onready var looped_track: Node3D

func _ready() -> void:
	_setup_scene()
	_setup_track()  # Create track first
	await get_tree().process_frame  # Wait for physics to initialize
	await get_tree().physics_frame  # Extra wait for track generation
	_setup_player()
	_setup_camera()
	_setup_lighting()
	_setup_debug_ui()
	_setup_pause_manager()

func _setup_scene() -> void:
	# Create DirectionalLight3D if not exists
	directional_light = DirectionalLight3D.new()
	directional_light.rotation_degrees = Vector3(-45, -45, 0)
	directional_light.light_energy = 1.0
	directional_light.shadow_enabled = true
	add_child(directional_light)
	
	# Create temporary ground plane
	var ground_body = StaticBody3D.new()
	ground_body.name = "TempGround"
	add_child(ground_body)
	
	var ground_collision = CollisionShape3D.new()
	var ground_shape = BoxShape3D.new()
	ground_shape.size = Vector3(500, 1, 500)
	ground_collision.shape = ground_shape
	ground_collision.position.y = -5
	ground_body.add_child(ground_collision)
	
	# Visual ground
	var ground_mesh = MeshInstance3D.new()
	var ground_box = BoxMesh.new()
	ground_box.size = Vector3(500, 1, 500)
	ground_mesh.mesh = ground_box
	ground_mesh.position.y = -5
	var ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.3, 0.5, 0.3)
	ground_mesh.material_override = ground_material
	add_child(ground_mesh)

func _setup_player() -> void:
	# Create player car using VehicleBody3D
	player_car = VehicleBody3D.new()
	player_car.name = "PlayerCar"
	add_child(player_car)
	
	# Add vehicle controller script
	var car_script = load("res://scripts/VehicleController.gd")
	player_car.set_script(car_script)
	
	# Set up collision shape for car body
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.8, 0.35, 1.6)  # Slightly taller for bigger wheels
	collision_shape.shape = box_shape
	collision_shape.position.y = 0.3  # Higher to accommodate larger wheels
	player_car.add_child(collision_shape)
	
	# Create wheels FIRST before visual
	_create_vehicle_wheels()
	
	# Add car visual AFTER wheels
	var car_visual = Node3D.new()
	car_visual.name = "CarVisual"
	var visual_script = load("res://scripts/CarVisual.gd")
	car_visual.set_script(visual_script)
	car_visual.position.y = -0.05  # Small offset for visual alignment
	player_car.add_child(car_visual)
	
	# Initialize car visual
	if car_visual.has_method("create_car_body"):
		car_visual.create_car_body()
	
	# Position car at track spawn point
	await get_tree().process_frame  # Wait for track to be ready
	
	if looped_track and looped_track.has_method("get_spawn_position"):
		var spawn_pos = looped_track.get_spawn_position()
		player_car.global_position = spawn_pos
		print("Spawning car at: ", spawn_pos)
		
		if looped_track.has_method("get_spawn_rotation"):
			player_car.rotation.y = looped_track.get_spawn_rotation()
	else:
		player_car.position = Vector3(0, 5.0, 0)
		print("No track spawn, using default position")
	
	# Give initial forward velocity after a frame
	await get_tree().physics_frame
	# Get forward direction from car rotation
	var forward = -player_car.global_transform.basis.z
	player_car.linear_velocity = forward * 5.0 + Vector3(0, -1.0, 0)  # Forward with slight downward
	
	print("VehicleBody3D car created at position: ", player_car.position)

func _create_vehicle_wheels() -> void:
	# Wheel configuration
	var wheel_radius = 0.25  # Bigger wheels for rough terrain
	var wheel_width = 0.15
	var wheel_rest_length = 0.3  # Longer rest length for more suspension travel
	var suspension_travel = 0.4  # Much more travel for rough terrain and gaps
	
	# Wheel positions - at "bottomed out" position (docs say position them here!)
	# Moving wheels down more to ensure ground contact
	var wheel_data = [
		{"name": "FrontLeft", "pos": Vector3(-0.4, 0.1, 0.6), "steer": true, "traction": true},
		{"name": "FrontRight", "pos": Vector3(0.4, 0.1, 0.6), "steer": true, "traction": true},
		{"name": "RearLeft", "pos": Vector3(-0.4, 0.1, -0.6), "steer": false, "traction": true},
		{"name": "RearRight", "pos": Vector3(0.4, 0.1, -0.6), "steer": false, "traction": true}
	]
	
	for wheel_info in wheel_data:
		# Create VehicleWheel3D node
		var wheel = VehicleWheel3D.new()
		wheel.name = wheel_info.name
		wheel.position = wheel_info.pos
		
		# Configure wheel physics
		wheel.wheel_radius = wheel_radius
		wheel.wheel_rest_length = wheel_rest_length
		wheel.suspension_travel = suspension_travel
		wheel.suspension_stiffness = 45.0  # Slightly stiffer to reduce bouncing
		wheel.suspension_max_force = 6000.0  # Higher to handle impacts
		wheel.damping_compression = 0.9  # More compression damping
		wheel.damping_relaxation = 0.8  # More relaxation damping
		wheel.wheel_friction_slip = 2.5  # More grip for uneven surfaces
		
		# Set steering and traction
		wheel.use_as_steering = wheel_info.steer
		wheel.use_as_traction = wheel_info.traction
		
		player_car.add_child(wheel)
		
		# Add visual wheel mesh
		var wheel_mesh = MeshInstance3D.new()
		var cylinder = CylinderMesh.new()
		cylinder.height = wheel_width
		cylinder.top_radius = wheel_radius
		cylinder.bottom_radius = wheel_radius
		cylinder.radial_segments = 16
		wheel_mesh.mesh = cylinder
		wheel_mesh.rotation.z = PI / 2  # Rotate to be a wheel
		
		# Wheel material
		var wheel_material = StandardMaterial3D.new()
		wheel_material.albedo_color = Color(0.1, 0.1, 0.1)
		wheel_mesh.material_override = wheel_material
		
		wheel.add_child(wheel_mesh)
		
		print("Created wheel: ", wheel.name, " at ", wheel.position)

func _setup_camera() -> void:
	# Create camera controller
	camera_controller = Node3D.new()
	camera_controller.name = "CameraController"
	var camera_script = load("res://scripts/CameraController.gd")
	camera_controller.set_script(camera_script)
	add_child(camera_controller)
	
	# Camera will create its own Camera3D child
	if camera_controller.has_method("set_target"):
		camera_controller.call_deferred("set_target", player_car)

func _setup_track() -> void:
	# Create smooth looped track
	looped_track = Node3D.new()
	looped_track.name = "SmoothLoopTrack"
	var track_script = load("res://scripts/SmoothLoopTrack.gd")
	looped_track.set_script(track_script)
	add_child(looped_track)
	
	# Set player reference
	if looped_track.has_method("set_player"):
		looped_track.call_deferred("set_player", player_car)

func _setup_lighting() -> void:
	# Set up environment
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	
	# Apply to camera when ready
	await get_tree().process_frame
	if camera_controller and camera_controller.has_node("Camera3D"):
		var camera = camera_controller.get_node("Camera3D")
		if camera:
			camera.environment = env

func _setup_debug_ui() -> void:
	# Create UI layer
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "UILayer"
	add_child(canvas_layer)
	
	# Create debug UI
	var debug_ui = Control.new()
	debug_ui.name = "DebugUI"
	var debug_script = load("res://scripts/DebugUI.gd")
	debug_ui.set_script(debug_script)
	canvas_layer.add_child(debug_ui)

func _setup_pause_manager() -> void:
	# Create pause manager
	var pause_manager = Node.new()
	pause_manager.name = "PauseManager"
	var pause_script = load("res://scripts/PauseManager.gd")
	pause_manager.set_script(pause_script)
	add_child(pause_manager)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	elif event.is_action_pressed("reset"):
		# Reset car to track spawn
		if looped_track and looped_track.has_method("get_spawn_position"):
			if player_car:
				player_car.global_position = looped_track.get_spawn_position()
				if looped_track.has_method("get_spawn_rotation"):
					player_car.rotation.y = looped_track.get_spawn_rotation()
				player_car.linear_velocity = Vector3.ZERO
				player_car.angular_velocity = Vector3.ZERO
		
		# Reset car using its own method
		if player_car and player_car.has_method("reset_to_spawn"):
			player_car.reset_to_spawn()
		
		# Reset camera
		if camera_controller and camera_controller.has_method("reset_camera"):
			camera_controller.reset_camera()