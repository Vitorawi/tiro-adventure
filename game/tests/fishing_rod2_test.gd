extends SceneTree
## Pesca, etapa 07: vara de molinete no Feirante, massa de milho, baú da lagoa, ensopado de peixe, Aventureiro,
## missões e encomenda. Relógio injetado (friend_clock) e sem SaveManager: nada toca o disco.
## --headless --path game -s res://tests/fishing_rod2_test.gd

const T0 := 1900000000.0

var failures := 0
var state: Node
var db: Node
var original_chest: Dictionary = {}
var original_base := 0.0


func _initialize() -> void:
	_run.call_deferred()
	create_timer(150).timeout.connect(func() -> void: quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("VARA2: " + message)


func _p() -> RefCounted:
	return state.get("progress")


func _f() -> RefCounted:
	return state.get("fishing")


func _inv() -> RefCounted:
	return state.get("inventory")


func _fresh() -> void:
	state.set("test_time", T0)
	state.set("unlimited_storage", false)
	state.call("reset")
	state.set("coins", 500)
	db.get("fishing")["chest"] = original_chest.duplicate(true)
	db.get("fishing").physics["bar_base"] = original_base


## Mercado liberado (capítulo 5 e Pesca nível 3), sem dar a vara.
func _market_open() -> void:
	state.call("dev_jump_to_chapter", 4)
	_f().xp = 100


func _row(id: String) -> Dictionary:
	for row: Dictionary in state.call("growth_info").requirements:
		if str(row.id) == id:
			return row
	return {}


func _frames(n: int = 3) -> void:
	for i in n:
		await process_frame


func _find(node: Node, node_name: String) -> Node:
	return node.find_child(node_name, true, false)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/friend_clock.gd"))
	Motion.reduced = true
	original_chest = db.get("fishing").chest.duplicate(true)
	original_base = float(db.get("fishing").physics.bar_base)
	_shop()
	_baits_and_rods()
	_chest()
	_stew_and_growth()
	_story()
	await _screen()
	print("FISHING ROD2 TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# 1/2. Pacote da vara: invisível antes, visível depois, cobra 180 + 4 fibras e entrega a vara uma vez.
func _shop() -> void:
	_fresh()
	var pack: Dictionary = db.get("progression").shop_items.reel_rod_pack
	check(pack.rods == ["reel_rod"] and int(pack.price) == 180 and int(pack.materials.fiber) == 4 and int(pack.max) == 1, "1: dados do pacote")
	check(str(pack.shop) == "market" and int(pack.requirements.chapter) == 5 and int(pack.requirements.fishing_level) == 3, "1: Feirante, capítulo 5 e pesca 3")
	check(state.call("shop_item_locked", "reel_rod_pack") != "", "1: bloqueado no começo")
	state.call("dev_jump_to_chapter", 4)
	check(state.call("shop_item_locked", "reel_rod_pack") != "", "1: sem pesca nível 3 ainda bloqueado")
	check(state.call("shop_item_locked", "reel_rod_pack") == "Pesca nível 3", "1: motivo 'Pesca nível 3': " + str(state.call("shop_item_locked", "reel_rod_pack")))
	_f().xp = 100
	check(state.call("shop_item_locked", "reel_rod_pack") == "", "1: capítulo 5 + nível 3 libera")
	_fresh()
	_f().xp = 100
	check(state.call("shop_item_locked", "reel_rod_pack") != "", "1: nível 3 sem o capítulo continua bloqueado")
	_market_open()
	state.call("give_rod", "bamboo_rod")
	check(not state.call("shop_items", "market").is_empty() and "reel_rod_pack" in state.call("shop_items", "market"), "1: o Feirante lista o pacote")
	state.set("coins", 100)
	_inv().add("fiber", 4)
	check(state.call("buy_shop_item_error", "reel_rod_pack").begins_with("Faltam"), "1: sem moedas: " + str(state.call("buy_shop_item_error", "reel_rod_pack")))
	state.set("coins", 500)
	_inv().remove("fiber", 4)
	check(state.call("buy_shop_item_error", "reel_rod_pack").begins_with("Falta"), "1: sem fibras: " + str(state.call("buy_shop_item_error", "reel_rod_pack")))
	check(state.get("coins") == 500 and not _f().has_rod("reel_rod"), "1: erro não cobra nem entrega")
	_inv().add("fiber", 5)
	check(int(state.call("shop_max_qty", "reel_rod_pack")) == 1, "1: dá para comprar 1")
	check(state.call("buy_shop_item", "reel_rod_pack") == "", "1: compra")
	check(state.get("coins") == 320 and _inv().count("fiber") == 1, "1: cobra 180 + 4 fibras")
	check(_f().has_rod("reel_rod") and _p().stat("rod:reel_rod") == 1 and _p().stat("buy:reel_rod_pack") == 1, "1: dá a vara e conta")
	check(state.call("buy_shop_item_error", "reel_rod_pack") == "Você já tem", "2: comprar de novo: Você já tem")
	check(int(state.call("shop_max_qty", "reel_rod_pack")) == 0, "2: máximo 0 depois de ter a vara")
	check(state.call("buy_shop_item", "reel_rod_pack") != "" and state.get("coins") == 320, "2: segunda compra não cobra")
	check(db.call("shop_problems").is_empty(), "1: shop_problems vazio: " + str(db.call("shop_problems")))


# 3/4. A isca escolhe o grupo; a vara 2 tem barra maior e dreno menor.
func _baits_and_rods() -> void:
	_fresh()
	state.call("dev_give_rod", "bamboo_rod")
	state.call("dev_give_rod", "reel_rod")
	var dough := {}
	var worm := {}
	for n in 300:
		var c := {"seed": 1000 + n * 17, "zone": 1 + n % 3, "bait": "bait_dough"}
		dough[str(state.call("_pick_fish", c))] = true
		c["bait"] = "bait_worm"
		worm[str(state.call("_pick_fish", c))] = true
	var dough_ids := dough.keys()
	dough_ids.sort()
	check(dough_ids == ["fish_carp", "fish_pacu", "fish_tambaqui"], "3: massa sorteia só carpa/pacu/tambaqui: " + str(dough_ids))
	var worm_ids := worm.keys()
	worm_ids.sort()
	check(worm_ids == ["fish_cara", "fish_lambari", "fish_tilapia"], "3: minhoca com a vara 2 continua nos peixes da vara 1: " + str(worm_ids))
	check(state.call("cast_error", "bait_dough", 1) == "Sem massa de milho", "3: lançar sem massa: " + str(state.call("cast_error", "bait_dough", 1)))
	state.call("choose_rod", "bamboo_rod")
	_inv().add("bait_dough", 2)
	check(state.call("cast_error", "bait_dough", 1) != "", "3: a vara de bambu não aceita massa")
	state.call("choose_rod", "reel_rod")
	check(state.call("cast_error", "bait_dough", 1) == "", "3: o molinete aceita massa")
	# Barra maior e dreno menor (usa a base original do catálogo: a atual do Vitor já passa do teto).
	db.get("fishing").physics["bar_base"] = 0.169
	state.call("choose_rod", "bamboo_rod")
	var bamboo_bar: float = state.call("fishing_bar_height")
	state.call("choose_rod", "reel_rod")
	var reel_bar: float = state.call("fishing_bar_height")
	check(reel_bar > bamboo_bar and absf(reel_bar - bamboo_bar - 0.025) < 0.0001, "4: barra do molinete +0,025 (%f → %f)" % [bamboo_bar, reel_bar])
	var rods: Dictionary = db.get("fishing").rods
	check(float(rods.reel_rod.hold) == 0.15 and float(rods.bamboo_rod.hold) == 0.0, "4: hold 0,15 contra 0")
	var drained := {}
	for id: String in ["bamboo_rod", "reel_rod"]:
		var sim := FishingSim.new(db.get("fishing"), {"still": true, "difficulty": 30}, 5, 0.17, rods[id])
		sim.fish_y = 0.9
		var before := sim.meter
		for i in 60:
			sim.bar_y = 0.0
			sim.bar_v = 0.0
			sim.step(false, sim._tick)
		drained[id] = before - sim.meter
	check(drained.reel_rod < drained.bamboo_rod and absf(drained.reel_rod / drained.bamboo_rod - 0.85) < 0.03, "4: o dreno do molinete é 85%% do do bambu (%s)" % str(drained))


## Joga o minigame com um piloto: segue o peixe, e na janela `cover_chest` cobre o baú. Devolve o sim.
func _play(seed_value: int, chest: bool, cover_chest: bool) -> FishingSim:
	var config: Dictionary = db.get("fishing")
	var rod: Dictionary = config.rods.reel_rod
	var sim := FishingSim.new(config, {"still": true, "difficulty": 20}, seed_value, 0.30, rod)
	sim.chest_enabled = chest
	var guard := 0
	while not sim.finished and guard < 6000:
		guard += 1
		var target := sim.fish_y
		if cover_chest and sim.chest_shown and not sim.chest_open and sim.meter > 0.5:
			target = sim.chest_y
		sim.bar_y = clampf(target - sim.bar_h / 2.0, 0.0, 1.0 - sim.bar_h)
		sim.bar_v = 0.0
		sim.step(false, sim._tick)
	return sim


# 5/6. Baú: decidido na fisgada, aparece no minigame, entrega uma vez e só com o peixe pego.
func _chest() -> void:
	var config: Dictionary = db.get("fishing")
	# Motor puro.
	var sim := _play(11, true, true)
	check(sim.chest_shown and sim.chest_open and sim.caught, "5: cobrindo o baú ele abre e o peixe é pego")
	check(absf(sim.chest_y - 0.5) >= 0.3 - 0.0001 and sim.chest_y >= 0.02 and sim.chest_y <= 0.98, "5: baú a ≥ 0,3 do peixe (y %f)" % sim.chest_y)
	var ignored := _play(11, true, false)
	check(ignored.chest_shown and not ignored.chest_open and ignored.chest_meter == 0.0, "5: sem cobrir o baú ele não enche")
	var off := _play(11, false, true)
	check(not off.chest_shown and not off.chest_open, "5: sem baú na partida, nada aparece")
	var late := FishingSim.new(config, {"still": true, "difficulty": 20}, 3, 0.30, config.rods.reel_rod)
	late.chest_enabled = true
	for i in 60:
		late.bar_y = 0.4
		late.step(false, late._tick)
	check(not late.chest_shown, "5: o baú só aparece depois de appear_after")
	# Enche a `fill` por segundo e nunca esvazia.
	var fill := FishingSim.new(config, {"still": true, "difficulty": 20}, 3, 0.30, config.rods.reel_rod)
	fill.chest_enabled = true
	var peak := 0.0
	for i in 600:
		var covering := fill.chest_shown and i % 120 < 60
		fill.bar_y = clampf((fill.chest_y if covering else 0.5) - fill.bar_h / 2.0, 0.0, 1.0 - fill.bar_h)
		fill.bar_v = 0.0
		fill.step(false, fill._tick)
		check(fill.chest_meter >= peak - 1e-9, "5: o baú nunca esvazia")
		peak = fill.chest_meter
		if fill.finished:
			break
	check(peak > 0.0, "5: enche enquanto cobre")

	# Decisão na fisgada: chance 1,0 para os casos determinísticos.
	config["chest"]["chance"] = 1.0
	_fresh()
	config["chest"]["chance"] = 1.0
	state.call("dev_give_rod", "reel_rod")
	_inv().add("bait_dough", 6)
	state.call("cast", "bait_dough", 1)
	_advance(float(_f().cast.wait) + 0.1)
	check(state.call("hook") == "", "5: fisgou com a massa")
	check(not bool(_f().cast.chest), "5: nunca baú na primeira partida da espécie")
	state.call("cancel_fishing")
	var species: String = str(_f().cast.get("fish", "")) if not _f().cast.is_empty() else ""
	# Registra todas as espécies da massa para sair do 'primeira vez'.
	for id: String in ["fish_carp", "fish_pacu", "fish_tambaqui"]:
		_f().records[id] = {"best_cm": 10.0, "best_class": "small", "count": 1, "gigantes": 0, "perfects": 0, "first_at": 1.0}
	_inv().add("bait_dough", 6)
	check(state.call("cast", "bait_dough", 1) == "", "5: lançou")
	_advance(float(_f().cast.wait) + 0.1)
	check(state.call("hook") == "" and bool(_f().cast.chest), "5: com a espécie já pega e chance 1, vem baú")
	var n: int = int(_f().cast.n)
	var coins_before: int = state.get("coins")
	var items_before: int = _inv().count("bolt") + _inv().count("carrot") + _inv().count("bait_lure")
	var escape := {"caught": false, "score": 0.2, "perfect": false, "chest": false}
	var snap_cast: Dictionary = _f().cast.duplicate(true)
	check(state.call("finish_fishing", escape) == "", "5: peixe escapa")
	check(not state.get("economy").granted.has("fish_chest:%d" % n) and state.get("coins") == coins_before, "5: escapou = baú perdido")
	# Pegou o peixe mas sem encher o baú: nada.
	_f().cast = snap_cast.duplicate(true)
	_f().cast["state"] = "fighting"
	check(state.call("finish_fishing", {"caught": true, "score": 0.6, "perfect": false, "chest": false}) == "", "5: pegou sem encher o baú")
	check(not state.get("economy").granted.has("fish_chest:%d" % n), "5: baú vazio não paga")
	for id: String in config.fish:
		_inv().remove(id, _inv().count(id))
	# Pegou o peixe e encheu o baú: prêmio uma vez.
	_f().cast = snap_cast.duplicate(true)
	_f().cast["state"] = "fighting"
	var full := {"caught": true, "score": 0.9, "perfect": false, "chest": true}
	check(state.call("finish_fishing", full) == "", "5: entrega")
	check(state.get("economy").granted.has("fish_chest:%d" % n), "5: baú pago uma vez")
	var gained_coins: int = state.get("coins") - coins_before
	var gained_items: int = _inv().count("bolt") + _inv().count("carrot") + _inv().count("bait_lure") - items_before
	check(gained_coins > 0 or gained_items > 0, "5: o prêmio chegou (%d moedas, %d itens)" % [gained_coins, gained_items])
	check(not state.get("last_fish_chest").is_empty() and _p().stat("fish_chest") == 1, "5: last_fish_chest e contador")
	_f().cast = snap_cast.duplicate(true)
	_f().cast["state"] = "fighting"
	var coins_after: int = state.get("coins")
	state.call("finish_fishing", full)
	check(state.get("coins") == coins_after, "5: o mesmo baú não paga duas vezes")
	for id: String in config.fish:
		_inv().remove(id, _inv().count(id))
	# Resultado com chest: true sem baú na partida não paga.
	_fresh()
	config["chest"]["chance"] = 0.0
	state.call("dev_give_rod", "reel_rod")
	_f().records["fish_carp"] = {"best_cm": 10.0, "best_class": "small", "count": 1, "gigantes": 0, "perfects": 0, "first_at": 1.0}
	_inv().add("bait_dough", 6)
	state.call("cast", "bait_dough", 1)
	_advance(float(_f().cast.wait) + 0.1)
	state.call("hook")
	check(not bool(_f().cast.chest), "5: chance 0 = sem baú")
	var n_free: int = int(_f().cast.n)
	state.call("finish_fishing", full)
	check(not state.get("economy").granted.has("fish_chest:%d" % n_free), "5: cliente que manda chest sem baú não ganha nada")
	# Vara 1 e tutorial: nunca baú.
	_fresh()
	config["chest"]["chance"] = 1.0
	state.call("give_rod", "bamboo_rod")  # tutorial ainda aberto
	_f().records["fish_lambari"] = {"best_cm": 8.0, "best_class": "small", "count": 1, "gigantes": 0, "perfects": 0, "first_at": 1.0}
	check(not bool(state.call("_chest_due", {"fish": "fish_lambari", "rod": "bamboo_rod", "seed": 1})), "5: nunca no tutorial")
	_f().tutorial["done"] = true
	check(not bool(state.call("_chest_due", {"fish": "fish_lambari", "rod": "bamboo_rod", "seed": 1})), "5: vara 1 não vê baú")
	check(bool(state.call("_chest_due", {"fish": "fish_lambari", "rod": "reel_rod", "seed": 1})), "5: vara 2 com espécie conhecida vê baú")
	check(not bool(state.call("_chest_due", {"fish": "fish_carp", "rod": "reel_rod", "seed": 1})), "5: espécie nova nunca traz baú")

	# 6. Sem espaço: o item do baú vira recibo em 'Presentes para guardar'.
	_fresh()
	config["chest"]["chance"] = 1.0
	config["chest"]["loot"] = [{"weight": 1, "items": {"carrot": 3}}]
	state.call("dev_give_rod", "reel_rod")
	_f().records["fish_carp"] = {"best_cm": 10.0, "best_class": "small", "count": 1, "gigantes": 0, "perfects": 0, "first_at": 1.0}
	var depot := str(state.call("storage_of", "carrot"))
	_inv().add("carrot", int(state.call("storage_space", depot)))
	_inv().add("bait_dough", 3)
	state.call("cast", "bait_dough", 1)
	_advance(float(_f().cast.wait) + 0.1)
	state.call("hook")
	var n_full: int = int(_f().cast.n)
	_f().cast["fish"] = "fish_carp"
	_f().cast["chest"] = true
	check(state.call("finish_fishing", full) == "", "6: entregou o peixe")
	check(state.get("economy").pending.has("fish_chest:%d" % n_full), "6: o que não coube virou recibo")
	check(int(state.get("economy").pending["fish_chest:%d" % n_full].items.carrot) == 3, "6: recibo guarda as 3 cenouras")
	check(str(state.call("_receipt_label", "fish_chest:1")) != "", "6: recibo tem nome")


# 7. Ensopado de peixe e o Aventureiro.
func _stew_and_growth() -> void:
	_fresh()
	var recipes: Dictionary = db.get("recipes")
	for pair: Array in [["fish_stew_carp", "fish_carp"], ["fish_stew_pacu", "fish_pacu"], ["fish_stew_tambaqui", "fish_tambaqui"]]:
		var r: Dictionary = recipes[pair[0]]
		check(str(r.output) == "fish_stew" and int(r.qty) == 2 and int(r.seconds) == 480 and str(r.station) == "stove", "7: " + str(pair[0]) + " dados")
		check(_same(r.inputs, {pair[1]: 1, "carrot": 1, "potato": 1}), "7: " + str(pair[0]) + " ingredientes")
		check(str(r.requirements.rod) == "reel_rod", "7: " + str(pair[0]) + " pede o molinete")
	var dough: Dictionary = recipes.bait_dough
	check(_same(dough.inputs, {"corn": 2}) and int(dough.qty) == 4 and int(dough.seconds) == 300 and str(dough.requirements.rod) == "reel_rod", "7: massa de milho 2 → 4 em 5 min")
	var stew: Dictionary = db.get("items").fish_stew
	check(str(stew.category) == "food" and str(stew.storage) == "fridge" and int(stew.sell_price) == 35, "7: item fish_stew")
	check(int(stew.feed.hunger) == 45 and int(stew.feed.energy) == 15 and stew.growth.phases == ["explorer", "young"], "7: feed e fases")
	# Cozinhar de verdade com cada peixe.
	state.call("dev_grant_upgrade", "stove")
	state.call("dev_give_rod", "reel_rod")
	for pair: Array in [["fish_stew_carp", "fish_carp"], ["fish_stew_pacu", "fish_pacu"], ["fish_stew_tambaqui", "fish_tambaqui"]]:
		_inv().add(pair[1], 1)
		_inv().add("carrot", 1)
		_inv().add("potato", 1)
		var before: int = _inv().count("fish_stew")
		check(state.call("cook", pair[0]) == "", "7: cozinhar " + str(pair[0]) + ": " + str(state.call("cook_error", pair[0])))
		state.call("dev_finish_timers")
		state.call("collect", "stove")
		check(_inv().count("fish_stew") == before + 2, "7: " + str(pair[0]) + " entrega 2 ensopados")
	check(_p().stat("produce:fish_stew") >= 3, "7: conta produce:fish_stew")
	# Aventureiro: dois ensopados, Corpo intacto.
	_fresh()
	state.growth.phase = "teething"
	var row := _row("fish_meal")
	check(not row.is_empty() and int(row.need) == 2 and str(row.item) == "fish_stew", "7: o Aventureiro pede 2 ensopados")
	var meals := _row("meals")
	check(not meals.is_empty() and int(meals.need) == 3, "7: a ração de crescimento continua pedindo 3")
	check(not row.has("body_level") or int(row.get("body_level", 0)) == 0, "7: o ensopado não leva Corpo")
	state.call("dev_complete_growth_reqs")
	state.growth.done["explorer"]["fish_meal"] = false
	check(str(state.call("grow_error")).contains("Ensopado"), "7: falta o ensopado: " + str(state.call("grow_error")))
	var body_before: int = state.growth.body_level
	for i in 2:
		_inv().add("fish_stew", 1)
		state.dog.needs["hunger"] = 10.0
		check(state.call("feed", "fish_stew"), "7: dar o ensopado %d" % i)
	check(bool(_row("fish_meal").done), "7: 2 ensopados cumprem o passo")
	check(state.growth.body_level == body_before, "7: o Corpo não mudou")
	check(_p().stat("feed:fish_stew") == 2, "7: conta feed:fish_stew")


# 8. Missões e encomenda.
func _story() -> void:
	var q: Dictionary = db.get("quests")
	var vara: Dictionary = q.merchant_fishing
	check(str(vara.line) == "angling" and str(vara.npc) == "merchant" and str(vara.goals[0].key) == "rod:reel_rod", "8: merchant_fishing compra a vara")
	check(int(vara.requirements.chapter) == 5 and str(vara.requirements.rod) == "bamboo_rod", "8: merchant_fishing pede capítulo 5 e a vara de bambu")
	check(int(vara.rewards.coins) == 20 and int(vara.rewards.items.bait_dough) == 4, "8: prêmio 20 moedas + 4 massas")
	check(str(vara.go.action) == "shop:reel_rod_pack", "8: Ir abre o pacote")
	check(str(q.merchant_regular.get("line")) == "merchant", "8: a linha do Feirante continua livre (sem travar o comércio)")
	var carp: Dictionary = q.bloblo_carp
	check(str(carp.npc) == "bloblo" and str(carp.goals[0].key) == "fish:fish_carp" and int(carp.rewards.coins) == 25, "8: bloblo_carp")
	check(carp.requirements.quests.has("merchant_fishing"), "8: a carpa vem depois da vara")
	var stew: Dictionary = q.lais_fish_stew
	check(str(stew.kind) == "main" and int(stew.chapter) == 6, "8: lais_fish_stew é do capítulo 6")
	check(int(stew.order) > int(q.main_5_bricks.order) and int(stew.order) < int(q.explorer_6_eggs.order), "8: ordem antes de explorer_6_eggs")
	check(str(stew.goals[0].key) == "produce:fish_stew" and str(stew.goals[1].key) == "feed:fish_stew", "8: objetivos com os contadores reais")
	check(bool(stew.goals[0].fresh) and bool(stew.goals[1].fresh) and int(stew.rewards.coins) == 30, "8: fresh e 30 moedas")
	var orders: Dictionary = db.get("progression").orders
	var lunch: Dictionary = orders.lais_fish_lunch
	check(_same(lunch.inputs, {"fish_pacu": 2, "fish_stew": 1}) and int(lunch.rewards.coins) == 90 and str(lunch.customer) == "lais", "8: encomenda Peixe para o almoço")
	_fresh()
	state.call("dev_grant_upgrade", "stove")
	_inv().add("fish_pacu", 2)
	_inv().add("fish_stew", 1)
	check(state.call("order_error", "lais_fish_lunch") != "", "8: sem a vara, a encomenda não aparece")
	state.call("dev_give_rod", "reel_rod")
	check(state.call("order_error", "lais_fish_lunch") == "", "8: com o molinete dá para entregar: " + str(state.call("order_error", "lais_fish_lunch")))
	var coins_before: int = state.get("coins")
	check(state.call("fulfill_order", "lais_fish_lunch") == "", "8: entrega")
	check(state.get("coins") == coins_before + 90 and _p().stat("order:lais_fish_lunch") == 1, "8: 90 moedas e contador")
	check(_inv().count("fish_pacu") == 0 and _inv().count("fish_stew") == 0, "8: consome os ingredientes")
	# Contadores das missões vindos das ações reais.
	_fresh()
	_market_open()
	state.call("give_rod", "bamboo_rod")
	_inv().add("fiber", 4)
	state.call("buy_shop_item", "reel_rod_pack")
	check(_p().stat("rod:reel_rod") >= 1, "8: comprar a vara cumpre merchant_fishing")
	state.call("_count", "fish:fish_carp")
	check(_p().stat("fish:fish_carp") >= 1, "8: pegar a carpa cumpre bloblo_carp")


## Feirante: o pacote da vara aparece na aba Comprar, com ícone da vara e sem "×N".
func _screen() -> void:
	_fresh()
	_market_open()
	state.call("give_rod", "bamboo_rod")
	var sell_ui: Script = load("res://scripts/ui/sell_ui.gd")
	sell_ui.set("last_tab", "buy")
	sell_ui.set("open_pack", "reel_rod_pack")
	sell_ui.set("open_tab", "buy")
	var live: Control = sell_ui.call("build", "village")
	root.add_child(live)
	await _frames(4)
	var card := _find(live, "Buy_reel_rod_pack") as Button
	check(card != null, "9: o Feirante mostra o pacote da vara")
	if card != null:
		check(not bool(card.get_meta("locked")), "9: pacote liberado")
		check(_find(card, "Pack") == null, "9: vara não mostra ×N")
		check(_find(card, "Icon") != null and (_find(card, "Icon") as TextureRect).texture != null, "9: ícone da vara")
	var buy := _find(live, "Locked_BuyItem")
	check(buy != null, "9: sem moedas/fibras o botão é bloqueado: " + str(state.call("buy_shop_item_error", "reel_rod_pack")))
	live.queue_free()
	await _frames()
	state.set("coins", 500)
	_inv().add("fiber", 4)
	var live2: Control = sell_ui.call("build", "village")
	root.add_child(live2)
	await _frames(4)
	check(_find(live2, "BuyItem") != null, "9: com tudo em mãos o botão Comprar aparece")
	(_find(live2, "BuyItem") as Button).pressed.emit()
	await _frames(4)
	check(state.call("has_rod", "reel_rod") if state.has_method("has_rod") else _f().has_rod("reel_rod"), "9: Comprar entrega a vara")
	live2.queue_free()
	await _frames()


func _advance(seconds: float) -> void:
	state.set("test_time", float(state.get("test_time")) + seconds)


## Compara dicionários de quantidades ignorando int × float (o JSON entrega números reais).
func _same(actual: Dictionary, expected: Dictionary) -> bool:
	if actual.size() != expected.size():
		return false
	for key: Variant in expected:
		if not actual.has(key) or int(actual[key]) != int(expected[key]):
			return false
	return true
