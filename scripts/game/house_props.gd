extends Node3D
## HouseProps — furniture, interactables, pickups placement (called by HouseBuilder).

var hb: Node3D  # house builder
var reg := {}

func build_all(p_hb: Node3D) -> void:
	hb = p_hb
	reg = hb.reg
	_street_props()
	_vestibule()
	_courtyard_props()
	_family_room()
	_kitchen()
	_corridor()
	_study()
	_grandmother()
	_bathroom()
	_storage()
	_stair_room()
	_basement_props()

# ---------- helpers mirroring builder ----------
func _box(sz: Vector3, pos: Vector3, mat: Material, collide := true, surface := "wood", parent: Node = null) -> MeshInstance3D:
	return hb._box(sz, pos, mat, collide, surface, parent)

func _interactable(script_path: String, pos: Vector3, id: String, rot_y := 0.0) -> Node:
	return hb._interactable(script_path, pos, id, rot_y)

func _note(id: String, key: String, pos: Vector3, rot_y := 0.0, once := "") -> NoteObj:
	return hb._note(id, key, pos, rot_y, once)

func _photo(id: String, key: String, pos: Vector3, rot_y := 0.0) -> NoteObj:
	return hb._photo(id, key, pos, rot_y)

func _pickup(id: String, item: String, pos: Vector3) -> Node:
	return hb._pickup(id, item, pos)

func _drawer(id: String, pos: Vector3, size: Vector3, dist: float, item: String, code_locked := false, rot_y := 0.0) -> DrawerObj:
	var d: DrawerObj = load("res://scripts/interact/drawer.gd").new()
	d.name = id
	hb.add_child(d)
	d.position = pos
	d.rotation.y = rot_y
	d.collision_layer = 4
	d.collision_mask = 0
	var body := Node3D.new()
	hb.add_child(body)
	body.position = pos
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = hb.mats["wood"]
	mesh.position = Vector3(0, size.y / 2.0 + 0.12, 0)
	mesh.set_meta("base_z", mesh.position.z)
	body.add_child(mesh)
	# static carcass
	_box(size + Vector3(0.14, 0.24, 0.14), pos + Vector3(0, size.y / 2.0, 0), hb.mats["wood_dark"])
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.5, 0.5, 0.4)
	cs.shape = bs
	cs.position = Vector3(0, 0.2, 0)
	d.add_child(cs)
	d.setup(mesh, dist, hb, pos, item)
	d.code_locked = code_locked
	if code_locked:
		d.set_meta("is_study", true)
	reg[id] = d
	return d

func _valve(id: String, vid: int, pos: Vector3, needs_handle: bool, rot_y := 0.0) -> Node:
	var v: ValveObj = _interactable("res://scripts/interact/valve.gd", pos, id, rot_y)
	v.valve_id = vid
	v.needs_handle = needs_handle
	var wheel := Node3D.new()
	v.add_child(wheel)
	wheel.position = Vector3(0, 0.15, -0.1)
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.13
	tm.outer_radius = 0.17
	mi.mesh = tm
	mi.material_override = hb.mats["metal"]
	wheel.add_child(mi)
	for i in 3:
		var sp := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.3, 0.03, 0.03)
		sp.mesh = bm
		sp.material_override = hb.mats["metal"]
		sp.rotation.y = i * PI / 3.0
		wheel.add_child(sp)
	var stem := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.03
	cm.bottom_radius = 0.03
	cm.height = 0.2
	stem.mesh = cm
	stem.material_override = hb.mats["metal"]
	stem.position = Vector3(0, 0.02, -0.1)
	v.add_child(stem)
	v.wheel = wheel
	return v

# ---------- street ----------
func _street_props() -> void:
	# main entrance door (south wall z=9, x=0)
	var d: DoorObj = hb._door("main_door", 0, 9, "x", false, "", "", 1)
	d.position = Vector3(-0.49, 0, 9)
	# puddle reflections decor done; shoes by door
	_box(Vector3(0.22, 0.09, 0.3), Vector3(0.9, 0.05, 8.8), hb.mats["dark"])

