extends Control
## Inventory panel — shows collected items with Persian names.

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
	vb.custom_minimum_size = Vector2(640, 0)
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)

	vb.add_child(UIH.centered_label(Fa.UI["inventory"], 28, UIH.COL_ACCENT, true))

	if GameState.items.is_empty():
		vb.add_child(UIH.centered_label(Fa.UI["empty_inv"], 20, UIH.COL_DIM))
	else:
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 16)
		grid.add_theme_constant_override("v_separation", 16)
		for id in GameState.items:
			var meta: Dictionary = Fa.ITEMS.get(id, {})
			var cell := VBoxContainer.new()
			cell.alignment = BoxContainer.ALIGNMENT_CENTER
			var tr := TextureRect.new()
			tr.texture = load(meta.get("icon", "res://assets/textures/icon_note.png"))
			tr.custom_minimum_size = Vector2(72, 72)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			cell.add_child(tr)
			cell.add_child(UIH.centered_label(str(meta.get("name", id)), 15))
			grid.add_child(cell)
		vb.add_child(grid)

	vb.add_child(UIH.vspace(8))
	var close := UIH.button(Fa.UI["close"], 18, 200)
	var cc := CenterContainer.new()
	cc.add_child(close)
	vb.add_child(cc)
	close.pressed.connect(func():
		GameState.set_ui_open(false)
		queue_free())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") or event.is_action_pressed("pause"):
		GameState.set_ui_open(false)
		queue_free()
		get_viewport().set_input_as_handled()
