extends SceneTree
## E06: jogo pela bancada e mapa em 360×780. Sem --headless, -- --screenshots grava as telas visitadas.

var state: Node
var db: Node
var events: Node
var main: Node
var room: Control
var failures := 0
var screenshots := false


func _initialize() -> void:
	screenshots = "--screenshots" in OS.get_cmdline_user_args()
	create_timer(100).timeout.connect(func() -> void: quit(1))
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FARM WEEK: " + message)


func inventory(item: String) -> int:
	return int(state.get("inventory").call("count", item))


func pause(seconds: float = 0.25) -> void:
	await create_timer(seconds).timeout


func hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		var layer: Variant = main.get(member)
		if layer is CanvasLayer:
			layer.hide()
	main.set("_modal_queue", [] as Array[Callable])


func tap(point: Vector2) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = point
		event.global_position = point
		root.push_input(event, true)
		await process_frame
	await pause()


func tap_control(node_name: String) -> void:
	var node := main.find_child(node_name, true, false) as Control
	check(node != null and node.is_visible_in_tree(), "alvo visível: " + node_name)
	if node != null:
		await tap(node.get_global_rect().get_center())


func shot(name: String) -> void:
	if not screenshots:
		return
	await pause(0.35)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://../build/screenshots/e06_farm/")
	DirAccess.make_dir_recursive_absolute(path)
	var error := image.save_png(path.path_join("%dx%d_%s.png" % [image.get_width(), image.get_height(), name]))
	check(error == OK, "salvou captura de " + name)


func visible_region(id: String) -> bool:
	var node := room.find_child("Region_" + id, true, false) as Node2D
	return node != null and node.visible


func check_routes() -> void:
	var data: Dictionary = db.call("room", "farm")
	var points: Dictionary = data.points
	var start := Vector2(float(points.dog_start[0]), float(points.dog_start[1]))
	var locations: Array = data.dig_spots.duplicate()
	locations.append(points.fishing_spot)
	for object: Dictionary in data.objects:
		if object.has("approach"):
			locations.append(object.approach)
	for point: Array in locations:
		var target := Vector2(float(point[0]), float(point[1]))
		var path: PackedVector2Array = room.call("find_path", start, target)
		check(not path.is_empty(), "Tiro alcança %s a partir da entrada" % target)


