extends SceneTree
## Linhas novas independentes, contadores fresh e retrato que sobrevive ao painel vivo.

var failures: int = 0
var state: Node


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _run() -> void:
	# Consulta das salas sem esperar a viagem; a animação tem teste próprio em world_selector_test.
	Motion.reduced = true
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	check(state.get("progress").current_line_quest("merchant") == "", "Feirante espera capítulo 4")
	check(state.get("progress").current_line_quest("guide") == "", "Guia espera capítulo 5")
	state.call("dev_jump_to_chapter", 3)
	check(state.get("progress").current_line_quest("merchant") == "merchant_meet", "Vila abre linha do Feirante")
	check(state.get("progress").current_line_quest("guide") == "", "Guia ainda não aparece na Vila")
	state.call("note_screen_opened", "village")
	check(state.call("claim_quest", "lais_village") == "", "Visita a Vila antes da venda")
	state.call("talk_to", "merchant")
	check(state.call("claim_quest", "merchant_meet") == "", "Conhece o Feirante")
	var grandma_step: String = state.get("progress").current_line_quest("bloblo")
	state.call("dev_add_items", 10)
	check(state.call("sell", "carrot", 1, "village") == "", "Primeira venda ao Feirante")
	check(state.call("claim_quest", "merchant_first_sale") == "", "Recebe primeira venda")
	check(state.call("sell", "carrot", 5, "village") == "", "Venda real conclui o excedente")
	check(state.call("claim_quest", "merchant_surplus") == "", "Recebe etapa da venda")
	check(state.get("progress").current_line_quest("bloblo") == grandma_step, "Linha do Feirante preserva a vovó")
	var snapshot: Dictionary = state.call("to_dict").duplicate(true)
	state.call("reset")
	state.call("from_dict", snapshot)
	check(state.get("progress").current_line_quest("merchant") == "merchant_orders", "Feirante persiste")
	state.call("dev_complete_quest", "merchant_orders")
	var lines_before: Dictionary = state.get("progress").active_steps().duplicate()
	var chapter_before: int = state.get("progress").chapter_index()
	check(lines_before.get("nina", "") == "nina_meet", "linha da Nina começa depois da encomenda")
	state.call("talk_to", "nina")
	check(state.call("claim_quest", "nina_meet") == "", "recebe nina_meet")
	check(state.get("progress").current_line_quest("nina") == "nina_walk", "linha da Nina avança")
	check(state.get("progress").chapter_index() == chapter_before and state.get("progress").current_line_quest("bloblo") == grandma_step, "Nina preserva capítulo e linha da vovó (marcos compartilhados podem sincronizar)")
	# O Guia só aparece depois de completar o capítulo 4 (inclui agora o baú da Nina).
	state.call("dev_jump_to_chapter", 4)
	state.call("talk_to", "guide")
	check(state.call("claim_quest", "guide_meet") == "", "Conhece o Guia")
	var merchant_step: String = state.get("progress").current_line_quest("merchant")
	state.call("dev_grant_upgrade", "forest_open")
	state.set("unlimited_storage", true)  # este teste mede linhas, não a pilha de materiais
	check(state.call("start_next_gathering", "trees", "lane") == "", "Guia permite coleta real")
	check(state.call("quest_error", "guide_wood") != "", "Iniciar não conclui coleta")
	state.call("dev_finish_timers")
	state.call("collect_gathering", "trees", 0)
	check(state.call("claim_quest", "guide_wood") == "", "Recolher conclui passo do Guia")
	check(state.get("progress").current_line_quest("merchant") == merchant_step, "Guia preserva o Feirante")
	snapshot = state.call("to_dict").duplicate(true)
	state.call("from_dict", snapshot)
	check(state.get("progress").current_line_quest("guide") == "guide_open_cave", "Guia persiste")
	var places_script: Script = load("res://scripts/ui/places.gd")
	check(not (places_script.call("visible_npcs", "park") as Array).has("dog_pipoca"), "Pipoca não é personagem")
	var help: Script = load("res://scripts/ui/task_help.gd")
	check(not (help.call("describe", "quest", "guide_stone") as Dictionary).get("next_target", {}).is_empty(), "Guia aponta o próximo requisito da Caverna")
	# Retrato permanece vivo enquanto o corpo da conversa é reconstruído.
	state.call("reset")
	var seen: Array[String] = ["intro"]
	state.call("mark_seen", seen)
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	# Isola o retrato da fila modal da casca: o prêmio da história agora fecha o Sheet (etapa 05).
	# O sinal continua chegando ao NpcPortrait e o LiveBox continua reconstruindo seus objetivos.
	root.get_node("Events").disconnect("quest_completed", Callable(main, "_on_quest_completed"))
	var places: Script = load("res://scripts/ui/places.gd")
	places.call("open_npc", "lais")
	await create_timer(0.2).timeout
	var portrait: TextureRect = main.find_child("NpcPortrait", true, false)
	check(is_instance_valid(portrait), "Laís tem retrato animado")
	var conversation := main.find_child("ContentHolder", true, false)
	check(conversation.find_child("NameTag", true, false) == null, "nome da folha não se repete no balão")
	for card: Control in conversation.find_children("LineCard_*", "Control", true, false):
		var heading := card.get_child(0).get_child(0)
		check(heading.find_children("*", "TextureRect", true, false).is_empty(), "missão da conversa não repete o retrato")
	check(portrait.texture.resource_path.contains("quest_request"), "Missão usa animação Pedindo algo")
	await _shot("npc_lais_request")
	check(state.call("claim_quest", "welcome") == "", "Receber missão da Laís")
	await create_timer(0.25).timeout
	check(is_instance_valid(portrait) and portrait == main.find_child("NpcPortrait", true, false), "Refresh preserva retrato")
	check(portrait.texture.resource_path.contains("intro_wave"), "Receber dispara aceno")
	await _shot("npc_lais_complete")
	await create_timer(1.3).timeout
	check(portrait.texture.resource_path.contains("quest_request"), "Aceno termina e volta ao pedido")
	state.call("dev_jump_to_chapter", 4)
	await create_timer(0.2).timeout
	main.get_node("Celebration").hide()
	main.call("_on_world_requested", "village", "npc:merchant")
	await create_timer(1.2).timeout
	await _shot("npc_merchant_line")
	main.call("_on_world_requested", "nature", "npc:guide")
	await create_timer(1.2).timeout
	await _shot("npc_guide_line")
	print("NPC LINES TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)


func _shot(filename: String) -> void:
	if "--screenshots" not in OS.get_cmdline_user_args():
		return
	await process_frame
	await process_frame
	var folder: String = ProjectSettings.globalize_path("res://../build/screenshots")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join(filename + ".png"))
