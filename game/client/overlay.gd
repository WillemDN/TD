extends Control
## 2D layer drawn over the 3D view: health bars, lightning beams and floating texts. Positions are projected from tiles.

var sim
var world
var debug := false
var _zaps: Array = []
var _texts: Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func add_zap(from: Vector2, to: Vector2) -> void:
	_zaps.append({"from": from, "to": to, "ttl": 0.14})


func add_text(pos: Vector2, text: String, color: Color, size: int = 20) -> void:
	_texts.append({"pos": pos, "text": text, "color": color, "ttl": 0.9, "size": size})


func tick(delta: float) -> void:
	for z in _zaps:
		z.ttl -= delta
	for t in _texts:
		t.ttl -= delta
	_zaps = _zaps.filter(func(z): return z.ttl > 0.0)
	_texts = _texts.filter(func(t): return t.ttl > 0.0)
	queue_redraw()


func _draw() -> void:
	if sim == null or world == null:
		return
	if debug:
		_draw_debug()
	for z in _zaps:
		draw_line(world.tile_to_screen(z.from, 0.6), world.tile_to_screen(z.to, 0.5), Color(0.95, 0.95, 0.4, clampf(z.ttl / 0.14, 0.0, 1.0)), 3.0)
	for c in sim.creeps.values():
		if c.hp >= c.max_hp:
			continue
		var base = world.tile_to_screen(c.pos, (2.6 if c.air else 1.2) * float(c.def.get("barScale", 1.0)) + (0.8 if c.boss else 0.0))
		var w := 34.0 if c.boss else 22.0
		var frac := clampf(c.hp / c.max_hp, 0.0, 1.0)
		draw_rect(Rect2(base.x - w * 0.5, base.y, w, 4.0), Color(0, 0, 0, 0.7))
		var col := Color(0.3, 0.9, 0.35).lerp(Color(0.95, 0.25, 0.2), 1.0 - frac)
		draw_rect(Rect2(base.x - w * 0.5, base.y, w * frac, 4.0), col)
	var font := ThemeDB.fallback_font
	for t in _texts:
		var p = world.tile_to_screen(t.pos, 1.0 + (0.9 - t.ttl) * 1.2)
		var a := clampf(t.ttl / 0.5, 0.0, 1.0)
		var col: Color = t.color
		col.a = a
		draw_string(font, p - Vector2(10, 0), t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, t.size, col)


## Debug view (F3 or the pause menu): what the simulation really thinks. Red = blocked by a tower, magenta dots = true monster
## positions, yellow squares = cells that a monster stands on.
func _draw_debug() -> void:
	var cs: float = sim.grid.cell_size
	var vr: Rect2 = world.view_rect()
	var x0 := maxi(0, int(floor(vr.position.x / cs)) - 1)
	var x1 := mini(sim.grid.w - 1, int(ceil(vr.end.x / cs)) + 1)
	var y0 := maxi(0, int(floor(vr.position.y / cs)) - 1)
	var y1 := mini(sim.grid.h - 1, int(ceil(vr.end.y / cs)) + 1)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var f: int = sim.grid.flags[y * sim.grid.w + x]
			if f & 4:
				var a: Vector2 = world.tile_to_screen(Vector2(float(x) * cs, float(y) * cs))
				var b: Vector2 = world.tile_to_screen(Vector2(float(x + 1) * cs, float(y + 1) * cs))
				var c: Vector2 = world.tile_to_screen(Vector2(float(x + 1) * cs, float(y) * cs))
				var d: Vector2 = world.tile_to_screen(Vector2(float(x) * cs, float(y + 1) * cs))
				draw_colored_polygon(PackedVector2Array([a, c, b, d]), Color(1, 0, 0, 0.35))
	var inside := 0
	for c in sim.creeps.values():
		var p: Vector2 = world.tile_to_screen(c.pos)
		draw_circle(p, 5.0, Color("ff00ff") if not c.air else Color("00e5ff"))
		if not c.air and sim.grid.flags[sim.grid.cell_of(c.pos)] & 4:
			inside += 1
	var font := ThemeDB.fallback_font
	var tower_cells := 0
	for i in sim.grid.flags.size():
		if sim.grid.flags[i] & 4:
			tower_cells += 1
	draw_string(font, Vector2(10, 120), "DEBUG towers %d (cells %d, expected %d) creeps %d, ground creeps inside a tower cell: %d" % [sim.towers.size(), tower_cells, sim.towers.size() * 4, sim.creeps.size(), inside], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.YELLOW)
