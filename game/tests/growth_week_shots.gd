extends SceneTree
## Capturas da E05 (Para crescer da primeira semana): painel de Recém-chegado, de Filhotinho, pronto e cerimônia com resumo.
## NÃO é teste. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/growth_week_shots.gd -- --out=e05_growth
## PNGs em build/screenshots/<out>/growth_<largura>x<altura>_<tela>.png. Não grava o save pessoal.
## Imprime FAIL se algo sai da tela/sob o HUD, alvo < 44, texto cortado, NinePatch torto ou mais de um botão verde.

var state: Node
var main: Node
var folder := "res://../build/screenshots/e05_growth/"
var failures := 0
const SHEET_TOP := 128.0  # Hud.SHEET_TOP


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
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "growth_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _greens(node: Node) -> int:
	var count := int(node is Button and bool(node.get_meta("wood_primary", false)) and (node as Control).is_visible_in_tree())
	for child: Node in node.get_children():
		count += _greens(child)
	return count


func _audit_controls(shot_name: String, scope: Node, screen: Vector2) -> void:
	for node: Node in scope.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree() or control.size.x <= 0.0 or control.size.y <= 0.0:
			continue
		var r := control.get_global_rect()
		var exempt := String(control.name).begins_with("Frame") or String(control.name).begins_with("Wood") or control is NinePatchRect
		if not exempt and (r.end.x > screen.x + 0.5 or r.position.x < -0.5):
			_fail("%s: %s sai dos lados (%s)" % [shot_name, control.name, r])
		if control is BaseButton and (control.size.x < 43.5 or control.size.y < 43.5) and not String(control.name).begins_with("Dot"):
			_fail("%s: alvo %s pequeno (%s)" % [shot_name, control.name, control.size])
		if control is Label and (control as Label).clip_text and control.get_minimum_size().y > control.size.y + 1.0:
			_fail("%s: texto cortado em %s" % [shot_name, control.name])
		if control is NinePatchRect and absf(control.scale.x - control.scale.y) > 0.001:
			_fail("%s: NinePatch %s com escala torta" % [shot_name, control.name])


func _audit_sheet(shot_name: String) -> void:
	var sheet := main.get_node("Sheet") as Control
	var panel := sheet.get_node("%Panel") as Control
	var screen := root.get_visible_rect().size
	var rect := panel.get_global_rect()
	print("[%s] folha %s" % [shot_name, rect])
	if rect.position.y < SHEET_TOP - 1.0: _fail(shot_name + ": folha sob o HUD")
	if rect.end.y > screen.y + 1.0: _fail(shot_name + ": folha passa da base")
	if sheet.get("_wood") != true: _fail(shot_name + ": folha não está em madeira")
	var greens := _greens(panel)
	if greens > 1: _fail("%s: %d botões verdes" % [shot_name, greens])
	_audit_controls(shot_name, panel, screen)
	var scroll := sheet.find_child("Scroll", true, false) as ScrollContainer
	if scroll != null:
		var bar := scroll.get_v_scroll_bar()
		print("  rolagem %d de %d" % [int(bar.max_value), int(bar.page)])
	var tiles := panel.find_children("GrowthReq_*", "Button", true, false)
	for tile: Node in tiles:
		if (tile as Control).size != (tiles[0] as Control).size:
			_fail("%s: quadradinhos de tamanhos diferentes" % shot_name)
	for header: String in ["GrowthDetails", "GrowthHistoryButton"]:
		for found: Node in sheet.find_children(header, "", true, false):
			print("  %s %s" % [header, (found as Control).get_global_rect()])
	var title := sheet.get_node("%Title") as Label
	for close: Node in sheet.find_children("CloseButton", "", true, false):
		if title.get_global_rect().end.x > (close as Control).get_global_rect().position.x + 1.0 and title.is_visible_in_tree():
			print("  aviso: título pode encostar no X (%s)" % title.get_global_rect())


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])
	for found: Node in main.find_children("*", "", true, false):
		if str(found.name) in ["QuestReward", "RewardSheet", "ModalCard"] or str(found.name).begins_with("Reward"):
			found.queue_free()


func _close_sheet() -> void:
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.4).timeout


func _sheet_shot(shot_name: String, opener: Callable) -> void:
	opener.call()
	await create_timer(0.7).timeout
	await _save(shot_name)
	_audit_sheet(shot_name)
	await _close_sheet()


func _feed_dishes(count: int) -> void:
	var rules: Script = load("res://scripts/state/dish_rules.gd")
	var per_type := {}
	var served := 0
	for entry: Dictionary in rules.call("combinations", 9):
		var type := str(entry.type)
		if not rules.call("is_meal", type) or served >= count or int(per_type.get(type, 0)) >= 3:
			continue
		per_type[type] = int(per_type.get(type, 0)) + 1
		state.get("inventory").call("add", str(rules.call("make_id", type, entry.ingredients, 1)), 1)
		state.call("feed", str(rules.call("make_id", type, entry.ingredients, 1)))
		served += 1


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "growth_week_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	var growth_ui: Script = load("res://scripts/ui/growth_ui.gd")
	# Recém-chegado: nada feito.
	await _sheet_shot("a_recem_chegado", func() -> void: growth_ui.call("open"))
	# Alguns pratos, um dia e brincadeiras.
	state.call("dev_grant_upgrade", "dog_bed")
	state.call("dev_week_goto", 1)
	_feed_dishes(3)
	state.call("dev_week_meal", "lunch")
	await _sheet_shot("b_recem_chegado_meio", func() -> void: growth_ui.call("open"))
	# Filhotinho: 8 pratos de só 2 tipos (falta um tipo) e ganchos ligados.
	state.call("dev_set_phase", "puppy")
	state.get("growth").phase_dishes = {}
	_feed_dishes(8)
	await create_timer(0.8).timeout
	_hide_modals()
	main.get_node("Sheet").call("close") if false else null
	await _sheet_shot("c_filhotinho", func() -> void:
		_hide_modals()
		growth_ui.call("open"))
	# Pronto + cerimônia com resumo.
	state.call("dev_set_phase", "newborn")
	state.call("dev_complete_growth_reqs")
	state.call("grow")
	await create_timer(0.6).timeout
	var ceremony: Variant = main.get("_growth_ceremony")
	if ceremony != null:
		(ceremony as CanvasLayer).call("open", "puppy")
		await create_timer(0.3).timeout
		ceremony.call("show_card")
		await create_timer(0.8).timeout
		await _save("d_cerimonia_resumo")
		if ceremony.find_child("CeremonySummary", true, false) == null and ceremony.find_child("CeremonyOpened", true, false) == null:
			_fail("d_cerimonia_resumo: sem resumo")
	print("growth_week_shots: %d falha(s)" % failures)
	quit(0 if failures == 0 else 1)
