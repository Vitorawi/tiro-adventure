extends SceneTree
## Regressão do cartão História: toque real, destinos, bloqueio e entrega única.
var state: Node
var main: Control
var failures := 0
var destinations: Array[String] = []
var gains := 0
var before := false
var shots := false

func _initialize() -> void:
	before = "--before" in OS.get_cmdline_user_args()
	shots = "--shots" in OS.get_cmdline_user_args()
	_run.call_deferred()
	create_timer(100).timeout.connect(func() -> void: quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("MISSIONS: " + message)

func frames(n: int = 6) -> void:
	for i in n: await process_frame

func node(id: String) -> Control:
	return main.find_child(id, true, false) as Control

func clear_modals() -> void:
	main.set("_modal_queue", [] as Array[Callable])
	main.set("_quest_rewards", [] as Array[Dictionary])
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		main.get(member).hide()

func fresh() -> void:
	if is_instance_valid(main):
		main.queue_free()
		await frames()
	state.call("reset")
	var progress: Object = state.get("progress")
	progress.seen.intro = true
	var quests: Dictionary = root.get_node("Database").get("quests")
	for chapter in [1, 2]:
		for id: String in progress.main_quests(chapter):
			if id == "lais_first_crops": break
			progress.claimed_quests[id] = true
			if quests[id].has("shared_with"): progress.claimed_quests[quests[id].shared_with] = true
	state.get("growth").phase = "puppy"
	state.call("_mark_all_seen")
	state.call("_changed")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	node("TasksScreen").get("_content").set_meta("tick_refresh", false)
	main.call("show_screen", &"tasks")
	node("TasksScreen").call("choose_group", "story")
	await frames(12)
	clear_modals()
	check(progress.displayed_main_quest() == "first_harvest", "fixture: primeira colheita da vovó")

func tap(control: Control) -> void:
	check(control != null and control.is_visible_in_tree(), "alvo visível")
	if control == null: return
	var scroll := node("TasksScreen").find_child("Scroll", true, false) as ScrollContainer
	scroll.ensure_control_visible(control)
	await frames()
	check(scroll.get_global_rect().encloses(control.get_global_rect()), "alvo inteiro na rolagem")
	check(control.size.x >= 44 and control.size.y >= 44, "alvo mínimo 44 px")
	var point := root.get_final_transform() * control.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames(2)
	await frames()

func shot(kind: String) -> void:
	if not shots: return
	# O exemplo tem dois passos: enquadra a recompensa e ambos os destinos.
	var scroll := node("TasksScreen").find_child("Scroll", true, false) as ScrollContainer
	scroll.scroll_vertical += int(node("StoryRewards").global_position.y - scroll.global_position.y)
	await frames()
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/missoes/")
	DirAccess.make_dir_recursive_absolute(folder)
	var file := "antes_%dx%d.png" if before else "depois_%dx%d_" + kind + ".png"
	check(root.get_texture().get_image().save_png(folder + file % [root.size.x, root.size.y]) == OK, "salvar captura")

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	# Fixture de UI: não deixa a virada de desejos/faro reconstruir o cartão entre toques.
	for child: Node in state.get_children():
		if child is Timer: child.stop()
	state.call("reset")
	state.get("progress").seen.intro = true
	Motion.reduced = true
	Input.emulate_mouse_from_touch = true
	root.get_node("Events").world_requested.connect(func(world: String, place: String) -> void: destinations.append(world + ":" + place))
	root.get_node("Events").items_gained.connect(func(_items: Dictionary, _coins: int, _origin: Vector2) -> void: gains += 1)
	for resolution: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = resolution
		await fresh()
		await shot("incompleta")
		if before: continue
		var locked := node("ClaimQuest_first_harvest") as Button
		check(locked != null and locked.disabled and locked.text == "Pegar" and locked.icon == null and locked.find_children("*", "TextureRect", true, false).is_empty(), "Pegar incompleto desabilitado sem ícone")
		check(locked.get_node("Frame").modulate == Color(0.48, 0.48, 0.48, 0.65), "Pegar incompleto apagado/acinzentado")
		var coins: int = state.get("coins")
		await tap(locked)
		check(state.get("coins") == coins and not state.get("progress").claimed_quests.has("first_harvest"), "toque travado não resgata")
		var go_rects: Array[Rect2] = []
		for i in 2:
			main.call("show_screen", &"tasks")
			await frames()
			var step := node("StoryGoal_%d" % i)
			var go := step.find_child("QuestGo_first_harvest" if i == 0 else "GoalGo_1", true, false) as Button
			var count := destinations.size()
			go_rects.append(Rect2(go.global_position - step.global_position, go.size))
			await tap(go)
			check(destinations.size() == count + 1 and destinations.back() == "farm:plots", "passo %d direciona aos canteiros" % i)
			await create_timer(1.4).timeout
			root.get_node("Events").sheet_close_requested.emit()
		state.get("progress").stats.water = 1
		state.call("_changed")
		main.call("show_screen", &"tasks")
		await frames()
		check(node("StepDone_0") != null and node("StoryGoal_0").find_children("*", "Button", true, false).is_empty() and node("QuestGo_first_harvest") != null, "feito mostra check e só pendente mantém Ir")
		await shot("misto")
		await check_done(0, go_rects[0])
		state.get("progress").stats.harvest = 1
		state.call("_changed")
		await frames()
		await shot("completa")
		var claim := node("ClaimQuest_first_harvest") as Button
		check(claim != null and not claim.disabled and claim.icon == null and claim.get_node("Frame").modulate == Color.WHITE and claim.get_node("Frame").texture.resource_path.ends_with("mission_go.png"), "Pegar pronto amarelo sem ícone")
		check(node("StepDone_0") != null and node("StepDone_1") != null and node("GoalGo_1") == null, "todos feitos sem Ir")
		await check_done(0, go_rects[0])
		await check_done(1, go_rects[1])
		var paid := gains
		await tap(claim)
		check(state.get("coins") == coins + 10 and gains == paid + 1 and state.get("progress").claimed_quests.has("first_harvest"), "Pegar paga uma vez")
		check(state.call("claim_quest", "first_harvest") != "" and state.get("coins") == coins + 10 and gains == paid + 1, "segunda entrega recusada")
		# Renderização de uma missão já recebida, ainda que o cartão vivo avance automaticamente.
		clear_modals()
		var box := VBoxContainer.new()
		node("TasksScreen").call("_story_rewards", box, "first_harvest")
		var received := box.find_child("ClaimQuest_first_harvest", true, false) as Button
		check(received != null and received.disabled and received.text == "Resgatado", "estado resgatado")
		box.queue_free()
		await frames()
		print("MISSIONS RESOLUTION PASS: ", resolution)
	print("MISSIONS ACTIONS TEST: ", "FAIL" if failures else "PASS")
	quit(1 if failures else 0)

func check_done(index: int, previous: Rect2) -> void:
	var done := node("StepDone_%d" % index)
	var step := node("StoryGoal_%d" % index)
	var actual := Rect2(done.global_position - step.global_position, done.size)
	check(actual.position.is_equal_approx(previous.position) and actual.size.is_equal_approx(previous.size), "Concluído no mesmo espaço do Ir")
	check(done.find_child("DoneText", true, false).text == "Concluído" and not done.has_node("Frame") and done.find_children("*", "Panel", true, false).is_empty(), "status Concluído plano sem fundo de botão")
	var caption := done.find_child("DoneText", true, false) as Label
	check(absf(caption.get_global_rect().end.x - done.get_global_rect().end.x) < 1.0 and absf(caption.get_global_rect().get_center().y - done.get_global_rect().get_center().y) < 1.0, "status à direita e centralizado verticalmente")
	check(step.get_node("Art/Frame").self_modulate == Color(0.90, 1.0, 0.90), "cartão concluído com tom verde suave")
	check(not done is Button and done.mouse_filter == Control.MOUSE_FILTER_IGNORE and done.focus_mode == Control.FOCUS_NONE and done.find_children("*", "Button", true, false).is_empty(), "status sem toque, ação ou foco")
	var count := destinations.size()
	var paid := gains
	var coins: int = state.get("coins")
	await tap(done)
	check(destinations.size() == count and gains == paid and state.get("coins") == coins and node("TasksScreen").is_visible_in_tree(), "toque no Concluído não navega nem resgata")
