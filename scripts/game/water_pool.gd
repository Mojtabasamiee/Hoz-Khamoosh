extends Node3D
class_name WaterPool
## Central courtyard pool: shader water, fake mirrored reflection, scripted events.

var water_mesh: MeshInstance3D
var water_mat: ShaderMaterial
var reflection: Node3D
var ghost_window: MeshInstance3D
var ghost_figure: MeshInstance3D
var hatch_slab: Node3D
var drained := false
var _frozen := false
var world: Node3D

const WATER_Y := -0.06
const DRAIN_Y := -0.78

func _ready() -> void:
	pass

func build(p_world: Node3D) -> void:
	world = p_world
	var tex1: Texture2D = load("res://assets/textures/water_noise1.png")
	var tex2: Texture2D = load("res://assets/textures/water_noise2.png")

	# ---- water plane ----
	water_mesh = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(4.4, 3.2)
	water_mesh.mesh = plane
	water_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = WATER_SHADER
	water_mat.shader = sh
	water_mat.set_shader_parameter("noise1", tex1)
	water_mat.set_shader_parameter("noise2", tex2)
	water_mat.set_shader_parameter("flow_speed", 0.028)
	water_mat.set_shader_parameter("ripple", 1.0)
	water_mesh.material_override = water_mat
	water_mesh.position = Vector3(0, WATER_Y, 0)
	water_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water_mesh)

	# ---- pool basin walls + floor (tile texture) ----
	var tile_mat := StandardMaterial3D.new()
	tile_mat.albedo_texture = load("res://assets/textures/tile_pool.png")
	tile_mat.albedo_color = Color(0.85, 0.9, 0.9)
	tile_mat.uv1_scale = Vector3(2.2, 1.0, 1.0)
	tile_mat.roughness = 0.3
	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_texture = load("res://assets/textures/tile_pool_dark.png")
	dark_mat.uv1_scale = Vector3(2.0, 0.6, 1.0)
	dark_mat.roughness = 0.4

	# pool floor pieces around stair hole x[0.7,2.15] z[-1.85,-0.6]
	_pool_rect(Vector2(-2.45, -1.85), Vector2(0.7, 1.85), tile_mat, 0.2, -1.0)
	_pool_rect(Vector2(0.7, -0.6), Vector2(2.15, 1.85), tile_mat, 0.2, -1.0)
	_pool_rect(Vector2(2.15, -1.85), Vector2(2.45, 1.85), tile_mat, 0.2, -1.0)
	# basin walls (north split for stair opening)
	_pool_rect(Vector2(-2.45, -1.85), Vector2(0.7, -1.6), tile_mat, 0.9, -0.45)
	_pool_rect(Vector2(2.15, -1.85), Vector2(2.45, -1.6), tile_mat, 0.9, -0.45)
	_pool_rect(Vector2(-2.45, 1.6), Vector2(2.45, 1.85), tile_mat, 0.9, -0.45)
	_pool_rect(Vector2(-2.45, -1.85), Vector2(-2.2, 1.85), tile_mat, 0.9, -0.45)
	_pool_rect(Vector2(2.2, -1.85), Vector2(2.45, 1.85), tile_mat, 0.9, -0.45)
	# coping rims (avoid stair hole)
	var edge_mat := StandardMaterial3D.new()
	edge_mat.albedo_texture = load("res://assets/textures/stone_floor.png")
	edge_mat.uv1_scale = Vector3(2.0, 2.0, 2.0)
	edge_mat.roughness = 0.55
	_pool_rect(Vector2(-2.75, -2.15), Vector2(2.75, -1.85), edge_mat, 0.12, -0.06)
	_pool_rect(Vector2(-2.75, 1.85), Vector2(2.75, 2.15), edge_mat, 0.12, -0.06)
	_pool_rect(Vector2(-2.75, -1.85), Vector2(-2.45, 1.85), edge_mat, 0.12, -0.06)
	_pool_rect(Vector2(2.45, -1.85), Vector2(2.75, 1.85), edge_mat, 0.12, -0.06)

	# ---- hatch slab (hides stairs until drained) ----
	hatch_slab = Node3D.new()
	var slab := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.45, 0.12, 1.25)
	slab.mesh = bm
	var smat := StandardMaterial3D.new()
	smat.albedo_texture = load("res://assets/textures/stone_floor.png")
	smat.albedo_color = Color(0.75, 0.78, 0.8)
	slab.material_override = smat
	slab.position = Vector3(1.425, -0.9, -1.225)
	hatch_slab.add_child(slab)
	var col := StaticBody3D.new()
	var cshape := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = Vector3(1.45, 0.12, 1.25)
	cshape.shape = bshape
	col.add_child(cshape)
	col.position = slab.position
	hatch_slab.add_child(col)
	add_child(hatch_slab)

	# ---- fake mirrored reflection (below water) ----
	reflection = Node3D.new()
	reflection.position = Vector3(0, WATER_Y * 2 + 0.02, 0)
	add_child(reflection)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_texture = load("res://assets/textures/tile_pool.png")
	rmat.albedo_color = Color(0.3, 0.5, 0.55, 1.0)
	# mirrored tree silhouette
	var tree_refl := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.06
	tm.bottom_radius = 0.14
	tm.height = 1.8
	tree_refl.mesh = tm
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.16, 0.12, 0.1)
	tree_refl.material_override = bark
	tree_refl.position = Vector3(-2.2, -0.32, -1.25)
	tree_refl.scale = Vector3(1.0, 0.5, 1.0)
	reflection.add_child(tree_refl)
	var canopy := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.7
	sm.height = 1.3
	canopy.mesh = sm
	var leaf := StandardMaterial3D.new()
	leaf.albedo_color = Color(0.1, 0.14, 0.1)
	canopy.material_override = leaf
	canopy.position = Vector3(-2.2, -0.5, -1.25)
	canopy.scale = Vector3(1.0, 0.45, 1.0)
	reflection.add_child(canopy)
	# mirrored lantern glow
	var lamp := MeshInstance3D.new()
	var lm := SphereMesh.new()
	lm.radius = 0.08
	lm.height = 0.16
	lamp.mesh = lm
	var lmt := StandardMaterial3D.new()
	lmt.albedo_color = Color(1.0, 0.75, 0.4)
	lmt.emission_enabled = true
	lmt.emission = Color(1.0, 0.7, 0.35)
	lmt.emission_energy_multiplier = 2.0
	lamp.material_override = lmt
	lamp.position = Vector3(4.4, -0.25, -3.4)
	lamp.visible = false
	reflection.add_child(lamp)
	# GHOST WINDOW (event: reflection shows a window that doesn't exist)
	ghost_window = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.0, 1.3)
	ghost_window.mesh = qm
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(1.0, 0.85, 0.5, 0.85)
	wmat.emission_enabled = true
	wmat.emission = Color(1.0, 0.8, 0.45)
	wmat.emission_energy_multiplier = 1.6
	ghost_window.material_override = wmat
	ghost_window.position = Vector3(0.5, -0.3, -1.45)
	ghost_window.rotation.x = -PI / 2.0 + 0.35
	ghost_window.visible = false
	reflection.add_child(ghost_window)
	# FIGURE (event: someone standing behind the player — in reflection only)
	ghost_figure = MeshInstance3D.new()
	var fq := QuadMesh.new()
	fq.size = Vector2(0.55, 1.15)
	ghost_figure.mesh = fq
	var fmat := StandardMaterial3D.new()
	fmat.albedo_texture = load("res://assets/textures/figure.png")
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost_figure.material_override = fmat
	ghost_figure.position = Vector3(-1.2, -0.42, -1.35)
	ghost_figure.rotation.x = -PI / 2.0 + 0.25
	ghost_figure.visible = false
	reflection.add_child(ghost_figure)

