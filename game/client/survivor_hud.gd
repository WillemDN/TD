extends Control
## Interface of the mode "survivor": gold, time, tower life, the shop with its five cards, your gear and an info sheet.
## It emits signals; survivor_game.gd decides what happens. Cards: tap = select and read, the Buy button (or a second tap) buys.

signal buy_pressed(index)
signal reroll_pressed
signal clear_pressed
signal menu_pressed
signal speed_pressed
signal pause_pressed

const RARITY_COLORS := [Color("b8c4d4"), Color("6fdc8c"), Color("5aa8ff"), Color("c77dff")]
const RARITY_HEX := ["b8c4d4", "6fdc8c", "5aa8ff", "c77dff"]
const KIND_GLYPH := {"projectile": "target", "orbit": "tech", "aura": "shadow", "artillery": "fire", "chain": "electric",
		"mine": "stone", "glaive": "crystal", "strike": "electric"}

var data
var i18n
var sim

var _gold: Label
var _income: Label
var _time: Label
var _round: Label
var _progress
var _hp_bar
var _hp_text: Label
var _speed_btn
var _pause_btn
var _toast: Label
var _toast_ttl := 0.0
var _tray: PanelContainer
var _cards: HBoxContainer
var _owned: HBoxContainer
var _reroll_btn
var _clear_btn
var _sheet: PanelContainer
var _sheet_text: RichTextLabel
var _sheet_buy
var _card_buttons: Array = []
var _sig := ""
var _selected := -1                    # selected shop card
var _info := {}                        # gear chip shown in the sheet: {kind, id}
var _next_shop: Label
var _head: HBoxContainer               # row above the cards: next shop timer and your gear (hidden on small screens)
var _fabs: HBoxContainer               # round buttons top right
var _side: VBoxContainer               # reroll and clear next to the cards (moved to the top on small screens)
var _gear_btn
var _gear_panel: PanelContainer
var _gear_flow: HFlowContainer
var _compact := false


## A thin filled bar (tower life, progress through the game).
class Bar extends Control:
	var value := 1.0
	var fill := Color("e05a5a")
	var over := 0.0                    # a second, lighter bar on top (the shield)
	var over_color := Color("8fd8ff")

	func _init(min_size := Vector2(120, 14)) -> void:
		custom_minimum_size = min_size
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55), true)
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * clampf(value, 0.0, 1.0), size.y)), fill, true)
		if over > 0.0:
			draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * clampf(over, 0.0, 1.0), size.y * 0.35)), over_color, true)
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.25), false, 1.0)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func setup(p_data, p_i18n) -> void:
	data = p_data
	i18n = p_i18n
	var th := Theme.new()
	th.default_font_size = 15
	theme = th
	_build_top()
	_build_sheet()
	_build_tray()
	_toast = Label.new()
	_toast.add_theme_font_size_override("font_size", 22)
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 6)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_top = 96
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)


func _pill() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.panel_style(0.82, 18))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	return p


