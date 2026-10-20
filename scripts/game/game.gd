extends Node3D
## Game — world assembly, story progression, puzzles wiring, save/load, endings.

var main: Node = null
var new_game: bool = true
var house: Node3D
var player: CharacterBody3D
var hud: CanvasLayer
var touch: CanvasLayer
var valve_seq: Array = []
var _intro_done := false

func _ready() -> void:
	add_to_group("game_root")
	if new_game:
		GameState.reset_new_game()
	else:
		var data := SaveSys.load_game()
		if data.is_empty():
			GameState.reset_new_game()
			new_game = true
		else:
			GameState.apply_save(data)

	house = load("res://scripts/game/house_builder.gd").new()
	house.name = "House"
	add_child(house)
	house.build(false)

	player = load("res://scripts/player/player.gd").new()
	player.name = "Player"
	add_child(player)
	var spawn_pos: Vector3 = Vector3(0, 0.3, 12.5)
	if GameState.flags.has("player_pos"):
		var parr: Array = GameState.flags["player_pos"]
		spawn_pos = Vector3(parr[0], parr[1], parr[2])
	player.position = spawn_pos

	hud = load("res://scripts/ui/hud.gd").new()
	add_child(hud)

	if OS.has_feature("android") or bool(AudioMgr.get_setting("force_touch", false)):
		touch = load("res://scripts/player/touch_ui.gd").new()
		add_child(touch)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	_ambience_start()
	_connect_signals()
	_apply_saved_world()

	EventBus.ui_open_changed.connect(_on_ui_open)
	if new_game:
		_intro()

func _intro() -> void:
	await get_tree().create_timer(1.6).timeout
	_story("intro")
	await get_tree().create_timer(4.5).timeout
	var panel: Control = load("res://scripts/ui/inspect.gd").new()
	var nd: Dictionary = Fa.NOTES["letter"]
	panel.fill(str(nd["body"]), str(nd["title"]))
	get_viewport().add_child(panel)
	GameState.add_item("note_letter")
	GameState.set_objective(Fa.OBJ["c1_enter"])

func _ambience_start() -> void:
	AudioMgr.start_ambient("rain", "res://assets/audio/ambience/rain_loop.ogg", -10.0)
	AudioMgr.start_ambient("wind", "res://assets/audio/ambience/wind_loop.ogg", -16.0)
	AudioMgr.start_ambient("pool", "res://assets/audio/ambience/pool_water.ogg", -13.0)

func _connect_signals() -> void:
	EventBus.power_on.connect(_on_power)
	EventBus.clock_solved.connect(_on_clock)
	EventBus.drawer_opened.connect(_on_drawer)
	EventBus.symbols_solved.connect(_on_symbols)
	EventBus.item_added.connect(_on_item)

# ---------------- saved world restore ----------------
func _apply_saved_world() -> void:
	if GameState.get_flag("power_on"):
		_set_power(true, true)
	if GameState.get_flag("clock_solved"):
		if house.reg.has("wall_clock"):
			house.reg["wall_clock"].mark_solved()
	if GameState.get_flag("drawer_code_ok"):
		pass  # drawer handles via flag
	if GameState.get_flag("valves_done"):
		if house.reg.has("pool"):
			house.reg["pool"].drained = true
		_set_pool_drained_state()
	if GameState.get_flag("symbols_solved"):
		if house.reg.has("symbol_door"):
			var sd = house.reg["symbol_door"]
			sd.solved = true
			sd.enabled = false
			var panel: Node3D = sd.get_node_or_null("Panel")
			if panel != null:
				panel.position.y = -2.4
	# doors
	for id in house.reg.keys():
		if id.begins_with("door_") or id in ["vest_door", "family_door", "stor_door", "kitchen_door", "corr_door", "study_door", "grand_door", "bath_door", "stair_door", "main_door"]:
			var d = house.reg[id]
			if GameState.get_flag("door_" + id):
				d.set_open_state(true)
	# main door permanently locked after entry
	if GameState.get_flag("entered_house"):
		var md = house.reg.get("main_door")
		if md != null:
			md.locked = true
			md.locked_msg = Fa.MSG["door_stuck"]
			md.enabled = false
	# valve states
	for vid in [1, 2, 3]:
		if GameState.get_flag("valve_" + str(vid) + "_on"):
			var v = house.reg.get("valve" + str(vid))
			if v != null:
				v.set_turned(true)
	# objectives label
	EventBus.objective_changed.emit(GameState.objective)

