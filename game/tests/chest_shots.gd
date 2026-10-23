extends SceneTree
## Capturas da Sacola de passeio → Baú (Etapa 08 da economia). NÃO é teste.
## Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/chest_shots.gd -- --out=etapa08_depois/360x780
## `--antes` desliga o limite provisório e volta ao baú antigo (80 moedas, madeira 4, base 20, sem limite nos itens de passeio).
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/etapa08/"
var before := false


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
		if arg == "--antes":
			before = true
	_run.call_deferred()


func shot(shot_name: String, wait: float = 0.6) -> void:
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path + shot_name + ".png")


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
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
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "chest_shots_descartavel.json"))
	state = root.get_node("GameState")
	if before:
		var database: Node = root.get_node("Database")
		var storage: Dictionary = database.get("progression").storage.chest
		storage.erase("prebuild_capacity")
		storage.erase("prebuild_name")
		storage["base"] = 20
		var chest: Dictionary = database.get("progression").upgrades.chest
		chest["cost"] = 80
		chest["materials"] = {"wood": 4}
		chest["requirements"] = {"quests": ["bloblo_warehouse"]}
		for id: String in database.get("items"):
			if str(database.get("items")[id].get("category", "")) == "trail":
				database.get("items")[id]["storage"] = "none"
	state.call("reset")
	var progress: Object = state.get("progress")
	progress.seen["intro"] = true
	state.call("dev_jump_to_chapter", 3)
	for id: String in ["main_2_order", "nina_meet", "nina_walk"]:
		state.call("dev_complete_quest", id)
	progress.owned["farm"] = true
	state.call("_mark_all_seen")
	progress.seen["feature:bag"] = true
	var inventory: Object = state.get("inventory")
	inventory.counts.clear()
	inventory.add("stick", 2)
	inventory.add("ribbon", 3)
	inventory.add("wildflower", 4)
	inventory.add("dog_food", 1)
	inventory.add("bolt", 1)
	for id: String in inventory.counts:
		progress.seen["ui:bag:" + id] = true
	state.set("coins", 100)
	state.call("_changed")
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	main.call("show_screen", &"bag")
	await shot("01_mochila_sacola")
	root.get_node("Events").sheet_requested.emit("Graveto", load("res://scripts/ui/sheet_builder.gd").call("item_detail", "stick"))
	await shot("02_detalhe_graveto")
	root.get_node("Events").sheet_close_requested.emit()
	root.get_node("Events").sheet_requested.emit("Baú", load("res://scripts/ui/progression_ui.gd").call("purchase", "chest"))
	await shot("03_painel_bau")
	root.get_node("Events").sheet_close_requested.emit()
	main.call("show_screen", &"tasks")
	await shot("04_missoes_nina")
	# Sacola cheia (12/12) e depois o baú construído.
	inventory.add("yarn", 12 - int(state.call("storage_used", "chest")))
	state.call("_changed")
	main.call("show_screen", &"bag")
	await shot("05_mochila_cheia")
	state.call("buy_upgrade", "chest")
	main.call("show_screen", &"bag")
	await shot("06_mochila_bau", 3.6)
	print("CHEST SHOTS: pronto")
	quit()
