extends SceneTree
## Capturas da etapa 21 da economia (Jardim da Vila e Piquenique da Praça). NÃO é teste.
## Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/garden_picnic_shots.gd -- --out=etapa21_depois/360x780
## `--antes` tira em memória as duas obras novas (Praça só com o banco, Vila sem "Nossa vila").
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var events: Node
var folder := "res://../build/screenshots/etapa21/"
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


func _panel(id: String) -> void:
	events.emit_signal("sheet_requested", str(root.get_node("Database").project(id).name), load("res://scripts/ui/project_ui.gd").call("panel", id))


func _phase(id: String, index: int) -> void:
	var phase: Dictionary = root.get_node("Database").project(id).phases[index]
	_give(phase.items)
	for item: String in phase.items:
		state.call("contribute_project", id, item, int(phase.items[item]))


func _world(id: String) -> Node:
	main.call("_on_world_requested", id, "")
	await create_timer(3.0).timeout
	_hide_modals()
	return main.find_child("World_" + id, true, false)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", "user://garden_picnic_shots_descartavel.json")
	state = root.get_node("GameState")
	events = root.get_node("Events")
	var database: Node = root.get_node("Database")
	if before:
		for id: String in ["village_garden", "park_picnic"]:
			database.get("projects").projects.erase(id)
		database.get("worlds").village.places.erase("community")
		database.get("worlds").village.places.erase("garden")
		database.get("worlds").park.places.erase("picnic")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	for id in ["welcome", "lais_bed", "bloblo_meet", "first_harvest", "main_2_order", "nina_pipoca"]:
		state.get("progress").claimed_quests[id] = true
	for id in ["stove", "workbench", "fridge", "atelier", "chest", "silo", "warehouse", "petshop", "sewing_table"]:
		state.call("dev_grant_upgrade", id)
	state.call("dev_complete_quest", "atelier_open")
	state.call("dev_jump_to_chapter", 6)
	state.call("_mark_all_seen")
	state.set("coins", 1200)
	state.call("start_project", "park_bench")
	for index in 3:
		_phase("park_bench", index)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.6).timeout
	_hide_modals()
	main.call("show_screen", &"map")
	var park := await _world("park")
	await shot("01_praca_inicio", 1.0)
	var places_button: Button = main.find_child("PlacesButton", true, false)
	if places_button:
		places_button.pressed.emit()
		await shot("02_praca_lugares")
		events.emit_signal("sheet_close_requested")
	events.emit_signal("sheet_requested", "Nossa praça", load("res://scripts/ui/project_ui.gd").call("community", "park"))
	await shot("03_nossa_praca_lista")
	events.emit_signal("sheet_close_requested")
	var village := await _world("village")
	await shot("04_vila_inicio", 1.0)
	places_button = main.find_child("PlacesButton", true, false)
	if places_button:
		places_button.pressed.emit()
		await shot("05_vila_lugares")
		events.emit_signal("sheet_close_requested")
	if before:
		quit(0)
		return
	events.emit_signal("sheet_requested", "Nossa vila", load("res://scripts/ui/project_ui.gd").call("community", "village"))
	await shot("06_nossa_vila_lista")
	_panel("village_garden")
	await shot("07_jardim_antes_de_comecar")
	state.call("start_project", "village_garden")
	state.call("start_project", "park_picnic")
	await shot("08_jardim_sem_material", 1.3)
	_give({"plank": 4, "brick": 2})
	await shot("09_jardim_entrega_parcial", 1.3)
	events.emit_signal("sheet_close_requested")
	await shot("10_vila_jardim_marcacao", 0.8)
	_phase("village_garden", 0)
	await shot("11_vila_jardim_canteiros", 0.8)
	_phase("village_garden", 1)
	await shot("12_vila_jardim_plantio", 0.8)
	_panel("village_garden")
	_give({"strawberry_juice": 3})
	await shot("13_jardim_ultima_fase", 1.3)
	events.emit_signal("sheet_close_requested")
	state.call("contribute_project", "village_garden", "strawberry_juice", 3)
	await create_timer(0.8).timeout
	await shot("14_jardim_pronto_cartao", 1.0)
	_hide_modals()
	await shot("15_vila_jardim_pronto", 0.8)
	var garden: Sprite2D = village.find_child("community_garden", true, false)
	village.call("zoom_to", village.call("world_to_screen", garden.position), 1.8, 0.0)
	await shot("16_zoom_jardim", 0.8)
	village.call("_on_tap_released", village.call("world_to_screen", garden.position - Vector2(0, 14)))
	_hide_modals()
	await shot("17_tiro_no_jardim", 4.0)
	park = await _world("park")
	await shot("18_praca_piquenique_marcacao", 1.0)
	_phase("park_picnic", 0)
	await shot("19_praca_cantinho", 0.8)
	_phase("park_picnic", 1)
	await shot("20_praca_cesta", 0.8)
	_panel("park_picnic")
	_give({"carrot_snack": 4, "strawberry_pop": 4})
	await shot("21_piquenique_ultima_fase", 1.3)
	events.emit_signal("sheet_close_requested")
	state.call("contribute_project", "park_picnic", "carrot_snack", 4)
	state.call("contribute_project", "park_picnic", "strawberry_pop", 4)
	await create_timer(0.8).timeout
	await shot("22_piquenique_pronto_cartao", 1.0)
	_hide_modals()
	await shot("23_praca_piquenique_pronto", 0.8)
	var picnic: Sprite2D = park.find_child("community_picnic", true, false)
	park.call("zoom_to", park.call("world_to_screen", picnic.position), 1.8, 0.0)
	await shot("24_zoom_piquenique", 0.8)
	park.call("_on_tap_released", park.call("world_to_screen", picnic.position - Vector2(0, 14)))
	_hide_modals()
	await shot("25_tiro_no_piquenique", 4.0)
	quit(0)
