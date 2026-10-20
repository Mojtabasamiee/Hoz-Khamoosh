extends Interactable
class_name LockedDoorMsg
## Non-passable door that only shows a contextual Persian message.

var msg: String = "در باز نمی‌شود."

func _ready() -> void:
        prompt = Fa.PROMPT["open"]

func can_interact() -> bool:
        return enabled

func interact(_player: Node) -> void:
        if has_meta("exit"):
                try_exit()
                return
        AudioMgr.play_sfx_3d("res://assets/audio/sfx/door_locked.wav", get_parent(), global_position, 1.0)
        EventBus.toast.emit(msg, 2.5)

func try_exit() -> void:
        if GameState.has_item("passage_key"):
                var world := get_tree().get_first_node_in_group("world_root")
                # route through game root for ending logic
                var game := get_tree().get_first_node_in_group("game_root")
                if game != null:
                        game.call("choose_ending", "A")
        else:
                EventBus.toast.emit("درِ گذرگاه قفل است. کلیدش روی میز سنگی است.", 3.0)
