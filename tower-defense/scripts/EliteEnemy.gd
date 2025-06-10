extends BaseEnemy

class_name EliteEnemy

func _ready() -> void:
	# Elite enemy - balanced stats, higher everything
	max_health = 100
	speed = 80.0
	reward = 20
	damage_to_base = 2
	enemy_color = Color(1.0, 0.5, 0.5)  # Light red
	enemy_scale = 1.2
	
	super._ready()