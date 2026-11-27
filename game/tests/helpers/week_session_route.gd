extends "res://tests/helpers/week_economy_route.gd"
## F05 do plano "Novo fluxo": percurso da semana nova por SESSÕES no relógio (não por "dia N").
## O robô entra e sai em horários do perfil, espera a produção dentro da sessão só quando é curta
## (senão sai e volta na próxima sessão), dá as refeições ao vivo na janela e usa a tigela de dois
## lugares antes de sair. Só ações reais do GameState: sem dev_*, sem depósito ilimitado, sem ready_at forçado.

## Perfis: horas de entrada, minutos de jogo por sessão (depois da primeira), dias de calendário que faltam.
const PROFILES := {
	"muito": {"hours": [8, 11, 14, 17, 20], "cap": 30.0, "skip": []},
	"regular": {"hours": [8.5, 19.5], "cap": 45.0, "skip": []},
	"perde_dia": {"hours": [8.5, 19.5], "cap": 45.0, "skip": [4]},
}
## Espera de até quatro minutos fica dentro da sessão (o jogador faz outra coisa); mais que isso, ele sai.
const STAY := 240.0
## Tempo de leitura e de gesto de uma pessoa (o robô é instantâneo): segundos extras por tipo de painel, além dos 3 s por toque.
const READ := {"chegada": 150.0, "história": 35.0, "crescimento": 45.0, "álbum": 90.0, "cuidar": 8.0, "mapa": 15.0, "sítio": 10.0,
	"horta": 6.0, "banca": 10.0, "fogão": 20.0, "produção": 6.0, "aula": 8.0, "quintal": 6.0, "lagoa": 15.0, "carroça": 15.0,
	"show": 8.0, "almoço": 20.0, "pomar": 6.0, "livro": 30.0, "cuidado": 8.0, "desejo": 15.0, "galinheiro": 8.0, "casa": 10.0, "montinho": 15.0}

var hours: Array = []
var cap_minutes := 30.0
var skip_days: Array = []
var protect := true
var in_service := false
var sess_acc := 0.0
var wait_in := 0.0
var max_wait := 0.0
var chap_cum := {}
var phase_cum := {}
var min_coins := 999999
var full_hits := {"silo": 0, "fridge": 0, "warehouse": 0, "chest": 0}
var first_session_min := 0.0
var secret_log := {"worm": 0, "fish": 0, "stew": 0, "extra_paws": 0}
var long_waits: Array = []


func cal_day(t: float) -> int:
	return int(floor((t - initial_midnight) / 86400.0)) + 1


func next_slot(t: float, honor_skips: bool = true) -> float:
	var number := cal_day(t)
	for step in 400:
		var n := number + step
		if honor_skips and n in skip_days:
			continue
		for h in hours:
			var at_time := initial_midnight + float(n - 1) * 86400.0 + float(h) * 3600.0
			if at_time >= t - 1.0:
				return at_time
	return t


func sess_total() -> float:
	return sess_acc + (state.now() - session_start if active_session else 0.0)


func close_session() -> void:
	if active_session:
		day.sessions_seconds += state.now() - session_start
		sess_acc += state.now() - session_start
		active_session = false


func start_session() -> void:
	while rows.size() < cal_day(state.now()):
		open_day(rows.size() + 1)
	day.sessions += 1
	session_start = state.now()
	active_session = true
	serve_live()


func observe(changed: bool = true) -> void:
	super.observe(changed)
	min_coins = mini(min_coins, state.coins)
	var cal := cal_day(state.now())
	var chapter: int = state.progress.chapter_index()
	for n in range(1, chapter):
		if not chap_cum.has(str(n)):
			chap_cum[str(n)] = {"day": cal, "touch": touch_total, "wait": wait_in, "sess": sess_total(), "coins": state.coins}
	var phase: String = state.growth.phase
	if phase != "newborn" and not phase_cum.has(phase):
		phase_cum[phase] = {"day": cal, "hour": snappedf(fposmod(state.now() - initial_midnight, 86400.0) / 3600.0, 0.1)}
	for depot in ["silo", "fridge", "warehouse", "chest"]:
		if state.storage_used(depot) >= state.storage_capacity(depot):
			full_hits[depot] += 1


