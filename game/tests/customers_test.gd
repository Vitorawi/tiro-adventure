extends SceneTree
## Etapa 15: clientes (confiança por entregas), banca 2/3 por contratos e tipos, banquete na banca 1.
var failures := 0
var state: Node
var db: Node
var market: Script

func _initialize() -> void: _run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("CUSTOMERS: " + message)

func _p() -> Object:
	return state.get("progress")

func _fresh() -> void:
	state.call("reset")
	state.set("unlimited_storage", true)
	state.call("dev_complete_quest", "first_harvest")
	state.set("level", 30)
	state.set("coins", 100000)
	for token: String in ["farm", "stove", "fridge", "blender", "dairy", "atelier", "workbench"]:
		_p().owned[token] = true
	for quest: String in ["bloblo_strawberry", "bloblo_potato"]:
		_p().claimed_quests[quest] = true
	state.call("_changed")

func _deliver(id: String) -> String:
	_p().cooldowns["order:" + id] = 0.0
	for item: String in db.get("progression").orders[id].inputs:
		state.get("inventory").add(item, int(db.get("progression").orders[id].inputs[item]))
	return state.call("fulfill_order", id)

func _supply() -> void:
	for id: String in ["plank", "brick", "fabric"]:
		state.get("inventory").add(id, 20)

