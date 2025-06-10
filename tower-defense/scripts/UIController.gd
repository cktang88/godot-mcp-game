extends CanvasLayer

# UI References
@onready var lives_label = $HUD/InfoPanel/Stats/LivesLabel
@onready var gold_label = $HUD/InfoPanel/Stats/GoldLabel
@onready var wave_label = $HUD/InfoPanel/Stats/WaveLabel
@onready var basic_tower_button = $ShopContainer/ShopPanel/ShopHBox/BasicTowerButton
@onready var smg_tower_button = $ShopContainer/ShopPanel/ShopHBox/SMGTowerButton
@onready var sniper_tower_button = $ShopContainer/ShopPanel/ShopHBox/SniperTowerButton
@onready var shotgun_tower_button = $ShopContainer/ShopPanel/ShopHBox/ShotgunTowerButton
@onready var start_wave_button = $WaveContainer/WavePanel/WaveVBox/StartWaveButton
@onready var next_wave_label = $WaveContainer/WavePanel/WaveVBox/NextWaveLabel

# Tower stats panel references
@onready var tower_stats_panel = $TowerStatsPanel
@onready var tower_name_label = $TowerStatsPanel/StatsVBox/TowerNameLabel
@onready var stats_label = $TowerStatsPanel/StatsVBox/StatsLabel
@onready var sell_button = $TowerStatsPanel/StatsVBox/ButtonsHBox/SellButton
@onready var close_button = $TowerStatsPanel/StatsVBox/ButtonsHBox/CloseButton

# Time control references
@onready var speed_1x_button = $TimeControlPanel/TimeHBox/Speed1xButton
@onready var speed_2x_button = $TimeControlPanel/TimeHBox/Speed2xButton
@onready var speed_4x_button = $TimeControlPanel/TimeHBox/Speed4xButton

# Tower scenes
var basic_tower_scene = preload("res://scenes/BasicTower.tscn")
var smg_tower_scene = preload("res://scenes/SMGTower.tscn")
var sniper_tower_scene = preload("res://scenes/SniperTower.tscn")
var shotgun_tower_scene = preload("res://scenes/ShotgunTower.tscn")

# Tower data
var tower_data = {
	"basic": {"scene": basic_tower_scene, "cost": 50, "damage": 15, "range": 200},
	"smg": {"scene": smg_tower_scene, "cost": 75, "damage": 8, "range": 180},
	"sniper": {"scene": sniper_tower_scene, "cost": 150, "damage": 50, "range": 350},
	"shotgun": {"scene": shotgun_tower_scene, "cost": 100, "damage": 12, "range": 150}
}

# State
var game_manager: Node
var camera: Camera2D
var time_controller: TimeController
var is_placing_tower: bool = false
var tower_preview: Node2D = null
var current_tower_type: String = ""
var current_tower_cost: int = 0
var selected_tower: BaseTower = null
var previously_selected_tower: BaseTower = null

func _ready():
	game_manager = get_node("../GameManager")
	
	# Camera will be created by MainSceneSetup, so we'll get it after a frame
	call_deferred("_setup_camera")
	
	# Create and setup time controller using deferred call
	time_controller = TimeController.new()
	time_controller.name = "TimeController"
	get_node("../").call_deferred("add_child", time_controller)
	
	# Connect signals
	game_manager.lives_changed.connect(_on_lives_changed)
	game_manager.gold_changed.connect(_on_gold_changed)
	game_manager.wave_started.connect(_on_wave_started)
	game_manager.game_over.connect(_on_game_over)
	
	# Connect buttons
	basic_tower_button.pressed.connect(_on_basic_tower_pressed)
	smg_tower_button.pressed.connect(_on_smg_tower_pressed)
	sniper_tower_button.pressed.connect(_on_sniper_tower_pressed)
	shotgun_tower_button.pressed.connect(_on_shotgun_tower_pressed)
	start_wave_button.pressed.connect(_on_start_wave_pressed)
	sell_button.pressed.connect(_on_sell_tower_pressed)
	close_button.pressed.connect(_on_close_stats_pressed)
	
	# Connect time control buttons if they exist
	_setup_time_controls()
	
	# Initialize display
	_on_lives_changed(game_manager.lives)
	_on_gold_changed(game_manager.gold)
	_update_next_wave_info()

func _on_lives_changed(new_lives: int):
	lives_label.text = "Lives: " + str(new_lives)

func _on_gold_changed(new_gold: int):
	gold_label.text = "Gold: " + str(new_gold)
	
	# Update tower buttons
	basic_tower_button.disabled = new_gold < tower_data["basic"]["cost"]
	smg_tower_button.disabled = new_gold < tower_data["smg"]["cost"]
	sniper_tower_button.disabled = new_gold < tower_data["sniper"]["cost"]
	shotgun_tower_button.disabled = new_gold < tower_data["shotgun"]["cost"]

