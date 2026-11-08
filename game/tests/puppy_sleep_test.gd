extends SceneTree
var animator: Node
var target: TextureRect
var state: Node

func _initialize() -> void:
	_run.call_deferred()
	if "--preview" not in OS.get_cmdline_user_args():
		create_timer(60.0).timeout.connect(func() -> void: quit(1))

func _frames() -> void:
	for i: int in 4: await process_frame

func _sleep(value: bool) -> void:
	state.call("set_sleeping", value)
	await _frames()
	assert(bool(state.get("dog").get("sleeping")) == value)

func _run() -> void:
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen.intro = true
	state.get("dog").get("needs")["energy"] = 40.0
	var manager := root.get_node("SaveManager")
	manager.call("set_puppy_illustrated", true)
	var main: Control = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await _frames()
	var pet: Control = main.find_child("PetScreen", true, false)
	pet.set("preview_hour", 12)
	animator = pet.get("_animator")
	target = pet.get("_dog_sprite")
	animator.set_process(false)
	animator.call("_play", &"idle_breathe", 1)
	var idle: AtlasTexture = target.texture
	await _shot("00_idle")
	await _sleep(true)
	assert(animator.get("_clip") == &"sleep_enter")
	var cache: Dictionary = animator.get("_animaref_frames")
	var enter: Array = cache[&"sleep_enter"]
	var sleeping: Array = cache[&"sleep_loop"]
	var waking: Array = cache[&"sleep_exit"]
	assert(enter.size() == 36 and sleeping.size() == 36 and waking.size() == 36)
	assert(enter[0].margin == enter[35].margin, "Entrance has no scale drift")
	assert(sleeping[0].margin == sleeping[35].margin, "Breathing uses fixed registration")
	_check_seam(idle, enter[0])
	_check_seam(enter[35], sleeping[0])
	_check_seam(sleeping[35], sleeping[0])
	_check_seam(sleeping[35], waking[0])
	_check_seam(waking[35], idle)
	for group: Array in [enter, sleeping, waking]:
		for frame: AtlasTexture in group:
			assert(frame.atlas.get_width() <= 4096 and frame.atlas.get_height() <= 4096)
			assert(frame.region.size == Vector2(438, 444))
			assert(absf(frame.get_size().aspect() - idle.get_size().aspect()) < 0.003)
	assert(waking[0].get_size().x > waking[35].get_size().x, "Wake compensates the smaller final drawing")
	assert(is_equal_approx(await _advance(&"sleep_enter", 0, true), 2.808))
	assert(animator.get("_clip") == &"sleep_loop")
	assert(is_equal_approx(await _advance(&"sleep_loop", 0, true), 2.124))
	for i: int in 3:
		await _advance(&"sleep_loop")
		assert(animator.get("_clip") == &"sleep_loop" and animator.get("_frame") == 0)
	await _sleep(false)
	assert(animator.get("_clip") == &"sleep_exit")
	assert(is_equal_approx(await _advance(&"sleep_exit", 0, true), 2.664))
	assert(animator.get("_clip") == &"idle_breathe" and target.texture == idle)
	await _shot("99_idle")
	# Rapid wake while lying down: finish entering, then wake without a pose jump.
	await _sleep(true)
	for i: int in 10: animator.call("_process", 0.0780001)
	await _sleep(false)
	assert(animator.get("_clip") == &"sleep_enter" and animator.get("_frame") == 10)
	await _advance(&"sleep_enter", 10)
	assert(animator.get("_clip") == &"sleep_exit")
	await _advance(&"sleep_exit")
	assert(animator.get("_clip") == &"idle_breathe")
	# Rapid sleep during wake: finish waking, then enter sleep again.
	await _sleep(true)
	await _advance(&"sleep_enter")
	await _sleep(false)
	for i: int in 12: animator.call("_process", 0.0740001)
	await _sleep(true)
	assert(animator.get("_clip") == &"sleep_exit" and animator.get("_frame") == 12)
	await _advance(&"sleep_exit", 12)
	assert(animator.get("_clip") == &"sleep_enter")
	await _advance(&"sleep_enter")
	# Turning the preference off while asleep falls back safely as a whole.
	manager.call("set_puppy_illustrated", false)
	animator.call("_process", 0.0)
	assert(animator.get("_clip") == &"sleep_loop" and target.material == null)
	manager.call("set_puppy_illustrated", true)
	await _sleep(false)
	await _advance(&"sleep_exit")
	await _sleep(true)
	await _advance(&"sleep_enter")
	state.call("dev_set_phase", "teething")
	assert(animator.get("_clip") == &"sleep", "Other bodies keep original sleeping pose")
	await _sleep(false)
	state.call("dev_set_phase", "newborn")
	cache[&"sleep_exit"] = []
	await _sleep(true)
	assert(animator.get("_clip") == &"idle_breathe" and target.material == null, "Incomplete group never returns to pixel")
	await _sleep(false)
	print("PUPPY SLEEP: PASS; real sleep/wake, 108 frames, five seams, breathing loops, rapid toggles and fallbacks")
	if "--preview" in OS.get_cmdline_user_args():
		cache.erase(&"sleep_exit")
		animator.set_process(true)
		_preview.call_deferred()
	else: quit()

func _advance(clip: StringName, first: int = 0, shots: bool = false) -> float:
	var times: Array = load("res://scripts/ui/animaref_clips.gd").CLIPS[clip]
	var total := 0.0
	for i: int in range(first, 36):
		assert(animator.get("_clip") == clip and animator.get("_frame") == i)
		if shots and i in [0, 12, 24, 35]: await _shot("%s_%02d" % [clip, i])
		animator.call("stroke", &"head", 0.2)
		animator.call("love")
		animator.call("react", &"play")
		assert(animator.get("_clip") == clip and animator.get("_frame") == i)
		var seconds := float(times[i])
		total += seconds
		animator.call("_process", seconds + 0.0000001)
	return total

func _check_seam(a: AtlasTexture, b: AtlasTexture) -> void:
	var ab := Rect2(a.atlas.get_image().get_region(a.region).get_used_rect())
	var bb := Rect2(b.atlas.get_image().get_region(b.region).get_used_rect())
	var na := Rect2((a.margin.position + ab.position) / a.get_size(), ab.size / a.get_size())
	var nb := Rect2((b.margin.position + bb.position) / b.get_size(), bb.size / b.get_size())
	assert(absf(na.size.x-nb.size.x) < 0.0045 and absf(na.size.y-nb.size.y) < 0.0045)
	assert(na.get_center().distance_to(nb.get_center()) < 0.0015)

func _preview() -> void:
	while true:
		await create_timer(3.0).timeout
		state.get("dog").get("needs")["energy"] = 40.0
		state.call("set_sleeping", true)
		await create_timer(9.2).timeout
		state.call("set_sleeping", false)
		await create_timer(2.9).timeout

func _shot(id: String) -> void:
	if "--shots" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/puppy_sleep/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + id + ".png")
