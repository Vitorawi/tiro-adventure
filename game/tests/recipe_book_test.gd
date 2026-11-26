extends SceneTree
## E11: regras, origens pelas ações reais e toque na interface. --screenshots usa a resolução da janela.

var state: Node
var database: Node
var main: Node
var inventory: RefCounted
var events: Node
var rules: Script
var failures := 0
var clock := 1791936000.0
var screenshots := false
var finds_seen := 0


func _initialize() -> void:
	screenshots = "--screenshots" in OS.get_cmdline_user_args()
	create_timer(100).timeout.connect(func() -> void:
		push_error("RECIPE BOOK: tempo excedido")
		quit(1))
	_run.call_deferred()


func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("RECIPE BOOK: " + label)


func day(number: int, hour: int = 19) -> void:
	state.call("dev_week_goto", number)
	state.call("dev_content_day", number)
	state.call("dev_week_hour", hour)
	state.call("update_week")


func reset() -> void:
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_set_phase", "puppy")
	state.call("_grant_upgrade", "stove")
	state.call("_mark_all_seen")
	inventory = state.get("inventory")
	inventory.call("from_dict", {})
	finds_seen = 0


func key_for(type: String, ingredients: Array) -> String:
	return str(state.call("dish_key", type, ingredients))


func make(type: String, items: Array, stars: int = 1, together: bool = false) -> Dictionary:
	state.call("dev_chef_points", 0)  # os tempos e brindes dos testes não dependem das habilidades do cozinheiro
	for item: String in items:
		inventory.call("add", item, 1)
	var reason: String = state.call("cook_dish", type, items, stars, together)
	check(reason == "", "preparo %s: %s" % [items, reason])
	var queue: Array = state.call("station", "stove").queue
	if queue.is_empty():
		return {}
	var job: Dictionary = queue.back().job
	state.call("dev_finish_timers")
	state.call("collect", "stove")
	return job


func test_mastery() -> void:
	reset()
	day(2)
	var key := key_for("papinha", ["cenoura", "milho"])
	check(state.call("recipe_book_state", key) == "desconhecida", "estado desconhecida")
	for i in 6:
		var job := make("papinha", ["carrot", "corn"])
		check(int(job.get("dish", {}).get("stars", 0)) == 1, "nova sai com uma estrela")
	check(state.call("recipe_book_state", key) == "descoberta", "estado descoberta")
	check(state.call("recipe_mastery", key).name == "Praticada", "seis pontos")
	var result := make("papinha", ["carrot", "corn"])
	check(int(result.dish.stars) == 2 and float(result.seconds) == 300.0, "praticada na fila: 2 estrelas e tempo cheio")
	check(state.call("feed", str(result.output)), "serve o prato")
	check(state.call("recipe_book_state", key) == "provada", "estado provada")
	for i in 3:
		result = make("papinha", ["carrot", "corn"], 9, true)
		check(int(result.dish.stars) == 3 and is_equal_approx(float(result.seconds), 75.0), "junto vale 3 pontos, limita estrelas e corta 75%")
	check(state.call("recipe_book_state", key) == "dominada", "estado dominada")
	check(state.call("recipe_mastery", key).until_gift == 4, "contador começa em quatro")
	# Drena o estoque acumulado para também conferir a entrega de duas porções do mesmo item.
	inventory.call("from_dict", {})
	for i in 4:
		result = make("papinha", ["carrot", "corn"])
		check(float(result.seconds) == 225.0 and int(result.dish.stars) == 2, "75% do tempo e duas estrelas na fila dominada")
		check(int(result.qty) == (2 if i == 3 else 1), "brinde determinístico a cada quatro")
	check(inventory.count(str(result.output)) == 5, "porção adicional chega à Mochila")
	for i in 4:
		make("papinha", ["carrot", "corn"], 3, true)
	check(state.call("recipe_mastery", key).name == "Especialidade", "trinta pontos")
	state.call("dev_chef_points", 25)
	check(state.call("chef_info").name == "Aprendiz" and state.call("station_slots", "stove") >= 3, "nível de cozinheiro libera terceira vaga")
	var first := make("papinha", ["carrot", "corn"])
	var second := make("papinha", ["carrot", "corn"], 3, true)
	check(float(first.seconds) == 150 and int(first.dish.stars) == 3, "especialidade na fila: metade do tempo e três estrelas")
	check(int(first.qty) == 1 and int(second.qty) == 2, "brinde a cada dois pela fila ou junto")
	var saved: Dictionary = state.call("to_dict")
	state.call("from_dict", saved)
	inventory = state.get("inventory")
	check(state.call("recipe_mastery", key).score == 30 and state.call("recipe_book_state", key) == "dominada", "maestria volta do save")


