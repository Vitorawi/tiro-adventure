extends SceneTree
## Etapa 14 do plano de economia: investimentos do sítio e a cadeia ovos → leite → farinha → queijo → café.
## Cobre: custos da tabela 02 F, preços/requisitos dos animais, linha da Bloblo 70–140, os cinco elos por
## ações reais, compra de animal antes/durante/depois do lote, café com o pedido existente e ração renovável.
## --headless --path game -s res://tests/animals_chain_test.gd

const T0 := 1791936000.0
const COSTS := {
	"farm": [220, {}], "workbench": [160, {"wood": 6}], "chicken_coop": [260, {"plank": 4}],
	"cow_barn": [420, {"plank": 6}], "mill": [300, {"plank": 3, "stone": 6}],
	"dairy": [420, {"plank": 4, "brick": 3}], "orchard": [400, {"plank": 5}],
	"stall": [500, {"plank": 5, "brick": 3}], "greenhouse": [850, {"plank": 6, "brick": 6, "crystal": 2}],
	"atelier": [1000, {"plank": 8, "copper": 6}],
}
const PRICES := {
	"chicken_white": 120, "chicken_brown": 150, "chicken_black": 180,
	"cow_white": 220, "cow_brown": 280, "cow_spotted": 340,
}

var failures := 0
var state: Node
var db: Node


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("ANIMAIS-CADEIA: " + message)


func _p() -> RefCounted:
	return state.get("progress")


func _stat(key: String) -> int:
	return int(_p().stat(key))


func _inv(item: String) -> int:
	return int(state.get("inventory").count(item))


func _coins() -> int:
	return int(state.get("coins"))


## Alimenta, espera e recolhe até o contador `produce:<item>` chegar à meta (ações reais).
func _produce(station: String, recipe: String, seconds: int, item: String, target: int) -> void:
	var guard := 0
	while _stat("produce:" + item) < target and guard < 24:
		guard += 1
		if state.call("cook", recipe) != "":
			break
		state.call("dev_advance_time", seconds)
		state.call("collect", station)


