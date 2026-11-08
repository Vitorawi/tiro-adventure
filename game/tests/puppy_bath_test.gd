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
	state.get("inventory").call("add", "herb_shampoo", 1)
	var before: int = state.get("inventory").call("count", "herb_shampoo")
	state.call("bathe", true)
	assert(int(state.get("inventory").call("count", "herb_shampoo")) == before - 1)
	assert(animator.get("_clip") == &"bath")
	var frames: Array = animator.call("_clip_frames")
	assert(frames.size() == 36)
	assert(target.material == null)
	_check_endpoint(idle, frames[0])
	_check_endpoint(idle, frames[35])
	var total := 0.0
	for i: int in 36:
		var frame: AtlasTexture = frames[i]
		assert(frame.atlas.get_width() <= 4096 and frame.atlas.get_height() <= 4096)
		assert(frame.region.size.x <= 430 and frame.region.size.y <= 754, "folha cortada/reduzida cabe na célula original")
		assert(frame.region.end.x <= frame.atlas.get_width() and frame.region.end.y <= frame.atlas.get_height())
		assert(absf(frame.get_size().aspect() - idle.get_size().aspect()) < 0.003)
		assert(animator.get("_clip") == &"bath" and animator.get("_frame") == i)
		if i in [0, 7, 14, 18, 21, 28, 35]: await _shot("bath_%02d" % i)
		animator.call("stroke", &"head", 0.2)
		animator.call("love")
		animator.call("react", &"play")
		animator.call("react", &"bathe")
		assert(animator.get("_clip") == &"bath" and animator.get("_frame") == i)
		var seconds: float = animator.call("_frame_seconds")
		total += seconds
		animator.call("_process", seconds + 0.0000001)
	assert(is_equal_approx(total, 4.68))
	assert(animator.get("_clip") == &"idle_breathe" and animator.get("_chain").is_empty())
	assert(target.texture == idle)
	await _shot("99_idle")
	animator.call("react", &"bathe")
	state.call("dev_set_phase", "teething")
	assert(animator.get("_clip") == &"idle_breathe")
	animator.call("react", &"bathe")
	assert(animator.get("_clip") == &"shake_off")
	state.call("dev_set_phase", "newborn")
	animator.call("_play", &"idle_breathe", 1)
	manager.call("set_puppy_illustrated", false)
	animator.call("react", &"bathe")
	assert(animator.get("_clip") == &"bath" and target.material == null)
	manager.call("set_puppy_illustrated", true)
	animator.call("_play", &"idle_breathe", 1)
	animator.get("_animaref_frames")[&"bath"] = []
	animator.call("react", &"bathe")
	assert(animator.get("_clip") == &"idle_breathe" and target.material == null)
	print("PUPPY BATH: PASS; real bath, 36 frames/4.68 s, endpoints, atlas pages, return, interruptions and fallback")
	if "--preview" in OS.get_cmdline_user_args():
		animator.get("_animaref_frames").erase(&"bath")
		animator.call("_play", &"idle_breathe", 1)
		animator.set_process(true)
		_preview.call_deferred()
	else: quit()

func _check_endpoint(idle: AtlasTexture, bath: AtlasTexture) -> void:
	# Actual source alpha bounds, not a frame containing foam/water.
	var idle_bounds := Rect2(idle.atlas.get_image().get_region(idle.region).get_used_rect())
	var bath_bounds := Rect2(bath.atlas.get_image().get_region(bath.region).get_used_rect())
	var a := Rect2((idle.margin.position + idle_bounds.position) / idle.get_size(), idle_bounds.size / idle.get_size())
	var b := Rect2((bath.margin.position + bath_bounds.position) / bath.get_size(), bath_bounds.size / bath.get_size())
	# About 1 px on the 360 px home; no promise of identical generated fur pixels.
	assert(absf(a.size.x-b.size.x) < 0.0025 and absf(a.size.y-b.size.y) < 0.0025)
	assert(a.get_center().distance_to(b.get_center()) < 0.002)

func _preview() -> void:
	while true:
		await create_timer(3.0).timeout
		animator.call("react", &"bathe")
		await create_timer(4.8).timeout

func _shot(id: String) -> void:
	if "--shots" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/puppy_bath/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + id + ".png")
