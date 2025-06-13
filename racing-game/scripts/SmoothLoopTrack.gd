extends Node3D

# Track parameters
@export var track_width: float = 8.0
@export var track_radius: float = 50.0   # Base radius of the loop
@export var curve_variation: float = 20.0  # How much the track varies
@export var height_variation: float = 10.0  # Hills and valleys
@export var control_points: int = 8  # Number of control points for the spline
@export var segments_per_curve: int = 20  # Smoothness of curves

# Visual settings
@export var asphalt_color: Color = Color(0.2, 0.2, 0.2)
@export var center_line_color: Color = Color(1.0, 1.0, 1.0)

# References
var player: Node3D
var track_curve: Curve3D
var track_mesh: MeshInstance3D
var collision_body: StaticBody3D

func _ready() -> void:
	print("SmoothLoopTrack: Starting track generation...")
	_generate_track_curve()
	_create_continuous_track_mesh()
	_create_track_collision()
	_create_barriers()
	print("SmoothLoopTrack: Track generation complete!")

func set_player(new_player: Node3D) -> void:
	player = new_player

func _generate_track_curve() -> void:
	# Create a smooth bezier curve for the track
	track_curve = Curve3D.new()
	
	# Generate control points in a rough circle with variations
	var points = []
	for i in range(control_points):
		var angle = float(i) / float(control_points) * TAU
		
		# Add variation to radius
		var radius = track_radius + sin(angle * 2) * curve_variation + cos(angle * 3) * curve_variation * 0.5
		
		# Position with height variation
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		var y = 5.0 + sin(angle * 1.5) * height_variation
		
		points.append(Vector3(x, y, z))
	
	# Add points to curve with smooth in/out controls
	for i in range(points.size()):
		var prev_idx = (i - 1 + points.size()) % points.size()
		var next_idx = (i + 1) % points.size()
		
		var point = points[i]
		var prev_point = points[prev_idx]
		var next_point = points[next_idx]
		
		# Calculate smooth tangents
		var in_control = (prev_point - next_point) * 0.25
		var out_control = -in_control
		
		track_curve.add_point(point, in_control, out_control)
	
	# Ensure the curve loops smoothly
	track_curve.add_point(points[0], 
		(points[points.size()-1] - points[1]) * 0.25,
		(points[1] - points[points.size()-1]) * 0.25)

func _create_continuous_track_mesh() -> void:
	# Create mesh instance
	track_mesh = MeshInstance3D.new()
	track_mesh.name = "TrackMesh"
	add_child(track_mesh)
	
	# Create arrays for mesh
	var array_mesh = ArrayMesh.new()
	var arrays = Array()
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	
	# Sample the curve to create a smooth track
	var total_points = control_points * segments_per_curve
	var curve_length = track_curve.get_baked_length()
	
	for i in range(total_points):
		var t1 = float(i) / float(total_points)
		var t2 = float((i + 1) % total_points) / float(total_points)
		
		# Get positions along the curve
		var offset1 = t1 * curve_length
		var offset2 = t2 * curve_length
		
		var pos1 = track_curve.sample_baked(offset1)
		var pos2 = track_curve.sample_baked(offset2)
		
		# Get curve directions and calculate banking
		var forward1 = (track_curve.sample_baked(offset1 + 0.1) - pos1).normalized()
		var forward2 = (track_curve.sample_baked(offset2 + 0.1) - pos2).normalized()
		
		# Calculate right vectors with banking
		var up = Vector3.UP
		var right1 = forward1.cross(up).normalized()
		var right2 = forward2.cross(up).normalized()
		
		# Add slight banking based on curve
		var curve_amount = forward1.cross(forward2).length() * 10.0
		var bank_angle = clamp(curve_amount * 0.2, -0.3, 0.3)
		right1 = right1.rotated(forward1, bank_angle)
		right2 = right2.rotated(forward2, bank_angle)
		
		# Create track vertices
		var half_width = track_width * 0.5
		var v1 = pos1 - right1 * half_width
		var v2 = pos1 + right1 * half_width
		var v3 = pos2 - right2 * half_width
		var v4 = pos2 + right2 * half_width
		
		# Add triangles with correct winding
		vertices.append_array([v1, v3, v2, v2, v3, v4])
		
		# Normals
		var normal1 = right1.cross(forward1).normalized()
		var normal2 = right2.cross(forward2).normalized()
		normals.append_array([normal1, normal1, normal1, normal2, normal2, normal2])
		
		# UVs
		var u1 = t1 * 10.0  # Repeat texture every 10 units
		var u2 = t2 * 10.0
		uvs.append_array([
			Vector2(0, u1), Vector2(0, u2), Vector2(1, u1),
			Vector2(1, u1), Vector2(0, u2), Vector2(1, u2)
		])
	
	# Create the mesh
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	track_mesh.mesh = array_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = asphalt_color
	material.roughness = 0.9
	track_mesh.material_override = material
	
	# Add center line
	_create_center_line()

