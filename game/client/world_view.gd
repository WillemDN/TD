extends Node3D
## 3D view of the simulation: terrain, forest, towers, monsters, projectiles, effects and the camera.
## It only reads the simulation; all game rules live in res://core.

const Models := preload("res://client/models.gd")

const PITCH := 1.2             # camera pitch in radians (69 degrees): steep, so tall things do not cover the tile behind them
const CELL_PX := 8             # terrain texture pixels per grid cell
const AIR_HEIGHT := 2.1
const MIN_VIEW_W := 9.0        # closest zoom: tiles visible across the screen
const MAX_VIEW_FRACTION := 0.5 # farthest zoom: at most this share of the map width is visible
const DEFAULT_VIEW_W := 17.0

# soft mottled snow: value noise on the world position modulates the terrain colours
const SNOW_SHADER := "
shader_type spatial;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec2 map_size;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment() {
	vec3 c = texture(tex, UV).rgb;
	vec2 w = UV * map_size;
	float n = vnoise(w * 0.55) * 0.55 + vnoise(w * 2.1) * 0.3 + vnoise(w * 7.0) * 0.15;
	c *= 0.9 + n * 0.14;
	ALBEDO = c;
	ROUGHNESS = 1.0;
}
"

const ARMOR_COLORS := {
	"small": Color("8be36a"), "medium": Color("f2d94a"), "large": Color("f08a3a"),
	"fort": Color("7fa6d6"), "divine": Color("ffffff"),
}

var sim
var data
var cs := 0.5
var cam: Camera3D
var cam_target := Vector2(30, 15)
var view_w := DEFAULT_VIEW_W          # tiles visible across the screen
var map_tiles := Vector2(48, 30)
var tower_nodes := {}
var clock := 0.0

var _creep_nodes := {}
var _proj_pool: Array = []
var _fx_pool: Array = []
var _fx_next := 0
var _puff_pool: Array = []
var _puff_next := 0
var _ghost: Node3D
var _ghost_box: MeshInstance3D
var _range_disc: MeshInstance3D
var _sel_marker: Node3D
var _grid_mesh: MeshInstance3D
var _grid_rev := -1
var _build_mode := false
var _path_mesh: ImmediateMesh
var _path_mat: StandardMaterial3D
var _path_rev := -1
var _snow: CPUParticles3D
var _element_colors := {}
var _lifted_id := 0
var _tower_height := {}
var _wall_ghosts: Array = []


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
	_build_forest()
	_build_markers()
	_build_ship()
	_build_overlays()
	_build_pools()
	_build_snow()
	fit_camera()


# ------------------------------------------------------------------ camera

func _max_view_w() -> float:
	return maxf(MIN_VIEW_W + 4.0, map_tiles.x * MAX_VIEW_FRACTION)


## Default framing: the shared field in front of the ship, a part of the map only. insets = (top, bottom) px of UI.
func fit_camera(insets := Vector2(60.0, 120.0)) -> void:
	view_w = DEFAULT_VIEW_W
	var rect: Array = data.map.shared.rect
	var center := Vector2((float(rect[0]) + float(rect[2]) + 1.0) * 0.5 * cs - 1.5, (float(rect[1]) + float(rect[3]) + 1.0) * 0.5 * cs)
	cam_target = center
	_apply_camera(insets)


func _apply_camera(insets := Vector2.ZERO) -> void:
	view_w = clampf(view_w, MIN_VIEW_W, _max_view_w())
	var vp := get_viewport().get_visible_rect().size
	var aspect := vp.x / maxf(vp.y, 1.0)
	cam.size = view_w / aspect
	if insets != Vector2.ZERO:
		var ext := view_extent()
		cam_target.y += (insets.y - insets.x) * 0.5 / vp.y * ext.y
	var ext2 := view_extent()
	var half := ext2 * 0.5
	cam_target.x = clampf(cam_target.x, minf(half.x * 0.6, map_tiles.x * 0.5), maxf(map_tiles.x - half.x * 0.6, map_tiles.x * 0.5))
	cam_target.y = clampf(cam_target.y, minf(half.y * 0.6, map_tiles.y * 0.5), maxf(map_tiles.y - half.y * 0.6, map_tiles.y * 0.5))
	cam.position = Vector3(cam_target.x, 0.0, cam_target.y) + Vector3(0.0, sin(PITCH), cos(PITCH)) * 40.0
	cam.rotation = Vector3(-PITCH, 0.0, 0.0)
	if _snow != null:
		_snow.position = Vector3(cam_target.x, 9.0, cam_target.y)
		_snow.emission_box_extents = Vector3(view_w * 0.62, 0.2, ext2.y * 0.6)


