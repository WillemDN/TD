extends RefCounted
## Checks for the game mode "survivor" (Last Tower). Called from run_tests.gd with the runner as argument.

const GameData := preload("res://core/game_data.gd")
const Survivor := preload("res://core/survivor.gd")
const BotSurvivor := preload("res://tests/bot_survivor.gd")
const Models := preload("res://client/models.gd")

var t


func run(runner) -> void:
	t = runner
	var data = GameData.load_all("res://data", "survivor")
	data_is_complete(data)
	shop(data)
	upgrades(data)
	every_weapon_works(data)
	enemies_and_tower(data)
	ending_rules(data)
	determinism_and_bot(data)


func data_is_complete(data) -> void:
	t.check(data.kind == "survivor" and data.mode == "survivor", "mode survivor loaded")
	t.check(data.weapons.size() >= 20 and data.upgrades.size() >= 20, "weapons and upgrades (%d, %d)" % [data.weapons.size(), data.upgrades.size()])
	for id in data.weapons:
		var w: Dictionary = data.weapons[id]
		t.check(w.name.nl != "" and w.name.en != "", "weapon %s has names" % id)
		t.check(w.kind in ["projectile", "orbit", "aura", "artillery", "chain", "mine", "glaive", "strike"], "weapon %s kind %s is known" % [id, w.kind])
		t.check(int(w.rarity) >= 0 and int(w.rarity) < data.rarities.size(), "weapon %s rarity" % id)
		t.check(float(w.damage) > 0.0 and float(w.cooldown) > 0.0 and float(w.cost) > 0.0, "weapon %s has numbers" % id)
	for id in data.upgrades:
		var u: Dictionary = data.upgrades[id]
		t.check(u.name.nl != "" and u.desc.en != "" and u.desc.nl != "", "upgrade %s has names and texts" % id)
		t.check(not u.stat.is_empty() and int(u.max) >= 1, "upgrade %s has a stat" % id)
	for r in 4:
		var wn := 0
		var un := 0
		for w in data.weapons.values():
			if int(w.rarity) == r:
				wn += 1
		for u in data.upgrades.values():
			if int(u.rarity) == r:
				un += 1
		t.check(wn >= 3 and un >= 4, "rarity %d has enough weapons (%d) and upgrades (%d)" % [r, wn, un])
	for id in data.enemies:
		var e: Dictionary = data.enemies[id]
		t.check(e.name.nl != "" and e.name.en != "", "enemy %s has names" % id)
		t.check(Models.CREEP_ASSETS.has(e.model), "enemy %s uses a known model (%s)" % [id, e.model])
	t.check(data.weapons.has(String(data.rules.starterWeapon)), "the starter weapon exists")
	var I18n = preload("res://client/i18n.gd")
	var tr = I18n.new()
	for lang in ["nl", "en"]:
		tr.lang = lang
		for key in ["mode.survivor", "mode.survivor.desc", "menu.hint.survivor", "help.tip.survivor", "sv.round", "sv.reroll", "sv.clear",
				"rarity.common", "rarity.epic", "wk.projectile", "wk.orbit", "wk.aura", "wk.artillery", "wk.chain", "wk.mine", "wk.glaive",
				"wk.strike", "msg.sv_gold", "end.sv_won", "end.sv_lost", "end.sv_stats", "menu.strength"]:
			t.check(tr.t(key) != key, "%s has text in %s" % [key, lang])


