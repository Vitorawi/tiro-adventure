extends SceneTree
## Evolução real da banca, venda inicial, canais, esperas e compatibilidade de saves.
var failures := 0
var state: Node
var db: Node
var market: Script
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("MARKET: " + message)
func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	market = load("res://scripts/ui/market_ui.gd")
	state.call("reset")
	state.call("dev_complete_quest", "first_harvest")
	state.set("level", 20)
	state.set("xp", 0)
	state.set("coins", 0)
	state.get("inventory").from_dict({"carrot": 4})
	check(state.call("requirement_error", db.get("worlds").village.requirements) != "", "Vila ainda fechada")
	check(state.call("requirement_error", db.get("worlds").farm.places.early_market.requirements) == "", "venda já acessível no sítio")
	var price: int = db.get("items").carrot.sell_price
	check(state.call("sell", "carrot", 2) == "" and state.get("coins") == price * 2, "venda inicial rende moedas sem Vila ou banca")
	check(state.get("coins") >= int(db.get("crops").carrot.coins), "venda da colheita financia novo plantio")
	check(state.call("claim_quest", "bloblo_sell_surplus") == "", "missão ensina primeira venda")
	check(market.call("order_ids", "contracts").is_empty(), "sem contratos antes de montar")
	check(state.call("upgrade_error", "stall_2") != "", "sem pular estágio")
	state.set("coins", 20000)
	for token: String in ["farm", "stove", "blender", "dairy", "atelier", "workbench"]:
		state.get("progress").owned[token] = true
	_supply()
	check(state.call("buy_upgrade", "stall") == "", "monta banca pela compra real")
	check(market.call("stall_level") == 1 and market.call("order_ids", "contracts").size() == 3, "nível 1 tem três contratos próprios (inclui o banquete)")
	check(not "building_order" in market.call("order_ids", "neighbors"), "quadro dos vizinhos não mistura contratos")
	for id: String in db.get("progression").orders:
		var order: Dictionary = db.get("progression").orders[id]
		var retail := 0
		for item: String in order.inputs:
			retail += int(order.inputs[item]) * int(db.get("items")[item].get("sell_price", 0))
		check(int(order.rewards.get("coins", 0)) > retail, "encomenda paga mais que venda avulsa: " + id)
	var before: int = state.get("coins")
	check(state.call("fulfill_order", "vegetables") == "", "encomenda simples funciona")
	check(state.get("progress").stat("contracts") == 0, "encomenda não aumenta contratos")
	check(state.call("fulfill_order", "building_order") == "", "primeiro contrato")
	check(state.get("inventory").count("bolt") == 1, "contrato rende material de ampliação")
	var after: int = state.get("coins")
	check(state.call("fulfill_order", "building_order") != "" and state.get("coins") == after, "espera impede duplicação")
	check(state.call("fulfill_order", "special_order") == "", "segundo contrato")
	check(state.get("progress").stat("contracts") == 2, "duas entregas contam")
	check(state.call("upgrade_error", "stall_2") != "", "duas entregas não bastam para a banca 2")
	for _i in 3:
		_deliver("building_order")
	check(state.get("progress").stat("contracts") == 5 and state.call("upgrade_error", "stall_2") != "", "5 contratos ainda não ampliam")
	_deliver("building_order")
	check(state.get("progress").stat("contracts") == 6 and state.get("progress").distinct_orders("contracts") == 2, "6 contratos de 2 tipos")
	_supply()
	check(state.call("buy_upgrade", "stall_2") == "" and market.call("stall_level") == 2, "amplia com 6 contratos de 2 tipos")
	check("fabric_order" in market.call("order_ids", "contracts") and "banquet_contract" in market.call("order_ids", "contracts"), "nível 2 abre novos contratos")
	check(state.call("fulfill_order", "fabric_order") == "" and state.call("fulfill_order", "banquet_contract") == "", "entrega contratos do nível 2")
	while state.get("progress").stat("contracts") < 12:
		_deliver("building_order")
	check(state.get("progress").distinct_orders("contracts") >= 3, "12 contratos com 4 tipos")
	_supply()
	check(state.call("buy_upgrade", "stall_3") == "" and market.call("stall_level") == 3, "nível 3 pela compra real")
	check(state.call("fulfill_order", "festival_contract") == "", "contrato final funciona")
	var saved: Dictionary = state.call("to_dict").duplicate(true)
	saved.progression.stats.erase("contracts")
	before = state.get("coins")
	state.call("from_dict", saved)
	check(market.call("stall_level") == 3 and state.get("progress").stat("contracts") == 13 and state.get("coins") == before, "save preserva banca e recompõe contratos sem prêmio extra")
	var board: Control = market.call("orders")
	root.add_child(board)
	await process_frame
	check(board.find_child("OrderGrid", true, false).get_child_count() <= 4, "quatro encomendas por página")
	check(board.find_child("DeliverOrder", true, false) != null, "detalhe e entrega na mesma tela")
	board.queue_free()
	await _first_sale_context()
	_merchant_missions()
	_final_contract_production()
	print("MARKET TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)


func _first_sale_context() -> void:
	state.call("reset")
	state.call("dev_jump_to_chapter", 3)
	state.get("inventory").from_dict({"carrot": 12})
	check(state.call("sell", "carrot", 1, "farm") == "", "venda anterior no Sítio")
	check(state.call("sell", "carrot", 1, "village") == "", "venda anterior na Vila")
	state.call("talk_to", "merchant")
	check(state.call("claim_quest", "merchant_meet") == "", "conhece o feirante")
	var goal: Dictionary = db.get("quests").merchant_first_sale.goals[0]
	check(state.call("goal_value", goal) == 0 and state.call("quest_error", "merchant_first_sale") != "", "nem venda antiga na Vila cumpre o tutorial novo")
	state.call("from_dict", JSON.parse_string(JSON.stringify(state.call("to_dict"))))
	check(state.call("goal_value", goal) == 0, "base da missão sobrevive ao save")
	var farm_board: Control = market.call("sell", "farm")
	root.add_child(farm_board)
	await process_frame
	(farm_board.find_child("SellSelected", true, false) as Button).pressed.emit()
	check(state.call("goal_value", goal) == 0, "vender no painel do Sítio não conta para o Feirante")
	farm_board.queue_free()
	var village_board: Control = market.call("sell", "village")
	root.add_child(village_board)
	await process_frame
	(village_board.find_child("SellSelected", true, false) as Button).pressed.emit()
	check(state.call("goal_value", goal) == 1 and state.call("quest_error", "merchant_first_sale") == "", "venda nova no painel do Feirante cumpre")
	village_board.queue_free()
	check(state.call("claim_quest", "merchant_first_sale") == "", "recebe o prêmio depois da venda certa")
	var coins: int = state.get("coins")
	state.call("from_dict", JSON.parse_string(JSON.stringify(state.call("to_dict"))))
	check(state.call("claim_quest", "merchant_first_sale") != "" and state.get("coins") == coins, "recebido permanece recebido sem duplicar prêmio")
func _deliver(id: String) -> void:
	state.get("progress").cooldowns["order:" + id] = 0.0
	_supply()
	var error: String = state.call("fulfill_order", id)
	check(error == "", "entrega " + id + ": " + error)

func _supply() -> void:
	for id: String in ["plank", "brick", "carrot", "carrot_snack", "treat_box", "fabric", "vegetable_soup", "cheese", "strawberry_juice", "strawberry_pop"]:
		state.get("inventory").add(id, 20)

func _merchant_missions() -> void:
	state.call("reset")
	state.call("dev_jump_to_chapter", 3)
	state.set("coins", 20000)
	state.set("level", 20)
	for token: String in ["farm", "stove", "blender", "dairy", "atelier", "workbench"]:
		state.get("progress").owned[token] = true
	state.call("_changed")
	var expected: Array[String] = ["merchant_meet", "merchant_first_sale", "merchant_surplus", "merchant_orders", "merchant_regular", "merchant_variety", "merchant_stall", "merchant_contracts", "merchant_expand", "merchant_clients", "merchant_village_stall", "merchant_festival"]
	for id: String in expected:
		check(state.get("progress").current_line_quest("merchant") == id, "ordem da linha: " + id)
		_supply()
		match id:
			"merchant_meet": state.call("talk_to", "merchant")
			"merchant_first_sale": state.call("sell", "carrot", 1, "village")
			"merchant_surplus": state.call("sell", "carrot", 5)
			"merchant_orders": state.call("fulfill_order", "vegetables")
			"merchant_regular":
				state.call("fulfill_order", "snacks")
				state.call("fulfill_order", "soup_order")
			"merchant_variety": pass  # os pedidos de legumes e petiscos já entregues acima valem (sem entregar de novo)
			"merchant_stall": state.call("buy_upgrade", "stall")
			"merchant_contracts":
				for kind in ["building_order", "special_order", "building_order", "building_order", "building_order", "building_order"]:
					_deliver(kind)
			"merchant_expand": state.call("buy_upgrade", "stall_2")
			"merchant_clients":
				_deliver("fabric_order")
				_deliver("banquet_contract")
				while state.get("progress").stat("contracts") < 12:
					_deliver("building_order")
			"merchant_village_stall": state.call("buy_upgrade", "stall_3")
			"merchant_festival": state.call("fulfill_order", "festival_contract")
		check(state.call("claim_quest", id) == "", "missão concluída por ações reais: " + id)
	check(state.get("progress").current_line_quest("merchant") == "", "linha da banca completa")

## Final: usa receitas reais para os produtos; só matérias-primas são fornecidas como fixture.
func _final_contract_production() -> void:
	state.call("reset")
	state.call("dev_unlock_everything")
	# A caixa de petiscos exige Aventureiro desde a etapa 07.
	state.call("dev_set_phase", "explorer")
	state.set("level", 30)
	state.get("inventory").from_dict({})
	for item: String in db.get("progression").orders.festival_contract.inputs:
		_produce(item, int(db.get("progression").orders.festival_contract.inputs[item]))
	check(state.call("fulfill_order", "festival_contract") == "", "contrato final com produtos realmente fabricados")

func _produce(item: String, amount: int) -> void:
	if state.get("inventory").count(item) >= amount: return
	for recipe_id: String in db.get("recipes"):
		var recipe: Dictionary = db.get("recipes")[recipe_id]
		if str(recipe.get("output", "")) != item: continue
		while state.get("inventory").count(item) < amount:
			for ingredient: String in recipe.get("inputs", {}):
				_produce(ingredient, int(recipe.inputs[ingredient]))
			var error: String = state.call("cook", recipe_id)
			check(error == "", "produzir " + item + ": " + error)
			if error != "": return
			for entry: Dictionary in state.call("station", recipe.station).queue:
				entry.ready_at = 1.0
			state.call("collect", recipe.station)
		return
	state.get("inventory").add(item, amount - state.get("inventory").count(item))
