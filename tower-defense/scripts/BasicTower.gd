class_name BasicTower
extends BaseTower

func _setup_tower():
	# Basic tower properties
	damage = 15
	fire_rate = 1.0
	range = 200.0
	cost = 50
	projectile_speed = 400.0
	tower_name = "Basic Tower"
	
	# Set visual appearance
	var base = $TowerBase
	var barrel = $TowerBarrel/BarrelVisual
	if base:
		base.color = Color(0.3, 0.7, 0.3, 1)  # Green base
	if barrel:
		barrel.color = Color(0.2, 0.5, 0.2, 1)  # Darker green barrel