func _set_pool_drained_state() -> void:
	var pool = house.reg.get("pool")
	if pool == null:
		return
	pool.water_mesh.position.y = pool.DRAIN_Y
	pool.reflection.position.y = pool.DRAIN_Y * 2 + 0.02
	pool.hatch_slab.position.y -= 2.2
	for c in pool.hatch_slab.get_children():
		if c is StaticBody3D:
			c.get_child(0).set("disabled", true)

# ---------------- zones / story ----------------
func on_zone(_body: Node3D, zone: String) -> void:
	match zone:
		"t_vestibule":
			if not GameState.get_flag("entered_house"):
				GameState.set_flag("entered_house")
				var md = house.reg.get("main_door")
				if md != null:
					md.force_close_and_lock()
				GameState.set_chapter(2)
				GameState.set_objective(Fa.OBJ["c2_explore"])
				auto_save()
		"t_courtyard":
			if not GameState.get_flag("entered_court"):
				GameState.set_flag("entered_court")
				await get_tree().create_timer(2.0).timeout
				_story("c2_pool")
				house.reg["pool"].ripple_event()
				Horror.cue_discover()
				await get_tree().create_timer(5.0).timeout
				house.reg["pool"].ripple_event()
				GameState.set_objective(Fa.OBJ["c2_note"])
			elif GameState.get_flag("cassette_played") and not GameState.get_flag("court_freeze_done"):
				GameState.set_flag("court_freeze_done")
				_story("c2_freeze")
				house.reg["pool"].freeze_seconds(3.0)
				await get_tree().create_timer(4.0).timeout
				house.reg["pool"].show_ghost_window(6.0)
				house.reg["pool"].ripple_event()
		"t_family":
			if GameState.get_flag("cassette_played") and not GameState.get_flag("family_knock"):
				GameState.set_flag("family_knock")
				_story("c3_knock")
				Horror.knock_3(self, Vector3(-9.5, 1.6, 8.5))
		"t_grand":
			if GameState.get_flag("cassette_played") and not GameState.get_flag("grand_done2"):
				GameState.set_flag("grand_done2")
				Horror.whisper(self, Vector3(-3.5, 1.8, -7.0))
		"t_basement":
			if not GameState.get_flag("entered_basement"):
				GameState.set_flag("entered_basement")
				_story("c6_enter")
				AudioMgr.play_music("res://assets/audio/music/basement_sting.ogg", 1.0)
				Horror.drop_ambient(3.0)
				AudioMgr.start_ambient("drips", "res://assets/audio/ambience/drips_loop.ogg", -8.0)
				AudioMgr.start_ambient("hum", "res://assets/audio/ambience/basement_hum.ogg", -12.0)
				GameState.set_chapter(6)
				GameState.set_objective(Fa.OBJ["c6_explore"])
				auto_save()
				await get_tree().create_timer(9.0).timeout
				GameState.set_flag("flash_flicker")
				await get_tree().create_timer(6.0).timeout
				GameState.set_flag("flash_flicker", false)
		"t_channel":
			if not GameState.get_flag("channel_knock"):
				GameState.set_flag("channel_knock")
				_story("c6_pipes")
				for i in 3:
					Horror.metal_clank(self, Vector3(-4 + i, BASEMENT_Y + 1.0, -7.3))
					await get_tree().create_timer(1.4).timeout
		"t_chamber":
			if not GameState.get_flag("entered_chamber"):
				GameState.set_flag("entered_chamber")
				_story("c7_chamber")
				GameState.set_chapter(7)
				GameState.set_objective(Fa.OBJ["c7_truth"])
				var b2 = house.lights.get("base2")
				if b2 != null:
					b2.light_energy = 1.4
				AudioMgr.play_music("res://assets/audio/music/drone_tension.ogg", 3.0)
				Horror.drop_ambient(2.5)
				auto_save()
				await get_tree().create_timer(6.0).timeout
				_story("final_ask")

const BASEMENT_Y := -3.8

