extends RefCounted
## Percurso usado pelo teste da semana e como abertura da campanha. Só o tempo é injetado.

var state: Node
var db: Node
var verify: Callable
var on_action: Callable
var first_dish_stars := 3
var cooking_stars := 1
var after_day_two: Dictionary
var day_one_wait: Dictionary
var farewell_pending: Dictionary
var village_bridge: Dictionary
var day_one_story: Dictionary


func _init(game: Node, database: Node, check: Callable) -> void:
	state = game
	db = database
	verify = check


func wait_for_work(seconds: float) -> void:
	state.advance_clock(seconds)


func action(panel: String, touches: int = 1) -> void:
	if on_action.is_valid():
		on_action.call(panel, touches)


func ok(result: String, action: String) -> void:
	verify.call(result == "", action + " · " + result)


func at(day: int, hour: int) -> void:
	state.dev_week_goto(day)
	state.dev_week_hour(hour)


func claim(id: String) -> void:
	if state.progress.claimed_quests.has(id) and bool(state.get_node("/root/Database").quests.get(id, {}).get("auto_claim", false)):
		return  # passo de transição: já se entregou sozinho quando ficou pronto
	verify.call(state.progress.current_main_quest() == id, "Passo da História " + id)
	action("história")
	ok(state.claim_quest(id), id)


func make_space(gain: Dictionary) -> void:
	var shortage: Dictionary = state.storage_shortage(gain)
	while not shortage.is_empty():
		var sold := false
		for item: String in ["corn", "pumpkin", "carrot", "potato", "oat_biscuit", "fish_lambari", "fish_cara", "egg", "oat"]:
			if gain.has(item) or state.storage_of(item) != shortage.depot or state.inventory.count(item) == 0:
				continue
			action("banca")
			var error: String = state.sell(item, 1, "farm")
			ok(error, "Abrir espaço vendendo " + item)
			sold = error == ""
			break
		if not sold:
			verify.call(false, "Sem espaço para " + str(gain))
			break
		shortage = state.storage_shortage(gain)


func crop(id: String, qty: int) -> void:
	var output := id
	for i in range(6):
		if state.inventory.count(output) >= qty:
			return
		var index := int(db.farm.corn_plot) if id == "corn" else 0
		make_space(db.crops[id].yield)
		action("horta")
		ok(state.plant(index, id), "Plantar " + id)
		wait_for_work(float(state.crop_seconds(index, id)) + 1.0)
		action("horta")
		verify.call(state.harvest(index).has(id), "Colher " + id)
	verify.call(false, "Estoque de " + id)


func buy(id: String, qty: int = 1) -> void:
	action("banca")
	ok(state.buy_shop_item(id, qty), "Comprar " + id)


func collect(station: String) -> String:
	var job: Dictionary = state.station(station).queue.back() if not state.station(station).queue.is_empty() else {}
	if job.is_empty():
		return ""
	wait_for_work(maxf(0.0, float(job.ready_at) - state.now()) + 1.0)
	var item := str(job.job.output)
	make_space({item: int(job.job.qty)})
	action("produção")
	verify.call(state.collect(station).has(item), "Recolher " + item)
	return item


func recipe(id: String, stars: int = 1, together: bool = false) -> String:
	for item: String in state.recipe_inputs(id):
		var needed: int = state.recipe_inputs(id)[item]
		if state.inventory.count(item) == 0 and item == "oat":
			buy("week_oat", needed)
		elif db.crops.has(item):
			crop(item, needed)
	action("fogão")
	ok(state.cook_many(id, 1, stars, together), "Preparar " + id)
	return collect("stove")


func dish(type: String, ingredients: Dictionary) -> String:
	for item: String in ingredients:
		if state.inventory.count(item) >= int(ingredients[item]):
			continue
		if item == "oat":
			buy("week_oat", int(ingredients[item]))
		elif db.crops.has(item):
			crop(item, int(ingredients[item]))
	action("fogão")
	ok(state.cook_invented(ingredients, type, cooking_stars, cooking_stars > 1), "Inventar " + type + " " + str(ingredients))
	return collect("stove")


func serve(item: String) -> void:
	verify.call(item != "" and state.feed(item), "Servir " + item)


func meal(day: int, hour: int, item: String = "") -> void:
	at(day, hour)
	serve(recipe("puppy_mash") if item == "" else item)


