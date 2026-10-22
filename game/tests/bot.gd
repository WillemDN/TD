extends RefCounted
## A simple scripted player used by the tests and for balance probes: picks one element, keeps buying the best tower it
## can afford and puts it next to the lane paths, with a mix of cheap and strong towers.

var element: String
var _spots_cache := {}


func _init(element_id: String) -> void:
	element = element_id


func step(sim) -> void:
	if sim.elements.is_empty():
		sim.unlock_element(element)
	if sim.state == "countdown" and sim.countdown > 10.0 and sim.towers.size() >= 4 and _all_built(sim):
		sim.next_wave_now()
	var guard := 0
	while guard < 6:
		guard += 1
		var def_id := _pick_tower(sim)
		if def_id == "":
			return
		if not _place(sim, def_id):
			return


func _all_built(sim) -> bool:
	for t in sim.towers.values():
		if t.building:
			return false
	return true


func _pick_tower(sim) -> String:
	var e: Dictionary = sim.data.element_of(element)
	# the first towers are the cheap tier-1 ones; after that the strongest tower we can afford
	var ids: Array = e.towers
	if sim.towers.size() < 8:
		var cheap: String = ids[0]
		return cheap if int(sim.data.towers[cheap].cost.gold) <= sim.gold else ""
	var best := ""
	var best_cost := -1
	for tid in ids:
		var cost: int = int(sim.data.towers[tid].cost.gold)
		if cost <= sim.gold and cost > best_cost:
			best = tid
			best_cost = cost
	return best


func _place(sim, def_id: String) -> bool:
	for pos in _candidate_spots(sim):
		if sim.can_place(def_id, pos.x, pos.y).ok:
			return sim.place_tower(def_id, pos.x, pos.y).ok
	return false


## Cells in the shared field in front of the ship, around the central path and nearest to the entrance first.
func _candidate_spots(sim) -> Array:
	if _spots_cache.has("spots"):
		return _spots_cache["spots"]
	var spots: Array = []
	var r: Array = sim.data.map.shared.rect
	var mid: int = (int(r[1]) + int(r[3])) / 2
	var x := int(r[0]) + 2
	while x < int(r[2]) - 3:
		for off in [-5, 4, -8, 7, -11, 10, -14, 13]:
			spots.append(Vector2i(x, mid + off))
		x += 3
	_spots_cache["spots"] = spots
	return spots
