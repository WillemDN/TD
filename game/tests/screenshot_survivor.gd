extends SceneTree
## Dev tool: screenshots of the mode "survivor" (menu, arena with a fight, the shop with an info sheet).
## Run: godot --path game --rendering-driver opengl3 --script res://tests/screenshot_survivor.gd -- <output dir> [phone]

const BotSurvivor := preload("res://tests/bot_survivor.gd")

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
	main.hud.mode = "survivor"
	main.hud._refresh_menu()
	await _frames(4)
	await _shot("s1_menu")
	main._play("survivor", "normal")
	await _frames(6)
	await _shot("s2_start")
	var game = main.survivor
	var sim = game.sim
	var bot = BotSurvivor.new()
	for i in 20 * 200:
		if i % 20 == 0:
			bot.step(sim)
		sim.tick()
	sim.gold += 400
	await _frames(8)
	await _shot("s3_fight")
	game.shud.select_card(1)
	await _frames(6)
	await _shot("s4_card")
	sim.time = 245.0
	for i in 20 * 12:
		sim.tick()
	await _frames(8)
	await _shot("s5_boss")
	quit()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, name])
	print("saved ", name, " ", img.get_size())
