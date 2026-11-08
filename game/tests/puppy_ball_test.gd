extends SceneTree
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
	var idle: AtlasTexture = target.texture
	await _shot("00_idle")
	var before: int = state.get("progress").call("stat", "play")
	assert(bool(state.call("play")))
	assert(int(state.get("progress").call("stat", "play")) == before + 1)
	assert(animator.get("_clip") == &"play_ball")
	var frames: Array = animator.call("_clip_frames")
	assert(frames.size() == 36 and target.material == null)
	_check_endpoint(idle, frames[0])
	_check_endpoint(idle, frames[35])
	var total := 0.0
	for i: int in 36:
		var frame: AtlasTexture = frames[i]
		assert(frame.atlas.get_width() <= 4096 and frame.atlas.get_height() <= 4096)
		assert(frame.region.size == Vector2(896, 504))
		assert(frame.region.end.x <= frame.atlas.get_width() and frame.region.end.y <= frame.atlas.get_height())
		assert(absf(frame.get_size().aspect() - idle.get_size().aspect()) < 0.003)
		assert(animator.get("_clip") == &"play_ball" and animator.get("_frame") == i)
		if i in [0, 7, 14, 18, 21, 28, 35]: await _shot("ball_%02d" % i)
		animator.call("stroke", &"head", 0.2)
		animator.call("love")
		animator.call("react", &"bathe")
		animator.call("react", &"play")
		assert(animator.get("_clip") == &"play_ball" and animator.get("_frame") == i)
		var seconds: float = animator.call("_frame_seconds")
		total += seconds
		animator.call("_process", seconds + 0.0000001)
	assert(is_equal_approx(total, 4.428))
	assert(animator.get("_clip") == &"idle_breathe" and target.texture == idle)
	await _shot("99_idle")
	animator.call("react", &"play")
	animator.call("set_sleeping", true)
	assert(animator.get("_clip") == &"sleep_enter" and animator.get("_chain").is_empty())
	animator.call("set_sleeping", false)
	animator.call("react", &"play")
	state.call("dev_set_phase", "teething")
	assert(animator.get("_clip") == &"idle_breathe")
	animator.call("react", &"play")
	assert(animator.get("_clip") == &"happy_jump")
	state.call("dev_set_phase", "newborn")
	animator.call("_play", &"idle_breathe", 1)
	manager.call("set_puppy_illustrated", false)
	animator.call("react", &"play")
	assert(animator.get("_clip") == &"play_ball" and target.material == null)
	manager.call("set_puppy_illustrated", true)
	animator.call("_play", &"idle_breathe", 1)
	animator.get("_animaref_frames")[&"play_ball"] = []
	animator.call("react", &"play")
	assert(animator.get("_clip") == &"idle_breathe" and target.material == null)
	print("PUPPY BALL: PASS; real play, 36 frames/4.428 s, endpoints, pages, return, interruptions and fallback")
	if "--preview" in OS.get_cmdline_user_args():
		animator.get("_animaref_frames").erase(&"play_ball")
		animator.call("_play", &"idle_breathe", 1)
		animator.set_process(true)
		_preview.call_deferred()
	else: quit()

func _check_endpoint(idle: AtlasTexture, ball: AtlasTexture) -> void:
	var idle_bounds := Rect2(idle.atlas.get_image().get_region(idle.region).get_used_rect())
	var ball_bounds := Rect2(ball.atlas.get_image().get_region(ball.region).get_used_rect())
	var a := Rect2((idle.margin.position + idle_bounds.position) / idle.get_size(), idle_bounds.size / idle.get_size())
	var b := Rect2((ball.margin.position + ball_bounds.position) / ball.get_size(), ball_bounds.size / ball.get_size())
	# Uniform scaling preserves proportions; generated endpoint shapes differ
	# slightly. Bounds stay within roughly 2–3 px on the 360 px home viewport.
	assert(absf(a.size.x-b.size.x) < 0.0045 and absf(a.size.y-b.size.y) < 0.0045)
	assert(a.get_center().distance_to(b.get_center()) < 0.001)

func _preview() -> void:
	while true:
		await create_timer(3.0).timeout
		animator.call("react", &"play")
		await create_timer(4.6).timeout

func _shot(id: String) -> void:
	if "--shots" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/puppy_ball/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + id + ".png")
