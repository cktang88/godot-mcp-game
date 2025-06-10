extends RigidBody2D

@export var lifetime = 2.0

func _ready():
	gravity_scale = 0
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_expired)
	body_entered.connect(_on_body_entered)

func _on_lifetime_expired():
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("asteroids"):
		body.destroy()
		queue_free()

func wrap_around_screen():
	var screen_size = get_viewport().get_visible_rect().size
	var half_size = 10
	
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
