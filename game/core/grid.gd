extends RefCounted
## Cell grid with static terrain and tower occupancy, plus flow-field pathing towards the goal.
## A cell is half a tile (cell_size = 0.5), positions elsewhere are in tiles.

const WALL := 1
const NOBUILD := 2
const TOWER := 4
const SQRT2 := 1.4142135
const CLEARANCE_PENALTY := 1.2   # extra cost of a step onto a cell next to a wall or tower: creeps keep to the middle of gaps

const DIRS := [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]

var w: int
var h: int
var cell_size: float
var flags := PackedByteArray()
var goal_cells := PackedInt32Array()
var goal_center := Vector2.ZERO
var dist := PackedFloat32Array()      # path cost to the goal in cells, INF when unreachable
var next_cell := PackedInt32Array()   # next cell on the way to the goal, -1 at the goal or when unreachable


func _init(map: Dictionary) -> void:
	w = int(map.width)
	h = int(map.height)
	cell_size = float(map.cellSize)
	flags.resize(w * h)
	for y in h:
		var row: String = map.rows[y]
		for x in w:
			var c := row[x]
			flags[y * w + x] = WALL if c == "#" else (NOBUILD if c == "," else 0)
	var g: Array = map.goal.rect
	for y in range(int(g[1]), int(g[3]) + 1):
		for x in range(int(g[0]), int(g[2]) + 1):
			goal_cells.append(y * w + x)
	goal_center = Vector2((float(g[0]) + float(g[2]) + 1.0) * 0.5 * cell_size, (float(g[1]) + float(g[3]) + 1.0) * 0.5 * cell_size)
	recompute()


func idx(x: int, y: int) -> int:
	return y * w + x


func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < w and y < h


func walkable(i: int) -> bool:
	return (flags[i] & (WALL | TOWER)) == 0


func is_goal(i: int) -> bool:
	return goal_cells.has(i)


func cell_center(i: int) -> Vector2:
	return Vector2((float(i % w) + 0.5) * cell_size, (float(i / w) + 0.5) * cell_size)


func cell_of(p: Vector2) -> int:
	var x := clampi(int(floor(p.x / cell_size)), 0, w - 1)
	var y := clampi(int(floor(p.y / cell_size)), 0, h - 1)
	return y * w + x


## Reason why a footprint (fw x fh cells, top-left cx, cy) cannot be built on, or "" when it is free.
func footprint_problem(cx: int, cy: int, fw: int, fh: int) -> String:
	if not in_bounds(cx, cy) or not in_bounds(cx + fw - 1, cy + fh - 1):
		return "bounds"
	for y in range(cy, cy + fh):
		for x in range(cx, cx + fw):
			var f := flags[y * w + x]
			if f & TOWER:
				return "occupied"
			if f & (WALL | NOBUILD):
				return "terrain"
	return ""


func set_footprint(cx: int, cy: int, fw: int, fh: int, on: bool) -> void:
	for y in range(cy, cy + fh):
		for x in range(cx, cx + fw):
			if on:
				flags[y * w + x] |= TOWER
			else:
				flags[y * w + x] &= ~TOWER


## True when every required cell can still reach the goal with the footprint blocked (anti-block check).
func stays_connected(cx: int, cy: int, fw: int, fh: int, required: PackedInt32Array) -> bool:
	set_footprint(cx, cy, fw, fh, true)
	var ok := _reach_all(required)
	set_footprint(cx, cy, fw, fh, false)
	return ok


## Average path length (in tiles) of the given start cells with the footprint blocked, or -1 when blocked.
func path_length_with(cx: int, cy: int, fw: int, fh: int, starts: PackedInt32Array) -> float:
	set_footprint(cx, cy, fw, fh, true)
	var d := PackedFloat32Array()
	var n := PackedInt32Array()
	_compute(d, n)
	set_footprint(cx, cy, fw, fh, false)
	return _avg_length(d, n, starts)


func path_length(starts: PackedInt32Array) -> float:
	return _avg_length(dist, next_cell, starts)


## Average walked length in tiles, following the flow field (the weighted costs are only for steering).
func _avg_length(d: PackedFloat32Array, n: PackedInt32Array, starts: PackedInt32Array) -> float:
	if starts.is_empty():
		return 0.0
	var total := 0.0
	for s in starts:
		if is_inf(d[s]):
			return -1.0
		var cur: int = s
		var guard := 0
		while n[cur] >= 0 and guard < 4000:
			guard += 1
			var nxt: int = n[cur]
			var dx: int = absi(nxt % w - cur % w)
			var dy: int = absi(nxt / w - cur / w)
			total += SQRT2 if (dx != 0 and dy != 0) else 1.0
			cur = nxt
	return total / float(starts.size()) * cell_size


func recompute() -> void:
	_compute(dist, next_cell)


func _step_ok(x: int, y: int, d: Vector2i) -> bool:
	var nx := x + d.x
	var ny := y + d.y
	if not in_bounds(nx, ny) or not walkable(ny * w + nx):
		return false
	if d.x != 0 and d.y != 0:
		# no corner cutting: both orthogonal neighbours must be free as well
		return walkable(y * w + nx) and walkable(ny * w + x)
	return true


func _near_blocked(i: int) -> bool:
	var x := i % w
	var y := i / w
	for d in DIRS:
		var nx: int = x + d.x
		var ny: int = y + d.y
		if not in_bounds(nx, ny) or (flags[ny * w + nx] & (WALL | TOWER)) != 0:
			return true
	return false


func _reach_all(required: PackedInt32Array) -> bool:
	var seen := PackedByteArray()
	seen.resize(w * h)
	var queue := PackedInt32Array()
	for g in goal_cells:
		seen[g] = 1
		queue.append(g)
	var head := 0
	while head < queue.size():
		var u := queue[head]
		head += 1
		var ux := u % w
		var uy := u / w
		for d in DIRS:
			if _step_ok(ux, uy, d):
				var v: int = (uy + d.y) * w + ux + d.x
				if seen[v] == 0:
					seen[v] = 1
					queue.append(v)
	for r in required:
		if seen[r] == 0:
			return false
	return true


func _compute(out_dist: PackedFloat32Array, out_next: PackedInt32Array) -> void:
	var n := w * h
	out_dist.resize(n)
	out_dist.fill(INF)
	out_next.resize(n)
	out_next.fill(-1)
	var in_q := PackedByteArray()
	in_q.resize(n)
	var queue := PackedInt32Array()
	for g in goal_cells:
		out_dist[g] = 0.0
		queue.append(g)
		in_q[g] = 1
	var head := 0
	while head < queue.size():
		if head > 8192:
			queue = queue.slice(head)
			head = 0
		var u := queue[head]
		head += 1
		in_q[u] = 0
		var ux := u % w
		var uy := u / w
		var du := out_dist[u]
		for d in DIRS:
			if not _step_ok(ux, uy, d):
				continue
			var v: int = (uy + d.y) * w + ux + d.x
			var c := du + (SQRT2 if (d.x != 0 and d.y != 0) else 1.0)
			if _near_blocked(v):
				c += CLEARANCE_PENALTY
			if c < out_dist[v]:
				out_dist[v] = c
				out_next[v] = u
				if in_q[v] == 0:
					in_q[v] = 1
					queue.append(v)