## Esperar a produção: curta, fica na sessão; longa (ou sessão já cheia), sai e volta na próxima entrada depois do pronto.
func wait_for_work(seconds: float) -> void:
	max_wait = maxf(max_wait, seconds)
	var over: bool = active_session and not protect and (state.now() - session_start) >= cap_minutes * 60.0
	if in_service or protect or (seconds <= STAY and not over):
		day.wait_seconds += seconds
		wait_in += seconds
		state.advance_clock(seconds)
		return
	long_waits.append("c%d:%.0f" % [int(state.progress.chapter_index()), seconds / 60.0])
	leave_until(state.now() + seconds)


func time_action(panel: String, touches: int) -> void:
	if active_session and not in_service and not protect and (state.now() - session_start) >= cap_minutes * 60.0:
		leave_until(state.now())
	super.time_action(panel, touches)
	var extra: float = float(READ.get(panel, 0.0)) + (40.0 if panel == "fogão" and cooking_stars > 1 else 0.0)
	touch_total += extra
	day.touch_seconds += extra
	state.advance_clock(extra)
	if not in_service and active_session:
		serve_live()


## Sai (guarda a refeição na tigela), passa o tempo fora do jogo e entra na primeira sessão marcada depois de `ready`.
func leave_until(ready: float) -> void:
	if in_service:
		state.advance_clock(maxf(0.0, ready - state.now()))
		return
	var target := next_slot(ready)
	serve_live()
	fill_bowl(next_slot(ready, false))  # quem perde um dia não sabia que ia perder: a tigela segue o combinado normal
	close_session()
	state.begin_absence(state.now())
	state.advance_clock(maxf(0.0, target - state.now()))
	state.end_absence()
	state.update_week()
	start_session()


# ---------------------------------------------------------------- refeições

func best_meal() -> String:
	if profile == "muito" and state.inventory.count("golden_stew") > 0 and state.secret_bonus_total() < 2:
		return "golden_stew"
	var owned: Array[String] = state.meal_items_owned()
	owned.sort_custom(func(a: String, b: String) -> bool: return state.inventory.count(a) > state.inventory.count(b))
	return owned[0] if not owned.is_empty() else ""


func meal_item() -> String:
	var item := best_meal()
	if item == "" and state.station("stove").queue.is_empty():
		item = recipe("puppy_mash")
	return item


## Janela aberta e ainda sem a refeição dela: dá ao vivo.
func serve_live() -> void:
	# Antes de abrir a caixinha `food_lesson_done()` vale (save sem a chegada): o robô só come depois dela.
	if in_service or not state.progress.seen.has("intro") or not state.food_lesson_done():
		return
	var info: Dictionary = state.meal_info()
	var period := str(info.period)
	if state.inventory.count("golden_stew") > 0 and secret_log.size() < 12:
		secret_log["dbg" + str(secret_log.size())] = "%s|%s|%s|%s" % [period, str(info.done), state.meal_error("golden_stew"), str(state.week_hour())]
	if bool(info.done.get(period, {}).get("on_time", false)):
		return
	if bool(info.arrival) and int(info.on_time) >= int(info.needed):
		return
	in_service = true
	var item := meal_item()
	if item != "" and state.meal_error(item) == "":
		action("cuidar")
		state.feed(item)
		if item == "golden_stew":
			secret_log.extra_paws = state.secret_bonus_total()
	in_service = false


## Tigela de dois lugares: guarda uma refeição para cada metade do dia que começa antes de ele voltar.
func fill_bowl(back_at: float) -> void:
	if in_service or not state.food_lesson_done():
		return
	in_service = true
	for i in 2:
		var target: Dictionary = state.meal_next_target()
		if target.is_empty() or state.week.stored.size() >= 2:
			break
		var ends: float = state.half_end_time(int(target.day), str(target.period))
		if ends > back_at:  # ele volta antes de a metade acabar: dá ao vivo (a tigela é só para a metade que ele perderia)
			break
		var item := ""
		for id: String in state.meal_items_owned():
			if id != "golden_stew" and id != "dog_food":
				item = id
				break
		if item == "" and state.station("stove").queue.is_empty():
			item = recipe("puppy_mash")
		if item == "" or state.store_meal(item) != "":
			break
		action("cuidar")
	in_service = false


# ---------------------------------------------------------------- horta em paralelo

