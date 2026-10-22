extends RefCounted
## Headless, deterministic simulation of the mode "survivor" (Last Tower, 20 Hz): one tower in the middle of an arena,
## hordes that walk at it, a shop where gold buys weapons and upgrades. Commands: buy, reroll, clear. No nodes, no rendering.
## Positions are in tiles with the tower at (0, 0).

const DT := 0.05
const ARMOR_STEP := 0.06

class Enemy extends RefCounted:
	var id := 0
	var def: Dictionary
	var level := 0                   # compatibility with the 2D overlay (not used)
	var hp := 0.0
	var max_hp := 0.0
	var pos := Vector2.ZERO
	var prev := Vector2.ZERO
	var dmg := 0.0
	var speed := 1.0
	var armor := 0.0
	var radius := 0.4
	var atk_t := 0.0
	var stop := 1.0                  # distance from the tower centre where it stops and attacks
	var dest := Vector2.ZERO         # gold bulls: the point they run to
	var slow_amt := 0.0
	var slow_t := 0.0
	var poison_dps := 0.0
	var poison_t := 0.0
	var burn_dps := 0.0
	var burn_t := 0.0
	var bounty := 0
	var boss := false
	var air := false                 # compatibility with the 2D overlay
	var wagon := false
	var alive := true
	var hit_until := {}              # orbit blades: weapon id -> time it may be hit again

class Shot extends RefCounted:       # a projectile or a flying disc
	var pos := Vector2.ZERO
	var prev := Vector2.ZERO
	var dir := Vector2.RIGHT
	var speed := 10.0
	var dmg := 0.0
	var dtype := "phys"
	var pierce := 0
	var ttl := 1.0
	var hit := {}
	var wid := ""
	var poison := 0.0
	var poison_t := 0.0
	var disc := false                # a disc flies out and comes back
	var back := false
	var out_left := 0.0
	var heal := 0.0

class Mine extends RefCounted:
	var pos := Vector2.ZERO
	var dmg := 0.0
	var splash := 1.5
	var life := 20.0
	var dtype := "phys"

class Shell extends RefCounted:
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var t_left := 1.0
	var t_total := 1.0
	var dmg := 0.0
	var splash := 1.5
	var dtype := "phys"

var data
var rules := {}
var rng := RandomNumberGenerator.new()
var difficulty := "normal"
var strength := 1.0

var tick_count := 0
var time := 0.0
var state := "running"            # running | won | lost
var lost_reason := ""
var gold := 0
var tower_hp := 0.0
var tower_max := 0.0
var shield := 0.0
var invuln_t := 0.0
var clear_cd := 0.0
var round_no := 1
var weapons := {}                 # id -> {level, cd, angle}
var upgrades := {}                # id -> level
var stat := {}
var offers: Array = []            # [{kind, id, bought}]
var reroll_count := 0
var enemies := {}                 # id -> Enemy
var shots: Array = []
var mines: Array = []
var shells: Array = []
var blades: Array = []            # Vector2 positions of all orbiting blades (for the view)
var events: Array = []
var record_events := false
var stats := {"kills": 0, "gold_earned": 0, "damage": 0.0, "leaks": 0, "rerolls": 0}

## The 2D overlay reads the enemies as "creeps" (health bars).
var creeps: Dictionary:
	get:
		return enemies

var _next_id := 1
var _next_def := {}
var _budget := 0.0
var _gold_frac := 0.0
var _shield_t := 0.0
var _phoenix_cd := 0.0
var _ankh_used := false
var _next_wagon := 0.0
var _boss_index := 0
var _round_clock := 0.0


func _init(game_data, seed_value: int = 1, difficulty_id: String = "") -> void:
	data = game_data
	rules = data.rules
	rng.seed = seed_value
	difficulty = difficulty_id if difficulty_id != "" else String(rules.defaultDifficulty)
	strength = float(rules.difficulties[difficulty]) / 100.0
	gold = int(rules.startGold)
	clear_cd = float(rules.clear.startCooldown)
	_next_wagon = float(rules.wagon.first)
	weapons[String(rules.starterWeapon)] = {"level": 1, "cd": 0.3, "angle": 0.0}
	_recalc()
	tower_hp = tower_max
	_roll_offers()


# ---------------------------------------------------------------- commands

