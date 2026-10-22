extends Node
## Game client: owns the simulation, turns touch and mouse input into commands, and keeps the 3D view and HUD in sync.
##
## Interaction model (works the same with a finger or a mouse):
##   drag the map = pan · pinch or wheel = zoom · tap a tower = select it
##   tap a card = arm it, then tap the map (a ghost appears, confirm with the check mark; mouse: click to build)
##   drag a card out of the tray onto the map = place it where you let go
##   hold a tower (or drag a selected one) = pick it up and move it · "Move" button does the same in two taps
##   "Drag a wall" = drag a line on the map to build a row of towers

const GameData := preload("res://core/game_data.gd")
const Sim := preload("res://core/sim.gd")
const WorldView := preload("res://client/world_view.gd")
const Hud := preload("res://client/hud.gd")
const Overlay := preload("res://client/overlay.gd")
const I18n := preload("res://client/i18n.gd")

const SETTINGS_PATH := "user://settings.json"
const TOWER_KEYS := [KEY_Q, KEY_W, KEY_E, KEY_R, KEY_T, KEY_Y]
const DRAG_START_PX := 14.0
const LONG_PRESS_S := 0.4
const FINGER_OFFSET_TILES := 1.5   # a dragged ghost floats above the finger so it stays visible

var data
var sim
var i18n
var world
var hud
var overlay

var acc := 0.0
var speed := 1
var paused := false
var menu_open := true
var end_shown := false

var build_id := ""
var active_element := ""
var selected_id := 0
var moving_id := 0
var ghost_cell := Vector2i(-1, -1)
var ghost_ok := false
var ghost_reason := ""
var path_text := ""
var wall_mode := false
var wall_cells: Array = []

var touch_mode := false
var touches := {}
var _pinch_dist := 0.0

# one pointer interaction at a time
var _press_active := false
var _press_pos := Vector2.ZERO
var _press_start := Vector2.ZERO
var _press_time := 0.0
var _press_kind := ""        # "pan" | "ghost" | "tower" | "wall" | "none"
var _press_tower := 0
var _press_dragged := false
var _right_down := false
var _right_dragged := false
var _last_pointer := Vector2.ZERO   # own motion delta: InputEventMouseMotion.relative is not scaled with the UI

# dragging a card out of the tray
var _card_id := ""
var _card_start := Vector2.ZERO
var _card_dragging := false
var _card_drop_guard := 0.0

var _last_leak_toast := 0
var settings := {"lang": "", "difficulty": "normal"}


func _ready() -> void:
	data = GameData.load_all()
	i18n = I18n.new()
	_load_settings()
	if settings.lang == "":
		settings.lang = "nl" if OS.get_locale_language() == "nl" else "en"
	i18n.lang = settings.lang
	touch_mode = DisplayServer.is_touchscreen_available()
	_apply_ui_scale()
	var layer := CanvasLayer.new()
	add_child(layer)
	overlay = Overlay.new()
	layer.add_child(overlay)
	hud = Hud.new()
	layer.add_child(hud)
	hud.setup(data, i18n)
	hud.difficulty = settings.difficulty
	hud.refresh_static_texts()
	hud.tower_chosen.connect(_on_tower_chosen)
	hud.card_down.connect(_on_card_down)
	hud.element_chosen.connect(_on_element_chosen)
	hud.unlock_pressed.connect(_on_unlock)
	hud.sell_pressed.connect(_sell_selected)
	hud.move_pressed.connect(_on_move_pressed)
	hud.skip_pressed.connect(_skip)
	hud.speed_pressed.connect(_cycle_speed)
	hud.pause_pressed.connect(func(): paused = not paused)
	hud.menu_pressed.connect(_open_pause_sheet)
	hud.resume_pressed.connect(_close_pause_sheet)
	hud.restart_pressed.connect(_open_menu)
	hud.lang_pressed.connect(_toggle_lang)
	hud.confirm_pressed.connect(_confirm)
	hud.cancel_pressed.connect(_cancel)
	hud.play_pressed.connect(_play)
	hud.again_pressed.connect(func(): _play(settings.difficulty))
	hud.center_pressed.connect(_fit)
	hud.wall_toggled.connect(func(on): _set_wall_mode(on))
	hud.minimap_focus.connect(func(t): world.focus_on(t))
	hud.tray_toggled.connect(func(_open): call_deferred("_fit_keep"))
	_new_game(settings.difficulty)
	hud.set_menu_visible(true)
	get_viewport().size_changed.connect(_fit)