func _run() -> void:
	if not screenshots:
		root.size = Vector2i(360, 780)
	state = root.get_node("GameState")
	db = root.get_node("Database")
	events = root.get_node("Events")
	var saver := root.get_node("SaveManager")
	events.state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await pause(0.7)
	hide_modals()
	main.call("_on_world_requested", "farm", "")
	main.call("show_screen", &"map")
	await pause(1.1)
	hide_modals()
	for view: Node in get_nodes_in_group("room_views"):
		if view.get("room_id") == "farm":
			room = view as Control
	check(room != null and room.is_visible_in_tree(), "Sítio aberto pelo Mapa no dia 1")
	if room == null:
		quit(1)
		return
	check(visible_region("silo") and visible_region("warehouse") and visible_region("cow_barn"), "áreas futuras cercadas")
	check(visible_region("lake") and visible_region("orchard") and visible_region("chicken_coop"), "áreas com placa por dia")
	check(state.call("usable_plot_indices") == [0, 1], "dia 1: dois terrenos grátis")
	check(state.call("sale_price", "pumpkin", "farm") == 9, "preço de venda da primeira semana")
	check(state.call("crop_seconds", 1, "potato") == 300 and state.call("crop_seconds", 1, "pumpkin") == 600, "tempos normais desde o dia 1 (F05: early_through 0)")
	check(state.call("buy_shop_item_error", "week_coop") == "Continue a História", "galinheiro fechado no dia 1")
	check(state.call("fishing_error") == "Continue a História", "lagoa fechada antes do dia 3")
	check(state.call("harvest_orchard", "apple") == "Continue a História", "pomar fechado antes do dia 4")
	state.get("finds").worlds.farm["next_at"] = 0
	state.call("update_finds")
	check(int(state.get("finds").worlds.farm.pending) == 1, "montinho no dia 1 sem missão")
	check_routes()
	await shot("01_mapa")

	state.set("coins", 230)
	var places: Script = load("res://scripts/ui/places.gd")
	places.call("run", "farm", "shop:week_plot")
	await pause(0.4)
	await tap_control("BuyItem")
	await tap_control("BuyItem")
	check(state.call("usable_plot_indices") == [0, 1, 2, 3] and state.get("coins") == 190, "dois canteiros a 20 pela banca")
	check(state.call("buy_shop_item", "week_plot") != "", "banca não vende um terceiro canteiro")
	events.sheet_close_requested.emit()
	state.call("dev_week_goto", 2)
	state.call("dev_content_day", 4)
	check(not visible_region("chicken_coop") and visible_region("lake"), "capítulo 4 libera o galinheiro; lagoa fechada")
	check(not room.find_child("week_training", true, false).visible, "tapete só no capítulo 5")
	state.call("dev_content_day", 5)
	check(room.find_child("week_training", true, false).visible, "tapete no capítulo 5")
	state.call("dev_content_day", 4)
	places.call("run", "farm", "shop:week_coop")
	await pause(0.35)
	await shot("02_banca")
	await tap_control("BuyItem")
	check(state.call("has_upgrade", "chicken_coop") and state.call("animal_count", "chicken_coop") == 2, "kit instala o galinheiro com duas galinhas")
	check(state.get("coins") == 150 and state.call("buy_shop_item", "week_coop") != "", "kit cobra 60 e devolve 20 uma vez")
	check(state.call("usable_plot_indices") == [0, 1, 2, 3, 8], "kit inclui o canteiro de milho")
	check(state.call("plant_error", 8, "carrot") != "" and state.call("plant", 8, "corn") == "", "só milho no canteiro dedicado")
	check(float(state.call("plot", 8).ready_at) - float(state.call("plot", 8).get("planted_at", 0.0)) == 1200.0, "milho leva vinte minutos")
	await shot("03_montagem")
	await tap_control("KitAssemblyGo")
	await pause(1.3)
	if main.find_child("ActionTray", true, false) == null:
		room.call("open_station_tray", "chicken_coop")
	state.get("inventory").call("add", "corn", 4)
	events.state_changed.emit()
	await pause()
	await shot("04_galinheiro")
	await tap_control("Cook")
	var queue: Array = state.call("station", "chicken_coop").queue
	check(queue.size() == 1 and queue[0].job.seconds == 1800.0 and queue[0].job.qty == 2, "fila pelo toque: dois ovos em trinta minutos")
	if not queue.is_empty():
		queue[0]["ready_at"] = 0.0
		check(state.call("collect", "chicken_coop") == {"egg": 2}, "recolhe os dois ovos")
	check(state.call("recipe_seconds", "eggs") == 1800, "lotes seguintes levam 30 minutos")
	room.call("close_tray")
	await pause(0.6)
	# E11: o primeiro lote de ovos também abre o cartão Achado!.
	(main.get("_celebration") as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	check(state.call("buy_shop_item", "week_bed") == "" and state.call("has_upgrade", "dog_bed") and state.get("coins") == 110, "kit constrói caminha por 40")
	check(state.call("buy_shop_item", "week_teether") == "Continue a História", "mordedor espera dia 7")

	state.call("finish_fishing_tutorial")
	state.call("dev_week_goto", 3)
	state.call("dev_content_day", 6)
	check(not visible_region("lake") and state.call("current_rod") == "bamboo_rod", "dia 3: píer e vara de bambu")
	check(inventory("bait_worm") == 3, "três iscas grátis no dia 3")
	check(state.call("cast_error", "bait_worm", 1) == "", "pesca disponível na lagoa")
	check(state.call("crop_seconds", 1, "potato") == 300 and state.call("crop_seconds", 1, "pumpkin") == 600 and state.call("crop_seconds", 8, "corn") == 1200, "dia 3 usa os tempos normais")
	var snapshot: Dictionary = state.call("to_dict")
	state.call("from_dict", snapshot)
	check(inventory("bait_worm") == 3, "recarregar não duplica o presente diário")

	state.call("dev_week_goto", 4)
	state.call("dev_content_day", 7)
	check(not visible_region("orchard") and state.call("has_upgrade", "orchard"), "pomar abre grátis no dia 4")
	check(inventory("bait_worm") == 6, "mais três iscas no dia seguinte")
	var orchard := room.find_child("orchard", true, false) as Sprite2D
	var center := orchard.transform * orchard.get_rect().get_center()
	room.call("_tween_camera", center, 0.79, 0.0)
	await pause()
	await tap(room.call("world_to_screen", center))
	check(main.find_child("OrchardTree", true, false) != null, "toque nas árvores abre a bandeja do pomar")
	await shot("05_pomar")
	await tap_control("OrchardHarvest")
	check(inventory("apple") == 2 and state.call("orchard_remaining", "apple") > 7190, "colhe duas maçãs, recarga de duas horas")
	check(state.call("harvest_orchard", "banana") == "" and inventory("banana") == 2, "a bananeira tem colheita independente")
	check(state.call("harvest_orchard", "apple") != "", "macieira não entrega duplicado")
	snapshot = state.call("to_dict")
	state.call("from_dict", snapshot)
	check(state.call("orchard_remaining", "banana") > 7190, "recarga da bananeira persiste")
	state.get("week").orchard_ready.apple = float(state.call("now")) - 1.0
	check(state.call("harvest_orchard", "apple") == "" and inventory("apple") == 4, "segunda colheita depois da recarga")
	check_routes()
	if screenshots:
		room.call("close_tray")
		state.call("dev_set_phase", "puppy")
		load("res://scripts/ui/growth_ui.gd").call("open")
		await pause()
		await shot("06_para_crescer")
		events.sheet_close_requested.emit()
	state.call("dev_week_goto", 6)
	state.call("dev_content_day", 10)
	check(room.find_child("week_audience_lais", true, false).visible and room.find_child("week_audience_bloblo", true, false).visible, "plateia no lote no dia 6")
	state.call("dev_week_goto", 7)
	state.call("dev_content_day", 11)
	check(state.call("buy_shop_item", "week_teether") == "" and inventory("chew_ring") == 1 and state.get("coins") == 60, "mordedor construído por 50")
	check(state.call("buy_shop_item", "week_teether") != "", "mordedor só pode ser comprado uma vez")
	state.call("dev_set_phase", "teething")
	check(not visible_region("silo"), "quando cresce a cerca do silo sai")
	print("farm_week_test: %d falha(s)" % failures)
	quit(0 if failures == 0 else 1)
