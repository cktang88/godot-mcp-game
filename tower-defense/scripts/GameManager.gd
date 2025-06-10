extends Node

# Game state
var lives: int = 20
var gold: int = 100
var current_wave: int = 0
var enemies_spawned: int = 0
var enemies_per_wave: int = 5
var wave_active: bool = false

# Enemy scenes
var enemy_scenes = {
	"basic": preload("res://scenes/Enemy.tscn"),
	"fast": preload("res://scenes/FastEnemy.tscn"),
	"tank": preload("res://scenes/TankEnemy.tscn"),
	"swarm": preload("res://scenes/SwarmEnemy.tscn"),
	"elite": preload("res://scenes/EliteEnemy.tscn")
}

# Wave configuration
var wave_configs = []
var current_wave_config = []
var wave_enemy_index: int = 0

var spawn_timer: Timer

# Signals
signal lives_changed(new_lives: int)
signal gold_changed(new_gold: int)
signal wave_started(wave_number: int)
signal game_over()

func _ready():
	spawn_timer = $SpawnTimer
	spawn_timer.timeout.connect(_spawn_enemy)
	_initialize_wave_configs()

func _initialize_wave_configs():
	# Define enemy patterns for each wave
	wave_configs = [
		# Wave 1: Basic enemies only
		["basic", "basic", "basic", "basic", "basic"],
		
		# Wave 2: Mix of basic and fast
		["basic", "fast", "basic", "fast", "basic", "basic"],
		
		# Wave 3: Introduce swarm
		["swarm", "swarm", "basic", "swarm", "swarm", "basic", "fast"],
		
		# Wave 4: First tank
		["basic", "basic", "tank", "fast", "fast", "basic"],
		
		# Wave 5: Mixed wave
		["fast", "swarm", "swarm", "basic", "tank", "fast", "basic"],
		
		# Wave 6: Elite introduction
		["basic", "basic", "elite", "fast", "fast", "swarm", "swarm"],
		
		# Wave 7: Heavy wave
		["tank", "basic", "elite", "tank", "fast", "fast", "basic"],
		
		# Wave 8: Swarm rush
		["swarm", "swarm", "swarm", "swarm", "fast", "swarm", "swarm", "swarm"],
		
		# Wave 9: Elite squad
		["elite", "basic", "elite", "tank", "elite", "fast"],
		
		# Wave 10: Boss wave
		["tank", "tank", "elite", "elite", "tank", "elite", "tank"]
	]

func start_wave():
	current_wave += 1
	enemies_spawned = 0
	wave_enemy_index = 0
	wave_active = true
	
	# Get wave configuration, cycle through if we run out
	var wave_index = (current_wave - 1) % wave_configs.size()
	current_wave_config = wave_configs[wave_index].duplicate()
	
	# Scale up enemy count for higher waves
	var wave_multiplier = 1 + floor((current_wave - 1) / wave_configs.size())
	for i in range(wave_multiplier - 1):
		current_wave_config.append_array(wave_configs[wave_index])
	
	enemies_per_wave = current_wave_config.size()
	
	wave_started.emit(current_wave)
	spawn_timer.start()

func _spawn_enemy():
	if wave_enemy_index >= current_wave_config.size():
		spawn_timer.stop()
		wave_active = false
		return
	
	var enemy_type = current_wave_config[wave_enemy_index]
	var enemy_scene = enemy_scenes.get(enemy_type, enemy_scenes["basic"])
	
	var enemy = enemy_scene.instantiate()
	var enemy_path = get_node("../EnemyPath")
	enemy_path.add_child(enemy)
	
	enemy.enemy_reached_end.connect(_on_enemy_reached_end.bind(enemy))
	enemy.enemy_killed.connect(_on_enemy_killed)
	
	wave_enemy_index += 1
	enemies_spawned += 1

func _on_enemy_reached_end(enemy):
	var damage = enemy.damage_to_base if enemy.has_method("get_damage_to_base") else 1
	lives -= damage
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
