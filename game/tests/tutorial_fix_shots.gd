extends SceneTree
## Capturas das correções do guia (27/11/2026). NÃO é teste.
## Rodar SEM --headless: & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/tutorial_fix_shots.gd
## PNGs em build/screenshots/tutorial_fix/: canteiro em foco junto do Comprar, faltam moedas,
## e a geladeira saindo do Sítio (lugares → Casa → +).

const FOLDER := "res://../build/screenshots/tutorial_fix/"
var main: Control
var state: Node
var db: Node
var failures := 0


func _initialize() -> void:
	_run.call_deferred()
	create_timer(300).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL: ", message)


func _wait(seconds: float = 0.6) -> void:
	await create_timer(seconds).timeout


func _save(shot_name: String) -> void:
	await _wait(0.8)
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(FOLDER)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _node(node_name: String) -> Control:
	for node: Node in main.find_children(node_name, "Control", true, false):
		if (node as Control).is_visible_in_tree():
			return node as Control
	return null


func _clear_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var modal: Variant = main.get(member)
		if modal is CanvasLayer:
			(modal as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	main.set("_quest_rewards", [] as Array[Dictionary])


func _guide() -> Array:
	var guide := main.find_child("WeekTutorial", true, false) as Control
	if guide == null or not guide.visible:
		return ["", -1]
	return [str(guide.get("active")), int(guide.get("step"))]


## Conclui os passos principais até (sem incluir) `stop`.
func _until(stop: String) -> void:
	var stop_quest: Dictionary = db.quests[stop]
	var ids: Array = db.quests.keys()
	ids.sort_custom(func(a: String, b: String) -> bool: return int(db.quests[a].get("chapter", 99)) * 1000 + int(db.quests[a].get("order", 0)) < int(db.quests[b].get("chapter", 99)) * 1000 + int(db.quests[b].get("order", 0)))
	for id: String in ids:
		var quest: Dictionary = db.quests[id]
		if quest.get("kind", "") != "main" or state.progress.claimed_quests.has(id):
			continue
		if int(quest.chapter) < int(stop_quest.chapter) or (int(quest.chapter) == int(stop_quest.chapter) and int(quest.order) < int(stop_quest.order)):
			state.dev_complete_quest(id)
	# Só as lições em revisão continuam abertas: as outras já foram vistas.
	for lesson: Dictionary in db.week_tutorials:
		if str(lesson.id) not in ["plots", "fridge"]:
			state.week.tutorial[str(lesson.id)] = {"done": true}


func _press(node_name: String) -> void:
	var button := _node(node_name) as BaseButton
	_check(button != null, "botão %s visível" % node_name)
	if button != null:
		button.pressed.emit()
	await _wait(0.5)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", str(load("res://scripts/util/build_info.gd").call("data_dir")) + "tutorial_fix_descartavel.json")
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/helpers/week_story_clock.gd"))
	state.call("set_clock", 1792411200.0)
	state.call("reset")
	state.call("_count", "arrival_box")
	state.call("finish_week_arrival")
	state.call("finish_home_tour")
	state.get("week").tutorial["arrival"] = {"done": true}
	Motion.reduced = true
	state.progress.seen["intro"] = true
	state.call("finish_fishing_tutorial")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await _wait(1.5)
	_until("week_plots")
	state.set("coins", 60)
	await _wait(0.8)
	_clear_modals()

	# 1. Banca: escolher o canteiro extra → a mão no Comprar e o cartão aceso junto.
	root.get_node("Events").world_requested.emit("farm", "early_market")
	await _wait(1.6)
	_clear_modals()
	await _press("NotebookTab_buy")
	await _press("Buy_week_plot")
	await _wait(0.6)
	print("  canteiro escolhido: ", _guide())
	_check(_guide() == ["plots", 2], "mão no Comprar com o canteiro escolhido")
	await _save("a_canteiro_e_comprar")

	# 2. Sem moedas: a fala avisa e a mão vai para Vender.
	state.set("coins", 3)
	root.get_node("Events").state_changed.emit()
	await _wait(1.2)
	print("  sem moedas: ", _guide())
	_check(_guide() == ["plots", 3], "sem moedas a mão leva a Vender")
	await _save("b_faltam_moedas")
	root.get_node("Events").sheet_close_requested.emit()
	await _wait(0.6)

	# 3. Geladeira com o seletor aberto no Sítio: a mão vai para a Casa (não para a aba Mapa).
	_until("week_fridge")
	state.finish_album_tutorial()
	state.set("coins", 200)
	main.call("show_screen", &"map")
	await _wait(1.0)
	_clear_modals()
	_node("WorldsScreen").call("show_map")
	await _wait(1.0)
	print("  seletor aberto: ", _guide())
	_check(_guide()[0] == "fridge" and _guide()[1] == 2, "seletor aberto: toque na Casa")
	await _save("c_geladeira_seletor")
	_node("WorldsScreen").call("close_map")
	await _wait(0.8)
	print("  Sítio: ", _guide())
	_check(_guide()[0] == "fridge" and _guide()[1] == 1, "no Sítio: escolher o lugar")
	await _save("d_geladeira_sitio")
	root.get_node("Events").world_requested.emit("house", "")
	await _wait(1.6)
	_clear_modals()
	print("  Casa: ", _guide())
	_check(_guide()[0] == "fridge" and _guide()[1] == 3, "na Casa: o + da geladeira")
	await _save("e_geladeira_casa")

	print("TUTORIAL FIX SHOTS: ", "OK" if failures == 0 else "FALHAS %d" % failures)
	quit(0 if failures == 0 else 1)
