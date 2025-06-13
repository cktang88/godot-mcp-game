extends Node3D

# Track parameters
@export var track_width: float = 8.0
@export var track_length: float = 200.0  # Total length of the loop
@export var track_radius: float = 50.0   # Base radius of the loop
@export var curve_variation: float = 15.0  # How much the track varies from perfect circle
@export var height_variation: float = 8.0  # Hills and valleys
@export var banking_angle: float = 15.0   # Banking on curves (degrees)
@export var track_segments: int = 100     # How many segments to create the smooth track

# Visual settings
@export var asphalt_color: Color = Color(0.2, 0.2, 0.2)
@export var side_strip_color: Color = Color(1.0, 1.0, 0.0)
@export var center_line_color: Color = Color(1.0, 1.0, 1.0)

# References
var player: Node3D
var track_points: Array = []  # Array of Vector3
var track_mesh: MeshInstance3D
var collision_body: StaticBody3D

func _ready() -> void:
	print("LoopedTrack: Starting track generation...")
	_generate_track_points()
	print("LoopedTrack: Generated ", track_points.size(), " track points")
	_create_track_mesh()
	print("LoopedTrack: Created track mesh")
	_create_collision()
	print("LoopedTrack: Created collision")
	_create_barriers()
	_create_track_decorations()
	print("LoopedTrack: Track generation complete!")
	
	# Add a simple box collision at spawn as backup
	_create_spawn_platform()

func set_player(new_player: Node3D) -> void:
	player = new_player

func _generate_track_points() -> void:
	track_points.clear()
	
	# Generate a smooth looped track using sine waves for variation
	for i in range(track_segments + 1):  # +1 to close the loop
		var t = float(i) / float(track_segments) * TAU  # 0 to 2*PI
		
		# Base circle with variations
		var radius = track_radius + sin(t * 3) * curve_variation + cos(t * 2) * curve_variation * 0.5
		
		# Position on the track
		var x = cos(t) * radius
		var z = sin(t) * radius
		
		# Height variation for hills - add base height to keep track above ground
		var y = 5.0 + sin(t * 2) * height_variation + cos(t * 3) * height_variation * 0.3
		
		track_points.append(Vector3(x, y, z))

func _create_track_mesh() -> void:
	# Create mesh instance
	track_mesh = MeshInstance3D.new()
	track_mesh.name = "TrackMesh"
	add_child(track_mesh)
	
	# Create the mesh
	var array_mesh = ArrayMesh.new()
	var arrays = Array()
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var colors = PackedColorArray()
	
	# Generate mesh for each segment
	for i in range(track_segments):
		var p1 = track_points[i]
		var p2 = track_points[(i + 1) % track_segments]
		
		# Calculate track direction and perpendicular
		var forward = (p2 - p1).normalized()
		var up = Vector3.UP
		var right = forward.cross(up).normalized()
		
		# Banking on curves
		var next_idx = (i + 2) % track_segments
		var p3 = track_points[next_idx]
		var curve_dir = (p3 - p1).normalized()
		var curve_amount = forward.cross(curve_dir).length()
		var bank_angle = curve_amount * deg_to_rad(banking_angle)
		
		# Rotate right vector for banking
		right = right.rotated(forward, bank_angle)
		up = right.cross(forward).normalized()
		
		# Create quad vertices (two triangles)
		var half_width = track_width * 0.5
		
		# Current segment vertices
		var v1 = p1 - right * half_width
		var v2 = p1 + right * half_width
		var v3 = p2 - right * half_width
		var v4 = p2 + right * half_width
		
		# Add vertices for two triangles - reversed winding order for upward-facing normals
		vertices.append_array([v1, v3, v2, v2, v3, v4])
		
		# Normals
		for j in range(6):
			normals.append(up)
		
		# UVs
		var u1 = float(i) / float(track_segments)
		var u2 = float(i + 1) / float(track_segments)
		uvs.append_array([
			Vector2(0, u1), Vector2(1, u1), Vector2(0, u2),
			Vector2(1, u1), Vector2(1, u2), Vector2(0, u2)
		])
		
		# Colors for lane markings
		for j in range(6):
			colors.append(asphalt_color)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	
	# Create mesh surface
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	track_mesh.mesh = array_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.9
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Double-sided
	track_mesh.material_override = material
	
	# Add lane markings as separate mesh
	_create_lane_markings()

