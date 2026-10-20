extends Node3D
## HouseBuilder — procedural traditional Kashan courtyard house (ground + basement).
## Everything is built from primitive meshes + generated textures.

const WALL_H := 3.3
const BASE_Y := -3.8

var reg := {}           # registry of interactables / key nodes
var pool: WaterPool
var mats := {}
var lights := {}
var rain_particles: GPUParticles3D
var _world_env: WorldEnvironment

func build(menu_mode: bool = false) -> void:
        _make_materials()
        _environment()
        _floors()
        _ground_walls()
        _roofs()
        _basement_structure()
        _pool_and_tree()
        _street()
        _lights()
        _props()
        _rain()
        if not menu_mode:
                _triggers()
        add_to_group("world_root")

func apply_quality(q: int) -> void:
        if lights.has("moon"):
                lights["moon"].shadow_enabled = q >= 1
        if _world_env != null and _world_env.environment != null:
                _world_env.environment.fog_enabled = q >= 1

# ================= materials =================
func _mat(id: String, tex: String, uv := Vector3(1, 1, 1), rough := 0.9, col := Color(1, 1, 1)) -> StandardMaterial3D:
        if mats.has(id):
                return mats[id]
        var m := StandardMaterial3D.new()
        if tex != "":
                m.albedo_texture = load(tex)
        m.albedo_color = col
        m.uv1_scale = uv
        m.roughness = rough
        mats[id] = m
        return m

func _make_materials() -> void:
        _mat("plaster", "res://assets/textures/plaster_old.png", Vector3(3, 1.2, 1), 0.95)
        _mat("plaster_dark", "res://assets/textures/plaster_dark.png", Vector3(3, 1.2, 1), 0.95)
        _mat("brick", "res://assets/textures/brick.png", Vector3(4, 2, 1), 0.95)
        _mat("stone", "res://assets/textures/stone_floor.png", Vector3(6, 6, 6), 0.7)
        _mat("stone_b", "res://assets/textures/stone_basement.png", Vector3(4, 1.2, 1), 0.95)
        _mat("wood_floor", "res://assets/textures/wood_dark.png", Vector3(4, 4, 1), 0.8)
        _mat("wood", "res://assets/textures/wood_door.png", Vector3(1, 1, 1), 0.85)
        _mat("wood_dark", "res://assets/textures/wood_dark.png", Vector3(1, 1, 1), 0.85)
        _mat("tile", "res://assets/textures/tile_dark.png", Vector3(4, 4, 1), 0.5)
        _mat("carpet", "res://assets/textures/carpet.png", Vector3(1, 1, 1), 0.95)
        _mat("metal", "res://assets/textures/metal_rust.png", Vector3(1, 1, 1), 0.55, Color(0.8, 0.75, 0.7))
        _mat("paper", "res://assets/textures/paper_old.png", Vector3(1, 1, 1), 0.95)
        _mat("dark", "", Vector3.ONE, 0.95, Color(0.05, 0.05, 0.06))

# ================= helpers =================
func _box(sz: Vector3, pos: Vector3, mat: Material, collide := true, surface := "stone", parent: Node = null) -> MeshInstance3D:
        var mi := MeshInstance3D.new()
        var bm := BoxMesh.new()
        bm.size = sz
        mi.mesh = bm
        mi.material_override = mat
        mi.position = pos
        (parent if parent != null else self).add_child(mi)
        if collide:
                var sb := StaticBody3D.new()
                sb.collision_layer = 5
                var cs := CollisionShape3D.new()
                var bs := BoxShape3D.new()
                bs.size = sz
                cs.shape = bs
                sb.add_child(cs)
                sb.position = pos
                sb.set_meta("surface", surface)
                (parent if parent != null else self).add_child(sb)
        return mi

