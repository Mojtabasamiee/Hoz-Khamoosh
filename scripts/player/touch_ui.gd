extends CanvasLayer
## TouchUI — Android controls (v2, rewritten & tested):
##  - floating joystick: touch anywhere on LEFT 42% of screen
##  - look drag: anywhere on RIGHT 58%
##  - big action buttons bottom-right: interact / flashlight / crouch
##  - pause (top-left) + inventory (top-right)
##  - Persian labels + haptic feedback (respects the vibration setting)

var player: Node

var left_pad: Control
var right_pad: Control
var joy_base: Control
var joy_knob: Control

var _joy_touch := -1
var _joy_center := Vector2.ZERO   # viewport/global coords
var _joy_cur := Vector2.ZERO
var _look_touch := -1
var _look_last := Vector2.ZERO
var _btns: Array[Control] = []

const JOY_R := 118.0
const JOY_DEAD := 0.14
const SPLIT := 0.42

func _ready() -> void:
	layer = 6
	player = get_tree().get_first_node_in_group("player")
	_build_pads()
	_build_buttons()

# ================= build =================
func _build_pads() -> void:
	left_pad = Control.new()
	left_pad.anchor_right = SPLIT
	left_pad.anchor_bottom = 1.0
	left_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE  # we handle touches in _input()
	add_child(left_pad)

	joy_base = Control.new()
	joy_base.size = Vector2(JOY_R * 2.0, JOY_R * 2.0)
	joy_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joy_base.draw.connect(func():
		joy_base.draw_circle(Vector2(JOY_R, JOY_R), JOY_R, Color(0.16, 0.26, 0.29, 0.38))
		joy_base.draw_arc(Vector2(JOY_R, JOY_R), JOY_R, 0, TAU, 48, Color(0.4, 0.75, 0.8, 0.55), 2.5, true)
		joy_base.draw_arc(Vector2(JOY_R, JOY_R), JOY_R * 0.45, 0, TAU, 32, Color(0.4, 0.75, 0.8, 0.25), 1.5, true))
	left_pad.add_child(joy_base)

	joy_knob = Control.new()
	joy_knob.size = Vector2(64, 64)
	joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joy_knob.draw.connect(func():
		joy_knob.draw_circle(Vector2(32, 32), 30, Color(0.55, 0.85, 0.9, 0.62))
		joy_knob.draw_arc(Vector2(32, 32), 30, 0, TAU, 32, Color(0.8, 0.97, 1.0, 0.8), 2.0, true))
	joy_base.add_child(joy_knob)

	right_pad = Control.new()
	right_pad.anchor_left = SPLIT
	right_pad.anchor_right = 1.0
	right_pad.anchor_bottom = 1.0
	right_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(right_pad)

	_reset_joy()

func _mk_icon_btn(tex_path: String, size_px: float, cb: Callable, label_text: String = "") -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = load(tex_path)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.modulate = Color(1, 1, 1, 0.82)
	b.pressed.connect(cb)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(b)
	_btns.append(b)
	if label_text != "":
		var l := Label.new()
		l.text = label_text
		l.add_theme_font_override("font", UIH.font_medium)
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color", Color(0.85, 0.95, 0.97, 0.9))
		l.set("text_direction", Control.TEXT_DIRECTION_RTL)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.anchor_right = 1.0
		l.anchor_top = 1.0
		l.anchor_bottom = 1.0
		l.offset_top = -2
		l.offset_bottom = 20
		l.offset_left = -30
		l.offset_right = 30
		b.add_child(l)
	# scale icon inside an expanded touch area
	var pad := size_px * 0.22
	b.offset_left = -pad
	b.offset_top = -pad
	b.offset_right = pad
	b.offset_bottom = pad
	return b

func _place_br(b: Control, from_right: float, from_bottom: float, size_px: float) -> void:
	b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT, true)
	b.offset_left = -from_right - size_px
	b.offset_top = -from_bottom - size_px
	b.offset_right = -from_right
	b.offset_bottom = -from_bottom

