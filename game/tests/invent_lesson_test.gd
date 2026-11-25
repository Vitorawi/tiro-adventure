extends SceneTree
## Aula do Inventar (WeekTutorial "invent"): a mão segue a vaga vazia, a janelinha de ingredientes (e Selecionar quando
## há um escolhido) e, com tudo montado, o "Cozinhar junto". Nada fica escondido atrás do véu.
## --headless --path game -s res://tests/invent_lesson_test.gd

var failures := 0
var state: Node
var main: Control
var cook: Script


func _initialize() -> void:
	_run.call_deferred()
	create_timer(120).timeout.connect(func() -> void: quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("INVENT LESSON: " + message)


func frames(count: int = 4) -> void:
	for i in count:
		await process_frame


func node(node_name: String) -> Control:
	var panel := cook.call("current") as Control
	return panel.find_child(node_name, true, false) as Control if panel != null else null


func tap(target: Control) -> void:
	var hit := target.get_node_or_null("Hit") as Control
	if hit != null:
		target = hit
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = target.size / 2.0
		target.gui_input.emit(click)


func lesson() -> Dictionary:
	for each: Dictionary in root.get_node("Database").get("week_tutorials"):
		if each.id == "invent":
			return each
	return {}


func located(guide: Node) -> Dictionary:
	return guide.call("_locate", lesson())


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	cook = load("res://scripts/ui/cook_panel.gd")
	Motion.reduced = true
	root.size = Vector2i(360, 780)
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("dev_week_goto", 8)
	state.call("_mark_all_seen")
	state.get("week").tutorial["arrival"] = {"done": true}  # semana em andamento: a aula do Inventar vale
	for id: String in state.get("stations"):
		state.get("stations")[id].queue.clear()
	state.get("inventory").call("from_dict", {})
	for item: String in ["carrot", "potato", "sweet_potato", "pumpkin"]:
		state.get("inventory").call("add", item, 3)
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await frames()
	main.call("_on_world_requested", "house", "")
	main.call("show_screen", &"map")
	await frames()
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	var house := main.find_child("World_house", true, false) as Control
	house.call("close_tray")
	house.call("open_station_tray", "stove", "")
	await frames()
	tap(node("InventHalf"))
	await frames()
	var guide := main.find_child("WeekTutorial", true, false)
	check(guide != null, "WeekTutorial existe")
	var view := node("InventView")
	view.call("choose_type", "papinha")
	await frames()
	check(bool(state.get("week").tutorial.get("invent_type_chosen", false)), "escolher o tipo marca o passo")
	var spot := located(guide)
	check(str(spot.get("target", "")) == "@inv_slot" and int(spot.get("step", -1)) == 2, "passo 3 aponta a vaga vazia: %s" % [spot])
	var slot_rect: Rect2 = guide.call("_target", "@inv_slot")
	check(slot_rect.has_area() and slot_rect.is_equal_approx(node("InvSlot_0").get_global_rect()) or slot_rect.intersects(node("InvSlot_0").get_global_rect()), "a vaga 0 é o alvo")
	# Abre a janelinha: o alvo vira a lista de ingredientes (clara e tocável).
	tap(node("InvSlot_0"))
	await frames()
	var picker := view.get("picker") as Control
	check(picker != null, "a janelinha abriu")
	spot = located(guide)
	check(str(spot.get("target", "")) == "@inv_picker", "com a janelinha aberta a mão vai para os ingredientes: %s" % [spot])
	var list_rect: Rect2 = guide.call("_target", "@inv_picker")
	var scroll := picker.find_child("InvPickerScroll", true, false) as Control
	check(list_rect.has_area() and list_rect.intersects(scroll.get_global_rect()), "o buraco do véu é a lista de ingredientes")
	# Escolhe um ingrediente: o alvo passa a ser Selecionar.
	var cell := picker.find_child("InvCell_carrot", true, false) as Control
	check(cell != null, "célula da cenoura")
	picker.set("selected", "carrot")
	await frames()
	var select_rect: Rect2 = guide.call("_target", "@inv_picker")
	var select := picker.find_child("InvSelect", true, false) as Control
	check(select_rect.intersects(select.get_global_rect()) and not select_rect.intersects(scroll.get_global_rect().grow(-20.0)), "com um escolhido, a mão vai para Selecionar")
	picker.call("_confirm")
	await frames()
	check(str(view.call("slot_items")[0]) == "carrot", "a cenoura entrou na vaga")
	spot = located(guide)
	check(str(spot.get("target", "")) == "@inv_slot", "depois de Selecionar a mão vai para a próxima vaga: %s" % [spot])
	check((guide.call("_target", "@inv_slot") as Rect2).intersects(node("InvSlot_1").get_global_rect()), "o alvo é a vaga 1")
	tap(node("InvSlot_1"))
	await frames()
	picker = view.get("picker") as Control
	picker.set("selected", "potato")
	picker.call("_confirm")
	await frames()
	spot = located(guide)
	check(str(spot.get("target", "")) == "@inv_cook" and int(spot.get("step", -1)) == 4, "tudo montado: a mão vai para Cozinhar junto: %s" % [spot])
	check((guide.call("_target", "@inv_cook") as Rect2).intersects(node("InvCookButton").get_global_rect()), "o alvo é o botão Cozinhar junto")
	print("INVENT LESSON TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
