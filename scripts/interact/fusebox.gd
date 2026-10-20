extends Interactable
class_name Fusebox
## Electrical panel — puzzle 1 entry.

func _ready() -> void:
	prompt = Fa.PROMPT["use"]

func can_interact() -> bool:
	return enabled and not GameState.get_flag("power_on")

func interact(_player: Node) -> void:
	if GameState.has_item("fuse"):
		var ui: Control = load("res://scripts/puzzles/fusebox_ui.gd").new()
		get_viewport().add_child(ui)
	else:
		EventBus.toast.emit(Fa.MSG["need_fuse"], 3.0)
		AudioMgr.play_sfx("res://assets/audio/sfx/click.wav", -6.0)
