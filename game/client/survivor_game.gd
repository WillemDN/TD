extends Node
## The mode "survivor" in the client: owns the simulation, the 3D arena, the shop interface and turns taps into commands.
## main.gd creates it when the chosen mode is of kind "survivor" and stays in charge of the menu, pause sheet and end screen.

const Survivor := preload("res://core/survivor.gd")
const SurvivorView := preload("res://client/survivor_view.gd")
const SurvivorHud := preload("res://client/survivor_hud.gd")

var host                    # main.gd: menu, pause state, shared HUD (end screen), overlay
var data
var sim
var view
var shud
var speed := 1

var _acc := 0.0
var _end_shown := false
var _pinch_dist := 0.0
var _touches := {}
var _inset_y := 0.0


func setup(p_host, p_data, difficulty: String) -> void:
	host = p_host
	data = p_data
	sim = Survivor.new(data, int(Time.get_ticks_usec() % 1000000007), difficulty)
	sim.record_events = true
	view = SurvivorView.new()
	add_child(view)
	view.setup(sim, data)
	view.cam.make_current()
	view.set_shadows(not host.touch_mode)
	shud = SurvivorHud.new()
	var layer: Node = host.hud.get_parent()
	layer.add_child(shud)
	layer.move_child(shud, host.hud.get_index())      # under the menu, pause and end screens
	shud.setup(data, host.i18n)
	shud.buy_pressed.connect(_buy)
	shud.reroll_pressed.connect(_reroll)
	shud.clear_pressed.connect(_clear)
	shud.menu_pressed.connect(func(): host._open_pause_sheet())
	shud.pause_pressed.connect(func(): host.paused = not host.paused)
	shud.speed_pressed.connect(func(): speed = 2 if speed == 1 else (3 if speed == 2 else 1))
	host.overlay.sim = sim
	host.overlay.world = view
	call_deferred("_fit")
	get_viewport().size_changed.connect(_fit)


func _exit_tree() -> void:
	if shud != null and is_instance_valid(shud):
		shud.queue_free()
	if host != null and is_instance_valid(host) and host.overlay != null:
		host.overlay.sim = null
		host.overlay.world = null


func _fit() -> void:
	if view != null and shud != null:
		view.fit_camera(shud.get_insets())


func _blocked() -> bool:
	return host.menu_open or host.paused or host.hud.is_blocking()


func _process(delta: float) -> void:
	if sim == null:
		return
	var running: bool = not _blocked() and sim.state == "running"
	if running:
		_acc += delta * float(speed)
		var n := 0
		while _acc >= Survivor.DT and n < 8:
			sim.tick()
			_acc -= Survivor.DT
			n += 1
		if n == 8:
			_acc = 0.0
	var alpha: float = clampf(_acc / Survivor.DT, 0.0, 1.0) if running else 1.0
	view.update_view(alpha, delta)
	_handle_events()
	host.overlay.tick(delta)
	shud.update_state(sim, {"speed": speed, "paused": host.paused})
	shud.tick(delta)
	var inset_y: float = shud.get_insets().y
	if absf(inset_y - _inset_y) > 2.0:      # the shop changed its height (small screens): keep the tower in the free middle
		_inset_y = inset_y
		view.fit_camera(shud.get_insets(), true)
	if not _end_shown and sim.state != "running":
		_end_shown = true
		var i18n = host.i18n
		var won: bool = sim.state == "won"
		var stats_text: String = i18n.t("end.sv_stats", [shud._mmss(sim.time), sim.stats.kills, sim.weapons.size()])
		host.hud.show_end(won, sim.lost_reason, stats_text, i18n.t("end.sv_won" if won else "end.sv_lost"), "")


func _handle_events() -> void:
	var i18n = host.i18n
	var kill_gold := 0
	var kill_pos := Vector2.ZERO
	var kills := 0
	for e in sim.events:
		match e.type:
			"kill":
				kill_gold += int(e.gold)
				kill_pos += e.pos
				kills += 1
				view.add_kill_burst(e.pos, e.boss)
			"zap":
				host.overlay.add_zap(e.from, e.to)
			"shot":
				host.overlay.add_zap(e.from, Vector2.ZERO)
			"boom":
				view.add_ring(e.pos, float(e.radius), Color("ffb05a"), 0.35)
			"strike":
				view.add_strike(e.pos)
			"pulse":
				view.pulse(e.wid)
			"tower_hit":
				view.tower_hit()
			"revived":
				shud.toast(i18n.t("sv.revived"), Color("b8ffb0"), 3.0)
				view.add_ring(Vector2.ZERO, 6.0, Color("b8ffb0"), 0.6)
			"cleared":
				shud.toast(i18n.t("msg.sv_cleared"), UiKit.ACCENT, 1.8)
				view.add_ring(Vector2.ZERO, 14.0, Color("8fd8ff"), 0.6)
			"boss":
				shud.toast(i18n.t("sv.boss_warning"), Color("ff8a5c"), 3.0)
			"wagon":
				shud.toast(i18n.t("sv.wagon"), UiKit.GOLD, 2.6)
			"round":
				shud.toast(i18n.t("sv.round", [e.round]), UiKit.ACCENT, 1.4)
				shud.clear_selection()
	if kills > 0:
		host.overlay.add_text(kill_pos / float(kills), "+%d" % kill_gold, UiKit.GOLD, 16)
	sim.events.clear()


# ------------------------------------------------------------------ commands

func _buy(index: int) -> void:
	var r: Dictionary = sim.buy(index)
	var i18n = host.i18n
	if r.ok:
		var o: Dictionary = sim.offers[index]
		var def: Dictionary = data.weapons[o.id] if o.kind == "weapon" else data.upgrades[o.id]
		shud.toast(i18n.t("msg.sv_bought", [i18n.n(def.name)]), UiKit.GOOD, 1.4)
		shud.clear_selection()
	elif r.reason != "bought":
		var key := "msg.sv_gold" if r.reason == "gold" else ("msg.sv_full" if r.reason == "full" else "msg.sv_maxed")
		shud.toast(i18n.t(key), Color("ff7a7a"), 1.6)


func _reroll() -> void:
	var r: Dictionary = sim.reroll()
	if r.ok:
		shud.clear_selection()
	else:
		shud.toast(host.i18n.t("msg.sv_gold"), Color("ff7a7a"), 1.4)


func _clear() -> void:
	var r: Dictionary = sim.clear()
	if not r.ok and r.reason == "cooldown":
		shud.toast(host.i18n.t("msg.sv_cooldown", [int(ceil(sim.clear_cd))]), Color("ff7a7a"), 1.4)


# ------------------------------------------------------------------ input: zoom, keys

func _unhandled_input(event: InputEvent) -> void:
	if sim == null or _blocked():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
				var idx: int = event.keycode - KEY_1
				if idx < sim.offers.size():
					shud.select_card(idx)
			KEY_R:
				_reroll()
			KEY_SPACE:
				_clear()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			view.zoom_by(0.92)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			view.zoom_by(1.08)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		_pinch_dist = 0.0
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() >= 2:
			var pts: Array = _touches.values()
			var d: float = (pts[0] as Vector2).distance_to(pts[1])
			if _pinch_dist > 0.0 and d > 1.0:
				view.zoom_by(_pinch_dist / d)
			_pinch_dist = d
