extends SceneTree
## Natureza: zonas, progressão real, obstáculos, destinos e atividade de save antigo.

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Natureza: " + message)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var state: Node = root.get_node("GameState")
	var places: Script = load("res://scripts/ui/places.gd")
	state.call("reset")
	check(places.call("world_error", "nature") != "", "Natureza espera o capítulo 3")
	state.call("dev_jump_to_chapter", 2)
	check(places.call("world_error", "nature") == "", "História abre Natureza")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.call("_on_world_requested", "village", "")
	places.call("open", "village", "gate")
	await create_timer(0.3).timeout
	var room: Control = main.find_child("World_nature", true, false)
	check(room != null and room.is_visible_in_tree(), "Portão da vila entra no novo mundo")
	var nav: AStarGrid2D = room.get("_nav")
	check(room.find_child("Region_creek_area", true, false).visible, "Riacho começa fechado")
	check(room.find_child("Region_meadow_area", true, false).visible, "Prado começa fechado")
	check(room.find_child("Region_rocks_area", true, false).visible, "Gruta precisa da picareta")
	check(room.find_child("Region_crystals_area", true, false).visible, "Cristais começam fechados")
	check(nav.is_point_solid(Vector2i(325, 144) / 8), "Não atravessa a zona fechada")
	check(state.call("start_activity", "trail") != "", "Não coleta no riacho fechado")
	room.call("_zoom_at", room.size / 2, 0.32)
	await process_frame
	_shot("nature_locked")
	var revision: int = room.get("navigation_revision")
	for i in 10:
		if not room.find_child("Region_creek_area", true, false).visible:
			break
		check(state.call("start_activity", "lane") == "", "Explorar bosque para evoluir")
		state.call("dev_finish_timers")
		check(state.call("collect_activity") == "", "Recolher madeira do bosque")
	check(not room.find_child("Region_creek_area", true, false).visible, "Exploração real abre o riacho")
	check(int(room.get("navigation_revision")) > revision, "Atributo mudou: navegação recalculada")
	check(not nav.is_point_solid(Vector2i(325, 144) / 8), "Riacho passa a ser andável")
	check(room.find_child("Region_meadow_area", true, false).visible, "Riacho não abre o prado")
	check(state.call("start_activity", "trail") == "", "Explorar riacho aberto")
	var indicator: Node = room.get("_route_markers")[1]
	check(indicator.call("active"), "Mapa mostra timer no destino correto")
	var old_activity: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", old_activity)
	check(state.get("progress").activity.id == "trail", "Rotas existentes sobrevivem à mudança de mundo")
	state.call("dev_finish_timers")
	var before: int = state.get("inventory").count("stone")
	check(state.call("collect_activity") == "", "Coleta offline do riacho")
	check(state.get("inventory").count("stone") == before + 2, "Riacho entrega pedras")
	check(state.call("collect_activity") != "", "Não duplica materiais")
	check(not indicator.call("active"), "Indicador desaparece depois de recolher")
	state.call("dev_add_coins", 200)
	state.call("dev_add_items", 20)
	check(state.call("buy_upgrade", "pickaxe") == "", "Comprar ferramenta no novo mundo")
	check(not room.find_child("Region_rocks_area", true, false).visible, "Picareta abre gruta de pedra")
	check(state.call("start_activity", "quarry") == "", "Explorar gruta")
	state.call("dev_finish_timers")
	check(state.call("collect_activity") == "", "Recolher pedras")
	state.call("dev_set_skills", 3)
	check(not room.find_child("Region_crystals_area", true, false).visible, "Aventura 3 abre cristais")
	check(room.find_child("Region_meadow_area", true, false).visible, "Prado ainda pede Aventura 4")
	state.call("dev_set_skills", 4)
	check(not room.find_child("Region_meadow_area", true, false).visible, "Aventura 4 abre prado")
	check(places.call("highlight_action", "route:trail") == "place:resources", "Ir abre coleta central")
	check(places.call("highlight_action", "route:crystal_cave") == "place:resources", "Cristais usam o mesmo painel")
	var target: Dictionary = places.call("goal_target", {"type": "stat", "key": "activity:meadow"})
	check(target.get("world", "") == "nature", "Missões levam ao novo mundo")
	var ui: Script = load("res://scripts/ui/nature_ui.gd")
	state.call("dev_add_coins", 2000)
	check(state.call("start_activity", "timber") != "", "Não coleta madeira dura sem ferramenta")
	ui.call("open", "tools", "wood")
	await create_timer(0.2).timeout
	var sheet: Control = main.find_child("Sheet", true, false)
	_shot("nature_tools_buy")
	var bought := false
	for button: Node in sheet.find_children("*", "Button", true, false):
		if button.text == "Comprar" and not button.disabled:
			button.pressed.emit()
			bought = true
			break
	check(bought and state.call("has_upgrade", "axe"), "Comprar machado pelo painel de ferramentas")
	check(ui.call("best_route", "wood") == "woodcutting", "Machado melhora coleta automaticamente")
	check(state.call("start_activity", "woodcutting") == "", "Coleta com machado")
	check(state.call("buy_upgrade", "axe_reinforced") == "", "Melhorar machado durante exploração")
	state.call("dev_finish_timers")
	var wood_before: int = state.get("inventory").count("wood")
	check(state.call("collect_activity") == "", "Recolher lote anterior")
	check(state.get("inventory").count("wood") == wood_before + 4, "Melhoria não altera coleta já iniciada")
	check(ui.call("best_route", "wood") == "timber", "Melhoria libera madeira dura")
	check(state.call("start_activity", "timber") == "", "Coletar madeira dura")
	state.call("dev_finish_timers")
	var hardwood_before: int = state.get("inventory").count("hardwood")
	check(state.call("collect_activity") == "", "Recolher madeira dura")
	check(state.get("inventory").count("hardwood") == hardwood_before + 2, "Recebe material melhor")
	check(state.call("buy_upgrade", "pickaxe_reinforced") == "", "Melhorar picareta")
	check(ui.call("best_route", "stone") == "deep_quarry", "Mais pedra e cobre com ferramenta melhor")
	check(state.call("buy_upgrade", "pickaxe_crystal") == "", "Melhorar para cristais")
	check(ui.call("best_route", "crystal") == "crystal_deep", "Cristais melhores sem trocar de lugar")
	check(state.call("buy_upgrade", "sickle") == "", "Comprar foice")
	check(ui.call("best_route", "fiber") == "reeds", "Foice melhora fibras")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	check(ui.call("best_route", "wood") == "timber", "Melhorias sobrevivem ao save")
	root.get_node("Events").emit_signal("sheet_close_requested")
	var data: Dictionary = root.get_node("Database").call("room", "nature")
	var dog: Node2D = room.get("_dog")
	for point: Vector2 in [Vector2(170, 182), Vector2(250, 196), Vector2(321, 199), Vector2(375, 190), Vector2(416, 173), Vector2(280, 281)]:
		check(not (room.call("find_path", dog.position, point) as PackedVector2Array).is_empty(), "Paisagem conectada pela trilha/ponte")
	for object: Dictionary in data.objects:
		if object.has("approach"):
			var approach := Vector2(object.approach[0], object.approach[1])
			check(not (room.call("find_path", dog.position, approach) as PackedVector2Array).is_empty(), "Destino acessível: " + str(object.id))
	main.get_node("Celebration").hide()
	await create_timer(3.2).timeout
	_shot("nature_open")
	check(state.call("start_activity", "trail") == "", "Exploração no mapa completo")
	state.call("dev_finish_timers")
	room.call("_animate_objects")
	await process_frame
	_shot("nature_ready")
	check(state.call("collect_activity") == "", "Recolher após indicador pronto")
	ui.call("open")
	await create_timer(1.1).timeout
	_shot("nature_collect")
	var start: Button = main.find_child("Start_wood", true, false)
	check(start != null and not start.disabled, "Coleta disponível no painel único")
	start.pressed.emit()
	await create_timer(0.2).timeout
	check(state.get("progress").activity.id == "timber", "Um toque escolhe coleta da ferramenta atual")
	state.call("dev_finish_timers")
	await create_timer(1.2).timeout
	_shot("nature_collect_ready")
	ui.call("open", "tools", "stone")
	await create_timer(0.3).timeout
	_shot("nature_tools")
	main.queue_free()
	await process_frame
	print("NATURE TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


func _shot(file_name: String) -> void:
	if "--screenshots" in OS.get_cmdline_user_args():
		var folder := ProjectSettings.globalize_path("res://../build/screenshots/")
		DirAccess.make_dir_recursive_absolute(folder)
		root.get_texture().get_image().save_png(folder + file_name + ".png")
