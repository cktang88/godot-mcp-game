extends Node

var current_lap: int = 1
var total_laps: int = 3
var race_time: float = 0.0
var is_racing: bool = false
var lap_times: Array[float] = []
var best_lap_time: float = -1.0

var player_checkpoints: Dictionary = {}
var checkpoint_count: int = 0

signal race_started()
signal race_finished(total_time: float)
signal lap_completed(lap_number: int, lap_time: float)
signal checkpoint_passed(checkpoint_index: int)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if is_racing:
		race_time += delta

func start_race() -> void:
	current_lap = 1
	race_time = 0.0
	is_racing = true
	lap_times.clear()
	player_checkpoints.clear()
	emit_signal("race_started")

func end_race() -> void:
	is_racing = false
	emit_signal("race_finished", race_time)

func pass_checkpoint(player: Node3D, checkpoint_index: int) -> void:
	if not is_racing:
		return
	
	var player_id = player.get_instance_id()
	
	if not player_checkpoints.has(player_id):
		player_checkpoints[player_id] = {
			"checkpoints": [],
			"lap_start_time": 0.0
		}
	
	var player_data = player_checkpoints[player_id]
	
	# Check if this is the finish line (checkpoint 0)
	if checkpoint_index == 0:
		# Check if player has passed all checkpoints
		if player_data.checkpoints.size() >= checkpoint_count - 1:
			complete_lap(player)
		elif current_lap == 1 and player_data.checkpoints.is_empty():
			# First checkpoint on first lap
			player_data.lap_start_time = race_time
	else:
		# Regular checkpoint
		if checkpoint_index not in player_data.checkpoints:
			player_data.checkpoints.append(checkpoint_index)
			emit_signal("checkpoint_passed", checkpoint_index)

func complete_lap(player: Node3D) -> void:
	var player_id = player.get_instance_id()
	var player_data = player_checkpoints[player_id]
	
	var lap_time = race_time - player_data.lap_start_time
	lap_times.append(lap_time)
	
	if best_lap_time < 0 or lap_time < best_lap_time:
		best_lap_time = lap_time
	
	emit_signal("lap_completed", current_lap, lap_time)
	
	if current_lap >= total_laps:
		end_race()
	else:
		current_lap += 1
		player_data.checkpoints.clear()
		player_data.lap_start_time = race_time

func reset_race() -> void:
	is_racing = false
	current_lap = 1
	race_time = 0.0
	player_checkpoints.clear()

func get_formatted_time(time_seconds: float) -> String:
	var minutes = int(time_seconds) / 60
	var seconds = int(time_seconds) % 60
	var milliseconds = int((time_seconds - int(time_seconds)) * 1000)
	return "%02d:%02d.%03d" % [minutes, seconds, milliseconds]