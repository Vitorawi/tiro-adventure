extends "res://tests/station_tray_test.gd"
## Fogão real + bancada com uma terceira linha de fixture: gesto comum e slots sem escala animada.
var before := false
var snapshots := false

func pointer(point: Vector2, kind: String) -> void:
	var event: InputEvent
	if kind == "move":
		var drag := InputEventScreenDrag.new()
		drag.position = root.get_final_transform() * point
		drag.relative = Vector2(0, -20)
		event = drag
	else:
		var touch := InputEventScreenTouch.new()
		touch.position = root.get_final_transform() * point
		touch.pressed = kind == "down"
		event = touch
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await frames(2)

func capture(prefix: String) -> void:
	if not snapshots: return
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/fogao/")
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder + "%s_%dx%d.png" % [prefix, root.size.x, root.size.y]) == OK, "captura do fogão")

func legacy_slots(station_id: String) -> Control:
	var row: Control = load("res://scripts/ui/sheet_builder.gd").call("station_slot_row", station_id)
	row.position = Vector2(-2000, -2000)  # processamento real, sem desenhar por cima da bandeja
	root.add_child(row)
	return row

func static_slots(current: Control, station_id: String) -> void:
	var legacy := legacy_slots(station_id)
	# Não guarda referências: o cabeçalho se reconstrói no tick e em state_changed.
	for sample in 32:
		var pluses := current.find_children("Add", "Control", true, false)
		check(not pluses.is_empty(), "há + vazios para verificar")
		for plus: Control in pluses:
			var node: Control = plus
			while node != null and node != current:
				check(node.scale.is_equal_approx(Vector2.ONE), "+ e ancestrais estáticos: " + str(node.name))
				node = node.get_parent() as Control
		for dot: Control in legacy.find_children("Dot", "Control", true, false):
			check(dot.scale.is_equal_approx(Vector2.ONE), "slots de consulta também estáticos")
		if sample in [8, 20]:
			state.call("_changed")
			current.find_child("Header", true, false).call("refresh")
			legacy.queue_free()
			legacy = legacy_slots(station_id)
		await create_timer(0.10).timeout
	legacy.queue_free()

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	events = root.get_node("Events")
	tray_script = load("res://scripts/ui/action_tray.gd")
	state.call("reset")
	state.get("progress").seen.intro = true
	state.get("progress").owned.merge({"stove": true, "stove_queue": true, "workbench": true, "farm": true}, true)
	for id: String in root.get_node("Database").get("quests"):
		state.get("progress").claimed_quests[id] = true
	# A bancada tem sete receitas hoje. Duas cópias só em memória exercitam overflow do mesmo componente.
	var recipes: Dictionary = root.get_node("Database").get("recipes")
	for i in 2:
		var recipe: Dictionary = recipes.plank.duplicate(true)
		recipes["grid_fixture_%d" % i] = recipe
	Motion.reduced = true
	Input.emulate_mouse_from_touch = true
	before = "--before" in OS.get_cmdline_user_args()
	snapshots = "--shots" in OS.get_cmdline_user_args()
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames(8)
	for resolution: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = resolution
		await frames(8)
		for entry: Array in [["house", "stove"], ["farm", "workbench"]]:
			Motion.reduced = true
			load("res://scripts/ui/station_tray.gd").get("last_recipe").erase(str(entry[1]))
			var room := await enter(str(entry[0]))
			var current := await tap(room, "place:" + str(entry[1]), str(entry[1]))
			await frames(8)
			var scroll := current.call("find_in_panel", "Scroll") as ScrollContainer
			check(scroll != null and scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page, "grade tem conteúdo rolável")
			if scroll == null: continue
			if entry[1] == "stove": await capture("antes" if before else "depois")
			Motion.reduced = false  # Detecta pulsos reais: não pode esconder o bug com Menos animação.
			await static_slots(current, str(entry[1]))
			Motion.reduced = true
			var changes: Array[String] = []
			current.connect("selected_changed", func(id: String) -> void: changes.append(id))
			var selected: String = current.get("selected")
			var ids: Array = current.call("entry_ids")
			var target := current.call("item_node", str(ids[1])) as Control
			var point := target.get_global_rect().get_center()
			var top := scroll.scroll_vertical
			await pointer(point, "down")
			for step in range(1, 6): await pointer(point - Vector2(0, step * 18), "move")
			await pointer(point - Vector2(0, 90), "up")
			await frames(5)
			if before:
				print("ANTES %s %s: scroll %d -> %d" % [resolution, entry[1], top, scroll.scroll_vertical])
				check(scroll.scroll_vertical == top, "reprodução: arrasto sobre tile não rola")
				room.call("close_tray")
				continue
			check(scroll.scroll_vertical > top, "arrasto sobre receita rola: " + str(entry[1]))
			check(changes.is_empty() and current.get("selected") == selected, "arrastar não seleciona")
			if entry[1] == "stove": await capture("depois_rolado")
			# Pare a inércia com o próximo down e toque um tile inteiramente visível, diferente do atual.
			var target_id := ""
			for id: String in ids:
				var tile := current.call("item_node", id) as Control
				if id != selected and scroll.get_global_rect().encloses(tile.get_global_rect()):
					target_id = id
					point = tile.get_global_rect().get_center()
					break
			check(target_id != "", "receita visível para tocar")
			await pointer(point, "down")
			await pointer(point + Vector2(1, 1), "move")
			await pointer(point + Vector2(1, 1), "up")
			await frames(5)
			check(current.get("selected") == target_id and changes == [target_id], "toque seleciona exatamente uma vez")
			room.call("close_tray")
		print("STATION GRID %s: verificado" % resolution)
	print("STATION GRID TOUCH TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
