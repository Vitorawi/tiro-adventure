extends SceneTree
## Capturas da etapa 09 da economia (colher não paga moeda; contratos). NÃO é teste.
## Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/coins_shots.gd -- --out=etapa09_depois/360x780
## `--antes` volta em memória às moedas por colheita e aos valores antigos (cenoura +3, contrato 220).
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/etapa09/"
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
	saver.set("_save_path", "user://coins_shots_descartavel.json")
	state = root.get_node("GameState")
	if before:
		var database: Node = root.get_node("Database")
		var old := {"carrot": 3, "potato": 9, "pumpkin": 16, "herbs": 24}
		for id: String in old:
			database.get("crops")[id]["coins"] = old[id]
		database.get("progression").orders.special_order.rewards["coins"] = 220
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
	events.sheet_requested.emit("Canteiro", load("res://scripts/ui/sheet_builder.gd").call("seed_picker", 0))
	await shot("01_sementes")
	events.sheet_close_requested.emit()
	events.sheet_requested.emit("Minha banca", load("res://scripts/ui/market_ui.gd").call("orders", "special_order", "contracts"))
	await shot("02_contrato_caixas")
	print("COINS SHOTS: pronto")
	quit()
