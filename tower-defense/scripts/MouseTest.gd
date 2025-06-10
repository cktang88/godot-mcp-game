extends Node2D

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		print("Mouse clicked at: ", event.position)
		print("Button index: ", event.button_index)
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("Left click")
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			print("Right click")
