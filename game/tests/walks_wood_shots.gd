extends SceneTree
## Capturas e MEDIDAS da folha "Passeios", do Tiro passeando na home (AwayView) e do cartão "Voltou do passeio!" em madeira
## ilustrada. NÃO é teste da suíte, mas imprime FAIL e sai com código 1 se algo sair torto. Rodar SEM --headless:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/walks_wood_shots.gd -- --out=walks_wood
## PNGs em build/screenshots/<out>/walks_<largura>x<altura>_<tela>.png. Não grava o save pessoal.
## Termina com "WALKS WOOD SHOTS: OK" quando nada falhou.

var state: Node
var main: Control
var sheet: Control
var folder := "res://../build/screenshots/walks_wood/"
var failures := 0
var hud_height := 168.0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(900).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL: ", message)


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])
	for hidden_name: String in ["Notice", "Toast", "MomentNotice"]:
		var extra := main.find_child(hidden_name, true, false) as CanvasItem
		if extra:
			extra.hide()


func _fresh(kind: String) -> void:
	state.call("reset")
	var progress: RefCounted = state.get("progress")
	progress.seen["intro"] = true
	if kind == "many":
		state.call("dev_unlock_everything")
		progress.count("walk", 30)
		for item in ["stick", "wildflower", "yarn"]:
			progress.count("walk_item:" + item, 2)
		for piece in ["bow_tie", "sailor_scarf", "explorer_backpack", "star_glasses", "sponge_hat"]:
			progress.collection.erase(piece)
	else:
		for id in ["welcome", "lais_bed", "bloblo_meet", "first_harvest", "main_2_order", "nina_meet", "nina_walk"]:
			progress.claimed_quests[id] = true
	state.get("dog").needs["energy"] = 100.0
	state.get("dog").sleeping = false
	state.call("_mark_all_seen")
	state.call("_changed")
	await create_timer(1.0).timeout
	_hide_modals()
	main.set("_modal_queue", [] as Array[Callable])


func _snap(shot_name: String) -> void:
	_hide_modals()
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "walks_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


# --- Medidas --------------------------------------------------------------------------------

func _all(node: Node, found: Array[Node] = []) -> Array[Node]:
	found.append(node)
	for child in node.get_children():
		_all(child, found)
	return found


func _audit(label: String, top: Node, frame_name: String) -> void:
	var screen := root.get_visible_rect().size
	var frame := top.find_child(frame_name, true, false) as Control
	if frame == null:
		_check(false, "[%s] sem %s" % [label, frame_name])
		return
	var rect := frame.get_global_rect()
	_check(rect.position.x >= -0.5 and rect.end.x <= screen.x + 0.5 and rect.end.y <= screen.y + 0.5, "[%s] moldura fora da tela %s" % [label, rect])
	_check(rect.position.y >= hud_height - 1.0 - 40.0, "[%s] moldura sob o HUD %s" % [label, rect])
	_check(absf(rect.get_center().x - screen.x / 2.0) <= 1.0, "[%s] moldura não centralizada" % label)
	var greens := 0
	var mouth := 0
	for node in _all(frame):
		if not (node is CanvasItem) or not (node as CanvasItem).is_visible_in_tree():
			continue
		if node is Button:
			var button := node as Button
			var br := button.get_global_rect()
			_check(br.size.x >= 43.5 and br.size.y >= 43.5, "[%s] alvo < 44: %s %s" % [label, button.name, br.size])
			if bool(button.get_meta("wood_primary", false)):
				greens += 1
		if node is Label:
			var l := node as Label
			if l.text == "":
				continue
			var font := l.get_theme_font("font")
			var px := l.get_theme_font_size("font_size")
			if l.clip_text and l.autowrap_mode == TextServer.AUTOWRAP_OFF:
				_check(font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x <= l.size.x + 1.0, "[%s] texto cortado: '%s' (%s)" % [label, l.text, l.name])
			elif l.autowrap_mode != TextServer.AUTOWRAP_OFF:
				_check(l.get_visible_line_count() >= l.get_line_count(), "[%s] linhas cortadas: '%s'" % [label, l.text])
		if node is TextureRect:
			var t := node as TextureRect
			if t.texture == null:
				continue
			var tr := t.get_global_rect()
			if t.name != "Disc" and t.stretch_mode == TextureRect.STRETCH_SCALE and tr.size.y > 0.0 and t.expand_mode == TextureRect.EXPAND_IGNORE_SIZE:
				var source := t.texture.get_size()
				var ratio := (tr.size.x / tr.size.y) / (source.x / source.y)
				_check(absf(ratio - 1.0) <= 0.01, "[%s] PNG distorcido %s: razão %.3f" % [label, t.name, ratio])
			if t.name == "Icon":
				var m := t.modulate
				_check(m.r + m.g + m.b > 0.9, "[%s] silhueta escura em %s" % [label, t.get_parent().get_parent().name])
			if t.name == "ResultPostcard" or t.name == "AwayPostcard":
				var scale_x := tr.size.x / t.texture.get_width()
				var scale_y := tr.size.y / t.texture.get_height()
				mouth += 1
				_check(absf(scale_x - roundf(scale_x)) < 0.01 and absf(scale_x - scale_y) < 0.01 and scale_x >= 1.0, "[%s] postal em escala não inteira: %.3f x %.3f" % [label, scale_x, scale_y])
				_check(absf(tr.position.x - roundf(tr.position.x)) < 0.01 and absf(tr.position.y - roundf(tr.position.y)) < 0.01, "[%s] postal em posição fracionária %s" % [label, tr.position])
	_check(greens <= 1, "[%s] mais de um botão verde (%d)" % [label, greens])
	print("  [%s] moldura %s verdes %d" % [label, rect, greens])


