extends Node
## Entry scene: menu plus session lifecycle.

const GAME_SCENE: PackedScene = preload("res://main/game.tscn")

var _game: Node

@onready var _menu: CanvasLayer = $Menu
@onready var _start_button: Button = $Menu/StartButton

func _ready() -> void:
	_start_button.pressed.connect(start_game)
	if OS.get_cmdline_user_args().has("--autostart"):
		start_game()

func start_game() -> void:
	if _game != null:
		return
	_game = GAME_SCENE.instantiate()
	_game.name = &"Game"
	add_child(_game)
	_menu.hide()

func end_game() -> void:
	if _game != null:
		_game.free()
		_game = null
	_menu.show()
