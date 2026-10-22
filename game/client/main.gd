extends Node
## Game client: owns the simulation, turns input into commands, and keeps the 3D view and the HUD in sync.

const GameData := preload("res://core/game_data.gd")
const Sim := preload("res://core/sim.gd")
const WorldView := preload("res://client/world_view.gd")
const Hud := preload("res://client/hud.gd")
const Overlay := preload("res://client/overlay.gd")
const I18n := preload("res://client/i18n.gd")

const SETTINGS_PATH := "user://settings.json"
const TOWER_KEYS := [KEY_Q, KEY_W, KEY_E, KEY_R, KEY_T, KEY_Y]
const REASON_COLORS := {"gold": Color("ffd45e"), "blocks_path": Color("ff7a7a")}

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
var ghost_cell := Vector2i(-1, -1)
var ghost_ok := false
var ghost_reason := ""
var path_text := ""
var selected_id := 0

var touch_mode := false
var touches := {}
var pressing := false
var dragging := false
var press_pos := Vector2.ZERO
var right_down := false
var right_dragged := false
var middle_down := false
var _pinch_dist := 0.0
var _last_toast_leak := 0.0

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
	hud.element_chosen.connect(_on_element_chosen)
	hud.unlock_pressed.connect(_on_unlock)
	hud.sell_pressed.connect(_sell_selected)
	hud.skip_pressed.connect(_skip)
	hud.speed_pressed.connect(_cycle_speed)
	hud.pause_pressed.connect(func(): paused = not paused)
	hud.menu_pressed.connect(func(): _open_menu())
	hud.lang_pressed.connect(_toggle_lang)
	hud.confirm_pressed.connect(_try_place)
	hud.cancel_pressed.connect(_cancel)
	hud.play_pressed.connect(_play)
	hud.again_pressed.connect(func(): _play(settings.difficulty))
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
	_fit()
	overlay.sim = sim
	overlay.world = world
	acc = 0.0
	speed = 1
	paused = false
	end_shown = false
	build_id = ""
	selected_id = 0
	active_element = ""
	ghost_cell = Vector2i(-1, -1)
	hud._bar_sig = ""


func _fit() -> void:
	if world != null:
		world.fit_camera(hud.get_insets() if hud != null else Vector2(64.0, 180.0))


## Phones are small: scale the interface up so the buttons stay finger sized.
func _apply_ui_scale() -> void:
	get_tree().root.content_scale_factor = 1.3 if touch_mode else 1.0


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
	world.update_view(alpha)
	_handle_events()
	hud.update_state(sim, _context())
	hud.tick(delta)
	overlay.tick(delta)
	if not end_shown and (sim.state == "won" or sim.state == "lost"):
		end_shown = true
		hud.show_end(sim.state == "won", sim.lost_reason, i18n.t("end.stats", [sim.level, sim.stats.kills, sim.towers.size()]))


