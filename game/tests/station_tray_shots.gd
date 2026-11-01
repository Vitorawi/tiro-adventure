extends SceneTree
## Capturas da bandeja de estação "madeira ilustrada" (fogão, liquidificador, bancada, galinheiro, Natureza, costura).
## NÃO é teste. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/station_tray_shots.gd -- --out=station_tray
## PNGs em build/screenshots/<out>/tray_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

var state: Node
var main: Control
var folder := "res://../build/screenshots/station_tray/"
var failures := 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(400).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FALHOU: ", message)


func tray() -> Control:
	var current: Variant = (load("res://scripts/ui/action_tray.gd") as Script).get("current")
	if current is Control and is_instance_valid(current) and not bool((current as Control).get("closing")):
		return current as Control
	return null


func shot(shot_name: String, wait: float = 0.7) -> void:
	await create_timer(wait).timeout
	_hide_modals()
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "tray_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])
	var current := tray()
	if current == null:
		_check(false, "[%s] sem bandeja aberta" % shot_name)
		return
	var box := current.get("_box") as Control
	var rect := box.get_global_rect()
	var screen := root.get_visible_rect().size
	var nav := main.find_child("TabBar", true, false) as Control
	print("[%s] bandeja %s tela %s abas y=%.0f" % [shot_name, rect, screen, nav.global_position.y])
	_check(rect.position.x >= 7.5 and rect.end.x <= screen.x - 7.5, "bandeja fora da folga de 8 px")
	_check(rect.position.y >= 119.0, "bandeja sob o HUD (y %.1f)" % rect.position.y)
	_check(rect.end.y <= nav.global_position.y + 1.0, "bandeja sobre as abas (fim %.1f)" % rect.end.y)
	for node_name: String in ["CloseTray", "SeeAll", "Cook", "Plus", "Minus", "QuantityMax", "BuyAnimals"]:
		var button := current.call("find_in_panel", node_name) as Control
		if button and button.is_visible_in_tree():
			var hit := button.get_global_rect()
			_check(hit.size.x >= 43.5 and hit.size.y >= 43.5, "%s menor que 44 (%s)" % [node_name, hit.size])


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])
	for hidden_name: String in ["Notice", "Toast", "MomentNotice"]:
		var extra := main.find_child(hidden_name, true, false) as CanvasItem
		if extra:
			extra.hide()
	var toast: Variant = main.get("_toast")
	if toast is Control:
		(toast as Control).hide()


func _fresh() -> void:
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.set("coins", 5000)
	for id: String in state.get("stations"):
		state.get("stations")[id].queue.clear()
	state.get("inventory").call("from_dict", {})
	state.set("animals", {})


func _enter(world: String) -> Control:
	main.call("_on_world_requested", world, "")
	main.call("show_screen", &"map")
	await create_timer(0.8).timeout
	_hide_modals()
	var room := main.find_child("World_" + world, true, false) as Control
	room.call("_animate_objects")
	room.call("recenter")
	await create_timer(0.4).timeout
	return room


func _tap(room: Control, action: String, object_id: String) -> void:
	room.call("close_tray")
	room.call("_on_object_tapped", action, room.find_child(object_id, true, false))
	await create_timer(1.0).timeout
	_hide_modals()


func _add(item: String, amount: int) -> void:
	state.get("inventory").call("add", item, amount)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "station_tray_descartavel.json"))
	state = root.get_node("GameState")
	Motion.reduced = false
	_fresh()
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()

	# (a) fogão com ingredientes, espaços vazios e as duas ampliações bloqueadas (com preço).
	_fresh()
	var progress: Object = state.get("progress")
	progress.owned.erase("stove_queue_2")
	progress.owned.erase("stove_queue_3")
	_add("carrot", 9)
	_add("potato", 6)
	var house := await _enter("house")
	await _tap(house, "place:stove", "stove")
	await shot("a_fogao_vazio")

	# (b) fogão produzindo, pronto e na fila; "Pegar tudo".
	_fresh()
	_add("carrot", 20)
	_add("potato", 6)
	state.call("cook_many", "carrot_snack", 3)
	await _tap(house, "place:stove", "stove")
	await shot("b_fogao_produzindo", 0.3)
	state.call("dev_finish_timers")
	await shot("b2_fogao_pronto", 1.6)

	# (c) seletor de quantidade e Tudo (3 vagas livres), receita escolhida.
	_fresh()
	_add("carrot", 20)
	await _tap(house, "place:stove", "stove")
	var current := tray()
	if current:
		(load("res://scripts/ui/station_tray.gd") as Script).call("_set_count", "carrot_snack", 2)
	await shot("c_fogao_quantidade", 0.5)

	# (d) falta ingrediente: marquinha e aviso na tábua.
	_fresh()
	await _tap(house, "place:stove", "stove")
	await shot("d_fogao_sem_ingrediente")

	# (e) receita bloqueada (cadeado e motivo).
	_fresh()
	progress.owned.erase("stove_queue_3")
	await _tap(house, "place:stove", "stove")
	current = tray()
	if current:
		var locked := ""
		for entry: Dictionary in current.get("entries"):
			if str(entry.get("error", "")) != "" and locked == "":
				locked = str(entry.id)
		print("  receita bloqueada: ", locked)
		if locked != "":
			current.call("tap_item", locked)
	await shot("e_fogao_bloqueada", 0.5)

	# (f) liquidificador (outra estação).
	_fresh()
	_add("strawberry", 8)
	_add("carrot", 6)
	house.call("_animate_objects")
	await _tap(house, "place:blender", "blender")
	await shot("f_liquidificador")

	# (g) bancada no Sítio e galinheiro com animais.
	_fresh()
	_add("wood", 6)
	_add("pebble", 6)
	var farm := await _enter("farm")
	await _tap(farm, "place:workbench", "workbench")
	await shot("g_bancada")
	state.set("animals", {"chicken_brown": 1, "chicken_white": 1})
	_add("corn", 12)
	state.call("cook", "eggs")
	await _tap(farm, "place:chicken_coop", "chicken_coop")
	await shot("h_galinheiro")

	# (i) Natureza.
	_fresh()
	var nature := await _enter("nature")
	nature.call("close_tray")
	nature.call("_on_object_tapped", "place:trees")
	await create_timer(1.0).timeout
	_hide_modals()
	await shot("i_natureza")
	nature.call("close_tray")

	# (j) costura.
	_fresh()
	var park := await _enter("park")
	await _tap(park, "place:sewing", "sewing_table")
	await shot("j_costura")
	park.call("close_tray")

	print("STATION TRAY SHOTS: ", "OK" if failures == 0 else "%d falhas" % failures)
	quit(0 if failures == 0 else 1)
