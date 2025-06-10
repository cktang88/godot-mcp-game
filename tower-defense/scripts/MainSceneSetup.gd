extends Node2D

func _ready() -> void:
	# Add Camera2D if it doesn't exist
	if not has_node("Camera2D"):
		var camera = Camera2D.new()
		camera.name = "Camera2D"
		camera.enabled = true
		camera.make_current()
		
		# Add the camera controller script
		camera.set_script(preload("res://scripts/CameraController.gd"))
		
		add_child(camera)
	
	# Add MapBackground if it doesn't exist
	if not has_node("MapBackground"):
		var map_bg = Node2D.new()
		map_bg.name = "MapBackground"
		map_bg.z_index = -10
		map_bg.set_script(preload("res://scripts/MapBackground.gd"))
		add_child(map_bg)
		move_child(map_bg, 0)  # Move to back
	
	# Update the path if PathGenerator script exists
	var enemy_path = get_node_or_null("EnemyPath")
	if enemy_path and ResourceLoader.exists("res://scripts/PathGenerator.gd"):
		enemy_path.set_script(preload("res://scripts/PathGenerator.gd"))
	
	# Add ParticleManager to the Main scene instead of root
	if not has_node("ParticleManager"):
		var particle_manager = ParticleManager.new()
		particle_manager.name = "ParticleManager"
		add_child(particle_manager)
