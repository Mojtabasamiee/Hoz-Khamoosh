extends Control
## Study drawer code lock — code = last digits of photo years, oldest->newest: 8713.

const CODE := "8713"
var _entry := ""
var _done := false
var _display: Label

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

	vb.add_child(UIH.centered_label("قفل عددی کشو", 28, UIH.COL_ACCENT, true))
	vb.add_child(UIH.centered_label("۴ رقم — از عکس‌ها: «از کهنه به نو»", 16, UIH.COL_DIM))

	_display = UIH.centered_label("— — — —", 34, Color(0.9, 0.85, 0.5), true)
	vb.add_child(_display)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	vb.add_child(grid)

	var digits := ["۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"]
	for d in digits:
		var b := UIH.button(d, 22, 90)
		var idx := digits.find(d)
		b.pressed.connect(func(): _press(idx + 1))
		grid.add_child(b)
	var b_clear := UIH.button("پاک", 18, 90)
	b_clear.pressed.connect(func():
		_entry = ""
		_update())
	grid.add_child(b_clear)
	var b_0 := UIH.button("۰", 22, 90)
	b_0.pressed.connect(func(): _press(0))
	grid.add_child(b_0)
	var b_ok := UIH.button("✓", 22, 90)
	b_ok.pressed.connect(func(): _check())
	grid.add_child(b_ok)

	vb.add_child(UIH.vspace(6))
	var close := UIH.button(Fa.UI["close"], 18, 160)
	close.pressed.connect(func():
		GameState.set_ui_open(false)
		queue_free())
	vb.add_child(close)

func _press(d: int) -> void:
	if _done:
		return
	if _entry.length() < 4:
		_entry += str(d)
		AudioMgr.play_sfx("res://assets/audio/sfx/click.wav", -6.0)
	_update()

func _update() -> void:
	var txt := ""
	for c in _entry:
		txt += Fa.to_fa_num(c) + " "
	while txt.count("— ") < 0:
		break
	_display.text = txt if _entry != "" else "— — — —"

func _check() -> void:
	if _done:
		return
	if _entry == CODE:
		_done = true
		AudioMgr.play_sfx("res://assets/audio/sfx/success.wav", -2.0)
		GameState.set_flag("drawer_code_ok")
		await get_tree().create_timer(0.8).timeout
		GameState.set_ui_open(false)
		EventBus.drawer_opened.emit()
		queue_free()
	else:
		AudioMgr.play_sfx("res://assets/audio/sfx/error.wav", -4.0)
		_entry = ""
		_update()
		EventBus.toast.emit("قفل باز نشد.", 2.0)
