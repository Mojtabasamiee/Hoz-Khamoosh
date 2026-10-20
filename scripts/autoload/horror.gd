extends Node
## Horror — scripted horror event helpers (audio-centric, no cheap repeats).

var _busy: Dictionary = {}

func knock_3(world: Node, pos: Vector3, volume_db: float = 3.0) -> void:
	AudioMgr.play_sfx_3d("res://assets/audio/sfx/knock_3.wav", world, pos, volume_db, 26.0)

func whisper(world: Node, pos: Vector3) -> void:
	AudioMgr.play_sfx_3d("res://assets/audio/sfx/whisper.wav", world, pos, 4.0, 20.0)

func metal_clank(world: Node, pos: Vector3) -> void:
	AudioMgr.play_sfx_3d("res://assets/audio/sfx/metal_clank.wav", world, pos, 2.0, 30.0)

func slam(world: Node, pos: Vector3) -> void:
	AudioMgr.play_sfx_3d("res://assets/audio/sfx/door_slam.wav", world, pos, 6.0, 30.0)

## Briefly silence ambience, then bring it back — "sudden drop" effect.
func drop_ambient(seconds: float = 2.5) -> void:
	AudioMgr.duck_ambient(seconds)

## Flashlight flicker via callback provided by owner.
func flicker(node: CanvasItem) -> void:
	if node == null or _busy.has("flick"):
		return
	_busy["flick"] = true
	var tw := node.create_tween()
	for i in 5:
		tw.tween_property(node, "modulate:a", 0.25, 0.05)
		tw.tween_property(node, "modulate:a", 1.0, 0.05)
	tw.tween_callback(func(): _busy.erase("flick"))

func light_flicker(light: Light3D, times: int = 4) -> void:
	if light == null:
		return
	var tw := light.create_tween()
	for i in times:
		tw.tween_property(light, "light_energy", 0.05, randf_range(0.03, 0.09))
		tw.tween_property(light, "light_energy", light.get_meta("base_energy", 1.0), randf_range(0.03, 0.09))

func cue_discover() -> void:
	AudioMgr.play_music("res://assets/audio/music/cue_discover.ogg", 0.6)
	# after cue, restore menu/ambient silence (music bus only played this cue)
	get_tree().create_timer(6.5).timeout.connect(func():
		if AudioMgr.current_music.begins_with("res://assets/audio/music/cue_"):
			AudioMgr.stop_music(1.5))

func cue_event() -> void:
	AudioMgr.play_music("res://assets/audio/music/cue_event.ogg", 0.4)
	get_tree().create_timer(7.5).timeout.connect(func():
		if AudioMgr.current_music.begins_with("res://assets/audio/music/cue_"):
			AudioMgr.stop_music(1.5))
