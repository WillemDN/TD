extends Node3D
## Greybox low-poly 3D view of the simulation: terrain, towers, creeps, projectiles, ghost and camera.
## It only reads the simulation; all game rules live in res://core.

const PITCH := 1.0123           # camera pitch (58 degrees) in radians
const CELL_PX := 8              # terrain texture pixels per grid cell
const AIR_HEIGHT := 1.3

const ARMOR_COLORS := {
	"small": Color("9be07a"), "medium": Color("e6d35a"), "large": Color("e0954a"),
	"fort": Color("90a6c0"), "divine": Color("ffffff"),
}

var sim
var data
var cs := 0.5
var cam: Camera3D
var cam_target := Vector2(24, 15)
var zoom := 1.0
var fit_size := 20.0
var map_tiles := Vector2(48, 30)

var _materials := {}
var _tower_nodes := {}
var _creep_nodes := {}
var _proj_pool: Array = []
var _ghost: Node3D
var _ghost_box: MeshInstance3D
var _range_disc: MeshInstance3D
var _sel_ring: MeshInstance3D
var _path_mesh: ImmediateMesh
var _path_rev := -1
var _element_colors := {}


func setup(p_sim, p_data) -> void:
	sim = p_sim
	data = p_data
	cs = sim.grid.cell_size
	map_tiles = Vector2(float(sim.grid.w) * cs, float(sim.grid.h) * cs)
	for e in data.elements:
		_element_colors[e.id] = Color(e.color)
	_element_colors["ultimate"] = Color("bff6ff")
	_build_environment()
	_build_terrain()
	_build_walls()
	_build_markers()
	_build_ship()
	_build_ghost()
	_build_paths()
	cam_target = map_tiles * 0.5
	fit_camera()


# ------------------------------------------------------------------ camera

func fit_camera(insets := Vector2(64.0, 180.0)) -> void:
	var vp := get_viewport().get_visible_rect().size
	var aspect := vp.x / maxf(vp.y, 1.0)
	var usable := maxf(vp.y - insets.x - insets.y, vp.y * 0.4)
	var need_h := map_tiles.y * sin(PITCH) * 1.03 * vp.y / usable
	var need_w := map_tiles.x / aspect * 1.03
	fit_size = maxf(need_h * 0.75, need_w)
	zoom = 1.0
	cam.size = fit_size
	var ext := _view_extent()
	# centre the map in the free area between the bars
	cam_target = map_tiles * 0.5 + Vector2(0.0, (insets.y - insets.x) * 0.5 / vp.y * ext.y)
	_apply_camera()


func _apply_camera() -> void:
	cam.size = fit_size * zoom
	cam_target.x = clampf(cam_target.x, -2.0, map_tiles.x + 2.0)
	cam_target.y = clampf(cam_target.y, -2.0, map_tiles.y + 6.0)
	var focus := Vector3(cam_target.x, 0.0, cam_target.y)
	cam.position = focus + Vector3(0.0, sin(PITCH), cos(PITCH)) * 40.0
	cam.rotation = Vector3(-PITCH, 0.0, 0.0)


## Visible ground extent in tiles (x, y).
func _view_extent() -> Vector2:
	var vp := get_viewport().get_visible_rect().size
	var aspect := vp.x / maxf(vp.y, 1.0)
	return Vector2(cam.size * aspect, cam.size / sin(PITCH))


func pan_by_screen(delta_px: Vector2) -> void:
	var vp := get_viewport().get_visible_rect().size
	var ext := _view_extent()
	cam_target -= Vector2(delta_px.x / vp.x * ext.x, delta_px.y / vp.y * ext.y)
	_apply_camera()


func zoom_at(factor: float, screen_pos: Vector2) -> void:
	var before = screen_to_tile(screen_pos)
	zoom = clampf(zoom * factor, 0.2, 1.15)
	_apply_camera()
	var after = screen_to_tile(screen_pos)
	if before != null and after != null:
		cam_target += before - after
		_apply_camera()


func screen_to_tile(pos: Vector2):
	var from := cam.project_ray_origin(pos)
	var dir := cam.project_ray_normal(pos)
	var hit = Plane(Vector3.UP, 0.0).intersects_ray(from, dir)
	if hit == null:
		return null
	return Vector2(hit.x, hit.z)


func tile_to_screen(tile: Vector2, height: float = 0.0) -> Vector2:
	return cam.unproject_position(Vector3(tile.x, height, tile.y))