## Visible ground extent in tiles (x, y).
func view_extent() -> Vector2:
	var vp := get_viewport().get_visible_rect().size
	var aspect := vp.x / maxf(vp.y, 1.0)
	return Vector2(cam.size * aspect, cam.size / sin(PITCH))


func view_rect() -> Rect2:
	var ext := view_extent()
	return Rect2(cam_target - ext * 0.5, ext)


func pan_by_screen(delta_px: Vector2) -> void:
	var vp := get_viewport().get_visible_rect().size
	var ext := view_extent()
	cam_target -= Vector2(delta_px.x / vp.x * ext.x, delta_px.y / vp.y * ext.y)
	_apply_camera()


func focus_on(tile: Vector2) -> void:
	cam_target = tile
	_apply_camera()


func zoom_at(factor: float, screen_pos: Vector2) -> void:
	var before = screen_to_tile(screen_pos)
	view_w *= factor
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


## Pixels (logical) covered by one tile at the current zoom.
func pixels_per_tile() -> float:
	return get_viewport().get_visible_rect().size.x / view_w


## Id of the tower under a screen position. Towers are tall, so the whole column from foot to top counts.
func pick_tower(pos: Vector2) -> int:
	var best := 0
	var best_d := INF
	var radius := pixels_per_tile() * 0.62
	for t in sim.towers.values():
		var foot := tile_to_screen(t.center, 0.0)
		var top := tile_to_screen(t.center, tower_height(t.id) * 0.8)
		var d := _dist_to_segment(pos, foot, top)
		if d <= radius and d < best_d:
			best_d = d
			best = t.id
	return best


func tower_height(id: int) -> float:
	return _tower_height.get(id, 1.2)


func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 0.0001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_to(a + ab * t)


# ------------------------------------------------------------------ static scene

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0b1422")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a9bfe0")
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.95, -0.7, 0.0)
	sun.light_color = Color("fff1dc")
	sun.light_energy = 0.9
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
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var g: Array = data.map.goal.rect
	for y in h:
		var row: String = data.map.rows[y]
		for x in w:
			var c := row[x]
			var col: Color
			if c == "#":
				col = Color("2d4a4a")
			elif c == ",":
				col = Color("c4d3e2")
				if x <= 7:
					col = Color("b8aed6")
				elif x >= int(g[0]) - 2:
					col = Color("a98e6a")
			else:
				col = Color("edf4fb")
			col = col.darkened(rng.randf_range(0.0, 0.012))
			img.fill_rect(Rect2i(x * CELL_PX, y * CELL_PX, CELL_PX, CELL_PX), col)
	var tex := ImageTexture.create_from_image(img)
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SNOW_SHADER
	m.shader = sh
	m.set_shader_parameter("tex", tex)
	m.set_shader_parameter("map_size", map_tiles)
	var plane := PlaneMesh.new()
	plane.size = map_tiles
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.material_override = m
	mi.position = Vector3(map_tiles.x * 0.5, 0.0, map_tiles.y * 0.5)
	add_child(mi)
	# dark ground around the map so the camera never sees the void
	var outer := PlaneMesh.new()
	outer.size = map_tiles * 3.0
	var om := MeshInstance3D.new()
	om.mesh = outer
	om.material_override = Models.mat(Color("233a3c"))
	om.position = Vector3(map_tiles.x * 0.5, -0.02, map_tiles.y * 0.5)
	add_child(om)


func _first_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n
	for c in n.get_children():
		var r := _first_mesh(c)
		if r != null:
			return r
	return null


