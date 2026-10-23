extends SceneTree
## Transações atômicas, snapshots atuais e recibos de presentes automáticos.
## --headless --path game -s res://tests/economy_transactions_test.gd
## Estados atuais sintéticos; nenhuma fixture de versão anterior.

var _failures: int = 0
var state: Node
var database: Node


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
	_projected_transactions()
	_work_snapshots()
	_walk_snapshot()
	_automatic_receipts()
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
func _reload(data: Dictionary) -> void:
	state.call("from_dict", (JSON.parse_string(JSON.stringify(data)) as Dictionary))


func _roundtrip() -> void:
	_reload(state.call("to_dict"))


func _inv(id: String) -> int:
	return int(state.get("inventory").count(id))


func _snapshot() -> String:
	return JSON.stringify(state.call("to_dict"))


# --- 1. Migração: fixtures v12 -----------------------------------------------------

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


func _walk_snapshot() -> void:
	var walks: Dictionary = database.get("walks")
	var id := "round"
	if not (walks.walks as Dictionary).has(id):
		id = (walks.walks as Dictionary).keys()[0]
	_fresh()
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
	state.call("_grant_automatic", "growth:puppy", level_reward)
	state.call("_grant_automatic", "growth:puppy", level_reward)
	_check(int(state.get("coins")) == gold + 60 and int(state.call("pending_reward_total")) == 1, "presente de fase pago uma vez, item no recibo uma vez")
	var chapter_reward: Dictionary = {"coins": 140, "skill_xp": {"agriculture": 20}}
	state.call("_grant_automatic", "chapter:6", chapter_reward)
	state.call("_grant_automatic", "chapter:6", chapter_reward)
	_check(int(state.get("coins")) == gold + 60 + 140, "capítulo compartilhado pago uma vez")
	# Nível congelado: nenhum recibo ou presente automático ao somar XP.
	_fresh()
	var level_before := int(state.get("level"))
	var coins_before_xp := int(state.get("coins"))
	state.call("_add_player_xp", 10000)
	_check(int(state.get("level")) == level_before and int(state.get("coins")) == coins_before_xp, "XP não sobe nível nem paga moeda")
	_check((state.get("economy").granted as Dictionary).is_empty() and int(state.call("pending_reward_count")) == 0, "XP não cria recibo")
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
