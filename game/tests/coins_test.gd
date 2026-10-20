extends SceneTree
## Etapa 09 do plano de economia: fontes de renda e transformação.
## Cobre: colheitas e rotas produtivas sem moeda (itens/XP intactos, snapshot antigo ainda paga),
## colheita rejeitada sem pagar nada, recuperação do zero (plantar grátis, colher, vender cedo),
## preços 30/140 e margens da cadeia, contratos 600/940 contra venda e insumos, prêmios pontuais,
## capítulos 1–9 e presente de nível acima de 10 dirigido por dados.
## --headless --path game -s res://tests/coins_test.gd

var failures := 0
var state: Node
var db: Node


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("COINS: " + message)


func _p() -> RefCounted:
	return state.get("progress")


func _inv(id: String) -> int:
	return int(state.get("inventory").count(id))


func _price(id: String) -> int:
	return int(db.get("items")[id].get("sell_price", 0))


func _fresh() -> void:
	state.call("reset")
	state.set("unlimited_storage", false)
	state.get("inventory").counts.clear()
	state.set("coins", 0)
	_p().owned["farm"] = true
	state.set("unlocked_plots", 4)
	state.call("_ensure_plots")


func _ready_plot(index: int, crop: String) -> void:
	check(state.call("plant", index, crop) == "", "planta %s no canteiro %d" % [crop, index])
	(state.get("plots") as Array)[index]["ready_at"] = 0.0


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	_harvest_without_coins()
	_routes_without_coins()
	_recovery_from_zero()
	_prices_and_margins()
	_contracts()
	_one_time_prizes()
	_level_gift()
	print("COINS TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# --- colheita e rotas -----------------------------------------------------------------------------

func _harvest_without_coins() -> void:
	var crops: Dictionary = db.get("crops")
	for id: String in crops:
		check(int(crops[id].get("coins", 0)) == 0, "cultura %s não paga moeda ao colher" % id)
		check(not (crops[id].get("yield", {}) as Dictionary).is_empty() and int(crops[id].get("skill_xp", 0)) > 0, "cultura %s mantém itens e XP" % id)
	_fresh()
	_ready_plot(0, "carrot")
	var xp_before: int = int(_p().skills.get("agriculture", 0))
	var received: Dictionary = state.call("harvest", 0)
	check(int(received.get("carrot", 0)) == 2 and _inv("carrot") == 2, "colheita entrega o produto")
	check(int(state.get("coins")) == 0, "colher não paga moeda")
	check(_p().skills.get("agriculture", 0) > xp_before, "colher ainda dá XP de agricultura")
	# Snapshot de um plantio antigo (job com moedas) continua pagando o que valia ao plantar.
	_ready_plot(1, "carrot")
	(state.get("plots") as Array)[1]["job"]["coins"] = 3
	state.call("harvest", 1)
	check(int(state.get("coins")) == 3, "plantio antigo paga o snapshot (3)")
	# Depósito cheio: nenhuma recompensa parcial.
	_fresh()
	state.get("inventory").add("carrot", 15)
	_ready_plot(0, "carrot")
	(state.get("plots") as Array)[0]["job"]["coins"] = 3
	var skill := int(_p().skills.get("agriculture", 0))
	var harvests := int(_p().stat("harvest"))
	check((state.call("harvest", 0) as Dictionary).is_empty(), "lote que não cabe é recusado")
	check(int(state.get("coins")) == 0 and _inv("carrot") == 15 and int(_p().skills.get("agriculture", 0)) == skill and int(_p().stat("harvest")) == harvests, "recusa não paga moeda, item, XP nem contador")
	check(state.call("plot_status", 0) == "ready", "planta continua pronta")


func _routes_without_coins() -> void:
	var activities: Dictionary = db.get("progression").activities
	for id: String in activities:
		var rewards: Dictionary = activities[id].rewards
		check(int(rewards.get("coins", 0)) == 0, "rota %s não paga moeda" % id)
		check(not (rewards.get("items", {}) as Dictionary).is_empty(), "rota %s mantém itens" % id)
	_fresh()
	var job: Dictionary = preload("res://scripts/state/work_jobs.gd").route("trail", activities)
	_p().activity = {"id": "trail", "started_at": 0.0, "ready_at": 0.0, "rewards": job.rewards, "player_xp": job.player_xp}
	check(state.call("collect_activity") == "", "recolhe a rota")
	check(int(state.get("coins")) == 0 and _inv("wood") == 4 and _inv("stone") == 3, "rota entrega materiais (tabela da etapa 11: 4 madeiras, 3 pedras) e nenhuma moeda")
	# Rota iniciada antes (snapshot com moeda) ainda paga.
	_p().activity = {"id": "trail", "started_at": 0.0, "ready_at": 0.0, "rewards": {"coins": 15, "items": {"wood": 1}}, "player_xp": 5}
	state.call("collect_activity")
	check(int(state.get("coins")) == 15, "snapshot de rota antiga continua valendo")


# --- recuperar do zero ------------------------------------------------------------------------

func _recovery_from_zero() -> void:
	_fresh()
	check(int(state.get("coins")) == 0 and state.get("inventory").counts.is_empty(), "começa sem moeda e sem estoque")
	check(state.call("plant_error", 0, "carrot") == "", "plantar é gratuito sem moeda")
	_ready_plot(0, "carrot")
	state.call("harvest", 0)
	check(_inv("carrot") == 2, "colhe com carteira vazia")
	var place: Dictionary = db.get("worlds").farm.places.early_market
	check(place.requirements.quests == ["bloblo_meet"] and place.panel == "sell", "venda inicial abre com bloblo_meet")
	check(state.call("sell", "carrot", 2) == "", "vende a colheita")
	check(int(state.get("coins")) == 2 * _price("carrot") and int(state.get("coins")) > 0, "o saldo vem da venda (%d)" % int(state.get("coins")))
	# Zero moeda e zero estoque: ainda dá para recomeçar e vender a segunda safra.
	_ready_plot(0, "carrot")
	state.call("harvest", 0)
	check(state.call("sell", "carrot", 2) == "" and int(state.get("coins")) == 4 * _price("carrot"), "segunda safra vende de novo")
	# O texto que guia a primeira renda fala em vender, não em moeda da planta.
	for id: String in ["merchant_meet", "bloblo_sell_surplus"]:
		var quests: Dictionary = db.get("quests")
		if quests.has(id):
			check(not str(quests[id].get("dialogue", "")).contains("cada colheita rende"), "%s não promete moeda direta" % id)


# --- preços e margens -------------------------------------------------------------------------

func _chain_cost(recipe_id: String) -> int:
	var total := 0
	var inputs: Dictionary = db.get("recipes")[recipe_id].inputs
	for item: String in inputs:
		total += _price(item) * int(inputs[item])
	return total


func _prices_and_margins() -> void:
	check(_price("apple_biscuit") == 30, "biscoito vale 30 por unidade")
	check(_price("treat_box") == 140, "caixa de petiscos vale 140")
	var biscuit: Dictionary = db.get("recipes").apple_biscuit
	check(int(biscuit.qty) == 2, "o lote do biscoito rende 2")
	var biscuit_in := _chain_cost("apple_biscuit")
	var biscuit_out := _price("apple_biscuit") * int(biscuit.qty)
	check(biscuit_in == 26 and biscuit_out == 60, "biscoito: usa %d e entrega %d" % [biscuit_in, biscuit_out])
	# A caixa consome 2 biscoitos (30 cada) + purê + ervas: o valor dos insumos é o preço de venda deles.
	var box_in := _chain_cost("treat_box")
	check(box_in == 101, "caixa usa 101 (%d)" % box_in)
	check(_price("treat_box") > box_in, "a caixa entrega mais do que os insumos valem (140 > 101)")
	check(_price("apple_biscuit") * 2 > _chain_cost("apple_biscuit"), "o lote do biscoito não destrói valor (60 > 26)")


func _contracts() -> void:
	var orders: Dictionary = db.get("progression").orders
	var special: Dictionary = orders.special_order
	var sell_value: int = int(special.inputs.treat_box) * _price("treat_box")
	check(int(special.inputs.treat_box) == 3 and int(special.rewards.coins) == 600, "special_order: 3 caixas por 600")
	check(sell_value == 420 and int(special.rewards.coins) > sell_value, "contrato (600) vence a venda direta (%d)" % sell_value)
	var festival: Dictionary = orders.festival_contract
	var inputs_value := 0
	for item: String in festival.inputs:
		inputs_value += _price(item) * int(festival.inputs[item])
	check(int(festival.rewards.coins) == 940, "festival_contract paga 940")
	check(int(festival.rewards.coins) > inputs_value, "festival (940) paga mais do que os insumos vendidos (%d)" % inputs_value)
	check(int(festival.rewards.items.bolt) == 1 and int(festival.rewards.items.iron_band) == 1, "peças do festival preservadas como bônus")
	check(int(orders.special_order.rewards.skill_xp.commerce) == 60 and int(festival.rewards.skill_xp.commerce) == 90, "XP dos contratos preservado")
	# Entregar no jogo: sem estoque nada acontece; com estoque, paga 600.
	_fresh()
	_p().owned["stall"] = true
	_p().claimed_quests["first_harvest"] = true
	state.get("inventory").add("treat_box", 3)
	var error: String = state.call("fulfill_order", "special_order")
	check(error == "" and int(state.get("coins")) == 600 and _inv("treat_box") == 0, "entregar 3 caixas paga 600 (%s)" % error)


# --- prêmios pontuais e níveis -----------------------------------------------------------------

func _one_time_prizes() -> void:
	var quests: Dictionary = db.get("quests")
	check(int(quests.merchant_stall.rewards.coins) == 30, "merchant_stall: 30")
	check(int(quests.atelier_open.rewards.coins) == 40, "atelier_open: 40")
	check(int(quests.bloblo_biggest.rewards.coins) == 40, "bloblo_biggest: 40")
	check((quests.own_business.rewards as Dictionary).is_empty(), "own_business (shared_with) continua sem prêmio")
	check(quests.atelier_open.rewards.collections == ["artisan_outfit"] and int(quests.atelier_open.rewards.skill_xp.adventure) == 70, "atelier_open mantém roupa e XP")
	check(int(quests.merchant_stall.rewards.skill_xp.commerce) == 60, "merchant_stall mantém XP")
	var chapters: Array = db.get("progression").chapters
	var expected: Array[int] = [10, 20, 30, 40, 60, 60, 60, 80, 80]
	for index in range(expected.size()):
		check(int(chapters[index].rewards.coins) == expected[index], "capítulo %d paga %d (%s)" % [index + 1, expected[index], str(chapters[index].rewards)])


func _level_gift() -> void:
	_fresh()
	state.call("_add_player_xp", 10000)
	check(int(state.get("level")) == 1 and int(state.get("coins")) == 0, "XP não sobe nível nem paga presente")
	check((state.get("economy").granted as Dictionary).is_empty(), "sem recibos de nível")