func _build_forest() -> void:
	var w: int = sim.grid.w
	var h: int = sim.grid.h
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var kinds := {"snow-detail-tree-large": [], "snow-detail-tree": [], "snow-detail-rocks": [], "snow-detail-crystal": []}
	var banks: Array = []
	for y in h:
		for x in w:
			if sim.grid.flags[y * w + x] & 1 == 0:
				continue
			var near := 99
			for dy in range(-6, 7):
				for dx in range(-6, 7):
					var nx := x + dx
					var ny := y + dy
					if sim.grid.in_bounds(nx, ny) and sim.grid.flags[ny * w + nx] & 1 == 0:
						near = mini(near, maxi(absi(dx), absi(dy)))
			if near > 6:
				continue
			var pos := Vector3((float(x) + rng.randf()) * cs, 0.0, (float(y) + rng.randf()) * cs)
			var roll := rng.randf()
			if near == 1 and roll < 0.7:
				banks.append(Vector3((float(x) + 0.5) * cs, 0.0, (float(y) + 0.5) * cs))
			if roll < 0.55:
				kinds["snow-detail-tree-large" if roll < 0.3 else "snow-detail-tree"].append(pos)
			elif roll < 0.62:
				kinds["snow-detail-rocks"].append(pos)
			elif roll < 0.64:
				kinds["snow-detail-crystal"].append(pos)
	for name in kinds:
		var list: Array = kinds[name]
		if list.is_empty():
			continue
		var src := _first_mesh(Models.inst(name))
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = src.mesh
		mm.instance_count = list.size()
		var base_scale := 1.9 if name.contains("tree") else 1.5
		for i in list.size():
			var s := base_scale * rng.randf_range(0.8, 1.35)
			var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.9, 1.3), s))
			mm.set_instance_transform(i, Transform3D(b, list[i]))
		var inst := MultiMeshInstance3D.new()
		inst.multimesh = mm
		add_child(inst)
	# snow banks along the edge of the playable area
	if not banks.is_empty():
		var mm2 := MultiMesh.new()
		mm2.transform_format = MultiMesh.TRANSFORM_3D
		mm2.mesh = Models.box(Vector3(cs * 1.1, 1.0, cs * 1.1))
		mm2.instance_count = banks.size()
		for i in banks.size():
			var hh := rng.randf_range(0.12, 0.3)
			mm2.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(1, hh, 1)), banks[i] + Vector3(0, hh * 0.5, 0)))
		var bi := MultiMeshInstance3D.new()
		bi.multimesh = mm2
		bi.material_override = Models.mat(Color("f4f9ff"))
		add_child(bi)


func _build_markers() -> void:
	for s in data.map.spawns:
		var p := Vector3((float(s.cell[0]) + 0.5) * cs, 0.0, (float(s.cell[1]) + 0.5) * cs)
		var n := Models.inst("spawn-round")
		n.position = p
		n.scale = Vector3.ONE * 1.3
		add_child(n)
		var ring := Models.add_mesh(self, Models.cylinder(0.62, 0.62, 0.03, 20), Color("ff5a4a"), p + Vector3(0, 0.03, 0), Vector3.ZERO, 1.4)
		ring.material_override = Models.mat(Color("ff5a4a"), 1.4, 0.6)


