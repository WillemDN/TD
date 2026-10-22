extends RefCounted
## A scripted player for the mode "elements": picks elements, puts towers on the build plates that cover the most path,
## and always buys the tower that fixes the weakest spot of its element coverage (every wave has another element).
## Between waves it trades weak towers in for strong ones (selling is free while idle). Used by the balance runs and tests.

var picks: Array             # element ids in the order they are learned
var reach := 5.2             # tiles around a plate that count as covered path
var _spots: Array = []       # [Vector2i] plate cells, best coverage first
var _planned := false
var trade := true


func _init(pick_order: Array) -> void:
	picks = pick_order


func _plan(sim) -> void:
	var path: Array = []
	var cell: int = sim.grid.idx(int(sim.data.map.spawns[0].cell[0]), int(sim.data.map.spawns[0].cell[1]))
	var guard := 0
	while cell >= 0 and guard < 5000:
		guard += 1
		path.append(sim.grid.cell_center(cell))
		cell = sim.grid.next_cell[cell]
	var scored: Array = []
	var cs: float = sim.grid.cell_size
	for y in range(0, sim.grid.h - 1, 2):
		for x in range(0, sim.grid.w - 1, 2):
			if sim.grid.footprint_problem(x, y, 2, 2) != "":
				continue
			var c := Vector2((float(x) + 1.0) * cs, (float(y) + 1.0) * cs)
			var n := 0
			for i in range(0, path.size(), 3):
				if path[i].distance_to(c) <= reach:
					n += 1
			scored.append([n, x, y])
	scored.sort_custom(func(a, b): return a[0] > b[0])
	for s in scored:
		_spots.append(Vector2i(s[1], s[2]))
	_planned = true


func step(sim) -> void:
	if not _planned:
		_plan(sim)
	for p in picks:
		if not (p in sim.elements) and sim.lumber > 0:
			sim.unlock_element(p)
	if sim.elements.is_empty():
		return
	var cov := _coverage(sim)
	var best := _best_def(sim, cov, 1000000)
	if best == "":
		return
	if trade and sim.is_idle():
		_trade_in(sim, cov, best)
	var guard := 0
	while guard < 12:
		guard += 1
		cov = _coverage(sim)
		var id := _best_def(sim, cov, sim.gold)
		if id == "":
			break
		if not _build(sim, id):
			break


func _value(sim, def: Dictionary, cov: Dictionary) -> float:
	var a: Dictionary = def.attack
	var dps: float = (float(a.damage[0]) + float(a.damage[1])) * 0.5 / maxf(0.05, float(a.cooldown))
	var extra := 1.0
	for e in def.effects:
		extra += 0.12
	if a.splash != null:
		extra += 0.2
	var score := 0.0
	for el in sim.data.elements:
		var m: float = float(sim.data.matrix[a.type][el.id])
		score += dps * extra * m / (1.0 + float(cov.get(el.id, 0.0)))
	return score / maxf(1.0, float(def.cost.gold))


func _coverage(sim) -> Dictionary:
	var cov := {}
	for el in sim.data.elements:
		cov[el.id] = 0.0
	for t in sim.towers.values():
		var a: Dictionary = t.def.attack
		var dps: float = (float(a.damage[0]) + float(a.damage[1])) * 0.5 / maxf(0.05, float(a.cooldown))
		for el in sim.data.elements:
			cov[el.id] += dps * float(sim.data.matrix[a.type][el.id])
	return cov


func _best_def(sim, cov: Dictionary, budget: int) -> String:
	var best := ""
	var best_v := -1.0
	for id in sim.data.towers:
		var def: Dictionary = sim.data.towers[id]
		if int(def.cost.gold) > budget:
			continue
		var ok := true
		for e in sim.needed_elements(def):
			if not (e in sim.elements):
				ok = false
		if not ok or sim.cleared < int(def.get("unlockAfter", 0)):
			continue
		var v := _value(sim, def, cov)
		if v > best_v:
			best_v = v
			best = id
	return best


func _build(sim, id: String) -> bool:
	for s in _spots:
		var r: Dictionary = sim.place_tower(id, s.x, s.y)
		if r.ok:
			return true
		if r.reason == "gold" or r.reason == "lumber" or r.reason == "locked" or r.reason == "locked_level":
			return false
	return false


## Sell cheap towers when a much stronger one is within reach of their refund.
func _trade_in(sim, cov: Dictionary, target: String) -> void:
	var def: Dictionary = sim.data.towers[target]
	var cost: int = int(def.cost.gold)
	if sim.gold >= cost:
		return
	var weak: Array = []
	for t in sim.towers.values():
		if int(t.def.cost.gold) * 4 <= cost:
			weak.append(t)
	weak.sort_custom(func(a, b): return a.damage_dealt < b.damage_dealt)
	var refund := 0
	var chosen: Array = []
	for t in weak:
		refund += sim.sell_value(t)
		chosen.append(t.id)
		if sim.gold + refund >= cost:
			break
	if sim.gold + refund >= cost:
		for id in chosen:
			sim.sell_tower(id)