## Planta todos os canteiros livres de uma vez e espera uma vez só (como uma pessoa faria).
func crop(id: String, qty: int) -> void:
	for attempt in range(8):
		var have: int = state.inventory.count(id)
		if have >= qty:
			return
		var per := int(db.crops[id].yield.get(id, 1))
		var batches := ceili(float(qty - have) / float(per))
		var planted: Array[int] = []
		var longest := 0.0
		for index in state.usable_plot_indices():
			if planted.size() >= batches:
				break
			if state.plant_error(index, id) != "":
				continue
			make_space({id: per * (planted.size() + 1)})
			action("horta")
			ok(state.plant(index, id), "Plantar " + id)
			planted.append(index)
			longest = maxf(longest, float(state.crop_seconds(index, id)))
		if planted.is_empty():
			wait_for_work(60.0)
			continue
		wait_for_work(longest + 1.0)
		for index in planted:
			action("horta")
			state.harvest(index)
	verify.call(false, "Estoque de " + id)


# ---------------------------------------------------------------- capítulos

func chapter_two() -> void:
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
	var soup := recipe("vegetable_soup")
	claim("week_soup")
	serve(soup)


func chapter_three() -> void:
	for attempt in 4:
		state.update_wishes()
		if not state.wish_now().is_empty():
			break
		wait_for_work(3600.0)
	first_wish()


func chapter_four() -> void:
	funds(60)
	buy("week_coop")
	claim("week_coop")
	eggs(2)
	claim("week_eggs")
	serve(recipe("egg_mash"))
	claim("week_egg_dish")


func chapter_five() -> void:
	recipe("week_oat_biscuit")
	claim("week_biscuits")
	lesson("sit")
	claim("week_sit")
	serve("oat_biscuit")


func chapter_six() -> void:
	state.note_week_pier()
	claim("week_bridge")
	catch_fish()
	catch_fish()
	claim("week_fish")
	state.inventory.add("fish_tilapia", 1)  # a pescaria do robô sorteia qualquer peixe; a papinha pede tilápia
	serve(recipe("fish_mash"))
	claim("week_fish_dish")


func chapter_seven() -> void:
	make_space({"apple": 2, "banana": 2})
	action("pomar")
	ok(state.harvest_orchard("apple"), "Colher maçãs")
	action("pomar")
	ok(state.harvest_orchard("banana"), "Colher bananas")
	claim("week_orchard")
	serve(recipe("banana_mash"))
	claim("week_fruit_dish")


func chapter_eight() -> void:
	serve(dish("papinha", {"pumpkin": 1, "potato": 1}))
	make_space({"oat": 2})
	claim("week_invent")
	action("livro")
	state.note_screen_opened("recipes")
	claim("week_book")


func chapter_nine() -> void:
	eggs(4)
	serve(recipe("egg_mash"))
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
					if state.inventory.count(item) >= needed:
						break
					if state.inventory.count("bait_worm") == 0:
						buy("worm_pack")
					catch_fish()
		if state.order_error(id) == "":
			action("carroça")
			ok(state.fulfill_order(id), "Encomenda " + id)
	claim("week_cart_order")
	funds(30)
	buy("cart_shampoo")
	action("cuidado")
	ok("" if state.bathe(true) else "banho", "Banho com xampu")
	claim("week_bath")


func chapter_ten() -> void:
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
	for id: String in show.get("sequence", []):
		action("show")
		state.trick_show_step(id, true)
	claim("week_show")


func chapter_eleven() -> void:
	funds(50)
	buy("week_teether")
	action("crescimento")
	ok(state.deliver_growth("chew_ring"), "Entrega do mordedor")
	claim("teeth_3_ring")
	in_service = true  # os três pratos do almoço não podem ser comidos pelo serviço de refeições
	var grandma := recipe("puppy_mash")
	var lais := recipe("puppy_mash")
	var tiro := dish("papinha", {"potato": 2})
	action("almoço")
	ok(state.serve_week_farewell("bloblo", grandma), "Prato da vovó")
	action("almoço")
	ok(state.serve_week_farewell("lais", lais), "Prato da Laís")
	action("almoço")
	ok(state.serve_week_farewell("tiro", tiro), "Prato do Tiro")
	in_service = false
	# O que resta para os Dentinhos são as patinhas: o robô só segue as refeições dos dias.
	for i in 40:
		if state.grow_error() == "":
			break
		secret_if_open()
		leave_until(state.now() + 600.0)
	action("crescimento")
	ok(state.grow(), "Virar Dentinhos")
	claim("growth_3_teething")
	state.note_world_visit("village")
	state.note_screen_opened("village")
	claim("lais_village")


