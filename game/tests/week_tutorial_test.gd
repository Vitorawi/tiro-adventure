extends SceneTree
## Exercita o roteiro de jogador novo. O relógio é acelerado para dispensar as esperas reais.

var failures := 0
var state: Node
var db: Node
var main: Node
var guide: Control
var route: RefCounted
var output := ""


func _initialize() -> void:
	run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("E14 · " + message)


func run() -> void:
	root.get_node("SaveManager").free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/helpers/week_story_clock.gd"))
	state.set_clock(1792411200.0)
	state.reset()
	route = load("res://tests/helpers/week_story_route.gd").new(state, db, check)
	route.at(1, 9)
	load("res://scripts/ui/motion.gd").reduced = true
	if "--screenshots" in OS.get_cmdline_user_args() or "--e15-shots" in OS.get_cmdline_user_args():
		var folder := "e15_tutoriais" if "--e15-shots" in OS.get_cmdline_user_args() else "e14_tutoriais"
		output = ProjectSettings.globalize_path("res://../build/screenshots/%s/%dx%d" % [folder, root.size.x, root.size.y])
		DirAccess.make_dir_recursive_absolute(output)
	check(db.week_tutorials.size() == 37, "37 lições: uma por sistema, presas ao passo da história (F04 Parte B)")
	check(db.week_tutorials.map(func(row: Dictionary) -> String: return row.id).count("arrival") == 1, "Abertura única")
	await open_main()
	check(shown("arrival") and not guide.get("_skip").visible, "A caixa tem guia obrigatório")
	await snap("01_caixa")
	await tap(find("ArrivalOpen"))
	check(main.get("_intro").get("_index") == 1, "O toque abre a caixinha")
	await reopen()
	check(shown("arrival") and guide.get("step") == 1, "A reabertura retoma no carinho")
	await tap(find("ArrivalPet"), 0.70)
	check(main.get("_intro").get("_index") == 2, "O carinho de segurar revela o focinho")
	await tap(find("ArrivalPet"), 0.70)
	await tap(find("ArrivalGo"))
	check(state.progress.stat("arrival_box") == 1, "O tutorial de chegada termina uma vez")
	# Passeio pela casa nova (primeira missão): Tiro/carinho, botão Cuidar, anéis das necessidades; só depois o Pegar.
	await wait_ui(0.6)
	await dismiss()
	await wait_ui(0.4)
	check(shown("home_tour") and guide.get("step") == 0, "O tour da casa começa no Tiro (%s / %s)" % [guide.get("active"), str(guide.get("step"))])
	check(not shown("home_claim") and state.quest_error("welcome") != "", "O Pegar só vale depois do tour")
	check((guide.get("_rects")[0] as ColorRect).color.a == 0.0, "Passo de carinho sem véu cinza: o Tiro aparece limpo")
	await snap("01b_tour_tiro")
	state.pet()  # um carinho de verdade avança
	await wait_ui(0.3)
	check(not guide.visible, "Durante o carinho o próximo balão espera o Tiro levantar")
	for _i in 40:  # o balão volta quando o Tiro termina o carinho
		if shown("home_tour") and guide.get("step") == 1:
			break
		await wait_ui(0.2)
	check(shown("home_tour") and guide.get("step") == 1, "O carinho leva ao botão Cuidar (%s / %s)" % [guide.get("active"), str(guide.get("step"))])
	check(find("CareButton") != null, "O Cuidar aparece durante o tour")
	check((guide.get("_rects")[0] as ColorRect).color.a > 0.0, "Passo informativo com destaque")
	await snap("01c_tour_cuidar")
	await tap(find("TutorialAccept", guide))
	await wait_ui(0.5)
	check(shown("home_tour") and guide.get("step") == 2, "Entendi leva aos anéis das necessidades (%s / %s)" % [guide.get("active"), str(guide.get("step"))])
	await snap("01d_tour_aneis")
	check(state.progress.stat("home_tour") == 0 and state.quest_error("welcome") != "", "Ainda sem Pegar no último passo")
	await tap(find("TutorialAccept", guide))
	await wait_ui(0.5)
	check(state.progress.stat("home_tour") == 1 and state.quest_error("welcome") == "", "Fim do tour libera o Pegar")
	check(shown("home_claim"), "Só então vem a mão do Pegar (%s)" % guide.get("active"))
	await snap("01e_pegar")
	route.claim("welcome")
	await wait_ui()
	await dismiss()
	main.call("show_screen", &"pet")
	await settle_cards()
	check(shown("missions"), "Logo depois do Pegar do welcome o balão aponta a aba Missões")
	var missions_ok := find("TutorialAccept", guide)
	if missions_ok:
		await tap(missions_ok)
	await wait_ui(0.3)
	route.ato_one()  # Ato 1 em casa: comida, banho, brincar, caminha, crescimento, Filhotinho e a carta (as mãos `home_*` vêm do jogo)
	await wait_ui(0.6)
	await dismiss()
	check(state.growth.phase == "newborn" and state.well_fed_days() == 1, "O Ato 1 termina com a patinha da chegada (o Filhotinho é o fecho do capítulo)")
	var places := load("res://scripts/ui/places.gd")
	state.note_screen_opened("farm")  # Ato 2: o Sítio e a vovó (as mãos `go_farm`/`meet_bloblo` são do ato2_test)
	route.claim("lais_farm")
	state.talk_to("bloblo")
	state.mark_seen(["npc_intro:bloblo"] as Array[String])  # a apresentação automática já passou
	check(state.progress.claimed_quests.has("bloblo_meet"), "Conhecer a vovó se entrega sozinho na conversa")
	await wait_ui(0.5)
	await dismiss()
	var destination: Dictionary = places.quest_target("lais_first_crops")
	places.go(destination)
	await wait_ui(1.0)
	await dismiss()
	check(shown("garden"), "O Ir da História encontra o guia da horta")
	if shown("garden"):
		await snap("02_horta")
		var rect: Rect2 = guide.call("_target", "@plot")
		if guide.get("step") == 0:
			await tap_at(rect.get_center())
			await wait_ui(0.85)
		check(shown("garden") and guide.get("step") == 1, "Tocar na terra leva ao passo da semente (%s / %d, %s)" % [guide.get("active"), guide.get("step"), str(rect)])
		check(guide.get("_skip").visible, "Pular disponível a partir da horta")
		guide.set_process(false)
		var gesture_at := Vector2(4, 200)
		pointer(gesture_at, true)
		pointer(gesture_at, false)
		var rect_seed: Rect2 = guide.call("_target", "Tile_carrot")
		guide.call("_layout_week", rect_seed, 19.99)
		check(not guide.get("_hand").visible, "Mão espera os 20 s")
		guide.call("_layout_week", rect_seed, 0.01)
		check(guide.get("_hand").visible, "Mão voltou após 20 s")
		guide.set_process(true)
		await reopen()
		await wait_ui(1.0)
		check(shown("garden") and guide.get("step") == 1, "Reabrir restaura a bandeja da primeira semente")
		var seed := find("Tile_carrot")
		if seed:
			var dock := find("FarmDock")
			var farm := find("World_farm")
			var plot := maxi(0, int(dock.get("plot_index")))
			var center: Vector2 = farm.call("world_to_screen", farm.call("plot_center", plot))
			drag(seed.get_global_rect().get_center(), center)
			await wait_ui()
			check(state.progress.stat("plant:carrot") > 0, "Arrastar a semente planta de verdade")
			state.advance_clock(float(state.crop_seconds(plot, "carrot")) + 1.0)
			await wait_ui()
			check(shown("garden") and guide.get("step") == 2, "A guia espera a colheita")
			await tap(find("TutorialSkip", guide))
			check(state.week.tutorial.get("garden", {}).get("skipped", false), "Pular grava apenas o tutorial")
			await tap_at(center)
			check(state.progress.stat("harvest:carrot") == 1, "Colher continua disponível depois de Pular")
	route.crop("carrot", 2)
	route.crop("potato", 3)
	route.claim("lais_first_crops")
	await settle_cards()
	route.ok(state.buy_upgrade("stove"), "Colocar o fogão da vovó")
	route.claim("place_stove")
	await settle_cards()
	places.go(places.quest_target("first_kitchen"))
	await until_visible("TogetherButton")
	var action := find("TogetherButton")
	if action:
		await tap(action)
	var kitchen := find("CookTogether")
	check(is_instance_valid(kitchen), "A História leva à primeira papinha no minigame")
	if kitchen:
		await cook_first_meal(kitchen)
	else:
		route.recipe("puppy_mash", 3, true)
	check(state.well_fed_days() == 1, "A primeira papinha vale a patinha da chegada")
	if state.progress.current_main_quest() == "first_kitchen":  # sem o minigame na tela: pega o passo 13 aqui
		route.claim("first_kitchen")
	if not state.food_lesson_done():
		route.serve("puppy_mash")
		state.finish_food_lesson()
	route.claim("first_meal")
	await dismiss()
	state.note_screen_opened("growth")
	state.note_growth_lesson()
	route.ok(state.grow(), "Virar Filhotinho no fim do capítulo 1")
	await wait_ui(0.6)
	state.acknowledge_growth("puppy")  # a cerimônia do Filhotinho já foi vista (senão os cartões do dia esperam)
	await dismiss()
	main.call("show_screen", &"pet")
	await settle_cards()
	check(not shown("missions"), "O balão das Missões não volta no fim do capítulo 1")
	check(state.week.tutorial.get("missions", {}).get("done", false), "Entendi guardou o balão das Missões")
	check(state.food_lesson_done() and not shown("clock"), "A aula da comida (F02B) explicou o relogio: a licao antiga nao repete")
	route.crop("carrot", 4)
	route.ok(state.sell("carrot", 4, "farm"), "Vender cenouras")
	route.buy("week_pumpkin_seed")
	route.buy("week_oat")
	route.claim("week_market")
	route.ok(state.buy_plot(2), "Terceiro canteiro")
	route.buy("week_plot")
	route.ok(state.plant(0, "pumpkin"), "Plantar abóbora")
	state.advance_clock(float(state.crop_seconds(0, "pumpkin")) + 1.0)
	state.harvest(0)
	route.claim("week_plots")
	state.finish_album_tutorial()
	route.claim("lais_photo")
	route.funds(40)
	route.ok(state.buy_upgrade("fridge"), "Comprar a geladeira")
	route.claim("week_fridge")
	route.at(1, 19)
	var soup: String = route.recipe("vegetable_soup")
	route.claim("week_soup")
	route.serve(soup)
	check(state.progress.current_main_quest() == "lais_first_wish", "Capítulo 2 foi concluído")
	await dismiss()
	var coins: int = state.coins
	await wait_ui(0.7)
	await close_main()
	route.at(2, 11)
	route.first_wish()
	await open_main()
	await until_visible("WeekMorning")
	check(state.coins == coins + 30, "O Bom dia do dia 2 concede 30 moedas")
	var morning := find("WeekMorning")
	check(is_instance_valid(morning), "O cartão Bom dia aparece antes do Novo! do galinheiro")
	if morning:
		await snap("04_bom_dia")
	if morning:
		await tap(first_button(morning))
	await until_visible("WeekTutorialNew")
	check(is_instance_valid(find("WeekTutorialNew")), "O cartão Novo! apresenta o kit")
	if is_instance_valid(find("WeekTutorialNew")):
		await snap("05_novo")
		route.funds(60)
		await tap(find("Primary", find("WeekTutorialNew")))
		await until_visible("BuyItem")
		check(shown("coop"), "Ir abre a banca com o foco no kit (%s)" % guide.get("active"))
		await tap(find("BuyItem"))
		check(state.has_upgrade("chicken_coop"), "Comprar monta o galinheiro pelo fluxo normal")
		if not state.has_upgrade("chicken_coop"):
			await snap("compra_interrompida")
			quit(1)
			return
		var assembly := find("KitAssemblyGo")
		if assembly:
			await tap(assembly)
	else:
		route.funds(60)
		route.buy("week_coop")
	route.claim("week_coop")
	route.eggs(2)
	route.claim("week_eggs")
	route.serve(route.recipe("egg_mash"))
	route.claim("week_egg_dish")
	route.recipe("week_oat_biscuit")
	route.claim("week_biscuits")
	await dismiss()
	main.call("show_screen", &"pet")
	var pet := main.find_child("PetScreen", true, false)
	pet.get("_care").call("open_food_menu")
	await wait_ui()
	check(not shown("snack"), "O lanche não tem mais dica fixa: é um balão na primeira vez que ele ganha um petisco (F02B)")
	route.lesson("sit")
	route.claim("week_sit")
	route.serve("oat_biscuit")
	route.at(2, 19)
	route.meal(2, 19)
	check(state.growth.phase == "puppy" and state.well_fed_days() == 2, "Dia 2 termina em Filhotinho com duas patinhas")
	await dismiss()
	main.call("show_screen", &"tasks")
	await wait_ui()
	var today := find("WeekToday")
	check(today != null and today.find_child("WeekDailySeal", true, false) != null and today.find_children("WeekDaily_*", "", true, false).is_empty(), "Hoje recolhe as três atividades concluídas ao selo")
	await snap("07_lista_do_dia")
	await dismiss()
	# As lições agora abrem pelo capítulo: encerra as que apareceram junto, para não cobrirem a revisão.
	for lesson: Dictionary in db.week_tutorials:
		if not state.week.tutorial.has(str(lesson.id)):
			state.week.tutorial[str(lesson.id)] = {"done": true}
	await dismiss()
	check(guide.call("_veil_free", {"target": "Care_sponge", "gesture": "scrub"}) and guide.call("_veil_free", {"target": "Care_ball", "gesture": "up"}) and not guide.call("_veil_free", {"target": "CareButton"}), "Passos com gesto sobre o Tiro ficam sem véu; os de toque mantêm")
	var manual := load("res://scripts/ui/game_manual.gd")
	manual.open("tutorials")
	await wait_ui()
	var notebook := find("WeekTutorialManual")
	check(notebook != null and notebook.find_children("TutorialReview_*", "", true, false).size() == 37, "Manual reúne todas as lições, inclusive puladas")
	var review := find("TutorialReview_garden")
	if review:
		await tap(review)
		check(find("TutorialReview_garden") != null and find("TutorialReview_arrival") == null, "A revisão abre a lição no Manual")
		await snap("08_manual")
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
	state.from_dict(snapshot)
	check(state.week.tutorial.get("garden", {}).get("skipped", false), "O save conserva lições puladas")
	print("WEEK TUTORIAL TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(int(failures != 0))


func open_main() -> void:
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	guide = main.find_child("WeekTutorial", true, false)
	await wait_ui()


func reopen() -> void:
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
	await wait_ui(0.65)
	await close_main()
	state.from_dict(snapshot)
	await open_main()


func close_main() -> void:
	# Deixa os sinais e as animações pendentes da tela saírem junto da cena.
	main.queue_free()
	await process_frame
	await process_frame


func shown(id: String) -> bool:
	return guide.visible and guide.get("active") == id


func find(id: String, scope: Node = null) -> Control:
	if scope == null:
		scope = main
	for node: Control in scope.find_children(id, "Control", true, false):
		if node.is_visible_in_tree() and not node.is_queued_for_deletion():
			return node
	return null


func tap(node: Control, seconds: float = 0.0) -> void:
	if node == null:
		check(false, "Controle esperado visível para toque")
		return
	var ancestor := node.get_parent()
	while ancestor is Control:
		if ancestor is ScrollContainer:
			ancestor.ensure_control_visible(node)
		ancestor = ancestor.get_parent()
	await process_frame
	if is_instance_valid(node):
		await tap_at((node.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, node.size)).get_center(), seconds)


