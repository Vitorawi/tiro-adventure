extends SceneTree
## Capturas da etapa 20 da economia (Banco da Praça). NÃO é teste.
## Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/bench_shots.gd -- --out=etapa20_depois/360x780
## `--antes` volta em memória à Praça sem "Nossa praça" nem obra (Amigos e Treino na lista, sem banco).
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var events: Node
var folder := "res://../build/screenshots/etapa20/"
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
	main.set("_modal_queue", [] as Array[Callable])


func _give(items: Dictionary) -> void:
	for id: String in items:
		state.get("inventory").add(id, int(items[id]))


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", "user://bench_shots_descartavel.json")
	state = root.get_node("GameState")
	events = root.get_node("Events")
	var database: Node = root.get_node("Database")
	if before:
		var places: Dictionary = database.get("worlds").park.places
		places.erase("community")
		places.erase("bench")
		places.friends.erase("hidden")
		places.training.erase("hidden")
		database.get("projects").projects = {}
	state.call("reset")
	state.get("progress").seen["intro"] = true
	for id in ["welcome", "lais_bed", "bloblo_meet", "first_harvest", "main_2_order", "nina_pipoca"]:
		state.get("progress").claimed_quests[id] = true
	for id in ["stove", "workbench", "fridge", "atelier", "chest", "silo", "warehouse", "petshop", "sewing_table"]:
		state.call("dev_grant_upgrade", id)
	state.call("dev_complete_quest", "atelier_open")
	state.call("_mark_all_seen")
	state.set("coins", 600)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.6).timeout
	_hide_modals()
	main.call("show_screen", &"map")
	main.find_child("WorldsScreen", true, false).call("show_map")
	await shot("01_mapa_carrossel")
	main.call("_on_world_requested", "park", "")
	await create_timer(3.0).timeout
	_hide_modals()
	await shot("02_praca_inicio", 1.2)
	main.call("show_screen", &"map")
	var places_button: Button = main.find_child("PlacesButton", true, false)
	if places_button:
		places_button.pressed.emit()
		await shot("03_lugares")
		events.emit_signal("sheet_close_requested")
	if before:
		quit(0)
		return
	events.emit_signal("sheet_requested", "Nossa praça", load("res://scripts/ui/project_ui.gd").call("community"))
	await shot("04_nossa_praca_lista")
	events.emit_signal("sheet_requested", "Banco da Praça", load("res://scripts/ui/project_ui.gd").call("panel", "park_bench"))
	await shot("05_obra_antes_de_comecar")
	state.call("start_project", "park_bench")
	await shot("06_obra_sem_material", 1.3)
	_give({"plank": 4, "brick": 1})
	await shot("07_entrega_parcial", 1.3)
	state.call("contribute_project", "park_bench", "plank", 3)
	await shot("08_entregue_parcial", 1.3)
	events.emit_signal("sheet_close_requested")
	await shot("09_praca_marcacao_progresso", 1.0)
	state.call("contribute_project", "park_bench", "plank", 1)
	state.call("contribute_project", "park_bench", "brick", 1)
	_give({"brick": 1})
	state.call("contribute_project", "park_bench", "brick", 1)
	await shot("10_praca_fase_base", 1.0)
	_give({"fabric": 2, "braided_toy": 1})
	state.call("contribute_project", "park_bench", "fabric", 2)
	state.call("contribute_project", "park_bench", "braided_toy", 1)
	await shot("11_praca_fase_conforto", 1.0)
	events.emit_signal("sheet_requested", "Banco da Praça", load("res://scripts/ui/project_ui.gd").call("panel", "park_bench"))
	_give({"carrot_snack": 3})
	await shot("12_painel_ultima_fase", 1.3)
	events.emit_signal("sheet_close_requested")
	main.set("_modal_queue", [] as Array[Callable])
	state.call("contribute_project", "park_bench", "carrot_snack", 3)
	await create_timer(0.8).timeout
	await shot("13_obra_pronta_cartao", 1.0)
	_hide_modals()
	await shot("14_praca_banco_pronto", 0.8)
	_hide_modals()
	events.emit_signal("sheet_requested", "Banco da Praça", load("res://scripts/ui/project_ui.gd").call("panel", "park_bench"))
	await shot("15_painel_obra_pronta", 1.0)
	events.emit_signal("sheet_close_requested")
	var park: Node = main.find_child("World_park", true, false)
	var bench: Sprite2D = park.find_child("community_bench", true, false)
	await create_timer(0.5).timeout
	_hide_modals()
	park.call("zoom_to", park.call("world_to_screen", bench.position), 1.8, 0.0)
	await shot("16_zoom_banco_pronto", 0.8)
	park.call("_on_tap_released", park.call("world_to_screen", bench.position - Vector2(0, 14)))
	_hide_modals()
	await shot("17_tiro_a_caminho", 1.5)
	_hide_modals()
	await shot("18_tiro_no_banco", 4.0)
	quit(0)
