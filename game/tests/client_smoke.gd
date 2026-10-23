extends SceneTree
## Smoke test of the real client (3D view, HUD, overlay) while a bot plays through air waves and bosses.
## Run: godot --headless --path game --script res://tests/client_smoke.gd
## Exit code 1 when a bot does not reach level 13. Engine script errors show up in the log, so read the output.

const Bot := preload("res://tests/bot.gd")
const BotElements := preload("res://tests/bot_elements.gd")
const BotSurvivor := preload("res://tests/bot_survivor.gd")


func _init() -> void:
	await process_frame
	var main = load("res://client/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var bad := 0
	for element in ["electric", "crystal", "ice"]:
		main._play("classic", "easy")
		var sim = main.sim
		sim.gold = 6000
		sim.lumber = 3
		var bot = Bot.new(element)
		bot.step(sim)
		main.active_element = element
		main.build_id = ""
		var frames := 0
		while sim.level < 13 and sim.state != "lost" and frames < 20000:
			if frames % 20 == 0:
				bot.step(sim)
				sim.gold += 400
			main._process(1.0 / 20.0)
			frames += 1
			if frames % 400 == 0:
				main._on_tower_chosen(sim.data.element_of(element).towers[0])
				main._set_ghost(Vector2i(60 + frames % 30, 30))
				main._cancel()
		print("%s: level %d state %s towers %d creeps %d frames %d" % [element, sim.level, sim.state, sim.towers.size(), sim.creeps.size(), frames])
		if sim.level < 13:
			bad += 1
	# the mode elements: the client switches data, the tray has the mixed tabs, and the view keeps up with a long wave
	main._play("elements", "easy")
	var esim = main.sim
	esim.gold = 4000
	esim.lumber = 4
	var ebot = BotElements.new(["fire", "water", "nature", "earth"])
	var eframes := 0
	while esim.level < 11 and esim.state != "lost" and eframes < 30000:
		if eframes % 20 == 0:
			ebot.step(esim)
			esim.gold += 300
			esim.cleared = maxi(esim.cleared, esim.level)
		main._process(1.0 / 20.0)
		eframes += 1
		if eframes % 500 == 0:
			main._on_element_chosen("g:dual")
		if eframes % 700 == 0:
			main._on_element_chosen("fire")
			main._on_tower_chosen("fire_1")
			main._set_ghost(Vector2i(20 + eframes % 40, 8))
			main._cancel()
	print("elements: level %d state %s towers %d creeps %d frames %d" % [esim.level, esim.state, esim.towers.size(), esim.creeps.size(), eframes])
	if esim.level < 11 or main.data.mode != "elements":
		bad += 1
	# the mode survivor: own simulation and interface, then back to a tower defence mode
	main._play("survivor", "easy")
	var game = main.survivor
	var ssim = game.sim
	var sbot = BotSurvivor.new()
	var sframes := 0
	while ssim.time < 150.0 and ssim.state == "running" and sframes < 5000:
		if sframes % 20 == 0:
			sbot.step(ssim)
		main._process(1.0 / 20.0)
		game._process(1.0 / 20.0)
		sframes += 1
		if sframes % 300 == 0:
			game.shud.select_card(sframes / 300 % 5)
		if sframes % 600 == 0:
			game._reroll()
	print("survivor: %.0f s state %s weapons %d enemies %d frames %d" % [ssim.time, ssim.state, ssim.weapons.size(), ssim.enemies.size(), sframes])
	if ssim.time < 150.0 or main.sim != null:
		bad += 1
	# the shop cards must survive a few frames of fighting: a card replaced between press and release swallows the tap
	var card_ids: Array = game.shud._card_buttons.map(func(c): return c.get_instance_id())
	for i in 5:
		main._process(1.0 / 20.0)
		game._process(1.0 / 20.0)
	if card_ids != game.shud._card_buttons.map(func(c): return c.get_instance_id()):
		print("survivor: shop cards were rebuilt while nothing changed")
		bad += 1
	main._play("classic", "easy")
	if main.survivor != null or main.sim == null or main.data.mode != "classic":
		bad += 1
	quit(bad)