func _new_game(difficulty: String) -> void:
	if world != null:
		world.queue_free()
	sim = Sim.new(data, int(Time.get_ticks_usec() % 1000000007), difficulty, 1)
	sim.record_events = true
	world = WorldView.new()
	add_child(world)
	world.setup(sim, data)
	world.cam.make_current()
	overlay.sim = sim
	overlay.world = world
	hud.attach_minimap(sim, world)
	acc = 0.0
	speed = 1
	paused = false
	end_shown = false
	_reset_interaction()
	active_element = ""
	hud._bar_sig = ""
	call_deferred("_fit")


func _reset_interaction() -> void:
	build_id = ""
	selected_id = 0
	moving_id = 0
	ghost_cell = Vector2i(-1, -1)
	wall_mode = false
	wall_cells.clear()
	path_text = ""
	_press_active = false
	_card_id = ""
	if world != null:
		world.hide_ghost()
		world.select_tower(null)
		world.lift_tower(0)
		world.set_build_mode(false)
		world.show_wall([], [], {})


func _fit() -> void:
	if world != null and hud != null:
		world.fit_camera(hud.get_insets())


func _fit_keep() -> void:
	pass


## Phones are small: scale the interface so the buttons stay finger sized (>= 44 px on a ~400 px high screen).
func _apply_ui_scale() -> void:
	get_tree().root.content_scale_factor = 1.64 if touch_mode else 1.2


func _play(difficulty: String) -> void:
	settings.difficulty = difficulty
	_save_settings()
	_new_game(difficulty)
	menu_open = false
	hud.set_menu_visible(false)


func _open_menu() -> void:
	menu_open = true
	hud.difficulty = settings.difficulty
	hud.refresh_static_texts()
	hud.set_menu_visible(true)


func _open_pause_sheet() -> void:
	paused = true
	hud.set_pause_visible(true)


func _close_pause_sheet() -> void:
	paused = false
	hud.set_pause_visible(false)


# ------------------------------------------------------------------ frame loop

func _process(delta: float) -> void:
	if sim == null:
		return
	var running: bool = not menu_open and not paused and sim.state != "won" and sim.state != "lost"
	if running:
		acc += delta * float(speed)
		var n := 0
		while acc >= Sim.DT and n < 8:
			sim.tick()
			acc -= Sim.DT
			n += 1
		if n == 8:
			acc = 0.0
	var alpha: float = clampf(acc / Sim.DT, 0.0, 1.0) if running else 1.0
	world.update_view(alpha, delta)
	_handle_events()
	_check_long_press(delta)
	_card_drop_guard = maxf(0.0, _card_drop_guard - delta)
	_pan_with_keys(delta)
	hud.update_state(sim, _context())
	hud.tick(delta)
	overlay.tick(delta)
	hud.minimap.queue_redraw()
	if not end_shown and (sim.state == "won" or sim.state == "lost"):
		end_shown = true
		hud.show_end(sim.state == "won", sim.lost_reason, i18n.t("end.stats", [sim.level, sim.stats.kills, sim.towers.size()]))


func _pan_with_keys(delta: float) -> void:
	var v := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT):
		v.x -= 1
	if Input.is_key_pressed(KEY_RIGHT):
		v.x += 1
	if Input.is_key_pressed(KEY_UP):
		v.y -= 1
	if Input.is_key_pressed(KEY_DOWN):
		v.y += 1
	if v != Vector2.ZERO:
		world.cam_target += v.normalized() * delta * world.view_w * 0.6
		world._apply_camera()


