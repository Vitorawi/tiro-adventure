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
var dock_script: Script
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
	dock_script = load("res://scripts/ui/farm_dock.gd")
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
	await _test_first_water_hint()

	print("TRAY TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


func _test_first_water_hint() -> void:
	main.call("_on_world_requested", "farm", "")
	for i in 4: await process_frame
	empty_plots()
	state.get("progress").claimed_quests.erase("first_harvest")
	state.get("progress").stats.water = 0
	farm.call("clear_pointer")
	check(farm.call("plant_plot", 0, "carrot") == "", "primeira plantação real")
	for i in 4: await process_frame
	check(is_instance_valid(farm.get("_pointer")), "plantar antes da primeira rega aponta o canteiro")
	check(not bool(state.call("plot", 0).get("watered", false)), "seta não rega sozinha")
	if "--water-guide-shots" in OS.get_cmdline_user_args():
		var folder := ProjectSettings.globalize_path("res://../build/screenshots/care_guides")
		DirAccess.make_dir_recursive_absolute(folder)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder.path_join("first_water.png"))
	farm.call("_on_plot_tapped", 0)
	check(bool(state.call("plot", 0).get("watered", false)), "toque indicado rega de verdade")
	check(not is_instance_valid(farm.get("_pointer")), "rega remove indicação")
	farm.call("plant_plot", 1, "carrot")
	for i in 4: await process_frame
	check(not is_instance_valid(farm.get("_pointer")), "não repete orientação depois de aprender a regar")
	empty_plots()
	state.get("progress").stats.water = 0
	state.get("progress").claimed_quests.first_harvest = true
	farm.call("plant_plot", 0, "carrot")
	for i in 4: await process_frame
	check(not is_instance_valid(farm.get("_pointer")), "missão concluída também dispensa seta")


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

## Barra da horta aberta agora (null se não há ou se está fechando).
func dock() -> Control:
	var current: Variant = dock_script.call("current")
	return current as Control if current is Control and is_instance_valid(current) else null


func open_dock(index: int) -> Control:
	farm.call("close_tray")
	farm.call("open_plot_tray", index)
	await process_frame
	await process_frame
	return dock()


func center_of(index: int) -> Vector2:
	return farm.call("world_to_screen", farm.call("plot_center", index)) as Vector2


func PlotTrayScript() -> Script:
	return load("res://scripts/ui/plot_tray.gd")


func tile_caption(current: Control, id: String) -> String:
	var tile: Control = current.call("tile_node", id)
	return (tile.get_node("Visual").get_child(1) as Label).text


# --- 1. toque no canteiro vazio ----------------------------------------------------------------

func _test_tap_plants() -> void:
	toasts.clear()
	empty_plots()
	farm.call("_animate_objects")
	var point: Vector2 = farm.call("plot_center", 0)
	check(farm.call("_handle_tap", point), "toque no canteiro 0 é tratado")
	await process_frame
	await process_frame
	var current := dock()
	check(current != null, "tocar no canteiro vazio abre a barra da horta")
	if current == null:
		return
	check(sheets == 0, "nenhum painel grande abriu")
	check(tray() == null, "nenhuma bandeja de ação sobre os canteiros")
	var ids: Array = current.call("entry_ids")
	check("carrot" in ids, "barra oferece cenoura")
	check(not ("herbs" in ids), "sítio não oferece plantas da estufa")
	check(ids[0] != "blueberry", "bloqueadas vão para o fim")
	check(status(0) == "growing", "o toque que abriu a barra já plantou")
	var nav := main.find_child("TabBar", true, false) as Control
	check(current.global_position.y + current.size.y <= nav.global_position.y + 1.0, "barra apoiada acima do rodapé")
	check(toasts.is_empty(), "plantar não gera aviso de erro")
	# A última semente usada vem selecionada.
	empty_plots()
	current.call("tap_tile", "potato")
	await process_frame
	current.call("drag_plots", [3])
	check(status(3) == "growing" and state.call("plot", 3)["crop"] == "potato", "escolher a batata e tocar no canteiro planta batata")
	var again := await open_dock(4)
	check(again != null and again.get("selected") == "potato", "última semente usada vem selecionada")
	farm.call("close_tray")
	empty_plots()


