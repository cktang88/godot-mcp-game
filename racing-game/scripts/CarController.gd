extends RigidBody3D

const MAX_STEER = 0.8
const ACCELERATION = 100.0
const MAX_SPEED = 30.0
const BRAKE_POWER = 50.0
const DRIFT_FRICTION = 0.95
const NORMAL_FRICTION = 0.98
const TURN_SPEED = 2.5
const DRIFT_TURN_MULTIPLIER = 1.5

var steer_input: float = 0.0
var throttle_input: float = 0.0
var brake_input: float = 0.0
var handbrake_input: float = 0.0
var is_drifting: bool = false
var is_grounded: bool = false

var current_speed_kph: float = 0.0

signal speed_changed(speed_kph: float)

func _ready() -> void:
	add_to_group("player")
	
	# Configure RigidBody3D for arcade car physics
	gravity_scale = 1.0  # Keep gravity for initial drop
	linear_damp = 1.0
	angular_damp = 5.0
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	freeze = false
	
	# Set collision layers
	collision_layer = 2  # Player layer
	collision_mask = 1   # Collide with world
	
	# Wait a bit then disable vertical movement
	await get_tree().create_timer(1.0).timeout
	is_grounded = true
	
	print("Car controller ready!")

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# This is called during physics processing
	if is_grounded:
		# Lock Y position once grounded
		var transform = state.transform
		transform.origin.y = max(transform.origin.y, 0.5)
		state.transform = transform
		
		# Remove vertical velocity
		var vel = state.linear_velocity
		vel.y = 0
		state.linear_velocity = vel

func _physics_process(delta: float) -> void:
	_handle_input()
	_apply_forces(delta)
	_update_speed()
	
	# Keep car level
	rotation.x = 0
	rotation.z = 0

func _handle_input() -> void:
	steer_input = Input.get_axis("steer_right", "steer_left")
	throttle_input = Input.get_action_strength("accelerate")
	brake_input = Input.get_action_strength("brake")
	handbrake_input = Input.get_action_strength("handbrake")
	
	if Input.is_action_just_pressed("reset"):
		_reset_car()

func _apply_forces(delta: float) -> void:
	# Get forward and right vectors
	var forward = -transform.basis.z
	var right = transform.basis.x
	
	# Apply acceleration/braking
	if throttle_input > 0:
		var acceleration_force = forward * ACCELERATION * throttle_input
		apply_central_force(acceleration_force)
		print("Applying force: ", acceleration_force)
	
	if brake_input > 0:
		# Brake by applying opposite force
		var brake_force = -linear_velocity.normalized() * BRAKE_POWER * brake_input
		brake_force.y = 0
		apply_central_force(brake_force)
	
	# Limit max speed
	if linear_velocity.length() > MAX_SPEED:
		linear_velocity = linear_velocity.normalized() * MAX_SPEED
	
	# Handle steering
	if abs(steer_input) > 0.1 and linear_velocity.length() > 0.5:
		# Calculate turn rate based on speed
		var speed_factor = clamp(linear_velocity.length() / MAX_SPEED, 0.1, 1.0)
		var turn_rate = steer_input * TURN_SPEED * speed_factor
		
		# Enhanced turning while drifting
		is_drifting = handbrake_input > 0.5 and linear_velocity.length() > 5.0
		if is_drifting:
			turn_rate *= DRIFT_TURN_MULTIPLIER
			# Add sideways velocity for drift
			var drift_velocity = right * steer_input * linear_velocity.length() * 0.3
			apply_central_impulse(drift_velocity * delta)
		
		# Apply rotation
		angular_velocity = Vector3(0, turn_rate, 0)
	else:
		angular_velocity = Vector3.ZERO
	
	# Apply friction
	if is_grounded:
		var friction = DRIFT_FRICTION if is_drifting else NORMAL_FRICTION
		var current_vel = linear_velocity
		current_vel.x *= friction
		current_vel.z *= friction
		linear_velocity = current_vel

func _update_speed() -> void:
	current_speed_kph = linear_velocity.length() * 3.6
	emit_signal("speed_changed", current_speed_kph)

func _reset_car() -> void:
	position = Vector3(0, 2.0, 0)
	rotation = Vector3.ZERO
	linear_velocity = Vector3(0, 0, -5.0)
	angular_velocity = Vector3.ZERO
	is_grounded = false
	
	# Re-enable grounding after a moment
	await get_tree().create_timer(1.0).timeout
	is_grounded = true
	
	print("Car reset!")

func get_speed_kph() -> float:
	return current_speed_kph

func get_speed_normalized() -> float:
	return clamp(linear_velocity.length() / MAX_SPEED, 0.0, 1.0)
