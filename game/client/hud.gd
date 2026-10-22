extends Control
## All 2D interface, designed for a phone held in landscape: a few floating glass pills at the edges, a minimap, a build
## tray with big cards and an action sheet for the selected tower. It emits signals; main.gd decides what happens.

const Minimap := preload("res://client/minimap.gd")
const GameData := preload("res://core/game_data.gd")

signal tower_chosen(id)
signal card_down(id)
signal element_chosen(id)
signal unlock_pressed(id)
signal sell_pressed
signal move_pressed
signal skip_pressed
signal speed_pressed
signal pause_pressed
signal menu_pressed
signal resume_pressed
signal restart_pressed
signal lang_pressed
signal confirm_pressed
signal cancel_pressed
signal play_pressed(mode, difficulty)
signal again_pressed
signal center_pressed
signal wall_toggled(on)
signal minimap_focus(tile)
signal tray_toggled(open)

const DIFFS := ["easy", "normal", "hard", "perfection"]
const MODES := ["classic", "elements"]
const GROUP_COLORS := {"dual": Color("ffd98a"), "triple": Color("ff9bd8")}
const ARMOR_COLORS := {"small": Color("8be36a"), "medium": Color("f2d94a"), "large": Color("f08a3a"), "fort": Color("7fa6d6"), "divine": Color("ffffff")}

var data
var i18n
var difficulty := "normal"
var mode := "classic"
var minimap
var tray_open := true

var _gold: Label
var _lumber: Label
var _lives: Label
var _level: Label
var _status: Label
var _creep_name: Label
var _armor_label: Label
var _armor_icon
var _kind_icon
var _boss_tag: Label
var _skip_btn
var _toast: Label
var _toast_ttl := 0.0
var _interest: Label
var _interest_ttl := 0.0
var _speed_btn
var _pause_btn
var _center_btn
var _elem_row: HBoxContainer
var _tower_row: HBoxContainer
var _hint: Label
var _tray: PanelContainer
var _tray_body: VBoxContainer
var _tray_toggle
var _tower_buttons := {}
var _sheet: PanelContainer
var _sheet_text: RichTextLabel
var _sheet_buttons: HBoxContainer
var _move_btn
var _sell_btn
var _wall_btn
var _confirm_bar: HBoxContainer
var _menu: Control
var _menu_scroll: ScrollContainer
var _menu_col: VBoxContainer
var _menu_footer: HBoxContainer
var _menu_diff := {}
var _menu_mode := {}
var _menu_texts := {}
var _pause_sheet: Control
var _pause_texts := {}
var _end: Control
var _end_title: Label
var _end_stats: Label
var _bar_sig := ""


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
	_build_minimap_column()
	_build_sheet()
	_build_tray()
	_build_confirm()
	_build_menu()
	_build_pause_sheet()
	_build_end()
	_toast = Label.new()
	_toast.add_theme_font_size_override("font_size", 22)
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 6)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_toast.offset_top = 92
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)
	_interest = _label(15, UiKit.GOLD)
	_interest.position = Vector2(16, 48)
	_interest.add_theme_color_override("font_outline_color", Color.BLACK)
	_interest.add_theme_constant_override("outline_size", 5)
	add_child(_interest)
	refresh_static_texts()


func attach_minimap(sim, world) -> void:
	minimap.setup(sim, world, data)


