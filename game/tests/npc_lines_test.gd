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
	state.call("dev_jump_to_chapter", 4)
	state.call("talk_to", "merchant")
	state.call("talk_to", "guide")
	state.call("claim_quest", "merchant_meet")
	state.call("claim_quest", "guide_meet")
	var main_step: String = state.get("progress").current_main_quest()
	var grandma_step: String = state.get("progress").current_line_quest("bloblo")
	var guide_base: Dictionary = state.get("progress").steps.guide.duplicate(true)
	state.call("dev_add_items", 10)
	check(state.call("sell", "carrot", 5) == "", "Venda real conclui objetivo do Feirante")
	check(state.call("claim_quest", "merchant_surplus") == "", "Recebe etapa da venda")
	check(state.get("progress").steps.guide == guide_base, "Trocar passo do Feirante preserva base do Guia")
	check(state.get("progress").current_main_quest() == main_step, "Linha nova não pula história")
	check(state.get("progress").current_line_quest("bloblo") == grandma_step, "Linha nova não pula vovó")
	state.call("dev_grant_upgrade", "forest_open")
	check(state.call("start_next_gathering", "trees", "lane") == "", "Guia permite coleta real")
	check(state.call("quest_error", "guide_wood") != "", "Iniciar não conclui coleta")
	state.call("dev_finish_timers")
	state.call("collect_gathering", "trees", 0)
	check(state.call("claim_quest", "guide_wood") == "", "Recolher conclui passo do Guia")
	var snapshot: Dictionary = state.call("to_dict").duplicate(true)
	state.call("reset")
	state.call("from_dict", snapshot)
	check(state.get("progress").current_line_quest("merchant") == "merchant_orders", "Feirante persiste")
	check(state.get("progress").current_line_quest("guide") == "guide_stone", "Guia persiste")
	var help: Script = load("res://scripts/ui/task_help.gd")
	check(not (help.call("describe", "quest", "guide_stone") as Dictionary).get("next_target", {}).is_empty(), "Guia aponta o próximo requisito da Caverna")
	# Retrato permanece vivo enquanto o corpo da conversa é reconstruído.
	state.call("reset")
	var seen: Array[String] = ["intro"]
	state.call("mark_seen", seen)
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	var places: Script = load("res://scripts/ui/places.gd")
	places.call("open_npc", "lais")
	await create_timer(0.2).timeout
	var portrait: TextureRect = main.find_child("NpcPortrait", true, false)
	check(is_instance_valid(portrait), "Laís tem retrato animado")
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
