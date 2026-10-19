extends SceneTree
## Etapa 18 do plano de economia: ampliações _4/_5, filas novas e maestria das estações.
## Cobre: totais exatos 128/176, 88/120, 128/176, 88/120 somando só diferenças, custos/requisitos da tabela 02 A,
## cada ampliação exige a anterior, piso legado sem bônus em dobro (recarregar não muda), estoque acima do limite
## continua vendável, filas stove_queue_3/mill_queue/dairy_queue/atelier_queue (só vaga, sem velocidade),
## maestria (12/40/100 lotes, variedade min(meta, catálogo), um lote de 3 unidades = 1, repetir coleta não conta,
## moinho com uma receita, receita nova não apaga selo, prêmios 10/20/30 uma vez, semeadura mínima de saves antigos).
## --headless --path game -s res://tests/expansion_test.gd

const T0 := 1791936000.0

const TOTALS := {
	"silo": [32, 56, 88, 128, 176], "fridge": [24, 40, 64, 88, 120],
	"warehouse": [32, 56, 88, 128, 176], "chest": [24, 40, 64, 88, 120],
}
const COSTS := {
	"silo_4": [550, "brick4iron_band1plank6"], "silo_5": [1000, "brick6iron_band2plank8"],
	"fridge_4": [500, "brick3iron_band1plank5"], "fridge_5": [900, "brick4iron_band2plank6"],
	"warehouse_4": [500, "brick3iron_band1plank6"], "warehouse_5": [900, "brick5iron_band2plank8"],
	"chest_4": [400, "fabric2iron_band1plank4"], "chest_5": [750, "fabric3iron_band2plank5"],
}

var failures := 0
var state: Node
var db: Node


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("EXPANSION: " + message)


func _p() -> RefCounted:
	return state.get("progress")


func _eco() -> RefCounted:
	return state.get("economy")


func _station(id: String) -> RefCounted:
	return state.call("station", id)


func _materials(upgrade: Dictionary) -> String:
	var keys: Array = (upgrade.get("materials", {}) as Dictionary).keys()
	keys.sort()
	var text := ""
	for key: String in keys:
		text += "%s%d" % [key, int(upgrade.materials[key])]
	return text


func _fresh() -> void:
	state.set("test_time", T0)
	state.set("unlimited_storage", false)
	state.call("reset")
	state.get("inventory").counts.clear()
	state.set("coins", 0)


