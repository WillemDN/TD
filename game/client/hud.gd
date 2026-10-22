extends Control
## All 2D interface: top bar, build bar, info panel, toasts, menu and end screen. It emits signals; main.gd decides.

signal tower_chosen(id)
signal element_chosen(id)
signal unlock_pressed(id)
signal sell_pressed
signal skip_pressed
signal speed_pressed
signal pause_pressed
signal menu_pressed
signal lang_pressed
signal confirm_pressed
signal cancel_pressed
signal play_pressed(difficulty)
signal again_pressed
signal fit_pressed

const DIFFS := ["easy", "normal", "hard", "perfection"]

var data
var i18n
var difficulty := "normal"

var _gold: Label
var _lumber: Label
var _lives: Label
var _level: Label
var _timer: Label
var _banner: Label
var _toast: Label
var _toast_ttl := 0.0
var _speed_btn: Button
var _pause_btn: Button
var _skip_btn: Button
var _top_buttons: Array = []
var _elem_row: HBoxContainer
var _tower_row: HBoxContainer
var _hint: Label
var _tower_buttons := {}
var _info_panel: PanelContainer
var _info_text: RichTextLabel
var _sell_btn: Button
var _confirm_bar: HBoxContainer
var _confirm_btn: Button
var _cancel_btn: Button
var _menu: Control
var _menu_diff_buttons := {}
var _menu_texts := {}
var _end: Control
var _end_title: Label
var _end_stats: Label
var _bar_sig := ""
var _tip: Label
var _top_panel: PanelContainer
var _bottom_panel: PanelContainer


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func setup(p_data, p_i18n) -> void:
	data = p_data
	i18n = p_i18n
	var th := Theme.new()
	th.default_font_size = 20
	theme = th
	_build_top()
	_build_bottom()
	_build_info()
	_build_menu()
	_build_end()
	_toast = Label.new()
	_toast.add_theme_font_size_override("font_size", 26)
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 6)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_top = 150
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)
	refresh_static_texts()


# ------------------------------------------------------------------ construction helpers

func _panel_style(alpha: float = 0.82) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.11, 0.18, alpha)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


func _button(text: String, min_size := Vector2(0, 48), accent := Color("3b6ea5")) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		var base := Color(0.13, 0.2, 0.31)
		if state == "hover":
			base = base.lightened(0.12)
		elif state == "pressed":
			base = accent
		sb.bg_color = base
		sb.set_corner_radius_all(8)
		sb.border_width_bottom = 5
		sb.border_color = accent
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		b.add_theme_stylebox_override(state, sb)
	return b


func _label(size: int = 22, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	return l


func _build_top() -> void:
	var panel := PanelContainer.new()
	_top_panel = panel
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 8
	panel.offset_right = -8
	panel.offset_top = 6
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	_gold = _label(22, Color("ffd45e"))
	_lumber = _label(22, Color("b98a55"))
	_lives = _label(22, Color("ff7a7a"))
	_level = _label(22, Color("9fd6ff"))
	_timer = _label(20, Color("dce8f5"))
	_timer.clip_text = true
	_timer.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_timer.custom_minimum_size = Vector2(60, 0)
	for l in [_gold, _lumber, _lives, _level]:
		row.add_child(l)
	_timer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_timer)
	_skip_btn = _button("", Vector2(0, 40), Color("3fa05a"))
	_skip_btn.pressed.connect(func(): skip_pressed.emit())
	_speed_btn = _button("", Vector2(0, 40))
	_speed_btn.pressed.connect(func(): speed_pressed.emit())
	_pause_btn = _button("", Vector2(0, 40))
	_pause_btn.pressed.connect(func(): pause_pressed.emit())
	var lang_btn := _button("NL/EN", Vector2(0, 40))
	lang_btn.pressed.connect(func(): lang_pressed.emit())
	var menu_btn := _button("", Vector2(0, 40))
	menu_btn.pressed.connect(func(): menu_pressed.emit())
	_top_buttons = [_skip_btn, _speed_btn, _pause_btn, lang_btn, menu_btn]
	for b in _top_buttons:
		row.add_child(b)
	_banner = _label(20, Color("e8f2ff"))
	_banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_banner.offset_top = 62
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)


func _build_bottom() -> void:
	var panel := PanelContainer.new()
	_bottom_panel = panel
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 8
	panel.offset_right = -8
	panel.offset_bottom = -6
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	_hint = _label(16, Color("c9d8ea"))
	col.add_child(_hint)
	_elem_row = HBoxContainer.new()
	_elem_row.add_theme_constant_override("separation", 6)
	col.add_child(_elem_row)
	_tower_row = HBoxContainer.new()
	_tower_row.add_theme_constant_override("separation", 6)
	col.add_child(_tower_row)
	_confirm_bar = HBoxContainer.new()
	_confirm_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_confirm_bar.offset_left = -176
	_confirm_bar.offset_right = 176
	_confirm_bar.offset_top = -210
	_confirm_bar.offset_bottom = -150
	_confirm_bar.add_theme_constant_override("separation", 12)
	_confirm_btn = _button("", Vector2(200, 60), Color("3fa05a"))
	_confirm_btn.pressed.connect(func(): confirm_pressed.emit())
	_cancel_btn = _button("", Vector2(140, 60), Color("b04a4a"))
	_cancel_btn.pressed.connect(func(): cancel_pressed.emit())
	_confirm_bar.add_child(_confirm_btn)
	_confirm_bar.add_child(_cancel_btn)
	_confirm_bar.visible = false
	add_child(_confirm_bar)


