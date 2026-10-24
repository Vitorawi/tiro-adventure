extends SceneTree
## Conferência visual guiada do capítulo 1. Sem campanha, sem SaveManager, sem completar missões por DEV.
var state: Node
var main: Control
var events: Node
var folder := "res://../build/screenshots/i2_05_mao/"
func _initialize() -> void: _run.call_deferred()
func frames() -> void:
	for i in 6: await process_frame
func shot(id: String) -> void:
	await frames()
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path + id + ".png")
func wait_modals() -> void:
	await frames()
	main.call("_flush_modals")
	await frames()
func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	events = root.get_node("Events")
	state.call("reset")
	state.get("progress").seen.intro = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	events.world_requested.connect(func(world: String, spot: String) -> void: print("DESTINO: ", world, "/", spot))
	events.screen_requested.connect(func(screen: StringName) -> void: print("TELA: ", screen))
	var pill := main.find_child("NextStep", true, false) as Button
	pill.pressed.emit()
	await frames()
	main.find_child("StepCardGo", true, false).pressed.emit()
	await frames()
	state.call("talk_to", "lais")
	await frames()
	for id: String in state.get("progress").main_quests(1):
		print("PASSO: ", id, " atual=", state.get("progress").current_main_quest(), " pronto=", state.call("quest_error", id))
		if state.call("quest_error", id) != "":
			push_error("Conferência não ficou pronta: " + id)
			quit(1)
			return
		events.sheet_close_requested.emit()
		await frames()
		pill.pressed.emit()
		await wait_modals()
		print("ENTREGUE: ", id, " = ", state.get("progress").claimed_quests.has(id))
		await shot(id + "_premio")
		if id == "growth_1_puppy": break
		var reward: CanvasLayer = main.get("_quest_reward")
		if not reward.visible:
			push_error("Folha não apareceu: " + id)
			quit(1)
			return
		print("FOLHA: próximo=", reward.find_child("NextStepCard", true, false).get_meta("quest"))
		reward.find_child("RewardGo", true, false).pressed.emit()
		await frames()
		# Novo! vem depois da folha: fecha a apresentação para seguir no destino já escolhido.
		main.call("_flush_modals")
		await frames()
		if main.get("_celebration").visible:
			print("NOVO: depois da folha")
			main.get("_celebration").hide()
		await shot(id + "_destino")
		match id:
			"welcome": state.call("feed", "dog_food")
			"lais_feed": state.call("bathe")
			"lais_bath": state.call("play")
			"lais_play": pass # RewardGo abriu a Mochila e contou open:bag.
			"lais_bag": state.call("buy_upgrade", "dog_bed")
			"lais_bed":
				# Somente prepara necessidades para fazer os cuidados úteis sem esperar horas reais.
				for i in 2:
					state.call("dev_set_need", "hunger", 30.0)
					state.call("feed", "dog_food")
				state.call("dev_set_need", "happiness", 30.0)
				state.call("pet")
				print("CRESCIMENTO: ", state.call("grow_error"))
				await frames()
				await shot("crescimento_pronto")
				var grow := main.find_child("GrowButton", true, false) as Button
				if grow: grow.pressed.emit()
				else: print("GrowButton ausente")
				events.sheet_close_requested.emit()
				await wait_modals()
				await shot("cerimonia")
				main.get("_growth_ceremony").hide()
				# Confirma somente a apresentação da cerimônia, sem modificar as regras do crescimento.
				state.call("acknowledge_growth", "puppy")
		await frames()
	print("CAPÍTULO: ", state.get("progress").chapter_index())
	main.queue_free()
	await frames()
	quit(0 if state.get("progress").chapter_index() == 2 else 1)
