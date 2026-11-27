extends SceneTree
## Capturas das telas da comida de dia e de noite (plano da alimentação, A2). NÃO é teste.
## Rodar SEM --headless, uma vez por resolução:
##   godot --path game --resolution 360x780 -s res://tests/meal_day_shots.gd
## PNGs em build/screenshots/meal_dia_noite/. Imprime FAIL se a folha passar da tela, um botão ficar < 40 ou o potinho/guia
## sair do lugar. A aula, o Bom dia, o Boa noite, o "?" e a linha das patinhas saem de `food_lesson_shots.gd` (mesma pasta).
var main: Node
var state: Node
var failures := 0
const FOLDER := "res://../build/screenshots/meal_dia_noite/"


func _initialize() -> void:
	_run.call_deferred()
	create_timer(200).timeout.connect(func() -> void:
		print("tempo esgotado")
		quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL: ", message)


func _path() -> String:
	var path := ProjectSettings.globalize_path(FOLDER)
	DirAccess.make_dir_recursive_absolute(path)
	return path


func _save(shot_name: String) -> void:
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(_path() + "%s_%dx%d.png" % [shot_name, image.get_width(), image.get_height()])


## O canto do HUD (avatar + potinho), ampliado 3x para ver os discos.
func _crop(shot_name: String) -> void:
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var part := image.get_region(Rect2i(0, 0, 150, 110))
	part.resize(450, 330, Image.INTERPOLATE_LANCZOS)
	part.save_png(_path() + "%s_%dx%d.png" % [shot_name, image.get_width(), image.get_height()])


func _sheet_ok(label: String) -> void:
	var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var panel := main.get_node("Sheet").get_node("%Panel") as Control
	_check(screen.encloses(panel.get_global_rect()), label + ": folha fora da tela " + str(panel.get_global_rect()))
	for button: Node in panel.find_children("*", "Button", true, false):
		var control := button as Control
		if control.is_visible_in_tree() and control.size.y > 0.0:
			_check(control.size.y >= 40.0 and control.size.x >= 40.0, label + ": botão pequeno " + str(control.name))


func _at(day: int, hour: int) -> void:
	state.call("dev_week_goto", day)
	state.call("dev_week_hour", hour)
	state.call("update_week")


func _tray() -> Node:
	for node in main.find_children("*", "Control", true, false):
		if node.has_method("open_food_menu"):
			return node
	return null


func _hide_cards() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var layer: Variant = main.get(member)
		if layer is CanvasLayer:
			(layer as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", str(load("res://scripts/util/build_info.gd").call("data_dir")) + "meal_day_shots_descartavel.json")
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.get("progress").seen["snack_note"] = true
	load("res://scripts/ui/motion.gd").set("reduced", true)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_cards()
	var events: Node = root.get_node("Events")
	var meal_ui: GDScript = load("res://scripts/ui/meal_ui.gd")
	var inventory: Object = state.get("inventory")
	var tray := _tray()
	for id: String in ["puppy_mash", "fish_mash", "egg_mash", "banana_mash", "apple_biscuit", "carrot_snack"]:
		inventory.call("add", id, 14)

	# --- Potinho do HUD nos cinco estados ---
	_at(3, 12)
	await _crop("potinho_1_sol_fome")
	var dish_box := main.find_child("MealDay", true, false) as Control
	_check(dish_box != null and dish_box.is_visible_in_tree() and dish_box.size.x >= 44.0 and dish_box.size.y >= 44.0, "potinho visível com alvo >= 44")
	var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	_check(dish_box != null and screen.encloses(dish_box.get_global_rect()) and dish_box.get_global_rect().position.x >= 4.0, "potinho dentro da tela, a >= 4 px da borda")
	await _save("potinho_tela_cheia")
	state.call("feed", "puppy_mash")
	await create_timer(0.4).timeout
	await _crop("potinho_2_sol_ok")
	_at(3, 17)
	await _crop("potinho_3_sol_ok_lua_fome")
	_at(4, 12)
	state.call("feed", "puppy_mash")
	state.call("store_meal", "puppy_mash")
	await _crop("potinho_4_lua_na_tigela")
	state.call("cancel_stored_meal", "")
	_at(5, 17)
	await _crop("potinho_5_sol_passou_lua_fome")
	state.call("feed", "puppy_mash")
	await create_timer(0.4).timeout
	_hide_cards()
	await _crop("potinho_6_sol_passou_lua_ok")

	# --- Folha Hoje ---
	_at(7, 12)
	events.sheet_requested.emit("Hoje", meal_ui.call("today_panel"))
	await create_timer(0.7).timeout
	_sheet_ok("Hoje com fome")
	await _save("hoje_1_de_dia_com_fome")
	events.sheet_close_requested.emit()
	await create_timer(0.4).timeout
	state.call("feed", "puppy_mash")
	_at(7, 17)
	events.sheet_requested.emit("Hoje", meal_ui.call("today_panel"))
	await create_timer(0.7).timeout
	_sheet_ok("Hoje de noite")
	await _save("hoje_2_de_noite_dia_ok")
	events.sheet_close_requested.emit()
	await create_timer(0.4).timeout
	_at(8, 12)
	state.call("feed", "puppy_mash")
	state.call("store_meal", "puppy_mash")
	events.sheet_requested.emit("Hoje", meal_ui.call("today_panel"))
	await create_timer(0.7).timeout
	_sheet_ok("Hoje com tigela")
	await _save("hoje_3_com_tigela")
	(main.find_child("MealHelp", true, false) as Button).pressed.emit()
	await create_timer(0.7).timeout
	_sheet_ok("revisão")
	await _save("revisao_pelo_ponto_de_interrogacao")
	events.sheet_close_requested.emit()
	await create_timer(0.4).timeout
	state.call("cancel_stored_meal", "")
	_at(8, 17)
	state.call("feed", "puppy_mash")
	await create_timer(0.4).timeout
	_hide_cards()
	events.sheet_requested.emit("Hoje", meal_ui.call("today_panel"))
	await create_timer(0.7).timeout
	_sheet_ok("Hoje com patinha")
	await _save("hoje_4_dia_completo")
	events.sheet_close_requested.emit()
	await create_timer(0.4).timeout

	# --- Ele já comeu ---
	_at(9, 12)
	state.call("feed", "puppy_mash")
	await create_timer(0.3).timeout
	tray.call("_act", "puppy_mash")
	await create_timer(0.7).timeout
	_sheet_ok("Ele já comeu (de dia)")
	await _save("ele_ja_comeu_1_de_dia")
	events.sheet_close_requested.emit()
	await create_timer(0.4).timeout
	_at(9, 17)
	state.call("feed", "puppy_mash")
	await create_timer(0.3).timeout
	_hide_cards()
	tray.call("_act", "puppy_mash")
	await create_timer(0.7).timeout
	_sheet_ok("Ele já comeu (de noite)")
	await _save("ele_ja_comeu_2_de_noite")
	events.sheet_close_requested.emit()
	await create_timer(0.4).timeout

	# --- Guia de comida: com e sem ✓ ---
	_at(10, 12)
	main.call("show_screen", &"pet")
	await create_timer(0.5).timeout
	tray.call("open_food_menu")
	await create_timer(0.8).timeout
	var menu := main.find_child("FoodMenu", true, false) as Control
	_check(menu != null and menu.visible and screen.encloses(menu.get_global_rect()), "guia de comida dentro da tela")
	_check(main.find_child("CountsRing", true, false) != null and main.find_child("CountsCheck", true, false) != null, "guia: refeições com contorno verde e ✓")
	_check(main.find_child("MealSeal", true, false) != null and main.find_child("SnackHeart", true, false) != null, "guia: selo sol/lua e divisória com coração")
	await _save("guia_1_sem_check")
	state.call("feed", "fish_mash")
	await create_timer(0.5).timeout
	tray.call("open_food_menu")
	await create_timer(0.3).timeout
	if not menu.visible:
		tray.call("open_food_menu")
	await create_timer(0.7).timeout
	_check(main.find_child("CountsRing", true, false) == null, "guia: sem contorno quando a metade já tem ✓")
	await _save("guia_2_com_check")
	tray.call("close_food_menu")

	# --- Avisos: ✓ ao vivo e Dia completo ---
	_at(11, 12)
	main.call("show_screen", &"pet")
	await create_timer(0.4).timeout
	_hide_cards()
	state.call("feed", "puppy_mash")
	await create_timer(0.9).timeout
	await _save("aviso_contou_de_dia")
	_at(11, 17)
	state.call("feed", "puppy_mash")
	await create_timer(2.5).timeout
	var card := main.find_child("DayComplete", true, false) as Control
	_check(card != null and card.is_visible_in_tree() and screen.encloses(card.get_global_rect()), "Dia completo! aparece ao vivo")
	await _save("dia_completo_ao_vivo")
	_hide_cards()
	# Dia completo vindo da tigela: guarda de dia, vira a metade da noite com o jogo aberto.
	_at(12, 12)
	state.call("feed", "puppy_mash")
	state.call("store_meal", "puppy_mash")
	_at(12, 15)
	state.get("week").clock_offset += 3598.0
	await create_timer(4.0).timeout
	card = main.find_child("DayComplete", true, false) as Control
	_check(card != null and card.is_visible_in_tree(), "Dia completo! da tigela aparece com o jogo aberto")
	_check(main.find_child("DayCompleteBowl", true, false) == null and main.find_child("PawNext", true, false) == null, "Dia completo! só a conta e a cartela (sem recado da tigela nem linha de baixo)")
	await _save("dia_completo_da_tigela")
	_hide_cards()
	# Sobremesa e fome.
	_at(13, 12)
	state.call("feed", "puppy_mash")
	_hide_cards()
	state.call("feed", "puppy_mash")
	await create_timer(0.8).timeout
	await _save("aviso_sobremesa")
	print("MEAL DAY SHOTS: ", "OK" if failures == 0 else "%d FAIL" % failures)
	quit(0 if failures == 0 else 1)