func test_stock_and_day() -> void:
	reset()
	day(2)
	var made := make("papinha", ["carrot", "corn"])
	make("papinha", ["carrot", "pumpkin"])
	inventory.call("add", "carrot", 2)
	inventory.call("add", "corn", 1)
	var rows: Array = state.call("recipe_book_rows", ["cenoura"])
	check(rows.size() == 2 and int(rows.front().missing) == 0 and int(rows.back().missing) == 1, "filtra pela Mochila e ordena pelo que falta")
	rows = state.call("recipe_book_rows", ["cenoura", "milho"])
	check(rows.size() == 1 and "milho" in rows[0].ingredients, "interseção dos ingredientes")
	check(state.call("recipe_ingredient_day").is_empty(), "ingrediente do dia começa no terceiro dia")
	day(3)
	var daily: Dictionary = state.call("recipe_ingredient_day")
	check(daily.get("id") == "abobora" and "recipe_ingredient" in state.call("routine_ids", "daily"), "ingrediente entra nas Diárias")
	make("papinha", ["carrot", "pumpkin"])
	check(state.call("routine_value", "daily", "recipe_ingredient") == 0, "repetir prato não cumpre a diária")
	make("papinha", ["pumpkin", "corn"])
	var coins: int = state.get("coins")
	check(state.call("claim_routine", "daily", "recipe_ingredient") == "" and int(state.get("coins")) == coins + 20, "prato inédito paga as moedas em dobro")
	check(state.call("claim_routine", "daily", "recipe_ingredient") != "", "diária só paga uma vez")
	var saved: Dictionary = state.call("to_dict")
	state.call("from_dict", saved)
	inventory = state.get("inventory")
	check(state.call("recipe_ingredient_day") == daily and state.call("routine_claimed", "daily", "recipe_ingredient"), "ingrediente e recibo persistem")
	day(4, 9)
	check(state.call("recipe_ingredient_day").is_empty(), "dia alternado sem desafio")
	day(5, 9)
	check(state.call("recipe_ingredient_day").get("id") != daily.id and state.call("routine_value", "daily", "recipe_ingredient") == 0, "renova ingrediente e progresso")
	check(not made.is_empty(), "prato de teste criado")


func test_ingredient_sources() -> void:
	reset()
	day(2)
	check(state.call("buy_shop_item_error", "week_rice") == "Continue a História", "arroz respeita o dia")
	day(3)
	state.set("coins", 100)
	check(state.call("buy_shop_item", "week_rice") == "" and inventory.count("rice") == 1, "arroz vem da banca")
	check(state.call("buy_shop_item", "week_zucchini_seed") == "", "semente de abobrinha na banca")
	check(state.call("buy_shop_item", "week_zucchini_seed") != "", "semente permanente é compra única")
	check(state.call("plant", 0, "zucchini") == "", "semente abre o canteiro")
	state.call("dev_finish_timers")
	check(int(state.call("harvest", 0).get("items", {}).get("zucchini", 0)) >= 3 or inventory.count("zucchini") >= 3, "colheita de abobrinha disponível")
	day(4)
	check(state.call("buy_shop_item", "week_sweet_potato_seed") == "" and state.call("plant", 0, "sweet_potato") == "", "muda de batata-doce libera antes da escritura")
	day(5)
	check(state.call("buy_shop_item", "week_watermelon_seed") == "" and state.call("plant", 1, "watermelon") == "", "carroça vende a semente da melancia")


func catch_fish() -> void:
	inventory.call("add", "bait_worm", 1)
	check(state.call("cast", "bait_worm", 1) == "", "lança na lagoa")
	clock += float(state.get("fishing").cast.get("wait", 0.0)) + 0.1
	state.set("test_time", clock)
	check(state.call("hook") == "", "fisga na hora")
	check(state.call("finish_fishing", {"caught": true, "score": 0.55}) == "", "recolhe pesca sem baú aleatório")


