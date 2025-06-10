extends Node

# Game state
var lives: int = 20
var gold: int = 100
var current_wave: int = 0
var enemies_spawned: int = 0
var enemies_per_wave: int = 5
var wave_active: bool = false

# Enemy settings
var enemy_scene = preload("res://scenes/Enemy.tscn")
var spawn_timer: Timer

# Signals
signal lives_changed(new_lives: int)
signal gold_changed(new_gold: int)
signal wave_started(wave_number: int)
signal game_over()

func _ready():
	spawn_timer = $SpawnTimer
	spawn_timer.timeout.connect(_spawn_enemy)
	
	# Don't auto-start waves anymore - wait for player to press button

func start_wave():
	current_wave += 1
	enemies_spawned = 0
	enemies_per_wave = 5 + (current_wave - 1) * 2  # Increase enemies each wave
	wave_active = true
	
	wave_started.emit(current_wave)
	spawn_timer.start()

func _spawn_enemy():
	if enemies_spawned >= enemies_per_wave:
		spawn_timer.stop()
		wave_active = false
		return
	
	var enemy = enemy_scene.instantiate()
	var enemy_path = get_node("../EnemyPath")
	enemy_path.add_child(enemy)
	enemy.enemy_reached_end.connect(_on_enemy_reached_end)
	enemy.enemy_killed.connect(_on_enemy_killed)
	
	enemies_spawned += 1

func _on_enemy_reached_end():
	lives -= 1
	lives_changed.emit(lives)
	
	if lives <= 0:
		game_over.emit()
		spawn_timer.stop()
		get_tree().paused = true

func _on_enemy_killed(reward: int):
	gold += reward
	gold_changed.emit(gold)

func can_afford_tower(cost: int) -> bool:
	return gold >= cost

func purchase_tower(cost: int):
	if can_afford_tower(cost):
		gold -= cost
		gold_changed.emit(gold)
		return true
	return false
