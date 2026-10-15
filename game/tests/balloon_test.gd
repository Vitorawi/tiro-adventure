extends SceneTree
## Etapa 06: balões, tamanho de tela, toque real da sala e apresentação das etiquetas.

var failures := 0
var state: Node
var main: Control
var worlds: Control


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("BALLOON: " + message)


func enter(id: String) -> Control:
	main.call("_on_world_requested", id, "")
	main.call("show_screen", &"map")
	for i in 4: await process_frame
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	var room: Control = main.find_child("World_" + id, true, false)
	room.call("_animate_objects")
	return room


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	Motion.reduced = true
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	for i in 4: await process_frame
	worlds = main.find_child("WorldsScreen", true, false)
	var farm := await enter("farm")
	check(state.call("plant", 0, "carrot") == "", "planta pela ação do jogo")
	farm.call("_animate_objects")
	var plot: Sprite2D = farm.find_child("plot_0", true, false)
	var balloon: Node2D = plot.get_node("Indicator")
	check(balloon.visible and balloon.get("state") == "progress", "canteiro crescendo tem balão progress")
	for zoom: float in [0.5, 2.0]:
		farm.call("_zoom_at", farm.size / 2, zoom)
		var width: float = balloon.global_scale.x * 44.0
		check(width >= 44 * 0.8 - 0.01 and width <= 44 * 1.25 + 0.01, "tamanho de tela limitado em zoom " + str(zoom))
		var rect: Rect2 = balloon.get("hit_rect")
		check(is_equal_approx(rect.size.x * plot.global_scale.x, width), "toque acompanha desenho")
	balloon.call("reveal_caption")
	farm.call("_zoom_at", farm.size / 2, 0.6)
	check(balloon.get("show_caption"), "toque revela tempo mesmo afastado")
	balloon.set("_caption_until", 0.0)
	balloon.call("refresh")
	check(not balloon.get("show_caption"), "tempo some depois de dois segundos")
	state.call("dev_finish_timers")
	farm.call("_animate_objects")
	check(balloon.get("state") == "ready", "terminar timer deixa balão pronto")
	var center: Vector2 = plot.position + (balloon.get("hit_rect") as Rect2).get_center() * plot.scale
	check(farm.call("_handle_tap", center), "toque no centro do balão é tratado")
	check(state.call("plot_status", 0) == "empty", "toque no balão pronto colhe")
	# As duas primeiras entradas apresentam todos os nomes; a terceira respeita o zoom.
	state.get("progress").seen.erase("ui:labels:farm")
	farm.call("present_labels")
	check(int(state.get("progress").seen["ui:labels:farm"]) == 1, "primeira entrada registrada")
	farm.call("present_labels")
	farm.call("present_labels")
	check(int(state.get("progress").seen["ui:labels:farm"]) == 2, "visitas limitadas a dois")
	farm.set("_label_intro_until", 0.0)
	farm.call("_place_labels")
	var quiet_hidden := 0
	for tag: Label in farm.get("_labels"):
		if tag.visible: check(tag.get_meta("always_visible", false), "zoom baixo só mantém etiquetas importantes")
		else: quiet_hidden += 1
	check(quiet_hidden > 0, "zoom baixo esconde nomes sem ação")
	var overview: Label
	for tag: Label in farm.get("_labels"):
		if tag.get_meta("overview_label", false): overview = tag
	check(overview != null and overview.visible, "nome do conjunto (Animais) aparece afastado")
	farm.call("_zoom_at", farm.size / 2, 1.2)
	farm.call("_place_labels")
	check(not overview.visible, "nome do conjunto some quando os nomes de detalhe aparecem")
	check(farm.find_child("plot_0", true, false) != null, "zoom próximo preserva objetos")
	var house := await enter("house")
	state.get("inventory").add("carrot", 2)
	check(state.call("cook", "carrot_snack") == "", "inicia lote no fogão")
	state.call("dev_finish_timers")
	house.set("_label_intro_until", 0.0)
	house.call("_zoom_at", house.size / 2, 0.6)
	house.call("_animate_objects")
	var kitchen := false
	for tag: Label in house.get("_labels"):
		if tag.get_meta("tap_data").get("action", "") == "place:stove":
			kitchen = tag.visible and tag.get_meta("always_visible", false)
	check(kitchen, "cozinha pronta aparece mesmo afastada")
	var stove: Sprite2D = house.find_child("stove", true, false)
	var production: Node2D = stove.get_node("ProductionIndicator")
	center = stove.position + (production.get("hit_rect") as Rect2).get_center() * stove.scale
	house.call("_handle_tap", center)
	check(state.call("station", "stove").ready_count(state.call("now")) == 0, "toque no balão da estação pega o lote")
	var nature := await enter("nature")
	check(state.call("start_next_gathering", "trees", "lane", "wood") == "", "inicia coleta de madeira")
	nature.call("_animate_objects")
	var route: Node2D
	for marker: Node2D in nature.get("_route_markers"):
		if marker.get("site") == "trees": route = marker
	check(route != null and route.get("state") == "progress" and route.get("texture") != null, "Natureza mostra produto e progresso")
	state.call("dev_finish_timers")
	nature.call("_animate_objects")
	center = route.position + (route.get("hit_rect") as Rect2).get_center()
	nature.call("_handle_tap", center)
	check(state.call("gathering_ready_count", "trees") == 0, "balão da Natureza pega a coleta")
	var park := await enter("park")
	check(state.call("start_walk", "park_loop") == "", "começa passeio")
	park.call("_animate_objects")
	var walk: Node2D = park.get("_walk_marker")
	check(walk.visible and walk.get("state") == "progress", "passeio usa balão progress")
	state.call("dev_finish_timers")
	park.call("_animate_objects")
	check(walk.get("state") == "ready", "passeio pronto usa balão ready")
	park.call("_handle_tap", walk.position + (walk.get("hit_rect") as Rect2).get_center())
	check(not state.call("walking"), "toque no balão recebe a volta do passeio")
	# Visitas atravessam serialização com os outros marcadores de interface.
	var snapshot: Dictionary = state.call("to_dict")
	state.call("from_dict", snapshot)
	check(int(state.get("progress").seen["ui:labels:farm"]) == 2, "contador de visitas preservado no save")
	main.queue_free()
	await process_frame
	Motion.reduced = false
	print("BALLOON TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
