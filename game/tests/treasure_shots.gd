extends SceneTree
## Capturas da Etapa 11 (rode SEM --headless, com --resolution 360x780). Não entra no test_all.
var state: Node
var main: Node
var events: Node

func _initialize() -> void:
	_run.call_deferred()

func shot(name: String) -> void:
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/etapa11/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + name + ".png")

func _clear() -> void:
	main.get_node("Celebration").hide()
	events.emit_signal("sheet_close_requested")

func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	events = root.get_node("Events")
	state.call("reset")
	var db: Node = root.get_node("Database")
	for id: String in db.get("quests"):
		if id != "guide_treasure" and db.get("quests")[id].get("kind", "") != "":
			state.get("progress").claimed_quests[id] = true
	state.get("progress").seen["intro"] = true
	state.set("coins", 200)
	for n in range(1, 4):
		state.get("progress").count("find_item:map_piece_%d" % n, 1)
		state.get("inventory").add("map_piece_%d" % n, 1)
	state.call("_changed")
	var unseen: Array[String] = state.call("new_unlocks")
	state.call("mark_seen", unseen)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.6).timeout
	_clear()
	main.call("show_screen", &"map")
	main.call("_on_world_requested", "nature", "")
	await create_timer(3.0).timeout
	await shot("natureza_antes")
	var places: Script = load("res://scripts/ui/places.gd")
	places.call("open_npc", "guide")
	await shot("guia_tres_pedacos")
	_clear()
	var progression_ui: Script = load("res://scripts/ui/progression_ui.gd")
	progression_ui.set("_collection_tab", "finds")
	events.emit_signal("sheet_requested", "Coleção", progression_ui.call("collection_panel"))
	await shot("colecao_tres_de_quatro")
	_clear()
	state.get("progress").count("find_item:map_piece_4", 1)
	state.get("inventory").add("map_piece_4", 1)
	state.call("_changed")
	events.emit_signal("sheet_requested", "Coleção", progression_ui.call("collection_panel"))
	await shot("colecao_quatro_de_quatro")
	_clear()
	places.call("open_npc", "guide")
	await shot("guia_pronta")
	print("receber: ", state.call("claim_quest", "guide_treasure"))
	_clear()
	events.emit_signal("world_requested", "nature", "treasure")
	await create_timer(2.0).timeout
	var nature: Control = main.get_node("%WorldsScreen").get("_views")["nature"]
	nature.call("point_at", "treasure")
	await shot("bau_fechado_seta")
	var chest: Sprite2D
	for node in nature.find_children("treasure_chest", "Sprite2D", true, false):
		chest = node
	nature.call("_open_treasure", chest)
	await shot("festa_tesouro")
	main.get_node("Celebration").hide()
	await shot("bau_aberto")
	nature.call("_open_treasure", chest)
	await shot("bau_ja_aberto")
	print("repetido: ", state.call("open_treasure"))
	events.emit_signal("sheet_requested", "Canteiro", load("res://scripts/ui/sheet_builder.gd").call("seed_picker", 0))
	await shot("sementes_mirtilo")
	_clear()
	main.call("show_screen", &"bag")
	await shot("mochila")
	print("TREASURE SHOTS DONE")
	quit(0)
