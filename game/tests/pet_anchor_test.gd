extends SceneTree
## Regressão do Tiro saindo do tapete: layout, animações, cuidados e rotação, sem save pessoal.
var failures := 0
var pet: Control
var main: Control
var shots := "--screenshots" in OS.get_cmdline_user_args()

func _initialize() -> void:
	_run.call_deferred()
	create_timer(180).timeout.connect(func() -> void: quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("PET ANCHOR: " + message)

func settle() -> void:
	for i in 8: await process_frame

func anchor_error() -> float:
	var sprite: Control = pet.get_node("%DogSprite")
	var corner: PetBackdrop = pet.get_node("%Corner")
	var feet := sprite.global_position + sprite.size * Vector2(0.5, 0.81)
	return feet.distance_to(corner.global_position + corner.pet_feet())

func shot(id: String) -> void:
	if not shots: return
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/pet_anchor")
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder.path_join(id + ".png")) == OK, "captura " + id)

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var state := root.get_node("GameState")
	state.reset()
	state.progress.seen.intro = true
	state._mark_all_seen()
	Motion.reduced = false
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await settle()
	pet = main.find_child("PetScreen", true, false)
	pet.preview_hour = 12
	for viewport: Vector2i in [Vector2i(360, 640), Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915), Vector2i(844, 390), Vector2i(390, 844)]:
		root.size = viewport
		await settle()
		check(anchor_error() < 0.1, "alinhamento após resize %s: erro %.2f px" % [viewport, anchor_error()])
		# Ordenação diferida do contêiner também acontece ao voltar de outra aba.
		for i in 5:
			main.show_screen(&"tasks")
			await settle()
			main.show_screen(&"pet")
			pet.get_node("%DogArea").queue_sort()
			await settle()
		check(anchor_error() < 0.1, "alinhamento após reordenar/voltar %s: erro %.2f px" % [viewport, anchor_error()])
		await shot("home_%dx%d" % [viewport.x, viewport.y])
	var animator: Node = pet.get("_animator")
	# Todos os clipes e corpos: a textura nunca deve deslocar o ponto de apoio.
	for phase: String in ["puppy", "young", "adult"]:
		state.growth.phase = phase
		state._changed()
		for clip: StringName in animator.FPS:
			animator._play(clip, 1)
			await settle()
			check(anchor_error() < 0.1, "corpo/clipe %s/%s" % [phase, clip])
	animator._play(&"idle_breathe", 1)
	await shot("iphone_start")
	# Execução real, sem avançar relógio nem chamar o layout para mascarar deriva.
	var seconds := 65 if shots else 5
	var max_error := 0.0
	for i in seconds * 10:
		await create_timer(0.1).timeout
		max_error = maxf(max_error, anchor_error())
	check(max_error < 0.1, "deriva durante %ds: %.2f px" % [seconds, max_error])
	print("PET ANCHOR: %ds reais; desvio máximo %.3f px" % [seconds, max_error])
	await shot("iphone_after_65s")
	main.queue_free()
	await settle()
	print("PET ANCHOR: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)
