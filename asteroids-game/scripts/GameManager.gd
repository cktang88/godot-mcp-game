extends Node2D

@export var asteroid_scene: PackedScene
@export var initial_asteroid_count = 5
@export var spawn_timer = 10.0

var score = 0
var asteroids_remaining = 0
var player_node
var health_ui
var game_over_ui

func _ready():
	add_to_group("game_manager")
	player_node = $Player
	health_ui = $UI/HealthUI
	game_over_ui = $UI/GameOverUI
	
	if player_node:
		player_node.health_changed.connect(_on_player_health_changed)
		player_node.player_died.connect(_on_player_died)
	
	spawn_initial_asteroids()

func spawn_initial_asteroids():
	for i in range(initial_asteroid_count):
		spawn_asteroid()

func spawn_asteroid():
	if asteroid_scene:
		var asteroid = asteroid_scene.instantiate()
		add_child(asteroid)
		
		var screen_size = get_viewport().get_visible_rect().size
		var spawn_position = Vector2()
		
		match randi() % 4:
			0:
				spawn_position = Vector2(randf() * screen_size.x, -50)
			1:
				spawn_position = Vector2(screen_size.x + 50, randf() * screen_size.y)
			2:
				spawn_position = Vector2(randf() * screen_size.x, screen_size.y + 50)
			3:
				spawn_position = Vector2(-50, randf() * screen_size.y)
		
		asteroid.global_position = spawn_position
		asteroids_remaining += 1

func _on_asteroid_destroyed(asteroid_size: int):
	asteroids_remaining -= 1
	
	match asteroid_size:
		3:
			score += 20
		2:
			score += 50
		1:
			score += 100
	
	if health_ui:
		health_ui.update_score(score)
	
	if asteroids_remaining <= 0:
		get_tree().create_timer(2.0).timeout.connect(spawn_new_wave)

func spawn_new_wave():
	initial_asteroid_count += 1
	spawn_initial_asteroids()

func _on_player_health_changed(new_health: int):
	if health_ui:
		health_ui.update_health(new_health)

func _on_player_died():
	if game_over_ui:
		game_over_ui.show_game_over(score)
