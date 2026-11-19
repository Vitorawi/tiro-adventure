extends SceneTree
## Percurso da rotina com calendário DEV, ações reais e o arquivo do SaveManager.

var state: Node
var route: RefCounted
var main: Node
var saver: Node
var failures := 0
var output := ""


func _initialize() -> void:
	run.call_deferred()


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("E13 · " + message)


func wait_for(id: String, required: bool = true) -> Node:
	for i in 70:
		var child := main.find_child(id, true, false) as CanvasItem
		if is_instance_valid(child) and child.is_visible_in_tree():
			return child
		if id in ["WeekMorning", "WeekNight"] and card("UnlockGo") != null:
			dismiss()
		await create_timer(0.06).timeout
	if required:
		check(false, id + " deveria estar visível")
	return null


func card(id: String) -> Node:
	var node: Node = main.get("_celebration").find_child(id, true, false)
	return node if main.get("_celebration").visible else null


func start_main() -> void:
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func reopen() -> void:
	check(saver.save_game(), "Gravar arquivo de save")
	if is_instance_valid(main):
		main.queue_free()
		await process_frame
	saver.load_game()
	saver.last_saved_at = state.now()
	start_main()


func dismiss() -> void:
	main.get("_celebration").hide()


func snap(name: String) -> void:
	if output == "":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK, "Captura " + name)


func complete_activity() -> void:
	var rows: Array = state.week_daily_rows()
	if rows.size() != 3 or rows[2].done:
		return
	match str(rows[2].id):
		"play":
			route.ball()
			route.ball()
		"harvest":
			for i in 3:
				route.make_space({"carrot": 3})
				route.ok(state.plant(0, "carrot"), "Plantar para a diária")
				state.advance_clock(state.crop_seconds(0, "carrot") + 1.0)
				check(state.harvest(0).has("carrot"), "Colher para a diária")
		"new_dish":
			route.serve(route.dish("papinha", {"potato": 2}))
		"eggs":
			route.eggs(state.inventory.count("egg") + 1)
		"fish":
			route.catch_fish()


func check_board() -> void:
	main.call("show_screen", &"tasks")
	var board := main.find_child("TasksScreen", true, false)
	check(await wait_for("WeekToday") != null, "Hoje aparece junto da História")
	check(board.find_children("WeekLineStep", "", true, false).size() == 1, "Missões tem um único Próximo passo das linhas")
	check(board.find_child("WeekDailySeal", true, false) != null, "Missões mostra selo das diárias")
	await snap("04_missoes")
	var events := root.get_node("Events")
	events.sheet_requested.emit("Caderninho", load("res://scripts/ui/pet_notebook.gd").panel("missions"))
	var selection := await wait_for("NotebookLine_clock") as Button
	check(main.find_child("NotebookLine_grandma", true, false) != null and main.find_child("NotebookLine_friends", true, false) != null,
		"Três linhas no Caderninho")
	if selection:
		await create_timer(0.45).timeout
		selection = main.find_child("NotebookLine_clock", true, false) as Button
		selection.pressed.emit()
	var go := await wait_for("WeekGo_Line_lunches") as Button
	check(main.find_child("WeekLine_full_week", true, false) != null, "Linha contém passos futuros")
	await snap("05_caderninho")
	if go:
		go.pressed.emit()
	check(await wait_for("TodayPanel") != null, "Ir da linha usa a folha Hoje")
	events.sheet_close_requested.emit()
	var places := load("res://scripts/ui/places.gd")
	var reached := {}
	var inspect := func(world: String, place: String) -> void: reached[world] = place
	events.world_requested.connect(inspect)
	var fish: Dictionary = root.get_node("Database").week_routine.daily.fish
	places.go(fish.go)
	check(reached.get("farm") == "fishing", "Ir de pescaria vai à lagoa")
	var invent: Dictionary = state.week_line_rows("grandma")[0]
	places.go(invent.go)
	check(reached.get("house") == "cookbook:invent", "Ir do Caderno da vovó vai ao fogão")
	events.world_requested.disconnect(inspect)
	var screens: Array[StringName] = []
	var inspect_screen := func(screen: StringName) -> void: screens.append(screen)
	events.screen_requested.connect(inspect_screen)
	var pet_step: Dictionary = state.week_line_rows("friends")[0]
	places.go(pet_step.go)
	check(&"pet" in screens, "Ir de Melhores amigos volta ao Tiro para o carinho")
	events.screen_requested.disconnect(inspect_screen)


