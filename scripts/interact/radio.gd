extends Interactable
class_name RadioObj
## Old radio: dead until power, then static, then a Persian phrase.

enum State { OFF, STATIC, PHRASE, DONE }
var state: int = State.OFF
var static_player: AudioStreamPlayer3D

func _ready() -> void:
        prompt = Fa.PROMPT["use"]

func can_interact() -> bool:
        return enabled

func interact(_player: Node) -> void:
        match state:
                State.OFF:
                        if not GameState.get_flag("power_on"):
                                AudioMgr.play_sfx("res://assets/audio/sfx/click.wav", -4.0)
                                EventBus.toast.emit(Fa.MSG["radio_dead"], 3.0)
                        else:
                                _enter_static()
                State.STATIC:
                        _play_phrase()
                State.PHRASE, State.DONE:
                        _stop_all()
                        state = State.OFF if not GameState.get_flag("power_on") else State.STATIC
                        prompt = Fa.PROMPT["use"]

func _enter_static() -> void:
        state = State.STATIC
        prompt = Fa.PROMPT["listen"]
        AudioMgr.play_sfx("res://assets/audio/sfx/radio_tune.wav", -6.0)
        if static_player == null:
                static_player = AudioStreamPlayer3D.new()
                static_player.stream = load("res://assets/audio/sfx/radio_static.ogg")
                static_player.bus = AudioMgr.BUS_SFX
                static_player.unit_size = 5.0
                static_player.max_distance = 14.0
                static_player.volume_db = -6.0
                add_child(static_player)
        if static_player.stream is AudioStreamWAV:
                static_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
                static_player.stream.loop_end = static_player.stream.data.size() / 2
        elif static_player.stream is AudioStreamOggVorbis:
                static_player.stream.loop = true
        static_player.play()

func _play_phrase() -> void:
        if static_player != null:
                static_player.stop()
        AudioMgr.play_sfx_3d("res://assets/audio/sfx/radio_phrase.ogg", get_parent(), global_position, 3.0, 16.0)
        state = State.PHRASE
        prompt = Fa.PROMPT["use"]
        var panel: Control = load("res://scripts/ui/inspect.gd").new()
        panel.fill(Fa.NOTES["radio_phrase"]["body"], Fa.NOTES["radio_phrase"]["title"])
        get_viewport().add_child(panel)
        Horror.cue_event()
        get_tree().create_timer(9.0).timeout.connect(func():
                if state == State.PHRASE:
                        state = State.DONE)

func _stop_all() -> void:
        if static_player != null and static_player.playing:
                static_player.stop()