func ball() -> void:
	action("quintal")
	var round: Dictionary = state.start_yard_round("ball")
	verify.call(round.has("id"), "Abrir Bolinha")
	for i in int(state.yard_rules().throws):
		action("quintal")
		state.yard_throw(int(round.get("id", -1)), Vector2(8.0, -45.0))
		state.advance_clock(1.6)
		state.yard_finish_throw(int(round.get("id", -1)), false)


func name_calls() -> void:
	for i in 3:
		action("quintal")
		var round: Dictionary = state.start_yard_round("name")
		state.advance_clock(0.8)
		action("quintal")
		verify.call(state.yard_answer_name(int(round.get("id", -1))).get("done", false), "Chamar pelo nome")


func rope() -> void:
	action("quintal")
	var round: Dictionary = state.start_yard_round("rope")
	for i in int(state.yard_rules().pulls):
		action("quintal")
		state.yard_rope_hold(int(round.get("id", -1)))
		state.advance_clock(1.2)
		state.yard_rope_release(int(round.get("id", -1)))


func lesson(id: String) -> void:
	if state.trick_lesson_cookies().is_empty():
		recipe("week_oat_biscuit")
	action("aula")
	ok(state.start_trick_lesson(id), "Aula de " + id)
	for i in 5:
		action("aula")
		state.trick_lesson_step(id, "show", 1.0)
		action("aula")
		state.trick_lesson_step(id, "mark", 1.0)
		action("aula")
		state.trick_lesson_step(id, "reward", 0.1)


func catch_fish() -> String:
	action("lagoa")
	ok(state.cast("bait_worm", 1, false), "Lançar na lagoa")
	wait_for_work(float(state.fishing.cast.get("wait", 0.0)) + 0.1)
	action("lagoa")
	ok(state.hook(), "Fisgar")
	var id := str(state.fishing.cast.get("fish", ""))
	action("lagoa")
	ok(state.finish_fishing({"caught": true, "score": 0.56, "perfect": false}), "Recolher peixe")
	return id


func eggs(qty: int) -> void:
	while state.inventory.count("egg") < qty:
		crop("corn", 2)
		action("galinheiro")
		ok(state.cook("eggs"), "Alimentar as galinhas")
		if collect("chicken_coop") == "":
			return


func funds(amount: int) -> void:
	for i in range(12):
		if state.coins >= amount:
			return
		crop("potato", 3)
		action("banca")
		ok(state.sell("potato", 3, "farm"), "Vender batatas")


## Ato 1 do novo fluxo (F01): os oito passos em casa, só com a papinha da caixinha e sem moeda.
func ato_one() -> void:
	var coins: int = state.coins
	verify.call(state.album.has_photo("h_arrival"), "Foto da chegada")
	action("cuidar")
	verify.call(state.feed("puppy_mash"), "Dar a papinha da caixinha")
	verify.call(state.meals_on_time(1) == 1 and state.well_fed_days() == 1, "Primeira papinha fora da janela dá patinha")
	claim("lais_feed")
	verify.call(state.bathe(), "Dar banho")
	claim("lais_bath")
	verify.call(state.play(), "Jogar a bolinha")
	claim("lais_play")
	ok(state.buy_upgrade("dog_bed"), "Colocar a caminha")
	claim("lais_bed")  # a rotina do dia paga as moedas da primeira refeição só a partir daqui
	verify.call(state.growth.phase == "newborn" and state.coins == coins, "Ato 1 inteiro sem moeda, ainda recém-chegado")


