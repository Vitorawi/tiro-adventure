extends SceneTree
## Etapa 07: bandeja de ação da horta (plantar, regar e colher tocando ou arrastando).
## Usa o Sítio de verdade (main.tscn), sem SaveManager.
## --headless --path game -s res://tests/tray_test.gd

var failures := 0
var state: Node
var events: Node
var main: Control
var farm: Control
var tray_script: Script
var toasts: Array[String] = []
var sheets := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("TRAY: " + message)


## Bandeja aberta agora (null se não há ou se está fechando).
func tray() -> Control:
	var current: Variant = tray_script.get("current")
	if current is Control and is_instance_valid(current) and not bool((current as Control).get("closing")):
		return current as Control
	return null


## Dedo que deixa o fantasma (40 px acima) exatamente sobre o centro do canteiro.
func finger_for(index: int) -> Vector2:
	return (farm.call("world_to_screen", farm.call("plot_center", index)) as Vector2) + Vector2(0, 40)


func empty_plots() -> void:
	var plots: Array = state.get("plots")
	for i in plots.size():
		plots[i] = {"crop": "", "ready_at": 0.0}
	state.call("_changed")


func open_tray(index: int) -> Control:
	farm.call("close_tray")
	farm.call("open_plot_tray", index)
	await process_frame
	await process_frame
	return tray()


func status(index: int) -> String:
	return state.call("plot_status", index)


