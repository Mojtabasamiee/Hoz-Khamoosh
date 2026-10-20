extends Control
## Symbol door puzzle — 4 dials (پ م ص ف), correct order = photo years oldest->newest:
## ۱۳۴۸=پ ، ۱۳۵۷=م ، ۱۳۶۱=ص ، ۱۳۷۳=ف

const SYMS := ["پ", "م", "ص", "ف"]
const SOLUTION := [0, 1, 2, 3]  # indices into SYMS

var dials: Array = []
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
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)

	vb.add_child(UIH.centered_label("درِ سنگی — چهار نشانه", 28, UIH.COL_ACCENT, true))
	vb.add_child(UIH.centered_label("نشانه‌ها را به ترتیبِ سالِ عکس‌ها بچین (کهنه به نو).", 16, UIH.COL_DIM))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	for i in 4:
		var b := UIH.button(SYMS[0], 34, 100)
		b.custom_minimum_size = Vector2(100, 80)
		var idx := i
		b.pressed.connect(func():
			var cur: int = b.get_meta("v", 0)
			cur = (cur + 1) % SYMS.size()
			b.set_meta("v", cur)
			b.text = SYMS[cur]
			AudioMgr.play_sfx("res://assets/audio/sfx/click.wav", -6.0))
		row.add_child(b)
		dials.append(b)
	vb.add_child(row)

	vb.add_child(UIH.vspace(4))
	var row2 := HBoxContainer.new()
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	var ok := UIH.button("آزمودن", 20, 180)
	ok.pressed.connect(func(): _check())
	var close := UIH.button(Fa.UI["close"], 18, 140)
	close.pressed.connect(func():
		GameState.set_ui_open(false)
		queue_free())
	row2.add_child(ok)
	row2.add_child(close)
	vb.add_child(row2)

func _check() -> void:
	if _done:
		return
	var ok := true
	for i in 4:
		if int(dials[i].get_meta("v", 0)) != SOLUTION[i]:
			ok = false
	if ok:
		_done = true
		GameState.set_flag("symbols_solved")
		await get_tree().create_timer(0.5).timeout
		GameState.set_ui_open(false)
		EventBus.symbols_solved.emit()
		queue_free()
	else:
		AudioMgr.play_sfx("res://assets/audio/sfx/error.wav", -4.0)
		EventBus.toast.emit(Fa.MSG["symbols_wrong"], 2.5)
		for b in dials:
			b.set_meta("v", 0)
			b.text = SYMS[0]
