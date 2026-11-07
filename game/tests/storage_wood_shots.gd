extends SceneTree
## Capturas da folha dos depósitos em madeira ilustrada (Armazém, Silo, Geladeira, Baú + ampliação). NÃO é teste.
## Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/storage_wood_shots.gd -- --out=storage_wood
## PNGs em build/screenshots/<out>/storage_<largura>x<altura>_<tela>.png. Não grava o save pessoal.
## Imprime FAIL se algo sai da tela/sob o HUD, alvo < 44, texto cortado ou NinePatch torto.

var state: Node
var main: Node
var folder := "res://../build/screenshots/storage_wood/"
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
	image.save_png(path + "storage_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _audit(shot_name: String) -> void:
	var sheet := main.get_node("Sheet") as Control
	var panel := sheet.get_node("%Panel") as Control
	var screen := root.get_visible_rect().size
	var rect := panel.get_global_rect()
	print("[%s] folha %s" % [shot_name, rect])
	if rect.position.y < SHEET_TOP - 1.0: _fail(shot_name + ": folha sob o HUD")
	if rect.end.y > screen.y + 1.0: _fail(shot_name + ": folha passa da base")
	if sheet.get("_wood") != true: _fail(shot_name + ": folha não está em madeira")
	var scroll := (sheet.get_node("%ContentHolder") as Control).get_parent() as Control
	for node: Node in panel.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree() or control.size.x <= 0.0 or control.size.y <= 0.0: continue
		var r := control.get_global_rect()
		var exempt := String(control.name).begins_with("Frame") or String(control.name).begins_with("Wood") or control is NinePatchRect
		if not exempt and (r.end.x > screen.x + 0.5 or r.position.x < -0.5):
			_fail("%s: %s sai dos lados (%s)" % [shot_name, control.name, r])
		if control is BaseButton and control.get_global_rect().intersects(scroll.get_global_rect()) and (control.size.x < 37.5 or control.size.y < 35.5):  # abas da tábua = as da Mochila (38)
			_fail("%s: alvo %s pequeno (%s)" % [shot_name, control.name, control.size])
		if control is Label and (control as Label).clip_text and control.get_minimum_size().y > control.size.y + 1.0:
			_fail("%s: texto cortado em %s" % [shot_name, control.name])
		if control is NinePatchRect and absf(control.scale.x - control.scale.y) > 0.001:
			_fail("%s: NinePatch %s com escala torta" % [shot_name, control.name])
	for name: String in ["UpgradeName", "BuildUpgrade", "LockHint"]:
		for found: Node in panel.find_children(name, "", true, false):
			print("  %s %s" % [name, (found as Control).get_global_rect()])


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


func _place(world: String, place: String, shot_name: String, expand := false) -> void:
	load("res://scripts/ui/places.gd").call("open", world, place)
	await create_timer(0.6).timeout
	await _save(shot_name)
	_audit(shot_name)
	if expand:
		var button := main.get_node("Sheet").find_child("ExpandStorage", true, false) as Button
		if button == null:
			_fail(shot_name + ": sem botão Expandir")
		else:
			print("  ExpandStorage %s verde=%s" % [button.get_global_rect(), button.has_meta("wood_primary")])
			button.pressed.emit()
			await create_timer(0.6).timeout
			await _save(shot_name + "_expandir")
			_audit(shot_name + "_expandir")
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.4).timeout
func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "storage_wood_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	state.call("dev_unlock_everything")
	for id: String in ["warehouse_2", "warehouse_3", "warehouse_4", "warehouse_5", "silo_2", "silo_3", "silo_4", "silo_5", "fridge_2", "fridge_3", "fridge_4", "fridge_5", "chest_2", "chest_3", "chest_4", "chest_5"]:
		state.get("progress").owned.erase(id)
	var inv: Object = state.get("inventory")
	for id: String in inv.get("counts").keys():
		inv.get("counts").erase(id)
	for pair: Array in [["wood", 6], ["stone", 2], ["bolt", 1], ["carrot", 12], ["wheat", 8], ["pumpkin", 4], ["strawberry_juice", 2], ["treat_box", 1], ["old_horseshoe", 2], ["egg", 3]]:
		if load("res://autoload/database.gd") != null:
			inv.get("counts")[pair[0]] = pair[1]
	state.set("coins", 577)
	await create_timer(0.5).timeout
	_hide_modals()
	await _place("farm", "warehouse", "a_armazem")
	await _place("farm", "warehouse", "b_armazem_falta", true)
	state.get("inventory").get("counts")["plank"] = 2
	await _place("farm", "warehouse", "g_armazem_pronto", true)
	state.set("coins", 3)
	await _place("farm", "warehouse", "f_armazem_sem_moedas", true)
	state.set("coins", 577)
	await _place("farm", "silo", "c_silo")
	await _place("house", "fridge", "d_geladeira")
	await _place("house", "chest", "e_bau")
	print("storage_wood_shots: %d falha(s)" % failures)
	quit(0 if failures == 0 else 1)
