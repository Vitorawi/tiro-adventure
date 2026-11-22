extends SceneTree
## Capturas do Ato 2 (novo fluxo, F03). NÃO é teste.
## Rodar SEM --headless: & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/ato2_shots.gd
## PNGs em build/screenshots/ato2/: seletor com Casa e Sítio, vovó com "!", conversa, canteiros, balão da Mochila,
## "+" do fogão na Casa, folha "Colocar", Cozinhar junto, aula na tigela e balão da aba Missões.

const FOLDER := "res://../build/screenshots/ato2/"
var main: Control
var state: Node
var route: RefCounted
var failures := 0


func _initialize() -> void:
	_run.call_deferred()
	create_timer(300).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL: ", message)


func _wait(seconds: float = 0.6) -> void:
	await create_timer(seconds).timeout


func _save(shot_name: String) -> void:
	await _wait(0.9)
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(FOLDER)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "ato2_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _node(node_name: String) -> Control:
	return main.find_child(node_name, true, false) as Control


func _clear_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var modal: Variant = main.get(member)
		if modal is CanvasLayer:
			(modal as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	main.set("_quest_rewards", [] as Array[Dictionary])


func _claim(id: String) -> void:
	state.call("claim_quest", id)
	await _wait(0.5)
	_clear_modals()


## Confere que a mão/balão da lição está dentro da tela e sobre o alvo.
func _guide_check(id: String) -> void:
	var guide := _node("WeekTutorial")
	var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	_check(guide != null and guide.visible and str(guide.get("active")) == id, "mão da lição %s à vista (ativa: %s)" % [id, str(guide.get("active")) if guide != null else "?"])
	if guide != null and not guide.visible:
		print("    depuração: card_open=", main.call("_card_open"), " sheet=", main.get_node("Sheet").call("is_open"), " notice=", main.call("notice_blocked"), " quest=", state.get("progress").current_main_quest(), " plot_rect=", guide.call("_target", "@plot"), " room=", _node("World_farm").call("week_tutorial_rect", "plot"), " idx=", _node("World_farm").call("plot_indices"), " plots=", state.get("plots").slice(0, 3), " lessons=", str(guide.get("active")), " rec=", state.get("week").tutorial.get("garden", {}), state.get("week").tutorial.get("meet_bloblo", {}))
	if guide != null and guide.visible:
		var target: Rect2 = guide.get("_anchor_rect")
		_check(screen.encloses(target), "alvo da lição %s dentro da tela: %s" % [id, str(target)])


func _tab_check() -> void:
	var bar := _node("TabBar")
	var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	_check(bar != null and screen.grow(1.0).encloses(bar.get_global_rect()), "rodapé fora da tela: %s" % (str(bar.get_global_rect()) if bar != null else "?"))
	var xs: Array[float] = []
	for tab_name: String in ["PetTab", "MapTab", "TasksTab", "BagTab"]:
		var tab := _node(tab_name)
		if tab != null and tab.visible:
			xs.append(tab.get_global_rect().get_center().x)
	print("  abas visíveis em x:", xs)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", str(load("res://scripts/util/build_info.gd").call("data_dir")) + "ato2_shots_descartavel.json")
	state = root.get_node("GameState")
	state.set_script(load("res://tests/helpers/week_story_clock.gd"))
	state.call("set_clock", 1792411200.0)
	state.call("reset")
	route = load("res://tests/helpers/week_story_route.gd").new(state, root.get_node("Database"), _check)
	route.at(1, 12)
	state.call("finish_week_arrival")
	route.claim("welcome")
	route.ato_one()
	state.call("acknowledge_growth", "puppy")
	state.get("week").tutorial["arrival"] = {"done": true}
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await _wait(1.5)
	_clear_modals()

	# 9. Sítio: a mão ensina Mapa, pílula do mundo e cartão do Sítio.
	main.call("show_screen", &"pet")
	await _wait(1.0)
	_tab_check()
	await _save("01_passo9_mapa_mao")
	_guide_check("go_farm")
	main.call("show_screen", &"map")
	await _wait(1.0)
	await _save("02_passo9_pilula_mao")
	_guide_check("go_farm")
	_node("WorldsScreen").call("show_map")
	await _wait(1.0)
	await _save("03_passo9_seletor_casa_e_sitio")
	_guide_check("go_farm")
	root.get_node("Events").world_requested.emit("farm", "")
	await _wait(1.5)
	await _claim("lais_farm")
	_tab_check()

	# 10. A vovó com "!" e a mão nela; depois a conversa.
	await _wait(1.0)
	await _save("04_passo10_vovo_exclamacao")
	_guide_check("meet_bloblo")
	load("res://scripts/ui/places.gd").call("open_npc", "bloblo")
	await _wait(1.2)
	await _save("05_passo10_conversa")
	root.get_node("Events").sheet_close_requested.emit()
	await _wait(0.6)
	state.call("talk_to", "bloblo")
	state.call("claim_quest", "bloblo_meet")
	await _wait(0.6)
	_clear_modals()

	# 11. Horta: canteiros e a mão da semente; depois a Mochila.
	await _wait(0.8)
	await _save("06_passo11_canteiros_mao")
	_guide_check("garden")
	route.crop("carrot", 1)
	await _wait(1.0)
	await _save("07_passo11_mochila_balao")
	_guide_check("bag")
	_tab_check()
	route.crop("potato", 1)
	state.call("claim_quest", "lais_first_crops")
	await _wait(0.5)
	_clear_modals()

	# 12. O fogão: "+" na Casa, a mão (se demorar) e a folha "Colocar".
	root.get_node("Events").world_requested.emit("house", "")
	await _wait(1.5)
	await _save("08_passo12_casa_mais_fogao")
	var guide := _node("WeekTutorial")
	guide.get("_idle_since")["place_stove"] = Time.get_ticks_msec() - 9000
	await _wait(0.8)
	await _save("09_passo12_mao_fogao")
	_guide_check("place_stove")
	root.get_node("Events").world_requested.emit("house", "buy:stove")
	await _wait(1.2)
	await _save("10_passo12_colocar_fogao")
	root.get_node("Events").sheet_close_requested.emit()
	state.call("buy_upgrade", "stove")
	await _claim("place_stove")

	# 13. Cozinhar junto.
	var places := load("res://scripts/ui/places.gd")
	places.call("go", places.call("quest_target", "first_kitchen"))
	await _wait(2.0)
	await _save("11_passo13_cozinha")
	var panel: Object = load("res://scripts/ui/cook_panel.gd").call("current")
	if panel != null:
		panel.call("_together_selected")
		await _wait(1.0)
		await _save("12_passo13_cozinhar_junto")
		var kitchen := _node("CookTogether")
		if kitchen != null:
			kitchen.call("_close")
	load("res://scripts/ui/cook_panel.gd").call("close_current", true)
	route.recipe("puppy_mash", 3, true)
	await _claim("first_kitchen")

	# 14. A aula da comida mora aqui.
	main.call("show_screen", &"pet")
	await _wait(2.0)
	await _save("13_passo14_aula_reloginho")
	var lesson := _node("LessonGuide")
	_check(lesson != null and str(lesson.get("kind")) == "food", "a aula da comida começou")
	_tab_check()
	state.call("feed", "puppy_mash")
	if lesson != null:
		lesson.call("_finish_food")
	await _wait(0.6)
	await _claim("first_meal")
	_clear_modals()
	main.call("show_screen", &"pet")
	await _wait(1.5)
	await _save("14_passo14_missoes_balao")
	_guide_check("missions")
	_tab_check()
	_check(_node("CoinsPill") != null and _node("CoinsPill").is_visible_in_tree(), "pílula de moedas no capítulo 2")

	print("ATO 2 SHOTS: ", "OK" if failures == 0 else "%d FAIL" % failures)
	quit(0 if failures == 0 else 1)
