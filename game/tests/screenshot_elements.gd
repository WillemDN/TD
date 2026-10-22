extends SceneTree
## Dev tool: the same as screenshot_runner.gd for the mode "elements" (menu, tray with mixed towers, a wave in progress).
## Run: godot --path game --rendering-driver opengl3 --script res://tests/screenshot_elements.gd -- <output dir> [phone]

const BotElements := preload("res://tests/bot_elements.gd")

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
	await _shot("e1_menu")
	main.hud.mode = "elements"
	main.hud._refresh_menu()
	await _frames(4)
	await _shot("e2_menu_elements")
	main._play("elements", "normal")
	await _frames(4)
	main._fit()
	var sim = main.sim
	await _frames(4)
	await _shot("e3_start")
	sim.gold = 6000
	sim.cleared = 16
	sim.lumber = 6
	var bot = BotElements.new(["fire", "water", "nature", "earth", "light", "dark"])
	for i in 6:
		bot.step(sim)
	for t in sim.towers.values():
		t.building = false
	main.active_element = "g:dual"
	main.hud._bar_sig = ""
	sim.countdown = 0.0
	await _frames(4)
	await _shot("e4_towers_dual_tab")
	for i in 20 * 25:
		sim.tick()
		if i % 40 == 0:
			bot.step(sim)
		for t in sim.towers.values():
			t.building = false
	main.speed = 1
	await _frames(6)
	await _shot("e5_wave")
	if not sim.creeps.is_empty():
		var c = sim.creeps.values()[0]
		main.world.focus_on(c.pos)
		await _frames(6)
		await _shot("e5b_creeps")
	main.active_element = "g:triple"
	main.hud._bar_sig = ""
	main.selected_id = sim.towers.keys()[0]
	main.world.select_tower(sim.towers[main.selected_id])
	await _frames(4)
	await _shot("e6_selected_triple_tab")
	quit()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, name])
	print("saved ", name, " ", img.get_size())
