extends SceneTree
## Etapa 17: brinquedo, cesta e petisco de mirtilo, receita de gravetos, encomendas, linha workshop e desejo do mirtilo.

var failures: int = 0
var state: Node
var database: Node


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Produtos: " + message)


func _initialize() -> void:
	_run.call_deferred()


func _progress() -> RefCounted:
	return state.get("progress")


func _stat(key: String) -> int:
	return _progress().stat(key)


func _inv() -> RefCounted:
	return state.get("inventory")


func _reload() -> void:
	state.call("from_dict", JSON.parse_string(JSON.stringify(state.call("to_dict"))))


func _fresh() -> void:
	state.call("reset")
	state.set("xp", 0)
	state.set("level", 1)


## Tudo comprado e as missões dos capítulos 1–9 feitas (ateliê aberto), sem tesouro nem estufa.
func _after_atelier() -> void:
	_fresh()
	for id: String in ["stove", "workbench", "fridge", "blender", "atelier", "chest", "silo", "warehouse"]:
		state.call("dev_grant_upgrade", id)
	state.call("dev_complete_quest", "atelier_open")
	state.set("xp", 0)
	state.set("level", 1)


func _make(recipe: String) -> Dictionary:
	var error: String = state.call("cook", recipe)
	check(error == "", "cook %s: %s" % [recipe, error])
	state.call("dev_advance_time", 4000.0)
	var station_id := str(database.recipes[recipe].station)
	return state.call("collect", station_id)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	database = root.get_node("Database")
	_data_check()
	_gating_check()
	_chain_check()
	_xp_check()
	_orders_check()
	_storage_and_reload_check()
	_workshop_check()
	_wish_check()
	print("PRODUCTS TEST: " + ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)


func _data_check() -> void:
	var r: Dictionary = database.recipes
	var items: Dictionary = database.items
	check(r.braided_toy.station == "workbench" and int(r.braided_toy.inputs.fabric) == 1 and int(r.braided_toy.inputs.stick) == 2 and int(r.braided_toy.seconds) == 720 and int(r.braided_toy.qty) == 1, "tabela do brinquedo")
	check(r.picnic_pack.station == "stove" and int(r.picnic_pack.inputs.carrot_snack) == 2 and int(r.picnic_pack.inputs.strawberry_pop) == 2 and int(r.picnic_pack.inputs.strawberry_juice) == 1 and int(r.picnic_pack.seconds) == 1080, "tabela da cesta")
	check(r.blueberry_treat.station == "stove" and int(r.blueberry_treat.inputs.blueberry) == 2 and int(r.blueberry_treat.inputs.herbs) == 1 and int(r.blueberry_treat.inputs.carrot_snack) == 1 and int(r.blueberry_treat.seconds) == 900, "tabela do petisco")
	check(r.cut_sticks.output == "stick" and int(r.cut_sticks.qty) == 2 and int(r.cut_sticks.inputs.wood) == 1 and int(r.cut_sticks.seconds) == 60 and not items.has("cut_sticks"), "gravetos: receita sem item novo")
	check(int(items.braided_toy.sell_price) == 40 and int(items.picnic_pack.sell_price) == 110 and int(items.blueberry_treat.sell_price) == 65, "preços de venda")
	check(not items.braided_toy.has("feed") and not items.picnic_pack.has("feed"), "brinquedo e cesta não são alimento")
	check(int(items.blueberry_treat.feed.hunger) == 20 and int(items.blueberry_treat.feed.happiness) == 10 and items.blueberry_treat.feed.size() == 2, "petisco: fome 20, alegria 10")
	check(str(items.blueberry_treat.storage) == "fridge" and str(items.braided_toy.category) == "product" and str(items.picnic_pack.category) == "product", "depósitos")
	for id: String in ["braided_toy", "picnic_pack", "blueberry_treat"]:
		check(ResourceLoader.exists(str(items[id].icon)), "ícone de " + id)
	# Margem imediata (preço de venda − insumos), tabela 07: 12 / 34 / 19.
	var margins := {"braided_toy": 12, "picnic_pack": 34, "blueberry_treat": 19}
	for id: String in margins:
		var cost := 0
		for input: String in r[id].inputs:
			cost += int(r[id].inputs[input]) * int(items[input].get("sell_price", 0))
		check(int(items[id].sell_price) - cost == int(margins[id]), "margem de %s = %d (tem %d)" % [id, int(margins[id]), int(items[id].sell_price) - cost])
	# Gravetos não geram lucro reverso: madeira vale 2, dois gravetos valem 4, mas não há receita graveto → madeira.
	for id: String in r:
		if str(r[id].get("output", "")) == "wood":
			check(false, "não pode existir receita que devolve madeira (" + id + ")")
	var orders: Dictionary = database.progression.orders
	check(int(orders.nina_toys.rewards.coins) == 110 and int(orders.nina_toys.inputs.braided_toy) == 2 and int(orders.nina_toys.cooldown) == 3600 and str(orders.nina_toys.customer) == "nina", "nina_toys")
	check(int(orders.lais_picnic.rewards.coins) == 190 and int(orders.lais_picnic.inputs.picnic_pack) == 1 and int(orders.lais_picnic.inputs.strawberry_juice) == 2 and str(orders.lais_picnic.customer) == "lais", "lais_picnic")
	check(int(orders.nina_blueberries.rewards.coins) == 175 and int(orders.nina_blueberries.inputs.blueberry_treat) == 2 and int(orders.nina_blueberries.cooldown) == 7200, "nina_blueberries")
	for id: String in ["nina_toys", "lais_picnic", "nina_blueberries"]:
		check(not orders[id].has("channel"), "%s não é contrato" % id)
	for id: String in ["farm_breakfast", "fruit_basket", "pop_order", "vegetable_soup", "soup_order"]:
		if orders.has(id):
			check(orders[id].has("customer"), "catálogo antigo preservado: " + id)


