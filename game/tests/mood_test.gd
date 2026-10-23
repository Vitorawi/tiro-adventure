extends SceneTree
## Estado calculado e ajudas reais, com relógio injetável e save atual descartável.
var state: Node
var db: Node
var failures := 0
var notices: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("MOOD: " + message)

func fresh(animated: bool = true) -> void:
	state.set_clock(1792746000.0)
	state.reset()
	state.set_process(false)
	state.growth.taste_seed = 42
	for id: String in db.needs: state.dog.needs[id] = 100.0
	if not animated: state.dog.needs.happiness = 40.0
	notices.clear()

func crop(seed_time: int) -> Dictionary:
	state.progress.owned.farm = true
	state.plant(0, "carrot")
	state.plots[0].planted_at = seed_time
	state.plots[0].ready_at = state.now() - 1
	return state.plot_job(0).get("yield", {}).duplicate()

func _run() -> void:
	root.size = Vector2i(360, 780)
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/helpers/economy_clock.gd"))
	root.get_node("Events").toast_requested.connect(func(message: String) -> void: notices.append(message))
	fresh()
	check(state.tiro_animated(), "satisfeito e acordado")
	for id: String in db.needs:
		state.dog.needs[id] = 49
		check(not state.tiro_animated(), id + " pedindo impede animado")
		state.dog.needs[id] = 50
		check(state.tiro_animated(), id + " no limiar não pede")
		state.dog.needs[id] = 100
	state.dog.sleeping = true
	check(not state.tiro_animated(), "dormindo não ajuda")
	# Encontra uma semente vencedora com a regra real; repete após save e sem espaço.
	var winner := -1
	for seed_time in 100:
		fresh()
		var normal := crop(seed_time)
		var reward: Dictionary = state.harvest(0)
		if int(reward.carrot) == int(normal.carrot) + 1:
			winner = seed_time
			break
	check(winner >= 0 and notices.has("O Tiro ajudou!"), "chance real de +1 anuncia ajuda")
	fresh()
	var normal := crop(winner)
	var saved: Dictionary = state.to_dict().duplicate(true)
	state.from_dict(saved)
	check(state.harvest(0).carrot == int(normal.carrot) + 1, "mesmo plantio após recarga mantém sorteio")
	fresh()
	normal = crop(winner)
	state.inventory.add("carrot", state.storage_capacity("silo") - int(normal.carrot))
	check(state.harvest(0) == normal and not notices.has("O Tiro ajudou!"), "lote cabe, extra não: só lote normal")
	fresh(false)
	normal = crop(winner)
	check(state.harvest(0) == normal, "sem animado colheita não muda")
	# Uma tabela de uma unidade permite contar os sorteios, sem raro/primeira volta/garantia.
	fresh()
	state.progress.claimed_quests.main_2_order = true
	state.progress.claimed_quests.nina_walk = true
	state.progress.claimed_quests.nina_meet = true
	var route: Dictionary = db.walks.walks.park_loop
	var old_loot: Dictionary = route.loot.duplicate(true)
	route.loot = {"rolls": 2, "table": [{"weight": 1, "items": {"stick": 1}}]}
	state.dog.needs.energy = 51
	check(state.start_walk("park_loop") == "", "começa animado antes de gastar energia")
	check(state.walk_state.current.snapshot.animated and not state.tiro_animated(), "saída congela animado antes do custo")
	state.dog.needs.happiness = 10
	saved = state.to_dict().duplicate(true)
	state.from_dict(saved)
	check(state.walk_loot().items.stick == 3, "snapshot atual recarregado mantém sorteio extra")
	state.advance_clock(3600)
	state.return_due_walk(false)
	check(state.walk_loot().items.stick == 3, "volta preserva bônus sem estar animado")
	fresh(false)
	state.progress.claimed_quests.main_2_order = true
	state.progress.claimed_quests.nina_walk = true
	state.progress.claimed_quests.nina_meet = true
	check(state.start_walk("park_loop") == "", "começa sem animado")
	for id: String in db.needs: state.dog.needs[id] = 100
	check(state.walk_loot().items.stick == 2, "ficar animado depois não acrescenta sorteio")
	route.loot = old_loot
	# Faro: um extra global por período, com mundo aberto e sem empilhar pendências.
	fresh()
	state.progress.claimed_quests.first_harvest = true
	state.progress.claimed_quests.bloblo_sell_surplus = true
	state.progress.claimed_quests.growth_1_puppy = true
	state.update_finds()
	state.advance_clock(21)
	state.update_finds()
	state.dig("farm")
	check(state.finds.worlds.farm.pending == 1 and state.finds.bonus_used == 1, "cavar libera um montinho extra")
	var extra_seed: int = state.finds.worlds.farm.seed
	var due: float = state.finds.worlds.farm.next_at
	saved = state.to_dict().duplicate(true)
	state.from_dict(saved)
	check(state.finds.worlds.farm.seed == extra_seed and state.finds.bonus_used == 1, "extra e limite persistem")
	state.dig("farm")
	check(state.finds.worlds.farm.pending == 0 and state.finds.worlds.farm.next_at == due, "extra não se repete nem adia montinho normal")
	state.dev_next_period()
	check(state.finds.worlds.farm.pending == 1 and state.finds.bonus_used == 1, "novo período dá um extra")
	fresh(false)
	state.progress.claimed_quests.first_harvest = true
	state.update_finds()
	state.advance_clock(21)
	state.update_finds()
	state.dig("farm")
	check(state.finds.worlds.farm.pending == 0 and state.finds.bonus_used == 0, "sem animado mantém intervalo normal")
	fresh()
	state.progress.claimed_quests.first_harvest = true
	state.update_finds()
	state.finds.worlds.farm.dug = 1
	state.update_finds()
	check(state.finds.bonus_used == 0, "mundo fechado não recebe extra")
	await ui_checks()
	print("MOOD TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)

func ui_checks() -> void:
	fresh()
	state.progress.seen.intro = true
	Motion.reduced = true
	var main: Control = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	for i in 8: await process_frame
	var hud: Control = main.get_node("TopBar")
	hud.refresh(false)
	check(hud.get_node("AvatarGroup/AnimatedBadge").visible, "HUD mostra selo Animado")
	var badge: Label = hud.get_node("AvatarGroup/AnimatedBadge")
	check(badge.size.x >= badge.get_minimum_size().x and badge.get_line_count() == 1, "selo tem largura para uma linha")
	var pop: Control = hud.show_level_popover()
	for i in 8: await process_frame
	var help: Label = pop.find_child("AnimatedHelp", true, false)
	check(help != null and help.text == state.animated_help(), "toque no avatar explica ajuda")
	if OS.get_cmdline_user_args().has("--screenshots"):
		await shot("avatar_help")
	pop.queue_free()
	for i in 8: await process_frame
	if OS.get_cmdline_user_args().has("--screenshots"): await shot("animated_reduced")
	Motion.reduced = false
	for i in 8: await process_frame
	if OS.get_cmdline_user_args().has("--screenshots"): await shot("animated")
	state.dog.needs.hunger = 40
	state._changed()
	hud.refresh(false)
	check(not hud.get_node("AvatarGroup/AnimatedBadge").visible, "HUD retira selo quando pede")
	main.queue_free()
	await process_frame

func shot(id: String) -> void:
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/cuidado05")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join(id + "_360.png"))

