extends StaticBody3D
class_name Interactable
## Base class for all interactable objects.

@export var prompt: String = "بررسی"
@export var enabled: bool = true

func can_interact() -> bool:
	return enabled

func interact(_player: Node) -> void:
	pass

func set_prompt(p: String) -> void:
	prompt = p