## Axis-aligned wall from (ax,az) to (bx,bz); gaps: [{c,w,y0,y1}]
func _wall(ax: float, az: float, bx: float, bz: float, mat: Material, h := WALL_H, y0 := 0.0, gaps := [], th := 0.25) -> void:
        var along_x := absf(bx - ax) > absf(bz - az)
        var length := (bx - ax) if along_x else (bz - az)
        var start := ax if along_x else az
        var sorted := gaps.duplicate()
        sorted.sort_custom(func(a, b): return a["c"] < b["c"])
        var cursor := 0.0
        for g in sorted:
                var gs: float = g["c"] - g["w"] / 2.0
                var ge: float = g["c"] + g["w"] / 2.0
                if gs > cursor:
                        _wall_chunk(start + cursor, start + gs, along_x, az if along_x else ax, mat, h, y0, th)
                # lintel
                if g["y1"] < h:
                        _wall_chunk_at(start + gs, start + ge, along_x, az if along_x else ax, mat, h, g["y1"], th)
                # sill
                if g["y0"] > y0:
                        _wall_chunk_low(start + gs, start + ge, along_x, az if along_x else ax, mat, g["y0"], y0, th)
                cursor = ge
        if cursor < length:
                _wall_chunk(start + cursor, start + length, along_x, az if along_x else ax, mat, h, y0, th)

func _wall_chunk(a: float, b: float, along_x: bool, other: float, mat: Material, h: float, y0: float, th: float) -> void:
        if b - a < 0.01 or h - y0 < 0.01:
                return
        var sz := Vector3(b - a, h - y0, th) if along_x else Vector3(th, h - y0, b - a)
        var pos := Vector3((a + b) / 2.0, y0 + (h - y0) / 2.0, other) if along_x else Vector3(other, y0 + (h - y0) / 2.0, (a + b) / 2.0)
        _box(sz, pos, mat, true, "stone")

func _wall_chunk_at(a: float, b: float, along_x: bool, other: float, mat: Material, h: float, y1: float, th: float) -> void:
        if b - a < 0.01 or h - y1 < 0.01:
                return
        var sz := Vector3(b - a, h - y1, th) if along_x else Vector3(th, h - y1, b - a)
        var pos := Vector3((a + b) / 2.0, y1 + (h - y1) / 2.0, other) if along_x else Vector3(other, y1 + (h - y1) / 2.0, (a + b) / 2.0)
        _box(sz, pos, mat, true, "stone")

func _wall_chunk_low(a: float, b: float, along_x: bool, other: float, mat: Material, top: float, bottom: float, th: float) -> void:
        if b - a < 0.01 or top - bottom < 0.01:
                return
        var sz := Vector3(b - a, top - bottom, th) if along_x else Vector3(th, top - bottom, b - a)
        var pos := Vector3((a + b) / 2.0, bottom + (top - bottom) / 2.0, other) if along_x else Vector3(other, bottom + (top - bottom) / 2.0, (a + b) / 2.0)
        _box(sz, pos, mat, true, "stone")

## Create a DoorObj in a wall gap. axis "x": wall runs along x; hinge at west/left edge.
func _door(id: String, c: float, other: float, axis: String, locked := false, msg := "", key_item := "", open_dir := -1) -> DoorObj:
        var door: DoorObj = load("res://scripts/interact/door.gd").new()
        door.name = "Door_" + id
        add_child(door)
        if axis == "x":
                door.position = Vector3(c - 0.49, 0, other)
        else:
                door.position = Vector3(other, 0, c - 0.49)
                door.rotation.y = PI / 2.0
        var mi := MeshInstance3D.new()
        var bm := BoxMesh.new()
        bm.size = Vector3(0.98, 2.06, 0.09)
        mi.mesh = bm
        mi.material_override = mats["wood"]
        mi.position = Vector3(0.49, 1.03, 0)
        door.add_child(mi)
        # iron knocker decor
        var kn := MeshInstance3D.new()
        var km := BoxMesh.new()
        km.size = Vector3(0.06, 0.12, 0.04)
        kn.mesh = km
        kn.material_override = mats["metal"]
        kn.position = Vector3(0.75, 1.25, -0.07)
        door.add_child(kn)
        var cs := CollisionShape3D.new()
        var bs := BoxShape3D.new()
        bs.size = Vector3(0.98, 2.06, 0.12)
        cs.shape = bs
        cs.position = Vector3(0.49, 1.03, 0)
        door.add_child(cs)
        door.collision_layer = 5
        door.collision_mask = 0
        door.setup(door, locked, msg)
        door.key_item = key_item
        door.is_open_angle = open_dir * 100.0
        reg[id] = door
        return door