# ---------- vestibule ----------
func _vestibule() -> void:
	# bench
	_box(Vector3(1.4, 0.1, 0.42), Vector3(-2.2, 0.42, 8.4), hb.mats["wood"])
	_box(Vector3(0.1, 0.4, 0.4), Vector3(-2.85, 0.2, 8.4), hb.mats["wood_dark"])
	_box(Vector3(0.1, 0.4, 0.4), Vector3(-1.55, 0.2, 8.4), hb.mats["wood_dark"])
	# lantern on bench
	var lan := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.16, 0.24, 0.16)
	lan.mesh = bm
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color(0.9, 0.7, 0.4)
	lm.emission_enabled = true
	lm.emission = Color(0.9, 0.65, 0.3)
	lm.emission_energy_multiplier = 1.6
	lan.material_override = lm
	lan.position = Vector3(-2.3, 0.6, 8.5)
	hb.add_child(lan)
	# wall niche with note
	_box(Vector3(0.5, 0.7, 0.18), Vector3(2.75, 1.35, 6.4), hb.mats["plaster_dark"], false)
	_note("vest_note", "note_vestibule", Vector3(2.55, 1.3, 6.4), PI / 2.0, "read_vestibule_note")
	# old shoes pair
	_box(Vector3(0.1, 0.07, 0.26), Vector3(1.1, 0.04, 8.6), hb.mats["dark"])
	_box(Vector3(0.1, 0.07, 0.26), Vector3(1.3, 0.04, 8.65), hb.mats["dark"])
	# faded inscription plaque
	_box(Vector3(0.8, 0.4, 0.05), Vector3(0, 1.8, 4.42), hb.mats["paper"], false)
	# inner door vestibule -> courtyard (already in wall gap at x=0)
	hb._door("vest_door", 0, 4.3, "x", false, "", "", 1)

# ---------- courtyard ----------
func _courtyard_props() -> void:
	# clay pots
	for i in 3:
		var pot := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.22
		cm.bottom_radius = 0.14
		cm.height = 0.5
		pot.mesh = cm
		var pm := StandardMaterial3D.new()
		pm.albedo_color = Color(0.45, 0.3, 0.22)
		pm.roughness = 1.0
		pot.material_override = pm
		pot.position = Vector3(4.1 + i * 0.35, 0.25, -3.3 - i * 0.2)
		hb.add_child(pot)
		var col := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := CylinderShape3D.new()
		bs.radius = 0.22
		bs.height = 0.5
		cs.shape = bs
		col.add_child(cs)
		col.position = pot.position
		col.set_meta("surface", "stone")
		hb.add_child(col)
	# pool outlet valve V1 (needs handle)
	_valve("valve1", 1, Vector3(1.9, 0.35, 2.0), true)
	# stone walkway decor (flat slabs)
	for i in 5:
		_box(Vector3(0.8, 0.02, 0.5), Vector3(-2.0 + i * 1.0, 0.012, 3.6), hb.mats["stone"], false)
	# rug visible through family door
	_box(Vector3(1.4, 0.02, 2.0), Vector3(-4.2, 0.012, 5.6), hb.mats["carpet"], false)

