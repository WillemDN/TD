extends RefCounted
## Checks for the game mode "elements" (fixed path, build plates, six elements, mixed towers, creep traits).
## Called from run_tests.gd with the runner as argument, so the check counters are shared.

const GameData := preload("res://core/game_data.gd")
const Sim := preload("res://core/sim.gd")
const BotElements := preload("res://tests/bot_elements.gd")
const Models := preload("res://client/models.gd")

var t   # the test runner


func run(runner) -> void:
	t = runner
	var data = GameData.load_all("res://data", "elements")
	data_is_complete(data)
	the_path_is_fixed(data)
	element_circle(data)
	unlocking(data)
	traits(data)
	economy_rules(data)
	a_bot_survives_the_first_levels(data)


func data_is_complete(data) -> void:
	t.check(data.mode == "elements", "mode elements loaded")
	t.check(data.elements.size() == 6, "six elements")
	t.check(data.towers.size() == 6 * 3 + 15 + 20, "18 single, 15 dual and 20 triple towers (%d)" % data.towers.size())
	t.check(data.waves.size() == 40 and data.creeps.size() == 40, "40 levels")
	t.check(int(data.rules.lastLevel) == 40, "the last level is 40")
	t.check(data.groups.dual.size() == 15 and data.groups.triple.size() == 20, "dual and triple groups")
	var ids: Dictionary = {}
	for id in data.towers:
		var d: Dictionary = data.towers[id]
		t.check(d.name.nl != "" and d.name.en != "", "tower %s has names" % id)
		t.check(not ids.has(d.name.en), "tower name %s is unique" % d.name.en)
		ids[d.name.en] = true
		t.check(data.matrix.has(d.attack.type), "tower %s has a matrix row" % id)
		for a in data.matrix[d.attack.type]:
			t.check(float(data.matrix[d.attack.type][a]) > 0.0, "tower %s multiplier against %s" % [id, a])
		for e in d.elements:
			t.check(not data.element_of(e).is_empty(), "tower %s element %s exists" % [id, e])
	for id in data.creeps:
		var c: Dictionary = data.creeps[id]
		t.check(data.element_of(c.armorType).is_empty() == false, "creep %s has an element" % id)
		t.check(Models.CREEP_ASSETS.has(c.model), "creep %s uses a known model (%s)" % [id, c.model])
		for tr in c.traits:
			t.check(tr in ["fast", "healing", "undead", "mechanical"], "creep %s trait %s is known" % [id, tr])
	# the same texts exist in both languages
	var I18n = preload("res://client/i18n.gd")
	var tr = I18n.new()
	for lang in ["nl", "en"]:
		tr.lang = lang
		for key in ["mode.elements", "mode.elements.desc", "group.dual", "group.triple", "trait.fast", "trait.healing", "trait.undead",
				"trait.mechanical", "msg.locked_level", "help.tip.elements", "menu.hint.elements", "fx.poison_plain"]:
			t.check(tr.t(key) != key, "%s has text in %s" % [key, lang])
		for e in data.elements:
			t.check(tr.t("armor." + e.id) != "armor." + e.id, "armor name for %s in %s" % [e.id, lang])