## Ato 2 do novo fluxo (F03): Sítio, vovó, primeira horta, fogão colocado, Cozinhar junto e a primeira papinha (aula da comida).
## Sem moeda e sem banca até o fim do passo 14. Devolve a papinha que o passo 14 deu ao Tiro.
func ato_two(first_stars: int = 3, late_arrival: bool = true) -> void:
	var coins: int = state.coins
	action("mapa")
	state.note_screen_opened("farm")
	claim("lais_farm")
	action("sítio")
	state.talk_to("bloblo")
	verify.call(state.progress.claimed_quests.has("bloblo_meet"), "Conhecer a vovó se completa sozinho ao falar com ela")
	verify.call(state.progress.current_main_quest() == "lais_first_crops", "Conhecer a vovó fecha o passo 10")
	crop("carrot", 1)
	crop("potato", 1)
	claim("lais_first_crops")
	verify.call(state.inventory.count("stove_gift") == 1 and not state.has_upgrade("stove"), "A vovó dá o fogãozinho, ainda sem colocar")
	action("casa")
	ok(state.buy_upgrade("stove"), "Colocar o fogão")
	verify.call(state.has_upgrade("stove") and state.coins == coins, "O fogão é de graça")
	claim("place_stove")
	var food := recipe("puppy_mash", first_stars, true)
	verify.call(state.progress.stat("together:puppy_mash") == 1, "Cozinhar junto conta o passo 13")
	claim("first_kitchen")
	if late_arrival:
		at(1, 23)
	serve(food)  # a aula da comida é da tela; aqui só o estado: dar a papinha cumpre o passo 14
	verify.call(state.well_fed_days() == 1, "A segunda papinha do dia da chegada não repete a patinha")
	verify.call(state.coins == coins, "Ato 2 inteiro sem moeda")
	claim("first_meal")
	# O capítulo 1 fecha com o crescimento: a papinha caseira é o último pedido do Filhotinho.
	action("crescimento")
	state.note_screen_opened("growth")
	state.note_growth_lesson()
	claim("lais_growth")
	ok(state.grow(), "Virar Filhotinho no fim do capítulo 1")
	claim("growth_1_puppy")
	verify.call(state.growth.phase == "puppy", "O capítulo 1 termina em Filhotinho")


func day_one(late_arrival: bool = true) -> void:
	at(1, 9)
	verify.call(not state.progress.seen.has("intro") and state.progress.current_main_quest() == "welcome", "Save novo começa na caixa")
	action("chegada", 4)
	state.finish_week_arrival()
	state.finish_home_tour()
	claim("welcome")
	day_one_story = snapshot()
	ato_one()
	ato_two(first_dish_stars, late_arrival)
	verify.call(first_dish_stars < 3 or state.economy.granted.has("week_challenge:1"), "Desafio de três estrelas pago")
	# Capítulo 2: banca, mais canteiros e a primeira sopinha.
	crop("carrot", 4)
	action("banca")
	ok(state.sell("carrot", 4, "farm"), "Venda de quatro cenouras")
	buy("week_pumpkin_seed")
	buy("week_oat")
	claim("week_market")
	action("horta")
	ok(state.buy_plot(2), "Terceiro canteiro")
	buy("week_plot")
	action("horta")
	ok(state.plant(0, "pumpkin"), "Plantar abóbora")
	wait_for_work(float(state.crop_seconds(0, "pumpkin")) + 1.0)
	action("horta")
	state.harvest(0)
	claim("week_plots")
	action("álbum")
	state.finish_album_tutorial()
	claim("lais_photo")  # a foto da chegada: depois dos canteiros, com algum dinheiro
	funds(40)
	ok(state.buy_upgrade("fridge"), "Comprar a geladeira")
	claim("week_fridge")
	verify.call(state.cook_invented_error({"pumpkin": 1, "potato": 1}, "papinha") == "Continue a História", "Inventar espera o capítulo 8")
	if not late_arrival:
		at(1, 19)
	var soup := recipe("vegetable_soup")
	verify.call(state.progress.stat("week_soup") == 1, "Sopinha recolhida conta o passo")
	claim("week_soup")
	verify.call(state.album.has_photo("h_week_soup") and state.photo_sealed("h_week_soup") == 1, "O capítulo 2 fecha com uma carta fechada")
	serve(soup)
	verify.call(state.quest_unlocked("lais_first_wish"), "O capítulo 3 abre na hora, sem esperar o relógio")
	verify.call(state.claim_quest("lais_first_wish") != "", "O passo do capítulo 3 ainda pede o desejo")
	day_one_wait = snapshot()


## Capítulo 3: atender o primeiro desejo do Tiro e pegar o passo.
func first_wish() -> void:
	var wish: Dictionary = state.wish_now()
	if wish.get("type") == "action":
		while state.wish_value() < state.wish_target():
			var previous: int = state.wish_value()
			match str(wish.goal.key):
				"pet": state.pet()
				"bathe": state.bathe()
				"play": state.play()
				_:
					verify.call(false, "Desejo inesperado: " + str(wish))
					break
			if state.wish_value() <= previous:
				verify.call(false, "Desejo sem avanço: " + str(wish))
				break
	action("desejo")
	ok(state.fulfill_wish(), "Atender ao primeiro desejo")
	claim("lais_first_wish")
	verify.call(state.album.has_photo("h_week_wish"), "O capítulo 3 fecha com uma carta")