## Missão secreta (só o perfil `muito`): minhoca gorda no montinho, peixe dourado Perfeito, Ensopado Dourado 3 estrelas.
func secret_if_open() -> void:
	if profile != "muito" or not state.secret_open() or in_service:
		return
	state.update_finds()
	if state.inventory.count("golden_worm") == 0 and state.inventory.count("fish_golden") == 0 and state.inventory.count("golden_stew") == 0:
		if state.dig_error("farm") == "":
			action("montinho")
			if state.dig("farm").get("items", {}).has("golden_worm"):
				secret_log.worm += 1
	if state.inventory.count("golden_worm") > 0 and not state.golden_bitten_today():
		action("lagoa")
		if state.cast("golden_worm", 1, false) == "":
			wait_for_work(float(state.fishing.cast.get("wait", 0.0)) + 0.1)
			action("lagoa")
			if state.hook() == "":
				action("lagoa")
				state.finish_fishing({"caught": true, "score": 1.0, "perfect": true, "chest": false})
				secret_log.fish += 1
	if state.inventory.count("fish_golden") > 0 and state.secret_bonus_total() < 2:
		crop("pumpkin", 1)
		eggs(1)
		action("fogão")
		if state.cook_many("golden_stew", 1, 3, true) == "":
			var got := collect("stove")
			secret_log.stew += 1
			secret_log["got"] = got + ":" + str(state.inventory.count("golden_stew"))


func measure_sessions(name: String) -> Dictionary:
	profile = name
	var plan: Dictionary = PROFILES[name]
	hours = plan.hours
	cap_minutes = float(plan.cap)
	skip_days = plan.skip
	on_action = time_action
	first_dish_stars = 3 if name == "muito" else 2
	cooking_stars = {"muito": 3, "regular": 2, "perde_dia": 2}[name]
	verify = check
	origin = state.now()
	initial_midnight = state.now() - fposmod(state.now() + state.zone_bias, 86400.0)
	last_balance = state.coins
	open_day(1)
	var events := state.get_node("/root/Events")
	events.state_changed.connect(observe)
	active_session = true
	session_start = state.now()
	# Primeira sessão (Ato 1 + Ato 2): sem corte por tempo.
	verify.call(not state.progress.seen.has("intro") and state.progress.current_main_quest() == "welcome", "Save novo começa na caixa")
	action("chegada", 4)
	state.finish_week_arrival()
	state.finish_home_tour()
	claim("welcome")
	ato_one()
	ato_two(first_dish_stars, false)
	first_session_min = snappedf(sess_total() / 60.0, 0.1)
	protect = false
	var steps: Array[Callable] = [chapter_two, chapter_three, chapter_four, chapter_five, chapter_six,
		chapter_seven, chapter_eight, chapter_nine, chapter_ten, chapter_eleven]
	for step in steps:
		if not errors.is_empty():
			break
		secret_if_open()
		step.call()
	close_session()
	observe(false)
	events.state_changed.disconnect(observe)
	for row in rows:
		check(row.opening + row.income - row.expense == row.ending, "Conservação do saldo")
	check(not state.unlimited_storage and state.week.clock_offset == 0, "Depósitos e relógio de produção")
	var chapters_out := {}
	for key: String in chap_cum:
		var c: Dictionary = chap_cum[key]
		var previous: Dictionary = chap_cum.get(str(int(key) - 1), {"touch": 0.0, "wait": 0.0, "sess": 0.0})
		chapters_out[key] = {"day": c.day, "coins": c.coins,
			"session_min": snappedf((c.sess - previous.sess) / 60.0, 0.1),
			"wait_min": snappedf((c.wait - previous.wait) / 60.0, 0.1),
			"touch_min": snappedf((c.touch - previous.touch) / 60.0, 0.1)}
	return {"profile": profile, "chapters": chapters_out, "phases": phase_cum, "days": rows, "errors": errors,
		"phase": state.growth.phase, "village": state.progress.claimed_quests.has("lais_village"),
		"paws": state.well_fed_days(), "first_session_min": first_session_min,
		"session_min_total": snappedf(sess_total() / 60.0, 0.1), "touch_min_total": snappedf(touch_total / 60.0, 0.1),
		"wait_min_in_session": snappedf(wait_in / 60.0, 0.1), "max_wait_min": snappedf(max_wait / 60.0, 0.1),
		"long_waits_min": long_waits, "min_coins": min_coins, "full_hits": full_hits, "secret": secret_log,
		"last_day": cal_day(state.now())}
