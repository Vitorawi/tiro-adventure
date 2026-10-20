extends SceneTree
## Portão 16: três resoluções, estado descartável e seis fases pelo DEV.
var state: Node
var main: Node
var out: String
var notebook: Script
var growth_ui: Script
var album_ui: Script
var house_ui: Script

func _initialize() -> void:
	_run.call_deferred()
	create_timer(160).timeout.connect(func() -> void: quit(1))

func quiet() -> void:
	main.set("_chapter_done", 0)
	main.set("_announce_pending", false)
	main.set("_modal_queue", [] as Array[Callable])
	main.set("_photo_queue", [] as Array[String])
	for member: String in ["_celebration", "_welcome", "_walk_result"]: main.get(member).hide()
	state._mark_all_seen()
	root.get_node("Events").sheet_close_requested.emit()

func shot(id: String) -> void:
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + id + ".png")

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.reset()
	state.dev_unlock_everything()
	state.dev_reset_album()
	state.growth.diary.clear()
	state.growth.diary_receipts = {}
	state.inventory.add("basic_brush", 1)
	state.dev_set_phase("explorer")
	state.growth.delivered = {"teething": {"chew_ring": 1}, "explorer": {"stick_chew": 1}, "young": {"soft_brush": 1}, "adult": {"courage_medal": 1}}
	state.dev_take_photo("h_arrival")
	state.dev_take_photo("h_growth_explorer")
	state.dev_take_photo("f_taste")
	state.hang_photo("h_arrival")
	state.hang_photo("h_growth_explorer")
	state.growth.personality.current = "explorer"
	state._diary("walk", "Trilha do parque")
	state.progress.seen.intro = true
	Motion.reduced = true
	notebook = load("res://scripts/ui/pet_notebook.gd")
	growth_ui = load("res://scripts/ui/growth_ui.gd")
	album_ui = load("res://scripts/ui/album_view.gd")
	house_ui = load("res://scripts/ui/house_ui.gd")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1).timeout
	var resolution := "%dx%d" % [root.size.x, root.size.y]
	out = ProjectSettings.globalize_path("res://../build/screenshots/tiro16_" + resolution + "/")
	DirAccess.make_dir_recursive_absolute(out)
	quiet()
	state.dev_set_phase("explorer")
	main.show_screen(&"pet")
	await shot("care_five")
	growth_ui.open()
	await shot("growth_personality")
	notebook.open("growth")
	await shot("notebook_diary")
	notebook.open("album:tricks")
	await shot("album_secrets")
	album_ui.open_photo("h_growth_explorer")
	await shot("album_photo")
	quiet()
	main.call("_on_world_requested", "house", "")
	await shot("house")
	house_ui.open("memory_shelf")
	await shot("house_shelf")
	quiet()
	main.show_screen(&"pet")
	var pet: Node = main.find_child("PetScreen", true, false)
	var animator: Node = pet.get("_animator")
	for phase: String in ["newborn", "puppy", "teething", "explorer", "young", "adult"]:
		state.dev_set_phase(phase)
		quiet()
		var clips := {}
		# Observa o sorteio real por 12 s; os pesos/intervalos são testados sem sorte.
		animator.call("_play", &"idle_breathe", 1)
		animator.set("_fidget_in", 0.1)
		for sample in 24:
			await create_timer(0.5).timeout
			clips[str(animator.get("_clip"))] = true
		print("PHASE OBSERVED ", phase, ": ", clips.keys())
		var example := str({"newborn": "yawn", "puppy": "sleep", "teething": "lick_paw", "explorer": "chase_tail", "young": "head_tilt", "adult": "idle_breathe"}[phase])
		animator.set("_fidget_in", 3.0)
		animator.call("_play", StringName(example), 1)
		print("PHASE DEMO ", phase, ": ", example, " (clipe existente, visual controlado após observação)")
		await shot("phase_" + phase)
	main.queue_free()
	await process_frame
	quit(0)

