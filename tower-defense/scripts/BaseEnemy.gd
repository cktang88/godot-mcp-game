extends PathFollow2D

class_name BaseEnemy

signal enemy_reached_end
signal enemy_killed(reward: int)

# Base stats - can be overridden by enemy types
@export var max_health: int = 50
@export var speed: float = 100.0
@export var reward: int = 10
@export var damage_to_base: int = 1

# Visual properties
@export var enemy_color: Color = Color.WHITE
@export var enemy_scale: float = 1.0

var health: int
var body: CharacterBody2D
var sprite: Sprite2D
var health_bar: ProgressBar

func _ready() -> void:
	health = max_health
	progress_ratio = 0.0
	
	# Create visual representation
	body = CharacterBody2D.new()
	body.add_to_group("enemies")
	add_child(body)
	
	# Setup sprite
	sprite = Sprite2D.new()
	sprite.texture = preload("res://sprites/enemy.png")
	sprite.modulate = enemy_color
	sprite.scale = Vector2(enemy_scale, enemy_scale)
	body.add_child(sprite)
	
	# Setup collision
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16 * enemy_scale
	collision_shape.shape = shape
	body.add_child(collision_shape)
	
	# Setup health bar
	_setup_health_bar()

func _setup_health_bar():
	health_bar = ProgressBar.new()
	health_bar.size = Vector2(40 * enemy_scale, 6)
	health_bar.position = Vector2(-20 * enemy_scale, -30 * enemy_scale)
	health_bar.value = 100
	health_bar.show_percentage = false
	
	# Create custom style for health bar
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.2)
	bg_style.border_width_top = 1
	bg_style.border_width_bottom = 1
	bg_style.border_width_left = 1
	bg_style.border_width_right = 1
	bg_style.border_color = Color(0, 0, 0)
	
	var fg_style = StyleBoxFlat.new()
	fg_style.bg_color = Color(0, 1, 0)
	
	health_bar.add_theme_stylebox_override("background", bg_style)
	health_bar.add_theme_stylebox_override("fill", fg_style)
	
	body.add_child(health_bar)

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
		
	# Move along the path
	progress += speed * delta
	
	# Update body position to match PathFollow2D
	if body:
		body.global_position = global_position
	
	# Check if reached the end
	if progress_ratio >= 1.0:
		enemy_reached_end.emit()
		queue_free()

func take_damage(damage: int) -> void:
	health -= damage
	
	# Spawn blood particle effect
	var particle_manager = get_node_or_null("/root/ParticleManager")
	if not particle_manager and get_tree().root.has_node("Main"):
		# Create particle manager if it doesn't exist
		particle_manager = ParticleManager.new()
		particle_manager.name = "ParticleManager"
		get_tree().root.add_child(particle_manager)
	
	if particle_manager and ParticleManager.instance:
		ParticleManager.instance.spawn_blood_effect(global_position)
	
	# Update health bar
	if health_bar:
		var health_percentage = float(health) / float(max_health) * 100
		health_bar.value = health_percentage
		
		# Change color based on health
		var fg_style = health_bar.get_theme_stylebox("fill")
		if fg_style is StyleBoxFlat:
			if health_percentage > 50:
				fg_style.bg_color = Color(0, 1, 0)
			elif health_percentage > 25:
				fg_style.bg_color = Color(1, 1, 0)
			else:
				fg_style.bg_color = Color(1, 0, 0)
	
	if health <= 0:
		enemy_killed.emit(reward)
		queue_free()

func get_current_health() -> int:
	return health

func get_max_health() -> int:
	return max_health