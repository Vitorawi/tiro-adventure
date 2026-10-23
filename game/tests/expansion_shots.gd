extends SceneTree
## Capturas da etapa 18 da economia (vagas novas e medidor de maestria nas estações). NÃO é teste.
## Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/expansion_shots.gd -- --out=etapa18_depois/360x780
## `--antes` mostra como era: sem as quatro filas novas e sem o medidor de maestria.
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/etapa18/"
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
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "expansion_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	var progress: Object = state.get("progress")
	progress.seen["intro"] = true
	state.call("dev_jump_to_chapter", 5)
	var queues := ["stove_queue", "stove_queue_2", "blender_queue"] + ([] if before else ["stove_queue_3", "mill_queue", "dairy_queue", "atelier_queue"])
	for id in ["stove", "workbench", "blender", "fridge", "farm", "chicken_coop", "mill", "silo", "silo_2", "silo_3", "atelier"] + queues:
		progress.owned[id] = true
	if before:
		(root.get_node("Database").get("progression") as Dictionary).mastery.stations = []
	else:
		progress.stats["station_jobs:stove"] = 14
		progress.stats["station_recipe_jobs:stove:carrot_snack"] = 10
		progress.stats["station_recipe_jobs:stove:vegetable_soup"] = 4
		progress.stats["station_jobs:mill"] = 45
		progress.stats["station_recipe_jobs:mill:flour"] = 45
		state.get("economy").granted["mastery:stove:1"] = true
		state.get("economy").granted["mastery:mill:1"] = true
		state.get("economy").granted["mastery:mill:2"] = true
	state.call("_mark_all_seen")
	state.set("unlimited_storage", true)
	var inventory: Object = state.get("inventory")
	for id in ["carrot", "potato", "strawberry", "pumpkin"]:
		inventory.add(id, 12)
	state.set("coins", 300)
	state.call("_changed")
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	main.call("_on_world_requested", "house", "")
	await create_timer(1.2).timeout
	var room: Node = main.find_child("World_house", true, false)
	if room != null:
		room.call("open_station_tray", "stove")
		await shot("01_fogao_bandeja", 1.2)
		if not before:
			var builder: Script = load("res://scripts/ui/sheet_builder.gd")
			root.get_node("Events").sheet_requested.emit("Maestria: Fogão", builder.call("mastery_help", "stove"))
			await shot("03_ajuda_maestria", 1.0)
			root.get_node("Events").sheet_close_requested.emit()
	main.call("_on_world_requested", "farm", "")
	await create_timer(1.2).timeout
	room = main.find_child("World_farm", true, false)
	if room != null:
		room.call("open_station_tray", "mill")
		await shot("02_moinho_bandeja", 1.2)
	print("EXPANSION SHOTS: pronto")
	quit()