# ------------------------------------------------------------------ construction helpers

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
	# resources, top left
	var res := _pill()
	res.position = Vector2(8, 6)
	add_child(res)
	var rrow := HBoxContainer.new()
	rrow.add_theme_constant_override("separation", 6)
	res.add_child(rrow)
	rrow.add_child(UiKit.GlyphRect.new("coin", Color.WHITE, 22))
	_gold = _label(20, UiKit.GOLD)
	rrow.add_child(_gold)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(6, 0)
	rrow.add_child(gap)
	rrow.add_child(UiKit.GlyphRect.new("log", Color.WHITE, 22))
	_lumber = _label(20, Color("d9a566"))
	rrow.add_child(_lumber)

	# wave pill, top centre
	var wave := _pill()
	wave.anchor_left = 0.5
	wave.anchor_right = 0.5
	wave.offset_left = 0
	wave.offset_right = 0
	wave.offset_top = 6
	wave.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(wave)
	var wrow := HBoxContainer.new()
	wrow.add_theme_constant_override("separation", 10)
	wave.add_child(wrow)
	var wcol := VBoxContainer.new()
	wcol.add_theme_constant_override("separation", 0)
	wrow.add_child(wcol)
	var line1 := HBoxContainer.new()
	line1.add_theme_constant_override("separation", 10)
	wcol.add_child(line1)
	_level = _label(17, UiKit.ACCENT)
	line1.add_child(_level)
	_status = _label(15, UiKit.MUTED)
	line1.add_child(_status)
	var line2 := HBoxContainer.new()
	line2.add_theme_constant_override("separation", 5)
	wcol.add_child(line2)
	_kind_icon = UiKit.GlyphRect.new("ground", UiKit.TEXT, 16)
	line2.add_child(_kind_icon)
	_creep_name = _label(15)
	line2.add_child(_creep_name)
	_armor_icon = UiKit.GlyphRect.new("shield", Color.WHITE, 16)
	line2.add_child(_armor_icon)
	_armor_label = _label(14, UiKit.MUTED)
	line2.add_child(_armor_label)
	_boss_tag = _label(14, Color("ff8a5c"))
	line2.add_child(_boss_tag)
	_skip_btn = UiKit.GlyphButton.new("play", "", UiKit.GOOD, Vector2(50, 40))
	_skip_btn.glyph_size = 20
	_skip_btn.pressed.connect(func(): skip_pressed.emit())
	wrow.add_child(_skip_btn)

	# lives and menu, top right
	var right := HBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	right.offset_top = 6
	right.offset_right = -8
	add_child(right)
	var lives := _pill()
	var lrow := HBoxContainer.new()
	lrow.add_theme_constant_override("separation", 6)
	lives.add_child(lrow)
	lrow.add_child(UiKit.GlyphRect.new("heart", Color.WHITE, 20))
	_lives = _label(20, Color("ff8a8a"))
	lrow.add_child(_lives)
	right.add_child(lives)
	var gear = UiKit.RoundButton.new("menu", UiKit.ACCENT, 44)
	gear.pressed.connect(func(): menu_pressed.emit())
	right.add_child(gear)


func _build_minimap_column() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	col.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	col.offset_top = 58
	col.offset_right = -8
	add_child(col)
	var holder := PanelContainer.new()
	holder.add_theme_stylebox_override("panel", UiKit.panel_style(0.8, 10))
	col.add_child(holder)
	minimap = Minimap.new()
	minimap.focus_requested.connect(func(t): minimap_focus.emit(t))
	holder.add_child(minimap)
	var fabs := HBoxContainer.new()
	fabs.add_theme_constant_override("separation", 6)
	fabs.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(fabs)
	_center_btn = UiKit.RoundButton.new("target", UiKit.ACCENT, 44)
	_center_btn.pressed.connect(func(): center_pressed.emit())
	fabs.add_child(_center_btn)
	_pause_btn = UiKit.RoundButton.new("pause", UiKit.ACCENT, 44)
	_pause_btn.pressed.connect(func(): pause_pressed.emit())
	fabs.add_child(_pause_btn)
	_speed_btn = UiKit.RoundButton.new("ff", UiKit.GOOD, 44)
	_speed_btn.pressed.connect(func(): speed_pressed.emit())
	fabs.add_child(_speed_btn)


