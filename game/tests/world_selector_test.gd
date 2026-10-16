extends SceneTree
## Carrossel real, retomada da aba, bloqueios e viagem com o painel esperando a nuvem.

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
	main.call("_on_tab_pressed", &"map")
	check(not worlds.call("is_map_open"), "Primeira entrada na aba mostra a Casa")
	main.call("_on_tab_pressed", &"map")
	await frames()
	check(worlds.call("is_map_open") and worlds.get_node("%WorldView").visible, "Seletor sobre o mundo visível")
	var nature: Button = worlds.find_child("WorldCard_nature", true, false)
	check(nature.disabled, "Natureza bloqueada no começo")
	var places: Script = load("res://scripts/ui/places.gd")
	var hint: Dictionary = places.call("unlock_hint", "nature")
	check(str(hint.text).begins_with("Abre no capítulo 5\n") and hint.icon != null, "Natureza mostra capítulo 5 e ícone da história")
	hint = places.call("unlock_hint", "farm")
	check(str(hint.text).begins_with("Abre no capítulo 1\nApós:") and hint.icon != null, "Sítio mostra capítulo 1, missão e retrato")
	for id: String in ["village", "park"]:
		hint = places.call("unlock_hint", id)
		check(str(hint.text).begins_with("Abre no capítulo 4\n"), id + ": abertura real no capítulo 4")
		var locked_card: Button = worlds.find_child("WorldCard_" + id, true, false)
		check(locked_card.disabled and locked_card.find_child("PreviewLock", true, false) != null, id + ": cartão bloqueado com cadeado")
		locked_card.pressed.emit()
		check(worlds.get("current_world") == "house", id + ": cartão fechado não permite viajar")
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	_hide_modals()
	worlds.call("show_map")
	await frames()
	var farm: Button = worlds.find_child("WorldCard_farm", true, false)
	farm.pressed.emit()
	check(worlds.get("current_world") == "house", "Lateral só centraliza")
	farm.pressed.emit()
	await frames()
	check(worlds.get("current_world") == "farm" and not worlds.call("is_map_open"), "Central viaja e fecha")
	main.call("_on_tab_pressed", &"pet")
	main.call("_on_tab_pressed", &"map")
	check(worlds.get("current_world") == "farm" and not worlds.call("is_map_open"), "Aba retoma o último mundo da sessão")
	worlds.call("show_map")
	await frames()
	check(selector.get("centered_world") == "farm", "Carrossel abre no mundo atual")
	for id: String in ["house", "nature"]:
		selector.call("center_on", id, false)
		await frames()
		var card: Control = worlds.find_child("WorldCard_" + id, true, false)
		check(absf(card.get_global_rect().get_center().x - selector.get_global_rect().get_center().x) < 2, "Primeiro/último cartão centraliza: " + id)
	selector.call("center_on", "farm", false)
	await frames()
	var start := selector.global_position + Vector2(selector.size.x / 2, selector.size.y / 2)
	_mouse_button(start, true)
	var motion := InputEventMouseMotion.new()
	motion.position = start - Vector2(220, 0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	selector.call("_input", motion)
	_mouse_button(motion.position, false)
	check(selector.get("centered_world") == "park", "Arrasto horizontal encaixa no mais próximo")
	_mouse_button(start, true)
	motion.position = start + Vector2(0, 90)
	selector.call("_input", motion)
	_mouse_button(motion.position, false)
	check(not worlds.call("is_map_open"), "Arrasto para baixo fecha")
	check((main.find_child("World_farm", true, false) as Node).is_processing_input(), "Fechar restaura pinça da sala")
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
	await create_timer(1.6).timeout
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


func _mouse_button(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	selector.call("_input", event)


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
