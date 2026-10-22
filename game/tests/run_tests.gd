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
