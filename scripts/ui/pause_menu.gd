extends Control
## Pause menu.

func _ready() -> void:
	GameState.set_ui_open(true)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 12)
	add_child(vb)
	vb.add_child(UIH.centered_label("مکث", 36, UIH.COL_ACCENT, true))
	vb.add_child(UIH.vspace(14))

	var cc := CenterContainer.new()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	cc.add_child(box)
	vb.add_child(cc)

	var b1 := UIH.button(Fa.UI["resume"], 22)
	b1.pressed.connect(_resume)
	box.add_child(b1)

	var b2 := UIH.button(Fa.UI["settings"], 22)
	b2.pressed.connect(func():
		var s: Control = load("res://scripts/menu/settings_menu.gd").new()
		add_child(s))
	box.add_child(b2)

	var b3 := UIH.button(Fa.UI["restart_save"], 22)
	b3.pressed.connect(func():
		if SaveSys.has_save():
			GameState.set_ui_open(false)
			var game := get_tree().get_first_node_in_group("game_root")
			if game != null:
				game.call("reload_from_save")
		else:
			EventBus.toast.emit(Fa.UI["no_save"], 2.5))
	box.add_child(b3)

	var b4 := UIH.button(Fa.UI["main_menu"], 22)
	b4.pressed.connect(func():
		GameState.set_ui_open(false)
		AudioMgr.stop_ambient("rain")
		AudioMgr.stop_ambient("wind")
		AudioMgr.stop_ambient("pool")
		AudioMgr.stop_ambient("hum")
		AudioMgr.stop_music(1.0)
		get_parent().call_deferred("back_to_menu"))
	box.add_child(b4)

func _resume() -> void:
	GameState.set_ui_open(false)
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_resume()
		get_viewport().set_input_as_handled()