func day_two() -> void:
	var before: int = state.coins
	at(2, 11)
	verify.call(state.coins - before == 30, "Bom dia paga 30 moedas uma vez")
	state.update_week()
	verify.call(state.coins - before == 30, "Atualizar o relógio não repete o Bom dia")
	first_wish()
	# Capítulo 4: galinheiro e prato com ovo.
	funds(60)
	before = state.coins
	buy("week_coop")
	verify.call(state.coins == before - 40, "Kit custa 60 e devolve 20 na compra")
	verify.call(state.buy_shop_item("week_coop") != "" and state.coins == before - 40, "Recibo único do kit")
	claim("week_coop")
	eggs(2)
	claim("week_eggs")
	serve(recipe("egg_mash"))
	verify.call(key_done("egg"), "Ovo simultâneo na História e em Para crescer")
	claim("week_egg_dish")
	# Capítulo 5: biscoitos e Senta.
	recipe("week_oat_biscuit")
	claim("week_biscuits")
	lesson("sit")
	claim("week_sit")
	verify.call(state.album.has_photo("h_first_trick"), "O capítulo 5 fecha com uma carta")
	serve("oat_biscuit")
	at(2, 19)
	meal(2, 19)
	verify.call(state.growth.phase == "puppy" and state.progress.stat("well_fed_day") == 2, "Duas patinhas, a da chegada e a do dia 2")
	after_day_two = snapshot()


## Capítulo 6: lagoa e prato com peixe.
func lake(day: int) -> void:
	at(day, 11)
	state.note_week_pier()
	claim("week_bridge")
	catch_fish()
	catch_fish()
	verify.call(state.progress.stat("fish") == 2, "Duas pescarias reais")
	claim("week_fish")
	# A papinha de peixe do fogão pede tilápia; a pescaria do teste sorteia qualquer peixe.
	state.inventory.add("fish_tilapia", 1)
	serve(recipe("fish_mash"))
	verify.call(key_done("fish"), "Peixe simultâneo na História e em Para crescer")
	claim("week_fish_dish")
	meal(day, 19, recipe("vegetable_soup"))


func key_done(group: String) -> bool:
	var story_goal := {"type": "week_dish", "key": group}
	return state.goal_value(story_goal) >= 1 and state.growth_info().requirements.any(
		func(row: Dictionary) -> bool: return row.id == "key_" + group and row.done)


## Capítulos 7 e 8: pomar e mingau; depois Inventar e Livro de receitas.
func day_four() -> void:
	at(4, 11)
	make_space({"apple": 2, "banana": 2})
	action("pomar")
	ok(state.harvest_orchard("apple"), "Colher maçãs")
	action("pomar")
	ok(state.harvest_orchard("banana"), "Colher bananas")
	claim("week_orchard")
	serve(recipe("banana_mash"))
	verify.call(key_done("fruit"), "Fruta simultânea na História e em Para crescer")
	claim("week_fruit_dish")
	verify.call(state.album.has_photo("h_week_mingau"), "O capítulo 7 fecha com uma carta")
	verify.call(state.progress.chapter_index() == 8 and state.invent_open(), "Inventar abre no capítulo 8")
	at(4, 19)
	serve(dish("papinha", {"pumpkin": 1, "potato": 1}))
	make_space({"oat": 2})
	claim("week_invent")
	action("livro")
	state.note_screen_opened("recipes")
	claim("week_book")
	verify.call(state.album.has_photo("h_week_book"), "O capítulo 8 fecha com uma carta")