func _claim(id: String) -> void:
	var reason: String = state.call("claim_quest", id)
	check(reason == "", "Receber %s: %s" % [id, reason])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	_data()
	_chain()
	print("ANIMALS CHAIN TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


func _data() -> void:
	var upgrades: Dictionary = db.get("progression").upgrades
	for id: String in COSTS:
		check(int(upgrades[id].cost) == int(COSTS[id][0]), "%s custa %s" % [id, COSTS[id][0]])
		var materials: Dictionary = upgrades[id].get("materials", {})
		check(materials.size() == (COSTS[id][1] as Dictionary).size(), "%s: materiais" % id)
		for item: String in COSTS[id][1]:
			check(int(materials.get(item, 0)) == int(COSTS[id][1][item]), "%s: %s" % [id, item])
	var animals: Dictionary = db.get("animals")
	for id: String in PRICES:
		check(int(animals[id].price) == PRICES[id], "%s custa %s" % [id, PRICES[id]])
	# Mesmo rendimento: variedades só diferem no desenho/escala e no requisito de uso.
	for id: String in animals:
		for key: String in animals[id]:
			check(key in ["name", "station", "price", "sprite", "legacy", "map_scale", "requirements"], "%s: campo escondido %s" % [id, key])
	check(int(animals.chicken_brown.requirements.produced.egg) == 8, "Ruiva pede 8 ovos")
	check(int(animals.chicken_black.requirements.produced.egg) == 24, "Preta pede 24 ovos")
	check(int(animals.cow_brown.requirements.produced.milk) == 8, "Caramelo pede 8 leites")
	check(int(animals.cow_spotted.requirements.produced.milk) == 24, "Malhada pede 24 leites")
	var quests: Dictionary = db.get("quests")
	var order := ["farm_deed", "main_9_coop", "main_9_eggs", "main_9_cows", "bloblo_milk", "main_9_flour", "main_9_cheese", "bloblo_breakfast"]
	var last := -1
	for id: String in order:
		check(quests.has(id), "Existe " + id)
		check(int(quests[id].order) > last, "Ordem crescente em " + id)
		last = int(quests[id].order)
	check(int(quests.bloblo_breakfast.order) == 140, "Café na ordem 140")
	check(int(quests.bloblo_breakfast.rewards.coins) == 15 and quests.bloblo_breakfast.rewards.size() == 1, "Café paga 15 moedas")
	check(str(quests.bloblo_breakfast.goals[0].key) == "order:farm_breakfast" and int(quests.bloblo_breakfast.goals[0].target) == 1, "Café reconhece o pedido")
	var flour: Dictionary = quests.main_9_flour
	var keys: Array = []
	for goal: Dictionary in flour.goals:
		check(not goal.get("fresh", false), "Farinha sem fresh")
		keys.append(str(goal.type) + ":" + str(goal.key))
	check("owned:mill" in keys and "stat:produce:flour" in keys, "Farinha pede moinho + 2 farinhas")
	var orders: Dictionary = db.get("progression").orders
	var same := 0
	for id: String in orders:
		if orders[id].inputs == orders.farm_breakfast.inputs:
			same += 1
	check(same == 1, "Nenhum pedido duplica o café")
	var o: Dictionary = orders.farm_breakfast
	check(int(o.inputs.egg) == 2 and int(o.inputs.flour) == 2 and int(o.inputs.cheese) == 1 and int(o.rewards.coins) == 95 and int(o.cooldown) == 600, "Pedido do café preservado")
	# A cadeia inteira não devolve o investimento: prêmios das missões < custo dos quatro abrigos.
	var rewards := 0
	for id: String in order.slice(1):
		rewards += int(quests[id].rewards.get("coins", 0))
	check(rewards < 420 + 260, "Prêmios da linha (%d) não pagam os abrigos" % rewards)
	# A ração tem origem renovável: plantas não dependem de produto de animal.
	for crop: String in ["corn", "wheat"]:
		var req: Dictionary = db.get("crops")[crop].get("requirements", {})
		check(not req.has("produced") and not req.has("stats"), crop + " não depende de produto animal")
	for recipe: String in ["eggs", "milk", "flour", "cheese"]:
		var req: Dictionary = db.get("recipes")[recipe].get("requirements", {})
		check(not req.has("produced"), recipe + " não depende de colher produto animal")


func _chain() -> void:
	state.set("test_time", T0)
	state.set("unlimited_storage", true)
	state.call("reset")
	state.call("dev_jump_to_chapter", 5)
	for id: String in ["farm_deed", "first_harvest", "main_4_bench", "main_4_materials"]:
		state.call("dev_complete_quest", id)
	state.call("dev_grant_upgrade", "farm")
	state.call("dev_grant_upgrade", "workbench")
	state.call("dev_add_coins", 3000)
	state.get("inventory").add("plank", 30)
	state.get("inventory").add("stone", 12)
	state.get("inventory").add("brick", 8)
	state.call("dev_advance_time", 0)
	check(_stat("produce:egg") == 0 and _stat("produce:milk") == 0, "Começa sem produto animal")
	# Ração renovável: milho/trigo plantam e rendem sem nenhum produto animal colhido.
	check(state.call("plant", 0, "corn") == "", "Milho planta sem produto animal")
	check(state.call("plant", 1, "wheat") == "", "Trigo planta sem produto animal")
	state.call("dev_finish_timers")
	check(int(state.call("harvest", 0).get("corn", 0)) == 6 and int(state.call("harvest", 1).get("wheat", 0)) == 4, "Colheita renova a ração")
	# Elo 1: galinheiro (260 + 4 tábuas) e a primeira galinha de presente.
	var coins := _coins()
	var planks := _inv("plank")
	check(state.call("buy_upgrade", "chicken_coop") == "", "Comprar galinheiro")
	check(_coins() == coins - 260 and _inv("plank") == planks - 4, "Galinheiro cobra 260 + 4 tábuas")
	check(state.call("animal_count", "chicken_coop") == 1, "Primeira galinha presente")
	_claim("main_9_coop")
	# Elo 2: ovos. O lote usa só os animais presentes; comprar durante não entra no lote.
	check(state.call("cook", "eggs") == "", "Alimentar a galinha")
	coins = _coins()
	check(state.call("buy_animal", "chicken_white") == "", "Comprar galinha durante o lote")
	check(_coins() == coins - 120, "Extra branca custa 120")
	state.call("dev_advance_time", 900)
	check(int(state.call("collect", "chicken_coop").get("egg", 0)) == 2, "Lote em andamento rende ovos 2 (sem o recém-comprado)")
	check(state.call("cook", "eggs") == "", "Novo lote com duas galinhas")
	state.call("dev_advance_time", 900)
	check(int(state.call("collect", "chicken_coop").get("egg", 0)) == 4, "Depois da compra, lote rende por animal")
	_claim("main_9_eggs")
	# Elo 3: curral e leite.
	coins = _coins()
	check(state.call("buy_upgrade", "cow_barn") == "", "Comprar curral")
	check(_coins() == coins - 420, "Curral custa 420")
	_claim("main_9_cows")
	_produce("cow_barn", "milk", 1800, "milk", 2)
	check(_inv("milk") >= 2, "Leite 2 recebido")
	_claim("bloblo_milk")
	# Elo 4: moinho e farinha 2 (sem fresh); o moinho pode ser comprado antes do queijo.
	check(state.call("quest_error", "main_9_flour") != "", "Farinha ainda não vale")
	check(state.call("buy_upgrade", "mill") == "", "Comprar moinho")
	_produce("mill", "flour", 300, "flour", 2)
	check(_inv("flour") >= 2, "Farinha 2 recebida")
	_claim("main_9_flour")
	# Elo 5: queijaria e queijo.
	check(state.call("buy_upgrade", "dairy") == "", "Comprar queijaria")
	_produce("cow_barn", "milk", 1800, "milk", 10)
	_produce("dairy", "cheese", 1200, "cheese", 2)
	_claim("main_9_cheese")
	# Café: o pedido existente, uma só entrega canônica.
	check(state.call("quest_error", "bloblo_breakfast") != "", "Café só vale depois do pedido")
	_produce("chicken_coop", "eggs", 900, "egg", 8)
	_produce("mill", "flour", 300, "flour", 4)
	_produce("cow_barn", "milk", 1800, "milk", 14)
	_produce("dairy", "cheese", 1200, "cheese", 3)
	var cheese := _inv("cheese")
	var egg := _inv("egg")
	var flour := _inv("flour")
	check(cheese >= 1 and egg >= 2 and flour >= 2, "Ingredientes do café prontos")
	check(state.call("fulfill_order", "farm_breakfast") == "", "Entregar o café")
	check(_inv("cheese") == cheese - 1 and _inv("egg") == egg - 2 and _inv("flour") == flour - 2, "Pedido consome 2 ovos, 2 farinhas, 1 queijo")
	check(state.call("fulfill_order", "farm_breakfast") != "", "Recarga de 600 s")
	coins = _coins()
	cheese = _inv("cheese")
	_claim("bloblo_breakfast")
	check(_coins() == coins + 15, "Café paga 15 moedas")
	check(_inv("cheese") == cheese, "Missão do café não recolhe outro queijo")
	check(state.call("quest_error", "bloblo_breakfast") != "", "Café não paga duas vezes")
	# Sem reset de save: ida e volta preserva a cadeia.
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	check(state.call("animal_count", "chicken_coop") == 2 and state.call("animal_count", "cow_barn") == 1, "Rebanho sobrevive ao save")