func _story(key: String) -> void:
	var lines: Array = Fa.STORY.get(key, [])
	for ln in lines:
		EventBus.toast.emit(str(ln), 3.4)
		await get_tree().create_timer(3.6).timeout

# ---------------- puzzle handlers ----------------
func _on_power() -> void:
	_set_power(true, false)
	_story("c4_power")
	EventBus.toast.emit(Fa.MSG["power_on"], 3.5)
	GameState.set_objective(Fa.OBJ["c4_clock"])
	Horror.cue_discover()
	# corridor light flicker + distant clank
	var cl = house.lights.get("corr")
	if cl != null:
		Horror.light_flicker(cl, 5)
	await get_tree().create_timer(2.5).timeout
	Horror.metal_clank(self, Vector3(8.0, 1.0, 0))
	auto_save()

func _set_power(on: bool, silent: bool) -> void:
	var ids := ["vest", "corr", "family", "kitchen", "study", "grand", "bath"]
	for id in ids:
		var l = house.lights.get(id)
		if l != null:
			l.light_energy = l.get_meta("base_energy", 1.6)
	if not silent:
		AudioMgr.start_ambient("hum", "res://assets/audio/ambience/electric_hum.ogg", -18.0)
	# storage lamp stays off; stair lamp flickers occasionally (decor)

func _on_clock() -> void:
	if house.reg.has("wall_clock"):
		house.reg["wall_clock"].mark_solved()
	# spawn brass key near clock
	_spawn_key_at_clock()
	EventBus.toast.emit("جایگاه مخفیِ ساعت باز شد!", 3.5)
	GameState.set_objective(Fa.OBJ["c4_study"])
	Horror.cue_discover()
	auto_save()

func _spawn_key_at_clock() -> void:
	var p: Node = load("res://scripts/interact/pickup.gd").new()
	p.item_id = "brass_key"
	add_child(p)
	p.position = Vector3(-7.02, 1.35, 3.3)
	house.reg["brass_key_spawn"] = p

func _on_drawer() -> void:
	GameState.set_flag("drawer_code_ok")
	EventBus.toast.emit("کشو باز شد — دسته‌ای فلزی داخل آن است.", 3.5)
	GameState.set_objective(Fa.OBJ["c5_valves"])
	Horror.cue_discover()
	auto_save()

func on_valve_turned(vid: int) -> void:
	if GameState.get_flag("valves_done"):
		return
	valve_seq.append(vid)
	GameState.set_flag("valve_" + str(vid) + "_on")
	var want := [2, 3, 1]
	var ok := true
	for i in valve_seq.size():
		if i >= want.size() or valve_seq[i] != want[i]:
			ok = false
			break
	if not ok:
		# wrong order: reset
		EventBus.toast.emit(Fa.MSG["valve_wrong"], 3.0)
		AudioMgr.play_sfx("res://assets/audio/sfx/error.wav", -4.0)
		valve_seq.clear()
		for v in [1, 2, 3]:
			var vv = house.reg.get("valve" + str(v))
			if vv != null:
				vv.turned = false
				vv.enabled = true
				GameState.set_flag("valve_" + str(v) + "_on", false)
		return
	if valve_seq.size() == 3:
		_valves_solved()

func _valves_solved() -> void:
	GameState.set_flag("valves_done")
	AudioMgr.play_sfx("res://assets/audio/sfx/success.wav", 0.0)
	_story("c5_drain")
	house.reg["pool"].drain()
	GameState.set_chapter(5)
	GameState.set_objective(Fa.OBJ["c5_basement"])
	await get_tree().create_timer(9.0).timeout
	EventBus.toast.emit(Fa.MSG["pool_drain_done"], 4.5)
	GameState.set_chapter(6)
	GameState.set_objective(Fa.OBJ["c6_explore"])
	# scary beat: figure in reflection once
	house.reg["pool"].show_figure(2.4)
	auto_save()

func _on_symbols() -> void:
	GameState.set_flag("symbols_solved")
	if house.reg.has("symbol_door"):
		house.reg["symbol_door"].open_door()
	EventBus.toast.emit(Fa.MSG["chamber_open"], 4.0)
	Horror.cue_event()
	auto_save()

