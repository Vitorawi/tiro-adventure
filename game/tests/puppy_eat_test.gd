extends SceneTree
## Feeding uses real game actions and the supplied three-part animation.
var animator: Node
var target: TextureRect

func _initialize() -> void:
	_run.call_deferred()
	if "--preview" not in OS.get_cmdline_user_args():
		create_timer(40.0).timeout.connect(func() -> void: quit(1))

func _run() -> void:
	var state := root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen.intro = true
	var manager := root.get_node("SaveManager")
	manager.call("set_puppy_illustrated", true)
	var main: Control = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	for i: int in 5: await process_frame
	var pet: Control = main.find_child("PetScreen", true, false)
	pet.set("preview_hour", 12)
	animator = pet.get("_animator")
	target = pet.get("_dog_sprite")
	animator.set_process(false)
	animator.call("_play", &"idle_breathe", 1)
	var idle_size := target.texture.get_size()
	await _shot("00_idle")
	state.get("inventory").call("add", "dog_food", 1)
	var before: int = state.get("inventory").call("count", "dog_food")
	assert(bool(state.call("feed", "dog_food")))
	assert(int(state.get("inventory").call("count", "dog_food")) == before - 1)
	assert(animator.get("_clip") == &"eat_enter")
	var total := 0.0
	for clip: StringName in [&"eat_enter", &"eat_loop", &"eat_exit"]:
		assert(animator.get("_clip") == clip, "Entry → chew → exit order")
		var list: Array = animator.call("_clip_frames")
		assert(list.size() == 36 and list[0] is AtlasTexture)
		assert(target.material == null)
		if clip != &"eat_exit":
			assert(target.texture.get_size().distance_to(idle_size / (530.0 / 352.0)) < 1.5, "Shared group scale (integer texture dimensions)")
		else:
			# Compare actual on-screen normalized bounds at both exit seams.
			var chew: AtlasTexture = animator.get("_animaref_frames")[&"eat_loop"][35]
			var idle: AtlasTexture = animator.get("_animaref_frames")[&"idle_breathe"][0]
			_check_seam(chew, Rect2(4, 150, 260, 269), list[0], Rect2(15, 158, 239, 249))
			_check_seam(list[35], Rect2(12, 60, 247, 346), idle, Rect2(18, 14, 379, 530))
			# All intermediate frames keep a uniform transform, same canvas aspect,
			# and a smooth correction instead of a new size jump inside the exit.
			for j: int in range(1, list.size()):
				var previous: AtlasTexture = list[j-1]
				var current: AtlasTexture = list[j]
				assert(absf(current.get_size().aspect() - idle_size.aspect()) < 0.004)
				assert(absf(current.get_size().x / previous.get_size().x - 1.0) < 0.008)
		var layout: Array = load("res://scripts/ui/animaref_clips.gd").CLIPS[clip]
		for i: int in 36:
			assert(animator.get("_frame") == i)
			if i in [0, 18, 35]: await _shot("%s_%02d" % [clip, i])
			# Touch and other care feedback cannot interrupt the feeding sequence.
			animator.call("stroke", &"head", 0.2)
			animator.call("love")
			animator.call("react", &"play")
			assert(animator.get("_clip") == clip and animator.get("_frame") == i)
			var seconds := float(layout[i])
			total += seconds
			animator.call("_process", seconds + 0.0000001)
	assert(is_equal_approx(total, 8.388))
	assert(animator.get("_clip") == &"idle_breathe" and animator.get("_chain").is_empty())
	await _shot("99_return_idle")
	animator.call("react", &"feed")
	animator.call("set_sleeping", true)
	assert(animator.get("_chain").is_empty(), "Sleep cancels queued feeding")
	animator.call("set_sleeping", false)
	animator.call("react", &"feed")
	state.call("dev_set_phase", "teething")
	assert(animator.get("_clip") == &"idle_breathe" and animator.get("_chain").is_empty())
	state.call("dev_set_phase", "newborn")
	manager.call("set_puppy_illustrated", false)
	animator.call("react", &"feed")
	assert(animator.get("_clip") == &"eat_enter" and target.material == null, "Obsolete preference cannot restore pixel")
	manager.call("set_puppy_illustrated", true)
	animator.call("_play", &"idle_breathe", 1)
	animator.get("_animaref_frames")[&"eat_exit"] = []
	animator.call("react", &"feed")
	assert(animator.get("_clip") == &"idle_breathe" and target.material == null, "Incomplete group uses new idle")
	print("PUPPY EAT: PASS; 108 frames, real feeding, 8.388 s, chain, touch, sleep, growth and fallback")
	if "--preview" in OS.get_cmdline_user_args():
		animator.get("_animaref_frames").erase(&"eat_exit")
		animator.call("_play", &"idle_breathe", 1)
		animator.set_process(true)
		_preview.call_deferred()
	else: quit()

func _preview() -> void:
	while true:
		await create_timer(4.0).timeout
		animator.call("react", &"feed")
		await create_timer(8.5).timeout

func _shot(id: String) -> void:
	if "--shots" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/puppy_eat/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + id + ".png")

func _check_seam(a: AtlasTexture, bounds_a: Rect2, b: AtlasTexture, bounds_b: Rect2) -> void:
	var normalized_a := Rect2((a.margin.position + bounds_a.position) / a.get_size(), bounds_a.size / a.get_size())
	var normalized_b := Rect2((b.margin.position + bounds_b.position) / b.get_size(), bounds_b.size / b.get_size())
	# At the 360 px home viewport these limits keep the two endpoint bounds
	# within about 1 px. Source drawing differences remain, with no scale pop.
	assert((normalized_a.size - normalized_b.size).abs().x < 0.003)
	assert((normalized_a.size - normalized_b.size).abs().y < 0.003)
	assert(normalized_a.get_center().distance_to(normalized_b.get_center()) < 0.002)
