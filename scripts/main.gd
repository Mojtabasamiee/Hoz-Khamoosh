extends Node
## Main — bootstraps input map and screen switching (menu <-> game <-> endings),
## with loading screens over every heavy transition.

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

func _loader(title: String, sub: String = "") -> CanvasLayer:
        var ls: CanvasLayer = load("res://scripts/ui/loading_screen.gd").new()
        ls.setup(title, sub)
        get_viewport().add_child(ls)
        # let the loader actually paint before the heavy work blocks the main thread
        await get_tree().process_frame
        await get_tree().process_frame
        return ls

func _clear() -> void:
        if is_instance_valid(current):
                current.queue_free()
        current = null

func _show_menu() -> void:
        _clear()
        await _loader(Fa.GAME_TITLE, "در حال آماده‌سازی خانه...")
        var menu: Node = load("res://scripts/menu/main_menu.gd").new()
        current = menu
        add_child(menu)
        # keep the loader at least a moment so it does not flash
        await get_tree().create_timer(0.7).timeout
        # close via the instance we created (find by script)
        for c in get_viewport().get_children():
                if c is CanvasLayer and c.layer == 30:
                        c.close(0.3)

func start_game(new_game: bool) -> void:
        _clear()
        var tip: String = Fa.LOAD_TIPS[randi() % Fa.LOAD_TIPS.size()]
        await _loader(Fa.UI["loading"], "« " + tip + " »")
        var game: Node = load("res://scripts/game/game.gd").new()
        current = game
        game.main = self
        game.new_game = new_game
        add_child(game)
        # house build is heavy (synchronous); loader stays visible above it
        await get_tree().create_timer(0.9).timeout
        for c in get_viewport().get_children():
                if c is CanvasLayer and c.layer == 30:
                        c.close(0.3)

func show_menu() -> void:
        _show_menu()

func show_ending(which: String) -> void:
        _clear()
        var tip: String = Fa.LOAD_TIPS[randi() % Fa.LOAD_TIPS.size()]
        await _loader("پایان", "« " + tip + " »")
        var e: Node = load("res://scripts/endings/ending.gd").new()
        current = e
        e.which = which
        add_child(e)
        await get_tree().create_timer(0.8).timeout
        for c in get_viewport().get_children():
                if c is CanvasLayer and c.layer == 30:
                        c.close(0.4)