func _build_ship() -> void:
	var g: Array = data.map.goal.rect
	var center := Vector3((float(g[0]) + float(g[2]) + 1.0) * 0.5 * cs, 0.0, (float(g[1]) + float(g[3]) + 1.0) * 0.5 * cs)
	var size := Vector3((float(g[2]) - float(g[0]) + 1.0) * cs, 0.9, (float(g[3]) - float(g[1]) + 1.0) * cs)
	var ship := Node3D.new()
	ship.position = center
	add_child(ship)
	Models.add_mesh(ship, Models.box(Vector3(size.x * 0.95, 0.5, size.z * 0.8)), Color("7a4a2c"), Vector3(0, 0.3, 0))
	Models.add_mesh(ship, Models.box(Vector3(size.x * 1.0, 0.1, size.z * 0.86)), Color("b98a55"), Vector3(0, 0.58, 0))
	var bow := Models.add_mesh(ship, Models.cylinder(0.0, size.z * 0.4, 0.5, 4), Color("7a4a2c"), Vector3(-size.x * 0.52, 0.3, 0))
	bow.rotation = Vector3(0, PI * 0.25, PI * 0.5)
	Models.add_mesh(ship, Models.box(Vector3(size.x * 0.34, 0.5, size.z * 0.5)), Color("e8e2d6"), Vector3(size.x * 0.22, 0.88, 0))
	Models.add_mesh(ship, Models.box(Vector3(size.x * 0.38, 0.1, size.z * 0.56)), Color("c0452f"), Vector3(size.x * 0.22, 1.18, 0))
	Models.add_mesh(ship, Models.cylinder(0.05, 0.07, 2.4, 6), Color("5a3d24"), Vector3(-size.x * 0.12, 1.8, 0))
	Models.add_mesh(ship, Models.box(Vector3(0.05, 1.5, size.z * 0.62)), Color("f4f4f0"), Vector3(-size.x * 0.12, 1.9, 0))
	Models.add_mesh(ship, Models.box(Vector3(0.04, 0.3, 0.5)), Color("c0452f"), Vector3(-size.x * 0.12, 3.0, 0.1), Vector3.ZERO, 0.4)
	for i in 3:
		Models.add_mesh(ship, Models.sphere(0.12), Color("ffd45e"), Vector3(size.x * (0.1 + 0.12 * i), 1.0, size.z * 0.28), Vector3.ZERO, 1.8)


func _build_overlays() -> void:
	_ghost = Node3D.new()
	_ghost.visible = false
	add_child(_ghost)
	_ghost_box = MeshInstance3D.new()
	_ghost_box.mesh = Models.box(Vector3(1.0, 0.5, 1.0))
	_ghost.add_child(_ghost_box)
	_range_disc = MeshInstance3D.new()
	_range_disc.mesh = Models.cylinder(1.0, 1.0, 0.02, 48)
	_range_disc.visible = false
	add_child(_range_disc)
	_sel_marker = Models.inst("selection-a")
	_sel_marker.visible = false
	_sel_marker.scale = Vector3.ONE * 1.25
	add_child(_sel_marker)
	# faint build grid, only shown while placing
	_grid_mesh = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = map_tiles
	_grid_mesh.mesh = pm
	_grid_mesh.position = Vector3(map_tiles.x * 0.5, 0.025, map_tiles.y * 0.5)
	_grid_mesh.visible = false
	add_child(_grid_mesh)
	# enemy route ribbons
	_path_mesh = ImmediateMesh.new()
	var pmi := MeshInstance3D.new()
	pmi.mesh = _path_mesh
	_path_mat = StandardMaterial3D.new()
	_path_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_path_mat.vertex_color_use_as_albedo = true
	_path_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_path_mat.albedo_texture = _dash_texture()
	_path_mat.texture_repeat = true
	pmi.material_override = _path_mat
	pmi.position.y = 0.04
	add_child(pmi)