func shop(data) -> void:
	var sim = Survivor.new(data, 5)
	t.check(sim.gold == int(data.rules.startGold), "start gold")
	t.check(sim.weapons.size() == 1 and sim.weapons.has("knives"), "you start with the starter weapon")
	t.check(sim.offers.size() == int(data.rules.shopSlots), "the shop has %d offers" % int(data.rules.shopSlots))
	var seen := {}
	for o in sim.offers:
		t.check(not seen.has(o.kind + o.id), "offers are unique")
		seen[o.kind + o.id] = true
	# buy a weapon
	sim.gold = 100000
	var wi := -1
	for i in sim.offers.size():
		if sim.offers[i].kind == "weapon" and sim.offers[i].id != "knives":
			wi = i
	if wi < 0:
		sim.offers[0] = {"kind": "weapon", "id": "crossbow", "bought": false}
		wi = 0
	var wid: String = sim.offers[wi].id
	var cost: int = sim.offer_cost(sim.offers[wi])
	var before: int = sim.gold
	t.check(sim.buy(wi).ok, "buying a weapon works")
	t.check(sim.gold == before - cost and sim.weapons.has(wid), "it costs its price and you own it")
	t.check(sim.buy(wi).reason == "bought", "one offer is bought once")
	# the same weapon again makes it stronger but also pricier
	sim.offers[wi] = {"kind": "weapon", "id": wid, "bought": false}
	var c2: int = sim.offer_cost(sim.offers[wi])
	t.check(c2 > cost, "a second copy costs more (%d > %d)" % [c2, cost])
	var d1: float = sim.weapon_damage(wid)
	t.check(sim.buy(wi).ok and int(sim.weapons[wid].level) == 2, "a duplicate levels the weapon up")
	t.check(sim.weapon_damage(wid) > d1 * 1.3, "level 2 hits harder")
	# weapon slots
	var ids: Array = []
	for id in data.weapons:
		ids.append(id)
	var s2 = Survivor.new(data, 5)
	s2.gold = 1000000
	for id in ids:
		if s2.weapons.size() >= int(data.rules.maxWeapons):
			break
		s2.offers[0] = {"kind": "weapon", "id": id, "bought": false}
		s2.buy(0)
	t.check(s2.weapons.size() == int(data.rules.maxWeapons), "weapon slots fill up")
	var extra := ""
	for id in ids:
		if not s2.weapons.has(id):
			extra = id
			break
	s2.offers[1] = {"kind": "weapon", "id": extra, "bought": false}
	t.check(s2.buy(1).reason == "full", "a seventh weapon is refused")
	var owned: String = s2.weapons.keys()[1]
	s2.weapons[owned].level = int(data.rules.maxWeaponLevel)
	s2.offers[2] = {"kind": "weapon", "id": owned, "bought": false}
	t.check(s2.buy(2).reason == "maxed", "a maxed weapon is refused")
	# not enough gold
	var s3 = Survivor.new(data, 5)
	s3.gold = 1
	t.check(s3.buy(0).reason == "gold", "too little gold")
	# rerolling costs more every time and starts over every round
	var s4 = Survivor.new(data, 5)
	s4.gold = 1000
	var c_first: int = s4.reroll_cost()
	t.check(s4.reroll().ok and s4.gold == 1000 - c_first, "a reroll costs gold")
	t.check(s4.reroll_cost() == c_first + int(data.rules.rerollStep), "and the next one costs more")
	for i in int(20 * float(data.rules.roundSeconds)) + 2:
		s4.tick()
	t.check(s4.reroll_cost() == c_first and s4.round_no == 2, "a new round starts: new shop, reroll price back")
	t.check(s4.offers.size() == int(data.rules.shopSlots), "and the shop is full again")
	# the shop gets richer over time
	var s5 = Survivor.new(data, 5)
	s5.time = 13.0 * 60.0
	var rare := 0
	for i in 40:
		s5._roll_offers()
		for o in s5.offers:
			if int(s5._item(o).rarity) >= 2:
				rare += 1
	var s6 = Survivor.new(data, 5)
	var rare_early := 0
	for i in 40:
		s6._roll_offers()
		for o in s6.offers:
			if int(s6._item(o).rarity) >= 2:
				rare_early += 1
	t.check(rare > rare_early * 3, "late shops hold many more rare items (%d vs %d)" % [rare, rare_early])


func _give(sim, upgrade_id: String, n := 1) -> void:
	for i in n:
		sim.upgrades[upgrade_id] = int(sim.upgrades.get(upgrade_id, 0)) + 1
	sim._recalc()


