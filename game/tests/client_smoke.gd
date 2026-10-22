extends SceneTree
## Smoke test of the real client (3D view, HUD, overlay) while a bot plays through air waves and bosses.
## Run: godot --headless --path game --script res://tests/client_smoke.gd
## Exit code 1 when a bot does not reach level 13. Engine script errors show up in the log, so read the output.

const Bot := preload("res://tests/bot.gd")


func _init() -> void:
	await process_frame
	var main = load("res://client/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var bad := 0
	for element in ["electric", "crystal", "ice"]:
		main._play("easy")
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
	quit(bad)