func test_secrets() -> void:
	var secrets: Dictionary = database.get("recipe_book").secrets
	reset()
	day(6)
	state.call("dev_give_rod", "bamboo_rod")
	state.call("_grant_upgrade", "chicken_coop")
	check(state.call("recipe_secret", "curau_do_tiro").state == "desconhecida", "segredo inicial")
	state.call("talk_to", "bloblo")
	check(state.call("recipe_secret", "curau_do_tiro").state == "pista", "vovó dá pista")
	for i in 3:
		catch_fish()
	check(state.call("recipe_secret", "sopinha_do_pescador").pieces.size() == 2 and state.call("recipe_secret", "risotinho_do_lago").pieces.size() == 1, "páginas da lagoa garantidas nas três primeiras pescas")
	for i in 2:
		inventory.call("add", "corn", 4)
		var error: String = state.call("cook", "eggs")
		check(error == "", "alimenta as galinhas: " + error)
		state.call("dev_finish_timers")
		check(int(state.call("collect", "chicken_coop").get("egg", 0)) > 0, "página ao recolher ovos")
	for item: String in ["apple", "banana"]:
		check(state.call("harvest_orchard", item) == "", "página ao colher " + item)
	for i in 16:
		state.call("dev_spawn_finds")
		var dug: Dictionary = state.call("dig", "farm")
		check(not dug.is_empty(), "montinho %d cavado" % [i + 1])
	for number: int in [5, 6]:
		day(number)
		for order: String in state.call("cart_order_ids"):
			var def: Dictionary = database.get("progression").cart_catalog[order]
			for item: String in def.inputs:
				inventory.call("add", item, int(def.inputs[item]))
			check(state.call("fulfill_order", order) == "", "página na terceira entrega")
	check(finds_seen == 12, "12 cartões, um por pedaço garantido")
	for id: String in secrets:
		var secret: Dictionary = state.call("recipe_secret", id)
		check(secret.pieces.size() == 3 and secret.state == "descoberta", "três partes revelam " + id)
		check(state.call("dish_record", secret.key).get("source") == "pieces", "origem registrada")
	day(6)
	var before: int = state.get("progress").call("stat", "dishes_known")
	for def: Dictionary in database.get("dishes").named:
		if not bool(def.get("secret", false)):
			continue
		var picks := {}
		for ingredient: String in def.ingredients:
			var item: String = rules.call("main_item", ingredient)
			inventory.call("add", item, 1)
			picks[item] = int(picks.get(item, 0)) + 1
		check(state.call("cook_invented", picks, def.type) == "", "Inventar a combinação de " + str(def.name))
		state.call("dev_finish_timers")
		state.call("collect", "stove")
	check(state.get("progress").call("stat", "dishes_known") == before, "Inventar depois das páginas não repete descoberta")
	var save: Dictionary = state.call("to_dict")
	state.call("from_dict", save)
	inventory = state.get("inventory")
	check(state.call("recipe_secret", "curau_do_tiro").pieces.size() == 3, "páginas persistem")
	reset()
	day(6)
	for def: Dictionary in database.get("dishes").named:
		if not bool(def.get("secret", false)):
			continue
		var picks := {}
		for ingredient: String in def.ingredients:
			var item: String = rules.call("main_item", ingredient)
			inventory.call("add", item, 1)
			picks[item] = int(picks.get(item, 0)) + 1
		check(state.call("recipe_secret", def.id).state == "desconhecida", "nome escondido até Inventar")
		check(state.call("cook_invented", picks, def.type) == "", "Inventar revela " + str(def.name))
		state.call("dev_finish_timers")
		state.call("collect", "stove")
		var secret: Dictionary = state.call("recipe_secret", def.id)
		check(secret.state == "descoberta" and secret.pieces.is_empty() and state.call("dish_record", secret.key).get("source") == "invent", "mesma chave com origem Inventar")
	var known: int = state.get("progress").call("stat", "dishes_known")
	# Repete a coleta pelos mesmos gatilhos já validados acima, em ordem inversa.
	for source: String in ["dig", "fish", "eggs", "orchard", "cart"]:
		for i in int({"dig":16, "fish":3, "eggs":2, "orchard":2, "cart":3}[source]):
			state.call("_recipe_source", source)
	check(state.get("progress").call("stat", "dishes_known") == known and finds_seen == 12, "páginas depois de Inventar também são idempotentes")


func test_wish() -> void:
	reset()
	day(6)
	state.call("_grant_upgrade", "sofa")
	state.call("dev_unlock_everything")
	var tasted := make("papinha", ["potato", "egg"])
	var same_flavor := make("papinha", ["potato", "zucchini"])
	var different_flavor := make("papinha", ["carrot", "pumpkin"])
	var different_quality: String = rules.call("make_id", "papinha", ["batata", "ovo"], 3)
	check(state.call("feed", str(tasted.output)), "Tiro provou a primeira receita")
	inventory.call("add", different_quality, 1)
	var flavor: String = state.call("dish_info", str(same_flavor.output)).taste
	state.get("wishes").current = {"id": "recipe_novelty", "item": flavor, "period": "test", "since": clock, "progress": 0}
	check(state.call("wishes_open"), "desejos abertos")
	check(state.call("wish_wants_item", str(same_flavor.output)), "prato inédito do sabor pedido aceito")
	check(not state.call("wish_wants_item", different_quality), "outra qualidade da receita já provada não vale")
	check(not state.call("wish_wants_item", str(different_flavor.output)), "outro sabor não vale")
	check(state.call("fulfill_wish", {}, different_quality) != "" and state.call("wish_id") == "recipe_novelty", "recusa não consome o desejo")
	check(state.call("fulfill_wish", {}, str(same_flavor.output)) == "" and int(state.get("progress").call("stat", "wish:recipe_novelty")) == 1, "novidade atende pelo fluxo de servir")


