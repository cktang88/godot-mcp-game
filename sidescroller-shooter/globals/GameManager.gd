extends Node
class_name GameManager

signal game_over
signal score_changed(new_score: int)
signal enemy_spawned(enemy: Enemy)

@export var enemy_spawn_interval: float = 5.0
@export var max_enemies: int = 10
@export var spawn_distance_from_player: float = 800.0

var current_score: int = 0
var current_enemies: Array[Enemy] = []
var player: Player
var is_game_over: bool = false

@onready var enemy_spawn_timer: Timer = $EnemySpawnTimer

var enemy_scene: PackedScene

func _ready():
	enemy_scene = preload("res://entities/enemies/Enemy.tscn")
	
	enemy_spawn_timer.wait_time = enemy_spawn_interval
	enemy_spawn_timer.timeout.connect(spawn_enemy)
	enemy_spawn_timer.start()

func initialize_game(game_player: Player):
	player = game_player
	player.died.connect(_on_player_died)
	is_game_over = false
	current_score = 0
	score_changed.emit(current_score)

func spawn_enemy():
	if is_game_over or current_enemies.size() >= max_enemies or not player:
		return
	
	var enemy = enemy_scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	
	var spawn_side = randi() % 2
	var spawn_x: float
	
	if spawn_side == 0:
		spawn_x = player.global_position.x - spawn_distance_from_player
	else:
		spawn_x = player.global_position.x + spawn_distance_from_player
	
	enemy.global_position = Vector2(spawn_x, player.global_position.y - 50)
	
	enemy.died.connect(_on_enemy_died.bind(enemy))
	current_enemies.append(enemy)
	enemy_spawned.emit(enemy)

func _on_enemy_died(enemy: Enemy):
	if enemy in current_enemies:
		current_enemies.erase(enemy)
		add_score(100)

func _on_player_died():
	is_game_over = true
	enemy_spawn_timer.stop()
	game_over.emit()

func add_score(points: int):
	current_score += points
	score_changed.emit(current_score)

func restart_game():
	is_game_over = false
	current_score = 0
	current_enemies.clear()
	score_changed.emit(current_score)
	enemy_spawn_timer.start()

func get_current_score() -> int:
	return current_score

func get_enemy_count() -> int:
	return current_enemies.size()