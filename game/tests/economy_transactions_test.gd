extends SceneTree
## Etapa 02 da economia R1: migração sem reset, transações atômicas, snapshots de trabalhos,
## capacidade provisória/piso legado e recibos de presentes automáticos.
## --headless --path game -s res://tests/economy_transactions_test.gd
## Só fixtures sintéticas (v12 montadas aqui), nunca o save do jogador.

var _failures: int = 0
var state: Node
var database: Node
var _migration: Script


## EconomyMigration é carregada em tempo de execução: teste -s não compila classes que citam autoloads.
func _migrate(data: Dictionary) -> Dictionary:
	return _migration.call("migrate", data)


func _needs(data: Dictionary) -> bool:
	return _migration.call("needs", data)


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	database = root.get_node("Database")
	_migration = load("res://scripts/state/economy_migration.gd")
	_migration_fixtures()
	_legacy_capacity()
	_projected_transactions()
	_work_snapshots()
	_walk_snapshot()
	_automatic_receipts()
	_prebuild_and_floor()
	_pure_migration_and_slots()
	_five_slots()
	print("ECONOMY TRANSACTIONS TEST: %s" % ("PASS" if _failures == 0 else "FAIL"))
	quit(1 if _failures > 0 else 0)


# --- Utilitários -------------------------------------------------------------------

func _fresh() -> void:
	state.call("reset")
	state.set("unlimited_storage", false)
	state.get("inventory").counts.clear()
	var progress: Object = state.get("progress")
	progress.owned["farm"] = true
	progress.owned["stove"] = true
	state.set("unlocked_plots", 3)
	state.call("_ensure_plots")


## Estado como um save v12 de ANTES da etapa 02: sem bloco de economia, sem snapshots de trabalhos.
func _as_v12() -> Dictionary:
	var data: Dictionary = (JSON.parse_string(JSON.stringify(state.call("to_dict"))) as Dictionary)
	data.erase("economy")
	for plot: Dictionary in data.get("plots", []):
		plot.erase("job")
	for station: Dictionary in data.get("stations", {}).values():
		for entry: Dictionary in station.get("queue", []):
			entry.erase("job")
	var current: Dictionary = data.get("walks", {}).get("current", {})
	current.erase("snapshot")
	var activity: Dictionary = data.get("progression", {}).get("activity", {})
	activity.erase("rewards")
	activity.erase("player_xp")
	return data


func _reload(data: Dictionary) -> void:
	state.call("from_dict", (JSON.parse_string(JSON.stringify(data)) as Dictionary))


func _roundtrip() -> void:
	_reload(state.call("to_dict"))


func _inv(id: String) -> int:
	return int(state.get("inventory").count(id))


func _snapshot() -> String:
	return JSON.stringify(state.call("to_dict"))


# --- 1. Migração: fixtures v12 -----------------------------------------------------

func _migration_fixtures() -> void:
	# Início sem depósitos: nada ganha limite, piso zero.
	_fresh()
	var data := _as_v12()
	_check(not data.has("economy"), "fixture v12 não tem economia")
	_reload(data)
	for depot: String in ["fridge", "chest", "silo", "warehouse"]:
		# Etapa 05 ligou o cesto provisório do silo; os demais só ganham o limite na própria etapa.
		var provisional: bool = database.get("progression").storage[depot].has("prebuild_capacity")
		_check(bool(state.call("storage_active", depot)) == provisional, "%s sem prédio: limite só se houver capacidade provisória" % depot)
		_check(int(state.call("storage_floor", depot)) == 0, "%s sem prédio: piso zero" % depot)
	_check(int(state.get("economy").revision) == 1, "save antigo recebe a revisão 1")
	_check(state.call("storage_error", {"carrot": 999}) != "", "sem silo vale o cesto provisório")
	# Migrar duas vezes dá o mesmo save.
	var migrated: Dictionary = _migrate(data)
	var twice: Dictionary = _migrate(migrated)
	_check(JSON.stringify(migrated) == JSON.stringify(twice), "migração idempotente")
	_check(not _needs(migrated), "revisão aplicada não migra de novo")
	# Capítulos 3 e 9: piso de capítulos e recompensas já pagas pelo mapa antigo.
	_fresh()
	var claimed: Dictionary = state.get("progress").claimed_quests
	for id: String in database.get("quests"):
		var quest: Dictionary = database.get("quests")[id]
		if quest.get("kind", "") == "main" and int(quest.get("chapter", 0)) <= 2:
			claimed[id] = true
	state.set("level", 4)
	var chapter3 := _as_v12()
	var migrated3: Dictionary = _migrate(chapter3)
	_check(int(migrated3.economy.legacy.chapter) == 3, "mapa antigo: capítulo 3 ativo")
	_check(migrated3.economy.granted.has("chapter:1") and migrated3.economy.granted.has("chapter:2"), "capítulos 1–2 já pagos")
	_check(not migrated3.economy.granted.has("chapter:3"), "capítulo 3 ainda não foi pago")
	_check(migrated3.economy.granted.has("level:2") and migrated3.economy.granted.has("level:4") and not migrated3.economy.granted.has("level:5"), "níveis 2–4 já pagos")
	for id: String in database.get("quests"):
		var quest: Dictionary = database.get("quests")[id]
		if quest.get("kind", "") == "main":
			state.get("progress").claimed_quests[id] = true
	var final_state: Dictionary = _migrate(_as_v12())
	_check(int(final_state.economy.legacy.chapter) == 10, "final 9: todos os capítulos concluídos")
	_check(final_state.economy.granted.has("chapter:9"), "capítulo 9 já pago")


