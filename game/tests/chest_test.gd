extends SceneTree
## Etapa 08 do plano de economia: o baú junto dos passeios (Sacola de passeio → Baú → _2 → _3).
## Cobre: capacidades 12/24/40/64, custos e requisitos, os 11 materiais de trilha e os produtos no baú, isentos,
## primeiro passeio de um save novo (2 gravetos sem sorteio), garantia da rota inicial para saves antigos,
## baú construído com gravetos, linha da Nina, bagagem acima do espaço (parcelas, recarga, Tiro presente),
## grafo de requisitos e a medição de bloqueio por estoque (build/economy/etapa_08/bloqueio.md).
## --headless --path game -s res://tests/chest_test.gd

const T0 := 1791936000.0
const TRAIL: Array[String] = ["stick", "ribbon", "wildflower", "color_button", "yarn", "smooth_pebble", "river_shell", "wild_mint", "bird_feather", "golden_leaf", "moon_pebble"]

var failures := 0
var state: Node
var db: Node


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("CHEST: " + message)


func _p() -> RefCounted:
	return state.get("progress")


func _inv(id: String) -> int:
	return int(state.get("inventory").count(id))


func _walk() -> RefCounted:
	return state.get("walk_state")


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
	state.get("dog").needs["energy"] = 100.0
	state.get("dog").updated_at = T0


func _after_nina_walk() -> void:
	_p().claimed_quests["main_2_order"] = true
	_p().claimed_quests["nina_meet"] = true


func _leave_and_return(id: String = "park_loop") -> void:
	var error: String = state.call("start_walk", id)
	check(error == "", "sai para " + id + ": " + error)
	state.set("test_time", float(state.get("test_time")) + float(db.get("walks").walks[id].seconds) + 1.0)
	state.call("return_due_walk")


