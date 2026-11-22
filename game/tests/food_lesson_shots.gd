extends SceneTree
## Capturas da lição do crescimento e da aula da comida (Novo fluxo, F02 Parte B). NÃO é teste.
## Rodar SEM --headless, uma vez por resolução:
##   godot --path game --resolution 360x780 -s res://tests/food_lesson_shots.gd
## PNGs em build/screenshots/food_lesson/. Imprime FAIL se o balão ou a folha passarem da tela, se o balão cobrir o alvo
## ou se um botão ficar abaixo de 44 px.
const FOLDER := "res://../build/screenshots/food_lesson/"
var state: Node
var db: Node
var main: Control
var failures := 0


func _initialize() -> void:
	_run.call_deferred()
	create_timer(240).timeout.connect(func() -> void:
		print("tempo esgotado")
		quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL: ", message)


func node(node_name: String) -> Control:
	return main.find_child(node_name, true, false) as Control


func guide() -> Node:
	return main.find_child("LessonGuide", true, false)


func _save(shot_name: String) -> void:
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(FOLDER)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "%s_%dx%d.png" % [shot_name, image.get_width(), image.get_height()])


func _at(day: int, hour: int) -> void:
	state.call("dev_week_goto", day)
	state.call("dev_week_hour", hour)
	state.call("update_week")


## O balão da lição cabe na tela e não cobre o alvo; os botões têm alvo de toque.
func _lesson_ok(label: String) -> void:
	var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var g := guide()
	_check(g.visible, label + ": lição visível")
	var balloon := g.find_child("TutorialBalloon", true, false) as Control
	_check(balloon != null and screen.encloses(balloon.get_global_rect()), label + ": balão fora da tela " + str(balloon.get_global_rect()))
	var target: Rect2 = g.get("_target")
	_check(target.has_area() and not balloon.get_global_rect().intersects(target.grow(-2.0)), label + ": o balão cobre o alvo")
	for button: Node in balloon.find_children("*", "Button", true, false):
		if (button as Control).is_visible_in_tree():
			_check((button as Control).size.y >= 44.0 and (button as Control).size.x >= 44.0, label + ": botão pequeno " + str(button.name))


func _sheet_ok(label: String) -> void:
	var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var panel := main.get_node("Sheet").get_node("%Panel") as Control
	_check(screen.encloses(panel.get_global_rect()), label + ": folha fora da tela")
	for button: Node in panel.find_children("*", "Button", true, false):
		var control := button as Control
		if control.is_visible_in_tree() and control.size.y > 0.0 and not String(control.name).begins_with("NotebookTab"):
			_check(control.size.y >= 40.0, label + ": botão baixo " + str(control.name))


func _card_ok(label: String) -> void:
	var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	for card_name: String in ["WeekNight", "WeekMorning"]:
		var card := node(card_name)
		if card != null and card.is_visible_in_tree():
			_check(screen.encloses(card.get_global_rect()), label + ": cartão fora da tela " + str(card.get_global_rect()))


func _fresh(hour: int, with_meal: bool, phase: String = "puppy") -> void:
	if main != null:
		main.queue_free()
		main = null
		await process_frame
		await process_frame
	state.call("reset")
	state.call("finish_week_arrival")
	state.call("finish_home_tour")
	state.week.arrival_extended = false
	state.week.tutorial["arrival"] = {"done": true}
	state.growth.phase = phase
	db.week_story.food_lesson["quest"] = str(state.progress.current_main_quest())
	_at(1, hour)
	if with_meal:
		state.inventory.add("puppy_mash", 1)
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(1.2).timeout


