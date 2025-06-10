extends BaseEnemy

class_name SwarmEnemy

func _ready() -> void:
	# Swarm enemy - very low health, medium speed, very low reward
	max_health = 15
	speed = 120.0
	reward = 3
	damage_to_base = 1
	enemy_scale = 0.6
	
	# Call parent ready
	super._ready()