func _on_wave_started(wave_number: int):
	wave_label.text = "Wave: " + str(wave_number)
	start_wave_button.disabled = true
	start_wave_button.text = "Wave in Progress"

func _update_next_wave_info():
	var next_wave = game_manager.current_wave + 1
	var enemy_count = 5 + (next_wave - 1) * 2
	next_wave_label.text = "Next Wave: " + str(next_wave) + "\nEnemies: " + str(enemy_count)
	
	if not game_manager.wave_active:
		start_wave_button.disabled = false
		start_wave_button.text = "Start Wave"

func _on_game_over():
	# Reset time scale
	if time_controller:
		time_controller.set_normal_speed()
	
	# Create game over screen
	var game_over_container = CenterContainer.new()
	game_over_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var game_over_panel = PanelContainer.new()
	game_over_container.add_child(game_over_panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	game_over_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "GAME OVER"
	title.add_theme_font_size_override("font_size", 48)
	vbox.add_child(title)
	
	var score = Label.new()
	score.text = "You survived " + str(game_manager.current_wave) + " waves!"
	score.add_theme_font_size_override("font_size", 24)
	vbox.add_child(score)
	
	add_child(game_over_container)

func _on_basic_tower_pressed():
	_start_tower_placement("basic")

func _on_smg_tower_pressed():
	_start_tower_placement("smg")

func _on_sniper_tower_pressed():
	_start_tower_placement("sniper")

func _on_shotgun_tower_pressed():
	_start_tower_placement("shotgun")

func _start_tower_placement(tower_type: String):
	if game_manager.can_afford_tower(tower_data[tower_type]["cost"]):
		is_placing_tower = true
		current_tower_type = tower_type
		current_tower_cost = tower_data[tower_type]["cost"]
		
		tower_preview = tower_data[tower_type]["scene"].instantiate()
		tower_preview.modulate.a = 0.5
		get_node("../").add_child(tower_preview)
		tower_preview.set_range_indicator_visible(true)

func _on_start_wave_pressed():
	game_manager.start_wave()
	start_wave_button.disabled = true
	start_wave_button.text = "Wave in Progress"

func _process(_delta):
	# Check if wave is complete
	if not game_manager.wave_active and start_wave_button.disabled:
		_update_next_wave_info()
	
	# Update tower stats panel if visible
	if tower_stats_panel.visible and selected_tower and is_instance_valid(selected_tower):
		_update_tower_stats_display()

func _unhandled_input(event):
	if is_placing_tower and tower_preview:
		if event is InputEventMouseMotion or event is InputEventMouseButton:
			# Convert screen position to world position using camera
			var world_pos = get_viewport().canvas_transform.affine_inverse() * event.position
			if camera:
				world_pos = camera.get_global_mouse_position()
			
			tower_preview.global_position = world_pos
			# Update color based on validity
			if _is_valid_placement(world_pos):
				tower_preview.modulate = Color(0.5, 1, 0.5, 0.7)  # Green tint
			else:
				tower_preview.modulate = Color(1, 0.5, 0.5, 0.7)  # Red tint
		
		if event.is_action_pressed("place_tower"):
			var world_pos = get_viewport().canvas_transform.affine_inverse() * event.position
			if camera:
				world_pos = camera.get_global_mouse_position()
			if _is_valid_placement(world_pos):
				_place_tower(world_pos)
					
		elif event.is_action_pressed("cancel_placement"):
			_cancel_placement()

func _is_valid_placement(pos: Vector2) -> bool:
	# Check distance from path
	var path = get_node("../EnemyPath")
	if not path or not path.curve:
		return true
		
	var curve = path.curve
	var min_distance = 60.0  # Minimum distance from path
	
	# Check multiple points along the curve for better accuracy
	for i in range(curve.get_point_count() - 1):
		var start_point = curve.get_point_position(i)
		var end_point = curve.get_point_position(i + 1)
		
		# Check several points between each curve segment
		for t in range(0, 11):  # 0.0 to 1.0 in 0.1 increments
			var point = start_point.lerp(end_point, t / 10.0)
			if pos.distance_to(point) < min_distance:
				return false
	
	# Check overlap with existing towers
	var towers = get_tree().get_nodes_in_group("towers")
	for tower in towers:
		if tower != tower_preview and pos.distance_to(tower.global_position) < 40:
			return false
	
	return true

func _place_tower(pos: Vector2):
	if game_manager.purchase_tower(current_tower_cost):
		var tower = tower_data[current_tower_type]["scene"].instantiate()
		tower.global_position = pos
		tower.add_to_group("towers")
		
		# Tower properties are set by their individual _setup_tower() methods
		
		# Connect tower click signal
		tower.tower_clicked.connect(_on_tower_clicked)
		
		get_node("../").add_child(tower)
		
	_cancel_placement()

func _cancel_placement():
	if tower_preview:
		tower_preview.queue_free()
		tower_preview = null
	is_placing_tower = false
	current_tower_type = ""
	current_tower_cost = 0

func _on_tower_clicked(tower: BaseTower):
	if is_placing_tower:
		return  # Don't show stats while placing towers
	
	# Hide range indicator for previously selected tower
	if previously_selected_tower and is_instance_valid(previously_selected_tower):
		previously_selected_tower.set_range_indicator_visible(false)
	
	# If clicking the same tower, deselect it
	if selected_tower == tower:
		selected_tower = null
		previously_selected_tower = null
		tower_stats_panel.visible = false
		tower.set_range_indicator_visible(false)
		return
	
	# Select new tower
	selected_tower = tower
	previously_selected_tower = tower
	tower.set_range_indicator_visible(true)
	_show_tower_stats()

func _show_tower_stats():
	if not selected_tower:
		return
	
	tower_name_label.text = selected_tower.tower_name
	sell_button.text = "Sell (%dg)" % selected_tower.sell_value
	tower_stats_panel.visible = true
	_update_tower_stats_display()

func _update_tower_stats_display():
	if not selected_tower or not is_instance_valid(selected_tower):
		return
	
	stats_label.text = "Enemies Killed: %d\nTotal Damage: %d\nShots Fired: %d" % [
		selected_tower.enemies_killed,
		selected_tower.total_damage_dealt,
		selected_tower.shots_fired
	]

func _on_sell_tower_pressed():
	if not selected_tower:
		return
	
	# Give player gold for selling
	game_manager.gold += selected_tower.sell_value
	game_manager.gold_changed.emit(game_manager.gold)
	
	# Hide range indicator before removing tower
	selected_tower.set_range_indicator_visible(false)
	
	# Remove tower from scene
	selected_tower.queue_free()
	selected_tower = null
	previously_selected_tower = null
	tower_stats_panel.visible = false

func _on_close_stats_pressed():
	# Hide range indicator before closing
	if selected_tower and is_instance_valid(selected_tower):
		selected_tower.set_range_indicator_visible(false)
	
	selected_tower = null
	previously_selected_tower = null
	tower_stats_panel.visible = false

func _setup_camera():
	camera = get_node_or_null("../Camera2D")
	if not camera:
		print("Warning: Camera2D not found")

func _setup_time_controls():
	# Create time control panel if it doesn't exist
	if not has_node("TimeControlPanel"):
		var time_panel = PanelContainer.new()
		time_panel.name = "TimeControlPanel"
		time_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		time_panel.position = Vector2(-200, 160)  # Moved further down to avoid overlap with wave panel
		time_panel.size = Vector2(180, 50)
		
		# Add custom style
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color(0.15, 0.15, 0.15, 0.9)
		panel_style.border_width_left = 2
		panel_style.border_width_right = 2
		panel_style.border_width_top = 2
		panel_style.border_width_bottom = 2
		panel_style.border_color = Color(0.3, 0.3, 0.3)
		panel_style.corner_radius_top_left = 5
		panel_style.corner_radius_top_right = 5
		panel_style.corner_radius_bottom_left = 5
		panel_style.corner_radius_bottom_right = 5
		time_panel.add_theme_stylebox_override("panel", panel_style)
		
		var hbox = HBoxContainer.new()
		hbox.name = "TimeHBox"
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		time_panel.add_child(hbox)
		
		# Create speed buttons
		var speed_1x = Button.new()
		speed_1x.name = "Speed1xButton"
		speed_1x.text = "1x"
		speed_1x.custom_minimum_size = Vector2(50, 40)
		speed_1x.pressed.connect(_on_speed_1x_pressed)
		hbox.add_child(speed_1x)
		speed_1x_button = speed_1x
		
		var speed_2x = Button.new()
		speed_2x.name = "Speed2xButton"
		speed_2x.text = "2x"
		speed_2x.custom_minimum_size = Vector2(50, 40)
		speed_2x.pressed.connect(_on_speed_2x_pressed)
		hbox.add_child(speed_2x)
		speed_2x_button = speed_2x
		
		var speed_4x = Button.new()
		speed_4x.name = "Speed4xButton"
		speed_4x.text = "4x"
		speed_4x.custom_minimum_size = Vector2(50, 40)
		speed_4x.pressed.connect(_on_speed_4x_pressed)
		hbox.add_child(speed_4x)
		speed_4x_button = speed_4x
		
		add_child(time_panel)
	
	# Register buttons with time controller
	if speed_1x_button:
		time_controller.register_speed_button(1.0, speed_1x_button)
	if speed_2x_button:
		time_controller.register_speed_button(2.0, speed_2x_button)
	if speed_4x_button:
		time_controller.register_speed_button(4.0, speed_4x_button)

func _on_speed_1x_pressed():
	time_controller.set_normal_speed()

func _on_speed_2x_pressed():
	time_controller.set_fast_speed()

func _on_speed_4x_pressed():
	time_controller.set_very_fast_speed()