## Capítulo 9: carroça e banho com xampu.
func day_five() -> void:
	at(5, 11)
	eggs(4)
	serve(recipe("egg_mash"))
	verify.call(key_done("egg"), "O ovo fica registrado em Filhotinho antes do quintal")
	# Preserve três ovos para a carroça e prepare as abóboras do segundo pedido.
	crop("pumpkin", 2)
	for id: String in state.cart_order_ids():
		for item: String in db.progression.cart_catalog[id].inputs:
			var needed: int = db.progression.cart_catalog[id].inputs[item]
			if item == "egg":
				eggs(needed)
			elif item == "apple" or item == "banana":
				if state.inventory.count(item) < needed:
					action("pomar")
					state.harvest_orchard(item)
			elif db.crops.has(item):
				crop(item, needed)
			else:
				for i in 5:
					if state.inventory.count(item) >= needed: break
					if state.inventory.count("bait_worm") == 0: buy("worm_pack")
					catch_fish()
		if state.order_error(id) == "":
			action("carroça")
			ok(state.fulfill_order(id), "Encomenda " + id)
	verify.call(state.progress.stat("cart_delivery") >= 1, "Pelo menos um pedido da carroça")
	claim("week_cart_order")
	funds(30)
	buy("cart_shampoo")
	action("cuidado")
	verify.call(state.bathe(true), "Banho com xampu")
	claim("week_bath")
	verify.call(state.album.has_photo("h_week_foam"), "O capítulo 9 fecha com uma carta")
	meal(5, 19, dish("sopinha", {"carrot": 2, "potato": 1}))


## Capítulo 10: quintal, mais truques e o show.
func day_six() -> void:
	at(6, 11)
	verify.call(state.yard_open("ball"), "O quintal abre no capítulo 10")
	ball()
	ball()
	claim("week_fetch")
	name_calls()
	rope()
	rope()
	claim("week_rope")
	lesson("paw")
	lesson("sit")
	claim("week_paw")
	lesson("lie_down")
	lesson("sit")
	claim("week_down")
	for i in 3:
		action("quintal")
		var round: Dictionary = state.start_yard_round("hide")
		state.advance_clock(1.2)
		action("quintal")
		state.yard_find(int(round.get("id", -1)), int(round.get("hideout", -1)))
	claim("week_hide")
	serve(recipe("puppy_mash"))
	ball()
	ball()
	action("show")
	var show: Dictionary = state.start_trick_show(5)
	verify.call(show.has("sequence"), "Abre o show")
	for id: String in show.get("sequence", []):
		action("show")
		state.trick_show_step(id, true)
	verify.call(state.album.has_photo("h_trick_show"), "O show tira a foto do capítulo 10")
	claim("week_show")
	verify.call(state.album.has_photo("h_trick_show"), "O capítulo 10 fecha com uma carta")
	meal(6, 19, dish("papinha", {"pumpkin": 1, "carrot": 1}))


## Capítulo 11: mordedor, almoço de despedida e Dentinhos.
func day_seven() -> void:
	at(7, 11)
	funds(50)
	buy("week_teether")
	action("crescimento")
	ok(state.deliver_growth("chew_ring"), "Entrega do mordedor")
	claim("teeth_3_ring")
	verify.call(state.grow_error() != "", "Cerimônia espera o almoço")
	var grandma := recipe("puppy_mash")
	var lais := recipe("puppy_mash")
	var tiro := dish("papinha", {"potato": 2})
	action("almoço")
	ok(state.serve_week_farewell("bloblo", grandma), "Prato da vovó")
	var saved: Dictionary = state.to_dict().duplicate(true)
	farewell_pending = snapshot()
	state.from_dict(saved)
	verify.call(state.serve_week_farewell("bloblo", grandma) == "Prato já servido", "Lugar servido sobrevive ao save")
	action("almoço")
	ok(state.serve_week_farewell("lais", lais), "Prato da Laís")
	verify.call(not state.album.has_photo("h_week_group"), "Foto de grupo espera o terceiro prato")
	action("almoço")
	ok(state.serve_week_farewell("tiro", tiro), "Prato do Tiro")
	verify.call(state.album.has_photo("h_week_group") and state.meals_on_time(state.week_day()) == 1, "Foto e almoço na hora")
	meal(7, 19)
	action("crescimento")
	ok(state.grow(), "Virar Dentinhos")
	claim("growth_3_teething")
	verify.call(state.progress.chapter_index() == 12 and state.progress.current_main_quest() == "lais_village", "A Vila é o capítulo 12")
	village_bridge = snapshot()
	state.note_world_visit("village")
	state.note_screen_opened("village")
	claim("lais_village")


func snapshot() -> Dictionary:
	var data: Dictionary = state.to_dict().duplicate(true)
	return data.merged({"test_clock": state.now()})


func restore(data: Dictionary) -> void:
	state.set_clock(float(data.test_clock))
	state.from_dict(data)


func run() -> void:
	day_one()
	day_two()
	lake(3)
	day_four()
	day_five()
	day_six()
	day_seven()


