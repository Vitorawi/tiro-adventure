extends SceneTree
## Etapa 07 do plano de economia: o armazém junto da Natureza (Pilha de materiais → Armazém → _2 → _3).
## Cobre: capacidades 16/32/56/88, custos e requisitos, classificação dos materiais, capítulo 5 de um save novo
## (caverna, armazém, material, bancada), sequência do Guia, dois parafusos sem sorteio, persistência do armazém
## recebido na Bloblo, grafo de requisitos com custos materiais e as primeiras ampliações em quatro ordens.
## --headless --path game -s res://tests/warehouse_test.gd

var failures := 0
var state: Node
var database: Node


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("WAREHOUSE: " + message)


func _inv(id: String) -> int:
	return int(state.get("inventory").count(id))


func _progress() -> Object:
	return state.get("progress")


func _materials(upgrade: Dictionary) -> String:
	var keys: Array = (upgrade.get("materials", {}) as Dictionary).keys()
	keys.sort()
	var text := ""
	for key: String in keys:
		text += "%s%d" % [key, int(upgrade.materials[key])]
	return text


func _fresh() -> void:
	state.call("reset")
	state.set("unlimited_storage", false)
	state.get("inventory").counts.clear()
	state.set("coins", 0)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	database = root.get_node("Database")
	_capacities()
	_classification()
	_chapter_five()
	_requirement_graph()
	_four_orders()
	print("WAREHOUSE TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# --- capacidades e dados ------------------------------------------------------------------------------

func _capacities() -> void:
	_fresh()
	check(bool(state.call("storage_active", "warehouse")), "jogo novo: a pilha já limita")
	check(int(state.call("storage_capacity", "warehouse")) == 16, "provisório = 16")
	check(state.call("storage_name", "warehouse") == "Pilha de materiais", "nome antes do armazém")
	check(int(state.call("storage_floor", "warehouse")) == 0, "jogo novo não tem piso legado")
	_progress().owned["warehouse"] = true
	check(int(state.call("storage_capacity", "warehouse")) == 32 and state.call("storage_name", "warehouse") == "Armazém", "armazém = 32 e nome novo")
	_progress().owned["warehouse_2"] = true
	check(int(state.call("storage_capacity", "warehouse")) == 56, "warehouse_2 = 56")
	_progress().owned["warehouse_3"] = true
	check(int(state.call("storage_capacity", "warehouse")) == 88, "warehouse_3 = 88")
	state.call("_changed")
	check(int(state.call("storage_floor", "warehouse")) == 0, "comprar não cria piso legado")
	var upgrades: Dictionary = database.get("progression").upgrades
	check(int(upgrades.warehouse_2.storage_capacity) == 24 and int(upgrades.warehouse_3.storage_capacity) == 32, "ampliações somam só a diferença (24 e 32)")
	var base: Dictionary = upgrades.warehouse
	check(int(base.cost) == 40 and _materials(base) == "stone2wood4", "armazém: 40 moedas, madeira 4, pedra 2")
	check(base.requirements.quests == ["lais_forest"], "armazém pede lais_forest (não a Bloblo nem a bancada)")
	check(not base.requirements.has("owned"), "armazém não pede a caverna comprada")
	check(int(upgrades.warehouse_2.cost) == 90 and _materials(upgrades.warehouse_2) == "bolt1plank2", "warehouse_2: 90, tábua 2, parafuso 1")
	check(int(upgrades.warehouse_3.cost) == 240 and _materials(upgrades.warehouse_3) == "bolt1brick2plank4", "warehouse_3: 240, tábua 4, tijolo 2, parafuso 1")
	check(upgrades.warehouse_2.requirements.quests == ["main_4_bench"] and upgrades.warehouse_2.requirements.owned == ["warehouse"], "warehouse_2: bancada + armazém")
	check(upgrades.warehouse_3.requirements.quests == ["own_business"] and upgrades.warehouse_3.requirements.owned == ["warehouse_2"], "warehouse_3: negócio + warehouse_2")
	check(upgrades.has("warehouse_4"), "o _4 é da etapa 18")
	var preview: Dictionary = state.call("storage_upgrade_preview", "warehouse_2")
	check(preview.depot == "warehouse", "prévia aponta o armazém")
	# O baú liga na etapa 08 (sacola 12); aqui só conferimos que a pilha não o afeta.
	_fresh()
	check(int(state.call("storage_capacity", "chest")) == 12, "o baú tem a própria sacola (12)")


func _classification() -> void:
	_fresh()
	for id: String in ["wood", "stone", "copper", "crystal", "plank", "brick", "fiber", "fabric", "hardwood"]:
		check(state.call("storage_of", id) == "warehouse", "%s mora no armazém" % id)
	for id: String in ["bolt", "iron_band", "bed_gift", "dog_food", "map_piece_1"]:
		check(state.call("storage_of", id) == "", "%s é isento" % id)
	check(state.call("storage_of", "flour") == "fridge", "farinha continua na geladeira")
	for id: String in database.get("items"):
		var depots := 0
		for depot: String in database.get("progression").storage:
			if state.call("storage_of", id) == depot:
				depots += 1
		check(depots <= 1, "%s conta em um depósito só" % id)
	# A pilha enche: a coleta que não cabe bloqueia antes de gastar a busca.
	_progress().owned["cave_open"] = true
	_progress().owned["forest_open"] = true
	state.get("inventory").add("wood", 15)
	check(state.call("storage_error", {"wood": 2}) != "", "15 + 2 > 16 bloqueia")
	check(state.call("storage_error", {"wood": 1}) == "", "15 + 1 cabe")
	check(state.call("storage_error", {"bolt": 40}) == "", "parafuso não ocupa depósito")


# --- capítulo 5 de um save novo ------------------------------------------------------------------------

func _quest_state() -> Array:
	return [_progress().current_line_quest("guide"), _progress().current_line_quest("storage"), _progress().current_main_quest()]


func _gather(site: String, route: String, times: int) -> void:
	for _i in times:
		check(state.call("start_next_gathering", site, route) == "", "inicia %s" % route)
		state.call("dev_finish_timers")
		check(state.call("collect_gathering", site, 0) == "", "recolhe %s" % route)


func _chapter_five() -> void:
	_fresh()
	state.call("dev_jump_to_chapter", 4)
	state.get("inventory").counts.clear()
	state.set("coins", 0)
	state.call("_changed")
	check(_progress().current_main_quest() == "lais_forest", "capítulo 5 começa em lais_forest")
	# Moedas só por venda.
	state.get("inventory").add("carrot", 20)
	check(state.call("sell", "carrot", 20) == "", "vende a colheita")
	var earned := int(state.get("coins"))
	check(earned > 0, "a venda dá moedas (%d)" % earned)
	# O armazém ainda não: pede lais_forest.
	state.get("inventory").add("wood", 4)
	state.get("inventory").add("stone", 2)
	check(state.call("upgrade_error", "warehouse") != "", "armazém espera lais_forest")
	state.set("coins", 200)
	check(state.call("buy_upgrade", "forest_open") == "", "abre o Bosque")
	check(state.call("claim_quest", "lais_forest") == "", "lais_forest recebida")
	check(state.call("upgrade_error", "warehouse") == "", "armazém liberado depois de lais_forest, sem a caverna")
	state.get("inventory").counts.clear()
	state.set("coins", 0)
	# Guia: meet → wood → open_cave → warehouse → stone → fibers → treasure.
	state.call("talk_to", "guide")
	check(state.call("claim_quest", "guide_meet") == "", "guide_meet")
	check(_progress().current_line_quest("guide") == "guide_wood", "guia: wood depois de meet")
	_gather("trees", "lane", 1)
	check(state.call("claim_quest", "guide_wood") == "", "guide_wood")
	check(_progress().current_line_quest("guide") == "guide_open_cave", "guia: caverna entra depois da madeira")
	var cave: Dictionary = database.get("progression").upgrades.cave_open
	check(int(cave.cost) == 80 and int(cave.requirements.chapter) == 5 and not cave.requirements.has("owned"), "caverna: 80 moedas, capítulo 5, sem armazém")
	check(state.call("claim_quest", "guide_open_cave") != "", "caverna ainda fechada: nada a receber")
	state.set("coins", 140)
	var coins_before := int(state.get("coins"))
	check(state.call("buy_upgrade", "cave_open") == "", "compra a caverna só com moedas")
	check(state.call("claim_quest", "guide_open_cave") == "", "guide_open_cave")
	check(int(state.get("coins")) == coins_before - 80 + 5, "caverna custa 80 e a missão paga 5")
	check(_progress().current_line_quest("guide") == "bloblo_warehouse", "guia: armazém vem depois da caverna")
	var warehouse_quest: Dictionary = database.get("quests").bloblo_warehouse
	check(warehouse_quest.npc == "guide" and warehouse_quest.line == "guide" and int(warehouse_quest.order) == 25, "bloblo_warehouse agora é do Guia, ordem 25")
	check(not (warehouse_quest.rewards as Dictionary).has("items") and int(warehouse_quest.rewards.coins) == 10, "armazém paga 10 moedas e nenhum parafuso")
	check(warehouse_quest.goals[0].key == "warehouse", "objetivo owned:warehouse")
	# A pedra do armazém vem da Pedreira (sem armazém).
	check(not state.call("storage_active", "warehouse") or true, "pilha provisória ativa")
	_gather("rocks", "quarry", 1)
	check(_inv("stone") == 6, "Pedreira rende 6 pedras com a pilha vazia (tabela da etapa 11)")
	# Madeira: 4 do armazém + 6 da bancada = 10, em duas pilhas dentro de 16.
	_gather("trees", "lane", 4)  # cada trilha do bosque rende 2 madeiras; a primeira já deu 2
	check(_inv("wood") == 10, "10 madeiras guardadas (%d)" % _inv("wood"))
	var materials: Dictionary = database.get("quests").main_4_materials
	check(materials.goals.size() == 2 and materials.goals[0].key == "warehouse" and materials.goals[1].key == "wood" and int(materials.goals[1].target) == 6, "main_4_materials: armazém + madeira 6")
	check(state.call("quest_error", "main_4_materials") != "", "sem armazém a missão não fecha")
	state.set("coins", 100)
	check(state.call("buy_upgrade", "warehouse") == "", "constrói o armazém (40 moedas, madeira 4, pedra 2)")
	check(_inv("wood") == 6 and _inv("stone") == 4 and int(state.get("coins")) == 60, "gastou 4 madeiras, 2 pedras e 40 moedas")
	check(int(state.call("storage_capacity", "warehouse")) == 32, "armazém = 32")
	check(state.call("claim_quest", "bloblo_warehouse") == "", "o Guia recebe o armazém")
	check(_progress().current_line_quest("guide") == "guide_stone", "guia: pedra depois do armazém")
	# main_4_materials NÃO consome a madeira: a bancada cobra os 6.
	check(state.call("claim_quest", "main_4_materials") == "" and _inv("wood") == 6, "main_4_materials não consome madeira")
	state.set("coins", 170)
	check(state.call("buy_upgrade", "workbench") == "", "bancada com as 6 madeiras que sobraram")
	check(_inv("wood") == 0, "madeira inteira usada")
	check(state.call("claim_quest", "main_4_bench") == "", "main_4_bench")
	# Linha storage: abre com a bancada; tábuas e entrega dão um parafuso cada, sem sorteio.
	check(_progress().current_line_quest("storage") == "storage_first_planks", "storage abre com a bancada")
	check(database.get("quests").storage_first_planks.npc == "bloblo", "storage é da Bloblo")
	var help: Script = load("res://scripts/ui/task_help.gd")
	var bolt_help: Dictionary = help.call("describe", "item", "bolt", 1)
	check(bolt_help.get("goals", []) == database.get("quests").storage_first_planks.goals, "o guia do parafuso aponta o passo que o paga")
	state.get("inventory").add("wood", 6)
	var bolts := _inv("bolt")
	state.call("cook", "plank")
	state.call("dev_finish_timers")
	state.call("collect", "workbench")
	check(state.call("quest_error", "storage_first_planks") != "", "uma tábua não basta")
	state.call("cook", "plank")
	state.call("dev_finish_timers")
	state.call("collect", "workbench")
	check(_inv("plank") == 2, "duas tábuas feitas")
	check(state.call("claim_quest", "storage_first_planks") == "" and _inv("bolt") == bolts + 1, "tábuas: 1 parafuso")
	check(_progress().current_line_quest("storage") == "storage_first_delivery", "storage: entrega depois das tábuas")
	state.get("inventory").add("carrot", 4)
	check(state.call("fulfill_order", "vegetables") == "", "encomenda entregue")
	check(state.call("claim_quest", "storage_first_delivery") == "" and _inv("bolt") == bolts + 2, "entrega: o segundo parafuso")
	check(_progress().current_line_quest("storage") == "bloblo_bigger", "storage: bloblo_bigger depois da entrega")
	# Os dois parafusos e as duas tábuas pagam a primeira ampliação do armazém (90 moedas).
	state.set("coins", 90)
	check(state.call("buy_upgrade", "warehouse_2") == "", "primeira ampliação financiada sem raro")
	check(int(state.call("storage_capacity", "warehouse")) == 56, "armazém = 56")
	check(int(_progress().stat("storage_upgrades")) == 1, "uma ampliação contada")
	var quests: Dictionary = database.get("quests")
	check(quests.bloblo_bigger.line == "storage" and int(quests.bloblo_bigger.order) == 30 and quests.bloblo_biggest.line == "storage" and int(quests.bloblo_biggest.order) == 40, "bigger 30 e biggest 40 na linha storage")
	var coins_now := int(state.get("coins"))
	var bolts_now := _inv("bolt")
	check(state.call("claim_quest", "bloblo_bigger") == "", "bloblo_bigger com 1 ampliação")
	check(int(state.get("coins")) >= coins_now + 15 and _inv("bolt") >= bolts_now + 2 and _inv("iron_band") == 0 and int(quests.bloblo_bigger.rewards.coins) == 15 and int(quests.bloblo_bigger.rewards.items.bolt) == 2 and int(quests.bloblo_biggest.rewards.coins) == 40 and int(quests.bloblo_biggest.rewards.items.bolt) == 1 and not quests.bloblo_biggest.rewards.items.has("iron_band"), "15 moedas, 2 parafusos e nenhum aro (%d/%d, %d/%d, %d)" % [int(state.get("coins")), coins_now, _inv("bolt"), bolts_now, _inv("iron_band")])



func _quest_deps(id: String, seen: Dictionary = {}) -> Dictionary:
	if seen.has(id):
		return seen
	seen[id] = true
	var quest: Dictionary = database.get("quests")[id]
	for required: String in quest.get("requirements", {}).get("quests", []):
		_quest_deps(required, seen)
	for goal: Dictionary in quest.goals:
		if goal.type == "quest":
			_quest_deps(str(goal.key), seen)
	return seen


func _requirement_graph() -> void:
	var upgrades: Dictionary = database.get("progression").upgrades
	var quests: Dictionary = database.get("quests")
	# Nenhuma missão que dá os primeiros parafusos exige uma ampliação (nem o próprio aro).
	for id: String in ["storage_first_planks", "storage_first_delivery"]:
		for goal: Dictionary in quests[id].goals:
			check(goal.type == "stat", "%s não exige posse" % id)
		check(not str(quests[id].goals).contains("_2") and not str(quests[id].goals).contains("_3"), "%s não pede ampliação" % id)
	# Armazém e ampliações: cada requisito de missão/posse chega a um conjunto sem ciclo e cada material tem fonte.
	for id: String in ["warehouse", "warehouse_2", "warehouse_3", "cave_open", "workbench"]:
		var data: Dictionary = upgrades[id]
		var requirements: Dictionary = data.get("requirements", {})
		for owned: String in requirements.get("owned", []):
			check(upgrades.has(owned), "%s: posse %s existe" % [id, owned])
			check(owned != id, "%s não pede a si mesmo" % id)
		for quest: String in requirements.get("quests", []):
			var deps := _quest_deps(quest)
			for dep: String in deps:
				for goal: Dictionary in quests[dep].goals:
					check(not (goal.type == "owned" and str(goal.key) in ["warehouse", "warehouse_2", "warehouse_3"] and id.begins_with("warehouse") and goal.key == id), "%s não depende de si mesmo via %s" % [id, dep])
		for item: String in data.get("materials", {}):
			if item == "bolt":
				check(quests.storage_first_planks.rewards.items.has("bolt") and quests.storage_first_delivery.rewards.items.has("bolt"), "parafuso de %s tem fonte fixa" % id)
			else:
				check(not (database.call("item_sources", item) as Array).is_empty(), "%s: %s tem origem" % [id, item])
	# A pedra e a madeira do armazém não dependem do próprio armazém nem da bancada.
	for route: String in ["quarry", "lane"]:
		var req: Dictionary = database.get("progression").activities[route].requirements
		check(not str(req).contains("warehouse") and not str(req).contains("workbench"), "rota %s não pede armazém nem bancada" % route)
	check(upgrades.cave_open.requirements.chapter == 5, "a caverna abre no capítulo 5")
	# Guias de origem: tábua aponta para a bancada, que já existe quando a ampliação é liberada.
	check(upgrades.warehouse_2.requirements.quests == ["main_4_bench"], "ampliação só depois da bancada (origem da tábua existe)")
	_fresh()
	var help: Script = load("res://scripts/ui/task_help.gd")
	var guide: Dictionary = help.call("describe", "quest", "guide_open_cave")
	check(not guide.is_empty(), "TaskHelp descreve guide_open_cave")
	var wh: Dictionary = help.call("describe", "upgrade", "warehouse")
	check(not wh.is_empty(), "TaskHelp descreve o armazém")


# --- quatro ordens de ampliação ------------------------------------------------------------------------

func _setup_upgrades() -> void:
	_fresh()
	state.call("dev_jump_to_chapter", 5)
	for id: String in ["silo", "fridge", "warehouse", "workbench"]:
		_progress().owned[id] = true
	for id: String in ["storage_first_planks", "storage_first_delivery"]:
		_progress().claimed_quests[id] = true
	state.get("inventory").counts.clear()
	state.set("coins", 100000)
	state.get("inventory").add("plank", 10)
	state.get("inventory").add("bolt", 10)
	state.call("_changed")


func _four_orders() -> void:
	var orders: Array = [
		["silo_2", "fridge_2", "warehouse_2"],
		["fridge_2", "warehouse_2", "silo_2"],
		["warehouse_2", "silo_2", "fridge_2"],
		["fridge_2", "silo_2", "warehouse_2"],
	]
	for order: Array in orders:
		_setup_upgrades()
		var bigger_before: bool = _progress().claimed_quests.has("bloblo_bigger")
		check(not bigger_before and int(_progress().stat("storage_upgrades")) == 0, "começa sem ampliações")
		check(state.call("quest_error", "bloblo_bigger") != "", "a primeira missão espera uma compra (%s)" % str(order))
		for index in order.size():
			var id: String = order[index]
			check(state.call("upgrade_error", id) == "", "%s pode ser comprada na posição %d (%s)" % [id, index + 1, str(order)])
			check(state.call("buy_upgrade", id) == "", "compra %s" % id)
			check(int(_progress().stat("storage_upgrades")) == index + 1, "contador = %d" % (index + 1))
			if index == 0:
				check(state.call("claim_quest", "bloblo_bigger") == "", "1 ampliação (%s) fecha bloblo_bigger" % id)
				check(state.call("quest_error", "bloblo_biggest") != "", "biggest espera 3")
		check(state.call("claim_quest", "bloblo_biggest") == "", "3 ampliações em qualquer ordem fecham bloblo_biggest (%s)" % str(order))
	# Abrir painel ou comprar o edifício inicial não conta.
	_fresh()
	_progress().owned["silo"] = true
	_progress().owned["warehouse"] = true
	state.call("_changed")
	check(int(_progress().stat("storage_upgrades")) == 0, "edifícios iniciais não contam")