func _label(size: int = 16, color := UiKit.TEXT) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _build_top() -> void:
	var res := _pill()
	res.position = Vector2(8, 6)
	add_child(res)
	var rrow := HBoxContainer.new()
	rrow.add_theme_constant_override("separation", 6)
	res.add_child(rrow)
	rrow.add_child(UiKit.GlyphRect.new("coin", Color.WHITE, 22))
	_gold = _label(20, UiKit.GOLD)
	rrow.add_child(_gold)
	_income = _label(13, UiKit.MUTED)
	rrow.add_child(_income)

	var mid := _pill()
	mid.anchor_left = 0.5
	mid.anchor_right = 0.5
	mid.offset_left = 0
	mid.offset_right = 0
	mid.offset_top = 6
	mid.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(mid)
	var mcol := VBoxContainer.new()
	mcol.add_theme_constant_override("separation", 2)
	mid.add_child(mcol)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	mcol.add_child(line)
	_time = _label(18, UiKit.ACCENT)
	line.add_child(_time)
	_round = _label(14, UiKit.MUTED)
	line.add_child(_round)
	_progress = Bar.new(Vector2(190, 6))
	_progress.fill = UiKit.ACCENT
	mcol.add_child(_progress)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	right.offset_top = 6
	right.offset_right = -8
	add_child(right)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	top_row.alignment = BoxContainer.ALIGNMENT_END
	right.add_child(top_row)
	var hp := _pill()
	var hrow := HBoxContainer.new()
	hrow.add_theme_constant_override("separation", 6)
	hp.add_child(hrow)
	hrow.add_child(UiKit.GlyphRect.new("heart", Color.WHITE, 20))
	_hp_bar = Bar.new(Vector2(104, 16))
	hrow.add_child(_hp_bar)
	_hp_text = _label(14, Color("ff9a9a"))
	hrow.add_child(_hp_text)
	top_row.add_child(hp)
	var gear = UiKit.RoundButton.new("menu", UiKit.ACCENT, 44)
	gear.pressed.connect(func(): menu_pressed.emit())
	top_row.add_child(gear)
	_fabs = HBoxContainer.new()
	_fabs.add_theme_constant_override("separation", 6)
	_fabs.alignment = BoxContainer.ALIGNMENT_END
	right.add_child(_fabs)
	_gear_btn = UiKit.RoundButton.new("tech", UiKit.ACCENT, 44)
	_gear_btn.pressed.connect(func():
		_gear_panel.visible = not _gear_panel.visible)
	_gear_btn.visible = false
	_fabs.add_child(_gear_btn)
	_pause_btn = UiKit.RoundButton.new("pause", UiKit.ACCENT, 44)
	_pause_btn.pressed.connect(func(): pause_pressed.emit())
	_fabs.add_child(_pause_btn)
	_speed_btn = UiKit.RoundButton.new("ff", UiKit.GOOD, 44)
	_speed_btn.pressed.connect(func(): speed_pressed.emit())
	_fabs.add_child(_speed_btn)


func _build_sheet() -> void:
	_sheet = PanelContainer.new()
	_sheet.add_theme_stylebox_override("panel", UiKit.panel_style(0.92, 14))
	_sheet.position = Vector2(8, 54)
	_sheet.custom_minimum_size = Vector2(250, 0)
	_sheet.visible = false
	add_child(_sheet)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	_sheet.add_child(col)
	_sheet_text = RichTextLabel.new()
	_sheet_text.bbcode_enabled = true
	_sheet_text.fit_content = true
	_sheet_text.scroll_active = false
	_sheet_text.custom_minimum_size = Vector2(232, 0)
	_sheet_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet_text.add_theme_font_size_override("normal_font_size", 13)
	_sheet_text.add_theme_font_size_override("bold_font_size", 16)
	col.add_child(_sheet_text)
	_sheet_buy = UiKit.GlyphButton.new("coin", "", UiKit.GOOD, Vector2(0, 50))
	_sheet_buy.add_theme_font_size_override("font_size", 15)
	_sheet_buy.pressed.connect(func():
		if _selected >= 0:
			buy_pressed.emit(_selected))
	col.add_child(_sheet_buy)


func _build_tray() -> void:
	_tray = PanelContainer.new()
	_tray.add_theme_stylebox_override("panel", UiKit.panel_style(0.9, 16))
	_tray.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_tray.offset_left = 8
	_tray.offset_right = -8
	_tray.offset_bottom = -6
	_tray.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_tray)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	_tray.add_child(col)
	_head = HBoxContainer.new()
	_head.add_theme_constant_override("separation", 8)
	col.add_child(_head)
	var head := _head
	_next_shop = _label(12, UiKit.MUTED)
	head.add_child(_next_shop)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 38)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(scroll)
	_owned = HBoxContainer.new()
	_owned.add_theme_constant_override("separation", 4)
	scroll.add_child(_owned)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	col.add_child(row)
	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 6)
	_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_cards)
	_side = VBoxContainer.new()
	_side.add_theme_constant_override("separation", 6)
	row.add_child(_side)
	_reroll_btn = UiKit.GlyphButton.new("move", "", UiKit.ACCENT, Vector2(132, 40))
	_reroll_btn.add_theme_font_size_override("font_size", 13)
	_reroll_btn.pressed.connect(func(): reroll_pressed.emit())
	_side.add_child(_reroll_btn)
	_clear_btn = UiKit.GlyphButton.new("cross", "", UiKit.BAD, Vector2(132, 40))
	_clear_btn.add_theme_font_size_override("font_size", 13)
	_clear_btn.pressed.connect(func(): clear_pressed.emit())
	_side.add_child(_clear_btn)
	# your gear as a floating panel (small screens)
	_gear_panel = PanelContainer.new()
	_gear_panel.add_theme_stylebox_override("panel", UiKit.panel_style(0.92, 14))
	_gear_panel.position = Vector2(8, 50)
	_gear_panel.custom_minimum_size = Vector2(230, 0)
	_gear_panel.visible = false
	add_child(_gear_panel)
	_gear_flow = HFlowContainer.new()
	_gear_flow.add_theme_constant_override("h_separation", 4)
	_gear_flow.add_theme_constant_override("v_separation", 4)
	_gear_flow.custom_minimum_size = Vector2(212, 0)
	_gear_panel.add_child(_gear_flow)