func _handle_events() -> void:
	for e in sim.events:
		match e.type:
			"wave":
				var wave: Dictionary = data.waves[int(e.level) - 1]
				var creep: Dictionary = data.creeps[wave.creep]
				hud.toast(i18n.t("msg.wave_start", [e.level, i18n.n(creep.name)]), Color("9fd6ff"), 2.6)
				if creep.boss:
					hud.toast(i18n.t("msg.boss_warning"), Color("ff8a5c"), 3.0)
			"kill":
				overlay.add_text(e.pos, "+%d" % int(e.gold), Color("ffd45e"), 22 if e.boss else 18)
			"leak":
				overlay.add_text(e.pos, "-1", Color("ff5d5d"), 26)
				if Time.get_ticks_msec() - _last_toast_leak > 1500:
					_last_toast_leak = Time.get_ticks_msec()
					hud.toast(i18n.t("msg.leak"), Color("ff7a7a"), 1.4)
			"zap":
				overlay.add_zap(e.from, e.to)
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
	var wave_text := ""
	if sim.state == "countdown":
		wave_text = i18n.t("hud.next_in", [int(ceil(sim.countdown))])
	elif sim.state == "active":
		wave_text = i18n.t("hud.wave_active", [sim.creeps_remaining()])
	var banner := ""
	var creep := _wave_creep()
	if not creep.is_empty() and (sim.state == "countdown" or sim.state == "active"):
		var wave_idx: int = sim.level - 1 if sim.state == "active" else sim.level
		var wave: Dictionary = data.waves[wave_idx]
		var parts: Array = [i18n.n(creep.name), "%s %s %d" % [i18n.t("stat.armor"), i18n.t("armor." + creep.armorType), int(creep.armor)],
			i18n.t("hud.air") if creep.air else i18n.t("hud.ground")]
		if creep.boss:
			parts.append(i18n.t("hud.boss"))
		if wave.noLifeLoss:
			parts.append(i18n.t("hud.bonus"))
		banner = (i18n.t("hud.wave_now") if sim.state == "active" else i18n.t("hud.wave_next")).replace("{0}", " · ".join(parts))
	var info := ""
	var sell_text := ""
	if build_id != "":
		info = _def_info(data.towers[build_id])
		if path_text != "":
			info += "\n" + path_text
	elif selected_id != 0 and sim.towers.has(selected_id):
		var t = sim.towers[selected_id]
		info = _tower_info(t)
		sell_text = i18n.t("hud.sell", [sim.sell_value(t)])
	var hint := ""
	if sim.elements.is_empty():
		hint = i18n.t("hud.choose_element")
	elif touch_mode and build_id != "":
		hint = i18n.t("touch.hint")
	if active_element == "" and not sim.elements.is_empty():
		active_element = sim.elements[0]
	return {
		"build_id": build_id, "active_element": active_element, "speed": speed, "paused": paused,
		"touch_mode": touch_mode, "ghost_valid": ghost_ok and ghost_cell.x >= 0, "info_bbcode": info,
		"sell_text": sell_text, "wave_text": wave_text, "banner": banner, "hint": hint,
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
	s += "%s: %s  ·  %s: %s/s\n" % [i18n.t("stat.damage"), dmg, i18n.t("stat.dps"), _fmt(avg / cd)]
	s += "%s: %s s  ·  %s: %s\n" % [i18n.t("stat.cooldown"), _fmt(cd), i18n.t("stat.range"), _fmt(float(a.range))]
	s += "%s: %s  ·  %s: %s\n" % [i18n.t("stat.attack"), i18n.t("attack." + a.type), i18n.t("stat.targets"), ", ".join(targets)]
	if a.splash != null:
		s += "%s: %s\n" % [i18n.t("stat.splash"), _fmt(float(a.splash[2]))]
	s += "%s: %dg%s  ·  %s: %d s\n" % [i18n.t("stat.cost"), int(def.cost.gold), (" + %d %s" % [int(def.cost.lumber), i18n.t("hud.lumber")]) if int(def.cost.lumber) > 0 else "", i18n.t("stat.build"), int(def.buildTime)]
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
	s += "\n%s: %d" % [i18n.t("stat.kills"), t.kills]
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
	if id == "__unlock":
		hud.toast(i18n.t("hud.choose_element"), Color("ffd45e"), 2.0)
		active_element = "__unlock"
		hud._bar_sig = ""
		return
	active_element = id
	_cancel()
	hud._bar_sig = ""


func _on_unlock(id: String) -> void:
	var r: Dictionary = sim.unlock_element(id)
	if r.ok:
		active_element = id
		hud.toast(i18n.t("msg.element_chosen", [i18n.n(data.element_of(id).name)]), Color("9fd6ff"))
		hud._bar_sig = ""
	else:
		hud.toast(i18n.t("msg." + String(r.reason)), Color("ff7a7a"))


func _on_tower_chosen(id: String) -> void:
	if build_id == id:
		_cancel()
		return
	build_id = id
	selected_id = 0
	world.select_tower(null)
	ghost_cell = Vector2i(-1, -1)
	path_text = ""
	world.hide_ghost()


func _cancel() -> void:
	build_id = ""
	ghost_cell = Vector2i(-1, -1)
	path_text = ""
	selected_id = 0
	world.hide_ghost()
	world.select_tower(null)


func _skip() -> void:
	var r: Dictionary = sim.next_wave_now()
	if not r.ok:
		hud.toast(i18n.t("msg.gold"), Color("ff7a7a"))


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


# ------------------------------------------------------------------ input

func _unhandled_input(event: InputEvent) -> void:
	if sim == null or menu_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_on_key(event.keycode)
	elif event is InputEventScreenTouch:
		if not touch_mode:
			touch_mode = true
			_apply_ui_scale()
		if event.pressed:
			touches[event.index] = event.position
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
				pressing = true
				dragging = false
				press_pos = event.position
			else:
				if pressing and not dragging and touches.size() < 2:
					_on_tap(event.position)
				pressing = false
		MOUSE_BUTTON_RIGHT:
			if event.pressed:
				right_down = true
				right_dragged = false
			else:
				if right_down and not right_dragged:
					_cancel()
				right_down = false
		MOUSE_BUTTON_MIDDLE:
			middle_down = event.pressed


func _on_mouse_motion(event: InputEventMouseMotion) -> void:
	if pressing:
		if not dragging and event.position.distance_to(press_pos) > 10.0:
			dragging = true
		if dragging and touches.size() < 2:
			world.pan_by_screen(event.relative)
	elif right_down or middle_down:
		right_dragged = true
		world.pan_by_screen(event.relative)
	elif build_id != "" and not touch_mode:
		_set_ghost(_cell_from_screen(event.position))


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
		KEY_HOME:
			_fit()


func _cell_from_screen(pos: Vector2) -> Vector2i:
	var tile = world.screen_to_tile(pos)
	if tile == null or build_id == "":
		return Vector2i(-1, -1)
	var def: Dictionary = data.towers[build_id]
	var cs: float = sim.grid.cell_size
	return Vector2i(int(round(tile.x / cs - float(def.footprint[0]) * 0.5)), int(round(tile.y / cs - float(def.footprint[1]) * 0.5)))


func _set_ghost(cell: Vector2i) -> void:
	if cell == ghost_cell and cell.x >= 0:
		return
	ghost_cell = cell
	if cell.x < 0 or build_id == "":
		world.hide_ghost()
		path_text = ""
		return
	_refresh_ghost()


func _refresh_ghost() -> void:
	var def: Dictionary = data.towers[build_id]
	var r: Dictionary = sim.can_place(build_id, ghost_cell.x, ghost_cell.y)
	ghost_ok = r.ok
	ghost_reason = String(r.get("reason", ""))
	world.show_ghost(def, ghost_cell.x, ghost_cell.y, ghost_ok or ghost_reason == "gold" or ghost_reason == "lumber")
	path_text = ""
	if r.ok or ghost_reason == "gold" or ghost_reason == "lumber":
		var starts := PackedInt32Array()
		for s in data.map.spawns:
			starts.append(sim.grid.idx(int(s.cell[0]), int(s.cell[1])))
		var before: float = sim.grid.path_length(starts)
		var after: float = sim.grid.path_length_with(ghost_cell.x, ghost_cell.y, int(def.footprint[0]), int(def.footprint[1]), starts)
		if after > 0.0 and before > 0.0:
			var pct := int(round((after / before - 1.0) * 100.0))
			path_text = i18n.t("hud.path", [_fmt(after), ("+%d%%" % pct) if pct >= 0 else ("%d%%" % pct)])


func _on_tap(pos: Vector2) -> void:
	if build_id != "":
		var cell := _cell_from_screen(pos)
		if cell.x < 0:
			return
		if touch_mode and cell != ghost_cell:
			_set_ghost(cell)
			return
		_set_ghost(cell)
		_try_place()
		return
	var tile = world.screen_to_tile(pos)
	var found = null
	if tile != null:
		for t in sim.towers.values():
			var half: float = float(t.def.footprint[0]) * sim.grid.cell_size * 0.5 + 0.1
			if absf(tile.x - t.center.x) <= half and absf(tile.y - t.center.y) <= half:
				found = t
				break
	selected_id = found.id if found != null else 0
	world.select_tower(found)


func _try_place() -> void:
	if build_id == "" or ghost_cell.x < 0:
		return
	var r: Dictionary = sim.place_tower(build_id, ghost_cell.x, ghost_cell.y)
	if r.ok:
		_refresh_ghost()
	else:
		hud.toast(i18n.t("msg." + String(r.reason)), REASON_COLORS.get(r.reason, Color("ff7a7a")), 1.6)


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
