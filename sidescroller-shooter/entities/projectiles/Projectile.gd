extends Area2D
class_name Projectile

# These will be overridden by setup(), so defaults don't matter much
@export var damage: int = 10
@export var speed: float = 800.0
@export var max_range: float = 1000.0

# Runtime variables - reset for each projectile
var direction: Vector2
var shooter: Actor
var start_position: Vector2
var lifetime: float = 0.0

@onready var color_rect: ColorRect = $ColorRect
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta):
	# Only move if we have a valid direction
	if direction == Vector2.ZERO:
		return
		
	# Move the projectile
	var movement = direction * speed * delta
	global_position += movement
	
	# Track lifetime and destroy if traveled too far
	lifetime += delta
	var max_lifetime = max_range / speed # time = distance / speed
	
	if lifetime >= max_lifetime:
		destroy()

func setup(dir: Vector2, proj_speed: float, proj_damage: int, range_distance: float, source: Actor, color: Color = Color.WHITE):
	# Fresh setup for this projectile instance
	direction = dir.normalized()
	speed = proj_speed
	damage = proj_damage
	max_range = range_distance
	shooter = source
	start_position = global_position
	lifetime = 0.0 # Reset lifetime
	
	rotation = direction.angle()
	
	# Set the projectile color
	if color_rect:
		color_rect.color = color

func _on_body_entered(body):
	# Don't hit the shooter
	if body == shooter:
		return
	
	# Check if we should damage this target
	if body is Actor:
		# Don't let enemy bullets hit other enemies
		if shooter is Enemy and body is Enemy:
			return
			
		body.take_damage(damage, self)
		destroy()
	elif body.has_method("take_damage"):
		body.take_damage(damage, self)
		destroy()
	else:
		# Hit environment/walls - create sparks
		if has_node("/root/ParticleManager"):
			get_node("/root/ParticleManager").create_hit_sparks(global_position, direction)
		destroy()

func _on_area_entered(area):
	# Ignore areas that belong to actors (like detection areas)
	if area.get_parent() is Actor:
		return
		
	# Ignore projectile-to-projectile collisions
	if area is Projectile:
		return

func destroy():
	queue_free()
