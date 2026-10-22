extends RefCounted
## Headless, deterministic game simulation (20 Hz). No nodes, no rendering: the client only reads this state and
## sends commands (place_tower, sell_tower, unlock_element, next_wave_now). One seeded RNG per match.

const GridScript := preload("res://core/grid.gd")

const DT := 0.05
const TICKS_PER_SECOND := 20

class Creep extends RefCounted:
	var id := 0
	var def: Dictionary
	var level := 0
	var hp := 0.0
	var max_hp := 0.0
	var pos := Vector2.ZERO
	var prev := Vector2.ZERO
	var air := false
	var boss := false
	var armor := 0.0
	var armor_type := "medium"
	var speed := 1.0
	var slow_amt := 0.0
	var slow_t := 0.0
	var root_t := 0.0
	var ared_amt := 0.0
	var ared_t := 0.0
	var poison_dps := 0.0
	var poison_t := 0.0
	var poison_src := 0
	var alive := true

class Tower extends RefCounted:
	var id := 0
	var def: Dictionary
	var cx := 0
	var cy := 0
	var center := Vector2.ZERO
	var building := true
	var build_total := 1.0
	var build_left := 1.0
	var cooldown := 0
	var spent := 0
	var kills := 0
	var damage_dealt := 0.0
	var aim := Vector2.ZERO          # last target position, for turning the turret in the view
	var moves := 0

class Proj extends RefCounted:
	var tower: Tower
	var target_id := 0
	var pos := Vector2.ZERO
	var prev := Vector2.ZERO
	var speed := 10.0
	var damage := 0.0

var data
var grid
var rng := RandomNumberGenerator.new()
var players := 1
var difficulty := "normal"

var tick_count := 0
var time := 0.0
var gold := 0
var lumber := 0
var lives := 0
var max_lives := 0
var level := 0                   # level of the wave that was started last
var state := "countdown"         # countdown | active | won | lost
var lost_reason := ""
var countdown := 0.0
var elements: Array = []         # unlocked element ids
var towers := {}                 # id -> Tower
var creeps := {}                 # id -> Creep, insertion ordered
var projectiles: Array = []
var record_events := false
var events: Array = []
var stats := {"kills": 0, "leaks": 0, "gold_earned": 0}
var grid_revision := 0           # bumps whenever towers change the walkable grid

var _next_id := 1
var _spawn_queue: Array = []
var _wave_clock := 0.0
var _spawn_cells := PackedInt32Array()
var _matrix := {}
var _rules := {}
var _boost := {"startGold": 1.0, "levelBonus": 1.0, "bounty": 1.0}


func _init(game_data, seed_value: int = 1, difficulty_id: String = "", player_count: int = 1) -> void:
	data = game_data
	_rules = data.rules
	_matrix = data.matrix
	rng.seed = seed_value
	players = maxi(1, player_count)
	difficulty = difficulty_id if difficulty_id != "" else String(_rules.defaultDifficulty)
	grid = GridScript.new(data.map)
	for s in data.map.spawns:
		_spawn_cells.append(grid.idx(int(s.cell[0]), int(s.cell[1])))
	var boost = _rules.get("playerBoost", {}).get(str(players))
	if boost != null:
		_boost = boost
	gold = int(round(float(_rules.startGold) * float(_boost.startGold)))
	lumber = int(_rules.startLumber)
	max_lives = int(_rules.difficulties[difficulty])
	lives = max_lives
	countdown = float(_rules.firstWaveDelay)


# ---------------------------------------------------------------- commands

func unlock_element(element_id: String) -> Dictionary:
	if element_id in elements:
		return _err("already")
	if data.element_of(element_id).is_empty():
		return _err("unknown")
	if lumber < 1:
		return _err("lumber")
	lumber -= 1
	elements.append(element_id)
	return {"ok": true}


## Check whether a tower can be placed at cell (cx, cy) without placing it. Result has ok and reason.
## The spot itself is checked first (so a spot on top of a tower is always "occupied"), the price last.
func can_place(def_id: String, cx: int, cy: int) -> Dictionary:
	var def = data.towers.get(def_id)
	if def == null:
		return _err("unknown")
	if state == "won" or state == "lost":
		return _err("ended")
	if def.element != "ultimate" and not (def.element in elements):
		return _err("locked")
	var spot := _can_place_here(cx, cy, int(def.footprint[0]), int(def.footprint[1]))
	if not spot.ok:
		return spot
	if gold < int(def.cost.gold):
		return _err("gold")
	if lumber < int(def.cost.lumber):
		return _err("lumber")
	return {"ok": true}


