extends SceneTree
## Capturas da Etapa 05 (rode SEM --headless, com --resolution 360x780). Não entra no test_all.
var state: Node
var main: Node

func _initialize() -> void:
	_run.call_deferred()

func shot(name: String) -> void:
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/etapa05/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + name + ".png")

func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	for id in ["bloblo_meet", "first_harvest"]:
		state.get("progress").claimed_quests[id] = true
	state.get("progress").seen["intro"] = true
	state.call("_changed")
	state.call("dev_advance_time", 25.0)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.4).timeout
	main.get_node("Celebration").hide()
	main.call("_on_world_requested", "farm", "")
	await create_timer(3.0).timeout
	await shot("farejando_sitio")
	var farm: Control = main.get_node("%WorldsScreen").get("_views")["farm"]
	farm.call("point_at", "find")
	await shot("seta_montinho")
	var reward: Dictionary = state.call("dig", "farm")
	print("achado: ", reward)
	await shot("apos_cavar")
	for id in ["old_horseshoe", "hen_feather", "grandma_button", "pinecone", "map_piece_1", "map_piece_3"]:
		state.get("progress").count("find_item:" + id, 1)
	state.get("progress").claimed_quests["bloblo_dig"] = true
	state.call("_changed")
	var items: Dictionary = {"old_horseshoe": 1, "hen_feather": 2, "map_piece_1": 1}
	for id: String in items:
		state.get("inventory").add(id, items[id])
	root.get_node("Events").emit_signal("state_changed")
	var progression_ui: Script = load("res://scripts/ui/progression_ui.gd")
	progression_ui.set("_collection_tab", "finds")
	root.get_node("Events").emit_signal("sheet_requested", "Coleção", progression_ui.call("collection_panel"))
	await shot("colecao_achados")
	root.get_node("Events").emit_signal("sheet_close_requested")
	main.call("show_screen", &"bag")
	await shot("mochila")
	quit(0)
