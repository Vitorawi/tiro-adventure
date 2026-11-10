extends SceneTree
## Captura da bandeja da estufa (4 espaços). NÃO é teste.
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/greenhouse_shots.gd -- --out=greenhouse
## PNGs em build/screenshots/<out>/estufa_<estado>.png

var state: Node
var main: Node
var folder := "res://../build/screenshots/greenhouse/"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(500).timeout.connect(func() -> void: quit(1))


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


func _room() -> Control:
	for view: Node in get_nodes_in_group("room_views"):
		if view.get("room_id") == "farm":
			return view as Control
	return null


func _shot(shot_name: String) -> void:
	await create_timer(0.8).timeout
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	root.get_viewport().get_texture().get_image().save_png(path + "estufa_%s.png" % shot_name)
	print("shot ", shot_name)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "greenhouse_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	state.call("dev_unlock_everything")
	state.set("unlocked_plots", 9)
	main.call("_on_world_requested", "farm", "")
	main.call("show_screen", &"map")
	await create_timer(1.2).timeout
	_hide_modals()
	var room := _room()
	await _shot("a_mapa")
	room.call("open_greenhouse_tray")
	await _shot("b_vazia")
	var plot := 9
	state.call("plant", plot, "blueberry")
	state.call("plant", plot + 1, "strawberry")
	await _shot("c_crescendo")
	state.get("plots")[plot + 1]["ready_at"] = 0.0
	state.call("_changed")
	await _shot("d_pronta")
	quit(0)
