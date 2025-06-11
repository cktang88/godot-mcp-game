extends Control
class_name UIController

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/HealthLabel
@onready var weapon_panel: Panel = $WeaponPanel
@onready var ammo_label: Label = $WeaponPanel/AmmoLabel
@onready var weapon_label: Label = $WeaponPanel/WeaponLabel
@onready var reload_label: Label = $WeaponPanel/ReloadLabel
@onready var reload_progress_bar: ProgressBar = $WeaponPanel/ReloadProgressBar
@onready var score_label: Label = $ScoreLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var game_over_label: Label = $GameOverPanel/GameOverLabel
@onready var restart_button: Button = $GameOverPanel/RestartButton

var player: Player
var game_manager: GameManager
var reload_timer: Timer
var current_connected_weapon: BaseWeapon

func _ready():
	game_over_panel.visible = false
	restart_button.pressed.connect(_on_restart_button_pressed)
	
	reload_timer = Timer.new()
	add_child(reload_timer)
	reload_timer.timeout.connect(_update_reload_progress)

func initialize(game_player: Player, manager: GameManager):
	player = game_player
	game_manager = manager
	
	player.health_changed.connect(_on_player_health_changed)
	player.weapon_changed.connect(_on_weapon_changed)
	
	game_manager.score_changed.connect(_on_score_changed)
	game_manager.game_over.connect(_on_game_over)

func _on_player_health_changed(current_health: int, max_health: int):
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	
	if health_label:
		health_label.text = "%d/%d" % [current_health, max_health]

func _on_weapon_changed(weapon_info: Dictionary):
	if weapon_label:
		weapon_label.text = weapon_info.name
	
	# Disconnect from previous weapon if exists
	if current_connected_weapon and is_instance_valid(current_connected_weapon):
		if current_connected_weapon.ammo_changed.is_connected(_on_ammo_changed):
			current_connected_weapon.ammo_changed.disconnect(_on_ammo_changed)
		if current_connected_weapon.reload_started.is_connected(_on_reload_started):
			current_connected_weapon.reload_started.disconnect(_on_reload_started)
		if current_connected_weapon.reload_finished.is_connected(_on_reload_finished):
			current_connected_weapon.reload_finished.disconnect(_on_reload_finished)
	
	# Connect to new weapon
	if player.current_weapon:
		current_connected_weapon = player.current_weapon
		current_connected_weapon.ammo_changed.connect(_on_ammo_changed)
		current_connected_weapon.reload_started.connect(_on_reload_started)
		current_connected_weapon.reload_finished.connect(_on_reload_finished)
		_on_ammo_changed(weapon_info.current_ammo, weapon_info.max_ammo)

func _on_ammo_changed(current_ammo: int, max_ammo: int):
	if ammo_label:
		ammo_label.text = "Ammo: %d/%d" % [current_ammo, max_ammo]

func _on_score_changed(new_score: int):
	if score_label:
		score_label.text = "Score: %d" % new_score

func _on_game_over():
	game_over_panel.visible = true
	
	if game_over_label and game_manager:
		game_over_label.text = "Game Over!\nFinal Score: %d" % game_manager.get_current_score()

func _on_restart_button_pressed():
	get_tree().reload_current_scene()

func _on_reload_started():
	if reload_label and reload_progress_bar and player.current_weapon:
		reload_label.text = "Reloading..."
		reload_progress_bar.visible = true
		reload_progress_bar.value = 0.0
		reload_progress_bar.max_value = player.current_weapon.reload_time
		
		reload_timer.wait_time = 0.05
		reload_timer.start()

func _on_reload_finished():
	if reload_label and reload_progress_bar:
		reload_label.text = ""
		reload_progress_bar.visible = false
		reload_timer.stop()

func _update_reload_progress():
	if reload_progress_bar.visible and player.current_weapon:
		reload_progress_bar.value += reload_timer.wait_time
		if reload_progress_bar.value >= reload_progress_bar.max_value:
			reload_timer.stop()