func _lamp(id: String, pos: Vector3, col := Color(1.0, 0.72, 0.42), energy := 1.6, dist := 7.0, on := true, shadows := false) -> OmniLight3D:
        # visual bulb
        var bulb := MeshInstance3D.new()
        var sm := SphereMesh.new()
        sm.radius = 0.09
        sm.height = 0.18
        bulb.mesh = sm
        var bm := StandardMaterial3D.new()
        bm.albedo_color = col
        bm.emission_enabled = true
        bm.emission = col
        bm.emission_energy_multiplier = 3.0 if on else 0.0
        bulb.material_override = bm
        bulb.position = pos
        add_child(bulb)
        # housing
        _box(Vector3(0.22, 0.06, 0.22), pos + Vector3(0, 0.16, 0), mats["metal"], false)
        var l := OmniLight3D.new()
        l.light_color = col
        l.light_energy = energy if on else 0.0
        l.omni_range = dist
        l.shadow_enabled = shadows
        l.position = pos
        l.set_meta("base_energy", energy)
        add_child(l)
        lights[id] = l
        return l

func _interactable(script_path: String, pos: Vector3, id: String, rot_y := 0.0) -> Node:
        var n: Node = load(script_path).new()
        n.name = id
        add_child(n)
        n.position = pos
        n.rotation.y = rot_y
        n.collision_layer = 4
        n.collision_mask = 0
        var cs := CollisionShape3D.new()
        var bs := BoxShape3D.new()
        bs.size = Vector3(0.45, 0.45, 0.3)
        cs.shape = bs
        cs.position = Vector3(0, 0.05, 0)
        n.add_child(cs)
        reg[id] = n
        return n

func _note(id: String, text_key: String, pos: Vector3, rot_y := 0.0, once := "") -> NoteObj:
        var n: NoteObj = _interactable("res://scripts/interact/note_obj.gd", pos, id, rot_y)
        n.setup_note(text_key, once)
        return n

func _photo(id: String, photo_key: String, pos: Vector3, rot_y := 0.0) -> NoteObj:
        var n: NoteObj = _interactable("res://scripts/interact/note_obj.gd", pos, id, rot_y)
        n.setup_photo(photo_key)
        # visible photo quad
        var mi := MeshInstance3D.new()
        var qm := QuadMesh.new()
        qm.size = Vector2(0.34, 0.42)
        mi.mesh = qm
        var pm := StandardMaterial3D.new()
        pm.albedo_texture = load(Fa.PHOTOS[photo_key]["img"])
        pm.emission_enabled = true
        pm.emission = Color(0.25, 0.22, 0.18)
        pm.emission_energy_multiplier = 0.4
        mi.material_override = pm
        mi.position = Vector3(0, 0.1, 0.02)
        n.add_child(mi)
        return n

func _pickup(id: String, item: String, pos: Vector3) -> Node:
        var p: Node = load("res://scripts/interact/pickup.gd").new()
        p.item_id = item
        add_child(p)
        p.position = pos
        reg[id] = p
        return p

# ================= environment =================
func _environment() -> void:
        _world_env = WorldEnvironment.new()
        var env := Environment.new()
        env.background_mode = Environment.BG_SKY
        var sky := Sky.new()
        var sm := ProceduralSkyMaterial.new()
        sm.sky_top_color = Color(0.015, 0.025, 0.06)
        sm.sky_horizon_color = Color(0.06, 0.08, 0.11)
        sm.ground_bottom_color = Color(0.01, 0.012, 0.02)
        sm.ground_horizon_color = Color(0.05, 0.065, 0.09)
        sm.sun_angle_max = 8.0
        sky.sky_material = sm
        env.sky = sky
        env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
        env.ambient_light_color = Color(0.12, 0.16, 0.22)
        env.ambient_light_energy = 0.55
        env.fog_enabled = true
        env.fog_light_color = Color(0.05, 0.07, 0.1)
        env.fog_density = 0.012
        env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
        env.glow_enabled = true
        env.glow_intensity = 0.4
        env.glow_bloom = 0.05
        _world_env.environment = env
        add_child(_world_env)

        var moon := DirectionalLight3D.new()
        moon.light_color = Color(0.6, 0.72, 0.95)
        moon.light_energy = 0.32
        moon.rotation_degrees = Vector3(-52, 28, 0)
        moon.shadow_enabled = true
        moon.directional_shadow_max_distance = 34.0
        add_child(moon)
        lights["moon"] = moon