func _hide_cards() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var layer: Variant = main.get(member)
		if layer is CanvasLayer:
			(layer as CanvasLayer).hide()


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", str(load("res://scripts/util/build_info.gd").call("data_dir")) + "food_lesson_shots_descartavel.json")
	state = root.get_node("GameState")
	db = root.get_node("Database")
	load("res://scripts/ui/motion.gd").set("reduced", true)
	var events: Node = root.get_node("Events")
	var original: String = str(db.week_story.food_lesson.quest)

	# --- Aula da comida, ao meio-dia (dentro da janela) ---
	await _fresh(12, true)
	_lesson_ok("toque 1")
	await _save("a_reloginho")
	(node("LessonNext") as Button).pressed.emit()
	await create_timer(0.9).timeout
	_lesson_ok("toque 2")
	_sheet_ok("toque 2")
	await _save("b_hoje")
	(node("LessonNext") as Button).pressed.emit()
	await create_timer(1.0).timeout
	_lesson_ok("toque 3")
	await _save("c_arrastar")
	state.feed("puppy_mash")
	await create_timer(0.7).timeout
	_lesson_ok("toque 4")
	await _save("d_patinha")
	(node("LessonNext") as Button).pressed.emit()
	await create_timer(1.0).timeout
	_lesson_ok("toque 5")
	_sheet_ok("toque 5")
	await _save("e_crescer_patinhas")
	(node("LessonNext") as Button).pressed.emit()
	await create_timer(0.6).timeout
	events.sheet_close_requested.emit()
	await create_timer(0.5).timeout
	await _save("f_depois_da_aula")

	# --- Faixas fora da janela: dia e noite (só as falas 2 e 4 mudam) ---
	await _fresh(9, true)
	(node("LessonNext") as Button).pressed.emit()
	await create_timer(0.9).timeout
	_lesson_ok("dia, toque 2")
	await _save("g_dia_toque2")
	(node("LessonNext") as Button).pressed.emit()
	await create_timer(0.9).timeout
	state.feed("puppy_mash")
	await create_timer(0.7).timeout
	_lesson_ok("dia, toque 4")
	await _save("h_dia_toque4")
	await _fresh(23, true)
	(node("LessonNext") as Button).pressed.emit()
	await create_timer(0.9).timeout
	(node("LessonNext") as Button).pressed.emit()
	await create_timer(0.9).timeout
	state.feed("puppy_mash")
	await create_timer(0.7).timeout
	_lesson_ok("noite, toque 4")
	await _save("i_noite_toque4")

	# --- Lição do painel de crescimento ---
	await _fresh(10, false, "newborn")
	for id: String in ["welcome", "lais_feed", "lais_bath", "lais_play", "lais_bed"]:
		state.progress.claimed_quests[id] = true
	db.week_story.food_lesson["quest"] = "lais_photo"
	load("res://scripts/ui/growth_ui.gd").call("open")
	await create_timer(0.9).timeout
	_lesson_ok("painel 1")
	await _save("j_painel_1")
	(node("LessonNext") as Button).pressed.emit()
	await create_timer(0.4).timeout
	_lesson_ok("painel 2")
	await _save("k_painel_2")
	(node("LessonNext") as Button).pressed.emit()
	await create_timer(0.4).timeout
	_lesson_ok("painel 3")
	await _save("l_painel_3")

	# --- Boa noite do dia 1 e Bom dia do dia 2 ---
	await _fresh(15, true)
	db.week_story.food_lesson["quest"] = "lais_photo"
	state.week.food_lesson = true
	state.progress.claimed_quests["lais_photo"] = true
	state.grant_lesson_paw("puppy_mash")
	state.inventory.add("puppy_mash", 2)
	_hide_cards()
	main.set("_modal_queue", [] as Array[Callable])
	_at(1, 23)
	var night: Dictionary = state.take_week_card(state.week_card_candidates().filter(func(c: Dictionary) -> bool: return c.kind == "night")[0])
	main.get("_celebration").call("show_week_card", night)
	await create_timer(0.7).timeout
	_card_ok("Boa noite")
	await _save("m_boa_noite_dia1")
	var scroll := node("WeekCardBody") as ScrollContainer
	if scroll != null:
		scroll.scroll_vertical = 9999
		await create_timer(0.3).timeout
		await _save("n_boa_noite_dia1_fim")
	main.get("_celebration").hide()
	_at(2, 9)
	var morning: Dictionary = state.take_week_card(state.week_card_candidates().filter(func(c: Dictionary) -> bool: return c.kind == "morning")[0])
	main.get("_celebration").call("show_week_card", morning)
	await create_timer(0.7).timeout
	_card_ok("Bom dia")
	await _save("o_bom_dia_dia2")
	main.get("_celebration").hide()
	state.week.stored.clear()
	state.week.served.append({"period": "lunch", "item": "puppy_mash", "day": 1, "hour": 11, "minute": 12, "seen": false})
	var morning2 := {"kind": "morning", "day": 2, "civil": 0, "news": db.week_routine.news[1], "weak": true, "still_weak": true, "yesterday": {}, "offer": false, "gift": false,
		"first_day": true, "before_lunch": false, "served": state.served_notes()}
	main.get("_celebration").call("show_week_card", morning2)
	await create_timer(0.7).timeout
	_card_ok("Bom dia fraco")
	await _save("p_bom_dia_fraco_recado")
	main.get("_celebration").hide()

	# --- Folha Hoje, "?", cartela, fome ---
	_at(2, 9)
	load("res://scripts/ui/meal_ui.gd").call("open_today")
	await create_timer(0.8).timeout
	_sheet_ok("Hoje")
	await _save("q_hoje_completo")
	(node("MealHelp") as Button).pressed.emit()
	await create_timer(0.8).timeout
	_sheet_ok("revisão")
	await _save("r_revisao")
	events.sheet_close_requested.emit()
	await create_timer(0.4).timeout
	state.week.days["2"] = {"paw": true, "lunch": {"on_time": true, "item": "puppy_mash"}, "dinner": {"on_time": true, "item": "puppy_mash"}}
	state.week.days["3"] = {"weak": true}
	state.week.days["4"] = {"paw": true, "dinner": {"on_time": true, "item": "puppy_mash"}}
	load("res://scripts/ui/growth_ui.gd").call("open", "days")
	await create_timer(0.8).timeout
	_sheet_ok("linha das patinhas")
	await _save("s_linha_das_patinhas")
	events.sheet_close_requested.emit()
	await create_timer(0.4).timeout
	state.week.days.erase("2")
	state.week.days.erase("3")
	state.week.days.erase("4")
	main.call("show_screen", &"pet")
	_at(2, 12)
	await create_timer(0.8).timeout
	await _save("t_fome")
	db.week_story.food_lesson["quest"] = original
	print("FOOD LESSON SHOTS: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