# --- 2. Capacidade legada ------------------------------------------------------------

func _legacy_capacity() -> void:
	var storage: Dictionary = database.get("progression").storage
	# Cada depósito comprado (só a base): capacidade antiga preservada; piso vem da compra.
	for depot: String in storage:
		_fresh()
		state.get("progress").owned[str(storage[depot].building)] = true
		_reload(_as_v12())
		_check(state.call("storage_active", depot), "%s comprado limita" % depot)
		var legacy_base := int(database.get("legacy").storage[depot].base)
		_check(int(state.call("storage_capacity", depot)) == maxi(int(storage[depot].base), legacy_base), "%s: capacidade antiga preservada" % depot)
		_check(int(state.call("storage_floor", depot)) == legacy_base, "%s: piso = base comprada (tabela congelada)" % depot)
	# Todos ampliados.
	_fresh()
	for depot: String in storage:
		state.get("progress").owned[str(storage[depot].building)] = true
		for level: String in storage[depot].levels.slice(0, 2):  # as ampliações que o save antigo conhecia (_2 e _3)
			state.get("progress").owned[level] = true
	var before := {}
	for depot: String in storage:
		before[depot] = int(state.call("storage_capacity", depot))
	_reload(_as_v12())
	for depot: String in storage:
		var legacy_total := int(database.get("legacy").storage[depot].base)
		for level: Dictionary in database.get("legacy").storage[depot].levels:
			legacy_total += int(level.capacity)
		_check(int(state.call("storage_capacity", depot)) == maxi(int(before[depot]), legacy_total), "%s ampliado: capacidade antiga preservada após migrar" % depot)
		_check(int(state.call("storage_floor", depot)) == legacy_total, "%s: piso = tabela congelada" % depot)
	# A curva viva pode mudar nas próximas etapas: o piso comprado não cai. (restaura no fim)
	var silo: Dictionary = storage.silo
	var base_before := int(silo.base)
	silo["base"] = 10
	_check(int(state.call("storage_curve", "silo")) < int(state.call("storage_floor", "silo")), "curva nova menor que o piso")
	_check(int(state.call("storage_capacity", "silo")) == int(state.call("storage_floor", "silo")), "capacidade = max(curva nova, piso comprado)")
	silo["base"] = base_before
	# Estoque acima do teto (excesso legado): nada some, entradas bloqueiam, consumo e venda funcionam.
	_fresh()
	state.get("progress").owned["silo"] = true
	state.get("inventory").add("carrot", 55)
	_reload(_as_v12())
	_check(_inv("carrot") == 55, "excesso legado preservado ao carregar")
	_check(int(state.call("storage_excess", "silo")) == 15, "excesso = 15 acima de 40")
	_check(int(state.call("storage_floor", "silo")) == 40, "piso não vem do estoque (55) e sim da compra (40)")
	_check(int(state.call("storage_capacity", "silo")) == 40, "capacidade continua 40")
	_check(state.call("storage_error", {"carrot": 1}) != "", "acima do limite bloqueia nova entrada")
	_check(state.call("storage_error", {}) == "", "sem entrada nada bloqueia")
	_check(state.call("sell", "carrot", 20) == "", "vender acima do limite funciona")
	_check(_inv("carrot") == 35, "estoque depois de vender")
	_check(state.call("storage_error", {"carrot": 5}) == "", "cabe de novo depois de consumir")
	_check(int(state.get("economy").storage_floor.silo) == 40, "piso persistido não cai ao vender")
	_roundtrip()
	_check(int(state.call("storage_floor", "silo")) == 40, "piso persiste no save")


