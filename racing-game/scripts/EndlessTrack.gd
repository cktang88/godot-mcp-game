extends Node3D

@export var segment_length: float = 10.0
@export var track_width: float = 8.0
@export var wall_height: float = 0.5  # Much shorter walls
@export var segments_ahead: int = 20
@export var segments_behind: int = 5
@export var curve_intensity: float = 0.3
@export var curve_frequency: float = 0.1
@export var hill_frequency: float = 0.05
@export var hill_intensity: float = 2.0

var segments: Array = []
var current_angle: float = 0.0
var current_height: float = 0.0
var segment_index: int = 0
var player: Node3D
var last_player_segment: int = -1

# Track segment data
class TrackSegment:
	var position: Vector3
	var rotation: float
	var height_offset: float
	var mesh_instance: MeshInstance3D
	var left_wall: MeshInstance3D
	var right_wall: MeshInstance3D
	var collision_body: StaticBody3D
	var index: int
	var has_ramp: bool = false
	var has_jump: bool = false

func _ready() -> void:
	_create_initial_track()

func set_player(p: Node3D) -> void:
	player = p

func _create_initial_track() -> void:
	var start_pos = Vector3.ZERO
	
	for i in range(segments_ahead + segments_behind):
		# Skip walls and features for first few segments (spawn area)
		var is_spawn_area = i < 3
		_create_segment(start_pos, current_angle, i, is_spawn_area)
		
		# Calculate next position
		var forward = Vector3(sin(current_angle), 0, cos(current_angle))
		start_pos += forward * segment_length
		
		# Add curve (but not in spawn area)
		if not is_spawn_area:
			current_angle += _generate_curve_angle()
			current_height = _generate_height_offset()

func _create_segment(pos: Vector3, angle: float, index: int, is_spawn_area: bool = false) -> void:
	var segment = TrackSegment.new()
	segment.position = pos
	segment.rotation = angle
	segment.height_offset = current_height if not is_spawn_area else 0.0
	segment.index = index
	
	# Create collision body
	segment.collision_body = StaticBody3D.new()
	segment.collision_body.position = pos
	segment.collision_body.rotation.y = angle
	segment.collision_body.collision_layer = 1  # World layer
	add_child(segment.collision_body)
	
	# Create road mesh
	segment.mesh_instance = MeshInstance3D.new()
	var road_mesh = BoxMesh.new()
	road_mesh.size = Vector3(track_width, 0.1, segment_length)
	segment.mesh_instance.mesh = road_mesh
	segment.mesh_instance.position.y = segment.height_offset - 0.05
	
	# Road material
	var road_material = StandardMaterial3D.new()
	road_material.albedo_color = Color(0.2, 0.2, 0.2)  # Dark gray asphalt
	segment.mesh_instance.material_override = road_material
	segment.collision_body.add_child(segment.mesh_instance)
	
	# Add road collision
	var road_collision = CollisionShape3D.new()
	var road_shape = BoxShape3D.new()
	road_shape.size = Vector3(track_width, 0.1, segment_length)
	road_collision.shape = road_shape
	road_collision.position.y = segment.height_offset - 0.05
	segment.collision_body.add_child(road_collision)
	
	# Create walls (skip for spawn area)
	if not is_spawn_area:
		_create_wall(segment, true)   # Left wall
		_create_wall(segment, false)  # Right wall
	
	# Add center line
	_create_center_line(segment)
	
	# Randomly add features (not in spawn area)
	if not is_spawn_area and randf() < 0.1:  # 10% chance
		if randf() < 0.5:
			_create_ramp(segment)
		else:
			_create_jump(segment)
	
	segments.append(segment)

func _create_wall(segment: TrackSegment, is_left: bool) -> void:
	var wall = MeshInstance3D.new()
	var wall_mesh = BoxMesh.new()
	wall_mesh.size = Vector3(0.3, wall_height, segment_length)
	wall.mesh = wall_mesh
	
	var x_offset = (track_width / 2 + 0.15) * (1 if is_left else -1)
	wall.position = Vector3(x_offset, wall_height / 2 + segment.height_offset, 0)
	
	# Wall material - make them more visible but shorter
	var wall_material = StandardMaterial3D.new()
	wall_material.albedo_color = Color(1.0, 0.5, 0.0) if is_left else Color(0.0, 0.5, 1.0)  # Orange/Blue
	wall.material_override = wall_material
	segment.collision_body.add_child(wall)
	
	# Wall collision
	var wall_collision = CollisionShape3D.new()
	var wall_shape = BoxShape3D.new()
	wall_shape.size = Vector3(0.3, wall_height, segment_length)
	wall_collision.shape = wall_shape
	wall_collision.position = Vector3(x_offset, wall_height / 2 + segment.height_offset, 0)
	segment.collision_body.add_child(wall_collision)
	
	if is_left:
		segment.left_wall = wall
	else:
		segment.right_wall = wall

func _create_center_line(segment: TrackSegment) -> void:
	var line_count = int(segment_length / 2.0)
	
	for i in range(line_count):
		if i % 2 == 0:  # Dashed line
			var line = MeshInstance3D.new()
			var line_mesh = BoxMesh.new()
			line_mesh.size = Vector3(0.2, 0.02, 1.5)
			line.mesh = line_mesh
			line.position = Vector3(0, segment.height_offset + 0.01, -segment_length/2 + i * 2 + 1)
			
			var line_material = StandardMaterial3D.new()
			line_material.albedo_color = Color(1, 1, 1)
			line.material_override = line_material
			segment.collision_body.add_child(line)