func upgrades(data) -> void:
	var sim = Survivor.new(data, 1)
	var hp0: float = sim.tower_max
	_give(sim, "heartymeal")
	t.check(sim.tower_max == hp0 + 80.0, "Hearty Meal: +80 life")
	_give(sim, "ironskin", 2)
	t.check_close(sim.stat.armor, float(data.rules.tower.armor) + 4.0, "armor stacks")
	_give(sim, "purse")
	t.check_close(sim.stat.income, float(data.rules.baseIncome) + 1.0, "income stacks")
	_give(sim, "whetstone", 2)
	t.check_close(sim.stat.dmg, 1.2, "damage stacks")
	var d0: float = sim.weapon_damage("knives")
	_give(sim, "whetstone")
	t.check(sim.weapon_damage("knives") > d0, "damage upgrades raise weapon damage")
	# income pays out
	var s2 = Survivor.new(data, 1)
	var g0: int = s2.gold
	for i in 20 * 10:
		s2.tick()
	t.check(s2.gold >= g0 + int(10.0 * float(data.rules.baseIncome)) - 1, "base income pays gold (%d)" % (s2.gold - g0))
	# damage to the tower: armor and block
	var s3 = Survivor.new(data, 1)
	var e = _spawn(s3, "walker", Vector2(1.0, 0.0))
	var hp1: float = s3.tower_hp
	s3._hit_tower(20.0, e)
	var lost1: float = hp1 - s3.tower_hp
	t.check(lost1 > 15.0 and lost1 < 20.0, "armor reduces a hit a little (%.1f)" % lost1)
	_give(s3, "buckler", 5)
	var hp2: float = s3.tower_hp
	s3._hit_tower(20.0, e)
	t.check(hp2 - s3.tower_hp < lost1 * 0.7, "block reduces hits")
	var hp3: float = s3.tower_hp
	s3._hit_tower(1.0, e)
	t.check(hp3 - s3.tower_hp > 0.5, "a hit always does at least a little damage")
	# thorns
	var s4 = Survivor.new(data, 1)
	_give(s4, "thornsmail", 2)
	var e4 = _spawn(s4, "raider", Vector2(1.0, 0.0))
	var ehp: float = e4.hp
	s4._hit_tower(10.0, e4)
	t.check(e4.hp < ehp, "thorns hurt the attacker")
	# phoenix: saves the tower, then rests
	var s5 = Survivor.new(data, 1)
	_give(s5, "phoenix")
	s5.tower_hp = 5.0
	s5._hit_tower(500.0, null)
	t.check(s5.state == "running" and s5.tower_hp == s5.tower_max, "Phoenix Claw saves the tower")
	s5.invuln_t = 0.0
	s5.tower_hp = 5.0
	s5._hit_tower(500.0, null)
	t.check(s5.state == "lost", "but not twice in a row")
	# ankh: once
	var s6 = Survivor.new(data, 1)
	_give(s6, "ankh")
	s6.tower_hp = 5.0
	s6._hit_tower(500.0, null)
	t.check(s6.state == "running", "Ankh saves the tower once")
	s6.invuln_t = 0.0
	s6.tower_hp = 5.0
	s6._hit_tower(500.0, null)
	t.check(s6.state == "lost", "and only once")
	# the shield returns after a quiet moment
	var s7 = Survivor.new(data, 1)
	_give(s7, "energyshield")
	t.check(s7.stat.shield == 150.0, "shield size")
	s7.shield = 150.0
	s7._hit_tower(100.0, null)
	t.check(s7.shield < 150.0, "the shield takes hits first")
	var hp7: float = s7.tower_hp
	for i in 20 * 12:
		s7.tick()
	t.check(s7.shield > 100.0, "the shield comes back")
	# unique upgrades cannot be bought twice
	var s8 = Survivor.new(data, 1)
	s8.gold = 100000
	s8.offers[0] = {"kind": "upgrade", "id": "phoenix", "bought": false}
	t.check(s8.buy(0).ok, "buy Phoenix Claw")
	s8.offers[1] = {"kind": "upgrade", "id": "phoenix", "bought": false}
	t.check(s8.buy(1).reason == "maxed", "Phoenix Claw is unique")