# ------------------------------------------------------------------ static scene

func _mat(color: Color, alpha: float = 1.0, unshaded: bool = false) -> StandardMaterial3D:
	var key := "%s_%s_%s" % [color.to_html(), alpha, unshaded]
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.roughness = 0.9
	_materials[key] = m
	return m


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0d1522")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b9c9e6")
	env.ambient_light_energy = 0.75
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.9, -0.6, 0.0)
	sun.light_energy = 0.85
	sun.shadow_enabled = false
	add_child(sun)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.near = 0.1
	cam.far = 200.0
	add_child(cam)


func _build_terrain() -> void:
	var w: int = sim.grid.w
	var h: int = sim.grid.h
	var img := Image.create(w * CELL_PX, h * CELL_PX, false, Image.FORMAT_RGBA8)
	var spawn_cells := {}
	for s in data.map.spawns:
		spawn_cells[int(s.cell[1]) * w + int(s.cell[0])] = true
	var g: Array = data.map.goal.rect
	for y in h:
		var row: String = data.map.rows[y]
		for x in w:
			var c := row[x]
			var col: Color
			if c == "#":
				col = Color("1b2635")
			elif c == ",":
				col = Color("5d7390")
				if x <= 7:
					col = Color("6b5a78")
				elif x >= int(g[0]) - 2:
					col = Color("4f87a6")
			else:
				var tile_odd := ((x / 2) + (y / 2)) % 2 == 1
				col = Color("e3edf7") if not tile_odd else Color("d3e1f0")
			img.fill_rect(Rect2i(x * CELL_PX, y * CELL_PX, CELL_PX, CELL_PX), col)
			if c == "." and x % 2 == 0:
				img.fill_rect(Rect2i(x * CELL_PX, y * CELL_PX, 1, CELL_PX), col.darkened(0.08))
			if c == "." and y % 2 == 0:
				img.fill_rect(Rect2i(x * CELL_PX, y * CELL_PX, CELL_PX, 1), col.darkened(0.08))
	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.roughness = 1.0
	var plane := PlaneMesh.new()
	plane.size = map_tiles
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.material_override = mat
	mi.position = Vector3(map_tiles.x * 0.5, 0.0, map_tiles.y * 0.5)
	add_child(mi)


func _build_walls() -> void:
	var w: int = sim.grid.w
	var h: int = sim.grid.h
	var cells: Array = []
	for y in h:
		for x in w:
			if sim.grid.flags[y * w + x] & 1 == 0:
				continue
			var edge := false
			for d in sim.grid.DIRS:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if sim.grid.in_bounds(nx, ny) and sim.grid.flags[ny * w + nx] & 1 == 0:
					edge = true
					break
			if edge:
				cells.append(Vector2i(x, y))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var box := BoxMesh.new()
	box.size = Vector3(cs, 1.0, cs)
	mm.mesh = box
	mm.instance_count = cells.size()
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in cells.size():
		var c: Vector2i = cells[i]
		var hgt := rng.randf_range(0.5, 1.1)
		var t := Transform3D(Basis.from_scale(Vector3(1.0, hgt, 1.0)), Vector3((float(c.x) + 0.5) * cs, hgt * 0.5, (float(c.y) + 0.5) * cs))
		mm.set_instance_transform(i, t)
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.material_override = _mat(Color("3a4d66"))
	add_child(inst)


func _build_markers() -> void:
	for s in data.map.spawns:
		var m := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.7
		cyl.bottom_radius = 0.7
		cyl.height = 0.06
		m.mesh = cyl
		m.material_override = _mat(Color("ff6a5c"), 0.8, true)
		m.position = Vector3((float(s.cell[0]) + 0.5) * cs, 0.04, (float(s.cell[1]) + 0.5) * cs)
		add_child(m)