func _create_center_line() -> void:
	var line_mesh_instance = MeshInstance3D.new()
	line_mesh_instance.name = "CenterLine"
	add_child(line_mesh_instance)
	
	var array_mesh = ArrayMesh.new()
	var arrays = Array()
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	
	# Create dashed center line
	var curve_length = track_curve.get_baked_length()
	var dash_length = 3.0
	var gap_length = 3.0
	var segment_length = dash_length + gap_length
	var num_dashes = int(curve_length / segment_length)
	
	for i in range(num_dashes):
		var start_offset = i * segment_length
		var end_offset = start_offset + dash_length
		
		if end_offset <= curve_length:
			# Sample multiple points for smooth dash
			for j in range(10):
				var t1 = float(j) / 10.0
				var t2 = float(j + 1) / 10.0
				
				var offset1 = start_offset + t1 * dash_length
				var offset2 = start_offset + t2 * dash_length
				
				var pos1 = track_curve.sample_baked(offset1) + Vector3(0, 0.02, 0)
				var pos2 = track_curve.sample_baked(offset2) + Vector3(0, 0.02, 0)
				
				var forward = (pos2 - pos1).normalized()
				var right = forward.cross(Vector3.UP).normalized() * 0.1
				
				# Create line segment
				var v1 = pos1 - right
				var v2 = pos1 + right
				var v3 = pos2 - right
				var v4 = pos2 + right
				
				vertices.append_array([v1, v3, v2, v2, v3, v4])
				for k in range(6):
					normals.append(Vector3.UP)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	if vertices.size() > 0:
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		line_mesh_instance.mesh = array_mesh
		
		var line_material = StandardMaterial3D.new()
		line_material.albedo_color = center_line_color
		line_material.emission_enabled = true
		line_material.emission = center_line_color
		line_material.emission_energy = 0.2
		line_mesh_instance.material_override = line_material

func _create_track_collision() -> void:
	# Create collision using trimesh
	if track_mesh and track_mesh.mesh:
		track_mesh.create_trimesh_collision()
		
		# Find and rename the collision
		for child in track_mesh.get_children():
			if child is StaticBody3D:
				collision_body = child
				collision_body.name = "TrackCollision"
				break

func _create_barriers() -> void:
	# Create smooth barriers along the track
	for side in [-1, 1]:
		var barrier_mesh = MeshInstance3D.new()
		barrier_mesh.name = "Barrier" + ("Left" if side < 0 else "Right")
		add_child(barrier_mesh)
		
		var array_mesh = ArrayMesh.new()
		var arrays = Array()
		arrays.resize(Mesh.ARRAY_MAX)
		
		var vertices = PackedVector3Array()
		var normals = PackedVector3Array()
		
		# Sample curve for barriers
		var total_points = control_points * segments_per_curve
		var curve_length = track_curve.get_baked_length()
		
		for i in range(total_points):
			var t1 = float(i) / float(total_points)
			var t2 = float((i + 1) % total_points) / float(total_points)
			
			var offset1 = t1 * curve_length
			var offset2 = t2 * curve_length
			
			var pos1 = track_curve.sample_baked(offset1)
			var pos2 = track_curve.sample_baked(offset2)
			
			var forward = (pos2 - pos1).normalized()
			var right = forward.cross(Vector3.UP).normalized()
			
			# Barrier position
			var barrier_offset = (track_width * 0.5 + 0.5) * side
			var base1 = pos1 + right * barrier_offset
			var base2 = pos2 + right * barrier_offset
			var top1 = base1 + Vector3(0, 0.5, 0)
			var top2 = base2 + Vector3(0, 0.5, 0)
			
			vertices.append_array([base1, top1, base2, top1, top2, base2])
			
			var normal = -right * side
			for j in range(6):
				normals.append(normal)
		
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		barrier_mesh.mesh = array_mesh
		
		var barrier_material = StandardMaterial3D.new()
		barrier_material.albedo_color = Color(1.0, 0.4, 0.0) if side < 0 else Color(0.0, 0.4, 1.0)
		barrier_mesh.material_override = barrier_material
		
		# Create collision
		barrier_mesh.create_trimesh_collision()

func get_spawn_position() -> Vector3:
	if track_curve and track_curve.get_point_count() > 0:
		return track_curve.get_point_position(0) + Vector3(0, 3, 0)
	return Vector3(0, 8, 0)

func get_spawn_rotation() -> float:
	if track_curve and track_curve.get_point_count() > 1:
		var forward = (track_curve.get_point_position(1) - track_curve.get_point_position(0)).normalized()
		return atan2(forward.x, forward.z)
	return 0.0