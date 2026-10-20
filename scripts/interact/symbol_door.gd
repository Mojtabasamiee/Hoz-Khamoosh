extends Interactable
class_name SymbolDoor
## Sealed stone door in basement — puzzle 5 (symbols).

var solved: bool = false

func _ready() -> void:
	prompt = Fa.PROMPT["use"]

func can_interact() -> bool:
	return enabled and not solved

func interact(_player: Node) -> void:
	if not GameState.has_item("symbols_paper") and not GameState.get_flag("read_study_files"):
		EventBus.toast.emit("سنگ‌ها نشانه‌هایی دارند... سرنخی لازم است.", 3.0)
	var ui: Control = load("res://scripts/puzzles/symbols_ui.gd").new()
	get_viewport().add_child(ui)

func open_door() -> void:
	if solved:
		return
	solved = true
	enabled = false
	AudioMgr.play_sfx_3d("res://assets/audio/sfx/stone_open.wav", get_parent(), global_position, 6.0, 30.0)
	var panel := get_node_or_null("Panel")
	if panel != null:
		var tw := create_tween()
		tw.tween_property(panel, "position:y", panel.position.y - 2.4, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var col := get_node_or_null("PanelCol")
		if col != null:
			col.get_child(0).set("disabled", true)
