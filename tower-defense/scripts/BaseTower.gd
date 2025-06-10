class_name BaseTower
extends Area2D

# Tower properties - can be overridden by subclasses
@export var damage: int = 10
@export var fire_rate: float = 1.0
@export var range: float = 200.0
@export var cost: int = 50
@export var projectile_speed: float = 400.0
@export var tower_name: String = "Basic Tower"

# Stats tracking
var enemies_killed: int = 0
var total_damage_dealt: int = 0
var shots_fired: int = 0
var sell_value: int = 0

# Click detection
signal tower_clicked(tower: BaseTower)

# References
var projectile_scene = preload("res://scenes/Projectile.tscn")
var shoot_timer: Timer
var current_target: Node2D = null
var enemies_in_range: Array = []

func _ready():
	# Add to towers group for collision detection
	add_to_group("towers")
	
	# Set collision mask to detect layer 1 (enemies)
	collision_mask = 1
	
	shoot_timer = $ShootTimer
	shoot_timer.timeout.connect(_shoot)
	
	# Connect area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	input_event.connect(_on_tower_clicked)
	
	# Initialize tower-specific setup
	_setup_tower()
	
	# Configure timer and collision after tower setup
	_update_tower_configuration()
	
	# Calculate sell value (75% of cost)
	sell_value = int(cost * 0.75)

# Virtual method for subclasses to override
func _setup_tower():
	pass

func _update_tower_configuration():
	# Update timer with correct fire rate
	shoot_timer.wait_time = 1.0 / fire_rate
	
	# Set detection range
	var range_collision = $RangeCollision
	if range_collision.shape is CircleShape2D:
		range_collision.shape.radius = range

func _process(_delta):
	if current_target and is_instance_valid(current_target):
		# Rotate barrel toward target
		var barrel = $TowerBarrel
		if barrel:
			barrel.look_at(current_target.global_position)
			# Offset by 90 degrees because barrel points up, but look_at assumes pointing right
			barrel.rotation += PI / 2
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

# Virtual method for subclasses to override shooting behavior
func _shoot():
	if not current_target or not is_instance_valid(current_target):
		return
	
	shots_fired += 1
	_create_projectile()
	_spawn_muzzle_flash()

# Virtual method for subclasses to override projectile creation
func _create_projectile():
	var projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)
	
	# Spawn projectile from barrel tip
	var barrel = $TowerBarrel
	if barrel:
		# Use the barrel's up direction (-Y in local space) to find the tip
		var barrel_tip_pos = barrel.global_position + barrel.transform.y * -30
		projectile.global_position = barrel_tip_pos
	else:
		projectile.global_position = global_position
	
	# Calculate direction to target
	var direction = (current_target.global_position - global_position).normalized()
	projectile.initialize(direction, damage, projectile_speed, self)

func _spawn_muzzle_flash():
	# Get particle manager from Main scene
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		var particle_manager = main.get_node_or_null("ParticleManager")
		if particle_manager and ParticleManager.instance:
			var barrel = $TowerBarrel
			var flash_position: Vector2
			var flash_direction: Vector2
			
			if barrel:
				# Use the barrel's up direction for muzzle flash position
				flash_position = barrel.global_position + barrel.transform.y * -30
				flash_direction = -barrel.transform.y  # Barrel points up, so negative Y is forward
			else:
				flash_position = global_position
				flash_direction = (current_target.global_position - global_position).normalized()
			
			ParticleManager.instance.spawn_muzzle_flash(flash_position, flash_direction)

func _on_tower_clicked(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Only respond to clicks on the click collision shape (index 1), not the range collision (index 0)
		if shape_idx == 1:  # ClickCollision is the second shape
			tower_clicked.emit(self)

func record_damage(damage_amount: int):
	total_damage_dealt += damage_amount

func record_kill():
	enemies_killed += 1

func set_range_indicator_visible(visible: bool):
	var range_indicator = $RangeIndicator
	range_indicator.visible = visible
	if visible:
		# Create a circle polygon for the range indicator
		var points = PackedVector2Array()
		var num_points = 32
		for i in range(num_points + 1):
			var angle = (i * PI * 2) / num_points
			var point = Vector2(cos(angle), sin(angle)) * range
			points.append(point)
		range_indicator.polygon = points
