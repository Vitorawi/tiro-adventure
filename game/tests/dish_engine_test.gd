extends SceneTree
## Motor de pratos (plano primeira_semana, E02): os totais da planilha por dia (23, 53, 308, 497 e 538), o cálculo de
## nutrientes linha a linha, Gororoba, nomes, o identificador de prato dinâmico e o prato indo ao depósito, à venda e ao Tiro
## (inclusive depois de salvar e carregar).
##   godot --headless --path game -s res://tests/dish_engine_test.gd
var _failures: int = 0
var state: Node
var db: Node
var rules: Script


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("DISH ENGINE: " + message)


func _run() -> void:
	state = root.get_node("GameState")
	db = root.get_node("Database")
	load("res://tests/helpers/old_day_rules.gd").new().apply(db)
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	rules = load("res://scripts/state/dish_rules.gd")
	var build_info: Script = load("res://scripts/util/build_info.gd")
	if not build_info.call("is_dev"):
		print("DISH ENGINE TEST: PASS (pulado fora da versão dev)")
		quit(0)
		return
	_data()
	_totals()
	_nutrients()
	_gororoba_rules()
	_names_and_tastes()
	_ids()
	_dynamic_dish()
	_gororoba_cooking()
	_errors()
	_meal_vs_snack()
	print("DISH ENGINE TEST: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(0 if _failures == 0 else 1)


func _n(type: String, ingredients: Array, stars: int = 1, phase: String = "puppy") -> Array:
	var values: Dictionary = rules.call("nutrients", type, ingredients, stars, phase)
	return [values.forca, values.brilho, values.foco, values.animo]


func _data() -> void:
	_check((db.call("dish_problems") as Array).is_empty(), "dishes.json coerente: %s" % [db.call("dish_problems")])
	_check((db.call("invent_problems") as Array).is_empty(), "invent.json coerente: %s" % [db.call("invent_problems")])
	_check((db.get("dishes").ingredients as Dictionary).size() == 13, "13 ingredientes")
	_check((db.get("dishes").duples as Array).size() == 13, "13 duplas")
	_check((db.get("dishes").types as Dictionary).size() == 5, "5 tipos de prato")
	var named: Array = db.get("dishes").named
	_check(named.size() >= 24 and named.size() <= 26, "cerca de 25 pratos com nome próprio (%d)" % named.size())
	var vovo := 0
	var secret := 0
	for entry: Dictionary in named:
		vovo += 1 if entry.has("taught") else 0
		secret += 1 if bool(entry.get("secret", false)) else 0
	_check(vovo == 7 and secret == 4, "a vovó ensina 7 e há 4 secretas (%d, %d)" % [vovo, secret])
	_check(rules.call("order") == ["cenoura", "batata", "abobora", "abobrinha", "batata_doce", "aveia", "milho", "arroz", "ovo", "peixe", "maca", "banana", "melancia"], "ordem canônica dos ingredientes")
	for item_id: String in ["zucchini", "oat", "rice", "banana", "watermelon", "gororoba"]:
		_check(db.get("items").has(item_id) and db.call("item_icon", item_id) != null, "item %s com ícone" % item_id)


func _totals() -> void:
	var expected := [23, 53, 308, 497, 538]
	for day in 5:
		var total := int(rules.call("count_for_day", day + 1))
		_check(total == expected[day], "dia %d: %d pratos (esperava %d)" % [day + 1, total, expected[day]])
	# Por tipo, acumulado (tabela do plano).
	var by_type := {
		"papinha": [9, 15, 160, 225, 225], "sopinha": [0, 0, 70, 110, 110], "mingau": [0, 0, 0, 39, 63],
		"petisco": [14, 27, 54, 90, 104], "biscoito": [0, 11, 24, 33, 36],
	}
	for day in 5:
		var counts := {}
		for entry: Dictionary in rules.call("combinations", day + 1):
			counts[entry.type] = int(counts.get(entry.type, 0)) + 1
		for type: String in by_type:
			_check(int(counts.get(type, 0)) == by_type[type][day], "dia %d: %s = %d (esperava %d)" % [day + 1, type, int(counts.get(type, 0)), by_type[type][day]])
	_check(int(rules.call("count_for_day", 5, 1)) == 398, "398 refeições")
	_check(int(rules.call("count_for_day", 5, 0)) == 140, "140 lanches")
	_check(int(rules.call("count_for_day", 99)) == 538, "depois do dia 5 nada novo (538)")


func _nutrients() -> void:
	# Linhas da planilha "Catálogo de pratos do filhote" (1 estrela, Filhotinho): [Força, Brilho, Foco, Ânimo].
	var rows: Array = [
		["papinha", ["cenoura", "abobora"], [1, 5, 2, 0]],
		["papinha", ["abobora", "abobora"], [2, 5, 0, 0]],
		["papinha", ["cenoura", "cenoura"], [0, 2, 5, 0]],
		["papinha", ["batata", "abobora"], [4, 2, 0, 0]],
		["papinha", ["cenoura", "aveia"], [1, 1, 4, 0]],
		["papinha", ["abobora", "aveia"], [2, 2, 1, 0]],
		["papinha", ["batata", "batata"], [5, 0, 0, 0]],
		["papinha", ["batata", "ovo"], [5, 4, 0, 0]],
		["papinha", ["abobora", "milho"], [2, 2, 0, 2]],
		["papinha", ["cenoura", "ovo", "peixe"], [4, 7, 4, 0]],
		["papinha", ["batata", "ovo", "peixe"], [7, 7, 0, 0]],
		["papinha", ["abobora", "peixe", "peixe"], [4, 10, 0, 0]],
		["papinha", ["abobrinha", "arroz", "peixe"], [2, 5, 2, 0]],
		["petisco", ["cenoura", "abobora"], [1, 4, 2, 0]],
		["petisco", ["ovo"], [2, 2, 0, 0]],
		["biscoito", ["milho", "ovo"], [4, 2, 0, 1]],
		["sopinha", ["cenoura", "abobora", "peixe"], [2, 7, 3, 1]],
		["sopinha", ["cenoura", "batata", "peixe"], [4, 4, 3, 1]],
		["sopinha", ["cenoura", "cenoura", "peixe"], [1, 5, 5, 1]],
		["mingau", ["abobora", "milho", "banana"], [2, 2, 0, 6]],
		["mingau", ["batata_doce", "aveia", "banana"], [2, 0, 1, 6]],
		["mingau", ["milho", "banana"], [1, 0, 0, 5]],
	]
	for row: Array in rows:
		var got := _n(str(row[0]), row[1])
		_check(got == row[2], "%s %s: %s (esperava %s)" % [row[0], row[1], got, row[2]])
	# Ordem das vagas não muda o prato.
	_check(_n("papinha", ["ovo", "cenoura", "peixe"]) == [4, 7, 4, 0], "a ordem das vagas não muda os nutrientes")
	# Estrelas: o multiplicador do preparo se soma ao da maciça UMA vez (exemplo do documento: 1 6 3 0).
	_check(_n("papinha", ["cenoura", "abobora"], 2) == [1, 6, 3, 0], "papinha 2 estrelas em Filhotinho: 1 6 3 0")
	# Fora das duas primeiras fases a papinha deixa de ser macia.
	_check(_n("papinha", ["cenoura", "abobora"], 1, "teething") == [1, 4, 2, 0], "Dentinhos: sem o x1,2 da maciça")
	_check(_n("papinha", ["cenoura", "abobora"], 3, "teething") == [1, 6, 3, 0], "3 estrelas ×1,4 em Dentinhos")
	# Duplas.
	var duples: Array = rules.call("duples_of", ["peixe", "batata", "ovo"])
	var ids: Array[String] = []
	for duple: Dictionary in duples:
		ids.append(str(duple.id))
	ids.sort()
	_check(ids == ["classico_da_lagoa", "pure_dourado"], "duplas de peixe+batata+ovo: %s" % [ids])
	_check((rules.call("duples_of", ["cenoura", "cenoura"]) as Array).is_empty(), "o mesmo ingrediente não faz dupla")


func _gororoba_rules() -> void:
	var cases: Array = [
		["sopinha", ["cenoura", "batata", "maca"], "gororoba", "maca"],
		["sopinha", ["cenoura", "batata", "abobora"], "dish", ""],
		["mingau", ["aveia", "banana", "peixe"], "gororoba", "peixe"],
		["mingau", ["aveia", "banana", "abobora"], "dish", ""],
		["mingau", ["aveia", "banana", "cenoura"], "gororoba", "cenoura"],
		["mingau", ["banana", "maca"], "gororoba", ""],
		["papinha", ["ovo", "milho"], "gororoba", ""],
		["papinha", ["cenoura", "maca"], "gororoba", "maca"],
		["papinha", ["cenoura"], "incomplete", ""],
		["papinha", ["cenoura", "batata", "ovo", "peixe"], "invalid", ""],
		["biscoito", ["cenoura", "batata"], "gororoba", ""],
		["biscoito", ["aveia", "peixe"], "dish", ""],
		["petisco", ["melancia"], "dish", ""],
		["petisco", [], "incomplete", ""],
		["torta", ["aveia"], "invalid", ""],
	]
	for row: Array in cases:
		var verdict: Dictionary = rules.call("evaluate", row[0], row[1])
		_check(str(verdict.state) == row[2], "%s %s: %s (esperava %s)" % [row[0], row[1], verdict.state, row[2]])
		if str(row[3]) != "":
			_check(str(verdict.get("culprit", "")) == row[3], "%s %s: devolve %s (veio %s)" % [row[0], row[1], row[3], verdict.get("culprit", "")])


func _names_and_tastes() -> void:
	var names: Array = [
		["papinha", ["abobora", "peixe", "peixe"], "Papinha de abóbora e peixe"],
		["papinha", ["abobrinha", "ovo", "peixe"], "Papinha de abobrinha, ovo e peixe"],
		["papinha", ["peixe", "abobrinha", "ovo"], "Papinha de abobrinha, ovo e peixe"],
		["petisco", ["abobora"], "Petisco de abóbora"],
		["biscoito", ["milho", "ovo"], "Biscoito de milho e ovo"],
		["mingau", ["abobora", "milho", "banana"], "Mingau de abóbora, milho e banana"],
		["papinha", ["cenoura", "batata"], "Papinha de cenoura e batata"],
		["mingau", ["milho", "banana"], "Curau do Tiro"],
		["papinha", ["abobrinha", "arroz", "peixe"], "Risotinho do lago"],
		["sopinha", ["cenoura", "batata", "peixe"], "Sopinha do pescador"],
		["petisco", ["ovo"], "Ovinho cozido"],
	]
	for row: Array in names:
		var got := str(rules.call("name_of", row[0], row[1]))
		_check(got == row[2], "nome de %s %s: '%s' (esperava '%s')" % [row[0], row[1], got, row[2]])
	var tastes: Array = [
		[["cenoura", "abobora"], "crocante"], [["abobora", "ovo"], "cremoso"], [["abobora", "aveia"], "docinho"],
		[["batata", "aveia"], "cremoso"], [["cenoura", "aveia"], "crocante"], [["abobora", "aveia", "banana"], "docinho"],
		[["cenoura", "peixe", "peixe"], "cheiroso_de_mar"],
	]
	for row: Array in tastes:
		_check(str(rules.call("taste", row[0])) == row[1], "sabor de %s: %s (esperava %s)" % [row[0], rules.call("taste", row[0]), row[1]])


func _ids() -> void:
	var id := str(rules.call("make_id", "papinha", ["ovo", "cenoura", "peixe"], 2))
	_check(id == "dish_papinha_cenoura+ovo+peixe_2", "id canônico: %s" % id)
	_check(str(rules.call("make_id", "papinha", ["peixe", "ovo", "cenoura"], 2)) == id, "a ordem escolhida não muda o id")
	var info: Dictionary = rules.call("parse", id)
	_check(str(info.type) == "papinha" and info.ingredients == ["cenoura", "ovo", "peixe"] and int(info.stars) == 2, "o id volta a ser descrição")
	var batata_doce := str(rules.call("make_id", "mingau", ["batata_doce", "aveia", "banana"], 1))
	_check(batata_doce == "dish_mingau_batata_doce+aveia+banana_1" and not (rules.call("parse", batata_doce) as Dictionary).is_empty(), "ingrediente com _ no meio do id: %s" % batata_doce)
	var allowed := RegEx.create_from_string("^[a-z0-9_+]+$")
	_check(allowed.search(batata_doce) != null and allowed.search(id) != null, "ids só com [a-z0-9_+] (servem de nome de nó)")
	for bad: String in ["dish_", "dish_papinha", "dish_papinha_x_1", "dish_papinha_cenoura+ovo", "dish_papinha_ovo+cenoura_1", "dish_nada_cenoura_1", "dish_papinha_cenoura_9", "carrot"]:
		_check(not bool(rules.call("is_dish_id", bad)), "id inválido recusado: %s" % bad)
	_check(str(rules.call("make_id", "papinha", [], 1)) == "" and str(rules.call("make_id", "papinha", ["pedra"], 1)) == "", "make_id recusa vazio e ingrediente desconhecido")
	_check(not bool(db.call("ensure_dish", "carrot_nao_existe")), "ensure_dish recusa id que não é prato")
	_check(bool(db.call("ensure_dish", id)) and db.get("items").has(id) and bool(db.call("ensure_dish", id)), "ensure_dish registra e é idempotente")
	var def: Dictionary = db.get("items")[id]
	_check(str(def.category) == "food" and str(def.storage) == "fridge" and def.has("feed") and def.has("growth") and not def.has("treat"), "item da refeição: comida, geladeira, sem treat")
	_check(str(db.call("item_name", id)) == "Papinha de cenoura, ovo e peixe" and db.call("item_icon", id) != null, "nome e ícone do prato")
	_check(int(def.sell_price) >= 4, "tem preço de venda")
	var snack := str(rules.call("make_id", "petisco", ["cenoura"], 1))
	db.call("ensure_dish", snack)
	_check(bool(db.get("items")[snack].get("treat", false)), "lanche vira treat")
	_check(str(rules.call("ingredient_of_item", "fish_cara")) == "peixe" and str(rules.call("ingredient_of_item", "fish_tilapia")) == "peixe", "os três peixes são o ingrediente peixe")
	_check(str(rules.call("ingredient_of_item", "flour")) == "", "farinha não é ingrediente da semana")


func _prepare() -> void:
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.set("coins", 100)
	state.get("inventory").call("from_dict", {})
	for station_id: String in state.get("stations"):
		state.get("stations")[station_id].queue.clear()
	state.call("dev_week_goto", 5)
	state.call("dev_content_day", 5)


func _give(item: String, amount: int) -> void:
	state.get("inventory").call("add", item, amount)


func _count(item: String) -> int:
	return int(state.get("inventory").call("count", item))


func _make_ready() -> void:
	for entry: Dictionary in state.call("station", "stove").queue:
		entry["ready_at"] = float(state.call("now")) - 1.0


func _dynamic_dish() -> void:
	_prepare()
	for item in ["carrot", "egg", "fish_tilapia"]:
		_give(item, 2)
	var id := str(rules.call("make_id", "papinha", ["cenoura", "ovo", "peixe"], 1))
	var plan: Dictionary = state.call("dish_plan", "papinha", ["fish_tilapia", "egg", "carrot"], 1)
	_check(str(plan.error) == "" and str(plan.output) == id and str(plan.state) == "dish", "plano: %s" % [plan])
	_check(str(state.call("cook_dish_error", "papinha", ["fish_tilapia", "egg", "carrot"])) == "", "dá para cozinhar")
	_check(str(state.call("cook_dish", "papinha", ["fish_tilapia", "egg", "carrot"])) == "", "cozinha a papinha")
	_check(_count("carrot") == 1 and _count("egg") == 1 and _count("fish_tilapia") == 1, "gastou os 3 ingredientes")
	var queue: Array = state.call("station", "stove").queue
	_check(queue.size() == 1 and str(queue[0].job.output) == id and bool(db.get("items").has(id)), "lote na fila com o prato registrado")
	# Estava na fila e o jogo foi fechado e aberto: o prato volta a ser conhecido.
	var saved: Dictionary = state.call("to_dict")
	db.get("items").erase(id)
	state.call("from_dict", saved.duplicate(true))
	_check(bool(db.get("items").has(id)), "carregar o save registra o prato do lote na fila")
	_make_ready()
	var got: Dictionary = state.call("collect", "stove")
	_check(int(got.get(id, 0)) == 1 and _count(id) == 1, "recolher entrega o prato (%s)" % [got])
	_check(str(state.call("storage_of", id)) == "fridge", "o prato é guardado na geladeira")
	_check(int(state.call("storage_used", "fridge")) >= 1, "o prato conta no depósito")
	_check(int(state.get("progress").call("stat", "produce:" + id)) == 1, "contador produce:<prato>")
	# Salvar e carregar com o prato no inventário.
	saved = state.call("to_dict")
	db.get("items").erase(id)
	state.call("from_dict", saved.duplicate(true))
	_check(_count(id) == 1 and bool(db.get("items").has(id)), "carregar o save registra o prato do inventário")
	_check(str(db.call("item_name", id)) == "Papinha de cenoura, ovo e peixe", "nome depois de carregar")
	# Vender.
	var price := int(db.get("items")[id].sell_price)
	var coins_before := int(state.get("coins"))
	_check(str(state.call("sell", id, 1)) == "" and _count(id) == 0 and int(state.get("coins")) == coins_before + price, "vender o prato paga %d" % price)
	# Dar ao Tiro.
	_give(id, 1)
	state.get("dog").needs["hunger"] = 20.0
	var hunger_before := float(state.get("dog").needs["hunger"])
	_check(bool(state.call("feed", id)) and _count(id) == 0, "dar o prato ao Tiro")
	_check(float(state.get("dog").needs["hunger"]) > hunger_before, "a barriga encheu")
	_check(int(state.get("progress").call("stat", "feed:" + id)) == 1, "contador feed:<prato>")
	var info: Dictionary = state.call("dish_info", id)
	_check(bool(info.meal) and str(info.name) == "Papinha de cenoura, ovo e peixe" and info.nutrients.brilho >= 1, "dish_info: %s" % [info])
	_check((state.call("dish_info", "carrot") as Dictionary).is_empty(), "dish_info de item comum é vazio")


func _gororoba_cooking() -> void:
	_prepare()
	_give("carrot", 2)
	_give("apple", 1)
	_check(str(state.call("cook_dish", "sopinha", ["carrot", "carrot", "apple"])) == "", "fruta na sopinha cozinha uma Gororoba")
	_check(_count("carrot") == 0 and _count("apple") == 1, "devolveu a fruta (sem desperdício)")
	_make_ready()
	var got: Dictionary = state.call("collect", "stove")
	_check(int(got.get("gororoba", 0)) == 1 and _count("gororoba") == 1, "recolher entrega a Gororoba")
	_check(not bool(state.call("is_meal_item", "gororoba")), "Gororoba não conta como refeição")
	_check(bool(state.call("feed", "gororoba")), "o Tiro come a Gororoba")
	_check(int(state.get("progress").call("stat", "produce:gororoba")) == 1, "contador de produção da Gororoba")


func _errors() -> void:
	_prepare()
	state.call("dev_week_goto", 1)
	state.call("dev_content_day", 1)
	_give("carrot", 3)
	_give("potato", 3)
	_give("pumpkin", 3)
	_check(str(state.call("cook_dish", "sopinha", ["carrot", "potato", "pumpkin"])) == "Continue a História", "tipo ainda fechado no dia 1")
	_check(str(state.call("cook_dish", "papinha", ["carrot", "potato", "pumpkin"])) == "Só cabem 2 ingredientes", "a 3ª vaga da papinha abre no dia 3")
	state.call("dev_week_goto", 3)
	state.call("dev_content_day", 3)
	_check(str(state.call("cook_dish", "papinha", ["carrot"])) == "Faltam ingredientes", "papinha com um ingrediente só")
	_check(str(state.call("cook_dish", "papinha", [])) == "Escolha ingredientes", "nada escolhido")
	_check(str(state.call("cook_dish", "papinha", ["wheat", "carrot"])) == "Ingrediente inválido", "trigo não é ingrediente")
	_check(str(state.call("cook_dish", "torta", ["carrot"])) == "Prato desconhecido", "tipo desconhecido")
	_check(str(state.call("cook_dish", "papinha", ["carrot", "egg"])) == "Falta Ovos ×1", "falta ingrediente: %s" % state.call("cook_dish_error", "papinha", ["carrot", "egg"]))
	_check(_count("carrot") == 3, "erro não gasta nada")
	var slots := int(state.call("station_slots", "stove"))
	_give("carrot", slots)
	_give("egg", slots + 2)
	for i in slots:
		_check(str(state.call("cook_dish", "papinha", ["carrot", "egg"])) == "", "enche a fila (%d)" % i)
	var eggs := _count("egg")
	_check(str(state.call("cook_dish", "papinha", ["potato", "egg"])) == "Fila cheia", "fila cheia")
	_check(_count("potato") == 3 and _count("egg") == eggs, "fila cheia não gasta (%d)" % _count("egg"))
	# Pelo caminho da aba Inventar (multiconjunto + tipo).
	_prepare()
	_give("carrot", 2)
	_check(str(state.call("cook_invented", {"carrot": 1, "pumpkin": 1}, "papinha")) == "Falta Abóbora ×1", "cook_invented com tipo passa pelo motor: %s" % state.call("cook_invented_error", {"carrot": 1, "pumpkin": 1}, "papinha"))
	_check(str(state.call("cook_invented", {"carrot": 2}, "petisco")) == "" and _count("carrot") == 0, "cook_invented com tipo cozinha o petisco")


func _meal_vs_snack() -> void:
	_prepare()
	var meal := str(rules.call("make_id", "sopinha", ["cenoura", "batata", "abobora"], 1))
	var snack := str(rules.call("make_id", "biscoito", ["aveia", "abobora"], 1))
	var snack2 := str(rules.call("make_id", "petisco", ["ovo"], 1))
	var mash := str(rules.call("make_id", "mingau", ["aveia", "banana"], 1))
	var papinha := str(rules.call("make_id", "papinha", ["cenoura", "batata"], 1))
	for id: String in [meal, snack, snack2, mash, papinha]:
		_give(id, 1)
	_check(bool(state.call("is_meal_item", meal)) and bool(state.call("is_meal_item", mash)) and bool(state.call("is_meal_item", papinha)), "sopinha, mingau e papinha são refeição")
	_check(not bool(state.call("is_meal_item", snack)) and not bool(state.call("is_meal_item", snack2)), "biscoito e petisco são lanche")
	# Lanche não conta como refeição na hora; refeição sim (dia 5, no almoço).
	state.call("dev_week_hour", 12)
	var on_time_before := int(state.call("meals_on_time", int(state.call("week_day"))))
	_check(bool(state.call("feed", snack)), "dá o biscoito")
	_check(int(state.call("meals_on_time", int(state.call("week_day")))) == on_time_before, "o biscoito não conta como refeição")
	_check(bool(state.call("feed", meal)), "dá a sopinha")
	_check(int(state.call("meals_on_time", int(state.call("week_day")))) == on_time_before + 1, "a sopinha conta como refeição na hora")
	_check(bool(state.call("is_meal_item", "puppy_mash")) and not bool(state.call("is_meal_item", "carrot_snack")), "itens fixos seguem a regra antiga")