func _handle_events() -> void:
	for e in sim.events:
		match e.type:
			"wave":
				var wave: Dictionary = data.waves[int(e.level) - 1]
				var creep: Dictionary = data.creeps[wave.creep]
				hud.toast(i18n.t("msg.wave_start", [e.level, i18n.n(creep.name)]), UiKit.ACCENT, 2.6)
				if creep.boss:
					hud.toast(i18n.t("msg.boss_warning"), Color("ff8a5c"), 3.0)
			"kill":
				overlay.add_text(e.pos, "+%d" % int(e.gold), UiKit.GOLD, 22 if e.boss else 18)
				world.add_kill_burst(e.pos, e.boss)
			"leak":
				overlay.add_text(e.pos, "-1", Color("ff5d5d"), 26)
				if Time.get_ticks_msec() - _last_leak_toast > 1500:
					_last_leak_toast = Time.get_ticks_msec()
					hud.toast(i18n.t("msg.leak"), Color("ff7a7a"), 1.4)
			"zap":
				overlay.add_zap(e.from, e.to)
			"impact":
				world.add_impact(e.pos, e.element, e.air)
			"crit":
				overlay.add_text(e.pos, "!", Color("ff9a3c"), 28)
	sim.events.clear()


func _wave_creep() -> Dictionary:
	if sim.state == "active" and sim.level >= 1:
		return data.creeps[data.waves[sim.level - 1].creep]
	if sim.level < data.waves.size():
		return data.creeps[data.waves[sim.level].creep]
	return {}


func _context() -> Dictionary:
	var status := ""
	if sim.state == "countdown":
		status = i18n.t("hud.starts_in", [int(ceil(sim.countdown))])
	elif sim.state == "active":
		status = i18n.t("hud.wave_active", [sim.creeps_remaining()])
	var creep := {}
	if sim.state == "countdown" or sim.state == "active":
		creep = _wave_creep()
	var sheet := ""
	var sell_text := ""
	var move_text: String = i18n.t("hud.move")
	if moving_id != 0 and sim.towers.has(moving_id):
		var mt = sim.towers[moving_id]
		sheet = "[b]%s[/b]\n%s" % [i18n.n(mt.def.name), i18n.t("hud.moving", [int(maxf(1.5, float(mt.def.buildTime) * float(sim.data.rules.moveBuildShare)))])]
	elif build_id != "":
		sheet = _def_info(data.towers[build_id])
		if wall_mode and wall_cells.size() > 0:
			sheet += "\n" + i18n.t("hud.wall_cost", [wall_cells.size(), wall_cells.size() * int(data.towers[build_id].cost.gold)])
		elif path_text != "":
			sheet += "\n" + path_text
	elif selected_id != 0 and sim.towers.has(selected_id):
		var t = sim.towers[selected_id]
		sheet = _tower_info(t)
		sell_text = i18n.t("hud.sell", [sim.sell_value(t)])
	var hint := ""
	if sim.elements.is_empty():
		hint = i18n.t("hud.choose_element")
	elif build_id == "" and moving_id == 0 and selected_id == 0 and sim.towers.is_empty():
		hint = i18n.t("hud.drag_hint")
	if active_element == "" and not sim.elements.is_empty():
		active_element = sim.elements[0]
	return {
		"build_id": build_id, "active_element": active_element, "speed": speed, "paused": paused, "touch": touch_mode,
		"selected": selected_id != 0 and moving_id == 0 and build_id == "", "ghost_valid": ghost_ok and ghost_cell.x >= 0 and (build_id != "" or moving_id != 0),
		"wall_mode": wall_mode, "sheet_bbcode": sheet, "sell_text": sell_text, "move_text": move_text,
		"level_text": i18n.t("hud.level_short", [sim.level, int(sim.data.rules.lastLevel)]), "status_text": status,
		"creep": creep, "hint": hint,
	}


# ------------------------------------------------------------------ info text

