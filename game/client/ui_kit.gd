class_name UiKit
extends RefCounted
## Look and feel of the interface: glass panels, buttons and vector icons drawn in code (no image assets).

const BG := Color(0.055, 0.09, 0.15)
const ACCENT := Color("5cc8ff")
const GOOD := Color("46c26a")
const BAD := Color("e05a5a")
const GOLD := Color("ffd45e")
const TEXT := Color("e8f2ff")
const MUTED := Color("93a8c2")


static func panel_style(alpha := 0.86, radius := 14, border := true) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(BG.r, BG.g, BG.b, alpha)
	sb.set_corner_radius_all(radius)
	if border:
		sb.set_border_width_all(1)
		sb.border_color = Color(1, 1, 1, 0.14)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


static func button_style(fill: Color, border: Color, radius := 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(2)
	sb.border_color = border
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb


## A button with a vector icon on the left or top and optional text. Toggle it for "selected" cards.
class GlyphButton extends Button:
	var glyph := ""
	var glyph_color := Color.WHITE
	var accent := Color("5cc8ff")
	var glyph_size := 22.0
	var top_icon := false      # icon above the text instead of left of it
	var badge := ""            # small text at the top right (hotkey or tier)

	func _init(p_glyph := "", p_text := "", p_accent := Color("5cc8ff"), min_size := Vector2(44, 44)) -> void:
		glyph = p_glyph
		text = p_text
		accent = p_accent
		glyph_color = p_accent.lightened(0.25)
		custom_minimum_size = min_size
		focus_mode = Control.FOCUS_NONE
		clip_text = true
		alignment = HORIZONTAL_ALIGNMENT_CENTER
		_restyle()

	func _left_margin() -> int:
		# text sits to the right of a left icon
		return int(glyph_size) + 16 if (glyph != "" and not top_icon) else 8

	func _restyle() -> void:
		var sbs := {
			"normal": UiKit.button_style(Color(0.11, 0.17, 0.27, 0.92), Color(1, 1, 1, 0.12)),
			"hover": UiKit.button_style(Color(0.16, 0.24, 0.36, 0.95), Color(accent.r, accent.g, accent.b, 0.6)),
			"pressed": UiKit.button_style(Color(accent.r, accent.g, accent.b, 0.35), accent),
			"disabled": UiKit.button_style(Color(0.1, 0.12, 0.17, 0.7), Color(1, 1, 1, 0.05)),
		}
		for k in sbs:
			sbs[k].content_margin_left = _left_margin()
			add_theme_stylebox_override(k, sbs[k])
		add_theme_color_override("font_color", UiKit.TEXT)
		add_theme_color_override("font_pressed_color", Color.WHITE)
		add_theme_color_override("font_hover_color", Color.WHITE)
		add_theme_color_override("font_disabled_color", UiKit.MUTED)

	func set_selected(on: bool) -> void:
		var border := accent if on else Color(1, 1, 1, 0.12)
		var fill := Color(accent.r, accent.g, accent.b, 0.28) if on else Color(0.11, 0.17, 0.27, 0.92)
		var top := int(glyph_size) + 10 if top_icon else 4
		for state in ["normal", "hover", "pressed"]:
			var sb := UiKit.button_style(fill.lightened(0.1) if state == "hover" else (Color(accent.r, accent.g, accent.b, 0.4) if state == "pressed" else fill), border if state != "pressed" else accent)
			sb.content_margin_top = top
			sb.content_margin_left = _left_margin()
			add_theme_stylebox_override(state, sb)

	func _draw() -> void:
		if glyph == "":
			return
		var c := Vector2(size.x * 0.5, size.y * 0.5)
		if top_icon:
			c = Vector2(size.x * 0.5, glyph_size * 0.5 + 8.0)
		elif text != "":
			c = Vector2(glyph_size * 0.5 + 10.0, size.y * 0.5)
		UiKit.draw_glyph(self, glyph, c, glyph_size, glyph_color)
		if badge != "":
			var font := get_theme_default_font()
			draw_string(font, Vector2(size.x - 14.0, 13.0), badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.55))


