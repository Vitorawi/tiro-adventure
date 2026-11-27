extends SceneTree
## E07: gestos pelo viewport e progressão pelo mesmo GameState que a aula usa.
## Sem --headless, acrescente -- --screenshots para gravar as telas visitadas.

const TRICKS := {"sit": 2, "paw": 4, "lie_down": 5}
var state: Node
var main: Node
var events: Node
var failures := 0
var screenshots := false


func _initialize() -> void:
	screenshots = "--screenshots" in OS.get_cmdline_user_args()
	create_timer(130).timeout.connect(func() -> void: quit(1))
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("TRICK LESSON: " + message)


func pause(seconds: float = 0.18) -> void:
	await create_timer(seconds).timeout


func shot(name: String) -> void:
	if not screenshots:
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/e07_tricks")
	DirAccess.make_dir_recursive_absolute(folder)
	check(image.save_png(folder.path_join("%dx%d_%s.png" % [image.get_width(), image.get_height(), name])) == OK, "captura " + name)


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		var layer: Variant = main.get(member)
		if layer is CanvasLayer:
			layer.hide()
	main.set("_modal_queue", [] as Array[Callable])


func _point(node: Control) -> Vector2:
	return node.get_global_rect().get_center()


func _press(point: Vector2, pressed: bool) -> void:
	var input := InputEventMouseButton.new()
	input.button_index = MOUSE_BUTTON_LEFT
	input.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	input.pressed = pressed
	input.position = point
	input.global_position = point
	root.push_input(input, true)


func _move(point: Vector2, previous: Vector2) -> void:
	var input := InputEventMouseMotion.new()
	input.button_mask = MOUSE_BUTTON_MASK_LEFT
	input.position = point
	input.global_position = point
	input.relative = point - previous
	root.push_input(input, true)


func _tap(point: Vector2) -> void:
	_press(point, true)
	_press(point, false)


func _button(name: String) -> Button:
	for node: Node in main.find_children(name, "Button", true, false):
		if node.is_visible_in_tree():
			return node as Button
	check(false, "botão visível: " + name)
	return null


func _inventory(id: String = "apple_biscuit") -> int:
	return state.get("inventory").count(id)


## Dia do calendário -> capítulo: o Senta é do capítulo 5; Dá a pata e Deita, do 10.
func _chapter(day: int) -> int:
	return 1 if day <= 1 else (5 if day < 4 else 10)


func _advance_day(day: int, hour: int) -> void:
	state.call("dev_week_goto", day)
	state.call("dev_content_day", _chapter(day))
	state.call("dev_week_hour", hour)
	state.call("update_week")


func _row(id: String) -> Dictionary:
	for row: Dictionary in state.call("growth_info").requirements:
		if row.id == id:
			return row
	return {}


