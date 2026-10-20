extends Control
## Fusebox puzzle UI — insert the new fuse into the CORRECT slot (top-right).

var _done := false

func _ready() -> void:
	GameState.set_ui_open(true)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := UIH.panel()
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	vb.add_child(UIH.centered_label("جعبه فیوز", 28, UIH.COL_ACCENT, true))
	var instr := UIH.centered_label("یادداشت: «فیوز سوخته همیشه بالا-راست می‌سوزه.»", 17, UIH.COL_DIM)
	vb.add_child(instr)
	vb.add_child(UIH.vspace(8))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	vb.add_child(grid)

	# slots: 0 top-left, 1 top-right(correct), 2 bottom-left, 3 bottom-right
	var slots := {}
	for i in 4:
		var b := UIH.button("جای فیوز " + Fa.to_fa_num(str(i + 1)), 18, 240)
		slots[i] = b
		b.pressed.connect(func(): _try_slot(i, slots))
		grid.add_child(b)

	vb.add_child(UIH.vspace(8))
	var close := UIH.button(Fa.UI["close"], 18, 160)
	close.pressed.connect(func():
		GameState.set_ui_open(false)
		queue_free())
	vb.add_child(close)

func _try_slot(i: int, slots: Dictionary) -> void:
	if _done:
		return
	if i == 1:
		_done = true
		AudioMgr.play_sfx("res://assets/audio/sfx/fuse_spark.wav", 0.0)
		GameState.remove_item("fuse")
		GameState.set_flag("power_on")
		slots[i].text = "✓ روشن"
		slots[i].modulate = Color(0.6, 1.0, 0.7)
		await get_tree().create_timer(1.1).timeout
		GameState.set_ui_open(false)
		EventBus.power_on.emit()
		queue_free()
	else:
		AudioMgr.play_sfx("res://assets/audio/sfx/fuse_fail.wav", -2.0)
		EventBus.toast.emit("جرقه! فیوز دوباره سوخت. جای درستی نیست.", 2.5)
		slots[i].modulate = Color(1, 0.5, 0.45)
		var tw := create_tween()
		tw.tween_interval(0.8)
		tw.tween_callback(func(): slots[i].modulate = Color(1, 1, 1))
