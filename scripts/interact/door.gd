extends Interactable
class_name DoorObj
## Hinged wooden door with locked states.

signal opened
signal closed

var pivot: Node3D
var locked: bool = false
var locked_msg: String = ""
var open: bool = false
var is_open_angle: float = -100.0
var closed_angle: float = 0.0
var busy: bool = false
var auto_lock_on_close: bool = false
var key_item: String = ""  # if set: unlocks automatically when player holds it

func setup(p_pivot: Node3D, p_locked: bool = false, p_msg: String = "") -> void:
        pivot = p_pivot
        locked = p_locked
        locked_msg = p_msg
        prompt = Fa.PROMPT["open"]

func can_interact() -> bool:
        return enabled and not busy

func interact(_player: Node) -> void:
        if locked:
                if key_item != "" and GameState.has_item(key_item):
                        unlock()
                        GameEventAfterUnlock()
                        toggle()
                        return
                AudioMgr.play_sfx_3d("res://assets/audio/sfx/door_locked.wav", get_parent(), global_position, 2.0)
                if locked_msg != "":
                        EventBus.toast.emit(locked_msg, 3.0)
                return
        toggle()

func GameEventAfterUnlock() -> void:
        pass

func toggle() -> void:
        if busy:
                return
        busy = true
        var target := closed_angle if open else deg_to_rad(is_open_angle)
        var snd := "res://assets/audio/sfx/door_close.wav" if open else "res://assets/audio/sfx/door_open.wav"
        AudioMgr.play_sfx_3d(snd, get_parent(), global_position, 0.0, 20.0)
        var tw := create_tween()
        tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
        tw.tween_property(pivot, "rotation:y", target, 0.9)
        await tw.finished
        open = not open
        busy = false
        prompt = Fa.PROMPT["open"]
        if open:
                opened.emit()
                if auto_lock_on_close:
                        pass
        else:
                closed.emit()
                if auto_lock_on_close:
                        locked = true
                        locked_msg = Fa.MSG["door_stuck"]

func force_close_and_lock() -> void:
        if open:
                var tw := create_tween()
                tw.tween_property(pivot, "rotation:y", closed_angle, 0.5)
                await tw.finished
                open = false
        locked = true
        locked_msg = Fa.MSG["door_stuck"]
        enabled = false

func set_open_state(o: bool, instant: bool = true) -> void:
        open = o
        if pivot != null:
                pivot.rotation.y = deg_to_rad(is_open_angle) if o else closed_angle
        if not o:
                prompt = Fa.PROMPT["open"]

func is_locked() -> bool:
        return locked

func unlock() -> void:
        locked = false
        enabled = true
        locked_msg = ""
        AudioMgr.play_sfx_3d("res://assets/audio/sfx/unlock.wav", get_parent(), global_position, 2.0)
