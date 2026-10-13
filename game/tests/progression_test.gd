extends SceneTree
## Testa contratos de estado e uma campanha inteira com tempo acelerado.
## Não grava o save pessoal: remove SaveManager antes de qualquer mutação.
var _failures: int = 0
var state: Node
var database: Node


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)


func _run() -> void:
	state = root.get_node("GameState")
	database = root.get_node("Database")
	var saver: Node = root.get_node("SaveManager")
	var old_state: Dictionary = state.call("to_dict").duplicate(true)
	old_state.erase("progression")
	old_state["coins"] = 123
	old_state["unlocked_plots"] = 7
	var migrated: Dictionary = saver.call("_migrate", {"save_version": 3, "state": old_state})
	root.remove_child(saver)
	saver.free()
	state.call("from_dict", migrated.state)
	_check(state.call("has_upgrade", "farm") and state.call("has_upgrade", "fridge") and state.call("has_upgrade", "stove"), "Migração deve preservar equipamentos e sítio")
	_check(state.get("coins") == 123 and state.get("unlocked_plots") == 7, "Migração deve preservar moedas e terrenos")
	_check(state.call("station_slots", "stove") == 3, "Migração deve preservar a fila antiga")
	_check(state.call("content_error", "crop", "pumpkin", database.get("crops")["pumpkin"]) == "", "Migração não pode bloquear culturas antigas")
	state.call("reset")
	_check(not state.call("has_upgrade", "stove") and state.call("accessible_plots") == 1, "Começo deve ter casa vazia e um canteiro emprestado")
	_check(state.call("cook", "carrot_snack") != "", "Não deve cozinhar sem estação")
	_check(state.call("plant", 1, "carrot") != "" and state.call("buy_plot", 3) != "", "Não deve usar terrenos próprios antes de comprar o sítio")
	_check(state.call("plant", 0, "pumpkin") != "", "Culturas devem respeitar o atributo")
	_check(state.call("start_activity", "quarry") != "", "Mineração precisa de ferramenta")
	_check(state.call("claim_quest", "first_sale") != "", "Não deve receber missão fora da sequência")
	_check(state.call("claim_quest", "welcome") != "", "Não deve receber missão sem objetivo")
	var coins_before: int = state.get("coins")
	_check(state.call("sell", "carrot", -2) != "" and state.get("coins") == coins_before, "Venda negativa não deve gerar itens ou moedas")
	_check(state.call("buy_upgrade", "stove") != "" and not state.call("has_upgrade", "stove"), "Compra sem saldo não deve liberar equipamento")
	_check(state.call("feed", "dog_food"), "Refeição inicial deve funcionar")
	_check(state.call("claim_quest", "welcome") == "", "Missão inicial deve ser possível")
	coins_before = state.get("coins")
	_check(state.call("claim_quest", "welcome") != "" and state.get("coins") == coins_before, "Missão não pode pagar duas vezes")
	var xp_before: int = state.get("xp")
	var level_before: int = state.get("level")
	state.call("feed", "dog_food")
	_check(state.get("xp") == xp_before and state.get("level") == level_before, "Cuidado repetido não pode farmar XP")
	_check(state.call("start_activity", "lane") != "", "Trilha fechada antes do capítulo 3")
	state.call("dev_jump_to_chapter", 2)
	_check(state.call("start_activity", "lane") == "", "Rota abre no capítulo 3")
	_check(state.call("collect_activity") != "" and state.call("start_activity", "lane") != "", "Atividade não pode ser antecipada ou sobreposta")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	_check(not state.get("progress").activity.is_empty() and state.get("progress").claimed_quests.has("welcome"), "Save deve manter atividade e missões")
	state.get("progress").activity["ready_at"] = 1.0
	_check(state.call("collect_activity") == "", "Atividade deve terminar offline")
	coins_before = state.get("coins")
	_check(state.call("collect_activity") != "" and state.get("coins") == coins_before, "Não deve duplicar coleta de atividade")
	state.call("reset")
	var final_save := _campaign()
	state.call("from_dict", JSON.parse_string(JSON.stringify(final_save)))
	_check(not final_save.progression.collection.is_empty() and state.get("progress").collection.size() == final_save.progression.collection.size(), "Coleção deve sobreviver ao save")
	_check(int(state.get("progress").stat("routines")) > 0, "Campanha deve receber diárias e semanais")
	if "--screenshots" in OS.get_cmdline_user_args():
		await _screenshots(final_save)
	print("PROGRESSION TEST: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(0 if _failures == 0 else 1)


func _campaign() -> Dictionary:
	var progression: Dictionary = database.get("progression")
	var recipes: Dictionary = database.get("recipes")
	var crops: Dictionary = database.get("crops")
	var iterations: int = 0
	# Acelera apenas o tempo. Moedas, materiais, XP e aquisições vêm das ações reais.
	for turn in 1500:
		iterations = turn + 1
		state.get("progress").cooldowns.clear()
		state.get("dog").updated_at -= 3600.0
		state.call("emergency_food")
		state.call("bathe")
		for item: String in database.get("items"):
			if database.get("items")[item].has("feed") and state.get("inventory").count(item) > 0:
				state.call("feed", item)
				break
		for i in int(state.call("accessible_plots")):
			var crop_id: String = crops.keys()[(turn + i) % crops.size()]
			if state.call("plant", i, crop_id) != "":
				state.call("plant", i, "carrot")
			state.get("plots")[i]["ready_at"] = 1.0
			state.call("harvest", i)
		# Guarda reserva para cadeias e entrega o excedente na feira.
		for item: String in database.get("items"):
			var amount: int = state.get("inventory").count(item) - 12
			if amount > 0 and state.call("requirement_error", database.get("worlds").village.requirements) == "":
				state.call("sell", item, amount)
		if turn == 2:
			state.call("sell", "carrot", 1)
		for id: String in progression.orders:
			if int(state.get("progress").stats.get("order:" + id, 0)) >= 3:
				continue # Guarda os materiais dos próximos pedidos para construir.
			state.call("fulfill_order", id)
		var step: String = state.get("progress").current_main_quest()
		var wanted: Array = database.get("quests")[step].goals.map(func(g: Dictionary) -> String: return str(g.get("key", ""))) if step != "" else []
		for id: String in recipes:
			if state.get("inventory").count(recipes[id].output) >= 12 and not ("produce:" + str(recipes[id].output)) in wanted:
				continue
			if state.call("cook", id) == "":
				var station: RefCounted = state.call("station", recipes[id].station)
				for entry: Dictionary in station.queue:
					entry["ready_at"] = 1.0
				state.call("collect", recipes[id].station)
		var current: String = state.get("progress").current_main_quest()
		if current != "":
			state.call("claim_quest", current)
		for kind: String in ["daily", "weekly"]:
			for id: String in state.call("routine_ids", kind):
				state.call("claim_routine", kind, id)
		for id: String in progression.upgrades:
			if state.call("requirement_error", database.get("worlds")[progression.upgrades[id].world].requirements) == "":
				state.call("buy_upgrade", id)
		if state.call("has_upgrade", "farm") and state.get("coins") > 300:
			state.call("buy_plot", int(state.get("unlocked_plots")))
		var rotation: Array[String] = ["lane", "trail", "quarry", "copper_vein", "crystal_cave", "meadow", "orchard_harvest"]
		var candidates: Array[String] = [rotation[turn % rotation.size()], "trail", "lane"]
		for id in candidates:
			if state.call("start_activity", id) == "":
				state.get("progress").activity["ready_at"] = 1.0
				state.call("collect_activity")
				break
		if state.get("progress").claimed_quests.size() == database.get("quests").size():
			break
	_check(state.get("progress").chapter_index() == 9, "Campanha deve concluir os oito capítulos")
	for id: String in progression.upgrades:
		if not state.call("has_upgrade", id):
			print("Pendente ", id, ": ", state.call("upgrade_error", id), "; mochila ", state.get("inventory").counts)
		_check(state.call("has_upgrade", id), "Campanha deve alcançar compra: " + id)
	for id: String in database.get("quests"):
		_check(state.get("progress").claimed_quests.has(id), "Campanha deve alcançar missão: " + id)
	print("Campanha simulada: ", iterations, " ciclos; ", state.get("progress").owned.size(), " aquisições; ", state.get("progress").claimed_quests.size(), " missões.")
	return state.call("to_dict").duplicate(true)


func _screenshots(final_save: Dictionary) -> void:
	state.call("reset")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	var events: Node = root.get_node("Events")
	var worlds: Node = main.find_child("WorldsScreen")
	# Começo do jogo: casa vazia, mapa, tarefas.
	main.call("_on_world_requested", "house", "")
	await create_timer(0.4).timeout
	_shot("ui_world_house_new")
	main.call("show_screen", &"map")
	worlds.call("show_map")
	await create_timer(0.3).timeout
	_shot("ui_map")
	main.call("show_screen", &"tasks")
	await create_timer(0.3).timeout
	_shot("ui_tasks_new")
	# Meio do jogo: save final da campanha.
	state.call("from_dict", final_save)
	for world_id: String in ["farm", "village"]:
		main.call("_on_world_requested", world_id, "")
		await create_timer(0.4).timeout
		_shot("ui_world_" + world_id)
	main.call("_on_world_requested", "village", "")
	worlds.get_node("%PlacesButton").emit_signal("pressed")
	await create_timer(0.4).timeout
	_shot("ui_places_village")
	events.emit_signal("sheet_close_requested")
	main.call("_on_world_requested", "village", "place:market")
	await create_timer(0.4).timeout
	_shot("ui_sell")
	events.emit_signal("sheet_close_requested")
	main.call("_on_world_requested", "village", "place:gate")
	await create_timer(0.4).timeout
	_shot("ui_gate")
	events.emit_signal("sheet_close_requested")
	main.call("_on_world_requested", "house", "place:stove")
	await create_timer(0.4).timeout
	_shot("ui_kitchen")
	events.emit_signal("sheet_close_requested")
	main.call("_on_world_requested", "village", "npc:artisan")
	await create_timer(0.4).timeout
	_shot("ui_npc_lais")
	events.emit_signal("sheet_close_requested")
	main.call("show_screen", &"tasks")
	await create_timer(0.3).timeout
	_shot("ui_tasks_late")
	main.call("show_screen", &"bag")
	await create_timer(0.3).timeout
	_shot("ui_bag")
	events.emit_signal("sheet_requested", "Tábua", load("res://scripts/ui/sheet_builder.gd").call("item_detail", "plank"))
	await create_timer(0.4).timeout
	_shot("ui_item_detail")


func _shot(file_name: String) -> void:
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + file_name + ".png")
