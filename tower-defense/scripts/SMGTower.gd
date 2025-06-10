class_name SMGTower
extends BaseTower

func _setup_tower():
	# SMG tower properties - fast fire rate, low damage
	damage = 8
	fire_rate = 3.0  # 3 shots per second
	range = 180.0
	cost = 75
	projectile_speed = 500.0
	tower_name = "SMG Tower"
	
	# Set visual appearance
	var base = $TowerBase
	var barrel = $TowerBarrel/BarrelVisual
	if base:
		base.color = Color(0.9, 0.5, 0.1, 1)  # Orange base
	if barrel:
		barrel.color = Color(0.7, 0.3, 0.1, 1)  # Darker orange barrel
		# SMG has a thinner barrel
		barrel.polygon = PackedVector2Array([Vector2(-3, -8), Vector2(3, -8), Vector2(3, -27), Vector2(-3, -27)])