# --- 3. Transações projetadas --------------------------------------------------------

func _projected_transactions() -> void:
	_fresh()
	var orders: Dictionary = database.get("progression").orders
	orders["__tx_swap"] = {"inputs": {"carrot": 4}, "rewards": {"coins": 7, "items": {"carrot": 3}}, "cooldown": 30, "requirements": {}}
	orders["__tx_big"] = {"inputs": {"carrot": 4}, "rewards": {"coins": 7, "items": {"carrot": 9}}, "cooldown": 30, "requirements": {}}
	state.get("progress").owned["silo"] = true
	state.get("inventory").add("carrot", 32)  # silo cheio (32/32)
	# Consumir do mesmo depósito libera espaço: entrega 4, recebe 3.
	_check(state.call("order_error", "__tx_swap") == "", "entrega que libera espaço é aceita")
	# Recebe mais do que entrega: net +5 → bloqueia sem nenhum efeito.
	var before := _snapshot()
	var error: String = state.call("order_error", "__tx_big")
	_check(error != "", "prêmio que não cabe depois de consumir bloqueia")
	_check(state.call("fulfill_order", "__tx_big") == error, "fulfill devolve o mesmo motivo")
	_check(_snapshot() == before, "erro é consulta pura: nada consumido, contado ou recarregado")
	var shortage: Dictionary = state.call("storage_shortage", {"carrot": 9}, {"carrot": 4})
	_check(int(shortage.missing) == 5, "falta real = 5 (e não o tamanho do lote)")
	# Aceita: consome e recebe juntos.
	var coins_before := int(state.get("coins"))
	_check(state.call("fulfill_order", "__tx_swap") == "", "entrega e prêmio juntos")
	_check(_inv("carrot") == 31 and int(state.get("coins")) == coins_before + 7, "saldo depois da transação")
	# Projetado por depósito: ovo e leite dividem a geladeira.
	_fresh()
	state.get("progress").owned["fridge"] = true
	state.get("inventory").add("egg", 22)
	_check(state.call("storage_error", {"milk": 2}) == "", "cabem exatamente 2 na geladeira")
	_check(state.call("storage_error", {"milk": 2, "egg": 1}) != "", "soma por depósito")
	_check(state.call("storage_error", {"milk": 2, "egg": 1}, {"egg": 1}) == "", "o que sai libera espaço")
	# Colheita e lote: indivisíveis, continuam prontos.
	_fresh()
	state.get("progress").owned["silo"] = true
	state.get("inventory").add("carrot", 31)
	state.call("plant", 0, "carrot")
	state.get("plots")[0]["ready_at"] = 0.0
	_check((state.call("harvest", 0) as Dictionary).is_empty(), "colheita de 2 não cabe em 31/32")
	_check(state.call("plot_status", 0) == "ready", "continua pronta")
	_check(state.call("harvest_error", 0) != "", "harvest_error igual")
	state.get("inventory").remove("carrot", 1)
	_check(not (state.call("harvest", 0) as Dictionary).is_empty(), "colhe quando abre espaço")
	orders.erase("__tx_swap")
	orders.erase("__tx_big")
	# Missão: entrega + prêmio juntos, com erro puro.
	_fresh()
	var quests: Dictionary = database.get("quests")
	quests["__tx_quest"] = {"kind": "side", "name": "x", "goals": [{"type": "deliver", "key": "carrot", "target": 4}], "rewards": {"items": {"carrot": 6}}, "requirements": {}, "requires": []}
	state.get("progress").owned["silo"] = true
	state.get("inventory").add("carrot", 32)
	var quest_before := _snapshot()
	var quest_error: String = state.call("quest_error", "__tx_quest")
	_check(quest_error != "", "missão com prêmio que não cabe fica bloqueada (net +2 com silo cheio)")
	_check(state.call("claim_quest", "__tx_quest") == quest_error and _snapshot() == quest_before, "claim_quest bloqueada não altera nada")
	state.get("inventory").remove("carrot", 2)
	_check(state.call("quest_error", "__tx_quest") == "", "com 2 vagas livres, entregar 4 e receber 6 cabe")
	_check(state.call("claim_quest", "__tx_quest") == "", "recebe a missão")
	_check(_inv("carrot") == 32, "30 − 4 + 6 = 32")
	quests.erase("__tx_quest")
	# transaction_error: moedas, ingredientes e espaço projetado numa só consulta.
	_fresh()
	state.get("progress").owned["silo"] = true
	state.get("inventory").add("carrot", 32)
	state.set("coins", 10)
	_check(state.call("transaction_error", {}, {}, 11) != "", "moedas insuficientes")
	_check(state.call("transaction_error", {"potato": 1}, {}, 0) != "", "ingrediente que falta")
	_check(state.call("transaction_error", {"carrot": 4}, {"carrot": 4}, 10) == "", "sai 4 e entra 4 no depósito cheio: cabe")
	_check(state.call("transaction_error", {"carrot": 4}, {"carrot": 5}, 0) != "", "sai 4 e entra 5: não cabe")
	_check(state.call("transaction_error", {}, {"bolt": 99}, 0) == "", "item isento (sem depósito) não atrapalha")
	# Todos os recebimentos manuais passam pela mesma validação.
	_fresh()
	state.get("progress").owned["fridge"] = true
	state.get("inventory").add("egg", 24)
	_check(state.call("buy_shop_item_error", "__missing") != "", "produto desconhecido")
	# Presente do dia (recebimento manual): com a geladeira cheia o prêmio de comida bloqueia sem gastar o dia.
	state.call("dev_unlock_everything")
	for upgrade: String in ["fridge_2", "fridge_3", "fridge_4", "fridge_5"]:
		state.get("progress").owned.erase(upgrade)
	state.get("economy").storage_floor.clear()
	state.get("inventory").counts.clear()
	state.get("inventory").add("egg", 24)
	state.get("progress").daily_gift = {"period": "", "count": 2}  # terceiro do ciclo: lanches de cenoura
	var gift_before := _snapshot()
	_check(str(state.call("daily_gift_error")).ends_with("sem espaço"), "presente do dia espera por espaço (%s)" % str(state.call("daily_gift_error")))
	_check(state.call("claim_daily_gift") != "" and _snapshot() == gift_before, "presente bloqueado não altera nada")
	state.get("inventory").remove("egg", 2)
	_check(state.call("claim_daily_gift") == "" and _inv("carrot_snack") == 2, "com espaço o presente é pago uma vez")
	_check(state.call("claim_daily_gift") != "", "o mesmo dia não paga de novo")


