extends RefCounted
## Builds all 3D models of the game.
## Towers are composed from CC0 Kenney "Tower Defense Kit" parts (assets/kenney_td, see CREDITS.md); the monsters are
## built here from primitives in the same chunky low-poly style, with a simple procedural walk animation.

const KT := "res://assets/kenney_td/"

# per element: tower style, weapon on top, colour variant letter
const RECIPES := {
	"fire": {"style": "round", "weapon": "weapon-catapult", "v": "a"},
	"ice": {"style": "round", "weapon": "weapon-cannon", "v": "b"},
	"tech": {"style": "square", "weapon": "weapon-turret", "v": "a"},
	"electric": {"style": "round", "weapon": "weapon-ballista", "v": "c"},
	"stone": {"style": "square", "weapon": "weapon-catapult", "v": "b"},
	"poison": {"style": "round", "weapon": "weapon-cannon", "v": "c"},
	"nature": {"style": "square", "weapon": "weapon-ballista", "v": "c"},
	"shadow": {"style": "square", "weapon": "weapon-turret", "v": "b"},
	"crystal": {"style": "round", "weapon": "weapon-cannon", "v": "a"},
	"ultimate": {"style": "round", "weapon": "weapon-turret", "v": "a"},
}

const TOWER_SCALE := 0.78
const STACK_Y := 0.42     # vertical squash of the tower stack so rows of towers do not hide each other

# creep id -> [archetype, main colour, accent colour, scale, option]
const CREEPS := {
	"snow_scout": ["imp", "8fd3ff", "ffffff", 0.8, ""],
	"frost_tinker": ["humanoid", "5aa0c8", "f0c9a0", 0.85, "goggles"],
	"dusk_archer": ["humanoid", "5b4a8c", "e7c9a8", 0.95, "hood"],
	"tundra_brute": ["brute", "b8793f", "e0a56a", 1.0, "club"],
	"ice_stalker": ["beast", "6c8aa8", "dfeaf5", 0.9, "cat"],
	"rime_runner": ["beast", "9fb7cc", "ffffff", 0.9, "wolf"],
	"glacier_troll": ["brute", "5f9a94", "a9d8cf", 1.15, "club"],
	"wolf_raider": ["rider", "7a7f8c", "c9552f", 1.0, ""],
	"frost_marshal": ["humanoid", "3f6fa8", "f0d6b8", 1.9, "crown"],
	"ice_skiff": ["sled", "8cc3e6", "dfeaf5", 1.0, ""],
	"clockwork_brute": ["machine", "8a8f99", "e0b04a", 1.0, ""],
	"frost_lizard": ["lizard", "4f9a8a", "bfe8dc", 1.0, ""],
	"shadow_imp": ["imp", "7a4fb0", "ff7ad9", 1.0, ""],
	"shard_golem": ["golem", "7cc4ea", "dff4ff", 1.1, ""],
	"winter_wisp": ["wisp", "bfe8ff", "ffffff", 0.9, ""],
	"siege_sled": ["sled", "8a6a4a", "d9c7a8", 1.15, "ram"],
	"frozen_husk": ["humanoid", "7f98a8", "b7c9d4", 1.0, "zombie"],
	"glacier_lord": ["golem", "4a86c0", "bfe6ff", 2.0, "boss"],
	"totem_bearer": ["brute", "a0603a", "5fbf6a", 1.05, "totem"],
	"cursed_rider": ["rider", "3b3350", "9b6bd6", 1.1, ""],
	"prism_mage": ["humanoid", "c35bb0", "f1d2c0", 1.0, "wizard"],
	"frost_infernal": ["brute", "4b7bc4", "ff8a3a", 1.2, "horns"],
	"dire_bear": ["beast", "e9eef3", "c5d0da", 1.35, "bear"],
	"haunted_hunter": ["humanoid", "5c6f86", "9fe0d0", 1.05, "hood"],
	"warlord": ["brute", "7a3b3b", "d8b27a", 1.25, "helmet"],
	"ice_king": ["humanoid", "2f5fa6", "f0d6b8", 2.1, "crown"],
	"yeti_scout": ["yeti", "f2f6fa", "9fcbe8", 0.95, ""],
	"snow_golem": ["golem", "eef4fa", "7fb9e0", 1.2, "snow"],
	"ice_wraith": ["wisp", "7aa8e8", "d6e8ff", 1.15, "cloak"],
	"frost_giant": ["brute", "6f93c0", "dfeaf5", 1.7, "club"],
	"aurora_sprite": ["wisp", "7affc8", "ff9bf0", 0.9, "aurora"],
	"frost_whelp": ["dragon", "7fc3ea", "e6f5ff", 0.8, ""],
	"frost_drake": ["dragon", "5aa0d8", "e6f5ff", 1.0, ""],
	"blizzard_dragon": ["dragon", "4a78c8", "d8ecff", 1.25, ""],
	"elder_wyrm": ["dragon", "6a5ac8", "e0dcff", 1.55, ""],
}

