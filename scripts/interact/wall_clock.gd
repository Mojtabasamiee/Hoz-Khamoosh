extends Interactable
class_name WallClock
## Old wall clock — puzzle 3. Opens clock UI.

var solved: bool = false

func _ready() -> void:
	prompt = Fa.PROMPT["use"]

func can_interact() -> bool:
	return enabled and not solved

func interact(_player: Node) -> void:
	var ui: Control = load("res://scripts/puzzles/clock_ui.gd").new()
	get_viewport().add_child(ui)

func mark_solved() -> void:
	solved = true
	enabled = false
