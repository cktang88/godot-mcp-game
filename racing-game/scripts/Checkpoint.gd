extends Area3D

@export var checkpoint_index: int = 0
@export var is_finish_line: bool = false
@export var width: float = 10.0
@export var height: float = 5.0

var players_passed: Array[int] = []

signal checkpoint_passed(body: Node3D, index: int)

func _ready() -> void:
	add_to_group("checkpoint")
	collision_layer = 0
	collision_mask = 2  # Only detect layer 2 (players)
	
	connect("body_entered", _on_body_entered)
	
	_setup_collision_shape()
	_setup_visual()

func _setup_collision_shape() -> void:
	var collision_shape = CollisionShape3D.new()
	add_child(collision_shape)
	
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(width, height, 1.0)
	collision_shape.shape = box_shape

func _setup_visual() -> void:
	var mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(width, height, 0.2)
	mesh_instance.mesh = box_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	if is_finish_line:
		material.albedo_color = Color(0, 1, 0, 0.5)  # Green for finish
	else:
		material.albedo_color = Color(0, 0.5, 1, 0.5)  # Blue for checkpoint
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	
	var player_id = body.get_instance_id()
	
	# Prevent multiple triggers for the same player
	if player_id in players_passed:
		return
	
	players_passed.append(player_id)
	emit_signal("checkpoint_passed", body, checkpoint_index)
	
	# Notify GameManager
	if GameManager:
		GameManager.pass_checkpoint(body, checkpoint_index)
	
	# Reset after a delay to allow re-triggering on next lap
	await get_tree().create_timer(2.0).timeout
	players_passed.erase(player_id)

func reset() -> void:
	players_passed.clear()