# ------------------------------------------------------------------ state

## Small screens (a phone in landscape is about 440 logical pixels high): a slimmer shop, buttons on top, gear in a popup.
func apply_layout() -> void:
	var small := get_viewport_rect().size.y < 480.0
	if small == _compact and _tray.size.y > 0.0:
		return
	_compact = small
	_head.visible = not small
	_gear_btn.visible = small
	if not small:
		_gear_panel.visible = false
	var target: Control = _fabs if small else _side
	for b in [_reroll_btn, _clear_btn]:
		if b.get_parent() != target:
			b.reparent(target)
		b.custom_minimum_size = Vector2(44, 44) if small else Vector2(132, 40)
	if small:
		_fabs.move_child(_gear_btn, 0)
	_sig = ""


func get_insets() -> Vector2:
	return Vector2(54.0, _tray.size.y + 12.0)


func covers_point(p: Vector2) -> bool:
	for c in [_tray, _sheet, _gear_panel]:
		if c.visible and Rect2(c.global_position, c.size).has_point(p):
			return true
	return false


func toast(text: String, color := Color.WHITE, seconds := 2.2) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	_toast.modulate.a = 1.0
	_toast_ttl = seconds


func tick(delta: float) -> void:
	if _toast_ttl > 0.0:
		_toast_ttl -= delta
		_toast.modulate.a = clampf(_toast_ttl / 0.6, 0.0, 1.0)
	elif _toast.text != "":
		_toast.text = ""


func select_card(index: int) -> void:
	if index == _selected:
		buy_pressed.emit(index)        # a second tap on the same card buys it
		return
	_selected = index
	_info = {}
	_sig = ""


func clear_selection() -> void:
	_selected = -1
	_info = {}
	_sig = ""


func _mmss(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]


func update_state(p_sim, ctx: Dictionary) -> void:
	sim = p_sim
	_gold.text = str(sim.gold)
	_income.text = "+%s/s" % str(snappedf(sim.gold_per_second(), 0.1))
	_time.text = i18n.t("sv.time", [_mmss(sim.time), _mmss(float(sim.rules.winTime))])
	_round.text = i18n.t("sv.round", [sim.round_no])
	_progress.value = sim.time / float(sim.rules.winTime)
	_progress.queue_redraw()
	_hp_bar.value = sim.tower_hp / maxf(sim.tower_max, 1.0)
	_hp_bar.over = sim.shield / maxf(sim.tower_max, 1.0)
	_hp_bar.fill = Color("e05a5a") if _hp_bar.value > 0.3 else Color("ff2a2a")
	_hp_bar.queue_redraw()
	_hp_text.text = "%d" % int(ceil(sim.tower_hp))
	_speed_btn.glyph = "ff" if ctx.speed == 1 else "ff2"
	_speed_btn.tint = UiKit.GOOD if ctx.speed == 1 else UiKit.GOLD
	_speed_btn.queue_redraw()
	_pause_btn.glyph = "play" if ctx.paused else "pause"
	_pause_btn.queue_redraw()
	apply_layout()
	_next_shop.text = i18n.t("sv.next_shop", [int(ceil(sim.round_time_left()))])
	if _compact:
		_round.text = "%s · %ds" % [i18n.t("sv.round", [sim.round_no]), int(ceil(sim.round_time_left()))]
		_reroll_btn.text = ""
		_reroll_btn.badge = str(sim.reroll_cost())
		_clear_btn.text = ""
		_clear_btn.badge = "%d" % int(ceil(sim.clear_cd)) if sim.clear_cd > 0.0 else "!"
	else:
		_reroll_btn.text = " " + i18n.t("sv.reroll", [sim.reroll_cost()])
		_reroll_btn.badge = ""
		_clear_btn.text = " %d s" % int(ceil(sim.clear_cd)) if sim.clear_cd > 0.0 else " " + i18n.t("sv.clear_ready")
		_clear_btn.badge = ""
	_reroll_btn.queue_redraw()
	_clear_btn.queue_redraw()
	_reroll_btn.modulate = Color(1, 1, 1, 1) if sim.gold >= sim.reroll_cost() else Color(1, 1, 1, 0.55)
	_clear_btn.modulate = Color(1, 1, 1, 0.55) if sim.clear_cd > 0.0 else Color(1, 1, 1, 1)
	_rebuild(sim)
	for i in _card_buttons.size():
		var o: Dictionary = sim.offers[i]
		var b = _card_buttons[i]
		b.modulate = Color(1, 1, 1, 0.4) if o.bought else (Color(1, 1, 1, 1) if sim.gold >= sim.offer_cost(o) else Color(1, 1, 1, 0.62))
	_update_sheet(sim)
	if sim.state != "running":
		_sheet.visible = false


