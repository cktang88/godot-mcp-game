extends Control

@export var heart_texture: Texture2D
var health_labels: Array[Label] = []
var score_label: Label

func _ready():
	setup_health_display(3)
	setup_score_display()

func setup_health_display(max_health: int):
	for child in get_children():
		if child != score_label:
			child.queue_free()
	
	health_labels.clear()
	
	var hbox = HBoxContainer.new()
	add_child(hbox)
	
	for i in range(max_health):
		var health_label = Label.new()
		health_label.text = "♥"
		health_label.add_theme_font_size_override("font_size", 32)
		health_label.add_theme_color_override("font_color", Color.RED)
		hbox.add_child(health_label)
		health_labels.append(health_label)

func setup_score_display():
	score_label = Label.new()
	score_label.text = "Score: 0"
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	score_label.position = Vector2(0, -40)
	add_child(score_label)

func update_health(current_health: int):
	for i in range(health_labels.size()):
		if i < current_health:
			health_labels[i].modulate = Color.WHITE
		else:
			health_labels[i].modulate = Color(0.3, 0.3, 0.3, 0.5)

func update_score(score: int):
	if score_label:
		score_label.text = "Score: " + str(score)
