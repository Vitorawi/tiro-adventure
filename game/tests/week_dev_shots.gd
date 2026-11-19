extends SceneTree
## Captura da aba DEV "Semana" (primeira semana, E00). NÃO é teste.
## Rodar SEM --headless: & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/week_dev_shots.gd
## PNGs em build/screenshots/week_dev/. Imprime FAIL se a folha passar da tela ou algum botão ficar < 44.

var main: Node
var failures := 0
const FOLDER := "res://../build/screenshots/week_dev/"


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
	image.save_png(path + "week_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "week_shots_descartavel.json"))
	var state: Node = root.get_node("GameState")
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
	var dev: GDScript = load("res://scripts/ui/dev_panel.gd")
	dev.set("_page", "week")
	root.get_node("Events").sheet_requested.emit("Ferramentas DEV", dev.call("panel"))
	await create_timer(0.6).timeout
	var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var panel := main.get_node("Sheet").get_node("%Panel") as Control
	_check(screen.encloses(panel.get_global_rect()), "folha fora da tela")
	for button: Node in main.find_children("*", "Button", true, false):
		if str(button.name).begins_with("DevTab_") or (button as Button).text.begins_with("Dia ") or (button as Button).text.ends_with("h"):
			_check((button as Control).size.y >= 40.0, "botão %s baixo (%s)" % [(button as Button).text, (button as Control).size.y])
	await _save("inicio")
	state.call("dev_week_goto", 3)
	state.call("dev_week_hour", 12)
	await create_timer(1.2).timeout
	_check(int(state.call("week_day")) == 3, "dia 3 não aplicado")
	await _save("dia3_12h")
	print("WEEK DEV SHOTS: ", "OK" if failures == 0 else "%d FAIL" % failures)
	quit(0 if failures == 0 else 1)