func _roundtrip() -> void:
	state.call("from_dict", JSON.parse_string(JSON.stringify(state.call("to_dict"))))


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/friend_clock.gd"))
	_capacities()
	_classification()
	_first_walk()
	_repeat_walk_guarantee()
	_nina_line()
	_baggage_over_space()
	_requirement_graph()
	_block_rate()
	print("CHEST TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# --- capacidades e dados ------------------------------------------------------------------------------

func _capacities() -> void:
	_fresh()
	var preview: Dictionary = state.call("storage_upgrade_preview", "chest")
	check(preview.depot == "chest" and int(preview.from) == 12 and int(preview.to) == 24, "prévia do baú: 12 → 24 (%s)" % str(preview))
	check(bool(state.call("storage_active", "chest")), "jogo novo: a sacola já limita")
	check(int(state.call("storage_capacity", "chest")) == 12, "provisório = 12")
	check(state.call("storage_name", "chest") == "Sacola de passeio", "nome antes do baú")
	check(int(state.call("storage_floor", "chest")) == 0, "jogo novo não tem piso legado")
	_p().owned["chest"] = true
	check(int(state.call("storage_capacity", "chest")) == 24 and state.call("storage_name", "chest") == "Baú", "baú = 24 e nome novo")
	_p().owned["chest_2"] = true
	check(int(state.call("storage_capacity", "chest")) == 40, "chest_2 = 40")
	_p().owned["chest_3"] = true
	check(int(state.call("storage_capacity", "chest")) == 64, "chest_3 = 64")
	state.call("_changed")
	check(int(state.call("storage_floor", "chest")) == 0, "comprar não cria piso legado")
	var upgrades: Dictionary = db.get("progression").upgrades
	check(int(upgrades.chest_2.storage_capacity) == 16 and int(upgrades.chest_3.storage_capacity) == 24, "ampliações somam só a diferença (16 e 24)")
	var base: Dictionary = upgrades.chest
	check(int(base.cost) == 0 and _materials(base) == "stick2", "baú: sem moeda, 2 gravetos")
	check(base.requirements.quests == ["nina_walk"] and not base.requirements.has("owned"), "baú pede só nina_walk")
	check(int(upgrades.chest_2.cost) == 80 and _materials(upgrades.chest_2) == "bolt1plank2", "chest_2: 80, tábua 2, parafuso 1")
	check(int(upgrades.chest_3.cost) == 200 and _materials(upgrades.chest_3) == "bolt1fabric1plank3", "chest_3: 200, tábua 3, tecido 1, parafuso 1")
	check(upgrades.chest_2.requirements.quests == ["main_4_bench"] and upgrades.chest_2.requirements.owned == ["chest"], "chest_2: bancada + baú")
	check(upgrades.chest_3.requirements.quests == ["own_business"] and upgrades.chest_3.requirements.owned == ["chest_2", "atelier"], "chest_3: negócio + chest_2 + ateliê")
	check(not upgrades.chest_3.materials.has("iron_band"), "_3 sem aro (o aro começa no _4, etapa 18)")


func _classification() -> void:
	_fresh()
	var items: Dictionary = db.get("items")
	var trail := 0
	for id: String in items:
		if str(items[id].get("category", "")) == "trail":
			trail += 1
			check(state.call("storage_of", id) == "chest", "%s (trilha) mora no baú" % id)
	check(trail == 11 and TRAIL.size() == 11, "são 11 materiais de trilha (%d)" % trail)
	for id: String in TRAIL:
		check(items.has(id) and state.call("storage_of", id) == "chest", "%s no baú" % id)
	check(state.call("storage_of", "wild_mint") == "chest", "hortelã silvestre no baú (material de passeio)")
	for id: String in ["treat_box", "accessory_set"]:
		check(state.call("storage_of", id) == "chest", "%s mora no baú" % id)
	for id: String in ["bolt", "iron_band", "bed_gift", "dog_food", "map_piece_1", "map_piece_4"]:
		check(state.call("storage_of", id) == "", "%s é isento" % id)
	for id: String in items:
		if str(items[id].get("category", "")) in ["find", "collection", "map"]:
			check(state.call("storage_of", id) == "", "%s (achado de álbum/mapa) continua isento" % id)
	check(state.call("storage_of", "egg") == "fridge" and state.call("storage_of", "plank") == "warehouse", "outros depósitos intactos")
	var depots := {}
	for id: String in items:
		var depot := str(state.call("storage_of", id))
		if depot != "":
			depots[depot] = int(depots.get(depot, 0)) + 1
	check(depots.size() == 4, "os quatro depósitos têm itens (%s)" % str(depots))
	# Encher a sacola: 12 cabem, o 13º não.
	state.get("inventory").add("stick", 11)
	check(state.call("storage_error", {"ribbon": 1}) == "", "11 + 1 cabe")
	check(state.call("storage_error", {"ribbon": 2}) == "Sacola de passeio sem espaço", "11 + 2 bloqueia pelo nome da sacola")
	check(state.call("storage_error", {"bolt": 40, "map_piece_1": 1}) == "", "parafuso e mapa não ocupam a sacola")
	var shortage: Dictionary = state.call("storage_shortage", {"yarn": 4})
	check(shortage.depot == "chest" and int(shortage.missing) == 3, "falta real = 3 (%s)" % str(shortage))
	# Produtos prontos disputam o mesmo espaço.
	state.get("inventory").add("stick", 1)
	check(state.call("storage_error", {"treat_box": 1}) != "", "caixa de petiscos não cabe na sacola cheia")
	check(state.call("transaction_error", {"stick": 12}, {"treat_box": 1}) == "", "gastar gravetos libera lugar para o produto")
	_p().owned["chest"] = true
	check(state.call("storage_error", {"treat_box": 4}) == "", "baú construído: 12 + 4 cabe em 24")


# --- primeiro passeio de um save novo ---------------------------------------------------------------------

func _first_walk() -> void:
	_fresh()
	_after_nina_walk()
	check(_inv("stick") == 0, "começa sem gravetos")
	check(state.call("upgrade_error", "chest") != "", "baú espera nina_walk")
	_leave_and_return()
	var plan: Dictionary = state.call("walk_baggage_plan")
	check(int(state.get("walk_state").baggage_left().get("stick", 0)) >= 2, "primeira volta traz ao menos 2 gravetos")
	check(plan.blocked == "", "a primeira bagagem cabe vazia na sacola (%s)" % str(plan))
	var left: Dictionary = _walk().baggage_left().duplicate()
	var total := 0
	for item: String in left:
		if state.call("storage_of", item) == "chest":
			total += int(left[item])
	check(total <= 12, "bagagem inicial (%d) cabe nos 12" % total)
	check(not state.call("walking"), "o Tiro voltou")
	check(not state.call("claim_walk_baggage").is_empty(), "guarda a bagagem")
	check(_inv("stick") >= 2, "gravetos na mochila")
	check(state.call("claim_quest", "nina_walk") == "", "nina_walk recebida")
	check(state.call("upgrade_error", "chest") == "", "baú liberado só com 2 gravetos, sem moeda e sem madeira")
	var coins := int(state.get("coins"))
	var sticks := _inv("stick")
	check(state.call("buy_upgrade", "chest") == "", "constrói o baú")
	check(int(state.get("coins")) == coins and _inv("stick") == sticks - 2, "gastou 2 gravetos e nenhuma moeda")
	check(int(state.call("storage_capacity", "chest")) == 24, "baú = 24")
	# O primeiro passeio é determinístico: o sorteio da semente não muda a garantia.
	for seed_value in [1, 77, 123456, 987654321]:
		_fresh()
		_after_nina_walk()
		var loot: Dictionary = state.call("_roll_walk", {"id": "park_loop", "seed": seed_value})
		check(int(loot.items.get("stick", 0)) >= 2, "semente %d: primeira volta com 2 gravetos" % seed_value)


# --- voltas repetidas: a rota inicial garante os gravetos ate comprar --------------------------------------

func _only_ribbon_table() -> Dictionary:
	var def: Dictionary = db.get("walks").walks.park_loop
	var before: Dictionary = def.loot.duplicate(true)
	def.loot["table"] = [{"weight": 1, "items": {"ribbon": 1}}]
	def.loot["rolls"] = 1
	return before


func _restore_table(before: Dictionary) -> void:
	db.get("walks").walks.park_loop.loot = before


func _repeat_walk_guarantee() -> void:
	var before := _only_ribbon_table()
	# Sem baú e sem gravetos, depois da primeira volta: a próxima rota inicial traz os 2.
	_fresh()
	_after_nina_walk()
	_walk().history["park_loop"] = {"count": 5}
	var loot: Dictionary = state.call("_roll_walk", {"id": "park_loop", "seed": 42})
	check(not bool(loot.first), "não é a primeira volta")
	check(int(loot.items.get("stick", 0)) == 2, "garantia: 2 gravetos (%s)" % str(loot.items))
	# Com 1 graveto: completa até 2.
	state.get("inventory").add("stick", 1)
	loot = state.call("_roll_walk", {"id": "park_loop", "seed": 42})
	check(int(loot.items.get("stick", 0)) == 1, "com 1 graveto vem só mais 1")
	# Com 2 ou mais: não duplica.
	state.get("inventory").add("stick", 1)
	loot = state.call("_roll_walk", {"id": "park_loop", "seed": 42})
	check(int(loot.items.get("stick", 0)) == 0, "já tem 2: nada a mais")
	# Quem já comprou o baú não recebe concessão retroativa.
	_fresh()
	_after_nina_walk()
	_walk().history["park_loop"] = {"count": 5}
	_p().owned["chest"] = true
	loot = state.call("_roll_walk", {"id": "park_loop", "seed": 42})
	check(int(loot.items.get("stick", 0)) == 0, "com o baú construído a garantia encerra")
	# O mecanismo é determinístico: mesma semente, mesmo resultado.
	_fresh()
	_after_nina_walk()
	_walk().history["park_loop"] = {"count": 5}
	var a: Dictionary = state.call("_roll_walk", {"id": "park_loop", "seed": 9})
	var b: Dictionary = state.call("_roll_walk", {"id": "park_loop", "seed": 9})
	check(str(a.items) == str(b.items), "sem dado aleatório novo")
	# Fim a fim: a volta real entrega e a garantia termina quando o jogador compra.
	_fresh()
	_after_nina_walk()
	_walk().history["park_loop"] = {"count": 5}
	_leave_and_return()
	check(int(_walk().baggage_left().get("stick", 0)) == 2, "volta real traz os 2 gravetos")
	check(not state.call("claim_walk_baggage").is_empty() and _inv("stick") == 2, "guarda os 2")
	check(state.call("claim_quest", "nina_walk") == "" and state.call("buy_upgrade", "chest") == "", "compra o baú")
	_leave_and_return()
	check(int(_walk().baggage_left().get("stick", 0)) == 0, "depois da compra a rota volta ao sorteio normal")
	# Os gravetos não são vendidos sozinhos.
	check(_inv("stick") == 0, "os gravetos ficam na mochila até gastar (sem venda automática)")
	_restore_table(before)


# --- linha da Nina ---------------------------------------------------------------------------------------

func _nina_line() -> void:
	var quests: Dictionary = db.get("quests")
	var q: Dictionary = quests.bloblo_chest
	check(q.npc == "nina" and q.line == "nina" and int(q.order) == 25, "bloblo_chest é da Nina, ordem 25")
	check(int(quests.nina_walk.order) == 20 and int(quests.nina_routes.order) == 30, "entre nina_walk (20) e nina_routes (30)")
	check(q.goals[0].type == "owned" and q.goals[0].key == "chest", "objetivo owned:chest")
	check(int(q.rewards.coins) == 10 and not (q.rewards as Dictionary).has("items"), "10 moedas e nenhum parafuso")
	check(str(q.dialogue) == "Trouxe gravetos? Vamos montar um baú para as coisas dos passeios.", "fala da Nina")
	_fresh()
	_after_nina_walk()
	check(_p().current_line_quest("nina") == "nina_walk", "linha: nina_walk primeiro")
	_leave_and_return()
	check(not state.call("claim_walk_baggage").is_empty(), "guarda a bagagem da primeira volta")
	check(state.call("claim_quest", "nina_walk") == "", "nina_walk")
	check(_p().current_line_quest("nina") == "bloblo_chest", "depois dela, o baú")
	check(state.call("quest_error", "bloblo_chest") != "", "ainda sem baú")
	check(state.call("buy_upgrade", "chest") == "", "constrói")
	var coins := int(state.get("coins"))
	check(state.call("claim_quest", "bloblo_chest") == "", "recebe a missão")
	check(int(state.get("coins")) == coins + 10 and _inv("bolt") == 0, "10 moedas, sem parafuso")
	check(_p().current_line_quest("nina") == "nina_routes", "depois, nina_routes")
	# Missão já recebida; não reabre o prêmio.
	_fresh()
	_after_nina_walk()
	_p().claimed_quests["nina_walk"] = true
	_p().claimed_quests["bloblo_chest"] = true
	_p().owned["chest"] = true
	var before := int(state.get("coins"))
	check(state.call("claim_quest", "bloblo_chest") != "" and int(state.get("coins")) == before, "prêmio recebido não reabre")
	check(_p().current_line_quest("nina") == "nina_routes", "a próxima missão da Nina aparece")


# --- bagagem acima do espaço ------------------------------------------------------------------------------

func _mixed_baggage() -> void:
	_fresh()
	_after_nina_walk()
	_p().claimed_quests["nina_walk"] = true
	_walk().history["park_loop"] = {"count": 3}
	_p().stats["walk"] = 3
	state.get("inventory").add("stick", 10)
	state.get("inventory").add("ribbon", 2)
	check(int(state.call("storage_space", "chest")) == 0, "sacola 12/12")
	var table: Array = [{"weight": 1, "items": {"stick": 3, "ribbon": 2}}]
	db.get("walks").walks.park_loop.loot["table"] = table
	db.get("walks").walks.park_loop.loot["rolls"] = 1
	db.get("walks").walks.park_loop.loot.erase("guarantee")
	db.get("walks").walks.park_loop.loot["rare"] = {"chance": 0.0, "pity": 99, "collection": "plaid_bow", "duplicate": {"coins": 20, "items": {}}}


func _baggage_over_space() -> void:
	var saved: Dictionary = db.get("walks").walks.park_loop.loot.duplicate(true)
	_mixed_baggage()
	_leave_and_return()
	check(not state.call("walking"), "Tiro volta com a sacola cheia")
	check(_walk().has_baggage(), "a bagagem espera")
	var left: Dictionary = _walk().baggage_left()
	check(int(left.stick) == 3 and int(left.ribbon) == 2, "bagagem 3 gravetos + 2 fitas")
	check(state.call("walk_baggage_error") != "", "nada cabe")
	check(state.call("claim_walk_baggage").is_empty(), "guardar não perde nada")
	check(int(_walk().baggage_left().stick) == 3, "bagagem intacta")
	check("Sacola de passeio" in str(state.call("walk_baggage_hint")), "a dica nomeia a sacola: %s" % state.call("walk_baggage_hint"))
	check(state.call("walk_error", "park_loop") != "", "novo passeio espera a bagagem")
	# O Tiro continua presente e cuidado.
	check(state.call("walk_ready"), "bagagem pronta para retirar")
	check(str(state.call("away_text")) == "" or not state.call("walking"), "o Tiro está em casa e recebe cuidados")
	# Saída 1: gastar/vender abre espaço; entra por parcelas.
	state.get("inventory").add("carrot", 0)
	check(state.call("sell", "stick", 4) == "", "vende 4 gravetos")
	var plan: Dictionary = state.call("walk_baggage_plan")
	check(int(plan.moved.get("stick", 0)) == 3 and int(plan.moved.get("ribbon", 0)) == 1, "parcela: 3 gravetos + 1 fita (%s)" % str(plan.moved))
	var stored: Dictionary = state.call("claim_walk_baggage")
	check(int(stored.get("stick", 0)) == 3 and int(stored.get("ribbon", 0)) == 1, "guardou a parcela")
	check(int(_walk().baggage_left().get("ribbon", 0)) == 1 and not _walk().baggage_left().has("stick"), "sobrou 1 fita")
	check(int(_p().stat("walk_item:stick")) == 3 and int(_p().stat("walk_item")) == 4, "contadores só do que entrou")
	# Recarregar não refaz nada.
	var walks_before := int(_p().stat("walk"))
	var coins := int(state.get("coins"))
	_roundtrip()
	check(_walk().has_baggage() and int(_walk().baggage_left().get("ribbon", 0)) == 1, "recarga: a fita continua esperando")
	check(int(_p().stat("walk")) == walks_before and int(state.get("coins")) == coins, "recarga: sem prêmio nem contador repetido")
	check(int(state.call("storage_used", "chest")) == 12, "sacola cheia de novo")
	# Saída 2: o baú construído.
	_p().owned["chest"] = true
	check(not state.call("claim_walk_baggage").is_empty(), "com o baú a fita entra")
	check(not _walk().has_baggage() or _walk().baggage_left().is_empty(), "bagagem vazia")
	db.get("walks").walks.park_loop.loot = saved
	# Mapa e coleções seguem o contrato: itens de achado não ocupam a sacola.
	_fresh()
	var find_items: Array = []
	for id: String in db.get("items"):
		if str(db.get("items")[id].get("category", "")) == "find":
			find_items.append(id)
	state.get("inventory").add("stick", 12)
	for id: String in find_items:
		check(state.call("storage_error", {id: 5}) == "", "%s (achado) entra com a sacola cheia" % id)
	check(state.call("storage_error", {"map_piece_2": 1}) == "", "pedaço do mapa entra com a sacola cheia")
	# Consumos: costurar gasta itens da sacola e não é bloqueado por ela estar cheia.
	_fresh()
	_p().owned["sewing_table"] = true
	state.get("inventory").add("stick", 12)
	state.get("inventory").add("yarn", 0)
	check(state.call("storage_error", {}, {"stick": 3}) == "", "consumir nunca bloqueia")
	state.get("inventory").counts.clear()
	state.get("inventory").add("stick", 12)
	check(state.call("storage_excess", "chest") == 0, "12/12 sem excesso")


# --- grafo de requisitos --------------------------------------------------------------------------------

func _quest_deps(id: String, seen: Dictionary = {}) -> Dictionary:
	if seen.has(id):
		return seen
	seen[id] = true
	var quest: Dictionary = db.get("quests")[id]
	for required: String in quest.get("requirements", {}).get("quests", []):
		_quest_deps(required, seen)
	for goal: Dictionary in quest.goals:
		if goal.type == "quest":
			_quest_deps(str(goal.key), seen)
	return seen


func _requirement_graph() -> void:
	var upgrades: Dictionary = db.get("progression").upgrades
	var quests: Dictionary = db.get("quests")
	for id: String in ["chest", "chest_2", "chest_3"]:
		var data: Dictionary = upgrades[id]
		for owned: String in data.get("requirements", {}).get("owned", []):
			check(upgrades.has(owned) and owned != id, "%s: posse %s existe e não é ela mesma" % [id, owned])
		for quest: String in data.get("requirements", {}).get("quests", []):
			var deps := _quest_deps(quest)
			for dep: String in deps:
				for goal: Dictionary in quests[dep].goals:
					check(not (goal.type == "owned" and str(goal.key) == id), "%s não depende de si mesmo via %s" % [id, dep])
		for item: String in data.get("materials", {}):
			if item != "bolt":
				check(not (db.call("item_sources", item) as Array).is_empty(), "%s: %s tem origem" % [id, item])
	# O baú inicial só pede o que a Nina já entregou: gravetos vêm do passeio.
	var sources: Array = db.call("item_sources", "stick")
	check(not sources.is_empty(), "graveto tem origem tocável")
	var help: Script = load("res://scripts/ui/task_help.gd")
	check(not (help.call("describe", "upgrade", "chest") as Dictionary).is_empty(), "TaskHelp descreve o baú")
	check(not (help.call("describe", "item", "stick", 2) as Dictionary).is_empty(), "TaskHelp descreve o graveto")
	# Primeiros parafusos do baú: bolt vem das missões da 07 sem exigir ampliação do baú.
	check(upgrades.chest_2.requirements.quests == ["main_4_bench"], "chest_2 só depois da bancada (tábua tem origem)")
	# Quatro ordens: o contador da Bloblo reconhece o baú entre as ampliações.
	_fresh()
	_p().owned["chest"] = true
	state.call("_changed")
	check(int(_p().stat("storage_upgrades")) == 0, "o baú inicial não conta")
	_p().owned["chest_2"] = true
	state.call("_changed")
	check(int(_p().stat("storage_upgrades")) == 1, "chest_2 conta como ampliação")


# --- medição: taxa de bloqueio por estoque -------------------------------------------------------------

func _block_rate() -> void:
	_fresh()
	var seeds := 400
	var lines: Array[String] = []
	lines.append("# Etapa 08 — bloqueio da bagagem de passeio por estoque")
	lines.append("")
	lines.append("%d sementes por caminho, sorteio real (`_roll_walk`), só itens do baú. Saídas recuperáveis = vender, gastar na costura, dar no desejo, construir/ampliar o baú." % seeds)
	lines.append("")
	lines.append("| Caminho | Itens do baú por volta (média / máx) | Cabe na sacola vazia (12) | Bloqueia com 6 já guardados | Bloqueia com 10 | Cabe no baú vazio (24) |")
	lines.append("|---|---:|---:|---:|---:|---:|")
	var worst_empty := 0
	for id: String in db.get("walks").walks:
		var total := 0
		var maximum := 0
		var over_empty := 0
		var over_6 := 0
		var over_10 := 0
		var over_24 := 0
		for s in seeds:
			var trip := {"id": id, "seed": 1000 + s * 7919}
			_walk().history[id] = {"count": 0 if s % 2 == 0 else 3}
			var loot: Dictionary = state.call("_roll_walk", trip)
			var chest_items := 0
			for item: String in loot.items:
				if state.call("storage_of", item) == "chest":
					chest_items += int(loot.items[item])
			total += chest_items
			maximum = maxi(maximum, chest_items)
			if chest_items > 12: over_empty += 1
			if chest_items > 6: over_6 += 1
			if chest_items > 2: over_10 += 1
			if chest_items > 24: over_24 += 1
		worst_empty = maxi(worst_empty, over_empty)
		lines.append("| %s | %.1f / %d | %d%% | %d%% | %d%% | %d%% |" % [id, float(total) / seeds, maximum, 100 - 100 * over_empty / seeds, 100 * over_6 / seeds, 100 * over_10 / seeds, 100 - 100 * over_24 / seeds])
		check(over_empty == 0, "%s: a volta cabe inteira na sacola vazia (%d casos acima de 12)" % [id, over_empty])
	var sellable := 0
	var unsellable: Array[String] = []
	for id: String in TRAIL:
		if int(db.get("items")[id].get("sell_price", 0)) > 0:
			sellable += 1
		else:
			unsellable.append(id)
	check(unsellable.is_empty(), "todo item de trilha pode ser vendido: %s" % str(unsellable))
	lines.append("")
	lines.append("Saídas recuperáveis por bloqueio: %d/11 itens de trilha vendáveis na feira; a costura gasta %d; o baú abre mais espaço (12 → 24 → 40 → 64)." % [sellable, _sewing_consumers()])
	lines.append("")
	lines.append("Pior caso na sacola vazia: %d voltas acima do limite (esperado 0)." % worst_empty)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://").path_join("../build/economy/etapa_08"))
	var file := FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../build/economy/etapa_08/bloqueio.md"), FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(lines) + "\n")
		file.close()
	print("\n".join(lines))


func _sewing_consumers() -> int:
	var total := 0
	for id: String in db.get("recipes"):
		var recipe: Dictionary = db.get("recipes")[id]
		if str(recipe.get("station", "")) != "sewing":
			continue
		for item: String in recipe.get("inputs", {}):
			if item in TRAIL:
				total += 1
				break
	return total
