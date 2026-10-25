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
