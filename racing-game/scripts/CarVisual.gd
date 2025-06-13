extends Node3D

func create_car_body() -> void:
	# Car dimensions (small scale for isometric view)
	var body_length = 1.2
	var body_width = 0.6
	var body_height = 0.3
	var hood_height = 0.2
	
	# Main body (lower part) - position it at the collision shape location
	var body_mesh = MeshInstance3D.new()
	body_mesh.name = "Body"
	var body_box = BoxMesh.new()
	body_box.size = Vector3(body_width, hood_height, body_length)
	body_mesh.mesh = body_box
	body_mesh.position.y = 0.3  # Adjusted for new collision shape
	
	# Create material for body
	var body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color(0.8, 0.2, 0.2)  # Red car
	body_mesh.material_override = body_material
	add_child(body_mesh)
	
	# Cabin (upper part)
	var cabin_mesh = MeshInstance3D.new()
	cabin_mesh.name = "Cabin"
	var cabin_box = BoxMesh.new()
	cabin_box.size = Vector3(body_width * 0.8, body_height - hood_height, body_length * 0.6)
	cabin_mesh.mesh = cabin_box
	cabin_mesh.position = Vector3(0, 0.3 + hood_height/2 + (body_height - hood_height)/2, -body_length * 0.1)
	
	# Create material for cabin
	var cabin_material = StandardMaterial3D.new()
	cabin_material.albedo_color = Color(0.2, 0.2, 0.3)  # Dark blue windows
	cabin_mesh.material_override = cabin_material
	add_child(cabin_mesh)
	
	# Don't create wheels here - VehicleWheel3D nodes handle the wheels
	
	# Add headlights
	var headlight_material = StandardMaterial3D.new()
	headlight_material.albedo_color = Color(1, 1, 0.8)  # Yellowish white
	headlight_material.emission_enabled = true
	headlight_material.emission = Color(1, 1, 0.8)
	headlight_material.emission_energy = 0.5
	
	for i in range(2):
		var headlight = MeshInstance3D.new()
		headlight.name = "Headlight" + str(i)
		var light_box = BoxMesh.new()
		light_box.size = Vector3(0.1, 0.05, 0.02)
		headlight.mesh = light_box
		var x_offset = 0.2 if i == 0 else -0.2
		headlight.position = Vector3(x_offset, 0.3, body_length / 2)
		headlight.material_override = headlight_material
		add_child(headlight)
	
	# Add tail lights
	var taillight_material = StandardMaterial3D.new()
	taillight_material.albedo_color = Color(1, 0, 0)  # Red
	taillight_material.emission_enabled = true
	taillight_material.emission = Color(1, 0, 0)
	taillight_material.emission_energy = 0.3
	
	for i in range(2):
		var taillight = MeshInstance3D.new()
		taillight.name = "Taillight" + str(i)
		var light_box = BoxMesh.new()
		light_box.size = Vector3(0.1, 0.05, 0.02)
		taillight.mesh = light_box
		var x_offset = 0.2 if i == 0 else -0.2
		taillight.position = Vector3(x_offset, 0.3, -body_length / 2)
		taillight.material_override = taillight_material
		add_child(taillight)
