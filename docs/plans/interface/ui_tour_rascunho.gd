extends SceneTree
## Tour de capturas para revisão da interface (fora do repositório).

var state: Node
var main: Node
var folder := "res://../build/screenshots/ui_audit/"


func _initialize() -> void:
	_run.call_deferred()


func shot(shot_name: String) -> void:
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path + shot_name + ".png")


func _sheet(title: String, content: Control) -> void:
	root.get_node("Events").emit_signal("sheet_requested", title, content)
	await create_timer(0.5).timeout


func _close() -> void:
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.3).timeout


func _hide_modals() -> void:
	for n in ["Celebration", "WelcomeBack", "WalkResult"]:
		var node := main.get_node_or_null(n)
		if node:
			node.hide()


func _world(id: String) -> void:
	main.call("_on_world_requested", id, "")
	await create_timer(2.0).timeout


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	var places: Script = load("res://scripts/ui/places.gd")
	var sb: Script = load("res://scripts/ui/sheet_builder.gd")
	var pu: Script = load("res://scripts/ui/progression_ui.gd")
	# --- Começo de jogo ---
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("_changed")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.0).timeout
	_hide_modals()
	await shot("a01_pet")
	main.call("show_screen", &"tasks")
	await shot("a02_tasks")
	main.call("show_screen", &"map")
	await shot("a03_map")
	await _world("house")
	await shot("a04_house")
	places.call("open", "house", "fridge")
	await shot("a05_fridge")
	await _close()
	# --- Meio/fim de jogo ---
	main.queue_free()
	await create_timer(0.5).timeout
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.call("plant", 0, "carrot")
	state.call("plant", 1, "potato")
	state.call("plant", 2, "pumpkin")
	state.call("_changed")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	await shot("b01_pet")
	main.call("show_screen", &"wishes")
	await shot("b02_wishes")
	main.call("show_screen", &"tasks")
	await shot("b03_tasks")
	main.call("show_screen", &"bag")
	await shot("b04_bag")
	main.call("show_screen", &"map")
	await shot("b05_map_list")
	for w in ["house", "farm", "park", "village", "nature"]:
		await _world(w)
		_hide_modals()
		await shot("b06_world_" + w)
	await _world("farm")
	var farm: Node = main.find_child("World_farm", true, false)
	farm.call("_on_object_tapped", "plot", farm.find_child("plot_3", true, false))
	await shot("b07_seed_picker")
	await _close()
	farm.call("_on_object_tapped", "plot", farm.find_child("plot_0", true, false))
	await shot("b08_growing_plot")
	await _close()
	places.call("open", "farm", "plots")
	await shot("b09_farm_view")
	await _close()
	places.call("open", "farm", "workbench")
	await shot("b10_workbench")
	await _close()
	places.call("open", "farm", "chicken_coop")
	await shot("b11_coop")
	await _close()
	await _world("house")
	places.call("open", "house", "stove")
	await shot("b12_stove")
	await _close()
	places.call("open", "house", "bowl")
	await shot("b13_bowl")
	await _close()
	await _world("village")
	places.call("open", "village", "market")
	await shot("b14_market")
	await _close()
	await _world("nature")
	places.call("open", "nature", "trees")
	await shot("b15_nature_trees")
	await _close()
	await _world("park")
	places.call("open", "park", "walk")
	await shot("b16_walks")
	await _close()
	places.call("open_npc", "lais")
	await shot("b17_npc_lais")
	await _close()
	await _sheet("Mochila", sb.call("item_detail", "carrot"))
	await shot("b18_item_detail")
	await _sheet("Atributos", pu.call("skills_panel"))
	await shot("b19_skills")
	await _sheet("Coleção", pu.call("collection_panel"))
	await shot("b20_collection")
	await _sheet("História", pu.call("story_panel"))
	await shot("b21_story")
	places.call("open", "farm", "orchard")
	await shot("b22_orchard")
	await _close()
	places.call("open", "farm", "home")
	await shot("b23_farm_home")
	await _close()
	quit(0)
