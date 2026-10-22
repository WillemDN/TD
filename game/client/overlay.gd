extends Control
## 2D layer drawn over the 3D view: health bars, lightning beams and floating texts. Positions are projected from tiles.

var sim
var world
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
	for z in _zaps:
		draw_line(world.tile_to_screen(z.from, 0.6), world.tile_to_screen(z.to, 0.5), Color(0.95, 0.95, 0.4, clampf(z.ttl / 0.14, 0.0, 1.0)), 3.0)
	for c in sim.creeps.values():
		if c.hp >= c.max_hp:
			continue
		var base = world.tile_to_screen(c.pos, (1.9 if c.air else 0.8) + (0.5 if c.boss else 0.0))
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
