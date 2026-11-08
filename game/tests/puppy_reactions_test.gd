extends SceneTree
var animator: Node
var state: Node
var pet: Control
var target: TextureRect

func _initialize() -> void:
	_run.call_deferred()
	if "--preview" not in OS.get_cmdline_user_args():
		create_timer(60.0).timeout.connect(func() -> void: quit(1))

func _frames() -> void:
	for i: int in 4: await process_frame

func _run() -> void:
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen.intro = true
	var manager := root.get_node("SaveManager")
	manager.call("set_puppy_illustrated", true)
	var main: Control = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await _frames()
	pet = main.find_child("PetScreen", true, false)
	pet.set("preview_hour", 12)
	animator = pet.get("_animator")
	target = pet.get("_dog_sprite")
	animator.set_process(false)
	animator.call("_play", &"idle_breathe", 1)
	var idle: AtlasTexture = target.texture
	await _shot("00_idle")
	# The same press/release path as touching the head in the actual home.
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = target.size * Vector2(0.5, 0.35)
	pet.call("_on_dog_input", down)
	down.pressed = false
	pet.call("_on_dog_input", down)
	assert(animator.get("_clip") == &"pet_head")
	animator.set("_frame", 6)
	animator.call("stroke", &"head", 0.1)
	assert(animator.get("_frame") == 6, "Repeated touch does not restart the clip")
	animator.call("_play", &"idle_breathe", 1)
	var before: int = state.get("progress").call("stat", "pet")
	state.call("pet")
	assert(int(state.get("progress").call("stat", "pet")) == before + 1)
	assert(animator.get("_clip") == &"pet_head")
	var expected := {&"pet_head": 2.952, &"sad": 3.204, &"lick_paw": 3.276}
	for clip: StringName in expected:
		animator.call("_play", clip, 1)
		var list: Array = animator.call("_clip_frames")
		assert(list.size() == 36 and target.material == null)
		_check_seam(idle, list[0])
		_check_seam(list[35], idle)
		var total := 0.0
		for i: int in 36:
			assert(animator.get("_clip") == clip and animator.get("_frame") == i)
			var frame: AtlasTexture = list[i]
			assert(frame.region.size == Vector2(383, 450))
			assert(frame.atlas.get_width() <= 4096 and frame.atlas.get_height() <= 4096)
			assert(absf(frame.get_size().aspect() - idle.get_size().aspect()) < 0.003)
			if i in [0, 12, 24, 35]: await _shot("%s_%02d" % [clip, i])
			var seconds: float = animator.call("_frame_seconds")
			total += seconds
			animator.call("_process", seconds + 0.0000001)
		assert(is_equal_approx(total, float(expected[clip])))
		assert(animator.get("_clip") == &"idle_breathe" and target.texture == idle)
	# A favorite-place gesture keeps its belly response, but does not cut the
	# new head animation in half while it is playing.
	animator.call("_play", &"pet_head", 1)
	animator.set("_frame", 12)
	animator.call("love")
	assert(animator.get("_clip") == &"pet_head" and animator.get("_frame") == 12)
	assert(animator.get("_chain") == [&"belly_enter"])
	animator.call("_process", 24.0 * 0.082 + 0.000001)
	assert(animator.get("_clip") == &"belly_enter")
	animator.set("_next", &"")
	animator.call("_play", &"idle_breathe", 1)
	# Real low need sets sadness; healthy dog never randomly plays it.
	state.get("dog").get("needs")["hunger"] = 10.0
	state.call("_changed")
	await _frames()
	assert(bool(animator.get("_sad")))
	seed(4281)
	var sad_count := 0
	for i: int in 300:
		if animator.call("_pick_fidget") == &"sad": sad_count += 1
	assert(sad_count > 120 and sad_count < 240, "Occasional sad reaction, no forced loop")
	for need: String in state.get("dog").get("needs"):
		state.get("dog").get("needs")[need] = 80.0
	state.call("_changed")
	await _frames()
	assert(not bool(animator.get("_sad")))
	var seen := {}
	for i: int in 300:
		var choice: StringName = animator.call("_pick_fidget")
		assert(choice in [&"head_tilt", &"close_eyes", &"lick_paw"])
		seen[choice] = true
	assert(seen.size() == 3)
	animator.set("_fidget_in", -1.0)
	animator.set("_frame", 4)
	animator.call("_process", 0.001)
	assert(animator.get("_clip") == &"idle_breathe")
	animator.set("_frame", 0)
	animator.call("_process", 0.001)
	assert(animator.get("_clip") in [&"head_tilt", &"close_eyes", &"lick_paw"])
	animator.call("_play", &"idle_breathe", 1)
	var portrait: Control = load("res://scripts/ui/pet_animator.gd").call("portrait", 64)
	root.add_child(portrait)
	await _frames()
	assert((portrait.get_child(0) as TextureRect).texture.resource_path.ends_with("/reference.png"))
	portrait.queue_free()
	manager.call("set_puppy_illustrated", false)
	animator.call("_play", &"pet_head", 1)
	assert(target.material == null and target.texture is AtlasTexture)
	manager.call("set_puppy_illustrated", true)
	animator.call("_play", &"idle_breathe", 1)
	var cache: Dictionary = animator.get("_animaref_frames")
	cache[&"sad"] = []
	cache[&"lick_paw"] = []
	animator.call("set_sad", true)
	for i: int in 100: assert(animator.call("_pick_fidget") in [&"head_tilt", &"close_eyes"])
	animator.call("set_sad", false)
	print("PUPPY REACTIONS: PASS; 108 frames, touch/pet, six seams, timing, low needs, random fidgets, portrait and fallback")
	if "--preview" in OS.get_cmdline_user_args():
		cache.erase(&"sad")
		cache.erase(&"lick_paw")
		animator.set_process(true)
		_preview.call_deferred()
	else: quit()

func _preview() -> void:
	while true:
		for clip: StringName in [&"pet_head", &"sad", &"lick_paw"]:
			animator.call("_play", &"idle_breathe", 1)
			animator.set("_fidget_in", 999.0)
			await create_timer(2.0).timeout
			animator.call("_play", clip, 1)
			await create_timer(3.4).timeout

func _check_seam(a: AtlasTexture, b: AtlasTexture) -> void:
	var ab := Rect2(a.atlas.get_image().get_region(a.region).get_used_rect())
	var bb := Rect2(b.atlas.get_image().get_region(b.region).get_used_rect())
	var na := Rect2((a.margin.position + ab.position) / a.get_size(), ab.size / a.get_size())
	var nb := Rect2((b.margin.position + bb.position) / b.get_size(), bb.size / b.get_size())
	assert(absf(na.size.x-nb.size.x) < 0.0045 and absf(na.size.y-nb.size.y) < 0.0045)
	assert(na.get_center().distance_to(nb.get_center()) < 0.0015)

func _shot(id: String) -> void:
	if "--shots" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/puppy_reactions/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + id + ".png")