# --- 2. arrastar a partir do canteiro ----------------------------------------------------------

func _test_drag_plant() -> void:
	toasts.clear()
	empty_plots()
	state.call("plant", 0, "carrot")
	var planted_at: float = state.call("plot", 0)["planted_at"]
	var before: Vector2 = farm.get("_content").position
	var current := await open_dock(1)
	check(current != null, "barra no canteiro 1")
	var path: Array[Vector2] = [center_of(1), center_of(2), center_of(3), center_of(0)]
	current.call("drag_points", path, false)
	check(current.call("gesture_active"), "arrastando: o gesto está ativo")
	check(farm.find_child("Ghost", true, false) != null, "ficha da semente aparece")
	check(farm.find_child("FarmGesture", true, false) != null, "rastro e alvos desenhados")
	check((farm.get("_content") as Control).position == before, "câmera parada durante o gesto")
	current.call("release_drag")
	check(status(1) == "growing" and status(2) == "growing" and status(3) == "growing", "arrasto plantou 1, 2 e 3")
	check(float(state.call("plot", 0)["planted_at"]) == planted_at, "canteiro 0 (já plantado) ficou intacto")
	check(state.call("plot", 0)["crop"] == "carrot", "0 continua cenoura")
	check(toasts.is_empty(), "nenhum aviso de erro no arrasto")
	check(dock() != null and not current.call("gesture_active"), "a barra continua aberta e o gesto acabou")
	# Plantar a horta inteira com um arrasto começando em qualquer canteiro.
	farm.call("close_tray")
	empty_plots()
	toasts.clear()
	var whole := await open_dock(0)
	check(whole != null and status(0) == "empty", "abrir pelo Ir não planta")
	whole.call("drag_plots", [0, 1, 2, 3, 4, 5, 6, 7, 8])
	var planted := 0
	for i in 9:
		if status(i) == "growing": planted += 1
	check(planted == 9, "horta inteira (9) com um arrasto (%d)" % planted)
	empty_plots()


# --- 3 e 4. estufa e planta bloqueada ------------------------------------------------------------

func _test_greenhouse_and_locked() -> void:
	empty_plots()
	toasts.clear()
	var current := await open_dock(9)
	check(current != null, "barra na estufa")
	if current == null:
		return
	var ids: Array = current.call("entry_ids")
	check(not ("carrot" in ids) and ("herbs" in ids) and ("strawberry" in ids), "estufa oferece ervas/morango, não cenoura")
	var seconds := int(Database_crop_seconds("herbs"))
	var caption := tile_caption(current, "herbs")
	check(caption == TimeText.short(int(round(seconds * 0.7))), "legenda considera a estufa (%s)" % caption)
	# Arrastar de um canteiro comum para a estufa só age nos compatíveis.
	current.call("tap_tile", "herbs")
	await process_frame
	current.call("drag_plots", [0, 9, 10])
	check(status(0) == "empty", "ervas não entram no canteiro comum")
	check(status(9) == "growing" and status(10) == "growing", "mas entram na estufa")
	empty_plots()
	# Planta bloqueada: apagada, toque não planta e abre o "Como fazer".
	check("blueberry" in ids, "mirtilo aparece na estufa")
	var locked_tile: Control = current.call("tile_node", "blueberry")
	check(locked_tile.find_child("LockIcon", true, false) != null, "bloqueada mostra cadeado")
	check((locked_tile.get_node("Visual/Picture") as Control).modulate.a < 0.6, "bloqueada fica apagada")
	sheets = 0
	toasts.clear()
	current.call("tap_tile", "blueberry")
	check(status(9) == "empty", "tocar na bloqueada não planta")
	check(sheets == 1, "tocar na bloqueada abre o Como fazer")
	check(dock() == null, "o painel fecha a barra")
	events.emit_signal("sheet_close_requested")