# --- 4. Snapshots de trabalhos ---------------------------------------------------------

func _work_snapshots() -> void:
	var crops: Dictionary = database.get("crops")
	var recipes: Dictionary = database.get("recipes")
	# Colheita: alterar a cultura depois de plantar não muda o que foi plantado.
	_fresh()
	state.call("plant", 0, "carrot")
	var job: Dictionary = state.get("plots")[0].job
	_check(job.crop == "carrot" and int(job.coins) == int(crops.carrot.coins), "snapshot da colheita guarda moedas")
	var old_yield: Dictionary = (crops.carrot.yield as Dictionary).duplicate()
	var old_coins := int(crops.carrot.coins)
	var old_skill := int(crops.carrot.skill_xp)
	crops.carrot["yield"] = {"carrot": 9}
	crops.carrot["coins"] = old_coins + 50
	crops.carrot["skill_xp"] = old_skill + 40
	state.get("plots")[0]["ready_at"] = 0.0
	var coins_before := int(state.get("coins"))
	var skills_before := int(state.get("progress").skills.get("agriculture", 0))
	_roundtrip()  # reload entre plantar e colher
	var got: Dictionary = state.call("harvest", 0)
	_check(int(got.get("carrot", 0)) == int(old_yield.carrot), "rendimento antigo mantido (%s)" % str(got))
	_check(int(state.get("coins")) == coins_before + old_coins, "moedas antigas mantidas")
	_check(int(state.get("progress").skills.get("agriculture", 0)) - skills_before == old_skill * 2, "XP de habilidade antigo (dobra na 1ª descoberta)")
	crops.carrot["yield"] = old_yield
	crops.carrot["coins"] = old_coins
	crops.carrot["skill_xp"] = old_skill
	# Receita: trocar entrada, saída e quantidade depois de iniciar não muda o lote.
	_fresh()
	state.get("inventory").add("carrot", 4)
	_check(state.call("cook", "carrot_snack") == "", "iniciou o lote")
	var queue: Array = state.call("station", "stove").queue
	_check(queue[0].job.output == "carrot_snack" and int(queue[0].job.qty) == 1 and int(queue[0].job.inputs.carrot) == 2, "snapshot do lote guarda entrada paga e saída")
	var recipe: Dictionary = recipes.carrot_snack
	var old_output: Variant = recipe.output
	var old_qty: Variant = recipe.qty
	recipe["output"] = "apple_biscuit"
	recipe["qty"] = 7
	recipe["skill_xp"] = 99
	queue[0]["ready_at"] = 0.0
	_roundtrip()
	var batch: Dictionary = state.call("collect", "stove")
	_check(int(batch.get("carrot_snack", 0)) == 1 and not batch.has("apple_biscuit"), "saída antiga mantida após trocar a receita (%s)" % str(batch))
	_check(_inv("carrot_snack") == 1 and _inv("apple_biscuit") == 0, "inventário recebe a saída antiga")
	recipe["output"] = old_output
	recipe["qty"] = old_qty
	recipe.erase("skill_xp")
	recipe["skill_xp"] = 10
	# Trabalho antigo (v12, sem snapshot) usa a tabela congelada, não a futura.
	_fresh()
	state.get("inventory").add("carrot", 4)
	state.call("cook", "carrot_snack")
	state.call("plant", 1, "carrot")
	state.call("station", "stove").queue[0]["ready_at"] = 0.0
	state.get("plots")[1]["ready_at"] = 0.0
	var legacy_file := _as_v12()
	recipes.carrot_snack["output"] = "apple_biscuit"
	crops.carrot["yield"] = {"carrot": 8}
	_reload(legacy_file)
	_check(state.call("station", "stove").queue[0].job.output == "carrot_snack", "migração congela o lote antigo com a tabela legada")
	_check(int(state.get("plots")[1].job.yield.carrot) == 2, "migração congela a colheita antiga")
	_check((state.call("collect", "stove") as Dictionary).has("carrot_snack"), "lote antigo entrega a saída antiga")
	_check(int((state.call("harvest", 1) as Dictionary).get("carrot", 0)) == 2, "canteiro antigo rende o que rendia")
	recipes.carrot_snack["output"] = "carrot_snack"
	crops.carrot["yield"] = old_yield
	# Prazo: ready_at existente prevalece, nada alonga.
	_fresh()
	state.call("plant", 0, "carrot")
	var ready_at := float(state.get("plots")[0].ready_at)
	crops.carrot["seconds"] = 9999
	_reload(_as_v12())
	_check(is_equal_approx(float(state.get("plots")[0].ready_at), ready_at), "prazo anterior preservado")
	crops.carrot["seconds"] = 60
	# Rota/coleta antiga recebe snapshot de rewards.
	_fresh()
	state.get("progress").activity = {"id": "pebbles", "started_at": 0.0, "ready_at": 1.0}
	_reload(_as_v12())
	var route: Dictionary = state.get("progress").activity
	_check(route.has("rewards") and route.has("player_xp"), "rota antiga ganhou contrato")