func pause(seconds: float = 0.20) -> void:
	await create_timer(seconds).timeout


func node(id: String) -> Control:
	return main.find_child(id, true, false) as Control


func touch(id: String) -> void:
	var control := node(id)
	check(control != null and control.is_visible_in_tree(), "controle " + id)
	if control == null:
		return
	var scroll := control.get_parent()
	while scroll != null and not scroll is ScrollContainer:
		scroll = scroll.get_parent()
	if scroll is ScrollContainer:
		(scroll as ScrollContainer).ensure_control_visible(control)
		await pause(0.1)
	var point := control.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.pressed = pressed
		root.push_input(event, true)
	await pause()


func shot(name: String) -> void:
	if not screenshots:
		return
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/e11_livro")
	DirAccess.make_dir_recursive_absolute(folder)
	check(frame.save_png(folder.path_join("%dx%d_%s.png" % [frame.get_width(), frame.get_height(), name])) == OK, "captura " + name)


func clear_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_quest_reward", "_growth_ceremony"]:
		var layer: Node = main.get(member)
		layer.call("hide")
	main.set("_modal_queue", [] as Array[Callable])


func test_ui() -> void:
	reset()
	day(5)
	for i in 6:
		make("papinha", ["carrot", "corn"], 3, true)
	make("papinha", ["pumpkin", "corn"])
	state.call("talk_to", "bloblo")
	inventory.call("add", "carrot", 4)
	inventory.call("add", "corn", 5)
	inventory.call("add", "potato", 2)
	inventory.call("add", "egg", 2)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await pause(0.6)
	clear_modals()
	load("res://scripts/ui/pet_notebook.gd").call("open", "recipes")
	await pause(0.5)
	check(node("RecipeBook") != null and node("ChefCard") != null, "Livro no Caderninho")
	await touch("BookIngredient_cenoura")
	check(node("BookPotItem_cenoura") != null, "ingrediente vai para a Panela")
	await shot("01_livro")
	await touch("BookPotItem_cenoura")
	check(node("BookPotItem_cenoura") == null, "tocar na Panela tira o ingrediente")
	await touch("BookDish_dish_papinha_cenoura+milho")
	check(node("BookDishSheet") != null, "toque abre o painel do prato")
	await shot("03_receita")
	await touch("BookNeed_cenoura")
	check(node("BookDishSheet") == null and node("BookPotItem_cenoura") != null, "ingrediente do painel põe só ele na Panela")
	await touch("BookDish_dish_papinha_cenoura+milho")
	await touch("BookCookTogether")
	await pause(1.0)
	var together: Node = main.find_child("CookTogether", true, false)
	check(together != null, "da página da receita ao Cozinhar junto")
	if together != null:
		together.call("cancel")
	main.call("show_screen", &"pet")
	load("res://scripts/ui/pet_notebook.gd").call("open", "recipes")
	await pause(0.5)
	await touch("BookSecret")
	check(node("BookSecret_curau_do_tiro") != null, "toque na faixa abre as receitas secretas")
	await shot("04_segredos")
	events.emit_signal("sheet_close_requested")
	await pause()
	clear_modals()
	# Pedaço solto vira só aviso; o cartão Achado! aparece quando a receita fica completa.
	state.call("_recipe_source", "eggs")
	await pause(0.5)
	check(main.find_child("RecipePieceCard", true, false) == null, "pedaço solto não abre cartão")
	for i in 12:
		state.call("_recipe_source", "dig")
	state.call("_recipe_source", "orchard")
	await pause(0.5)
	check(main.find_child("RecipePieceCard", true, false) != null, "receita completa abre cartão Achado!")
	await shot("05_achado")


func _run() -> void:
	if not screenshots:
		root.size = Vector2i(360, 780)
	state = root.get_node("GameState")
	database = root.get_node("Database")
	load("res://tests/helpers/old_day_rules.gd").new().apply(database)
	events = root.get_node("Events")
	var saver := root.get_node("SaveManager")
	events.state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	state.set_script(load("res://tests/friend_clock.gd"))
	state.set("test_time", clock)
	rules = load("res://scripts/state/dish_rules.gd")
	events.recipe_piece_found.connect(func(_id: String, _count: int) -> void: finds_seen += 1)
	Motion.reduced = true
	if not screenshots:
		test_mastery()
		test_stock_and_day()
		test_secrets()
		test_ingredient_sources()
		test_wish()
	await test_ui()
	print("RECIPE BOOK TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(int(failures > 0))
