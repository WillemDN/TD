extends Node3D
## 3D view of the mode "survivor": a round arena with the tower in the middle, enemies, shots, blades, mines and effects.
## It only reads the simulation (core/survivor.gd). The same camera and lighting as the tower defence view.

const Models := preload("res://client/models.gd")
const WorldView := preload("res://client/world_view.gd")

const PITCH := 1.2
const MIN_VIEW_W := 16.0
const MAX_VIEW_W := 40.0
const DEFAULT_VIEW_W := 27.0
const ARENA_TILES := 36.0             # size of the ground plane
const TOWER_SCALE := 2.1
const ENEMY_SCALE := 1.25

const SHOT_COLORS := {"projectile": "ffe9a0", "glaive": "d8e8ff", "poison": "7fe05a"}

var sim
var data
var cam: Camera3D
var view_w := DEFAULT_VIEW_W
var cam_target := Vector2.ZERO
var clock := 0.0
var shake := 0.0

var _sun: DirectionalLight3D
var _tower: Node3D
var _tower_flash := 0.0
var _creep_nodes := {}
var _proj_pool: Array = []
var _disc_pool: Array = []
var _blade_pool: Array = []
var _mine_pool: Array = []
var _shell_pool: Array = []
var _fx_pool: Array = []
var _fx_next := 0
var _puff_pool: Array = []
var _puff_next := 0
var _rings := {}                      # aura weapon id -> ring node
var _pulse := {}                      # aura weapon id -> seconds left of the flash
var _snow: CPUParticles3D


func setup(p_sim, p_data) -> void:
	sim = p_sim
	data = p_data
	_build_environment()
	_build_ground()
	_build_forest()
	_build_tower()
	_build_pools()
	_build_snow()
	fit_camera()


# ------------------------------------------------------------------ camera

func fit_camera(insets := Vector2(54.0, 150.0), keep_zoom := false) -> void:
	if not keep_zoom:
		view_w = DEFAULT_VIEW_W
	cam_target = Vector2.ZERO
	_apply_camera(insets)


func _apply_camera(insets := Vector2.ZERO) -> void:
	view_w = clampf(view_w, MIN_VIEW_W, MAX_VIEW_W)
	var vp := get_viewport().get_visible_rect().size
	var aspect := vp.x / maxf(vp.y, 1.0)
	cam.size = view_w / aspect
	var ext := view_extent()
	if insets != Vector2.ZERO:
		# the bars at the top and the shop at the bottom: keep the tower in the free middle
		cam_target.y += (insets.y - insets.x) * 0.5 / vp.y * ext.y
	cam.position = Vector3(cam_target.x, 0.0, cam_target.y) + Vector3(0.0, sin(PITCH), cos(PITCH)) * 40.0
	cam.rotation = Vector3(-PITCH, 0.0, 0.0)
	if _snow != null:
		_snow.position = Vector3(cam_target.x, 9.0, cam_target.y)
		_snow.emission_box_extents = Vector3(view_w * 0.62, 0.2, ext.y * 0.6)


func view_extent() -> Vector2:
	var vp := get_viewport().get_visible_rect().size
	var aspect := vp.x / maxf(vp.y, 1.0)
	return Vector2(cam.size * aspect, cam.size / sin(PITCH))


func zoom_by(factor: float) -> void:
	var keep_y := cam_target.y
	view_w *= factor
	_apply_camera()
	cam_target.y = keep_y


func tile_to_screen(tile: Vector2, height: float = 0.0) -> Vector2:
	return cam.unproject_position(Vector3(tile.x, height, tile.y))


func set_shadows(on: bool) -> void:
	if _sun != null:
		_sun.shadow_enabled = on


# ------------------------------------------------------------------ construction

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("050a14")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("6f8fc0")
	env.ambient_light_energy = 0.62
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 1.25
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	_sun = DirectionalLight3D.new()
	_sun.rotation = Vector3(-1.0, -0.8, 0.0)
	_sun.light_color = Color("c4d8ff")
	_sun.light_energy = 1.15
	_sun.shadow_enabled = true
	_sun.shadow_bias = 0.04
	_sun.shadow_opacity = 0.5
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_sun.directional_shadow_max_distance = 40.0
	add_child(_sun)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.near = 0.1
	cam.far = 200.0
	add_child(cam)


