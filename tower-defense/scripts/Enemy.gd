extends BaseEnemy

class_name BasicEnemy

func _ready() -> void:
	# Basic enemy stats
	max_health = 50
	speed = 100.0
	reward = 10
	damage_to_base = 1
	enemy_scale = 1.0
	
	# Call parent ready
	super._ready()

func get_path_progress() -> float:
	return progress
