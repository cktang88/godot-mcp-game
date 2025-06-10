extends Node

class_name ParticleManager

# Singleton instance
static var instance: ParticleManager

# Particle pools
var blood_particles_pool: Array[GPUParticles2D] = []
var muzzle_flash_pool: Array[GPUParticles2D] = []

const POOL_SIZE = 20

func _init():
	if instance == null:
		instance = self

func _ready():
	# Initialize particle pools
	_create_blood_particles_pool()
	_create_muzzle_flash_pool()

func _create_blood_particles_pool():
	for i in range(POOL_SIZE):
		var particles = _create_blood_particles()
		particles.emitting = false
		add_child(particles)
		blood_particles_pool.append(particles)

func _create_muzzle_flash_pool():
	for i in range(POOL_SIZE):
		var particles = _create_muzzle_flash_particles()
		particles.emitting = false
		add_child(particles)
		muzzle_flash_pool.append(particles)

func _create_blood_particles() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 15
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.emitting = false
	particles.local_coords = true
	
	# Create process material
	var process_material = ParticleProcessMaterial.new()
	
	# Emission shape
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process_material.emission_sphere_radius = 5.0
	
	# Initial velocity
	process_material.initial_velocity_min = 100.0
	process_material.initial_velocity_max = 300.0
	process_material.direction = Vector3(0, -1, 0)
	process_material.spread = 45.0
	
	# Gravity
	process_material.gravity = Vector3(0, 500, 0)
	
	# Scale
	process_material.scale_min = 0.5
	process_material.scale_max = 1.5
	process_material.scale_curve = create_scale_curve()
	
	# Color
	process_material.color = Color(0.8, 0.1, 0.1, 1.0)
	process_material.color_initial_ramp = create_color_ramp()
	
	# Angular velocity
	process_material.angular_velocity_min = -180.0
	process_material.angular_velocity_max = 180.0
	
	# Damping
	process_material.damping_min = 10.0
	process_material.damping_max = 30.0
	
	particles.process_material = process_material
	
	# Create texture
	particles.texture = create_blood_texture()
	
	return particles

func _create_muzzle_flash_particles() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 8
	particles.lifetime = 0.1
	particles.one_shot = true
	particles.emitting = false
	particles.local_coords = true
	
	# Create process material
	var process_material = ParticleProcessMaterial.new()
	
	# Emission shape
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	
	# Initial velocity
	process_material.initial_velocity_min = 50.0
	process_material.initial_velocity_max = 150.0
	process_material.direction = Vector3(1, 0, 0)  # Will be rotated based on tower direction
	process_material.spread = 15.0
	
	# Scale
	process_material.scale_min = 0.8
	process_material.scale_max = 1.2
	process_material.scale_curve = create_flash_scale_curve()
	
	# Color with transparency fade
	process_material.color = Color(1.0, 0.9, 0.6, 1.0)
	process_material.color_initial_ramp = create_flash_color_ramp()
	
	particles.process_material = process_material
	
	# Create texture
	particles.texture = create_muzzle_flash_texture()
	
	return particles

func spawn_blood_effect(position: Vector2):
	for particles in blood_particles_pool:
		if not particles.emitting:
			particles.global_position = position
			particles.restart()
			particles.emitting = true
			break

func spawn_muzzle_flash(position: Vector2, direction: Vector2):
	for particles in muzzle_flash_pool:
		if not particles.emitting:
			particles.global_position = position
			# Rotate the emission direction
			var angle = direction.angle()
			var process_mat = particles.process_material as ParticleProcessMaterial
			process_mat.direction = Vector3(direction.x, direction.y, 0).normalized()
			particles.restart()
			particles.emitting = true
			break

func create_scale_curve() -> Curve:
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.5, 0.8))
	curve.add_point(Vector2(1.0, 0.0))
	return curve

func create_flash_scale_curve() -> Curve:
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.1, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	return curve

func create_color_ramp() -> Gradient:
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.8, 0.1, 0.1, 1.0))
	gradient.add_point(0.7, Color(0.4, 0.05, 0.05, 0.8))
	gradient.add_point(1.0, Color(0.2, 0.02, 0.02, 0.0))
	return gradient

func create_flash_color_ramp() -> Gradient:
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 1.0, 0.8, 1.0))
	gradient.add_point(0.3, Color(1.0, 0.8, 0.4, 0.8))
	gradient.add_point(1.0, Color(1.0, 0.6, 0.2, 0.0))
	return gradient

func create_blood_texture() -> ImageTexture:
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	
	# Create a simple circle
	for x in range(8):
		for y in range(8):
			var dist = Vector2(x - 3.5, y - 3.5).length()
			if dist <= 3.5:
				var alpha = 1.0 - (dist / 3.5) * 0.3
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	return ImageTexture.create_from_image(image)

func create_muzzle_flash_texture() -> ImageTexture:
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	
	# Create a star-like flash
	var center = Vector2(8, 8)
	for x in range(16):
		for y in range(16):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			# Create rays
			var angle = pos.angle_to_point(center)
			var ray_intensity = abs(sin(angle * 4)) * 0.5 + 0.5
			
			if dist <= 8:
				var alpha = (1.0 - dist / 8) * ray_intensity
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	return ImageTexture.create_from_image(image)