func _dash_texture() -> ImageTexture:
	var img := Image.create(32, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	for x in 20:
		for y in 8:
			var edge := minf(float(y), float(7 - y)) / 3.5
			img.set_pixel(x, y, Color(1, 1, 1, clampf(0.4 + edge * 0.6, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


func _build_pools() -> void:
	for i in 28:
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
		_fx_pool.append({"node": m, "ttl": 0.0, "max": 0.3, "color": Color.WHITE})
	for i in 16:
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
		sm.radius = 0.05
		sm.height = 0.1
		sm.radial_segments = 4
		sm.rings = 2
		p.mesh = sm
		p.material_override = Models.mat(Color("ffd45e"), 1.6)
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
	q.size = Vector2(0.07, 0.07)
	_snow.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1, 1, 1, 0.85)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_snow.material_override = m
	add_child(_snow)


# ------------------------------------------------------------------ build mode, ghost, selection

func set_build_mode(on: bool) -> void:
	_build_mode = on
	_grid_mesh.visible = on
	if on:
		_refresh_grid()
	_path_mat.albedo_color = Color(1, 1, 1, 1.0 if on else 0.55)


func _refresh_grid() -> void:
	_grid_rev = sim.grid_revision
	var w: int = sim.grid.w
	var h: int = sim.grid.h
	var img := Image.create(w * CELL_PX, h * CELL_PX, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var line := Color(0.2, 0.5, 0.9, 0.12)
	var line2 := Color(0.15, 0.45, 0.9, 0.3)
	for y in h:
		for x in w:
			var f: int = sim.grid.flags[y * w + x]
			if f & 7 != 0:
				continue
			img.fill_rect(Rect2i(x * CELL_PX, y * CELL_PX, CELL_PX, 1), line2 if y % 2 == 0 else line)
			img.fill_rect(Rect2i(x * CELL_PX, y * CELL_PX, 1, CELL_PX), line2 if x % 2 == 0 else line)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	_grid_mesh.material_override = m


func show_ghost(def: Dictionary, cx: int, cy: int, ok: bool, lift: float = 0.0) -> void:
	var fw: float = float(def.footprint[0]) * cs
	var fh: float = float(def.footprint[1]) * cs
	_ghost.visible = true
	_ghost.position = Vector3(float(cx) * cs + fw * 0.5, lift, float(cy) * cs + fh * 0.5)
	(_ghost_box.mesh as BoxMesh).size = Vector3(fw, 0.12, fh)
	_ghost_box.position.y = 0.06
	_ghost_box.material_override = Models.mat(Color("5dff8a") if ok else Color("ff5d5d"), 1.0, 0.7)
	show_range(Vector3(_ghost.position.x, 0, _ghost.position.z), float(def.attack.range), ok)


## Preview of a dragged wall: one box per cell, green when it can be built and red when not.
func show_wall(cells: Array, oks: Array, def: Dictionary) -> void:
	while _wall_ghosts.size() < cells.size():
		var m := MeshInstance3D.new()
		m.mesh = Models.box(Vector3(1, 0.12, 1))
		add_child(m)
		_wall_ghosts.append(m)
	for i in _wall_ghosts.size():
		var m: MeshInstance3D = _wall_ghosts[i]
		if i >= cells.size() or def.is_empty():
			m.visible = false
			continue
		var fw: float = float(def.footprint[0]) * cs
		var fh: float = float(def.footprint[1]) * cs
		(m.mesh as BoxMesh).size = Vector3(fw, 0.14, fh)
		m.position = Vector3(float(cells[i].x) * cs + fw * 0.5, 0.08, float(cells[i].y) * cs + fh * 0.5)
		m.material_override = Models.mat(Color("5dff8a") if oks[i] else Color("ff5d5d"), 1.0, 0.75)
		m.visible = true


func hide_ghost() -> void:
	_ghost.visible = false
	if not _sel_marker.visible:
		_range_disc.visible = false


func show_range(world_pos: Vector3, radius: float, ok: bool = true) -> void:
	var cyl := _range_disc.mesh as CylinderMesh
	var r := minf(radius, 40.0)
	cyl.top_radius = r
	cyl.bottom_radius = r
	_range_disc.position = Vector3(world_pos.x, 0.035, world_pos.z)
	_range_disc.material_override = Models.mat(Color("4fb8ff") if ok else Color("ff7070"), 0.6, 0.13)
	_range_disc.visible = true


func select_tower(t) -> void:
	if t == null:
		_sel_marker.visible = false
		if not _ghost.visible:
			_range_disc.visible = false
		return
	_sel_marker.visible = true
	_sel_marker.position = Vector3(t.center.x, 0.04, t.center.y)
	show_range(Vector3(t.center.x, 0, t.center.y), float(t.def.attack.range))


func lift_tower(id: int) -> void:
	_lifted_id = id


# ------------------------------------------------------------------ per-frame sync

func update_view(alpha: float, delta: float) -> void:
	clock += delta
	_sync_towers()
	_sync_creeps(alpha)
	_sync_projectiles(alpha)
	_update_fx(delta)
	if _path_rev != sim.grid_revision:
		_path_rev = sim.grid_revision
		_rebuild_paths()
	if _build_mode and _grid_rev != sim.grid_revision:
		_refresh_grid()
	_path_mat.uv1_offset.x -= delta * 1.2


func _sync_towers() -> void:
	for id in tower_nodes.keys():
		if not sim.towers.has(id):
			tower_nodes[id].queue_free()
			tower_nodes.erase(id)
			_tower_height.erase(id)
	for t in sim.towers.values():
		var n: Node3D = tower_nodes.get(t.id)
		if n == null:
			var color: Color = _element_colors.get(t.def.element, Color.WHITE)
			n = Models.make_tower(t.def, color)
			_tower_height[t.id] = float(n.get_meta("height"))
			var shadow := Models.add_mesh(n, Models.cylinder(0.55, 0.55, 0.01, 14), Color(0, 0, 0), Vector3(0, 0.005, 0))
			shadow.material_override = Models.mat(Color(0, 0, 0), 0.0, 0.28)
			add_child(n)
			tower_nodes[t.id] = n
		var lift := 0.0
		if t.id == _lifted_id:
			lift = 0.35 + sin(clock * 6.0) * 0.04
		n.position = Vector3(t.center.x, lift, t.center.y)
		var progress := 1.0 - clampf(t.build_left / t.build_total, 0.0, 1.0)
		Models.set_build_progress(n, 1.0 if not t.building else minf(progress, 0.99))
		if not t.building:
			Models.aim_turret(n, t.center, t.aim if t.aim != Vector2.ZERO else t.center + Vector2(1, 0))


func _sync_creeps(alpha: float) -> void:
	for id in _creep_nodes.keys():
		if not sim.creeps.has(id):
			_creep_nodes[id].queue_free()
			_creep_nodes.erase(id)
	for c in sim.creeps.values():
		var n: Node3D = _creep_nodes.get(c.id)
		if n == null:
			n = _make_creep_node(c)
			_creep_nodes[c.id] = n
		var p: Vector2 = c.prev.lerp(c.pos, alpha)
		var air_h := AIR_HEIGHT if c.air else 0.0
		n.position = Vector3(p.x, air_h, p.y)
		var d: Vector2 = c.pos - c.prev
		if d.length() > 0.001:
			n.rotation.y = lerp_angle(n.rotation.y, atan2(-d.x, -d.y), 0.35)
		var model: Node3D = n.get_node("creep")
		var moving: bool = c.root_t <= 0.0
		Models.animate_creep(model, clock if moving else 0.0, c.speed * (1.0 - c.slow_amt), float(c.id) * 0.7)
		var marker: MeshInstance3D = n.get_node("marker")
		var tint: Color = ARMOR_COLORS.get(c.armor_type, Color.WHITE)
		if c.root_t > 0.0:
			tint = Color("ffffff")
		elif c.poison_t > 0.0:
			tint = Color("3fd04a")
		elif c.slow_t > 0.0:
			tint = Color("4aa8ff")
		marker.material_override = Models.mat(tint, 1.0, 0.9)


func _make_creep_node(c) -> Node3D:
	var n := Node3D.new()
	var model := Models.make_creep(c.def.id, c.def)
	model.name = "creep"
	n.add_child(model)
	var s: float = float(model.get_meta("scale"))
	var r := 0.3 * s if not c.boss else 0.5 * s
	var ground := -(AIR_HEIGHT if c.air else 0.0)
	var marker := Models.add_mesh(n, Models.cylinder(r, r, 0.03, 14), ARMOR_COLORS.get(c.armor_type, Color.WHITE), Vector3(0, ground + 0.03, 0), Vector3.ZERO, 1.0)
	marker.name = "marker"
	var sr := r * (1.5 if c.air else 0.9)
	var shadow := Models.add_mesh(n, Models.cylinder(sr, sr, 0.01, 12), Color(0, 0, 0), Vector3(0, ground + 0.01, 0))
	shadow.name = "shadow"
	shadow.material_override = Models.mat(Color(0, 0, 0), 0.0, 0.4 if c.air else 0.3)
	if c.air:
		# a thin line from the shadow up to the flyer makes it clear that it is in the air
		var line := Models.add_mesh(n, Models.cylinder(0.012, 0.012, AIR_HEIGHT, 4), Color("ffe45a"), Vector3(0, ground + AIR_HEIGHT * 0.5, 0), Vector3.ZERO, 0.8)
		line.material_override = Models.mat(Color("ffe45a"), 0.8, 0.5)
	add_child(n)
	return n


func _sync_projectiles(alpha: float) -> void:
	var count: int = sim.projectiles.size()
	while _proj_pool.size() < count:
		var node := Node3D.new()
		var glow := Models.add_mesh(node, Models.sphere(0.1), Color.WHITE, Vector3.ZERO, Vector3.ZERO, 1.8)
		glow.name = "glow"
		add_child(node)
		_proj_pool.append(node)
	for i in _proj_pool.size():
		var node: Node3D = _proj_pool[i]
		if i >= count:
			node.visible = false
			continue
		var p = sim.projectiles[i]
		var pos: Vector2 = p.prev.lerp(p.pos, alpha)
		node.position = Vector3(pos.x, 0.9, pos.y)
		var col: Color = _element_colors.get(p.tower.def.element, Color.WHITE).lightened(0.25)
		(node.get_node("glow") as MeshInstance3D).material_override = Models.mat(col, 1.8)
		node.visible = true


# ------------------------------------------------------------------ effects

func add_impact(pos: Vector2, element: String, air: bool) -> void:
	var fx: Dictionary = _fx_pool[_fx_next]
	_fx_next = (_fx_next + 1) % _fx_pool.size()
	var n: MeshInstance3D = fx.node
	n.position = Vector3(pos.x, 1.0 if air else 0.25, pos.y)
	fx.ttl = 0.28
	fx.max = 0.28
	fx.color = _element_colors.get(element, Color.WHITE).lightened(0.3)
	n.visible = true


func add_kill_burst(pos: Vector2, boss: bool) -> void:
	var p: CPUParticles3D = _puff_pool[_puff_next]
	_puff_next = (_puff_next + 1) % _puff_pool.size()
	p.position = Vector3(pos.x, 0.4, pos.y)
	p.amount = 24 if boss else 10
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
		var s := 0.15 + 0.5 * k
		n.scale = Vector3(s, s, s)
		var c: Color = fx.color
		(n.material_override as StandardMaterial3D).albedo_color = Color(c.r, c.g, c.b, 1.0 - k)


# ------------------------------------------------------------------ enemy routes

func _rebuild_paths() -> void:
	_path_mesh.clear_surfaces()
	var drawn := {}
	for i in data.map.spawns.size():
		var s: Dictionary = data.map.spawns[i]
		var cell: int = sim.grid.idx(int(s.cell[0]), int(s.cell[1]))
		var pts: Array = []
		var guard := 0
		while cell >= 0 and guard < 4000:
			guard += 1
			pts.append(sim.grid.cell_center(cell))
			cell = sim.grid.next_cell[cell]
		var simple: Array = []
		for j in pts.size():
			if j == 0 or j == pts.size() - 1:
				simple.append(pts[j])
				continue
			var a: Vector2 = (pts[j] - pts[j - 1]).normalized()
			var b: Vector2 = (pts[j + 1] - pts[j]).normalized()
			if a.dot(b) < 0.999:
				simple.append(pts[j])
		var col := Color(1.0, 0.55, 0.35, 0.9) if i % 2 == 0 else Color(1.0, 0.72, 0.3, 0.9)
		var u := 0.0
		var started := false
		for j in range(simple.size() - 1):
			var p0: Vector2 = simple[j]
			var p1: Vector2 = simple[j + 1]
			var key := "%d_%d_%d_%d" % [int(p0.x * 4), int(p0.y * 4), int(p1.x * 4), int(p1.y * 4)]
			var seg_len := p0.distance_to(p1)
			if drawn.has(key) or seg_len < 0.01:
				u += seg_len * 2.0
				continue
			drawn[key] = true
			if not started:
				_path_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
				started = true
			var dir := (p1 - p0) / seg_len
			var nrm := Vector2(-dir.y, dir.x) * 0.07
			var u1 := u + seg_len * 2.0
			var quad := [[p0 + nrm, u, 0.0], [p1 + nrm, u1, 0.0], [p0 - nrm, u, 1.0], [p1 + nrm, u1, 0.0], [p1 - nrm, u1, 1.0], [p0 - nrm, u, 1.0]]
			for v in quad:
				_path_mesh.surface_set_color(col)
				_path_mesh.surface_set_uv(Vector2(float(v[1]), float(v[2])))
				_path_mesh.surface_add_vertex(Vector3((v[0] as Vector2).x, 0.0, (v[0] as Vector2).y))
			u = u1
		if started:
			_path_mesh.surface_end()