func offer_cost(o: Dictionary) -> int:
	var def: Dictionary = _item(o)
	var owned := 0
	if o.kind == "weapon":
		owned = int(weapons.get(o.id, {}).get("level", 0))
	else:
		owned = int(upgrades.get(o.id, 0))
	return int(round(float(def.cost) * (1.0 + 0.5 * float(owned))))


func reroll_cost() -> int:
	return int(rules.rerollBase) + int(rules.rerollStep) * reroll_count


func buy(index: int) -> Dictionary:
	if state != "running":
		return _err("ended")
	if index < 0 or index >= offers.size():
		return _err("unknown")
	var o: Dictionary = offers[index]
	if o.bought:
		return _err("bought")
	var def: Dictionary = _item(o)
	if o.kind == "weapon":
		var owned: bool = weapons.has(o.id)
		if owned and int(weapons[o.id].level) >= int(rules.maxWeaponLevel):
			return _err("maxed")
		if not owned and weapons.size() >= int(rules.maxWeapons):
			return _err("full")
	else:
		if int(upgrades.get(o.id, 0)) >= int(def.max):
			return _err("maxed")
	var cost := offer_cost(o)
	if gold < cost:
		return _err("gold")
	gold -= cost
	o.bought = true
	if o.kind == "weapon":
		if weapons.has(o.id):
			weapons[o.id].level += 1
		else:
			weapons[o.id] = {"level": 1, "cd": 0.3, "angle": 0.0}
	else:
		upgrades[o.id] = int(upgrades.get(o.id, 0)) + 1
		var heal := float(def.stat.get("heal", 0.0))
		_recalc()
		tower_hp = minf(tower_max, tower_hp + heal)
	_recalc()
	_event({"type": "bought", "kind": o.kind, "id": o.id})
	return {"ok": true}


func reroll() -> Dictionary:
	if state != "running":
		return _err("ended")
	var c := reroll_cost()
	if gold < c:
		return _err("gold")
	gold -= c
	reroll_count += 1
	stats.rerolls += 1
	_roll_offers()
	return {"ok": true}


## The panic button: sweeps every enemy except bosses away (no gold), heals a bit and makes the tower safe for a moment.
func clear() -> Dictionary:
	if state != "running":
		return _err("ended")
	if clear_cd > 0.0:
		return _err("cooldown")
	for e in enemies.values():
		if e.alive and not e.boss:
			e.alive = false
	clear_cd = float(rules.clear.cooldown)
	invuln_t = maxf(invuln_t, float(rules.clear.invuln))
	tower_hp = minf(tower_max, tower_hp + tower_max * float(rules.clear.heal))
	_event({"type": "cleared"})
	return {"ok": true}


# ---------------------------------------------------------------- queries

func minute() -> float:
	return time / 60.0


func round_time_left() -> float:
	return float(rules.roundSeconds) - _round_clock


func gold_per_second() -> float:
	return float(stat.income)


func armor_reduction(armor: float) -> float:
	if armor >= 0.0:
		return ARMOR_STEP * armor / (1.0 + ARMOR_STEP * armor)
	return -(1.0 - pow(1.0 - ARMOR_STEP, -armor))


func weapon_def(id: String) -> Dictionary:
	return data.weapons[id]


func weapon_range(id: String) -> float:
	return float(data.weapons[id].range) * float(stat.range)


func weapon_damage(id: String) -> float:
	var w: Dictionary = data.weapons[id]
	var lvl: int = int(weapons[id].level)
	return float(w.damage) * (1.0 + float(rules.weaponLevelDamage) * float(lvl - 1)) * float(stat.dmg)


func weapon_interval(id: String) -> float:
	var w: Dictionary = data.weapons[id]
	var lvl: int = int(weapons[id].level)
	return float(w.cooldown) * pow(float(rules.weaponLevelSpeed), float(lvl - 1)) / float(stat.aspd)


func alive_count() -> int:
	return enemies.size()


func state_hash() -> int:
	var parts := [tick_count, gold, int(tower_hp * 100.0), state, stats.kills, enemies.size(), weapons.size(), upgrades.size()]
	for e in enemies.values():
		parts.append(int(e.hp * 100.0))
		parts.append(int(e.pos.x * 1000.0))
	return str(parts).hash()


# ---------------------------------------------------------------- simulation

