extends Interactable
class_name PickupObj
## Collectible item in the world.

var item_id: String = ""
var _t := 0.0

func _ready() -> void:
        prompt = Fa.PROMPT["take"]
        add_to_group("pickups")
        # make the pickup visible to the player's interact ray (mask = layer 3)
        collision_layer = 4
        collision_mask = 0
        var cs := CollisionShape3D.new()
        var sp := SphereShape3D.new()
        sp.radius = 0.34
        cs.shape = sp
        cs.position = Vector3(0, 0.22, 0)
        add_child(cs)
        _build_visual()

func _build_visual() -> void:
        var mesh_node := MeshInstance3D.new()
        var icons := {
                "brass_key": "res://assets/textures/icon_key.png",
                "fuse": "res://assets/textures/icon_fuse.png",
                "photo": "res://assets/textures/icon_photo.png",
                "valve_handle": "res://assets/textures/icon_valve.png",
                "cassette": "res://assets/textures/icon_cassette.png",
                "symbols_paper": "res://assets/textures/icon_paper.png",
                "passage_key": "res://assets/textures/icon_key.png",
                "note_letter": "res://assets/textures/icon_note.png",
        }
        var tex_path: String = icons.get(item_id, "res://assets/textures/icon_note.png")
        var mat := StandardMaterial3D.new()
        mat.albedo_texture = load(tex_path)
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        mat.cull_mode = BaseMaterial3D.CULL_DISABLED
        mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
        var quad := QuadMesh.new()
        quad.size = Vector2(0.34, 0.34)
        mesh_node.mesh = quad
        mesh_node.material_override = mat
        mesh_node.position.y = 0.22
        add_child(mesh_node)
        # soft glow ring
        var ring := MeshInstance3D.new()
        var tm := TorusMesh.new()
        tm.inner_radius = 0.18
        tm.outer_radius = 0.21
        var rmat := StandardMaterial3D.new()
        rmat.albedo_color = Color(0.35, 0.85, 0.9, 0.35)
        rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        ring.mesh = tm
        ring.material_override = rmat
        ring.position.y = 0.04
        add_child(ring)

func _process(delta: float) -> void:
        # differential bobbing: works no matter when the position is set from outside
        var prev := _t
        _t += delta
        position.y += (sin(_t * 2.2) - sin(prev * 2.2)) * 0.03

func can_interact() -> bool:
        return enabled

func interact(_player: Node) -> void:
        if item_id == "":
                return
        GameState.add_item(item_id)
        AudioMgr.play_sfx("res://assets/audio/sfx/pickup.wav", -2.0)
        var item_name: String = Fa.ITEMS.get(item_id, {}).get("name", item_id)
        EventBus.toast.emit(Fa.MSG["item_take"] + item_name, 2.5)
        if item_id == "cassette":
                Horror.slam(get_parent(), global_position + Vector3(0, 1, 0))
        if item_id == "symbols_paper":
                GameState.set_flag("has_symbols")
        queue_free()
