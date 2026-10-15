extends SceneTree
## Capturas rápidas do seletor, sem autosave; o tour completo continua sendo a régua final.
var main: Control
var worlds: Control


func _initialize() -> void:
	_run.call_deferred()


func _shot(id: String) -> void:
	await create_timer(0.3).timeout
	_hide_modals()
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../build/screenshots/etapa05_rapidas/")
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path + id + ".png")


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	(main.get("_toast") as Control).hide()


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var state: Node = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(0.3).timeout
	worlds = main.find_child("WorldsScreen", true, false)
	main.call("show_screen", &"map")
	worlds.call("show_map")
	await _shot("01_house")
	worlds.get_node("%MapView").call("center_on", "farm", false)
	await _shot("02_farm_locked")
	worlds.get_node("%MapView").call("center_on", "nature", false)
	await _shot("03_nature_locked")
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	for id: String in ["house", "farm", "park", "village", "nature"]:
		worlds.call("enter", id, "")
		worlds.call("show_map")
		await _shot("04_" + id)
	worlds.call("close_map")
	Motion.reduced = false
	worlds.call("enter", "farm", "")
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../build/screenshots/etapa05_rapidas/05_transition.png"))
	await create_timer(0.6).timeout
	quit(0)
