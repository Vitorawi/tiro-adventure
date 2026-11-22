extends SceneTree
## Capturas do Ato 1 (novo fluxo, F01). NÃO é teste.
## Rodar SEM --headless: & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/ato1_shots.gd
## PNGs em build/screenshots/ato1/ (um por passo: caixinha, cada roleta, o "+" da caminha, painel, cerimônia, carta).
## Imprime FAIL se o rodapé, a mão ou o painel saírem da tela.

const FOLDER := "res://../build/screenshots/ato1/"
var main: Control
var state: Node
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


func _save(shot_name: String) -> void:
	await _wait(0.9)
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(FOLDER)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "ato1_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _node(node_name: String) -> Control:
	return main.find_child(node_name, true, false) as Control


func _claim(id: String) -> void:
	state.call("claim_quest", id)
	await _wait(0.5)


func _clear_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var modal: Variant = main.get(member)
		if modal is CanvasLayer:
			(modal as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	main.set("_quest_rewards", [] as Array[Dictionary])


func _tab_check() -> void:
	var bar := _node("TabBar")
	var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	_check(bar != null and screen.encloses(bar.get_global_rect()), "rodapé fora da tela")
	var xs: Array[float] = []
	for tab_name: String in ["PetTab", "MapTab", "TasksTab", "BagTab"]:
		var tab := _node(tab_name)
		if tab != null and tab.visible:
			xs.append(tab.get_global_rect().get_center().x)
	print("  abas visíveis em x:", xs)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", str(load("res://scripts/util/build_info.gd").call("data_dir")) + "ato1_shots_descartavel.json")
	state = root.get_node("GameState")
	state.call("reset")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await _wait(1.5)

	# 1. Caixinha: a última fala é da Laís ("Oi, Tiro!").
	var intro: Node = main.get("_intro")
	if intro != null:
		var lines: Array = intro.get("_lines")
		while int(intro.get("_index")) < lines.size() - 1:
			intro.call("_advance")
		await _save("01_caixinha_fim")
		intro.call("_finish")
		await _wait(1.0)
	_clear_modals()
	main.call("show_screen", &"pet")
	await _wait(0.5)
	await _save("02_passo1_pegar")
	_tab_check()

	# 2. Passo 2: só a Comida na roleta.
	await _claim("welcome")
	_clear_modals()
	await _save("03_passo2_cuidar")
	var tray := _node("CareTray")
	tray.call("open_wheel")
	await _save("04_passo2_roleta_comida")
	tray.call("close_wheel")
	tray.call("open_food_menu")
	await _save("05_passo2_comida_mao")
	tray.call("close_food_menu")
	state.call("feed", "puppy_mash")
	await _claim("lais_feed")
	_clear_modals()

	# 3. Passo 3: banho entra na roleta.
	tray.call("open_wheel")
	await _save("06_passo3_roleta_banho")
	for star: Node in tray.find_children("NewDiscStar", "Control", true, false):
		print("  estrela: ", (star as Control).get_global_rect(), " ", (star as Control).is_visible_in_tree(), " pai ", star.get_parent().name, " ", (star.get_parent() as Control).get_global_rect())
	var guide := _node("WeekTutorial")
	if guide != null:
		guide.hide()
		guide.set_process(false)
	await _save("06b_passo3_roleta_banho_sem_mao")
	if guide != null:
		guide.set_process(true)
	tray.call("close_wheel")
	state.call("bathe")
	await _claim("lais_bath")
	_clear_modals()

	# 4. Passo 4: brincar.
	tray.call("open_wheel")
	await _save("07_passo4_roleta_brincar")
	tray.call("close_wheel")
	state.call("play")
	await _claim("lais_play")
	_clear_modals()
	_tab_check()
	await _save("08_passo5_mapa_aba")

	# 5. Passo 5: o "+" da caminha na Casa (Mapa, sem pílula do mundo).
	main.call("show_screen", &"map")
	await _save("09_passo5_casa_mais")
	_tab_check()
	root.get_node("Events").world_requested.emit("house", "buy:dog_bed")
	await _wait(1.2)
	await _save("10_passo5_colocar_caminha")
	root.get_node("Events").sheet_close_requested.emit()
	state.call("buy_upgrade", "dog_bed")
	await _claim("lais_bed")
	_clear_modals()
	main.call("show_screen", &"pet")
	tray.call("open_wheel")
	await _save("11_passo5_roleta_dormir")
	tray.call("close_wheel")

	# 6. Passo 6: painel de crescimento.
	main.get("_hud").call("show_level_popover")
	await _save("12_passo6_avatar_popover")
	root.get_node("Events").sheet_close_requested.emit()
	load("res://scripts/ui/growth_ui.gd").call("open")
	await _save("13_passo6_painel")
	root.get_node("Events").sheet_close_requested.emit()
	await _claim("lais_growth")
	_clear_modals()

	# 7. Passo 7: pronto para crescer e a cerimônia.
	load("res://scripts/ui/growth_ui.gd").call("open")
	await _save("14_passo7_crescer")
	state.call("grow")
	await _wait(3.2)
	await _save("15_passo7_cerimonia")
	_clear_modals()
	root.get_node("Events").sheet_close_requested.emit()
	await _claim("growth_1_puppy")
	_clear_modals()

	# 8. Passo 8: Álbum só agora.
	main.call("show_screen", &"pet")
	await _save("16_passo8_album_botao")
	load("res://scripts/ui/album_screen.gd").call("open")
	await _wait(1.5)
	await _save("17_passo8_carta")

	print("ATO 1 SHOTS: ", "OK" if failures == 0 else "%d FAIL" % failures)
	quit(0 if failures == 0 else 1)
