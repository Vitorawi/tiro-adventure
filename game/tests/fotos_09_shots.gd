extends SceneTree
## Etapa 09 das Fotos: capturas do tutorial da carta, um PNG por passo. NÃO é teste. Rodar SEM --headless:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/fotos_09_shots.gd -- --out=fotos_09
## PNGs em build/screenshots/<out>/tutorial_<largura>x<altura>_<passo>.png; imprime "FAIL ..." na auditoria.
## Usa save descartável (nenhuma escrita no save pessoal).

var state: Node
var main: Node
var folder := "fotos_09"
var failures := 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(150.0).timeout.connect(func() -> void: quit(1))


func _fail(message: String) -> void:
	failures += 1
	print("FAIL ", message)


func _tut() -> Control:
	return load("res://scripts/ui/album_tutorial.gd").get("current") as Control


func _viewer() -> Control:
	return load("res://scripts/ui/card_viewer.gd").get("current") as Control


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer: (node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree(): (intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


func _wait_phase(phase: String) -> bool:
	for i in 80:
		var node := _tut()
		if node != null and str(node.get("phase")) == phase: return true
		await create_timer(0.1).timeout
	_fail("fase %s não chegou" % phase)
	return false


func _tap(pos: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = pos
		event.global_position = pos
		root.push_input(event, true)
		await process_frame


func _audit(label: String) -> void:
	var node := _tut()
	if node == null: return
	var screen := root.get_visible_rect()
	var hole: Rect2 = node.call("target_rect")
	var balloon := node.find_child("TutorialBalloon", true, false) as Control
	if hole.size != Vector2.ZERO:
		if not screen.encloses(hole): _fail("%s: alvo fora da tela" % label)
		if label != "5_inclinar" and (hole.size.x < 44.0 or hole.size.y < 44.0): _fail("%s: alvo menor que 44" % label)
	if balloon != null and balloon.visible:
		var rect := balloon.get_global_rect()
		if not screen.encloses(rect): _fail("%s: balão fora da tela %s" % [label, rect])
		if hole.size != Vector2.ZERO and rect.intersects(hole): _fail("%s: balão cobre o alvo" % label)
		if rect.position.y < 168.0: _fail("%s: balão sob o HUD" % label)


func shot(label: String, wait: float = 0.9) -> void:
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	_audit(label)
	var path := ProjectSettings.globalize_path("res://../build/screenshots/" + folder + "/")
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "tutorial_%dx%d_%s.png" % [image.get_width(), image.get_height(), label])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer: child.queue_free()
	saver.set("_save_path", str(load("res://scripts/util/build_info.gd").call("data_dir")) + "fotos_09_descartavel.json")
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	var intro: Array[String] = ["intro"]
	state.call("mark_seen", intro)
	state.get("progress").claimed_quests["lais_play"] = true
	state.set("coins", 800)
	main.call("show_screen", &"pet")
	await create_timer(0.5).timeout
	_hide_modals()
	load("res://scripts/ui/pet_notebook.gd").call("open", "album")
	if not await _wait_phase("open"): quit(1); return
	await shot("1_abrir")
	await _tap((_tut().call("target_rect") as Rect2).get_center())
	await shot("2_revelando", 0.35)
	if not await _wait_phase("reroll"): quit(1); return
	await shot("3_tentar_sorte")
	await _tap((_tut().call("target_rect") as Rect2).get_center())
	if not await _wait_phase("upgrade"): quit(1); return
	await shot("4_melhorar")
	await _tap((_tut().call("target_rect") as Rect2).get_center())
	if not await _wait_phase("tilt"): quit(1); return
	await shot("5_inclinar")
	var card := _viewer()
	var center: Vector2 = (card.call("card_rect") as Rect2).get_center()
	card.call("touch_down", center)
	card.call("touch_move", center + Vector2(60, 10))
	await shot("5b_inclinando", 0.3)
	card.call("touch_up", center + Vector2(60, 10))
	if not await _wait_phase("version"): quit(1); return
	await shot("6_versao")
	var tile := card.find_child("Version_1", true, false) as Control
	await _tap(tile.get_global_rect().get_center())
	if not await _wait_phase("feature"): quit(1); return
	await shot("7_varal")
	await _tap((_tut().call("target_rect") as Rect2).get_center())
	await shot("8_home", 1.6)
	print("FOTOS 09 SHOTS: ", "PASS" if failures == 0 else "FALHAS=%d" % failures)
	quit(failures)