func _fmt(v: float) -> String:
	return str(snappedf(v, 0.1)).rstrip("0").rstrip(".") if v != floor(v) else str(int(v))


func _def_info(def: Dictionary) -> String:
	var a: Dictionary = def.attack
	var avg: float = (float(a.damage[0]) + float(a.damage[1])) * 0.5
	var cd: float = ceil(float(a.cooldown) / Sim.DT - 0.0001) * Sim.DT
	var dmg := _fmt(float(a.damage[0])) if a.damage[0] == a.damage[1] else "%s-%s" % [_fmt(float(a.damage[0])), _fmt(float(a.damage[1]))]
	var el: Dictionary = data.element_of(def.element)
	var color: String = el.get("color", "#bff6ff")
	var targets: Array = []
	for t in a.targets:
		targets.append(i18n.t("targets." + t))
	var s := "[b][color=%s]%s[/color][/b]\n" % [color, i18n.n(def.name)]
	s += "%s %s · %s/s\n" % [i18n.t("stat.damage"), dmg, _fmt(avg / cd)]
	s += "%s %s s · %s %s\n" % [i18n.t("stat.cooldown"), _fmt(cd), i18n.t("stat.range"), _fmt(float(a.range))]
	s += "%s · %s\n" % [i18n.t("attack." + a.type), ", ".join(targets)]
	if a.splash != null:
		s += "%s %s\n" % [i18n.t("stat.splash"), _fmt(float(a.splash[2]))]
	for e in def.effects:
		s += "• " + _effect_text(e, def) + "\n"
	var creep := _wave_creep()
	if not creep.is_empty():
		var m: float = sim.damage_multiplier(a.type, creep.armorType, float(creep.armor))
		var c := "#7ee08a" if m >= 1.0 else "#ff9a7a"
		s += "[color=%s]%s[/color]" % [c, i18n.t("stat.vs", [_fmt(snappedf(m, 0.01))])]
	return s


func _tower_info(t) -> String:
	var s := _def_info(t.def)
	s += "\n%s %d" % [i18n.t("stat.kills"), t.kills]
	if t.building:
		s += "\n" + i18n.t("hud.tower_building", [int(ceil(t.build_left))])
	return s


func _effect_text(e: Dictionary, def: Dictionary) -> String:
	match e.kind:
		"slow":
			return i18n.t("fx.slow", [int(round(float(e.amount) * 100.0)), _fmt(float(e.duration))])
		"poison":
			var avg: float = (float(def.attack.damage[0]) + float(def.attack.damage[1])) * 0.5
			return i18n.t("fx.poison", [int(round(float(e.slow) * 100.0)), _fmt(avg * float(e.dpsFactor)), _fmt(float(e.duration))])
		"crit":
			return i18n.t("fx.crit", [int(round(float(e.chance) * 100.0)), _fmt(float(e.multiplier))])
		"chain":
			return i18n.t("fx.chain", [int(e.targets)])
		"bounce":
			return i18n.t("fx.bounce", [int(e.targets)])
		"armor_reduce":
			return i18n.t("fx.armor_reduce", [int(e.amount), _fmt(float(e.duration))])
		"percent_hp":
			return i18n.t("fx.percent_hp", [int(round(float(e.percent) * 100.0))])
		"set_hp":
			return i18n.t("fx.set_hp", [int(e.hp)])
		"root":
			if e.has("chance"):
				return i18n.t("fx.root_chance", [int(round(float(e.chance) * 100.0)), _fmt(float(e.duration))])
			return i18n.t("fx.root")
		"bonus_damage":
			return i18n.t("fx.bonus_damage", [int(e.amount)])
	return ""


# ------------------------------------------------------------------ commands from the HUD

func _on_element_chosen(id: String) -> void:
	active_element = "__unlock" if id == "__unlock" else id
	hud._bar_sig = ""
	_cancel()