func Database_crop_seconds(crop_id: String) -> float:
	return float((root.get_node("Database").get("crops") as Dictionary)[crop_id].seconds)


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
		await process_frame
		check(status(i) == "empty", "toque colhe a cenoura %d" % i)
		check(tray() == null, "colher %d não abre bandeja sobre os canteiros" % i)
		if i < 5:
			check(dock() != null and dock().get("mode") == "harvest", "sobraram prontos: barra em colher (%d)" % i)
	check(dock() == null, "sem prontos a barra de colher se fecha")
	check(state.get("coins") == coins_before, "colher não paga moeda (etapa 09)")
	check(state.get("inventory").call("count", "carrot") == carrots_before + 12, "seis toques colhem seis canteiros sem perda")
	# Plantar continua disponível no próximo toque deliberado num canteiro já vazio.
	farm.call("_on_plot_tapped", 0)
	await process_frame
	check(dock() != null and dock().get("mode") == "plant", "tocar depois no canteiro vazio abre a barra de sementes")
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
	await process_frame
	await process_frame
	check(status(1) == "ready", "toque com depósito cheio não colhe")
	check(toasts.size() == 1, "um aviso só (do próprio harvest)")
	var current := dock()
	check(current != null and current.find_child("LockHint", true, false) != null, "a barra de colher mostra o depósito cheio")
	check(current != null and current.find_child("HarvestAll", true, false) == null, "sem botão de colher tudo")
	# Foice na mão mesmo assim: arrastar não colhe nem perde plantas, avisando uma vez.
	toasts.clear()
	if current:
		current.call("drag_plots", [2, 3])
	check(status(2) == "ready" and status(3) == "ready", "arrasto com depósito cheio mantém as plantas")
	check(toasts.size() == 1, "o arrasto avisa só uma vez")
	toasts.clear()
	var entries: Array = PlotTrayScript().call("sickle_entries", farm)
	var reason: String = (entries[1].tap as Callable).call()
	check(status(2) == "ready" and reason != "", "Tudo também respeita o depósito e explica")
	inventory.call("remove", "carrot", int(inventory.call("count", "carrot")) - carrots)
	farm.call("close_tray")
	empty_plots()


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
	await process_frame
	var current := dock()
	check(current != null and current.get("selected") == "water", "a barra abre com o regador escolhido")
	if current == null:
		return
	check(tile_caption(current, "water") == "×3", "regador mostra os que faltam (%s)" % tile_caption(current, "water"))
	current.call("drag_plots", [1, 2, 1])
	check(state.call("water_error", 1) != "" and state.call("water_error", 2) != "", "arrasto regou 1 e 2")
	check(state.call("water_error", 3) == "", "3 ficou sem regar")
	check(state.get("progress").stat("water") == water_before + 3, "cada canteiro só uma vez (%d)" % (state.get("progress").stat("water") - water_before))
	# Tocar no último rega e não abre mais nada.
	await process_frame
	farm.call("_on_plot_tapped", 3)
	check(state.call("water_error", 3) != "", "toque rega o 3")
	await process_frame
	check(dock() == null, "sem outros para regar não abre a barra")
	# Já regado: o toque mostra o tempo (cabeçalho com anel) num balão.
	farm.call("_on_plot_tapped", 3)
	await process_frame
	await process_frame
	var care := farm.find_child("CareHeader", true, false)
	check(care != null, "canteiro regado mostra o cabeçalho de tempo")
	check(care != null and (care.find_child("Time", true, false) as Label).text != "", "com o tempo restante")
	check(care != null and (care.find_child("Watered", true, false) as Control).visible, "e a marca de regado")
	check(care != null and farm.find_child("Popover", true, false) != null, "dentro de um balão (Popover)")
	check(sheets == 0 and tray() == null and dock() == null, "nada de painel grande nem de barra")
	var popover := farm.find_child("Popover", true, false)
	if popover:
		popover.call("close")
		await process_frame
	farm.call("close_tray")
	# Regador em tudo: escolhido, arrastando por todos.
	empty_plots()
	for i in 4:
		state.call("plant", i, "carrot")
	farm.call("_on_plot_tapped", 0)
	await process_frame
	await process_frame
	dock().call("drag_plots", [0, 1, 2, 3])
	var dry := 0
	for i in 4:
		if state.call("water_error", i) == "": dry += 1
	check(dry == 0, "arrastar o regador rega todos")
	farm.call("close_tray")
	empty_plots()


# --- 8. fechar -----------------------------------------------------------------------------------------------------

