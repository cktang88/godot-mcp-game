extends Node3D

@export var track_name: String = "Test Track"
@export var track_length_km: float = 2.5
@export var lap_count: int = 3

var checkpoints: Array[Area3D] = []
var spawn_points: Array[Marker3D] = []

signal lap_completed(lap_number: int)
signal race_finished()

func _ready() -> void:
	_find_checkpoints()
	_find_spawn_points()

func _find_checkpoints() -> void:
	checkpoints.clear()
	for child in get_children():
		if child.is_in_group("checkpoint"):
			checkpoints.append(child)
			child.connect("body_entered", _on_checkpoint_entered.bind(child))

func _find_spawn_points() -> void:
	spawn_points.clear()
	for child in get_children():
		if child.is_in_group("spawn_point"):
			spawn_points.append(child)

func _on_checkpoint_entered(body: Node3D, checkpoint: Area3D) -> void:
	if body.is_in_group("player"):
		# Handle checkpoint logic in GameManager
		pass

func get_spawn_transform(index: int = 0) -> Transform3D:
	if spawn_points.is_empty():
		return Transform3D()
	
	index = clamp(index, 0, spawn_points.size() - 1)
	return spawn_points[index].global_transform

func reset_checkpoints() -> void:
	# Reset checkpoint states if needed
	pass
