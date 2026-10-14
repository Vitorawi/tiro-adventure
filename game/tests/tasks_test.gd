extends SceneTree
## Contratos da história e da migração, sem escrever o save pessoal.
var failures: int = 0
var state: Node
var database: Node
var quest_signals: Array[String] = []
var chapter_signals: Array[int] = []

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _run() -> void:
	state = root.get_node("GameState")
	database = root.get_node("Database")
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	state.call("reset")
	# v12: começo refeito; qualquer save anterior recomeça do zero.
	var old: Dictionary = state.call("to_dict").duplicate(true)
	old.coins = 137
	var migrated: Dictionary = saver.call("_migrate", {"save_version": 11, "state": old})
	check((migrated.state as Dictionary).is_empty(), "Save anterior à v12 recomeça do zero")
	var current: Dictionary = {"save_version": saver.get("SAVE_VERSION"), "state": old}
	check(saver.call("_migrate", current) == current, "Save atual não é alterado")
	saver.free()
	# Linhas em paralelo: a vovó tem passo próprio e o "fresh" usa a base da linha dela.
	state.call("reset")
	state.get("progress").stats["harvest"] = 40
	state.call("dev_complete_quest", "first_harvest")
	check(state.get("progress").current_line_quest("bloblo") == "bloblo_more_crops", "Passo da vovó é o atual")
	check(state.get("progress").current_main_quest() == "lais_meet_bloblo", "Laís segue na linha dela")
	check(state.call("quest_error", "lais_meet_bloblo") == "", "Cruzamento: conhecer a vovó cumpre o passo da Laís")
	var fresh: Dictionary = database.get("quests").bloblo_more_crops.goals[0]
	check(state.call("goal_value", fresh) == 0, "Colheitas anteriores não contam")
	state.get("progress").count("harvest", 2)
	check(state.call("goal_value", fresh) == 2, "Colheitas novas contam")
	check(state.call("accessible_plots") == 2, "Vovó empresta dois canteiros ao conhecer")
	state.get("progress").count("harvest", 1)
	check(state.call("claim_quest", "bloblo_more_crops") == "" and state.call("accessible_plots") == 4, "Mais colheitas: vovó empresta quatro canteiros")
	state.call("reset")
	var events: Node = root.get_node("Events")
	events.connect("quest_completed", func(id: String) -> void: quest_signals.append(id))
	events.connect("chapter_completed", func(index: int) -> void: chapter_signals.append(index))
	check(state.get("progress").current_main_quest() == "welcome", "História começa em welcome")
	check(state.get("progress").current_line_quest("bloblo") == "", "Vovó espera a Laís apresentar")
	check(state.call("accessible_plots") == 0, "Sem canteiros antes de conhecer a vovó")
	check(not state.call("quest_unlocked", "first_harvest"), "Passo futuro não está liberado")
	check(state.call("requirement_error", {"chapter": 3}) != "", "Requisito de capítulo bloqueia")
	state.call("dev_add_coins", 1000)
	state.call("dev_add_items", 20)
	state.call("dev_set_skills", 10)
	var first: Array = state.get("progress").main_quests(1)
	for id: String in first:
		for goal: Dictionary in database.get("quests")[id].goals:
			match str(goal.type):
				"stat": state.get("progress").stats[goal.key] = int(goal.get("target", 1))
				"owned": state.get("progress").owned[goal.key] = true
		var before_reward: int = state.get("coins")
		check(state.call("claim_quest", id) == "", "Receber passo " + id)
		var expected: int = int(database.get("quests")[id].rewards.get("coins", 0))
		if id == first.back():
			expected += int(database.get("progression").chapters[0].get("rewards", {}).get("coins", 0))
		check(state.get("coins") == before_reward + expected, "Pagamento exato do passo e capítulo")
	check(quest_signals.size() == first.size() and chapter_signals == [1], "Sinais de passos e capítulo uma vez")
	var coins: int = state.get("coins")
	check(state.call("claim_quest", first.back()) != "" and state.get("coins") == coins, "Capítulo não paga duas vezes")
	# Missões sintéticas isolam consumo dos novos tipos.
	for kind: String in ["coins", "have", "deliver", "chapter"]:
		database.get("quests")["test_goal"] = {"kind": "side", "goals": [{"type": kind, "key": "carrot", "target": 1}], "rewards": {}}
		state.get("progress").claimed_quests.erase("test_goal")
		var before: int = state.get("inventory").count("carrot")
		state.set("xp", 0)
		coins = state.get("coins")
		check(state.call("claim_quest", "test_goal") == "", "Objetivo " + kind)
		check(state.get("coins") == coins, "Objetivo não consome moedas")
		check(state.get("inventory").count("carrot") == before - (1 if kind == "deliver" else 0), "Consumo de " + kind)
	database.get("quests").erase("test_goal")
	_routines_check()
	_unlocks_check()
	await _ui_check()
	print("TASKS TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)


## Revelar aos poucos: o começo mostra pouco; cada passo anuncia o que abriu, uma vez só.
func _unlocks_check() -> void:
	state.call("reset")
	var progress: RefCounted = state.get("progress")
	check((state.call("new_unlocks") as Array).is_empty(), "Começo sem novidades pendentes")
	check(not progress.feature_unlocked("bag") and not progress.skills_visible(), "Mochila e atributos escondidos no começo")
	check(not progress.npc_visible("guide") and not progress.npc_visible("bloblo") and progress.npc_visible("lais"), "Só a Laís no começo")
	state.call("dev_jump_to_chapter", 1)
	var news: Array = state.call("new_unlocks")
	for key: String in ["feature:bag", "world:farm", "npc:bloblo"]:
		check(key in news, "Novidade do capítulo 2: " + key)
	check(not "world:village" in news, "Vila ainda não apresentada")
	check(not "npc:guide" in news, "Guia ainda não apresentado")
	state.call("mark_seen", news)
	check((state.call("new_unlocks") as Array).is_empty(), "Novidade aparece uma vez só")
	# Save antigo (sem "seen"): o que já estava aberto não vira novidade.
	var old: Dictionary = state.call("to_dict")
	old.progression.erase("seen")
	state.call("from_dict", old)
	check((state.call("new_unlocks") as Array).is_empty(), "Save antigo não anuncia o que já tinha")


## Diárias e semanais: liberação, sorteio estável, progresso pela base, recompensa única e virada de período.
func _routines_check() -> void:
	state.call("reset")
	check(not state.call("routines_unlocked", "daily"), "Diárias escondidas no capítulo 1")
	check((state.call("routine_ids", "daily") as Array).is_empty(), "Sem diárias antes de liberar")
	# Capítulo 3: diárias abrem com 3 missões; semanais só no 4.
	state.call("dev_jump_to_chapter", 2)
	check(state.get("progress").chapter_index() == 3, "Está no capítulo 3")
	check(state.call("routines_unlocked", "daily") and (state.call("routine_ids", "daily") as Array).size() == 3, "Diárias abrem no capítulo 3 com 3 missões")
	check(not state.call("routines_unlocked", "weekly"), "Semanais ainda fechadas no capítulo 3")
	state.get("progress").stats["harvest"] = 7
	state.call("dev_jump_to_chapter", 4)
	# Reinicia após preparar os contadores: a diária já pode ter sido sorteada no capítulo 3.
	state.call("dev_restart_routines")
	var progress: RefCounted = state.get("progress")
	for kind: String in ["daily", "weekly"]:
		var ids: Array = state.call("routine_ids", kind)
		check(ids.size() == int(database.get("routines")[kind].count), kind + ": quantidade sorteada")
		check(state.call("routine_ids", kind) == ids, kind + ": sorteio estável")
		var id: String = ids[0]
		var goal: Dictionary = state.call("routine_data", kind, id).goal
		check(state.call("routine_value", kind, id) == 0, kind + ": progresso começa do zero")
		check(state.call("claim_routine", kind, id) != "", kind + ": não recebe sem cumprir")
		progress.stats[goal.key] = progress.stat(goal.key) + int(goal.target)
		check(state.call("routine_error", kind, id) == "", kind + ": pronta ao cumprir")
		state.set("xp", 0)  # evita presente de nível no meio da conta
		var coins: int = state.get("coins")
		check(state.call("claim_routine", kind, id) == "", kind + ": recebe")
		check(state.get("coins") == coins + int(state.call("routine_data", kind, id).rewards.get("coins", 0)), kind + ": paga moedas")
		check(state.call("claim_routine", kind, id) != "", kind + ": paga uma vez só")
		# Virada do período: novo sorteio com progresso e recompensas zerados.
		progress.routines[kind].period = "2000-01-01"
		var next: Array = state.call("routine_ids", kind)
		check(progress.routines[kind].period == state.call("routine_period", kind), kind + ": período atualizado")
		check(not state.call("routine_claimed", kind, next[0]) and state.call("routine_value", kind, next[0]) == 0, kind + ": novo período zerado")
	var monday: String = state.call("routine_period", "weekly")
	check(int(Time.get_datetime_dict_from_datetime_string(monday + "T12:00:00", true).weekday) == 1, "Semana começa na segunda")
	check(state.call("routine_seconds_left", "daily") <= 86400 and state.call("routine_seconds_left", "weekly") <= 7 * 86400, "Tempo até renovar")


func _ui_check() -> void:
	state.call("reset")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.call("show_screen", &"tasks")
	await create_timer(0.2).timeout
	var card: Control = main.find_child("StoryCard", true, false)
	check(card != null and card.size.y < 570, "Cartão da história deve caber na tela")
	check(main.get("_tasks_pulse") != null, "Guia pulsa no começo")
	check(main.find_child("MoodLabel", true, false).text == "Veja suas missões aqui embaixo!", "Guia do Tiro aparece no começo")
	check(not main.find_child("BagTab", true, false).visible, "Aba Mochila escondida no começo")
	# "Ir": seta sobre o objeto do destino, depois o painel.
	main.call("_on_world_requested", "house", "place:bowl")
	await create_timer(0.3).timeout
	var house: Node = main.find_child("World_house", true, false)
	check(house != null and house.find_child("Pointer", true, false) != null, "Ir mostra a seta no objeto")
	_shot("go_pointer")
	await create_timer(0.8).timeout
	check(main.find_child("Sheet", true, false).visible, "Painel abre depois da seta")
	root.get_node("Events").emit_signal("sheet_close_requested")
	main.call("show_screen", &"tasks")
	state.get("progress").stats["talk:lais"] = 1
	root.get_node("Events").emit_signal("state_changed")
	check(main.get("_tasks_badge").text == "1", "Badge conta a principal pronta uma vez")
	state.get("progress").stats["talk:lais"] = 0
	root.get_node("Events").emit_signal("state_changed")
	await create_timer(0.2).timeout
	_shot("tasks_start")
	state.call("dev_jump_to_chapter", 3)
	await create_timer(2.2).timeout
	main.get_node("Celebration").hide()
	await process_frame
	await process_frame
	main.call("show_screen", &"tasks")
	check(main.get("_tasks_pulse") == null, "Guia para após welcome")
	check(main.find_child("LineCard_bloblo", true, false) != null, "Cartão da vovó aparece em paralelo à história")
	_shot("tasks_middle")
	var ui: Script = load("res://scripts/ui/progression_ui.gd")
	var events: Node = root.get_node("Events")
	events.emit_signal("sheet_requested", "História", ui.call("story_panel"))
	await create_timer(0.3).timeout
	_shot("tasks_story")
	events.emit_signal("sheet_close_requested")
	events.emit_signal("sheet_requested", "Como fazer", load("res://scripts/ui/task_help.gd").call("panel", "quest", state.get("progress").current_main_quest()))
	await create_timer(0.3).timeout
	_shot("tasks_help")
	events.emit_signal("sheet_close_requested")
	events.emit_signal("sheet_requested", "Atributos", ui.call("skills_panel"))
	await create_timer(0.3).timeout
	_shot("tasks_skills")
	events.emit_signal("sheet_close_requested")
	events.emit_signal("sheet_requested", "Coleção", ui.call("collection_panel"))
	await create_timer(0.3).timeout
	_shot("tasks_collection")
	events.emit_signal("sheet_close_requested")
	var news: Array[String] = ["world:village", "feature:bag", "npc:merchant"]
	main.get_node("Celebration").call("show_chapter", 2, news)
	await create_timer(0.2).timeout
	_shot("tasks_celebration")
	main.get_node("Celebration").hide()
	events.emit_signal("sheet_close_requested")
	state.call("dev_unlock_everything")
	await create_timer(2.2).timeout
	main.get_node("Celebration").hide()
	await process_frame
	await process_frame
	main.call("show_screen", &"tasks")
	_shot("tasks_end")
	main.queue_free()
	await process_frame


func _shot(file_name: String) -> void:
	if not "--screenshots" in OS.get_cmdline_user_args():
		return
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + file_name + ".png")
