extends Control
## Minimap: the whole map at a glance (towers, monsters, the part of the map on screen). Tap or drag to move the camera.

signal focus_requested(tile)

var sim
var world
var _terrain: ImageTexture
var _map_tiles := Vector2.ONE
var _dragging := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(150, 94)


func setup(p_sim, p_world, data) -> void:
	sim = p_sim
	world = p_world
	_map_tiles = Vector2(float(sim.grid.w), float(sim.grid.h)) * sim.grid.cell_size
	var img := Image.create(sim.grid.w, sim.grid.h, false, Image.FORMAT_RGBA8)
	var g: Array = data.map.goal.rect
	for y in sim.grid.h:
		var row: String = data.map.rows[y]
		for x in sim.grid.w:
			var c := row[x]
			var col := Color("e6eef8")
			if c == "#":
				col = Color("27403f")
			elif c == ",":
				col = Color("9fb3c8")
				if x >= int(g[0]) - 2:
					col = Color("a98e6a")
			img.set_pixel(x, y, col)
	_terrain = ImageTexture.create_from_image(img)
	queue_redraw()


func _to_tile(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x / size.x, 0.0, 1.0), clampf(p.y / size.y, 0.0, 1.0)) * _map_tiles


func _to_mini(tile: Vector2) -> Vector2:
	return Vector2(tile.x / _map_tiles.x * size.x, tile.y / _map_tiles.y * size.y)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if event.pressed:
			focus_requested.emit(_to_tile(event.position))
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		focus_requested.emit(_to_tile(event.position))
		accept_event()


func _draw() -> void:
	if sim == null or _terrain == null:
		return
	draw_texture_rect(_terrain, Rect2(Vector2.ZERO, size), false)
	for t in sim.towers.values():
		var p := _to_mini(t.center)
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color("5cc8ff") if not t.building else Color("8aa0b8"))
	for c in sim.creeps.values():
		var p := _to_mini(c.pos)
		var col := Color("ff5a5a") if not c.air else Color("ffe45a")
		var r := 2.2 if not c.boss else 4.0
		draw_circle(p, r, col)
	var vr: Rect2 = world.view_rect()
	var a := _to_mini(vr.position)
	var b := _to_mini(vr.end)
	draw_rect(Rect2(a, b - a).intersection(Rect2(Vector2.ZERO, size)), Color(1, 1, 1, 0.9), false, 1.5)
	draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.25), false, 1.0)
