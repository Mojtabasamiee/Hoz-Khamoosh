extends CanvasLayer
## TouchUI — Android controls: left joystick, right look pad, action buttons.

var player: Node
var joy_base: Control
var joy_knob: Control
var _joy_touch := -1
var _joy_center := Vector2.ZERO
var _look_touch := -1
var _look_last := Vector2.ZERO

const JOY_R := 110.0

func _ready() -> void:
	layer = 6
	player = get_tree().get_first_node_in_group("player")

	# ---- look layer (covers right 55%) ----
	var look := Control.new()
	look.set_anchors_preset(Control.PRESET_FULL_RECT)
	look.anchor_left = 0.45
	look.mouse_filter = Control.MOUSE_FILTER_STOP
	look.gui_input.connect(_on_look_input)
	add_child(look)

	# ---- joystick ----
	joy_base = Control.new()
	joy_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joy_base.position = Vector2(60, -260)
	joy_base.size = Vector2(JOY_R * 2, JOY_R * 2)
	joy_base.mouse_filter = Control.MOUSE_FILTER_STOP
	joy_base.gui_input.connect(_on_joy_input)
	joy_base.draw.connect(func():
		joy_base.draw_circle(Vector2(JOY_R, JOY_R), JOY_R, Color(0.2, 0.3, 0.33, 0.35))
		joy_base.draw_arc(Vector2(JOY_R, JOY_R), JOY_R, 0, TAU, 40, Color(0.4, 0.75, 0.8, 0.5), 2.0, true))
	add_child(joy_base)

	joy_knob = Control.new()
	joy_knob.size = Vector2(56, 56)
	joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joy_knob.draw.connect(func():
		joy_knob.draw_circle(Vector2(28, 28), 26, Color(0.55, 0.85, 0.9, 0.6)))
	joy_base.add_child(joy_knob)
	joy_knob.position = Vector2(JOY_R - 28, JOY_R - 28)

	# ---- action buttons (right bottom) ----
	var defs := [
		["res://assets/textures/icon_hand.png", 210, -240, func(): _act_interact(), 92],
		["res://assets/textures/icon_flash.png", 120, -180, func(): _act_flash(), 78],
		["res://assets/textures/icon_crouch.png", 210, -120, func(): _act_crouch(), 78],
		["res://assets/textures/icon_pause.png", 34, 34, func(): _act_pause(), 64],
	]
	for d in defs:
		var b := TextureButton.new()
		b.texture_normal = load(d[0])
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		b.custom_minimum_size = Vector2(d[4], d[4])
		b.size = Vector2(d[4], d[4])
		b.position = Vector2(d[1], d[2])
		b.modulate = Color(1, 1, 1, 0.75)
		b.pressed.connect(d[3])
		add_child(b)

func _process(_delta: float) -> void:
	if player != null and is_instance_valid(player):
		player.touch_move = _joy_vec()

func _joy_vec() -> Vector2:
	if _joy_touch == -1:
		return Vector2.ZERO
	var off := (get_local_mouse_position() if false else _joy_cur - _joy_center)
	var v := off / JOY_R
	if v.length() > 1.0:
		v = v.normalized()
	return v

var _joy_cur := Vector2.ZERO

func _on_joy_input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed and _joy_touch == -1:
			_joy_touch = ev.index
			_joy_center = ev.position
			_joy_cur = ev.position
			_joy_knob_pos(Vector2.ZERO)
		elif not ev.pressed and ev.index == _joy_touch:
			_joy_touch = -1
			joy_knob.position = Vector2(JOY_R - 28, JOY_R - 28)
			_joy_cur = Vector2.ZERO
	elif ev is InputEventScreenDrag and ev.index == _joy_touch:
		_joy_cur = ev.position
		var v := (_joy_cur - _joy_center) / JOY_R
		if v.length() > 1.0:
			v = v.normalized()
		_joy_knob_pos(v * JOY_R)

func _joy_knob_pos(off: Vector2) -> void:
	joy_knob.position = Vector2(JOY_R - 28, JOY_R - 28) + off

func _on_look_input(ev: InputEvent) -> void:
	if player == null or not is_instance_valid(player):
		return
	if ev is InputEventScreenTouch:
		if ev.pressed and _look_touch == -1:
			_look_touch = ev.index
			_look_last = ev.position
		elif not ev.pressed and ev.index == _look_touch:
			_look_touch = -1
	elif ev is InputEventScreenDrag and ev.index == _look_touch:
		var d: Vector2 = ev.position - _look_last
		_look_last = ev.position
		player.add_touch_look(d)

# actions
func _act_interact() -> void:
	if player != null and is_instance_valid(player):
		player._do_interact()

func _act_flash() -> void:
	if player != null and is_instance_valid(player):
		player.toggle_flashlight()

func _act_crouch() -> void:
	if player != null and is_instance_valid(player):
		player.toggle_crouch()

func _act_pause() -> void:
	var game := get_tree().get_first_node_in_group("game_root")
	if game != null:
		game.call("toggle_pause")