func _on_item(id: String) -> void:
	match id:
		"cassette":
			_story("c3_slam")
			var gd = house.reg.get("grand_door")
			if gd != null and gd.open:
				var tw := create_tween()
				tw.tween_property(gd, "rotation:y", 0.0, 0.5)
				gd.open = false
			AudioMgr.play_sfx_3d("res://assets/audio/sfx/door_slam.wav", self, Vector3(-3.5, 1.4, -4.3), 6.0)
			GameState.set_flag("cassette_played")
		"fuse":
			EventBus.toast.emit("فیوز نو — حالا جعبه فیوز را پیدا کن.", 3.0)
		"valve_handle":
			EventBus.toast.emit("دسته شیر — آب‌کن حوض آن را می‌خواهد.", 3.0)

# ---------------- mirror scare ----------------
func mirror_scare(pos: Vector3) -> void:
	# brief figure behind player
	var fig := Sprite3D.new()
	fig.texture = load("res://assets/textures/figure.png")
	fig.pixel_size = 0.008
	fig.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(fig)
	var back: Vector3 = -player.yaw_node.global_transform.basis.z
	fig.global_position = player.global_position + Vector3(back.x, 0, back.z).normalized() * 1.6 + Vector3(0, 1.0, 0)
	fig.rotation.y = player.rotation.y + PI
	var tw := fig.create_tween()
	tw.tween_interval(0.7)
	tw.tween_property(fig, "modulate:a", 0.0, 0.5)
	tw.tween_callback(fig.queue_free)
	AudioMgr.play_sfx_3d("res://assets/audio/sfx/whisper.wav", self, pos + Vector3(0, 0.4, 0), 2.0)

# ---------------- endings ----------------
func spawn_passage_door() -> void:
	if house.reg.has("exit_door"):
		return
	var d: LockedDoorMsg = load("res://scripts/interact/locked_msg_door.gd").new()
	d.name = "ExitDoor"
	add_child(d)
	d.position = Vector3(-7.8, BASEMENT_Y, 3.2)
	d.rotation.y = PI / 2.0
	d.collision_layer = 4
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.4, 0.4, 0.3)
	cs.shape = bs
	d.add_child(cs)
	d.prompt = Fa.PROMPT["use"]
	d.set_meta("exit", true)
	# visible arch
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.2, 2.2, 0.3)
	mi.mesh = bm
	mi.material_override = house.mats["stone_b"]
	mi.position = Vector3(0, 1.1, 0)
	d.add_child(mi)
	d.enabled = true
	# custom interact: check passage key
	house.reg["exit_door"] = d
	EventBus.toast.emit("درِ گذرگاه باز شد... کلید را بزن.", 3.5)

func choose_ending(which: String) -> void:
	if GameState.decision != "":
		return
	GameState.decision = which
	GameState.set_chapter(8)
	EventBus.request_fade.emit(true, 2.5)
	AudioMgr.stop_music(2.0)
	AudioMgr.stop_ambient("rain")
	AudioMgr.stop_ambient("wind")
	AudioMgr.stop_ambient("pool")
	AudioMgr.stop_ambient("drips")
	AudioMgr.stop_ambient("hum")
	await get_tree().create_timer(2.7).timeout
	if main != null:
		main.call_deferred("show_ending", which)

# ---------------- UI helpers ----------------
func toggle_pause() -> void:
	if GameState.ui_open:
		return
	var p: Control = load("res://scripts/ui/pause_menu.gd").new()
	get_viewport().add_child(p)

func toggle_inventory() -> void:
	if GameState.ui_open:
		return
	var p: Control = load("res://scripts/ui/inventory_panel.gd").new()
	get_viewport().add_child(p)

func _on_ui_open(open: bool) -> void:
	if not OS.has_feature("android"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED

func back_to_menu() -> void:
	if main != null:
		main.show_menu()

func reload_from_save() -> void:
	if main != null:
		main.start_game(false)

# ---------------- saving ----------------
func auto_save() -> void:
	var data := GameState.to_save_data()
	data["player_pos"] = [player.global_position.x, player.global_position.y, player.global_position.z]
	SaveSys.save_game(data)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not GameState.ui_open:
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory") and not GameState.ui_open:
		toggle_inventory()
		get_viewport().set_input_as_handled()