func _create_lane_markings() -> void:
	# Create center line
	var center_line = MeshInstance3D.new()
	center_line.name = "CenterLine"
	add_child(center_line)
	
	var line_mesh = ArrayMesh.new()
	var arrays = Array()
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var colors = PackedColorArray()
	
	# Generate dashed center line
	var dash_length = 4.0
	var gap_length = 4.0
	var total_length = dash_length + gap_length
	var line_width = 0.15
	
	for i in range(track_segments):
		var p1 = track_points[i]
		var p2 = track_points[(i + 1) % track_segments]
		
		# Calculate segment length
		var segment_length = p1.distance_to(p2)
		var segments_in_dash = int(segment_length / total_length)
		
		var forward = (p2 - p1).normalized()
		var up = Vector3.UP
		var right = forward.cross(up).normalized()
		
		# Create dashes
		for j in range(segments_in_dash):
			var start_t = float(j) * total_length / segment_length
			var end_t = min(start_t + dash_length / segment_length, 1.0)
			
			if start_t < 1.0:
				var start_pos = p1.lerp(p2, start_t) + Vector3(0, 0.01, 0)  # Slightly above road
				var end_pos = p1.lerp(p2, end_t) + Vector3(0, 0.01, 0)
				
				# Create dash quad
				var v1 = start_pos - right * line_width * 0.5
				var v2 = start_pos + right * line_width * 0.5
				var v3 = end_pos - right * line_width * 0.5
				var v4 = end_pos + right * line_width * 0.5
				
				vertices.append_array([v1, v2, v3, v2, v4, v3])
				
				for k in range(6):
					normals.append(Vector3.UP)
					colors.append(center_line_color)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	
	if vertices.size() > 0:
		line_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		center_line.mesh = line_mesh
		
		var line_material = StandardMaterial3D.new()
		line_material.vertex_color_use_as_albedo = true
		line_material.emission_enabled = true
		line_material.emission = center_line_color
		line_material.emission_energy = 0.2
		center_line.material_override = line_material

func _create_collision() -> void:
	# Create static body for track
	collision_body = StaticBody3D.new()
	collision_body.name = "TrackCollision"
	add_child(collision_body)
	
	# Create trimesh collision shape directly from the mesh
	if track_mesh and track_mesh.mesh:
		track_mesh.create_trimesh_collision()
		
		# Find the created static body and reparent it
		for child in track_mesh.get_children():
			if child is StaticBody3D:
				track_mesh.remove_child(child)
				add_child(child)
				collision_body = child
				collision_body.name = "TrackCollision"
				break

func _create_barriers() -> void:
	# Create barriers along the track edges
	var barrier_height = 0.8
	var barrier_width = 0.3
	
	for side in [-1, 1]:  # Left and right sides
		var barrier_mesh = MeshInstance3D.new()
		barrier_mesh.name = "Barrier" + ("Left" if side < 0 else "Right")
		add_child(barrier_mesh)
		
		var array_mesh = ArrayMesh.new()
		var arrays = Array()
		arrays.resize(Mesh.ARRAY_MAX)
		
		var vertices = PackedVector3Array()
		var normals = PackedVector3Array()
		var colors = PackedColorArray()
		
		# Create barrier segments
		for i in range(track_segments):
			var p1 = track_points[i]
			var p2 = track_points[(i + 1) % track_segments]
			
			var forward = (p2 - p1).normalized()
			var right = forward.cross(Vector3.UP).normalized()
			
			# Offset to track edge
			var edge_offset = right * (track_width * 0.5 + barrier_width * 0.5) * side
			
			# Barrier vertices
			var base1 = p1 + edge_offset
			var base2 = p2 + edge_offset
			var top1 = base1 + Vector3(0, barrier_height, 0)
			var top2 = base2 + Vector3(0, barrier_height, 0)
			
			# Create barrier quad
			vertices.append_array([base1, top1, base2, top1, top2, base2])
			
			# Normals pointing inward
			var normal = -right * side
			for j in range(6):
				normals.append(normal)
				colors.append(Color(1.0, 0.4, 0.0) if side < 0 else Color(0.0, 0.4, 1.0))
		
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = colors
		
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		barrier_mesh.mesh = array_mesh
		
		# Material for barriers
		var barrier_material = StandardMaterial3D.new()
		barrier_material.vertex_color_use_as_albedo = true
		barrier_material.roughness = 0.7
		barrier_mesh.material_override = barrier_material
		
		# Add collision for barriers
		_create_barrier_collision(barrier_mesh, "Barrier" + ("Left" if side < 0 else "Right"))

