extends SceneTree
## Coleta por local: três tarefas realmente paralelas, save antigo e interação simples.

var failures: int = 0
var main: Node


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Natureza: " + message)


func _run() -> void:
	# Consulta das salas sem esperar a viagem; a animação tem teste próprio em world_selector_test.
	Motion.reduced = true
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var state: Node = root.get_node("GameState")
	var ui: Script = load("res://scripts/ui/nature_ui.gd")
	var places: Script = load("res://scripts/ui/places.gd")
	state.call("reset")
	state.set("unlimited_storage", true)  # a Natureza enche a pilha de materiais (16); o limite tem teste próprio (warehouse_test)
	var legacy: Dictionary = state.call("to_dict").duplicate(true)
	legacy.progression.erase("nature_levels_version")
	legacy.progression.owned = {"axe_reinforced": true, "pickaxe_crystal": true, "sickle": true}
	legacy.progression.claimed_quests = {"main_5_pickaxe": true}
	legacy.progression.gathering = {"trees": [{"id":"timber", "resource":"wood", "started_at":state.call("now"), "ready_at":state.call("now") + 240, "rewards":{"items":{"wood":5,"hardwood":2}}}]}
	state.call("from_dict", legacy)
	check(state.get("progress").nature_level("trees") == 3 and state.get("progress").nature_level("rocks") == 3 and state.get("progress").nature_level("fibers") == 2, "Ferramentas antigas viram níveis incluindo ampliações anteriores")
	check(not state.get("progress").owned.has("axe_reinforced"), "Save deixa de guardar ferramentas")
	check(state.get("coins") == legacy.coins and state.get("progress").claimed_quests.has("main_5_pickaxe"), "Conversão não cobra nem perde missão recebida")
	check(state.call("gathering_entry", "trees", 0) == legacy.progression.gathering.trees[0], "Conversão preserva prazo, material e recompensa em curso")
	var converted: Dictionary = state.call("to_dict").duplicate(true)
	state.call("from_dict", converted)
	check(state.call("to_dict") == converted, "Migração de níveis é idempotente")
	legacy.progression.owned = {}
	legacy.progression.gathering = {}
	legacy.progression.stats = {"activity:lane": 1}
	state.call("from_dict", legacy)
	check(state.get("progress").nature_level("trees") == 1 and state.get("progress").nature_level("rocks") == 0, "Save antigo preserva só o local que já foi explorado")
	state.call("reset")
	check(state.call("start_gathering", "trees", 0, "lane") != "", "História bloqueia coleta antecipada")
	state.call("dev_jump_to_chapter", 4)
	state.call("dev_add_coins", 4000)
	check(state.call("start_next_gathering", "trees", "lane", "wood") != "", "Bosque precisa ser desbloqueado")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.call("_on_world_requested", "village", "")
	places.call("open", "village", "gate")
	await create_timer(0.3).timeout
	var room: Control = main.find_child("World_nature", true, false)
	check(room != null and room.is_visible_in_tree(), "Portão continua entrando na Natureza")
	ui.call("open", "trees")
	await create_timer(0.2).timeout
	_shot("nature_forest_locked")
	check(main.find_child("Material_wood", true, false) == null, "Local fechado oferece desbloqueio")
	check(state.call("buy_upgrade", "forest_open") == "", "Desbloquear Bosque só com moedas")
	check(state.call("buy_upgrade", "cave_open") == "", "Desbloquear Caverna sem materiais circulares")
	check(state.call("gathering_slots", "trees") == 1 and state.call("gathering_slots", "rocks") == 1, "Um espaço inicial em cada local")
	var before: Dictionary = state.call("to_dict").duplicate(true)
	check(state.call("start_gathering", "trees", 1, "lane") != "", "Vaga fechada não coleta")
	check(state.call("start_gathering", "trees", 0, "quarry") != "", "Mineração não entra nas árvores")
	check(state.call("start_next_gathering", "trees", "quarry", "stone") != "", "Coleta automática também valida o local")
	check(state.call("to_dict") == before, "Falhas não mudam estado")
	check(state.call("start_gathering", "trees", 0, "lane") == "", "Coletar madeira")
	check(state.call("start_gathering", "rocks", 0, "pebbles") == "", "Pedras trabalham junto com madeira")
	check(state.call("start_gathering", "trees", 0, "lane") != "", "Não sobrescreve espaço ocupado")
	var parallel_save: Dictionary = state.call("to_dict").duplicate(true)
	# Migração da versão anterior: uma atividade global continua no local certo.
	var old: Dictionary = before.duplicate(true)
	old.progression.erase("gathering")
	old.progression.activity = {"id": "trail", "started_at": state.call("now") - 20, "ready_at": state.call("now") + 160}
	state.call("from_dict", old)
	check(state.get("progress").activity.is_empty(), "Migração tira antiga coleta da fila global")
	check(state.call("gathering_entry", "rocks", 0).id == "trail", "Coleta antiga preservada em Pedras")
	check(state.call("gathering_remaining", "rocks", 0) >= 158, "Mantém tempo restante")
	var migrated: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", migrated)
	check(state.call("gathering_jobs", "rocks").size() == 1, "Carregar de novo não duplica tarefa")
	state.call("dev_advance_time", 180)
	var stone_before: int = state.get("inventory").count("stone")
	check(state.call("collect_gathering", "rocks", 0) == "", "Recolher atividade migrada")
	check(state.get("inventory").count("stone") == stone_before + 3, "Coleta antiga sem snapshot usa a tabela vigente da rota (trilha: 3 pedras)")
	check(state.call("collect_gathering", "rocks", 0) != "", "Migração não duplica recompensa")
	state.call("from_dict", parallel_save)
	state.call("dev_finish_timers")
	check(int(state.get("progress").nature_xp.get("trees", 0)) == 0, "Timer pronto ainda não concede experiência")
	check(state.call("collect_gathering", "trees", 0) == "", "Recolher madeira inicial")
	check(int(state.get("progress").nature_xp.get("trees", 0)) == 2, "Uma coleta recolhida dá o XP local da rota (lane = 2) uma vez")
	check(state.call("collect_gathering", "rocks", 0) == "", "Recolher pedra inicial")
	ui.call("open", "rocks")
	await create_timer(0.2).timeout
	check(main.find_child("Material_copper", true, false).disabled, "Cobre bloqueado não vira seleção nem inicia tarefa")
	before = state.call("to_dict").duplicate(true)
	main.find_child("Material_copper", true, false).pressed.emit()
	check(state.call("to_dict") == before, "Falta de ferramenta não altera a fila")
	# Tocar no cenário abre diretamente o painel daquele tipo.
	room.call("_handle_tap", Vector2(150, 150))
	await create_timer(0.2).timeout
	var sheet: Control = main.find_child("Sheet", true, false)
	var tray_script: Script = load("res://scripts/ui/action_tray.gd")
	var current_tray: Control = tray_script.get("current")
	check(current_tray != null and current_tray.get("selected") == "wood", "Um toque abre a bandeja do Bosque")
	current_tray.call("tap_item", "hardwood")
	await process_frame
	await process_frame
	check(current_tray.call("find_in_panel", "RequiredLevel_hardwood") != null, "Madeira dura bloqueada pelo nível na bandeja")
	# A consulta completa continua verificando todos os materiais e suas restrições.
	ui.call("open", "trees")
	await create_timer(0.2).timeout
	check(main.find_child("Material_hardwood", true, false).disabled, "Madeira dura exige nível 3 do Bosque")
	check(main.find_child("Material_copper", true, false) == null, "Árvores não mistura cobre")
	_shot("nature_trees_initial")
	var coins: int = state.get("coins")
	check(state.call("buy_upgrade", "trees_slot_3") != "", "Espaços não podem ser comprados")
	check(state.get("coins") == coins, "Compra inválida não cobra")
	check(state.get("progress").nature_info("trees").remaining == 22, "Mostra XP exato até o próximo nível (24)")
	for index in 2:
		state.call("start_next_gathering", "trees", "woodcutting", "wood")
		check(state.get("progress").nature_level("trees") == 1, "Iniciar não antecipa XP")
		state.call("dev_finish_timers")
		state.call("collect_gathering_all", "trees")
	check(state.call("gathering_slots", "trees") == 2 and state.get("progress").nature_level("trees") == 2, "Duas buscas longas (12 XP cada) liberam nível 2 e segundo espaço")
	check(state.call("start_next_gathering", "trees", "timber", "hardwood") != "", "Bosque 2 ainda não libera madeira dura")
	check(state.get("progress").nature_level("rocks") == 1, "XP do Bosque não aumenta Caverna")
	for index in 8:
		state.call("start_next_gathering", "trees", "woodcutting", "wood")
		state.call("dev_finish_timers")
		state.call("collect_gathering_all", "trees")
	await create_timer(0.2).timeout
	check(state.call("gathering_slots", "trees") == 2 and state.get("progress").nature_level("trees") == 3, "Nível 3 libera madeira dura, mas ainda só dois espaços")
	check(state.call("start_next_gathering", "trees", "timber", "hardwood") == "", "Madeira dura no nível 3")
	state.call("dev_finish_timers")
	state.call("collect_gathering_all", "trees")
	for index in 6:
		state.call("start_next_gathering", "trees", "timber", "hardwood")
		state.call("dev_finish_timers")
		state.call("collect_gathering_all", "trees")
	check(state.call("gathering_slots", "trees") == 3 and state.get("progress").nature_level("trees") == 4, "Nível 4 libera o terceiro espaço")
	check(state.get("coins") >= coins, "Evolução não cobra moedas")
	check(state.call("gathering_slots", "rocks") == 1, "Árvores não libera vagas de Pedras")
	ui.call("open_route", "lane")
	await create_timer(0.2).timeout
	for count in 3:
		main.find_child("Material_wood", true, false).pressed.emit()
		await create_timer(0.1).timeout
		check(state.call("gathering_jobs", "trees").size() == count + 1, "Cada toque no material inicia exatamente uma coleta")
	check(main.find_child("Material_wood", true, false).disabled, "Material desabilita quando as três vagas estão ocupadas")
	before = state.call("to_dict").duplicate(true)
	check(state.call("start_next_gathering", "trees", "lane", "wood") != "", "Fila cheia recusa novo material")
	check(state.call("to_dict") == before, "Fila cheia não sobrescreve coletas")
	var jobs: Array = state.call("gathering_jobs", "trees")
	for entry: Dictionary in jobs:
		check(absf(float(entry.ready_at) - float(entry.started_at) - 120) < 0.01, "Cada corte começa agora, sem fila sequencial")
		check(absf(float(entry.started_at) - float(jobs[0].started_at)) < 1, "Três cortes simultâneos")
	check(state.call("start_gathering", "trees", 3, "lane") != "", "Máximo três vagas")
	check(state.call("start_gathering", "rocks", 0, "quarry") == "", "Locais independentes durante três cortes")
	_shot("nature_trees_working")
	var offline: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", offline)
	check(state.call("gathering_jobs", "trees").size() == 3 and state.call("gathering_jobs", "rocks").size() == 1, "Todas as tarefas sobrevivem ao save")
	state.call("dev_add_items", 20)
	state.call("dev_advance_time", 125)
	check(state.call("gathering_ready_count", "trees") == 3, "Três terminam juntos offline")
	check(state.call("gathering_ready_count", "rocks") == 0, "Pedra tem duração independente")
	before = state.call("to_dict").duplicate(true)
	check(state.call("collect_gathering", "rocks", 0) != "", "Não recolhe antes do tempo")
	check(state.call("to_dict") == before, "Coleta antecipada não remove tarefa")
	var wood_before: int = state.get("inventory").count("wood")
	check(state.call("collect_gathering_all", "trees") == "", "Um toque recolhe os três cortes")
	check(state.get("inventory").count("wood") == wood_before + 6, "Nova ferramenta não altera lote iniciado à mão")
	var gained_xp: int = state.get("progress").nature_xp.trees
	check(state.call("collect_gathering_all", "trees") != "", "Não recolhe duas vezes")
	check(state.get("progress").nature_xp.trees == gained_xp, "Não duplica XP ao recolher de novo")
	state.call("dev_advance_time", 600)
	# Tocar no marcador do mapa recolhe direto e anima os itens (sem abrir painel).
	var gains: Array = []
	root.get_node("Events").items_gained.connect(func(items: Dictionary, coins: int, origin: Vector2) -> void: gains.append([items, coins, origin]))
	var rock_marker: Node2D
	for marker: Node2D in room.get("_route_markers"):
		if marker.get("site") == "rocks":
			rock_marker = marker
	check(state.call("gathering_ready_count", "rocks") == 1, "Pedra pronta antes do toque")
	room.call("_handle_tap", rock_marker.position + Vector2(0, -15))
	check(gains.size() == 1 and not gains[0][0].is_empty(), "Toque no mapa recolhe e avisa os itens")
	check(state.call("gathering_ready_count", "rocks") == 0, "Recolher no mapa libera a vaga")
	var fx: Node = null
	for node in main.get_children():
		if node.get_script() != null and str(node.get_script().resource_path).ends_with("collect_fx.gd"):
			fx = node
	check(fx != null and fx.get_child_count() >= 1, "Miniaturas aparecem na tela")
	await create_timer(0.3).timeout
	for node in main.get_children():
		if node is CanvasLayer and node.layer == 20:
			node.queue_free()
	await create_timer(0.1).timeout
	_shot("collect_fx")
	check(state.call("buy_upgrade", "forest_level_3") != "", "Nível por uso não é compra")
	check(state.get("progress").nature_level("trees") == 4, "Bosque 4 mantém madeira dura refinável")
	check(state.call("start_gathering_all", "trees", "timber") == "", "Três cortes com a ferramenta nova")
	state.call("dev_advance_time", 3700)
	var hardwood: int = state.get("inventory").count("hardwood")
	check(state.call("collect_gathering_all", "trees") == "", "Recolher madeira dura")
	check(state.get("inventory").count("hardwood") == hardwood + 9, "Três lotes rendem nove madeiras duras")
	state.call("dev_set_skills", 4)
	check(state.get("progress").nature_level("rocks") == 1, "Caverna já desbloqueada")
	for index in 14:
		state.call("start_next_gathering", "rocks", "quarry", "stone")
		state.call("dev_finish_timers")
		state.call("collect_gathering_all", "rocks")
		if index == 1:
			check(state.get("progress").nature_level("rocks") == 2 and state.call("gathering_slots", "rocks") == 2, "Três coletas da pedreira liberam cobre e segundo espaço")
			ui.call("open", "rocks")
			await create_timer(0.2).timeout
			check(not main.find_child("Material_copper", true, false).disabled and main.find_child("Material_crystal", true, false).disabled, "Nível 2 mostra cobre liberado e cristal futuro")
			check(main.find_child("NatureProgress_rocks", true, false).text.contains("/96 XP"), "Painel mostra o progresso até o próximo nível")
			_shot("nature_cave_level_2")
	check(state.get("progress").nature_level("rocks") == 3 and state.call("gathering_slots", "rocks") == 2, "Quatorze coletas da pedreira liberam cristais, com dois espaços")
	room.call("_handle_tap", Vector2(400, 200))
	await create_timer(0.2).timeout
	current_tray = tray_script.get("current")
	check(current_tray != null and "crystal" in current_tray.call("entry_ids"), "Um toque abre a bandeja da Caverna")
	ui.call("open", "rocks")
	await create_timer(0.2).timeout
	check(main.find_child("NextTool_trees", true, false) == null, "Pedras não mistura machados")
	check(ui.call("choose_route", "crystal", "crystal_deep"), "Cristal profundo pode ser escolhido")
	ui.call("open", "rocks")
	await create_timer(0.2).timeout
	main.find_child("Material_crystal", true, false).pressed.emit()
	await create_timer(0.2).timeout
	check(state.call("gathering_entry", "rocks", 0).id == "crystal_deep", "Um toque no cristal já inicia com ferramenta correta")
	main.find_child("Material_copper", true, false).pressed.emit()
	await create_timer(0.2).timeout
	check(state.call("gathering_entry", "rocks", 1).resource == "copper", "Guarda material selecionado na segunda vaga")
	check(main.find_child("GatherItem_rocks_0", true, false).texture.resource_path.ends_with("item_crystal.png"), "Trocar material não muda a primeira coleta")
	check(main.find_child("GatherItem_rocks_1", true, false).texture.resource_path.ends_with("item_copper.png"), "Coleta de cobre mostra cobre, mesmo rendendo pedras extras")
	var mineral_save: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", mineral_save)
	check(state.call("gathering_entry", "rocks", 1).resource == "copper", "Material escolhido também fica salvo")
	_shot("nature_rocks")
	check(places.call("highlight_action", "route:lane") == "place:trees", "Missão aponta para árvores")
	check(places.call("highlight_action", "route:quarry") == "place:rocks", "Missão aponta para pedras")
	# Ir de uma missão preserva a rota exata, mesmo com ferramentas melhores.
	ui.call("open_route", "lane")
	await create_timer(0.2).timeout
	main.find_child("Material_wood", true, false).pressed.emit()
	check(state.call("gathering_entry", "trees", 0).id == "lane", "Missão da rota inicial continua concluível")
	state.call("dev_finish_timers")
	state.call("collect_gathering_all", "trees")
	var copper_before: int = state.get("inventory").count("copper")
	var stones_before: int = state.get("inventory").count("stone")
	var crystals_before: int = state.get("inventory").count("crystal")
	state.call("collect_gathering_all", "rocks")
	check(state.get("inventory").count("copper") == copper_before + 7 and state.get("inventory").count("stone") == stones_before + 3 and state.get("inventory").count("crystal") == crystals_before + 5, "Seleção do material mantém todos os produtos dos dois lotes")
	ui.call("open", "trees")
	await create_timer(0.2).timeout
	for index in 3:
		main.find_child("Material_wood", true, false).pressed.emit()
		await create_timer(0.1).timeout
	state.call("dev_finish_timers")
	await create_timer(1.2).timeout
	_shot("nature_trees_ready")
	root.get_node("Events").emit_signal("sheet_close_requested")
	main.get_node("Celebration").hide()
	await create_timer(2.2).timeout
	room.call("_animate_objects")
	_shot("nature_sites_map")
	var indicator: Node = room.get("_route_markers")[0]
	check(indicator.call("jobs").size() == 3, "Mapa mostra três coletas do local")
	var final_save: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", final_save)
	check(state.call("gathering_slots", "trees") == 3 and state.call("gathering_ready_count", "trees") == 3, "Vagas e coletas prontas salvas")
	var first: Dictionary = state.call("gathering_entry", "trees", 0).duplicate(true)
	var third: Dictionary = state.call("gathering_entry", "trees", 2).duplicate(true)
	state.call("collect_gathering", "trees", 1)
	check(state.call("start_next_gathering", "trees", "timber", "wood") == "", "Um toque reutiliza o espaço vazio no meio")
	check(state.call("gathering_entry", "trees", 1).id == "timber", "Preenche a primeira vaga livre")
	check(state.call("gathering_entry", "trees", 0) == first and state.call("gathering_entry", "trees", 2) == third, "Coleta automática preserva as outras tarefas")
	for point: Vector2 in [Vector2(170, 182), Vector2(250, 196), Vector2(375, 190)]:
		check(not (room.call("find_path", (room.get("_dog") as Node2D).position, point) as PackedVector2Array).is_empty(), "Paisagem continua conectada")
	var refine: Control = ui.call("refining_panel", "trees")
	check(refine.find_child("RefineRecipe_hardwood_planks", true, false) != null, "Madeira dura tem receita de refino acessível")
	var destination: Array[String] = []
	var capture := func(world: String, place: String) -> void: destination.assign([world, place])
	root.get_node("Events").world_requested.connect(capture)
	refine.find_child("RefineRecipe_hardwood_planks", true, false).pressed.emit()
	check(destination == ["farm", "place:workbench"], "Refinar leva à bancada certa")
	root.get_node("Events").world_requested.disconnect(capture)
	refine.free()
	var chain: Control = ui.call("levels_panel", "rocks")
	root.add_child(chain)
	check(chain.find_child("NatureLevel_rocks_4", true, false) != null, "Cadeia mostra os quatro níveis")
	chain.queue_free()
	var skills: Control = load("res://scripts/ui/progression_ui.gd").call("skills_panel")
	root.add_child(skills)
	check(skills.find_child("NatureSkill_rocks", true, false) != null, "Caverna aparece nos atributos do Tiro")
	skills.queue_free()
	main.queue_free()
	await process_frame
	print("NATURE TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


func _shot(file_name: String) -> void:
	if "--screenshots" in OS.get_cmdline_user_args():
		var folder := ProjectSettings.globalize_path("res://../build/screenshots/")
		DirAccess.make_dir_recursive_absolute(folder)
		root.get_texture().get_image().save_png(folder + file_name + ".png")
