extends Control
## SettingsMenu — reusable settings panel (menu + pause). Everything functional.

var on_closed: Callable = Callable()
var _sliders := {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := UIH.panel()
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(520, 0)
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	var title := UIH.centered_label(Fa.UI["settings"], 30, UIH.COL_ACCENT, true)
	vb.add_child(title)
	vb.add_child(UIH.vspace(6))

	_add_slider(vb, Fa.UI["master_vol"], AudioMgr.BUS_MASTER)
	_add_slider(vb, Fa.UI["music_vol"], AudioMgr.BUS_MUSIC)
	_add_slider(vb, Fa.UI["sfx_vol"], AudioMgr.BUS_SFX)
	_add_slider(vb, Fa.UI["amb_vol"], AudioMgr.BUS_AMB)

	vb.add_child(UIH.vspace(4))
	vb.add_child(_sep())

	# look sensitivity
	var sens_row := HBoxContainer.new()
	var sens_label := UIH.label(Fa.UI["sensitivity"], 20)
	sens_row.add_child(sens_label)
	var sens_val := UIH.label("1.0", 18, UIH.COL_ACCENT)
	var sens := HSlider.new()
	sens.min_value = 0.3
	sens.max_value = 3.0
	sens.step = 0.05
	sens.value = float(AudioMgr.get_setting("sensitivity", 1.0))
	sens.custom_minimum_size = Vector2(220, 24)
	sens.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sens.value_changed.connect(func(v):
		AudioMgr.set_setting("sensitivity", v)
		sens_val.text = "%.2f" % v)
	_sliders["sensitivity"] = sens
	sens_row.add_child(sens)
	sens_row.add_child(sens_val)
	vb.add_child(sens_row)

	# touch sensitivity
	var trow := HBoxContainer.new()
	trow.add_child(UIH.label(Fa.UI["touch_sens"], 20))
	var tval := UIH.label("1.0", 18, UIH.COL_ACCENT)
	var tsens := HSlider.new()
	tsens.min_value = 0.4
	tsens.max_value = 2.5
	tsens.step = 0.05
	tsens.value = float(AudioMgr.get_setting("touch_sens", 1.0))
	tsens.custom_minimum_size = Vector2(220, 24)
	tsens.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tsens.value_changed.connect(func(v):
		AudioMgr.set_setting("touch_sens", v)
		tval.text = "%.2f" % v)
	trow.add_child(tsens)
	trow.add_child(tval)
	vb.add_child(trow)

	# vibration toggle
	var vib := AudioMgr.get_setting("vibration", true)
	var vrow := HBoxContainer.new()
	vrow.add_child(UIH.label(Fa.UI["vibration"], 20))
	var vbtn := UIH.button((Fa.UI["on"] if vib else Fa.UI["off"]), 18, 120)
	vbtn.pressed.connect(func():
		var cur := bool(AudioMgr.get_setting("vibration", true))
		AudioMgr.set_setting("vibration", not cur)
		vbtn.text = Fa.UI["on"] if not cur else Fa.UI["off"])
	vrow.add_child(vbtn)
	vb.add_child(vrow)

	# graphics quality
	var grow := HBoxContainer.new()
	grow.add_child(UIH.label(Fa.UI["graphics"], 20))
	var q := int(AudioMgr.get_setting("quality", 1))
	var qbtns := {}
	for i in 3:
		var names := [Fa.UI["low"], Fa.UI["med"], Fa.UI["high"]]
		var b := UIH.button(names[i], 16, 90)
		qbtns[i] = b
		b.pressed.connect(func():
			AudioMgr.set_setting("quality", i)
			_apply_quality(i)
			for k in qbtns:
				qbtns[k].modulate = Color(0.55, 0.55, 0.55) if k != i else Color(1, 1, 1))
		if i != q:
			b.modulate = Color(0.55, 0.55, 0.55)
		grow.add_child(b)
	vb.add_child(grow)

	vb.add_child(UIH.vspace(10))
	var close := UIH.button(Fa.UI["back"], 20)
	close.pressed.connect(func():
		queue_free()
		if on_closed.is_valid():
			on_closed.call())
	vb.add_child(close)

func _sep() -> HSeparator:
	var s := HSeparator.new()
	return s

func _add_slider(parent: Control, text: String, bus: String) -> void:
	var row := HBoxContainer.new()
	row.add_child(UIH.label(text, 20))
	var val := UIH.label("%d%%" % int(AudioMgr.get_bus_linear(bus) * 100), 18, UIH.COL_ACCENT)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.01
	s.value = AudioMgr.get_bus_linear(bus)
	s.custom_minimum_size = Vector2(220, 24)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(func(v):
		AudioMgr.set_bus_linear(bus, v)
		val.text = "%d%%" % int(v * 100))
	row.add_child(s)
	row.add_child(val)
	parent.add_child(row)

func _apply_quality(q: int) -> void:
	var vp := get_viewport()
	if vp == null:
		return
	match q:
		0:
			vp.scaling_3d_scale = 0.7
		1:
			vp.scaling_3d_scale = 0.85
		2:
			vp.scaling_3d_scale = 1.0
	var world := get_tree().get_first_node_in_group("world_root")
	if world != null:
		world.call_deferred("apply_quality", q)