# ================= floors =================
func _floor_slab(x0: float, z0: float, x1: float, z1: float, y: float, mat: Material, surface: String, th := 0.12) -> void:
        var sz := Vector3(x1 - x0, th, z1 - z0)
        var pos := Vector3((x0 + x1) / 2.0, y - th / 2.0, (z0 + z1) / 2.0)
        _box(sz, pos, mat, true, surface)

func _floors() -> void:
        # street
        _floor_slab(-4, 9.2, 4, 15.0, 0.0, _mat("street", "res://assets/textures/stone_floor.png", Vector3(4, 6, 1), 0.75, Color(0.6, 0.6, 0.62)), "stone")
        # courtyard
        _floor_slab(-5, -4, 0.7, 4.3, 0.0, mats["stone"], "stone")
        _floor_slab(2.15, -4, 5, 4.3, 0.0, mats["stone"], "stone")
        _floor_slab(0.7, -0.6, 2.15, 4.3, 0.0, mats["stone"], "stone")
        _floor_slab(0.7, -4, 2.15, -2.6, 0.0, mats["stone"], "stone")
        # permanent grate over the upper stair trench (walkable, flush with floor)
        _box(Vector3(1.45, 0.12, 2.0), Vector3(1.425, -0.06, -1.6), mats["metal"], true, "metal")
        # cover slit above shaft between slabs
        _box(Vector3(1.45, 0.12, 0.6), Vector3(1.425, -0.18, -4.15), mats["dark"], false)
        # south wing
        _floor_slab(-10.75, 4.3, -2.9, 9, 0.0, mats["wood_floor"], "wood")      # family
        _floor_slab(-2.9, 4.3, 2.9, 9, 0.0, mats["stone"], "stone")             # vestibule
        _floor_slab(2.9, 4.3, 10.75, 9, 0.0, mats["stone"], "stone")            # storage
        # west wing
        _floor_slab(-7.2, -4, -5.2, 4.3, 0.0, mats["stone"], "stone")           # corridor
        _floor_slab(-11, -4, -7.2, -0.2, 0.0, mats["tile"], "tile")             # kitchen
        _floor_slab(-11, 0.2, -7.2, 4, 0.0, mats["wood_floor"], "wood")         # study
        # north wing
        _floor_slab(-6.5, -9, -0.5, -4.3, 0.0, mats["wood_floor"], "wood")      # grandmother
        _floor_slab(0.5, -9, 4.5, -4.3, 0.0, mats["tile"], "tile")              # bathroom
        # east wing
        _floor_slab(5.2, -2.5, 10.75, 2.5, 0.0, mats["stone"], "stone")         # stair room
        # basement slab
        _floor_slab(-8.5, -8.5, 2.5, 6, BASE_Y, mats["stone_b"], "stone")

# ================= walls =================
func _ground_walls() -> void:
        var p: StandardMaterial3D = mats["plaster"]
        var pb: StandardMaterial3D = mats["brick"]
        # outer perimeter (compound)
        _wall(-11, 9, 11, 9, pb, WALL_H, 0, [{"c": 5 + 11, "w": 1.1, "y0": 0, "y1": 2.2}])       # south (main door at x=0)
        _wall(-11, -9, 11, -9, p)                                                                  # north
        _wall(-11, -9, -11, 9, p)                                                                  # west
        _wall(11, -9, 11, 9, p)                                                                    # east
        # south wing inner wall (courtyard side) z=4.3 — doors: family(-4.2), vestibule(0), storage(4.2)
        _wall(-11, 4.3, 11, 4.3, p, WALL_H, 0, [
                {"c": -4.2 + 11, "w": 1.1, "y0": 0, "y1": 2.15},
                {"c": 0 + 11, "w": 1.1, "y0": 0, "y1": 2.15},
                {"c": 4.2 + 11, "w": 1.1, "y0": 0, "y1": 2.15},
        ])
        # south wing dividers
        _wall(-2.9, 4.3, -2.9, 9, p)
        _wall(2.9, 4.3, 2.9, 9, p)
        # west wing: courtyard side x=-5.2 (door at z=0), kitchen/study divider x=-7.2 (doors z=-2, z=2)
        _wall(-5.2, -4, -5.2, 4.3, p, WALL_H, 0, [{"c": 4 + 4.3, "w": 1.1, "y0": 0, "y1": 2.15}])
        _wall(-7.2, -4, -7.2, 4.3, p, WALL_H, 0, [
                {"c": -2 + 4.3, "w": 1.1, "y0": 0, "y1": 2.15},
                {"c": 2 + 4.3, "w": 1.1, "y0": 0, "y1": 2.15},
        ])
        # kitchen/study divider z=-0.2
        _wall(-11, -0.2, -7.2, -0.2, p)
        # north wing inner wall z=-4.3 — doors: grandmother(-3.5), bathroom(2.5)
        _wall(-11, -4.3, 11, -4.3, p, WALL_H, 0, [
                {"c": -3.5 + 11, "w": 1.1, "y0": 0, "y1": 2.15},
                {"c": 2.5 + 11, "w": 1.1, "y0": 0, "y1": 2.15},
        ])
        # north wing dividers
        _wall(-6.5, -9, -6.5, -4.3, p)
        _wall(-0.5, -9, -0.5, -4.3, p)
        _wall(4.5, -9, 4.5, -4.3, p)
        # east wing (stair room) x=5.2 wall with door z=0, and side walls
        _wall(5.2, -4, 5.2, 4.3, p, WALL_H, 0, [{"c": 2.5 + 4, "w": 1.1, "y0": 0, "y1": 2.15}])
        _wall(5.2, -2.5, 10.75, -2.5, p)
        _wall(5.2, 2.5, 10.75, 2.5, p)