func _on_unlock(id: String) -> void:
	var r: Dictionary = sim.unlock_element(id)
	if r.ok:
		active_element = id
		hud.toast(i18n.t("msg.element_chosen", [i18n.n(data.element_of(id).name)]), UiKit.ACCENT)
		hud._bar_sig = ""
	else:
		hud.toast(i18n.t("msg." + String(r.reason)), Color("ff7a7a"))


func _on_tower_chosen(id: String) -> void:
	if _card_drop_guard > 0.0:
		return
	if build_id == id:
		_cancel()
		return
	_arm(id)


func _arm(id: String) -> void:
	_cancel_move()
	build_id = id
	selected_id = 0
	world.select_tower(null)
	ghost_cell = Vector2i(-1, -1)
	path_text = ""
	world.hide_ghost()
	world.set_build_mode(true)


func _cancel_move() -> void:
	if moving_id != 0:
		moving_id = 0
		world.lift_tower(0)


func _cancel() -> void:
	_cancel_move()
	build_id = ""
	ghost_cell = Vector2i(-1, -1)
	path_text = ""
	selected_id = 0
	wall_cells.clear()
	_set_wall_mode(false)
	world.hide_ghost()
	world.select_tower(null)
	world.set_build_mode(false)
	world.show_wall([], [], {})


func _set_wall_mode(on: bool) -> void:
	wall_mode = on
	wall_cells.clear()
	world.show_wall([], [], {})


func _skip() -> void:
	sim.next_wave_now()


func _cycle_speed() -> void:
	speed = 2 if speed == 1 else (4 if speed == 2 else 1)


func _toggle_lang() -> void:
	i18n.toggle()
	settings.lang = i18n.lang
	_save_settings()
	hud.refresh_static_texts()


func _sell_selected() -> void:
	if selected_id != 0 and sim.towers.has(selected_id):
		sim.sell_tower(selected_id)
	selected_id = 0
	world.select_tower(null)


func _on_move_pressed() -> void:
	if selected_id != 0 and sim.towers.has(selected_id):
		_begin_move(selected_id)


func _begin_move(id: int) -> void:
	var t = sim.towers[id]
	build_id = ""
	moving_id = id
	selected_id = id
	world.lift_tower(id)
	world.set_build_mode(true)
	world.select_tower(null)
	ghost_cell = Vector2i(t.cx, t.cy)
	_refresh_ghost()


## The check mark: place the armed tower, or drop the one that is being moved.
func _confirm() -> void:
	if ghost_cell.x < 0:
		return
	if moving_id != 0:
		_try_move()
	elif build_id != "":
		_try_place()


# ------------------------------------------------------------------ ghost handling

func _active_def() -> Dictionary:
	if moving_id != 0 and sim.towers.has(moving_id):
		return sim.towers[moving_id].def
	if build_id != "":
		return data.towers[build_id]
	return {}


## Grid cell (top-left of the footprint) for a screen position. A dragged finger gets a vertical offset.
func _cell_from_screen(pos: Vector2, finger := false) -> Vector2i:
	var def := _active_def()
	if def.is_empty():
		return Vector2i(-1, -1)
	var p := pos
	if finger and touch_mode:
		p.y -= world.pixels_per_tile() * FINGER_OFFSET_TILES
	var tile = world.screen_to_tile(p)
	if tile == null:
		return Vector2i(-1, -1)
	var cs: float = sim.grid.cell_size
	return Vector2i(int(round(tile.x / cs - float(def.footprint[0]) * 0.5)), int(round(tile.y / cs - float(def.footprint[1]) * 0.5)))


func _set_ghost(cell: Vector2i) -> void:
	if cell == ghost_cell and cell.x >= 0:
		return
	ghost_cell = cell
	if cell.x < 0:
		world.hide_ghost()
		path_text = ""
		return
	_refresh_ghost()


