extends SceneTree
## Capturas das telas de crescimento em madeira ilustrada (painel, caderneta, cuidados, resumo do avatar, aviso do HUD).
## NÃO é teste. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/growth_wood_shots.gd -- --out=growth_wood
## PNGs em build/screenshots/<out>/growth_<largura>x<altura>_<tela>.png. Não grava o save pessoal.
## Imprime FAIL se algo sai da tela/sob o HUD, alvo < 44, texto cortado, NinePatch torto ou mais de um botão verde.

var state: Node
var main: Node
var folder := "res://../build/screenshots/growth_wood/"
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


func _close_sheet() -> void:
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.4).timeout


func _sheet_shot(shot_name: String, opener: Callable) -> void:
	opener.call()
	await create_timer(0.7).timeout
	await _save(shot_name)
	_audit_sheet(shot_name)
	await _close_sheet()


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "growth_wood_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	var growth_ui: Script = load("res://scripts/ui/growth_ui.gd")
	var hud: Node = main.find_child("TopBar", true, false)
	var screen := root.get_visible_rect().size

	# Filhotinho: passos pendentes e passo recomendado.
	state.call("dev_set_phase", "puppy")
	await _sheet_shot("a_puppy", func() -> void: growth_ui.call("open"))
	# Dentinhos com momentos parciais e outro passo escolhido.
	state.call("dev_set_phase", "teething")
	state.get("growth").phase_moments = {"body": 34, "coat": 0, "smart": 19, "brave": 61}
	state.get("progress").owned["stove"] = true
	state.call("_changed")
	await _sheet_shot("b_teething", func() -> void: growth_ui.call("open"))
	growth_ui.call("open")
	await create_timer(0.7).timeout
	var tile := main.find_child("GrowthReq_pillars", true, false) as Button
	if tile != null:
		tile.pressed.emit()
		await create_timer(0.5).timeout
		await _save("c_teething_outro_passo")
		_audit_sheet("c_teething_outro_passo")
	await _close_sheet()
	# Resumo do avatar (madeira) com passos pendentes.
	hud.call("show_level_popover")
	await create_timer(0.7).timeout
	await _save("d_resumo_avatar")
	var pop := main.get_node_or_null("PopoverCatcher")
	if pop == null:
		_fail("d_resumo_avatar: sem popover")
	else:
		var surface := pop.get_node("Popover") as Control
		var rect := surface.get_global_rect()
		print("[d_resumo_avatar] popover %s" % rect)
		if rect.end.x > screen.x or rect.end.y > screen.y or rect.position.x < 0.0:
			_fail("d_resumo_avatar: popover fora da tela")
		if _greens(pop) > 1: _fail("d_resumo_avatar: mais de um verde")
		_audit_controls("d_resumo_avatar", pop, screen)
		main.get_node("PopoverCatcher").queue_free()
	await create_timer(0.3).timeout
	# Pronto: aviso no HUD, painel com o botão Crescer e resumo.
	state.call("dev_complete_growth_reqs")
	await create_timer(0.6).timeout
	await _save("e_hud_pode_crescer")
	var alert := main.find_child("GrowthReadyAlert", true, false) as Control
	if alert == null or not alert.is_visible_in_tree():
		_fail("e_hud_pode_crescer: aviso invisível")
	else:
		print("[e_hud] alerta %s perfil %s moedas %s" % [alert.get_global_rect(), (main.find_child("HudProfile", true, false) as Control).get_global_rect(), (main.find_child("CoinsColumn", true, false) as Control).get_global_rect()])
		if alert.size.y < 43.5 and alert.size.y < 30.0: _fail("alerta pequeno demais")
		if alert.get_global_rect().end.x >= (main.find_child("CoinsColumn", true, false) as Control).get_global_rect().position.x:
			_fail("e_hud_pode_crescer: aviso invade as moedas")
	await _sheet_shot("f_pronto", func() -> void: growth_ui.call("open"))
	hud.call("show_level_popover")
	await create_timer(0.7).timeout
	await _save("g_resumo_pronto")
	if main.get_node_or_null("PopoverCatcher") != null:
		main.get_node("PopoverCatcher").queue_free()
	await create_timer(0.3).timeout
	# Caderneta e Cuidados do Tiro.
	await _sheet_shot("h_caderneta", func() -> void: growth_ui.call("history"))
	await _sheet_shot("i_cuidados", func() -> void: root.get_node("Events").emit_signal("sheet_requested", "Cuidados do Tiro", load("res://scripts/ui/pillar_ui.gd").call("panel")))
	# Adulto: brilho (seda) com requisito faltando e pronto.
	state.call("dev_set_phase", "adult")
	state.get("growth").silk = 0
	state.call("_changed")
	await _sheet_shot("j_adulto_seda", func() -> void: growth_ui.call("open"))
	print("growth_wood_shots: %d falha(s)" % failures)
	quit(0 if failures == 0 else 1)