func _roofs() -> void:
        var r: StandardMaterial3D = mats["plaster_dark"]
        _box(Vector3(22, 0.3, 4.9), Vector3(0, WALL_H + 0.15, 6.65), r, false)    # south wing roof
        _box(Vector3(6, 0.3, 8.5), Vector3(-9.1, WALL_H + 0.15, -0.1), r, false)  # west wing roof
        _box(Vector3(13, 0.3, 4.9), Vector3(-4.75, WALL_H + 0.15, -6.65), r, false)  # north roof west part
        _box(Vector3(8, 0.3, 4.9), Vector3(6.75, WALL_H + 0.15, -6.65), r, false)    # north roof east part
        _box(Vector3(5.75, 0.3, 5.2), Vector3(7.97, WALL_H + 0.15, 0), r, false)     # east wing roof
        # ceiling for rooms is the same slab (visible from inside)

# ================= pool & tree =================
func _pool_and_tree() -> void:
        pool = WaterPool.new()
        pool.name = "Pool"
        add_child(pool)
        pool.build(self)
        reg["pool"] = pool

        # pomegranate tree
        var tree := Node3D.new()
        tree.name = "Tree"
        add_child(tree)
        tree.position = Vector3(-3.6, 0, 2.6)
        var trunk := MeshInstance3D.new()
        var cm := CylinderMesh.new()
        cm.top_radius = 0.09
        cm.bottom_radius = 0.16
        cm.height = 2.0
        trunk.mesh = cm
        var bark := StandardMaterial3D.new()
        bark.albedo_color = Color(0.23, 0.15, 0.11)
        bark.roughness = 1.0
        trunk.material_override = bark
        trunk.position.y = 1.0
        tree.add_child(trunk)
        for i in 4:
                var cl := MeshInstance3D.new()
                var sm2 := SphereMesh.new()
                sm2.radius = 0.62
                sm2.height = 1.1
                cl.mesh = sm2
                var leaf := StandardMaterial3D.new()
                leaf.albedo_color = Color(0.10, 0.15, 0.09).lerp(Color(0.13, 0.09, 0.10), i / 4.0)
                leaf.roughness = 1.0
                cl.material_override = leaf
                cl.position = Vector3(sin(i * 1.7) * 0.5, 2.1 + cos(i * 2.1) * 0.35, cos(i * 1.3) * 0.5)
                tree.add_child(cl)
        # tiny pomegranates
        for i in 5:
                var pm := MeshInstance3D.new()
                var s3 := SphereMesh.new()
                s3.radius = 0.055
                s3.height = 0.11
                pm.mesh = s3
                var pmat := StandardMaterial3D.new()
                pmat.albedo_color = Color(0.55, 0.08, 0.1)
                pm.material_override = pmat
                pm.position = Vector3(sin(i * 2.4) * 0.7, 1.6 + cos(i * 1.9) * 0.6, cos(i * 2.2) * 0.7)
                tree.add_child(pm)
        var tcol := StaticBody3D.new()
        var tcs := CollisionShape3D.new()
        var tbs := CylinderShape3D.new()
        tbs.radius = 0.18
        tbs.height = 2.2
        tcs.shape = tbs
        tcol.add_child(tcs)
        tcol.position = Vector3(-3.6, 1.1, 2.6)
        add_child(tcol)
        reg["tree"] = tree

