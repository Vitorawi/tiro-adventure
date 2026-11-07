extends SceneTree
## Real home, isolated save. --verify checks playback; --shots saves each clip.
var animator: Node
var main: Control

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var state := root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen.intro = true
	root.get_node("SaveManager").call("set_puppy_illustrated", true)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	for i: int in 5: await process_frame
	var pet: Control = main.find_child("PetScreen", true, false)
	pet.set("preview_hour", 12)
	animator = pet.get("_animator")
	if "--verify" in OS.get_cmdline_user_args() or "--shots" in OS.get_cmdline_user_args():
		animator.set_process(false)
		var target: TextureRect = pet.get("_dog_sprite")
		for clip: StringName in [&"idle_breathe", &"head_tilt", &"close_eyes"]:
			animator.call("_play", clip, 1)
			var list: Array = animator.call("_clip_frames")
			assert(list.size() == 36 and list[0] is AtlasTexture)
			assert(target.material == null)
			animator.set("_fidget_in", 999.0)
			for i: int in 36:
				assert(animator.get("_frame") == i, "Original frame timing")
				animator.call("_process", float(animator.call("_frame_seconds")) + 0.0000001)
			assert(animator.get("_clip") == &"idle_breathe", "Return to idle")
			animator.call("_play", clip, 1)
			animator.set("_frame", 18)
			animator.call("_show")
			await _shot(str(clip))
		animator.call("_play", &"idle_breathe", 1)
		animator.set("_frame", 4)
		animator.set("_fidget_in", -1.0)
		animator.call("_process", 0.001)
		assert(animator.get("_clip") == &"idle_breathe", "Wait for idle boundary")
		animator.set("_frame", 0)
		animator.call("_process", 0.001)
		assert(animator.get("_clip") in [&"head_tilt", &"close_eyes"])
		root.get_node("SaveManager").call("set_puppy_illustrated", false)
		animator.call("_show")
		assert(target.material is ShaderMaterial, "Preference restores pixel")
		root.get_node("SaveManager").call("set_puppy_illustrated", true)
		state.call("dev_set_phase", "teething")
		animator.call("_play", &"idle_breathe", 1)
		assert(not bool(animator.call("_uses_animaref")), "Other bodies unchanged")
		print("ANIMAREF HOME: PASS (108 frames, timing, idle boundary, return, preference, growth)")
		quit()
		return

func _shot(id: String) -> void:
	if "--shots" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/animaref_home/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + id + ".png")
