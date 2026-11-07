extends SceneTree
## Capturas das folhas de produção/horta/Natureza, do balão de cuidado e dos selos dos personagens, em madeira
## ilustrada. NÃO é teste. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/map_wood_shots.gd -- --out=map_wood
## PNGs em build/screenshots/<out>/map_<largura>x<altura>_<tela>.png. Não grava o save pessoal.
## Imprime FAIL se algo sai da tela/sob o HUD, alvo < 44, texto cortado ou NinePatch torto.

var state: Node
var main: Node
var folder := "res://../build/screenshots/map_wood/"
var failures := 0
const SHEET_TOP := 128.0  # Hud.SHEET_TOP


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(400).timeout.connect(func() -> void: quit(1))


func _fail(message: String) -> void:
	failures += 1
	print("  FAIL: ", message)


func _save(shot_name: String) -> void:
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "map_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _audit(shot_name: String) -> void:
	var sheet := main.get_node("Sheet") as Control
	var panel := sheet.get_node("%Panel") as Control
	var screen := root.get_visible_rect().size
	var rect := panel.get_global_rect()
	if rect.position.y < SHEET_TOP - 1.0: _fail(shot_name + ": folha sob o HUD")
	if rect.end.y > screen.y + 1.0: _fail(shot_name + ": folha passa da base")
	if sheet.get("_wood") != true: _fail(shot_name + ": folha não está em madeira")
	var scroll := (sheet.get_node("%ContentHolder") as Control).get_parent() as Control
	var visible_area := scroll.get_global_rect()
	for node: Node in panel.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree() or control.size.x <= 0.0 or control.size.y <= 0.0: continue
		var r := control.get_global_rect()
		var exempt := String(control.name).begins_with("Frame") or String(control.name).begins_with("Wood") or control is NinePatchRect
		if not exempt and (r.end.x > screen.x + 0.5 or r.position.x < -0.5):
			_fail("%s: %s sai dos lados (%s)" % [shot_name, control.name, r])
		if control is BaseButton and r.intersects(visible_area) and r.size.y > 1.0 and (control.size.x < 37.5 or control.size.y < 35.5):
			_fail("%s: alvo %s pequeno (%s)" % [shot_name, control.name, control.size])
		if control is Label and (control as Label).clip_text and control.get_minimum_size().y > control.size.y + 1.0:
			_fail("%s: texto cortado em %s" % [shot_name, control.name])
		if control is NinePatchRect and absf(control.scale.x - control.scale.y) > 0.001:
			_fail("%s: NinePatch %s com escala torta" % [shot_name, control.name])
	var greens := 0
	for button: Node in panel.find_children("*", "Button", true, false):
		if button.has_meta("wood_primary") and (button as Control).is_visible_in_tree():
			greens += 1
	if greens > 1: _fail("%s: %d botões verdes" % [shot_name, greens])
	print("[%s] folha %s verdes=%d" % [shot_name, rect, greens])


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


func _close() -> void:
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.4).timeout


func _place(world: String, place: String, shot_name: String) -> void:
	load("res://scripts/ui/places.gd").call("open", world, place)
	await create_timer(0.6).timeout
	await _save(shot_name)
	_audit(shot_name)
	await _close()


func _sheet(title: String, content: Control, shot_name: String) -> void:
	root.get_node("Events").emit_signal("sheet_requested", title, content)
	await create_timer(0.6).timeout
	await _save(shot_name)
	_audit(shot_name)
	await _close()


func _world(id: String) -> void:
	main.call("_on_world_requested", id, "")
	await create_timer(2.0).timeout
	_hide_modals()


func _empty_plots() -> void:
	var plots: Array = state.get("plots")
	for i in plots.size():
		plots[i] = {"crop": "", "ready_at": 0.0}
	state.call("_changed")


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "map_wood_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	state.call("dev_unlock_everything")
	state.call("dev_add_items", 20)
	state.set("coins", 900)
	await create_timer(0.5).timeout
	_hide_modals()
	var builder: Script = load("res://scripts/ui/sheet_builder.gd")
	# Selos dos personagens no mapa (era um quadrado vermelho).
	await _world("farm")
	var farm_room: Node = main.find_child("World_farm", true, false)
	for id: String in ["bloblo", "lais"]:
		var npc: Node = farm_room.call("npc_node", id)
		if npc != null:
			npc.call("_set_badge", "new" if id == "bloblo" else "ready")
			print("selo forçado em ", id)
	await _save("a_selos_sitio")
	await _world("house")
	await _save("a_selos_casa")
	# Folhas "Ver tudo" das estações.
	await _place("house", "stove", "b_fogao")
	state.call("dev_add_items", 20)
	for i in 3:
		state.call("cook", "carrot_snack")
	state.call("dev_advance_time", 40)
	await _place("house", "stove", "b_fogao_trabalhando")
	await _place("house", "bowl", "c_tigela")
	await _world("farm")
	await _place("farm", "workbench", "d_producao")
	await _place("farm", "chicken_coop", "e_galinheiro")
	await _place("farm", "plots", "f_canteiros")
	await _place("farm", "greenhouse", "g_estufa")
	await _sheet("Canteiro", builder.call("seed_picker", 0), "h_sementes")
	await _sheet("Maestria: Fogão", builder.call("mastery_help", "stove"), "i_maestria")
	await _world("nature")
	await _place("nature", "trees", "j_bosque")
	await _sheet("Evolução · Bosque", load("res://scripts/ui/nature_ui.gd").call("levels_panel", "trees"), "k_niveis")
	await _sheet("Refinar · Bosque", load("res://scripts/ui/nature_ui.gd").call("refining_panel", "trees"), "l_refinar")
	# Balão de cuidado do canteiro e o da colheita.
	await _world("farm")
	var farm: Node = main.find_child("World_farm", true, false)
	_empty_plots()
	state.call("plant", 5, "carrot")
	state.call("water", 5)
	farm.call("_on_plot_tapped", 5)
	await _save("m_cuidado")
	farm.call("close_tray")
	print("map_wood_shots: %d falha(s)" % failures)
	quit(0 if failures == 0 else 1)
