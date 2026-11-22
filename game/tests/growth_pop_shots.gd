extends SceneTree
## Capturas da janelinha de explicação dos passos do painel Crescimento (madeira ilustrada).
## NÃO é teste. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/growth_pop_shots.gd -- --out=growth_pop
## PNGs em build/screenshots/<out>/pop_<largura>x<altura>_<caso>.png. Não grava o save pessoal.
## Imprime FAIL se a janelinha sai da tela, fica sob o HUD, tem alvo < 44, texto cortado ou mais de um botão verde.

var state: Node
var main: Node
var folder := "res://../build/screenshots/growth_pop/"
var failures := 0
var growth_ui: Script


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(300).timeout.connect(func() -> void: quit(1))


func _fail(message: String) -> void:
	failures += 1
	print("  FAIL: ", message)


func _save(shot_name: String) -> void:
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "pop_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _greens(node: Node) -> int:
	var count := int(node is Button and bool(node.get_meta("wood_primary", false)) and (node as Control).is_visible_in_tree())
	for child: Node in node.get_children():
		count += _greens(child)
	return count


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


func _audit(case_name: String, tile: Variant) -> void:
	var pop := main.find_child("GrowthStepPop", true, false) as Control
	if pop == null:
		_fail(case_name + ": janelinha não abriu")
		return
	var screen := root.get_visible_rect().size
	var rect := pop.get_global_rect()
	var tile_rect := (tile as Control).get_global_rect() if is_instance_valid(tile) else Rect2()
	print("[%s] janelinha %s  quadradinho %s" % [case_name, rect, tile_rect])
	if rect.position.x < -0.5 or rect.end.x > screen.x + 0.5: _fail(case_name + ": sai dos lados")
	if rect.position.y < 0.0 or rect.end.y > screen.y + 0.5: _fail(case_name + ": sai da tela")
	if _greens(pop) > 1: _fail(case_name + ": mais de um botão verde")
	for node: Node in pop.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree() or control.size.x <= 0.0:
			continue
		var r := control.get_global_rect()
		if r.end.x > rect.end.x + 0.5 or r.position.x < rect.position.x - 0.5:
			_fail("%s: %s passa da janelinha (%s)" % [case_name, control.name, r])
		if control is BaseButton and control.size.y < 43.5 and not String(control.name).begins_with("Dot"):
			_fail("%s: alvo %s pequeno (%s)" % [case_name, control.name, control.size])
		if control is Label and (control as Label).clip_text and control.get_minimum_size().y > control.size.y + 1.0:
			_fail("%s: texto cortado em %s" % [case_name, control.name])
	var explain := pop.find_children("GrowthExplain_*", "Label", true, false)
	if explain.is_empty() or (explain[0] as Label).text.strip_edges() == "": _fail(case_name + ": sem explicação")


func _case(case_name: String, step_id: String) -> void:
	growth_ui.call("_close_pop")
	await create_timer(0.2).timeout
	var tile := main.find_child("GrowthReq_" + step_id, true, false) as Button
	if tile == null:
		_fail(case_name + ": sem o quadradinho " + step_id)
		return
	var scroll := main.get_node("Sheet").find_child("Scroll", true, false) as ScrollContainer
	if scroll != null:
		scroll.ensure_control_visible(tile)
		await create_timer(0.2).timeout
	tile.pressed.emit()
	await create_timer(0.6).timeout
	await _save(case_name)
	_audit(case_name, tile)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "growth_pop_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	growth_ui = load("res://scripts/ui/growth_ui.gd")
	var events: Node = root.get_node("Events")

	# Filhotinho: comida, banho e um passo feito.
	state.call("dev_set_phase", "newborn")
	state.get("growth").done = {"puppy": {"bath": true}}
	state.call("_changed")
	growth_ui.call("open")
	await create_timer(0.8).timeout
	await _case("a_comida", "feed")
	await _case("b_banho_feito", "bath")
	await _case("c_caminha_direita", "bed")
	events.emit_signal("sheet_close_requested")
	await create_timer(0.4).timeout

	# Dentinhos com a aula da comida concluída (patinhas), coluna da direita e última linha.
	state.call("dev_set_phase", "puppy")
	state.get("week").food_lesson = true
	state.get("growth").done = {"teething": {"key_egg": true}}
	state.call("_changed")
	growth_ui.call("open")
	await create_timer(0.8).timeout
	await _case("d_patinhas", "days")
	await _case("e_prato_direita", "star_dish")
	await _case("f_ultima_linha", "sit_good")
	await _case("g_ultima_linha_meio", "rope")
	events.emit_signal("sheet_close_requested")
	await create_timer(0.4).timeout

	# Fase pronta: todos os passos feitos; o toque ainda abre a janelinha.
	state.call("dev_set_phase", "newborn")
	var done := {}
	for req: Dictionary in root.get_node("Database").growth.phases[1].requirements:
		done[str(req.id)] = true
	state.get("growth").done = {"puppy": done}
	state.call("_changed")
	growth_ui.call("open")
	await create_timer(0.8).timeout
	await _case("h_fase_pronta", "feed")

	print("GROWTH_POP SHOTS: ", "OK" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures else 0)
