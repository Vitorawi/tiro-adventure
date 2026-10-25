extends SceneTree
## Miniaturas estáticas sem HUD/balões; save novo e compras básicas. Rodar com janela 720×480.

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.content_scale_size = Vector2i(720, 480)
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var state: Node = root.get_node("GameState")
	var folder := ProjectSettings.globalize_path("res://assets/sprites/ui/worlds")
	DirAccess.make_dir_recursive_absolute(folder)
	for id: String in root.get_node("Database").get("worlds"):
		state.call("reset")
		for upgrade: String in {"house": ["fridge", "stove"], "farm": ["farm", "workbench"], "village": [], "park": [], "nature": ["forest_open"]}[id]:
			state.call("dev_grant_upgrade", upgrade)
		var room: Control = load("res://scenes/levels/room/room.tscn").instantiate()
		room.set("room_id", id)
		room.set("world_id", id)
		root.add_child(room)
		for i: int in 4: await process_frame
		room.set_process(false)
		for tag: Label in room.get("_labels"): tag.hide()
		var dog: Node2D = room.get("_dog")
		if is_instance_valid(dog):
			dog.set_process(false)
			if dog.has_node("WishBalloon"): dog.get_node("WishBalloon").hide()
		for balloon: Node2D in get_nodes_in_group("world_balloons"): balloon.hide()
		for region: Node2D in room.get("_regions"): region.hide()
		room.get_node("RecenterButton").hide()
		await RenderingServer.frame_post_draw
		var screen := root.get_texture().get_image()
		var image := screen.get_region(Rect2i((screen.get_width() - 600) / 2, (screen.get_height() - 400) / 2, 600, 400))
		image.resize(300, 200, Image.INTERPOLATE_NEAREST)
		image.convert(Image.FORMAT_RGBA8)
		for y: int in image.get_height():
			for x: int in image.get_width():
				var corner := Vector2(clampf(x, 30, 269), clampf(y, 30, 169))
				if Vector2(x,y).distance_to(corner) > 30: image.set_pixel(x,y,Color.TRANSPARENT)
		image.save_png(folder.path_join(id + ".png"))
		for y: int in image.get_height():
			for x: int in image.get_width():
				var color := image.get_pixel(x,y)
				var gray := color.r * 0.299 + color.g * 0.587 + color.b * 0.114
				image.set_pixel(x,y,Color(gray,gray,gray,color.a))
		image.save_png(folder.path_join(id + "_locked.png"))
		room.queue_free()
		await process_frame
	quit(0)
