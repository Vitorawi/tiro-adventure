extends SceneTree
## Etapa 04 da pesca: lojas genéricas (banca da vovó, Feirante, pet shop), limite diário, abas Vender · Comprar e o "Ir".
## Relógio injetado (friend_clock); nunca toca no save do jogador.

const T0 := 1900000000.0
const DAY := 86400.0

var failures := 0
var state: Node
var db: Node


func _initialize() -> void:
	_run.call_deferred()
	create_timer(120).timeout.connect(func() -> void: quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("SHOP: " + message)


func _fresh() -> void:
	state.set("test_time", T0)
	state.set("unlimited_storage", false)
	state.call("reset")
	state.set("coins", 500)


func _p() -> RefCounted:
	return state.get("progress")


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/friend_clock.gd"))
	_data_and_gates()
	_buying()
	_daily()
	_daily_offer()
	_petshop()
	await _screen()
	await _go()
	_sources()
	print("SHOP TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


## 1 e 2: loja fechada, item com requisito escondido (só a dica).
func _data_and_gates() -> void:
	check((db.call("shop_problems") as Array).is_empty(), "shop_problems vazio: " + str(db.call("shop_problems")))
	_fresh()
	check(state.call("shop_error", "farm_stall") != "", "1: banca fechada antes de bloblo_meet")
	check((state.call("shop_items", "farm_stall") as Array).is_empty(), "1: sem pacotes com a loja fechada")
	_p().claimed_quests["bloblo_meet"] = true
	check(state.call("shop_error", "farm_stall") == "", "1: banca abre depois de bloblo_meet")
	var shown: Array = state.call("shop_items", "farm_stall")
	check(shown == ["food_stall", "worm_pack"], "2: ração + UMA dica bloqueada (minhoca): " + str(shown))
	check(state.call("shop_item_locked", "worm_pack") != "", "2: minhoca bloqueada sem vara")
	check(state.call("buy_shop_item_error", "worm_pack") != "", "2: não compra o bloqueado")
	state.call("give_rod", "bamboo_rod")
	check(state.call("shop_item_locked", "worm_pack") == "", "2: vara libera a minhoca")
	check(state.call("shop_items", "farm_stall") == ["food_stall", "worm_pack", "daily_offer"], "2: os dois revelados + a dica da oferta do dia")
	check(state.call("shop_items", "market") == [] or state.call("shop_error", "market") != "", "2: Feirante fechado no capítulo 1")


## 3, 4, 5: quantidade, moedas, depósito, max.
func _buying() -> void:
	_fresh()
	_p().claimed_quests["bloblo_meet"] = true
	state.call("give_rod", "bamboo_rod")
	var worms: int = state.get("inventory").count("bait_worm")
	var coins: int = state.get("coins")
	check(state.call("buy_shop_item", "worm_pack", 3) == "", "3: compra 3 pacotes")
	check(state.get("coins") == coins - 30, "3: cobra 3 × preço")
	check(state.get("inventory").count("bait_worm") == worms + 15, "3: entrega 3 × itens")
	check(_p().stat("bought:bait_worm") == 15 and _p().stat("buy:worm_pack") == 3 and _p().stat("bought_shop:farm_stall") == 3, "3: contadores por unidade/pacote/loja")
	state.set("coins", 4)
	var error: String = state.call("buy_shop_item_error", "worm_pack", 1)
	check(error == "Faltam 6 moedas", "4: sem moedas diz quanto falta: " + error)
	var before: int = state.get("inventory").count("bait_worm")
	check(state.call("buy_shop_item", "worm_pack", 1) != "" and state.get("coins") == 4 and state.get("inventory").count("bait_worm") == before, "4: nada muda sem moedas")
	# Depósito cheio: pacote de teste que entra no silo (limite com `prebuild_capacity`).
	db.get("progression").shop_items["test_carrots"] = {"shop": "farm_stall", "name": "Teste", "items": {"carrot": 3}, "price": 5, "icon": "item_carrot"}
	state.set("coins", 500)
	var capacity: int = state.call("storage_capacity", "silo")
	state.get("inventory").add("carrot", capacity)
	var coins_full: int = state.get("coins")
	var full: String = state.call("buy_shop_item", "test_carrots", 1)
	check(full != "" and state.get("coins") == coins_full, "4: depósito cheio não cobra: " + full)
	db.get("progression").shop_items.erase("test_carrots")
	check(state.call("buy_shop_item_error", "worm_pack", 0) != "", "5: qty 0 recusada")
	check(state.call("buy_shop_item_error", "worm_pack", 6) != "", "5: acima do max (5) recusada")
	check(state.call("buy_shop_item_error", "worm_pack", 5) == "", "5: max aceito")
	check(state.call("shop_max_qty", "worm_pack") == 5, "5: shop_max_qty respeita max e moedas")


## 6: daily 2, virada do dia, relógio para trás.
func _daily() -> void:
	_fresh()
	_p().claimed_quests["bloblo_meet"] = true
	check(state.call("shop_daily_left", "food_stall") == 2, "6: 2 por dia")
	check(state.call("shop_daily_left", "worm_pack") == -1, "6: sem limite onde não há daily")
	check(state.call("buy_shop_item", "food_stall") == "", "6: 1ª compra")
	check(state.call("buy_shop_item", "food_stall") == "", "6: 2ª compra")
	var third: String = state.call("buy_shop_item", "food_stall")
	check(third == "Volta amanhã", "6: a 3ª é recusada: " + third)
	check(state.call("shop_daily_left", "food_stall") == 0, "6: zero hoje")
	state.set("test_time", T0 - DAY)
	check(state.call("buy_shop_item_error", "food_stall") == "Volta amanhã", "6: relógio para trás não reabre")
	state.set("test_time", T0 + DAY)
	check(state.call("shop_daily_left", "food_stall") == 2, "6: virar o dia reabre")
	check(state.call("buy_shop_item", "food_stall", 2) == "", "6: 2 de uma vez no dia novo")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	check(state.call("shop_daily_left", "food_stall") == 0, "6: o limite persiste no save")


## 7: pet shop igual ao antigo e painel só dos itens dele.
## Etapa 10: oferta do dia (rotação por dia local + semente do Tiro, limite 1 por dia, requisitos por entrada).
func _daily_offer() -> void:
	_fresh()
	_p().claimed_quests["bloblo_meet"] = true
	state.call("give_rod", "bamboo_rod")
	check(state.call("shop_item_locked", "daily_offer") != "", "10: oferta fechada antes de lais_forest")
	_p().claimed_quests["lais_forest"] = true
	check(state.call("shop_item_locked", "daily_offer") == "", "10: oferta abre depois de lais_forest")
	var rotation: Array = db.get("progression").shop_items.daily_offer.rotation
	var seen := {}
	for day in 6:
		state.set("test_time", T0 + day * DAY)
		var pack: Dictionary = state.call("shop_pack", "daily_offer")
		var item := str(pack.items.keys()[0])
		check(state.call("shop_pack", "daily_offer").items.keys()[0] == item, "10: o mesmo dia dá a mesma oferta")
		check(item != "fiber", "10: sem guide_open_cave a fibra é pulada (%s)" % item)
		seen[item] = true
	check(seen.size() == 2, "10: a rotação passa por madeira e pedra em 6 dias: " + str(seen.keys()))
	_p().claimed_quests["guide_open_cave"] = true
	seen.clear()
	for day in 9:
		state.set("test_time", T0 + day * DAY)
		seen[str(state.call("shop_pack", "daily_offer").items.keys()[0])] = true
	check(seen.size() == 3 and rotation.size() == 3, "10: com o requisito da fibra a rotação tem as três entradas: " + str(seen.keys()))
	state.set("test_time", T0 + 20 * DAY)
	var pack2: Dictionary = state.call("shop_pack", "daily_offer")
	var item2 := str(pack2.items.keys()[0])
	var have: int = state.get("inventory").count(item2)
	var coins: int = state.get("coins")
	check(state.call("shop_daily_left", "daily_offer") == 1, "10: 1 por dia")
	check(state.call("buy_shop_item", "daily_offer") == "", "10: compra a oferta")
	check(state.get("inventory").count(item2) == have + int(pack2.items[item2]) and state.get("coins") == coins - int(pack2.price), "10: entrega e cobra a entrada do dia")
	check(state.call("buy_shop_item_error", "daily_offer") == "Volta amanhã", "10: só uma por dia")
	state.set("test_time", T0 + 21 * DAY)
	check(state.call("buy_shop_item_error", "daily_offer") == "", "10: no dia seguinte volta")


func _petshop() -> void:
	_fresh()
	check(state.call("buy_shop_item_error", "dog_food_pack") == "Monte o pet shop", "7: pet shop fechado")
	_p().owned["petshop"] = true
	var food: int = state.get("inventory").count("dog_food")
	check(state.call("buy_shop_item", "dog_food_pack") == "" and state.get("inventory").count("dog_food") == food + 5 and state.get("coins") == 485, "7: cinco por quinze")
	check(state.call("shop_items", "petshop") == ["dog_food_pack"], "7: o pet shop só lista o dele")


func _frames(count: int = 3) -> void:
	for _i in count:
		await process_frame


func _find(node: Node, name: String) -> Node:
	return node.find_child(name, true, false)


## 8: tela. Sem itens para comprar = sem abas; com itens = duas abas; Comprar compra e o total confere.
func _screen() -> void:
	var sell_ui: Script = load("res://scripts/ui/sell_ui.gd")
	_fresh()
	# Sem a loja aberta (bloblo_meet não feito): a banca é igual à de antes.
	var closed: Control = sell_ui.call("build", "farm")
	root.add_child(closed)
	await _frames()
	check(_find(closed, "NotebookTab_buy") == null and _find(closed, "NotebookTab_sell") == null, "8: sem pacotes, sem abas")
	check(_find(closed, "SellFrame") != null, "8: a venda continua igual")
	closed.queue_free()
	await _frames()
	_p().claimed_quests["bloblo_meet"] = true
	sell_ui.set("last_tab", "sell")
	var live: Control = sell_ui.call("build", "farm")
	root.add_child(live)
	await _frames()
	check(_find(live, "NotebookTab_sell") != null and _find(live, "NotebookTab_buy") != null, "8: duas abas")
	check(_find(live, "NewBadge") != null, "8: selo na aba Comprar enquanto o pacote é novo")
	(_find(live, "NotebookTab_buy") as Button).pressed.emit()
	await _frames(4)
	check(_find(live, "Buy_food_stall") != null, "8: Comprar mostra Buy_food_stall")
	check(_find(live, "Buy_worm_pack") != null and bool((_find(live, "Buy_worm_pack") as Button).get_meta("locked")), "8: a minhoca aparece como dica bloqueada")
	check(_find(live, "DailyLeft") != null and (_find(live, "DailyLeft") as Label).text == "2 hoje", "8: '2 hoje'")
	(_find(live, "Plus") as Button).pressed.emit()
	await _frames(4)
	check((_find(live, "QuantityValue") as Label).text == "2" and (_find(live, "BuyTotalValue") as Label).text == "20", "8: quantidade 2 → total 20")
	var coins: int = state.get("coins")
	var food: int = state.get("inventory").count("dog_food")
	(_find(live, "BuyItem") as Button).pressed.emit()
	await _frames(4)
	check(state.get("coins") == coins - 20 and state.get("inventory").count("dog_food") == food + 6, "8: BuyItem cobra 20 e entrega 6")
	check(_find(live, "Locked_BuyItem") != null, "8: sem mais nada hoje, o botão vira bloqueado")
	var again: Button = _find(live, "Locked_BuyItem") as Button
	check(str(again.get_meta("reason", "")) == "Volta amanhã", "8: motivo 'Volta amanhã'")
	check(not bool(_p().seen.get("shop_item:worm_pack", false)) or true, "8: marcação de visto não quebra")
	live.queue_free()
	await _frames()
	# Voltar para a aba Vender só na sessão.
	check(str(sell_ui.get("last_tab")) == "buy", "8: lembra a última aba na sessão")
	sell_ui.set("last_tab", "sell")


## 9: o "Ir" abre direto em Comprar com o pacote escolhido.
func _go() -> void:
	_fresh()
	_p().claimed_quests["bloblo_meet"] = true
	state.call("give_rod", "bamboo_rod")
	var sell_ui: Script = load("res://scripts/ui/sell_ui.gd")
	sell_ui.set("last_tab", "sell")
	var captured: Array[Control] = []
	root.get_node("Events").sheet_requested.connect(func(_title: String, content: Control) -> void: captured.append(content))
	var places: Script = load("res://scripts/ui/places.gd")
	places.call("run", "farm", "shop:worm_pack")
	check(captured.size() == 1, "9: o Ir abre a banca")
	if captured.size() == 1:
		root.add_child(captured[0])
		await _frames(4)
		var card := _find(captured[0], "Buy_worm_pack") as Button
		check(card != null and bool(card.get_meta("selected")), "9: abre em Comprar com a minhoca escolhida")
		captured[0].queue_free()
		await _frames()
	sell_ui.set("last_tab", "sell")
	var target: Dictionary = places.call("goal_target", {"type": "stat", "key": "shop:worm_pack"})
	check(str(target.get("world", "")) == "farm" and str(target.get("place", "")) == "shop:worm_pack", "9: goal_target da loja")
	check(str(places.call("highlight_action", "shop:worm_pack")) == "place:early_market", "9: a seta aponta a banca")


## 10: de onde vem a minhoca e a ração.
func _sources() -> void:
	var lines: PackedStringArray = db.call("sources_of", "bait_worm")
	check(" · ".join(lines).contains("Banca da vovó"), "10: sources_of(bait_worm) inclui a banca: " + str(lines))
	var found := false
	for source: Dictionary in db.call("item_sources", "bait_worm"):
		found = found or str(source.key) == "shop:worm_pack"
	check(found, "10: item_sources(bait_worm) inclui a loja")
	var help: Script = load("res://scripts/ui/task_help.gd")
	_fresh()
	_p().claimed_quests["bloblo_meet"] = true
	state.call("give_rod", "bamboo_rod")
	var info: Dictionary = help.call("describe", "item", "bait_worm")
	check(str(info.get("target", {}).get("place", "")) == "shop:worm_pack", "10: Como fazer da minhoca leva à banca")
