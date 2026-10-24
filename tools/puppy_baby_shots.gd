extends SceneTree
## Revisão local dos novos PNGs; nunca grava o save pessoal.
var state: Node
var main: Node

func _initialize() -> void:
	_run.call_deferred()
	create_timer(90).timeout.connect(func() -> void: quit(1))

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.reset()
	state.progress.seen["intro"] = true
	state.growth.phase = "puppy"
	state._mark_all_seen()
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.8).timeout
	main.set("_announce_pending", false)
	main.set("_modal_queue", [] as Array[Callable])
	main.set("_photo_queue", [] as Array[String])
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer: node.hide()
	root.get_node("Events").sheet_close_requested.emit()
	var pet: Node = main.find_child("PetScreen", true, false)
	pet.set("preview_hour", 12)
	var animator: Node = pet.get("_animator")
	for viewport: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = viewport
		main.call("show_screen", &"pet")
		animator.call("_play", &"idle_breathe", 1)
		animator.set_process(false)
		await create_timer(0.3).timeout
		await _shot("home_%dx%d" % [viewport.x, viewport.y])
	root.size = Vector2i(360, 780)
	for clip: StringName in [&"eat", &"sleep", &"roll_over", &"belly_rub", &"belly_kick"]:
		animator.call("_play", clip, 1)
		animator.set("_frame", 0 if clip == &"eat" else animator.get("_frames")[clip].size() - 1)
		animator.call("_show")
		await process_frame
		await _shot(str(clip))
	print("PUPPY BABY SHOTS: PASS")
	quit()

func _shot(id: String) -> void:
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/puppy_baby_20261024/")
	DirAccess.make_dir_recursive_absolute(folder)
	var err := root.get_texture().get_image().save_png(folder.path_join(id + ".png"))
	if err != OK:
		push_error("Falha na captura " + id)
		quit(1)
