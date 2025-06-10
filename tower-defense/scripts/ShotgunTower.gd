class_name ShotgunTower
extends BaseTower

func _setup_tower():
	# Shotgun tower properties - medium damage, close range, multiple projectiles
	damage = 12
	fire_rate = 1.2
	range = 150.0
	cost = 100
	projectile_speed = 350.0
	tower_name = "Shotgun Tower"
	
	# Set visual appearance
	var base = $TowerBase
	var barrel = $TowerBarrel/BarrelVisual
	if base:
		base.color = Color(0.8, 0.2, 0.8, 1)  # Purple base
	if barrel:
		barrel.color = Color(0.5, 0.1, 0.5, 1)  # Darker purple barrel
		# Shotgun has a wider barrel
		barrel.polygon = PackedVector2Array([Vector2(-7, -8), Vector2(7, -8), Vector2(7, -24), Vector2(-7, -24)])

func _create_projectile():
	if not current_target or not is_instance_valid(current_target):
		return
	
	# Shotgun fires 3 projectiles in a spread
	var base_direction = (current_target.global_position - global_position).normalized()
	var spread_angles = [-0.3, 0.0, 0.3]  # 3 projectiles with spread
	
	for angle_offset in spread_angles:
		var projectile = projectile_scene.instantiate()
		get_tree().root.add_child(projectile)
		
		# Spawn projectile from barrel tip
		var barrel = $TowerBarrel
		if barrel:
			# Use the barrel's up direction (-Y in local space) to find the tip
			var barrel_tip_pos = barrel.global_position + barrel.transform.y * -24
			projectile.global_position = barrel_tip_pos
		else:
			projectile.global_position = global_position
		
		# Apply spread to direction
		var spread_direction = base_direction.rotated(angle_offset)
		
		# Make shotgun projectiles orange
		var proj_visual = projectile.get_node("ProjectileVisual")
		if proj_visual:
			proj_visual.color = Color(1.0, 0.5, 0.0, 1)  # Orange projectile
		
		projectile.initialize(spread_direction, damage, projectile_speed, self)