func tap_at(at: Vector2, seconds: float = 0.0) -> void:
	pointer(at, true)
	if seconds > 0.0:
		await create_timer(seconds).timeout
	pointer(at, false)
	await wait_ui()


func pointer(at: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	event.position = at
	event.global_position = at
	root.push_input(event, true)


func wait_ui(seconds: float = 0.30) -> void:
	await create_timer(seconds).timeout
	await process_frame


func dismiss() -> void:
	# Fecha os cartões já apresentados para focalizar o ponto em revisão.
	await process_frame
	main.get("_modal_queue").clear()
	main.get("_week_cards_queued").clear()
	main.get("_quest_rewards").clear()
	for id: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		main.get(id).hide()
	root.get_node("Events").sheet_close_requested.emit()
	await wait_ui(0.36)


func snap(id: String) -> void:
	if output.is_empty():
		return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(id + ".png")) == OK, "Captura " + id)


func until_visible(id: String) -> void:
	for i in 10:
		if is_instance_valid(find(id)):
			return
		var card := find("ModalCard")
		if card and not card.name == id:
			var next := find("Ghost", card)
			if next == null:
				next = find("Primary", card)
			if next:
				await tap(next)
		await wait_ui()


func first_button(scope: Node) -> Control:
	for control: Control in scope.find_children("*", "Button", true, false):
		if control.is_visible_in_tree() and not (control as Button).disabled:
			return control
	return null


