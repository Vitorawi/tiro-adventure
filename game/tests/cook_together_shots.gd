extends SceneTree
## Capturas do "Cozinhar junto" (Picar, Mexer, Servir, Prato pronto) com medidas que imprimem FALHOU. NÃO é teste.
## Rodar SEM --headless, por resolução:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/cook_together_shots.gd -- --out=e04_cook_together
## PNGs em build/screenshots/<out>/cook_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

var state: Node
var main: Control
var together: Script
var folder := "res://../build/screenshots/e04_cook_together/"
var failures := 0
var _last := Vector2.ZERO


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(240).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FALHOU: ", message)


func game() -> Control:
	return together.call("current") as Control


func at(point: Vector2) -> Vector2:
	return (game().call("to_screen", point) as Vector2) + game().global_position


func press(point: Vector2) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = at(point)
	click.global_position = click.position
	click.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(click)


func release(point: Vector2) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = false
	click.position = at(point)
	click.global_position = click.position
	root.push_input(click)


func move(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at(point)
	motion.global_position = motion.position
	motion.relative = motion.position - _last
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	_last = motion.position
	root.push_input(motion)


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	for hidden_name: String in ["Notice", "Toast", "MomentNotice"]:
		var extra := main.find_child(hidden_name, true, false) as CanvasItem
		if extra:
			extra.hide()


func shot(shot_name: String) -> void:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "cook_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])
	_measure(shot_name)


func _measure(label: String) -> void:
	var current := game()
	if current == null:
		return
	var screen := root.get_visible_rect().size
	for node_name: String in ["SkipButton", "QuitButton"]:
		var node := current.find_child(node_name, true, false) as Control
		if node == null:
			continue
		var rect := Rect2(node.global_position, node.size)
		_check(rect.size.x >= 43.5 and rect.size.y >= 43.5, "[%s] %s menor que 44 px (%s)" % [label, node_name, rect.size])
		_check(Rect2(Vector2.ZERO, screen).encloses(rect), "[%s] %s fora da tela" % [label, node_name])
	var hotspots: Array[Rect2] = [Rect2(30, 252, 300, 214), Rect2(24, 348, 150, 112)]
	for spot in hotspots:
		var corner: Vector2 = current.call("to_screen", spot.end)
		_check(corner.x <= screen.x + 0.5 and corner.y <= screen.y + 0.5, "[%s] área de jogo passa da tela" % label)
	for label_node in current.find_children("*", "Label", true, false):
		var text := label_node as Label
		if text.text == "" or not text.is_visible_in_tree():
			continue
		var rect := Rect2(text.global_position, text.size)
		_check(rect.position.x >= -0.5 and rect.end.x <= screen.x + 0.5, "[%s] texto fora da tela: %s" % [label, text.text])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	together = load("res://scripts/ui/cook_together.gd")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("dev_week_goto", 3)
	state.call("_mark_all_seen")
	state.set("coins", 5000)
	state.get("inventory").call("from_dict", {})
	for item: String in ["carrot", "potato", "pumpkin", "egg"]:
		state.get("inventory").call("add", item, 6)
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	for i in 8:
		await process_frame
	_hide_modals()
	var chosen := {"carrot": 1, "potato": 1}
	var spec := {"name": "Papinha de cenoura e batata", "output": "puppy_mash", "items": ["carrot", "potato"],
		"check": func() -> String: return state.call("cook_invented_error", chosen, "papinha"),
		"cook": func(stars: int, together_flag: bool) -> String: return state.call("cook_invented", chosen, "papinha", stars, together_flag)}
	together.call("open", main, spec)
	for i in 4:
		await process_frame
	var playing := game()
	await shot("1_picar_inicio")
	for n in 2:
		var x: float = float(playing.call("guide_x"))
		press(Vector2(x, 280))
		move(Vector2(x, 300))
		move(Vector2(x, 360))
		release(Vector2(x, 360))
	await shot("2_picar_cortes")
	var guard := 0
	while str(playing.get("phase")) == "picar" and guard < 20:
		var x: float = float(playing.call("guide_x"))
		press(Vector2(x, 280))
		move(Vector2(x, 300))
		move(Vector2(x, 360))
		release(Vector2(x, 360))
		guard += 1
	playing.call("tick", 0.6)
	await shot("3_mexer_inicio")
	var center := Vector2(180, 424)
	var angle := -PI / 2.0
	press(center + Vector2(cos(angle), sin(angle)) * 150.0)
	for i in 36:
		angle += 0.3
		move(center + Vector2(cos(angle), sin(angle)) * 150.0)
		playing.call("tick", 0.1)
	await shot("4_mexer_no_ponto")
	while str(playing.get("phase")) == "mexer":
		angle += 0.3
		move(center + Vector2(cos(angle), sin(angle)) * 150.0)
		playing.call("tick", 0.1)
	release(center)
	playing.call("tick", 0.6)
	await shot("5_servir_inicio")
	var pot := Vector2(99, 404)
	var bowl := Vector2(272, 566)
	press(pot)
	move(Vector2(180, 500))
	move(Vector2(250, 540))
	await shot("6_servir_concha")
	move(bowl)
	release(bowl)
	press(pot)
	move(bowl)
	release(bowl)
	await shot("7_servir_coracao")
	press(Vector2(180, 690))
	move(bowl)
	release(bowl)
	playing.call("tick", 0.6)
	for i in 6:
		await process_frame
	await shot("8_prato_pronto")
	print("COOK TOGETHER SHOTS: ", "OK" if failures == 0 else "%d falha(s)" % failures)
	quit(0 if failures == 0 else 1)
