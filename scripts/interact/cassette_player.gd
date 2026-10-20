extends Interactable
class_name CassettePlayer
## Grandmother's cassette player — the story core of chapter 3.

var played: bool = false

func _ready() -> void:
        prompt = Fa.PROMPT["listen"]

func can_interact() -> bool:
        return enabled

func interact(_player: Node) -> void:
        if not GameState.has_item("cassette"):
                EventBus.toast.emit(Fa.MSG["need_cassette"], 3.0)
                AudioMgr.play_sfx("res://assets/audio/sfx/click.wav", -6.0)
                return
        if played:
                var rp: Control = load("res://scripts/ui/inspect.gd").new()
                rp.fill(Fa.NOTES["cassette_text"]["body"], Fa.NOTES["cassette_text"]["title"])
                get_viewport().add_child(rp)
                return
        played = true
        GameState.set_flag("cassette_played")
        AudioMgr.play_sfx("res://assets/audio/sfx/cassette_start.wav", 0.0)
        # grandmother's recorded voice (tape-filtered Persian speech)
        AudioMgr.play_sfx_3d("res://assets/audio/sfx/cassette_voice.ogg", get_parent(), global_position, 4.0, 14.0)
        # story sequence: sound -> text with typewriter
        await get_tree().create_timer(1.6).timeout
        var panel: Control = load("res://scripts/ui/inspect.gd").new()
        panel.fill(Fa.NOTES["cassette_text"]["body"], Fa.NOTES["cassette_text"]["title"])
        get_viewport().add_child(panel)
        Horror.cue_discover()
        GameState.set_chapter(4)
        GameState.set_objective(Fa.OBJ["c4_fuse"])
        # subtle horror: knocking starts after cassette
        await get_tree().create_timer(6.0).timeout
        var world := get_tree().get_first_node_in_group("world_root")
        if world != null:
                Horror.knock_3(world, global_position + Vector3(1.5, 1.2, -1.0), 4.0)
                EventBus.toast.emit(Fa.MSG["knock_wall"], 3.5)
