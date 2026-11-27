extends SceneTree
## Capturas de E12 produzidas a partir do percurso de ações reais.

var state: Node
var main: Node
var output: String
var failures := 0


func _initialize() -> void:
	run.call_deferred()


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func snap(id: String, node: Control = null) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	if node:
		var rect := node.get_global_rect()
		var viewport := Rect2(Vector2.ZERO, root.get_visible_rect().size)
		check(node.is_visible_in_tree() and viewport.encloses(rect), id + " deve caber na tela")
	check(root.get_texture().get_image().save_png(output.path_join(id + ".png")) == OK, "Gravar " + id)


func clean() -> void:
	main.get("_modal_queue").clear()
	for id: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		main.get(id).hide()


func read_morning_card() -> void:
	# O save restaurado pode enfileirar Bom dia no frame seguinte.
	await create_timer(0.45).timeout
	var card: Node = main.get("_celebration")
	if card.visible:
		var primary := card.find_child("Primary", true, false) as Button
		if primary and primary.is_visible_in_tree():
			await press(primary)
	await create_timer(0.4).timeout


func press(node: Button) -> void:
	if not is_instance_valid(node):
		return
	var at := node.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var touch := InputEventMouseButton.new()
		touch.button_index = MOUSE_BUTTON_LEFT
		touch.pressed = pressed
		touch.position = at
		touch.global_position = at
		root.push_input(touch, true)
	await process_frame


func press_story_go(id: String) -> void:
	await process_frame
	await process_frame
	var tasks := main.find_child("TasksScreen", true, false)
	var button := tasks.find_child("QuestGo_" + id, true, false) as Button
	check(button != null, "A História tem Ir para " + id)
	if button == null:
		return
	(tasks.get_node("%Scroll") as ScrollContainer).ensure_control_visible(button)
	await process_frame
	await press(tasks.find_child("QuestGo_" + id, true, false) as Button)


func run() -> void:
	var suffix := "%dx%d" % [root.size.x, root.size.y]
	var folder := "e15_historia" if "--e15" in OS.get_cmdline_user_args() else "e12_historia"
	output = ProjectSettings.globalize_path("res://../build/screenshots/" + folder + "/" + suffix)
	DirAccess.make_dir_recursive_absolute(output)
	root.get_node("SaveManager").free()
	state = root.get_node("GameState")
	state.set_script(load("res://tests/helpers/week_story_clock.gd"))
	state.set_clock(1792411200.0)
	state.reset()
	var route: RefCounted = load("res://tests/helpers/week_story_route.gd").new(state, root.get_node("Database"), check)
	route.run()
	state.reset()
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	var intro: Node = main.get("_intro")
	var card := intro.find_child("IntroCard", true, false) as Control
	await snap("01_caixinha", card)
	intro.call("_advance")
	intro.call("_advance")
	await snap("02_focinho", card)
	intro.call("_advance")
	await create_timer(3.0).timeout
	check(state.progress.stat("arrival_box") == 1, "Abertura tocável")
	clean()
	route.restore(route.day_one_story)
	main.call("show_screen", &"tasks")
	main.find_child("TasksScreen", true, false).get("_content").set_meta("tick_refresh", false)
	await read_morning_card()
	var tasks := main.find_child("TasksScreen", true, false)
	var go := tasks.find_child("QuestGo_lais_first_crops", true, false) as Button
	check(go != null, "A primeira horta tem um destino na história")
	if go:
		var scroll := tasks.get_node("%Scroll") as ScrollContainer
		check(scroll.get_global_rect().encloses(go.get_global_rect()), "Ir da primeira horta visível sem rolar")
	await snap("04_historia", go)
	route.restore(route.day_one_wait)
	await read_morning_card()
	await snap("05_espera", main.find_child("WeekWait", true, false))
	route.restore(route.farewell_pending)
	clean()
	var places: Script = load("res://scripts/ui/places.gd")
	var target: Dictionary = places.quest_target("growth_3_teething")
	check(target.get("farewell", false), "Ir do dia 7 aponta ao almoço")
	await press_story_go("growth_3_teething")
	await create_timer(0.45).timeout
	var button_lais := main.find_child("Serve_lais", true, false) as Button
	check(button_lais != null, "O prato da Laís tem ação Servir")
	await snap("06_almoco", button_lais)
	await press(button_lais)
	var button_tiro := main.find_child("Serve_tiro", true, false) as Button
	check(button_tiro != null, "A mesa atualiza depois de servir")
	if button_tiro:
		await press(button_tiro)
	check(state.week_farewell_complete() and state.album.has_photo("h_week_group"), "Servir por toque registra a foto")
	await create_timer(0.45).timeout
	await snap("07_foto_grupo")
	root.get_node("Events").sheet_close_requested.emit()
	route.restore(route.village_bridge)
	clean()
	await create_timer(0.4).timeout
	await snap("08_historia_vila", main.find_child("StoryCard", true, false))
	await press_story_go("lais_village")
	await create_timer(0.45).timeout
	check(state.progress.stat("open:village") == 1 and state.quest_error("lais_village") == "", "Ir abre a Vila e cumpre a primeira missão")
	await snap("09_vila")
	print("WEEK STORY SHOTS ", suffix, " · ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
