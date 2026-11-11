extends SceneTree
## Capturas e MEDIDAS da pesca na lagoa (etapa 02): lagoa sem vara, painel de arremesso, força, espera, mordida,
## minigame (começo/meio), pausa, resultados (comum, recorde, Gigante, geladeira cheia) e a bolha no mapa.
## NÃO é teste da suíte, mas imprime FAIL e sai com código 1 se algo sair torto. Rodar SEM --headless:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/fishing_shots.gd -- --out=fishing
## PNGs em build/screenshots/<out>/fishing_<largura>x<altura>_<tela>.png. Não grava o save pessoal.
## Termina com "FISHING SHOTS: OK" quando nada falhou.

var state: Node
var main: Control
var folder := "res://../build/screenshots/fishing/"
var failures := 0
const HUD_HEIGHT := 168.0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(600).timeout.connect(func() -> void: quit(1))


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


func _panel() -> Control:
	var node := _farm().find_child("FishingPanel", false, false) as Control
	return node if node != null and not bool(node.get("_closing")) else null


func _fresh(with_rod: bool = true, baits: int = 6) -> void:
	if _flow() != null:
		_flow().call("end")
	state.call("cancel_fishing")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.get("inventory").call("from_dict", {})
	if with_rod:
		state.call("dev_give_rod", "bamboo_rod")
		state.get("inventory").add("bait_worm", baits)
		state.get("fishing").tutorial["done"] = false  # a janela da fisgada não fecha: dá tempo de capturar a mordida
	state.call("_changed")
	await create_timer(0.6).timeout
	_hide_modals()


func _screen() -> Rect2:
	return root.get_visible_rect()


func _tabs_top() -> float:
	return (main.find_child("TabBarArt", true, false) as Control).global_position.y


## Medidas de um controle visível: dentro da tela, fora do HUD e das abas, e (botões) alvo >= 44.
func _measure(node_name: String, button: bool = false, under_tabs: bool = true) -> void:
	var node: Control
	if node_name == "FishingPanel":
		node = _panel().find_child("Panel", true, false) as Control  # a raiz é de tela cheia; mede a bandeja
	else:
		node = main.find_child(node_name, true, false) as Control
	if node == null:
		_check(false, node_name + " existe")
		return
	if not node.is_visible_in_tree():
		_check(false, node_name + " visível")
		return
	var rect := node.get_global_rect()
	var screen := _screen()
	_check(rect.position.x >= -0.5 and rect.end.x <= screen.end.x + 0.5, "%s dentro da tela na horizontal (%s)" % [node_name, rect])
	_check(rect.position.y >= HUD_HEIGHT - 0.5, "%s não fica sob o HUD (y %.0f)" % [node_name, rect.position.y])
	if under_tabs:
		_check(rect.end.y <= _tabs_top() + 0.5, "%s não fica sob as abas (fim %.0f, abas %.0f)" % [node_name, rect.end.y, _tabs_top()])
	if button:
		_check(rect.size.x >= 43.5 and rect.size.y >= 43.5, "%s com alvo >= 44 (%s)" % [node_name, rect.size])


func _clipped(root_node: Node) -> void:
	for node in root_node.find_children("*", "Label", true, false):
		var label := node as Label
		if not label.is_visible_in_tree() or label.text == "" or label.autowrap_mode != TextServer.AUTOWRAP_OFF or label.clip_text:
			continue
		var wanted := label.get_minimum_size().x
		_check(label.size.x + 1.0 >= wanted or label.size.x < 1.0, "texto cortado: '%s' (%.0f < %.0f)" % [label.text, label.size.x, wanted])


func _snap(shot_name: String) -> void:
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "fishing_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _cast_and_bite() -> void:
	_panel().set("power_override", 0.5)
	_panel().call("press_cast")
	_panel().call("release_cast")


