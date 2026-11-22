extends SceneTree
## Capturas do passeio pela casa nova (primeira missão) e do banho sem véu. NÃO é teste.
## Rodar SEM --headless: & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/home_tour_shots.gd
## PNGs em build/screenshots/home_tour/. Imprime FAIL se o balão, o Pular ou o alvo saírem da tela.

const FOLDER := "res://../build/screenshots/home_tour/"
var main: Control
var state: Node
var guide: Control
var failures := 0


func _initialize() -> void:
	_run.call_deferred()
	create_timer(240).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL: ", message)


func _wait(seconds: float = 0.6) -> void:
	await create_timer(seconds).timeout


func _node(node_name: String, scope: Node = null) -> Control:
	return (scope if scope != null else main).find_child(node_name, true, false) as Control


func _clear_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var modal: Variant = main.get(member)
		if modal is CanvasLayer:
			(modal as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	main.set("_quest_rewards", [] as Array[Dictionary])


## Foto + conferência de que o balão e o Pular cabem na tela e não cobrem o alvo.
func _save(shot_name: String, expect: String = "") -> void:
	await _wait(0.9)
	await RenderingServer.frame_post_draw
	var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	if expect != "":
		_check(guide.visible and str(guide.get("active")) == expect, "%s: lição %s não está na tela (%s)" % [shot_name, expect, str(guide.get("active"))])
		for bubble_name: String in ["TutorialBalloon", "WeekTutorialHint", "TutorialSkip"]:
			var bubble := _node(bubble_name, guide)
			if bubble != null and bubble.is_visible_in_tree():
				_check(screen.encloses(bubble.get_global_rect()), "%s: %s fora da tela %s" % [shot_name, bubble_name, str(bubble.get_global_rect())])
		var balloon := _node("TutorialBalloon", guide)
		var target: Rect2 = guide.get("_anchor_rect")
		if balloon != null and balloon.is_visible_in_tree() and target.has_area():
			var overlap := balloon.get_global_rect().intersection(target)
			_check(overlap.get_area() < target.get_area() * 0.25, "%s: balão cobre o alvo (%s)" % [shot_name, str(overlap)])
	var path := ProjectSettings.globalize_path(FOLDER)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "tour_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", str(load("res://scripts/util/build_info.gd").call("data_dir")) + "home_tour_shots_descartavel.json")
	state = root.get_node("GameState")
	state.call("reset")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await _wait(1.5)
	guide = _node("WeekTutorial")
	var intro: Node = main.get("_intro")
	if intro != null:
		var lines: Array = intro.get("_lines")
		while int(intro.get("_index")) < lines.size() - 1:
			intro.call("_advance")
		intro.call("_finish")
		await _wait(1.0)
	_clear_modals()
	main.call("show_screen", &"pet")
	await _wait(0.8)
	await _save("01_tiro_carinho", "home_tour")
	state.call("pet")
	await _wait(0.6)
	await _save("02_cuidar", "home_tour")
	_node("TutorialAccept", guide).pressed.emit()
	await _wait(0.6)
	await _save("03_aneis", "home_tour")
	_node("TutorialAccept", guide).pressed.emit()
	await _wait(0.6)
	await _save("04_pegar", "home_claim")
	state.call("claim_quest", "welcome")
	await _wait(0.5)
	_clear_modals()
	state.call("feed", "puppy_mash")
	state.call("claim_quest", "lais_feed")
	await _wait(0.5)
	_clear_modals()
	await _wait(0.8)
	await _save("05_banho_cuidar", "home_bath")
	var tray := _node("CareTray")
	tray.call("open_wheel")
	await _wait(0.8)
	await _save("06_banho_sem_veu", "home_bath")
	_check((guide.get("_rects")[0] as ColorRect).color.a == 0.0, "o véu do banho deveria estar transparente")
	print("TOUR SHOTS: ", "OK" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
