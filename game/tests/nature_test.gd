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
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var state: Node = root.get_node("GameState")
	var ui: Script = load("res://scripts/ui/nature_ui.gd")
	var places: Script = load("res://scripts/ui/places.gd")
	state.call("reset")
	check(state.call("start_gathering", "trees", 0, "lane") != "", "História bloqueia coleta antecipada")
	state.call("dev_jump_to_chapter", 2)
	state.call("dev_add_coins", 4000)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.call("_on_world_requested", "village", "")
	places.call("open", "village", "gate")
	await create_timer(0.3).timeout
	var room: Control = main.find_child("World_nature", true, false)
	check(room != null and room.is_visible_in_tree(), "Portão continua entrando na Natureza")
	check(state.call("gathering_slots", "trees") == 1 and state.call("gathering_slots", "rocks") == 1, "Um espaço inicial em cada local")
	var before: Dictionary = state.call("to_dict").duplicate(true)
	check(state.call("start_gathering", "trees", 1, "lane") != "", "Vaga fechada não coleta")
	check(state.call("start_gathering", "trees", 0, "quarry") != "", "Mineração não entra nas árvores")
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
	check(state.get("inventory").count("stone") == stone_before + 2, "Recompensa antiga preservada")
	check(state.call("collect_gathering", "rocks", 0) != "", "Migração não duplica recompensa")
	state.call("from_dict", parallel_save)
	state.call("dev_finish_timers")
	check(state.call("collect_gathering", "trees", 0) == "", "Recolher madeira inicial")
	check(state.call("collect_gathering", "rocks", 0) == "", "Recolher pedra inicial")
	# Tocar no cenário abre diretamente o painel daquele tipo.
	room.call("_handle_tap", Vector2(150, 150))
	await create_timer(0.2).timeout
	var sheet: Control = main.find_child("Sheet", true, false)
	check(sheet.get_node("%Title").text == "Árvores", "Um toque abre Árvores")
	check(main.find_child("Material_copper", true, false) == null, "Árvores não mistura cobre")
	_shot("nature_trees_initial")
	var coins: int = state.get("coins")
	check(state.call("buy_upgrade", "trees_slot_3") != "", "Terceiro espaço exige segundo")
	check(state.get("coins") == coins, "Compra inválida não cobra")
	main.find_child("Unlock_trees_1", true, false).pressed.emit()
	await create_timer(0.2).timeout
	check(state.call("gathering_slots", "trees") == 2, "Comprar segunda vaga no próprio painel")
	main.find_child("Unlock_trees_2", true, false).pressed.emit()
	await create_timer(0.2).timeout
	check(state.call("gathering_slots", "trees") == 3, "Comprar terceira vaga no próprio painel")
	check(state.get("coins") == coins - 300, "Só cobra as duas compras")
	check(state.call("gathering_slots", "rocks") == 1, "Árvores não libera vagas de Pedras")
	main.find_child("StartAll_trees", true, false).pressed.emit()
	await create_timer(0.2).timeout
	check(state.call("gathering_jobs", "trees").size() == 3, "Um toque inicia três coletas")
	var jobs: Array = state.call("gathering_jobs", "trees")
	for entry: Dictionary in jobs:
		check(absf(float(entry.ready_at) - float(entry.started_at) - 60) < 0.01, "Cada corte começa agora, sem fila sequencial")
		check(absf(float(entry.started_at) - float(jobs[0].started_at)) < 1, "Três cortes simultâneos")
	check(state.call("start_gathering", "trees", 3, "lane") != "", "Máximo três vagas")
	check(state.call("start_gathering", "rocks", 0, "pebbles") == "", "Locais independentes durante três cortes")
	_shot("nature_trees_working")
	var offline: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", offline)
	check(state.call("gathering_jobs", "trees").size() == 3 and state.call("gathering_jobs", "rocks").size() == 1, "Todas as tarefas sobrevivem ao save")
	state.call("dev_add_items", 20)
	check(state.call("buy_upgrade", "axe") == "", "Comprar ferramenta durante corte")
	state.call("dev_advance_time", 65)
	check(state.call("gathering_ready_count", "trees") == 3, "Três terminam juntos offline")
	check(state.call("gathering_ready_count", "rocks") == 0, "Pedra tem duração independente")
	before = state.call("to_dict").duplicate(true)
	check(state.call("collect_gathering", "rocks", 0) != "", "Não recolhe antes do tempo")
	check(state.call("to_dict") == before, "Coleta antecipada não remove tarefa")
	var wood_before: int = state.get("inventory").count("wood")
	check(state.call("collect_gathering_all", "trees") == "", "Um toque recolhe os três cortes")
	check(state.get("inventory").count("wood") == wood_before + 3, "Nova ferramenta não altera lote iniciado à mão")
	check(state.call("collect_gathering_all", "trees") != "", "Não recolhe duas vezes")
	state.call("dev_advance_time", 10)
	check(state.call("collect_gathering", "rocks", 0) == "", "Pedra termina depois")
	check(state.call("buy_upgrade", "axe_reinforced") == "", "Melhorar machado")
	check(state.call("start_gathering_all", "trees", "timber") == "", "Três cortes com a ferramenta nova")
	state.call("dev_advance_time", 250)
	var hardwood: int = state.get("inventory").count("hardwood")
	check(state.call("collect_gathering_all", "trees") == "", "Recolher madeira dura")
	check(state.get("inventory").count("hardwood") == hardwood + 6, "Três lotes rendem seis madeiras duras")
	state.call("dev_set_skills", 4)
	check(state.call("buy_upgrade", "pickaxe") == "", "Comprar picareta")
	check(state.call("buy_upgrade", "pickaxe_reinforced") == "", "Melhorar picareta")
	check(state.call("buy_upgrade", "pickaxe_crystal") == "", "Picareta para cristais")
	check(state.call("buy_upgrade", "rocks_slot_2") == "" and state.call("buy_upgrade", "rocks_slot_3") == "", "Três espaços em Pedras")
	room.call("_handle_tap", Vector2(400, 200))
	await create_timer(0.2).timeout
	check(sheet.get_node("%Title").text == "Pedras", "Um toque abre Pedras")
	check(main.find_child("NextTool_trees", true, false) == null, "Pedras não mistura machados")
	main.find_child("Material_crystal", true, false).pressed.emit()
	await create_timer(0.2).timeout
	main.find_child("Gather_rocks_0", true, false).pressed.emit()
	await create_timer(0.2).timeout
	check(state.call("gathering_entry", "rocks", 0).id == "crystal_deep", "Botão usa ferramenta e material escolhidos")
	main.find_child("Material_copper", true, false).pressed.emit()
	await create_timer(0.2).timeout
	main.find_child("Gather_rocks_1", true, false).pressed.emit()
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
	main.find_child("Gather_trees_0", true, false).pressed.emit()
	check(state.call("gathering_entry", "trees", 0).id == "lane", "Missão da rota inicial continua concluível")
	state.call("dev_finish_timers")
	state.call("collect_gathering_all", "trees")
	var copper_before: int = state.get("inventory").count("copper")
	var stones_before: int = state.get("inventory").count("stone")
	var crystals_before: int = state.get("inventory").count("crystal")
	state.call("collect_gathering_all", "rocks")
	check(state.get("inventory").count("copper") == copper_before + 7 and state.get("inventory").count("stone") == stones_before + 8 and state.get("inventory").count("crystal") == crystals_before + 4, "Seleção do material mantém todos os produtos dos dois lotes")
	ui.call("open", "trees")
	await create_timer(0.2).timeout
	main.find_child("StartAll_trees", true, false).pressed.emit()
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
	for point: Vector2 in [Vector2(170, 182), Vector2(250, 196), Vector2(375, 190)]:
		check(not (room.call("find_path", (room.get("_dog") as Node2D).position, point) as PackedVector2Array).is_empty(), "Paisagem continua conectada")
	main.queue_free()
	await process_frame
	print("NATURE TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


func _shot(file_name: String) -> void:
	if "--screenshots" in OS.get_cmdline_user_args():
		var folder := ProjectSettings.globalize_path("res://../build/screenshots/")
		DirAccess.make_dir_recursive_absolute(folder)
		root.get_texture().get_image().save_png(folder + file_name + ".png")
