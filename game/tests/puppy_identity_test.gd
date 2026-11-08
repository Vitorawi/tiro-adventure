extends SceneTree
var state: Node
var main: Control
var count := 0

func _initialize() -> void:
	_run.call_deferred()
	create_timer(90.0).timeout.connect(func() -> void: quit(1))

func _frames() -> void:
	for i: int in 5: await process_frame

func _run() -> void:
	var dog_art: Script = load("res://scripts/ui/dog_look.gd")
	var growth_ui: Script = load("res://scripts/ui/growth_ui.gd")
	var ceremony_ui: Script = load("res://scenes/ui/growth_ceremony/growth_ceremony.gd")
	var photo_ui: Script = load("res://scripts/ui/photo_card.gd")
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen.intro = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await _frames()
	var pet: Control = main.find_child("PetScreen", true, false)
	pet.set("preview_hour", 12)
	state.call("_changed")
	await _frames()
	var look: Dictionary = state.call("dog_look")
	assert(look.body == "puppy" and str(look.portrait).ends_with("reference_head.png") and str(look.idle_front).ends_with("reference_front.png"))
	var head: TextureRect = main.find_child("HudHead", true, false)
	assert(head.texture.resource_path == look.portrait and head.material == null)
	var button: Button = main.find_child("HudAvatar", true, false)
	assert(button.icon.resource_path == look.portrait and button.material == null)
	var world: Node = main.find_child("World_house", true, false)
	assert(str(world.get("_dog").get("sprite_dir")) == str(look.dir_world), "Map art stays unchanged")
	await _shot("home")
	# The introduction uses the same exact reference, cropped to a full portrait.
	var intro: Node = load("res://scenes/ui/intro/intro.gd").new()
	root.add_child(intro)
	await _frames()
	var intro_pet: TextureRect = intro.get("_tiro")
	assert(intro_pet.texture.resource_path == look.idle_front and intro_pet.material == null)
	intro_pet.modulate.a = 1.0
	intro_pet.scale = Vector2.ONE
	await _shot("intro")
	intro.queue_free()
	await _frames()
	var portrait: Control = load("res://scripts/ui/pet_animator.gd").call("portrait", 96)
	root.add_child(portrait)
	await _frames()
	var image: TextureRect = portrait.get_child(0)
	assert(image.texture.resource_path == dog_art.PUPPY_REFERENCE and image.material == null)
	var current: Dictionary = state.call("growth_info").current
	var phase: Dictionary = state.call("growth_info").next
	var silhouette: Control = growth_ui.call("silhouette", phase, 1, false, "IdentitySilhouette", 96)
	root.add_child(silhouette)
	assert((silhouette.get_child(0) as TextureRect).texture.resource_path == dog_art.PUPPY_REFERENCE)
	var ceremony: Control = ceremony_ui.call("pose", current, 124)
	root.add_child(ceremony)
	assert((ceremony.get_child(0) as TextureRect).texture.resource_path == dog_art.PUPPY_REFERENCE)
	assert((ceremony.get_child(0) as TextureRect).material == null)
	assert(photo_ui.call("dog_frame", "newborn", "sleep", 0).resource_path == dog_art.PUPPY_REFERENCE)
	assert(photo_ui.call("dog_frame", "puppy", "pet_head", 4).resource_path == dog_art.PUPPY_REFERENCE)
	portrait.queue_free()
	silhouette.queue_free()
	ceremony.queue_free()
	growth_ui.call("open")
	await _frames()
	await _shot("growth")
	root.get_node("Events").emit_signal("sheet_close_requested")
	await _frames()
	# Render before/after puppy portraits through the actual ceremony card.
	var show: Node = load("res://scenes/ui/growth_ceremony/growth_ceremony.gd").new()
	root.add_child(show)
	show.set("_before", current)
	show.set("_after", phase)
	show.set("phase", "puppy")
	show.show()
	show.call("show_card")
	await _frames()
	await _shot("ceremony")
	show.queue_free()
	await _frames()
	# Existing phase two uses the same baby reference; young/adult keep theirs.
	state.call("dev_set_phase", "puppy")
	await _frames()
	assert((main.find_child("HudHead", true, false) as TextureRect).texture.resource_path == look.portrait)
	state.call("dev_set_phase", "teething")
	await _frames()
	assert(not str(state.call("dog_look").portrait).contains("animaref"))
	assert((main.find_child("HudHead", true, false) as TextureRect).material is ShaderMaterial)
	print("PUPPY IDENTITY: PASS; HUD, intro, portraits, growth, ceremony, photos, both baby phases, other bodies/maps unchanged")
	quit()

func _shot(id: String) -> void:
	if "--shots" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/puppy_identity/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + id + ".png")
