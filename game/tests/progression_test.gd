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
	root.remove_child(saver)
	saver.free()
	state.call("reset")
	_check(not state.call("has_upgrade", "stove") and not state.call("has_upgrade", "fridge") and state.call("accessible_plots") == 0, "Começo: casa sem cozinha e sítio ainda não apresentado")
	_check(state.call("cook", "carrot_snack") != "", "Não deve cozinhar sem estação")
	_check(state.call("plant", 0, "carrot") != "" and state.call("buy_plot", 3) != "", "Sem canteiros antes de conhecer a vovó")
	_check(state.call("buy_upgrade", "fridge") != "" and state.call("buy_upgrade", "stove") != "", "Cozinha só depois da história apresentar")
	_check(state.call("start_activity", "quarry") != "", "Mineração precisa de ferramenta")
	_check(state.call("claim_quest", "first_sale") != "", "Não deve receber missão fora da sequência")
	_check(state.call("claim_quest", "welcome") != "", "Não deve receber missão sem objetivo")
	var coins_before: int = state.get("coins")
	_check(state.call("sell", "carrot", -2) != "" and state.get("coins") == coins_before, "Venda negativa não deve gerar itens ou moedas")
	_check(state.call("feed", "dog_food"), "Refeição inicial deve funcionar")
	var progress_now: RefCounted = state.get("progress")
	_check(progress_now.call("stat", "feed:dog_food") == 1, "feed conta também a comida usada")
	state.call("pet")
	_check(progress_now.call("stat", "pet") == 1, "carinho conta estatística")
	_check(progress_now.get("firsts").has("feed") and progress_now.get("started_at") > 0.0, "Ritmo: primeira vez e início gravados")
	_check(state.call("available_actions") is Array, "available_actions devolve lista")
	_check(progress_now.call("pace_lines").size() > 0 and "feed" in " ".join(progress_now.call("pace_lines")), "Ritmo lista as primeiras vezes")
	_foundation()
	state.call("talk_to", "lais")
	_check(state.call("claim_quest", "welcome") == "", "Falar com a Laís conclui a missão inicial")
	coins_before = state.get("coins")
	_check(state.call("claim_quest", "welcome") != "" and state.get("coins") == coins_before, "Missão não pode pagar duas vezes")
	var xp_before: int = state.get("xp")
	var level_before: int = state.get("level")
	state.call("feed", "dog_food")
	_check(state.get("xp") == xp_before and state.get("level") == level_before, "Cuidado repetido não pode farmar XP")
	_check(state.call("start_activity", "lane") != "", "Trilha fechada antes do capítulo 5")
	state.call("dev_jump_to_chapter", 4)
	_check(state.call("start_activity", "lane") != "", "Capítulo 5 apresenta o local ainda fechado")
	state.call("dev_add_coins", 40)
	_check(state.call("buy_upgrade", "forest_open") == "", "Bosque pode ser desbloqueado no capítulo 5")
	_check(state.call("start_activity", "lane") == "", "Rota abre ao desbloquear o Bosque")
	_check(state.call("collect_activity") != "" and state.call("start_activity", "lane") != "", "Atividade não pode ser antecipada ou sobreposta")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	_check(not state.get("progress").activity.is_empty() and state.get("progress").claimed_quests.has("welcome"), "Save deve manter atividade e missões")
	state.get("progress").activity["ready_at"] = 1.0
	_check(state.call("collect_activity") == "", "Atividade deve terminar offline")
	coins_before = state.get("coins")
	_check(state.call("collect_activity") != "" and state.get("coins") == coins_before, "Não deve duplicar coleta de atividade")
	state.call("reset")
	state.set_script(load("res://tests/friend_clock.gd"))
	state.set("test_time", Time.get_unix_time_from_system())
	state.call("reset")
	var final_save := _campaign()
	state.call("from_dict", JSON.parse_string(JSON.stringify(final_save)))
	_check(not final_save.progression.collection.is_empty() and state.get("progress").collection.size() == final_save.progression.collection.size(), "Coleção deve sobreviver ao save")
	_check(int(state.get("progress").stat("routines")) > 0, "Campanha deve receber diárias e semanais")
	if "--screenshots" in OS.get_cmdline_user_args():
		await _screenshots(final_save)
	print("PROGRESSION TEST: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(0 if _failures == 0 else 1)


## Peças da Etapa 00: requisitos stats/bond/hours, recompensas affection/needs e bond_level.
func _foundation() -> void:
	var progress: RefCounted = state.get("progress")
	_check(state.call("requirement_error", {"stats": {"walk": 5}}) == "Faça mais 5 passeios", "Requisito stats pede mais passeios")
	progress.call("count", "walk", 5)
	_check(state.call("requirement_error", {"stats": {"walk": 5}}) == "", "Requisito stats cumprido")
	progress.call("count", "xyz", 1)
	_check(state.call("requirement_error", {"stats": {"xyz": 3}}) == "Faça mais 2 xyz", "Chave sem rótulo usa a própria chave")
	var dog: RefCounted = state.get("dog")
	var affection_before: int = dog.get("affection")
	dog.set("affection", 0)
	_check(state.call("requirement_error", {"bond": 3}) == "Vínculo 3", "Requisito bond bloqueia")
	dog.set("affection", 50)
	_check(state.call("requirement_error", {"bond": 3}) == "", "Requisito bond cumprido")
	_check(progress.call("bond_level", 0) == 1 and progress.call("bond_level", 20) == 2 and progress.call("bond_level", 9999) == 8, "bond_level segue bond_levels")
	var hour: int = Time.get_datetime_dict_from_unix_time(state.call("_local_time")).hour
	_check(state.call("requirement_error", {"hours": [hour, (hour + 1) % 24]}) == "", "Requisito hours dentro da faixa")
	var outside: String = state.call("requirement_error", {"hours": [(hour + 1) % 24, (hour + 2) % 24]})
	_check(outside.begins_with("Só das "), "Requisito hours fora da faixa")
	dog.set("affection", affection_before)
	state.call("_apply_rewards", {"affection": 7, "needs": {"happiness": -10}})
	_check(dog.get("affection") == affection_before + 7, "Recompensa affection soma ao afeto")


func _campaign() -> Dictionary:
	var progression: Dictionary = database.get("progression")
	var recipes: Dictionary = database.get("recipes")
	var crops: Dictionary = database.get("crops")
	var iterations: int = 0
	# A simulação estoca 12 de cada item: o limite de armazenamento é testado em storage_test.
	state.set("unlimited_storage", true)
	# Acelera apenas o tempo. Moedas, materiais, XP e aquisições vêm das ações reais.
	for turn in 1500:
		iterations = turn + 1
		# Uma janela por ciclo; só tempo simulado e petiscos produzidos pelas receitas abaixo.
		state.set("test_time", state.get("test_time") + 10800.0)
		state.call("_changed")
		for friend: String in state.call("friends_present"):
			state.call("give_friend", friend)
		if turn % 100 == 0:
			print("Campanha: ciclo ", turn, "; passos ", state.get("progress").active_steps(), "; passeios ", state.get("progress").stat("walk"))
		state.get("progress").cooldowns.clear()
		state.get("dog").updated_at -= 3600.0
		state.call("update_finds")
		for find_world: String in state.get("finds").worlds:
			state.get("finds").worlds[find_world].pending = 1
			state.call("dig", find_world)
		# Passeio da Praça: descansa o Tiro, sai e recolhe na hora (o tempo é simulado).
		if state.call("walk_error", "park_loop") != "" and not state.call("walking"):
			state.get("dog").sleeping = false
			state.get("dog").needs["energy"] = 100.0
		var walk_id := "flower_street" if state.get("progress").current_line_quest("nina") in ["nina_routes", "nina_petshop", "nina_dress", "nina_sewing"] and state.call("walk_lock_error", "flower_street") == "" else "park_loop"
		if state.get("inventory").count("yarn") < 5 and (not state.call("has_upgrade", "walk_bag") or not state.call("has_upgrade", "bed_soft")) and state.call("walk_lock_error", "village_fair") == "":
			walk_id = "village_fair"
		if state.call("start_walk", walk_id) == "":
			state.get("walk_state").current["ready_at"] = 1.0
			state.call("collect_walk")
		if state.call("equip_error", "red_scarf") == "":
			state.call("equip", "red_scarf")
		for trick: String in progression.tricks:
			state.call("learn_trick", trick)
			state.call("perform_trick", trick)
		state.call("emergency_food")
		state.call("bathe")
		state.call("play")
		for npc_id: String in database.get("npcs"):
			if not state.get("progress").npc_visible(npc_id):
				continue
			state.call("talk_to", npc_id)
		for screen: String in ["bag", "village"]:
			state.call("note_screen_opened", screen)
		for item: String in database.get("items"):
			if database.get("items")[item].has("feed") and state.get("inventory").count(item) > 0:
				state.call("feed", item)
				break
		# Sítio e estufa: as ervas (missão da estufa) só crescem nos canteiros delicados.
		for i: int in state.call("usable_plot_indices"):
			var crop_id: String = crops.keys()[(turn + i) % crops.size()]
			if state.call("is_greenhouse_plot", i):
				crop_id = "herbs"
			if state.call("plant", i, crop_id) != "":
				state.call("plant", i, "herbs" if state.call("is_greenhouse_plot", i) else "carrot")
			state.call("water", i)
			state.get("plots")[i]["ready_at"] = 1.0
			state.call("harvest", i)
		# Guarda reserva para cadeias e entrega o excedente na feira.
		if state.get("progress").current_line_quest("bloblo") == "bloblo_sell_surplus" and state.get("inventory").count("carrot") > 0:
			state.call("sell", "carrot", 1)
		for item: String in database.get("items"):
			var amount: int = state.get("inventory").count(item) - 12
			if amount > 0 and state.call("requirement_error", database.get("worlds").village.requirements) == "":
				state.call("sell", item, amount)
		if turn == 2:
			state.call("sell", "carrot", 1)
		for id: String in progression.orders:
			if int(state.get("progress").stats.get("order:" + id, 0)) >= (5 if str(progression.orders[id].get("channel", "neighbors")) == "contracts" else 3):
				continue # Guarda os materiais dos próximos pedidos para construir.
			state.call("fulfill_order", id)
		var wanted: Array = []
		var reserved := {}
		for step: String in state.get("progress").active_steps().values():
			wanted.append_array(database.get("quests")[step].goals.map(func(g: Dictionary) -> String: return str(g.get("key", ""))))
			for goal: Dictionary in database.get("quests")[step].goals:
				if str(goal.get("key", "")).begins_with("order:"):
					reserved.merge(progression.orders[str(goal.key).trim_prefix("order:")].inputs, true)
		# Objetivo de produzir algo: começa pela receita dele e, se faltar insumo, pelas receitas dos insumos (como o jogador faria).
		for step: String in state.get("progress").active_steps().values():
			for goal: Dictionary in database.get("quests")[step].goals:
				if str(goal.get("key", "")).begins_with("produce:"):
					for recipe_id: String in recipes:
						if str(recipes[recipe_id].get("output", "")) == str(goal.key).trim_prefix("produce:"):
							_cook_with_inputs(recipe_id, recipes)
		for id: String in recipes:
			# Como o jogador, guarda os produtos do contrato atual em vez de gastá-los em outra receita.
			var output_id := str(recipes[id].get("output", recipes[id].get("output_collection", "")))
			if not reserved.has(output_id) and recipes[id].get("inputs", {}).keys().any(func(item: String) -> bool: return reserved.has(item) and state.get("inventory").count(item) - int(recipes[id].inputs[item]) < int(reserved[item])):
				continue
			for animal_id: String in database.get("animals"):
				if database.get("animals")[animal_id].station == recipes[id].station and state.call("animal_count", recipes[id].station) == 0:
					state.call("buy_animal", animal_id)
			if state.get("inventory").count(recipes[id].get("output", recipes[id].get("output_collection", ""))) >= 12 and not ("produce:" + str(recipes[id].get("output", recipes[id].get("output_collection", "")))) in wanted:
				continue
			if state.call("cook", id) == "":
				var station: RefCounted = state.call("station", recipes[id].station)
				for entry: Dictionary in station.queue:
					entry["ready_at"] = 1.0
				state.call("collect", recipes[id].station)
		# Com os quatro pedaços do mapa, o jogador abre o baú da Clareira (o mirtilo e o petisco dependem dele).
		if state.call("open_treasure_error") == "":
			state.call("open_treasure")
		# Missão do desejo do mirtilo: o espaço vazio pronto recebe o pedido garantido; o jogador faz o petisco e entrega.
		if state.get("progress").active_steps().get("nina_flavors", "") == "nina_blueberry":
			var slots: Array = state.get("wishes").slots
			state.get("wishes").first_done = true  # o pedido inicial é o tutorial; a campanha não passa por ele
			if not slots.any(func(sl: Dictionary) -> bool: return str(sl.id) == "blueberry_treat"):
				# O jogador troca um pedido (grátis) para abrir a vaga ao pedido da missão.
				for slot_index in slots.size():
					if str(slots[slot_index].id) != "" and state.call("wish_slot_open", slot_index):
						state.call("swap_wish", slot_index)
						break
			for slot_index in slots.size():
				if str(slots[slot_index].id) == "" and state.call("wish_slot_open", slot_index):
					slots[slot_index]["ready_at"] = 0.0
			state.call("update_wishes")
			for slot_index in slots.size():
				if str(slots[slot_index].id) == "blueberry_treat":
					# O cultivo do mirtilo (4 h) já é testado em treasure_test/products_test; aqui o robô só precisa dos 2 mirtilos.
					if state.get("inventory").count("blueberry") < 2:
						state.get("inventory").add("blueberry", 2)
					_cook_with_inputs("blueberry_treat", recipes)
					state.call("fulfill_wish", slot_index)
		# História do Tiro (etapa 11): crescer e as obras da vila (capítulos 10–12) fazem parte da campanha.
		_grow_story(recipes)
		_projects_step()
		for current: String in state.get("progress").active_steps().values():
			state.call("claim_quest", current)
		for kind: String in ["daily", "weekly"]:
			for id: String in state.call("routine_ids", kind):
				state.call("claim_routine", kind, id)
		for id: String in progression.upgrades:
			if state.call("requirement_error", database.get("worlds")[progression.upgrades[id].world].requirements) == "":
				state.call("buy_upgrade", id)
		if state.call("has_upgrade", "farm") and state.get("coins") > 300:
			state.call("buy_plot", int(state.get("unlocked_plots")))
		var rotation: Array[String] = ["lane", "trail", "quarry", "copper_vein", "crystal_cave", "meadow", "orchard_harvest", "timber", "deep_quarry", "crystal_deep", "reeds"]
		var candidates: Array[String] = [rotation[turn % rotation.size()], "trail", "lane"]
		for id in candidates:
			if state.call("start_activity", id) == "":
				state.get("progress").activity["ready_at"] = 1.0
				state.call("collect_activity")
				break
		if state.get("progress").claimed_quests.size() == database.get("quests").size() and progression.upgrades.keys().all(func(id: String) -> bool: return state.call("has_upgrade", id)):
			break
	for id: String in database.get("quests"):
		if not state.get("progress").claimed_quests.has(id):
			print("Missão pendente: ", id, " passos ", state.get("progress").active_steps())
	_check(state.get("progress").chapter_index() == progression.chapters.size() + 1, "Campanha deve concluir todos os capítulos")
	for id: String in progression.upgrades:
		if not state.call("has_upgrade", id):
			print("Pendente ", id, ": ", state.call("upgrade_error", id), "; mochila ", state.get("inventory").counts)
		_check(state.call("has_upgrade", id), "Campanha deve alcançar compra: " + id)
	for id: String in database.get("quests"):
		_check(state.get("progress").claimed_quests.has(id), "Campanha deve alcançar missão: " + id)
	print("Campanha simulada: ", iterations, " ciclos; ", state.get("progress").owned.size(), " aquisições; ", state.get("progress").claimed_quests.size(), " missões.")
	return state.call("to_dict").duplicate(true)


## O Tiro cresce quando a história chega à missão de crescer: refeição da fase, item-chave entregue,
## banhos com xampu e o lacinho vêm das ações reais do jogo (o resto da campanha já faz as receitas).
## Só os pontos dos pilares usam `dev_add_pillar`: a taxa deles é validada em pillars_test e aqui
## importa a história passar pelos cinco crescimentos, sem depender de dias de cuidado.
func _grow_story(recipes: Dictionary) -> void:
	# "Banho de ervas" (capítulo 8): a missão pede um banho com xampu antes de o Mocinho exigir dois.
	for step: String in state.get("progress").active_steps().values():
		for goal: Dictionary in database.get("quests")[step].goals:
			if str(goal.get("key", "")) == "shampoo_bath" and state.call("goal_value", goal) < int(goal.get("target", 1)):
				_make("herb_shampoo", recipes)
				state.call("bathe", true)
	var main: String = state.get("progress").current_main_quest()
	if main == "" or str(database.get("quests")[main].goals[0].type) != "growth":
		return
	var info: Dictionary = state.call("growth_info")
	if info.next.is_empty():
		return
	for row: Dictionary in info.requirements:
		if row.done:
			continue
		match str(row.type):
			"feed":
				var food := str(state.call("favorite_food")) if str(row.item) == "favorite" else (str(row.item) if str(row.item) != "any" else "dog_food")
				for _i in int(row.need) - int(row.have):
					_make(food, recipes)
					state.call("feed", food)
			"deliver":
				_make(str(row.item), recipes)
				state.call("deliver_growth", str(row.item))
			"stat":
				if str(row.counter) == "shampoo_bath":
					for _i in int(row.need) - int(row.have):
						_make("herb_shampoo", recipes)
						state.call("bathe", true)
			"collection":
				for recipe_id: String in recipes:
					if str(recipes[recipe_id].get("output_collection", "")) == str(row.collection):
						_cook_with_inputs(recipe_id, recipes)
			"pillars":
				for id: String in row.levels:
					var missing: int = int(database.get("growth").levels[int(row.levels[id]) - 1]) - int(state.get("growth").points.get(id, 0))
					if missing > 0:
						state.call("dev_add_pillar", id, missing)
	if state.call("grow_error") == "":
		_check(state.call("grow") == "", "Crescer na campanha: " + str(info.next.id))


## Garante uma unidade do item: faz pela receita (com os insumos) se a mochila não tem.
func _make(item: String, recipes: Dictionary) -> void:
	if state.get("inventory").count(item) > 0:
		return
	for recipe_id: String in recipes:
		if str(recipes[recipe_id].get("output", "")) == item:
			_cook_with_inputs(recipe_id, recipes)
			break


## Obras da vila que a história pede (banco, jardim, piquenique, festa): taxa, material e uso pelo Tiro.
## O material vem da mochila quando a campanha já o produz; o que falta é posto na mochila (a cadeia de
## produção de cada obra é validada em projects_test, festival_test e pelo robô do simulador).
func _projects_step() -> void:
	for step: String in state.get("progress").active_steps().values():
		for goal: Dictionary in database.get("quests")[step].goals:
			var key := str(goal.get("key", ""))
			var id := key if str(goal.type) == "project" else (key.trim_prefix("project_use:") if key.begins_with("project_use:") else "")
			if id == "":
				continue
			if not state.call("project_completed", id):
				if not state.call("project_started", id):
					if state.call("project_error", id) != "" and state.get("coins") < int(database.call("project", id).start_coins):
						state.call("dev_add_coins", int(database.call("project", id).start_coins) - int(state.get("coins")))
					state.call("start_project", id)
				for _i in 6:
					var stage: Dictionary = state.call("project_stage", id)
					if bool(stage.done) or stage.remaining.is_empty():
						break
					for item: String in stage.remaining:
						var need: int = int(stage.remaining[item])
						if state.get("inventory").count(item) < need:
							state.get("inventory").add(item, need - state.get("inventory").count(item))
						state.call("contribute_project", id, item, need)
				state.call("complete_project", id)
			if key.begins_with("project_use:"):
				state.get("dog").sleeping = false
				state.call("use_project", id)


## Cozinha a receita e, antes, o que falta de insumo que outra receita faz (um nível de profundidade por chamada, até 3).
func _cook_with_inputs(recipe_id: String, recipes: Dictionary, depth: int = 0) -> void:
	if depth < 3:
		for item: String in recipes[recipe_id].get("inputs", {}):
			if state.get("inventory").count(item) >= int(recipes[recipe_id].inputs[item]):
				continue
			for other: String in recipes:
				if str(recipes[other].get("output", "")) == item:
					_cook_with_inputs(other, recipes, depth + 1)
					break
	if state.call("cook", recipe_id) == "":
		for entry: Dictionary in state.call("station", recipes[recipe_id].station).queue:
			entry["ready_at"] = 1.0
		state.call("collect", recipes[recipe_id].station)


func _screenshots(final_save: Dictionary) -> void:
	# Consulta das salas sem esperar a viagem; a animação tem teste próprio em world_selector_test.
	Motion.reduced = true
	state.call("reset")
	state.get("progress").seen["intro"] = true
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
	await create_timer(1.2).timeout
	_shot("ui_sell")
	events.emit_signal("sheet_close_requested")
	main.call("_on_world_requested", "village", "place:gate")
	await create_timer(1.2).timeout
	_shot("ui_gate")
	events.emit_signal("sheet_close_requested")
	main.call("_on_world_requested", "house", "place:stove")
	await create_timer(1.2).timeout
	state.get("progress").owned["stove"] = true
	state.get("progress").owned["workbench"] = true
	state.get("progress").owned.erase("stove_queue")
	state.get("progress").owned.erase("stove_queue_2")
	events.emit_signal("sheet_close_requested")
	load("res://scripts/ui/places.gd").call("open", "house", "stove")
	await create_timer(0.5).timeout
	_check(main.find_child("LockedSlot_stove_queue", true, false) != null and main.find_child("LockedSlot_stove_queue_2", true, false) != null, "Fogão mostra na fileira de espaços as duas ampliações")
	_shot("ui_kitchen_slots")
	_shot("ui_kitchen")
	events.emit_signal("sheet_close_requested")
	main.call("_on_world_requested", "house", "npc:lais")
	await create_timer(1.2).timeout
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