## A plain icon widget for labels and chips.
class GlyphRect extends Control:
	var glyph := ""
	var tint := Color.WHITE

	func _init(p_glyph := "", p_tint := Color.WHITE, px := 22.0) -> void:
		glyph = p_glyph
		tint = p_tint
		custom_minimum_size = Vector2(px, px)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_glyph(g: String, c: Color) -> void:
		if g != glyph or c != tint:
			glyph = g
			tint = c
			queue_redraw()

	func _draw() -> void:
		UiKit.draw_glyph(self, glyph, size * 0.5, minf(size.x, size.y), tint)


## Round floating button (speed, camera...) with an icon.
class RoundButton extends Button:
	var glyph := ""
	var tint := Color("5cc8ff")

	func _init(p_glyph := "", p_tint := Color("5cc8ff"), diameter := 48.0) -> void:
		glyph = p_glyph
		tint = p_tint
		custom_minimum_size = Vector2(diameter, diameter)
		focus_mode = Control.FOCUS_NONE
		var r := int(diameter * 0.5)
		for state in ["normal", "hover", "pressed", "disabled"]:
			var fill := Color(0.09, 0.14, 0.22, 0.9)
			if state == "pressed":
				fill = Color(tint.r, tint.g, tint.b, 0.4)
			var sb := UiKit.button_style(fill, Color(tint.r, tint.g, tint.b, 0.7), r)
			add_theme_stylebox_override(state, sb)

	func _draw() -> void:
		UiKit.draw_glyph(self, glyph, size * 0.5, minf(size.x, size.y) * 0.5, tint.lightened(0.3))


# ------------------------------------------------------------------ vector icons

static func _poly(ci: CanvasItem, pts: Array, color: Color) -> void:
	var arr := PackedVector2Array()
	for p in pts:
		arr.append(p)
	ci.draw_colored_polygon(arr, color)