func _walk_snapshot() -> void:
	var walks: Dictionary = database.get("walks")
	var id := "round"
	if not (walks.walks as Dictionary).has(id):
		id = (walks.walks as Dictionary).keys()[0]
	_fresh()
	var def: Dictionary = walks.walks[id]
	state.get("walk_state").current = {"id": id, "started_at": 0.0, "ready_at": float(state.call("now")) + 1000.0, "seed": 4242, "energy": 0}
	var live_loot: Dictionary = state.call("walk_loot")
	_reload(_as_v12())
	var snapshot: Dictionary = state.get("walk_state").current.get("snapshot", {})
	_check(not snapshot.is_empty() and snapshot.has("def"), "passeio antigo recebeu snapshot")
	var original_table: Variant = (def.loot as Dictionary).duplicate(true)
	(def.loot as Dictionary)["table"] = [{"weight": 1, "items": {"plank": 99}}]
	var frozen_loot: Dictionary = state.call("walk_loot")
	_check(JSON.stringify(frozen_loot.items) == JSON.stringify(live_loot.items), "passeio em andamento mantém o sorteio antigo")
	def["loot"] = original_table
	# Novo passeio: o snapshot sai junto com o save.
	_fresh()
	state.call("dev_unlock_everything")
	state.get("inventory").counts.clear()
	state.get("dog").apply({"energy": 100.0}, state.call("now"))
	_check(state.call("walk_error", id) == "", "passeio de teste liberado (%s)" % str(state.call("walk_error", id)))
	state.call("start_walk", id)
	_check(state.get("walk_state").current.has("snapshot"), "start_walk grava o snapshot")
	var live_def: Dictionary = (database.get("walks").walks[id] as Dictionary)
	var old_seconds: Variant = live_def.get("seconds")
	_roundtrip()
	_check(state.get("walk_state").current.has("snapshot"), "snapshot sobrevive ao save")
	_check(int(state.get("walk_state").current.snapshot.def.seconds) == int(old_seconds), "snapshot guarda o tempo e os prêmios do passeio")