func tick() -> void:
	if state != "running":
		return
	tick_count += 1
	time += DT
	clear_cd = maxf(0.0, clear_cd - DT)
	invuln_t = maxf(0.0, invuln_t - DT)
	_phoenix_cd = maxf(0.0, _phoenix_cd - DT)
	_update_economy()
	_update_round()
	_update_spawns()
	_update_weapons()
	_update_shots()
	_update_enemies()
	_cleanup()
	_update_tower()
	if state == "running" and time >= float(rules.winTime):
		state = "won"
		_event({"type": "won"})


func _update_economy() -> void:
	_gold_frac += float(stat.income) * DT
	if _gold_frac >= 1.0:
		var g := int(floor(_gold_frac))
		_gold_frac -= float(g)
		gold += g
		stats.gold_earned += g


func _update_round() -> void:
	_round_clock += DT
	if _round_clock + 0.0001 >= float(rules.roundSeconds):
		_round_clock = 0.0
		round_no += 1
		reroll_count = 0
		var rg := int(stat.roundGold)
		if rg > 0:
			gold += rg
			stats.gold_earned += rg
		_roll_offers()
		_event({"type": "round", "round": round_no})


func _update_tower() -> void:
	if tower_hp <= 0.0:
		return
	tower_hp = minf(tower_max, tower_hp + float(stat.regen) * DT)
	_shield_t += DT
	var smax := float(stat.shield)
	if smax > 0.0 and _shield_t >= float(rules.tower.shieldDelay):
		shield = minf(smax, shield + smax * 0.25 * DT)


func _update_spawns() -> void:
	var m := minute()
	var diff_budget := 0.8 + 0.2 * strength
	_budget = minf(_budget + (float(rules.spawn.base) + float(rules.spawn.perMinute) * m) * diff_budget * DT, 60.0)
	var guard := 0
	while guard < 6 and enemies.size() < int(rules.maxEnemies):
		guard += 1
		# the next enemy is chosen first and waited for, so that expensive kinds are not starved by the cheap ones
		if _next_def.is_empty():
			_next_def = _pick_enemy(m)
		if _next_def.is_empty() or _budget < float(_next_def.cost):
			break
		_budget -= float(_next_def.cost)
		_spawn_pack(_next_def)
		_next_def = {}
	if time >= _next_wagon:
		_next_wagon += float(rules.wagon.every)
		_spawn_pack(data.enemies.wagon)
		_event({"type": "wagon"})
	var bosses: Array = rules.bosses
	if _boss_index < bosses.size() and time >= float(bosses[_boss_index].time):
		_spawn_pack(data.enemies[bosses[_boss_index].enemy])
		_boss_index += 1
		_event({"type": "boss"})


func _pick_enemy(m: float) -> Dictionary:
	var total := 0.0
	for e in data.enemies.values():
		if float(e.weight) > 0.0 and float(e.from) <= m:
			total += float(e.weight)
	if total <= 0.0:
		return {}
	var r := rng.randf() * total
	for e in data.enemies.values():
		if float(e.weight) > 0.0 and float(e.from) <= m:
			r -= float(e.weight)
			if r <= 0.0:
				return e
	return {}


func _spawn_pack(def: Dictionary) -> void:
	var angle := rng.randf() * TAU
	var base := Vector2.from_angle(angle) * float(rules.spawnRadius)
	for i in int(def.pack):
		_spawn_enemy(def, base + Vector2(rng.randf_range(-0.8, 0.8), rng.randf_range(-0.8, 0.8)) if int(def.pack) > 1 else base)


func _spawn_enemy(def: Dictionary, pos: Vector2) -> void:
	var m := minute()
	var sc: Dictionary = rules.scale
	var hp_scale := pow(float(sc.hpPerMinute), m)
	if m > float(sc.lateHpAfter):
		hp_scale *= pow(float(sc.lateHpPerMinute), m - float(sc.lateHpAfter))
	var e := Enemy.new()
	e.id = _next_id
	_next_id += 1
	e.def = def
	e.max_hp = float(def.hp) * hp_scale * strength
	e.hp = e.max_hp
	e.dmg = float(def.dmg) * pow(float(sc.dmgPerMinute), m) * (0.8 + 0.2 * strength)
	e.speed = float(def.speed)
	e.armor = float(def.armor) + 0.4 * m
	e.radius = float(def.radius)
	e.bounty = int(round(float(def.bounty) * pow(float(sc.bountyPerMinute), m)))
	e.boss = bool(def.boss)
	e.wagon = bool(def.wagon)
	e.pos = pos
	e.prev = pos
	e.atk_t = rng.randf() * float(def.atkCd)
	var tr: float = float(rules.tower.radius)
	if float(def.range) > 1.0:
		e.stop = tr + float(def.range)
	else:
		e.stop = tr + e.radius + float(def.range) + rng.randf() * 0.9
	if e.wagon:
		# runs past the tower to the other side of the arena
		e.dest = (-pos).rotated(rng.randf_range(-0.4, 0.4))
	enemies[e.id] = e


