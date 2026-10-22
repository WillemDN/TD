extends RefCounted
## A better scripted player: builds a serpentine maze of towers in the shared field in front of the ship, fills it with the
## cheapest tower first and, between waves, trades the weakest tower in for the strongest one it can afford.

var element: String
var mode := "maze"            # "maze" = serpentine walls, "zone" = a dense kill zone around the route
var _slots: Array = []        # cells of the wall slots, in the order they are built
var _ready := false
var gap_rows := 4             # size of the openings in the walls (cells)
var wall_columns := [56, 62, 68, 74]
var _extra: Array = []        # spare spots next to the maze for strong towers


func _init(element_id: String, plan_mode := "maze") -> void:
	element = element_id
	mode = plan_mode


func _plan(sim) -> void:
	if mode == "zone":
		_plan_zone(sim)
		return
	var r: Array = sim.data.map.shared.rect
	var y0: int = int(r[1])
	var y1: int = int(r[3]) + 1
	var wi := 0
	for x in wall_columns:
		var gap_top: bool = wi % 2 == 0
		for y in range(y0, y1, 2):
			if gap_top and y < y0 + gap_rows:
				continue
			if (not gap_top) and y >= y1 - gap_rows:
				continue
			_slots.append(Vector2i(x, y))
		wi += 1
	_ready = true


func _plan_zone(sim) -> void:
	var r: Array = sim.data.map.shared.rect
	var mid: int = (int(r[1]) + int(r[3])) / 2
	var x := int(r[0]) + 3
	while x < int(r[2]) - 2:
		for off in [-4, 4, -6, 6, -8, 8, -10, 10, -12, 12]:
			_slots.append(Vector2i(x, mid + off))
		x += 2
	_ready = true


func step(sim) -> void:
	if not _ready:
		_plan(sim)
	if sim.elements.is_empty():
		sim.unlock_element(element)
	var ids: Array = sim.data.element_of(element).towers
	# 1. fill empty wall slots with the cheapest tower
	var cheapest: String = ids[0]
	for slot in _slots:
		if sim.gold < int(sim.data.towers[cheapest].cost.gold):
			break
		if _tower_at(sim, slot) == null:
			sim.place_tower(cheapest, slot.x, slot.y)
	# 2. between waves: swap weak towers for strong ones
	if sim.state == "countdown":
		_upgrade(sim, ids)
		if sim.lumber > 0 and sim.gold >= 750 + 60:
			for spot in _slots:
				pass
	# 3. start early when everything stands
	if sim.state == "countdown" and sim.countdown > 8.0 and _all_built(sim) and sim.towers.size() >= 8:
		sim.next_wave_now()


func _tower_at(sim, slot: Vector2i):
	for t in sim.towers.values():
		if t.cx == slot.x and t.cy == slot.y:
			return t
	return null


func _all_built(sim) -> bool:
	for t in sim.towers.values():
		if t.building:
			return false
	return true


func _upgrade(sim, ids: Array) -> void:
	var guard := 0
	while guard < 6:
		guard += 1
		# weakest tower in the maze
		var weakest = null
		for t in sim.towers.values():
			if t.building:
				continue
			if weakest == null or int(t.def.tier) < int(weakest.def.tier):
				weakest = t
		if weakest == null:
			return
		var best := ""
		for tid in ids:
			var def: Dictionary = sim.data.towers[tid]
			if int(def.tier) <= int(weakest.def.tier):
				continue
			var net: int = int(def.cost.gold) - sim.sell_value(weakest)
			if net <= sim.gold and int(def.cost.lumber) == 0:
				best = tid
		if best == "":
			return
		var cx: int = weakest.cx
		var cy: int = weakest.cy
		sim.sell_tower(weakest.id)
		if not sim.place_tower(best, cx, cy).ok:
			# could not place the better one: put the old kind back
			sim.place_tower(ids[0], cx, cy)
			return
