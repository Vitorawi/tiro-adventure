extends SceneTree
## Capturas da lição do crescimento e da aula da comida (Novo fluxo, F02 Parte B). NÃO é teste.
## Rodar SEM --headless, uma vez por resolução:
##   godot --path game --resolution 360x780 -s res://tests/food_lesson_shots.gd
## PNGs em build/screenshots/food_lesson/. Imprime FAIL se o balão ou a folha passarem da tela, se o balão cobrir o alvo
## ou se um botão ficar abaixo de 44 px.
const FOLDER := "res://../build/screenshots/meal_dia_noite/"
var state: Node
var db: Node
var main: Control
var failures := 0


func _initialize() -> void:
	_run.call_deferred()
	create_timer(560).timeout.connect(func() -> void:
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
	state.week.tutorial["arrival"] = {"done": true}
	state.growth.phase = phase
	db.week_story.food_lesson["quest"] = str(state.progress.current_main_quest())
	_at(1 if hour >= 6 else 2, hour)
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

	# --- Aula da comida em 3 toques: de dia (10h), de noite (22h) e de madrugada (3h, ainda a lua) ---
	for row: Array in [[10, "dia"], [22, "noite"], [3, "madrugada"]]:
		var tag: String = row[1]
		await _fresh(int(row[0]), true)
		_lesson_ok(tag + " toque 1")
		_check(state.dog.get_need("hunger", state.now()) <= 25.0, tag + ": o Tiro começa com fome")
		await _save("tutorial_aula_%s_1_arrastar" % tag)
		state.feed("puppy_mash")
		await create_timer(0.9).timeout
		_lesson_ok(tag + " toque 2")
		await _save("tutorial_aula_%s_2_patinha" % tag)
		(node("LessonNext") as Button).pressed.emit()
		await create_timer(1.0).timeout
		_lesson_ok(tag + " toque 3")
		_sheet_ok(tag + " toque 3")
		await _save("tutorial_aula_%s_3_crescer_patinhas" % tag)
		(node("LessonNext") as Button).pressed.emit()
		await create_timer(0.6).timeout
		events.sheet_close_requested.emit()
		await create_timer(0.5).timeout

	# --- Depois da aula: mão no potinho (meal_day), tigela (bowl), sobremesa e o Manual ---
	await _fresh(12, true)
	for lesson: Dictionary in db.week_tutorials:
		if str(lesson.id) not in ["meal_day", "bowl"]:
			state.week.tutorial[str(lesson.id)] = {"done": true}
	state.finish_food_lesson()
	state.progress.claimed_quests["first_meal"] = true  # as duas lições ficam presas ao passo da aula (`after_quest`)
	state.inventory.add("puppy_mash", 4)
	await create_timer(1.8).timeout
	var hand := main.find_child("WeekTutorial", true, false)
	_check(hand != null and hand.visible and str(hand.get("active")) == "meal_day", "lição do potinho visível")
	await _save("tutorial_potinho_mao")
	(node("MealDay") as Button).pressed.emit()
	await create_timer(0.9).timeout
	_sheet_ok("Hoje (lição)")
	await _save("tutorial_potinho_hoje")
	events.sheet_close_requested.emit()
	await create_timer(0.4).timeout
	state.feed("puppy_mash")
	state.feed("puppy_mash")
	await create_timer(1.0).timeout
	await _save("tutorial_sobremesa_aviso")
	_hide_cards()
	main.set("_modal_queue", [] as Array[Callable])
	var tray: Node = null
	for found in main.find_children("*", "Control", true, false):
		if found.has_method("open_food_menu"):
			tray = found
			break
	tray.call("_act", "puppy_mash")
	await create_timer(1.6).timeout
	_check(hand.visible and str(hand.get("active")) == "bowl", "lição da tigela visível")
	await _save("tutorial_tigela_mao")
	events.sheet_close_requested.emit()
	await create_timer(0.4).timeout
	load("res://scripts/ui/game_manual.gd").call("open", "tutorials")
	await create_timer(0.9).timeout
	await _save("tutorial_manual_lista")
	var review := node("TutorialReview_food")
	if review != null:
		(review as Button).pressed.emit()
		await create_timer(0.7).timeout
		await _save("tutorial_manual_comida")
	events.sheet_close_requested.emit()

	# --- Lição do painel de crescimento ---
	await _fresh(10, false, "newborn")
	db.week_story.food_lesson["quest"] = "lais_photo"
	for id: String in ["welcome", "lais_feed", "lais_bath", "lais_play", "lais_bed", "lais_photo", "lais_farm", "lais_meet_bloblo", "lais_first_crops", "place_stove", "first_kitchen", "first_meal"]:
		state.progress.claimed_quests[id] = true
	for counter: String in ["feed", "bathe", "play", "together:puppy_mash"]:
		state.progress.stats[counter] = 1
	state.progress.owned["dog_bed"] = true
	for seen: String in ["missions", "home_tour", "home_claim", "food"]:
		state.week.tutorial[seen] = {"done": true}
	state.mark_seen(state.new_unlocks())
	load("res://scripts/ui/growth_ui.gd").call("open")
	await create_timer(0.9).timeout
	_lesson_ok("painel 1")
	await _save("painel_1")
	(node("LessonNext") as Button).pressed.emit()
	await create_timer(0.4).timeout
	_lesson_ok("painel 2")
	await _save("painel_2")
	(node("LessonNext") as Button).pressed.emit()
	await create_timer(0.4).timeout
	_lesson_ok("painel 3")
	await _save("painel_3")

	# --- Boa noite do dia 1 e Bom dia do dia 2 ---
	await _fresh(15, true)
	db.week_story.food_lesson["quest"] = "lais_photo"
	state.week.food_lesson = true
	state.progress.claimed_quests["lais_photo"] = true
	state.progress.claimed_quests["lais_bed"] = true
	state.grant_lesson_paw("puppy_mash")
	state.inventory.add("puppy_mash", 2)
	_hide_cards()
	main.set("_modal_queue", [] as Array[Callable])
	_at(1, 23)
	var night: Dictionary = state.take_week_card(state.week_card_candidates().filter(func(c: Dictionary) -> bool: return c.kind == "night")[0])
	main.get("_celebration").call("show_week_card", night)
	await create_timer(0.7).timeout
	_card_ok("Boa noite")
	await _save("boa_noite_dia1")
	var scroll := node("WeekCardBody") as ScrollContainer
	if scroll != null:
		scroll.scroll_vertical = 9999
		await create_timer(0.3).timeout
		await _save("boa_noite_dia1_fim")
	main.get("_celebration").hide()
	_at(2, 9)
	var morning: Dictionary = state.take_week_card(state.week_card_candidates().filter(func(c: Dictionary) -> bool: return c.kind == "morning")[0])
	main.get("_celebration").call("show_week_card", morning)
	await create_timer(0.7).timeout
	_card_ok("Bom dia")
	await _save("bom_dia_dia2")
	main.get("_celebration").hide()
	state.week.stored.clear()
	state.week.served.append({"period": "moon", "item": "puppy_mash", "day": 1, "hour": 16, "minute": 0, "seen": false})
	var morning2 := {"kind": "morning", "day": 2, "civil": 0, "news": db.week_routine.news[1], "missed": true, "yesterday": {"sun": {"on_time": true, "item": "puppy_mash"}, "missed": true}, "gift": false,
		"first_day": true, "before_lunch": false, "served": state.served_notes()}
	main.get("_celebration").call("show_week_card", morning2)
	await create_timer(0.7).timeout
	_card_ok("Bom dia fraco")
	await _save("bom_dia_sem_patinha_recado")
	main.get("_celebration").hide()
	var morning3 := {"kind": "morning", "day": 3, "civil": 0, "news": db.week_routine.news[2], "missed": false,
		"yesterday": {"paw": true, "sun": {"on_time": true, "item": "puppy_mash"}, "moon": {"on_time": true, "item": "puppy_mash", "stored": true}}, "gift": false,
		"first_day": false, "before_lunch": false, "served": state.served_notes()}
	main.get("_celebration").call("show_week_card", morning3)
	await create_timer(0.7).timeout
	_card_ok("Bom dia com patinha")
	await _save("bom_dia_com_patinha_recado")
	main.get("_celebration").hide()
	var night3 := {"kind": "night", "day": 3, "civil": 0, "news": db.week_routine.news[2], "next": db.week_routine.news[3], "arrival": false, "first_night": false,
		"deal": {}, "store_offer": false, "paw_total": 2, "meals": {"paw": true, "sun": {"on_time": true}, "moon": {"on_time": true}},
		"dish": "puppy_mash", "done": 3, "seal": true}
	main.get("_celebration").call("show_week_card", night3)
	await create_timer(0.7).timeout
	_card_ok("Boa noite comum")
	await _save("boa_noite_comum")
	main.get("_celebration").hide()

	# --- Folha Hoje, "?", cartela, fome ---
	_at(2, 9)
	load("res://scripts/ui/meal_ui.gd").call("open_today")
	await create_timer(0.8).timeout
	_sheet_ok("Hoje")
	await _save("hoje_dia2")
	(node("MealHelp") as Button).pressed.emit()
	await create_timer(0.8).timeout
	_sheet_ok("revisão")
	await _save("revisao")
	events.sheet_close_requested.emit()
	await create_timer(0.4).timeout
	state.week.days["2"] = {"paw": true, "sun": {"on_time": true, "item": "puppy_mash"}, "moon": {"on_time": true, "item": "puppy_mash"}}
	state.week.days["3"] = {"missed": true}
	state.week.days["4"] = {"paw": true, "moon": {"on_time": true, "item": "puppy_mash"}}
	load("res://scripts/ui/growth_ui.gd").call("open", "days")
	await create_timer(0.8).timeout
	_sheet_ok("linha das patinhas")
	await _save("linha_das_patinhas")
	events.sheet_close_requested.emit()
	await create_timer(0.4).timeout
	state.week.days.erase("2")
	state.week.days.erase("3")
	state.week.days.erase("4")
	main.call("show_screen", &"pet")
	_at(2, 12)
	await create_timer(0.8).timeout
	await _save("tiro_fome")
	db.week_story.food_lesson["quest"] = original
	print("FOOD LESSON SHOTS: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
