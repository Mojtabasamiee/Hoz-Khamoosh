extends Control
## MainMenu — cinematic courtyard background + Persian title + buttons.

var world: Node3D
var cam: Camera3D
var _t := 0.0
var _overlay_shown := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# ----- 3D background world -----
	world = load("res://scripts/game/house_builder.gd").new()
	world.add_to_group("world_root")
	add_child(world)
	world.call_deferred("build", true)

	cam = Camera3D.new()
	cam.fov = 60.0
	world.add_child(cam)
	cam.make_current()

	# ambient: rain + wind + pool
	AudioMgr.start_ambient("rain", "res://assets/audio/ambience/rain_loop.ogg", -8.0)
	AudioMgr.start_ambient("wind", "res://assets/audio/ambience/wind_loop.ogg", -14.0)
	AudioMgr.start_ambient("pool", "res://assets/audio/ambience/pool_water.ogg", -12.0)
	AudioMgr.play_music("res://assets/audio/music/menu_theme.ogg", 3.0)

	_build_ui()

func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.0, 0.01, 0.02, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 12)
	add_child(vb)

	var t1 := UIH.centered_label(Fa.GAME_TITLE, 76, Color(0.72, 0.94, 0.97), true)
	var t2 := UIH.centered_label(Fa.GAME_TITLE_EN, 22, UIH.COL_DIM)
	var t3 := UIH.centered_label(Fa.DEV_NAME, 15, Color(0.5, 0.55, 0.55))
	vb.add_child(t1)
	vb.add_child(t2)
	vb.add_child(UIH.vspace(26))

	var cc := CenterContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	cc.add_child(box)
	vb.add_child(cc)

	var b_start := UIH.button(Fa.UI["start"], 24)
	b_start.pressed.connect(func(): main().start_game(true))
	box.add_child(b_start)

	var b_cont := UIH.button(Fa.UI["continue"], 22)
	if not SaveSys.has_save():
		b_cont.disabled = true
		b_cont.modulate = Color(1, 1, 1, 0.35)
	b_cont.pressed.connect(func(): main().start_game(false))
	box.add_child(b_cont)

	var b_set := UIH.button(Fa.UI["settings"], 22)
	b_set.pressed.connect(func():
		var s: Control = load("res://scripts/menu/settings_menu.gd").new()
		add_child(s))
	box.add_child(b_set)

	var b_about := UIH.button(Fa.UI["about"], 22)
	b_about.pressed.connect(func(): _show_about())
	box.add_child(b_about)

	if OS.has_feature("android"):
		pass  # no Quit button on Android
	else:
		var b_quit := UIH.button(Fa.UI["quit"], 22)
		b_quit.pressed.connect(func(): get_tree().quit())
		box.add_child(b_quit)

	vb.add_child(UIH.vspace(20))
	vb.add_child(t3)
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 1.4)

func main() -> Node:
	return get_parent()

func _show_about() -> void:
	var s: Control = load("res://scripts/ui/inspect.gd").new()
	s.fill(Fa.UI["about_body"], Fa.UI["about"])
	add_child(s)

func _process(delta: float) -> void:
	_t += delta
	if cam != null and world != null:
		# slow cinematic drift over courtyard
		var r := 6.4
		var x := sin(_t * 0.045) * r
		var z := cos(_t * 0.045) * r
		cam.global_position = Vector3(x, 2.1 + sin(_t * 0.09) * 0.25, z)
		var look := Vector3(sin(_t * 0.02) * 1.2, 0.6, cos(_t * 0.017) * 0.8)
		cam.look_at(look, Vector3.UP)