func _spawn(sim, id: String, pos: Vector2):
	sim._spawn_enemy(sim.data.enemies[id], pos)
	var e = sim.enemies[sim.enemies.keys()[sim.enemies.size() - 1]]
	e.atk_t = 100.0
	return e


func every_weapon_works(data) -> void:
	for id in data.weapons:
		var sim = Survivor.new(data, 3)
		sim.weapons.clear()
		sim.weapons[id] = {"level": 1, "cd": 0.0, "angle": 0.0}
		sim._recalc()
		var w: Dictionary = data.weapons[id]
		# a ring of slow targets around the tower at a distance the weapon can reach
		var r: float = minf(float(w.range) * 0.7, 5.0) if w.kind != "orbit" else float(w.range)
		for i in 10:
			var e = _spawn(sim, "raider", Vector2.from_angle(TAU * float(i) / 10.0) * (r + 0.3 * float(i % 3)))
			e.speed = 0.01
			e.hp = 1000000.0
			e.max_hp = 1000000.0
			e.stop = 0.0
		var before := 0.0
		for i in 20 * 8:
			sim.tick()
		t.check(sim.stats.damage > 0.0, "weapon %s deals damage (%.0f)" % [id, sim.stats.damage])
		if w.kind == "orbit":
			t.check(sim.blades.size() >= int(w.blades), "orbit weapon %s has its blades" % id)
	# magic ignores armor, physical does not
	var s = Survivor.new(data, 1)
	var e1 = _spawn(s, "golem", Vector2(5, 0))
	var hp: float = e1.hp
	s._hurt(e1, 100.0, "phys")
	var phys: float = hp - e1.hp
	hp = e1.hp
	s._hurt(e1, 100.0, "magic")
	var magic: float = hp - e1.hp
	t.check(magic == 100.0 and phys < 100.0, "armor reduces physical damage only (%.0f vs %.0f)" % [phys, magic])
	# levels make weapons faster and stronger
	var s2 = Survivor.new(data, 1)
	var i0: float = s2.weapon_interval("knives")
	s2.weapons.knives.level = 3
	t.check(s2.weapon_interval("knives") < i0 and s2.weapon_damage("knives") > 1.7 * data.weapons.knives.damage, "weapon levels help")
	# critical hits
	var s3 = Survivor.new(data, 1)
	s3.stat.crit = 1.0
	t.check_close(s3._roll(10.0), 10.0 * float(data.rules.tower.critMult), "a certain crit multiplies the damage")