# ---------- family room ----------
func _family_room() -> void:
	# low seating (traditional)
	_box(Vector3(3.6, 0.35, 1.0), Vector3(-6.8, 0.175, 8.2), hb.mats["carpet"])
	_box(Vector3(3.6, 0.35, 0.9), Vector3(-6.8, 0.175, 4.9), hb.mats["carpet"])
	# cushions
	for i in 3:
		_box(Vector3(0.5, 0.16, 0.5), Vector3(-8.1 + i * 1.3, 0.43, 8.2), hb.mats["carpet"], false)
	# wooden table + samovar + tea glasses
	_box(Vector3(1.2, 0.5, 0.7), Vector3(-6.8, 0.25, 6.5), hb.mats["wood_dark"])
	var sam := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.14
	cm.bottom_radius = 0.2
	cm.height = 0.45
	sam.mesh = cm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.72, 0.55, 0.3)
	sm.metallic = 0.8
	sm.roughness = 0.3
	sam.material_override = sm
	sam.position = Vector3(-6.8, 0.72, 6.5)
	hb.add_child(sam)
	for i in 2:
		var g := MeshInstance3D.new()
		var gm := CylinderMesh.new()
		gm.top_radius = 0.035
		gm.bottom_radius = 0.025
		gm.height = 0.09
		g.mesh = gm
		g.material_override = sm
		g.position = Vector3(-6.4 + i * 0.2, 0.55, 6.3)
		hb.add_child(g)
	# radio on shelf
	var radio: RadioObj = _interactable("res://scripts/interact/radio.gd", Vector3(-10.2, 1.05, 7.6), "radio")
	var rmesh := MeshInstance3D.new()
	var rbm := BoxMesh.new()
	rbm.size = Vector3(0.4, 0.24, 0.18)
	rmesh.mesh = rbm
	rmesh.material_override = hb.mats["wood_dark"]
	rmesh.position.y = 0.12
	radio.add_child(rmesh)
	_box(Vector3(1.2, 0.06, 0.4), Vector3(-10.2, 0.9, 7.6), hb.mats["wood"])  # shelf
	# bookshelf
	_box(Vector3(0.4, 1.8, 2.2), Vector3(-10.5, 0.9, 5.4), hb.mats["wood_dark"])
	# family drawer with folded photograph
	_drawer("family_drawer", Vector3(-10.3, 0, 6.4), Vector3(0.5, 0.22, 0.45), 0.42, "photo")
	# wall photos (3)
	_photo("photo_a", "p1348", Vector3(-8.5, 1.7, 8.85), 0.0)
	_photo("photo_b", "p1357", Vector3(-6.5, 1.7, 8.85), 0.0)
	_photo("photo_c", "p1373", Vector3(-4.5, 1.7, 8.85), 0.0)
	# wall clock decor (non-interactive here); interactive clock is in corridor
	# carpet
	_box(Vector3(4.2, 0.02, 3.0), Vector3(-6.8, 0.012, 6.6), hb.mats["carpet"], false)
	# door family -> courtyard
	hb._door("family_door", -4.2, 4.3, "x", false, "", "", 1)

# ---------- kitchen ----------
func _kitchen() -> void:
	# counters
	_box(Vector3(2.6, 0.9, 0.6), Vector3(-9.7, 0.45, -3.6), hb.mats["wood_dark"])
	_box(Vector3(0.6, 0.9, 2.4), Vector3(-10.6, 0.45, -2.2), hb.mats["wood_dark"])
	# stove
	_box(Vector3(0.7, 0.85, 0.6), Vector3(-7.9, 0.43, -3.6), hb.mats["metal"])
	# copper pots on counter
	for i in 2:
		var pot := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.12
		cm.bottom_radius = 0.1
		cm.height = 0.16
		pot.mesh = cm
		var pm := StandardMaterial3D.new()
		pm.albedo_color = Color(0.7, 0.5, 0.28)
		pm.metallic = 0.7
		pot.material_override = pm
		pot.position = Vector3(-9.4 + i * 0.4, 1.0, -3.6)
		hb.add_child(pot)
	# tap + sink
	_box(Vector3(0.5, 0.12, 0.4), Vector3(-10.6, 0.95, -2.2), hb.mats["metal"], false)
	# fridge (old)
	_box(Vector3(0.7, 1.6, 0.65), Vector3(-7.7, 0.8, -0.7), hb.mats["metal"])
	# shelves
	_box(Vector3(1.8, 0.05, 0.35), Vector3(-9.2, 1.6, -3.72), hb.mats["wood"], false)
	# drawer (empty decor with dried herbs? decorative)
	_drawer("kitchen_drawer", Vector3(-9.9, 0.9, -3.6), Vector3(0.45, 0.2, 0.4), 0.4, "")
	# door kitchen -> corridor
	hb._door("kitchen_door", -2, -7.2, "z", false, "", "", 1)