func _build_info() -> void:
	_info_panel = PanelContainer.new()
	_info_panel.add_theme_stylebox_override("panel", _panel_style(0.9))
	_info_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_info_panel.offset_left = 8
	_info_panel.offset_right = 288
	_info_panel.offset_top = 96
	_info_panel.offset_bottom = 96
	_info_panel.custom_minimum_size = Vector2(280, 0)
	_info_panel.visible = false
	add_child(_info_panel)
	var col := VBoxContainer.new()
	_info_panel.add_child(col)
	_info_text = RichTextLabel.new()
	_info_text.bbcode_enabled = true
	_info_text.fit_content = true
	_info_text.scroll_active = false
	_info_text.custom_minimum_size = Vector2(260, 0)
	_info_text.add_theme_font_size_override("normal_font_size", 16)
	_info_text.add_theme_font_size_override("bold_font_size", 18)
	col.add_child(_info_text)
	_sell_btn = _button("", Vector2(0, 42), Color("b08a3a"))
	_sell_btn.pressed.connect(func(): sell_pressed.emit())
	col.add_child(_sell_btn)


func _build_menu() -> void:
	_menu = Control.new()
	_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.06, 0.1, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(0.97))
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(520, 0)
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var title := _label(54, Color("9fd6ff"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	_menu_texts["title"] = title
	var tag := _label(22, Color("dce8f5"))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(tag)
	_menu_texts["tagline"] = tag
	var mode := _label(20, Color("ffd45e"))
	mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(mode)
	_menu_texts["mode"] = mode
	var dl := _label(20)
	col.add_child(dl)
	_menu_texts["difficulty"] = dl
	for d in DIFFS:
		var b := _button("", Vector2(0, 46))
		b.pressed.connect(func():
			difficulty = d
			_refresh_menu())
		col.add_child(b)
		_menu_diff_buttons[d] = b
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)
	var play := _button("", Vector2(0, 64), Color("3fa05a"))
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play.pressed.connect(func(): play_pressed.emit(difficulty))
	row.add_child(play)
	_menu_texts["play"] = play
	var lang := _button("NL / EN", Vector2(120, 64))
	lang.pressed.connect(func(): lang_pressed.emit())
	row.add_child(lang)
	var hint := _label(16, Color("9bb0c8"))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(hint)
	_menu_texts["hint"] = hint
	var controls := _label(16, Color("9bb0c8"))
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(controls)
	_menu_texts["controls"] = controls
	add_child(_menu)


func _build_end() -> void:
	_end = Control.new()
	_end.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end.visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.06, 0.1, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(0.97))
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(440, 0)
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)
	_end_title = _label(50, Color("ffd45e"))
	_end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_end_title)
	_end_stats = _label(22)
	_end_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_end_stats)
	var again := _button("", Vector2(0, 60), Color("3fa05a"))
	again.pressed.connect(func(): again_pressed.emit())
	col.add_child(again)
	_menu_texts["again"] = again
	add_child(_end)


# ------------------------------------------------------------------ texts and state

## Space taken by the top and bottom bars in logical pixels (x = top, y = bottom), for framing the camera.
func get_insets() -> Vector2:
	return Vector2(_top_panel.size.y + 14.0, _bottom_panel.size.y + 14.0)


func refresh_static_texts() -> void:
	_menu_texts.title.text = i18n.t("app.title")
	_menu_texts.tagline.text = i18n.t("app.tagline")
	_menu_texts.mode.text = i18n.t("menu.mode")
	_menu_texts.difficulty.text = i18n.t("menu.difficulty")
	_menu_texts.play.text = i18n.t("menu.play")
	_menu_texts.hint.text = i18n.t("menu.hint") + "\n" + i18n.t("help.tip")
	_menu_texts.controls.text = i18n.t("help.controls")
	_menu_texts.again.text = i18n.t("end.again")
	_skip_btn.text = i18n.t("hud.skip")
	_top_buttons[4].text = i18n.t("hud.menu")
	_confirm_btn.text = i18n.t("hud.confirm")
	_cancel_btn.text = i18n.t("hud.cancel")
	_refresh_menu()
	_bar_sig = ""


func _refresh_menu() -> void:
	for d in DIFFS:
		var b: Button = _menu_diff_buttons[d]
		b.text = ("● " if d == difficulty else "○ ") + i18n.t("diff." + d)


func set_menu_visible(v: bool) -> void:
	_menu.visible = v
	_end.visible = false