# --- 5. Recibos de recompensas automáticas ----------------------------------------------

func _automatic_receipts() -> void:
	_fresh()
	state.get("progress").owned["fridge"] = true
	state.get("progress").owned["warehouse"] = true
	state.get("inventory").add("egg", 24)  # geladeira cheia
	var coins_before := int(state.get("coins"))
	var reward := {"coins": 25, "skill_xp": {"cooking": 10}, "items": {"carrot_snack": 2, "plank": 3}}
	var paid: Dictionary = state.call("_grant_automatic", "customer:lais:2", reward)
	_check(bool(paid.paid) and (paid.pending as Dictionary).has("carrot_snack"), "prêmio misto: comida não coube")
	_check(_inv("plank") == 3 and _inv("carrot_snack") == 0, "prêmio misto: o que cabia entrou, o resto espera")
	_check(int(state.get("coins")) == coins_before + 25, "moedas pagas uma vez")
	var cooking: int = state.get("progress").skills.get("cooking", 0)
	var again: Dictionary = state.call("_grant_automatic", "customer:lais:2", reward)
	_check(not bool(again.paid), "mesma identidade não paga de novo")
	_check(int(state.get("coins")) == coins_before + 25 and _inv("plank") == 3 and state.get("progress").skills.get("cooking", 0) == cooking, "nada duplicado")
	_check(int(state.call("pending_reward_count")) == 1 and int(state.call("pending_reward_total")) == 2, "um recibo com 2 unidades")
	# Guardar sem espaço: erro com a falta real, nada muda.
	var snapshot := _snapshot()
	_check(state.call("pending_reward_error") != "" and (state.call("claim_pending_rewards") as Dictionary).is_empty(), "sem espaço não guarda")
	_check(_snapshot() == snapshot, "guardar sem espaço é consulta pura")
	_check(str(state.call("pending_reward_hint")).contains("Geladeira") and str(state.call("pending_reward_hint")).contains("×2"), "aviso nomeia o depósito")
	# Reload entre receber e guardar: recibo persiste, sem repagar.
	_roundtrip()
	_check(int(state.call("pending_reward_total")) == 2 and int(state.get("coins")) == coins_before + 25, "recibo persiste e moedas não repetem")
	_check(not bool(state.call("_grant_automatic", "customer:lais:2", reward).paid), "identidade persiste no save")
	# Consumir abre espaço; guarda parcialmente (1 de 2) e o resto continua.
	state.get("inventory").remove("egg", 1)
	var moved: Dictionary = state.call("claim_pending_rewards")
	_check(int(moved.get("carrot_snack", 0)) == 1 and _inv("carrot_snack") == 1, "guardou só o que cabe (1)")
	_check(int(state.call("pending_reward_total")) == 1, "saldo restante persistido no recibo")
	_roundtrip()
	_check(int(state.call("pending_reward_total")) == 1 and _inv("carrot_snack") == 1, "recebimento parcial sobrevive ao reload")
	state.get("inventory").remove("egg", 5)
	state.call("claim_pending_rewards")
	_check(_inv("carrot_snack") == 2 and int(state.call("pending_reward_count")) == 0, "tudo guardado, recibo encerrado")
	_check(state.call("pending_reward_error") != "", "sem recibo: nada para guardar")
	_check(_inv("carrot_snack") + int(state.call("pending_reward_total")) == 2, "conservação: nada perdido nem duplicado")
	# Nível recebido duas vezes e capítulo compartilhado.
	_fresh()
	state.get("progress").owned["fridge"] = true
	state.get("inventory").add("egg", 24)
	var level_reward: Dictionary = {"coins": 60, "items": {"carrot_snack": 1}}
	var gold := int(state.get("coins"))
	state.call("_grant_automatic", "level:8", level_reward)
	state.call("_grant_automatic", "level:8", level_reward)
	_check(int(state.get("coins")) == gold + 60 and int(state.call("pending_reward_total")) == 1, "nível 8 pago uma vez, item no recibo uma vez")
	var chapter_reward: Dictionary = {"coins": 140, "skill_xp": {"agriculture": 20}}
	state.call("_grant_automatic", "chapter:6", chapter_reward)
	state.call("_grant_automatic", "chapter:6", chapter_reward)
	_check(int(state.get("coins")) == gold + 60 + 140, "capítulo compartilhado pago uma vez")
	# Subir de nível de verdade: item que não cabe vira recibo, XP/moedas contam uma vez.
	_fresh()
	state.get("progress").owned["fridge"] = true
	state.get("inventory").add("egg", 24)
	var level_before := int(state.get("level"))
	state.call("_add_player_xp", 100 * level_before)  # sobe um nível
	_check(int(state.get("level")) == level_before + 1, "subiu de nível")
	var receipt_id := "level:%d" % int(state.get("level"))
	_check(state.get("economy").granted.has(receipt_id), "nível registrado como pago")
	if (state.call("level_reward", int(state.get("level"))).get("items", {}) as Dictionary).has("carrot_snack"):
		_check((state.get("economy").pending as Dictionary).has(receipt_id), "carrot_snack do nível vira recibo com a geladeira cheia")
	# Recompensas manuais não viram banco sem limite: nada vai para o recibo.
	_fresh()
	state.get("progress").owned["silo"] = true
	state.get("inventory").add("carrot", 32)
	_check(state.call("storage_error", {"carrot": 3}) != "" and int(state.call("pending_reward_count")) == 0, "manual bloqueia e não cria recibo")
	# Recibo sem item que ainda cabe no depósito ilimitado (sem depósito construído): entra direto.
	_fresh()
	state.call("_grant_automatic", "bond:3", {"coins": 0, "items": {"carrot_snack": 2}})
	_check(_inv("carrot_snack") == 2 and int(state.call("pending_reward_count")) == 0, "depósito sem limite: tudo entra, sem recibo")


