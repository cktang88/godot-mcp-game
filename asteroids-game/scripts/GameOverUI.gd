extends Control

@onready var score_label = $VBoxContainer/ScoreLabel
@onready var restart_label = $VBoxContainer/RestartLabel

func show_game_over(final_score: int):
	score_label.text = "GAME OVER\nScore: " + str(final_score) + " asteroids destroyed"
	restart_label.text = "Press SPACE to restart"
	visible = true

func _input(event):
	if visible and event.is_action_pressed("shoot"):
		restart_game()

func restart_game():
	get_tree().reload_current_scene()