## The arena: slate plates with the tile grid in the middle, a ring of dark forest soil around it.
func _build_ground() -> void:
	var px := 4
	var n := int(ARENA_TILES) * px
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var arena: float = float(sim.rules.arenaRadius)
	for y in n:
		for x in n:
			var p := Vector2((float(x) + 0.5) / float(px) - ARENA_TILES * 0.5, (float(y) + 0.5) / float(px) - ARENA_TILES * 0.5)
			var d := p.length()
			var c := Color(1, 0, 0, 0)
			if d > arena + 1.4:
				c = Color(0, 0, 1, 0)
			elif d > arena - 0.4:
				c = Color(0.4, 0.6, 0, 0)
			img.set_pixel(x, y, c)
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = WorldView.TERRAIN_SHADER
	m.shader = sh
	m.set_shader_parameter("region", ImageTexture.create_from_image(img))
	m.set_shader_parameter("map_size", Vector2(ARENA_TILES, ARENA_TILES))
	var plane := PlaneMesh.new()
	plane.size = Vector2(ARENA_TILES, ARENA_TILES)
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.material_override = m
	add_child(mi)
	var outer := PlaneMesh.new()
	outer.size = Vector2(ARENA_TILES, ARENA_TILES) * 3.0
	var om := MeshInstance3D.new()
	om.mesh = outer
	om.material_override = Models.mat(Color("070d18"))
	om.position = Vector3(0, -0.02, 0)
	add_child(om)


func _build_forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var kinds := {"snow-detail-tree-large": [], "snow-detail-tree": [], "snow-detail-rocks": [], "snow-detail-crystal": []}
	var arena: float = float(sim.rules.arenaRadius)
	for i in 150:
		var a := rng.randf() * TAU
		var r := arena + 0.7 + rng.randf() * 3.2
		var pos := Vector3(cos(a) * r, 0.0, sin(a) * r)
		var roll := rng.randf()
		if roll < 0.5:
			kinds["snow-detail-tree-large" if roll < 0.32 else "snow-detail-tree"].append(pos)
		elif roll < 0.9:
			kinds["snow-detail-rocks"].append(pos)
		else:
			kinds["snow-detail-crystal"].append(pos)
	for name in kinds:
		var list: Array = kinds[name]
		if list.is_empty():
			continue
		var src := _first_mesh(Models.inst(name))
		if src == null:
			continue
		var forest_mesh: Mesh = src.mesh.duplicate()
		for si in forest_mesh.get_surface_count():
			var fm = forest_mesh.surface_get_material(si)
			if fm is BaseMaterial3D:
				var fd: BaseMaterial3D = fm.duplicate()
				fd.albedo_color = Color("56697c")
				forest_mesh.surface_set_material(si, fd)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = forest_mesh
		mm.instance_count = list.size()
		var base_scale := 1.9 if name.contains("tree") else 1.5
		for i in list.size():
			var s := base_scale * rng.randf_range(0.8, 1.35)
			var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.9, 1.3), s))
			mm.set_instance_transform(i, Transform3D(b, list[i]))
		var inst := MultiMeshInstance3D.new()
		inst.multimesh = mm
		add_child(inst)


func _first_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n
	for c in n.get_children():
		var r := _first_mesh(c)
		if r != null:
			return r
	return null


func _build_tower() -> void:
	var def := {"element": "ultimate", "tier": 6, "elements": []}
	_tower = Models.make_tower(def, Color("bff6ff"))
	Models.set_build_progress(_tower, 1.0)
	_tower.scale = Vector3.ONE * TOWER_SCALE
	var pad := _tower.get_node("ring") as MeshInstance3D
	pad.visible = false
	add_child(_tower)
	# a soft glow disc under the tower
	var glow := Models.add_mesh(self, Models.cylinder(1.9, 1.9, 0.02, 24), Color("1d3a5c"), Vector3(0, 0.02, 0), Vector3.ZERO, 0.4)
	glow.material_override = Models.mat(Color("2a5a8c"), 0.5, 0.6)


