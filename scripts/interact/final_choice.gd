extends Interactable
class_name FinalChoice
## Final chamber objects: passage key (Ending A), pool gaze (Ending B), exit door.

var mode: String = "key"  # "key" | "pool" | "exit"

func _ready() -> void:
        prompt = Fa.PROMPT["take"] if mode == "key" else Fa.PROMPT["look"]

func can_interact() -> bool:
        return enabled

func interact(_player: Node) -> void:
        var game = get_tree().get_first_node_in_group("game_root")
        if mode == "key":
                if GameState.has_item("passage_key"):
                        return
                GameState.add_item("passage_key")
                AudioMgr.play_sfx("res://assets/audio/sfx/pickup.wav", 0.0)
                GameState.set_flag("has_passage_key")
                EventBus.toast.emit("کلید گذرگاه را برداشتی. راه، باز است.", 3.5)
                GameState.set_objective(Fa.OBJ["c7_decide"])
                if game != null:
                        game.call("spawn_passage_door")
        else:
                # Ending B: gaze into the pool after midnight
                if game != null:
                        game.call("choose_ending", "B")

func try_exit() -> void:
        if GameState.has_item("passage_key"):
                var game := get_tree().get_first_node_in_group("game_root")
                if game != null:
                        game.call("choose_ending", "A")
        else:
                EventBus.toast.emit("درِ گذرگاه قفل است. کلیدش روی میز سنگی است.", 3.0)
                AudioMgr.play_sfx_3d("res://assets/audio/sfx/door_locked.wav", get_parent(), global_position, 1.0)
