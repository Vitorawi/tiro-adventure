extends SceneTree
## Capturas do prato dinâmico (E02) na Mochila, no detalhe do item e na aba DEV Semana. NÃO é teste.
## Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/dish_shots.gd -- --out=dish_bag
## PNGs em build/screenshots/<out>/dish_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/dish_bag/"
var failures := 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(120).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FALHOU: ", message)


func shot(shot_name: String, wait: float = 0.7) -> void:
	await create_timer(wait).timeout
	_hide_modals()
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "dish_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
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


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "dish_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("_mark_all_seen")
	state.set("coins", 800)
	state.call("dev_unlock_everything")
	state.call("dev_week_goto", 5)
	var rules: Script = load("res://scripts/state/dish_rules.gd")
	var ids: Array[String] = []
	for entry: Array in [["papinha", ["cenoura", "ovo", "peixe"], 2], ["sopinha", ["cenoura", "batata", "peixe"], 1], ["mingau", ["milho", "banana"], 1],
			["petisco", ["ovo"], 1], ["biscoito", ["aveia", "abobora"], 1], ["papinha", ["abobrinha", "arroz", "peixe"], 3]]:
		ids.append(str(rules.call("make_id", entry[0], entry[1], entry[2])))
	for id in ids:
		state.get("inventory").call("add", id, 2)
	state.get("inventory").call("add", "gororoba", 1)
	state.get("inventory").call("add", "carrot", 3)
	state.call("_changed")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	main.call("show_screen", &"bag")
	await shot("a_mochila")
	var bag := main.find_child("BagScreen", true, false)
	var list := bag.find_child("InventoryList", true, false)
	list.call("choose_storage", "fridge")
	await shot("b_geladeira", 0.5)
	for id: String in [ids[0], ids[3], "gororoba"]:
		_check(state.get("inventory").call("count", id) > 0 and root.get_node("Database").get("items").has(id), "%s no inventário e registrado" % id)
	list.call("choose_storage", "fridge")
	# Detalhe de uma refeição (papinha de 2 estrelas) e de um lanche.
	for index in [[0, "c_detalhe_papinha"], [3, "d_detalhe_petisco"]]:
		var id: String = ids[index[0]]
		root.get_node("Events").sheet_requested.emit(str(root.get_node("Database").call("item_name", id)), (load("res://scripts/ui/sheet_builder.gd") as Script).call("item_detail", id))
		await shot(index[1], 0.8)
		root.get_node("Events").sheet_close_requested.emit()
		await create_timer(0.4).timeout
	# DEV: aba Semana com os botões de ingredientes.
	var dev := main.find_child("DevButton", true, false) as Button
	if dev != null:
		dev.pressed.emit()
		await create_timer(0.6).timeout
		var panel := main.find_child("DevTab_week", true, false) as Button
		if panel != null:
			panel.pressed.emit()
			await create_timer(0.4).timeout
		await shot("e_dev_semana", 0.5)
	print("DISH SHOTS: ", "OK" if failures == 0 else "FALHOU (%d)" % failures)
	quit()
