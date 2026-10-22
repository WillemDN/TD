extends SceneTree
## Dev tool: starts the real game in a window, plays a few scripted moments and saves PNGs.
## Run: godot --path game --script res://tests/screenshot_runner.gd -- <output dir>

const Bot := preload("res://tests/bot.gd")

var out_dir := "/tmp"


func _init() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	var size := Vector2i(1280, 720)
	var touch := false
	if args.size() > 1 and args[1] == "phone":
		size = Vector2i(844, 390)
		touch = true
	DisplayServer.window_set_size(size)
	root.size = size
	var main = load("res://client/main.tscn").instantiate()
	root.add_child(main)
	if touch:
		main.touch_mode = true
		main._apply_ui_scale()
	await _frames(8)
	await _shot("1_menu")
	main._play("classic", "normal")
	await _frames(4)
	main._fit()
	# pick an element and build with the bot so there is something to see
	var sim = main.sim
	sim.gold = 900
	var bot = Bot.new("ice")
	for i in 10:
		bot.step(sim)
	main.active_element = "ice"
	for t in sim.towers.values():
		t.building = false
	sim.countdown = 0.0
	await _frames(4)
	await _shot("2_towers")
	for i in 20 * 14:
		sim.tick()
		if i % 40 == 0:
			bot.step(sim)
	main.speed = 2
	await _frames(6)
	await _shot("3_wave")
	main.build_id = "frost_shard"
	main._set_ghost(Vector2i(60, 30))
	await _frames(4)
	await _shot("4_ghost")
	main._cancel()
	main.selected_id = sim.towers.keys()[0]
	main.world.select_tower(sim.towers[main.selected_id])
	await _frames(4)
	await _shot("5_selected")
	quit()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, name])
	print("saved ", name, " ", img.get_size())
