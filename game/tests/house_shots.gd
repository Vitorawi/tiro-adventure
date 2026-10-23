extends SceneTree
## Capturas da etapa 14, sem save pessoal. Rodar em 360x780, sem --headless.
var state: Node
var main: Node
const OUT := "res://../build/screenshots/tiro14/"

func _initialize() -> void:
	_run.call_deferred()
	create_timer(90).timeout.connect(func() -> void: quit(1))

func shot(id: String) -> void:
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + id + ".png")

func quiet() -> void:
	main.set("_chapter_done", 0)
	main.set("_announce_pending", false)
	main.set("_modal_queue", [] as Array[Callable])
	main.set("_photo_queue", [] as Array[String])
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer: node.hide()
	state._mark_all_seen()
	root.get_node("Events").sheet_close_requested.emit()

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer: child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "house_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.reset()
	state.progress.seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.0).timeout
	root.get_node("Events").quest_completed.disconnect(Callable(main, "_on_quest_completed"))
	root.get_node("Events").chapter_completed.disconnect(Callable(main, "_on_chapter_completed"))
	quiet()
	main.call("_on_world_requested", "house", "")
	await shot("t11_house_start")
	state.dev_grant_upgrade("dog_bed")
	state.dev_grant_upgrade("stove")
	state.dev_grant_upgrade("fridge")
	state.growth.phase = "explorer"
	state.growth.delivered = {"teething": {"chew_ring": 1}, "explorer": {"stick_chew": 1}}
	for id: String in ["puppy", "teething", "explorer"]:
		state.growth.ceremonies[id] = {"at": state.now(), "seen": true}
	for i in 8: state.dev_take_photo(str(root.get_node("Database").album.photos[i].id))
	state.hang_photo("h_arrival")
	state.hang_photo("h_growth_teething")
	state.hang_photo("h_growth_explorer")
	state._changed()
	quiet()
	await shot("t11_house_middle")
	state.dev_unlock_everything()
	state.growth.phase = "adult"
	state.growth.delivered = {"teething": {"chew_ring": 1}, "explorer": {"stick_chew": 1}, "young": {"soft_brush": 1}, "adult": {"courage_medal": 1}}
	for id: String in ["young", "adult"]:
		state.growth.ceremonies[id] = {"at": state.now(), "seen": true}
	for i in 45: state.dev_take_photo(str(root.get_node("Database").album.photos[i].id))
	state.set_main_photo("h_growth_adult")
	state._changed()
	quiet()
	await shot("t11_house_end")
	var ui: Variant = load("res://scripts/ui/house_ui.gd")
	ui.open("memory_shelf")
	await shot("t11_house_shelf")
	ui.open("photo_wall")
	await shot("t11_house_photos")
	root.get_node("Events").sheet_close_requested.emit()
	main.call("show_screen", &"pet")
	await shot("t11_corner_decor")
	main.call("_on_world_requested", "house", "")
	root.get_node("Events").sheet_requested.emit("Caminha", ui.bed())
	await shot("t11_house_bed")
	quit()
