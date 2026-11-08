extends SceneTree
const IDLE_HASH := "fb010a541283d6ff575032edf172642b569b0d22eae062a11f1e4f0d9d4ca0b5"
var animator: Node
var state: Node
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
	assert(FileAccess.get_sha256("res://assets/sprites/characters/tiro_pet_puppy_animaref/idle_breathe.png") == IDLE_HASH)
	assert(idle.margin == Rect2(300, 190, 601, 313))
	var provider: GDScript = load("res://scripts/ui/animaref_clips.gd")
	assert(provider.CLIPS[&"idle_breathe"].size() == 36)
	for seconds: float in provider.CLIPS[&"idle_breathe"]: assert(is_equal_approx(seconds, 0.105))
	await _shot("00_idle")
	# A real favorite-place care action queues the belly after head petting.
	animator.call("_play", &"pet_head", 1)
	animator.set("_frame", 12)
	var before: int = state.get("progress").call("stat", "pet")
	state.call("pet", state.call("favorite_spot"))
	assert(int(state.get("progress").call("stat", "pet")) == before + 1)
	assert(animator.get("_clip") == &"pet_head" and animator.get("_frame") == 12)
	assert(animator.get("_chain") == [&"belly_enter"])
	await _advance(&"pet_head", 12)
	assert(animator.get("_clip") == &"belly_enter")
	var cache: Dictionary = animator.get("_animaref_frames")
	var enter: Array = cache[&"belly_enter"]
	var rubbing: Array = cache[&"belly_loop"]
	var exit: Array = cache[&"belly_exit"]
	assert(enter.size() == 36 and rubbing.size() == 36 and exit.size() == 36)
	assert(enter[0].get_size() == enter[35].get_size(), "Entrance keeps its scale")
	assert(rubbing[0].margin == rubbing[35].margin, "Loop does not breathe by resizing the whole body")
	_check_seam(idle, enter[0])
	_check_seam(enter[35], rubbing[0])
	_check_seam(rubbing[35], rubbing[0])
	_check_seam(rubbing[35], exit[0])
	_check_seam(exit[35], idle)
	for group: Array in [enter, rubbing, exit]:
		for frame: AtlasTexture in group:
			assert(frame.atlas.get_width() <= 4096 and frame.atlas.get_height() <= 4096)
			assert(frame.region.size == Vector2(437, 336))
			assert(absf(frame.get_size().aspect() - idle.get_size().aspect()) < 0.004)
	assert(is_equal_approx(await _advance(&"belly_enter", 0, true), 3.348))
	assert(animator.get("_clip") == &"belly_loop" and bool(animator.get("_belly_up")))
	assert(is_equal_approx(await _advance(&"belly_loop", 0, true, true), 3.636))
	for i: int in 2:
		await _advance(&"belly_loop", 0, false, true)
		assert(animator.get("_clip") == &"belly_loop" and bool(animator.get("_belly_up")))
	assert(int(state.get("progress").call("stat", "pet")) == before + 1, "Visual rubbing does not grant extra care")
	# Release: timer expires, then finish the current loop before standing up.
	await _advance(&"belly_loop")
	assert(animator.get("_clip") == &"belly_loop")
	await _advance(&"belly_loop")
	assert(animator.get("_clip") == &"belly_exit" and not bool(animator.get("_belly_up")))
	assert(is_equal_approx(await _advance(&"belly_exit", 0, true), 2.34))
	assert(animator.get("_clip") == &"idle_breathe" and target.texture == idle)
	await _shot("99_idle")
	# Sleep requested while belly-up stands first, then uses the seated entry.
	animator.call("love")
	await _advance(&"belly_enter")
	state.call("set_sleeping", true)
	await _frames()
	assert(animator.get("_clip") == &"belly_exit")
	await _advance(&"belly_exit")
	assert(animator.get("_clip") == &"sleep_enter")
	await _advance(&"sleep_enter")
	state.call("set_sleeping", false)
	await _frames()
	await _advance(&"sleep_exit")
	assert(animator.get("_clip") == &"idle_breathe")
	animator.call("love")
	await _advance(&"belly_enter")
	state.call("dev_set_phase", "teething")
	assert(animator.get("_clip") == &"idle_breathe" and not bool(animator.get("_belly_up")))
	state.call("dev_set_phase", "newborn")
	animator.call("love")
	await _advance(&"belly_enter")
	manager.call("set_puppy_illustrated", false)
	animator.call("_process", 0.0)
	assert(animator.get("_clip") == &"belly_loop" and bool(animator.get("_belly_up")))
	assert(target.material == null)
	manager.call("set_puppy_illustrated", true)
	cache[&"belly_exit"] = []
	animator.call("_process", 0.0)
	animator.call("love")
	assert(animator.get("_clip") == &"pet_head", "Incomplete group uses an approved new reaction")
	animator.set("_next", &"")
	animator.call("_play", &"idle_breathe", 1)
	assert(FileAccess.get_sha256("res://assets/sprites/characters/tiro_pet_puppy_animaref/idle_breathe.png") == IDLE_HASH)
	print("PUPPY BELLY: PASS; immutable idle, 108 frames/five seams, favorite care, held loop/release, sleep and fallback")
	if "--preview" in OS.get_cmdline_user_args():
		cache.erase(&"belly_exit")
		animator.set_process(true)
		_preview.call_deferred()
	else: quit()

func _advance(clip: StringName, first: int = 0, shots: bool = false, rubbing: bool = false) -> float:
	var times: Array = load("res://scripts/ui/animaref_clips.gd").CLIPS[clip]
	var total := 0.0
	for i: int in range(first, 36):
		assert(animator.get("_clip") == clip and animator.get("_frame") == i)
		if shots and i in [0, 12, 24, 35]: await _shot("%s_%02d" % [clip, i])
		if rubbing: animator.call("stroke", &"belly", 0.1)
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
		animator.call("love")
		await create_timer(3.5).timeout
		for i: int in 16:
			animator.call("stroke", &"belly", 0.1)
			await create_timer(0.25).timeout
		await create_timer(10.0).timeout

func _shot(id: String) -> void:
	if "--shots" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/puppy_belly/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + id + ".png")