func _refresh_ghost() -> void:
	var def := _active_def()
	if def.is_empty() or ghost_cell.x < 0:
		return
	var r: Dictionary
	if moving_id != 0:
		r = sim.can_move(moving_id, ghost_cell.x, ghost_cell.y)
	else:
		r = sim.can_place(build_id, ghost_cell.x, ghost_cell.y)
	ghost_ok = r.ok
	ghost_reason = String(r.get("reason", ""))
	var soft_ok: bool = ghost_ok or ghost_reason == "gold" or ghost_reason == "lumber"
	world.show_ghost(def, ghost_cell.x, ghost_cell.y, soft_ok, 0.0)
	path_text = ""
	if soft_ok and moving_id == 0:
		var starts := PackedInt32Array()
		for s in data.map.spawns:
			starts.append(sim.grid.idx(int(s.cell[0]), int(s.cell[1])))
		var before: float = sim.grid.path_length(starts)
		var after: float = sim.grid.path_length_with(ghost_cell.x, ghost_cell.y, int(def.footprint[0]), int(def.footprint[1]), starts)
		if after > 0.0 and before > 0.0:
			var pct := int(round((after / before - 1.0) * 100.0))
			path_text = i18n.t("hud.path", [_fmt(after), ("+%d%%" % pct) if pct >= 0 else ("%d%%" % pct)])


func _try_place() -> void:
	var r: Dictionary = sim.place_tower(build_id, ghost_cell.x, ghost_cell.y)
	if r.ok:
		_refresh_ghost()
	else:
		hud.toast(i18n.t("msg." + String(r.reason)), Color("ff7a7a"), 1.6)


func _try_move() -> void:
	var r: Dictionary = sim.move_tower(moving_id, ghost_cell.x, ghost_cell.y)
	if r.ok:
		hud.toast(i18n.t("msg.moved"), UiKit.GOOD, 1.2)
		var id := moving_id
		_cancel_move()
		world.hide_ghost()
		world.set_build_mode(false)
		ghost_cell = Vector2i(-1, -1)
		selected_id = id
		world.select_tower(sim.towers[id])
	else:
		hud.toast(i18n.t("msg." + String(r.reason)), Color("ff7a7a"), 1.6)


# ------------------------------------------------------------------ walls

func _wall_line(a: Vector2i, b: Vector2i) -> Array:
	# cells along the line, one footprint (2 cells) apart
	var cells: Array = []
	var d := Vector2(b - a)
	var steps := maxi(1, int(ceil(d.length() / 2.0)))
	var last := Vector2i(-9999, -9999)
	for i in steps + 1:
		var p := Vector2(a) + d * (float(i) / float(steps))
		var c := Vector2i(int(round(p.x)), int(round(p.y)))
		if c != last:
			cells.append(c)
			last = c
	return cells


func _update_wall_preview(end_pos: Vector2) -> void:
	var start := _cell_from_screen(_press_start)
	var end := _cell_from_screen(end_pos)
	if start.x < 0 or end.x < 0:
		return
	var def: Dictionary = data.towers[build_id]
	var cells := _wall_line(start, end)
	var oks: Array = []
	var valid: Array = []
	var budget: int = sim.gold
	for c in cells:
		var r: Dictionary = sim.can_place(build_id, c.x, c.y)
		var ok: bool = r.ok or String(r.get("reason", "")) == "gold"
		oks.append(ok)
		if ok:
			valid.append(c)
	wall_cells = valid
	world.show_wall(cells, oks, def)


func _finish_wall() -> void:
	var placed := 0
	for c in wall_cells:
		if sim.place_tower(build_id, c.x, c.y).ok:
			placed += 1
	if placed > 0:
		hud.toast(i18n.t("msg.wall", [placed]), UiKit.GOOD, 1.4)
	else:
		hud.toast(i18n.t("msg.nothing_placed"), Color("ff7a7a"), 1.4)
	wall_cells.clear()
	world.show_wall([], [], {})
	world.set_build_mode(true)


# ------------------------------------------------------------------ input