func the_path_is_fixed(data) -> void:
	var sim = Sim.new(data, 1, "normal", 1)
	var g = sim.grid
	var spawn: int = g.idx(int(data.map.spawns[0].cell[0]), int(data.map.spawns[0].cell[1]))
	var starts := PackedInt32Array([spawn])
	var length: float = g.path_length(starts)
	t.check(length > 100.0 and length < 180.0, "the serpentine path is long (%.0f tiles)" % length)
	# plates are never walkable, so no tower and no creep can change the path
	var plate := Vector2i(-1, -1)
	var path_cell := Vector2i(-1, -1)
	for y in g.h:
		for x in g.w:
			if g.flags[y * g.w + x] & g.PLATE and plate.x < 0:
				plate = Vector2i(x, y)
			if data.map.rows[y][x] == "," and path_cell.x < 0 and x > 20:
				path_cell = Vector2i(x, y)
	t.check(plate.x >= 0, "the map has build plates")
	t.check(not g.walkable(g.idx(plate.x, plate.y)), "a plate cannot be walked on")
	sim.unlock_element("fire")
	sim.gold = 100000
	t.check(sim.can_place("fire_1", plate.x, plate.y).ok, "a tower can stand on a plate")
	t.check(sim.can_place("fire_1", path_cell.x, path_cell.y).reason == "terrain", "no towers on the path")
	# fill every plate with towers: the route stays exactly the same
	var placed := 0
	for y in range(0, g.h - 1, 2):
		for x in range(0, g.w - 1, 2):
			if sim.place_tower("fire_1", x, y).ok:
				placed += 1
	t.check(placed > 300, "hundreds of towers fit on the plates (%d)" % placed)
	t.check(is_equal_approx(g.path_length(starts), length), "the path is the same with all plates built")
	# a creep walks the whole way and ends at the ship
	var sim2 = Sim.new(data, 1, "normal", 1)
	sim2.level = 1
	sim2._spawn_creep("e01", 0)
	var c = sim2.creeps.values()[0]
	var steps := 0
	while c.alive and steps < 20 * 200 and sim2.stats.leaks == 0:
		steps += 1
		sim2.tick()
		if steps % 40 == 0:
			t.check(not (sim2.grid.flags[sim2.grid.cell_of(c.pos)] & g.PLATE), "creep never on a plate")
	t.check(sim2.stats.leaks >= 1, "a creep that nobody stops reaches the ship (%d ticks)" % steps)
	t.check(sim2.lives == sim2.max_lives - 1, "and costs a life")


func element_circle(data) -> void:
	var sim = Sim.new(data, 1)
	# Light beats Darkness, Darkness beats Water, ... Earth beats Light; the previous one resists
	var order := ["light", "dark", "water", "fire", "nature", "earth"]
	for i in 6:
		var a: String = order[i]
		var b: String = order[(i + 1) % 6]
		var prev: String = order[(i + 5) % 6]
		t.check_close(sim.damage_multiplier(a + "_1", b, 0.0), 2.0, "%s hits %s double" % [a, b])
		t.check_close(sim.damage_multiplier(a + "_1", prev, 0.0), 0.5, "%s hits %s at half" % [a, prev])
		t.check_close(sim.damage_multiplier(a + "_1", a, 0.0), 1.0, "%s hits %s normally" % [a, a])
	# a mix averages: fire (x2 on nature, x0.5 on water) + earth (x2 on light, x0.5 on nature)
	t.check_close(sim.damage_multiplier("d_fire_earth", "nature", 0.0), 1.25, "fire+earth against nature")
	t.check_close(sim.damage_multiplier("d_fire_earth", "water", 0.0), 0.75, "fire+earth against water")
	t.check_close(sim.damage_multiplier("d_fire_earth", "light", 0.0), 1.5, "fire+earth against light")
	t.check_close(sim.damage_multiplier("t_fire_nature_earth", "dark", 0.0), 1.0, "three elements dilute: x1.0 against a neutral one")
	# the mix is a real trade: no mixed tower is weak or strong against everything
	for id in data.towers:
		var worst := 9.0
		var best := 0.0
		for e in order:
			var m: float = sim.damage_multiplier(id, e, 0.0)
			worst = minf(worst, m)
			best = maxf(best, m)
		t.check(worst >= 0.5 and best <= 2.0, "%s multipliers stay between 0.5 and 2" % id)


