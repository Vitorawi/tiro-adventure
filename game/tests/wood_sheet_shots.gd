extends SceneTree
## Capturas das folhas em madeira ilustrada: conversa com personagem (missões, pronta, apresentação) e compra de
## construção (comprável, bloqueada, adquirida). NÃO é teste.
## Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/wood_sheet_shots.gd -- --out=wood_sheet
## PNGs em build/screenshots/<out>/wood_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/wood_sheet/"
var failures := 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(400).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FALHOU: ", message)


func shot(shot_name: String, wait: float = 0.8) -> void:
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "wood_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])
	var sheet := main.get_node("Sheet") as Control
	var panel := sheet.get_node("%Panel") as Control
	var rect := panel.get_global_rect()
	print("[%s] folha %s (tela %s)" % [shot_name, rect, root.get_visible_rect().size])
	_check(rect.position.x <= 0.5 and rect.end.x >= root.get_visible_rect().size.x - 0.5, "folha não ocupa a largura")
	var scroll := sheet.get_node("%ContentHolder").get_parent() as Control
	var holder := sheet.get_node("%ContentHolder") as Control
	_check(holder.get_combined_minimum_size().x <= scroll.size.x + 1.0, "conteúdo mais largo que a folha (%s > %s)" % [holder.get_combined_minimum_size().x, scroll.size.x])
	for button: Node in sheet.find_children("*", "Button", true, false):
		var control := button as Control
		if control.is_visible_in_tree() and control.get_global_rect().size.y > 0.0 and (control.size.y < 43.5 or control.size.x < 43.5):
			_check(false, "alvo %s menor que 44 px (%s)" % [button.name, control.size])


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


func _close_sheet() -> void:
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.3).timeout


func _fresh() -> void:
	state.call("reset")
	var progress: Object = state.get("progress")
	progress.seen["intro"] = true
	state.call("_mark_all_seen")
	state.call("_changed")
	main.call("show_screen", &"pet")
	await create_timer(0.3).timeout
	_hide_modals()


## Avança a história até o passo `stop` (marca os anteriores como recebidos).
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


func _talk(npc_id: String) -> void:
	state.call("mark_seen", ["npc_intro:" + npc_id] as Array[String])
	load("res://scripts/ui/places.gd").call("open_npc", npc_id)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "wood_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	var progression_ui: Script = load("res://scripts/ui/progression_ui.gd")
	var db: Node = root.get_node("Database")

	# Apresentação: primeira fala e a última (Vamos!).
	await _fresh()
	state.call("dev_unlock_everything")
	state.get("progress").seen.erase("npc_intro:bloblo")
	await create_timer(1.0).timeout
	_hide_modals()
	root.get_node("Events").emit_signal("sheet_requested", "Vovó Bloblo", progression_ui.call("npc_introduction", "bloblo", 0))
	await shot("a_apresentacao")
	var lines: Array = db.npcs.bloblo.introduction
	root.get_node("Events").emit_signal("sheet_requested", "Vovó Bloblo", progression_ui.call("npc_introduction", "bloblo", lines.size() - 1))
	await shot("b_apresentacao_fim")
	await _close_sheet()

	# Conversa com mais de uma missão ativa (uma delas com objetivo feito).
	await _reopen_lines("bloblo", 2)
	_talk("bloblo")
	await shot("c_conversa_missoes")
	await _close_sheet()

	# Missão pronta (Pegar): a primeira da Laís, depois de falar com ela.
	await _fresh()
	state.call("talk_to", "lais")
	_talk("lais")
	await shot("d_conversa_pronta")
	await _close_sheet()

	# Compra: comprável, com materiais e ganho de espaço, bloqueada e adquirida.
	await _fresh()
	root.get_node("Events").emit_signal("sheet_requested", "Desbloquear Bosque", progression_ui.call("purchase", "forest_open"))
	await shot("e_compra_bloqueada")
	await _close_sheet()
	_claim_until("main_5_cooking")
	state.set("coins", 500)
	await create_timer(0.3).timeout
	root.get_node("Events").emit_signal("sheet_requested", "Desbloquear Bosque", progression_ui.call("purchase", "forest_open"))
	await shot("f_compra_disponivel")
	await _close_sheet()
	state.set("coins", 5)
	await create_timer(0.3).timeout
	root.get_node("Events").emit_signal("sheet_requested", "Desbloquear Bosque", progression_ui.call("purchase", "forest_open"))
	await shot("g_compra_sem_moedas")
	await _close_sheet()
	state.set("coins", 500)
	root.get_node("Events").emit_signal("sheet_requested", "Silo", progression_ui.call("purchase", "silo_2"))
	await shot("h_compra_ampliacao")
	await _close_sheet()
	state.call("dev_unlock_everything")
	await create_timer(1.0).timeout
	_hide_modals()
	root.get_node("Events").emit_signal("sheet_requested", "Desbloquear Bosque", progression_ui.call("purchase", "forest_open"))
	await shot("i_compra_adquirida")
	await _close_sheet()

	print("WOOD SHOTS: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures else 0)


## Deixa `count` linhas do personagem com um passo ativo (reabre o último passo de cada uma) e zera o primeiro objetivo
## do primeiro passo, para a conversa mostrar uma missão pela metade.
func _reopen_lines(npc_id: String, count: int) -> void:
	var progress: Object = state.get("progress")
	var quests: Dictionary = root.get_node("Database").get("quests")
	var by_line: Dictionary = {}
	for id: String in quests:
		var quest: Dictionary = quests[id]
		if quest.get("npc", "") == npc_id and quest.get("kind", "") == "line":
			var line := str(quest.get("line", ""))
			if not by_line.has(line):
				by_line[line] = []
			by_line[line].append(id)
	var picked := 0
	for line: String in by_line:
		if picked >= count:
			break
		var ids: Array = by_line[line]
		ids.sort_custom(func(a: String, b: String) -> bool: return int(quests[a].get("order", 0)) < int(quests[b].get("order", 0)))
		progress.claimed_quests.erase(ids[ids.size() - 1])
		picked += 1
		if picked == 1:
			for goal: Dictionary in quests[ids[ids.size() - 1]].goals:
				progress.stats.erase(str(goal.get("key", "")))
	state.call("_changed")
	await create_timer(0.3).timeout
	print("  ativas de ", npc_id, ": ", load("res://scripts/ui/places.gd").call("npc_active_quests", npc_id))


func _dump(node: Node, depth: int = 0) -> void:
	var control := node as Control
	if control and control.get_combined_minimum_size().y > 400.0:
		print("  ", "  ".repeat(depth), node.name, " ", node.get_class(), " min ", control.get_combined_minimum_size(), " size ", control.size)
		for child: Node in node.get_children():
			_dump(child, depth + 1)
