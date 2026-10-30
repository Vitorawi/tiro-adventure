extends SceneTree
## Contratos da história e da persistência atual, sem escrever o save pessoal.
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
	saver.free()
	# Linhas em paralelo: a vovó tem passo próprio e o "fresh" usa a base da linha dela.
	state.call("reset")
	state.get("progress").stats["harvest"] = 40
	state.call("dev_complete_quest", "first_harvest")
	check(state.get("progress").current_line_quest("bloblo") == "bloblo_sell_surplus", "Primeira colheita ensina a vender no sítio")
	state.call("dev_complete_quest", "bloblo_sell_surplus")
	check(state.get("progress").current_line_quest("bloblo") == "bloblo_dig", "Depois da colheita a vovó manda cavar")
	state.call("dev_complete_quest", "bloblo_dig")
	check(state.get("progress").current_line_quest("bloblo") == "bloblo_silo", "Depois do faro a vovó manda arrumar o silo (ordem 27)")
	state.call("dev_complete_quest", "bloblo_silo")
	check(state.get("progress").current_line_quest("bloblo") == "bloblo_more_crops", "Passo da vovó é o atual")
	state.call("dev_complete_quest", "growth_1_puppy")  # o capítulo 1 só fecha com o Tiro crescendo
	state.get("progress").stats["wish"] = 1
	check(state.call("claim_quest", "lais_first_wish") == "", "tutorial do desejo concluído antes do cruzamento")
	check(state.get("progress").current_main_quest() == "lais_first_crops", "Conhecer a vovó já avança a história junto")
	check(state.get("progress").claimed_quests.has("lais_meet_bloblo") and not state.call("quest_unlocked", "lais_meet_bloblo"), "Cruzamento não exige outro prêmio")
	var fresh: Dictionary = database.get("quests").bloblo_more_crops.goals[0]
	check(state.call("goal_value", fresh) == 0, "Colheitas anteriores não contam")
	state.get("progress").count("harvest", 2)
	check(state.call("goal_value", fresh) == 2, "Colheitas novas contam")
	check(state.call("accessible_plots") == 2, "Vovó empresta dois canteiros ao conhecer")
	state.get("progress").count("harvest", 1)
	check(state.call("claim_quest", "bloblo_more_crops") == "" and state.call("accessible_plots") == 4, "Mais colheitas: vovó empresta quatro canteiros")
	check(not database.get("quests").has("bloblo_carrots"), "entrega repetida de cenouras saiu do catálogo")
	check(state.get("progress").current_line_quest("bloblo") == "bloblo_potato", "depois de colher três vezes segue direto para batatas")
	check(state.call("plant_error", 0, "potato") == "", "batata já pode ser plantada sem entregar cenouras")
	var before_carrots: int = state.get("inventory").count("carrot")
	var previous: Dictionary = state.call("to_dict").duplicate(true)
	state.call("from_dict", previous)
	check(state.get("progress").current_line_quest("bloblo") == "bloblo_potato" and state.get("inventory").count("carrot") == before_carrots, "save na etapa retirada segue para batatas sem consumir cenouras")
	_shared_quests_check()
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
				"growth": state.call("dev_set_phase", str(goal.key))
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



