extends SceneTree
## Capturas e MEDIDAS do tutorial "A vovó ensina a pescar" (Pesca, etapa 05): um PNG por passo (1 a 13).
## NÃO é teste da suíte, mas imprime FAIL e sai com código 1 se algo sair torto (balão cobrindo o alvo, fora da tela,
## texto cortado). Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/fishing_tutorial_shots.gd
## PNGs em build/screenshots/fishing_tutorial/step_<NN>_<tela>_<largura>x<altura>.png. Não grava o save pessoal.
## Termina com "FISHING TUTORIAL SHOTS: OK" quando nada falhou.

var state: Node
var main: Control
var folder := "res://../build/screenshots/fishing_tutorial/"
var failures := 0
const HUD_HEIGHT := 168.0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(300).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL: ", message)


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_growth_ceremony", "_quest_reward", "_walk_result"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


func _farm() -> Control:
	return main.find_child("World_farm", true, false) as Control


func _flow() -> Node:
	return _farm().call("fishing_flow")


func _tutorial() -> Control:
	return main.find_child("AnglerTutorial", false, false) as Control


func _phase() -> String:
	var node := _tutorial()
	return str(node.get("phase")) if node != null else ""


func _game() -> Control:
	var flow := _flow()
	return flow.get("game") as Control if flow != null else null


func _panel() -> Control:
	var node := _farm().find_child("FishingPanel", false, false) as Control
	return node if node != null and not bool(node.get("_closing")) else null


func _wait_phase(expected: String, seconds: float = 6.0) -> bool:
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		_hide_modals()
		if _phase() == expected:
			return true
		await process_frame
	_check(false, "fase %s (está em '%s')" % [expected, _phase()])
	return false


func _next() -> void:
	for node in _tutorial().find_children("TutorialNext", "Button", true, false):
		if (node as Button).is_visible_in_tree():
			(node as Button).pressed.emit()
			return
	_check(false, "botão Continuar visível na fase %s" % _phase())


## Mede o balão/nota do passo: dentro da tela, fora do HUD e sem cobrir o alvo; texto sem corte.
func _measure(step: String) -> void:
	var tutorial := _tutorial()
	if tutorial == null:
		_check(false, step + ": tutorial aberto")
		return
	var screen := root.get_visible_rect()
	var holder: Control = tutorial.find_child("TutorialNote", true, false) if _phase() in ["see", "hold", "release", "play", "almost"] else tutorial.find_child("TutorialBalloon", true, false)
	if holder == null or not holder.is_visible_in_tree():
		_check(false, step + ": balão visível")
		return
	var rect := holder.get_global_rect()
	_check(rect.position.x >= -0.5 and rect.end.x <= screen.end.x + 0.5, "%s: balão dentro da tela na horizontal (%s)" % [step, rect])
	_check(rect.position.y >= HUD_HEIGHT - 0.5 or _phase() == "result" and rect.position.y >= HUD_HEIGHT - 0.5, "%s: balão fora do HUD (y %.0f)" % [step, rect.position.y])
	_check(rect.end.y <= screen.end.y + 0.5, "%s: balão dentro da tela na vertical (fim %.0f)" % [step, rect.end.y])
	var hole: Rect2 = tutorial.call("target_rect")
	if hole.size != Vector2.ZERO:
		_check(not rect.intersects(hole.grow(2.0)), "%s: balão não cobre o alvo (%s × %s)" % [step, rect, hole])
	var game := _game()
	if game != null and _phase() in ["see", "hold", "release", "play", "almost"]:
		_check(not rect.intersects(game.call("track_global_rect")), "%s: nota não cobre a pista" % step)
	for node in holder.find_children("*", "Label", true, false):
		var label := node as Label
		if label.is_visible_in_tree() and label.text != "" and label.autowrap_mode == TextServer.AUTOWRAP_OFF and not label.clip_text:
			_check(label.size.x + 1.0 >= label.get_minimum_size().x, "%s: texto cortado '%s'" % [step, label.text])
	var next: Control = null
	for candidate in holder.find_children("TutorialNext", "Button", true, false):
		if (candidate as Control).is_visible_in_tree():
			next = candidate as Control
	if next != null and next.is_visible_in_tree():
		_check(next.size.x >= 43.5 and next.size.y >= 43.5, "%s: Continuar com alvo >= 44 (%s)" % [step, next.size])


