extends SceneTree
## Capturas das telas do relógio (primeira semana, E01c). NÃO é teste.
## Rodar SEM --headless: godot --path game --resolution 360x780 -s res://tests/meal_shots.gd
## PNGs em build/screenshots/meal/. Imprime FAIL se a folha passar da tela ou um botão ficar < 44.
var main: Node
var state: Node
var failures := 0
const FOLDER := "res://../build/screenshots/meal/"


func _initialize() -> void:
	_run.call_deferred()
	create_timer(90).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL: ", message)


func _save(shot_name: String) -> void:
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(FOLDER)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "meal_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _sheet_ok() -> void:
	var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var panel := main.get_node("Sheet").get_node("%Panel") as Control
	_check(screen.encloses(panel.get_global_rect()), "folha fora da tela")
	for button: Node in panel.find_children("*", "Button", true, false):
		if (button as Control).is_visible_in_tree():
			_check((button as Control).size.y >= 40.0, "botão %s baixo" % (button as Button).text)


func _at(day: int, hour: int) -> void:
	state.call("dev_week_goto", day)
	state.call("dev_week_hour", hour)
	state.call("update_week")


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "meal_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	load("res://scripts/ui/motion.gd").set("reduced", true)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	var events: Node = root.get_node("Events")
	var meal_ui: GDScript = load("res://scripts/ui/meal_ui.gd")
	_at(3, 12)
	await _save("a_tiro_hora_de_comer")
	events.sheet_requested.emit("Hoje", meal_ui.call("today_panel"))
	await create_timer(0.6).timeout
	_sheet_ok()
	await _save("b_hoje")
	events.sheet_close_requested.emit()
	_at(3, 9)
	state.get("inventory").call("add", "puppy_mash", 1)
	var tray: Node = null
	for node in main.find_children("*", "Control", true, false):
		if node.has_method("open_food_menu"):
			tray = node
			break
	tray.call("_act", "puppy_mash")
	await create_timer(0.6).timeout
	_sheet_ok()
	await _save("c_deixar_pronto")
	(main.find_child("StoreMeal", true, false) as Button).pressed.emit()
	await create_timer(0.8).timeout
	await _save("d_tiro_com_tampinha")
	events.sheet_requested.emit("Hoje", meal_ui.call("today_panel"))
	await create_timer(0.6).timeout
	_sheet_ok()
	await _save("e_hoje_guardado_fraquinho")
	print("MEAL SHOTS: ", "OK" if failures == 0 else "%d FAIL" % failures)
	quit(0 if failures == 0 else 1)
