extends SceneTree
## Capturas da missão secreta da vovó (F04b). NÃO é teste.
## Rodar SEM --headless: godot --path game --resolution 360x780 -s res://tests/secret_stew_shots.gd
## PNGs em build/screenshots/secret_stew/.
var main: Node
var state: Node
const FOLDER := "res://../build/screenshots/secret_stew/"


func _initialize() -> void:
	_run.call_deferred()
	create_timer(90).timeout.connect(func() -> void: quit(1))


func _save(shot_name: String) -> void:
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(FOLDER)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "secret_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "secret_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.get("progress").seen["npc_intro:bloblo"] = true
	state.call("_count", "arrival_box")
	state.call("dev_week_goto", 1)
	state.call("dev_content_day", 11)
	state.get("growth").phase = "puppy"
	var info: Dictionary = state.call("growth_info")
	var target := str(info.next.id)
	var growth: Object = state.get("growth")
	if not growth.done.has(target):
		growth.done[target] = {}
	for row: Dictionary in info.requirements:
		if str(row.get("counter", "")) != "well_fed_day":
			growth.done[target][str(row.id)] = true
	state.call("dev_give_rod", "bamboo_rod")
	state.call("finish_fishing_tutorial")
	load("res://scripts/ui/motion.gd").set("reduced", true)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	var events: Node = root.get_node("Events")
	events.world_requested.emit("farm", "")
	await create_timer(1.5).timeout
	await _save("a_selo_segredo_no_mapa")
	load("res://scripts/ui/places.gd").call("open_npc", "bloblo")
	await create_timer(0.8).timeout
	for node: Node in main.find_children("QuestTitle_*", "", true, false):
		print("quest na conversa: ", node.name)
	await _save("b_fala_da_vovo")
	events.sheet_close_requested.emit()
	await create_timer(0.5).timeout
	events.sheet_requested.emit("Peixe dourado", load("res://scripts/ui/sheet_builder.gd").call("item_detail", "fish_golden"))
	await _save("c_peixe_dourado")
	events.sheet_requested.emit("Ensopado Dourado", load("res://scripts/ui/sheet_builder.gd").call("item_detail", "golden_stew"))
	await _save("d_ensopado_dourado")
	events.sheet_close_requested.emit()
	await create_timer(0.5).timeout
	# Patinha extra: ensopado ao vivo no almoço do dia 2.
	state.call("dev_week_goto", 2)
	state.call("dev_week_hour", 12)
	state.get("inventory").call("add", "golden_stew", 1)
	state.call("feed", "golden_stew")
	await create_timer(1.8).timeout
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	events.sheet_requested.emit("Hoje", load("res://scripts/ui/meal_ui.gd").call("today_panel"))
	await create_timer(0.6).timeout
	await _save("e_cartela_carimbo_dourado")
	print("SECRET STEW SHOTS: done")
	quit(0)
