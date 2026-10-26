extends SceneTree
## Diagnóstico reproduzível; não grava save. Executar sem --headless para PNGs.
var folder := "res://../build/screenshots/tiro_samba/"
var prefix := "antes"
var main: Node
var pet: Control
var layout_calls := 0
var image_cache := {}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--prefix="): prefix = arg.trim_prefix("--prefix=")
	_run.call_deferred()

func metrics(texture: Texture2D) -> Dictionary:
	var path := texture.resource_path
	if image_cache.has(path): return image_cache[path]
	var image := texture.get_image()
	var box := image.get_used_rect()
	# Centro do contato inferior: última linha opaca, sem confundir cauda/cabeça com patas.
	var left := image.get_width()
	var right := -1
	for x in image.get_width():
		if image.get_pixel(x, box.end.y - 1).a > 0.5:
			left = mini(left, x)
			right = maxi(right, x)
	var result := {"box": box, "feet": Vector2((left + right + 1) * 0.5, box.end.y), "canvas": image.get_size()}
	image_cache[path] = result
	return result

func shot(id: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder + prefix + "_" + id + ".png"))

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var state := root.get_node("GameState")
	state.reset()
	state.progress.seen.intro = true
	state._mark_all_seen()
	state.dev_set_phase("puppy")
	Motion.reduced = false
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	for i in 12: await process_frame
	pet = main.find_child("PetScreen", true, false)
	pet.preview_hour = 12
	var animator: Node = pet.get("_animator")
	var target: TextureRect = pet.get_node("%DogSprite")
	var corner: Control = pet.get_node("%Corner")
	for node: Control in [pet, corner, pet.get_node("%DogArea")]:
		node.resized.connect(func() -> void: layout_calls += 1)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var assets := FileAccess.open(folder + prefix + "_assets.csv", FileAccess.WRITE)
	assets.store_csv_line(["clip", "frame", "width", "height", "bbox_x", "bbox_y", "bbox_w", "bbox_h", "feet_x", "feet_y"])
	var log := FileAccess.open(folder + prefix + "_runtime.csv", FileAccess.WRITE)
	log.store_csv_line(["clip", "sample", "frame", "pos_x", "pos_y", "size_x", "size_y", "scale_x", "scale_y", "rotation", "pivot_x", "pivot_y", "draw_x", "draw_y", "factor", "feet_global_x", "feet_global_y", "bbox_global_x", "bbox_global_y", "bbox_global_w", "bbox_global_h", "resize_events"])
	for clip: StringName in animator.FPS:
		var frames: Array = animator.get("_frames")[clip]
		for i in frames.size():
			var m := metrics(frames[i])
			var b: Rect2i = m.box
			assets.store_csv_line([clip, i, m.canvas.x, m.canvas.y, b.position.x, b.position.y, b.size.x, b.size.y, m.feet.x, m.feet.y])
		animator.call("_play", clip, 100)
		animator.set("_fidget_in", 999.0)
		var start := Time.get_ticks_msec()
		var sample := 0
		while Time.get_ticks_msec() - start < 2300:
			await process_frame
			var m := metrics(target.texture)
			var factor := minf(target.size.x / m.canvas.x, target.size.y / m.canvas.y)
			var draw_at: Vector2 = target.global_position + (target.size - Vector2(m.canvas) * factor) * 0.5
			var feet: Vector2 = draw_at + m.feet * factor
			var b := Rect2(draw_at + Vector2(m.box.position) * factor, Vector2(m.box.size) * factor)
			log.store_csv_line([clip, sample, animator.get("_frame"), target.position.x, target.position.y, target.size.x, target.size.y, target.scale.x, target.scale.y, target.rotation, target.pivot_offset.x, target.pivot_offset.y, draw_at.x, draw_at.y, factor, feet.x, feet.y, b.position.x, b.position.y, b.size.x, b.size.y, layout_calls])
			if sample == 0 or (sample == 12 and clip in [&"idle_breathe", &"head_tilt", &"shake_off"]):
				await shot("%s_%02d" % [clip, sample])
			sample += 1
	assets.close()
	log.close()
	print("SAMBA PROBE: ", prefix, "; resize events = ", layout_calls, "; textures = ", image_cache.size())
	main.queue_free()
	for i in 3: await process_frame
	quit()