## Diárias e semanais: liberação, sorteio, progresso e recompensa única no formato atual.
func _routines_check() -> void:
	state.call("reset")
	check(not state.call("routines_unlocked", "daily"), "Diárias escondidas no capítulo 1")
	check((state.call("routine_ids", "daily") as Array).is_empty(), "Sem diárias antes de liberar")
	# Capítulo 3: diárias abrem com 3 missões; semanais só no 4.
	state.call("dev_jump_to_chapter", 2)
	check(state.get("progress").chapter_index() == 3, "Está no capítulo 3")
	check(state.call("routines_unlocked", "daily") and (state.call("routine_ids", "daily") as Array).size() == 1, "Diárias abrem no capítulo 3 só com a colheita acessível (sem tarefa impossível)")
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
		progress.stats[goal.key] = progress.stat(goal.key) + int(state.call("routine_target", kind, id))
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
	root.size = Vector2i(360, 780)
	state.call("reset")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.call("show_screen", &"tasks")
	await create_timer(0.2).timeout
	var card: Control = main.find_child("StoryCard", true, false)
	check(card != null and card.size.y < 570, "Cartão da história deve caber na tela")
	check(main.find_child("GroupTabs", true, false).is_visible_in_tree() and main.find_child("NotebookTab_story", true, false) != null and main.find_child("NotebookTab_characters", true, false).has_meta("locked") and main.find_child("NotebookTab_timed", true, false).has_meta("locked"), "início: as três abas aparecem, Pessoas e Diárias com cadeado")
	check(card.find_child("StoryHero", true, false) != null and card.find_child("StoryRewards", true, false) != null and card.find_child("StoryGoal_0", true, false) != null, "história: cartão do topo, recompensas e passos")
	check(card.find_child("ChapterSteps", true, false) == null, "lista antiga de passos do capítulo saiu")
	var chapter_bar := card.find_child("BarText", true, false) as Label
	check(chapter_bar != null and chapter_bar.text == "0/1", "barra do cartão mostra o progresso da missão atual")
	check(main.find_child("MissionFrame", true, false).visible, "moldura de madeira na História")
	check(card.find_child("QuestGo_welcome", true, false) != null and (card.find_child("ClaimQuest_welcome", true, false) as Button).disabled, "missão em andamento: Ir e Pegar travado")
	check((card.find_child("ClaimQuest_welcome", true, false) as Button).icon == null, "Pegar travado sem cadeado ou outro ícone")
	var step: Control = main.find_child("NextStep", true, false)
	check(step != null and not step.visible and (load("res://scripts/ui/quest_guide.gd") as GDScript).call("current").id == "welcome", "O próximo passo só aparece na tela do Tiro: oculto em Missões, mas o passo atual segue welcome")
	check(main.find_child("MoodLabel", true, false).text == "Tiro está feliz da vida!", "Humor do Tiro substitui a instrução fixa (Etapa 09)")
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
	await process_frame
	await process_frame
	var done := main.find_child("StepDone_0", true, false) as Control
	check(done != null and not done is Button and done.size == Vector2(104, 44) and done.mouse_filter == Control.MOUSE_FILTER_IGNORE and done.focus_mode == Control.FOCUS_NONE, "passo feito: status no espaço 104×44 sem toque ou foco")
	check(done != null and done.find_child("DoneText", true, false).text == "Concluído" and not done.has_node("Frame") and done.find_children("*", "Button", true, false).is_empty(), "passo feito: Concluído plano sem botão")
	check(main.find_child("StoryGoal_0", true, false).get_node("Art/Frame").self_modulate == Color(0.90, 1.0, 0.90), "cartão feito com tom verde")
	state.get("progress").stats["talk:lais"] = 0
	root.get_node("Events").emit_signal("state_changed")
	await create_timer(0.2).timeout
	_shot("tasks_start")
	state.call("dev_jump_to_chapter", 1)
	state.get("progress").stats["wish"] = 1
	check(state.call("claim_quest", "lais_first_wish") == "", "prepara a orientação da vovó após o desejo")
	state.call("_changed")
	await process_frame
	await process_frame
	var guidance: Label = main.find_child("SharedQuestGuidance", true, false)
	check(guidance != null and guidance.text.contains(str(database.get("npcs").bloblo.name)), "principal orienta até o marco da linha")
	var tasks: Control = main.find_child("TasksScreen", true, false)
	check(tasks.find_child("LineCard_bloblo", true, false) == null, "principal não repete as secundárias")
	_shot("tasks_shared_guidance")
	tasks.call("choose_group", "characters")
	await process_frame
	await process_frame
	check(tasks.find_child("LineCard_bloblo", true, false) != null and tasks.find_child("LineCard_bloblo", true, false).find_children("*", "TextureRect", true, false).any(func(picture: TextureRect) -> bool: return picture.texture != null and picture.texture.resource_path == str(database.get("npcs").bloblo.portrait)), "uma linha por missão com retrato")
	check(tasks.find_child("LineDetail_bloblo", true, false) == null, "detalhe começa recolhido")
	_shot("tasks_characters")
	tasks.call("choose_character", "bloblo")
	await process_frame
	await process_frame
	check(tasks.find_child("LineDetail_bloblo", true, false) != null, "abrir Bloblo mostra o detalhe da missão")
	check(tasks.find_child("StoryCard", true, false) == null, "personagens não repetem a principal")
	check(tasks.find_child("MissionFrame", true, false).visible, "Pessoas também tem a moldura de madeira")
	state.call("dev_jump_to_chapter", 3)
	await create_timer(2.2).timeout
	main.get_node("Celebration").hide()
	await process_frame
	await process_frame
	main.call("show_screen", &"tasks")
	check((load("res://scripts/ui/quest_guide.gd") as GDScript).call("current").id != "welcome", "O próximo passo avança depois de welcome")
	check(main.find_child("LineDetail_bloblo", true, false) != null, "linha aberta continua selecionada ao atualizar")
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
	events.emit_signal("sheet_requested", "Crescimento", ui.call("skills_panel"))
	await create_timer(0.3).timeout
	_shot("tasks_growth")
	events.emit_signal("sheet_close_requested")
	events.emit_signal("sheet_requested", "Coleção", ui.call("collection_panel"))
	await create_timer(0.3).timeout
	_shot("tasks_collection")
	events.emit_signal("sheet_close_requested")
	var news: Array[String] = ["world:village", "feature:bag", "npc:merchant"]
	main.get_node("Celebration").call("show_chapter", 2, news)
	await create_timer(0.2).timeout
	var short_scroll := main.find_child("CelebrationScroll", true, false) as ScrollContainer
	check((short_scroll.get_parent() as Control).size.y < root.get_visible_rect().size.y - 32, "Comemoração curta mantém cartão centrado e compacto")
	_shot("tasks_celebration")
	# Muitas novidades: o cartão cabe no celular e o último botão fica acessível pela rolagem.
	# Desde a etapa 07 só a grade rola. Use destinos reais suficientes para exceder a grade compacta.
	var many_news: Array[String] = []
	for world_id: String in root.get_node("Database").get("worlds"):
		many_news.append("world:" + world_id)
		for place_id: String in root.get_node("Database").get("worlds")[world_id].places:
			many_news.append("place:" + world_id + "/" + place_id)
	main.get_node("Celebration").call("show_chapter", 2, many_news)
	await create_timer(0.2).timeout
	var scroll := main.find_child("CelebrationScroll", true, false) as ScrollContainer
	var panel := scroll.get_parent() as Control
	check(panel.get_global_rect().position.y >= 0 and panel.get_global_rect().end.y <= root.get_visible_rect().size.y + 1, "Desbloqueios longos cabem na altura da tela")
	check(scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page, "Lista longa tem rolagem vertical")
	_shot("unlocks_scroll_top")
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await create_timer(0.2).timeout
	var content := scroll.get_child(0) as GridContainer
	var last_tile := content.get_child(content.get_child_count() - 1) as Control
	check(scroll.get_global_rect().encloses(last_tile.get_global_rect()), "Rolagem chega à última novidade inteira")
	var last_button: Button = null
	for button: Button in main.get_node("Celebration").find_children("*", "Button", true, false):
		if button.text == "Continuar": last_button = button
	check(last_button != null and panel.get_global_rect().encloses(last_button.get_global_rect()) and not scroll.is_ancestor_of(last_button), "Continuar inteiro e fixo após rolar as novidades")
	_shot("unlocks_scroll_bottom")
	last_button.emit_signal("pressed")
	check(not main.get_node("Celebration").visible, "Continuar fecha o desbloqueio após rolar")
	main.get_node("Celebration").hide()
	events.emit_signal("sheet_close_requested")
	state.call("dev_unlock_everything")
	await create_timer(2.2).timeout
	main.get_node("Celebration").hide()
	await process_frame
	await process_frame
	main.call("show_screen", &"tasks")
	_shot("tasks_end")
	check(main.find_child("StoryAlbum", true, false) != null and main.find_child("StoryFull", true, false) != null, "história concluída oferece Álbum e capítulos anteriores")
	main.find_child("StoryAlbum", true, false).emit_signal("pressed")
	await process_frame
	await process_frame
	check(main.find_child("NotebookTab_album", true, false) != null, "atalho final abre o Álbum do caderninho")
	main.queue_free()
	await process_frame


