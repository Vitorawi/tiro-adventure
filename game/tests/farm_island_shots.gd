extends SceneTree
## Capturas da sala do Sítio em ilha (cena única + peças). NÃO é teste.
## Rodar SEM --headless, em celular em pé:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/farm_island_shots.gd -- --out=farm_island
## PNGs em build/screenshots/<out>/ilha_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/farm_island/"
const BUILDINGS := ["silo", "warehouse", "workbench", "greenhouse", "chicken_coop", "cow_barn", "mill", "dairy"]


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(300).timeout.connect(func() -> void: quit(1))


func _save(shot_name: String) -> void:
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "ilha_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


func _enter(world_id: String) -> void:
	main.call("_on_world_requested", world_id, "")
	main.call("show_screen", &"map")
	for i in 6:
		await process_frame
	await create_timer(1.0).timeout
	_hide_modals()


func _room() -> Control:
	for view: Node in get_nodes_in_group("room_views"):
		if view.get("room_id") == "farm":
			return view as Control
	return null


func _close_up(pivot: Vector2, zoom: float, shot_name: String) -> void:
	var view := _room()
	view.call("zoom_to", pivot, zoom, 0.01)
	await create_timer(0.6).timeout
	await _save(shot_name)
	view.call("recenter")
	await create_timer(1.0).timeout


func _focus(point: Vector2, shot_name: String) -> void:
	var view := _room()
	var there: Vector2 = view.call("world_to_screen", point)
	view.call("scroll_by", there - Vector2(180, 400))
	await create_timer(0.6).timeout
	await _close_up(Vector2(180, 400), 1.3, shot_name)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "farm_island_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()

	# 1) Começo: nada construído, só os "+" das compras já liberadas.
	state.call("dev_unlock_everything")
	state.call("finish_fishing_tutorial")  # sem o tutorial da pesca puxando a câmera para a lagoa
	for id: String in BUILDINGS:
		state.get("progress").owned.erase(id)
	state.set("unlocked_plots", 4)
	state.set("coins", 5000)
	await create_timer(0.5).timeout
	await _enter("farm")
	await _save("a_inicio")
	await _close_up(Vector2(170, 470), 1.1, "c_inicio_perto_canteiros")

	# 2) Tudo construído e com animais.
	state.call("dev_unlock_everything")
	state.set("unlocked_plots", 9)
	for station: String in ["chicken_coop", "cow_barn"]:
		for i in 3:
			state.call("buy_animal", "chicken_brown" if station == "chicken_coop" else "cow_brown")
	await create_timer(0.8).timeout
	await _save("b_tudo_construido")
	await _close_up(Vector2(300, 470), 1.0, "d_construido_perto_direita")
	await _close_up(Vector2(60, 440), 1.0, "e_construido_perto_esquerda")
	for n: String in ["hen_1", "hen_2", "cow_1", "cow_2"]:
		var sp: Sprite2D = _room().find_child(n, true, false)
		print("DBG ", n, " vis=", sp.visible, " pos=", sp.position, " a=", sp.self_modulate.a, " scale=", sp.scale, " z=", sp.z_index, " tex=", sp.texture.resource_path, " off=", sp.offset)
	await _focus(Vector2(1080, 1150), "f_galinheiro")
	await _focus(Vector2(1040, 1320), "g_curral")
	var gh_crop := ""
	for id: String in root.get_node("Database").get("crops"):
		if str(root.get_node("Database").get("crops")[id].get("greenhouse", "")) == "only":
			gh_crop = id
			break
	state.call("dev_unlock_everything")
	print("DBG plant ", state.call("plant", 9, gh_crop), state.call("plant", 10, gh_crop), state.call("plant", 11, gh_crop), " crop=", gh_crop)
	state.call("plot", 9)["ready_at"] = 0.0
	state.call("plot", 10)["ready_at"] = 0.0
	await create_timer(1.0).timeout
	await _focus(Vector2(700, 1380), "h_estufa")
	var gh: Sprite2D = _room().find_child("greenhouse", true, false)
	print("DBG tap ", _room().call("_on_object_tapped", "place:greenhouse", gh))
	await create_timer(1.0).timeout
	await _focus(Vector2(700, 1380), "i_estufa_depois")
	# O pomar agora é dentro da estufa: a rota de maçãs aparece no balão da estufa.
	state.get("progress").owned["orchard"] = true
	print("DBG activity ", state.call("start_activity", "orchard_harvest") if state.has_method("start_activity") else "sem start_activity")
	await create_timer(1.0).timeout
	await _focus(gh.position, "j_pomar_na_estufa")
	# Canteiros com plantas (os quatro primeiros ficam abertos no começo).
	state.set("unlocked_plots", 4)
	for i in 4:
		state.call("plant", i, "carrot")
	state.call("plot", 0)["ready_at"] = 0.0
	await create_timer(1.0).timeout
	await _close_up(Vector2(170, 470), 1.1, "k_canteiros_plantados")
	quit(0)