func _build_buttons() -> void:
	# bottom-right cluster
	var b_inter := _mk_icon_btn("res://assets/textures/icon_hand.png", 120, _act_interact, "تعامل")
	_place_br(b_inter, 26, 96, 120)
	var b_flash := _mk_icon_btn("res://assets/textures/icon_flash.png", 86, _act_flash, "چراغ")
	_place_br(b_flash, 44, 236, 86)
	var b_crouch := _mk_icon_btn("res://assets/textures/icon_crouch.png", 86, _act_crouch, "خم‌شدن")
	_place_br(b_crouch, 168, 84, 86)
	# top corners
	var b_inv := _mk_icon_btn("res://assets/textures/icon_paper.png", 68, _act_inventory, "وسایل")
	b_inv.set_anchors_preset(Control.PRESET_TOP_RIGHT, true)
	b_inv.offset_left = -96
	b_inv.offset_top = 22
	b_inv.offset_right = -28
	b_inv.offset_bottom = 90
	var b_pause := _mk_icon_btn("res://assets/textures/icon_pause.png", 68, _act_pause, "مکث")
	b_pause.set_anchors_preset(Control.PRESET_TOP_LEFT, true)
	b_pause.offset_left = 24
	b_pause.offset_top = 22
	b_pause.offset_right = 92
	b_pause.offset_bottom = 90

# ================= joystick =================
func _split_x() -> float:
	return get_viewport().get_visible_rect().size.x * SPLIT

func _rest_center() -> Vector2:
	var sz := get_viewport().get_visible_rect().size
	return Vector2(JOY_R + 52.0, sz.y - JOY_R - 56.0)

func _reset_joy() -> void:
	var c := _rest_center()
	_joy_center = c
	_joy_cur = c
	joy_base.position = c - Vector2(JOY_R, JOY_R)
	joy_knob.position = Vector2(JOY_R - 32, JOY_R - 32)

func _show_joy_at(g: Vector2) -> void:
	_joy_center = g
	_joy_cur = g
	joy_base.position = g - Vector2(JOY_R, JOY_R)
	joy_knob.position = Vector2(JOY_R - 32, JOY_R - 32)

func _update_knob() -> void:
	var v := _joy_vec()
	joy_knob.position = Vector2(JOY_R - 32, JOY_R - 32) + v * JOY_R

func _joy_vec() -> Vector2:
	if _joy_touch == -1:
		return Vector2.ZERO
	var v := (_joy_cur - _joy_center) / JOY_R
	if v.length() < JOY_DEAD:
		return Vector2.ZERO
	if v.length() > 1.0:
		v = v.normalized()
	return v

# ================= input routing =================
func _input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		var g: Vector2 = ev.position
		if ev.pressed:
			if GameState.ui_open:
				return
			if _over_button(g):
				return
			if g.x < _split_x():
				if _joy_touch == -1:
					_joy_touch = ev.index
					_show_joy_at(g)
					_haptic(12)
			else:
				if _look_touch == -1:
					_look_touch = ev.index
					_look_last = g
		else:
			if ev.index == _joy_touch:
				_joy_touch = -1
				_reset_joy()
			elif ev.index == _look_touch:
				_look_touch = -1
	elif ev is InputEventScreenDrag:
		var g2: Vector2 = ev.position
		if ev.index == _joy_touch:
			_joy_cur = g2
			_update_knob()
		elif ev.index == _look_touch:
			if not GameState.ui_open and player != null and is_instance_valid(player):
				player.add_touch_look(g2 - _look_last)
			_look_last = g2

func _process(_delta: float) -> void:
	if player != null and is_instance_valid(player):
		player.touch_move = _joy_vec()

func _over_button(g: Vector2) -> bool:
	for b in _btns:
		if is_instance_valid(b) and b.get_global_rect().has_point(g):
			return true
	return false

func _haptic(ms: int = 25) -> void:
	if bool(AudioMgr.get_setting("vibration", true)):
		Input.vibrate_handheld(ms)

# ================= actions =================
func _act_interact() -> void:
	_haptic(30)
	if player != null and is_instance_valid(player):
		player._do_interact()

func _act_flash() -> void:
	_haptic(18)
	if player != null and is_instance_valid(player):
		player.toggle_flashlight()

func _act_crouch() -> void:
	_haptic(18)
	if player != null and is_instance_valid(player):
		player.toggle_crouch()

func _act_inventory() -> void:
	_haptic(18)
	var game := get_tree().get_first_node_in_group("game_root")
	if game != null:
		game.call("toggle_inventory")

func _act_pause() -> void:
	_haptic(18)
	var game := get_tree().get_first_node_in_group("game_root")
	if game != null:
		game.call("toggle_pause")