func _input(event: InputEvent) -> void:
	# dragging a card out of the tray: follow the pointer before the interface sees the events
	if _card_id == "":
		return
	if event is InputEventMouseMotion:
		_card_motion(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_card_release(event.position)


func _on_card_down(id: String) -> void:
	_card_id = id
	_card_start = get_viewport().get_mouse_position()
	_card_dragging = false


func _card_motion(pos: Vector2) -> void:
	if not _card_dragging:
		var d := pos - _card_start
		if d.length() > 18.0 and (absf(d.y) > absf(d.x) * 0.7 or d.y < 0.0):
			_card_dragging = true
			_cancel_move()
			build_id = _card_id
			selected_id = 0
			world.select_tower(null)
			world.set_build_mode(true)
		else:
			return
	if hud.covers_point(pos):
		world.hide_ghost()
		ghost_cell = Vector2i(-1, -1)
		return
	_set_ghost(_cell_from_screen(pos, true))


func _card_release(pos: Vector2) -> void:
	var id := _card_id
	_card_id = ""
	if not _card_dragging:
		return
	_card_dragging = false
	_card_drop_guard = 0.25
	if hud.covers_point(pos) or ghost_cell.x < 0:
		_cancel()
		return
	var r: Dictionary = sim.place_tower(id, ghost_cell.x, ghost_cell.y)
	if r.ok:
		_refresh_ghost()
		if not touch_mode:
			pass
		# stay armed so several towers can be dropped in a row
	else:
		hud.toast(i18n.t("msg." + String(r.reason)), Color("ff7a7a"), 1.6)


func _unhandled_input(event: InputEvent) -> void:
	if sim == null or menu_open or hud.is_blocking():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_on_key(event.keycode)
	elif event is InputEventScreenTouch:
		if not touch_mode:
			touch_mode = true
			_apply_ui_scale()
		if event.pressed:
			touches[event.index] = event.position
			if touches.size() >= 2:
				_press_active = false
				_press_kind = "none"
		else:
			touches.erase(event.index)
		_pinch_dist = 0.0
	elif event is InputEventScreenDrag:
		touches[event.index] = event.position
		if touches.size() >= 2:
			var pts: Array = touches.values()
			var d: float = (pts[0] as Vector2).distance_to(pts[1])
			if _pinch_dist > 0.0 and d > 1.0:
				world.zoom_at(_pinch_dist / d, (pts[0] + pts[1]) * 0.5)
			_pinch_dist = d
	elif event is InputEventMouseButton:
		_on_mouse_button(event)
	elif event is InputEventMouseMotion:
		_on_mouse_motion(event)


func _on_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			if event.pressed:
				world.zoom_at(0.9, event.position)
		MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				world.zoom_at(1.1, event.position)
		MOUSE_BUTTON_LEFT:
			if event.pressed:
				_press_begin(event.position)
			else:
				_press_end(event.position)
		MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_last_pointer = event.position
				_right_down = true
				_right_dragged = false
			else:
				if _right_down and not _right_dragged:
					_cancel()
				_right_down = false


func _on_mouse_motion(event: InputEventMouseMotion) -> void:
	var rel: Vector2 = event.position - _last_pointer
	_last_pointer = event.position
	if _press_active:
		_press_move(event.position, rel)
	elif _right_down:
		_right_dragged = true
		world.pan_by_screen(rel)
	elif not touch_mode and (build_id != "" or moving_id != 0) and not wall_mode:
		_set_ghost(_cell_from_screen(event.position))


func _press_begin(pos: Vector2) -> void:
	_last_pointer = pos
	if touches.size() >= 2 or hud.covers_point(pos):
		return
	_press_active = true
	_press_pos = pos
	_press_start = pos
	_press_time = 0.0
	_press_dragged = false
	_press_tower = 0
	_press_kind = "pan"
	if moving_id != 0:
		_press_kind = "ghost"
		_set_ghost(_cell_from_screen(pos, true))
		return
	if build_id != "":
		if wall_mode:
			_press_kind = "wall"
			wall_cells.clear()
			return
		if ghost_cell.x >= 0 and _near_ghost(pos):
			_press_kind = "ghost"
			return
		_press_kind = "pan"
		return
	var id: int = world.pick_tower(pos)
	if id != 0:
		_press_kind = "tower"
		_press_tower = id


func _near_ghost(pos: Vector2) -> bool:
	var def := _active_def()
	if def.is_empty():
		return false
	var cs: float = sim.grid.cell_size
	var center := Vector2((float(ghost_cell.x) + float(def.footprint[0]) * 0.5) * cs, (float(ghost_cell.y) + float(def.footprint[1]) * 0.5) * cs)
	return world.tile_to_screen(center, 0.4).distance_to(pos) < world.pixels_per_tile() * 1.4


func _press_move(pos: Vector2, rel: Vector2) -> void:
	if touches.size() >= 2:
		return
	if not _press_dragged and pos.distance_to(_press_start) > DRAG_START_PX:
		_press_dragged = true
		if _press_kind == "tower" and _press_tower != 0:
			# dragging a tower picks it up when it is selected, or when it was held down: otherwise pan
			if _press_tower == selected_id:
				_begin_move(_press_tower)
				_press_kind = "ghost"
			else:
				_press_kind = "pan"
	_press_pos = pos
	if not _press_dragged:
		return
	match _press_kind:
		"pan":
			world.pan_by_screen(rel)
		"ghost":
			_set_ghost(_cell_from_screen(pos, true))
		"wall":
			_update_wall_preview(pos)


func _press_end(pos: Vector2) -> void:
	if not _press_active:
		return
	_press_active = false
	var kind := _press_kind
	_press_kind = ""
	if not _press_dragged:
		_on_tap(pos, kind)
		return
	match kind:
		"ghost":
			if moving_id != 0:
				_try_move()
		"wall":
			_finish_wall()


func _on_tap(pos: Vector2, kind: String) -> void:
	if moving_id != 0:
		var cell := _cell_from_screen(pos, false)
		if cell.x >= 0:
			_set_ghost(cell)
			if not touch_mode:
				_try_move()
		return
	if build_id != "":
		if wall_mode:
			return
		var hit: int = world.pick_tower(pos)
		if hit != 0 and kind != "ghost":
			# tapping an existing tower selects it instead of building on top of it
			_cancel()
			selected_id = hit
			world.select_tower(sim.towers[hit])
			return
		var cell2 := _cell_from_screen(pos, false)
		if cell2.x < 0:
			return
		if touch_mode and cell2 != ghost_cell and kind != "ghost":
			_set_ghost(cell2)
			return
		_set_ghost(cell2)
		_try_place()
		return
	var id: int = world.pick_tower(pos)
	selected_id = id
	world.select_tower(sim.towers[id] if id != 0 else null)
	world.set_build_mode(false)


func _check_long_press(delta: float) -> void:
	if not _press_active or _press_dragged or _press_kind != "tower" or _press_tower == 0:
		return
	_press_time += delta
	if _press_time >= LONG_PRESS_S and sim.towers.has(_press_tower):
		_press_dragged = true
		_begin_move(_press_tower)
		_press_kind = "ghost"
		_set_ghost(_cell_from_screen(_press_pos, true))


func _on_key(code: int) -> void:
	if code in TOWER_KEYS:
		var el: Dictionary = data.element_of(active_element)
		var idx: int = TOWER_KEYS.find(code)
		if not el.is_empty() and idx < el.towers.size():
			_on_tower_chosen(el.towers[idx])
		return
	match code:
		KEY_ESCAPE:
			_cancel()
		KEY_S:
			_sell_selected()
		KEY_M:
			_on_move_pressed()
		KEY_SPACE:
			_skip()
		KEY_P:
			paused = not paused
		KEY_1:
			speed = 1
		KEY_2:
			speed = 2
		KEY_3:
			speed = 4
		KEY_HOME, KEY_F:
			_fit()
		KEY_ENTER, KEY_KP_ENTER:
			_confirm()


# ------------------------------------------------------------------ settings

func _load_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		for k in settings.keys():
			if parsed.has(k):
				settings[k] = parsed[k]


func _save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(settings))
