extends SceneTree
## Capturas da etapa 10 da economia (sementes com tempo e lote novos). NÃO é teste.
## Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/garden_shots.gd -- --out=etapa10_depois/360x780
## `--antes` volta em memória aos tempos, lotes e XP antigos.
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/etapa10/"
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
	saver.set("_save_path", "user://garden_shots_descartavel.json")
	state = root.get_node("GameState")
	if before:
		var database: Node = root.get_node("Database")
		var old := {"carrot": [60, 2, 10], "potato": [300, 2, 22], "pumpkin": [600, 1, 35], "herbs": [900, 2, 55], "wheat": [120, 3, 12], "corn": [180, 3, 15], "strawberry": [180, 2, 15], "blueberry": [900, 3, 40], "sweet_potato": [420, 2, 30]}
		for id: String in old:
			var crop: Dictionary = database.get("crops")[id]
			crop["seconds"] = old[id][0]
			crop["yield"] = {id: old[id][1]}
			crop["skill_xp"] = old[id][2]
	
	state.call("reset")
	var progress: Object = state.get("progress")
	progress.seen["intro"] = true
	state.call("dev_jump_to_chapter", 7)
	progress.owned["farm"] = true
	progress.owned["stall"] = true
	progress.claimed_quests["first_harvest"] = true
	state.call("_mark_all_seen")
	state.get("inventory").counts.clear()
	state.get("inventory").add("treat_box", 3)
	state.set("coins", 100)
	state.call("_changed")
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	var events: Node = root.get_node("Events")
	progress.owned["greenhouse"] = true
	progress.claimed_quests["bloblo_dig"] = true
	progress.claimed_quests["bloblo_potato"] = true
	progress.claimed_quests["farm_deed"] = true
	state.call("_changed")
	events.sheet_requested.emit("Canteiro", load("res://scripts/ui/sheet_builder.gd").call("seed_picker", 0))
	await shot("01_sementes")
	events.sheet_close_requested.emit()
	events.sheet_requested.emit("Estufa", load("res://scripts/ui/sheet_builder.gd").call("seed_picker", 9))
	await shot("02_estufa")
	print("GARDEN SHOTS: pronto")
	quit()