func _gating_check() -> void:
	_fresh()
	for id: String in ["braided_toy", "picnic_pack", "blueberry_treat"]:
		check(state.call("cook_error", id) != "", "%s bloqueado no começo" % id)
	for id: String in ["nina_toys", "lais_picnic", "nina_blueberries"]:
		check(state.call("order_error", id) != "", "%s não vale antes das origens" % id)
	_after_atelier()
	check(state.call("cook_error", "blueberry_treat") != "", "petisco pede tesouro e estufa")
	check(state.call("order_error", "nina_blueberries") != "" and not state.call("wish_item_reachable", state.call("wish_def", "blueberry_treat")), "encomenda e desejo do petisco esperam tesouro + estufa")
	_inv().add("fabric", 1)
	_inv().add("stick", 2)
	check(state.call("cook_error", "braided_toy") == "", "brinquedo depois do ateliê")
	# Com a estufa mas sem o tesouro (e o contrário), continua fechado.
	state.call("dev_grant_upgrade", "greenhouse")
	check(state.call("cook_error", "blueberry_treat") != "", "estufa sem tesouro")
	state.get("progress").stats["treasure"] = 1
	_inv().add("blueberry", 2)
	_inv().add("herbs", 1)
	_inv().add("carrot_snack", 1)
	check(state.call("cook_error", "blueberry_treat") == "", "petisco com tesouro e estufa")


