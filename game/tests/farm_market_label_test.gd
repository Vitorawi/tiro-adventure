extends SceneTree
## Regressão da etiqueta da fachada; --before captura o dado anterior sem exigir a posição nova.
var failures: int = 0
var before: bool = "--before" in OS.get_cmdline_user_args()
var shots: bool = "--screenshots" in OS.get_cmdline_user_args()

func _initialize() -> void:
	_run.call_deferred()
	create_timer(90).timeout.connect(func() -> void: quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FARM MARKET LABEL: " + message)

func settle() -> void:
	for i: int in 12: await process_frame

func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var state: Node = root.get_node("GameState")
	state.reset()
	state.dev_unlock_everything()
	state._mark_all_seen()
	state.progress.seen.intro = true
	Motion.reduced = true
	var main: Control = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await settle()
	main.call("_on_world_requested", "farm", "")
	main.call("show_screen", &"map")
	await settle()
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	var room: Control = main.find_child("World_farm", true, false)
	# Congela personagens para os pares antes/depois serem comparáveis.
	for actor: Node2D in room.get("_npcs"):
		actor.set_process(false)
	(room.get("_dog") as Node2D).set_process(false)
	var market: Label
	for tag: Label in room.get("_labels"):
		if tag.get_meta("tap_data").get("id", "") == "early_market": market = tag
	check(market != null, "etiqueta existe")
	if market == null: quit(1); return
	for viewport: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = viewport
		await settle()
		room.call("recenter")
		await settle()
		check(not market.is_visible_in_tree(), "venda sem nome fixo")
		var hold_point: Vector2 = (room.get("_content") as Control).position + (market.get_meta("anchor") as Vector2) * float(room.get("_zoom"))
		room.set("_press_position", hold_point)
		room.call("_hold_name")
		var bounds := market.get_global_rect()
		check(market.is_visible_in_tree(), "segurar na zona revela venda")
		if not before:
			# Faixa da fachada no próprio fundo da sala, abaixo do telhado e acima dos canteiros.
			var anchor: Vector2 = market.get_meta("anchor")
			check(Rect2(470, 115, 100, 45).has_point(anchor), "âncora no meio da fachada")
			var zone: Dictionary = market.get_meta("tap_data")
			var polygon := PackedVector2Array()
			for point: Array in zone.polygon: polygon.append(Vector2(point[0], point[1]))
			check(Geometry2D.is_point_in_polygon(anchor, polygon), "área tocável acompanha a etiqueta")
			check(Rect2(Vector2.ZERO, root.get_visible_rect().size).encloses(bounds), "venda dentro da tela")
			for other: Label in room.get("_labels"):
				if other != market and other.is_visible_in_tree():
					check(not bounds.grow(3).intersects(other.get_global_rect()), "separada de " + other.text + " em " + str(viewport))
			for sprite: Sprite2D in room.get("_objects"):
				if sprite.visible and (sprite.has_meta("plot") or sprite.name == &"workbench" or sprite.name == &"warehouse"):
					var rect := sprite.get_global_transform() * sprite.get_rect()
					check(not bounds.intersects(rect), "não cobre " + str(sprite.name))
			for actor: Node2D in room.get("_npcs"):
				if actor.visible:
					var feet: float = actor.get("_feet")
					var rect := actor.get_global_transform() * Rect2(-22, -feet * 2 - 6, 44, feet * 2 + 10)
					check(not bounds.intersects(rect), "não cobre personagem " + str(actor.get("npc_id")))
		if shots:
			await RenderingServer.frame_post_draw
			var folder := ProjectSettings.globalize_path("res://../build/screenshots/vender_colheita")
			DirAccess.make_dir_recursive_absolute(folder)
			var filename := "%s_%dx%d.png" % ["before" if before else "after", viewport.x, viewport.y]
			check(root.get_texture().get_image().save_png(folder.path_join(filename)) == OK, "captura " + filename)
		if not before:
			room.call("_handle_tap", market.get_meta("anchor"))
			await settle()
			check(main.get_node("Sheet").call("is_open"), "toque abre venda")
			check(main.get_node("Sheet").get_node("%Title").text == "Vender", "toque abre o painel correto")
			root.get_node("Events").sheet_close_requested.emit()
			await settle()
		room.set("_held_label", null)
		market.hide()
	print("FARM MARKET LABEL TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