func _build_pools() -> void:
	for i in 32:
		var m := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = 0.9
		t.outer_radius = 1.0
		m.mesh = t
		var fm := StandardMaterial3D.new()
		fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.material_override = fm
		m.visible = false
		add_child(m)
		_fx_pool.append({"node": m, "ttl": 0.0, "max": 0.3, "color": Color.WHITE, "size": 1.0, "beam": false})
	for i in 14:
		var p := CPUParticles3D.new()
		p.emitting = false
		p.one_shot = true
		p.amount = 10
		p.lifetime = 0.55
		p.explosiveness = 1.0
		p.direction = Vector3(0, 1, 0)
		p.spread = 70.0
		p.initial_velocity_min = 1.4
		p.initial_velocity_max = 2.6
		p.gravity = Vector3(0, -7.0, 0)
		var sm := SphereMesh.new()
		sm.radius = 0.04
		sm.height = 0.08
		sm.radial_segments = 4
		sm.rings = 2
		p.mesh = sm
		p.material_override = Models.mat(Color("ffd45e"), 0.9)
		add_child(p)
		_puff_pool.append(p)


func _build_snow() -> void:
	_snow = CPUParticles3D.new()
	_snow.amount = 260
	_snow.lifetime = 7.0
	_snow.preprocess = 7.0
	_snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_snow.emission_box_extents = Vector3(12, 0.2, 8)
	_snow.direction = Vector3(0.15, -1, 0.05)
	_snow.spread = 12.0
	_snow.initial_velocity_min = 1.0
	_snow.initial_velocity_max = 1.8
	_snow.gravity = Vector3.ZERO
	var q := QuadMesh.new()
	q.size = Vector2(0.05, 0.05)
	_snow.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1, 1, 1, 0.6)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_snow.material_override = m
	add_child(_snow)


# ------------------------------------------------------------------ per frame

func update_view(alpha: float, delta: float) -> void:
	clock += delta
	_sync_tower(delta)
	_sync_enemies(alpha)
	_sync_shots(alpha)
	_sync_blades()
	_sync_mines()
	_sync_shells()
	_sync_rings(delta)
	_update_fx(delta)


func _sync_tower(delta: float) -> void:
	_tower_flash = maxf(0.0, _tower_flash - delta)
	shake = maxf(0.0, shake - delta)
	var j := 0.0
	if shake > 0.0:
		j = sin(clock * 90.0) * 0.06 * (shake / 0.2)
	_tower.position = Vector3(j, 0.0, 0.0)
	# the turret follows the nearest enemy
	var best := INF
	var target := Vector2(1.0, 0.0)
	for e in sim.enemies.values():
		var d: float = e.pos.length_squared()
		if d < best:
			best = d
			target = e.pos
	Models.aim_turret(_tower, Vector2.ZERO, target)


func _sync_enemies(alpha: float) -> void:
	for id in _creep_nodes.keys():
		if not sim.enemies.has(id) or not sim.enemies[id].alive:
			_creep_nodes[id].queue_free()
			_creep_nodes.erase(id)
	for e in sim.enemies.values():
		if not e.alive:
			continue
		var n: Node3D = _creep_nodes.get(e.id)
		if n == null:
			n = _make_enemy_node(e)
			_creep_nodes[e.id] = n
		var p: Vector2 = e.prev.lerp(e.pos, alpha)
		n.position = Vector3(p.x, 0.0, p.y)
		var dir: Vector2 = e.pos - e.prev
		if e.wagon and dir.length() > 0.001:
			n.rotation.y = lerp_angle(n.rotation.y, atan2(-dir.x, -dir.y), 0.3)
		else:
			# they always look at the tower
			n.rotation.y = lerp_angle(n.rotation.y, atan2(p.x, p.y), 0.3)
		var model: Node3D = n.get_node("creep")
		var moving: bool = (e.pos - e.prev).length() > 0.001
		Models.animate_creep(model, clock if moving else 0.0, e.speed * (1.0 - e.slow_amt), float(e.id) * 0.7)