func _test_closing() -> void:
	empty_plots()
	var current := await open_dock(5)
	check(current != null, "barra aberta")
	sheets = 0
	events.emit_signal("sheet_requested", "Teste", Label.new())
	check(dock() == null, "abrir um painel fecha a barra")
	events.emit_signal("sheet_close_requested")
	# Tocar fora de canteiros e da barra fecha sem plantar (o toque é consumido).
	current = await open_dock(5)
	var outside := farm.global_position + Vector2(20, 200)
	farm.call("_gui_input", mouse_event("press", outside))
	farm.call("_gui_input", mouse_event("release", outside))
	check(dock() == null, "tocar fora fecha a barra")
	check(status(4) == "empty" and status(5) == "empty", "o toque que fechou não plantou nada")
	# Só existe uma barra por vez.
	await open_dock(5)
	await open_dock(6)
	var docks := 0
	for node in main.find_children("FarmDock", "", true, false):
		if not bool(node.get("closing")): docks += 1
	check(docks == 1, "uma barra por vez (%d)" % docks)
	# Mexer na câmera não fecha a barra (ela não aponta para um ponto do mundo).
	var zoom: float = farm.get("_zoom")
	farm.call("_zoom_at", farm.size / 2.0, zoom * 1.3)
	check(dock() != null, "mexer na câmera não fecha a barra")
	farm.call("recenter")
	await process_frame
	# Trocar de aba esconde a sala: fecha.
	main.call("show_screen", &"pet")
	await process_frame
	check(dock() == null, "trocar de aba fecha a barra")
	main.call("show_screen", &"map")
	await process_frame
	empty_plots()


# --- Rolagem na borda --------------------------------------------------------------------------------------------------

func _test_edge_scroll() -> void:
	empty_plots()
	farm.call("recenter")
	await process_frame
	var current := await open_dock(1)
	var before: Vector2 = farm.get("_content").position
	var edge := Vector2(farm.size.x - 10.0, center_of(1).y)
	current.call("press", center_of(1))
	current.call("move", edge)
	for i in 5:
		await process_frame
	var after: Vector2 = farm.get("_content").position
	check(after.x < before.x, "dedo na borda direita rola a câmera (%.1f → %.1f)" % [before.x, after.x])
	check(dock() != null and current.call("gesture_active"), "rolar não fecha a barra nem acaba o gesto")
	current.call("release", edge)
	farm.call("close_tray")
	farm.call("recenter")
	await process_frame
	empty_plots()


# --- Dica "Arraste pelos canteiros" (três primeiras aberturas) ---------------------------------------------------------

func _test_hint() -> void:
	empty_plots()
	farm.call("recenter")
	await process_frame
	state.get("progress").seen.erase("ui:tray_drag_hint")
	for time in 3:
		var current := await open_dock(0)
		await process_frame
		check(current != null and main.find_child("DragHint", true, false) != null, "abertura %d com 2+ vazios mostra a dica" % (time + 1))
		check(int(state.get("progress").seen.get("ui:tray_drag_hint", 0)) == time + 1, "a abertura conta (%s)" % str(state.get("progress").seen.get("ui:tray_drag_hint")))
		farm.call("close_tray")
		await process_frame
	var fourth := await open_dock(0)
	await process_frame
	check(fourth != null and main.find_child("DragHint", true, false) == null, "na quarta abertura a dica não volta")
	farm.call("close_tray")
	# Com menos de dois canteiros vazios a dica não aparece.
	state.get("progress").seen.erase("ui:tray_drag_hint")
	empty_plots()
	for i in range(1, 13):
		state.call("plant", i, "carrot" if i < 9 else "herbs")
	var few := await open_dock(0)
	await process_frame
	check(few != null and main.find_child("DragHint", true, false) == null, "um canteiro vazio só: sem dica")
	farm.call("close_tray")
	empty_plots()


# --- Evento real (mouse/toque emulado) ---------------------------------------------------------------------------------------