func unlocking(data) -> void:
	var sim = Sim.new(data, 1)
	sim.gold = 100000
	t.check(sim.lumber == 2, "two elements to choose at the start")
	var spot := Vector2i(10, 8)
	t.check(sim.place_tower("fire_1", spot.x, spot.y).reason == "locked", "an element has to be learned first")
	sim.unlock_element("fire")
	t.check(sim.place_tower("fire_1", spot.x, spot.y).ok, "learned element, tower can be built")
	t.check(sim.can_place("d_water_fire", spot.x + 2, spot.y).reason == "locked", "a dual tower needs both elements")
	sim.unlock_element("water")
	t.check(sim.lumber == 0, "both lumber spent")
	t.check(sim.can_place("d_water_fire", spot.x + 2, spot.y).reason == "locked_level", "dual towers come later in the game")
	t.check(sim.can_place("fire_2", spot.x + 2, spot.y).reason == "locked_level", "tier 2 comes later in the game")
	sim.cleared = int(data.towers.d_water_fire.unlockAfter)
	t.check(sim.can_place("d_water_fire", spot.x + 2, spot.y).ok, "a dual tower is available once enough levels are cleared")
	t.check(sim.can_place("t_water_fire_nature", spot.x + 4, spot.y).reason == "locked", "a triple tower needs three elements")
	# guardian levels give lumber for the next element
	t.check(data.rules.lumberAtLevel.has("5") and data.rules.lumberAtLevel.has("40"), "a new element every 5 levels")
	for l in data.waves:
		if int(l.level) % 5 == 0:
			t.check(data.creeps[l.creep].boss, "level %d is a guardian" % int(l.level))
			t.check(int(l.countPerSpawn) == 1, "a guardian comes alone")


func traits(data) -> void:
	# undead: stands up once, 5 s later, with a third of its life
	var sim = Sim.new(data, 1)
	sim.unlock_element("fire")
	sim.gold = 100000
	var undead_id := ""
	var healing_id := ""
	var mech_id := ""
	for id in data.creeps:
		var tr: Array = data.creeps[id].traits
		if "undead" in tr and undead_id == "":
			undead_id = id
		if "healing" in tr and healing_id == "":
			healing_id = id
		if "mechanical" in tr and mech_id == "":
			mech_id = id
	t.check(undead_id != "" and healing_id != "" and mech_id != "", "the waves contain undead, healing and mechanical creeps")
	sim.level = int(undead_id.substr(1))
	sim._spawn_creep(undead_id, 0)
	var c = sim.creeps.values()[0]
	var tower = null
	sim.place_tower("fire_1", 40, 8)
	tower = sim.towers.values()[0]
	sim._deal(c, c.max_hp * 2.0, "fire_1", tower, true)
	t.check(c.alive and c.revive_t > 0.0 and c.hp == 0.0, "an undead creep goes down instead of dying")
	t.check(sim.stats.kills == 0, "and does not count as a kill")
	var before: Vector2 = c.pos
	for i in 20 * 4:
		sim.tick()
	t.check(c.pos == before, "a downed creep does not move")
	t.check(sim._find_target(tower) == null or sim._find_target(tower) != c, "towers ignore a downed creep")
	sim._deal(c, 999.0, "fire_1", tower, true)
	t.check(c.hp == 0.0 and c.alive, "a downed creep cannot be hurt")
	for i in 20 * 2:
		sim.tick()
	t.check(c.revive_t == 0.0 and c.revived and absf(c.hp - c.max_hp * 0.33) < 1.0, "it stands up with 33% life")
	sim._deal(c, c.max_hp * 2.0, "fire_1", tower, true)
	t.check(not c.alive and sim.stats.kills == 1, "the second death is final")
	# healing: neighbours get 20% back when it dies
	var sim2 = Sim.new(data, 1)
	sim2.level = int(healing_id.substr(1))
	sim2._spawn_creep(healing_id, 0)
	sim2._spawn_creep(healing_id, 0)
	var a = sim2.creeps.values()[0]
	var b = sim2.creeps.values()[1]
	b.pos = a.pos + Vector2(1.0, 0.0)
	b.hp = b.max_hp * 0.5
	sim2._kill(a, null)
	t.check_close(b.hp / b.max_hp, 0.7, "a dying healer gives 20% life to neighbours", 0.001)
	# mechanical: invulnerable for 3 s of every 12 s
	var sim3 = Sim.new(data, 1)
	sim3.level = int(mech_id.substr(1))
	sim3._spawn_creep(mech_id, 0)
	var m = sim3.creeps.values()[0]
	var hp0: float = m.hp
	m.mech_t = 10.0
	sim3._deal(m, 50.0, "fire_1", null, true)
	t.check(m.hp == hp0, "a plated creep shrugs off damage during its shield")
	m.mech_t = 3.0
	sim3._deal(m, 50.0, "fire_1", null, true)
	t.check(m.hp == hp0 - 50.0, "and takes damage the rest of the time")
	# fast creeps are faster
	var fast_id := ""
	for id in data.creeps:
		if "fast" in data.creeps[id].traits:
			fast_id = id
			break
	t.check(fast_id != "" and float(data.creeps[fast_id].speed) > float(data.creeps["e01"].speed) * 1.2, "fast creeps run faster")


