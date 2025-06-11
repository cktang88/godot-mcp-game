extends Node

static var instance: Node

func _ready():
	instance = self

func create_muzzle_flash(position: Vector2, direction: Vector2, color: Color = Color.WHITE):
	var particles = CPUParticles2D.new()
	get_tree().current_scene.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	particles.amount = 10
	particles.lifetime = 0.15
	particles.one_shot = true
	particles.speed_scale = 2.0
	particles.gravity = Vector2(0, 0)

	
	# Create a simple texture
	var image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture = ImageTexture.create_from_image(image)
	particles.texture = texture
	
	# Visual properties
	particles.direction = direction
	particles.spread = 40.0
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	particles.angular_velocity_min = -180.0
	particles.angular_velocity_max = 180.0
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.0
	
	# Color gradient
	var gradient = Gradient.new()
	gradient.add_point(0.0, color)
	gradient.add_point(0.5, Color(color.r, color.g, color.b, 0.5))
	gradient.add_point(1.0, Color(color.r, color.g, color.b, 0.0))
	particles.color_ramp = gradient
	
	# Auto cleanup
	var timer = Timer.new()
	particles.add_child(timer)
	timer.wait_time = particles.lifetime * 2
	timer.one_shot = true
	timer.timeout.connect(particles.queue_free)
	timer.start()

func create_blood_splatter(position: Vector2, direction: Vector2):
	var particles = CPUParticles2D.new()
	get_tree().current_scene.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	particles.amount = 12
	particles.lifetime = 0.4
	particles.one_shot = true
	
	# Create a simple texture
	var image = Image.create(6, 6, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture = ImageTexture.create_from_image(image)
	particles.texture = texture
	
	# Visual properties
	particles.direction = -direction  # Opposite of impact direction
	particles.spread = 45.0
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 150.0
	particles.angular_velocity_min = -360.0
	particles.angular_velocity_max = 360.0
	particles.scale_amount_min = 0.3
	particles.scale_amount_max = 0.8
	particles.gravity = Vector2(0, 300)
	particles.damping_min = 10.0
	particles.damping_max = 50.0
	
	# Blood color gradient
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.8, 0.1, 0.1, 1.0))
	gradient.add_point(0.3, Color(0.6, 0.0, 0.0, 0.8))
	gradient.add_point(1.0, Color(0.4, 0.0, 0.0, 0.0))
	particles.color_ramp = gradient
	
	# Auto cleanup
	var timer = Timer.new()
	particles.add_child(timer)
	timer.wait_time = particles.lifetime * 2
	timer.one_shot = true
	timer.timeout.connect(particles.queue_free)
	timer.start()

func create_hit_sparks(position: Vector2, direction: Vector2):
	var particles = CPUParticles2D.new()
	get_tree().current_scene.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	particles.amount = 8
	particles.lifetime = 0.2
	particles.one_shot = true
	
	# Create a simple texture
	var image = Image.create(3, 3, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture = ImageTexture.create_from_image(image)
	particles.texture = texture
	
	# Visual properties
	particles.direction = -direction
	particles.spread = 30.0
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 250.0
	particles.scale_amount_min = 0.2
	particles.scale_amount_max = 0.5
	particles.gravity = Vector2(0, 200)
	
	# Spark color gradient
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 1.0, 0.8, 1.0))
	gradient.add_point(0.2, Color(1.0, 0.8, 0.4, 1.0))
	gradient.add_point(1.0, Color(0.8, 0.4, 0.2, 0.0))
	particles.color_ramp = gradient
	
	# Auto cleanup
	var timer = Timer.new()
	particles.add_child(timer)
	timer.wait_time = particles.lifetime * 2
	timer.one_shot = true
	timer.timeout.connect(particles.queue_free)
	timer.start()