# ================= street =================
func _street() -> void:
        var pb: StandardMaterial3D = mats["brick"]
        _wall(-4, 12.2, 4, 12.2, pb, 3.0, 0, [], 0.4)  # alley wall across (so street feels narrow) with gap? no gap — wall beyond the door is behind player? Actually player enters FROM street moving north; wall at z=12.2 blocks view south. Put gap? keep solid.
        _wall(4, 9.2, 4, 12.2, pb, 3.0)
        _wall(-4, 9.2, -4, 12.2, pb, 3.0)
        _box(Vector3(2.4, 0.02, 0.9), Vector3(-2.6, 0.011, 11.6), _mat("puddle", "", Vector3.ONE, 0.05, Color(0.1, 0.14, 0.18)), false)
        # wall lamp above door
        _lamp("street_lamp", Vector3(1.2, 2.4, 9.0), Color(1.0, 0.7, 0.4), 1.4, 5.0, true)
        # NOTE: main door created in _props (registry)

# ================= basement =================
func _basement_structure() -> void:
        var sm: StandardMaterial3D = mats["stone_b"]
        var y := BASE_Y
        var h := 2.6
        # main room x[-8,2] z[-8,-2]
        _wall(-8, -8, 2, -8, sm, h, y)                                   # south outer... wait z=-8 is south? z decreases northward; use consistent naming anyway.
        _wall(-8, -2, 2, -2, sm, h, y, [{"c": 3.0, "w": 1.3, "y0": y, "y1": y + 2.1}])  # chamber wall, symbol door gap at x=-5
        _wall(-8, -8, -8, 6, sm, h, y)   # west
        _wall(2, -8, 2, -2, sm, h, y)    # east (with stair opening handled below)
        # chamber x[-8,-3] z[-2,5.5]... chamber: z from -2 (wall) to 5.5
        _wall(-8, 5.5, -3, 5.5, sm, h, y)
        _wall(-3, -2, -3, 5.5, sm, h, y)
        # tunnel from stairs (x~1.2) into main room: opening in east wall z[-8,-6.5]
        # east wall built above spans z[-8,-2]; we need a gap at z=-7: rebuild east wall with gap:
        # (simpler: punch visual hole is hard; instead stairs descend INTO room through ceiling gap placed inside room bounds)
        # Basement ceiling slabs (avoid stair shaft x[0.7,1.7])
        _box(Vector3(9.2, 0.3, 15), Vector3(-3.85, -1.35, -1.2), mats["plaster_dark"], false)
        _box(Vector3(0.8, 0.3, 15), Vector3(2.1, -1.35, -1.2), mats["plaster_dark"], false)
        _box(Vector3(1.0, 0.3, 1.9), Vector3(1.2, -1.35, -7.7), mats["plaster_dark"], false)
        # stairs (12 steps) from pool hatch (top -1.14) down to basement floor (-3.78)
        for i in 11:
            var top_y := -1.16 - i * 0.26
            var sz := -0.75 - i * 0.28
            _box(Vector3(1.45, 0.26, 0.3), Vector3(1.425, top_y - 0.13, sz), mats["stone_b"], false)
        # stair side walls (west wall stops early = exit gap toward main room)
        _wall(0.7, -1.4, 0.7, -5.0, sm, 3.2, BASE_Y - 0.2)
        _wall(1.7, -1.4, 1.7, -6.6, sm, 3.2, BASE_Y - 0.2)
        # invisible walkable ramp over the whole staircase (pool floor -> basement)
        _ramp(Vector3(1.425, -2.35, -2.155), 1.45, 4.3, 43.0)
        # pool entry ramp (courtyard <-> pool floor) west side
        _ramp(Vector3(-1.8, -0.45, 0.7), 0.8, 2.05, 24.5)
        for i in 3:
                _box(Vector3(0.8, 0.3, 0.35), Vector3(-1.8, -0.15 - i * 0.3, 1.45 - i * 0.6), mats["stone"], false)
        # water channel trough along main room: x[-7,-1], z=-7.3
        _box(Vector3(6.4, 0.25, 0.6), Vector3(-4, y + 0.12, -7.35), mats["stone_b"], true, "stone")
        var ch_water := MeshInstance3D.new()
        var cpm := PlaneMesh.new()
        cpm.size = Vector2(6.2, 0.42)
        ch_water.mesh = cpm
        var cwm := StandardMaterial3D.new()
        cwm.albedo_color = Color(0.05, 0.2, 0.24, 0.85)
        cwm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        cwm.roughness = 0.1
        cwm.emission_enabled = true
        cwm.emission = Color(0.02, 0.08, 0.1)
        ch_water.material_override = cwm
        ch_water.position = Vector3(-4, y + 0.2, -7.35)
        add_child(ch_water)
        # chamber small pool (the source)
        _box(Vector3(1.6, 0.5, 1.6), Vector3(-5.5, y + 0.25, 4.2), mats["tile"], true, "tile")
        var src := MeshInstance3D.new()
        var spm := PlaneMesh.new()
        spm.size = Vector2(1.4, 1.4)
        src.mesh = spm
        var srcm := StandardMaterial3D.new()
        srcm.albedo_color = Color(0.01, 0.04, 0.05, 0.96)
        srcm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        srcm.roughness = 0.03
        srcm.emission_enabled = true
        srcm.emission = Color(0.0, 0.03, 0.04)
        src.material_override = srcm
        src.position = Vector3(-5.5, y + 0.46, 4.2)
        add_child(src)
        reg["source_pool"] = src