func _build_sheet() -> void:
	_sheet = PanelContainer.new()
	_sheet.add_theme_stylebox_override("panel", UiKit.panel_style(0.9, 14))
	_sheet.position = Vector2(8, 58)
	_sheet.custom_minimum_size = Vector2(256, 0)
	_sheet.visible = false
	add_child(_sheet)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	_sheet.add_child(col)
	_sheet_text = RichTextLabel.new()
	_sheet_text.bbcode_enabled = true
	_sheet_text.fit_content = true
	_sheet_text.scroll_active = false
	_sheet_text.custom_minimum_size = Vector2(238, 0)
	_sheet_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet_text.add_theme_font_size_override("normal_font_size", 13)
	_sheet_text.add_theme_font_size_override("bold_font_size", 16)
	col.add_child(_sheet_text)
	_sheet_buttons = HBoxContainer.new()
	_sheet_buttons.add_theme_constant_override("separation", 6)
	col.add_child(_sheet_buttons)
	_move_btn = UiKit.GlyphButton.new("move", "", UiKit.ACCENT, Vector2(0, 50))
	_move_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_move_btn.add_theme_font_size_override("font_size", 14)
	_move_btn.pressed.connect(func(): move_pressed.emit())
	_sheet_buttons.add_child(_move_btn)
	_sell_btn = UiKit.GlyphButton.new("sell", "", UiKit.GOLD, Vector2(0, 50))
	_sell_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sell_btn.add_theme_font_size_override("font_size", 14)
	_sell_btn.pressed.connect(func(): sell_pressed.emit())
	_sheet_buttons.add_child(_sell_btn)
	_wall_btn = UiKit.GlyphButton.new("wall", "", UiKit.ACCENT, Vector2(0, 46))
	_wall_btn.toggle_mode = true
	_wall_btn.toggled.connect(func(on): wall_toggled.emit(on))
	col.add_child(_wall_btn)


func _build_tray() -> void:
	_tray = PanelContainer.new()
	_tray.add_theme_stylebox_override("panel", UiKit.panel_style(0.88, 16))
	_tray.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_tray.offset_left = 8
	_tray.offset_right = -8
	_tray.offset_bottom = -6
	_tray.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_tray)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	_tray.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	col.add_child(head)
	_elem_row = HBoxContainer.new()
	_elem_row.add_theme_constant_override("separation", 5)
	_elem_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_elem_row)
	_hint = _label(13, UiKit.MUTED)
	head.add_child(_hint)
	_tray_toggle = UiKit.RoundButton.new("chevron_down", UiKit.ACCENT, 36)
	_tray_toggle.pressed.connect(func():
		tray_open = not tray_open
		tray_toggled.emit(tray_open))
	head.add_child(_tray_toggle)
	_tray_body = VBoxContainer.new()
	col.add_child(_tray_body)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 74)
	_tray_body.add_child(scroll)
	_tower_row = HBoxContainer.new()
	_tower_row.add_theme_constant_override("separation", 6)
	scroll.add_child(_tower_row)


func _build_confirm() -> void:
	_confirm_bar = HBoxContainer.new()
	_confirm_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_confirm_bar.offset_left = -80
	_confirm_bar.offset_right = 80
	_confirm_bar.offset_top = -200
	_confirm_bar.offset_bottom = -140
	_confirm_bar.add_theme_constant_override("separation", 14)
	_confirm_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_confirm_bar.visible = false
	add_child(_confirm_bar)
	var ok = UiKit.RoundButton.new("check", UiKit.GOOD, 60)
	ok.pressed.connect(func(): confirm_pressed.emit())
	_confirm_bar.add_child(ok)
	var no = UiKit.RoundButton.new("cross", UiKit.BAD, 60)
	no.pressed.connect(func(): cancel_pressed.emit())
	_confirm_bar.add_child(no)


func _centered_panel(parent: Control, dim: float, scrollable := false) -> VBoxContainer:
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.08, dim)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel_style(0.97, 20))
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(380, 0)
	col.add_theme_constant_override("separation", 8)
	if scrollable:
		# a small phone screen is shorter than the menu: the menu scrolls
		var outer := VBoxContainer.new()
		outer.add_theme_constant_override("separation", 8)
		panel.add_child(outer)
		_menu_scroll = ScrollContainer.new()
		_menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		outer.add_child(_menu_scroll)
		_menu_scroll.add_child(col)
		_menu_col = col
		_menu_footer = HBoxContainer.new()      # the play button stays in view while the rest scrolls
		_menu_footer.add_theme_constant_override("separation", 8)
		outer.add_child(_menu_footer)
	else:
		panel.add_child(col)
	return col


func fit_menu() -> void:
	if _menu_scroll == null:
		return
	var vh := get_viewport_rect().size.y
	var room := vh - 44.0 - _menu_footer.get_combined_minimum_size().y - 8.0
	_menu_scroll.custom_minimum_size.y = clampf(_menu_col.get_combined_minimum_size().y, 80.0, maxf(80.0, room))