func enemies_and_tower(data) -> void:
	var sim = Survivor.new(data, 2)
	sim.weapons.clear()
	sim._recalc()
	var e = _spawn(sim, "walker", Vector2(10.0, 0.0))
	e.atk_t = 0.0
	var d0: float = e.pos.length()
	for i in 20:
		sim.tick()
	t.check(e.pos.length() < d0 - 1.0, "enemies walk to the tower")
	var hp0: float = sim.tower_hp
	for i in 20 * 12:
		sim.tick()
	var near := 0
	for x in sim.enemies.values():
		if x.pos.length() < 3.0:
			near += 1
	t.check(sim.tower_hp < hp0 + 1.0 and near >= 1, "they reach it and attack (%d near)" % near)
	# ranged enemies stop at a distance
	var s2 = Survivor.new(data, 2)
	s2.weapons.clear()
	var a = _spawn(s2, "archer", Vector2(12.0, 0.0))
	for i in 20 * 15:
		s2.tick()
	t.check(a.pos.length() > 4.0 and a.pos.length() < 6.5, "archers shoot from a distance (%.1f)" % a.pos.length())
	# a gold bull runs past and escapes without costing anything
	var s3 = Survivor.new(data, 2)
	s3.weapons.clear()
	var bull = _spawn(s3, "wagon", Vector2(15.0, 0.0))
	for i in 20 * 30:
		s3.tick()
	t.check(not s3.enemies.has(bull.id) and s3.stats.leaks >= 1 and s3.stats.kills == 0, "a gold bull runs through and leaves")
	# bounty and scaling over time
	var s4 = Survivor.new(data, 2)
	var early = _spawn(s4, "walker", Vector2(10, 0))
	s4.time = 600.0
	var late = _spawn(s4, "walker", Vector2(10, 1))
	t.check(late.max_hp > early.max_hp * 3.0 and late.bounty > early.bounty and late.dmg > early.dmg, "enemies grow stronger over time")
	# difficulty scales the enemies
	var easy = Survivor.new(data, 2, "easy")
	var hard = Survivor.new(data, 2, "hard")
	var ee = _spawn(easy, "walker", Vector2(10, 0))
	var eh = _spawn(hard, "walker", Vector2(10, 0))
	t.check(ee.max_hp < eh.max_hp, "easy enemies have less life than hard ones")
	# bosses and bulls come on a schedule
	var s5 = Survivor.new(data, 2)
	s5.weapons.clear()
	s5.time = float(data.rules.bosses[0].time) - 0.1
	for i in 5:
		s5.tick()
	var boss := false
	for x in s5.enemies.values():
		if x.boss:
			boss = true
	t.check(boss, "the first boss arrives on time")
	# the clear button
	var s6 = Survivor.new(data, 2)
	s6.weapons.clear()
	for i in 6:
		_spawn(s6, "walker", Vector2(8, i))
	_spawn(s6, "boss1", Vector2(9, 0))
	t.check(s6.clear().reason == "cooldown", "clear needs its cooldown first")
	s6.clear_cd = 0.0
	t.check(s6.clear().ok, "clear works")
	s6.tick()
	var left := 0
	for x in s6.enemies.values():
		if not x.boss:
			left += 1
	t.check(left == 0 and s6.stats.kills == 0, "clear removes everything but bosses, without gold")
	t.check(s6.invuln_t > 0.0 and s6.clear_cd > 60.0, "the tower is safe for a moment and clear recharges")


func ending_rules(data) -> void:
	var sim = Survivor.new(data, 2)
	sim.time = float(data.rules.winTime) - 0.04
	sim.weapons.clear()
	sim.tick()
	t.check(sim.state == "won", "surviving the full time wins")
	t.check(sim.buy(0).reason == "ended", "no shopping after the end")
	var s2 = Survivor.new(data, 2)
	s2.weapons.clear()
	s2.tower_hp = 3.0
	var e = _spawn(s2, "walker", Vector2(1.0, 0.0))
	e.atk_t = 0.0
	e.dmg = 100.0
	for i in 40:
		s2.tick()
	t.check(s2.state == "lost" and s2.lost_reason == "tower", "a dead tower loses the game")
	var frozen: int = s2.tick_count
	s2.tick()
	t.check(s2.tick_count == frozen, "nothing happens after the end")


func determinism_and_bot(data) -> void:
	var a = _bot_run(data, 11, 20 * 60 * 3)
	var b = _bot_run(data, 11, 20 * 60 * 3)
	t.check(a.state_hash() == b.state_hash() and a.gold == b.gold, "same seed, same game")
	t.check(a.state == "running" and a.weapons.size() >= 3, "a simple bot survives 3 minutes and buys weapons (%d)" % a.weapons.size())
	t.check(a.stats.kills > 100, "and kills a lot (%d)" % a.stats.kills)
	print("survivor bot: %.1f min, tower %d/%d, weapons %s, kills %d" % [a.time / 60.0, a.tower_hp, a.tower_max, a.weapons.keys(), a.stats.kills])


func _bot_run(data, seed_value: int, ticks: int):
	var sim = Survivor.new(data, seed_value)
	var bot = BotSurvivor.new()
	for i in ticks:
		if i % 20 == 0:
			bot.step(sim)
		sim.tick()
		if sim.state != "running":
			break
	return sim
