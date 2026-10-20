extends CharacterBody3D
class_name Player
## First-person controller: WASD/mouse + Android touch. Head bob, footsteps, flashlight, interact ray.

const WALK_SPEED := 2.6
const CROUCH_SPEED := 1.4
const ACCEL := 9.0
const GRAVITY := 12.0

var yaw_node: Node3D
var pitch_node: Node3D
var cam: Camera3D
var flashlight: SpotLight3D
var interact_ray: RayCast3D
var floor_ray: RayCast3D

var mouse_sens := 1.0
var touch_sens := 1.0
var look_sens := 0.0022
var touch_look_delta := Vector2()
var touch_move := Vector2()
var crouching := false
var flashlight_on := false
var battery := 100.0
var drain_enabled := true

var _bob_t := 0.0
var _step_t := 0.0
var _current_target: Interactable = null
var _last_surface := "stone"
var _foot_mat := {}

signal interacted

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	floor_max_angle = deg_to_rad(50.0)
	floor_snap_length = 0.4

	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.7
	shape.shape = cap
	shape.position = Vector3(0, 0.85, 0)
	add_child(shape)

	yaw_node = Node3D.new()
	add_child(yaw_node)
	yaw_node.position.y = 1.62
	pitch_node = Node3D.new()
	yaw_node.add_child(pitch_node)
	cam = Camera3D.new()
	cam.fov = 72.0
	cam.near = 0.08
	pitch_node.add_child(cam)
	cam.current = true

	flashlight = SpotLight3D.new()
	flashlight.spot_range = 11.0
	flashlight.spot_angle = 32.0
	flashlight.light_energy = 2.4
	flashlight.light_color = Color(1.0, 0.95, 0.82)
	flashlight.shadow_enabled = false
	flashlight.position = Vector3(0.12, -0.08, 0.0)
	pitch_node.add_child(flashlight)
	flashlight.visible = false

	interact_ray = RayCast3D.new()
	interact_ray.target_position = Vector3(0, 0, -2.3)
	interact_ray.collision_mask = 4
	interact_ray.collide_with_areas = true
	interact_ray.collide_with_bodies = true
	cam.add_child(interact_ray)

	floor_ray = RayCast3D.new()
	floor_ray.target_position = Vector3(0, -1.2, 0)
	floor_ray.position = Vector3(0, 0.5, 0)
	floor_ray.collision_mask = 1
	add_child(floor_ray)

	mouse_sens = float(AudioMgr.get_setting("sensitivity", 1.0))
	touch_sens = float(AudioMgr.get_setting("touch_sens", 1.0))

func _unhandled_input(event: InputEvent) -> void:
	if GameState.ui_open:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var rel: Vector2 = event.relative * mouse_sens * look_sens
		yaw_node.rotation.y -= rel.x
		pitch_node.rotation.x = clampf(pitch_node.rotation.x - rel.y, -1.45, 1.45)
	elif event.is_action_pressed("flashlight"):
		toggle_flashlight()
	elif event.is_action_pressed("interact"):
		_do_interact()
	elif event.is_action_pressed("crouch"):
		toggle_crouch()

func _physics_process(delta: float) -> void:
	if GameState.ui_open:
		velocity.x = 0
		velocity.z = 0
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
			move_and_slide()
		_update_ray()
		return
	# gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	# input direction (keyboard + touch joystick)
	var in_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if touch_move.length() > 0.05:
		in_vec = touch_move
	var dir := (yaw_node.global_transform.basis * Vector3(in_vec.x, 0, in_vec.y))
	dir.y = 0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3.ZERO
	var speed := CROUCH_SPEED if crouching else WALK_SPEED
	velocity.x = move_toward(velocity.x, dir.x * speed, ACCEL * delta * speed)
	velocity.z = move_toward(velocity.z, dir.z * speed, ACCEL * delta * speed)
	# touch look
	if touch_look_delta.length() > 0.0:
		var rel := touch_look_delta * touch_sens * look_sens * 46.0
		yaw_node.rotation.y -= rel.x
		pitch_node.rotation.x = clampf(pitch_node.rotation.x - rel.y, -1.45, 1.45)
		touch_look_delta = Vector2.ZERO
	move_and_slide()
	_head_bob(delta, dir)
	_footsteps(delta, dir)
	_flashlight_tick(delta)
	_update_ray()

# ---------------- head bob & steps ----------------
func _head_bob(delta: float, dir: Vector3) -> void:
	if is_on_floor() and dir.length() > 0.1:
		_bob_t += delta * (9.0 if not crouching else 6.0)
		var bob := sin(_bob_t) * 0.035
		cam.position.y = bob
		cam.position.x = cos(_bob_t * 0.5) * 0.02
	else:
		cam.position.y = lerpf(cam.position.y, 0.0, 8.0 * delta)
		cam.position.x = lerpf(cam.position.x, 0.0, 8.0 * delta)

func _footsteps(delta: float, dir: Vector3) -> void:
	if is_on_floor() and dir.length() > 0.1:
		_step_t -= delta * (1.0 if not crouching else 0.6)
		if _step_t <= 0.0:
			_step_t = 0.52
			_play_step()
	else:
		_step_t = 0.12

func _play_step() -> void:
	if floor_ray.is_colliding():
		var col := floor_ray.get_collider()
		if col != null and col.has_meta("surface"):
			_last_surface = str(col.get_meta("surface"))
	var idx := randi() % 4 + 1
	AudioMgr.play_sfx("res://assets/audio/footsteps/%s_%d.wav" % [_last_surface, idx], -14.0, randf_range(0.92, 1.08))

# ---------------- flashlight ----------------
func toggle_flashlight() -> void:
	flashlight_on = not flashlight_on
	flashlight.visible = flashlight_on
	AudioMgr.play_sfx("res://assets/audio/sfx/flash_click.wav", -8.0)
	EventBus.flashlight_state.emit(flashlight_on, battery)

func _flashlight_tick(delta: float) -> void:
	if flashlight_on:
		if drain_enabled:
			battery = maxf(0.0, battery - delta * 0.45)
		# subtle flicker during story flags
		if GameState.get_flag("flash_flicker"):
			if randf() < 0.04:
				flashlight.light_energy = randf_range(0.4, 2.4)
			else:
				flashlight.light_energy = 2.4
		EventBus.flashlight_state.emit(true, battery)
		if battery <= 0.0:
			flashlight_on = false
			flashlight.visible = false
			EventBus.flashlight_state.emit(false, 0.0)
			GameState.set_flag("flash_flicker", false)

func recharge_battery(v: float = 100.0) -> void:
	battery = v

# ---------------- crouch ----------------
func toggle_crouch() -> void:
	crouching = not crouching
	var tw := create_tween()
	tw.tween_property(yaw_node, "position:y", 1.05 if crouching else 1.62, 0.25)

# ---------------- interaction ----------------
func _update_ray() -> void:
	if interact_ray == null:
		return
	if interact_ray.is_colliding():
		var col := interact_ray.get_collider()
		if col is Interactable and col.can_interact():
			_current_target = col
			var p: String = col.prompt
			if not OS.has_feature("android"):
				p = "[E] " + p
			EventBus.prompt_changed.emit(p)
			return
	_current_target = null
	EventBus.prompt_changed.emit("")

func _do_interact() -> void:
	if _current_target != null and is_instance_valid(_current_target):
		_current_target.interact(self)
		interacted.emit()

# touch API
func add_touch_look(delta_px: Vector2) -> void:
	touch_look_delta += delta_px