func run() -> void:
	saver = root.get_node("SaveManager")
	check(OS.has_environment("TIRO_TEST_TAG"), "Teste usa um perfil isolado")
	if not OS.has_environment("TIRO_TEST_TAG"):
		quit(1)
		return
	state = root.get_node("GameState")
	state.set_script(load("res://tests/helpers/week_story_clock.gd"))
	state.set_clock(1792411200.0)
	state.reset()
	Motion.reduced = true
	if "--screenshots" in OS.get_cmdline_user_args():
		output = ProjectSettings.globalize_path("res://../build/screenshots/e13_rotina/%dx%d" % [root.size.x, root.size.y])
		DirAccess.make_dir_recursive_absolute(output)
	var db := root.get_node("Database")
	route = load("res://tests/helpers/week_story_route.gd").new(state, db, check)
	check(not state.week_meal_reminder_enabled() and state.week_card_candidates().is_empty(), "Aviso desligado e chegada vem primeiro")
	route.day_one(false)
	check(state.economy.granted.has("week_line:invention") and state.economy.granted.has("week_line:paw"),
		"Inventar e servir contam nas linhas")
	route.at(1, 9)
	state.pet()
	route.at(1, 14)
	state.pet()
	route.at(1, 19)
	state.pet()
	check(state.album.has_photo("h_routine_belly"), "Carinho em três períodos rende foto")
	state.update_week()
	var day_one: Array = state.week_daily_rows()
	check(day_one.size() == 3 and day_one[2].id in ["play", "harvest"], "Diária sorteada entre atividades já abertas")
	check(not state.routines_unlocked("weekly"), "Semanais fechadas em Recém-chegado")
	route.day_two()
	check(state.week_daily_rows().size() == 3, "Duas refeições e atividade no dia 2")
	var selected: String = str(state.week_daily_rows()[2].id)
	check(selected != "fish" and state.economy.granted.has("week_morning:2"), "Pesca ainda fechada e recibo de 30 moedas emitido")
	complete_activity()
	route.at(2, 23)
	state.update_week()
	var civil: int = state.week_day_number()
	check(state.economy.granted.has("week_daily_seal:%d" % civil), "As três diárias entregam o selo")
	check(state.economy.granted.has("week_daily:%d:%s" % [civil, selected]), "Recibo único da atividade")
	check(state.economy.granted.has("week_line:streak") and state.inventory.count("week_lunchbox") == 1,
		"Duas patinhas seguidas rendem marmita de reserva")
	saver.last_saved_at = state.now()
	start_main()
	check(await wait_for("CloseCeremony") != null, "A cerimônia de Filhotinho chega primeiro")
	check(card("WeekMorning") == null and card("WeekNight") == null, "Cartões da rotina esperam a cerimônia")
	main.get("_growth_ceremony").call("_close")
	check(await wait_for("WeekMorning") != null, "Bom dia após a cerimônia")
	check(state.progress.seen.has("week_morning:2"), "Presente aparece no Bom dia do dia 2")
	await snap("01_bom_dia")
	dismiss()
	check(await wait_for("WeekNight") != null, "Boa noite após Bom dia")
	check(main.find_child("WeekTomorrowShadow", true, false) != null and main.find_child("WeekNightPaw", true, false) != null,
		"Boa noite mostra patinha e silhueta")
	await snap("03_boa_noite")
	dismiss()
	await check_board()
	var balance: int = state.coins
	await reopen()
	await create_timer(0.45).timeout
	check(card("WeekMorning") == null and card("WeekNight") == null and state.week_card_candidates().is_empty(), "Cartões vistos sobrevivem à reabertura")
	check(str(state.week_daily_rows()[2].id) == selected and state.coins == balance, "Sorteio e moedas preservados")
	main.queue_free()
	await process_frame

	route.at(4, 9)
	await reopen()
	check(await wait_for("WeekMorning") != null, "Retorno após faltar abre o Bom dia atual")
	check(state.tiro_weak() and state.progress.chapter_index() == 3 and state.quest_unlocked("week_bridge"),
		"Dia fraco preserva o capítulo atrasado")
	check(state.week_meal_reminder_offered() and not state.week_meal_reminder_enabled(), "Primeiro dia fraco oferece opção desligada")
	await snap("02_bom_dia_fraco")
	dismiss()
	var stored := "week_lunchbox"
	route.ok(state.store_meal(stored), "Deixar a marmita pronta")
	state.set_week_meal_reminder(true)
	main.queue_free()
	await process_frame
	route.at(4, 11)
	await reopen()
	check(state.meals_on_time(4) == 1 and not state.tiro_weak(), "Marmita conta na hora e recupera o Tiro na reabertura")
	check(state.take_week_meal_reminder() == "", "Refeição guardada já servida dispensa aviso")
	main.queue_free()
	await process_frame
	route.at(4, 19)
	state.update_week()
	check(state.take_week_meal_reminder() == "dinner" and state.take_week_meal_reminder() == "", "Aviso no máximo uma vez na janela")
	route.at(5, 9)
	state.update_week()
	var morning: Dictionary = state.take_week_card(state.week_card_candidates()[0])
	check(morning.weak and not morning.offer and state.week_meal_reminder_enabled(), "Outro dia fraco conserva a opção sem repetir oferta")
	route.restore(route.after_day_two)
	route.lake(3)
	route.day_four()
	route.day_five()
	route.day_six()
	route.day_seven()
	check(state.growth.phase == "teething" and state.routines_unlocked("weekly"), "Dentinhos libera semanais com a Vila")
	await process_frame
	print("WEEK ROUTINE TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures else 0)
