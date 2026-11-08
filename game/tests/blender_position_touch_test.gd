extends SceneTree
## Casa real: apoio no tampo, separação do fogão, toque no corpo e no balão.
var failures := 0
var state: Node
var main: Control

func _initialize() -> void:
	_run.call_deferred()

func frames(n: int = 6) -> void:
	for i in n: await process_frame

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("BLENDER POSITION: " + message)

func tap(point: Vector2) -> void:
	for down: bool in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = root.get_final_transform() * point
		event.pressed = down
		Input.parse_input_event(event)
		await frames(2)
	await frames()

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen.intro = true
	state.get("progress").owned["stove"] = true
	state.get("progress").owned["blender"] = true
	state.get("progress").owned["fridge"] = true
	state.get("progress").claimed_quests["lais_blender"] = true
	state.call("_mark_all_seen")
	Input.emulate_mouse_from_touch = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	main.call("_on_world_requested", "house", "")
	main.call("show_screen", &"map")
	await frames()
	var room := main.find_child("World_house", true, false) as Control
	var blender := room.find_child("blender", true, false) as Sprite2D
	var stove := room.find_child("stove", true, false) as Sprite2D
	var before := "--before" in OS.get_cmdline_user_args()
	for resolution: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = resolution
		room.call("close_tray")
		state.get("stations")["blender"].queue.clear()
		state.get("inventory").add("carrot", 10)
		check(state.call("cook", "frozen_carrot") == "", "prepara cenoura para captura")
		room.call("recenter")
		await frames(10)
		room.call("_animate_objects")
		if "--shots" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			var folder := ProjectSettings.globalize_path("res://../build/screenshots/liquidificador/")
			DirAccess.make_dir_recursive_absolute(folder)
			var image := root.get_texture().get_image()
			var prefix := "antes" if before else "depois"
			image.save_png(folder + prefix + "_%dx%d.png" % [resolution.x, resolution.y])
			if resolution.x == 390: image.save_png(folder + prefix + ".png")
		if before: continue
		state.get("stations")["blender"].queue.clear()
		room.call("_animate_objects")
		# Tampo em coordenadas da sala (polígono da superfície, não o pé no chão).
		var surface := PackedVector2Array([Vector2(384, 277), Vector2(421, 256), Vector2(534, 304), Vector2(495, 326)])
		for base: Vector2 in [blender.position + Vector2(-5, -3), blender.position + Vector2(5, -3), blender.position]:
			check(Geometry2D.is_point_in_polygon(base, surface), "base apoiada no tampo")
		var bounds := Rect2(blender.position + blender.offset, blender.texture.get_size())
		var stove_bounds := Rect2(stove.position + stove.offset, stove.texture.get_size())
		check(not bounds.intersects(stove_bounds), "sprite não sobrepõe fogão")
		check(blender.z_index == 1, "continua acima da bancada")
		var local_point := blender.position + Vector2(0, -8)
		check(room.call("_target_at", local_point).get("sprite") == blender, "corpo tem alvo correto")
		await tap(blender.get_global_transform_with_canvas() * Vector2(0, -8))
		var tray: Variant = load("res://scripts/ui/action_tray.gd").get("current")
		check(is_instance_valid(tray) and not bool(tray.get("closing")), "toque abre bandeja %s" % resolution)
		check(is_instance_valid(tray) and tray.get("options").get("title") == "Liquidificador", "bandeja pertence ao liquidificador")
		room.call("close_tray")
		await frames()
		# Trabalho real: cenoura, progresso e coleta pelo balão deslocam junto com o objeto.
		state.get("inventory").add("carrot", 10)
		check(state.call("cook", "frozen_carrot") == "", "inicia geladinho de cenoura")
		room.call("_animate_objects")
		await frames()
		var marker: Variant = blender.get_node("ProductionIndicator")
		check(marker.visible and marker.state == "progress" and marker.texture != null, "balão com produto e progresso")
		var marker_point: Vector2 = marker.get_global_transform_with_canvas() * marker.hit_rect.get_center()
		await tap(marker_point)
		tray = load("res://scripts/ui/action_tray.gd").get("current")
		check(is_instance_valid(tray) and not bool(tray.get("closing")), "balão abre produção")
		room.call("close_tray")
		await frames()
		var queue: Array = state.get("stations")["blender"].queue
		queue[0].ready_at = state.call("now") - 1
		room.call("_animate_objects")
		await frames()
		check(marker.state == "ready", "balão pronto")
		var count: int = state.get("inventory").count("frozen_carrot")
		await tap(marker.get_global_transform_with_canvas() * marker.hit_rect.get_center())
		check(state.get("inventory").count("frozen_carrot") == count + 1, "toque recolhe produto")
		print("LIQUIDIFICADOR %s: verificado" % resolution)
	print("BLENDER POSITION TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