func _rebuild(sim) -> void:
	# only what the buttons show: sim.weapons also holds cooldowns and angles that change every tick, which would rebuild
	# the cards every frame and swallow every tap (a button that is replaced between press and release never fires)
	var levels := {}
	for id in sim.weapons:
		levels[id] = int(sim.weapons[id].level)
	var sig := "%s|%s|%s|%s|%s|%s|%s" % [sim.offers, levels, sim.upgrades, _selected, i18n.lang, _info, sim.round_no]
	if sig == _sig:
		return
	_sig = sig
	for c in _cards.get_children():
		c.queue_free()
	_card_buttons.clear()
	for i in sim.offers.size():
		var o: Dictionary = sim.offers[i]
		var def: Dictionary = data.weapons[o.id] if o.kind == "weapon" else data.upgrades[o.id]
		var rar: int = int(def.rarity)
		var b = UiKit.GlyphButton.new(_glyph_of(o.kind, def), "", RARITY_COLORS[rar], Vector2(0, 58 if _compact else 84))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.top_icon = true
		b.glyph_size = 20 if _compact else 26
		b.add_theme_font_size_override("font_size", 11 if _compact else 12)
		var level := 0
		if o.kind == "weapon":
			level = int(sim.weapons.get(o.id, {}).get("level", 0))
		else:
			level = int(sim.upgrades.get(o.id, 0))
		b.text = "%s\n%s" % [i18n.n(def.name), i18n.t("sv.sold_out") if o.bought else "%dg" % sim.offer_cost(o)]
		if level > 0:
			b.badge = "+%d" % level
		b.tooltip_text = i18n.n(def.name)
		b.set_selected(i == _selected)
		var idx: int = i
		b.pressed.connect(func(): select_card(idx))
		_cards.add_child(b)
		_card_buttons.append(b)
	for c in _owned.get_children():
		c.queue_free()
	for c in _gear_flow.get_children():
		c.queue_free()
	var target: Control = _gear_flow if _compact else _owned
	for id in sim.weapons.keys():
		target.add_child(_chip("weapon", id, int(sim.weapons[id].level)))
	for id in sim.upgrades.keys():
		target.add_child(_chip("upgrade", id, int(sim.upgrades[id])))


func _chip(kind: String, id: String, level: int):
	var def: Dictionary = data.weapons[id] if kind == "weapon" else data.upgrades[id]
	var b = UiKit.GlyphButton.new(_glyph_of(kind, def), "", RARITY_COLORS[int(def.rarity)], Vector2(46, 34))
	b.glyph_size = 18
	b.badge = str(level)
	b.set_selected(_info.get("id", "") == id and _info.get("kind", "") == kind)
	b.pressed.connect(func():
		_selected = -1
		_info = {"kind": kind, "id": id}
		_sig = "")
	return b


func _glyph_of(kind: String, def: Dictionary) -> String:
	if kind == "weapon":
		return KIND_GLYPH.get(def.kind, "target")
	var st: Dictionary = def.stat
	if st.has("phoenix") or st.has("ankh"):
		return "heart"
	if st.has("income") or st.has("bounty") or st.has("roundGold"):
		return "coin"
	if st.has("armor") or st.has("maxHp") or st.has("block") or st.has("shield") or st.has("thorns") or st.has("regen"):
		return "shield"
	return "ultimate"


# ------------------------------------------------------------------ info sheet