func _shot(file_name: String) -> void:
	if not "--screenshots" in OS.get_cmdline_user_args():
		return
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + file_name + ".png")

## Cruzamentos da história: uma entrega, um prêmio e compatibilidade com saves anteriores.
func _shared_quests_check() -> void:
	for alias: String in ["lais_meet_bloblo", "lais_first_crops", "lais_stew"]:
		state.call("reset")
		var progress: RefCounted = state.get("progress")
		var quests: Dictionary = database.get("quests")
		var shared: String = quests[alias].shared_with
		for chapter in range(1, int(quests[alias].chapter) + 1):
			for previous: String in progress.main_quests(chapter):
				if previous == alias: break
				progress.claimed_quests[previous] = true
		for previous: String in progress.line_quests("bloblo"):
			if previous == shared: break
			progress.claimed_quests[previous] = true
		state.call("_changed")
		for goal: Dictionary in quests[shared].goals:
			if goal.type == "stat":
				progress.count(goal.key, int(goal.get("target", 1)))
			elif goal.type == "deliver":
				state.get("inventory").add(goal.key, int(goal.target))
		check(progress.displayed_main_quest() == shared, "história mostra missão canônica: " + alias)
		var before: int = state.get("coins")
		var count_before: int = progress.stat("quests")
		check(state.call("claim_quest", shared) == "", "entrega única: " + shared)
		var chapter_reward := 0
		if alias == "lais_first_crops":  # lais_stew deixou de fechar o capítulo 3 (depois vêm os dentinhos)
			chapter_reward = int(database.get("progression").chapters[int(quests[alias].chapter) - 1].get("rewards", {}).get("coins", 0))
		check(progress.claimed_quests.has(alias), "história avança junto: " + alias)
		check(state.get("coins") == before + int(quests[shared].rewards.get("coins", 0)) + chapter_reward, "só prêmio canônico e eventual capítulo")
		check(progress.stat("quests") == count_before + 1, "conta só uma missão")
		check(state.call("claim_quest", alias) != "" and state.call("claim_quest", shared) != "", "sem segunda entrega")
