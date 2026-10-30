extends SceneTree
## Interface 2, etapa 07: barra da horta (FarmDock) — plantar, regar e colher com o gesto começando no canteiro.
## Usa o Sítio de verdade (main.tscn), sem SaveManager.
## --headless --path game -s res://tests/farm_dock_test.gd

var failures := 0
var state: Node
var events: Node
var main: Control
var farm: Control
var dock_script: Script
var toasts: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FARM_DOCK: " + message)


func dock() -> Control:
	return dock_script.call("current") as Control


func empty_plots() -> void:
	var plots: Array = state.get("plots")
	for i in plots.size():
		plots[i] = {"crop": "", "ready_at": 0.0}
	state.call("_changed")


func status(index: int) -> String:
	return state.call("plot_status", index)


func center(index: int) -> Vector2:
	return farm.call("world_to_screen", farm.call("plot_center", index)) as Vector2


func mouse_event(kind: String, position: Vector2) -> InputEvent:
	if kind == "motion":
		var motion := InputEventMouseMotion.new()
		motion.position = position - farm.global_position
		motion.global_position = position
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		motion.relative = Vector2(30, 0)
		return motion
	var button := InputEventMouseButton.new()
	button.button_index = MOUSE_BUTTON_LEFT
	button.pressed = kind == "press"
	button.position = position - farm.global_position
	button.global_position = position
	button.button_mask = MOUSE_BUTTON_MASK_LEFT if button.pressed else 0
	return button


