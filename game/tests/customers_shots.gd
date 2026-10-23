extends SceneTree
## Capturas da etapa 15 da economia (clientes e banca). NÃO é teste.
## Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/customers_shots.gd -- --out=etapa15_depois/360x780
## `--antes` troca em memória a interface antiga (sem cliente nem tipos): só esconde o resumo/cliente.
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/etapa15/"
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
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "customers_shots_descartavel.json"))
	state = root.get_node("GameState")
	if before:
		var orders: Dictionary = root.get_node("Database").get("progression").orders
		for id: String in orders:
			orders[id].erase("customer")
	state.call("reset")
	state.set("unlimited_storage", true)
	var progress: Object = state.get("progress")
	progress.seen["intro"] = true
	state.call("dev_jump_to_chapter", 9)
	for token: String in ["farm", "stove", "fridge", "blender", "dairy", "stall"]:
		progress.owned[token] = true
	progress.claimed_quests["first_harvest"] = true
	progress.claimed_quests["bloblo_strawberry"] = true
	progress.claimed_quests["bloblo_potato"] = true
	state.call("_mark_all_seen")
	state.set("coins", 400)
	state.get("inventory").add("carrot", 4)
	state.get("inventory").add("carrot_snack", 3)
	state.call("_changed")
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	var events: Node = root.get_node("Events")
	var market: Script = load("res://scripts/ui/market_ui.gd")
	# Cliente sem patamar (Laís 0/3, Bloblo 0/3) e banca com 0 contratos.
	events.sheet_requested.emit("Pedidos", market.call("orders", "vegetables", "neighbors"))
	await shot("01_clientes_sem_patamar")
	events.sheet_close_requested.emit()
	events.sheet_requested.emit("Minha banca", market.call("orders", "", "contracts"))
	await shot("02_banca_sem_contratos")
	events.sheet_close_requested.emit()
	# Último patamar da Laís; Bloblo no meio.
	progress.stats["order:vegetables"] = 10
	progress.stats["order:soup_order"] = 6
	progress.stats["order:juice_order"] = 3
	progress.stats["order:snacks"] = 9
	progress.stats["order:farm_breakfast"] = 1
	progress.stats["order:building_order"] = 5
	progress.stats["order:special_order"] = 1
	state.call("_changed")
	events.sheet_requested.emit("Pedidos", market.call("orders", "vegetables", "neighbors"))
	await shot("03_clientes_ultimo_patamar")
	events.sheet_close_requested.emit()
	events.sheet_requested.emit("Minha banca", market.call("orders", "", "contracts"))
	await shot("04_banca_6_contratos_2_tipos")
	print("CUSTOMERS SHOTS: pronto")
	quit()