# ---------------------------------------------------------------- weapons

func _update_weapons() -> void:
	blades.clear()
	for id in weapons.keys():
		var w: Dictionary = data.weapons[id]
		var st: Dictionary = weapons[id]
		var lvl: int = int(st.level)
		if w.kind == "orbit":
			_update_orbit(id, w, st, lvl)
			continue
		st.cd -= DT
		if st.cd > 0.0:
			continue
		var fired := _fire(id, w, lvl)
		st.cd = weapon_interval(id) if fired else 0.15


func _update_orbit(id: String, w: Dictionary, st: Dictionary, lvl: int) -> void:
	var n: int = int(w.blades) + (lvl - 1) / 2
	st.angle += float(w.spin) * float(stat.aspd) * DT
	var orbit_r: float = float(w.range) * float(stat.range)
	var dmg := weapon_damage(id)
	for i in n:
		var p := Vector2.from_angle(float(st.angle) + TAU * float(i) / float(n)) * orbit_r
		blades.append(p)
		for e in enemies.values():
			if not e.alive:
				continue
			if p.distance_to(e.pos) <= float(w.size) + e.radius and float(e.hit_until.get(id, 0.0)) <= time:
				e.hit_until[id] = time + weapon_interval(id)
				_hurt(e, _roll(dmg), w.dtype)


