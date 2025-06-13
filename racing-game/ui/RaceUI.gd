extends Control

@onready var speed_label: Label = $MarginContainer/VBoxContainer/SpeedContainer/SpeedLabel
@onready var lap_label: Label = $MarginContainer/VBoxContainer/LapContainer/LapLabel
@onready var time_label: Label = $MarginContainer/VBoxContainer/TimeContainer/TimeLabel
@onready var best_lap_label: Label = $MarginContainer/VBoxContainer/BestLapContainer/BestLapLabel
@onready var countdown_label: Label = $CenterContainer/CountdownLabel
@onready var race_complete_panel: Panel = $RaceCompletePanel
@onready var final_time_label: Label = $RaceCompletePanel/VBoxContainer/FinalTimeLabel
@onready var restart_button: Button = $RaceCompletePanel/VBoxContainer/RestartButton

var player_car: VehicleBody3D

func _ready() -> void:
	race_complete_panel.visible = false
	countdown_label.visible = false
	
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	
	# Connect to GameManager signals
	if GameManager:
		GameManager.race_started.connect(_on_race_started)
		GameManager.race_finished.connect(_on_race_finished)
		GameManager.lap_completed.connect(_on_lap_completed)

func _process(_delta: float) -> void:
	if GameManager and GameManager.is_racing:
		update_time_display()

func set_player_car(car: VehicleBody3D) -> void:
	player_car = car
	if player_car and player_car.has_signal("speed_changed"):
		player_car.speed_changed.connect(_on_speed_changed)

func _on_speed_changed(speed_kph: float) -> void:
	if speed_label:
		speed_label.text = "%d KPH" % int(speed_kph)

func update_time_display() -> void:
	if time_label and GameManager:
		time_label.text = GameManager.get_formatted_time(GameManager.race_time)

func _on_lap_completed(lap_number: int, lap_time: float) -> void:
	if lap_label and GameManager:
		lap_label.text = "LAP %d/%d" % [GameManager.current_lap, GameManager.total_laps]
	
	if best_lap_label and GameManager:
		best_lap_label.text = "BEST: " + GameManager.get_formatted_time(GameManager.best_lap_time)

func _on_race_started() -> void:
	if lap_label and GameManager:
		lap_label.text = "LAP %d/%d" % [GameManager.current_lap, GameManager.total_laps]
	race_complete_panel.visible = false

func _on_race_finished(total_time: float) -> void:
	race_complete_panel.visible = true
	if final_time_label and GameManager:
		final_time_label.text = "Final Time: " + GameManager.get_formatted_time(total_time)

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func show_countdown() -> void:
	countdown_label.visible = true
	countdown_label.text = "3"
	await get_tree().create_timer(1.0).timeout
	countdown_label.text = "2"
	await get_tree().create_timer(1.0).timeout
	countdown_label.text = "1"
	await get_tree().create_timer(1.0).timeout
	countdown_label.text = "GO!"
	await get_tree().create_timer(0.5).timeout
	countdown_label.visible = false