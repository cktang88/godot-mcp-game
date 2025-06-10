extends PathFollow2D

# Enemy properties
@export var max_health: int = 50
@export var speed: float = 100.0
@export var reward: int = 10

# Current state
var health: int
var is_dead: bool = false

# References
@onready var character_body = $CharacterBody2D
@onready var health_bar = $CharacterBody2D/HealthBar
@onready var health_bar_bg = $CharacterBody2D/HealthBarBG

# Signals
signal enemy_reached_end()
signal enemy_killed(reward: int)

func _ready():
	health = max_health
	progress_ratio = 0.0
	_update_health_bar()
	
	# Add CharacterBody2D to enemies group for tower detection
	character_body.add_to_group("enemies")

func _physics_process(delta):
	if is_dead:
		return
	
	# Move along the path
	progress += speed * delta
	
	# Check if reached the end
	if progress_ratio >= 1.0:
		is_dead = true  # Prevent further processing
		enemy_reached_end.emit()
		queue_free()

func take_damage(damage: int):
	if is_dead:
		return
	
	health -= damage
	_update_health_bar()
	
	if health <= 0:
		_die()

func _update_health_bar():
	if health_bar:
		var health_percentage = float(health) / float(max_health)
		health_bar.size.x = 60 * health_percentage
		
		# Change color based on health
		if health_percentage > 0.6:
			health_bar.color = Color(0, 1, 0)  # Green
		elif health_percentage > 0.3:
			health_bar.color = Color(1, 1, 0)  # Yellow
		else:
			health_bar.color = Color(1, 0, 0)  # Red

func _die():
	if is_dead:  # Already processed (might have reached end)
		return
	is_dead = true
	enemy_killed.emit(reward)
	queue_free()

func get_path_progress() -> float:
	return progress
