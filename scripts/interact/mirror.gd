extends Interactable
class_name MirrorObj
## Bathroom mirror — timed scripted scare (subtle).

func _ready() -> void:
	prompt = Fa.PROMPT["look"]

func can_interact() -> bool:
	return enabled

func interact(_player: Node) -> void:
	if GameState.get_flag("power_on") and not GameState.get_flag("mirror_done"):
		GameState.set_flag("mirror_done")
		Horror.drop_ambient(2.2)
		AudioMgr.play_sfx("res://assets/audio/sfx/water_freeze.wav", -4.0)
		await get_tree().create_timer(0.9).timeout
		EventBus.toast.emit(Fa.MSG["bat_cold"], 3.0)
		Horror.whisper(get_parent(), global_position + Vector3(0, 0.4, -0.8))
		var world := get_tree().get_first_node_in_group("world_root")
		if world != null:
			world.call_deferred("mirror_scare", global_position)
	else:
		AudioMgr.play_sfx("res://assets/audio/sfx/paper.wav", -8.0)
		EventBus.toast.emit("آینه‌ات را می‌بینی؛ همین.", 2.0)