func _fire(id: String, w: Dictionary, lvl: int) -> bool:
	var rng_r := weapon_range(id)
	match w.kind:
		"projectile":
			var t := _nearest(Vector2.ZERO, rng_r)
			if t == null:
				return false
			var s := Shot.new()
			var dir: Vector2 = (t.pos - Vector2.ZERO).normalized()
			if w.has("jitter"):
				dir = dir.rotated(rng.randf_range(-float(w.jitter), float(w.jitter)))
			s.dir = dir
			s.speed = float(w.speed) * float(stat.range)
			s.dmg = _roll(weapon_damage(id))
			s.dtype = w.dtype
			s.pierce = int(w.pierce) + (lvl - 1) / 2
			s.ttl = rng_r * 1.3 / s.speed + 0.15
			s.wid = id
			s.poison = float(w.get("poison", 0.0)) * (1.0 + float(rules.weaponLevelDamage) * float(lvl - 1)) * float(stat.dmg)
			s.poison_t = float(w.get("poisonTime", 0.0))
			shots.append(s)
			return true
		"chain":
			var first := _nearest(Vector2.ZERO, rng_r)
			if first == null:
				return false
			var hit := {first.id: true}
			var cur: Enemy = first
			var d := _roll(weapon_damage(id))
			_hurt(first, d, w.dtype)
			_event({"type": "zap", "from": Vector2.ZERO, "to": first.pos})
			for i in int(w.bounces) + (lvl - 1) / 2:
				var nxt: Enemy = null
				var best := INF
				for e in enemies.values():
					if not e.alive or hit.has(e.id):
						continue
					var dist: float = cur.pos.distance_to(e.pos)
					if dist <= float(w.chainRange) and dist < best:
						best = dist
						nxt = e
				if nxt == null:
					break
				d *= 0.85
				hit[nxt.id] = true
				_event({"type": "zap", "from": cur.pos, "to": nxt.pos})
				_hurt(nxt, d, w.dtype)
				cur = nxt
			return true
		"artillery":
			var shots_n: int = int(w.get("count", 1))
			var fired := false
			for i in shots_n:
				var t2 := _random_enemy(rng_r)
				if t2 == null:
					break
				var sh := Shell.new()
				sh.from = Vector2.ZERO
				sh.to = t2.pos
				sh.t_total = float(w.flight)
				sh.t_left = sh.t_total
				sh.dmg = _roll(weapon_damage(id))
				sh.splash = float(w.splash)
				sh.dtype = w.dtype
				shells.append(sh)
				fired = true
			return fired
		"aura":
			var dmg := weapon_damage(id)
			for e in enemies.values():
				if not e.alive or e.pos.length() > rng_r:
					continue
				_hurt(e, dmg, w.dtype)
				if float(w.slow) > 0.0 and e.alive:
					e.slow_amt = maxf(e.slow_amt, float(w.slow))
					e.slow_t = maxf(e.slow_t, float(w.slowTime))
				if w.has("burn") and e.alive:
					e.burn_dps = maxf(e.burn_dps, float(w.burn) * (1.0 + float(rules.weaponLevelDamage) * float(lvl - 1)) * float(stat.dmg))
					e.burn_t = 1.5
			_event({"type": "pulse", "wid": id, "radius": rng_r})
			return true
		"mine":
			var cap: int = int(w.maxMines) + (lvl - 1) / 2
			if mines.size() >= cap:
				return false
			var m := Mine.new()
			m.pos = Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(1.8, rng_r)
			m.dmg = _roll(weapon_damage(id))
			m.splash = float(w.splash)
			m.life = float(w.mineLife)
			m.dtype = w.dtype
			mines.append(m)
			return true
		"glaive":
			var tg := _nearest(Vector2.ZERO, rng_r)
			if tg == null:
				return false
			var g := Shot.new()
			g.disc = true
			g.dir = tg.pos.normalized()
			g.speed = float(w.speed)
			g.dmg = _roll(weapon_damage(id))
			g.dtype = w.dtype
			g.wid = id
			g.out_left = rng_r
			g.heal = float(w.heal)
			g.ttl = 99.0
			shots.append(g)
			return true
		"strike":
			var n: int = int(w.count) + (lvl - 1) / 2
			var pool: Array = []
			for e in enemies.values():
				if e.alive and e.pos.length() <= rng_r:
					pool.append(e)
			if pool.is_empty():
				return false
			var dmg2 := weapon_damage(id)
			for i in mini(n, pool.size()):
				var k := rng.randi_range(0, pool.size() - 1)
				var tgt: Enemy = pool[k]
				pool.remove_at(k)
				_event({"type": "strike", "pos": tgt.pos})
				_hurt(tgt, _roll(dmg2), w.dtype)
			return true
	return false


func _update_shots() -> void:
	var keep: Array = []
	for s in shots:
		s.prev = s.pos
		var step: float = s.speed * DT
		if s.disc:
			if not s.back:
				s.pos += s.dir * step
				s.out_left -= step
				if s.out_left <= 0.0:
					s.back = true
					s.hit.clear()
			else:
				var to: Vector2 = -s.pos
				if to.length() <= step + 0.3:
					continue
				s.dir = to.normalized()
				s.pos += s.dir * step
			for e in enemies.values():
				if e.alive and not s.hit.has(e.id) and _seg_dist(e.pos, s.prev, s.pos) <= 0.8 + e.radius:
					s.hit[e.id] = true
					_hurt(e, s.dmg, s.dtype)
					if s.heal > 0.0:
						tower_hp = minf(tower_max, tower_hp + s.heal)
			keep.append(s)
			continue
		s.pos += s.dir * step
		s.ttl -= DT
		var done: bool = s.ttl <= 0.0
		for e in enemies.values():
			if not e.alive or s.hit.has(e.id):
				continue
			if _seg_dist(e.pos, s.prev, s.pos) <= 0.3 + e.radius:
				s.hit[e.id] = true
				_hurt(e, s.dmg, s.dtype)
				if s.poison > 0.0 and e.alive:
					e.poison_dps = maxf(e.poison_dps, s.poison)
					e.poison_t = maxf(e.poison_t, s.poison_t)
				s.pierce -= 1
				if s.pierce < 0:
					done = true
					break
		if not done:
			keep.append(s)
	shots = keep
	# shells in the air
	var left: Array = []
	for sh in shells:
		sh.t_left -= DT
		if sh.t_left > 0.0:
			left.append(sh)
			continue
		_event({"type": "boom", "pos": sh.to, "radius": sh.splash})
		for e in enemies.values():
			if e.alive and e.pos.distance_to(sh.to) <= sh.splash + e.radius * 0.5:
				_hurt(e, sh.dmg, sh.dtype)
	shells = left
	# mines
	var armed: Array = []
	for m in mines:
		m.life -= DT
		var blown := false
		if m.life > 0.0:
			for e in enemies.values():
				if e.alive and not e.wagon and e.pos.distance_to(m.pos) <= 0.8 + e.radius:
					blown = true
					break
		if blown:
			_event({"type": "boom", "pos": m.pos, "radius": m.splash})
			for e in enemies.values():
				if e.alive and e.pos.distance_to(m.pos) <= m.splash + e.radius * 0.5:
					_hurt(e, m.dmg, m.dtype)
		elif m.life > 0.0:
			armed.append(m)
	mines = armed