func _make_enemy_node(e) -> Node3D:
	var n := Node3D.new()
	var def: Dictionary = e.def
	var model := Models.make_creep(def.model, def)
	model.name = "creep"
	var s: float = ENEMY_SCALE * (1.15 if e.boss else 1.0)     # the model table already sizes bosses up
	model.scale = Vector3.ONE * s
	n.add_child(model)
	var r: float = e.radius
	var shadow := Models.add_mesh(n, Models.cylinder(r, r, 0.01, 12), Color(0, 0, 0), Vector3(0, 0.01, 0))
	shadow.material_override = Models.mat(Color(0, 0, 0), 0.0, 0.3)
	if e.boss:
		var ring := Models.add_mesh(n, Models.cylinder(r * 1.4, r * 1.4, 0.03, 18), Color("ff5a4a"), Vector3(0, 0.03, 0), Vector3.ZERO, 1.2)
		ring.material_override = Models.mat(Color("ff5a4a"), 1.2, 0.6)
	add_child(n)
	return n


func _ensure(pool: Array, count: int, factory: Callable) -> void:
	while pool.size() < count:
		var n: Node3D = factory.call()
		add_child(n)
		pool.append(n)


func _sync_shots(alpha: float) -> void:
	var projectiles: Array = []
	var discs: Array = []
	for s in sim.shots:
		if s.disc:
			discs.append(s)
		else:
			projectiles.append(s)
	_ensure(_proj_pool, projectiles.size(), func():
		var node := Node3D.new()
		var glow := Models.add_mesh(node, Models.sphere(0.12), Color.WHITE, Vector3.ZERO, Vector3.ZERO, 1.8)
		glow.name = "glow"
		return node)
	for i in _proj_pool.size():
		var node: Node3D = _proj_pool[i]
		if i >= projectiles.size():
			node.visible = false
			continue
		var s = projectiles[i]
		var pos: Vector2 = s.prev.lerp(s.pos, alpha)
		node.position = Vector3(pos.x, 0.9, pos.y)
		var col := Color(SHOT_COLORS["poison"] if s.poison > 0.0 else SHOT_COLORS["projectile"])
		(node.get_node("glow") as MeshInstance3D).material_override = Models.mat(col, 1.8)
		node.visible = true
	_ensure(_disc_pool, discs.size(), func():
		var node := Node3D.new()
		var disc := Models.add_mesh(node, Models.cylinder(0.55, 0.55, 0.05, 12), Color("d8e8ff"), Vector3.ZERO, Vector3.ZERO, 1.4)
		disc.name = "disc"
		return node)
	for i in _disc_pool.size():
		var node: Node3D = _disc_pool[i]
		if i >= discs.size():
			node.visible = false
			continue
		var s = discs[i]
		var pos: Vector2 = s.prev.lerp(s.pos, alpha)
		node.position = Vector3(pos.x, 0.8, pos.y)
		node.rotation.y = clock * 14.0
		node.visible = true


func _sync_blades() -> void:
	var list: Array = sim.blades
	_ensure(_blade_pool, list.size(), func():
		var node := Node3D.new()
		Models.add_mesh(node, Models.box(Vector3(0.9, 0.1, 0.22)), Color("c8d6e8"), Vector3.ZERO, Vector3.ZERO, 0.5)
		Models.add_mesh(node, Models.box(Vector3(0.2, 0.12, 0.3)), Color("8a5a2c"), Vector3(-0.4, 0, 0))
		return node)
	for i in _blade_pool.size():
		var node: Node3D = _blade_pool[i]
		if i >= list.size():
			node.visible = false
			continue
		var p: Vector2 = list[i]
		node.position = Vector3(p.x, 0.7, p.y)
		node.rotation.y = -atan2(p.y, p.x) + PI * 0.5 + clock * 6.0
		node.visible = true