# --- 6. Capacidade provisória e piso ----------------------------------------------------

func _prebuild_and_floor() -> void:
	var storage: Dictionary = database.get("progression").storage
	_fresh()
	# Etapas 05–08: silo, geladeira, armazém e baú já têm provisório (sem o campo valeria a regra antiga, sem limite).
	_check(state.call("storage_active", "silo") and state.call("storage_active", "fridge") and state.call("storage_active", "warehouse") and state.call("storage_active", "chest"), "os quatro depósitos têm limite provisório")
	_check(int(state.call("storage_capacity", "fridge")) == 12, "capacidade provisória antes de construir")
	_check(int(state.call("storage_capacity", "chest")) == 12, "sacola provisória do baú = 12")
	state.get("inventory").add("egg", 12)
	_check(state.call("storage_error", {"egg": 1}) != "", "provisório cheio bloqueia")
	_check(state.call("storage_error", {"treat_box": 99}) != "" and state.call("storage_error", {"bolt": 99}) == "", "o baú limita os produtos, mas o parafuso é isento")
	state.get("progress").owned["fridge"] = true
	_check(int(state.call("storage_capacity", "fridge")) == int(storage.fridge.base), "adquirir o prédio amplia")
	state.get("progress").owned.erase("fridge")
	var saved_prebuild: int = storage.fridge.prebuild_capacity
	storage.fridge.erase("prebuild_capacity")
	_check(not state.call("storage_active", "fridge"), "campo removido volta à regra antiga")
	storage.fridge["prebuild_capacity"] = saved_prebuild
	# Piso nunca vem do estoque: só a migração grava o que o save antigo tinha comprado.
	_fresh()
	state.get("progress").owned["warehouse"] = true
	state.get("inventory").add("plank", 500)
	_reload(_as_v12())
	var legacy_base := int(database.get("legacy").storage.warehouse.base)
	_check(int(state.get("economy").storage_floor.warehouse) == legacy_base, "piso = compra antiga, não os 500 estocados")
	# Ampliar num jogo já migrado NÃO sobe mais o piso (a curva R1 vale para compras novas).
	state.get("progress").owned["warehouse_2"] = true
	state.call("_changed")
	_check(int(state.get("economy").storage_floor.warehouse) == legacy_base, "compra nova não vira piso legado")
	var raised := int(state.get("economy").storage_floor.warehouse)
	state.get("economy").raise_floor("warehouse", 1)
	_check(int(state.get("economy").storage_floor.warehouse) == raised, "piso nunca cai")


# --- 7. Migração pura e slots ---------------------------------------------------------