func _update_sheet(sim) -> void:
	var show := false
	var text := ""
	var buy_text := ""
	if _selected >= 0 and _selected < sim.offers.size():
		var o: Dictionary = sim.offers[_selected]
		text = info_text(sim, o.kind, o.id)
		show = true
		buy_text = i18n.t("sv.sold_out") if o.bought else i18n.t("msg.sv_buy", [sim.offer_cost(o)])
		_sheet_buy.visible = not o.bought
		_sheet_buy.text = " " + buy_text
		_sheet_buy.modulate = Color(1, 1, 1, 1) if sim.gold >= sim.offer_cost(o) else Color(1, 1, 1, 0.6)
	elif not _info.is_empty():
		text = info_text(sim, _info.kind, _info.id)
		show = true
		_sheet_buy.visible = false
	_sheet.visible = show
	if show:
		_sheet_text.text = text


func _fmt(v: float) -> String:
	return str(snappedf(v, 0.1)).rstrip("0").rstrip(".") if v != floor(v) else str(int(v))


## BBCode for a weapon or upgrade: name, rarity, what it does and the numbers (with your upgrades and level included).
func info_text(sim, kind: String, id: String) -> String:
	var def: Dictionary = data.weapons[id] if kind == "weapon" else data.upgrades[id]
	var rar: int = int(def.rarity)
	var s := "[b][color=#%s]%s[/color][/b]\n%s\n" % [RARITY_HEX[rar], i18n.n(def.name), i18n.t("rarity." + String(data.rarities[rar]))]
	if kind == "upgrade":
		s += i18n.n(def.desc) + "\n"
		var lvl: int = int(sim.upgrades.get(id, 0))
		s += i18n.t("sv.level", [lvl]) + " / " + str(int(def.max)) if lvl > 0 else i18n.t("sv.max") + ": " + str(int(def.max))
		return s
	var level := int(sim.weapons.get(id, {}).get("level", 1))
	var owned: bool = sim.weapons.has(id)
	var lvl_mult: float = 1.0 + float(sim.rules.weaponLevelDamage) * float(level - 1)
	var dmg: float = float(def.damage) * lvl_mult * float(sim.stat.dmg)
	var interval: float = float(def.cooldown) * pow(float(sim.rules.weaponLevelSpeed), float(level - 1)) / float(sim.stat.aspd)
	var n_extra: int = (level - 1) / 2
	match def.kind:
		"projectile":
			var pierce: int = int(def.pierce) + n_extra
			s += (i18n.t("wk.projectile", [pierce]) if pierce > 0 else i18n.t("wk.shoot")) + "\n"
		"orbit":
			s += i18n.t("wk.orbit", [int(def.blades) + n_extra]) + "\n"
		"aura":
			s += i18n.t("wk.aura", [_fmt(float(def.range) * float(sim.stat.range))]) + "\n"
		"artillery":
			s += i18n.t("wk.artillery", [_fmt(float(def.range) * float(sim.stat.range))]) + "\n"
		"chain":
			s += i18n.t("wk.chain", [int(def.bounces) + n_extra + 1]) + "\n"
		"mine":
			s += i18n.t("wk.mine", [int(def.maxMines) + n_extra]) + "\n"
		"glaive":
			s += i18n.t("wk.glaive") + "\n"
		"strike":
			s += i18n.t("wk.strike", [int(def.count) + n_extra]) + "\n"
	s += i18n.t("sv.dmg", [_fmt(dmg)]) + " · " + i18n.t("sv.cd", [_fmt(interval)]) + " · " + i18n.t("sv.rng", [_fmt(float(def.range) * float(sim.stat.range))]) + "\n"
	s += i18n.t("wk.phys" if def.dtype == "phys" else "wk.magic") + "\n"
	if float(def.get("slow", 0.0)) > 0.0:
		s += i18n.t("wk.slow", [int(round(float(def.slow) * 100.0))]) + "\n"
	if def.has("poison"):
		s += i18n.t("wk.poison", [_fmt(float(def.poison) * lvl_mult * float(sim.stat.dmg))]) + "\n"
	if def.has("burn"):
		s += i18n.t("wk.burn", [_fmt(float(def.burn) * lvl_mult * float(sim.stat.dmg))]) + "\n"
	if float(def.get("heal", 0.0)) > 0.0:
		s += i18n.t("wk.heal", [_fmt(float(def.heal))]) + "\n"
	if owned:
		s += i18n.t("sv.level", [level]) + (" (" + i18n.t("sv.max") + ")" if level >= int(sim.rules.maxWeaponLevel) else "")
	return s