func _scroll_list(node_name: String, to_end: bool) -> void:
	var scroll := sheet.find_child(node_name, true, false) as ScrollContainer
	if scroll != null:
		scroll.scroll_vertical = 100000 if to_end else 0
	await create_timer(0.3).timeout


# --- Cenas ----------------------------------------------------------------------------------

func _open_walks(shot_name: String, audit: bool = true) -> void:
	root.get_node("Events").sheet_requested.emit("Passeios", (load("res://scripts/ui/progression_ui.gd") as Script).call("walks_panel"))
	await create_timer(0.9).timeout
	_hide_modals()
	await _snap(shot_name)
	if audit:
		_audit(shot_name, sheet, "WalksFrame")


func _close_sheet() -> void:
	root.get_node("Events").sheet_close_requested.emit()
	await create_timer(0.6).timeout


func _show_result(shot_name: String, result: Dictionary) -> void:
	var card: CanvasLayer = main.get("_walk_result")
	card.call("show_result", result)
	await create_timer(1.0).timeout
	for member: String in ["_celebration", "_welcome"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	await _snap(shot_name)
	_audit(shot_name, card, "WelcomeFrame")
	card.hide()
	await create_timer(0.4).timeout


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "walks_descartavel.json"))
	state = root.get_node("GameState")
	Motion.reduced = false
	hud_height = float((load("res://scripts/ui/hud.gd") as GDScript).get_script_constant_map()["HEIGHT"])
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	sheet = main.find_child("Sheet", true, false)
	_hide_modals()
	var events: Node = root.get_node("Events")

	# (a) começo: só "Volta na praça" liberada e nada achado.
	await _fresh("start")
	await _open_walks("a_comeco")
	await _close_sheet()

	# (b) passeio em andamento.
	state.call("start_walk", "park_loop")
	await create_timer(0.4).timeout
	await _open_walks("b_andando")
	await _close_sheet()

	# (d) Tiro passeando na home: postal na moldura de madeira, placa e pílula do tempo.
	main.call("show_screen", &"pet")
	await create_timer(1.2).timeout
	_hide_modals()
	await _snap("d_home_passeando")
	_audit_away()
	state.call("cancel_walk")
	main.call("show_screen", &"map")
	await create_timer(0.4).timeout

	# (c) vários caminhos liberados, achados já pegos (✓), raros e lendário.
	await _fresh("many")
	await _open_walks("c_varios")
	await _scroll_list("WalksScroll", true)
	await _snap("c_varios_rolado")
	await _close_sheet()

	# (e) volta do passeio comum, com muitos achados e com sobra sem espaço.
	await _fresh("start")
	main.call("show_screen", &"pet")
	await create_timer(0.5).timeout
	var common := {"id": "park_loop", "name": "Volta na praça", "postcard": state.call("walk_postcard", "park_loop"), "items": {"stick": 2, "ribbon": 1}, "new": ["ribbon"], "first": true, "coins": 14, "needs": {"happiness": 20, "hygiene": -10}}
	await _show_result("e_volta_comum", common)
	var many_items := {}
	for item in ["stick", "ribbon", "wildflower", "yarn", "color_button", "smooth_pebble", "river_shell", "bird_feather", "wild_mint", "golden_leaf"]:
		many_items[item] = 2
	var big := {"id": "creek_walk", "name": "Beira do riacho", "postcard": state.call("walk_postcard", "creek_walk"), "items": many_items, "new": ["river_shell", "golden_leaf"], "first": false, "coins": 22, "needs": {"happiness": 30, "hygiene": -20}}
	await _show_result("e_muitos_achados", big)
	var walk_state: RefCounted = state.get("walk_state")
	walk_state.pending_return = {"id": "park_loop", "started_at": 0.0, "ready_at": 0.0, "returned_at": 0.0, "seed": 1, "result": common, "left": {"stick": 3}, "rewards_applied": true, "result_shown": false}
	await _show_result("e_com_sobra", common)
	walk_state.pending_return = {}

	events.sheet_close_requested.emit()
	print("WALKS WOOD SHOTS: ", "OK" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


func _audit_away() -> void:
	var screen := root.get_visible_rect().size
	var away := main.find_child("AwayView", true, false) as Control
	if away == null or not away.is_visible_in_tree():
		_check(false, "[d] sem AwayView visível")
		return
	var rect := away.get_global_rect()
	_check(rect.position.y >= hud_height - 0.5, "[d] AwayView sob o HUD %s (HUD %.0f)" % [rect, hud_height])
	var tabs := main.find_child("TabBarArt", true, false) as Control
	if tabs != null and tabs.is_visible_in_tree():
		_check(rect.end.y <= tabs.get_global_rect().position.y + 0.5, "[d] AwayView sobre a barra de abas %s / %s" % [rect, tabs.get_global_rect()])
	var care := main.find_child("CareButton", true, false) as Control
	if care != null and care.is_visible_in_tree():
		_check(not rect.intersects(care.get_global_rect()), "[d] AwayView sobre o botão Cuidar %s / %s" % [rect, care.get_global_rect()])
	_check(rect.position.x >= 0.0 and rect.end.x <= screen.x, "[d] AwayView fora da tela %s" % rect)
	var postcard := main.find_child("AwayPostcard", true, false) as TextureRect
	if postcard != null:
		var tr := postcard.get_global_rect()
		var sx := tr.size.x / postcard.texture.get_width()
		var sy := tr.size.y / postcard.texture.get_height()
		_check(absf(sx - roundf(sx)) < 0.01 and absf(sx - sy) < 0.01, "[d] postal em escala não inteira %.3f x %.3f" % [sx, sy])
		_check(absf(tr.position.x - roundf(tr.position.x)) < 0.01 and absf(tr.position.y - roundf(tr.position.y)) < 0.01, "[d] postal em posição fracionária %s" % tr.position)
	var manual := main.find_child("ManualButton", true, false) as Control
	var frame_part := main.find_child("AwayFrame", true, false) as Control
	if manual != null and manual.is_visible_in_tree() and frame_part != null:
		_check(not frame_part.get_global_rect().intersects(manual.get_global_rect()), "[d] moldura do postal sob o caderninho")
	var plaque_part := main.find_child("AwayPlaque", true, false) as Control
	if manual != null and manual.is_visible_in_tree() and plaque_part != null:
		_check(not plaque_part.get_global_rect().grow(8.0).intersects(manual.get_global_rect()), "[d] placa a menos de 8 px do caderninho %s / %s" % [plaque_part.get_global_rect(), manual.get_global_rect()])
	if plaque_part != null:
		_check(plaque_part.size.x >= 179.5 and absf(plaque_part.get_global_rect().get_center().x - frame_part.get_global_rect().get_center().x) <= 1.0, "[d] placa fora do minimo ou descentrada")
	for node_name: String in ["AwayFrame", "AwayPlaque", "AwayTimePill"]:
		var part := main.find_child(node_name, true, false) as Control
		_check(part != null and screen.y >= part.get_global_rect().end.y, "[d] %s fora da tela" % node_name)
	print("  [d] AwayView ", rect)
