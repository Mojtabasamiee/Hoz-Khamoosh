extends Interactable
class_name Telephone
## Study telephone — rings once after power; creepy optional clue.

func _ready() -> void:
	prompt = Fa.PROMPT["listen"]

func can_interact() -> bool:
	return enabled

func interact(_player: Node) -> void:
	enabled = false
	AudioMgr.play_sfx("res://assets/audio/sfx/radio_tune.wav", -8.0)
	var panel: Control = load("res://scripts/ui/inspect.gd").new()
	panel.fill(Fa.NOTES["phone_note"]["body"], Fa.NOTES["phone_note"]["title"])
	get_viewport().add_child(panel)
	Horror.drop_ambient(1.8)