func _chain_check() -> void:
	_after_atelier()
	state.call("dev_grant_upgrade", "greenhouse")
	_progress().stats["treasure"] = 1
	# Gravetos renováveis: madeira → 2 gravetos, sem depender de sorteio.
	_inv().add("wood", 2)
	var got := _make("cut_sticks")
	check(int(got.get("stick", 0)) == 2 and _inv().count("wood") == 1 and _inv().count("stick") == 2, "madeira 1 → 2 gravetos")
	_make("cut_sticks")
	check(_inv().count("stick") == 4 and _inv().count("wood") == 0, "segundo lote de gravetos")
	check(_stat("produce:stick") == 4 and _stat("production_jobs") == 2, "contadores dos gravetos")
	# Brinquedo com insumos reais.
	_inv().add("fabric", 1)
	_make("braided_toy")
	check(_inv().count("braided_toy") == 1 and _inv().count("stick") == 2 and _inv().count("fabric") == 0, "brinquedo consome tecido 1 + graveto 2")
	check(_stat("produce:braided_toy") == 1, "contador produce:braided_toy")
	# Cesta.
	var before := {}
	for item: String in ["carrot_snack", "strawberry_pop", "strawberry_juice"]:
		_inv().add(item, 2)
		before[item] = _inv().count(item)
	_make("picnic_pack")
	check(_inv().count("picnic_pack") == 1 and _inv().count("carrot_snack") == int(before.carrot_snack) - 2 and _inv().count("strawberry_pop") == int(before.strawberry_pop) - 2 and _inv().count("strawberry_juice") == int(before.strawberry_juice) - 1, "cesta consome 2 + 2 + 1")
	# Petisco.
	_inv().add("blueberry", 2)
	_inv().add("herbs", 1)
	_inv().add("carrot_snack", 1)
	var snacks: int = _inv().count("carrot_snack")
	_make("blueberry_treat")
	check(_inv().count("blueberry_treat") == 1 and _inv().count("blueberry") == 0 and _inv().count("herbs") == 0 and _inv().count("carrot_snack") == snacks - 1, "petisco consome 2 + 1 + 1")
	# Só o petisco alimenta: hunger +20 e happiness +10; brinquedo/cesta não entram no menu alimentar.
	var dog: RefCounted = state.get("dog")
	dog.commit(state.call("now"))
	dog.needs["hunger"] = 50.0
	dog.needs["happiness"] = 50.0
	check(state.call("feed", "blueberry_treat") == true, "petisco alimenta")
	check(absf(dog.get_need("hunger", state.call("now")) - 70.0) < 1.0 and absf(dog.get_need("happiness", state.call("now")) - 60.0) < 1.0, "efeitos 20/10")
	check(state.call("feed", "braided_toy") == false and _inv().count("braided_toy") == 1, "brinquedo não é comida")
	check(state.call("feed", "picnic_pack") == false and _inv().count("picnic_pack") == 1, "cesta não é comida")


func _xp_check() -> void:
	_after_atelier()
	state.call("dev_grant_upgrade", "greenhouse")
	_progress().stats["treasure"] = 1
	var base := int(database.xp.cook)
	_inv().add("carrot", 2)
	_make("carrot_snack")
	check(int(state.get("xp")) == base, "receita antiga: XP global do cook (%d)" % int(state.get("xp")))
	var expected := {"cut_sticks": 1, "braided_toy": 8, "picnic_pack": 10, "blueberry_treat": 10}
	for id: String in expected:
		state.set("xp", 0)
		for input: String in database.recipes[id].inputs:
			_inv().add(input, int(database.recipes[id].inputs[input]))
		_make(id)
		check(int(state.get("xp")) == int(expected[id]), "%s paga %d de XP, sem somar o global (%d)" % [id, int(expected[id]), int(state.get("xp"))])
	# Habilidade: gravetos não treinam; o brinquedo treina aventura.
	check(int(database.recipes.cut_sticks.skill_xp) == 0, "gravetos: XP local 0")
	# Snapshot: ajustar player_xp depois de começar não muda o lote em andamento.
	state.set("xp", 0)
	_inv().add("fabric", 1)
	_inv().add("stick", 2)
	check(state.call("cook", "braided_toy") == "", "começa brinquedo")
	var original: int = database.recipes.braided_toy.player_xp
	database.recipes.braided_toy["player_xp"] = 99
	state.call("dev_advance_time", 4000.0)
	state.call("collect", "workbench")
	check(int(state.get("xp")) == 8, "snapshot: lote começado antes do ajuste paga 8 (%d)" % int(state.get("xp")))
	# Um novo lote já vale o ajuste.
	state.set("xp", 0)
	_inv().add("fabric", 1)
	_inv().add("stick", 2)
	_make("braided_toy")
	check(int(state.get("xp")) == 99, "novo trabalho usa o valor novo")
	database.recipes.braided_toy["player_xp"] = original


