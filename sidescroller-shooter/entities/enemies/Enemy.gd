extends Actor
class_name Enemy

enum AIState {
	PATROL,
	CHASE,
	ATTACK,
	RETREAT
}

@export var patrol_distance: float = 200.0
@export var detection_range: float = 300.0
@export var attack_range: float = 150.0
@export var retreat_health_threshold: float = 0.3
@export var ai_react_time: float = 0.5

var ai_state: AIState = AIState.PATROL
var target: Player
var patrol_start_position: Vector2
var patrol_direction: int = 1
var last_known_target_position: Vector2
var ai_timer: float = 0.0
var current_weapon: BaseWeapon

@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var weapon_mount: Node2D = $WeaponMount
@onready var sight_ray: RayCast2D = $SightRay

func _ready():
	super._ready()
	patrol_start_position = global_position
	setup_ai_areas()
	setup_weapon()
	
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

func _physics_process(delta):
	super._physics_process(delta)
	
	if is_dead:
		return
		
	ai_timer += delta
	update_ai_state()
	execute_ai_behavior(delta)

func setup_ai_areas():
	if detection_area:
		var detection_shape = CircleShape2D.new()
		detection_shape.radius = detection_range
		var detection_collision = CollisionShape2D.new()
		detection_collision.shape = detection_shape
		detection_area.add_child(detection_collision)
	
	if attack_area:
		var attack_shape = CircleShape2D.new()
		attack_shape.radius = attack_range
		var attack_collision = CollisionShape2D.new()
		attack_collision.shape = attack_shape
		attack_area.add_child(attack_collision)

func setup_weapon():
	var weapon_scenes = [
		load("res://entities/weapons/Pistol.tscn"),
		load("res://entities/weapons/AssaultRifle.tscn"),
		load("res://entities/weapons/SMG.tscn")
	]
	
	var weapon_scene = weapon_scenes[randi() % weapon_scenes.size()]
	current_weapon = weapon_scene.instantiate()
	weapon_mount.add_child(current_weapon)

func update_ai_state():
	if not target:
		ai_state = AIState.PATROL
		return
	
	var distance_to_target = global_position.distance_to(target.global_position)
	var health_ratio = float(current_health) / float(max_health)
	
	if health_ratio <= retreat_health_threshold:
		ai_state = AIState.RETREAT
	elif distance_to_target <= attack_range and can_see_target():
		ai_state = AIState.ATTACK
	elif distance_to_target <= detection_range:
		ai_state = AIState.CHASE
	else:
		ai_state = AIState.PATROL

func execute_ai_behavior(delta: float):
	match ai_state:
		AIState.PATROL:
			patrol_behavior(delta)
		AIState.CHASE:
			chase_behavior(delta)
		AIState.ATTACK:
			attack_behavior(delta)
		AIState.RETREAT:
			retreat_behavior(delta)

func patrol_behavior(delta: float):
	var target_position = patrol_start_position + Vector2(patrol_direction * patrol_distance, 0)
	var distance_to_patrol_point = global_position.distance_to(target_position)
	
	if distance_to_patrol_point < 50.0:
		patrol_direction *= -1
	
	move_towards_position(target_position)

func chase_behavior(delta: float):
	if target:
		last_known_target_position = target.global_position
		move_towards_position(target.global_position)

func attack_behavior(delta: float):
	if target and current_weapon:
		var direction_to_target = (target.global_position - global_position).normalized()
		set_facing_direction(direction_to_target.x)
		
		if can_see_target():
			current_weapon.fire(target.global_position, self)

func retreat_behavior(delta: float):
	if target:
		var retreat_direction = (global_position - target.global_position).normalized()
		var retreat_position = global_position + retreat_direction * 200.0
		move_towards_position(retreat_position)

func move_towards_position(target_position: Vector2):
	var direction = (target_position - global_position).normalized()
	velocity.x = direction.x * move_speed * 0.7
	set_facing_direction(direction.x)

func can_see_target() -> bool:
	if not target or not sight_ray:
		return false
	
	sight_ray.target_position = to_local(target.global_position)
	sight_ray.force_raycast_update()
	
	if sight_ray.is_colliding():
		var collider = sight_ray.get_collider()
		return collider == target
	
	return true

func _on_detection_area_body_entered(body):
	if body is Player:
		target = body

func _on_detection_area_body_exited(body):
	if body == target:
		target = null

func on_death():
	if current_weapon:
		current_weapon.visible = false
	
	collision.set_deferred("disabled", true)
	
	var death_timer = Timer.new()
	add_child(death_timer)
	death_timer.wait_time = 2.0
	death_timer.one_shot = true
	death_timer.timeout.connect(queue_free)
	death_timer.start()
