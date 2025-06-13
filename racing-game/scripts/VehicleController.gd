extends VehicleBody3D

# Control settings
@export var max_engine_force: float = 80.0  # Very low to prevent wheelies
@export var max_brake_force: float = 100.0
@export var max_steer_angle: float = 0.4  # radians (~23 degrees)
@export var drift_friction: float = 0.5
@export var normal_friction: float = 3.0  # Match wheel settings
@export var anti_wheelie_factor: float = 0.5  # Reduces power when front lifts

# State
var spawn_position: Vector3 = Vector3(0, 8.0, 0)  # Higher default for elevated track
var spawn_rotation: Vector3 = Vector3.ZERO

signal speed_changed(speed_kph: float)

func _ready() -> void:
	add_to_group("player")
	
	# Configure vehicle
	mass = 1500.0  # Much heavier to prevent flipping
	center_of_mass = Vector3(0, -0.3, 0.4)  # Very low and forward for stability
	
	# Reduce jitter with physics settings
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = 1.0
	physics_material_override.bounce = 0.0
	
	# Enable continuous collision detection for smoother movement
	continuous_cd = true
	linear_damp = 0.1  # Small amount of damping to reduce jitter
	angular_damp = 1.0  # More angular damping for stability
	
	# Store spawn position (will be updated from track if available)
	spawn_position = global_position
	spawn_rotation = global_rotation
	
	print("VehicleBody3D initialized with mass: ", mass)
	
	# Find and configure wheels
	for child in get_children():
		if child is VehicleWheel3D:
			# Set proper wheel physics based on Godot docs
			child.suspension_stiffness = 45.0  # Match Main.gd settings
			child.suspension_max_force = 6000.0  # Higher to handle impacts
			child.damping_compression = 0.9
			child.damping_relaxation = 0.8
			child.wheel_friction_slip = 2.5  # More grip for uneven surfaces
			print("Configured wheel: ", child.name, " at position: ", child.position, " traction: ", child.use_as_traction, " steering: ", child.use_as_steering)
	
	# Debug check after a moment
	await get_tree().create_timer(1.0).timeout
	print("=== Wheel Status Check ===")
	for child in get_children():
		if child is VehicleWheel3D:
			print("Wheel ", child.name, " is in contact: ", child.is_in_contact(), " traction: ", child.use_as_traction)

func _physics_process(delta: float) -> void:
	# Get input using Godot's recommended input axes
	var steer_input = Input.get_axis("steer_right", "steer_left")
	var throttle_input = Input.get_axis("brake", "accelerate")
	var handbrake = Input.get_action_strength("handbrake")
	
	# Apply steering
	steering = steer_input * max_steer_angle
	
	# Apply throttle/brake
	if throttle_input > 0:
		# Check if front wheels are lifting (anti-wheelie)
		var front_wheels_contact = 0
		var rear_wheels_contact = 0
		for child in get_children():
			if child is VehicleWheel3D:
				if child.is_in_contact():
					if "Front" in child.name:
						front_wheels_contact += 1
					elif "Rear" in child.name:
						rear_wheels_contact += 1
		
		# Reduce power if front wheels are lifting
		var power_multiplier = 1.0
		if front_wheels_contact < 2 and rear_wheels_contact >= 2:
			power_multiplier = anti_wheelie_factor
			if randf() < 0.2:
				print("Anti-wheelie active! Reducing power.")
		
		engine_force = throttle_input * max_engine_force * power_multiplier
		brake = 0.0
		
		if randf() < 0.1:  # Debug print occasionally
			print("Engine force: ", engine_force, " Speed: ", linear_velocity.length(), " Front contact: ", front_wheels_contact)
	elif throttle_input < 0:
		# S key for reverse
		engine_force = throttle_input * max_engine_force * 0.7  # 70% power in reverse
		brake = 0.0
	else:
		engine_force = 0.0
		brake = 0.0
	
	# Apply handbrake
	if handbrake > 0:
		brake = handbrake * max_brake_force * 0.7
		# Reduce rear wheel friction for drifting
		for child in get_children():
			if child is VehicleWheel3D and child.name.contains("Rear"):
				child.wheel_friction_slip = drift_friction
	else:
		# Restore normal friction
		for child in get_children():
			if child is VehicleWheel3D and child.name.contains("Rear"):
				child.wheel_friction_slip = normal_friction
	
	# Emit speed signal
	var speed_kph = linear_velocity.length() * 3.6
	emit_signal("speed_changed", speed_kph)
	
	# Check for flip
	if transform.basis.y.dot(Vector3.UP) < 0.3:
		await get_tree().create_timer(2.0).timeout
		if transform.basis.y.dot(Vector3.UP) < 0.3:
			reset_to_spawn()
	
	# Reset on key press
	if Input.is_action_just_pressed("reset"):
		reset_to_spawn()

func reset_to_spawn() -> void:
	print("Resetting vehicle to spawn position")
	
	# Reset physics state
	set_physics_process(false)
	
	# Reset transform
	global_transform.origin = spawn_position
	global_transform.basis = Basis()
	global_rotation = spawn_rotation
	
	# Clear velocities
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	# Clear controls
	engine_force = 0.0
	brake = 0.0
	steering = 0.0
	
	# Give initial push forward
	var forward = -global_transform.basis.z
	linear_velocity = forward * 5.0
	
	# Re-enable physics
	set_physics_process(true)

func get_speed_kph() -> float:
	return linear_velocity.length() * 3.6

func get_speed_normalized() -> float:
	return clamp(linear_velocity.length() / 30.0, 0.0, 1.0)
