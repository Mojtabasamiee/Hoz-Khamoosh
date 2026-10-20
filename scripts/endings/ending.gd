extends Control
## Ending screen — A (خروج) or B (ماندن).

var which: String = "A"

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.005, 0.008, 0.012)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 18)
	add_child(vb)

	var data: Dictionary = Fa.ENDINGS[which]
	var title := UIH.centered_label(str(data["title"]), 34, UIH.COL_ACCENT, true)
	vb.add_child(title)

	var body := RichTextLabel.new()
	body.text = str(data["body"])
	body.fit_content = true
	body.bbcode_enabled = false
	body.custom_minimum_size = Vector2(760, 0)
	body.add_theme_font_override("normal_font", UIH.font_regular)
	body.add_theme_font_size_override("normal_font_size", 21)
	body.add_theme_color_override("default_color", Color(0.85, 0.86, 0.82))
	body.set("text_direction", Control.TEXT_DIRECTION_RTL)
	var cc := CenterContainer.new()
	cc.add_child(body)
	vb.add_child(cc)

	vb.add_child(UIH.vspace(18))
	var btn := UIH.button(Fa.UI["main_menu"], 20)
	btn.pressed.connect(func():
		AudioMgr.stop_music(1.0)
		get_parent().call_deferred("show_menu"))
	var cc2 := CenterContainer.new()
	cc2.add_child(btn)
	vb.add_child(cc2)

	# music per ending
	if which == "A":
		AudioMgr.play_music("res://assets/audio/music/ending_a.ogg", 2.0)
	else:
		AudioMgr.play_music("res://assets/audio/music/ending_b.ogg", 2.0)

	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 2.0)

	# clear save after an ending run
	SaveSys.delete_save()
	GameState.ending_watched = which
