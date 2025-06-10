class_name SniperTower
extends BaseTower

func _setup_tower():
	# Sniper tower properties - high damage, slow fire rate, long range
	damage = 50
	fire_rate = 0.5  # One shot every 2 seconds
	range = 350.0
	cost = 150
	projectile_speed = 800.0
	tower_name = "Sniper Tower"
	
	# Set visual appearance
	var base = $TowerBase
	var barrel = $TowerBarrel/BarrelVisual
	if base:
		base.color = Color(0.2, 0.2, 0.8, 1)  # Blue base
	if barrel:
		barrel.color = Color(0.1, 0.1, 0.5, 1)  # Darker blue barrel
		# Sniper has a longer, thinner barrel
		barrel.polygon = PackedVector2Array([Vector2(-3, -8), Vector2(3, -8), Vector2(3, -39), Vector2(-3, -39)])

func _create_projectile():
	# Sniper creates larger, more visible projectiles
	var projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)
	
	# Spawn projectile from barrel tip
	var barrel = $TowerBarrel
	if barrel:
		# Use the barrel's up direction (-Y in local space) to find the tip
		var barrel_tip_pos = barrel.global_position + barrel.transform.y * -39  # Longer barrel
		projectile.global_position = barrel_tip_pos
	else:
		projectile.global_position = global_position
	
	# Make sniper projectiles larger and different color
	var proj_visual = projectile.get_node("ProjectileVisual")
	if proj_visual:
		proj_visual.scale = Vector2(1.5, 1.5)
		proj_visual.color = Color(0.2, 0.2, 1.0, 1)  # Blue projectile
	
	# Calculate direction to target
	var direction = (current_target.global_position - global_position).normalized()
	projectile.initialize(direction, damage, projectile_speed, self)