func _create_barrier_collision(mesh_instance: MeshInstance3D, barrier_name: String) -> void:
	var barrier_body = StaticBody3D.new()
	barrier_body.name = barrier_name + "Collision"
	mesh_instance.add_child(barrier_body)
	
	if mesh_instance.mesh:
		var shape = ConcavePolygonShape3D.new()
		var vertices = PackedVector3Array()
		
		for surface in range(mesh_instance.mesh.get_surface_count()):
			var arrays = mesh_instance.mesh.surface_get_arrays(surface)
			if arrays.size() > Mesh.ARRAY_VERTEX:
				vertices.append_array(arrays[Mesh.ARRAY_VERTEX])
		
		shape.set_faces(vertices)
		
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = shape
		barrier_body.add_child(collision_shape)

func _create_track_decorations() -> void:
	# Add some visual elements like distance markers
	var marker_interval = 10  # Every 10 segments
	
	for i in range(0, track_segments, marker_interval):
		var marker = MeshInstance3D.new()
		marker.name = "Marker" + str(i)
		add_child(marker)
		
		# Create simple box marker
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(0.5, 2.0, 0.5)
		marker.mesh = box_mesh
		
		# Position marker
		var p = track_points[i]
		var next_p = track_points[(i + 1) % track_segments]
		var forward = (next_p - p).normalized()
		var right = forward.cross(Vector3.UP).normalized()
		
		marker.position = p + right * (track_width * 0.6) + Vector3(0, 1, 0)
		
		# Material
		var marker_material = StandardMaterial3D.new()
		marker_material.albedo_color = Color(1, 1, 1)
		marker_material.emission_enabled = true
		marker_material.emission = Color(1, 1, 1)
		marker_material.emission_energy = 0.3
		marker.material_override = marker_material

func get_spawn_position() -> Vector3:
	if track_points.size() > 0:
		# Spawn 3 units above the first track point
		return track_points[0] + Vector3(0, 3, 0)
	return Vector3(0, 8, 0)  # Default higher since track is at y=5

func get_spawn_rotation() -> float:
	if track_points.size() > 1:
		var forward = (track_points[1] - track_points[0]).normalized()
		return atan2(forward.x, forward.z)
	return 0.0

func _create_spawn_platform() -> void:
	# Create a solid platform at spawn point to ensure car doesn't fall through
	if track_points.size() == 0:
		return
		
	var platform_body = StaticBody3D.new()
	platform_body.name = "SpawnPlatform"
	add_child(platform_body)
	
	var platform_collision = CollisionShape3D.new()
	var platform_shape = BoxShape3D.new()
	platform_shape.size = Vector3(track_width * 2, 0.5, 20)  # Wide platform
	platform_collision.shape = platform_shape
	platform_collision.position = track_points[0] + Vector3(0, -0.25, 0)
	platform_body.add_child(platform_collision)
	
	# Visual platform
	var platform_mesh = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(track_width * 2, 0.5, 20)
	platform_mesh.mesh = box_mesh
	platform_mesh.position = track_points[0] + Vector3(0, -0.25, 0)
	
	var platform_material = StandardMaterial3D.new()
	platform_material.albedo_color = Color(0.3, 0.3, 0.3)
	platform_mesh.material_override = platform_material
	add_child(platform_mesh)
	
	print("Created spawn platform at: ", track_points[0])