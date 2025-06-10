extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: int = 10
var speed: float = 400.0
var source_tower: BaseTower = null

func _ready():
	# Connect hit detection
	body_entered.connect(_on_body_entered)
	
	# Auto-destroy after 5 seconds to prevent memory leaks
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _physics_process(delta):
	position += velocity * delta

func initialize(direction: Vector2, projectile_damage: int, projectile_speed: float, tower: BaseTower = null):
	velocity = direction * projectile_speed
	damage = projectile_damage
	speed = projectile_speed
	source_tower = tower
	
	# Rotate to face direction
	rotation = direction.angle()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		# Deal damage to enemy - enemy is CharacterBody2D, parent is PathFollow2D
		var enemy_pathfollow = body.get_parent()
		if enemy_pathfollow and enemy_pathfollow.has_method("take_damage"):
			var enemy_health_before = enemy_pathfollow.health
			enemy_pathfollow.take_damage(damage)
			
			# Track damage and kills for source tower
			if source_tower:
				source_tower.record_damage(damage)
				if enemy_pathfollow.health <= 0 and enemy_health_before > 0:
					source_tower.record_kill()
		
		# Destroy projectile
		queue_free()
