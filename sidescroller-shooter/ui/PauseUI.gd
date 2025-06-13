extends CanvasLayer

@onready var control = $Control

func _ready():
	control.visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func show_pause():
	control.visible = true

func hide_pause():
	control.visible = false