func _build_menu() -> void:
	_menu = Control.new()
	_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var col := _centered_panel(_menu, 0.72, true)
	var title := _label(40, UiKit.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	_menu_texts["title"] = title
	var tag := _label(16, UiKit.TEXT)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(tag)
	_menu_texts["tagline"] = tag
	var ml := _label(14, UiKit.MUTED)
	col.add_child(ml)
	_menu_texts["choose_mode"] = ml
	var mrow := HBoxContainer.new()
	mrow.add_theme_constant_override("separation", 6)
	col.add_child(mrow)
	for m in MODES:
		var mb = UiKit.GlyphButton.new("", "", UiKit.ACCENT, Vector2(0, 56))
		mb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mb.add_theme_font_size_override("font_size", 18)
		mb.pressed.connect(func():
			mode = m
			_refresh_menu())
		mrow.add_child(mb)
		_menu_mode[m] = mb
	var mdesc := _label(13, UiKit.TEXT)
	mdesc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mdesc.custom_minimum_size = Vector2(0, 54)
	col.add_child(mdesc)
	_menu_texts["mode_desc"] = mdesc
	var dl := _label(14, UiKit.MUTED)
	col.add_child(dl)
	_menu_texts["difficulty"] = dl
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	col.add_child(grid)
	for d in DIFFS:
		var b = UiKit.GlyphButton.new("", "", UiKit.ACCENT, Vector2(0, 46))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func():
			difficulty = d
			_refresh_menu())
		grid.add_child(b)
		_menu_diff[d] = b
	var row := _menu_footer
	var play = UiKit.GlyphButton.new("play", "", UiKit.GOOD, Vector2(0, 58))
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play.pressed.connect(func(): play_pressed.emit(mode, difficulty))
	row.add_child(play)
	_menu_texts["play"] = play
	var lang = UiKit.GlyphButton.new("", "NL / EN", UiKit.ACCENT, Vector2(92, 58))
	lang.pressed.connect(func(): lang_pressed.emit())
	row.add_child(lang)
	var hint := _label(12, UiKit.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(hint)
	_menu_texts["hint"] = hint
	var controls := _label(12, UiKit.MUTED)
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(controls)
	_menu_texts["controls"] = controls
	var credits := _label(11, UiKit.MUTED)
	credits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(credits)
	_menu_texts["credits"] = credits
	add_child(_menu)


func _build_pause_sheet() -> void:
	_pause_sheet = Control.new()
	_pause_sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_sheet.visible = false
	var col := _centered_panel(_pause_sheet, 0.55)
	var title := _label(26, UiKit.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	_pause_texts["title"] = title
	var resume = UiKit.GlyphButton.new("play", "", UiKit.GOOD, Vector2(0, 54))
	resume.pressed.connect(func(): resume_pressed.emit())
	col.add_child(resume)
	_pause_texts["resume"] = resume
	var lang = UiKit.GlyphButton.new("", "NL / EN", UiKit.ACCENT, Vector2(0, 46))
	lang.pressed.connect(func(): lang_pressed.emit())
	col.add_child(lang)
	var restart = UiKit.GlyphButton.new("cross", "", UiKit.BAD, Vector2(0, 46))
	restart.pressed.connect(func(): restart_pressed.emit())
	col.add_child(restart)
	_pause_texts["restart"] = restart
	add_child(_pause_sheet)


func _build_end() -> void:
	_end = Control.new()
	_end.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end.visible = false
	var col := _centered_panel(_end, 0.65)
	_end_title = _label(40, UiKit.GOLD)
	_end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_end_title)
	_end_stats = _label(16)
	_end_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_end_stats)
	var again = UiKit.GlyphButton.new("play", "", UiKit.GOOD, Vector2(0, 58))
	again.pressed.connect(func(): again_pressed.emit())
	col.add_child(again)
	_menu_texts["again"] = again
	add_child(_end)


# ------------------------------------------------------------------ texts and state