func _can_place_here(cx: int, cy: int, fw: int, fh: int) -> Dictionary:
	var problem: String = grid.footprint_problem(cx, cy, fw, fh)
	if problem != "":
		return _err(problem)
	if _creep_in_footprint(cx, cy, fw, fh):
		return _err("creep")
	if not grid.stays_connected(cx, cy, fw, fh, _required_cells()):
		return _err("blocks_path")
	return {"ok": true}


func place_tower(def_id: String, cx: int, cy: int) -> Dictionary:
	var res := can_place(def_id, cx, cy)
	if not res.ok:
		return res
	var def: Dictionary = data.towers[def_id]
	gold -= int(def.cost.gold)
	lumber -= int(def.cost.lumber)
	var t := Tower.new()
	t.id = _take_id()
	t.def = def
	t.cx = cx
	t.cy = cy
	var cs: float = grid.cell_size
	t.center = Vector2((float(cx) + float(def.footprint[0]) * 0.5) * cs, (float(cy) + float(def.footprint[1]) * 0.5) * cs)
	t.build_total = maxf(0.05, float(def.buildTime))
	t.build_left = t.build_total
	t.spent = int(def.cost.gold)
	towers[t.id] = t
	grid.set_footprint(cx, cy, int(def.footprint[0]), int(def.footprint[1]), true)
	grid.recompute()
	grid_revision += 1
	_event({"type": "placed", "tower": t.id})
	return {"ok": true, "id": t.id}


func sell_tower(tower_id: int) -> Dictionary:
	var t: Tower = towers.get(tower_id)
	if t == null:
		return _err("unknown")
	gold += sell_value(t)
	grid.set_footprint(t.cx, t.cy, int(t.def.footprint[0]), int(t.def.footprint[1]), false)
	grid.recompute()
	grid_revision += 1
	towers.erase(tower_id)
	_event({"type": "sold", "tower": tower_id})
	return {"ok": true}


## Check whether a tower can be moved to cell (cx, cy). The tower's own cells count as free.
func can_move(tower_id: int, cx: int, cy: int) -> Dictionary:
	var t: Tower = towers.get(tower_id)
	if t == null:
		return _err("unknown")
	if state == "won" or state == "lost":
		return _err("ended")
	var fw := int(t.def.footprint[0])
	var fh := int(t.def.footprint[1])
	if cx == t.cx and cy == t.cy:
		return _err("same")
	grid.set_footprint(t.cx, t.cy, fw, fh, false)
	var res := _can_place_here(cx, cy, fw, fh)
	grid.set_footprint(t.cx, t.cy, fw, fh, true)
	return res


## Move a built tower. It costs no gold, but the tower has to be set up again: it is out of action for a share of
## its build time (rules.moveBuildShare), so moving in the middle of a wave is a real decision.
func move_tower(tower_id: int, cx: int, cy: int) -> Dictionary:
	var res := can_move(tower_id, cx, cy)
	if not res.ok:
		return res
	var t: Tower = towers[tower_id]
	var fw := int(t.def.footprint[0])
	var fh := int(t.def.footprint[1])
	grid.set_footprint(t.cx, t.cy, fw, fh, false)
	grid.set_footprint(cx, cy, fw, fh, true)
	grid.recompute()
	grid_revision += 1
	t.cx = cx
	t.cy = cy
	var cs: float = grid.cell_size
	t.center = Vector2((float(cx) + float(fw) * 0.5) * cs, (float(cy) + float(fh) * 0.5) * cs)
	var share: float = float(_rules.get("moveBuildShare", 0.35))
	t.building = true
	t.build_total = maxf(1.5, float(t.def.buildTime) * share)
	t.build_left = t.build_total
	t.moves += 1
	_event({"type": "moved", "tower": t.id})
	return {"ok": true}


func sell_value(t: Tower) -> int:
	var rate: float = float(_rules.sellRefund.idle) if (t.building or is_idle()) else float(_rules.sellRefund.wave)
	return int(floor(float(t.spent) * rate))


## Start the next wave right away. Gives a small bonus for the time that was skipped.
func next_wave_now() -> Dictionary:
	if state != "countdown":
		return _err("not_waiting")
	gold += int(floor(countdown * float(_rules.skipBonusPerSecond)))
	countdown = 0.0
	return {"ok": true}


# ---------------------------------------------------------------- queries

func is_idle() -> bool:
	return state != "active" and creeps.is_empty()


func alive_count() -> int:
	return creeps.size()


## Creeps still on the field plus those waiting to spawn.
func creeps_remaining() -> int:
	return creeps.size() + _spawn_queue.size()


