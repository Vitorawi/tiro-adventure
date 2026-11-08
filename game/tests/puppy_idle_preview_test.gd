extends SceneTree
## The approved idle is immutable; every baby home path uses new art only.

func _initialize() -> void:
	_run.call_deferred()
	create_timer(60.0).timeout.connect(func() -> void: quit(1))

func _run() -> void:
	var dog_art: Script = load("res://scripts/ui/dog_look.gd")
	var state := root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen.intro = true
	var manager := root.get_node("SaveManager")
	manager.call("set_puppy_illustrated", false)
	var main: Control = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	for i: int in 4: await process_frame
	var pet: Control = main.find_child("PetScreen", true, false)
	var animator: Node = pet.get("_animator")
	var target: TextureRect = pet.get("_dog_sprite")
	animator.set_process(false)
	var provider: GDScript = load("res://scripts/ui/animaref_clips.gd")
	assert(FileAccess.get_sha256("res://assets/sprites/characters/tiro_pet_puppy_animaref/idle_breathe.png") == "fb010a541283d6ff575032edf172642b569b0d22eae062a11f1e4f0d9d4ca0b5")
	animator.call("_play", &"idle_breathe", 1)
	assert((target.texture as AtlasTexture).margin == Rect2(300, 190, 601, 313))
	for seconds: float in provider.CLIPS[&"idle_breathe"]: assert(is_equal_approx(seconds, 0.105))
	# All old clip requests, including wishes, care feedback and unknown IDs,
	# must resolve to a supplied animation, never to a legacy texture.
	var requests: Array = animator.get("FPS").keys()
	requests.append(&"missing_animation")
	requests.append_array(provider.CLIPS.keys())
	for request: StringName in requests:
		animator.call("_play", request, 1)
		assert(provider.CLIPS.has(animator.get("_clip")))
		var frames: Array = animator.call("_clip_frames")
		assert(not frames.is_empty())
		for texture: Texture2D in frames: assert(bool(dog_art.call("is_illustrated", texture)))
		animator.set("_frame", frames.size()-1)
		animator.call("_show")
		assert(bool(dog_art.call("is_illustrated", target.texture)) and target.material == null)
		assert(not bool(animator.get("_party_hat").visible))
	for action: StringName in [&"wish", &"brush", &"pet", &"feed", &"play", &"bathe"]:
		animator.call("_play", &"idle_breathe", 1)
		animator.call("react", action)
		assert(bool(dog_art.call("is_illustrated", target.texture)) and target.material == null)
	for zone: StringName in [&"head", &"belly", &"paw"]:
		animator.call("_play", &"idle_breathe", 1)
		animator.call("stroke", zone, 0.1)
		assert(bool(dog_art.call("is_illustrated", target.texture)))
	# A damaged/newly missing clip also falls back exclusively to approved art.
	animator.get("_animaref_frames")[&"pet_head"] = []
	animator.call("_play", &"pet_head", 1)
	assert(animator.get("_clip") == &"idle_breathe" and bool(dog_art.call("is_illustrated", target.texture)))
	animator.get("_animaref_frames")[&"idle_breathe"] = []
	animator.call("_play", &"idle_breathe", 1)
	assert(target.texture.resource_path == dog_art.PUPPY_REFERENCE)
	var settings: Control = load("res://scripts/ui/settings_panel.gd").call("panel")
	root.add_child(settings)
	for i: int in 4: await process_frame
	assert(settings.find_child("PuppyIllustratedToggle", true, false) == null)
	settings.queue_free()
	state.call("dev_set_phase", "teething")
	animator.call("_play", &"idle_breathe", 1)
	assert(target.texture.resource_path.contains("tiro_pet_young/") and target.material is ShaderMaterial)
	print("PUPPY IDLE TEST: PASS; immutable idle, all clips/actions, no pixel fallback, obsolete preference ignored, other bodies preserved")
	quit()
