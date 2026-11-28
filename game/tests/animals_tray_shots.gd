extends SceneTree
## Capturas da bandeja das criações animal por animal (galinheiro e curral).
## NÃO é teste. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/animals_tray_shots.gd -- --out=animals_tray
## PNGs em build/screenshots/<out>/tray_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

var state: Node
var main: Control
var folder := "res://../build/screenshots/animals_tray/"
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
	var first_id: String = str((current.call("entry_ids") as Array)[0]) if not (current.call("entry_ids") as Array).is_empty() else ""
	var tile := current.call("item_node", first_id) as Control if first_id != "" else null
	if tile:
		var cap := tile.find_child("Caption", true, false) as Control
		var lab := tile.find_child("CaptionLabel", true, false) as Label
		print("  tile %s caption %s rótulo %s texto '%s'" % [tile.get_global_rect(), cap.get_global_rect() if cap else "?", lab.get_global_rect() if lab else "?", lab.text if lab else ""])
	_check(rect.position.x >= 7.5 and rect.end.x <= screen.x - 7.5, "bandeja fora da folga de 8 px")
	_check(rect.position.y >= 119.0, "bandeja sob o HUD (y %.1f)" % rect.position.y)
	_check(rect.end.y <= nav.global_position.y + 1.0, "bandeja sobre as abas (fim %.1f)" % rect.end.y)
	for node_name: String in ["CloseTray", "SeeAll", "AnimalAction", "AnimalExpand"]:
		var button := current.call("find_in_panel", node_name) as Control
		if button and button.is_visible_in_tree():
			var hit := button.get_global_rect()
			_check(hit.size.x >= 43.5 and hit.size.y >= 43.5, "%s menor que 44 (%s)" % [node_name, hit.size])
	# Fichas do cercadinho: mesmo tamanho, dentro da moldura da bandeja, sem sair da linha.
	var pen := current.call("find_in_panel", "AnimalPen") as Control
	if pen != null:
		var sizes := {}
		for card in pen.get_children():
			var card_rect := (card as Control).get_global_rect()
			sizes[card_rect.size] = true
			_check(card_rect.position.x >= rect.position.x + 20.0 and card_rect.end.x <= rect.end.x - 20.0, "ficha %s fora da moldura (%s)" % [card.name, card_rect])
			_check(card_rect.size.x >= 43.5 and card_rect.size.y >= 43.5, "ficha %s menor que 44" % card.name)
			print("  ficha %s %s" % [card.name, card_rect])
		_check(sizes.size() == 1, "fichas de tamanhos diferentes %s" % str(sizes.keys()))
	var info := current.call("find_in_panel", "AnimalInfo") as Control
	if info != null:
		print("  info %s" % info.get_global_rect())
		_check(info.get_global_rect().end.x <= rect.end.x - 20.0, "linha de informação passa da moldura")


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
	state.call("finish_fishing_tutorial")
	for npc: String in root.get_node("Database").get("npcs"):
		state.get("progress").seen["npc_intro:" + npc] = true
	state.set("coins", 5000)
	for id: String in state.get("stations"):
		state.get("stations")[id].queue.clear()
	state.get("inventory").call("from_dict", {})
	state.set("animals", {})
	# O tutorial da pesca começa sozinho com a vara: encerra e tira o véu que ele já tenha montado.
	state.call("finish_fishing_tutorial")
	if main != null:
		var guide := main.find_child("AnglerTutorial", true, false)
		if guide != null:
			guide.queue_free()


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


## A faixa dos espaços não pode piscar nem mudar de lugar/tamanho: amostra 90 quadros (a faixa se refaz a cada 1 s)
## e compara os pixels de duas capturas com 1,5 s de intervalo.
func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "animals_tray_descartavel.json"))
	state = root.get_node("GameState")
	Motion.reduced = false
	_fresh()
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()

	# (a) galinheiro vazio: "Compre sua primeira galinha".
	_fresh()
	state.get("progress").owned.erase("chicken_coop_2")
	var farm := await _enter("farm")
	await _tap(farm, "place:chicken_coop", "chicken_coop")
	await shot("a_vazio")

	# (b) uma galinha livre + "+ Comprar 50" + Ampliar.
	_fresh()
	state.get("progress").owned.erase("chicken_coop_2")
	state.set("animals", {"chicken_white": 1})
	_add("corn", 12)
	await _tap(farm, "place:chicken_coop", "chicken_coop")
	await shot("b_uma_galinha")

	# (c) duas galinhas, uma produzindo e a outra pronta; "Pegar tudo" e Ampliar.
	_fresh()
	state.get("progress").owned.erase("chicken_coop_2")
	state.set("animals", {"chicken_white": 2})
	_add("corn", 12)
	state.call("cook_animal", "eggs", 0)
	state.call("cook_animal", "eggs", 1)
	state.call("station", "chicken_coop").queue[1]["ready_at"] = 0.0
	farm.call("close_tray")
	farm.call("open_station_tray", "chicken_coop")  # tocar numa criação pronta recolhe direto; a bandeja abre por aqui
	await create_timer(1.0).timeout
	_hide_modals()
	await shot("c_produzindo_e_pronta")

	# (d) quatro galinhas depois da ampliação: "Alimentar todas (4)".
	_fresh()
	state.set("animals", {"chicken_white": 4})
	_add("corn", 12)
	await _tap(farm, "place:chicken_coop", "chicken_coop")
	await shot("d_quatro_alimentar_todas")

	# (f) duas galinhas livres e sem milho: "Falta milho".
	_fresh()
	state.get("progress").owned.erase("chicken_coop_2")
	state.set("animals", {"chicken_white": 2})
	await _tap(farm, "place:chicken_coop", "chicken_coop")
	await shot("f_falta_milho")

	# (g) uma galinha livre com milho: "Alimentar" (um só).
	_fresh()
	state.get("progress").owned.erase("chicken_coop_2")
	state.set("animals", {"chicken_white": 1})
	_add("corn", 12)
	await _tap(farm, "place:chicken_coop", "chicken_coop")
	await shot("g_alimentar_uma")

	# (e) curral com uma vaca e lugar para comprar.
	_fresh()
	state.get("progress").owned.erase("cow_barn_2")
	state.set("animals", {"cow_white": 1})
	_add("wheat", 12)
	await _tap(farm, "place:cow_barn", "cow_barn")
	await shot("e_curral")

	print("ANIMALS TRAY SHOTS: ", "OK" if failures == 0 else "%d falhas" % failures)
	quit(0 if failures == 0 else 1)
