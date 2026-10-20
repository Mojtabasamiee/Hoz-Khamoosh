extends Node
## AudioMgr — buses, SFX pools, 3D SFX, music crossfade, ambient loops, settings.

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const BUS_AMB := "Ambient"

var _sfx_pool: Array = []
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_current: AudioStreamPlayer
var _amb_players: Dictionary = {}
var _settings: ConfigFile
var _stream_cache: Dictionary = {}
var current_music: String = ""

func _ready() -> void:
        process_mode = Node.PROCESS_MODE_ALWAYS
        _make_bus(BUS_MUSIC)
        _make_bus(BUS_SFX)
        _make_bus(BUS_AMB)
        for i in 10:
                var p := AudioStreamPlayer.new()
                p.bus = BUS_SFX
                add_child(p)
                _sfx_pool.append(p)
        _music_a = AudioStreamPlayer.new()
        _music_b = AudioStreamPlayer.new()
        for m in [_music_a, _music_b]:
                m.bus = BUS_MUSIC
                add_child(m)
        _music_current = _music_a
        _load_settings()

func _make_bus(name: String) -> void:
        if AudioServer.get_bus_index(name) == -1:
                var idx := AudioServer.bus_count
                AudioServer.add_bus(idx)
                AudioServer.set_bus_name(idx, name)
                AudioServer.set_bus_send(idx, BUS_MASTER)

# ---------- streams ----------
func _stream(path: String) -> AudioStream:
        if _stream_cache.has(path):
                return _stream_cache[path]
        if not ResourceLoader.exists(path):
                push_warning("Missing audio: " + path)
                return null
        var s: AudioStream = load(path)
        _stream_cache[path] = s
        return s

func _looped(path: String) -> AudioStream:
        var s := _stream(path)
        if s == null:
                return null
        var key := path + "::loop"
        if _stream_cache.has(key):
                return _stream_cache[key]
        var dup: AudioStream = s.duplicate()
        if dup is AudioStreamWAV:
                dup.loop_mode = AudioStreamWAV.LOOP_FORWARD
                dup.loop_begin = 0
                var frames := 0
                if dup.data.size() > 0:
                        frames = dup.data.size() / 2  # 16-bit mono
                dup.loop_end = frames
        elif dup is AudioStreamOggVorbis:
                dup.loop = true
        _stream_cache[key] = dup
        return dup