func open_plant(index: int) -> void:
	farm.call("close_tray")
	farm.call("_on_plot_tapped", index)
	await process_frame
	await process_frame


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	events = root.get_node("Events")
	dock_script = load("res://scripts/ui/farm_dock.gd")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.set("unlocked_plots", 9)
	state.set("coins", 5000)
	Motion.reduced = true
	events.toast_requested.connect(func(text: String) -> void: toasts.append(text))
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
	farm.call("recenter")
	await process_frame
	empty_plots()
	(state.get("inventory") as RefCounted).call("from_dict", {})

	await _test_tap_plants()
	await _test_drag_plants()
	await _test_drag_outside_moves_camera()
	await _test_camera_and_pinch_keep_dock()
	await _test_water()
	await _test_harvest()
	await _test_outside_closes()
	await _test_layout()
	await _test_real_events()
	await _test_position()
	await _test_scroll_select_ghost()
	await _test_next_locked()
	await _test_first_flow()

	print("FARM DOCK TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# 1 — tocar num canteiro vazio planta nele e abre a barra com a semente usada selecionada.
func _test_tap_plants() -> void:
	empty_plots()
	await open_plant(3)
	var current := dock()
	check(current != null, "tocar num canteiro vazio abre o FarmDock")
	if current == null:
		return
	check(status(3) == "growing", "o toque já é o primeiro plantio")
	check(str(current.get("mode")) == "plant", "barra em modo plantar")
	var selected: String = current.get("selected")
	check(selected != "" and selected != "water", "uma semente vem selecionada")
	check(state.get("plots")[3]["crop"] == selected, "planta a semente selecionada")
	check(current.call("tile_node", "water") != null, "tile Regar na barra")
	# Escolher outra semente e tocar de novo: planta a nova e ela vira a selecionada ao reabrir.
	var ids: Array = current.call("entry_ids")
	var other := ""
	for id: String in ids:
		if id != "water" and id != selected and str(current.call("selected_entry").get("error", "")) == "":
			var entry: Dictionary = {}
			for candidate: Dictionary in current.get("entries"):
				if candidate.id == id:
					entry = candidate
			if str(entry.get("error", "")) == "":
				other = id
				break
	if other != "":
		current.call("tap_tile", other)
		await process_frame
		check(current.get("selected") == other, "tocar no tile escolhe a semente")
		current.call("drag_plots", [5])  # plantar com ela a torna a última usada
		check(state.get("plots")[5]["crop"] == other, "tocar num canteiro com a semente escolhida planta ela")
		farm.call("close_tray")
		await open_plant(4)
		check(dock() != null and dock().get("selected") == other, "a última usada volta selecionada")
		check(state.get("plots")[4]["crop"] == other, "e é a que planta")
	farm.call("close_tray")


# 2 — gesto começando no canteiro 3, passando por 4, 5 e por um já plantado: planta só os vazios, a câmera fica.
func _test_drag_plants() -> void:
	empty_plots()
	farm.call("recenter")
	await process_frame
	await open_plant(0)
	var current := dock()
	state.call("plant", 4, "carrot")
	state.call("plant", 0, "carrot")
	empty_plots()
	state.call("plant", 4, "carrot")  # já plantado no meio do caminho
	var before: Vector2 = (farm.get("_content") as Control).position
	var crop_before: String = state.get("plots")[4]["crop"]
	var ready_before: float = state.get("plots")[4]["ready_at"]
	if current == null:
		check(false, "barra para o gesto")
		return
	current.call("select", str(current.call("selected_entry").get("id", "carrot")))
	var selected: String = current.get("selected")
	current.call("drag_plots", [3, 5, 4, 6])
	await process_frame
	check(status(3) == "growing" and status(5) == "growing" and status(6) == "growing", "plantou nos vazios do caminho")
	check(state.get("plots")[3]["crop"] == selected and state.get("plots")[5]["crop"] == selected, "com a semente escolhida")
	check(state.get("plots")[4]["crop"] == crop_before and is_equal_approx(float(state.get("plots")[4]["ready_at"]), ready_before), "o canteiro já plantado não mudou")
	check(status(0) == "empty" and status(1) == "empty", "fora do caminho continua vazio")
	check((farm.get("_content") as Control).position.is_equal_approx(before), "a câmera não se moveu")
	check(not bool(current.call("gesture_active")), "o gesto acabou ao soltar")
	farm.call("close_tray")


# 3 — dedo que começa fora dos canteiros mexe a câmera e não planta.
func _test_drag_outside_moves_camera() -> void:
	empty_plots()
	farm.call("recenter")
	await process_frame
	await open_plant(0)
	empty_plots()
	var before: Vector2 = (farm.get("_content") as Control).position
	var start := farm.global_position + Vector2(20, 200)  # céu, sempre sem canteiro
	farm.call("_gui_input", mouse_event("press", start))
	for step in 4:
		farm.call("_gui_input", mouse_event("motion", start + Vector2(30.0 * (step + 1), 10.0)))
	farm.call("_gui_input", mouse_event("release", start + Vector2(120, 10)))
	await process_frame
	check(not (farm.get("_content") as Control).position.is_equal_approx(before), "começando fora dos canteiros a câmera anda")
	var planted := 0
	for i in 13:
		if status(i) != "empty" and status(i) != "locked":
			planted += 1
	check(planted == 0, "e nada é plantado")
	farm.call("close_tray")


# 3b — ajustes, etapa 04 (item 9): mexer na câmera e a pinça NÃO fecham a barra da horta; a pinça só cancela o gesto.
func _test_camera_and_pinch_keep_dock() -> void:
	empty_plots()
	farm.call("recenter")
	await process_frame
	await open_plant(0)
	check(dock() != null, "a barra abre")
	farm.call("scroll_by", Vector2(40, 0))
	farm.call("_set_camera", (farm.call("screen_to_world", farm.global_position + farm.size / 2.0) as Vector2) + Vector2(30, 0), farm.get("_zoom") as float)
	await process_frame
	check(dock() != null, "mexer na câmera não fecha a barra")
	var current := dock()
	var before: int = (state.get("plots") as Array).filter(func(p: Dictionary) -> bool: return str(p.get("crop", "")) != "").size()
	current.call("press", center(1))
	check(bool(current.call("gesture_active")), "o gesto começa no canteiro")
	farm.call("_set_touch", 0, center(1))
	farm.call("_set_touch", 1, center(1) + Vector2(80, 0))
	check(bool(farm.call("_is_pinching")), "dois dedos são uma pinça")
	current.call("move", center(2))
	check(not bool(current.call("gesture_active")), "a pinça cancela o gesto")
	check(dock() == current, "a pinça não fecha a barra")
	(farm.get("_touches") as Dictionary).clear()
	current.call("release_drag")
	var after: int = (state.get("plots") as Array).filter(func(p: Dictionary) -> bool: return str(p.get("crop", "")) != "").size()
	check(after <= before + 1, "a pinça não planta nos canteiros seguintes (%d → %d)" % [before, after])
	farm.call("close_tray")


# 4 — Regar escolhido: arrastar por dois canteiros crescendo rega os dois.
func _test_water() -> void:
	empty_plots()
	farm.call("recenter")
	await process_frame
	state.call("plant", 1, "carrot")
	state.call("plant", 2, "carrot")
	state.call("plant", 3, "carrot")
	farm.call("open_farm_dock", "plant", 1, "water")
	await process_frame
	await process_frame
	var current := dock()
	if current == null:
		check(false, "barra com o regador")
		return
	check(current.get("selected") == "water", "Regar vem escolhido")
	check(state.call("water_error", 1) == "" and state.call("water_error", 2) == "", "crescendo e regáveis antes")
	current.call("drag_plots", [1, 2])
	check(state.call("water_error", 1) != "" and state.call("water_error", 2) != "", "os dois foram regados")
	check(state.call("water_error", 3) == "", "o terceiro, fora do gesto, não")
	farm.call("close_tray")


# 5 — prontos: tocar num colhe só ele e abre a barra em colher; "Colher tudo (2)"; depósito cheio = lock_hint.
func _test_harvest() -> void:
	empty_plots()
	toasts.clear()
	farm.call("recenter")
	await process_frame
	var inventory: Object = state.get("inventory")
	inventory.call("from_dict", {})
	for i in 3:
		state.call("plant", i, "carrot")
	state.call("dev_finish_timers")
	farm.call("_animate_objects")
	farm.call("_on_plot_tapped", 0)
	await process_frame
	await process_frame
	check(status(0) == "empty" and status(1) == "ready" and status(2) == "ready", "o toque colheu só o canteiro tocado")
	var current := dock()
	check(current != null and current.get("mode") == "harvest", "sobraram prontos: barra em colher")
	if current == null:
		return
	var all := current.find_child("HarvestAll", true, false) as Button
	check(all != null and all.text == "Colher tudo (2)", "botão verde mostra a quantidade")
	# Depósito cheio: o verde vira lock_hint e nada é colhido.
	var carrots: int = inventory.call("count", "carrot")
	inventory.call("add", "carrot", 5000)
	events.emit_signal("state_changed")
	await process_frame
	await process_frame
	current = dock()
	check(current != null and current.find_child("LockHint", true, false) != null, "depósito cheio troca o verde por lock_hint")
	check(current != null and current.find_child("HarvestAll", true, false) == null, "sem botão de colher")
	check(status(1) == "ready" and status(2) == "ready", "nada foi colhido")
	inventory.call("remove", "carrot", int(inventory.call("count", "carrot")) - carrots)
	events.emit_signal("state_changed")
	await process_frame
	await process_frame
	current = dock()
	all = current.find_child("HarvestAll", true, false) as Button if current else null
	check(all != null, "com espaço o botão volta")
	if all:
		all.pressed.emit()
		await process_frame
	check(status(1) == "empty" and status(2) == "empty", "Colher tudo colhe os outros dois")
	await process_frame
	check(dock() == null, "sem prontos a barra se fecha")
	farm.call("close_tray")


# 6 — tocar fora dos canteiros e da barra fecha a barra sem agir no mundo.
func _test_outside_closes() -> void:
	empty_plots()
	farm.call("recenter")
	await process_frame
	await open_plant(0)
	check(dock() != null, "barra aberta")
	var coins: int = state.get("coins")
	var spot := farm.global_position + Vector2(20, 200)
	farm.call("_gui_input", mouse_event("press", spot))
	farm.call("_gui_input", mouse_event("release", spot))
	await process_frame
	await process_frame
	check(dock() == null, "toque fora fecha a barra")
	check(state.get("coins") == coins, "sem agir no mundo")
	check(status(1) == "empty", "e sem plantar")


# 7 — a barra fica acima do rodapé e nenhum tile tem alvo menor que 44.
func _test_layout() -> void:
	empty_plots()
	await open_plant(0)
	await process_frame
	var current := dock()
	if current == null:
		check(false, "barra para o layout")
		return
	var nav := main.find_child("TabBar", true, false) as Control
	check(current.global_position.y + current.size.y <= nav.global_position.y + 1.0, "barra acima do rodapé")
	var smallest := 999.0
	var count := 0
	for id: String in current.call("entry_ids"):
		var tile := current.call("tile_node", id) as Control
		if tile:
			count += 1
			smallest = minf(smallest, minf(tile.size.x, tile.size.y))
	check(count >= 2 and smallest >= 44.0, "tiles com alvo de 44 px ou mais (menor %s)" % smallest)
	check(current.find_child("CloseDock", true, false) != null, "botão de fechar")
	farm.call("close_tray")


# Eventos de mouse reais pela sala: começa no canteiro e planta por onde passa.
func _test_real_events() -> void:
	empty_plots()
	farm.call("recenter")
	await process_frame
	await open_plant(0)
	empty_plots()
	var start := center(1)
	farm.call("_gui_input", mouse_event("press", start))
	for point: Vector2 in [center(1) + Vector2(4, 0), center(2), center(3)]:
		farm.call("_gui_input", mouse_event("motion", point))
		await process_frame
	farm.call("_gui_input", mouse_event("release", center(3)))
	await process_frame
	check(status(1) == "growing" and status(2) == "growing" and status(3) == "growing", "eventos reais plantam 1, 2 e 3")
	check(farm.get("tray_dragging") == false, "e o mundo não fica preso")
	farm.call("close_tray")


func tile_center(id: String) -> Vector2:
	return (dock().call("tile_node", id) as Control).get_global_rect().get_center()


func dock_event(kind: String, position: Vector2) -> void:
	dock().call("_gui_input", mouse_event(kind, position))


## O menu abre EM CIMA do canteiro, centralizado e sem passar sob o HUD; a seta aponta para ele; ao fechar a
## câmera volta; sem lugar em cima, ele vira para baixo (seta para cima).
func _test_position() -> void:
	root.size = Vector2i(360, 780)  # celular em pé: a largura que decide quantos espaços cabem
	for i in 6: await process_frame
	empty_plots()
	farm.call("recenter")
	await process_frame
	await open_plant(4)
	await create_timer(0.1).timeout
	var current := dock()
	check(current != null, "menu aberto para o posicionamento")
	if current == null:
		return
	var plot := center(4)
	var rect := current.get_global_rect()
	check(rect.end.y <= plot.y, "o menu fica em cima do canteiro (%.0f <= %.0f)" % [rect.end.y, plot.y])
	check(rect.position.y >= 100.0, "e não passa sob o HUD (y %.0f)" % rect.position.y)
	check(rect.position.x >= 7.5 and rect.end.x <= farm.size.x - 7.5, "com 8 px de folga dos lados")
	var arrow := current.find_child("DockArrow", true, false) as TextureRect
	check(arrow != null and not arrow.flip_v, "a seta aponta para baixo")
	check(arrow != null and absf(arrow.get_global_rect().get_center().x - plot.x) <= 40.0, "e fica na altura do canteiro")
	var bar := main.find_child("WorldBar", true, false) as CanvasItem
	check(bar != null and not bar.visible, "a barra do mundo sai da frente")
	# Mexer na câmera: o menu acompanha o canteiro (nada de fechar).
	farm.call("scroll_by", Vector2(0, 30))
	await process_frame
	await process_frame
	check(dock() == current, "mexer na câmera não fecha o menu")
	check(current.get_global_rect().end.y <= center(4).y + 1.0, "e ele continua em cima do canteiro")
	# Sem lugar em cima: vira para baixo.
	farm.call("scroll_by", Vector2(0, -420))
	await process_frame
	await process_frame
	var low := center(4)
	var flipped := current.get_global_rect()
	check(flipped.position.y >= 100.0, "sempre abaixo do HUD (%.0f)" % flipped.position.y)
	if flipped.end.y > low.y:
		check(arrow.flip_v, "sem lugar em cima a seta aponta para cima")
	farm.call("close_tray")
	await process_frame
	await create_timer(0.5).timeout
	check(bar != null and bar.visible, "ao fechar a barra do mundo volta")
	farm.call("recenter")
	await process_frame


## Rolar para os lados não escolhe nem planta; tocar escolhe; arrastar a semente para fora planta nos canteiros.
func _test_scroll_select_ghost() -> void:
	empty_plots()
	farm.call("recenter")
	await process_frame
	await open_plant(4)
	empty_plots()
	var current := dock()
	if current == null:
		check(false, "menu para a rolagem")
		return
	var ids: Array = current.call("entry_ids")
	check(ids.size() >= 6, "várias sementes liberadas (%d)" % ids.size())
	check(float(current.get("_scroll_max")) > 0.0, "com sementes demais a fileira rola")
	var first: String = ids[0]
	var from := tile_center(first)
	var selected_before: String = current.get("selected")
	dock_event("press", from)
	for step in 5:
		dock_event("motion", from + Vector2(-30.0 * (step + 1), 2.0))
	dock_event("release", from + Vector2(-150, 2))
	await process_frame
	check(float(current.get("_scroll")) > 40.0, "arrastar para o lado rola (%.0f)" % float(current.get("_scroll")))
	check(current.get("selected") == selected_before, "rolar não troca a semente escolhida")
	var planted := 0
	for i in 13:
		if status(i) != "empty" and status(i) != "locked":
			planted += 1
	check(planted == 0, "e não planta")
	# O refresh de estado não mexe na rolagem nem na escolha.
	current.set("_coast", 0.0)
	var scrolled: float = current.get("_scroll")
	events.emit_signal("state_changed")
	await process_frame
	await process_frame
	check(is_equal_approx(float(current.get("_scroll")), scrolled), "o refresh de estado não zera a rolagem")
	# Tocar num espaço visível escolhe a semente.
	var visible_id := ""
	var view := current.get("_view") as Control
	for id: String in ids:
		var tile := current.call("tile_node", id) as Control
		if tile and id != "water" and not bool(tile.get_meta("locked", false)) and view.get_global_rect().encloses(tile.get_global_rect()) and id != current.get("selected"):
			visible_id = id
			break
	check(visible_id != "", "há outra semente visível para tocar")
	if visible_id != "":
		var spot := tile_center(visible_id)
		dock_event("press", spot)
		dock_event("release", spot)
		await process_frame
		await process_frame
		check(current.get("selected") == visible_id, "tocar num espaço escolhe a semente")
		check(status(0) == "empty" and status(1) == "empty", "e escolher não planta")
		# Arrastar o espaço para os canteiros: a ficha sai do menu e planta por onde passa.
		spot = tile_center(visible_id)
		dock_event("press", spot)
		dock_event("motion", spot + Vector2(0, 14))
		dock_event("motion", spot + Vector2(0, 40))
		check(bool(current.call("gesture_active")), "arrastar o espaço para baixo começa a ficha")
		for index in [1, 2, 3]:
			dock_event("motion", center(index))
			await process_frame
		dock_event("release", center(3))
		await process_frame
		check(status(1) == "growing" and status(2) == "growing" and status(3) == "growing", "a semente arrastada plantou em 1, 2 e 3")
		check(state.get("plots")[2]["crop"] == visible_id, "com a semente do espaço")
		check(not bool(current.call("gesture_active")), "ao soltar o gesto acaba")
	farm.call("close_tray")


## Só a PRÓXIMA semente aparece bloqueada (as outras ficam escondidas); tocar nela abre o Como fazer.
func _test_next_locked() -> void:
	empty_plots()
	var progress: Object = state.get("progress")
	var kept: Dictionary = progress.claimed_quests.duplicate()
	progress.claimed_quests.erase("bloblo_dig")
	progress.claimed_quests.erase("farm_deed")
	state.call("_changed")
	await open_plant(5)
	var current := dock()
	if current == null:
		check(false, "menu para a bloqueada")
		return
	var ids: Array = current.call("entry_ids")
	var locked_ids: Array[String] = []
	for id: String in ids:
		var tile := current.call("tile_node", id) as Control
		if tile and bool(tile.get_meta("locked", false)):
			locked_ids.append(id)
	check(locked_ids.size() == 1, "exatamente um espaço bloqueado (%s)" % str(locked_ids))
	check(not locked_ids.is_empty() and locked_ids[0] == "strawberry" and not ("sweet_potato" in ids), "é a próxima na ordem, sem as outras bloqueadas (%s)" % str(ids))
	check(ids.find("strawberry") == ids.size() - 2, "fica no fim, depois das liberadas (antes do Regar)")
	var sheets: Array = []
	events.sheet_requested.connect(func(title: String, content: Control) -> void: sheets.append(title))
	if not locked_ids.is_empty():
		var tile := current.call("tile_node", locked_ids[0]) as Control
		check(tile.find_child("LockIcon", true, false) != null, "cadeado dourado no espaço")
		current.call("tap_tile", locked_ids[0])
		await process_frame
		check(sheets.size() == 1, "tocar na bloqueada abre o Como fazer")
	events.emit_signal("sheet_close_requested")
	progress.claimed_quests = kept
	state.call("_changed")
	farm.call("close_tray")
	await process_frame


## Primeira vez de verdade: save novo, o "Ir" da horta abre o menu com a cenoura em destaque e a dica "Arraste
## até a terra"; plantar por toque e por arrasto funciona e a dica some.
func _test_first_flow() -> void:
	farm.call("close_tray")
	state.call("reset")
	var progress: Object = state.get("progress")
	progress.seen["intro"] = true
	progress.claimed_quests["growth_1_puppy"] = true
	state.call("_grant_upgrade", "farm")
	state.call("_mark_all_seen")
	state.set("unlocked_plots", 6)
	progress.seen.erase("ui:tray_drag_hint")
	state.call("_changed")
	(state.get("inventory") as RefCounted).call("from_dict", {})
	main.call("_on_world_requested", "farm", "")
	main.call("show_screen", &"map")
	for i in 20: await process_frame
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		(main.get(member) as CanvasLayer).hide()
	farm = main.find_child("World_farm", true, false)
	farm.call("recenter")
	empty_plots()
	await process_frame
	# O que o Ir da missão da horta emite: a semente pedida e o primeiro canteiro vazio.
	events.emit_signal("plot_tray_requested", "carrot", -1)
	await create_timer(0.9).timeout
	var current := dock()
	check(current != null, "o Ir abre o menu da horta")
	if current == null:
		return
	var ids: Array = current.call("entry_ids")
	check(ids[0] == "carrot" and current.get("selected") == "carrot", "a cenoura vem primeiro e escolhida")
	var locked_count := 0
	for id: String in ids:
		var tile := current.call("tile_node", id) as Control
		if tile and bool(tile.get_meta("locked", false)):
			locked_count += 1
	check(locked_count <= 1, "no começo só uma semente bloqueada à vista (%d)" % locked_count)
	check(status(0) == "empty", "o Ir não planta sozinho")
	var hint := main.find_child("DragHint", true, false) as Control
	check(hint != null, "a dica do primeiro uso aparece")
	check(int(progress.seen.get("ui:tray_drag_hint", 0)) == 1, "e conta uma abertura")
	# Toque num canteiro: planta a cenoura e a dica some; o menu desliza para o canteiro novo.
	var spot := center(1)
	farm.call("_gui_input", mouse_event("press", spot))
	farm.call("_gui_input", mouse_event("release", spot))
	await process_frame
	await process_frame
	check(status(1) == "growing" and state.get("plots")[1]["crop"] == "carrot", "tocar num canteiro planta a cenoura")
	await process_frame
	check(main.find_child("DragHint", true, false) == null, "plantou: a dica some")
	check(dock() == current and current.get("plot_index") == 1, "o menu continua e segue o canteiro tocado")
	# Arrastar por vários canteiros.
	farm.call("_gui_input", mouse_event("press", center(2)))
	for point: Vector2 in [center(2) + Vector2(4, 0), center(3), center(4)]:
		farm.call("_gui_input", mouse_event("motion", point))
		await process_frame
	farm.call("_gui_input", mouse_event("release", center(4)))
	await process_frame
	check(status(2) == "growing" and status(3) == "growing" and status(4) == "growing", "arrastar planta os canteiros do caminho")
	farm.call("close_tray")
	await process_frame
	# Segunda abertura: a dica volta (são três ao todo).
	events.emit_signal("plot_tray_requested", "carrot", 5)
	await create_timer(0.7).timeout
	check(int(progress.seen.get("ui:tray_drag_hint", 0)) == 2, "a dica conta as aberturas (%s)" % str(progress.seen.get("ui:tray_drag_hint")))
	farm.call("close_tray")
