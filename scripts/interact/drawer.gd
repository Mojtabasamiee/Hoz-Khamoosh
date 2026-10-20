extends Interactable
class_name DrawerObj
## Sliding drawer that can reveal a pickup inside.

var slide_mesh: Node3D
var slide_dist: float = 0.45
var is_open: bool = false
var item_id: String = ""
var item_pos: Vector3
var item_parent: Node3D
var pickup: Node3D
var code_locked: bool = false
var code_msg: String = ""

func setup(mesh: Node3D, dist: float, parent: Node3D, pos: Vector3, p_item: String = "") -> void:
        slide_mesh = mesh
        slide_dist = dist
        item_parent = parent
        item_pos = pos
        item_id = p_item
        prompt = Fa.PROMPT["open"]

func can_interact() -> bool:
        return enabled and not is_open

func interact(_player: Node) -> void:
        if code_locked:
                if GameState.get_flag("drawer_code_ok"):
                        code_locked = false
                        open()
                else:
                        var ui: Control = load("res://scripts/puzzles/code_ui.gd").new()
                        get_viewport().add_child(ui)
                return
        open()

func open() -> void:
        if is_open:
                return
        is_open = true
        enabled = false
        prompt = Fa.PROMPT["examine"]
        AudioMgr.play_sfx_3d("res://assets/audio/sfx/drawer_open.wav", item_parent, item_pos, 0.0)
        var tw := create_tween()
        tw.tween_property(slide_mesh, "position:z", slide_mesh.position.z + slide_dist, 0.7).set_trans(Tween.TRANS_SINE)
        await tw.finished
        if item_id != "":
                pickup = load("res://scripts/interact/pickup.gd").new()
                pickup.item_id = item_id
                item_parent.add_child(pickup)
                pickup.global_position = item_pos
                item_id = ""
        if has_meta("is_study"):
                EventBus.drawer_opened.emit()

func set_open(o: bool) -> void:
        is_open = o
        enabled = not o
        if slide_mesh != null:
                slide_mesh.position.z = slide_mesh.get_meta("base_z", slide_mesh.position.z) + (slide_dist if o else 0.0)