# ---------- SFX ----------
func play_sfx(path: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
        var s := _stream(path)
        if s == null:
                return
        for p in _sfx_pool:
                if not p.playing:
                        p.stream = s
                        p.volume_db = volume_db
                        p.pitch_scale = pitch
                        p.play()
                        return
        # all busy: steal first
        _sfx_pool[0].stream = s
        _sfx_pool[0].volume_db = volume_db
        _sfx_pool[0].pitch_scale = pitch
        _sfx_pool[0].play()

func play_sfx_3d(path: String, parent: Node, pos: Vector3, volume_db: float = 0.0, max_m: float = 18.0, pitch: float = 1.0) -> void:
        var s := _stream(path)
        if s == null or parent == null:
                return
        var p := AudioStreamPlayer3D.new()
        p.stream = s
        p.bus = BUS_SFX
        p.volume_db = volume_db
        p.max_distance = max_m
        p.unit_size = 6.0
        p.pitch_scale = pitch
        p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
        parent.add_child(p)
        p.global_position = pos
        p.play()
        p.finished.connect(p.queue_free)

# ---------- Music ----------
func play_music(path: String, fade: float = 2.0) -> void:
        if current_music == path and _music_current.playing:
                return
        current_music = path
        var s := _looped(path)
        if s == null:
                return
        var old := _music_current
        var nxt := _music_b if _music_current == _music_a else _music_a
        _music_current = nxt
        nxt.stream = s
        nxt.volume_db = -40.0
        nxt.play()
        var tw := nxt.create_tween()
        tw.tween_property(nxt, "volume_db", 0.0, fade)
        if old.playing:
                var tw2 := old.create_tween()
                tw2.tween_property(old, "volume_db", -40.0, fade)
                tw2.tween_callback(old.stop)

func stop_music(fade: float = 1.5) -> void:
        current_music = ""
        for m in [_music_a, _music_b]:
                if m.playing:
                        var tw: Tween = m.create_tween()
                        tw.tween_property(m, "volume_db", -40.0, fade)
                        tw.tween_callback(m.stop)

# ---------- Ambience ----------
func start_ambient(id: String, path: String, volume_db: float = 0.0) -> void:
        if _amb_players.has(id):
                return
        var s := _looped(path)
        if s == null:
                return
        var p := AudioStreamPlayer.new()
        p.stream = s
        p.bus = BUS_AMB
        p.volume_db = volume_db
        add_child(p)
        p.play()
        _amb_players[id] = p

func stop_ambient(id: String, fade: float = 0.8) -> void:
        if not _amb_players.has(id):
                return
        var p: AudioStreamPlayer = _amb_players[id]
        _amb_players.erase(id)
        var tw := p.create_tween()
        tw.tween_property(p, "volume_db", -50.0, fade)
        tw.tween_callback(p.queue_free)

func duck_ambient(seconds: float) -> void:
        var idx := AudioServer.get_bus_index(BUS_AMB)
        if idx == -1:
                return
        var old_db := AudioServer.get_bus_volume_db(idx)
        AudioServer.set_bus_volume_db(idx, -38.0)
        var t := get_tree().create_timer(seconds)
        t.timeout.connect(func():
                if AudioServer.get_bus_index(BUS_AMB) != -1 and not _amb_players.is_empty():
                        AudioServer.set_bus_volume_db(idx, old_db))

# ---------- Volumes ----------
func set_bus_linear(bus: String, linear: float) -> void:
        var idx := AudioServer.get_bus_index(bus)
        if idx == -1:
                return
        AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0001, 1.0)))
        AudioServer.set_bus_mute(idx, linear <= 0.001)
        save_settings()

func get_bus_linear(bus: String) -> float:
        var idx := AudioServer.get_bus_index(bus)
        if idx == -1:
                return 1.0
        if AudioServer.is_bus_mute(idx):
                return 0.0
        return db_to_linear(AudioServer.get_bus_volume_db(idx))

# ---------- Settings persistence ----------
func _load_settings() -> void:
        _settings = ConfigFile.new()
        _settings.load("user://settings.cfg")
        var m := float(_settings.get_value("audio", "master", 0.9))
        var mu := float(_settings.get_value("audio", "music", 0.9))
        var sf := float(_settings.get_value("audio", "sfx", 1.0))
        var ab := float(_settings.get_value("audio", "ambient", 1.0))
        var idx := AudioServer.get_bus_index(BUS_MASTER)
        if idx != -1:
                AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(m, 0.0001, 1.0)))
                AudioServer.set_bus_mute(idx, m <= 0.001)
        idx = AudioServer.get_bus_index(BUS_MUSIC)
        if idx != -1:
                AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(mu, 0.0001, 1.0)))
                AudioServer.set_bus_mute(idx, mu <= 0.001)
        idx = AudioServer.get_bus_index(BUS_SFX)
        if idx != -1:
                AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(sf, 0.0001, 1.0)))
                AudioServer.set_bus_mute(idx, sf <= 0.001)
        idx = AudioServer.get_bus_index(BUS_AMB)
        if idx != -1:
                AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(ab, 0.0001, 1.0)))
                AudioServer.set_bus_mute(idx, ab <= 0.001)

func save_settings() -> void:
        _settings.set_value("audio", "master", get_bus_linear(BUS_MASTER))
        _settings.set_value("audio", "music", get_bus_linear(BUS_MUSIC))
        _settings.set_value("audio", "sfx", get_bus_linear(BUS_SFX))
        _settings.set_value("audio", "ambient", get_bus_linear(BUS_AMB))
        _settings.save("user://settings.cfg")

func set_setting(key: String, value) -> void:
        _settings.set_value("general", key, value)
        _settings.save("user://settings.cfg")

func get_setting(key: String, def):
        return _settings.get_value("general", key, def)
