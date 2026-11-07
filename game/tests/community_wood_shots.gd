extends SceneTree
## Capturas das folhas da Praça, da Vila e do Tiro em madeira ilustrada (obras, Nossa praça/vila, amigos, truques, casa,
## pet shop, rotas, diário, coleção). NÃO é teste. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/community_wood_shots.gd -- --out=community_wood
## PNGs em build/screenshots/<out>/community_<largura>x<altura>_<tela>.png. Não grava o save pessoal.
## Imprime FAIL se algo sai da tela/sob o HUD, alvo < 44, texto cortado ou NinePatch torto.

var state: Node
var main: Node
var folder := "res://../build/screenshots/community_wood/"
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
	image.save_png(path + "community_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


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


func _finish_project(id: String) -> void:
	for guard in 12:
		if state.call("project_completed", id):
			return
		var stage: Dictionary = state.call("project_stage", id)
		if bool(stage.get("done", false)):
			return
		for item: String in stage.remaining:
			var need := int(stage.remaining[item])
			if need > 0:
				state.get("inventory").call("add", item, need)
				state.call("contribute_project", id, item, need)
		state.call("_recover_projects")


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "community_wood_shots_descartavel.json"))
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
	var project: Script = _script("project_ui")
	# Obras: antes de começar, em andamento (falta material e com material), pronta e com Encontro.
	state.call("dev_complete_quest", "atelier_open")
	await _sheet("Banco da Praça", project.call("panel", "park_bench"), "a_banco_inicio")
	state.call("start_project", "park_bench")
	await _sheet("Banco da Praça", project.call("panel", "park_bench"), "b_banco_falta")
	var stage: Dictionary = state.call("project_stage", "park_bench")
	for item: String in stage.needed:
		state.get("inventory").call("add", item, 6)
	await _sheet("Banco da Praça", project.call("panel", "park_bench"), "c_banco_entrega")
	_finish_project("park_bench")
	await _sheet("Banco da Praça", project.call("panel", "park_bench"), "d_banco_pronto")
	await _sheet("Nossa praça", project.call("community", "park"), "e_nossa_praca")
	state.call("start_project", "park_picnic")
	state.call("start_project", "village_garden")
	await _sheet("Piquenique da Praça", project.call("panel", "park_picnic"), "f_piquenique")
	await _sheet("Jardim da Vila", project.call("panel", "village_garden"), "g_jardim")
	await _sheet("Nossa vila", project.call("community", "village"), "h_nossa_vila")
	_finish_project("park_picnic")
	_finish_project("village_garden")
	state.call("start_project", "village_festival")
	_finish_project("village_festival")
	for item: String in ["picnic_pack", "carrot_snack"]:
		state.get("inventory").call("add", item, 3)
	await _sheet("Festa da Vila", project.call("panel", "village_festival"), "i_festa_encontro")
	# Amigos.
	state.get("friend_state").entry("pipoca").gifts = 1
	await _sheet("Amigos", _script("friend_ui").call("panel", "pipoca"), "j_amigo")
	await _sheet("Amigos", project.call("wood_sheet", _script("friend_ui").call("album")), "k_album_amigos")
	state.get("inventory").call("add", "carrot_snack", 2)
	root.get_node("Events").emit_signal("world_requested", "park", "")
	await create_timer(1.5).timeout
	_hide_modals()
	_script("friend_ui").call("open", "pipoca")
	await create_timer(0.8).timeout
	await _save("l_bandeja_amigo")
	var tray := main.find_child("ActionTray", true, false) as Control
	if tray == null:
		_fail("l_bandeja_amigo: sem bandeja do amigo")
	else:
		_audit("l_bandeja_amigo", tray)
	var rooms := get_nodes_in_group("room_views")
	for room: Node in rooms:
		if room.has_method("close_tray"):
			room.call("close_tray")
	# Truques.
	await _sheet("Truques", _script("trick_ui").call("panel", true), "m_truques_treino")
	state.get("progress").tricks["paw"] = true
	await _sheet("Truques", _script("trick_ui").call("panel", false), "n_truques")
	# Casa.
	var house: Script = _script("house_ui")
	await _sheet("Caminha", house.call("bed"), "o_cama")
	state.call("dev_take_photo", "h_arrival")
	await _sheet("Prateleira de lembranças", house.call("shelf"), "p_prateleira")
	await _sheet("Parede de fotos", house.call("wall"), "q_parede")
	await _sheet("Moldura dourada", house.call("frame"), "r_moldura")
	await _sheet("Cesto de brinquedos", house.call("toys"), "s_cesto")
	# Pet shop, rotas, diário, coleção.
	var progression: Script = _script("progression_ui")
	await _sheet("Pet shop", progression.call("petshop_panel"), "t_petshop")
	await _sheet("Pomar", progression.call("routes_panel", "orchard"), "u_pomar")
	await _sheet("Diário de passeios", progression.call("walk_diary"), "v_diario")
	await _sheet("Coleção", progression.call("collection_panel"), "w_colecao")
	print("community_wood_shots: %d falha(s)" % failures)
	quit(0 if failures == 0 else 1)