func _floor_box(sz: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = sz
	cs.shape = bs
	sb.add_child(cs)
	sb.position = pos
	sb.set_meta("surface", "tile")
	add_child(sb)

# ---------- events API ----------
func ripple_event() -> void:
	var tw := create_tween()
	water_mat.set_shader_parameter("ripple", 3.0)
	tw.tween_interval(4.0)
	tw.tween_callback(func(): water_mat.set_shader_parameter("ripple", 1.0))
	AudioMgr.play_sfx_3d("res://assets/audio/sfx/pool_event.wav", world, global_position, 2.0)

## Pool part box between min/max (x,z) corners; box top at top_y, height h.
func _pool_rect(minv: Vector2, maxv: Vector2, mat: Material, h: float, top_y: float) -> void:
	var sz := Vector3(maxv.x - minv.x, h, maxv.y - minv.y)
	var pos := Vector3((minv.x + maxv.x) / 2.0, top_y - h / 2.0, (minv.y + maxv.y) / 2.0)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = sz
	cs.shape = bs
	sb.add_child(cs)
	sb.position = pos
	sb.set_meta("surface", "tile")
	add_child(sb)


func freeze_seconds(dur: float = 3.0) -> void:
	if _frozen:
		return
	_frozen = true
	AudioMgr.play_sfx_3d("res://assets/audio/sfx/water_freeze.wav", world, global_position, 0.0)
	var old: float = water_mat.get_shader_parameter("flow_speed")
	water_mat.set_shader_parameter("flow_speed", 0.0)
	get_tree().create_timer(dur).timeout.connect(func():
		water_mat.set_shader_parameter("flow_speed", old)
		_frozen = false)

func show_ghost_window(dur: float = 6.0) -> void:
	ghost_window.visible = true
	AudioMgr.play_music("res://assets/audio/music/cue_event.ogg", 0.8)
	get_tree().create_timer(8.0).timeout.connect(func():
		if AudioMgr.current_music.begins_with("res://assets/audio/music/cue_"):
			AudioMgr.stop_music(2.0))
	get_tree().create_timer(dur).timeout.connect(func(): ghost_window.visible = false)

func show_figure(dur: float = 2.2) -> void:
	ghost_figure.visible = true
	Horror.whisper(world, global_position + Vector3(0, 0.5, -1.0))
	get_tree().create_timer(dur).timeout.connect(func(): ghost_figure.visible = false)

func drain() -> void:
	if drained:
		return
	drained = true
	AudioMgr.play_sfx_3d("res://assets/audio/sfx/water_drain.ogg", world, global_position, 6.0, 40.0)
	var tw := create_tween()
	tw.tween_property(water_mesh, "position:y", DRAIN_Y, 7.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(reflection, "position:y", DRAIN_Y * 2 + 0.02, 7.0)
	tw.parallel().tween_property(water_mat, "albedo_color", Color(1,1,1), 7.0)
	# darken water as it drains
	water_mat.set_shader_parameter("ripple", 4.0)
	tw.tween_callback(func():
		water_mat.set_shader_parameter("ripple", 1.2)
		water_mat.set_shader_parameter("flow_speed", 0.006))
	# open slab after level drops
	get_tree().create_timer(5.0).timeout.connect(_open_hatch)

func _open_hatch() -> void:
	AudioMgr.play_sfx_3d("res://assets/audio/sfx/stone_open.wav", world, global_position, 2.0)
	var tw := create_tween()
	tw.tween_property(hatch_slab, "position:y", hatch_slab.position.y - 2.2, 2.5).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		for c in hatch_slab.get_children():
			if c is StaticBody3D:
				c.get_child(0).set("disabled", true))

const WATER_SHADER := "
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back;
uniform sampler2D noise1;
uniform sampler2D noise2;
uniform float flow_speed = 0.03;
uniform float ripple = 1.0;
uniform vec4 col_deep : source_color = vec4(0.015, 0.07, 0.09, 0.88);
uniform vec4 col_surface : source_color = vec4(0.06, 0.28, 0.33, 0.62);
void fragment() {
	vec2 uv1 = UV * vec2(3.0, 2.2) + vec2(TIME * flow_speed, TIME * flow_speed * 0.6);
	vec2 uv2 = UV * vec2(2.2, 3.1) - vec2(TIME * flow_speed * 0.7, TIME * flow_speed * 1.1);
	float n1 = texture(noise1, uv1).r;
	float n2 = texture(noise2, uv2).r;
	float h = mix(n1, n2, 0.5);
	h = pow(h, 1.2) * ripple;
	vec3 base = mix(col_deep.rgb, col_surface.rgb, clamp(h, 0.0, 1.0));
	float sparkle = smoothstep(0.72, 0.95, h);
	base += sparkle * vec3(0.10, 0.16, 0.17);
	ALBEDO = base;
	ALPHA = clamp(mix(col_deep.a, col_surface.a, h), 0.35, 0.95);
	ROUGHNESS = 0.06;
	METALLIC = 0.25;
	NORMAL_MAP = vec3(texture(noise1, uv1 * 2.0).rg, 1.0);
}
"