func _sync_mines() -> void:
	var list: Array = sim.mines
	_ensure(_mine_pool, list.size(), func():
		var node := Node3D.new()
		Models.add_mesh(node, Models.cylinder(0.3, 0.34, 0.12, 10), Color("5a4a3a"))
		Models.add_mesh(node, Models.sphere(0.07), Color("ff4a3a"), Vector3(0, 0.12, 0), Vector3.ZERO, 2.4)
		return node)
	for i in _mine_pool.size():
		var node: Node3D = _mine_pool[i]
		if i >= list.size():
			node.visible = false
			continue
		node.position = Vector3(list[i].pos.x, 0.06, list[i].pos.y)
		node.visible = true


func _sync_shells() -> void:
	var list: Array = sim.shells
	_ensure(_shell_pool, list.size(), func():
		var node := Node3D.new()
		Models.add_mesh(node, Models.sphere(0.2), Color("ff9a3c"), Vector3.ZERO, Vector3.ZERO, 2.0)
		return node)
	for i in _shell_pool.size():
		var node: Node3D = _shell_pool[i]
		if i >= list.size():
			node.visible = false
			continue
		var sh = list[i]
		var k: float = 1.0 - sh.t_left / maxf(sh.t_total, 0.01)
		var p: Vector2 = sh.from.lerp(sh.to, k)
		node.position = Vector3(p.x, 0.5 + sin(k * PI) * 3.2, p.y)
		node.visible = true


func _sync_rings(delta: float) -> void:
	for id in sim.weapons.keys():
		var w: Dictionary = sim.data.weapons[id]
		if w.kind != "aura":
			continue
		var ring: MeshInstance3D = _rings.get(id)
		if ring == null:
			ring = MeshInstance3D.new()
			var t := TorusMesh.new()
			t.inner_radius = 0.985
			t.outer_radius = 1.0
			ring.mesh = t
			var fm := StandardMaterial3D.new()
			fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ring.material_override = fm
			ring.position = Vector3(0, 0.05, 0)
			add_child(ring)
			_rings[id] = ring
		var r: float = sim.weapon_range(id)
		ring.scale = Vector3(r, 1.0, r)
		var flash: float = float(_pulse.get(id, 0.0))
		_pulse[id] = maxf(0.0, flash - delta)
		var col := Color("8fd8ff") if float(w.slow) > 0.0 else (Color("ff7a3a") if w.has("burn") else Color("8fe05a"))
		(ring.material_override as StandardMaterial3D).albedo_color = Color(col.r, col.g, col.b, 0.18 + 0.6 * flash / 0.25)


# ------------------------------------------------------------------ effects

func pulse(wid: String) -> void:
	_pulse[wid] = 0.25


func tower_hit() -> void:
	shake = 0.2


func add_ring(pos: Vector2, radius: float, color: Color, ttl := 0.3) -> void:
	var fx: Dictionary = _fx_pool[_fx_next]
	_fx_next = (_fx_next + 1) % _fx_pool.size()
	var n: MeshInstance3D = fx.node
	n.position = Vector3(pos.x, 0.15, pos.y)
	fx.ttl = ttl
	fx.max = ttl
	fx.color = color
	fx.size = radius
	fx.beam = false
	n.visible = true


func add_strike(pos: Vector2) -> void:
	add_ring(pos, 0.9, Color("fff27a"), 0.25)


func add_kill_burst(pos: Vector2, boss: bool) -> void:
	var p: CPUParticles3D = _puff_pool[_puff_next]
	_puff_next = (_puff_next + 1) % _puff_pool.size()
	p.position = Vector3(pos.x, 0.4, pos.y)
	p.amount = 26 if boss else 8
	p.restart()
	p.emitting = true


func _update_fx(delta: float) -> void:
	for fx in _fx_pool:
		if fx.ttl <= 0.0:
			continue
		fx.ttl -= delta
		var n: MeshInstance3D = fx.node
		if fx.ttl <= 0.0:
			n.visible = false
			continue
		var k: float = 1.0 - fx.ttl / fx.max
		var s: float = float(fx.size) * (0.25 + 0.75 * k)
		n.scale = Vector3(s, 1.0, s)
		var c: Color = fx.color
		(n.material_override as StandardMaterial3D).albedo_color = Color(c.r, c.g, c.b, 1.0 - k)
