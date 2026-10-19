extends SceneTree
## Capturas da Pilha de materiais → Armazém (Etapa 07 da economia). NÃO é teste.
## Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/warehouse_shots.gd -- --out=etapa07_depois/360x780
## `--antes` desliga o limite provisório e volta ao armazém antigo (150 moedas, madeira 8, pedra 4, base 40).
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/etapa07/"
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
	saver.set("_save_path", "user://warehouse_shots_descartavel.json")
	state = root.get_node("GameState")
	if before:
		var database: Node = root.get_node("Database")
		var storage: Dictionary = database.get("progression").storage.warehouse
		storage.erase("prebuild_capacity")
		storage.erase("prebuild_name")
		storage["base"] = 40
		var warehouse: Dictionary = database.get("progression").upgrades.warehouse
		warehouse["cost"] = 150
		warehouse["materials"] = {"wood": 8, "stone": 4}
		warehouse["requirements"] = {"quests": ["bloblo_silo"]}
	state.call("reset")
	var progress: Object = state.get("progress")
	progress.seen["intro"] = true
	state.call("dev_jump_to_chapter", 4)
	for id: String in ["lais_forest", "guide_meet", "guide_wood", "guide_open_cave"]:
		if root.get_node("Database").get("quests").has(id):
			state.call("dev_complete_quest", id)
	progress.owned["farm"] = true
	state.set("unlocked_plots", 4)
	state.call("_ensure_plots")
	state.call("_mark_all_seen")
	progress.seen["feature:bag"] = true
	var inventory: Object = state.get("inventory")
	inventory.counts.clear()
	inventory.add("wood", 5)
	inventory.add("stone", 3)
	inventory.add("fiber", 2)
	inventory.add("bolt", 1)
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
	await shot("01_mochila_materiais")
	root.get_node("Events").sheet_requested.emit("Madeira", load("res://scripts/ui/sheet_builder.gd").call("item_detail", "wood"))
	await shot("02_detalhe_madeira")
	root.get_node("Events").sheet_close_requested.emit()
	root.get_node("Events").sheet_requested.emit("Armazém", load("res://scripts/ui/progression_ui.gd").call("purchase", "warehouse"))
	await shot("03_painel_armazem")
	root.get_node("Events").sheet_close_requested.emit()
	main.call("show_screen", &"tasks")
	await shot("04_missoes_guia")
	# Pilha cheia e depois o armazém construído.
	inventory.add("wood", 16 - int(state.call("storage_used", "warehouse")))
	state.call("_changed")
	main.call("show_screen", &"bag")
	await shot("05_mochila_cheia")
	state.call("buy_upgrade", "warehouse")
	main.call("show_screen", &"bag")
	await shot("06_mochila_armazem", 3.6)
	print("WAREHOUSE SHOTS: pronto")
	quit()