static func draw_glyph(ci: CanvasItem, kind: String, c: Vector2, size: float, color: Color) -> void:
	var r := size * 0.5
	match kind:
		"coin":
			ci.draw_circle(c, r, GOLD)
			ci.draw_circle(c, r * 0.68, Color("e0a82e"))
			ci.draw_circle(c, r * 0.4, GOLD)
		"log":
			ci.draw_rect(Rect2(c.x - r, c.y - r * 0.6, r * 2.0, r * 1.2), Color("a9763f"), true)
			ci.draw_circle(Vector2(c.x + r, c.y), r * 0.6, Color("d9a566"))
			ci.draw_circle(Vector2(c.x + r, c.y), r * 0.3, Color("a9763f"))
		"heart":
			ci.draw_circle(c + Vector2(-r * 0.45, -r * 0.2), r * 0.55, BAD)
			ci.draw_circle(c + Vector2(r * 0.45, -r * 0.2), r * 0.55, BAD)
			_poly(ci, [c + Vector2(-r * 0.98, -r * 0.05), c + Vector2(r * 0.98, -r * 0.05), c + Vector2(0, r * 0.95)], BAD)
		"fire":
			_poly(ci, [c + Vector2(0, -r), c + Vector2(r * 0.7, r * 0.1), c + Vector2(r * 0.5, r * 0.8), c + Vector2(-r * 0.5, r * 0.8), c + Vector2(-r * 0.7, r * 0.1), c + Vector2(-r * 0.15, -r * 0.2)], Color("ff7a2a"))
			_poly(ci, [c + Vector2(0, -r * 0.1), c + Vector2(r * 0.35, r * 0.4), c + Vector2(0, r * 0.8), c + Vector2(-r * 0.35, r * 0.4)], Color("ffd45e"))
		"ice":
			for i in 3:
				var a := PI * float(i) / 3.0
				var d := Vector2(cos(a), sin(a)) * r
				ci.draw_line(c - d, c + d, color, maxf(2.0, size * 0.1))
			ci.draw_circle(c, r * 0.22, color)
		"tech":
			ci.draw_circle(c, r * 0.72, color)
			ci.draw_circle(c, r * 0.3, Color(0, 0, 0, 0.55))
			for i in 8:
				var a := TAU * float(i) / 8.0
				ci.draw_line(c + Vector2(cos(a), sin(a)) * r * 0.7, c + Vector2(cos(a), sin(a)) * r, color, maxf(3.0, size * 0.16))
		"electric":
			_poly(ci, [c + Vector2(r * 0.2, -r), c + Vector2(-r * 0.6, r * 0.15), c + Vector2(-r * 0.05, r * 0.15), c + Vector2(-r * 0.25, r), c + Vector2(r * 0.65, -r * 0.2), c + Vector2(r * 0.1, -r * 0.2)], Color("fff27a"))
		"stone":
			_poly(ci, [c + Vector2(-r, r * 0.4), c + Vector2(-r * 0.6, -r * 0.5), c + Vector2(-r * 0.05, -r * 0.9), c + Vector2(r * 0.7, -r * 0.4), c + Vector2(r, r * 0.4), c + Vector2(r * 0.4, r * 0.8), c + Vector2(-r * 0.5, r * 0.8)], Color("b08a60"))
			ci.draw_line(c + Vector2(-r * 0.05, -r * 0.9), c + Vector2(r * 0.1, r * 0.2), Color(0, 0, 0, 0.3), 2.0)
		"poison":
			ci.draw_circle(c + Vector2(0, r * 0.25), r * 0.7, Color("7ccf3a"))
			_poly(ci, [c + Vector2(0, -r), c + Vector2(r * 0.55, r * 0.05), c + Vector2(-r * 0.55, r * 0.05)], Color("7ccf3a"))
			ci.draw_circle(c + Vector2(-r * 0.2, r * 0.25), r * 0.14, Color("d8ff9a"))
		"nature":
			_poly(ci, [c + Vector2(-r * 0.9, r * 0.8), c + Vector2(-r * 0.7, -r * 0.2), c + Vector2(0, -r), c + Vector2(r * 0.9, -r * 0.8), c + Vector2(r * 0.6, r * 0.1), c + Vector2(-r * 0.1, r * 0.7)], Color("49b05a"))
			ci.draw_line(c + Vector2(-r * 0.9, r * 0.8), c + Vector2(r * 0.5, -r * 0.5), Color("1f5a2a"), 2.0)
		"shadow":
			var pts: Array = []
			for i in 13:
				var a := PI * 0.5 + PI * float(i) / 12.0
				pts.append(c + Vector2(cos(a), sin(a)) * r)
			for i in 13:
				var a := PI * 1.5 - PI * float(i) / 12.0
				pts.append(c + Vector2(r * 0.35, 0) + Vector2(cos(a), sin(a)) * r * 0.8)
			_poly(ci, pts, Color("b58aff"))
		"crystal":
			_poly(ci, [c + Vector2(0, -r), c + Vector2(r * 0.75, -r * 0.1), c + Vector2(0, r), c + Vector2(-r * 0.75, -r * 0.1)], Color("ff9be0"))
			_poly(ci, [c + Vector2(0, -r), c + Vector2(r * 0.25, -r * 0.1), c + Vector2(0, r), c + Vector2(-r * 0.25, -r * 0.1)], Color("ffd0f2"))
		"ultimate":
			var pts2: Array = []
			for i in 10:
				var a := -PI * 0.5 + TAU * float(i) / 10.0
				var rr := r if i % 2 == 0 else r * 0.45
				pts2.append(c + Vector2(cos(a), sin(a)) * rr)
			_poly(ci, pts2, Color("bff6ff"))
		"play":
			_poly(ci, [c + Vector2(-r * 0.5, -r * 0.7), c + Vector2(r * 0.8, 0), c + Vector2(-r * 0.5, r * 0.7)], color)
		"ff":
			_poly(ci, [c + Vector2(-r * 0.9, -r * 0.6), c + Vector2(0, 0), c + Vector2(-r * 0.9, r * 0.6)], color)
			_poly(ci, [c + Vector2(0, -r * 0.6), c + Vector2(r * 0.9, 0), c + Vector2(0, r * 0.6)], color)
		"ff2":
			_poly(ci, [c + Vector2(-r * 1.0, -r * 0.55), c + Vector2(-r * 0.35, 0), c + Vector2(-r * 1.0, r * 0.55)], color)
			_poly(ci, [c + Vector2(-r * 0.35, -r * 0.55), c + Vector2(r * 0.3, 0), c + Vector2(-r * 0.35, r * 0.55)], color)
			_poly(ci, [c + Vector2(r * 0.3, -r * 0.55), c + Vector2(r * 0.95, 0), c + Vector2(r * 0.3, r * 0.55)], color)
		"pause":
			ci.draw_rect(Rect2(c.x - r * 0.6, c.y - r * 0.7, r * 0.45, r * 1.4), color)
			ci.draw_rect(Rect2(c.x + r * 0.15, c.y - r * 0.7, r * 0.45, r * 1.4), color)
		"menu":
			for i in 3:
				ci.draw_rect(Rect2(c.x - r * 0.8, c.y - r * 0.7 + r * 0.7 * i, r * 1.6, r * 0.24), color)
		"move":
			for i in 4:
				var a := TAU * float(i) / 4.0
				var d := Vector2(cos(a), sin(a))
				var n := Vector2(-d.y, d.x)
				ci.draw_line(c, c + d * r * 0.8, color, 2.5)
				_poly(ci, [c + d * r, c + d * r * 0.55 + n * r * 0.28, c + d * r * 0.55 - n * r * 0.28], color)
		"sell":
			ci.draw_circle(c + Vector2(0, -r * 0.15), r * 0.62, GOLD)
			_poly(ci, [c + Vector2(-r * 0.5, r * 0.45), c + Vector2(r * 0.5, r * 0.45), c + Vector2(0, r)], color)
		"check":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.7, 0), c + Vector2(-r * 0.2, r * 0.55), c + Vector2(r * 0.8, -r * 0.6)]), Color.WHITE, maxf(3.0, size * 0.16))
		"cross":
			ci.draw_line(c + Vector2(-r * 0.6, -r * 0.6), c + Vector2(r * 0.6, r * 0.6), Color.WHITE, maxf(3.0, size * 0.16))
			ci.draw_line(c + Vector2(-r * 0.6, r * 0.6), c + Vector2(r * 0.6, -r * 0.6), Color.WHITE, maxf(3.0, size * 0.16))
		"wall":
			for row in 3:
				var off := 0.0 if row % 2 == 0 else r * 0.5
				ci.draw_rect(Rect2(c.x - r + off, c.y - r * 0.8 + row * r * 0.55, r * 0.9, r * 0.4), color, false, 2.0)
				ci.draw_rect(Rect2(c.x - r + off + r * 1.0, c.y - r * 0.8 + row * r * 0.55, r * 0.9, r * 0.4), color, false, 2.0)
		"air":
			_poly(ci, [c + Vector2(-r, -r * 0.2), c + Vector2(0, r * 0.15), c + Vector2(r, -r * 0.2), c + Vector2(0, -r * 0.7)], color)
			_poly(ci, [c + Vector2(-r * 0.4, r * 0.3), c + Vector2(0, r * 0.9), c + Vector2(r * 0.4, r * 0.3)], color)
		"ground":
			_poly(ci, [c + Vector2(-r, r * 0.7), c + Vector2(-r * 0.3, -r * 0.5), c + Vector2(r * 0.2, r * 0.2), c + Vector2(r * 0.55, -r * 0.2), c + Vector2(r, r * 0.7)], color)
		"shield":
			_poly(ci, [c + Vector2(-r * 0.8, -r * 0.8), c + Vector2(r * 0.8, -r * 0.8), c + Vector2(r * 0.8, 0), c + Vector2(0, r), c + Vector2(-r * 0.8, 0)], color)
		"target":
			ci.draw_arc(c, r * 0.75, 0, TAU, 20, color, 2.5)
			ci.draw_circle(c, r * 0.2, color)
			for i in 4:
				var a := TAU * float(i) / 4.0
				ci.draw_line(c + Vector2(cos(a), sin(a)) * r * 0.55, c + Vector2(cos(a), sin(a)) * r, color, 2.5)
		"chevron_up":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.7, r * 0.3), c + Vector2(0, -r * 0.4), c + Vector2(r * 0.7, r * 0.3)]), color, 3.0)
		"chevron_down":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-r * 0.7, -r * 0.3), c + Vector2(0, r * 0.4), c + Vector2(r * 0.7, -r * 0.3)]), color, 3.0)
		"skull":
			ci.draw_circle(c + Vector2(0, -r * 0.1), r * 0.75, color)
			ci.draw_rect(Rect2(c.x - r * 0.4, c.y + r * 0.4, r * 0.8, r * 0.5), color)
			ci.draw_circle(c + Vector2(-r * 0.3, -r * 0.1), r * 0.2, Color(0, 0, 0, 0.7))
			ci.draw_circle(c + Vector2(r * 0.3, -r * 0.1), r * 0.2, Color(0, 0, 0, 0.7))
		_:
			ci.draw_circle(c, r * 0.6, color)


static func element_glyph(element_id: String) -> String:
	if element_id == "ultimate":
		return "ultimate"
	return element_id