func refresh_static_texts() -> void:
	_menu_texts.title.text = i18n.t("app.title")
	_menu_texts.tagline.text = i18n.t("app.tagline")
	_menu_texts.choose_mode.text = i18n.t("menu.choose_mode")
	_menu_texts.difficulty.text = i18n.t("menu.difficulty")
	_menu_texts.play.text = " " + i18n.t("menu.play")
	_menu_texts.hint.text = i18n.t("menu.hint." + mode) + "\n" + i18n.t("help.tip." + mode)
	_menu_texts.controls.text = i18n.t("help.controls")
	_menu_texts.credits.text = i18n.t("app.credits")
	_menu_texts.again.text = " " + i18n.t("end.again")
	_pause_texts.title.text = i18n.t("hud.pause")
	_pause_texts.resume.text = " " + i18n.t("hud.resume")
	_pause_texts.restart.text = " " + i18n.t("hud.restart")
	_wall_btn.text = " " + i18n.t("hud.wall")
	_refresh_menu()
	_bar_sig = ""
	call_deferred("fit_menu")


func _refresh_menu() -> void:
	call_deferred("fit_menu")
	for m in MODES:
		var mb = _menu_mode[m]
		mb.text = i18n.t("mode." + m)
		mb.set_selected(m == mode)
	_menu_texts.mode_desc.text = i18n.t("mode." + mode + ".desc")
	_menu_texts.hint.text = i18n.t("menu.hint." + mode) + "\n" + i18n.t("help.tip." + mode)
	var lives: Dictionary = GameData.rules_of(mode).difficulties
	for d in DIFFS:
		var b = _menu_diff[d]
		var n: int = int(lives[d])
		b.text = "%s (%s)" % [i18n.t("diff." + d), i18n.t("menu.life") if n == 1 else i18n.t("menu.lives", [n])]
		b.set_selected(d == difficulty)


func set_menu_visible(v: bool) -> void:
	_menu.visible = v
	call_deferred("fit_menu")
	_end.visible = false
	_pause_sheet.visible = false


func set_pause_visible(v: bool) -> void:
	_pause_sheet.visible = v


func is_blocking() -> bool:
	return _menu.visible or _pause_sheet.visible or _end.visible


func show_end(won: bool, reason: String, stats_text: String) -> void:
	_end_title.text = i18n.t("end.won") if won else i18n.t("end.lost")
	_end_title.add_theme_color_override("font_color", UiKit.GOLD if won else UiKit.BAD)
	var why = "" if won else i18n.t("end.lost_boss" if reason == "boss" else "end.lost_lives") + "\n"
	_end_stats.text = why + stats_text
	_end.visible = true


func toast(text: String, color := Color.WHITE, seconds := 2.2) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	_toast.modulate.a = 1.0
	_toast_ttl = seconds


## A short "+3 interest" under the gold counter.
func flash_interest(gold: int) -> void:
	_interest.text = i18n.t("msg.interest", [gold])
	_interest.modulate.a = 1.0
	_interest_ttl = 2.5


func tick(delta: float) -> void:
	if _interest_ttl > 0.0:
		_interest_ttl -= delta
		_interest.modulate.a = clampf(_interest_ttl / 0.8, 0.0, 1.0)
	elif _interest.text != "":
		_interest.text = ""
	if _toast_ttl > 0.0:
		_toast_ttl -= delta
		_toast.modulate.a = clampf(_toast_ttl / 0.6, 0.0, 1.0)
	elif _toast.text != "":
		_toast.text = ""


## True when a logical-pixel point lies on a floating panel, so a press there must not move the map.
func covers_point(p: Vector2) -> bool:
	for c in [_tray, _sheet, _confirm_bar]:
		if c.visible and Rect2(c.global_position, c.size).has_point(p):
			return true
	return false


## Space taken by the top and bottom bars in logical pixels (x = top, y = bottom), for framing the camera.
func get_insets() -> Vector2:
	return Vector2(54.0, _tray.size.y + 12.0)


