extends BaseEnemy

class_name FastEnemy

func _ready() -> void:
	# Fast enemy - low health, high speed, low reward
	max_health = 30
	speed = 150.0
	reward = 5
	damage_to_base = 1
	enemy_color = Color(0.7, 1.0, 0.7)  # Light green
	enemy_scale = 0.8
	
	super._ready()