# ---------- corridor ----------
func _corridor() -> void:
	# fusebox on east wall
	var fb: Fusebox = _interactable("res://scripts/interact/fusebox.gd", Vector3(-5.38, 1.35, 3.4), "fusebox", PI / 2.0)
	var fm := MeshInstance3D.new()
	var fbm := BoxMesh.new()
	fbm.size = Vector3(0.34, 0.5, 0.14)
	fm.mesh = fbm
	fm.material_override = hb.mats["metal"]
	fm.position.y = 0.1
	fb.add_child(fm)
	# instruction note pinned next to fusebox
	_note("fuse_note", "fuse_instr", Vector3(-5.38, 1.35, 2.85), PI / 2.0)
	# wall clock (interactive) on west wall
	var clock: WallClock = _interactable("res://scripts/interact/wall_clock.gd", Vector3(-7.02, 1.8, 3.3), "wall_clock", -PI / 2.0)
	var cmesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.28
	cyl.bottom_radius = 0.28
	cyl.height = 0.07
	cmesh.mesh = cyl
	cmesh.rotation.x = PI / 2.0
	cmesh.material_override = hb.mats["wood"]
	cmesh.position.y = 0.1
	clock.add_child(cmesh)
	# shelf + family photographs (decor frames)
	_box(Vector3(0.35, 0.05, 1.2), Vector3(-6.9, 1.2, -1.0), hb.mats["wood"], false)
	# V3 boiler valve at corridor north end
	_valve("valve3", 3, Vector3(-6.2, 1.05, -3.9), false)
	# boiler
	_box(Vector3(0.8, 1.4, 0.6), Vector3(-6.9, 0.7, -3.85), hb.mats["metal"])
	# door corridor -> courtyard
	hb._door("corr_door", 0, -5.2, "z", false, "", "", 1)
	# door study (locked, brass key)
	hb._door("study_door", 2, -7.2, "z", true, Fa.MSG["study_locked"], "brass_key", 1)

# ---------- study ----------
func _study() -> void:
	# desk
	_box(Vector3(1.7, 0.08, 0.8), Vector3(-9.0, 0.75, 3.2), hb.mats["wood_dark"])
	_box(Vector3(0.08, 0.75, 0.7), Vector3(-9.8, 0.375, 3.2), hb.mats["wood_dark"])
	_box(Vector3(0.08, 0.75, 0.7), Vector3(-8.2, 0.375, 3.2), hb.mats["wood_dark"])
	# desk lamp
	var lamp := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.1
	lm.bottom_radius = 0.05
	lm.height = 0.25
	lamp.mesh = lm
	var lmt := StandardMaterial3D.new()
	lmt.albedo_color = Color(0.2, 0.2, 0.22)
	lamp.material_override = lmt
	lamp.position = Vector3(-9.6, 0.92, 3.2)
	hb.add_child(lamp)
	# files & diagram notes
	_note("study_files", "study_files", Vector3(-8.8, 0.84, 3.15), 0.4)
	_note("study_diagram", "study_diagram", Vector3(-8.45, 0.84, 3.3), -0.5)
	# symbols notebook (gives paper)
	_note("symbols_note", "symbols_note", Vector3(-9.25, 0.84, 3.35), 0.2)
	# hand-drawn floor plan on wall
	_box(Vector3(1.1, 0.8, 0.04), Vector3(-10.85, 1.8, 3.0), hb.mats["paper"], false)
	# typewriter decor
	_box(Vector3(0.4, 0.15, 0.35), Vector3(-8.75, 0.86, 3.4), hb.mats["dark"])
	# telephone
	_interactable("res://scripts/interact/telephone.gd", Vector3(-9.35, 0.84, 2.9), "phone")
	# CODE drawer (valve handle inside)
	_drawer("study_drawer", Vector3(-9.0, 0.35, 3.2), Vector3(0.55, 0.22, 0.5), 0.5, "valve_handle", true)

