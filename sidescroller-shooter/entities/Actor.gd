extends CharacterBody2D
class_name Actor

signal health_changed(new_health: int, max_health: int)
signal died

@export var max_health: int = 100
@export var move_speed: float = 300.0
@export var jump_velocity: float = -550.0
@export var friction: float = 0.1
@export var acceleration: float = 0.2

var current_health: int
var gravity: float = 980.0
var facing_direction: int = 1
var is_dead: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var health_bar: HealthBarComponent = $HealthBar

func _ready():
	current_health = max_health
	health_changed.emit(current_health, max_health)
	
	if health_bar:
		health_bar.set_health(current_health, max_health)

func _physics_process(delta):
	if is_dead:
		return
		
	apply_gravity(delta)
	handle_movement(delta)
	move_and_slide()

func apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_movement(delta: float):
	pass

func jump():
	if is_on_floor() and not is_dead:
		velocity.y = jump_velocity

func take_damage(amount: int, source: Node = null):
	if is_dead:
		return
		
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	if health_bar:
		health_bar.set_health(current_health, max_health)
	
	# Create blood splatter effect
	if has_node("/root/ParticleManager"):
		if source and source.has_method("get_global_position"):
			var impact_direction = (global_position - source.get_global_position()).normalized()
			get_node("/root/ParticleManager").create_blood_splatter(global_position, impact_direction)
		else:
			get_node("/root/ParticleManager").create_blood_splatter(global_position, Vector2.UP)
	
	if current_health <= 0:
		die()

func heal(amount: int):
	if is_dead:
		return
		
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
	
	if health_bar:
		health_bar.set_health(current_health, max_health)

func die():
	if is_dead:
		return
		
	is_dead = true
	died.emit()
	on_death()

func on_death():
	pass

func set_facing_direction(direction: int):
	if direction != 0:
		facing_direction = sign(direction)
		if sprite:
			sprite.flip_h = facing_direction < 0

func get_facing_direction() -> int:
	return facing_direction