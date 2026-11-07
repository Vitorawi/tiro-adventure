extends SceneTree
## Capturas dos restos da revisão em madeira: diário/exclusivos de passeio, escolha de rota do Bosque e Achados da Coleção. NÃO é teste.
## pet shop, rotas, diário, coleção). NÃO é teste. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/leftover_wood_shots.gd -- --out=leftover_wood
## PNGs em build/screenshots/<out>/community_<largura>x<altura>_<tela>.png. Não grava o save pessoal.
## Imprime FAIL se algo sai da tela/sob o HUD, alvo < 44, texto cortado ou NinePatch torto.

var state: Node
var main: Node
var folder := "res://../build/screenshots/leftover_wood/"
var failures := 0
const SHEET_TOP := 128.0  # Hud.SHEET_TOP


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(420).timeout.connect(func() -> void: quit(1))


func _fail(message: String) -> void:
	failures += 1
	print("  FAIL: ", message)


func _save(shot_name: String) -> void:
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "leftover_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _audit(shot_name: String, region: Control = null) -> void:
	var sheet := main.get_node("Sheet") as Control
	var panel := (region if region != null else sheet.get_node("%Panel")) as Control
	var screen := root.get_visible_rect().size
	var rect := panel.get_global_rect()
	print("[%s] %s" % [shot_name, rect])
	if region == null:
		if rect.position.y < SHEET_TOP - 1.0: _fail(shot_name + ": folha sob o HUD")
		if rect.end.y > screen.y + 1.0: _fail(shot_name + ": folha passa da base")
		if sheet.get("_wood") != true: _fail(shot_name + ": folha não está em madeira")
	var scroll_rect := rect
	if region == null:
		scroll_rect = ((sheet.get_node("%ContentHolder") as Control).get_parent() as Control).get_global_rect()
	var greens := 0
	for node: Node in panel.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree() or control.size.x <= 0.0 or control.size.y <= 0.0: continue
		var r := control.get_global_rect()
		var exempt := String(control.name).begins_with("Frame") or String(control.name).begins_with("Wood") or control is NinePatchRect or String(control.name) == "Art"
		if not exempt and (r.end.x > screen.x + 0.5 or r.position.x < -0.5):
			_fail("%s: %s sai dos lados (%s)" % [shot_name, control.name, r])
		if control is BaseButton and r.intersects(scroll_rect) and (control.size.x < 37.5 or control.size.y < 35.5) and String(control.name) != "PhotoPick":
			if not String(control.name).begins_with("PhotoPick_"):
				_fail("%s: alvo %s pequeno (%s)" % [shot_name, control.name, control.size])
		if control is Label and (control as Label).clip_text and control.get_minimum_size().y > control.size.y + 1.0:
			_fail("%s: texto cortado em %s" % [shot_name, control.name])
		if control is NinePatchRect and absf(control.scale.x - control.scale.y) > 0.001:
			_fail("%s: NinePatch %s com escala torta" % [shot_name, control.name])
		if control is Button and control.has_meta("wood_primary"):
			greens += 1
	if greens > 1: _fail("%s: %d botões verdes" % [shot_name, greens])
	for node: Node in panel.find_children("*", "Button", true, false):
		var button := node as Button
		if button.disabled and button.is_visible_in_tree() and button.text.strip_edges() != "" and not String(button.name) in ["Minus", "Plus"]:
			_fail("%s: botão desabilitado %s" % [shot_name, button.name])
		if button.theme_type_variation == &"PrimaryButton" or button.theme_type_variation == &"SmallGoButton":
			_fail("%s: botão liso %s" % [shot_name, button.name])


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


## Abre `content` numa folha, captura e audita; fecha em seguida.
func _sheet(title: String, content: Control, shot_name: String) -> void:
	_hide_modals()
	root.get_node("Events").emit_signal("sheet_requested", title, content)
	await create_timer(0.6).timeout
	await _save(shot_name)
	_audit(shot_name)
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.4).timeout


func _script(path: String) -> Script:
	return load("res://scripts/ui/%s.gd" % path) as Script



func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "leftover_wood_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	state.call("dev_unlock_everything")
	state.set("coins", 3000)
	await create_timer(0.5).timeout
	_hide_modals()
	var progression: Script = _script("progression_ui")
	var tray_script: Script = _script("station_tray")
	var places: Script = _script("places")
	# 1. Passeios: diário, exclusivos e a folha de passeios.
	await _sheet("Diário de passeios", progression.call("walk_diary"), "a_diario")
	root.get_node("Events").emit_signal("sheet_requested", "Passeios", _script("walks_ui").call("build"))
	await create_timer(0.8).timeout
	await _save("b_passeios")
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.4).timeout
	# 2. Bosque: escolha de rota na folha e na bandeja.
	state.get("progress").nature_xp["trees"] = 130
	main.call("_on_world_requested", "nature", "")
	await create_timer(2.0).timeout
	_hide_modals()
	for room: Node in get_nodes_in_group("room_views"):
		if room.is_visible_in_tree() and room.has_method("open_nature_tray"):
			room.call("open_nature_tray", "trees", "wood")
	await create_timer(0.8).timeout
	await _save("c_bosque_bandeja")
	var wtray := main.find_child("ActionTray", true, false) as Control
	if wtray == null:
		_fail("c_bosque_bandeja: sem bandeja")
	else:
		_audit("c_bosque_bandeja", wtray)
		if wtray.find_child("RouteChoice_wood", true, false) == null:
			print("  (aviso) bandeja sem RouteChoice_wood")
	for room: Node in get_nodes_in_group("room_views"):
		if room.has_method("close_tray"):
			room.call("close_tray")
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.4).timeout
	await _sheet("Bosque", _script("nature_ui").call("panel", "trees", "wood"), "d_bosque_folha")
	await _sheet("Madeira", project_wood(tray_script.call("material_detail", "trees", "wood")), "e_bosque_detalhe")
	# 3. Achados da Coleção.
	var finds: Script = _script("find_ui")
	await _sheet("Coleção", progression.call("collection_panel"), "f_colecao")
	await _sheet("Achados", project_wood(finds.call("album")), "g_achados_vazio")
	for item: String in ["map_piece_1", "map_piece_2"]:
		state.get("progress").stats["find_item:" + item] = 1
	var db: Node = root.get_node("Database")
	for world: String in db.finds.album_groups:
		for id: String in db.finds.album_groups[world]:
			state.get("progress").stats["find_item:" + id] = 1
			break
	await _sheet("Achados", project_wood(finds.call("album")), "h_achados_parcial")
	print("leftover_wood_shots: %d falha(s)" % failures)
	quit(0 if failures == 0 else 1)


func project_wood(content: Control) -> Control:
	return _script("project_ui").call("wood_sheet", content)
