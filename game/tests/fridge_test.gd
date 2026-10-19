extends SceneTree
## Etapa 06 do plano de economia: a despensa ligada à cozinha (Despensa → Geladeira).
## Cobre: capacidades 12/24/40/64, preço e requisito da geladeira, classificação dos itens, cozinha inicial
## inteira num jogo novo, lote que não cabe (sem XP nem contador), saldo pós-entrega das missões, alimentar
## libera espaço, snapshot de comida pendente, farinha/leite, presente de nível com a despensa cheia e saves antigos.
## --headless --path game -s res://tests/fridge_test.gd

var failures := 0
var state: Node
var database: Node
var toasts: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FRIDGE: " + message)


func _inv(id: String) -> int:
	return int(state.get("inventory").count(id))


func _progress() -> Object:
	return state.get("progress")


func _snapshot() -> String:
	return JSON.stringify(state.call("to_dict"))


## Jogo novo logo depois de conhecer a vovó: sítio aberto, sem geladeira nem fogão.
func _fresh() -> void:
	state.call("reset")
	state.set("unlimited_storage", false)
	state.get("inventory").counts.clear()
	_progress().owned["farm"] = true
	state.set("unlocked_plots", 4)
	state.call("_ensure_plots")


func _materials(upgrade: Dictionary) -> String:
	var keys: Array = (upgrade.get("materials", {}) as Dictionary).keys()
	keys.sort()
	var text := ""
	for key: String in keys:
		text += "%s%d" % [key, int(upgrade.materials[key])]
	return text


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	database = root.get_node("Database")
	root.get_node("Events").toast_requested.connect(func(text: String) -> void: toasts.append(text))
	_capacities()
	_classification()
	_kitchen_from_scratch()
	_batch_does_not_fit()
	_quest_balance()
	_feeding_frees_space()
	_pending_snapshot()
	_flour_and_milk()
	_level_gift_full()
	_legacy_saves()
	print("FRIDGE TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# --- capacidades e dados ------------------------------------------------------------------------------

func _capacities() -> void:
	_fresh()
	check(bool(state.call("storage_active", "fridge")), "jogo novo: a despensa já limita")
	check(int(state.call("storage_capacity", "fridge")) == 12, "provisório = 12")
	check(state.call("storage_name", "fridge") == "Despensa", "nome antes da geladeira")
	check(int(state.call("storage_floor", "fridge")) == 0, "jogo novo não tem piso legado")
	_progress().owned["fridge"] = true
	check(int(state.call("storage_capacity", "fridge")) == 24 and state.call("storage_name", "fridge") == "Geladeira", "geladeira = 24 e nome novo")
	_progress().owned["fridge_2"] = true
	check(int(state.call("storage_capacity", "fridge")) == 40, "fridge_2 = 40")
	_progress().owned["fridge_3"] = true
	check(int(state.call("storage_capacity", "fridge")) == 64, "fridge_3 = 64")
	state.call("_changed")
	check(int(state.call("storage_floor", "fridge")) == 0, "comprar não cria piso legado")
	var upgrades: Dictionary = database.get("progression").upgrades
	check(int(upgrades.fridge_2.storage_capacity) == 16 and int(upgrades.fridge_3.storage_capacity) == 24, "ampliações somam só a diferença (16 e 24)")
	check(int(upgrades.fridge_2.cost) == 100 and _materials(upgrades.fridge_2) == "bolt1plank2", "fridge_2: 100, tábua 2, parafuso 1")
	check(int(upgrades.fridge_3.cost) == 240 and _materials(upgrades.fridge_3) == "bolt1brick2plank4", "fridge_3: 240, tábua 4, tijolo 2, parafuso 1")
	check(upgrades.fridge_2.requirements.quests == ["main_4_bench"] and upgrades.fridge_2.requirements.owned == ["fridge"], "fridge_2: bancada + geladeira")
	check(upgrades.fridge_3.requirements.quests == ["own_business"] and upgrades.fridge_3.requirements.owned == ["fridge_2"], "fridge_3: negócio + fridge_2")
	check(upgrades.has("fridge_4") and not upgrades.fridge_3.materials.has("iron_band"), "o _3 não pede aro; o _4 é da etapa 18")
	var fridge: Dictionary = upgrades.fridge
	check(int(fridge.cost) == 40 and not fridge.has("materials") and fridge.requirements.quests == ["lais_first_crops"], "geladeira: 40 moedas, sem material, lais_first_crops")
	check(upgrades.stove.requirements.owned == ["fridge"], "o fogão continua pedindo a geladeira")
	var main: Dictionary = database.get("quests")
	check(main.main_2_fridge.goals[0].key == "fridge" and main.first_kitchen.goals[0].key == "stove", "main_2_fridge → first_kitchen intactas")
	var preview: Dictionary = state.call("storage_upgrade_preview", "fridge_2")
	check(int(preview.depot == "fridge") == 1, "prévia aponta a geladeira")
	# Armazém (etapa 07) e baú (etapa 08) já limitam, cada um com a própria capacidade.
	_fresh()
	check(bool(state.call("storage_active", "chest")) and int(state.call("storage_capacity", "chest")) == 12, "o baú tem a sacola de 12")


# --- classificação -------------------------------------------------------------------------------------

func _classification() -> void:
	_fresh()
	for id: String in ["carrot_snack", "pumpkin_mash", "vegetable_soup", "apple_biscuit", "cheese", "strawberry_pop", "strawberry_juice", "mashed_potato", "sweet_potato_chips", "mint_snack", "egg", "milk", "flour"]:
		check(state.call("storage_of", id) == "fridge", "%s mora na geladeira" % id)
	for id: String in ["dog_food", "bolt", "iron_band", "bed_gift", "map_piece_1"]:
		check(state.call("storage_of", id) == "", "%s é isento" % id)
	for id: String in ["herbs", "blueberry", "apple", "carrot"]:
		check(state.call("storage_of", id) == "silo", "%s continua no silo" % id)
	# Cada item pertence a um depósito só (a pergunta é por id, nunca duas contas).
	var counted := 0
	for id: String in database.get("items"):
		var depots := 0
		for depot: String in database.get("progression").storage:
			if state.call("storage_of", id) == depot:
				depots += 1
		counted += depots
		check(depots <= 1, "%s conta em um depósito só" % id)
	check(counted > 0, "há itens classificados")
	# Os alimentos estão classificados de forma explícita no JSON (não só pela categoria).
	for id: String in database.get("items"):
		var item: Dictionary = database.get("items")[id]
		if str(item.get("category", "")) == "food" and id != "dog_food":
			check(str(item.get("storage", "")) == "fridge", "%s tem storage explícito" % id)


# --- cozinha inicial inteira ----------------------------------------------------------------------------

func _ready_all(station_id: String) -> void:
	for entry: Dictionary in state.call("station", station_id).queue:
		entry["ready_at"] = 0.0


func _kitchen_from_scratch() -> void:
	_fresh()
	# Sem geladeira e sem fogão: comprar na ordem do jogo, sem ferramentas de dev além de concluir a missão.
	state.set("coins", 40 + 60 + 40)
	check(state.call("upgrade_error", "fridge") != "", "geladeira espera lais_first_crops")
	state.call("dev_complete_quest", "lais_first_crops")
	check(state.call("upgrade_error", "fridge") == "", "lais_first_crops libera a geladeira")
	# Inventário 12 → 24: com a despensa cheia, comprar amplia sem perder nada.
	state.get("inventory").add("carrot_snack", 12)
	check(state.call("storage_error", {"carrot_snack": 1}) != "", "12 cheio na despensa")
	var coins := int(state.get("coins"))
	check(state.call("buy_upgrade", "fridge") == "" and int(state.get("coins")) == coins - 40, "geladeira por 40, sem material")
	check(_inv("carrot_snack") == 12 and int(state.call("storage_capacity", "fridge")) == 24 and int(state.call("storage_space", "fridge")) == 12, "comprar cheio: 12 → 24 sem perder itens")
	state.get("inventory").remove("carrot_snack", 12)
	# Fogão e o primeiro petisco: tudo pelas ações reais.
	check(state.call("buy_upgrade", "stove") == "", "fogão depois da geladeira")
	state.get("inventory").add("carrot", 4)
	check(state.call("cook", "carrot_snack") == "", "primeiro lote de petisco")
	_ready_all("stove")
	check(int((state.call("collect", "stove") as Dictionary).get("carrot_snack", 0)) == 1, "coleta o primeiro petisco")
	check(state.call("cook", "carrot_snack") == "", "segundo lote de petisco")
	_ready_all("stove")
	check(int((state.call("collect", "stove") as Dictionary).get("carrot_snack", 0)) == 1 and _inv("carrot_snack") == 2, "coleta o segundo petisco")
	check(state.call("cook_error", "vegetable_soup") != "", "sopa pede ingredientes (cozinha segue acessível)")
	state.get("inventory").add("carrot", 2)
	state.get("inventory").add("potato", 1)
	check(state.call("cook", "vegetable_soup") == "", "sopa de legumes")
	_ready_all("stove")
	check(int((state.call("collect", "stove") as Dictionary).get("vegetable_soup", 0)) == 1, "coleta a sopa")


# --- lote que não cabe ------------------------------------------------------------------------------------

func _batch_does_not_fit() -> void:
	_fresh()
	state.get("progress").owned["fridge"] = true
	state.get("progress").owned["stove"] = true
	state.get("progress").owned["workbench"] = true
	state.get("inventory").add("carrot_snack", 23)  # 23/24: sobra 1 vaga
	state.get("inventory").add("apple", 2)
	state.get("inventory").add("carrot_snack", 1)  # precisa de 1 para a receita: 24/24
	check(state.call("cook", "apple_biscuit") == "", "biscoito começa (gasta ingredientes)")
	check(_inv("carrot_snack") == 23, "o petisco foi usado (23/24)")
	_ready_all("stove")
	var cooking := int(_progress().skills.get("cooking", 0))
	var produced := int(_progress().stat("produce"))
	var xp := int(state.get("player_xp")) if state.get("player_xp") != null else 0
	toasts.clear()
	var got: Dictionary = state.call("collect", "stove")
	check(got.is_empty(), "lote de 2 em 1 vaga não é coletado")
	check(_inv("apple_biscuit") == 0 and int(_progress().skills.get("cooking", 0)) == cooking, "sem item nem XP de habilidade")
	check(int(_progress().stat("produce")) == produced and (state.get("player_xp") == null or int(state.get("player_xp")) == xp), "sem contador nem XP do jogador")
	check(state.call("station", "stove").queue.size() == 1, "o lote continua pronto na fila")
	check(toasts.size() == 1 and toasts[0] == "Geladeira sem espaço", "um aviso com o motivo (%s)" % str(toasts))
	# Liberar espaço (vender não é automático): o jogador usa um petisco e o lote entra inteiro.
	state.get("inventory").remove("carrot_snack", 1)
	got = state.call("collect", "stove")
	check(int(got.get("apple_biscuit", 0)) == 2 and _inv("apple_biscuit") == 2, "com espaço, o lote entra inteiro")
	check(int(_progress().stat("produce")) == produced + 2, "o contador conta uma vez")
	# Nada de vender nem iniciar receita sozinho para abrir espaço.
	check(_inv("carrot_snack") == 22, "nada foi vendido nem gasto sozinho")


# --- missões que entregam comida --------------------------------------------------------------------------

func _quest_balance() -> void:
	_fresh()
	state.get("progress").owned["fridge"] = true
	var quests: Dictionary = database.get("quests")
	quests["__fr_quest"] = {"kind": "side", "name": "x", "goals": [{"type": "deliver", "key": "carrot_snack", "target": 2}], "rewards": {"items": {"cheese": 3}}, "requirements": {}, "requires": []}
	state.get("inventory").add("carrot_snack", 22)
	state.get("inventory").add("egg", 2)  # 24/24
	var before := _snapshot()
	var error: String = state.call("quest_error", "__fr_quest")
	check(error != "", "net +1 com a geladeira cheia bloqueia")
	check(state.call("claim_quest", "__fr_quest") == error and _snapshot() == before, "bloqueio não altera nada")
	state.get("inventory").remove("egg", 1)
	check(state.call("quest_error", "__fr_quest") == "", "entrega 2 e recebe 3 cabe com 1 vaga")
	check(state.call("claim_quest", "__fr_quest") == "" and _inv("carrot_snack") == 20 and _inv("cheese") == 3, "saldo pós-entrega correto")
	quests.erase("__fr_quest")


# --- alimentar libera espaço ------------------------------------------------------------------------------

func _feeding_frees_space() -> void:
	_fresh()
	state.get("inventory").add("carrot_snack", 12)  # despensa cheia, sem geladeira
	check(state.call("storage_error", {"carrot_snack": 1}) != "", "despensa cheia")
	check(bool(state.call("feed", "carrot_snack")) and _inv("carrot_snack") == 11, "alimentar tira o item")
	check(state.call("storage_error", {"carrot_snack": 1}) == "", "e libera a vaga")
	# Acima do piso legado também: capacidade 30 antiga, estoque 30.
	_fresh()
	_progress().owned["fridge"] = true
	state.get("economy").storage_floor["fridge"] = 30
	state.get("inventory").add("carrot_snack", 30)
	check(state.call("storage_error", {"carrot_snack": 1}) != "", "piso 30 cheio")
	check(bool(state.call("feed", "carrot_snack")) and state.call("storage_error", {"carrot_snack": 1}) == "", "alimentar libera acima do piso")
	# O Tiro continua comendo mesmo acima do teto.
	_fresh()
	state.get("inventory").add("carrot_snack", 40)
	check(int(state.call("storage_excess", "fridge")) == 28 and bool(state.call("feed", "carrot_snack")), "estoque acima do teto não impede alimentar")


# --- snapshot de comida pendente --------------------------------------------------------------------------

func _pending_snapshot() -> void:
	_fresh()
	state.get("progress").owned["fridge"] = true
	state.get("progress").owned["stove"] = true
	state.get("inventory").add("carrot", 2)
	check(state.call("cook", "carrot_snack") == "", "começa o petisco")
	var recipes: Dictionary = database.get("recipes")
	var saved: Dictionary = (recipes.carrot_snack as Dictionary).duplicate(true)
	recipes.carrot_snack["output"] = "cheese"
	recipes.carrot_snack["qty"] = 5
	_ready_all("stove")
	state.call("from_dict", JSON.parse_string(JSON.stringify(state.call("to_dict"))))
	var got: Dictionary = state.call("collect", "stove")
	check(int(got.get("carrot_snack", 0)) == 1 and _inv("cheese") == 0, "o lote pendente mantém a saída de quando começou")
	recipes.carrot_snack = saved


# --- farinha e leite ---------------------------------------------------------------------------------------

func _flour_and_milk() -> void:
	_fresh()
	state.call("dev_unlock_everything")
	for upgrade: String in ["fridge", "fridge_2", "fridge_3", "fridge_4", "fridge_5"]:
		state.get("progress").owned.erase(upgrade)
	state.get("economy").storage_floor.clear()
	state.get("inventory").counts.clear()
	var recipes: Dictionary = database.get("recipes")
	for recipe_id: String in ["flour", "milk", "eggs", "cheese"]:
		var output := str(recipes[recipe_id].output)
		check(state.call("storage_of", output) == "fridge", "%s sai na geladeira" % output)
	_progress().owned["fridge"] = true
	_progress().owned["mill"] = true
	state.get("inventory").add("egg", 23)  # 23/24
	state.get("inventory").add("wheat", 3)
	check(state.call("cook_error", "flour") == "", "farinha começa")
	check(state.call("cook", "flour") == "", "farinha começa de verdade")
	_ready_all("mill")
	state.get("inventory").add("milk", 1)  # 24/24
	var got: Dictionary = state.call("collect", "mill")
	check(got.is_empty() and state.call("station", "mill").queue.size() == 1, "farinha espera sem espaço")
	state.get("inventory").remove("egg", 2)
	got = state.call("collect", "mill")
	check(int(got.get("flour", 0)) >= 1, "farinha entra quando abre espaço")
	check(state.call("storage_error", {"milk": 1}) != "", "leite divide a mesma geladeira")


# --- presente de nível ---------------------------------------------------------------------------------------

func _level_gift_full() -> void:
	_fresh()
	state.get("inventory").add("carrot_snack", 12)  # despensa cheia
	var coins := int(state.get("coins"))
	var reward := {"coins": 20, "items": {"carrot_snack": 2}}
	state.call("_grant_automatic", "level:4", reward)
	state.call("_grant_automatic", "level:4", reward)
	check(int(state.get("coins")) == coins + 20, "moedas do nível pagas uma vez")
	check(_inv("carrot_snack") == 12 and int(state.call("pending_reward_total")) == 2, "a comida espera no recibo")
	check(str(state.call("pending_reward_hint")).contains("Despensa"), "o aviso fala em Despensa (%s)" % str(state.call("pending_reward_hint")))
	state.get("inventory").remove("carrot_snack", 2)
	var moved: Dictionary = state.call("claim_pending_rewards")
	check(int(moved.get("carrot_snack", 0)) == 2 and _inv("carrot_snack") == 12, "guarda quando abre espaço")


# --- saves antigos -------------------------------------------------------------------------------------------

func _v12(data: Dictionary) -> Dictionary:
	var copy: Dictionary = JSON.parse_string(JSON.stringify(data))
	copy.erase("economy")
	return copy


func _legacy_saves() -> void:
	# Geladeira antiga (30): não cai para 24.
	_fresh()
	_progress().owned["fridge"] = true
	state.get("inventory").add("carrot_snack", 28)
	state.call("from_dict", _v12(state.call("to_dict")))
	check(int(state.call("storage_floor", "fridge")) == 30 and int(state.call("storage_capacity", "fridge")) == 30, "geladeira antiga continua com 30")
	check(state.call("storage_error", {"carrot_snack": 2}) == "" and state.call("storage_error", {"carrot_snack": 3}) != "", "30 vale até o fim")
	# Geladeira_2 antiga (50) é maior que os 40 novos.
	_fresh()
	_progress().owned["fridge"] = true
	_progress().owned["fridge_2"] = true
	state.call("from_dict", _v12(state.call("to_dict")))
	check(int(state.call("storage_capacity", "fridge")) == 50, "fridge_2 antiga mantém 50")
	# Sem geladeira e com 40 comidas: estoque preservado, entradas bloqueiam, saídas funcionam.
	_fresh()
	state.get("inventory").add("carrot_snack", 40)
	state.call("from_dict", _v12(state.call("to_dict")))
	check(_inv("carrot_snack") == 40 and int(state.call("storage_capacity", "fridge")) == 12 and int(state.call("storage_excess", "fridge")) == 28, "estoque de 40 preservado, capacidade 12")
	check(state.call("storage_error", {"cheese": 1}) != "", "entradas bloqueadas")
	check(state.call("sell", "carrot_snack", 10) == "" and _inv("carrot_snack") == 30, "vender continua funcionando")