func armor_reduction(armor: float) -> float:
	var step: float = float(_rules.armorStep)
	if armor >= 0.0:
		return step * armor / (1.0 + step * armor)
	return -(1.0 - pow(1.0 - step, -armor))


func damage_multiplier(attack_type: String, armor_type: String, armor: float) -> float:
	return float(_matrix[attack_type][armor_type]) * (1.0 - armor_reduction(armor))


func level_bonus(for_level: int) -> int:
	var base: int = int(_rules.levelBonus.base) + int(_rules.levelBonus.perLevel) * for_level
	return int(round(float(base) * float(_boost.levelBonus)))


## Number of creeps a wave brings, scaled to the player count (the original is balanced for 9 players).
func wave_total(wave: Dictionary) -> int:
	var per: float = float(wave.countPerSpawn) * float(_rules.spawnPoints) * float(players) / float(_rules.playerScaleBase)
	return maxi(1, int(round(per)))


func state_hash() -> int:
	var parts := [tick_count, gold, lumber, lives, level, state, stats.kills, stats.leaks, creeps.size(), towers.size()]
	for c in creeps.values():
		parts.append(int(c.hp * 100.0))
		parts.append(int(c.pos.x * 1000.0))
	return str(parts).hash()


# ---------------------------------------------------------------- simulation

func tick() -> void:
	if state == "won" or state == "lost":
		return
	tick_count += 1
	time += DT
	_update_waves()
	for t in towers.values():
		_update_tower(t)
	_update_projectiles()
	_update_creeps()
	_cleanup()
	_check_wave_end()


func _update_waves() -> void:
	if state == "countdown":
		countdown -= DT
		if countdown <= 0.0:
			_start_wave()
	if state == "active":
		_wave_clock += DT
		while not _spawn_queue.is_empty() and _spawn_queue[0].t <= _wave_clock:
			var e: Dictionary = _spawn_queue.pop_front()
			_spawn_creep(e.creep, e.spawn)


func _start_wave() -> void:
	level += 1
	state = "active"
	_wave_clock = 0.0
	var wave: Dictionary = data.waves[level - 1]
	var total := wave_total(wave)
	var points := int(_rules.spawnPoints)
	var interval := float(_rules.spawnRoundInterval)
	_spawn_queue.clear()
	for i in total:
		_spawn_queue.append({
			"t": float(i / points) * interval + float(i % points) * 0.05,
			"creep": wave.creep,
			"spawn": (i + level) % points,
		})
	_event({"type": "wave", "level": level})


func _spawn_creep(creep_id: String, spawn_index: int) -> void:
	var def: Dictionary = data.creeps[creep_id]
	var c := Creep.new()
	c.id = _take_id()
	c.def = def
	c.level = level
	c.max_hp = float(def.hp)
	c.hp = c.max_hp
	c.air = bool(def.air)
	c.boss = bool(def.boss)
	c.armor = float(def.armor)
	c.armor_type = def.armorType
	c.speed = float(def.speed)
	var cell: Array = data.map.spawns[spawn_index].cell
	var cs: float = grid.cell_size
	c.pos = Vector2((float(cell[0]) + 0.5) * cs + rng.randf_range(-0.2, 0.2), (float(cell[1]) + 0.5) * cs + rng.randf_range(-0.2, 0.2))
	c.prev = c.pos
	creeps[c.id] = c


func _update_tower(t: Tower) -> void:
	if t.building:
		t.build_left -= DT
		if t.build_left <= 0.0:
			t.building = false
			t.cooldown = 0
			_event({"type": "built", "tower": t.id})
		return
	if t.cooldown > 0:
		t.cooldown -= 1
		return
	var target := _find_target(t)
	if target == null:
		return
	t.cooldown = maxi(1, int(ceil(float(t.def.attack.cooldown) / DT - 0.0001)))
	_fire(t, target)


func _find_target(t: Tower) -> Creep:
	var a: Dictionary = t.def.attack
	var range2: float = float(a.range) * float(a.range)
	var can_air: bool = a.targets.has("air")
	var can_ground: bool = a.targets.has("ground")
	var best: Creep = null
	var best_d := INF
	for c in creeps.values():
		if not c.alive:
			continue
		if c.air and not can_air:
			continue
		if not c.air and not can_ground:
			continue
		var d := t.center.distance_squared_to(c.pos)
		if d <= range2 and d < best_d:
			best_d = d
			best = c
	return best


