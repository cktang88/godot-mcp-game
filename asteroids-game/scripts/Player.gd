extends RigidBody2D

@export var thrust_power = 600.0
@export var rotation_speed = 8.0
@export var bullet_scene: PackedScene
@export var max_health = 3

var can_shoot = true
var current_health: int
var invulnerable = false
var invulnerability_time = 2.0

signal health_changed(new_health)
signal player_died

func _ready():
	gravity_scale = 0
	current_health = max_health
	health_changed.emit(current_health)
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	handle_input()

func handle_input():
	if Input.is_action_pressed("move_up"):
		var thrust_vector = Vector2(0, -thrust_power).rotated(rotation)
		apply_central_force(thrust_vector)
	
	var rotation_input = 0.0
	if Input.is_action_pressed("move_left"):
		rotation_input = -1.0
	elif Input.is_action_pressed("move_right"):
		rotation_input = 1.0
	
	angular_velocity = rotation_input * rotation_speed
	
	if Input.is_action_just_pressed("shoot") and can_shoot:
		shoot()

func shoot():
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		
		var spawn_offset = Vector2(0, -35).rotated(rotation)
		bullet.global_position = global_position + spawn_offset
		bullet.rotation = rotation
		
		var bullet_velocity = Vector2(0, -1200).rotated(rotation)
		bullet.linear_velocity = linear_velocity + bullet_velocity
		
		can_shoot = false
		get_tree().create_timer(0.2).timeout.connect(_on_shoot_cooldown)

func _on_shoot_cooldown():
	can_shoot = true

func wrap_around_screen():
	var screen_size = get_viewport().get_visible_rect().size
	var half_width = 30
	var half_height = 30
	
	if global_position.x < -half_width:
		global_position.x = screen_size.x + half_width
	elif global_position.x > screen_size.x + half_width:
		global_position.x = -half_width
	
	if global_position.y < -half_height:
		global_position.y = screen_size.y + half_height
	elif global_position.y > screen_size.y + half_height:
		global_position.y = -half_height

func _on_body_entered(body):
	if body.is_in_group("asteroids") and not invulnerable:
		take_damage(1)

func take_damage(amount: int):
	current_health -= amount
	health_changed.emit(current_health)
	
	if current_health <= 0:
		player_died.emit()
		queue_free()
	else:
		start_invulnerability()

func start_invulnerability():
	invulnerable = true
	modulate = Color(1, 1, 1, 0.5)
	get_tree().create_timer(invulnerability_time).timeout.connect(_on_invulnerability_ended)

func _on_invulnerability_ended():
	invulnerable = false
	modulate = Color(1, 1, 1, 1)

func _integrate_forces(state):
	wrap_around_screen()