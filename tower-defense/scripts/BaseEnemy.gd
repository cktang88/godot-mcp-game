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

# Scene references
@onready var character_body = $CharacterBody2D
@onready var health_bar_visual = $CharacterBody2D/HealthBar
@onready var health_bar_bg = $CharacterBody2D/HealthBarBG
@onready var enemy_visual = $CharacterBody2D/EnemyVisual

func _ready() -> void:
	health = max_health
	progress_ratio = 0.0
	
	# Use the existing CharacterBody2D from the scene
	body = character_body
	
	# Ensure the body is in the enemies group
	if body and not body.is_in_group("enemies"):
		body.add_to_group("enemies")
	
	# Setup visuals based on enemy type
	_setup_visuals()
	_update_health_bar_visual()

func _setup_visuals() -> void:
	# Update visual properties - can be overridden by subclasses
	if enemy_visual:
		# Scale the polygon
		if enemy_scale != 1.0:
			var scaled_polygon = PackedVector2Array()
			for point in enemy_visual.polygon:
				scaled_polygon.append(point * enemy_scale)
			enemy_visual.polygon = scaled_polygon
	
	# Scale health bars
	if health_bar_visual and health_bar_bg:
		var bar_width = 60 * enemy_scale
		health_bar_visual.size.x = bar_width
		health_bar_bg.size.x = bar_width
		health_bar_visual.position.x = -bar_width / 2
		health_bar_bg.position.x = -bar_width / 2
		health_bar_visual.position.y = -35 * enemy_scale
		health_bar_bg.position.y = -35 * enemy_scale

func _update_health_bar_visual():
	if health_bar_visual:
		var health_percentage = float(health) / float(max_health)
		health_bar_visual.size.x = health_bar_bg.size.x * health_percentage
		
		# Change color based on health
		if health_percentage > 0.6:
			health_bar_visual.color = Color(0, 1, 0)  # Green
		elif health_percentage > 0.3:
			health_bar_visual.color = Color(1, 1, 0)  # Yellow
		else:
			health_bar_visual.color = Color(1, 0, 0)  # Red

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
		
	# Move along the path
	progress += speed * delta
	
	# Update body position to match PathFollow2D
	if body and is_instance_valid(body) and body.is_inside_tree():
		body.global_position = global_position
	
	# Check if reached the end
	if progress_ratio >= 1.0:
		enemy_reached_end.emit()
		queue_free()

func take_damage(damage: int) -> void:
	health -= damage
	
	# Spawn blood particle effect
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		var particle_manager = main.get_node_or_null("ParticleManager")
		if particle_manager and ParticleManager.instance:
			ParticleManager.instance.spawn_blood_effect(global_position)
	
	# Update health bar
	_update_health_bar_visual()
	
	if health <= 0:
		enemy_killed.emit(reward)
		queue_free()

func get_current_health() -> int:
	return health

func get_max_health() -> int:
	return max_health

func get_path_progress() -> float:
	return progress