func _orders_check() -> void:
	_after_atelier()
	state.call("dev_grant_upgrade", "greenhouse")
	_progress().stats["treasure"] = 1
	_inv().add("braided_toy", 2)
	var coins: int = state.get("coins")
	check(state.call("fulfill_order", "nina_toys") == "" and state.get("coins") >= coins + 110, "entrega nina_toys")
	check(_inv().count("braided_toy") == 0 and _stat("order:nina_toys") == 1, "brinquedos consumidos e contados")
	check(state.call("order_error", "nina_toys") != "", "recarga de 1 h")
	_inv().add("picnic_pack", 1)
	_inv().add("strawberry_juice", 2)
	coins = state.get("coins")
	check(state.call("fulfill_order", "lais_picnic") == "" and state.get("coins") >= coins + 190, "entrega lais_picnic")
	_inv().add("blueberry_treat", 2)
	coins = state.get("coins")
	check(state.call("fulfill_order", "nina_blueberries") == "" and state.get("coins") >= coins + 175, "entrega nina_blueberries")
	check(_stat("order:nina_toys") + _stat("order:nina_blueberries") == 2, "clientes contam entregas")


func _storage_and_reload_check() -> void:
	_after_atelier()
	# Baú cheio: o lote não cabe, continua pronto e nada se perde (nem XP nem contador).
	var cap: int = state.call("storage_capacity", "chest")
	_inv().add("fabric", 1)
	_inv().add("stick", 2)
	check(state.call("cook", "braided_toy") == "", "brinquedo na fila")
	# Reload com a fila andando: o trabalho sobrevive.
	_reload()
	check(not state.call("station", "workbench").queue.is_empty(), "fila sobrevive ao reload")
	var filler: int = cap - _inv().count("braided_toy") - _inv().count("stick")
	var item := "picnic_pack"
	_inv().add(item, maxi(0, state.call("storage_capacity", "chest") - _inv().count(item) - _inv().count("stick")))
	state.set("xp", 0)
	state.call("dev_advance_time", 4000.0)
	var got: Dictionary = state.call("collect", "workbench")
	check(got.is_empty() and _inv().count("braided_toy") == 0 and _stat("produce:braided_toy") == 0 and int(state.get("xp")) == 0, "baú cheio: lote fica pronto sem XP (filler %d)" % filler)
	_inv().remove(item, 1)
	got = state.call("collect", "workbench")
	check(int(got.get("braided_toy", 0)) == 1 and int(state.get("xp")) == 8, "depois de abrir espaço, entrega uma vez")
	check(state.call("collect", "workbench").is_empty(), "não entrega duas vezes")


func _workshop_check() -> void:
	var quests: Dictionary = database.quests
	for id: String in ["workshop_toy", "workshop_first_set", "workshop_picnic"]:
		check(quests.has(id) and str(quests[id].line) == "workshop" and str(quests[id].npc) == "guide" and str(quests[id].kind) == "line", "missão " + id)
	check([int(quests.workshop_toy.order), int(quests.workshop_first_set.order), int(quests.workshop_picnic.order)] == [10, 20, 30], "ordens 10/20/30")
	check(int(quests.workshop_toy.rewards.coins) == 10 and int(quests.workshop_picnic.rewards.coins) == 10 and int(quests.workshop_first_set.rewards.items.iron_band) == 1, "prêmios")
	check(not quests.workshop_first_set.goals[0].has("fresh"), "conjunto sem fresh")
	_fresh()
	check(_progress().current_line_quest("workshop") == "", "linha fechada antes do ateliê")
	_after_atelier()
	check(_progress().current_line_quest("workshop") == "workshop_toy", "linha abre depois de atelier_open")
	# Já fez o conjunto no capítulo 9: o passo 2 reconhece sozinho.
	_progress().stats["produce:accessory_set"] = 1
	_progress().stats["produce:braided_toy"] = 1
	var before: int = _inv().count("iron_band")
	check(state.call("claim_quest", "workshop_toy") == "", "brinquedo produzido fecha o passo 1")
	check(_progress().current_line_quest("workshop") == "workshop_first_set", "passo 2 é o conjunto")
	check(state.call("claim_quest", "workshop_first_set") == "", "conjunto já feito é reconhecido")
	check(_inv().count("iron_band") == before + 1, "prêmio iron_band")
	_progress().stats["produce:picnic_pack"] = 1
	check(state.call("claim_quest", "workshop_picnic") == "", "cesta fecha o passo 3")
	check(_progress().current_line_quest("workshop") == "", "linha concluída")


