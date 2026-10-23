extends SceneTree
## Conferência visual da interface mínima de momentos, sem SaveManager nem save pessoal.
var main: Control
var state: Node

func _initialize() -> void:
	_run.call_deferred()

func frames() -> void:
	for i in 8: await process_frame

func shot(id: String) -> void:
	await frames()
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony"]:
		main.get(member).hide()
	(main.get("_toast") as Control).hide()
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/cuidado01")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join(id + "_360.png"))

func _run() -> void:
	root.size = Vector2i(360, 780)
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.reset()
	state.progress.seen.intro = true
	state.growth.phase = "teething"
	state.growth.moments = {"brave": 6, "smart": 2, "coat": 1}
	state.growth.phase_moments = {"brave": 2, "smart": 1, "coat": 0}
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	load("res://scripts/ui/growth_ui.gd").open()
	await shot("growth")
	root.get_node("Events").sheet_close_requested.emit()
	await frames()
	root.get_node("Events").sheet_requested.emit("Momentos do Tiro", load("res://scripts/ui/pillar_ui.gd").panel())
	await shot("notebook")
	root.get_node("Events").sheet_close_requested.emit()
	await frames()
	state.dev_set_need("happiness", 40.0)
	state.pet()
	await shot("care")
	print("MOMENTS SHOTS: PASS")
	main.queue_free()
	await frames()
	quit()