func _build_ship() -> void:
	var g: Array = data.map.goal.rect
	var center := Vector3((float(g[0]) + float(g[2]) + 1.0) * 0.5 * cs, 0.0, (float(g[1]) + float(g[3]) + 1.0) * 0.5 * cs)
	var size := Vector3((float(g[2]) - float(g[0]) + 1.0) * cs, 0.9, (float(g[3]) - float(g[1]) + 1.0) * cs)
	var hull := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(size.x * 0.9, 0.9, size.z * 0.75)
	hull.mesh = hb
	hull.material_override = _mat(Color("8a5a36"))
	hull.position = center + Vector3(0, 0.45, 0)
	add_child(hull)
	var cabin := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(size.x * 0.4, 0.7, size.z * 0.45)
	cabin.mesh = cb
	cabin.material_override = _mat(Color("e8e2d6"))
	cabin.position = center + Vector3(-size.x * 0.1, 1.25, 0)
	add_child(cabin)
	var mast := MeshInstance3D.new()
	var mc := CylinderMesh.new()
	mc.top_radius = 0.05
	mc.bottom_radius = 0.06
	mc.height = 2.6
	mast.mesh = mc
	mast.material_override = _mat(Color("5a3d24"))
	mast.position = center + Vector3(size.x * 0.15, 1.7, 0)
	add_child(mast)
	var sail := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(0.04, 1.5, size.z * 0.55)
	sail.mesh = sb
	sail.material_override = _mat(Color("f4f4f0"))
	sail.position = center + Vector3(size.x * 0.15, 2.0, 0)
	add_child(sail)


func _build_ghost() -> void:
	_ghost = Node3D.new()
	_ghost.visible = false
	add_child(_ghost)
	_ghost_box = MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(1.0, 0.5, 1.0)
	_ghost_box.mesh = b
	_ghost.add_child(_ghost_box)
	_range_disc = MeshInstance3D.new()
	var d := CylinderMesh.new()
	d.height = 0.02
	d.radial_segments = 48
	_range_disc.mesh = d
	_range_disc.visible = false
	add_child(_range_disc)
	_sel_ring = MeshInstance3D.new()
	var r := BoxMesh.new()
	r.size = Vector3(1.2, 0.05, 1.2)
	_sel_ring.mesh = r
	_sel_ring.material_override = _mat(Color("ffffff"), 0.55, true)
	_sel_ring.visible = false
	add_child(_sel_ring)


func _build_paths() -> void:
	_path_mesh = ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = _path_mesh
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	add_child(mi)


func _rebuild_paths() -> void:
	_path_mesh.clear_surfaces()
	for i in data.map.spawns.size():
		var s: Dictionary = data.map.spawns[i]
		var cell: int = sim.grid.idx(int(s.cell[0]), int(s.cell[1]))
		_path_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		_path_mesh.surface_set_color(Color(1.0, 0.45, 0.35, 0.55))
		var guard := 0
		while cell >= 0 and guard < 4000:
			guard += 1
			var p: Vector2 = sim.grid.cell_center(cell)
			_path_mesh.surface_add_vertex(Vector3(p.x, 0.05, p.y))
			cell = sim.grid.next_cell[cell]
		_path_mesh.surface_end()


# ------------------------------------------------------------------ ghost and selection

func show_ghost(def: Dictionary, cx: int, cy: int, ok: bool) -> void:
	var fw: float = float(def.footprint[0]) * cs
	var fh: float = float(def.footprint[1]) * cs
	_ghost.visible = true
	_ghost.position = Vector3((float(cx) * cs) + fw * 0.5, 0.0, (float(cy) * cs) + fh * 0.5)
	(_ghost_box.mesh as BoxMesh).size = Vector3(fw, 0.5, fh)
	_ghost_box.position.y = 0.25
	_ghost_box.material_override = _mat(Color("5dff8a") if ok else Color("ff5d5d"), 0.6, true)
	show_range(_ghost.position, float(def.attack.range), ok)


func hide_ghost() -> void:
	_ghost.visible = false
	if not _sel_ring.visible:
		_range_disc.visible = false


func show_range(world_pos: Vector3, radius: float, ok: bool = true) -> void:
	var cyl := _range_disc.mesh as CylinderMesh
	var r := minf(radius, 40.0)
	cyl.top_radius = r
	cyl.bottom_radius = r
	_range_disc.position = Vector3(world_pos.x, 0.03, world_pos.z)
	_range_disc.material_override = _mat(Color("ffffff") if ok else Color("ff8080"), 0.16, true)
	_range_disc.visible = true


func select_tower(t) -> void:
	if t == null:
		_sel_ring.visible = false
		if not _ghost.visible:
			_range_disc.visible = false
		return
	_sel_ring.visible = true
	_sel_ring.position = Vector3(t.center.x, 0.06, t.center.y)
	show_range(Vector3(t.center.x, 0, t.center.y), float(t.def.attack.range))


# ------------------------------------------------------------------ per-frame sync

