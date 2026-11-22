extends SceneTree
## Capturas do Ato 3 (novo fluxo, F04 Parte B). NÃO é teste.
## Rodar SEM --headless: & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/ato3_shots.gd
## PNGs em build/screenshots/ato3/: início de cada capítulo 2 a 11 (pílula do próximo passo + mão da lição), carta de
## fechamento de dois capítulos, Sítio com as placas "Em breve", seletor de mundos, desafio do dia e Manual por capítulo.

const FOLDER := "res://../build/screenshots/ato3/"
var main: Control
var state: Node
var db: Node
var failures := 0


func _initialize() -> void:
	_run.call_deferred()
	create_timer(420).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL: ", message)


func _wait(seconds: float = 0.6) -> void:
	await create_timer(seconds).timeout


func _save(shot_name: String) -> void:
	await _wait(0.9)
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(FOLDER)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "ato3_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _node(node_name: String) -> Control:
	return main.find_child(node_name, true, false) as Control


func _clear_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var modal: Variant = main.get(member)
		if modal is CanvasLayer:
			(modal as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	main.set("_quest_rewards", [] as Array[Dictionary])


## Conclui os passos principais dos capítulos anteriores (`dev_complete_quest`) e abre o capítulo.
func _to_chapter(chapter: int) -> void:
	for c in range(1, chapter):
		for id: String in state.progress.main_quests(c):
			if not state.progress.claimed_quests.has(id):
				state.dev_complete_quest(id)
	state.dev_content_day(chapter)
	state.growth.phase = "puppy"
	# Lições dos capítulos anteriores já foram vistas: a mão que aparece é a do capítulo.
	for lesson: Dictionary in db.week_tutorials:
		if int(lesson.day) < chapter and not state.week.tutorial.has(str(lesson.id)):
			state.week.tutorial[str(lesson.id)] = {"done": true}


func _guide() -> String:
	var guide := _node("WeekTutorial")
	if guide != null and guide.visible:
		var rect: Rect2 = guide.get("_anchor_rect")
		var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
		_check(screen.encloses(rect), "alvo da lição %s dentro da tela: %s" % [str(guide.get("active")), str(rect)])
		return str(guide.get("active"))
	return ""


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", str(load("res://scripts/util/build_info.gd").call("data_dir")) + "ato3_shots_descartavel.json")
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/helpers/week_story_clock.gd"))
	state.call("set_clock", 1792411200.0)
	state.call("reset")
	state.call("_count", "arrival_box")
	state.call("finish_week_arrival")
	state.get("week").tutorial["arrival"] = {"done": true}
	Motion.reduced = true
	state.progress.seen["intro"] = true
	state.call("finish_fishing_tutorial")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await _wait(1.5)
	_clear_modals()

	# Início de cada capítulo: a pílula do próximo passo e (se houver) a mão da lição do passo.
	for chapter in range(2, 12):
		_to_chapter(chapter)
		main.call("show_screen", &"pet")
		await _wait(1.2)
		_clear_modals()
		await _save("cap%02d_inicio" % chapter)
		print("  capítulo %d: passo %s, lição ativa %s" % [chapter, state.progress.displayed_main_quest(), _guide()])

	# Sítio no capítulo 2 e 3: placas "Em breve" só no capítulo anterior ao da área.
	for chapter in [2, 3, 5, 6]:
		_to_chapter(chapter)
		root.get_node("Events").world_requested.emit("farm", "")
		await _wait(1.6)
		_clear_modals()
		await _save("sitio_cap%02d" % chapter)
		var area := {3: "chicken_coop", 5: "lake", 6: "orchard"}.get(chapter, "") as String
		if area != "":
			# Leva a câmera até a placa "Em breve" da área que abre no capítulo seguinte.
			var room := _node("World_farm")
			for region: Dictionary in room.get("_room").regions:
				if str(region.id) == area:
					var plaque: Array = region.plaque
					room.call("scroll_by", (room.call("world_to_screen", Vector2(plaque[0], plaque[1])) as Vector2) - room.size / 2.0)
			await _save("sitio_cap%02d_placa" % chapter)
		var plaque_count := 0
		for board: Node in main.find_children("PlaqueBoard", "Control", true, false):
			if (board as Control).is_visible_in_tree():
				plaque_count += 1
		print("  Sítio no capítulo %d: %d placa(s) visível(is)" % [chapter, plaque_count])
		_check(plaque_count == (1 if chapter in [3, 5, 6] else 0), "placas visíveis no capítulo %d: %d" % [chapter, plaque_count])

	# Seletor de mundos até o Dentinhos: mundos abertos e só a Vila trancada.
	_to_chapter(4)
	main.call("show_screen", &"map")
	await _wait(1.0)
	_node("WorldsScreen").call("show_map")
	await _wait(1.0)
	await _save("seletor_ate_dentinhos")
	var shown := 0
	for card: Node in main.find_children("*", "Button", true, false):
		if card.get_script() != null and card.get("world_id") != null and (card as Control).is_visible_in_tree():
			shown += 1
	print("  seletor: %d mundos visíveis" % shown)
	_check(shown == 3, "seletor mostra Casa, Sítio e a Vila trancada")
	_node("WorldsScreen").call("close_map")

	# Carta de fechamento de dois capítulos (sopinha e a lagoa).
	for entry: Array in [[2, "h_week_soup"], [6, "h_week_fish"]]:
		_to_chapter(entry[0])
		for id: String in state.progress.main_quests(entry[0]):
			if not state.progress.claimed_quests.has(id):
				state.dev_complete_quest(id)
		main.call("show_screen", &"pet")
		await _wait(1.0)
		_clear_modals()
		var reveal := load("res://scripts/ui/card_reveal.gd")
		reveal.call("open", str(entry[1]), {"host": main})
		await _wait(1.0)
		await _save("carta_cap%02d" % entry[0])
		var viewer: Variant = load("res://scripts/ui/card_viewer.gd").get("current")
		if is_instance_valid(viewer):
			viewer.call("close")
		await _wait(0.4)

	# Desafio do dia: só faltam as patinhas.
	_to_chapter(11)
	for id: String in state.progress.main_quests(11):
		if id == "growth_3_teething":
			continue
		if not state.progress.claimed_quests.has(id):
			state.dev_complete_quest(id)
	var growth_info: Dictionary = state.growth_info()
	for row: Dictionary in growth_info.requirements:
		if str(row.get("counter", "")) != "well_fed_day":
			if not state.growth.done.has(str(growth_info.next.id)):
				state.growth.done[str(growth_info.next.id)] = {}
			state.growth.done[str(growth_info.next.id)][str(row.id)] = true
	main.call("show_screen", &"pet")
	await _wait(1.5)
	_clear_modals()
	print("  só faltam as patinhas: ", state.only_paws_left())
	await _save("desafio_do_dia")
	var step := _node("NextStep")
	if step != null and step.visible:
		step.call("_on_pressed")
		await _wait(0.8)
		await _save("desafio_do_dia_cartao")

	# Manual: lições agrupadas por capítulo.
	var notebook := load("res://scripts/ui/pet_notebook.gd")
	notebook.call("open", "manual")
	await _wait(1.0)
	await _save("manual_licoes")

	print("ATO3 SHOTS: ", "OK" if failures == 0 else "FALHAS %d" % failures)
	quit(0 if failures == 0 else 1)
