extends Node2D

@export var map_size: Vector2 = Vector2(2560, 1440)
@export var grid_size: int = 64
@export var grid_color: Color = Color(0.2, 0.2, 0.2, 0.3)
@export var background_color: Color = Color(0.1, 0.15, 0.1)

func _ready() -> void:
	# Create background
	var background = ColorRect.new()
	background.size = map_size
	background.color = background_color
	background.position = Vector2.ZERO
	add_child(background)
	
	# Move to back
	move_child(background, 0)

func _draw() -> void:
	# Draw grid
	for x in range(0, int(map_size.x) + 1, grid_size):
		draw_line(Vector2(x, 0), Vector2(x, map_size.y), grid_color, 1.0)
	
	for y in range(0, int(map_size.y) + 1, grid_size):
		draw_line(Vector2(0, y), Vector2(map_size.x, y), grid_color, 1.0)
	
	# Draw border
	draw_rect(Rect2(Vector2.ZERO, map_size), Color(0.3, 0.3, 0.3), false, 2.0)