func _make_bite_due() -> void:
	var cast: Dictionary = state.get("fishing").cast
	cast["at"] = float(state.call("now")) - float(cast.wait) - 0.05
	state.call("update_fishing")


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "fishing_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
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

	# 1) Lagoa sem vara: o balão da vovó.
	await _fresh(false)
	_farm().call("recenter")
	await create_timer(0.5).timeout
	_farm().call("open_fishing")
	await _snap("a_lagoa_sem_vara")

	# 2) Painel com uma vara.
	await _fresh()
	_farm().call("open_fishing")
	await _snap("b_painel_1_vara")
	_measure("FishingPanel")
	_measure("CastButton", true)
	_measure("CloseTray", true)
	_clipped(_panel())

	# 3) Painel com três varas.
	state.call("dev_give_rod", "reel_rod")
	state.call("dev_give_rod", "angler_rod")
	state.get("inventory").add("bait_dough", 3)
	state.call("_changed")
	await create_timer(0.5).timeout
	await _snap("c_painel_3_varas")
	_measure("FishingPanel")
	_measure("Rod_reel_rod", true)
	_measure("Bait_bait_dough", true)
	_clipped(_panel())

	# 4) Sem isca.
	await _fresh(true, 0)
	_farm().call("open_fishing")
	await _snap("d_painel_sem_isca")
	_measure("FishingPanel")
	_measure("Locked_CastButton", true)
	_clipped(_panel())

	# 5) Força: segurando o botão.
	await _fresh()
	_farm().call("open_fishing")
	_panel().set("power_override", 0.62)
	_panel().call("press_cast")
	await _snap("e_forca")
	_measure("CastPower")
	_panel().call("release_cast")

	# 6) Espera e 7) mordida.
	await create_timer(0.9).timeout
	await _snap("f_espera")
	_make_bite_due()
	await create_timer(0.3).timeout
	await _snap("g_mordida")

	# 8) Minigame: começo e meio.
	_flow().call("handle_tap")
	await create_timer(0.8).timeout
	await _snap("h_minigame_comeco")
	var game := main.find_child("FishingGame", true, false) as Control
	_check(game != null, "FishingGame aberto")
	if game:
		_measure("FishingGame")
		_measure("PauseButton", true)
		_measure("HoldButton", true)
		var track: Rect2 = game.call("track_rect")
		_check(track.size.y > 150.0 and track.position.x >= 0 and track.end.x <= game.size.x, "pista cabe na tela")
		# o motor segue sozinho e a partida acabaria antes da foto: conduz o motor com o peixe seguido pela barra
		game.set("_paused", true)
		var sim: FishingSim = game.get("sim")
		for i in 90:
			sim.step(sim.fish_y > sim.bar_y + sim.bar_h / 2.0, 1.0 / 60.0)
		sim.meter = 0.55
		await _snap("i_minigame_meio")
		game.set("_paused", false)
		game.call("pause")
		await create_timer(0.3).timeout
		await _snap("j_pausa")
		_measure("PauseCard")
		_measure("ResumeButton", true)
		_measure("ReleaseButton", true)
		game.call("resume")

	# 9) Resultados.
	var result: Node = _flow().get("result")
	var fish := str(state.get("fishing").cast.get("fish", "fish_lambari"))
	state.call("cancel_fishing")
	_flow().call("end")
	var info := {"fish": fish, "cm": 12.5, "class": "medium", "previous_cm": 12.5, "first": false, "qty": 1, "xp": 4, "perfect": false}
	result.call("show_caught", info)
	await _snap("k_resultado_comum")
	_measure("FishAgain", true, false)
	_measure("FishLeave", true, false)
	_measure("FishSize", false, false)
	result.call("close")
	info.cm = 14.5
	info.previous_cm = 11.0
	result.call("show_caught", info)
	await _snap("l_resultado_recorde")
	_check(result.find_child("FishRecord", true, false) != null, "Novo recorde!")
	result.call("close")
	info.cm = 15.0
	info.class = "giant"
	info.qty = 2
	info.xp = 12
	result.call("show_caught", info)
	await _snap("m_resultado_gigante")
	_measure("FishAgain", true, false)
	result.call("close")
	info.first = true
	info.class = "small"
	info.cm = 7.0
	result.call("show_caught", info)
	await _snap("n_primeira_vez")
	result.call("close")
	result.call("show_full", fish)
	await _snap("o_geladeira_cheia")
	_measure("Locked_Fridge", true, false)
	_measure("FishFreeSpace", true, false)
	result.call("close")

	# 10) Bolha no mapa.
	await _fresh()
	state.call("dev_bubble_now")
	_farm().call("recenter")
	await create_timer(0.6).timeout
	var bubbles: Node = _farm().call("fishing_bubbles")
	_check(int(bubbles.call("active_spot")) >= 0, "bolha ativa")
	var point: Vector2 = bubbles.call("spot_position", int(bubbles.call("active_spot")))
	_farm().call("zoom_to", point, 0.9, 0.01)
	await create_timer(0.7).timeout
	await _snap("p_bolha_no_mapa")

	print("FISHING SHOTS: ", "OK" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