func economy_rules(data) -> void:
	var sim = Sim.new(data, 1)
	t.check(sim.gold == int(data.rules.startGold) and sim.max_lives == 40, "start gold and 40 lives")
	# difficulty also scales the life of the creeps
	var easy = Sim.new(data, 1, "easy", 1)
	var hard = Sim.new(data, 1, "hard", 1)
	easy.level = 1
	hard.level = 1
	easy._spawn_creep("e01", 0)
	hard._spawn_creep("e01", 0)
	t.check(easy.creeps.values()[0].max_hp < hard.creeps.values()[0].max_hp, "easy creeps have less life than hard ones")
	t.check_close(easy.creeps.values()[0].max_hp, float(data.creeps.e01.hp) * 0.7, "easy: 70% life")
	# interest: 2% of the gold every 15 s
	sim.gold = 1000
	for i in 20 * 15:
		sim.tick()
	t.check(sim.gold == 1020, "interest after 15 s: 2%% (%d)" % sim.gold)
	# a leaked creep comes back at the start and costs a life per lap
	var sim2 = Sim.new(data, 1)
	sim2.level = 1
	sim2._spawn_creep("e01", 0)
	var c = sim2.creeps.values()[0]
	c.pos = sim2.grid.cell_center(sim2.grid.goal_cells[0])
	sim2._leak(c)
	t.check(c.alive and sim2.lives == sim2.max_lives - 1, "a leaked creep respawns and costs a life")
	t.check(c.pos.x < 5.0, "it is back at the start")
	t.check(sim2.stats.kills == 0, "no gold for it")
	# the level only ends when every creep is dead, also the ones that came back
	t.check(sim2.creeps_remaining() >= 1, "the creep still counts for the level")
	# selling is free while nothing happens
	var sim3 = Sim.new(data, 1)
	sim3.unlock_element("fire")
	var r = sim3.place_tower("fire_1", 10, 8)
	var gold_after: int = sim3.gold
	sim3.sell_tower(r.id)
	t.check(sim3.gold == gold_after + int(data.towers.fire_1.cost.gold), "idle selling refunds in full")
	# a mixed tower costs more than its single parts
	t.check(int(data.towers.d_water_fire.cost.gold) > int(data.towers.fire_1.cost.gold) + int(data.towers.water_1.cost.gold), "a dual tower costs more than two singles")


func a_bot_survives_the_first_levels(data) -> void:
	var sim = Sim.new(data, 3, "normal", 1)
	var bot = BotElements.new(["fire", "water", "nature"])
	for i in 20 * 60 * 9:
		if i % 20 == 0:
			bot.step(sim)
		sim.tick()
		if sim.state == "won" or sim.state == "lost":
			break
	t.check(sim.state != "lost" and sim.level >= 6, "the bot gets through the first levels (level %d, lives %d)" % [sim.level, sim.lives])
	t.check(sim.elements.size() >= 2, "it learned its elements")
	print("elements bot: level %d, lives %d/%d, towers %d, gold %d" % [sim.level, sim.lives, sim.max_lives, sim.towers.size(), sim.gold])