func settle_cards() -> void:
	for i in 7:
		if not main.call("notice_blocked"):
			return
		await dismiss()


## Toca em Entendi da aula e espera o proximo toque (eat); 0 = a aula terminou.
func lesson_next(guide_node: Node, expected: int) -> void:
	await wait_ui(0.6)
	if expected in [2, 3]:
		check(find("LessonNext") != null, "Entendi da aula visivel")
	guide_node.call("_on_next")  # o mesmo que tocar em Entendi (o toque de verdade ja e coberto pelo food_lesson_test)
	for i in 15:
		if int(guide_node.get("beat")) == expected:
			return
		await wait_ui(0.2)


func drag(from: Vector2, to: Vector2) -> void:
	pointer(from, true)
	move_pointer(from, from.lerp(to, 0.5))
	move_pointer(from.lerp(to, 0.5), to)
	pointer(to, false)


func move_pointer(from: Vector2, to: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = to
	event.global_position = to
	event.relative = to - from
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(event, true)


func kitchen_at(kitchen: Control, point: Vector2) -> Vector2:
	return kitchen.global_position + (kitchen.call("to_screen", point) as Vector2)


func cook_first_meal(kitchen: Control) -> void:
	check(shown("cook") and guide.get("step") == 1, "Cozinhar junto mostra Picar")
	for i in 20:
		if kitchen.get("phase") != "picar":
			break
		var x: float = kitchen.call("guide_x")
		drag(kitchen_at(kitchen, Vector2(x, 280)), kitchen_at(kitchen, Vector2(x, 360)))
	kitchen.call("tick", 0.6)
	await wait_ui()
	check(shown("cook") and guide.get("step") == 2, "Picar leva a Mexer")
	await snap("09_mexer")
	await reopen()
	await until_visible("CookTogether")
	kitchen = find("CookTogether")
	check(kitchen != null and kitchen.get("phase") == "mexer", "Reabrir restaura o passo e os brilhos da cozinha")
	if not kitchen:
		route.serve(route.recipe("puppy_mash", 3, true))
		return
	var center := Vector2(180, 424)
	var angle := -PI / 2.0
	var position := kitchen_at(kitchen, center + Vector2.from_angle(angle) * 150.0)
	pointer(position, true)
	for i in 150:
		if kitchen.get("phase") != "mexer":
			break
		angle += 0.3
		var next := kitchen_at(kitchen, center + Vector2.from_angle(angle) * 150.0)
		move_pointer(position, next)
		position = next
		kitchen.call("tick", 0.1)
	pointer(position, false)
	kitchen.call("tick", 0.6)
	await wait_ui()
	check(shown("cook") and guide.get("step") == 3, "Mexer leva a Servir")
	var bowl := kitchen_at(kitchen, Vector2(272, 566))
	for i in 2:
		drag(kitchen_at(kitchen, Vector2(99, 404)), bowl)
	drag(kitchen_at(kitchen, Vector2(180, 690)), bowl)
	kitchen.call("tick", 0.6)
	await wait_ui()
	check(shown("feed"), "Após os três gestos, o guia segue ao prato pronto")
	await tap(find("GiveToTiro"))
	await wait_ui(0.8)
	check(state.progress.claimed_quests.has("first_kitchen"), "Dar ao Tiro pega o passo 13 sozinho, para o 14 abrir a aula")
	await dismiss()
	await until_visible("LessonNext")
	var lesson_guide := main.find_child("LessonGuide", true, false)
	check(lesson_guide != null and lesson_guide.get("kind") == "food" and lesson_guide.get("beat") == 1, "O prato pronto leva à aula da comida (F02B), que assume o gesto da tigela (kind=%s, startable=%s, quest=%s, sheet=%s, cook=%s, notice=%s)" % [str(lesson_guide.get("kind")) if lesson_guide else "-", state.food_lesson_startable(), state.progress.current_main_quest(), main.get_node("Sheet").call("is_open"), load("res://scripts/ui/cook_panel.gd").call("current") != null, main.call("notice_blocked")])
	await lesson_next(lesson_guide, 2)
	await lesson_next(lesson_guide, 3)
	await until_visible("TutorialMealBowl")
	check(lesson_guide.get("beat") == 3, "A aula chega ao toque de arrastar a papinha (toque %s, tipo %s, fala %s)" % [lesson_guide.get("beat"), lesson_guide.get("kind"), lesson_guide.get("_text")])
	var plate := find("Care_puppy_mash")
	var bowl_target := find("TutorialMealBowl")
	if plate and bowl_target:
		var lift: float = load("res://scripts/ui/drag_ghost.gd").LIFT
		drag(plate.get_global_rect().get_center(), bowl_target.get_global_rect().get_center() + Vector2(0, lift))
		await wait_ui()
	check(state.progress.stat("feed:puppy_mash") == 2, "Dar ao Tiro serve a papinha cozida (a da caixinha foi a primeira)")
	await wait_ui(0.5)
	check(lesson_guide.get("beat") == 4 and bool(state.meal_info().paw), "Comer na aula dá a patinha garantida")
	await lesson_next(lesson_guide, 5)
	await lesson_next(lesson_guide, 0)
	check(state.food_lesson_done() and shown("clock") == false, "A aula termina e entrega o relógio (a lição antiga do relógio não repete)")
