extends SceneTree
## Capturas das Missões reorganizadas: Principal (só a história + faixa do capítulo), Diárias da semana, Pessoas e a
## conversa com Principal × Extra. NÃO é teste. Rodar SEM --headless:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/missoes_v2_shots.gd -- --out=missoes_v2
## PNGs em build/screenshots/<out>/missoes_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/missoes_v2/"
var failures := 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(300).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FALHOU: ", message)


func shot(shot_name: String, wait: float = 0.7) -> void:
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "missoes_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])
	print("[%s] ok" % shot_name)


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


func _claim_until(stop: String) -> void:
	var progress: Object = state.get("progress")
	var quests: Dictionary = root.get_node("Database").get("quests")
	for c in range(1, int(quests[stop].chapter) + 1):
		for id: String in progress.main_quests(c):
			if id == stop:
				break
			progress.claimed_quests[id] = true
			if quests[id].has("shared_with"):
				progress.claimed_quests[str(quests[id].shared_with)] = true
	state.call("_changed")


func _scene(stop: String) -> void:
	state.call("reset")
	var progress: Object = state.get("progress")
	progress.seen["intro"] = true
	if stop != "":
		_claim_until(stop)
	state.call("_mark_all_seen")
	state.set("unlimited_storage", true)
	state.call("_changed")
	main.call("show_screen", &"pet")
	await create_timer(0.3).timeout
	_hide_modals()
	main.call("show_screen", &"tasks")
	await create_timer(0.5).timeout


func _close_sheet() -> void:
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.4).timeout


func _talk(npc_id: String) -> void:
	state.call("mark_seen", ["npc_intro:" + npc_id] as Array[String])
	load("res://scripts/ui/places.gd").call("open_npc", npc_id)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "missoes_v2_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	var progression_ui: Script = load("res://scripts/ui/progression_ui.gd")

	# Principal na semana: faixa do capítulo + passo da vez, sem Hoje/Desafio.
	await _scene("lais_first_crops")
	state.get("progress").stats["arrival_box"] = 1
	state.call("_changed")
	var tasks := main.find_child("TasksScreen", true, false)
	tasks.call("choose_group", "story")
	await shot("a_principal", 0.6)
	_check(tasks.find_child("ChapterStrip", true, false) != null, "faixa do capítulo na Principal")
	_check(tasks.find_child("WeekToday", true, false) == null and tasks.find_child("WeekChallenge", true, false) == null and tasks.find_child("WeekLineStep", true, false) == null, "Principal sem Hoje/Desafio/Próximo passo")
	# Diárias na semana.
	tasks.call("choose_group", "timed")
	await shot("b_diarias", 0.6)
	_check(tasks.find_child("NotebookTab_timed", true, false) != null, "aba Diárias existe na semana")
	_check(tasks.find_child("WeekChallenge", true, false) != null, "Desafio da vovó nas Diárias")
	tasks.call("choose_group", "characters")
	await shot("c_pessoas", 0.6)
	for id: String in state.get("progress").call("lines"):
		pass
	var first_line := tasks.find_child("LineCard_*", true, false)
	if first_line:
		tasks.call("choose_line", str(first_line.name).trim_prefix("LineCard_"))
		await shot("d_pessoa_detalhe", 0.6)
	tasks.call("choose_group", "story")
	# Conversa: a vovó tem a missão da história (primeira horta) e pode ter extras.
	print("  ativas bloblo: ", load("res://scripts/ui/places.gd").call("npc_active_quests", "bloblo"))
	_talk("bloblo")
	await shot("e_conversa_bloblo", 0.8)
	var sheet := main.get_node("Sheet") as Control
	for tag: Node in sheet.find_children("QuestKind_*", "PanelContainer", true, false):
		print("  selo ", tag.name, " ", tag.get_meta("kind"), " ", (tag as Control).get_global_rect())
		_check((tag as Control).get_global_rect().end.x <= root.get_visible_rect().size.x, "selo fora da tela")
	await _close_sheet()
	# Conversa com extra: depois da história avançar, com a linha da vovó ativa ao mesmo tempo.
	await _scene("")
	state.call("dev_unlock_everything")
	await create_timer(2.2).timeout
	_hide_modals()
	for id: String in ["week_coop", "bloblo_first_fish", "bloblo_rod"]:
		state.get("progress").claimed_quests.erase(id)
	state.call("_changed")
	await create_timer(0.3).timeout
	print("  ativas bloblo (2): ", load("res://scripts/ui/places.gd").call("npc_active_quests", "bloblo"))
	_talk("bloblo")
	await shot("f_conversa_extra", 0.8)
	await _close_sheet()
	main.call("show_screen", &"tasks")
	var tasks2 := main.find_child("TasksScreen", true, false)
	tasks2.call("choose_group", "characters")
	await shot("g_pessoas_extra", 0.6)
	# Pessoas com um passo da história compartilhado (bloblo_meet = lais_meet_bloblo).
	await _scene("lais_meet_bloblo")
	var tasks3 := main.find_child("TasksScreen", true, false)
	tasks3.call("choose_group", "characters")
	await shot("h_pessoas_historia", 0.6)
	_check(tasks3.find_child("QuestKind_bloblo_meet", true, false) != null and str(tasks3.find_child("QuestKind_bloblo_meet", true, false).get_meta("kind")) == "story", "bloblo_meet é História")
	print("MISSOES V2 SHOTS: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures else 0)
