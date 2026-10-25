extends SceneTree
## Lista real de cinco destinos, toque único, bloqueios e viagem com o painel esperando a nuvem.

var failures: int = 0
var main: Control
var worlds: Control
var selector: Control
var state: Node


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("WORLD_SELECTOR: " + message)


func frames() -> void:
	for i in 4: await process_frame


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await frames()
	worlds = main.find_child("WorldsScreen", true, false)
	selector = worlds.get_node("%MapView")
	check(root.get_node("Database").get("worlds").keys() == ["house", "farm", "village", "park", "nature"], "lista acompanha abertura: Casa, Sítio, Vila, Praça e Natureza")
	check(selector.z_index > 5 and selector.z_index < 8, "seletor cobre indicadores do mundo e fica abaixo do HUD")
	main.call("_on_tab_pressed", &"map")
	check(not worlds.call("is_map_open"), "Primeira entrada na aba mostra a Casa")
	main.call("_on_tab_pressed", &"map")
	await frames()
	check(worlds.call("is_map_open") and worlds.get_node("%WorldView").visible, "Seletor sobre o mundo visível")
	check(not main.find_child("HudRow2", true, false).visible, "folha de mundos não compete com o próximo passo")
	var nature: Button = worlds.find_child("WorldCard_nature", true, false)
	check(nature.disabled, "Natureza bloqueada no começo")
	var places: Script = load("res://scripts/ui/places.gd")
	var hint: Dictionary = places.call("unlock_hint", "nature")
	check(str(hint.text).begins_with("Abre no capítulo 5\n") and hint.icon != null, "Natureza mostra capítulo 5 e ícone da história")
	hint = places.call("unlock_hint", "farm")
	check(str(hint.text).begins_with("Abre no capítulo 1\nDepois de:") and hint.icon != null, "Sítio mostra capítulo 1, missão e retrato")
	for id: String in ["village", "park"]:
		hint = places.call("unlock_hint", id)
		check(str(hint.text).begins_with("Abre no capítulo 4\n"), id + ": abertura real no capítulo 4")
		var locked_card: Button = worlds.find_child("WorldCard_" + id, true, false)
		check(locked_card.disabled and locked_card.find_child("WorldLock", true, false).visible, id + ": destino bloqueado com cadeado")
		locked_card.pressed.emit()
		check(worlds.get("current_world") == "house", id + ": cartão fechado não permite viajar")
	await _check_list("locked")
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	_hide_modals()
	worlds.call("show_map")
	await frames()
	var farm: Button = worlds.find_child("WorldCard_farm", true, false)
	await _tap(farm.get_global_rect().get_center())
	await frames()
	check(worlds.get("current_world") == "farm" and not worlds.call("is_map_open"), "Um toque real no cartão viaja e fecha")
	if worlds.get("current_world") != "farm":
		main.queue_free()
		await process_frame
		quit(1)
		return
	main.call("_on_tab_pressed", &"pet")
	main.call("_on_tab_pressed", &"map")
	check(worlds.get("current_world") == "farm" and not worlds.call("is_map_open"), "Aba retoma o último mundo da sessão")
	worlds.call("show_map")
	await frames()
	check(farm.find_child("CurrentWorld", true, false).visible, "lista identifica o mundo atual com Aqui")
	await _check_list("open")
	await _tap(selector.global_position + Vector2(3, 80))
	check(not worlds.call("is_map_open"), "toque no fundo fecha a lista")
	check((main.find_child("World_farm", true, false) as Node).is_processing_input(), "Fechar restaura pinça da sala")
	worlds.call("show_map")
	selector.find_child("CloseSelector", true, false).pressed.emit()
	check(not worlds.call("is_map_open"), "X também fecha")
	# O Ir funciona imediato em movimento reduzido, preservando a seta e o atraso do painel.
	root.get_node("Events").emit_signal("world_requested", "village", "market")
	check(worlds.get("current_world") == "village", "Ir troca imediatamente com movimento reduzido")
	await create_timer(1.1).timeout
	check(main.get_node("Sheet").call("is_open"), "Ir abre a feira após apontar")
	root.get_node("Events").emit_signal("sheet_close_requested")
	# Com movimento ligado, a troca só ocorre coberta e o destino espera o final.
	Motion.reduced = false
	root.get_node("Events").emit_signal("world_requested", "farm", "workbench")
	check(worlds.get("current_world") == "village", "Mundo anterior permanece durante a entrada das nuvens")
	await create_timer(0.28).timeout
	check(worlds.get("current_world") == "farm", "Mundo troca sob a nuvem")
	check(not main.get_node("Sheet").call("is_open"), "Painel espera as nuvens")
	var tray_script: Script = load("res://scripts/ui/action_tray.gd")
	check(tray_script.get("current") == null, "Bandeja também espera as nuvens")
	var cover: Control = worlds.find_child("CloudCover", true, false)
	check(main.get_node("TopBar").z_index > cover.z_index and main.get_node("Layout/TabBar").z_index > cover.z_index, "HUD e abas ficam acima da cobertura")
	# Além da viagem/seta, a bandeja espera a câmera levar a estação à área confortável.
	var tray_deadline := Time.get_ticks_msec() + 4000
	while tray_script.get("current") == null and Time.get_ticks_msec() < tray_deadline:
		await process_frame
	var destination_tray: Control = tray_script.get("current")
	check(destination_tray != null and "plank" in destination_tray.call("entry_ids"), "Bandeja da Bancada abre após a viagem, a seta e o enquadramento")
	check(not main.get_node("Sheet").call("is_open"), "Destino de produção dispensa painel grande")
	check(not worlds.find_child("CloudCover", true, false).visible, "Nuvens saem completamente")
	Motion.reduced = true
	# Um pedido novo substitui o destino anterior, sem painel atrasado do mundo antigo.
	root.get_node("Events").emit_signal("sheet_close_requested")
	worlds.call("enter", "village", "market")
	worlds.call("enter", "house", "")
	await create_timer(1.0).timeout
	check(worlds.get("current_world") == "house" and not main.get_node("Sheet").call("is_open"), "Viagem substituída cancela o painel anterior")
	check(tray_script.get("current") == null, "Trocar de mundo fecha a bandeja anterior")
	main.queue_free()
	await process_frame
	Motion.reduced = false
	print("WORLD_SELECTOR TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


func _tap(point: Vector2) -> void:
	_hide_modals()
	var motion := InputEventMouseMotion.new()
	motion.position = root.get_final_transform() * point
	root.push_input(motion)
	await frames()
	_hide_modals()
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = root.get_final_transform() * point
		event.global_position = event.position
		root.push_input(event)
		await frames()


func _check_list(phase: String) -> void:
	for viewport: Vector2i in [Vector2i(360, 640), Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = viewport
		await frames()
		var panel: Control = selector.find_child("WorldListPanel", true, false)
		var list: Control = selector.find_child("WorldList", true, false)
		check(list.get_child_count() == 5, "cinco mundos juntos")
		check(panel.get_global_rect().position.y >= 64 and panel.get_global_rect().end.y <= main.get_node("Layout/TabBar").global_position.y, "lista entre HUD e abas em %s" % viewport)
		for row: Control in list.get_children():
			check(row.is_visible_in_tree() and panel.get_global_rect().encloses(row.get_global_rect()), "destino inteiro visível em %s: %s" % [viewport, row.name])
			check(row.size.y >= 64, "alvo de toque grande")
			var hint: Control = row.get_node("WorldHint")
			if hint.visible: check(row.get_global_rect().encloses(hint.get_global_rect()), "bloqueio cabe na linha: " + row.name)
		var first: Control = list.get_child(0)
		var second: Control = list.get_child(1)
		var last: Control = list.get_child(4)
		check(is_equal_approx(first.position.y, second.position.y) and second.position.x > first.position.x, "cartões em duas colunas")
		check(last.size.x > first.size.x * 1.9, "último cartão ocupa as duas colunas")
		check(selector.find_children("*", "ScrollContainer", true, false).is_empty(), "todos os destinos dispensam rolagem")
		if "--list-shots" in OS.get_cmdline_user_args():
			_hide_modals()
			(main.get("_toast") as Control).hide()
			var folder := ProjectSettings.globalize_path("res://../build/screenshots/world_list")
			DirAccess.make_dir_recursive_absolute(folder)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder.path_join("%s_%dx%d.png" % [phase, viewport.x, viewport.y]))


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	main.set("_chapter_done", 0)
	main.set("_announce_pending", false)