func show_end(won: bool, reason: String, stats_text: String) -> void:
	_end_title.text = i18n.t("end.won") if won else i18n.t("end.lost")
	_end_title.add_theme_color_override("font_color", Color("ffd45e") if won else Color("ff7a7a"))
	var why = "" if won else i18n.t("end.lost_boss" if reason == "boss" else "end.lost_lives") + "\n"
	_end_stats.text = why + stats_text
	_end.visible = true


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


## ctx: build_id, active_element, selected_id (tower id or 0), speed, paused, touch_mode, ghost_valid, info_bbcode,
## sell_text, wave_text, banner, path_text
func update_state(sim, ctx: Dictionary) -> void:
	_gold.text = "%s %d" % [i18n.t("hud.gold"), sim.gold]
	_lumber.text = "%s %d" % [i18n.t("hud.lumber"), sim.lumber]
	_lives.text = "%s %d/%d" % [i18n.t("hud.lives"), sim.lives, sim.max_lives]
	_level.text = i18n.t("hud.wave", [sim.level, int(sim.data.rules.lastLevel)])
	_timer.text = ctx.wave_text
	_banner.text = ctx.banner
	_speed_btn.text = i18n.t("hud.speed", [ctx.speed])
	_pause_btn.text = i18n.t("hud.resume") if ctx.paused else i18n.t("hud.pause")
	_skip_btn.visible = sim.state == "countdown"
	_rebuild_bars(sim, ctx)
	for id in _tower_buttons:
		var def: Dictionary = data.towers[id]
		var affordable: bool = sim.gold >= int(def.cost.gold) and sim.lumber >= int(def.cost.lumber)
		var b: Button = _tower_buttons[id]
		b.modulate = Color(1, 1, 1, 1) if affordable else Color(1, 1, 1, 0.5)
		b.button_pressed = ctx.build_id == id
	_info_panel.visible = ctx.info_bbcode != ""
	if _info_panel.visible:
		_info_text.text = ctx.info_bbcode
	_sell_btn.visible = ctx.sell_text != ""
	_sell_btn.text = ctx.sell_text
	_confirm_bar.visible = ctx.touch_mode and ctx.build_id != "" and ctx.ghost_valid
	_hint.text = ctx.hint
	_hint.visible = ctx.hint != ""


func _rebuild_bars(sim, ctx: Dictionary) -> void:
	var sig := "%s|%s|%s|%s|%s" % [sim.elements, ctx.active_element, sim.lumber > 0, i18n.lang, ctx.build_id != ""]
	if sig == _bar_sig:
		return
	_bar_sig = sig
	for c in _elem_row.get_children():
		c.queue_free()
	for c in _tower_row.get_children():
		c.queue_free()
	_tower_buttons.clear()
	if sim.elements.is_empty():
		for e in data.elements:
			var b := _button(i18n.n(e.name), Vector2(96, 46), Color(e.color))
			b.pressed.connect(func(): unlock_pressed.emit(e.id))
			_elem_row.add_child(b)
		return
	for eid in sim.elements:
		var e: Dictionary = data.element_of(eid)
		var b := _button(i18n.n(e.name), Vector2(92, 38), Color(e.color))
		b.add_theme_font_size_override("font_size", 17)
		b.toggle_mode = true
		b.button_pressed = eid == ctx.active_element
		b.pressed.connect(func(): element_chosen.emit(eid))
		_elem_row.add_child(b)
	if sim.lumber > 0:
		var more := _button(i18n.t("hud.unlock"), Vector2(0, 38), Color("b98a55"))
		more.add_theme_font_size_override("font_size", 17)
		more.pressed.connect(func(): element_chosen.emit("__unlock"))
		_elem_row.add_child(more)
	var ids: Array = []
	var accent := Color("bff6ff")
	if ctx.active_element == "__unlock":
		for e in data.elements:
			if e.id in sim.elements:
				continue
			var b := _button(i18n.n(e.name), Vector2(110, 56), Color(e.color))
			b.pressed.connect(func(): unlock_pressed.emit(e.id))
			_tower_row.add_child(b)
	elif ctx.active_element == "__ultimate":
		ids = [data.ultimate]
	else:
		var el: Dictionary = data.element_of(ctx.active_element)
		if not el.is_empty():
			ids = el.towers
			accent = Color(el.color)
	var ult := _button(i18n.t("hud.ultimate"), Vector2(92, 38), Color("bff6ff"))
	ult.add_theme_font_size_override("font_size", 17)
	ult.toggle_mode = true
	ult.button_pressed = ctx.active_element == "__ultimate"
	ult.pressed.connect(func(): element_chosen.emit("__ultimate"))
	_elem_row.add_child(ult)
	var keys := ["Q", "W", "E", "R", "T", "Y"]
	var i := 0
	for id in ids:
		var def: Dictionary = data.towers[id]
		var cost := "%dg" % int(def.cost.gold) + (" + %dh" % int(def.cost.lumber) if int(def.cost.lumber) > 0 else "")
		var b := _button("%s\n%s  [%s]" % [i18n.n(def.name), cost, keys[mini(i, 5)]], Vector2(138, 56), accent)
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 16)
		var tid: String = id
		b.pressed.connect(func(): tower_chosen.emit(tid))
		_tower_row.add_child(b)
		_tower_buttons[id] = b
		i += 1