func _test_real_input() -> void:
	empty_plots()
	farm.call("recenter")
	await process_frame
	await open_dock(0)
	empty_plots()
	var start := center_of(1)
	farm.call("_gui_input", mouse_event("press", start))
	for point: Vector2 in [start + Vector2(3, 2), center_of(2), center_of(3)]:
		farm.call("_gui_input", mouse_event("motion", point))
		await process_frame
	farm.call("_gui_input", mouse_event("release", center_of(3)))
	await process_frame
	check(status(1) == "growing" and status(2) == "growing" and status(3) == "growing", "arrasto por eventos reais planta 1, 2 e 3")
	check(farm.get("tray_dragging") == false, "e o mundo não fica preso")
	# Toque simples com tremida pequena (< 12 px) continua sendo toque: planta um só.
	empty_plots()
	await open_dock(4)
	var spot := center_of(4)
	farm.call("_gui_input", mouse_event("press", spot))
	farm.call("_gui_input", mouse_event("motion", spot + Vector2(3, 2)))
	farm.call("_gui_input", mouse_event("release", spot + Vector2(3, 2)))
	await process_frame
	var planted := 0
	for i in 9:
		if status(i) == "growing": planted += 1
	check(status(4) == "growing" and planted == 1, "toque com tremida pequena planta só o canteiro tocado (%d)" % planted)
	farm.call("close_tray")
	empty_plots()


# --- Outros caminhos ("Ir", painel de canteiros) -------------------------------------------------------------------------------

func _test_other_paths() -> void:
	empty_plots()
	farm.call("recenter")
	await process_frame
	toasts.clear()
	var places: Script = load("res://scripts/ui/places.gd")
	# "Ir" com planta pedida: barra no primeiro canteiro vazio, planta pedida escolhida.
	state.call("plant", 0, "carrot")
	places.call("run", "farm", "crop:potato")
	await process_frame
	await process_frame
	var current := dock()
	check(current != null, "Ir com planta abre a barra")
	if current:
		check(current.get("selected") == "potato", "planta pedida já vem escolhida")
		check((current.call("entry_ids") as Array)[0] == "potato", "e vem primeiro")
		check(status(1) == "empty", "navegar não planta sozinho")
		current.call("drag_plots", [1])
		check(status(1) == "growing" and state.call("plot", 1)["crop"] == "potato", "plantou no canteiro tocado com a planta pedida")
	# Sem canteiro vazio: aponta e avisa.
	for i in 9:
		if status(i) == "empty":
			state.call("plant", i, "carrot")
	for i in range(9, 13):
		state.call("plant", i, "herbs")
	toasts.clear()
	farm.call("close_tray")
	places.call("run", "farm", "crop:carrot")
	await process_frame
	check(dock() == null and "Todos os canteiros estão ocupados" in toasts, "sem vazio: aviso 'Todos os canteiros estão ocupados'")
	check(farm.find_child("Pointer", true, false) != null, "e o alfinete aponta o primeiro canteiro")
	farm.call("clear_pointer")
	# Ir geral: abre a barra direto, sem passar pelo resumo antigo.
	empty_plots()
	var worlds: Control = main.find_child("WorldsScreen", true, false)
	worlds.call("enter", "farm", "plots")
	var deadline := Time.get_ticks_msec() + 3000
	while dock() == null and Time.get_ticks_msec() < deadline:
		await process_frame
	var sheet: Control = main.find_child("Sheet", true, false)
	check(dock() != null and "carrot" in dock().call("entry_ids"), "Ir para canteiros abre a barra de sementes direto")
	check(not sheet.call("is_open"), "Ir para canteiros não abre o painel antigo")
	farm.call("close_tray")
	# Estufa respeita seus próprios canteiros, mesmo com a horta vazia.
	places.call("run", "farm", "place:greenhouse")
	await process_frame
	check(dock() != null and "herbs" in dock().call("entry_ids"), "Ir para estufa abre suas sementes")
	farm.call("close_tray")
	empty_plots()
	for i in 9:
		state.call("plant", i, "carrot")
	state.call("dev_finish_timers")
	places.call("run", "farm", "plots")
	await process_frame
	await process_frame
	check(dock() != null and dock().get("mode") == "harvest", "horta pronta abre a barra de colher direto")
	check(status(0) == "ready", "Ir não colhe automaticamente")
	farm.call("close_tray")
	empty_plots()
	# A consulta explícita continua disponível e leva à barra ao tocar na grade.
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
		check(dock() != null, "tocar numa linha do resumo abre a barra")
		check(not sheet.call("is_open"), "e fecha o painel")
	farm.call("close_tray")
	empty_plots()