func _fire(t: Tower, target: Creep) -> void:
	t.aim = target.pos
	var a: Dictionary = t.def.attack
	var dmg := float(rng.randi_range(int(a.damage[0]), int(a.damage[1])))
	for e in t.def.effects:
		if e.kind == "crit" and rng.randf() < float(e.chance):
			dmg *= float(e.multiplier)
			_event({"type": "crit", "pos": target.pos})
	var speed := float(a.projectileSpeed)
	if speed <= 0.0:
		_event({"type": "zap", "from": t.center, "to": target.pos, "tower": t.id})
		_impact(t, target, dmg)
		return
	var p := Proj.new()
	p.tower = t
	p.target_id = target.id
	p.pos = t.center
	p.prev = t.center
	p.speed = speed
	p.damage = dmg
	projectiles.append(p)


func _update_projectiles() -> void:
	var keep: Array = []
	for p in projectiles:
		var target: Creep = creeps.get(p.target_id)
		if target == null or not target.alive:
			continue
		p.prev = p.pos
		var to: Vector2 = target.pos - p.pos
		var step: float = p.speed * DT
		if to.length() <= step:
			_impact(p.tower, target, p.damage)
		else:
			p.pos += to.normalized() * step
			keep.append(p)
	projectiles = keep


func _impact(t: Tower, target: Creep, dmg: float) -> void:
	var a: Dictionary = t.def.attack
	var hit_pos := target.pos
	_event({"type": "impact", "pos": hit_pos, "element": t.def.element, "air": target.air})
	_deal(target, dmg, a.type, t, false)
	for e in t.def.effects:
		if e.kind == "bonus_damage":
			_deal(target, float(e.amount), a.type, t, false)
	var splash = a.splash
	if splash != null:
		var r_full := float(splash[0])
		var r_mid := float(splash[1])
		var r_small := float(splash[2])
		for c in creeps.values():
			if c == target or not c.alive:
				continue
			var d: float = hit_pos.distance_to(c.pos)
			if d > r_small:
				continue
			var f := 1.0 if d <= r_full else (0.5 if d <= r_mid else 0.25)
			_deal(c, dmg * f, a.type, t, false)
	for e in t.def.effects:
		match e.kind:
			"chain":
				_chain(t, target, dmg, e, false)
			"bounce":
				_chain(t, target, dmg, e, true)
			_:
				if target.alive:
					_apply_status(t, target, e)


func _chain(t: Tower, first: Creep, dmg: float, e: Dictionary, bounce: bool) -> void:
	var a: Dictionary = t.def.attack
	var hit := {first.id: true}
	var current := first
	var d := float(e.damage) if e.has("damage") else dmg
	var range_limit := float(e.range)
	for i in int(e.targets):
		var best: Creep = null
		var best_d := INF
		for c in creeps.values():
			if not c.alive or hit.has(c.id):
				continue
			if c.air and not a.targets.has("air"):
				continue
			if not c.air and not a.targets.has("ground"):
				continue
			var dist := current.pos.distance_to(c.pos)
			if dist <= range_limit and dist < best_d:
				best_d = dist
				best = c
		if best == null:
			return
		d *= float(e.falloff)
		hit[best.id] = true
		_event({"type": "zap", "from": current.pos, "to": best.pos, "tower": t.id})
		_deal(best, d, a.type, t, false)
		current = best


func _apply_status(t: Tower, c: Creep, e: Dictionary) -> void:
	if e.get("bossImmune", false) and c.boss:
		return
	match e.kind:
		"slow":
			_slow(c, float(e.amount), float(e.duration))
		"poison":
			_slow(c, float(e.slow), float(e.duration))
			var avg: float = (float(t.def.attack.damage[0]) + float(t.def.attack.damage[1])) * 0.5
			var dps: float = avg * float(e.dpsFactor)
			if dps >= c.poison_dps or c.poison_t <= 0.0:
				c.poison_dps = dps
				c.poison_t = float(e.duration)
				c.poison_src = t.id
		"armor_reduce":
			if float(e.amount) >= c.ared_amt or c.ared_t <= 0.0:
				c.ared_amt = float(e.amount)
			c.ared_t = maxf(c.ared_t, float(e.duration))
		"root":
			if e.has("chance") and rng.randf() >= float(e.chance):
				return
			c.root_t = maxf(c.root_t, float(e.duration))
		"percent_hp":
			_deal(c, c.hp * float(e.percent), "chaos", t, true)
		"set_hp":
			c.hp = minf(c.hp, float(e.hp))


func _slow(c: Creep, amount: float, duration: float) -> void:
	if amount >= c.slow_amt or c.slow_t <= 0.0:
		c.slow_amt = amount
	c.slow_t = maxf(c.slow_t, duration)


