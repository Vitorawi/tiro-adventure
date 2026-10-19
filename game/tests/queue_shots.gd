extends SceneTree
## Capturas da etapa 12 da economia (Preparar N na bandeja do fogão). NÃO é teste.
## Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/queue_shots.gd -- --out=etapa12_depois/360x780
## `--antes` tira as ampliações da fila: com uma só vaga a bandeja fica como era (sem seletor de quantidade).
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/etapa12/"
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
	saver.set("_save_path", "user://queue_shots_descartavel.json")
	state = root.get_node("GameState")
	state.call("reset")
	var progress: Object = state.get("progress")
	progress.seen["intro"] = true
	state.call("dev_jump_to_chapter", 5)
	for id in ["stove", "workbench", "blender"] + ([] if before else ["stove_queue", "stove_queue_2", "blender_queue"]):
		progress.owned[id] = true
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
	var tray: Script = load("res://scripts/ui/station_tray.gd")
	if room != null:
		room.call("open_station_tray", "stove")
		await shot("01_fogao_bandeja", 1.2)
		if not before:
			tray.call("_set_count", "carrot_snack", 3)
			await shot("02_fogao_quantidade_3", 0.8)
			var current: Control = (load("res://scripts/ui/action_tray.gd") as Script).get("current")
			var cook: Button = current.find_child("Cook", true, false)
			if cook != null:
				cook.pressed.emit()
				await shot("03_fogao_fila_cheia", 1.2)
	print("QUEUE SHOTS: pronto")
	quit()
