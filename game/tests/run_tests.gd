extends SceneTree
## Headless tests. Run: godot --headless --path game --script res://tests/run_tests.gd
## Exit code 0 when everything passes.

const GameData := preload("res://core/game_data.gd")
const Sim := preload("res://core/sim.gd")
const Bot := preload("res://tests/bot.gd")

var failures := 0
var checks := 0


func _init() -> void:
	var data = GameData.load_all()
	test_data(data)
	test_damage(data)
	test_grid_and_placement(data)
	test_economy(data)
	test_effects(data)
	test_waves_scale(data)
	test_creeps_keep_clear(data)
	test_moving_towers(data)
	test_game_end_rules(data)
	test_i18n_complete(data)
	test_determinism(data)
	test_bot_plays(data)
	print("\n%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("FAIL: " + what)


func check_close(a: float, b: float, what: String, eps := 0.001) -> void:
	check(absf(a - b) <= eps, "%s (got %s, want %s)" % [what, a, b])


func test_data(data) -> void:
	check(data.towers.size() == 46, "46 towers (got %d)" % data.towers.size())
	check(data.elements.size() == 9, "9 elements")
	check(data.waves.size() == 35, "35 waves")
	check(data.creeps.size() == 35, "35 creeps")
	for id in data.towers:
		var t: Dictionary = data.towers[id]
		check(t.name.nl != "" and t.name.en != "", "tower %s has NL and EN names" % id)
		check(data.matrix.has(t.attack.type), "tower %s attack type %s is in the matrix" % [id, t.attack.type])
		check(float(t.attack.cooldown) > 0.0 and float(t.attack.range) > 0.0, "tower %s has cooldown and range" % id)
	for id in data.creeps:
		var c: Dictionary = data.creeps[id]
		check(data.matrix["normal"].has(c.armorType), "creep %s armor type %s is in the matrix" % [id, c.armorType])
		check(c.name.nl != "" and c.name.en != "", "creep %s has names" % id)
	for e in data.elements:
		for tid in e.towers:
			check(data.towers.has(tid), "element %s lists known tower %s" % [e.id, tid])


func test_damage(data) -> void:
	var sim = Sim.new(data, 1)
	check_close(sim.armor_reduction(10.0), 0.375, "10 armor reduces 37.5%")
	check_close(sim.armor_reduction(20.0), 0.5454545, "20 armor reduces 54.5%", 0.0001)
	check_close(sim.armor_reduction(0.0), 0.0, "0 armor reduces nothing")
	check(sim.armor_reduction(-5.0) < 0.0, "negative armor amplifies damage")
	check_close(sim.damage_multiplier("pierce", "small", 0.0), 2.0, "pierce vs small is 200%")
	check_close(sim.damage_multiplier("chaos", "divine", 0.0), 1.0, "chaos ignores divine")


func test_grid_and_placement(data) -> void:
	var sim = Sim.new(data, 1)
	sim.unlock_element("ice")
	sim.gold = 100000
	# not on walls / non-buildable ground
	check(sim.can_place("frost_shard", 0, 0).reason == "terrain", "walls are not buildable")
	check(sim.can_place("frost_shard", 3, 5).reason == "terrain", "the spawn zone is not buildable")
	# a valid spot in the first lane field
	var r = sim.place_tower("frost_shard", 20, 8)
	check(r.ok, "placing on open ground works")
	check(sim.can_place("frost_shard", 20, 8).reason == "occupied", "cannot stack towers")
	check(sim.can_place("frost_shard", 21, 9).reason == "occupied", "overlapping footprints are rejected")
	check(sim.can_place("frost_shard", 22, 8).ok, "adjacent footprints are fine")
	# the anti-block rule: wall off the whole lane height except the last gap, then close it
	var sim2 = Sim.new(data, 1)
	sim2.unlock_element("ice")
	sim2.gold = 100000
	var first_row := 4
	var last_row := 17
	var placed := 0
	var y := first_row
	while y + 1 <= last_row:
		var res = sim2.place_tower("frost_shard", 30, y)
		if res.ok:
			placed += 1
		y += 2
	check(placed >= 6, "a near complete wall can be built (%d placed)" % placed)
	var blocked_any := false
	for yy in range(first_row, last_row):
		var res2 = sim2.can_place("frost_shard", 30, yy)
		if res2.reason == "blocks_path":
			blocked_any = true
	check(blocked_any, "closing the last gap is refused as blocks_path")
	# the path still exists after all that
	var starts := PackedInt32Array()
	for s in data.map.spawns:
		starts.append(sim2.grid.idx(int(s.cell[0]), int(s.cell[1])))
	check(sim2.grid.path_length(starts) > 0.0, "every spawn still reaches the ship")
	# selling restores the ground
	var ids: Array = sim2.towers.keys()
	for id in ids:
		sim2.sell_tower(id)
	check(sim2.can_place("frost_shard", 30, 8).ok, "ground is free again after selling")


func test_economy(data) -> void:
	var nine = Sim.new(data, 1, "normal", 9)
	check(nine.gold == 30 and nine.lumber == 1 and nine.lives == 20, "nine players start with 30 gold, 1 lumber, 20 lives")
	var sim = Sim.new(data, 1, "normal", 9)
	check(sim.place_tower("frost_shard", 20, 8).reason == "locked", "needs an element first")
	check(sim.unlock_element("ice").ok, "the first element costs the starting lumber")
	check(sim.lumber == 0, "lumber was spent")
	check(not sim.unlock_element("fire").ok, "a second element needs lumber")
	var r = sim.place_tower("frost_shard", 20, 8)
	check(r.ok and sim.gold == 20, "a 10 gold tower costs 10")
	var t = sim.towers[r.id]
	check(sim.sell_value(t) == 10, "selling a tower under construction refunds fully")
	sim.sell_tower(r.id)
	check(sim.gold == 30, "gold is back after selling")
	# lumber for the ultimate tower
	sim.gold = 5000
	check(not sim.place_tower("aurora_cannon", 20, 8).ok, "the ultimate needs lumber")
	sim.lumber = 1
	check(sim.place_tower("aurora_cannon", 20, 8).ok, "the ultimate costs 1 lumber")
	check(sim.lumber == 0 and sim.gold == 4250, "750 gold and 1 lumber spent")
	# skipping the countdown pays a bonus
	var sim2 = Sim.new(data, 1)
	check(sim2.gold == 90, "a solo player starts with the boosted 90 gold")
	var before = sim2.gold
	sim2.next_wave_now()
	check(sim2.gold == before + 12, "skipping 60 s pays 12 gold")
	sim2.tick()
	check(sim2.state == "active" and sim2.level == 1, "wave 1 starts")


func make_target(sim, creep_id: String, pos: Vector2):
	var c = Sim.Creep.new()
	c.id = sim._take_id()
	c.def = sim.data.creeps[creep_id]
	c.level = 1
	c.max_hp = float(c.def.hp)
	c.hp = c.max_hp
	c.air = bool(c.def.air)
	c.boss = bool(c.def.boss)
	c.armor = float(c.def.armor)
	c.armor_type = c.def.armorType
	c.speed = float(c.def.speed)
	c.pos = pos
	c.prev = pos
	sim.creeps[c.id] = c
	return c


func build_and_finish(sim, tower_id: String, cx: int, cy: int):
	sim.gold = 100000
	sim.lumber = 2
	var r = sim.place_tower(tower_id, cx, cy)
	var t = sim.towers[r.id]
	t.building = false
	t.cooldown = 0
	return t


func test_effects(data) -> void:
	# slow
	var sim = Sim.new(data, 1)
	sim.unlock_element("ice")
	var t = build_and_finish(sim, "frost_shard", 20, 8)
	var c = make_target(sim, "frost_tinker", t.center + Vector2(2, 0))
	sim._impact(t, c, 6.0)
	check_close(c.slow_amt, 0.25, "frost shard slows by 25%")
	# crit multiplies the hit: force the chance to 1 and compare with the same tower without crit
	var sim2 = Sim.new(data, 5)
	sim2.unlock_element("stone")
	var t2 = build_and_finish(sim2, "pebble_slinger", 20, 8)
	var big = make_target(sim2, "ice_king", t2.center + Vector2(2, 0))
	big.max_hp = 1.0e9
	big.hp = 1.0e9
	for e in t2.def.effects:
		if e.kind == "crit":
			e.chance = 1.0
	var d0 = big.hp
	sim2._fire(t2, big)
	var shot = sim2.projectiles[0]
	check(shot.damage >= 20.0, "a guaranteed crit at least doubles the minimum hit (%s)" % shot.damage)
	for e in t2.def.effects:
		if e.kind == "crit":
			e.chance = 0.2
	# percent hp and boss immunity
	var sim3 = Sim.new(data, 1)
	sim3.unlock_element("electric")
	var t3 = build_and_finish(sim3, "lightning_rod", 20, 8)
	var normal = make_target(sim3, "rime_runner", t3.center + Vector2(1, 0))
	normal.hp = 1000.0
	normal.max_hp = 1000.0
	sim3._impact(t3, normal, 1.0)
	check(normal.hp < 800.0, "lightning rod removes a quarter of the current hp")
	var boss = make_target(sim3, "frost_marshal", t3.center + Vector2(1, 0))
	var before_hp = boss.hp
	sim3._impact(t3, boss, 1.0)
	check(before_hp - boss.hp < 5.0, "bosses are immune to percent hp damage")
	# chain hits several targets
	var sim4 = Sim.new(data, 1)
	sim4.unlock_element("electric")
	var t4 = build_and_finish(sim4, "storm_coil", 20, 8)
	var group: Array = []
	for i in 4:
		group.append(make_target(sim4, "frost_tinker", t4.center + Vector2(1.0 + 0.5 * i, 0)))
	sim4._impact(t4, group[0], 30.0)
	var hurt := 0
	for g in group:
		if g.hp < g.max_hp:
			hurt += 1
	check(hurt == 4, "storm coil chains to 3 extra targets (%d hurt)" % hurt)
	# ground only towers ignore air
	var sim5 = Sim.new(data, 1)
	sim5.unlock_element("tech")
	var t5 = build_and_finish(sim5, "rocket_rack", 20, 8)
	var air = make_target(sim5, "frost_whelp", t5.center + Vector2(3, 0))
	check(sim5._find_target(t5) == null, "ground-only towers do not target air")
	var ground = make_target(sim5, "frost_tinker", t5.center + Vector2(3, 0))
	check(sim5._find_target(t5) == ground, "ground-only towers target ground")


func test_waves_scale(data) -> void:
	var sim = Sim.new(data, 1, "normal", 1)
	check(sim.wave_total(data.waves[0]) == 13, "solo wave 1 has 13 creeps (got %d)" % sim.wave_total(data.waves[0]))
	check(sim.wave_total(data.waves[9]) == 1, "solo boss wave has 1 boss")
	var sim9 = Sim.new(data, 1, "normal", 9)
	check(sim9.wave_total(data.waves[0]) == 120, "nine players get the original 120 creeps")
	check(sim9.wave_total(data.waves[9]) == 6, "nine players get 6 bosses")


func test_creeps_keep_clear(data) -> void:
	# a tower on the straight route: the path around it must keep at least two cells away from it
	var sim = Sim.new(data, 1)
	sim.unlock_element("ice")
	var r = sim.place_tower("frost_shard", 30, 6)
	check(r.ok, "tower placed on the lane route")
	var cur: int = sim.grid.idx(int(data.map.spawns[0].cell[0]), int(data.map.spawns[0].cell[1]))
	var closest := 99
	var guard := 0
	while cur >= 0 and guard < 4000:
		guard += 1
		var x: int = cur % sim.grid.w
		var y: int = cur / sim.grid.w
		if x >= 24 and x <= 38:
			var dx: int = maxi(maxi(30 - x, x - 31), 0)
			var dy: int = maxi(maxi(6 - y, y - 7), 0)
			closest = mini(closest, maxi(dx, dy))
		cur = sim.grid.next_cell[cur]
	check(closest >= 2, "creeps keep two cells from a tower when there is room (closest %d)" % closest)
	var starts := PackedInt32Array()
	for s in data.map.spawns:
		starts.append(sim.grid.idx(int(s.cell[0]), int(s.cell[1])))
	var len_open: float = Sim.new(data, 1).grid.path_length(starts)
	var len_tower: float = sim.grid.path_length(starts)
	check(len_tower >= len_open and len_tower < len_open + 2.0, "the reported path length is the walked length (%s vs %s)" % [len_tower, len_open])


func test_moving_towers(data) -> void:
	var sim = Sim.new(data, 1)
	sim.unlock_element("ice")
	var r = sim.place_tower("frost_shard", 60, 30)
	var t = sim.towers[r.id]
	t.building = false
	var gold = sim.gold
	check(sim.can_move(r.id, 60, 30).reason == "same", "moving to the same cell is refused")
	check(sim.can_move(r.id, 61, 30).ok, "a tower may move onto its own old cells")
	check(sim.can_move(r.id, 0, 0).reason == "terrain", "cannot move onto a wall")
	var rev = sim.grid_revision
	var m = sim.move_tower(r.id, 70, 24)
	check(m.ok and t.cx == 70 and t.cy == 24, "the tower moved")
	check(sim.gold == gold, "moving costs no gold")
	check(t.building and t.build_left < t.build_total + 0.001 and t.build_left >= 1.5, "a moved tower is set up again")
	check(sim.grid_revision == rev + 1, "moving updates the path revision")
	check(sim.grid.footprint_problem(60, 30, 2, 2) == "", "the old spot is free again")
	check(sim.grid.footprint_problem(70, 24, 2, 2) == "occupied", "the new spot is occupied")
	check(t.moves == 1, "moves are counted")
	# a move that would block the path is refused
	var sim2 = Sim.new(data, 1)
	sim2.unlock_element("ice")
	sim2.gold = 100000
	var y := 4
	var last = -1
	while y + 1 <= 17:
		var rr = sim2.place_tower("frost_shard", 30, y)
		if rr.ok:
			last = rr.id
		y += 2
	var spare = sim2.place_tower("frost_shard", 40, 6)
	var blocked := false
	for yy in range(4, 17):
		if sim2.can_move(spare.id, 30, yy).reason == "blocks_path":
			blocked = true
	check(blocked, "moving a tower into the last gap is refused")


func test_game_end_rules(data) -> void:
	# a leak costs a life and lives at zero lose the game
	var sim = Sim.new(data, 1, "hard", 1)
	sim.level = 1
	sim.state = "active"
	var c = make_target(sim, "snow_scout", Vector2(1, 1))
	sim._leak(c)
	check(sim.lives == 9 and sim.stats.leaks == 1, "a leak costs one life")
	for i in 9:
		sim._leak(make_target(sim, "snow_scout", Vector2(1, 1)))
	check(sim.state == "lost" and sim.lost_reason == "lives", "no lives left means defeat")
	# one life on perfection
	var perf = Sim.new(data, 1, "perfection", 1)
	check(perf.lives == 1, "perfection has one life")
	# bonus levels do not cost lives
	var bonus = Sim.new(data, 1)
	bonus.level = 31
	bonus.state = "active"
	var b = make_target(bonus, "yeti_scout", Vector2(1, 1))
	b.level = 31
	bonus._leak(b)
	check(bonus.lives == 20, "bonus levels cost no lives")
	# the level 30 boss reaching the ship is an instant defeat
	var boss = Sim.new(data, 1)
	boss.level = 30
	boss.state = "active"
	var k = make_target(boss, "ice_king", Vector2(1, 1))
	k.level = 30
	boss._leak(k)
	check(boss.state == "lost" and boss.lost_reason == "boss", "the final boss at the ship loses at once")
	# clearing a wave pays the level bonus and starts the countdown
	var clear = Sim.new(data, 1, "normal", 9)
	clear.level = 4
	clear.state = "active"
	var before = clear.gold
	clear._check_wave_end()
	check(clear.gold == before + 20 and clear.state == "countdown" and clear.countdown == 30.0, "level 4 pays 12+2*4 gold and waits 30 s")
	# lumber after level 15
	var lum = Sim.new(data, 1, "normal", 9)
	lum.level = 15
	lum.state = "active"
	var l0 = lum.lumber
	lum._check_wave_end()
	check(lum.lumber == l0 + 1, "level 15 grants one lumber")
	# the last level ends in victory
	var win = Sim.new(data, 1)
	win.level = 35
	win.state = "active"
	win._check_wave_end()
	check(win.state == "won", "clearing level 35 wins")
	# bounty is paid per kill
	var pay = Sim.new(data, 1, "normal", 9)
	pay.unlock_element("fire")
	var g0 = pay.gold
	var victim = make_target(pay, "frost_tinker", Vector2(1, 1))
	pay._deal(victim, 1000.0, "chaos", null, true)
	check(pay.gold == g0 + 1 and pay.stats.kills == 1, "a kill pays its bounty")


func test_i18n_complete(data) -> void:
	var I18n = preload("res://client/i18n.gd")
	var tr = I18n.new()
	for key in ["hud.gold", "msg.blocks_path", "end.won", "fx.slow", "attack.chaos", "armor.divine"]:
		tr.lang = "nl"
		var nl = tr.t(key)
		tr.lang = "en"
		var en = tr.t(key)
		check(nl != key and en != key, "key %s exists in nl and en" % key)
	for e in data.towers.values():
		for k in e.effects:
			tr.lang = "en"
			check(tr.t("fx." + k.kind) != "fx." + k.kind, "effect %s has a text" % k.kind)
	tr.lang = "en"
	for at in data.matrix:
		check(tr.t("attack." + at) != "attack." + at, "attack type %s has a name" % at)
	for ar in data.matrix["normal"]:
		check(tr.t("armor." + ar) != "armor." + ar, "armor type %s has a name" % ar)


func run_bot(data, seed_value: int, element: String, max_ticks: int):
	var sim = Sim.new(data, seed_value)
	var bot = Bot.new(element)
	for i in max_ticks:
		if i % 20 == 0:
			bot.step(sim)
		sim.tick()
		if sim.state == "won" or sim.state == "lost":
			break
	return sim


func test_determinism(data) -> void:
	var a = run_bot(data, 42, "ice", 20 * 60 * 6)
	var b = run_bot(data, 42, "ice", 20 * 60 * 6)
	check(a.state_hash() == b.state_hash(), "same seed gives the same result")
	check(a.tick_count == b.tick_count and a.gold == b.gold and a.lives == b.lives, "same seed, same economy")


func test_bot_plays(data) -> void:
	var sim = run_bot(data, 7, "fire", 20 * 60 * 12)
	check(sim.level >= 3, "a simple bot reaches at least level 3 (level %d)" % sim.level)
	print("bot: level %d, lives %d, kills %d, towers %d, state %s" % [sim.level, sim.lives, sim.stats.kills, sim.towers.size(), sim.state])
