extends Path2D

@export var path_width: float = 40.0
@export var path_color: Color = Color(0.6, 0.5, 0.3)
@export var path_border_color: Color = Color(0.4, 0.3, 0.2)

var path_line: Line2D
var path_border: Line2D

func _ready() -> void:
	# Create a longer, more complex path
	_generate_path()
	_create_visual_path()

func _generate_path():
	# Clear existing curve
	curve = Curve2D.new()
	
	# Define waypoints for a longer, more interesting path
	var waypoints = [
		Vector2(-50, 720),      # Start off-screen center-left
		Vector2(200, 720),      # Enter screen
		Vector2(400, 600),      # Move up
		Vector2(600, 500),      # Continue diagonal
		Vector2(800, 500),      # Move right
		Vector2(1000, 600),     # Move down
		Vector2(1200, 700),     # Continue down
		Vector2(1400, 700),     # Move right
		Vector2(1600, 600),     # Move up
		Vector2(1800, 500),     # Continue up
		Vector2(2000, 400),     # Move up more
		Vector2(2200, 300),     # Continue diagonal
		Vector2(2200, 200),     # Move up
		Vector2(2000, 100),     # Move left
		Vector2(1800, 100),     # Continue left
		Vector2(1600, 200),     # Move down
		Vector2(1400, 300),     # Continue diagonal
		Vector2(1200, 400),     # Continue down
		Vector2(1000, 400),     # Move left
		Vector2(800, 300),      # Move up
		Vector2(600, 200),      # Continue diagonal
		Vector2(400, 200),      # Move left
		Vector2(200, 300),      # Move down
		Vector2(200, 500),      # Continue down
		Vector2(300, 600),      # Move diagonal
		Vector2(400, 700),      # Continue down
		Vector2(600, 800),      # Move diagonal
		Vector2(800, 900),      # Continue diagonal
		Vector2(1000, 1000),    # Continue diagonal
		Vector2(1200, 1100),    # Continue diagonal
		Vector2(1400, 1100),    # Move right
		Vector2(1600, 1000),    # Move up
		Vector2(1800, 900),     # Continue diagonal
		Vector2(2000, 900),     # Move right
		Vector2(2200, 1000),    # Move down
		Vector2(2400, 1100),    # Continue diagonal
		Vector2(2600, 1100),    # Exit off-screen right
	]
	
	# Add points to curve with smooth in/out controls
	for i in range(waypoints.size()):
		curve.add_point(waypoints[i])
		
		# Add bezier handles for smoother curves
		if i > 0 and i < waypoints.size() - 1:
			var prev = waypoints[i - 1]
			var curr = waypoints[i]
			var next = waypoints[i + 1]
			
			# Calculate smooth bezier handles
			var in_dir = (curr - prev).normalized()
			var out_dir = (next - curr).normalized()
			var handle_length = 50.0
			
			curve.set_point_in(i, -out_dir * handle_length)
			curve.set_point_out(i, out_dir * handle_length)

func _create_visual_path():
	# Create border line (drawn first, so it appears behind)
	path_border = Line2D.new()
	path_border.width = path_width + 4
	path_border.default_color = path_border_color
	path_border.joint_mode = Line2D.LINE_JOINT_ROUND
	path_border.cap_mode = Line2D.LINE_CAP_ROUND
	add_child(path_border)
	
	# Create main path line
	path_line = Line2D.new()
	path_line.width = path_width
	path_line.default_color = path_color
	path_line.joint_mode = Line2D.LINE_JOINT_ROUND
	path_line.cap_mode = Line2D.LINE_CAP_ROUND
	add_child(path_line)
	
	# Update visual representation
	_update_path_visuals()

func _update_path_visuals():
	if not curve or curve.point_count < 2:
		return
	
	var points = []
	var bake_interval = 10.0  # Sample every 10 units
	var length = curve.get_baked_length()
	
	for i in range(0, int(length), int(bake_interval)):
		points.append(curve.sample_baked(i))
	
	# Add the last point
	points.append(curve.sample_baked(length))
	
	# Update both lines
	if path_line:
		path_line.points = points
	if path_border:
		path_border.points = points