## ctx keys: build_id, active_element, selected (bool), speed, paused, touch, ghost_valid, wall_mode, sheet_bbcode,
## sell_text, move_text, level_text, status_text, creep (def or {}), hint
func update_state(sim, ctx: Dictionary) -> void:
	_gold.text = str(sim.gold)
	_lumber.text = str(sim.lumber)
	_lives.text = "%d/%d" % [sim.lives, sim.max_lives]
	_level.text = ctx.level_text
	_status.text = ctx.status_text
	var creep: Dictionary = ctx.creep
	var has_creep: bool = not creep.is_empty()
	_kind_icon.visible = has_creep
	_creep_name.visible = has_creep
	_armor_icon.visible = has_creep
	_armor_label.visible = has_creep
	_boss_tag.visible = has_creep
	if has_creep:
		_kind_icon.set_glyph("air" if creep.air else "ground", UiKit.TEXT)
		_creep_name.text = i18n.n(creep.name)
		var ac: Color = ARMOR_COLORS.get(creep.armorType, Color.WHITE)
		var el: Dictionary = data.element_of(creep.armorType)
		if not el.is_empty():
			ac = Color(el.color)
		_armor_icon.set_glyph("shield", ac)
		_armor_label.text = "%s %d" % [i18n.t("armor." + creep.armorType), int(creep.armor)]
		var tags: Array = []
		for tr in creep.get("traits", []):
			tags.append(i18n.t("trait." + tr))
		if creep.air:
			tags.append(i18n.t("hud.air"))
		if creep.boss:
			tags.append(i18n.t("hud.boss"))
		_boss_tag.text = " · ".join(tags)
	_skip_btn.visible = sim.state == "countdown"
	_speed_btn.glyph = "ff" if ctx.speed == 1 else "ff2"
	_speed_btn.tint = UiKit.GOOD if ctx.speed == 1 else (UiKit.GOLD if ctx.speed == 2 else UiKit.BAD)
	_speed_btn.queue_redraw()
	_pause_btn.glyph = "play" if ctx.paused else "pause"
	_pause_btn.queue_redraw()
	_rebuild_bars(sim, ctx)
	for id in _tower_buttons:
		var def: Dictionary = data.towers[id]
		var affordable: bool = sim.gold >= int(def.cost.gold) and sim.lumber >= int(def.cost.lumber) and sim.cleared >= int(def.get("unlockAfter", 0))
		var b = _tower_buttons[id]
		b.modulate = Color(1, 1, 1, 1) if affordable else Color(1, 1, 1, 0.55)
		b.set_selected(ctx.build_id == id)
	_tray_body.visible = tray_open
	_tray_toggle.glyph = "chevron_down" if tray_open else "chevron_up"
	_tray_toggle.queue_redraw()
	_sheet.visible = ctx.sheet_bbcode != ""
	if _sheet.visible:
		_sheet_text.text = ctx.sheet_bbcode
	_sheet_buttons.visible = ctx.selected
	_move_btn.text = " " + ctx.move_text
	_sell_btn.text = " " + ctx.sell_text
	_wall_btn.visible = ctx.build_id != "" and data.mode == "classic"
	if _wall_btn.button_pressed != ctx.wall_mode:
		_wall_btn.set_pressed_no_signal(ctx.wall_mode)
	_confirm_bar.visible = ctx.touch and ctx.build_id != "" and ctx.ghost_valid and not ctx.wall_mode
	_hint.text = ctx.hint
	_hint.visible = ctx.hint != ""