func _wish_check() -> void:
	_after_atelier()
	state.call("dev_set_phase", "puppy")
	var wishes: RefCounted = state.get("wishes")
	wishes.first_done = true
	check(str(state.call("wish_def", "blueberry_treat").get("item", "")) == "blueberry_treat", "desejo cadastrado")
	# Antes do tesouro/estufa a missão nem está ativa e o pedido não é oferecido.
	check(_progress().current_line_quest("nina_flavors") == "", "missão do mirtilo fechada")
	state.call("dev_grant_upgrade", "greenhouse")
	_progress().stats["treasure"] = 1
	check(_progress().current_line_quest("nina_flavors") == "nina_blueberry", "missão do mirtilo aberta")
	check(not state.call("wish_item_reachable", state.call("wish_def", "blueberry_treat")) == false, "pedido alcançável (receita liberada)")
	# Vaga ocupada por outro pedido: nunca é substituída.
	var open_slots: Array[int] = []
	for i in wishes.slots.size():
		if state.call("wish_slot_open", i):
			open_slots.append(i)
	check(open_slots.size() >= 1, "há espaço de desejo aberto")
	for i in open_slots:
		wishes.slots[i] = {"id": "pet", "base": 0, "since": 0.0, "ready_at": 0.0, "special": false, "last": "", "used": false}
	state.call("update_wishes")
	for i in open_slots:
		check(str(wishes.slots[i].id) == "pet", "pedido atual não é substituído")
	# Próxima vaga vazia e pronta recebe o desejo garantido.
	wishes.slots[open_slots[0]] = {"id": "", "base": 0, "since": 0.0, "ready_at": 0.0, "special": false, "last": "", "used": false}
	state.call("update_wishes")
	check(str(wishes.slots[open_slots[0]].id) == "blueberry_treat", "desejo de mirtilo garantido na próxima vaga")
	check(_inv().count("blueberry_treat") == 0 and _inv().count("blueberry") == 0, "não gera ingrediente nem item")
	# Troca voluntária: sem custo, e o mesmo espaço não repete na hora.
	check(state.call("swap_wish", open_slots[0]) == "", "troca voluntária funciona")
	wishes.slots[open_slots[0]].ready_at = 0.0
	state.call("update_wishes")
	check(str(wishes.slots[open_slots[0]].id) != "blueberry_treat", "depois de trocar, outro pedido ocupa o espaço")
	# Em outra vaga vazia ele volta (a missão continua ativa).
	if open_slots.size() > 1:
		wishes.slots[open_slots[1]] = {"id": "", "base": 0, "since": 0.0, "ready_at": 0.0, "special": false, "last": "", "used": false}
		state.call("update_wishes")
		check(str(wishes.slots[open_slots[1]].id) == "blueberry_treat", "volta na próxima vaga elegível")
	# Entregar: conta uma vez, o item sai e a missão fecha.
	var slot := -1
	for i in open_slots:
		if str(wishes.slots[i].id) == "blueberry_treat":
			slot = i
	if slot < 0:
		wishes.slots[open_slots[0]] = {"id": "blueberry_treat", "base": 0, "since": 0.0, "ready_at": 0.0, "special": true, "last": "", "used": false}
		slot = open_slots[0]
	_inv().add("blueberry_treat", 1)
	check(state.call("fulfill_wish", slot) == "", "entrega o desejo")
	check(_stat("wish_item:blueberry_treat") == 1 and _inv().count("blueberry_treat") == 0, "contador uma vez e item consumido")
	check(state.call("claim_quest", "nina_blueberry") == "", "missão do mirtilo pronta")
	check(_progress().claimed_quests.has("nina_blueberry"), "missão recebida")
	state.call("update_wishes")
	for i in wishes.slots.size():
		if i != slot:
			wishes.slots[i] = {"id": "", "base": 0, "since": 0.0, "ready_at": 0.0, "special": false, "last": "", "used": false}
	state.call("update_wishes")
	for i in wishes.slots.size():
		check(str(wishes.slots[i].id) != "blueberry_treat" or not state.call("wish_slot_open", i) or false, "depois da missão deixa de ser garantido")
	# Sem rare: o contador walk_rare continua 0.
	check(_stat("walk_rare") == 0, "mirtilo sem depender de raro")