# ---------- grandmother's room ----------
func _grandmother() -> void:
	# bed
	_box(Vector3(1.8, 0.45, 1.1), Vector3(-5.4, 0.225, -8.2), hb.mats["wood_dark"])
	_box(Vector3(1.7, 0.14, 1.0), Vector3(-5.4, 0.52, -8.2), hb.mats["carpet"], false)
	# folded blanket
	_box(Vector3(0.6, 0.12, 0.5), Vector3(-4.7, 0.6, -8.3), hb.mats["carpet"], false)
	# diary on bed
	_note("diary", "diary", Vector3(-5.9, 0.62, -8.1), 0.3, "read_diary")
	# wardrobe with cassette inside (sliding)
	_drawer("wardrobe", Vector3(-1.0, 0, -8.5), Vector3(1.1, 1.9, 0.55), 0.9, "cassette")
	# bedside table
	_box(Vector3(0.45, 0.55, 0.45), Vector3(-4.4, 0.275, -8.4), hb.mats["wood"])
	# framed photo on table (p1361)
	_photo("photo_d", "p1361", Vector3(-4.4, 0.75, -8.4), 0.0)
	# small mirror decor
	_box(Vector3(0.3, 0.5, 0.04), Vector3(-2.9, 1.6, -8.85), _mat_metal_smooth(), false)
	# prayer rug
	_box(Vector3(0.9, 0.02, 1.5), Vector3(-2.0, 0.012, -6.0), hb.mats["carpet"], false)
	# wooden chest (decor locked)
	var chest := _box(Vector3(0.9, 0.5, 0.55), Vector3(-6.0, 0.25, -5.2), hb.mats["wood"])
	chest.set_meta("surface", "wood")
	# cassette player on bedside table
	_interactable("res://scripts/interact/cassette_player.gd", Vector3(-4.4, 0.75, -7.9), "cassette_player")
	# carpet
	_box(Vector3(3.4, 0.02, 2.4), Vector3(-3.5, 0.012, -5.8), hb.mats["carpet"], false)
	# door grandmother -> courtyard
	hb._door("grand_door", -3.5, -4.3, "x", false, "", "", 1)

func _mat_metal_smooth() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.75, 0.8, 0.82)
	m.metallic = 0.9
	m.roughness = 0.05
	return m

# ---------- bathroom & service ----------
func _bathroom() -> void:
	# sink
	var sink := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.28
	cm.bottom_radius = 0.18
	cm.height = 0.5
	sink.mesh = cm
	sink.material_override = hb.mats["tile"]
	sink.position = Vector3(1.2, 0.45, -8.6)
	hb.add_child(sink)
	# mirror (interactive)
	_interactable("res://scripts/interact/mirror.gd", Vector3(1.2, 1.55, -8.82), "bath_mirror")
	var mm := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.55, 0.7)
	mm.mesh = qm
	mm.material_override = _mat_metal_smooth()
	mm.position.y = 0.1
	var mnode = hb.reg["bath_mirror"]
	mnode.add_child(mm)
	mm.position = Vector3(0, 0.1, 0.05)
	# old cabinet
	_box(Vector3(0.5, 0.7, 0.35), Vector3(4.1, 1.1, -8.6), hb.mats["wood_dark"])
	# pipes along wall
	for i in 2:
		var pipe := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.045
		pm.bottom_radius = 0.045
		pm.height = 3.0
		pipe.mesh = pm
		pipe.material_override = hb.mats["metal"]
		pipe.rotation.z = PI / 2.0
		pipe.position = Vector3(2.4, 2.6 - i * 0.25, -8.7)
		hb.add_child(pipe)
	# V2 service valve
	_valve("valve2", 2, Vector3(3.4, 1.05, -8.75), false)
	# dripping tap sound source (decor audio played via zone later)
	# door bathroom -> courtyard
	hb._door("bath_door", 2.5, -4.3, "x", false, "", "", 1)

# ---------- storage ----------
func _storage() -> void:
	# shelves with boxes
	for i in 3:
		_box(Vector3(2.2, 0.05, 0.5), Vector3(7.4, 0.5 + i * 0.55, 8.6), hb.mats["wood"], false)
	for i in 4:
		_box(Vector3(0.4, 0.3, 0.35), Vector3(6.7 + (i % 2) * 0.7, 0.7 + (i / 2) * 0.55, 8.55), hb.mats["wood_dark"], false)
	# clay jars
	for i in 3:
		var jar := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.2
		cm.bottom_radius = 0.26
		cm.height = 0.7
		jar.mesh = cm
		var pm := StandardMaterial3D.new()
		pm.albedo_color = Color(0.5, 0.38, 0.28)
		jar.material_override = pm
		jar.position = Vector3(9.8, 0.35, 5.4 + i * 0.7)
		hb.add_child(jar)
	# FUSE on shelf
	_pickup("fuse_pickup", "fuse", Vector3(7.9, 1.68, 8.5))
	# door storage -> courtyard
	hb._door("stor_door", 4.2, 4.3, "x", false, "", "", 1)