func _update_enemies() -> void:
	var slow_all: float = float(stat.slowAll)
	for e in enemies.values():
		if not e.alive:
			continue
		e.prev = e.pos
		if e.poison_t > 0.0:
			e.poison_t -= DT
			_hurt(e, e.poison_dps * DT, "magic")
			if not e.alive:
				continue
		if e.burn_t > 0.0:
			e.burn_t -= DT
			_hurt(e, e.burn_dps * DT, "magic")
			if not e.alive:
				continue
		e.slow_t -= DT
		if e.slow_t <= 0.0:
			e.slow_amt = 0.0
		var step: float = e.speed * (1.0 - minf(e.slow_amt + slow_all, 0.85)) * DT
		if e.wagon:
			var to_dest: Vector2 = e.dest - e.pos
			if to_dest.length() <= step + 0.3:
				e.alive = false
				stats.leaks += 1
				_event({"type": "escaped", "pos": e.pos})
			else:
				e.pos += to_dest.normalized() * step
			continue
		var d: float = e.pos.length()
		if d > e.stop:
			e.pos -= e.pos / d * minf(step, d - e.stop)
			continue
		e.atk_t -= DT
		if e.atk_t <= 0.0:
			e.atk_t = float(e.def.atkCd)
			if float(e.def.range) > 1.0:
				_event({"type": "shot", "from": e.pos})
			_hit_tower(e.dmg, e)


func _hit_tower(raw: float, attacker: Enemy) -> void:
	if invuln_t > 0.0 or state != "running":
		return
	var d := maxf(1.0, raw - float(stat.block))
	d *= 1.0 - armor_reduction(float(stat.armor))
	if float(stat.thorns) > 0.0 and attacker != null and attacker.alive:
		_hurt(attacker, float(stat.thorns), "magic")
		if float(stat.thornsHeal) > 0.0:
			tower_hp = minf(tower_max, tower_hp + float(stat.thornsHeal))
	_shield_t = 0.0
	if shield > 0.0:
		var take := minf(shield, d)
		shield -= take
		d -= take
	tower_hp -= d
	_event({"type": "tower_hit"})
	if tower_hp <= 0.0:
		if bool(stat.phoenix) and _phoenix_cd <= 0.0:
			_phoenix_cd = float(rules.tower.phoenixRest)
			_rise()
		elif bool(stat.ankh) and not _ankh_used:
			_ankh_used = true
			_rise()
		else:
			tower_hp = 0.0
			state = "lost"
			lost_reason = "tower"
			_event({"type": "lost"})


func _rise() -> void:
	tower_hp = tower_max
	invuln_t = 2.0
	for e in enemies.values():
		if e.alive and not e.boss and e.pos.length() < 4.0:
			e.alive = false
	_event({"type": "revived"})


func _hurt(e: Enemy, raw: float, dtype: String) -> void:
	if not e.alive:
		return
	var d := raw
	if dtype == "phys":
		d *= 1.0 - armor_reduction(e.armor)
	e.hp -= d
	stats.damage += d
	if e.hp <= 0.0:
		_kill(e)


func _kill(e: Enemy) -> void:
	e.alive = false
	var g := int(round(float(e.bounty) * float(stat.bounty)))
	gold += g
	stats.gold_earned += g
	stats.kills += 1
	_event({"type": "kill", "pos": e.pos, "gold": g, "boss": e.boss})


