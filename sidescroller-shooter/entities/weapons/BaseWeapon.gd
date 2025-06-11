extends Node2D
class_name BaseWeapon

signal ammo_changed(current_ammo: int, max_ammo: int)
signal weapon_fired
signal reload_started
signal reload_finished

@export var weapon_name: String = "Base Weapon"
@export var damage: int = 10
@export var fire_rate: float = 0.3
@export var max_ammo: int = 30
@export var reload_time: float = 2.0
@export var projectile_speed: float = 800.0
@export var spread_angle: float = 0.0
@export var range_distance: float = 1000.0
@export var auto_fire: bool = false
@export var projectile_color: Color = Color.WHITE

var current_ammo: int
var can_fire: bool = true
var is_reloading: bool = false
var last_fire_time: float = 0.0

@onready var fire_point: Marker2D = $FirePoint
@onready var fire_timer: Timer = $FireTimer
@onready var reload_timer: Timer = $ReloadTimer

var projectile_scene: PackedScene

func _ready():
	current_ammo = max_ammo
	ammo_changed.emit(current_ammo, max_ammo)
	
	fire_timer.wait_time = fire_rate
	fire_timer.one_shot = true
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	
	reload_timer.wait_time = reload_time
	reload_timer.one_shot = true
	reload_timer.timeout.connect(_on_reload_timer_timeout)
	
	load_projectile_scene()

func load_projectile_scene():
	projectile_scene = load("res://entities/projectiles/Projectile.tscn")

func can_shoot() -> bool:
	return can_fire and current_ammo > 0 and not is_reloading

func fire(target_position: Vector2, shooter: Actor) -> bool:
	if not can_shoot():
		return false
	
	create_projectile(target_position, shooter)
	current_ammo -= 1
	ammo_changed.emit(current_ammo, max_ammo)
	
	can_fire = false
	fire_timer.start()
	weapon_fired.emit()
	
	if current_ammo <= 0:
		start_reload()
	
	return true

func create_projectile(target_position: Vector2, shooter: Actor):
	if not projectile_scene or not fire_point:
		return
	
	var projectile = projectile_scene.instantiate()
	
	projectile.global_position = fire_point.global_position
	
	var direction = (target_position - fire_point.global_position).normalized()
	
	if spread_angle > 0:
		var spread_rad = deg_to_rad(spread_angle)
		var random_spread = randf_range(-spread_rad, spread_rad)
		direction = direction.rotated(random_spread)
	
	get_tree().current_scene.add_child(projectile)
	projectile.setup(direction, projectile_speed, damage, range_distance, shooter, projectile_color)
	
	# Create muzzle flash
	if has_node("/root/ParticleManager"):
		get_node("/root/ParticleManager").create_muzzle_flash(fire_point.global_position, direction, projectile_color)

func start_reload():
	if is_reloading or current_ammo >= max_ammo:
		return
	
	is_reloading = true
	reload_started.emit()
	reload_timer.start()

func _on_fire_timer_timeout():
	can_fire = true

func _on_reload_timer_timeout():
	current_ammo = max_ammo
	is_reloading = false
	ammo_changed.emit(current_ammo, max_ammo)
	reload_finished.emit()

func get_weapon_info() -> Dictionary:
	return {
		"name": weapon_name,
		"damage": damage,
		"fire_rate": fire_rate,
		"current_ammo": current_ammo,
		"max_ammo": max_ammo,
		"auto_fire": auto_fire
	}
