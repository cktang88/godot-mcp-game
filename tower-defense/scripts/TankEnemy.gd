extends BaseEnemy

class_name TankEnemy

func _ready() -> void:
	# Tank enemy - high health, slow speed, high reward
	max_health = 150
	speed = 50.0
	reward = 25
	damage_to_base = 3
	enemy_scale = 1.5
	
	# Call parent ready
	super._ready()