## Põe um lote pronto na fila da estação e recolhe (o caminho real de `collect`). Esvazia o estoque antes.
func _finish(station_id: String, recipe_id: String, qty: int = -1) -> Dictionary:
	state.get("inventory").counts.clear()
	var entry := {"recipe": recipe_id, "ready_at": T0 - 10.0}
	if qty > 0:
		entry["qty"] = qty
	_station(station_id).queue.append(entry)
	return state.call("collect", station_id)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/friend_clock.gd"))
	_totals_and_data()
	_chain_and_buy()
	_legacy_floor_and_excess()
	_queues()
	_mastery_counting()
	_mastery_variety()
	_mastery_reload_and_seed()
	_mastery_ui()
	print("EXPANSION TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# --- totais, custos e requisitos -----------------------------------------------------------------------

func _totals_and_data() -> void:
	_fresh()
	var upgrades: Dictionary = db.get("progression").upgrades
	for depot: String in TOTALS:
		var levels: Array = db.get("progression").storage[depot].levels
		check(levels.size() == 4, "%s: quatro ampliações (_2.._5)" % depot)
		_p().owned[str(db.get("progression").storage[depot].building)] = true
		var running := int(TOTALS[depot][0])
		check(int(state.call("storage_capacity", depot)) == running, "%s construído = %d" % [depot, running])
		for index in levels.size():
			var id: String = levels[index]
			check(upgrades.has(id), id + " existe")
			_p().owned[id] = true
			var want := int(TOTALS[depot][index + 1])
			check(int(state.call("storage_capacity", depot)) == want, "%s = %d (soma de diferenças)" % [id, want])
			check(int(upgrades[id].storage_capacity) == want - running, "%s soma só %d" % [id, want - running])
			running = want
	for id: String in COSTS:
		check(int(upgrades[id].cost) == int(COSTS[id][0]) and _materials(upgrades[id]) == str(COSTS[id][1]), "%s: custo/material da tabela 02 A (%s)" % [id, _materials(upgrades[id])])
		var number := int(id.get_slice("_", 1))
		var previous := "%s_%d" % [id.get_slice("_", 0), number - 1]
		check(previous in upgrades[id].requirements.owned, id + " exige " + previous)
		if number == 4:
			check(upgrades[id].requirements.quests == ["atelier_open"], id + " exige atelier_open")
		else:
			check(int(upgrades[id].requirements.stats.contracts) == 12, id + " exige 12 contratos")


func _contract_order() -> String:
	for id: String in db.get("progression").orders:
		if str(db.get("progression").orders[id].get("channel", "neighbors")) == "contracts":
			return id
	return ""


func _chain_and_buy() -> void:
	_fresh()
	_p().owned["silo"] = true
	_p().owned["silo_2"] = true
	_p().owned["silo_3"] = true
	state.set("coins", 5000)
	for item: String in ["plank", "brick", "iron_band", "fabric"]:
		state.get("inventory").counts[item] = 20
	_p().claimed_quests["atelier_open"] = true
	check(state.call("upgrade_error", "silo_5") != "", "silo_5 não pula o _4")
	check(state.call("upgrade_error", "silo_4") == "", "silo_4 liberado após atelier_open: " + str(state.call("upgrade_error", "silo_4")))
	# Sem o ateliê aberto o _4 fica fechado, mesmo com tudo o mais.
	_p().claimed_quests.erase("atelier_open")
	check(state.call("upgrade_error", "silo_4") != "", "silo_4 pede atelier_open")
	_p().claimed_quests["atelier_open"] = true
	check(state.call("buy_upgrade", "silo_4") == "", "comprar silo_4")
	check(int(state.call("storage_capacity", "silo")) == 128, "silo = 128 depois da compra")
	check(int(state.get("coins")) == 5000 - 550 and int(state.get("inventory").count("iron_band")) == 19, "gastou 550 moedas e 1 aro")
	check(state.call("upgrade_error", "silo_5") != "", "silo_5 pede 12 contratos")
	var order := _contract_order()
	check(order != "", "existe encomenda de contrato")
	_p().stats["order:" + order] = 12
	state.call("_changed")
	check(int(_p().stat("contracts")) == 12, "contador de contratos derivado")
	check(state.call("upgrade_error", "silo_5") == "", "silo_5 liberado com 12 contratos: " + str(state.call("upgrade_error", "silo_5")))
	check(state.call("buy_upgrade", "silo_5") == "", "comprar silo_5")
	check(int(state.call("storage_capacity", "silo")) == 176, "silo = 176")
	check(int(_p().stat("storage_upgrades")) == 4, "ampliações _2.._5 contam 4")


func _legacy_floor_and_excess() -> void:
	_fresh()
	_p().owned["silo"] = true
	_p().owned["silo_2"] = true
	_p().owned["silo_3"] = true
	state.get("economy").raise_floor("silo", 300)  # save antigo com 300 comprados
	check(int(state.call("storage_capacity", "silo")) == 300, "piso legado vale 300")
	_p().owned["silo_4"] = true
	_p().owned["silo_5"] = true
	check(int(state.call("storage_capacity", "silo")) == 300, "_4/_5 não somam ao piso (max, não soma)")
	var dumped: Dictionary = state.call("to_dict")
	state.call("from_dict", dumped)
	check(int(state.call("storage_capacity", "silo")) == 300 and int(state.call("storage_floor", "silo")) == 300, "recarregar não aplica o piso de novo")
	state.call("from_dict", state.call("to_dict"))
	check(int(state.call("storage_capacity", "silo")) == 300, "duas recargas: mesma capacidade")
	# Estoque acima do limite: consumir e vender continuam livres.
	_fresh()
	state.get("inventory").counts["carrot"] = 40
	check(int(state.call("storage_excess", "silo")) == 24, "excesso = 40 − 16")
	check(state.call("sell", "carrot", 5) == "", "vender com excesso funciona")
	check(int(state.get("inventory").count("carrot")) == 35, "estoque caiu para 35")


# --- filas ---------------------------------------------------------------------------------------------

func _queues() -> void:
	_fresh()
	var upgrades: Dictionary = db.get("progression").upgrades
	var want := {
		"stove_queue_3": [500, "bolt1plank4"], "mill_queue": [250, "plank3"],
		"dairy_queue": [350, "brick2plank3"], "atelier_queue": [450, "fabric1plank4"],
	}
	for id: String in want:
		check(int(upgrades[id].cost) == int(want[id][0]) and _materials(upgrades[id]) == str(want[id][1]), "%s: custo e material" % id)
		check(not upgrades[id].has("storage_capacity"), id + " só dá vaga")
	check(upgrades.stove_queue_3.requirements.owned == ["stove_queue_2"] and upgrades.stove_queue_3.requirements.quests == ["own_business"], "stove_queue_3 exige a fila 2 e own_business")
	check(upgrades.mill_queue.requirements.owned == ["mill"] and upgrades.dairy_queue.requirements.owned == ["dairy"] and upgrades.atelier_queue.requirements.owned == ["atelier"], "filas exigem a própria estação")
	for id: String in want:
		check(not (upgrades[id].requirements.has("stats") or upgrades[id].requirements.has("skills")), id + " não obriga maestria")
	# Vagas: base + compras (nada de velocidade ou rendimento junto).
	var seconds_before := {}
	for rid: String in ["carrot_snack", "flour", "cheese", "fabric"]:
		seconds_before[rid] = int(db.get("recipes")[rid].seconds)
	var base := {"stove": 1, "mill": 2, "dairy": 2, "atelier": 2}
	for station_id: String in base:
		check(int(state.call("station_slots", station_id)) == int(base[station_id]), "%s: vagas iniciais %d" % [station_id, base[station_id]])
	_p().owned["stove_queue"] = true
	_p().owned["stove_queue_2"] = true
	_p().owned["stove_queue_3"] = true
	check(int(state.call("station_slots", "stove")) == 4, "fogão 4 vagas")
	for pair: Array in [["mill", "mill_queue"], ["dairy", "dairy_queue"], ["atelier", "atelier_queue"]]:
		_p().owned[pair[1]] = true
		check(int(state.call("station_slots", pair[0])) == 3, "%s: 3 vagas" % pair[0])
	check(state.call("pending_slot_upgrades", "stove").is_empty() and state.call("pending_slot_upgrades", "mill").is_empty(), "nada pendente depois das compras")
	for rid: String in seconds_before:
		check(int(db.get("recipes")[rid].seconds) == int(seconds_before[rid]), "tempo de %s não mudou" % rid)
	check(int(db.get("recipes").flour.qty) == 2 and int(db.get("recipes").cheese.qty) == 1, "rendimentos intactos")
	# Compra de verdade: o jogo cobra e libera a vaga.
	_fresh()
	_p().owned["mill"] = true
	state.set("coins", 400)
	state.get("inventory").counts["plank"] = 3
	check(state.call("buy_upgrade", "mill_queue") == "", "comprar mill_queue")
	check(int(state.call("station_slots", "mill")) == 3 and int(state.get("coins")) == 150, "moinho 3 vagas, 250 moedas")
	_fresh()
	check(state.call("upgrade_error", "mill_queue") != "" and state.call("upgrade_error", "stove_queue_3") != "", "sem a estação/fila anterior não compra")
	var rooms_ok := true
	for place_id: String in ["stove", "mill", "dairy", "atelier", "silo", "fridge", "chest", "warehouse"]:
		var found := false
		for world: Dictionary in db.get("worlds").values():
			if world.get("places", {}).has(place_id):
				found = true
		rooms_ok = rooms_ok and found
	check(rooms_ok, "lugares das ampliações existem nos mundos")


# --- maestria ------------------------------------------------------------------------------------------

func _mastery_counting() -> void:
	_fresh()
	check(_eco().mastery_method == "r1", "jogo novo conta lote a lote")
	_p().owned["workbench"] = true
	var got := _finish("workbench", "hardwood_planks", 3)
	check(int(got.get("hardwood", 0)) == 3 or got.size() == 1, "o lote entregou 3 unidades")
	check(int(_p().stat("station_jobs:workbench")) == 1, "saída de 3 unidades = 1 lote")
	check(int(_p().stat("station_recipe_jobs:workbench:hardwood_planks")) == 1, "contador por receita")
	var again: Dictionary = state.call("collect", "workbench")
	check(again.is_empty() and int(_p().stat("station_jobs:workbench")) == 1, "repetir a coleta não conta")
	# Lote que não cabe: continua na fila e NÃO conta até ser recolhido.
	state.get("inventory").counts["wood"] = 16  # armazém provisório cheio
	_station("workbench").queue.append({"recipe": "plank", "ready_at": T0 - 10.0})
	state.call("collect", "workbench")
	check(int(_p().stat("station_jobs:workbench")) == 1 and _station("workbench").queue.size() == 1, "lote bloqueado fica na fila sem contar")
	state.get("inventory").counts.clear()
	state.call("collect", "workbench")
	check(int(_p().stat("station_jobs:workbench")) == 2, "contou quando foi recolhido")
	# Estações fora da maestria não criam contadores.
	check(not state.call("mastery_enabled", "sewing") and not state.call("mastery_enabled", "chicken_coop"), "costura e animais ficam de fora")
	# Moinho: uma receita só alcança os três selos. Controle: as mesmas 100 coletas sem maestria (níveis também pagam moedas).
	var mastery: Dictionary = db.get("progression").mastery
	var stations: Array = mastery.stations
	mastery["stations"] = []
	_fresh()
	_p().owned["mill"] = true
	for n in 100:
		_finish("mill", "flour")
	var control := int(state.get("coins"))
	mastery["stations"] = stations
	_fresh()
	_p().owned["mill"] = true
	for n in 100:
		_finish("mill", "flour")
		var jobs := n + 1
		var want := 0
		if jobs >= 100:
			want = 3
		elif jobs >= 40:
			want = 2
		elif jobs >= 12:
			want = 1
		check(int(state.call("mastery_level", "mill")) == want, "moinho com %d lotes = selo %d" % [jobs, want])
	var paid := int(state.get("coins")) - control
	check(paid == 60, "10 + 20 + 30 moedas de maestria (%d)" % paid)
	check(_eco().granted.has("mastery:mill:1") and _eco().granted.has("mastery:mill:2") and _eco().granted.has("mastery:mill:3"), "ids persistentes dos três selos")
	var granted_n: int = _eco().granted.size()
	_finish("mill", "flour")
	check(_eco().granted.size() == granted_n and not _eco().granted.has("mastery:mill:4"), "nada novo é pago")
	check(int(state.call("mastery_kinds_needed", "mill", 2)) == 1, "variedade do moinho = min(4, 1) = 1")


func _mastery_variety() -> void:
	_fresh()
	_p().owned["stove"] = true
	_p().owned["fridge"] = true
	var catalog := int(state.call("mastery_catalog_size", "stove"))
	check(catalog >= 2, "fogão tem catálogo de ao menos 2 (%d)" % catalog)
	for n in 12:
		_finish("stove", "carrot_snack")
	check(int(state.call("mastery_jobs", "stove")) == 12 and int(state.call("mastery_level", "stove")) == 0, "12 lotes da mesma receita não bastam (variedade 2)")
	check(not _eco().granted.has("mastery:stove:1"), "sem prêmio ainda")
	var coins := int(state.get("coins"))
	_finish("stove", "vegetable_soup")
	check(int(state.call("mastery_level", "stove")) == 1 and int(state.get("coins")) - coins == 10, "segunda receita fecha o selo 1 (+10)")
	# Receita nova no catálogo (desbloqueio) não apaga o selo recebido.
	for quest: String in ["bloblo_pumpkin", "bloblo_potato", "bloblo_sweet_potato"]:
		_p().claimed_quests[quest] = true
	_p().owned["workbench"] = true
	check(int(state.call("mastery_catalog_size", "stove")) > catalog, "catálogo cresceu")
	check(int(state.call("mastery_level", "stove")) == 1, "selo continua depois de abrir receitas")
	# Bronze exige 2; prata exige min(3, catálogo) e ouro min(4, catálogo).
	check(int(state.call("mastery_kinds_needed", "stove", 0)) == 2 and int(state.call("mastery_kinds_needed", "stove", 1)) == 3 and int(state.call("mastery_kinds_needed", "stove", 2)) == 4, "variedade 2/3/4 com catálogo grande")
	# Costura de coleção não conta.
	_fresh()
	_p().owned["sewing_table"] = true
	check(int(_p().stat("station_jobs:sewing")) == 0, "costura sem contador de maestria")


func _mastery_reload_and_seed() -> void:
	_fresh()
	_p().owned["mill"] = true
	for n in 12:
		_finish("mill", "flour")
	var coins := int(state.get("coins"))
	state.call("from_dict", state.call("to_dict"))
	check(int(_p().stat("station_jobs:mill")) == 12 and int(state.call("mastery_level", "mill")) == 1, "recarregar conserva contador e selo")
	check(int(state.get("coins")) == coins and _eco().mastery_method == "r1", "recarregar não paga nem muda o método")
	# Save antigo: sem contadores de lote; só o histórico de unidades.
	var old: Dictionary = state.call("to_dict")
	old.progression.stats = {"produce:plank": 125, "produce:stick": 10, "produce:flour": 31, "produce:carrot_snack": 7}
	old.economy.erase("mastery_method")
	old.economy.granted = {}
	state.call("from_dict", old)
	check(_eco().mastery_method == "min_units_v1", "método do histórico registrado")
	check(int(_p().stat("station_jobs:workbench")) == 47, "tábua compartilhada: 125 unidades ÷ 3 = no mínimo 42 lotes (+5 de gravetos), não 125")
	check(int(_p().stat("station_recipe_jobs:workbench:plank")) == 0 and int(_p().stat("station_recipe_jobs:workbench:hardwood_planks")) == 0, "saída ambígua: variedade da receita fica em 0")
	check(int(_p().stat("station_recipe_jobs:workbench:cut_sticks")) == 5, "10 gravetos de saída 2 = 5 lotes")
	check(int(_p().stat("station_recipe_jobs:mill:flour")) == 16, "31 farinhas de saída 2 = 16 lotes")
	check(int(_p().stat("station_recipe_jobs:stove:carrot_snack")) == 7, "petisco rende 1")
	check(int(_p().stat("produce:plank")) == 125, "histórico antigo permanece")
	check(_eco().legacy.has("mastery") and str(_eco().legacy.mastery.method) == "min_units_v1", "método gravado em economy.legacy")
	var coins_before := int(state.get("coins"))
	check(not _eco().granted.has("mastery:mill:1"), "semeadura não paga selo")
	# O selo atingido pelo histórico sai no próximo lote recolhido.
	_finish("mill", "flour")
	check(_eco().granted.has("mastery:mill:1") and int(state.get("coins")) == coins_before + 10, "bronze do moinho pago no próximo lote")
	state.call("from_dict", state.call("to_dict"))
	check(_eco().mastery_method == "min_units_v1" and int(_p().stat("station_jobs:mill")) == 17, "semeadura acontece uma única vez")


func _mastery_ui() -> void:
	_fresh()
	_p().owned["stove"] = true
	var builder: GDScript = load("res://scripts/ui/sheet_builder.gd")
	var text: String = builder.call("mastery_text", "stove")
	check(text.begins_with("0/12 lotes"), "medidor: " + text)
	var row: Control = builder.call("mastery_row", "stove")
	check(row.visible and row.find_child("MasteryText", true, false) != null and row.find_child("MasterySeals", true, false).get_child_count() == 3, "linha do medidor tem três selos e texto")
	var help: Control = builder.call("mastery_help", "stove")
	check(help.find_child("Tier_1", true, false) != null and help.find_child("Tier_3", true, false) != null, "ajuda lista os três patamares")
	var hidden: Control = builder.call("mastery_row", "mill")
	check(not hidden.visible, "estação não comprada não mostra o medidor")
	row.free()
	help.free()
	hidden.free()