func _deal(c: Creep, raw: float, attack_type: String, t: Tower, pure: bool) -> void:
	if not c.alive:
		return
	var dmg := raw if pure else raw * damage_multiplier(attack_type, c.armor_type, c.armor - c.ared_amt)
	c.hp -= dmg
	if t != null:
		t.damage_dealt += dmg
	if c.hp <= 0.0:
		_kill(c, t)


func _kill(c: Creep, t: Tower) -> void:
	c.alive = false
	var b: Dictionary = c.def.bounty
	var g := int(b.base)
	for i in int(b.dice):
		g += rng.randi_range(1, int(b.sides))
	g = int(round(float(g) * float(_boost.bounty)))
	gold += g
	stats.gold_earned += g
	stats.kills += 1
	if t != null:
		t.kills += 1
	_event({"type": "kill", "pos": c.pos, "gold": g, "boss": c.boss})


func _update_creeps() -> void:
	for c in creeps.values():
		if not c.alive:
			continue
		c.prev = c.pos
		if c.poison_t > 0.0:
			c.poison_t -= DT
			_deal(c, c.poison_dps * DT, "chaos", towers.get(c.poison_src), true)
			if not c.alive:
				continue
		c.slow_t -= DT
		if c.slow_t <= 0.0:
			c.slow_amt = 0.0
		c.ared_t -= DT
		if c.ared_t <= 0.0:
			c.ared_amt = 0.0
		if c.root_t > 0.0:
			c.root_t -= DT
			continue
		var step: float = c.speed * (1.0 - minf(c.slow_amt, 0.85)) * DT
		var leaked := _move_air(c, step) if c.air else _move_ground(c, step)
		if leaked:
			_leak(c)


func _move_ground(c: Creep, step: float) -> bool:
	return _move_along(c, step, grid.next_cell)


## Flyers follow the corridors of the map (terrain only), so they fly over towers instead of cutting across the forest.
func _move_air(c: Creep, step: float) -> bool:
	return _move_along(c, step, grid.air_next)


func _move_along(c: Creep, step: float, route: PackedInt32Array) -> bool:
	var remaining := step
	var guard := 0
	while remaining > 0.0001 and guard < 8:
		guard += 1
		var cur: int = grid.cell_of(c.pos)
		if grid.is_goal(cur):
			return true
		var nxt: int = route[cur]
		if nxt < 0:
			return false
		var target: Vector2 = grid.cell_center(nxt)
		var to := target - c.pos
		var d := to.length()
		if d <= remaining:
			c.pos = target
			remaining -= d
		else:
			c.pos += to / d * remaining
			remaining = 0.0
	return grid.is_goal(grid.cell_of(c.pos))


func _leak(c: Creep) -> void:
	c.alive = false
	stats.leaks += 1
	var wave: Dictionary = data.waves[c.level - 1]
	_event({"type": "leak", "pos": c.pos, "boss": c.boss})
	if bool(wave.finalBoss) and c.boss:
		state = "lost"
		lost_reason = "boss"
		_event({"type": "lost", "reason": "boss"})
		return
	if not bool(wave.noLifeLoss):
		lives -= 1
		if lives <= 0:
			lives = 0
			state = "lost"
			lost_reason = "lives"
			_event({"type": "lost", "reason": "lives"})


func _cleanup() -> void:
	for id in creeps.keys():
		if not creeps[id].alive:
			creeps.erase(id)


func _check_wave_end() -> void:
	if state != "active" or not _spawn_queue.is_empty() or not creeps.is_empty():
		return
	gold += level_bonus(level)
	stats.gold_earned += level_bonus(level)
	var extra = _rules.lumberAtLevel.get(str(level))
	if extra != null:
		lumber += int(extra)
	_event({"type": "cleared", "level": level})
	if level >= int(_rules.lastLevel):
		state = "won"
		_event({"type": "won"})
	else:
		state = "countdown"
		countdown = float(_rules.waveDelay)


# ---------------------------------------------------------------- helpers

func _required_cells() -> PackedInt32Array:
	var req := PackedInt32Array(_spawn_cells)
	for c in creeps.values():
		if c.alive and not c.air:
			req.append(grid.cell_of(c.pos))
	return req


func _creep_in_footprint(cx: int, cy: int, fw: int, fh: int) -> bool:
	var cs: float = grid.cell_size
	var rect := Rect2(float(cx) * cs, float(cy) * cs, float(fw) * cs, float(fh) * cs)
	for c in creeps.values():
		if c.alive and not c.air and rect.has_point(c.pos):
			return true
	return false


func _take_id() -> int:
	_next_id += 1
	return _next_id - 1


func _err(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}


func _event(e: Dictionary) -> void:
	if record_events:
		events.append(e)