func _rebuild_bars(sim, ctx: Dictionary) -> void:
	var sig := "%s|%s|%s|%s|%s" % [sim.elements, ctx.active_element, sim.lumber > 0, i18n.lang, sim.cleared]
	if sig == _bar_sig:
		return
	_bar_sig = sig
	for c in _elem_row.get_children():
		c.queue_free()
	for c in _tower_row.get_children():
		c.queue_free()
	_tower_buttons.clear()
	if sim.elements.is_empty():
		_element_picker(sim)
		return
	for eid in sim.elements:
		var e: Dictionary = data.element_of(eid)
		var b = UiKit.GlyphButton.new(UiKit.element_glyph(eid), "", Color(e.color), Vector2(52, 40))
		b.glyph_size = 24
		b.set_selected(eid == ctx.active_element)
		b.pressed.connect(func(): element_chosen.emit(eid))
		_elem_row.add_child(b)
	for gid in data.groups:
		var gb = UiKit.GlyphButton.new(gid, "", GROUP_COLORS.get(gid, Color.WHITE), Vector2(52, 40))
		gb.glyph_size = 24
		gb.set_selected(ctx.active_element == "g:" + gid)
		var gtab: String = "g:" + gid
		gb.pressed.connect(func(): element_chosen.emit(gtab))
		_elem_row.add_child(gb)
	if data.ultimate != "":
		var ult = UiKit.GlyphButton.new("ultimate", "", Color("bff6ff"), Vector2(52, 40))
		ult.glyph_size = 24
		ult.set_selected(ctx.active_element == "__ultimate")
		ult.pressed.connect(func(): element_chosen.emit("__ultimate"))
		_elem_row.add_child(ult)
	if sim.lumber > 0 and sim.elements.size() < data.elements.size():
		var more = UiKit.GlyphButton.new("log", "+", Color("d9a566"), Vector2(64, 40))
		more.glyph_size = 20
		more.pressed.connect(func(): element_chosen.emit("__unlock"))
		_elem_row.add_child(more)
	if ctx.active_element == "__unlock":
		_element_picker(sim)
		return
	var ids: Array = []
	var accent := Color("bff6ff")
	if ctx.active_element == "__ultimate":
		ids = [data.ultimate]
	elif ctx.active_element.begins_with("g:"):
		var gid: String = ctx.active_element.substr(2)
		accent = GROUP_COLORS.get(gid, Color.WHITE)
		# mixed towers: only the ones whose elements are all learned
		for tid in data.groups.get(gid, []):
			var ok := true
			for e in sim.needed_elements(data.towers[tid]):
				if not (e in sim.elements):
					ok = false
			if ok:
				ids.append(tid)
		if ids.is_empty():
			var none := _label(13, UiKit.MUTED)
			none.text = i18n.t("hud.elements_none")
			_tower_row.add_child(none)
	else:
		var el: Dictionary = data.element_of(ctx.active_element)
		if not el.is_empty():
			ids = el.towers
			accent = Color(el.color)
	var keys := ["Q", "W", "E", "R", "T", "Y"]
	var i := 0
	for id in ids:
		var def: Dictionary = data.towers[id]
		var cost = "%dg" % int(def.cost.gold) + (" +%dh" % int(def.cost.lumber) if int(def.cost.lumber) > 0 else "")
		if sim.cleared < int(def.get("unlockAfter", 0)):
			cost = i18n.t("hud.locked_level", [int(def.unlockAfter) + 1])
		var els: Array = def.get("elements", [])
		var card_color := accent
		if els.size() == 1:
			card_color = Color(data.element_of(els[0]).color)
		var b = UiKit.GlyphButton.new(UiKit.element_glyph(def.element), cost, card_color, Vector2(84, 70))
		b.top_icon = true
		b.glyph_size = 26
		b.badge = keys[mini(i, 5)] if els.size() < 2 and data.mode == "classic" else ("I" if int(def.tier) == 1 else ("II" if int(def.tier) == 2 else ("III" if int(def.tier) == 3 else "")))
		if els.size() > 1:
			b.glyphs = els
		b.tooltip_text = i18n.n(def.name)
		b.add_theme_font_size_override("font_size", 15)
		b.set_selected(false)
		var tid: String = id
		b.pressed.connect(func(): tower_chosen.emit(tid))
		b.button_down.connect(func(): card_down.emit(tid))
		_tower_row.add_child(b)
		_tower_buttons[id] = b
		i += 1


## Big element buttons: the first pick at the start, or an extra element when lumber is available.
func _element_picker(sim) -> void:
	for e in data.elements:
		if e.id in sim.elements:
			continue
		var b = UiKit.GlyphButton.new(UiKit.element_glyph(e.id), i18n.n(e.name), Color(e.color), Vector2(92, 64))
		b.top_icon = true
		b.glyph_size = 22
		b.add_theme_font_size_override("font_size", 13)
		b.set_selected(false)
		b.pressed.connect(func(): unlock_pressed.emit(e.id))
		_tower_row.add_child(b)
