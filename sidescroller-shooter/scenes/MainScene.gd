extends Node2D
class_name MainScene

@onready var player: Player = $Player
@onready var game_manager: GameManager = $GameManager
@onready var ui: UIController = $UILayer/UI
@onready var aim_cursor: Node2D = $AimCursor

func _ready():
	if game_manager and player and ui:
		game_manager.initialize_game(player)
		ui.initialize(player, game_manager)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(delta):
	if aim_cursor:
		aim_cursor.global_position = get_global_mouse_position()