extends SceneTree
## Interface 2, etapa 06: alvos físicos, segurar sem agir, brilho, alfinete e cartões.
var failures: int = 0
var state: Node
var main: Control

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("WORLD_PIN: " + message)

func frames() -> void:
	for i: int in 4: await process_frame

func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	Motion.reduced = true
	await _audit()
	state.get("progress").seen.intro = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	main.call("_on_world_requested", "farm", "")
	await frames()
	_clean()
	var farm: Control = main.find_child("World_farm", true, false)
	for tag: Label in farm.get("_labels"): check(not tag.visible, "entrada não escreve " + tag.text)
	Motion.reduced = false
	farm.get("_owned_snapshot").clear()
	farm.call("_refresh_ownership")
	for tag: Label in farm.get("_labels"): check(not tag.visible, "atualizar compras não pisca o nome " + tag.text)
	Motion.reduced = true
	for spark: Node2D in farm.get("_sparks").values(): check(not spark.visible, "primeira entrada não acende os lugares já abertos")
	var coop: Sprite2D = farm.find_child("chicken_coop", true, false)
	var point: Vector2 = coop.position + _opaque(coop)
	(farm.get("_dog") as Node2D).position = Vector2.ZERO
	(farm.get("_dog") as Node2D).set_process(false)
	farm.call("_tween_camera", point, 1.0)
	var local: Vector2 = (farm.get("_content") as Control).position + point * float(farm.get("_zoom"))
	_mouse(farm, local, true)
	for i: int in 2: await create_timer(0.3).timeout
	var held: Label = farm.get("_held_label")
	check(is_instance_valid(held) and held.visible and held.text == "Galinheiro", "segurar 0,6 s mostra Galinheiro")
	_mouse(farm, local, false)
	check(not main.get_node("Sheet").call("is_open") and load("res://scripts/ui/action_tray.gd").get("current") == null, "soltar depois de segurar não age")
	for i: int in 4: await create_timer(0.4).timeout
	check(not held.visible, "nome some depois de 1,5 s")
	_mouse(farm, local, true)
	_mouse(farm, local, false)
	await frames()
	var tray: Control = load("res://scripts/ui/action_tray.gd").get("current")
	check(tray != null and tray.get("options").get("title", "") == "Galinheiro", "toque rápido abre bandeja do galinheiro")
	farm.call("close_tray")
	await frames()
	# Arrastar cancela o segurar, preservando a câmera.
	_mouse(farm, local, true)
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.position = local + Vector2(30, 0)
	motion.relative = Vector2(30, 0)
	farm.call("_gui_input", motion)
	for i: int in 2: await create_timer(0.3).timeout
	check(farm.get("_held_label") == null, "arrastar cancela consulta do nome")
	_mouse(farm, motion.position, false)
	farm.call("point_at", "place:workbench", 0.0)
	var pin: Node2D = farm.find_child("Pointer", true, false)
	check(pin != null and pin.get_script() == load("res://scripts/ui/world_pin.gd") and pin.get("texture") != null, "Pointer é WorldPin com ícone")
	for zoom: float in [0.5, 2.0]:
		farm.call("_zoom_at", farm.size / 2, zoom)
		check(is_equal_approx(pin.global_scale.x, 1.0), "alfinete mantém tamanho no zoom " + str(zoom))
		check((pin.get("ground_offset") as Vector2).is_equal_approx(((pin.get_meta("ground_base") as Vector2) - pin.position) * float(farm.get("_zoom"))), "anel fica na base real")
	var bench: Sprite2D = farm.find_child("workbench", true, false)
	farm.call("_handle_tap", bench.position + _opaque(bench))
	check(farm.get("_pointer") == null, "tocar na bancada remove Pointer")
	farm.call("close_tray")
	# Primeira visita sem chuva de novidades; liberação posterior é uma novidade.
	var seen: Dictionary = state.get("progress").seen
	seen.erase("ui:place_tapped:farm:early_market")
	state.get("progress").claimed_quests.erase("bloblo_meet")
	farm.call("_place_labels")
	check(not _spark_visible(farm, "place:early_market"), "venda bloqueada não brilha")
	state.call("dev_complete_quest", "bloblo_meet")
	farm.call("_place_labels")
	check(_spark_visible(farm, "place:early_market"), "venda recém-liberada brilha")
	farm.call("_on_object_tapped", "place:early_market")
	check(seen.get("ui:place_tapped:farm:early_market", false) and not _spark_visible(farm, "place:early_market"), "primeiro toque marca e apaga brilho")
	root.get_node("Events").emit_signal("sheet_close_requested")
	var worlds: Control = main.find_child("WorldsScreen", true, false)
	worlds.call("show_map")
	await frames()
	var card: Control = worlds.find_child("WorldCard_farm", true, false)
	check(card.find_child("WorldPhoto", true, false).texture.resource_path == "res://assets/sprites/ui/worlds/farm.png", "cartão usa miniatura do Sítio")
	check(card.find_child("CurrentWorld", true, false).visible, "Aqui identifica mundo atual")
	state.get("progress").claimed_quests.erase("growth_6_explorer")
	state.call("reset")
	worlds.call("show_map")
	await frames()
	var nature: Control = worlds.find_child("WorldCard_nature", true, false)
	check(nature.disabled and nature.find_child("WorldLock", true, false).visible, "Natureza fechada tem cadeado")
	check(nature.find_child("WorldPhoto", true, false).texture.resource_path.ends_with("nature_locked.png"), "Natureza fechada usa foto cinza")
	farm.call("_animate_objects")
	var locked_plot: Node2D = farm.find_child("plot_8", true, false).get_node("Indicator")
	check(locked_plot.get("caption") == "" and not locked_plot.get("show_caption"), "horta sem escritura também não escreve nome no balão de compra")
	print("WORLD_PIN TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _clean() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])

func _mouse(room: Control, point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	room.call("_gui_input", event)

func _spark_visible(room: Control, action: String) -> bool:
	var sparks: Dictionary = room.get("_sparks")
	return sparks.has(action) and sparks[action].visible and sparks[action].state == "spark"

func _opaque(sprite: Sprite2D) -> Vector2:
	var rect := sprite.get_rect()
	var middle := rect.get_center()
	var best := middle
	var distance := INF
	for y: int in range(int(rect.position.y), int(rect.end.y), 2):
		for x: int in range(int(rect.position.x), int(rect.end.x), 2):
			var candidate := Vector2(x,y)
			if sprite.is_pixel_opaque(candidate) and candidate.distance_to(middle) < distance:
				best = candidate
				distance = candidate.distance_to(middle)
	return best * sprite.scale

func _audit() -> void:
	var missing: int = 0
	for id: String in root.get_node("Database").get("worlds"):
		var room: Control = load("res://scenes/levels/room/room.tscn").instantiate()
		room.set_script(load("res://tests/helpers/world_tap_spy.gd"))
		room.set("room_id", id)
		room.set("world_id", id)
		root.add_child(room)
		await process_frame
		_quiet(room)
		for tag: Label in room.get("_labels"): tag.hide()
		for tag: Label in room.get("_labels"):
			var data: Dictionary = tag.get_meta("tap_data")
			var action: String = data.get("action", "")
			if action == "": continue
			if data.has("requirements") and state.call("requirement_error", data.requirements) != "": continue
			if data.has("upgrade") and not state.call("has_upgrade", data.upgrade): continue
			var found: bool = false
			# Pixels opacos e polígonos reais: nunca a área da etiqueta.
			for sprite: Sprite2D in room.get("_objects"):
				if sprite.get_meta("action", "") != action: continue
				var r: Rect2 = sprite.get_rect()
				for y: int in range(int(r.position.y), int(r.end.y), 4):
					for x: int in range(int(r.position.x), int(r.end.x), 4):
						if not sprite.is_pixel_opaque(Vector2(x,y)): continue
						room.set("audited_action", "")
						var handled: bool = room.call("_handle_tap", sprite.position + Vector2(x,y) * sprite.scale)
						if handled and room.get("audited_action") == action: found = true; break
					if found: break
				if found: break
			if not found:
				for zone: Dictionary in room.get("_room").get("zones", []):
					if zone.get("action", "") != action: continue
					var p: PackedVector2Array = room.call("_polygon", zone.polygon)
					# Vários pontos dentro do polígono: basta um chegar ao alvo (um sprite pode cobrir um ponto).
					for candidate: Vector2 in _zone_points(p):
						room.set("audited_action", "")
						var handled: bool = room.call("_handle_tap", candidate)
						if handled and room.get("audited_action") == action:
							found = true
							break
					if found: break
			print("AUDIT ", id, " ", action, " ", "OK" if found else "SEM CAMINHO")
			if not found: missing += 1
			check(found, id + ": ação sem toque físico: " + action)
		room.queue_free()
		await process_frame


## A auditoria confere só o chão e os objetos da sala: personagens, montinho do faro e balões (que dependem
## do relógio e de sorteios) saem de cena e param, para nada ficar na frente do ponto tocado.
func _quiet(room: Control) -> void:
	var dig: Variant = room.get("_dig_spot")
	if is_instance_valid(dig):
		(dig as Node).free()
	var stack: Array[Node] = [room]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		var script: Script = node.get_script()
		var kind: StringName = script.get_global_name() if script != null else &""
		if kind in [&"NpcWorld", &"DogWorld", &"WorldBalloon", &"PlotIndicator", &"StationIndicator", &"RouteIndicator", &"WalkIndicator"]:
			node.set_process(false)
			(node as CanvasItem).visible = false


## Centro e pontos de uma grade dentro do polígono (até 9), do mais central para os cantos.
func _zone_points(polygon: PackedVector2Array) -> Array[Vector2]:
	var center := Vector2.ZERO
	for v: Vector2 in polygon: center += v
	center /= polygon.size()
	var points: Array[Vector2] = []
	if Geometry2D.is_point_in_polygon(center, polygon):
		points.append(center)
	var box := Rect2(polygon[0], Vector2.ZERO)
	for v: Vector2 in polygon: box = box.expand(v)
	for fy: float in [0.5, 0.25, 0.75]:
		for fx: float in [0.5, 0.25, 0.75]:
			var candidate := box.position + box.size * Vector2(fx, fy)
			if Geometry2D.is_point_in_polygon(candidate, polygon) and not points.has(candidate):
				points.append(candidate)
	if points.is_empty():
		points.append(center)
	return points
