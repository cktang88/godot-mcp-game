extends Actor
class_name Player

signal weapon_changed(weapon_info: Dictionary)

var available_weapons: Array[PackedScene] = []
var current_weapon_index: int = 0
var current_weapon: BaseWeapon
var is_shooting: bool = false

@onready var weapon_mount: Node2D = $WeaponMount
@onready var camera: Camera2D = $Camera2D

func _ready():
	super._ready()
	setup_weapons()
	setup_camera()

func _input(event):
	if is_dead:
		return
		
	if event.is_action_pressed("jump"):
		jump()
	elif event.is_action_pressed("weapon_switch_next"):
		switch_weapon(1)
	elif event.is_action_pressed("weapon_switch_prev"):
		switch_weapon(-1)
	elif event.is_action_pressed("reload"):
		reload_weapon()
	elif event.is_action_pressed("shoot"):
		is_shooting = true
	elif event.is_action_released("shoot"):
		is_shooting = false

func _physics_process(delta):
	super._physics_process(delta)
	
	if is_dead:
		return
		
	handle_aiming()
	handle_shooting()

func setup_weapons():
	available_weapons = [
		load("res://entities/weapons/Pistol.tscn"),
		load("res://entities/weapons/AssaultRifle.tscn"),
		load("res://entities/weapons/SMG.tscn"),
		load("res://entities/weapons/MachineGun.tscn")
	]
	
	equip_weapon(0)

func setup_camera():
	if camera:
		camera.enabled = true
		camera.limit_left = -10000
		camera.limit_right = 10000
		camera.limit_top = -5000
		camera.limit_bottom = 5000

func handle_movement(delta: float):
	var input_direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_left"):
		input_direction.x -= 1
	if Input.is_action_pressed("move_right"):
		input_direction.x += 1
	
	if input_direction.x != 0:
		velocity.x = move_toward(velocity.x, input_direction.x * move_speed, acceleration * move_speed)
		set_facing_direction(input_direction.x)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * move_speed)

func handle_aiming():
	if not current_weapon:
		return
		
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - current_weapon.global_position).normalized()
	
	current_weapon.rotation = direction.angle()
	
	if direction.x < 0 and facing_direction > 0:
		set_facing_direction(-1)
	elif direction.x > 0 and facing_direction < 0:
		set_facing_direction(1)

func handle_shooting():
	if not current_weapon or not is_shooting:
		return
		
	var mouse_pos = get_global_mouse_position()
	
	if current_weapon.auto_fire:
		current_weapon.fire(mouse_pos, self)
	elif Input.is_action_just_pressed("shoot"):
		current_weapon.fire(mouse_pos, self)

func switch_weapon(direction: int):
	var new_index = (current_weapon_index + direction) % available_weapons.size()
	if new_index < 0:
		new_index = available_weapons.size() - 1
	
	equip_weapon(new_index)

func equip_weapon(weapon_index: int):
	if weapon_index < 0 or weapon_index >= available_weapons.size():
		return
		
	if current_weapon:
		current_weapon.queue_free()
	
	current_weapon_index = weapon_index
	var weapon_scene = available_weapons[weapon_index]
	current_weapon = weapon_scene.instantiate()
	weapon_mount.add_child(current_weapon)
	
	weapon_changed.emit(current_weapon.get_weapon_info())

func reload_weapon():
	if current_weapon:
		current_weapon.start_reload()

func on_death():
	is_shooting = false
	if current_weapon:
		current_weapon.visible = false