func _snap(step: String, label: String) -> void:
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "step_%s_%s_%dx%d.png" % [step, label, image.get_width(), image.get_height()])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "fishing_tutorial_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("_dev_complete_quest", "bloblo_more_crops")
	state.call("_dev_complete_quest", "lais_first_crops")
	state.call("_mark_all_seen")
	state.get("inventory").call("from_dict", {})
	state.call("_changed")
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	main.call("_on_world_requested", "farm", "")
	main.call("show_screen", &"map")
	for i in 6:
		await process_frame
	await create_timer(1.0).timeout
	_hide_modals()
	_farm().call("recenter")
	await create_timer(0.4).timeout

	# 01 — a vovó entrega a vara (conversa).
	var load_places: Script = load("res://scripts/ui/places.gd")
	state.get("progress").seen["npc_intro:bloblo"] = true  # a apresentação já passou: a conversa mostra a missão da vara
	load_places.call("open_npc", "bloblo")
	await _snap("01", "conversa_vara")
	root.get_node("Events").sheet_close_requested.emit()
	await create_timer(0.4).timeout
	state.call("talk_to", "bloblo")
	state.call("claim_quest", "bloblo_rod")
	await create_timer(0.3).timeout
	_hide_modals()

	# 02 — toque na lagoa.
	if await _wait_phase("lake"):
		_measure("02")
		await _snap("02", "lagoa")
	_farm().call("open_fishing")
	await create_timer(0.5).timeout
	# 03 — a minhoca já está no anzol.
	if await _wait_phase("bait"):
		_measure("03")
		await _snap("03", "isca")
	_next()
	# 04 — força.
	if await _wait_phase("force"):
		_measure("04")
		await _snap("04", "forca")
	_panel().set("power_override", 0.55)
	_panel().call("press_cast")
	_panel().call("release_cast")
	# 05 — espera.
	if await _wait_phase("wait"):
		await create_timer(0.3).timeout
		_measure("05")
		await _snap("05", "espera")
	# 06 — mordida (a espera fixa é de 3 s; o toque só vale depois).
	if await _wait_phase("bite", 8.0):
		_measure("06")
		await _snap("06", "mordida")
	_flow().call("handle_tap")
	# 07 — minigame pausado.
	if await _wait_phase("see"):
		await create_timer(0.3).timeout
		_measure("07")
		await _snap("07", "rede")
	_next()
	# 08 — segurar.
	if await _wait_phase("hold"):
		_measure("08")
		_game().set("_button_held", true)
		await _snap("08", "segurar")
	# 09 — soltar.
	if await _wait_phase("release", 4.0):
		_measure("09")
		await _snap("09", "soltar")
		_game().set("_button_held", false)
	# 10 — jogo ao vivo.
	if await _wait_phase("play", 4.0):
		_measure("10")
		await _snap("10", "jogando")
	# 11 — quase lá: sobe a rede para 60%.
	var game := _game()
	if game != null:
		var sim: FishingSim = game.get("sim")
		sim.meter = 0.62
		if await _wait_phase("almost", 3.0):
			_measure("11")
			await _snap("11", "quase")
		# termina a partida sem ninguém tocar (o piso do tutorial garante a captura)
		var guard := 0
		while str(_flow().get("state")) == "fighting" and guard < 6000:
			game.call("_process", 0.1)
			guard += 1
	# 12 — resultado.
	if await _wait_phase("result", 6.0):
		_measure("12")
		await _snap("12", "resultado")
	var again := main.find_child("FishAgain", true, false) as Button
	if again != null:
		again.pressed.emit()
	# 13 — volta à lagoa.
	if await _wait_phase("outro", 6.0):
		_measure("13")
		await _snap("13", "outro")
	_next()
	await create_timer(0.4).timeout
	_check(bool(state.get("fishing").tutorial.done), "tutorial concluído ao fim")
	print("FISHING TUTORIAL SHOTS: ", "OK" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
