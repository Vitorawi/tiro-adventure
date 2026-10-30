extends SceneTree
## Capturas do mini-cartão do próximo passo (madeira ilustrada). NÃO é teste.
## Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/step_card_shots.gd -- --out=step_card
## PNGs em build/screenshots/<out>/step_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/step_card/"
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
	image.save_png(path + "step_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])
	var card := main.find_child("StepCard", true, false) as Control
	if card:
		var rect := card.get_global_rect()
		var width := float(root.get_visible_rect().size.x)
		print("[%d %s] cartão %s | margens esq %.1f dir %.1f" % [int(width), shot_name, rect, rect.position.x, width - rect.end.x])
		_check(rect.position.x >= 7.5 and width - rect.end.x >= 7.5, "cartão fora da folga de 8 px")
		_check(rect.end.y <= root.get_visible_rect().size.y, "cartão passa da tela")
		for button: Node in card.find_children("*", "Button", true, false):
			var size := (button as Control).size
			_check(size.y >= 43.5 and size.x >= 43.5, "alvo %s menor que 44 px (%s)" % [button.name, size])


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


func _open_real(shot_name: String, setup: Callable) -> void:
	state.call("reset")
	var progress: Object = state.get("progress")
	progress.seen["intro"] = true
	if setup.is_valid():
		setup.call(progress)
	state.call("_mark_all_seen")
	state.call("_changed")
	main.call("show_screen", &"pet")
	await create_timer(0.4).timeout
	_hide_modals()
	var step := main.find_child("NextStep", true, false) as Button
	_check(step != null and step.visible, "%s: NextStep invisível" % shot_name)
	if step == null:
		return
	step.pressed.emit()
	await shot(shot_name, 0.6)
	var catcher := root.find_child("PopoverCatcher", true, false)
	if catcher:
		catcher.queue_free()
	await create_timer(0.1).timeout


## Cartão de uma missão sintética (objetivos à vontade), aberto pelo mesmo Popover da pílula real.
func _open_fake(shot_name: String, goals: Array, values: Array, rewards: Dictionary) -> void:
	var quests: Dictionary = root.get_node("Database").get("quests")
	var entry := {"npc": "lais", "name": "Missão de teste", "dialogue": "Vamos juntos, uma coisa de cada vez. Eu ajudo você com cada passo, tá?", "goals": goals, "rewards": rewards, "kind": "main", "chapter": 1, "order": 1}
	quests["_shot_fake"] = entry
	var progress: Object = state.get("progress")
	for i in goals.size():
		progress.stats[str(goals[i].key)] = int(values[i])
	state.call("_changed")
	var step := main.find_child("NextStep", true, false) as Control
	var card: Control = load("res://scripts/ui/next_step.gd").call("card", "_shot_fake")
	var popover: Object = load("res://scripts/ui/popover.gd").call("open", main, step, card, 0.0)
	await shot(shot_name, 0.6)
	popover.close()
	await create_timer(0.3).timeout
	quests.erase("_shot_fake")


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "step_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	# (a) um objetivo, 0/1.
	await _open_real("a_um_objetivo", Callable())
	# (b) três objetivos, o primeiro feito.
	await _open_real("b_varios", func(p: Object) -> void:
		_claim_until("main_5_cooking")
		p.stats["produce:carrot_snack"] = 2)
	# (c) depósito cheio: "Liberar espaço".
	await _open_real("c_liberar_espaco", func(p: Object) -> void:
		p.stats["talk:lais"] = 1
		# A ração normalmente não tem teto: só para esta captura ela vai para o cesto da horta (em memória).
		root.get_node("Database").items["dog_food"]["storage"] = "silo"
		state.get("inventory").call("add", "dog_food", 500)
		print("  guia: ", (load("res://scripts/ui/quest_guide.gd") as GDScript).call("current").state))
	# (d) quatro e seis objetivos (linhas compactas, rolagem).
	var goals4: Array = [
		{"type": "stat", "key": "shot_a", "target": 3, "label": "Colher 3 cenouras"},
		{"type": "stat", "key": "shot_b", "target": 2, "label": "Cozinhar 2 lanches de cenoura"},
		{"type": "have", "key": "wood", "target": 6, "label": "Guardar madeira"},
		{"type": "stat", "key": "shot_d", "target": 1, "label": "Fazer 1 suco de morango"}]
	root.get_node("Database").items["dog_food"]["storage"] = "none"
	state.get("inventory").call("from_dict", {})
	_hide_modals()
	await _open_fake("d_quatro", goals4, [3, 1, 0, 0], {"coins": 40, "items": {"wood": 2}})
	var goals7: Array = goals4.duplicate(true)
	goals7.append({"type": "stat", "key": "shot_e", "target": 5, "label": "Regar 5 vezes"})
	goals7.append({"type": "stat", "key": "shot_f", "target": 4, "label": "Brincar 4 vezes com o Tiro"})
	goals7.append({"type": "stat", "key": "shot_g", "target": 2, "label": "Passear com o Tiro"})
	await _open_fake("e_sete_rolagem", goals7, [3, 2, 0, 0, 1, 0, 0], {"coins": 40})
	print("STEP SHOTS: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures else 0)
