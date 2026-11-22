extends SceneTree
## F03 do plano "Novo fluxo": o Ato 2 (passos 9 a 14) leva da carta da chegada ao fim do capítulo 1 com a vovó:
## Sítio, conversa, primeira horta, fogão dado e colocado, Cozinhar junto e a primeira papinha (aula da comida).
## Sem moeda e sem banca até o fim; a Mochila entra na primeira colheita e Missões ao fechar o capítulo 1.
## --headless --path game -s res://tests/ato2_test.gd

var failures := 0
var state: Node
var db: Node
var main: Control
var route: RefCounted
var coins_start := 0


func _initialize() -> void:
	_run.call_deferred()
	create_timer(170).timeout.connect(func() -> void: quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("ATO 2: " + message)


func frames(count: int = 3) -> void:
	for i in count:
		await process_frame


func node(node_name: String) -> Control:
	return main.find_child(node_name, true, false) as Control


func shown(node_name: String) -> bool:
	var control := node(node_name)
	return control != null and control.is_visible_in_tree()


func quest() -> String:
	return str(state.progress.current_main_quest())


## Fecha cartões e folhas que a conclusão de um passo abre (a fila modal é da casca).
func dismiss() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var modal: Variant = main.get(member)
		if modal is CanvasLayer:
			(modal as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	main.set("_quest_rewards", [] as Array[Dictionary])
	await frames()


func claim(id: String) -> void:
	route.claim(id)
	await frames()
	await dismiss()


func lesson_shown(id: String) -> bool:
	var guide := node("WeekTutorial")
	return guide != null and guide.visible and str(guide.get("active")) == id


func _run() -> void:
	root.size = Vector2i(360, 780)
	root.get_node("SaveManager").free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/helpers/week_story_clock.gd"))
	state.set_clock(1792411200.0)
	state.reset()
	Motion.reduced = true
	route = load("res://tests/helpers/week_story_route.gd").new(state, db, check)
	route.at(1, 9)

	# Dados: os seis passos do Ato 2 depois da carta, na ordem, e o capítulo 2 começando pela banca.
	var chapter: Array = state.progress.main_quests(1)
	check(chapter.slice(8) == ["lais_farm", "lais_meet_bloblo", "lais_first_crops", "place_stove", "first_kitchen", "first_meal"], "passos 9 a 14: " + str(chapter.slice(8)))
	check(state.progress.main_quests(2) == ["week_market", "week_plots", "week_soup"], "o capítulo 2 é a banca e a sopinha: " + str(state.progress.main_quests(2)))
	check(str(db.quests.lais_meet_bloblo.get("shared_with", "")) == "bloblo_meet", "a conversa com a vovó é o marco da linha dela")
	var crops_rewards: Dictionary = db.quests.lais_first_crops.rewards
	check(crops_rewards.keys() == ["items"] and int(crops_rewards.items.get("stove_gift", 0)) == 1 and crops_rewards.items.size() == 1, "a primeira horta dá só o fogãozinho, sem moeda")
	check(db.quests.place_stove.goals[0].key == "stove" and db.quests.first_kitchen.goals.size() == 1, "colocar o fogão e só o Cozinhar junto")
	check(str(db.week_story.food_lesson.quest) == "first_meal", "a aula da comida mora no passo 14")
	var stove: Dictionary = db.progression.upgrades.stove
	check(int(stove.cost) == 0 and stove.materials.keys() == ["stove_gift"] and int(stove.materials.stove_gift) == 1 and str(stove.verb) == "Colocar", "o fogão é um presente: custa 0, consome o fogãozinho e diz Colocar")
	check(stove.requirements.get("quests", []) == ["lais_first_crops"] and not stove.requirements.has("owned"), "o fogão libera com a primeira horta, sem a geladeira")
	check(db.items.has("stove_gift") and str(db.items.stove_gift.category) == "material", "o fogãozinho é um item de presente")
	check(db.progression.upgrades.fridge.requirements.quests == ["first_meal"], "a geladeira espera o capítulo 2")
	check(not db.quests.lais_first_crops.has("goal_go") and db.quests.lais_first_crops.npc == "bloblo", "a vovó pede a horta")

	# Ato 1 pelo estado (o ato1_test cobre as telas) e a casca nova.
	state.finish_week_arrival()
	state.finish_home_tour()
	route.claim("welcome")
	route.ato_one()
	state.acknowledge_growth("puppy")
	state.week.tutorial["arrival"] = {"done": true}  # a abertura já foi vista: as mãos do Ato 2 podem aparecer
	coins_start = state.coins
	check(quest() == "lais_farm", "o passo 9 é ir ao Sítio")
	check(state.requirement_error(db.worlds.farm.places.early_market.requirements) != "", "a banca do Sítio ainda não existe")
	check(not state.plot_can_buy(2), "comprar canteiro ainda não")
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await frames(4)
	await dismiss()
	main.call("show_screen", &"pet")
	await frames(3)
	check(shown("MapTab") and not shown("TasksTab") and not shown("BagTab"), "só Tiro e Mapa no rodapé")
	check(not shown("CoinsPill"), "sem pílula de moedas")

	# Passo 9: o Sítio. A mão aponta Mapa, depois a pílula do mundo e o cartão do Sítio.
	await create_timer(0.6).timeout
	check(lesson_shown("go_farm"), "a mão ensina o caminho até o Sítio")
	main.call("show_screen", &"map")
	await frames(4)
	check(shown("MapButton"), "com dois mundos abertos aparece a pílula do mundo")
	main.call("_on_world_requested", "farm", "")
	await create_timer(0.5).timeout
	check(state.progress.stat("open:farm") == 1, "abrir o Sítio conta o passo")
	await claim("lais_farm")

	# Passo 10: a vovó. O passo da história vira o marco da linha dela.
	check(quest() == "lais_meet_bloblo" and str(state.progress.displayed_main_quest()) == "bloblo_meet", "o passo 10 mostra a vovó")
	var farm := node("World_farm")
	check(farm != null and farm.call("week_tutorial_rect", "npc:bloblo").has_area(), "a vovó está à vista para a mão")
	await create_timer(0.5).timeout
	check(lesson_shown("meet_bloblo"), "a mão aponta a vovó")
	state.talk_to("bloblo")
	check(state.quest_error("bloblo_meet") == "", "conversar libera o prêmio da vovó")
	check(state.claim_quest("bloblo_meet") == "", "pegar o marco da vovó")
	await frames(3)
	await dismiss()
	check(quest() == "lais_first_crops" and state.coins == coins_start, "conhecer a vovó fecha o passo 10, sem moeda")

	# Passo 11: horta. A mão da horta aponta um canteiro vazio; a Mochila só entra na primeira colheita.
	await create_timer(1.0).timeout
	check(lesson_shown("garden"), "a mão da horta aponta o canteiro vazio")
	check(not shown("BagTab"), "sem Mochila antes de colher")
	route.crop("carrot", 1)
	await frames(3)
	check(shown("BagTab") and not shown("TasksTab"), "a Mochila entra na primeira colheita, Missões não")
	await create_timer(0.7).timeout
	check(lesson_shown("bag"), "balão da Mochila: guardei aqui")
	route.crop("potato", 1)
	await claim("lais_first_crops")
	check(state.inventory.count("stove_gift") == 1 and state.coins == coins_start, "o prêmio é o fogãozinho, sem moeda")

	# Passo 12: o fogão na Casa. O "+" só dele aparece; a compra é grátis.
	check(quest() == "place_stove" and not state.has_upgrade("stove"), "o passo 12 pede o fogão colocado")
	check(state.upgrade_error("stove") == "", "o fogão pode ser colocado: " + str(state.upgrade_error("stove")))
	main.call("_on_world_requested", "house", "")
	await create_timer(0.6).timeout
	var house := node("World_house")
	check(house != null and house.call("week_tutorial_rect", "buy:stove").has_area(), "o + do fogão aparece na Casa")
	var other_markers := 0
	for sprite: Sprite2D in house.get("_objects"):
		var marker := sprite.get_node_or_null("PurchaseMarker") as Node2D
		if marker != null and marker.visible and sprite.get_meta("upgrade", "") != "stove":
			other_markers += 1
	check(other_markers == 0, "nenhum outro + na Casa antes do capítulo 2 (%d)" % other_markers)
	check(not lesson_shown("place_stove"), "a mão do fogão não aparece logo: o gesto já foi ensinado")
	var guide := node("WeekTutorial")
	guide.get("_idle_since")["place_stove"] = Time.get_ticks_msec() - 9000
	await create_timer(0.5).timeout
	check(lesson_shown("place_stove"), "se a pessoa demora, a mão aponta o + do fogão")
	check(state.buy_upgrade("stove") == "", "colocar o fogão")
	check(state.inventory.count("stove_gift") == 0 and state.coins == coins_start, "gastou o fogãozinho e nenhuma moeda")
	await claim("place_stove")

	# Passo 13: Cozinhar junto. A banca ainda não existe.
	check(quest() == "first_kitchen", "o passo 13 é a primeira papinha")
	var food: String = route.recipe("puppy_mash", 3, true)
	check(food == "puppy_mash" and state.progress.stat("together:puppy_mash") == 1, "a papinha do Cozinhar junto")
	check(not state.food_lesson_done() and not shown("MealClock"), "sem relógio antes da aula da comida")
	await claim("first_kitchen")

	# Passo 14: a aula da comida mora aqui. Ainda sem moeda e sem banca.
	check(quest() == "first_meal" and state.food_lesson_startable(), "o passo 14 libera a aula da comida")
	check(state.requirement_error(db.worlds.farm.places.early_market.requirements) != "" and not shown("CoinsPill"), "banca e moedas ainda esperam")
	main.call("show_screen", &"pet")
	await create_timer(1.0).timeout
	var lesson := node("LessonGuide")
	check(lesson != null and str(lesson.get("kind")) == "food", "a aula da comida começa sozinha")
	check(state.feed("puppy_mash"), "dar a papinha")
	check(state.progress.stat("feed:puppy_mash") == 2 and state.well_fed_days() == 1, "a papinha da aula vale a patinha da chegada, uma só")
	if lesson != null:
		lesson.call("_finish_food")
	check(state.food_lesson_done() and state.coins == coins_start, "aula dada, nenhuma moeda ganha em todo o Ato 2")
	check(state.quest_error("first_meal") == "", "o passo 14 pode ser pego")
	await claim("first_meal")
	await frames(3)

	# Capítulo 2: moedas, banca e Missões aparecem; a história segue pela banca.
	check(state.ato2_done(), "o Ato 2 acabou")
	check(shown("TasksTab") and shown("BagTab") and shown("CoinsPill"), "Missões, Mochila e moedas no capítulo 2")
	await create_timer(0.6).timeout
	check(lesson_shown("missions"), "balão da aba Missões")
	check(state.requirement_error(db.worlds.farm.places.early_market.requirements) == "", "a banca do Sítio abre")
	check(state.plot_can_buy(2), "o terceiro canteiro pode ser comprado")
	check(quest() == "week_market" and state.progress.chapter_index() == 2, "o capítulo 2 começa pela banca")

	# Nada antigo ficou pendurado: o save inteiro volta igual.
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
	state.from_dict(snapshot)
	check(quest() == "week_market" and state.ato2_done(), "o save guarda o fim do capítulo 1")

	print("ATO 2 TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
