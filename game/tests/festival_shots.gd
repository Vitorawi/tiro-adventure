extends SceneTree
## Capturas da etapa 22 da economia (Festa da Vila, Lenço da nossa turma, Encontro da turma). NÃO é teste.
## Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/festival_shots.gd -- --out=etapa22_depois/360x780
## `--antes` tira em memória a Festa e o Lenço (Vila só com o jardim, sem lugar da festa).
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var events: Node
var folder := "res://../build/screenshots/etapa22/"
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


func _full(id: String) -> void:
	state.set("coins", int(state.get("coins")) + int(root.get_node("Database").project(id).start_coins))
	state.call("start_project", id)
	for index in root.get_node("Database").project(id).phases.size():
		_phase(id, index)


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
	saver.set("_save_path", "user://festival_shots_descartavel.json")
	state = root.get_node("GameState")
	events = root.get_node("Events")
	var database: Node = root.get_node("Database")
	if before:
		database.get("projects").projects.erase("village_festival")
		database.get("worlds").village.places.erase("festival")
		database.get("collections").erase("community_ribbon")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	for id in ["welcome", "lais_bed", "bloblo_meet", "first_harvest", "main_2_order", "nina_pipoca"]:
		state.get("progress").claimed_quests[id] = true
	for id in ["stove", "workbench", "fridge", "atelier", "chest", "silo", "warehouse", "petshop", "sewing_table", "stall", "stall_2"]:
		state.call("dev_grant_upgrade", id)
	state.call("dev_complete_quest", "atelier_open")
	state.call("dev_jump_to_chapter", 6)
	state.call("_mark_all_seen")
	for id: String in ["park_bench", "village_garden", "park_picnic"]:
		_full(id)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.6).timeout
	_hide_modals()
	main.call("show_screen", &"map")
	var village := await _world("village")
	await shot("01_vila_sem_festa", 1.0)
	var places_button: Button = main.find_child("PlacesButton", true, false)
	if places_button:
		places_button.pressed.emit()
		await shot("02_vila_lugares")
		events.emit_signal("sheet_close_requested")
	if before:
		events.emit_signal("sheet_requested", "Nossa vila", load("res://scripts/ui/project_ui.gd").call("community", "village"))
		await shot("03_nossa_vila_lista")
		quit(0)
		return
	state.call("dev_grant_upgrade", "stall_3")
	await create_timer(0.5).timeout
	await shot("03_vila_festa_marcacao", 1.0)
	events.emit_signal("sheet_requested", "Nossa vila", load("res://scripts/ui/project_ui.gd").call("community", "village"))
	await shot("04_nossa_vila_lista")
	_panel("village_festival")
	await shot("05_festa_antes_de_comecar")
	state.set("coins", 500)
	state.call("start_project", "village_festival")
	await shot("06_festa_sem_material", 1.0)
	_give({"fabric": 2})
	await shot("07_festa_entrega_parcial", 1.0)
	events.emit_signal("sheet_close_requested")
	await shot("08_vila_festa_marcacao_aberta", 0.8)
	_phase("village_festival", 0)
	await shot("09_vila_festa_enfeites", 0.8)
	_phase("village_festival", 1)
	await shot("10_vila_festa_mesa", 0.8)
	_panel("village_festival")
	_give({"treat_box": 3, "braided_toy": 2})
	await shot("11_festa_ultima_fase", 1.3)
	events.emit_signal("sheet_close_requested")
	state.call("contribute_project", "village_festival", "treat_box", 3)
	state.call("contribute_project", "village_festival", "braided_toy", 2)
	await create_timer(0.8).timeout
	await shot("12_festa_pronta_cartao", 1.0)
	_hide_modals()
	await shot("13_vila_festa_pronta", 0.8)
	var festa: Sprite2D = village.find_child("community_festival", true, false)
	village.call("zoom_to", village.call("world_to_screen", festa.position), 1.8, 0.0)
	await shot("14_zoom_festa", 0.8)
	village.call("_on_tap_released", village.call("world_to_screen", festa.position - Vector2(0, 14)))
	_hide_modals()
	await shot("15_tiro_na_festa", 4.0)
	_panel("village_festival")
	await shot("16_festa_pronta_encontro_espera", 1.0)
	events.emit_signal("sheet_close_requested")
	state.call("dev_advance_time", 25.0 * 3600.0)
	_give({"picnic_pack": 1, "carrot_snack": 2})
	_panel("village_festival")
	await shot("17_encontro_pronto", 1.0)
	var gather: Button = main.find_child("GatherProject", true, false)
	if gather:
		gather.pressed.emit()
	events.emit_signal("sheet_close_requested")
	await shot("18_tiro_no_encontro", 4.0)
	_panel("village_festival")
	await shot("19_encontro_espera_nova", 1.0)
	events.emit_signal("sheet_close_requested")
	# Lenço da turma no Tiro, em pé e dormindo.
	state.call("equip", "community_ribbon")
	main.call("show_screen", &"pet")
	await shot("20_tiro_com_lenco", 1.5)
	state.call("set_sleeping", true)
	await shot("21_tiro_dormindo_com_lenco", 1.5)
	state.call("set_sleeping", false)
	# Caderninho: Coleção com o lenço.
	var notebook: Button = main.find_child("ManualButton", true, false)
	if notebook:
		notebook.pressed.emit()
		await shot("22_caderninho", 1.0)
	quit(0)
