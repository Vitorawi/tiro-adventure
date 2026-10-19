extends SceneTree
## Capturas da Despensa → Geladeira (Etapa 06 da economia). NÃO é teste.
## Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/fridge_shots.gd -- --out=etapa06_depois/360x780
## `--antes` desliga o limite provisório e volta a base 30 (como era antes da etapa 06).
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/etapa06/"
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
	saver.set("_save_path", "user://fridge_shots_descartavel.json")
	state = root.get_node("GameState")
	if before:
		var storage: Dictionary = root.get_node("Database").get("progression").storage.fridge
		storage.erase("prebuild_capacity")
		storage.erase("prebuild_name")
		storage["base"] = 30
	state.call("reset")
	var progress: Object = state.get("progress")
	progress.seen["intro"] = true
	for id: String in ["lais_bed", "lais_meet_bloblo", "lais_first_crops", "bloblo_meet", "first_harvest"]:
		state.call("dev_complete_quest", id)
	progress.owned["farm"] = true
	state.set("unlocked_plots", 4)
	state.call("_ensure_plots")
	state.call("_mark_all_seen")
	progress.seen["feature:bag"] = true
	var inventory: Object = state.get("inventory")
	inventory.counts.clear()
	inventory.add("carrot_snack", 6)
	inventory.add("cheese", 3)
	inventory.add("egg", 2)
	inventory.add("dog_food", 3)
	for id: String in inventory.counts:
		progress.seen["ui:bag:" + id] = true
	state.set("coins", 200)
	state.call("_changed")
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	main.call("show_screen", &"bag")
	await shot("01_mochila_despensa")
	root.get_node("Events").sheet_requested.emit("Petisco de cenoura", load("res://scripts/ui/sheet_builder.gd").call("item_detail", "carrot_snack"))
	await shot("02_detalhe_comida")
	root.get_node("Events").sheet_close_requested.emit()
	root.get_node("Events").sheet_requested.emit("Queijo", load("res://scripts/ui/sheet_builder.gd").call("item_detail", "cheese"))
	await shot("03_detalhe_queijo")
	root.get_node("Events").sheet_close_requested.emit()
	# Despensa cheia (12/12) e o painel de compra da geladeira (12 → 24).
	inventory.add("carrot_snack", 1)
	inventory.add("cheese", 0)
	inventory.add("milk", 12 - int(state.call("storage_used", "fridge")))
	state.call("_changed")
	main.call("show_screen", &"bag")
	await shot("04_mochila_cheia")
	root.get_node("Events").sheet_requested.emit("Geladeira", load("res://scripts/ui/progression_ui.gd").call("purchase", "fridge"))
	await shot("05_painel_geladeira")
	root.get_node("Events").sheet_close_requested.emit()
	state.call("buy_upgrade", "fridge")
	main.call("show_screen", &"bag")
	await shot("06_mochila_geladeira", 3.6)
	print("FRIDGE SHOTS: pronto")
	quit()
