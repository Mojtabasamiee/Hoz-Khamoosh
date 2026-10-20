extends Control
## Wall clock puzzle UI — set the clock to 3:15 (from the diary).
## Persian numerals shown; ± hour/minute buttons; confirm checks.

var hour: int = 12
var minute: int = 0

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

	vb.add_child(UIH.centered_label("ساعت دیواری", 28, UIH.COL_ACCENT, true))
	vb.add_child(UIH.centered_label("عقربه‌ها را تنظیم کن.", 16, UIH.COL_DIM))

	var clock_view := ClockFace.new()
	clock_view.custom_minimum_size = Vector2(240, 240)
	vb.add_child(clock_view)

	var hour_row := HBoxContainer.new()
	hour_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var h_minus := UIH.button("−", 24, 80)
	var h_label := UIH.centered_label("ساعت: " + Fa.to_fa_num(str(hour)), 20)
	var h_plus := UIH.button("+", 24, 80)
	h_minus.pressed.connect(func():
		hour = (hour + 11) % 12 + 1 if hour == 12 else hour - 1
		if hour < 1: hour = 12
		h_label.text = "ساعت: " + Fa.to_fa_num(str(hour))
		clock_view.set_time(hour, minute))
	h_plus.pressed.connect(func():
		hour = hour % 12 + 1
		h_label.text = "ساعت: " + Fa.to_fa_num(str(hour))
		clock_view.set_time(hour, minute))
	hour_row.add_child(h_minus)
	hour_row.add_child(h_label)
	hour_row.add_child(h_plus)
	vb.add_child(hour_row)

	var min_row := HBoxContainer.new()
	min_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var m_minus := UIH.button("−", 24, 80)
	var m_label := UIH.centered_label("دقیقه: " + Fa.to_fa_num("%02d" % minute), 20)
	var m_plus := UIH.button("+", 24, 80)
	m_minus.pressed.connect(func():
		minute = (minute + 55) % 60
		m_label.text = "دقیقه: " + Fa.to_fa_num("%02d" % minute)
		clock_view.set_time(hour, minute))
	m_plus.pressed.connect(func():
		minute = (minute + 5) % 60
		m_label.text = "دقیقه: " + Fa.to_fa_num("%02d" % minute)
		clock_view.set_time(hour, minute))
	min_row.add_child(m_minus)
	min_row.add_child(m_label)
	min_row.add_child(m_plus)
	vb.add_child(min_row)

	vb.add_child(UIH.vspace(6))
	var row2 := HBoxContainer.new()
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	var ok := UIH.button("تنظیم کردن", 20, 200)
	var close := UIH.button(Fa.UI["close"], 18, 140)
	ok.pressed.connect(func(): _check())
	close.pressed.connect(func():
		GameState.set_ui_open(false)
		queue_free())
	row2.add_child(ok)
	row2.add_child(close)
	vb.add_child(row2)

func _check() -> void:
	if hour == 3 and minute == 15:
		AudioMgr.play_sfx("res://assets/audio/sfx/clock_chime.wav", 0.0)
		GameState.set_flag("clock_solved")
		EventBus.clock_solved.emit()
		GameState.set_ui_open(false)
		queue_free()
	else:
		AudioMgr.play_sfx("res://assets/audio/sfx/error.wav", -4.0)
		EventBus.toast.emit(Fa.MSG["clock_wrong"], 2.5)

class ClockFace extends Control:
	var h := 12
	var m := 0
	func set_time(ph: int, pm: int) -> void:
		h = ph
		m = pm
		queue_redraw()
	func _draw() -> void:
		var c := size / 2.0
		var r := minf(c.x, c.y) - 8.0
		draw_circle(c, r, Color(0.09, 0.11, 0.10))
		draw_arc(c, r, 0, TAU, 48, Color(0.75, 0.62, 0.35), 3.0, true)
		for i in 12:
			var a := TAU * i / 12.0 - TAU / 4.0
			var p1 := c + Vector2(cos(a), sin(a)) * (r - 6)
			var p2 := c + Vector2(cos(a), sin(a)) * (r - 14)
			draw_line(p1, p2, Color(0.8, 0.75, 0.6), 2.0)
		# hour hand
		var ha := TAU * ((h % 12) + m / 60.0) / 12.0 - TAU / 4.0
		draw_line(c, c + Vector2(cos(ha), sin(ha)) * (r * 0.5), Color(0.9, 0.85, 0.7), 4.0)
		# minute hand
		var ma := TAU * m / 60.0 - TAU / 4.0
		draw_line(c, c + Vector2(cos(ma), sin(ma)) * (r * 0.78), Color(0.9, 0.85, 0.7), 2.5)
		draw_circle(c, 5, Color(0.85, 0.7, 0.4))
