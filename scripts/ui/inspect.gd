extends Control
## Inspect panel — documents, photos, about. RTL Persian, typewriter, tap to complete/close.

var body_text: String = ""
var title_text: String = ""
var photo_path: String = ""
var _rich: RichTextLabel
var _done := false

func fill(body: String, title: String = "", photo: String = "") -> void:
	body_text = body
	title_text = title
	photo_path = photo

func _ready() -> void:
	GameState.set_ui_open(true)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := UIH.panel(Color(0.06, 0.07, 0.075, 0.98))
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(680, 0)
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)

	if title_text != "":
		vb.add_child(UIH.centered_label(title_text, 26, UIH.COL_ACCENT, true))

	if photo_path != "":
		var tr := TextureRect.new()
		tr.texture = load(photo_path)
		tr.custom_minimum_size = Vector2(0, 300)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vb.add_child(tr)

	_rich = RichTextLabel.new()
	_rich.text = body_text
	_rich.fit_content = true
	_rich.custom_minimum_size = Vector2(0, 10)
	_rich.add_theme_font_override("normal_font", UIH.font_regular)
	_rich.add_theme_font_size_override("normal_font_size", 22)
	_rich.add_theme_color_override("default_color", Color(0.92, 0.9, 0.82))
	_rich.set("text_direction", Control.TEXT_DIRECTION_RTL)
	_rich.set("autowrap_mode", TextServer.AUTOWRAP_WORD_SMART)
	vb.add_child(_rich)

	vb.add_child(UIH.vspace(6))
	var close := UIH.button(Fa.UI["close"], 18, 200)
	close.pressed.connect(_close)
	var cc := CenterContainer.new()
	cc.add_child(close)
	vb.add_child(cc)

	# typewriter
	_rich.visible_characters = 0
	var total := body_text.length()
	_done = false
	var tw := create_tween()
	tw.tween_property(_rich, "visible_characters", total, clampf(total * 0.02, 0.6, 3.0))
	tw.tween_callback(func(): _done = true)
	# clicking anywhere completes/closes
	dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			if _rich.visible_characters < body_text.length():
				_rich.visible_characters = -1
				_done = true
			else:
				_close())
	close.focus_neighbor_left = close.get_path()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("pause") or event.is_action_pressed("ui_accept"):
		if _rich != null and _rich.visible_characters >= 0 and _rich.visible_characters < body_text.length():
			_rich.visible_characters = -1
		else:
			_close()
		get_viewport().set_input_as_handled()

func _close() -> void:
	GameState.set_ui_open(false)
	queue_free()