func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	market = load("res://scripts/ui/market_ui.gd")
	_mapping()
	_tiers()
	_old_history()
	_stall_requirements()
	_banquet()
	await _ui()
	print("CUSTOMERS TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

func _mapping() -> void:
	var expected := {"lais": ["vegetables", "soup_order", "juice_order"], "bloblo": ["snacks", "puree_order", "farm_breakfast"], "nina": ["fruit_basket", "pop_order"]}
	var orders: Dictionary = db.get("progression").orders
	for customer: String in expected:
		for id: String in expected[customer]:
			check(str(orders[id].get("customer", "")) == customer, "%s é de %s" % [id, customer])
	for id: String in orders:
		if str(orders[id].get("channel", "neighbors")) == "contracts":
			check(not orders[id].has("customer"), "contrato %s não é de cliente" % id)
	check(int(orders.farm_breakfast.rewards.coins) == 95 and int(orders.farm_breakfast.cooldown) == 600, "farm_breakfast preservado (95 moedas, 600 s)")
	var tiers: Array = db.get("progression").customer_tiers
	check(tiers.size() == 3 and int(tiers[0].count) == 3 and int(tiers[1].count) == 8 and int(tiers[2].count) == 18, "patamares 3/8/18")
	check(int(tiers[0].kinds) == 1 and int(tiers[1].kinds) == 2 and int(tiers[2].kinds) == 2, "variedade 1/2/2")
	check(int(tiers[0].rewards.coins) == 10 and int(tiers[1].rewards.coins) == 20 and int(tiers[2].rewards.coins) == 30, "prêmios 10/20/30")
	check(int(tiers[1].rewards.items.bolt) == 1 and not tiers[0].rewards.has("items") and not tiers[2].rewards.has("items"), "parafuso só no segundo")

func _tiers() -> void:
	_fresh()
	var coins: int = state.get("coins")
	for _i in 2:
		check(_deliver("vegetables") == "", "entrega 1-2")
	check(_p().customer_level("lais") == 0, "2 entregas: sem patamar")
	var before: int = state.get("coins")
	check(_deliver("vegetables") == "", "3ª entrega")
	check(_p().customer_level("lais") == 1, "3 entregas de 1 tipo = patamar 1")
	check(state.get("coins") == before + 18 + 10, "paga o pedido (18) + 10 do patamar, sem multiplicador (%d)" % (int(state.get("coins")) - before))
	check(state.get("economy").granted.has("customer:lais:1"), "recibo único registrado")
	for _i in 4:
		_deliver("vegetables")
	check(_p().customer_orders("lais").count == 7 and _p().customer_level("lais") == 1, "7 entregas")
	before = state.get("coins")
	var bolts: int = state.get("inventory").count("bolt")
	_deliver("vegetables")
	check(_p().customer_orders("lais").count == 8 and _p().customer_level("lais") == 1, "8 do mesmo tipo não passam do patamar 1")
	check(state.get("coins") == before + 18 and state.get("inventory").count("bolt") == bolts, "sem prêmio sem variedade")
	before = state.get("coins")
	_deliver("soup_order")
	check(_p().customer_level("lais") == 2 and state.get("coins") == before + 75 + 20, "2º tipo libera o patamar 2 (+20)")
	check(state.get("inventory").count("bolt") == bolts + 1, "parafuso extra no patamar 2")
	for _i in 9:
		_deliver("soup_order")
	check(_p().customer_orders("lais").count == 18 and _p().customer_level("lais") == 3, "18 entregas = patamar 3")
	var spent: int = int(state.get("coins")) - coins
	check(state.get("economy").granted.has("customer:lais:3"), "patamar 3 pago")
	# Repetir entregas depois do último patamar não paga de novo.
	before = state.get("coins")
	_deliver("soup_order")
	check(state.get("coins") == before + 75, "sem pagamento repetido (%d)" % spent)
	# Outro cliente não herda a confiança.
	check(_p().customer_level("bloblo") == 0 and _p().customer_level("nina") == 0, "confiança por cliente")
	# Recarregar não repaga nem perde.
	var saved: Dictionary = state.call("to_dict").duplicate(true)
	before = state.get("coins")
	state.call("from_dict", saved)
	_deliver("soup_order")
	check(state.get("coins") == before + 75 and _p().customer_level("lais") == 3, "reload preserva patamares sem repagar")
	# Contrato e consulta não contam como cliente.
	_fresh()
	_p().owned["stall"] = true
	_deliver("building_order")
	check(_p().customer_orders("lais").count == 0 and _p().stat("orders") == 1, "contrato não conta para clientes")
	check(_p().stat("contracts") == 1, "contrato conta como contrato")
	_deliver("vegetables")
	check(_p().stat("contracts") == 1, "encomenda não conta como contrato")
	market.call("order_ids", "neighbors")
	market.call("customer_text", "lais")
	check(_p().stat("contracts") == 1 and _p().customer_orders("lais").count == 1, "consultar não incrementa")

func _old_history() -> void:
	# Histórico antigo: 20 entregas sem nenhum recibo → paga cada patamar pendente uma única vez.
	_fresh()
	_p().stats["order:fruit_basket"] = 12
	_p().stats["order:pop_order"] = 8
	check(_p().customer_level("nina") == 3, "histórico antigo já vale patamar 3")
	var before: int = state.get("coins")
	var bolts: int = state.get("inventory").count("bolt")
	_deliver("fruit_basket")
	var paid: int = int(state.get("coins")) - before - 26
	check(paid == 60, "paga 10+20+30 uma vez (%d)" % paid)
	check(state.get("inventory").count("bolt") == bolts + 1, "um parafuso só")
	before = state.get("coins")
	_deliver("fruit_basket")
	check(state.get("coins") == before + 26, "segunda entrega não repaga")
	# Patamar já pago (granted) não volta.
	_fresh()
	state.get("economy").granted["customer:nina:1"] = true
	_p().stats["order:fruit_basket"] = 2
	before = state.get("coins")
	_deliver("fruit_basket")
	check(state.get("coins") == before + 26, "patamar já pago não paga de novo")

func _stall_requirements() -> void:
	var up: Dictionary = db.get("progression").upgrades
	check(int(up.stall_2.cost) == 900 and int(up.stall_3.cost) == 1500, "custos 900/1500")
	check(int(up.stall_2.materials.plank) == 6 and int(up.stall_2.materials.brick) == 4, "materiais da banca 2")
	check(int(up.stall_3.materials.plank) == 8 and int(up.stall_3.materials.brick) == 6 and int(up.stall_3.materials.fabric) == 2, "materiais da banca 3")
	_fresh()
	_supply()
	check(state.call("buy_upgrade", "stall") == "", "banca 1")
	# 5 contratos de 2 tipos e 6 contratos de 1 tipo falham; 6 de 2 tipos passa.
	_deliver("building_order")
	for _i in 4:
		_deliver("building_order")
	_deliver("special_order")
	check(_p().stat("contracts") == 6 and _p().distinct_orders("contracts") == 2, "6 contratos / 2 tipos")
	# repetição não soma diversidade
	_fresh()
	_supply()
	state.call("buy_upgrade", "stall")
	for _i in 6:
		_deliver("building_order")
	check(_p().stat("contracts") == 6 and _p().distinct_orders("contracts") == 1, "6 do mesmo tipo = 1 tipo")
	_supply()
	check(state.call("upgrade_error", "stall_2") != "", "banca 2 com 6 contratos de 1 tipo falha")
	_deliver("special_order")
	_supply()
	check(state.call("buy_upgrade", "stall_2") == "", "banca 2 com 7 contratos / 2 tipos")
	# 5 contratos e 2 tipos não bastam
	_fresh()
	_supply()
	state.call("buy_upgrade", "stall")
	for id: String in ["building_order", "special_order", "building_order", "building_order", "building_order"]:
		_deliver(id)
	_supply()
	check(_p().stat("contracts") == 5 and state.call("upgrade_error", "stall_2") != "", "5 contratos / 2 tipos falha")
	_deliver("building_order")
	check(state.call("buy_upgrade", "stall_2") == "", "6 contratos / 2 tipos compra")
	# Banca 3: 11/2 tipos falha, 12/2 tipos falha, 12/3 tipos passa.
	for _i in 4:
		_deliver("building_order")
	_deliver("special_order")
	_supply()
	check(_p().stat("contracts") == 11 and _p().distinct_orders("contracts") == 2, "11 contratos / 2 tipos")
	check(state.call("upgrade_error", "stall_3") != "", "banca 3 falha com 11/2")
	_deliver("building_order")
	check(_p().stat("contracts") == 12 and state.call("upgrade_error", "stall_3") != "", "banca 3 falha com 12/2 tipos")
	_deliver("banquet_contract")
	_supply()
	check(_p().distinct_orders("contracts") == 3 and state.call("buy_upgrade", "stall_3") == "", "banca 3 com 12+ e 3 tipos")
	# Posse antiga: quem já tem a banca mantém, mesmo com contadores baixos.
	_fresh()
	_p().owned["stall"] = true
	_p().owned["stall_2"] = true
	_p().owned["stall_3"] = true
	state.call("_changed")
	check(market.call("stall_level") == 3 and state.call("has_upgrade", "stall_3"), "posse antiga preservada")
	# Fabric_order continua exigindo a banca 2 e o ateliê.
	check(db.get("progression").orders.fabric_order.requirements.owned.has("stall_2"), "fabric_order fica na banca 2")
	# Contratos mostram o cabeçalho com tipos.
	check(str(db.get("progression").settings.stat_labels.get("contracts", "")) != "", "rótulo de contratos")

func _banquet() -> void:
	var req: Dictionary = db.get("progression").orders.banquet_contract.requirements
	check(req.owned.has("stall") and not req.owned.has("stall_2") and req.owned.has("dairy") and req.owned.has("blender"), "banquete: banca 1 + laticínio + liquidificador")
	var order: Dictionary = db.get("progression").orders.banquet_contract
	check(int(order.rewards.coins) == 300 and int(order.cooldown) == 1200 and int(order.rewards.items.iron_band) == 1, "banquete preserva pagamento, recarga e aro")
	check(int(order.inputs.vegetable_soup) == 3 and int(order.inputs.cheese) == 2 and int(order.inputs.strawberry_juice) == 3, "banquete preserva ingredientes")
	_fresh()
	_p().owned["stall"] = true
	var kinds := 0
	for id: String in ["building_order", "special_order", "banquet_contract"]:
		check(state.call("requirement_error", db.get("progression").orders[id].requirements) == "", id + " acessível com a banca 1")
		if _deliver(id) == "":
			kinds += 1
	check(kinds == 3 and _p().distinct_orders("contracts") == 3, "três tipos antes da banca 2 (sem estufa, pomar ou caixas)")
	check(state.call("requirement_error", db.get("progression").orders.festival_contract.requirements) != "", "festival segue exigindo a banca 3")
	check(state.call("requirement_error", db.get("progression").orders.fabric_order.requirements) != "", "tecidos seguem na banca 2")
	var ids: Array = db.get("quests").merchant_contracts.goals
	check(int(ids[0].target) == 6 and int(db.get("quests").merchant_clients.goals[0].target) == 12, "missões do Feirante: 6 e 12")

func _ui() -> void:
	_fresh()
	var text: String = market.call("customer_text", "lais")
	check("Laís" in text and "0/3" in text, "cliente sem patamar: " + text)
	_p().stats["order:vegetables"] = 10
	_p().stats["order:soup_order"] = 8
	text = market.call("customer_text", "lais")
	check(_p().customer_level("lais") == 3 and "18" in text, "último patamar: " + text)
	var board: Control = market.call("orders")
	root.add_child(board)
	await process_frame
	check(board.find_child("CustomerSummary", true, false) != null and board.find_child("Customer_lais", true, false) != null, "resumo de clientes no quadro")
	check(board.find_child("OrderDetail", true, false) == null or board.find_child("OrderDetail", true, false).find_child("Customer_*", true, false) != null, "cliente no detalhe")
	board.queue_free()