func _place_basement_door() -> void:
        # symbol door occupies the gap at x=-5, z=-2 (between main room and chamber)
        var sd: SymbolDoor = load("res://scripts/interact/symbol_door.gd").new()
        sd.name = "SymbolDoor"
        add_child(sd)
        sd.position = Vector3(-5.0, BASE_Y, -2.0)
        sd.collision_layer = 5
        sd.collision_mask = 0
        var cs := CollisionShape3D.new()
        var bs := BoxShape3D.new()
        bs.size = Vector3(1.3, 2.1, 0.3)
        cs.shape = bs
        cs.position = Vector3(0, 1.05, 0)
        sd.add_child(cs)
        # visible stone panel
        var panel := Node3D.new()
        panel.name = "Panel"
        sd.add_child(panel)
        var mi := MeshInstance3D.new()
        var bm := BoxMesh.new()
        bm.size = Vector3(1.3, 2.1, 0.26)
        mi.mesh = bm
        mi.material_override = mats["stone_b"]
        mi.position = Vector3(0, 1.05, 0)
        panel.add_child(mi)
        # four symbol plaques
        var syms := ["پ", "م", "ص", "ف"]
        for i in 4:
                var pl := MeshInstance3D.new()
                var qm := QuadMesh.new()
                qm.size = Vector2(0.22, 0.22)
                pl.mesh = qm
                var pm2 := StandardMaterial3D.new()
                pm2.albedo_color = Color(0.3, 0.65, 0.7)
                pm2.emission_enabled = true
                pm2.emission = Color(0.2, 0.5, 0.55)
                pm2.emission_energy_multiplier = 0.8
                pl.material_override = pm2
                pl.position = Vector3(-0.45 + i * 0.3, 1.3, -0.15)
                panel.add_child(pl)
        reg["symbol_door"] = sd

# ================= lights =================
func _lights() -> void:
        _lamp("court1", Vector3(-4.5, 2.2, -3.6), Color(1.0, 0.72, 0.42), 1.5, 8.0, true)
        _lamp("court2", Vector3(4.5, 2.2, 3.8), Color(1.0, 0.7, 0.4), 1.2, 8.0, true)
        _lamp("vest", Vector3(0, 2.4, 6.5), Color(1.0, 0.75, 0.45), 0.0, 6.0, false)
        _lamp("corr", Vector3(-6.2, 2.4, 0), Color(1.0, 0.78, 0.5), 0.0, 7.0, false)
        _lamp("family", Vector3(-6.8, 2.5, 6.6), Color(1.0, 0.75, 0.45), 0.0, 8.0, false)
        _lamp("kitchen", Vector3(-9.1, 2.4, -2.1), Color(0.95, 0.8, 0.55), 0.0, 6.0, false)
        _lamp("study", Vector3(-9.1, 2.4, 2.1), Color(1.0, 0.75, 0.45), 0.0, 6.0, false)
        _lamp("grand", Vector3(-3.5, 2.5, -6.6), Color(1.0, 0.72, 0.42), 0.0, 7.0, false)
        _lamp("bath", Vector3(2.5, 2.4, -6.6), Color(0.85, 0.9, 0.95), 0.0, 5.0, false)
        _lamp("stor", Vector3(6.8, 2.4, 6.6), Color(1.0, 0.75, 0.45), 0.0, 6.0, false)
        _lamp("stair", Vector3(8.0, 2.3, 0), Color(1.0, 0.65, 0.35), 0.8, 6.0, true)   # flickers
        _lamp("base1", Vector3(1.2, BASE_Y + 2.2, -5.6), Color(0.9, 0.6, 0.4), 0.9, 7.0, true)
        _lamp("base2", Vector3(-5.5, BASE_Y + 2.2, 3.0), Color(0.55, 0.75, 0.9), 0.0, 8.0, false)