func _create_ramp(segment: TrackSegment) -> void:
	segment.has_ramp = true
	
	# Create ramp using box meshes for better control
	var ramp_container = Node3D.new()
	ramp_container.name = "Ramp"
	segment.collision_body.add_child(ramp_container)
	
	# Ramp dimensions
	var ramp_length = 6.0
	var ramp_height = 1.5
	var ramp_width = track_width * 0.8
	
	# Create angled ramp surface
	var ramp_surface = MeshInstance3D.new()
	var ramp_mesh = BoxMesh.new()
	ramp_mesh.size = Vector3(ramp_width, 0.2, ramp_length)
	ramp_surface.mesh = ramp_mesh
	
	# Position at the back of segment, angled upward in driving direction
	ramp_surface.position = Vector3(0, ramp_height/2 + segment.height_offset, segment_length/2 - ramp_length/2)
	ramp_surface.rotation.x = -atan2(ramp_height, ramp_length)  # Angle it upward
	
	# Ramp material
	var ramp_material = StandardMaterial3D.new()
	ramp_material.albedo_color = Color(1, 1, 0)  # Yellow ramp
	ramp_surface.material_override = ramp_material
	ramp_container.add_child(ramp_surface)
	
	# Create ramp collision as a series of steps for smoother driving
	var steps = 4
	for i in range(steps):
		var step_collision = CollisionShape3D.new()
		var step_shape = BoxShape3D.new()
		var step_height = (ramp_height / steps) * (i + 1)
		var step_length = ramp_length / steps
		
		step_shape.size = Vector3(ramp_width, step_height, step_length)
		step_collision.shape = step_shape
		
		# Position each step
		var z_pos = segment_length/2 - ramp_length + (i + 0.5) * step_length
		step_collision.position = Vector3(0, step_height/2 + segment.height_offset, z_pos)
		
		segment.collision_body.add_child(step_collision)
	
	# Add visual supports
	var support_material = StandardMaterial3D.new()
	support_material.albedo_color = Color(0.3, 0.3, 0.3)
	
	for x in [-ramp_width/3, ramp_width/3]:
		var support = MeshInstance3D.new()
		var support_mesh = BoxMesh.new()
		support_mesh.size = Vector3(0.2, ramp_height, 0.2)
		support.mesh = support_mesh
		support.position = Vector3(x, ramp_height/2 + segment.height_offset, segment_length/2 - ramp_length)
		support.material_override = support_material
		ramp_container.add_child(support)

func _create_jump(segment: TrackSegment) -> void:
	segment.has_jump = true
	
	# Create jump platform
	var jump = MeshInstance3D.new()
	var jump_mesh = BoxMesh.new()
	jump_mesh.size = Vector3(track_width * 0.6, 0.3, 2.0)
	jump.mesh = jump_mesh
	jump.position = Vector3(0, 0.5 + segment.height_offset, 0)
	
	# Jump material
	var jump_material = StandardMaterial3D.new()
	jump_material.albedo_color = Color(0.4, 0.4, 0.5)  # Gray-blue jump
	jump.material_override = jump_material
	segment.collision_body.add_child(jump)
	
	# Jump collision
	var jump_collision = CollisionShape3D.new()
	var jump_shape = BoxShape3D.new()
	jump_shape.size = Vector3(track_width * 0.6, 0.3, 2.0)
	jump_collision.shape = jump_shape
	jump_collision.position = Vector3(0, 0.5 + segment.height_offset, 0)
	segment.collision_body.add_child(jump_collision)

func _generate_curve_angle() -> float:
	# Generate smooth curves using sine waves
	segment_index += 1
	var curve = sin(segment_index * curve_frequency) * curve_intensity
	curve += sin(segment_index * curve_frequency * 2.3) * curve_intensity * 0.5
	curve += randf_range(-0.02, 0.02)  # Small random variation
	return curve

func _generate_height_offset() -> float:
	# Generate hills and valleys
	var height = sin(segment_index * hill_frequency) * hill_intensity
	height += sin(segment_index * hill_frequency * 1.7) * hill_intensity * 0.5
	return height

func _process(_delta: float) -> void:
	if not player:
		return
	
	# Find which segment the player is on
	var player_segment = _get_player_segment()
	
	if player_segment != last_player_segment:
		last_player_segment = player_segment
		_update_track()

func _get_player_segment() -> int:
	var player_pos = player.global_position
	var min_dist = INF
	var closest_segment = 0
	
	for i in range(segments.size()):
		var dist = player_pos.distance_to(segments[i].position)
		if dist < min_dist:
			min_dist = dist
			closest_segment = i
	
	return closest_segment

func _update_track() -> void:
	# Remove segments too far behind
	while segments.size() > 0 and last_player_segment > segments_behind:
		var old_segment = segments.pop_front()
		old_segment.collision_body.queue_free()
		last_player_segment -= 1
	
	# Add new segments ahead
	while segments.size() < segments_ahead + segments_behind:
		var last_segment = segments.back()
		var forward = Vector3(sin(current_angle), 0, cos(current_angle))
		var new_pos = last_segment.position + forward * segment_length
		
		current_angle += _generate_curve_angle()
		current_height = _generate_height_offset()
		_create_segment(new_pos, current_angle, segment_index, false)

func reset_track() -> void:
	# Clear existing track
	for segment in segments:
		segment.collision_body.queue_free()
	segments.clear()
	
	# Reset variables
	current_angle = 0.0
	current_height = 0.0
	segment_index = 0
	last_player_segment = -1
	
	# Create new track
	_create_initial_track()
