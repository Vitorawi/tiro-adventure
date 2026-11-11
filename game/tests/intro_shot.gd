extends SceneTree
## Captura da tela de chegada (intro). NÃO é teste. Rodar sem --headless: -s res://tests/intro_shot.gd

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", str(load("res://scripts/util/build_info.gd").call("data_dir")) + "intro_shot_descartavel.json")
	root.get_node("GameState").call("reset")
	var intro: Node = load("res://scenes/ui/intro/intro.gd").new()
	root.add_child(intro)
	await create_timer(0.5).timeout
	var lines: Array = intro.get("_lines")
	while int(intro.get("_index")) < lines.size() - 1 and (lines[int(intro.get("_index"))] as Dictionary).get("show", "") != "tiro":
		intro.call("_advance")
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../build/screenshots/intro/")
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "intro_%dx%d.png" % [image.get_width(), image.get_height()])
	quit()