func _run() -> void:
	if not screenshots:
		root.size = Vector2i(360, 780)
	state = root.get_node("GameState")
	events = root.get_node("Events")
	var saver := root.get_node("SaveManager")
	events.state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.get("inventory").add("apple_biscuit", 20)
	state.call("dev_week_goto", 1)
	state.call("dev_content_day", 1)
	state.call("dev_week_hour", 12)
	for id: String in TRICKS:
		check(state.call("trick_lesson_error", id) == "Continue a História", "dia de abertura de " + id)
		check(state.call("learn_trick", id) == "Aprenda na Aula do Tiro", "sem atalho pela Nina: " + id)
	# Os ganchos dos truques sao do Dentinhos (F01): com o Filhotinho pronto, a lista que o painel mostra e a dele.
	state.get("growth").phase = "puppy"
	check(_row("tricks").get("done") == false and int(_row("tricks").get("have", 0)) == 0, "Para crescer mostra os truques por aprender")

	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await pause(0.7)
	_hide_modals()
	_advance_day(2, 12)
	var notebook: Script = load("res://scripts/ui/pet_notebook.gd")
	check((notebook.call("tabs") as Array).any(func(tab: Dictionary) -> bool: return tab.id == "tricks"), "o caderninho tem a aba Truques no dia 2")
	main.call("_on_world_requested", "farm", "week_training")
	await pause(1.0)
	_hide_modals()
	var room: Node
	for view: Node in get_nodes_in_group("room_views"):
		if view.get("room_id") == "farm" and view.is_visible_in_tree():
			room = view
	check(room != null, "Sítio visível")
	if room == null:
		quit(1)
		return
	var rug := room.find_child("week_training", true, false) as Sprite2D
	check(rug != null and rug.is_visible_in_tree(), "tapete aberto no dia 2")
	if rug == null:
		quit(1)
		return
	_tap(rug.to_global(rug.get_rect().get_center()))
	await pause(0.55)
	await shot("01_caderno")
	var start := _button("LessonTrain_sit")
	if start == null:
		quit(1)
		return
	var before := _inventory()
	_tap(_point(start))
	await pause()
	var lesson := main.get_node_or_null("TrickLesson")
	if lesson == null:
		check(false, "aula abriu pelo tapete")
		quit(1)
		return
	_tap(_point(_button("LessonExit")))
	await pause(0.4)
	check(_inventory() == before and state.call("trick_lesson_error", "sit") == "", "sair não cobra, conta ou bloqueia")

	for id: String in TRICKS:
		_advance_day(int(TRICKS[id]), 12)
		_hide_modals()
		load("res://scripts/ui/trick_ui.gd").call("open_lessons")
		await _play_through(id)
		check(state.call("trick_level", id) == 1, "Aprendeu com 3 (" + id + ")")
		check(state.call("trick_lesson_error", id) == "", "sem limite por período: só o biscoito segura")
		check(state.call("perform_trick", id) != "", "a Aula é a origem dos acertos do filhote")
		if id == "sit":
			check(int(_row("tricks").get("have", 0)) >= 1, "Senta marca Para crescer")
			if screenshots:
				load("res://scripts/ui/growth_ui.gd").call("open")
				await pause(0.45)
				await shot("09_para_crescer_recem_chegado")
	check(state.get("progress").stat("trick_learned") == 3, "três aprendizados únicos")

	state.call("dev_week_hour", 19)
	_advance_day(5, 19)
	check(state.call("trick_lesson_error", "sit") == "", "a aula segue liberada (comer nunca trava)")
	var cookies := _inventory()
	state.get("inventory").remove("apple_biscuit", cookies)
	state.get("inventory").add("carrot_snack", 1)
	check(state.call("start_trick_lesson", "sit") == "Falta Biscoito ×1", "petisco não substitui biscoito")
	var dishes := load("res://scripts/state/dish_rules.gd")
	var dynamic: String = dishes.call("make_id", "biscoito", ["aveia", "maca"], 2)
	state.get("inventory").add(dynamic, 1)
	check(_complete("sit", 1).get("stars") == 1 and _inventory(dynamic) == 0, "aula de 1 estrela aceita biscoito do Inventar")
	state.get("inventory").add("apple_biscuit", cookies)
	check(_complete("paw", 2).get("stars") == 2 and _inventory() == cookies - 1, "2 estrelas e recarga independente")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	check(state.get("progress").stat("trick:sit") == 4, "os acertos persistem")
	state.call("dev_week_goto", 6)
	state.call("dev_content_day", 10)
	state.call("dev_week_hour", 4)
	state.get("growth").phase = "puppy"
	check(_row("tricks").get("done") == true and _row("sit_good").get("done") == false, "Para crescer lê três aprendidos e aguarda Sabe bem")
	var help := load("res://scripts/ui/task_help.gd")
	var info: Dictionary = help.call("describe", "growth_req", "sit_good")
	check(info.get("target", {}).get("place") == "week_training", "Ir leva ao tapete")

	for day in range(6, 10):
		_advance_day(day, 12)
		for id: String in TRICKS:
			var outcome := _complete(id, 3)
			check(int(outcome.get("stars", 0)) == 3, "prática de " + id)
			if day == 7:
				check(state.call("trick_level", id) == 2, "Sabe bem ao passar de 8")
	for id: String in TRICKS:
		check(state.get("progress").stat("trick:" + id) >= 15 and state.call("trick_level", id) == 3, "Craque pelo treino: " + id)
	check(_row("sit_good").get("done") == true and state.get("progress").stat("trick_learned") == 3, "Sabe bem marca Para crescer; nenhum aprendizado duplica")
	_hide_modals()
	load("res://scripts/ui/growth_ui.gd").call("open")
	await pause(0.45)
	await shot("08_para_crescer")
	print("TRICK LESSON TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


func _play_through(id: String) -> void:
	await pause(0.4)
	var start := _button("LessonTrain_" + id)
	if start == null:
		return
	var before := _inventory()
	_tap(_point(start))
	await pause(0.3)
	var lesson := main.get_node_or_null("TrickLesson")
	check(lesson != null, "abriu " + id)
	if lesson == null:
		return
	var stage := lesson.find_child("LessonStage", true, false) as Control
	for repetition in range(1, 6):
		check(int(lesson.get("repetition")) == repetition and lesson.get("phase") == 0, "Mostrar %s %d/5" % [id, repetition])
		var path: PackedVector2Array = lesson.get("_path")
		if repetition == 1:
			await shot("02_" + id)
		if id == "paw":
			check((path[-1].x < path[0].x) == (repetition % 2 == 1), "pata indicada alterna")
		var wrong := repetition == 2
		await _drag(stage, path, id, wrong, repetition == 1)
		if not is_instance_valid(lesson):
			check(false, "a aula fechou durante o gesto: " + str(state.call("trick_lesson_error", id)))
			return
		check(lesson.get("phase") == 1 and _inventory() == before, "Marcar só depois do gesto; sem cobrar no meio")
		check(str(lesson.get("_feedback").text).begins_with("Quase") == wrong, "gesto aceito ou recusado: %s %d" % [id, repetition])
		if id == "sit" and repetition == 1:
			await shot("05_marcar")
		var mark := _button("LessonMark")
		if mark == null:
			break
		lesson.set("elapsed", 1.0)
		_tap(_point(mark))
		check(lesson.get("phase") == 2, "Premiar vem depois de Isso!")
		if id == "sit" and repetition == 1:
			await shot("06_premiar")
		var reward := _button("LessonReward")
		if reward == null:
			break
		_tap(_point(reward))
		await pause(0.06)
	var result: Dictionary = lesson.get("result")
	check(result.get("stars", 0) == 3 and _inventory() == before - 1, "cinco repetições dão 3 estrelas e cobram um biscoito: " + id)
	await pause(0.35)
	if id == "sit":
		await shot("07_resultado")
	var done := _button("LessonDone")
	if done != null:
		_tap(_point(done))
	await pause(0.35)


func _drag(stage: Control, path: PackedVector2Array, id: String, wrong: bool, touch: bool) -> void:
	var origin := stage.global_position
	var last := origin + path[0]
	_drag_touch(last, true) if touch else _press(last, true)
	for i in range(1, path.size()):
		if id == "lie_down":
			await pause(0.34)
		if wrong and id == "sit" and i != path.size() - 1:
			continue
		var point := origin + path[i]
		if wrong and id == "paw":
			point.x = origin.x + stage.size.x - path[i].x
		if touch:
			var input := InputEventScreenDrag.new()
			input.position = point
			input.relative = point - last
			root.push_input(input, true)
		else:
			_move(point, last)
		last = point
	if id == "lie_down" and not wrong:
		await pause(2.15)
	_drag_touch(last, false) if touch else _press(last, false)
	await process_frame
	await process_frame


func _drag_touch(point: Vector2, pressed: bool) -> void:
	var input := InputEventScreenTouch.new()
	input.position = point
	input.pressed = pressed
	root.push_input(input, true)


func _complete(id: String, stars: int) -> Dictionary:
	check(state.call("start_trick_lesson", id) == "", "iniciar prática " + id)
	check(state.call("trick_lesson_step", id, "reward", 0.1).has("error"), "fora de ordem não avança")
	var result: Dictionary
	for i in 5:
		state.call("trick_lesson_step", id, "show", float(stars > 1))
		state.call("trick_lesson_step", id, "mark", 1.0 if stars == 3 else (1.35 if stars == 2 else 0.0))
		result = state.call("trick_lesson_step", id, "reward", 0.1 if stars == 3 else 3.0)
		check(result.has("stars") == (i == 4), "resultado apenas após 5 repetições")
	check(state.call("trick_lesson_step", id, "reward", 0.1).has("error"), "fim repetido não cobra nem conta")
	return result