static var _scenes := {}
static var _mats := {}
static var _heights := {}


# ------------------------------------------------------------------ shared helpers

static func scene(name: String) -> PackedScene:
	if not _scenes.has(name):
		_scenes[name] = load(KT + name + ".glb")
	return _scenes[name]


static func inst(name: String) -> Node3D:
	return scene(name).instantiate() as Node3D


static func mat(color: Color, emissive: float = 0.0, alpha: float = 1.0) -> StandardMaterial3D:
	var key := "%s_%s_%s" % [color.to_html(), emissive, alpha]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	m.roughness = 0.85
	if emissive > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emissive
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mats[key] = m
	return m


static func _mesh_height(n: Node) -> float:
	var top := 0.0
	if n is MeshInstance3D:
		var b: AABB = (n as MeshInstance3D).mesh.get_aabb()
		top = b.position.y + b.size.y
	for c in n.get_children():
		top = maxf(top, _mesh_height(c))
	return top


static func part_height(name: String) -> float:
	if not _heights.has(name):
		var n := inst(name)
		_heights[name] = _mesh_height(n)
		n.free()
	return _heights[name]


static func add_mesh(parent: Node3D, mesh: Mesh, color: Color, pos := Vector3.ZERO, rot := Vector3.ZERO, glow := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(color, glow)
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


static func sphere(r: float, squash := 1.0) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0 * squash
	m.radial_segments = 12
	m.rings = 6
	return m


static func capsule(r: float, h: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = 10
	m.rings = 4
	return m


static func cylinder(top: float, bottom: float, h: float, seg := 10) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = seg
	return m


# ------------------------------------------------------------------ towers

## Build a tower for a definition. The returned node has children "stack" (finished tower), "turret" (the part that turns
## to the target) and "build" (construction stages), see set_build_progress.
static func make_tower(def: Dictionary, color: Color) -> Node3D:
	var root := Node3D.new()
	var r: Dictionary = RECIPES.get(def.element, RECIPES["fire"])
	var style: String = r.style
	var v: String = r.v
	var tier: int = int(def.tier)
	var ultimate: bool = def.element == "ultimate"
	var stack := Node3D.new()
	stack.name = "stack"
	root.add_child(stack)
	var y := 0.0
	var parts: Array = ["tower-round-base", "tower-%s-bottom-%s" % [style, v]]
	if tier >= 3:
		parts.append("tower-%s-middle-%s" % [style, v])
	if tier >= 5:
		parts.append("tower-%s-middle-%s" % [style, "a" if v != "a" else "b"])
	if tier >= 2:
		parts.append("tower-%s-top-%s" % [style, v])
	if ultimate:
		parts = ["tower-round-base", "tower-round-bottom-a", "tower-round-middle-a", "tower-round-middle-b", "tower-round-middle-c", "tower-round-top-c"]
	for p in parts:
		var n := inst(p)
		n.position.y = y
		stack.add_child(n)
		y += part_height(p)
	var turret := Node3D.new()
	turret.name = "turret"
	turret.position.y = y
	turret.scale = Vector3(1.0, 1.0 / STACK_Y, 1.0)   # the weapon keeps its own proportions
	stack.add_child(turret)
	var w := inst(r.weapon)
	turret.add_child(w)
	if ultimate:
		w.scale = Vector3(1.4, 1.4, 1.4)
	var wy := 0.5
	_accent(turret, def.element, color, wy, tier)
	# colour ring on the foot so the element reads from far away
	# the real build footprint: exactly one tile, so you can see which tiles a tower blocks
	var pad := add_mesh(root, box(Vector3(0.98, 0.04, 0.98)), color.darkened(0.25), Vector3(0, 0.02, 0), Vector3.ZERO, 0.35)
	pad.name = "ring"
	var build := Node3D.new()
	build.name = "build"
	build.visible = false
	root.add_child(build)
	stack.scale = Vector3(TOWER_SCALE, TOWER_SCALE * STACK_Y, TOWER_SCALE)
	build.scale = Vector3(TOWER_SCALE, TOWER_SCALE * STACK_Y, TOWER_SCALE)
	root.set_meta("height", y * TOWER_SCALE * STACK_Y + 0.45)
	return root


static func _accent(parent: Node3D, element: String, color: Color, y: float, tier: int) -> void:
	var k := 0.8 + 0.08 * float(tier)
	match element:
		"fire":
			add_mesh(parent, cylinder(0.0, 0.15 * k, 0.4 * k, 8), Color("ff7a2a"), Vector3(0, y + 0.18, 0), Vector3.ZERO, 1.6)
			add_mesh(parent, cylinder(0.0, 0.08 * k, 0.26 * k, 8), Color("ffd45e"), Vector3(0, y + 0.14, 0), Vector3.ZERO, 2.0)
		"ice":
			for i in 3:
				var a := TAU * float(i) / 3.0
				add_mesh(parent, cylinder(0.0, 0.07 * k, 0.4 * k, 5), Color("9fe6ff"), Vector3(cos(a) * 0.24, y + 0.1, sin(a) * 0.24), Vector3(sin(a) * 0.3, 0, -cos(a) * 0.3), 1.0)
		"tech":
			add_mesh(parent, box(Vector3(0.1, 0.34 * k, 0.1)), Color("cfd8e0"), Vector3(0.22, y + 0.15, 0.2))
			add_mesh(parent, sphere(0.07), Color("ff5a5a"), Vector3(0.22, y + 0.34 * k + 0.1, 0.2), Vector3.ZERO, 2.0)
		"electric":
			add_mesh(parent, sphere(0.13 * k), Color("fff27a"), Vector3(0, y + 0.3, 0), Vector3.ZERO, 2.2)
			var t := TorusMesh.new()
			t.inner_radius = 0.2 * k
			t.outer_radius = 0.24 * k
			add_mesh(parent, t, Color("fff27a"), Vector3(0, y + 0.3, 0), Vector3(1.2, 0, 0), 1.6)
		"stone":
			add_mesh(parent, sphere(0.14 * k, 0.8), Color("b08a60"), Vector3(0.2, y + 0.1, 0.0))
			add_mesh(parent, sphere(0.1 * k, 0.8), Color("8c6a46"), Vector3(-0.18, y + 0.08, 0.14))
		"poison":
			add_mesh(parent, sphere(0.16 * k, 0.8), Color("7ccf3a"), Vector3(0, y + 0.18, 0.0), Vector3.ZERO, 1.4)
			add_mesh(parent, sphere(0.06), Color("c8ff7a"), Vector3(0.12, y + 0.34, 0.05), Vector3.ZERO, 2.0)
		"nature":
			add_mesh(parent, cylinder(0.0, 0.2 * k, 0.5 * k, 7), Color("3f9a4f"), Vector3(0.2, y + 0.22, 0.1))
			add_mesh(parent, cylinder(0.0, 0.14 * k, 0.36 * k, 7), Color("5fc46a"), Vector3(-0.2, y + 0.16, -0.1))
		"shadow":
			add_mesh(parent, sphere(0.14 * k), Color("b58aff"), Vector3(0, y + 0.34, 0), Vector3.ZERO, 2.0)
			add_mesh(parent, cylinder(0.0, 0.1, 0.3, 4), Color("5a3a8a"), Vector3(0, y + 0.1, 0), Vector3.ZERO, 0.8)
		"crystal":
			for i in 2:
				add_mesh(parent, cylinder(0.0, 0.1 * k, 0.5 * k, 4), Color("ff9be0"), Vector3(0.16 * (1 - 2 * i), y + 0.25, 0.1), Vector3(0, 0.4 * i, 0.25 * (1 - 2 * i)), 1.4)
		"ultimate":
			add_mesh(parent, sphere(0.2), Color("bff6ff"), Vector3(0, y + 0.5, 0), Vector3.ZERO, 2.4)


## Show construction: stages a-f while building, the finished tower when done. progress is 0..1.
static func set_build_progress(root: Node3D, progress: float) -> void:
	var stack: Node3D = root.get_node("stack")
	var build: Node3D = root.get_node("build")
	if progress >= 1.0:
		if not stack.visible:
			stack.visible = true
			build.visible = false
		return
	stack.visible = false
	build.visible = true
	var stage := clampi(int(progress * 6.0), 0, 5)
	var current: String = build.get_meta("stage", "")
	var want := "tower-round-build-%s" % "abcdef"[stage]
	if current != want:
		for c in build.get_children():
			c.queue_free()
		build.add_child(inst(want))
		build.set_meta("stage", want)


static func aim_turret(root: Node3D, from: Vector2, to: Vector2) -> void:
	var turret: Node3D = root.get_node("stack/turret")
	var d := to - from
	if d.length() > 0.01:
		turret.rotation.y = atan2(-d.x, -d.y)


# ------------------------------------------------------------------ monsters

## A creep model facing -Z. Meta: "legs" (nodes to swing), "wings", "bob" (how much it bobs), "float" (hover height).
static func make_creep(creep_id: String, def: Dictionary) -> Node3D:
	var root := Node3D.new()
	var model := Node3D.new()
	model.name = "model"
	root.add_child(model)
	var spec: Array = CREEPS.get(creep_id, ["brute", "8899aa", "ffffff", 1.0, ""])
	var c1 := Color(spec[1])
	var c2 := Color(spec[2])
	var s: float = float(spec[3])
	var opt: String = spec[4]
	var legs: Array = []
	var wings: Array = []
	match spec[0]:
		"imp":
			_imp(model, c1, c2, legs)
		"humanoid":
			_humanoid(model, c1, c2, opt, legs)
		"brute":
			_brute(model, c1, c2, opt, legs)
		"beast":
			_beast(model, c1, c2, opt, legs)
		"rider":
			_beast(model, c1, c2, "wolf", legs)
			var rider := Node3D.new()
			rider.position = Vector3(0, 0.38, 0.0)
			rider.scale = Vector3.ONE * 0.62
			model.add_child(rider)
			_humanoid(rider, c2, Color("e7c9a8"), "helmet", [])
		"lizard":
			_lizard(model, c1, c2, legs)
		"golem":
			_golem(model, c1, c2, opt)
		"wisp":
			_wisp(model, c1, c2, opt)
			root.set_meta("float", 0.28)
		"sled":
			_sled(model, c1, c2, opt)
		"machine":
			_machine(model, c1, c2, legs)
		"yeti":
			_brute(model, c1, c2, "yeti", legs)
		"dragon":
			_dragon(model, c1, c2, wings)
	# big monsters are slimmed down so they fit the gaps the pathing allows
	var width_cap := 1.5 if def.boss else 1.3
	model.scale = Vector3.ONE * minf(s, width_cap)
	s = minf(s, width_cap)
	root.set_meta("legs", legs)
	root.set_meta("wings", wings)
	root.set_meta("scale", s)
	root.set_meta("kind", spec[0])
	return root


static func _leg(parent: Node3D, x: float, z: float, len: float, thick: float, color: Color, legs: Array, phase: float) -> void:
	var pivot := Node3D.new()
	pivot.position = Vector3(x, len, z)
	parent.add_child(pivot)
	add_mesh(pivot, box(Vector3(thick, len, thick)), color, Vector3(0, -len * 0.5, 0))
	legs.append([pivot, phase])


static func _eyes(parent: Node3D, y: float, z: float, spread: float, color := Color("ffffff"), r := 0.035) -> void:
	for sx in [-1, 1]:
		add_mesh(parent, sphere(r), color, Vector3(spread * sx, y, z), Vector3.ZERO, 1.2)


static func _imp(m: Node3D, c1: Color, c2: Color, legs: Array) -> void:
	add_mesh(m, sphere(0.2, 0.9), c1, Vector3(0, 0.26, 0))
	add_mesh(m, sphere(0.13), c2, Vector3(0, 0.15, -0.12))
	for sx in [-1, 1]:
		add_mesh(m, cylinder(0.0, 0.05, 0.16, 5), c2, Vector3(0.12 * sx, 0.5, -0.02), Vector3(0, 0, -0.4 * sx))
	_eyes(m, 0.32, -0.17, 0.08, Color("1a2a3a"))
	_leg(m, -0.08, 0.0, 0.1, 0.07, c2, legs, 0.0)
	_leg(m, 0.08, 0.0, 0.1, 0.07, c2, legs, PI)


static func _humanoid(m: Node3D, c1: Color, skin: Color, opt: String, legs: Array) -> void:
	_leg(m, -0.07, 0.0, 0.22, 0.09, c1.darkened(0.3), legs, 0.0)
	_leg(m, 0.07, 0.0, 0.22, 0.09, c1.darkened(0.3), legs, PI)
	add_mesh(m, box(Vector3(0.26, 0.3, 0.17)), c1, Vector3(0, 0.37, 0))
	for sx in [-1, 1]:
		var arm := Node3D.new()
		arm.position = Vector3(0.17 * sx, 0.5, 0)
		m.add_child(arm)
		add_mesh(arm, box(Vector3(0.07, 0.26, 0.07)), c1.lightened(0.1), Vector3(0, -0.12, 0))
		if opt == "zombie":
			arm.rotation.x = -1.3
		legs.append([arm, PI * (0.5 if sx < 0 else 1.5)])
	add_mesh(m, sphere(0.12), skin, Vector3(0, 0.64, 0))
	_eyes(m, 0.66, -0.1, 0.05, Color("1a2a3a"), 0.025)
	match opt:
		"goggles":
			add_mesh(m, box(Vector3(0.24, 0.06, 0.04)), Color("ffd45e"), Vector3(0, 0.67, -0.1), Vector3.ZERO, 1.0)
		"hood":
			add_mesh(m, sphere(0.15, 1.1), c1.darkened(0.2), Vector3(0, 0.67, 0.03))
		"crown":
			add_mesh(m, cylinder(0.12, 0.1, 0.1, 6), Color("ffd45e"), Vector3(0, 0.78, 0), Vector3.ZERO, 1.2)
			for i in 5:
				var a := TAU * float(i) / 5.0
				add_mesh(m, cylinder(0.0, 0.025, 0.08, 4), Color("ffd45e"), Vector3(cos(a) * 0.1, 0.87, sin(a) * 0.1), Vector3.ZERO, 1.2)
			add_mesh(m, box(Vector3(0.3, 0.42, 0.04)), c1.darkened(0.15), Vector3(0, 0.4, 0.12))
		"wizard":
			add_mesh(m, cylinder(0.0, 0.17, 0.3, 8), c1.darkened(0.2), Vector3(0, 0.84, 0))
			add_mesh(m, cylinder(0.02, 0.02, 0.7, 5), Color("8a5a36"), Vector3(0.24, 0.35, -0.08))
			add_mesh(m, sphere(0.07), Color("ff9be0"), Vector3(0.24, 0.72, -0.08), Vector3.ZERO, 2.0)
		"helmet":
			add_mesh(m, sphere(0.135, 0.8), Color("9aa6b4"), Vector3(0, 0.69, 0))


static func _brute(m: Node3D, c1: Color, c2: Color, opt: String, legs: Array) -> void:
	_leg(m, -0.11, 0.0, 0.2, 0.14, c1.darkened(0.25), legs, 0.0)
	_leg(m, 0.11, 0.0, 0.2, 0.14, c1.darkened(0.25), legs, PI)
	add_mesh(m, box(Vector3(0.44, 0.38, 0.28)), c1, Vector3(0, 0.4, 0))
	add_mesh(m, sphere(0.22, 0.85), c1.lightened(0.05), Vector3(0, 0.58, 0.02))
	for sx in [-1, 1]:
		var arm := Node3D.new()
		arm.position = Vector3(0.27 * sx, 0.55, 0)
		m.add_child(arm)
		add_mesh(arm, box(Vector3(0.12, 0.34, 0.12)), c2, Vector3(0, -0.17, 0))
		legs.append([arm, PI * (0.5 if sx < 0 else 1.5)])
		if opt == "club" and sx > 0:
			add_mesh(arm, cylinder(0.08, 0.03, 0.4, 6), Color("8a5a36"), Vector3(0, -0.36, -0.1), Vector3(-0.6, 0, 0))
	add_mesh(m, sphere(0.13), c2, Vector3(0, 0.76, -0.04))
	_eyes(m, 0.78, -0.15, 0.06, Color("ffeb7a"), 0.03)
	match opt:
		"horns", "helmet":
			for sx in [-1, 1]:
				add_mesh(m, cylinder(0.0, 0.05, 0.22, 5), Color("e8e0cc") if opt == "helmet" else Color("ff8a3a"), Vector3(0.12 * sx, 0.9, -0.02), Vector3(0, 0, -0.5 * sx), 1.0 if opt == "horns" else 0.0)
		"totem":
			add_mesh(m, cylinder(0.05, 0.05, 0.7, 6), Color("7a4a2a"), Vector3(-0.3, 0.55, 0.0))
			add_mesh(m, sphere(0.09), c2, Vector3(-0.3, 0.95, 0.0), Vector3.ZERO, 1.2)
		"yeti":
			add_mesh(m, sphere(0.1), c2, Vector3(0, 0.74, -0.14), Vector3.ZERO, 0.6)


static func _beast(m: Node3D, c1: Color, c2: Color, opt: String, legs: Array) -> void:
	var len := 0.62 if opt != "bear" else 0.52
	add_mesh(m, capsule(0.17 if opt != "bear" else 0.24, len), c1, Vector3(0, 0.34, 0), Vector3(PI * 0.5, 0, 0))
	add_mesh(m, sphere(0.16 if opt != "bear" else 0.2), c1.lightened(0.05), Vector3(0, 0.46, -0.36))
	add_mesh(m, box(Vector3(0.1, 0.09, 0.14)), c2, Vector3(0, 0.42, -0.5))
	for sx in [-1, 1]:
		add_mesh(m, cylinder(0.0, 0.05, 0.12, 4), c1.darkened(0.2), Vector3(0.09 * sx, 0.62, -0.34))
		_leg(m, 0.12 * sx, -0.2, 0.22, 0.08, c1.darkened(0.25), legs, 0.0 if sx < 0 else PI)
		_leg(m, 0.12 * sx, 0.2, 0.22, 0.08, c1.darkened(0.25), legs, PI if sx < 0 else 0.0)
	_eyes(m, 0.5, -0.46, 0.07, Color("ffeb7a"), 0.025)
	add_mesh(m, cylinder(0.02, 0.06, 0.3, 5), c2, Vector3(0, 0.42, 0.42), Vector3(-0.9, 0, 0))


static func _lizard(m: Node3D, c1: Color, c2: Color, legs: Array) -> void:
	add_mesh(m, capsule(0.13, 0.62), c1, Vector3(0, 0.2, 0), Vector3(PI * 0.5, 0, 0))
	add_mesh(m, sphere(0.12, 0.8), c1.lightened(0.1), Vector3(0, 0.24, -0.38))
	add_mesh(m, cylinder(0.0, 0.1, 0.5, 6), c1.darkened(0.1), Vector3(0, 0.18, 0.55), Vector3(-PI * 0.5, 0, 0))
	for i in 4:
		add_mesh(m, box(Vector3(0.04, 0.09, 0.1)), c2, Vector3(0, 0.34, -0.15 + 0.14 * i))
	_eyes(m, 0.3, -0.45, 0.06, Color("ffeb7a"), 0.025)
	for sx in [-1, 1]:
		_leg(m, 0.14 * sx, -0.18, 0.12, 0.06, c1.darkened(0.25), legs, 0.0 if sx < 0 else PI)
		_leg(m, 0.14 * sx, 0.18, 0.12, 0.06, c1.darkened(0.25), legs, PI if sx < 0 else 0.0)


static func _golem(m: Node3D, c1: Color, c2: Color, opt: String) -> void:
	var round_parts := opt == "snow"
	if round_parts:
		add_mesh(m, sphere(0.26), c1, Vector3(0, 0.26, 0))
		add_mesh(m, sphere(0.2), c1, Vector3(0, 0.62, 0))
		add_mesh(m, sphere(0.14), c1, Vector3(0, 0.9, 0))
		add_mesh(m, cylinder(0.0, 0.04, 0.12, 5), Color("ff8a3a"), Vector3(0, 0.9, -0.16), Vector3(-PI * 0.5, 0, 0))
	else:
		add_mesh(m, box(Vector3(0.4, 0.34, 0.3)), c1, Vector3(0, 0.22, 0), Vector3(0, 0.2, 0))
		add_mesh(m, box(Vector3(0.34, 0.34, 0.26)), c1.lightened(0.1), Vector3(0, 0.56, 0), Vector3(0, -0.15, 0))
		add_mesh(m, box(Vector3(0.22, 0.22, 0.2)), c2, Vector3(0, 0.86, 0), Vector3(0, 0.3, 0), 0.5)
		for sx in [-1, 1]:
			add_mesh(m, box(Vector3(0.12, 0.3, 0.12)), c1.darkened(0.15), Vector3(0.32 * sx, 0.5, 0), Vector3(0, 0, 0.2 * sx))
	_eyes(m, 0.88 if not round_parts else 0.93, -0.12, 0.06, Color("ff5a5a") if opt == "boss" else Color("1a2a3a"), 0.03)
	if opt == "boss":
		for i in 4:
			var a := TAU * float(i) / 4.0 + 0.4
			add_mesh(m, cylinder(0.0, 0.07, 0.36, 4), Color("bfe6ff"), Vector3(cos(a) * 0.22, 1.05, sin(a) * 0.22), Vector3(sin(a) * 0.4, 0, -cos(a) * 0.4), 1.2)


static func _wisp(m: Node3D, c1: Color, c2: Color, opt: String) -> void:
	add_mesh(m, sphere(0.2), c1, Vector3(0, 0.32, 0), Vector3.ZERO, 1.6)
	add_mesh(m, sphere(0.11), c2, Vector3(0, 0.32, 0), Vector3.ZERO, 2.4)
	add_mesh(m, cylinder(0.0, 0.17, 0.46, 8), Color(c1.r, c1.g, c1.b, 0.7), Vector3(0, 0.1, 0.0), Vector3.ZERO, 0.8)
	_eyes(m, 0.34, -0.15, 0.07, Color("1a2a3a"), 0.03)
	if opt == "cloak":
		add_mesh(m, cylinder(0.0, 0.28, 0.6, 6), c1.darkened(0.4), Vector3(0, 0.15, 0.02), Vector3.ZERO, 0.4)
	if opt == "aurora":
		for i in 3:
			var a := TAU * float(i) / 3.0
			add_mesh(m, sphere(0.06), Color.from_hsv(float(i) / 3.0, 0.5, 1.0), Vector3(cos(a) * 0.3, 0.32 + sin(a) * 0.1, sin(a) * 0.3), Vector3.ZERO, 2.2)


static func _sled(m: Node3D, c1: Color, c2: Color, opt: String) -> void:
	add_mesh(m, box(Vector3(0.36, 0.14, 0.7)), c1, Vector3(0, 0.2, 0))
	add_mesh(m, box(Vector3(0.4, 0.05, 0.8)), c2, Vector3(0, 0.1, 0))
	add_mesh(m, box(Vector3(0.3, 0.12, 0.2)), c1.lightened(0.15), Vector3(0, 0.32, 0.18))
	add_mesh(m, sphere(0.1), Color("e7c9a8"), Vector3(0, 0.46, 0.18))
	if opt == "ram":
		add_mesh(m, cylinder(0.1, 0.1, 0.5, 8), Color("7a4a2a"), Vector3(0, 0.34, -0.3), Vector3(PI * 0.5, 0, 0))
		add_mesh(m, cylinder(0.0, 0.11, 0.16, 8), Color("9aa6b4"), Vector3(0, 0.34, -0.62), Vector3(-PI * 0.5, 0, 0))


static func _machine(m: Node3D, c1: Color, c2: Color, legs: Array) -> void:
	add_mesh(m, box(Vector3(0.4, 0.3, 0.5)), c1, Vector3(0, 0.34, 0))
	add_mesh(m, box(Vector3(0.28, 0.2, 0.28)), c2, Vector3(0, 0.6, -0.04))
	add_mesh(m, cylinder(0.04, 0.04, 0.26, 6), Color("5a5f68"), Vector3(0, 0.78, 0.05))
	add_mesh(m, cylinder(0.03, 0.03, 0.34, 6), Color("5a5f68"), Vector3(0, 0.62, -0.32), Vector3(PI * 0.5, 0, 0))
	for sx in [-1, 1]:
		_leg(m, 0.14 * sx, -0.14, 0.2, 0.09, Color("5a5f68"), legs, 0.0 if sx < 0 else PI)
		_leg(m, 0.14 * sx, 0.14, 0.2, 0.09, Color("5a5f68"), legs, PI if sx < 0 else 0.0)
	_eyes(m, 0.62, -0.19, 0.06, Color("ff5a5a"), 0.035)


static func _dragon(m: Node3D, c1: Color, c2: Color, wings: Array) -> void:
	add_mesh(m, capsule(0.14, 0.62), c1, Vector3(0, 0.3, 0), Vector3(PI * 0.5, 0, 0))
	add_mesh(m, sphere(0.13, 0.9), c1.lightened(0.1), Vector3(0, 0.38, -0.38))
	add_mesh(m, box(Vector3(0.1, 0.07, 0.12)), c2, Vector3(0, 0.34, -0.5))
	add_mesh(m, cylinder(0.0, 0.08, 0.5, 6), c1.darkened(0.1), Vector3(0, 0.28, 0.5), Vector3(-PI * 0.5, 0, 0))
	for sx in [-1, 1]:
		add_mesh(m, cylinder(0.0, 0.03, 0.14, 4), c2, Vector3(0.06 * sx, 0.52, -0.38), Vector3(-0.4, 0, -0.4 * sx))
	_eyes(m, 0.42, -0.46, 0.07, Color("ffeb7a"), 0.03)
	for sx in [-1, 1]:
		var wing := Node3D.new()
		wing.position = Vector3(0.1 * sx, 0.42, 0.0)
		m.add_child(wing)
		add_mesh(wing, box(Vector3(0.42, 0.04, 0.26)), c1.lightened(0.15), Vector3(0.21 * sx, 0, 0.04))
		add_mesh(wing, box(Vector3(0.28, 0.035, 0.18)), c2, Vector3(0.44 * sx, 0, 0.12))
		wings.append([wing, float(sx)])
	for i in 4:
		add_mesh(m, box(Vector3(0.04, 0.06, 0.08)), c2, Vector3(0, 0.46, -0.2 + 0.14 * i))


## Advance the walk animation of a creep model. t is a clock in seconds, speed the creep speed in tiles/s.
static func animate_creep(root: Node3D, t: float, speed: float, stagger: float) -> void:
	var model: Node3D = root.get_node("model")
	var phase := t * (5.0 + speed * 2.2) + stagger
	for l in root.get_meta("legs"):
		(l[0] as Node3D).rotation.x = sin(phase + float(l[1])) * 0.7
	for w in root.get_meta("wings"):
		(w[0] as Node3D).rotation.z = sin(t * 9.0 + stagger) * 0.55 * float(w[1])
	var kind: String = root.get_meta("kind")
	var lift: float = float(root.get_meta("float", 0.0))
	if kind == "wisp":
		model.position.y = lift + sin(t * 3.0 + stagger) * 0.06
	elif kind == "dragon":
		model.position.y = sin(t * 4.0 + stagger) * 0.05
	else:
		model.position.y = absf(sin(phase)) * 0.04
