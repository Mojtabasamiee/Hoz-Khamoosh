extends Node
## Main — bootstraps input map and screen switching (menu <-> game <-> endings).

var current: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_show_menu()

func _setup_input() -> void:
	var defs := {
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"interact": [KEY_E],
		"flashlight": [KEY_F],
		"crouch": [KEY_C, KEY_CTRL],
		"pause": [KEY_ESCAPE],
		"inventory": [KEY_I, KEY_TAB],
	}
	for action in defs.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in defs[action]:
			var ev := InputEventKey.new()
			ev.keycode = key
			InputMap.action_add_event(action, ev)
	# ui_accept exists by default; fine.

func _clear() -> void:
	if is_instance_valid(current):
		current.queue_free()
	current = null

func _show_menu() -> void:
	_clear()
	var menu: Node = load("res://scripts/menu/main_menu.gd").new()
	current = menu
	add_child(menu)

func start_game(new_game: bool) -> void:
	_clear()
	var game: Node = load("res://scripts/game/game.gd").new()
	current = game
	game.main = self
	game.new_game = new_game
	add_child(game)

func show_menu() -> void:
	_show_menu()

func show_ending(which: String) -> void:
	_clear()
	var e: Node = load("res://scripts/endings/ending.gd").new()
	current = e
	e.which = which
	add_child(e)