func _rain() -> void:
        rain_particles = GPUParticles3D.new()
        rain_particles.amount = 380
        rain_particles.lifetime = 1.1
        rain_particles.visibility_aabb = AABB(Vector3(-14, -6, -14), Vector3(28, 14, 28))
        var mat := ParticleProcessMaterial.new()
        mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
        mat.emission_box_extents = Vector3(12, 0.5, 12)
        mat.direction = Vector3(0, -1, 0)
        mat.spread = 3.0
        mat.initial_velocity_min = 9.0
        mat.initial_velocity_max = 12.0
        mat.gravity = Vector3(0, -6, 0)
        rain_particles.process_material = mat
        var mesh := QuadMesh.new()
        mesh.size = Vector2(0.02, 0.28)
        var rm := StandardMaterial3D.new()
        rm.albedo_color = Color(0.55, 0.65, 0.8, 0.35)
        rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        rm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
        mesh.material = rm
        rain_particles.draw_pass_1 = mesh
        rain_particles.position = Vector3(0, 9.0, 0)
        add_child(rain_particles)

# ================= triggers =================
func _triggers() -> void:
        var defs := [
                ["t_vestibule", Vector3(0, 1.2, 6.6), Vector3(5.4, 2.5, 4.4)],
                ["t_courtyard", Vector3(0, 1.2, 0), Vector3(10, 2.5, 8)],
                ["t_family", Vector3(-6.8, 1.2, 6.6), Vector3(7.5, 2.5, 4.4)],
                ["t_grand", Vector3(-3.5, 1.2, -6.6), Vector3(5.6, 2.5, 4.4)],
                ["t_basement", Vector3(-3, BASE_Y + 1.2, -5), Vector3(10, 2.6, 6)],
                ["t_channel", Vector3(-4, BASE_Y + 1.0, -7.3), Vector3(6.4, 2.0, 1.2)],
                ["t_chamber", Vector3(-5.5, BASE_Y + 1.2, 3.0), Vector3(4.6, 2.6, 6.6)],
        ]
        for d in defs:
                var area := Area3D.new()
                area.name = d[0]
                area.collision_layer = 0
                area.collision_mask = 2
                var cs := CollisionShape3D.new()
                var bs := BoxShape3D.new()
                bs.size = d[2]
                cs.shape = bs
                area.add_child(cs)
                add_child(area)
                area.position = d[1]
                var zone_name: String = d[0]
                area.body_entered.connect(func(body):
                        if body.is_in_group("player"):
                                var game := get_tree().get_first_node_in_group("game_root")
                                if game != null:
                                        game.call("on_zone", body, zone_name))
        reg["triggers"] = true

## Invisible sloped walkable collider: center, width(x), slope length, angle deg (downhill toward -Z)
func _ramp(pos: Vector3, width: float, length: float, angle_deg: float) -> void:
    var sb := StaticBody3D.new()
    sb.collision_layer = 5
    var cs := CollisionShape3D.new()
    var bs := BoxShape3D.new()
    bs.size = Vector3(width, 0.3, length)
    cs.shape = bs
    sb.add_child(cs)
    add_child(sb)
    sb.position = pos
    sb.rotation.x = -deg_to_rad(angle_deg)

func _props() -> void:
        var props: Node = load("res://scripts/game/house_props.gd").new()
        add_child(props)
        props.build_all(self)
