extends SceneTree
## Capturas da Mochila "madeira ilustrada". NÃO é teste.
## Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/bag_shots.gd -- --out=bag_wood
## PNGs em build/screenshots/<out>/bag_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/bag_wood/"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()


func shot(shot_name: String, wait: float = 0.7) -> void:
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "bag_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "bag_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("_mark_all_seen")
	state.set("coins", 1280)
	state.call("dev_unlock_everything")
	state.call("_changed")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	# Poucos itens, alguns novos (pontinho).
	for pair: Array in [["carrot", 6], ["wheat", 3], ["apple", 2], ["wood", 4], ["egg", 2], ["carrot_snack", 1]]:
		state.get("inventory").call("add", pair[0], pair[1])
	state.call("_changed")
	main.call("show_screen", &"bag")
	await shot("mochila")
	# Muitos itens: a grade rola.
	state.call("dev_add_items", 5)
	await create_timer(0.3).timeout
	_hide_modals()
	main.call("show_screen", &"pet")
	await create_timer(0.2).timeout
	main.call("show_screen", &"bag")
	await shot("mochila_cheia")
	var bag := main.find_child("BagScreen", true, false)
	var list := bag.find_child("InventoryList", true, false)
	list.call("choose_category", "crop")
	await shot("filtro_colheitas", 0.4)
	list.call("choose_category", "all")
	list.call("choose_storage", "silo")
	await shot("silo", 0.4)
	list.call("choose_storage", "silo")
	state.call("dev_add_pending_gift")
	await create_timer(0.3).timeout
	_hide_modals()
	await shot("presentes", 0.5)
	quit()