func _pure_migration_and_slots() -> void:
	_fresh()
	state.get("progress").owned["silo"] = true
	state.get("inventory").add("carrot", 45)
	state.call("plant", 0, "carrot")
	var data := _as_v12()
	var untouched := JSON.stringify(data)
	var migrated: Dictionary = _migrate(data)
	_check(JSON.stringify(data) == untouched, "a migração não altera a entrada")
	_check(int(migrated.coins) == int(data.coins) and JSON.stringify(migrated.inventory) == JSON.stringify(data.inventory), "migração não paga nem muda estoque")
	_check(JSON.stringify(migrated.dog) == JSON.stringify(data.dog), "migração não mexe em tempos do Tiro")
	_check(JSON.stringify(migrated.friends) == JSON.stringify(data.friends), "migração não gera visita")
	# O SaveManager usa o mesmo caminho (relatórios de slot, "copiar da publicada").
	var manager: Node = (load("res://autoload/save_manager.gd") as GDScript).new()
	var viaSave: Dictionary = manager.call("_migrate", {"save_version": 12, "saved_at": 1.0, "state": data})
	_check(viaSave.state.has("economy") and int(viaSave.state.economy.revision) == 1, "SaveManager._migrate carimba a revisão")
	var viaTwice: Dictionary = manager.call("_migrate", viaSave)
	_check(JSON.stringify(viaTwice) == JSON.stringify(viaSave), "SaveManager._migrate idempotente")
	var reset_case: Dictionary = manager.call("_migrate", {"save_version": 3, "state": {"coins": 5}})
	_check((reset_case.state as Dictionary).is_empty(), "ramo histórico <12 continua igual (não amplia o reset)")
	manager.free()
	# Carregar duas vezes e serializar: estado estável.
	_reload(migrated)
	var first := _snapshot()
	_roundtrip()
	_check(_snapshot() == first, "carregar e salvar de novo não muda nada")
	_check(_inv("carrot") == 45 and int(state.call("storage_capacity", "silo")) == 40, "saldo e capacidade iguais antes de nova ação")
	# Conteúdo atual do jogo: todos os depósitos do plano estão ativados (etapas 05–08).
	_fresh()
	_check(state.call("storage_active", "chest"), "o baú está ativado")


# --- 8. Cinco slots pelo mesmo caminho (SaveManager._migrate + from_dict) ---------------------

func _five_slots() -> void:
	var manager: Node = (load("res://autoload/save_manager.gd") as GDScript).new()
	var files: Array[Dictionary] = []
	# 1: começo; 2: silo e geladeira; 3: tudo ampliado com excesso; 4: trabalhos em andamento; 5: recibo pendente.
	_fresh()
	files.append({"save_version": 12, "saved_at": 1.0, "state": _as_v12()})
	_fresh()
	state.get("progress").owned["silo"] = true
	state.get("progress").owned["fridge"] = true
	files.append({"save_version": 12, "saved_at": 2.0, "state": _as_v12()})
	_fresh()
	var storage: Dictionary = database.get("progression").storage
	for depot: String in storage:
		state.get("progress").owned[str(storage[depot].building)] = true
		for level: String in storage[depot].levels:
			state.get("progress").owned[level] = true
	state.get("inventory").add("carrot", 500)
	files.append({"save_version": 12, "saved_at": 3.0, "state": _as_v12()})
	_fresh()
	state.get("inventory").add("carrot", 4)
	state.call("cook", "carrot_snack")
	state.call("plant", 0, "carrot")
	files.append({"save_version": 12, "saved_at": 4.0, "state": _as_v12()})
	_fresh()
	state.get("progress").owned["fridge"] = true
	state.get("inventory").add("egg", 30)
	state.call("_grant_automatic", "customer:lais:1", {"coins": 10, "items": {"carrot_snack": 2}})
	var with_receipt: Dictionary = (JSON.parse_string(JSON.stringify({"save_version": 12, "saved_at": 5.0, "state": state.call("to_dict")})) as Dictionary)
	files.append(with_receipt)
	var seen: Array[String] = []
	for index in 5:
		var migrated: Dictionary = manager.call("_migrate", files[index])
		_check(int(migrated.state.economy.revision) == 1, "slot %d: revisão carimbada" % (index + 1))
		state.call("from_dict", migrated.state)
		seen.append(_snapshot())
	# Trocar entre os slots de novo (1 → 5 → 3 → 1...) devolve exatamente o mesmo estado: nada vaza entre eles.
	for index in [0, 4, 2, 0, 3, 1, 4]:
		var again: Dictionary = manager.call("_migrate", manager.call("_migrate", files[index]))
		state.call("from_dict", again.state)
		_check(_snapshot() == seen[index], "slot %d: o mesmo estado ao voltar" % (index + 1))
	# O recibo do slot 5 não aparece nos demais.
	state.call("from_dict", manager.call("_migrate", files[0]).state)
	_check(int(state.call("pending_reward_count")) == 0, "slot 1 não herdou o recibo do slot 5")
	state.call("from_dict", manager.call("_migrate", files[4]).state)
	_check(int(state.call("pending_reward_count")) == 1 and int(state.call("pending_reward_total")) == 2, "slot 5 mantém o recibo")
	manager.free()
