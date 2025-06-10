extends BaseEnemy

class_name BasicEnemy

# Scene-based enemy with predefined visuals
@onready var character_body = $CharacterBody2D
@onready var health_bar_visual = $CharacterBody2D/HealthBar
@onready var health_bar_bg = $CharacterBody2D/HealthBarBG

func _ready() -> void:
	# Basic enemy stats
	max_health = 50
	speed = 100.0
	reward = 10
	damage_to_base = 1
	enemy_color = Color.WHITE
	enemy_scale = 1.0
	
	# Initialize health
	health = max_health
	progress_ratio = 0.0
	
	# Use the existing CharacterBody2D from the scene
	body = character_body
	if body and not body.is_in_group("enemies"):
		body.add_to_group("enemies")
	
	# Update the polygon color to white for basic enemy
	var polygon = body.get_node_or_null("EnemyVisual")
	if polygon:
		polygon.color = enemy_color
	
	# Don't call super._ready() to avoid creating duplicate visuals
	_update_health_bar_visual()

func _setup_health_bar():
	# Override to prevent creating a new health bar since we use scene-based ones
	pass

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

func _update_health_bar_visual():
	if health_bar_visual:
		var health_percentage = float(health) / float(max_health)
		health_bar_visual.size.x = 60 * health_percentage
		
		# Change color based on health
		if health_percentage > 0.6:
			health_bar_visual.color = Color(0, 1, 0)  # Green
		elif health_percentage > 0.3:
			health_bar_visual.color = Color(1, 1, 0)  # Yellow
		else:
			health_bar_visual.color = Color(1, 0, 0)  # Red

func take_damage(damage: int) -> void:
	super.take_damage(damage)
	_update_health_bar_visual()

func get_path_progress() -> float:
	return progress
