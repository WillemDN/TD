extends SceneTree
## Dev tool: renders every tower and monster model in a grid and saves PNGs.
## Run: godot --path game --rendering-driver opengl3 --script res://tests/model_gallery.gd -- <output dir>

const Models := preload("res://client/models.gd")
const GameData := preload("res://core/game_data.gd")


func _init() -> void:
	await process_frame
	var out := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "/tmp"
	DisplayServer.window_set_size(Vector2i(1400, 800))
	root.size = Vector2i(1400, 800)
	var data = GameData.load_all()
	var world := Node3D.new()
	root.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("c9d8ea")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c0d0e8")
	env.ambient_light_energy = 0.9
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.95, -0.7, 0.0)
	world.add_child(sun)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	world.add_child(cam)
	var colors := {}
	for e in data.elements:
		colors[e.id] = Color(e.color)
	colors["ultimate"] = Color("bff6ff")
	# creeps
	var i := 0
	for cid in data.creeps:
		var n := Models.make_creep(cid, data.creeps[cid])
		n.position = Vector3(float(i % 12) * 1.6, 0, float(i / 12) * 1.8)
		world.add_child(n)
		i += 1
	# towers: all tiers of every element
	var row := 3
	for e in data.elements:
		var col := 0
		for tid in e.towers:
			var t := Models.make_tower(data.towers[tid], colors[e.id])
			t.position = Vector3(float(col) * 1.6, 0, float(row) * 1.8 + 1.0)
			world.add_child(t)
			col += 1
		row += 1
	var u := Models.make_tower(data.towers[data.ultimate], colors["ultimate"])
	u.position = Vector3(11 * 1.6, 0, 4.0 * 1.8)
	world.add_child(u)
	# build stages
	for s in 6:
		var b := Models.make_tower(data.towers["frost_shard"], colors["ice"])
		Models.set_build_progress(b, float(s) / 6.0 + 0.01)
		b.position = Vector3(float(s) * 1.6, 0, 13.5 * 1.8)
		world.add_child(b)
	for part in [[0, 2.2, "a"], [1, 2.2, "b"]]:
		pass
	var shots := [
		["creeps_a", Vector3(4.8, 0, 1.2), 6.5], ["creeps_b", Vector3(14.4, 0, 1.2), 6.5],
		["creeps_c", Vector3(4.8, 0, 3.6), 5.0], ["towers_a", Vector3(4.0, 0, 8.6), 8.5],
		["towers_b", Vector3(4.0, 0, 15.2), 8.5], ["towers_c", Vector3(4.0, 0, 21.8), 8.5],
	]
	for sh in shots:
		var p: Vector3 = sh[1]
		cam.size = sh[2]
		cam.rotation = Vector3(-0.96, 0, 0)
		cam.position = p + Vector3(0, sin(0.96), cos(0.96)) * 30.0
		for k in 4:
			await process_frame
		root.get_texture().get_image().save_png("%s/gallery_%s.png" % [out, sh[0]])
	print("gallery saved")
	quit()