# ---------- east stair room (basement entrance decoy) ----------
func _stair_room() -> void:
	# stone steps descending partway
	for i in 3:
		_box(Vector3(2.2, 0.3, 0.5), Vector3(8.2, -0.15 - i * 0.3, -1.2 + i * 0.5), hb.mats["stone_b"], false)
	hb._ramp(Vector3(8.2, -0.45, 0.1), 2.2, 2.1, 31.0)
	# heavy metal door at the bottom (locked forever)
	var door: LockedDoorMsg = _interactable("res://scripts/interact/locked_msg_door.gd", Vector3(10.2, 0.4, -0.2), "base_decoy", PI / 2.0)
	door.msg = Fa.MSG["basement_locked"]
	door.prompt = Fa.PROMPT["open"]
	var dm := MeshInstance3D.new()
	var dbm := BoxMesh.new()
	dbm.size = Vector3(1.1, 2.0, 0.12)
	dm.mesh = dbm
	dm.material_override = hb.mats["metal"]
	dm.position = Vector3(0, 1.0, 0)
	door.add_child(dm)
	# old lock
	_box(Vector3(0.1, 0.16, 0.08), Vector3(10.14, 1.0, -0.2), hb.mats["metal"])
	# pipes decor
	var pipe := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.05
	pm.bottom_radius = 0.05
	pm.height = 4.0
	pipe.mesh = pm
	pipe.material_override = hb.mats["metal"]
	pipe.rotation.z = PI / 2.0
	pipe.position = Vector3(8.2, 2.7, 2.2)
	hb.add_child(pipe)
	# door stair room -> courtyard
	hb._door("stair_door", 0, 5.2, "z", true, Fa.MSG["cold_draft"], "", 1)

# ---------- basement props ----------
func _basement_props() -> void:
	hb._place_basement_door()
	var y := -3.8
	# storage shelves
	for i in 2:
		_box(Vector3(2.6, 0.05, 0.5), Vector3(-6.6, y + 0.6 + i * 0.6, -7.6), hb.mats["wood"], false)
	# clay jars row
	for i in 5:
		var jar := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.22
		cm.bottom_radius = 0.3
		cm.height = 0.8
		jar.mesh = cm
		var pm := StandardMaterial3D.new()
		pm.albedo_color = Color(0.45, 0.36, 0.28)
		jar.material_override = pm
		jar.position = Vector3(-7.2 + i * 0.7, y + 0.4, -3.0)
		hb.add_child(jar)
	# work table + documents
	_box(Vector3(1.6, 0.08, 0.9), Vector3(-1.0, y + 0.85, -6.6), hb.mats["wood_dark"])
	_box(Vector3(0.08, 0.85, 0.8), Vector3(-1.75, y + 0.42, -6.6), hb.mats["wood_dark"])
	_box(Vector3(0.08, 0.85, 0.8), Vector3(-0.25, y + 0.42, -6.6), hb.mats["wood_dark"])
	_note("base_docs", "chamber_report", Vector3(-1.0, y + 0.95, -6.6), 0.3)
	# concealed wall panel decor
	_box(Vector3(0.9, 1.3, 0.06), Vector3(1.9, y + 1.3, -4.0), hb.mats["stone_b"], false)
	# final chamber: stone table with passage key + report
	_box(Vector3(1.4, 0.85, 0.8), Vector3(-5.5, y + 0.425, 3.2), hb.mats["stone_b"])
	_note("chamber_docs", "chamber_report", Vector3(-5.5, y + 0.92, 3.1), 0.2)
	# passage key pickup (appears always; taking it enables ending A)
	_pickup("passage_key_pickup", "passage_key", Vector3(-5.3, y + 0.95, 3.35))
	# final pool interactable (ending B)
	var fc: FinalChoice = _interactable("res://scripts/interact/final_choice.gd", Vector3(-4.6, y + 0.6, 4.2), "final_pool")
	fc.mode = "pool"
	fc.prompt = Fa.PROMPT["look"]
	# spawn_passage_door target area marker (door mesh created by game on demand)
	# basement drip sound decor handled by game ambience
