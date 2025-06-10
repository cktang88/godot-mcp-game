extends RigidBody2D

@export var size = 3
var rotation_speed: float

func _ready():
	gravity_scale = 0
	rotation_speed = randf_range(-5.0, 5.0)
	angular_velocity = rotation_speed
	add_to_group("asteroids")
	
	var velocity = Vector2(randf_range(-200, 200), randf_range(-200, 200))
	linear_velocity = velocity
	
	update_size()

func destroy():
	get_tree().call_group("game_manager", "_on_asteroid_destroyed", size)
	if size > 1:
		spawn_smaller_asteroids()
	queue_free()

func spawn_smaller_asteroids():
	var asteroid_scene = preload("res://scenes/Asteroid.tscn")
	var spawn_position = global_position
	
	for i in range(2):
		var smaller_asteroid = asteroid_scene.instantiate()
		get_tree().current_scene.add_child(smaller_asteroid)
		
		smaller_asteroid.size = size - 1
		smaller_asteroid.global_position = spawn_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		
		var spread_velocity = Vector2(randf_range(-300, 300), randf_range(-300, 300))
		smaller_asteroid.linear_velocity = spread_velocity
		
		smaller_asteroid.update_size()

func update_size():
	match size:
		3:
			scale = Vector2(1.0, 1.0)
		2:
			scale = Vector2(0.6, 0.6)
		1:
			scale = Vector2(0.3, 0.3)

func wrap_around_screen():
	var screen_size = get_viewport().get_visible_rect().size
	var half_size = 60 * scale.x
	
	if global_position.x < -half_size:
		global_position.x = screen_size.x + half_size
	elif global_position.x > screen_size.x + half_size:
		global_position.x = -half_size
	
	if global_position.y < -half_size:
		global_position.y = screen_size.y + half_size
	elif global_position.y > screen_size.y + half_size:
		global_position.y = -half_size

func _integrate_forces(state):
	wrap_around_screen()