func mouse_event(kind: String, position: Vector2) -> InputEvent:
	if kind == "motion":
		var motion := InputEventMouseMotion.new()
		motion.position = position
		motion.global_position = position
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		return motion
	var button := InputEventMouseButton.new()
	button.button_index = MOUSE_BUTTON_LEFT
	button.pressed = kind == "press"
	button.position = position
	button.global_position = position
	button.button_mask = MOUSE_BUTTON_MASK_LEFT if button.pressed else 0
	return button


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	events = root.get_node("Events")
	tray_script = load("res://scripts/ui/action_tray.gd")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.set("unlocked_plots", 9)
	state.set("coins", 5000)
	Motion.reduced = true
	events.toast_requested.connect(func(text: String) -> void: toasts.append(text))
	events.sheet_requested.connect(func(_title: String, _content: Control) -> void: sheets += 1)
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	for i in 4: await process_frame
	main.call("_on_world_requested", "farm", "")
	main.call("show_screen", &"map")
	for i in 4: await process_frame
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	farm = main.find_child("World_farm", true, false)
	farm.call("_animate_objects")
	empty_plots()
	check((farm.call("plot_indices") as Array).size() == 13, "Sítio com 9 canteiros + 4 da estufa visíveis")
	var garden: Sprite2D = farm.find_child("plot_0", true, false)
	var glass: Sprite2D = farm.find_child("plot_9", true, false)
	check(glass.texture.resource_path.ends_with("plot_greenhouse.png") and garden.texture.resource_path.ends_with("plot.png"), "estufa tem canteiro próprio (pedra e vidro)")
	var boundary: Sprite2D = farm.find_child("greenhouse", true, false)
	check(boundary.texture.resource_path.ends_with("greenhouse_boundary.svg") and boundary.get_meta("action") == "place:greenhouse", "estufa é área demarcada com acesso próprio")
	var greenhouse_panel: Control = load("res://scripts/ui/sheet_builder.gd").call("farm_view", "", true)
	root.add_child(greenhouse_panel)
	await process_frame
	check(greenhouse_panel.find_child("GreenhousePlots", true, false).get_child_count() == 4, "painel da estufa só tem seus quatro canteiros")
	greenhouse_panel.queue_free()

	await _test_state_helpers()
	await _test_plot_at()
	await _test_tap_plants()
	await _test_drag_plant()
	await _test_greenhouse_and_locked()
	await _test_harvest()
	await _test_full_storage()
	await _test_water()
	await _test_closing()
	await _test_edge_scroll()
	await _test_hint()
	await _test_real_input()
	await _test_other_paths()

	print("TRAY TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# --- 7.1 plant_error / harvest_error ----------------------------------------------------

func _test_state_helpers() -> void:
	check(state.call("plant_error", 0, "carrot") == "", "plant_error vazio quando dá para plantar")
	check(state.call("plant_error", 9, "carrot") != "", "estufa recusa cenoura")
	check(state.call("plant_error", 0, "herbs") != "", "sítio recusa planta só da estufa")
	check(state.call("plant_error", 0, "blueberry") != "", "planta bloqueada por requisito")
	check(state.call("plant_error", 0, "nada") == "Semente desconhecida", "semente desconhecida")
	check(state.call("harvest_error", 0) == "Ainda não está pronto", "harvest_error de canteiro vazio")
	for index in [0, 9]:
		for crop_id: String in ["carrot", "herbs", "strawberry", "blueberry"]:
			var predicted: String = state.call("plant_error", index, crop_id)
			var done: String = state.call("plant", index, crop_id)
			check((predicted == "") == (done == ""), "plant e plant_error concordam (%d, %s)" % [index, crop_id])
			check(predicted == "" or predicted == done, "mesmo motivo (%d, %s)" % [index, crop_id])
			empty_plots()
	state.call("plant", 0, "carrot")
	check(state.call("harvest_error", 0) == "Ainda não está pronto", "plantado mas crescendo")
	state.call("dev_finish_timers")
	check(state.call("harvest_error", 0) == "", "pronto e cabe no depósito")
	empty_plots()


# --- 7.3 plot_at -------------------------------------------------------------------------

func _test_plot_at() -> void:
	for index in farm.call("plot_indices"):
		var center: Vector2 = farm.call("plot_center", index)
		check(farm.call("plot_at", center) == index, "plot_at acha o centro do canteiro %d" % index)
	var center0: Vector2 = farm.call("plot_center", 0)
	check(farm.call("plot_at", center0 + Vector2(0, -300)) == -1, "longe de todos = −1")
	# Losango de 74×50: ampliado 20%, ainda pega um pouco para fora do canto (e não pega muito longe).
	check(farm.call("plot_at", center0 + Vector2(40, 0)) == 0, "folga de 20% à direita")
	check(farm.call("plot_at", center0 + Vector2(0, -29)) == 0, "folga de 20% em cima")
	check(farm.call("plot_at", center0 + Vector2(0, -80)) != 0, "bem acima não é o canteiro 0")
	# Entre dois vizinhos vence o mais perto.
	var between: Vector2 = (farm.call("plot_center", 1) as Vector2).lerp(farm.call("plot_center", 2), 0.3)
	check(farm.call("plot_at", between) == 1, "ponto perto do 1 escolhe o 1")
	check(farm.call("plot_anchor", 0).above.y < center0.y, "a bandeja aponta para cima do canteiro")
	var screen: Vector2 = farm.call("world_to_screen", center0)
	check((farm.call("screen_to_world", screen) as Vector2).distance_to(center0) < 0.01, "screen_to_world desfaz world_to_screen")


# --- 1. toque no canteiro vazio -------------------------------------------------------------

func _test_tap_plants() -> void:
	toasts.clear()
	empty_plots()
	farm.call("_animate_objects")
	var point: Vector2 = farm.call("plot_center", 0)
	check(farm.call("_handle_tap", point), "toque no canteiro 0 é tratado")
	await process_frame
	await process_frame
	var current := tray()
	check(current != null, "tocar no canteiro vazio abre a bandeja")
	if current == null:
		return
	check(sheets == 0, "nenhum painel grande abriu")
	var ids: Array = current.call("entry_ids")
	check("carrot" in ids, "bandeja de sementes oferece cenoura")
	check(not ("herbs" in ids), "sítio não oferece plantas da estufa")
	check(ids[0] != "blueberry", "bloqueadas vão para o fim")
	var box: Control = current.get("_box")
	check(box.position.y >= 119.0, "bandeja não fica sob o HUD (y %.0f)" % box.position.y)
	check(Rect2(Vector2.ZERO, farm.size).encloses(Rect2(box.position, box.size)), "bandeja inteira dentro da sala")
	check(current.get_parent() == farm, "bandeja é filha da sala")
	current.call("tap_item", "carrot")
	check(status(0) == "growing", "tocar na cenoura planta o canteiro 0")
	check(tray() == null, "depois de plantar a bandeja fecha")
	check(toasts.is_empty(), "plantar não gera aviso de erro")
	# A última semente usada passa a vir primeiro.
	empty_plots()
	state.call("plant", 1, "potato")
	farm.call("plant_plot", 2, "pumpkin")
	var again := await open_tray(3)
	check(again != null and (again.call("entry_ids") as Array)[0] in ["pumpkin", "potato", "carrot"], "bandeja reabre")
	again.call("tap_item", "potato")
	await open_tray(4)
	check((tray().call("entry_ids") as Array)[0] == "potato", "última semente usada vem primeiro")
	farm.call("close_tray")
	empty_plots()


# --- 2. arrastar a semente -------------------------------------------------------------------

func _test_drag_plant() -> void:
	toasts.clear()
	empty_plots()
	state.call("plant", 0, "carrot")
	var planted_at: float = state.call("plot", 0)["planted_at"]
	var before: Vector2 = farm.get("_content").position
	var current := await open_tray(1)
	check(current != null, "bandeja no canteiro 1")
	var path: Array[Vector2] = [finger_for(1), finger_for(2), finger_for(3), finger_for(0)]
	current.call("drag_through", "carrot", path, false)
	check(current.call("is_dragging"), "arrastando: fantasma ativo")
	check(farm.get("tray_dragging") == true, "mundo sabe que a bandeja arrasta")
	check(current.find_child("Ghost", true, false) != null, "fantasma aparece")
	check((farm.get("_content") as Control).position == before, "câmera parada durante o arrasto")
	current.call("release_item", path[3])
	check(status(1) == "growing" and status(2) == "growing" and status(3) == "growing", "arrasto plantou 1, 2 e 3")
	check(float(state.call("plot", 0)["planted_at"]) == planted_at, "canteiro 0 (já plantado) ficou intacto")
	check(state.call("plot", 0)["crop"] == "carrot", "0 continua cenoura")
	check(toasts.is_empty(), "nenhum aviso de erro no arrasto")
	check(tray() == null and farm.get("tray_dragging") == false, "agiu: a bandeja fecha e o mundo volta ao normal")
	# Arrasto que não pega nenhum canteiro vazio: a bandeja continua.
	current = await open_tray(4)
	current.call("drag_through", "carrot", [Vector2(180, 700), Vector2(200, 705)] as Array[Vector2])
	check(tray() != null and status(4) == "empty", "arrasto no vazio não planta e não fecha")
	# Plantar a horta inteira: 1 toque + 1 arrasto.
	farm.call("close_tray")
	empty_plots()
	toasts.clear()
	var whole := await open_tray(0)
	whole.call("tap_item", "carrot")
	var second := await open_tray(1)
	var every: Array[Vector2] = []
	for i in range(1, 9):
		every.append(finger_for(i))
	second.call("drag_through", "carrot", every)
	var planted := 0
	for i in 9:
		if status(i) == "growing": planted += 1
	check(planted == 9, "horta inteira (9) com 1 toque + 1 arrasto (%d)" % planted)
	empty_plots()


# --- 3 e 4. estufa e planta bloqueada ------------------------------------------------------------

func _test_greenhouse_and_locked() -> void:
	empty_plots()
	toasts.clear()
	var current := await open_tray(9)
	check(current != null, "bandeja na estufa")
	if current == null:
		return
	var ids: Array = current.call("entry_ids")
	check(not ("carrot" in ids) and ("herbs" in ids) and ("strawberry" in ids), "estufa oferece ervas/morango, não cenoura")
	check(current.find_child("Title", true, false) != null, "título Estufa")
	var seconds := int(Database_crop_seconds("herbs"))
	var caption := _caption_of(current, "herbs")
	check(caption == TimeText.short(int(round(seconds * 0.7))), "legenda considera a estufa (%s)" % caption)
	# Planta bloqueada: apagada, toque não planta e abre o "Como fazer".
	check("blueberry" in ids, "mirtilo aparece na estufa")
	var locked_item: Control = current.call("item_node", "blueberry")
	check(locked_item.find_child("Lock", true, false) != null, "bloqueada mostra cadeado")
	check((locked_item.find_child("Body", true, false) as Control).modulate.a < 0.6, "bloqueada fica apagada")
	sheets = 0
	toasts.clear()
	current.call("tap_item", "blueberry")
	check(status(9) == "empty", "tocar na bloqueada não planta")
	check(sheets == 1, "tocar na bloqueada abre o Como fazer")
	check(toasts.size() == 1, "e mostra o motivo")
	check(tray() == null, "o painel fecha a bandeja")
	# Rodapé "Ver tudo" abre o painel antigo.
	var again := await open_tray(9)
	var footer := again.find_child("FooterGhost", true, false) as Button
	check(footer != null, "rodapé Ver tudo")
	sheets = 0
	footer.pressed.emit()
	check(sheets == 1 and tray() == null, "Ver tudo abre o painel de sementes e fecha a bandeja")
	events.emit_signal("sheet_close_requested")


func Database_crop_seconds(crop_id: String) -> float:
	return float((root.get_node("Database").get("crops") as Dictionary)[crop_id].seconds)


func _caption_of(current: Control, id: String) -> String:
	var item: Control = current.call("item_node", id)
	return (item.find_child("Caption", true, false) as Label).text


# --- 5. colher e foice -------------------------------------------------------------------------------

func _test_harvest() -> void:
	empty_plots()
	toasts.clear()
	for i in 6:
		state.call("plant", i, "carrot")
	state.call("dev_finish_timers")
	farm.call("_animate_objects")
	var coins_before: int = state.get("coins")
	var carrots_before: int = state.get("inventory").call("count", "carrot")
	for i in 6:
		farm.call("_on_plot_tapped", i)
		await process_frame
		check(status(i) == "empty", "toque colhe a cenoura %d" % i)
		check(tray() == null, "colher %d não abre sementes nem foice" % i)
	check(state.get("coins") == coins_before, "colher não paga moeda (etapa 09)")
	check(state.get("inventory").call("count", "carrot") == carrots_before + 12, "seis toques colhem seis canteiros sem perda")
	# Plantar continua disponível no próximo toque deliberado num canteiro já vazio.
	farm.call("_on_plot_tapped", 0)
	await process_frame
	check(tray() != null, "tocar depois no canteiro vazio abre sementes")
	farm.call("close_tray")
	empty_plots()

# --- 6. armazenamento cheio -----------------------------------------------------------------------------

func _test_full_storage() -> void:
	empty_plots()
	toasts.clear()
	for i in 4:
		state.call("plant", i, "carrot")
	state.call("dev_finish_timers")
	farm.call("_animate_objects")
	var inventory: Object = state.get("inventory")
	var carrots: int = inventory.call("count", "carrot")
	inventory.call("add", "carrot", 5000)
	check(state.call("harvest_error", 1) != "", "depósito cheio: harvest_error explica")
	farm.call("_on_plot_tapped", 1)
	check(status(1) == "ready", "toque com depósito cheio não colhe")
	check(toasts.size() == 1, "um aviso só (do próprio harvest)")
	check(tray() == null, "e sem bandeja da foice (nada foi colhido)")
	# Foice na mão mesmo assim: arrastar não colhe nem perde plantas.
	var sickle_tray := PlotTrayScript().call("sickle", farm, 1) as Control
	await process_frame
	toasts.clear()
	sickle_tray.call("drag_through", "sickle", [finger_for(2), finger_for(3)] as Array[Vector2])
	check(status(2) == "ready" and status(3) == "ready", "arrasto com depósito cheio mantém as plantas")
	check(toasts.size() == 1, "o arrasto avisa só uma vez")
	toasts.clear()
	sickle_tray = PlotTrayScript().call("sickle", farm, 1) as Control
	await process_frame
	sickle_tray.call("tap_item", "all")
	check(status(2) == "ready", "Tudo também respeita o depósito")
	check(toasts.size() >= 1, "Tudo explica o motivo")
	inventory.call("remove", "carrot", int(inventory.call("count", "carrot")) - carrots)
	farm.call("close_tray")
	empty_plots()


func PlotTrayScript() -> Script:
	return load("res://scripts/ui/plot_tray.gd")


# --- 9. regar -------------------------------------------------------------------------------------------------

func _test_water() -> void:
	empty_plots()
	toasts.clear()
	for i in 4:
		state.call("plant", i, "carrot")
	sheets = 0
	var water_before: int = state.get("progress").stat("water")
	farm.call("_on_plot_tapped", 0)
	check(state.call("water_error", 0) == "Já foi regado", "toque num crescendo regável rega na hora")
	await process_frame
	var current := tray()
	check(current != null and (current.call("entry_ids") as Array) == ["water"], "bandeja do regador")
	if current == null:
		return
	check(_caption_of(current, "water") == "×3", "regador mostra os que faltam (%s)" % _caption_of(current, "water"))
	await process_frame
	current.call("drag_through", "water", [finger_for(1), finger_for(2), finger_for(1)] as Array[Vector2])
	check(state.call("water_error", 1) != "" and state.call("water_error", 2) != "", "arrasto regou 1 e 2")
	check(state.call("water_error", 3) == "", "3 ficou sem regar")
	check(state.get("progress").stat("water") == water_before + 3, "cada canteiro só uma vez (%d)" % (state.get("progress").stat("water") - water_before))
	# Tocar no regador rega o que faltar.
	await process_frame
	farm.call("_on_plot_tapped", 3)
	check(state.call("water_error", 3) != "", "toque rega o 3")
	check(tray() == null, "sem outros para regar não abre a bandeja")
	# Já regado: o toque mostra o tempo (cabeçalho com anel).
	farm.call("_on_plot_tapped", 3)
	await process_frame
	var care := tray()
	check(care != null and care.find_child("CareHeader", true, false) != null, "canteiro regado mostra o cabeçalho de tempo")
	check(care != null and (care.find_child("Time", true, false) as Label).text != "", "com o tempo restante")
	check(care != null and (care.find_child("Watered", true, false) as Control).visible, "e a marca de regado")
	check(care != null and care.find_child("FooterGhost", true, false) != null, "e Ver tudo")
	check(sheets == 0, "nada de painel grande")
	farm.call("close_tray")
	# Regador em tudo com um toque.
	empty_plots()
	for i in 4:
		state.call("plant", i, "carrot")
	farm.call("_on_plot_tapped", 0)
	await process_frame
	tray().call("tap_item", "water")
	var dry := 0
	for i in 4:
		if state.call("water_error", i) == "": dry += 1
	check(dry == 0, "tocar no regador rega todos")
	empty_plots()


# --- 8. fechar -----------------------------------------------------------------------------------------------------

func _test_closing() -> void:
	empty_plots()
	var current := await open_tray(5)
	check(current != null, "bandeja aberta")
	sheets = 0
	events.emit_signal("sheet_requested", "Teste", Label.new())
	check(tray() == null, "abrir um painel fecha a bandeja")
	events.emit_signal("sheet_close_requested")
	# Tocar fora fecha sem plantar (o toque é consumido).
	current = await open_tray(5)
	var outside: Vector2 = (farm.call("world_to_screen", farm.call("plot_center", 4)) as Vector2) - (farm.get("global_position") as Vector2)
	farm.call("_gui_input", mouse_event("press", outside))
	check(tray() == null, "tocar fora fecha a bandeja")
	farm.call("_gui_input", mouse_event("release", outside))
	check(status(4) == "empty" and status(5) == "empty", "o toque que fechou não plantou nada")
	check(tray() == null, "e não abriu outra bandeja")
	# O gesto seguinte volta ao normal.
	farm.call("_gui_input", mouse_event("press", outside))
	farm.call("_gui_input", mouse_event("release", outside))
	await process_frame
	check(tray() != null, "o próximo toque no canteiro abre a bandeja de novo")
	# Só existe uma bandeja por vez.
	farm.call("open_plot_tray", 6)
	await process_frame
	var trays := 0
	for child in farm.get_children():
		if child.get_script() == tray_script and not bool(child.get("closing")): trays += 1
	check(trays == 1, "uma bandeja por vez (%d)" % trays)
	# Câmera mexeu: fecha.
	var zoom: float = farm.get("_zoom")
	farm.call("_zoom_at", farm.size / 2.0, zoom * 1.3)
	check(tray() == null, "mexer na câmera fecha a bandeja")
	farm.call("recenter")
	await process_frame
	# Trocar de aba esconde a sala: fecha.
	await open_tray(5)
	main.call("show_screen", &"pet")
	await process_frame
	check(tray() == null, "trocar de aba fecha a bandeja")
	main.call("show_screen", &"map")
	await process_frame
	# Fecha sozinha (auto_close) depois de ficar parada.
	farm.call("_on_plot_tapped", 0)  # vazio: abre sementes (sem auto_close)
	farm.call("close_tray")
	state.call("plant", 7, "carrot")
	state.call("water", 7)
	farm.call("_on_plot_tapped", 7)
	await process_frame
	var care := tray()
	check(care != null, "bandeja de cuidado")
	if care:
		care.call("_process", 3.5)
		check(tray() == null, "auto_close fecha a bandeja depois de 3 s")
	empty_plots()


# --- Rolagem na borda --------------------------------------------------------------------------------------------------

func _test_edge_scroll() -> void:
	empty_plots()
	farm.call("recenter")
	await process_frame
	var current := await open_tray(1)
	var before: Vector2 = farm.get("_content").position
	var edge := Vector2(farm.size.x - 10.0, finger_for(1).y)
	current.call("press_item", 0, current.call("item_center", "carrot"))
	current.call("move_item", edge)
	for i in 5:
		await process_frame
	var after: Vector2 = farm.get("_content").position
	check(after.x < before.x, "fantasma na borda direita rola a câmera (%.1f → %.1f)" % [before.x, after.x])
	check(tray() != null and current.call("is_dragging"), "rolar não fecha a bandeja")
	current.call("release_item", edge)
	farm.call("close_tray")
	farm.call("recenter")
	await process_frame
	empty_plots()


# --- 7.5 mãozinha de ensino ---------------------------------------------------------------------------------------------

func _test_hint() -> void:
	empty_plots()
	farm.call("recenter")
	await process_frame
	state.get("progress").seen.erase("ui:tray_drag_hint")
	var current := await open_tray(0)
	await process_frame
	check(current.find_child("HintHand", true, false) != null, "primeira bandeja com 2+ vazios mostra a mãozinha")
	var label := current.find_child("HintLabel", true, false) as Label
	check(label != null and label.text == "Arraste até a terra", "legenda do arrasto")
	check(not bool(state.get("progress").seen.get("ui:tray_drag_hint", false)), "ainda não marcou como visto")
	current.call("tap_item", "carrot")
	check(bool(state.get("progress").seen.get("ui:tray_drag_hint", false)), "plantar marca a dica como vista")
	empty_plots()
	var second := await open_tray(0)
	await process_frame
	check(second.find_child("HintHand", true, false) == null, "depois de vista a dica não volta")
	farm.call("close_tray")
	# Pegou no item: a mãozinha some.
	state.get("progress").seen.erase("ui:tray_drag_hint")
	var third := await open_tray(0)
	await process_frame
	third.call("press_item", 0, third.call("item_center", "carrot"))
	await process_frame
	check(third.find_child("HintHand", true, false) == null, "tocar no item esconde a mãozinha")
	third.call("release_item", Vector2.ZERO)
	farm.call("close_tray")
	# A foice ensina uma vez.
	empty_plots()
	for i in 4:
		state.call("plant", i, "carrot")
	state.call("dev_finish_timers")
	state.get("progress").seen.erase("ui:tray_harvest_hint")
	PlotTrayScript().call("sickle", farm, 0)
	await process_frame
	await process_frame
	var sickle := tray()
	check(sickle != null and sickle.find_child("HintHand", true, false) != null, "foice mostra a mãozinha na primeira vez")
	if sickle:
		sickle.call("drag_through", "sickle", [finger_for(1), finger_for(2)] as Array[Vector2])
	check(bool(state.get("progress").seen.get("ui:tray_harvest_hint", false)), "colher marca a dica da foice")
	empty_plots()


# --- Evento real (mouse/toque emulado) ---------------------------------------------------------------------------------------

func _test_real_input() -> void:
	empty_plots()
	farm.call("recenter")
	await process_frame
	var current := await open_tray(1)
	if current == null:
		check(false, "bandeja para o teste de eventos")
		return
	var start: Vector2 = current.call("item_center", "carrot")
	send("carrot", mouse_event("press", start))
	for point: Vector2 in [start + Vector2(0, -30), finger_for(1), finger_for(2), finger_for(3)]:
		send("carrot", mouse_event("motion", point))
		await process_frame
	check(current.call("is_dragging"), "evento de mouse real começa o arrasto")
	send("carrot", mouse_event("release", finger_for(3)))
	await process_frame
	check(status(1) == "growing" and status(2) == "growing" and status(3) == "growing", "arrasto por eventos reais planta 1, 2 e 3")
	check(farm.get("tray_dragging") == false, "e solta o mundo no fim")
	# Toque simples (sem mover) num item é toque.
	empty_plots()
	var tap_tray := await open_tray(4)
	var item: Vector2 = tap_tray.call("item_center", "carrot")
	send("carrot", mouse_event("press", item))
	send("carrot", mouse_event("motion", item + Vector2(3, 2)))
	send("carrot", mouse_event("release", item + Vector2(3, 2)))
	await process_frame
	check(status(4) == "growing", "toque com tremida pequena (< 12 px) continua sendo toque")
	empty_plots()


# --- Outros caminhos ("Ir", painel de canteiros) -------------------------------------------------------------------------------

func _test_other_paths() -> void:
	empty_plots()
	farm.call("recenter")
	await process_frame
	toasts.clear()
	var places: Script = load("res://scripts/ui/places.gd")
	# "Ir" com planta pedida: bandeja no primeiro canteiro vazio, planta em primeiro e destacada.
	state.call("plant", 0, "carrot")
	places.call("run", "farm", "crop:potato")
	await process_frame
	await process_frame
	var current := tray()
	check(current != null, "Ir com planta abre a bandeja")
	if current:
		check((current.call("entry_ids") as Array)[0] == "potato", "planta pedida vem primeiro")
		var circle := (current.call("item_node", "potato") as Control).find_child("Circle", true, false) as Panel
		var style := circle.get_theme_stylebox("panel") as StyleBoxFlat
		check(style.border_width_left == 3 and style.border_color == Palette.PRIMARY, "e destacada com borda verde")
		current.call("tap_item", "potato")
		check(status(1) == "growing", "plantou no primeiro vazio (o 1, porque o 0 está ocupado)")
	# Sem canteiro vazio: aponta e avisa.
	for i in 9:
		if status(i) == "empty":
			state.call("plant", i, "carrot")
	for i in range(9, 13):
		state.call("plant", i, "herbs")
	toasts.clear()
	places.call("run", "farm", "crop:carrot")
	await process_frame
	check(tray() == null and "Todos os canteiros estão ocupados" in toasts, "sem vazio: aviso 'Todos os canteiros estão ocupados'")
	check(farm.find_child("Pointer", true, false) != null, "e a seta aponta o primeiro canteiro")
	farm.call("clear_pointer")
	# Ir geral: abre as sementes direto, sem passar pelo resumo antigo.
	empty_plots()
	var worlds: Control = main.find_child("WorldsScreen", true, false)
	worlds.call("enter", "farm", "plots")
	await create_timer(1.3).timeout
	var sheet: Control = main.find_child("Sheet", true, false)
	check(tray() != null and "carrot" in tray().call("entry_ids"), "Ir para canteiros abre sementes direto")
	check(not sheet.call("is_open"), "Ir para canteiros não abre o painel antigo")
	farm.call("close_tray")
	# Estufa respeita seus próprios canteiros, mesmo com a horta vazia.
	places.call("run", "farm", "place:greenhouse")
	await process_frame
	check(tray() != null and "herbs" in tray().call("entry_ids"), "Ir para estufa abre suas sementes")
	farm.call("close_tray")
	for i in 9:
		state.call("plant", i, "carrot")
	places.call("run", "farm", "plots")
	await process_frame
	check(tray() != null and "water" in tray().call("entry_ids"), "horta ocupada abre cuidado, sem usar vazios da estufa")
	farm.call("close_tray")
	state.call("dev_finish_timers")
	places.call("run", "farm", "plots")
	await process_frame
	check(tray() != null and "sickle" in tray().call("entry_ids"), "horta pronta abre foice direto")
	check(status(0) == "ready", "Ir não colhe automaticamente")
	farm.call("close_tray")
	empty_plots()
	# A consulta explícita continua disponível e leva à bandeja ao tocar na grade.
	places.call("open", "farm", "plots")
	await create_timer(0.3).timeout
	var tile: Button = null
	for button: Button in sheet.find_children("*", "Button", true, false):
		if button.text == "Livre":
			tile = button
			break
	check(tile != null, "resumo de canteiros tem canteiros livres (sem botão Plantar)")
	check(sheet.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return b.text == "Plantar").is_empty(), "os botões Plantar saíram da grade")
	if tile:
		tile.pressed.emit()
		for i in 30: await process_frame
		check(tray() != null, "tocar numa linha do resumo abre a bandeja")
		check(not sheet.call("is_open"), "e fecha o painel")
	farm.call("close_tray")
	empty_plots()


## Entrega o evento ao item da bandeja pelo mesmo sinal que o motor usa (o DisplayServer sem janela não despacha GUI).
func send(id: String, event: InputEvent) -> void:
	var current: Control = tray_script.get("current")
	if is_instance_valid(current):
		(current.call("item_node", id) as Control).gui_input.emit(event)
