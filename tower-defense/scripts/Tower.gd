extends Area2D

# Tower properties
@export var damage: int = 10
@export var fire_rate: float = 1.0
@export var range: float = 200.0
@export var cost: int = 50
@export var projectile_speed: float = 400.0

# References
var projectile_scene = preload("res://scenes/Projectile.tscn")
var shoot_timer: Timer
var current_target: Node2D = null
var enemies_in_range: Array = []

func _ready():
	# Add to towers group for collision detection
	add_to_group("towers")
	
	shoot_timer = $ShootTimer
	shoot_timer.wait_time = 1.0 / fire_rate
	shoot_timer.timeout.connect(_shoot)
	
	# Set detection range
	var collision_shape = $CollisionShape2D
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = range
	
	# Connect area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta):
	if current_target and is_instance_valid(current_target):
		# Look at target
		look_at(current_target.global_position)
	else:
		# Find new target
		_acquire_target()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		enemies_in_range.append(body)
		if not current_target:
			_acquire_target()

func _on_body_exited(body):
	if body in enemies_in_range:
		enemies_in_range.erase(body)
		if body == current_target:
			current_target = null
			_acquire_target()

func _acquire_target():
	# Target the enemy that has traveled the furthest
	current_target = null
	var furthest_progress = -1.0
	
	for enemy in enemies_in_range:
		if is_instance_valid(enemy):
			# The enemy is the CharacterBody2D, we need its parent PathFollow2D
			var path_follow = enemy.get_parent()
			if path_follow and path_follow.has_method("get_path_progress"):
				var progress = path_follow.get_path_progress()
				if progress > furthest_progress:
					furthest_progress = progress
					current_target = enemy

func _shoot():
	if not current_target or not is_instance_valid(current_target):
		return
	
	var projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)
	projectile.global_position = global_position
	
	# Calculate direction to target
	var direction = (current_target.global_position - global_position).normalized()
	projectile.initialize(direction, damage, projectile_speed)

func set_range_indicator_visible(visible: bool):
	$RangeIndicator.visible = visible
