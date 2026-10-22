extends RefCounted
## A scripted player for the mode "survivor": buys the best affordable offer, rerolls when the shop has nothing it wants,
## and uses the clear button when the tower is in trouble. Used by the balance runs and tests.

var rerolled_round := 0
var greedy := false     # true: keep gold for rarer offers


func step(sim) -> void:
	if sim.state != "running":
		return
	if sim.tower_hp < sim.tower_max * 0.3 and sim.clear_cd <= 0.0:
		sim.clear()
	var guard := 0
	while guard < 6:
		guard += 1
		var best := -1
		var best_score := 0.0
		# saving up: a much better offer that is nearly affordable is worth waiting for
		var target_cost := 0
		var target_score := 0.0
		for o in sim.offers:
			if o.bought:
				continue
			var tc: int = sim.offer_cost(o)
			var ts := _score(sim, o)
			if ts > target_score and tc > sim.gold and float(tc - sim.gold) <= sim.gold_per_second() * 25.0:
				target_score = ts
				target_cost = tc
		for i in sim.offers.size():
			var o: Dictionary = sim.offers[i]
			if o.bought:
				continue
			var cost: int = sim.offer_cost(o)
			if cost > sim.gold:
				continue
			var sc := _score(sim, o)
			if sc <= 0.0:
				continue
			if target_cost > 0 and sc < target_score * 0.85 and sim.gold - cost < target_cost:
				continue    # do not spend the money for the better offer on this one
			sc = sc / pow(float(cost), 0.3)
			if sc > best_score:
				best_score = sc
				best = i
		if best < 0:
			break
		if sim.buy(best).ok != true:
			break
	if sim.round_no != rerolled_round and sim.gold >= sim.reroll_cost() + 150:
		var any_left := false
		for o in sim.offers:
			if not o.bought and _score(sim, o) > 0.0:
				any_left = true
		if not any_left:
			rerolled_round = sim.round_no
			sim.reroll()


func _score(sim, o: Dictionary) -> float:
	var def: Dictionary = sim.data.weapons[o.id] if o.kind == "weapon" else sim.data.upgrades[o.id]
	var rar: int = int(def.rarity)
	if o.kind == "weapon":
		var owned: bool = sim.weapons.has(o.id)
		if owned and int(sim.weapons[o.id].level) >= int(sim.rules.maxWeaponLevel):
			return 0.0
		if not owned and sim.weapons.size() >= int(sim.rules.maxWeapons):
			return 0.0
		return (70.0 + 40.0 * rar) if owned else (100.0 + 60.0 * rar)
	if int(sim.upgrades.get(o.id, 0)) >= int(def.max):
		return 0.0
	var v := 50.0 + 40.0 * rar
	for k in def.stat:
		if k in ["dmg", "aspd", "armor", "income", "regen", "maxHp"]:
			v += 25.0
		if k in ["phoenix", "ankh"]:
			v += 60.0
	if sim.weapons.size() < 3:
		v *= 0.4    # first get a few weapons
	return v