func _cleanup() -> void:
	for id in enemies.keys():
		if not enemies[id].alive:
			enemies.erase(id)


func _roll(base: float) -> float:
	if float(stat.crit) > 0.0 and rng.randf() < float(stat.crit):
		_event({"type": "crit"})
		return base * float(stat.critMult)
	return base


func _nearest(from: Vector2, limit: float) -> Enemy:
	var best: Enemy = null
	var best_d := limit
	for e in enemies.values():
		if not e.alive:
			continue
		var d: float = from.distance_to(e.pos)
		if d <= best_d:
			best_d = d
			best = e
	return best


func _random_enemy(limit: float) -> Enemy:
	var pool: Array = []
	for e in enemies.values():
		if e.alive and e.pos.length() <= limit:
			pool.append(e)
	if pool.is_empty():
		return null
	return pool[rng.randi_range(0, pool.size() - 1)]


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 0.000001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_to(a + ab * t)


# ---------------------------------------------------------------- shop and stats

func _item(o: Dictionary) -> Dictionary:
	return data.weapons[o.id] if o.kind == "weapon" else data.upgrades[o.id]


func _recalc() -> void:
	var t: Dictionary = rules.tower
	var s := {"dmg": 1.0, "aspd": 1.0, "crit": 0.0, "critMult": float(t.critMult), "armor": float(t.armor), "block": 0.0,
			"regen": float(t.regen), "maxHp": float(t.hp), "thorns": 0.0, "thornsHeal": 0.0, "income": float(rules.baseIncome),
			"roundGold": 0.0, "bounty": 1.0, "range": 1.0, "shield": 0.0, "slowAll": 0.0, "phoenix": false, "ankh": false}
	for id in upgrades.keys():
		var lvl: int = int(upgrades[id])
		var st: Dictionary = data.upgrades[id].stat
		for k in st:
			var v := float(st[k]) * float(lvl)
			match k:
				"heal":
					pass
				"phoenix":
					s.phoenix = true
				"ankh":
					s.ankh = true
				_:
					s[k] = float(s[k]) + v
	stat = s
	var was_max := tower_max
	tower_max = float(s.maxHp)
	if was_max > 0.0 and tower_max > was_max:
		tower_hp += tower_max - was_max
	tower_hp = minf(tower_hp, tower_max)
	shield = minf(shield, float(s.shield))


func _odds() -> Array:
	var m := minute()
	var w: Array = rules.shopOdds[0].w
	for o in rules.shopOdds:
		if m >= float(o.from):
			w = o.w
	return w


func _roll_offers() -> void:
	offers.clear()
	var odds: Array = _odds()
	var rarities: Array = data.rarities
	var tries := 0
	while offers.size() < int(rules.shopSlots) and tries < 80:
		tries += 1
		var r := rng.randf() * 100.0
		var rarity := 0
		for i in odds.size():
			r -= float(odds[i])
			if r <= 0.0:
				rarity = i
				break
		var kind := "weapon" if rng.randf() < float(rules.weaponShare) else "upgrade"
		var pool := _candidates(kind, rarity)
		if pool.is_empty():
			kind = "upgrade" if kind == "weapon" else "weapon"
			pool = _candidates(kind, rarity)
		if pool.is_empty():
			continue
		var pick: String = pool[rng.randi_range(0, pool.size() - 1)]
		var dup := false
		for o in offers:
			if o.kind == kind and o.id == pick:
				dup = true
		if dup:
			continue
		offers.append({"kind": kind, "id": pick, "bought": false})
	_event({"type": "shop"})


func _candidates(kind: String, rarity: int) -> Array:
	var out: Array = []
	if kind == "weapon":
		for id in data.weapons:
			var w: Dictionary = data.weapons[id]
			if int(w.rarity) != rarity:
				continue
			var owned: bool = weapons.has(id)
			if owned and int(weapons[id].level) >= int(rules.maxWeaponLevel):
				continue
			if not owned and weapons.size() >= int(rules.maxWeapons):
				continue
			out.append(id)
	else:
		for id in data.upgrades:
			var u: Dictionary = data.upgrades[id]
			if int(u.rarity) != rarity or int(upgrades.get(id, 0)) >= int(u.max):
				continue
			out.append(id)
	return out


func _err(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}


func _event(e: Dictionary) -> void:
	if record_events:
		events.append(e)
