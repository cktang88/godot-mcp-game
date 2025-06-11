extends Control
class_name HealthBarComponent

@onready var background: ColorRect = $Background
@onready var health_fill: ColorRect = $HealthFill
@onready var health_label: Label = $HealthLabel

var max_health: int = 100
var current_health: int = 100

func _ready():
	update_display()

func set_health(current: int, maximum: int):
	current_health = current
	max_health = maximum
	update_display()

func update_display():
	if not background or not health_fill or not health_label:
		return
		
	var health_ratio = float(current_health) / float(max_health) if max_health > 0 else 0.0
	
	health_fill.size.x = background.size.x * health_ratio
	health_label.text = "%d/%d" % [current_health, max_health]
	
	if health_ratio > 0.6:
		health_fill.color = Color.GREEN
	elif health_ratio > 0.3:
		health_fill.color = Color.YELLOW
	else:
		health_fill.color = Color.RED