func update_view(alpha: float) -> void:
	_sync_towers()
	_sync_creeps(alpha)
	_sync_projectiles(alpha)
	if _path_rev != sim.grid_revision:
		_path_rev = sim.grid_revision
		_rebuild_paths()


func _sync_towers() -> void:
	for id in _tower_nodes.keys():
		if not sim.towers.has(id):
			_tower_nodes[id].queue_free()
			_tower_nodes.erase(id)
	for t in sim.towers.values():
		var n: Node3D = _tower_nodes.get(t.id)
		if n == null:
			n = _make_tower(t)
			_tower_nodes[t.id] = n
		var body: Node3D = n.get_node("body")
		var progress := 1.0 - clampf(t.build_left / t.build_total, 0.0, 1.0)
		var s := 1.0 if not t.building else 0.15 + 0.85 * progress
		body.scale = Vector3(1.0, s, 1.0)
		body.position.y = 0.18


func _make_tower(t) -> Node3D:
	var n := Node3D.new()
	var color: Color = _element_colors.get(t.def.element, Color.WHITE)
	var tier: int = int(t.def.tier)
	var base := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(0.94, 0.18, 0.94)
	base.mesh = bb
	base.material_override = _mat(color.darkened(0.55))
	base.position.y = 0.09
	n.add_child(base)
	var body := Node3D.new()
	body.name = "body"
	var height := 0.45 + 0.16 * float(tier)
	if t.def.element == "ultimate":
		height = 1.7
	var col := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.2 + 0.02 * float(tier)
	cm.bottom_radius = 0.34
	cm.height = height
	col.mesh = cm
	col.material_override = _mat(color)
	col.position.y = height * 0.5
	body.add_child(col)
	var cap := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.2
	sm.height = 0.4
	cap.mesh = sm
	cap.material_override = _mat(color.lightened(0.4))
	cap.position.y = height + 0.12
	body.add_child(cap)
	n.add_child(body)
	n.position = Vector3(t.center.x, 0.0, t.center.y)
	add_child(n)
	return n


func _sync_creeps(alpha: float) -> void:
	for id in _creep_nodes.keys():
		if not sim.creeps.has(id):
			_creep_nodes[id].queue_free()
			_creep_nodes.erase(id)
	for c in sim.creeps.values():
		var n: MeshInstance3D = _creep_nodes.get(c.id)
		if n == null:
			n = _make_creep(c)
			_creep_nodes[c.id] = n
		var p: Vector2 = c.prev.lerp(c.pos, alpha)
		n.position = Vector3(p.x, float(n.get_meta("lift", 0.0)) + (AIR_HEIGHT if c.air else 0.0), p.y)
		var tint: Color = ARMOR_COLORS.get(c.armor_type, Color.WHITE)
		if c.root_t > 0.0:
			tint = Color("f2f6ff")
		elif c.poison_t > 0.0:
			tint = tint.lerp(Color("3fd04a"), 0.6)
		elif c.slow_t > 0.0:
			tint = tint.lerp(Color("4aa8ff"), 0.6)
		n.material_override = _mat(tint)


func _make_creep(c) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var scale := 2.2 if c.boss else 1.45
	if c.air:
		var m := SphereMesh.new()
		m.radius = 0.2 * scale
		m.height = 0.4 * scale
		n.mesh = m
		var wing := MeshInstance3D.new()
		var wb := BoxMesh.new()
		wb.size = Vector3(0.12, 0.04, 0.8 * scale)
		wing.mesh = wb
		wing.material_override = _mat(Color("dfe9f5"))
		n.add_child(wing)
	else:
		var m := CapsuleMesh.new()
		m.radius = 0.17 * scale
		m.height = 0.62 * scale
		n.mesh = m
		n.set_meta("lift", 0.31 * scale)
	add_child(n)
	return n


func _sync_projectiles(alpha: float) -> void:
	var count: int = sim.projectiles.size()
	while _proj_pool.size() < count:
		var m := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.1
		s.height = 0.2
		m.mesh = s
		add_child(m)
		_proj_pool.append(m)
	for i in _proj_pool.size():
		var m: MeshInstance3D = _proj_pool[i]
		if i < count:
			var p = sim.projectiles[i]
			var pos: Vector2 = p.prev.lerp(p.pos, alpha)
			m.position = Vector3(pos.x, 0.8, pos.y)
			m.material_override = _mat(_element_colors.get(p.tower.def.element, Color.WHITE).lightened(0.3), 1.0, true)
			m.visible = true
		else:
			m.visible = false
