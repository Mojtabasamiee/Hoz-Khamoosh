extends Interactable
class_name ValveObj
## Water valve — part of puzzle 4 sequence (2 -> 3 -> 1).

var valve_id: int = 1
var needs_handle: bool = false
var wheel: Node3D
var turned: bool = false

func _ready() -> void:
	prompt = Fa.PROMPT["turn"]

func can_interact() -> bool:
	return enabled and not turned

func interact(_player: Node) -> void:
	if needs_handle and not GameState.get_flag("handle_installed_" + str(valve_id)):
		if GameState.has_item("valve_handle"):
			GameState.remove_item("valve_handle")
			GameState.set_flag("handle_installed_" + str(valve_id))
			AudioMgr.play_sfx_3d("res://assets/audio/sfx/unlock.wav", get_parent(), global_position, 0.0)
			EventBus.toast.emit("دسته را نصب کردی.", 2.5)
			return
		else:
			EventBus.toast.emit(Fa.MSG["need_handle"], 2.5)
			AudioMgr.play_sfx("res://assets/audio/sfx/click.wav", -6.0)
			return
	if turned:
		return
	turned = true
	enabled = false
	AudioMgr.play_sfx_3d("res://assets/audio/sfx/valve_turn.wav", get_parent(), global_position, 2.0)
	if wheel != null:
		var tw := create_tween()
		tw.tween_property(wheel, "rotation:z", wheel.rotation.z + TAU * 2.5, 1.4).set_trans(Tween.TRANS_SINE)
	var world := get_tree().get_first_node_in_group("world_root")
	if world != null:
		world.on_valve_turned(valve_id)

func set_turned(t: bool) -> void:
	turned = t
	enabled = not t
	if t and wheel != null:
		wheel.rotation.z = TAU * 2.5
