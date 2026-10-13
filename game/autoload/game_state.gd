extends Node
## Estado global do jogador (autoload "GameState").
##
## Única fonte da verdade para dados que sobrevivem entre cenas e sessões,
## e ponto de entrada das ações do jogo (alimentar, plantar, cozinhar, comprar,
## entregar pedidos, concluir missões...). Toda ação valida, altera e emite
## Events.state_changed (o SaveManager salva sozinho).
## Não acessa disco: o SaveManager usa to_dict()/from_dict().
## Regras numéricas e conteúdo vêm do Database (game/data/*.json).
##
## Convenção das ações: devolvem "" quando deu certo ou o motivo da falha
## (texto pronto para toast). Cada ação tem um *_error() que a UI usa para
## desabilitar botões com o mesmo motivo.

var dog := DogState.new()
var inventory := Inventory.new()
var stations: Dictionary = {}  # station_id -> StationState
var animals: Dictionary = {}  # variedade -> quantidade comprada
## Canteiros: crop, planted_at e ready_at (Unix). Quantidade em config "farm.plots".
var plots: Array[Dictionary] = []
## Terrenos comprados (em ordem fixa). Só valem depois da escritura do sítio ("farm").
var unlocked_plots: int = 0
var coins: int = 0
var xp: int = 0
var level: int = 1
## Atributos, aquisições, missões, coleção, contadores e rota em andamento.
var progress := ProgressionState.new()


func now() -> float:
	return Time.get_unix_time_from_system()


func reset() -> void:
	dog = DogState.new()
	dog.setup(now())
	inventory = Inventory.new()
	var start_items: Dictionary = Database.start.get("inventory", {})
	for id: String in start_items:
		inventory.add(id, int(start_items[id]))
	stations = {}
	animals = {}
	_ensure_stations()
	plots = []
	unlocked_plots = int(Database.farm.get("initial_plots", 3))
	_ensure_plots()
	coins = int(Database.start.get("coins", 0))
	xp = 0
	level = 1
	progress = ProgressionState.new()
	progress.setup()
	_mark_all_seen()
	_changed()


# --- Ações do Tiro ---------------------------------------------------------

func feed(item_id: String) -> bool:
	var useful := _need_is_low("hunger")
	var effects: Dictionary = Database.items.get(item_id, {}).get("feed", {})
	if effects.is_empty() or not inventory.remove(item_id):
		return false
	dog.apply(effects, now())
	progress.count("feed")
	_care_reward("feed", useful)
	_changed()
	Events.dog_action.emit(&"feed")
	return true


func pet() -> void:
	dog.apply(Database.actions.get("pet", {}), now())
	dog.affection += 1
	_changed()
	Events.dog_action.emit(&"pet")


func play() -> bool:
	if dog.sleeping or dog.get_need("energy", now()) < 15.0:
		return false
	var useful := _need_is_low("happiness")
	dog.apply(Database.actions.get("play", {}), now())
	dog.affection += 2
	progress.count("play")
	_care_reward("play", useful)
	_changed()
	Events.dog_action.emit(&"play")
	return true


func bathe() -> void:
	var useful := _need_is_low("hygiene")
	dog.apply(Database.actions.get("bathe", {}), now())
	progress.count("bathe")
	_care_reward("bathe", useful)
	_changed()
	Events.dog_action.emit(&"bathe")


func set_sleeping(value: bool) -> void:
	dog.set_sleeping(value, now())
	_changed()


## Ajuda sem moedas para nunca travar o cuidado com o Tiro (recarga em progression.json).
func emergency_food() -> String:
	for id: String in inventory.counts:
		if Database.items.get(id, {}).has("feed"):
			return "Você ainda tem comida na mochila"
	var wait := progress.cooldown_left("emergency_food", now())
	if wait > 0:
		return "A ajuda volta em " + TimeText.short(wait)
	var settings: Dictionary = Database.progression.settings
	inventory.add("dog_food", int(settings.emergency_food_amount))
	progress.cooldowns["emergency_food"] = now() + float(settings.emergency_food_cooldown)
	_changed()
	return ""


## Cuidar só dá XP quando o Tiro precisa (abaixo do limite) e fora da recarga.
func _need_is_low(need_id: String) -> bool:
	return dog.get_need(need_id, now()) < float(Database.progression.settings.care_need_threshold)


func _care_reward(action_id: String, useful: bool) -> void:
	var key := "care:" + action_id
	if not useful or progress.cooldown_left(key, now()) > 0:
		return
	var settings: Dictionary = Database.progression.settings
	progress.cooldowns[key] = now() + float(settings.care_reward_cooldown)
	_gain_xp(action_id)


# --- Produção (fogão, bancada, forno, ateliê) ----------------------------------

func station(station_id: String) -> StationState:
	_ensure_stations()
	return stations[station_id]


## Espaços na fila: base de config.json + melhorias em "slot_upgrades".
func station_slots(id: String) -> int:
	var data: Dictionary = Database.stations.get(id, {})
	var result := int(data.get("slots", 1))
	for upgrade_id: String in data.get("slot_upgrades", {}):
		if has_upgrade(upgrade_id):
			result += int(data["slot_upgrades"][upgrade_id])
	return result


## Coloca uma receita na fila. Retorna "" se deu certo ou o motivo da falha.
func cook(recipe_id: String) -> String:
	var error := cook_error(recipe_id)
	if error != "":
		return error
	var recipe: Dictionary = Database.recipes[recipe_id]
	var station_id: String = recipe.station
	inventory.remove_all(recipe_inputs(recipe_id))
	station(station_id).enqueue(recipe_id, float(recipe.seconds), now())
	station(station_id).queue.back()["qty"] = recipe_quantity(recipe_id)
	_changed()
	if Database.stations[station_id].get("kind", "") == "animal":
		Events.world_activity.emit(&"feed_animal", station_id, -1)
	return ""


## A mesma validação para alimentação dos animais e fabricação nas estações.
func cook_error(recipe_id: String) -> String:
	if not Database.recipes.has(recipe_id):
		return "Receita desconhecida"
	var recipe: Dictionary = Database.recipes[recipe_id]
	var station_id: String = recipe.get("station", "")
	if not has_upgrade(station_id):
		return "Compre %s no seu lugar do mapa" % Database.stations.get(station_id, {}).get("name", station_id)
	var reason := content_error("recipe", recipe_id, recipe)
	if reason != "":
		return reason
	var target := station(station_id)
	if Database.stations[station_id].get("kind", "") == "animal" and animal_count(station_id) == 0:
		return "Compre um animal para começar"
	if target.queue.size() >= station_slots(station_id):
		return "Fila cheia"
	if not inventory.has_all(recipe_inputs(recipe_id)):
		return "Faltam ingredientes"
	return ""


## Coleta tudo o que está pronto na estação. Retorna os itens recebidos.
func collect(station_id: String) -> Dictionary:
	var received := {}
	for entry: Dictionary in station(station_id).take_ready_batches(now()):
		var recipe_id: String = entry.recipe
		var recipe: Dictionary = Database.recipes.get(recipe_id, {})
		if recipe.is_empty():
			continue  # receita removida do JSON: descarta sem travar a fila
		var output: String = recipe["output"]
		var qty := int(entry.get("qty", recipe.get("qty", 1)))
		inventory.add(output, qty)
		progress.count("produce:" + output, qty)
		progress.count("produce", qty)
		_discover("recipe:" + recipe_id, str(recipe.get("skill", "cooking")), int(recipe.get("skill_xp", 10)))
		received[output] = int(received.get(output, 0)) + qty
		_gain_xp("animal" if Database.stations.get(station_id, {}).get("kind", "") == "animal" else "cook")
	if not received.is_empty():
		_changed()
		Events.world_activity.emit(&"collect", station_id, -1)
	return received


func animal_count(station_id: String) -> int:
	return animal_roster(station_id).size()


func animal_roster(station_id: String) -> Array[String]:
	var result: Array[String] = []
	for id: String in Database.animals:
		if Database.animals[id].station == station_id:
			for i in int(animals.get(id, 0)):
				result.append(id)
	return result


func buy_animal_error(id: String) -> String:
	if not Database.animals.has(id):
		return "Animal desconhecido"
	var data: Dictionary = Database.animals[id]
	if not has_upgrade(data.station):
		return "Compre o abrigo primeiro"
	if animal_count(data.station) >= int(Database.stations[data.station].animal_capacity):
		return "Abrigo cheio"
	if coins < int(data.price):
		return "Faltam moedas"
	return ""


func buy_animal(id: String) -> String:
	var error := buy_animal_error(id)
	if error != "":
		return error
	coins -= int(Database.animals[id].price)
	animals[id] = int(animals.get(id, 0)) + 1
	_changed()
	Events.world_activity.emit(&"buy_upgrade", str(Database.animals[id].station), -1)
	return ""


func recipe_quantity(recipe_id: String) -> int:
	var recipe: Dictionary = Database.recipes[recipe_id]
	var factor := animal_count(recipe.station) if Database.stations[recipe.station].get("kind", "") == "animal" else 1
	return int(recipe.get("qty", 1)) * factor


func recipe_inputs(recipe_id: String) -> Dictionary:
	var recipe: Dictionary = Database.recipes[recipe_id]
	var factor := animal_count(recipe.station) if Database.stations[recipe.station].get("kind", "") == "animal" else 1
	var result: Dictionary = recipe.get("inputs", {}).duplicate()
	for id: String in result:
		result[id] = int(result[id]) * factor
	return result


# --- Horta (sítio) ---------------------------------------------------------

func plot(index: int) -> Dictionary:
	_ensure_plots()
	return plots[index]


## Canteiros utilizáveis: os comprados, ou só o emprestado antes da escritura.
func accessible_plots() -> int:
	return unlocked_plots if has_upgrade("farm") else int(Database.farm.get("borrowed_plots", 1))


## "locked", "empty", "growing" ou "ready".
func plot_status(index: int) -> String:
	if index < 0 or index >= accessible_plots():
		return "locked"
	var target := plot(index)
	if target["crop"] == "":
		return "empty"
	return "ready" if float(target["ready_at"]) <= now() else "growing"


## Planta no canteiro. Retorna "" se deu certo ou o motivo da falha.
func plant(index: int, crop_id: String) -> String:
	if plot_status(index) == "locked":
		return "Compre este terreno primeiro"
	if not Database.crops.has(crop_id):
		return "Semente desconhecida"
	var reason := content_error("crop", crop_id, Database.crops[crop_id])
	if reason != "":
		return reason
	if plot_status(index) != "empty":
		return "Canteiro ocupado"
	var planted_at := now()
	plots[index] = { "crop": crop_id, "planted_at": planted_at, "ready_at": planted_at + float(Database.crops[crop_id].get("seconds", 60)) }
	_changed()
	return ""


## Colhe um canteiro pronto. Retorna os itens recebidos (vazio se não estava pronto).
func harvest(index: int) -> Dictionary:
	if plot_status(index) != "ready":
		return {}
	var crop_id: String = plot(index)["crop"]
	var crop: Dictionary = Database.crops.get(crop_id, {})
	var received: Dictionary = crop.get("yield", {})
	progress.count("harvest")
	progress.count("harvest:" + crop_id)
	_discover("crop:" + crop_id, "agriculture", int(crop.get("skill_xp", 10)))
	coins += int(crop.get("coins", 0))
	for item_id: String in received:
		inventory.add(item_id, int(received[item_id]))
	plots[index] = { "crop": "", "ready_at": 0.0 }
	_gain_xp("harvest")
	_changed()
	Events.world_activity.emit(&"harvest", crop_id, index)
	return received


## Progresso calculado por timestamps; continua com o jogo fechado.
func plot_progress(index: int) -> float:
	if plot_status(index) in ["locked", "empty"]:
		return 0.0
	var target := plot(index)
	var end := float(target["ready_at"])
	var start := float(target.get("planted_at", end - float(Database.crops.get(target["crop"], {}).get("seconds", 60))))
	return clampf((now() - start) / maxf(end - start, 0.001), 0.0, 1.0)


func plot_cost(index: int) -> int:
	var costs: Array = Database.farm.get("unlock_costs", [])
	return int(costs[index]) if index >= 0 and index < costs.size() else -1


## Expansão em ordem fixa. Valida novamente no momento da compra.
func buy_plot(index: int) -> String:
	if not has_upgrade("farm"):
		return "Compre a escritura do sítio primeiro"
	if index < 0 or index >= int(Database.farm.get("plots", 0)):
		return "Terreno inválido"
	if index < unlocked_plots:
		return "Este terreno já é seu"
	if index != unlocked_plots:
		return "Compre o terreno %d primeiro" % (unlocked_plots + 1)
	var cost := plot_cost(index)
	if cost < 0:
		return "Terreno indisponível"
	if coins < cost:
		return "Faltam %d moedas" % (cost - coins)
	coins -= cost
	unlocked_plots += 1
	_changed()
	return ""


func _ensure_plots() -> void:
	while plots.size() < int(Database.farm.get("plots", 0)):
		plots.append({ "crop": "", "ready_at": 0.0 })


# --- Nível do jogador e atributos ------------------------------------------------

func xp_to_next_level() -> int:
	return int(Database.xp.get("per_level", 100)) * level


func skill_info(id: String) -> Dictionary:
	return progress.skill_info(id)


func _gain_xp(action: String) -> void:
	_add_player_xp(int(Database.xp.get(action, 0)))


func _add_player_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		level += 1
		Events.toast_requested.emit("Nível %d!" % level)


func _award_skill(id: String, amount: int) -> void:
	if not Database.progression.skills.has(id) or amount <= 0:
		return
	var before := progress.skill_level(id)
	progress.skills[id] = int(progress.skills.get(id, 0)) + amount
	var after := progress.skill_level(id)
	if after > before and progress.skills_visible():
		Events.toast_requested.emit("%s · nível %d!" % [Database.progression.skills[id].name, after])


## Primeira vez (colher uma cultura, fazer uma receita) vale XP multiplicado.
func _discover(key: String, skill: String, amount: int) -> void:
	var multiplier := 1 if progress.discoveries.has(key) else int(Database.progression.settings.first_discovery_multiplier)
	progress.discoveries[key] = true
	_award_skill(skill, amount * multiplier)


func _apply_rewards(rewards: Dictionary) -> void:
	coins += int(rewards.get("coins", 0))
	for id: String in rewards.get("items", {}):
		inventory.add(id, int(rewards["items"][id]))
	for id: String in rewards.get("skill_xp", {}):
		_award_skill(id, int(rewards["skill_xp"][id]))
	for id: String in rewards.get("collections", []):
		progress.collection[id] = true
	for id: String in rewards.get("unlocks", []):
		progress.unlocks[id] = true


# --- Aquisições (Construir) -------------------------------------------------------

func has_upgrade(id: String) -> bool:
	return progress.has_upgrade(id)


func requirement_error(requirements: Dictionary) -> String:
	return progress.requirement_error(requirements)


func content_error(kind: String, id: String, data: Dictionary) -> String:
	return progress.content_error(kind, id, data)


func current_chapter() -> Dictionary:
	return progress.current_chapter()


func upgrade_error(id: String) -> String:
	var data: Dictionary = Database.progression.upgrades.get(id, {})
	if data.is_empty():
		return "Melhoria desconhecida"
	if has_upgrade(id):
		return "Já adquirido"
	var reason := requirement_error(data.get("requirements", {}))
	if reason != "":
		return reason
	if coins < int(data.get("cost", 0)):
		return "Faltam %d moedas" % (int(data.cost) - coins)
	if not inventory.has_all(data.get("materials", {})):
		return "Faltam materiais"
	return ""


func buy_upgrade(id: String) -> String:
	var reason := upgrade_error(id)
	if reason != "":
		return reason
	var data: Dictionary = Database.progression.upgrades[id]
	inventory.remove_all(data.get("materials", {}))
	coins -= int(data.get("cost", 0))
	_grant_upgrade(id)
	_apply_rewards({"skill_xp": data.get("skill_xp", {})})
	progress.count("build")
	_add_player_xp(int(data.get("player_xp", 10)))
	_changed()
	Events.world_activity.emit(&"build", id, -1)
	return ""


func _grant_upgrade(id: String) -> void:
	progress.owned[id] = true
	if id == "farm":
		unlocked_plots = maxi(unlocked_plots, int(Database.farm.initial_plots))


# --- Feira (venda direta e encomendas) --------------------------------------------

func sell(item_id: String, amount: int = 1) -> String:
	var price := int(Database.items.get(item_id, {}).get("sell_price", 0))
	if amount <= 0 or price <= 0:
		return "Venda inválida"
	if not inventory.remove(item_id, amount):
		return "Você não tem essa quantidade"
	coins += price * amount
	progress.count("trade")
	progress.count("sold", amount)
	_award_skill("commerce", int(Database.items[item_id].get("trade_xp", 1)) * amount)
	_changed()
	return ""


func order_error(id: String) -> String:
	var order: Dictionary = Database.progression.orders.get(id, {})
	if order.is_empty():
		return "Pedido desconhecido"
	var reason := requirement_error(order.get("requirements", {}))
	if reason != "":
		return reason
	var wait := progress.cooldown_left("order:" + id, now())
	if wait > 0:
		return "Novo pedido em " + TimeText.short(wait)
	if not inventory.has_all(order.inputs):
		return "Faltam produtos"
	return ""


func fulfill_order(id: String) -> String:
	var reason := order_error(id)
	if reason != "":
		return reason
	var order: Dictionary = Database.progression.orders[id]
	inventory.remove_all(order.inputs)
	progress.cooldowns["order:" + id] = now() + float(order.get("cooldown", 0))
	progress.count("trade")
	progress.count("orders")
	progress.count("order:" + id)
	_apply_rewards(order.rewards)
	_changed()
	return ""


# --- Rotas (passeios e mineração) --------------------------------------------------

func activity_error(id: String) -> String:
	if not progress.activity.is_empty():
		return "Conclua a atividade em andamento"
	var data: Dictionary = Database.progression.activities.get(id, {})
	if data.is_empty():
		return "Rota desconhecida"
	return requirement_error(data.get("requirements", {}))


func start_activity(id: String) -> String:
	var reason := activity_error(id)
	if reason != "":
		return reason
	var start := now()
	progress.activity = {"id": id, "started_at": start, "ready_at": start + float(Database.progression.activities[id].seconds)}
	_changed()
	return ""


## Segundos até a rota em andamento terminar (0 = pronta ou nenhuma).
func activity_remaining() -> int:
	if progress.activity.is_empty():
		return 0
	return maxi(0, int(ceil(float(progress.activity.ready_at) - now())))


func collect_activity() -> String:
	if progress.activity.is_empty():
		return "Nenhuma atividade em andamento"
	if activity_remaining() > 0:
		return "A atividade ainda está em andamento"
	var id: String = progress.activity.id
	var data: Dictionary = Database.progression.activities.get(id, {})
	progress.activity = {}
	if data.is_empty():
		_changed()
		return "Rota indisponível"
	progress.count("activity:" + id)
	progress.count("explore")
	_apply_rewards(data.rewards)
	_add_player_xp(int(data.get("player_xp", 5)))
	_changed()
	return ""


# --- Missões ----------------------------------------------------------------------

func quest_unlocked(id: String) -> bool:
	return progress.quest_unlocked(id)


## Valor atual de um objetivo de missão (tipos: owned, skill, deliver, stat).
func goal_value(goal: Dictionary) -> int:
	match str(goal.type):
		"owned":
			return 1 if has_upgrade(goal.key) else 0
		"skill":
			return progress.skill_level(goal.key)
		"deliver", "have":
			return inventory.count(goal.key)
		"coins":
			return coins
		"chapter":
			return progress.chapter_index()
		"stat":
			# "fresh": conta só o que foi feito depois que o passo da história começou.
			if goal.get("fresh", false):
				return maxi(0, progress.stat(goal.key) - int(progress.step.get("base", {}).get(goal.key, progress.stat(goal.key))))
			return progress.stat(goal.key)
	return 0


func quest_error(id: String) -> String:
	if not quest_unlocked(id):
		return "Conclua as missões anteriores"
	if progress.claimed_quests.has(id):
		return "Recompensa já recebida"
	for goal: Dictionary in Database.quests[id].goals:
		if goal_value(goal) < int(goal.get("target", 1)):
			return "Objetivos pendentes"
	if not inventory.has_all(_quest_deliveries(id)):
		return "Faltam itens para entregar"
	return ""


func claim_quest(id: String) -> String:
	var reason := quest_error(id)
	if reason != "":
		return reason
	inventory.remove_all(_quest_deliveries(id))
	_finish_quest(id)
	_changed()
	return ""


## Missões com objetivos cumpridos e recompensa ainda não recebida.
func ready_quest_count() -> int:
	var total := 0
	for id: String in Database.quests:
		if quest_error(id) == "":
			total += 1
	return total


func _quest_deliveries(id: String) -> Dictionary:
	var deliveries := {}
	for goal: Dictionary in Database.quests[id].goals:
		if goal.type == "deliver":
			deliveries[goal.key] = int(deliveries.get(goal.key, 0)) + int(goal.target)
	return deliveries


func _finish_quest(id: String) -> void:
	var chapter := progress.chapter_index()
	progress.claimed_quests[id] = true
	_apply_rewards(Database.quests[id].rewards)
	progress.count("quests")
	_add_player_xp(int(Database.quests[id].get("player_xp", 15)))
	Events.quest_completed.emit(id)
	if Database.quests[id].get("kind", "side") == "main" and progress.chapter_index() > chapter:
		_apply_rewards(Database.progression.chapters[chapter - 1].get("rewards", {}))
		Events.chapter_completed.emit(chapter)


# --- Novidades (revelar aos poucos) ---------------------------------------------------

## O que a história acabou de revelar e o jogador ainda não viu (chaves de ProgressionState.unlocked_keys).
func new_unlocks() -> Array[String]:
	var result: Array[String] = []
	for key in progress.unlocked_keys():
		if not progress.seen.has(key):
			result.append(key)
	return result


func mark_seen(keys: Array[String]) -> void:
	for key in keys:
		progress.seen[key] = true
	_changed()


func _mark_all_seen() -> void:
	for key in progress.unlocked_keys():
		progress.seen[key] = true


# --- Diárias e semanais -------------------------------------------------------------
# Modelos em data/routines.json. A cada dia (ou semana, a partir de segunda) sorteia
# `count` modelos liberados; o sorteio usa o período como semente, então é o mesmo
# ao reabrir o jogo. O progresso é o contador do objetivo menos o valor no início.

## Período atual em hora local: "AAAA-MM-DD" do dia ou da segunda-feira da semana.
func routine_period(kind: String, at: float = -1.0) -> String:
	var local := _local_time(at)
	if kind == "weekly":
		local -= _days_into_week(local) * 86400
	return Time.get_date_string_from_unix_time(local)


## Segundos até as missões do tipo se renovarem.
func routine_seconds_left(kind: String) -> int:
	var local := _local_time()
	var left := 86400 - local % 86400
	if kind == "weekly":
		left += (6 - _days_into_week(local)) * 86400
	return left


func routines_unlocked(kind: String) -> bool:
	return progress.feature_unlocked(kind)


## Missões do período (sorteia ao virar o dia ou a semana).
func routine_ids(kind: String) -> Array[String]:
	_ensure_routines(kind)
	var ids: Array[String] = []
	ids.assign(progress.routines.get(kind, {}).get("ids", []))
	return ids


func routine_data(kind: String, id: String) -> Dictionary:
	return Database.routines.get(kind, {}).get("missions", {}).get(id, {})


func routine_value(kind: String, id: String) -> int:
	var key: String = routine_data(kind, id).get("goal", {}).get("key", "")
	var base: Dictionary = progress.routines.get(kind, {}).get("base", {})
	return maxi(0, progress.stat(key) - int(base.get(key, 0)))


func routine_claimed(kind: String, id: String) -> bool:
	return progress.routines.get(kind, {}).get("claimed", {}).has(id)


func routine_error(kind: String, id: String) -> String:
	if not id in routine_ids(kind):
		return "Esta missão já passou"
	if routine_claimed(kind, id):
		return "Recompensa já recebida"
	if routine_value(kind, id) < int(routine_data(kind, id).goal.get("target", 1)):
		return "Objetivo pendente"
	return ""


func claim_routine(kind: String, id: String) -> String:
	var reason := routine_error(kind, id)
	if reason != "":
		return reason
	var data := routine_data(kind, id)
	progress.routines[kind].claimed[id] = true
	_apply_rewards(data.get("rewards", {}))
	progress.count("routines")
	_add_player_xp(int(data.get("player_xp", 10 if kind == "daily" else 30)))
	_changed()
	return ""


func ready_routine_count() -> int:
	var total := 0
	for kind: String in Database.routines:
		if routines_unlocked(kind):
			for id in routine_ids(kind):
				if routine_error(kind, id) == "":
					total += 1
	return total


func _ensure_routines(kind: String) -> void:
	if not routines_unlocked(kind):
		return
	var period := routine_period(kind)
	if progress.routines.get(kind, {}).get("period", "") == period:
		return
	var missions: Dictionary = Database.routines[kind].missions
	var pool: Array[String] = []
	for id: String in missions:
		if requirement_error(missions[id].get("requirements", {})) == "":
			pool.append(id)
	pool.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind + period)
	var ids: Array[String] = []
	while ids.size() < int(Database.routines[kind].get("count", 3)) and not pool.is_empty():
		ids.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	var base := {}
	for id in ids:
		var key: String = missions[id].goal.key
		base[key] = progress.stat(key)
	progress.routines[kind] = {"period": period, "ids": ids, "base": base, "claimed": {}}
	# Adiado: pode ser chamado durante a montagem de uma tela.
	_changed.call_deferred()


func _local_time(at: float = -1.0) -> int:
	return int(now() if at < 0.0 else at) + int(Time.get_time_zone_from_system().get("bias", 0)) * 60


## 0 = segunda ... 6 = domingo.
func _days_into_week(local: int) -> int:
	return (int(Time.get_datetime_dict_from_unix_time(local).weekday) + 6) % 7


# --- Ferramentas de desenvolvimento (só na versão dev) --------------------------------
# Usadas pelo painel DEV (scripts/ui/dev_panel.gd). Na versão publicada (prod) não fazem
# nada. Alteram o estado por aqui para respeitar a regra "estado só no GameState".

func dev_add_coins(amount: int) -> void:
	if not BuildInfo.is_dev():
		return
	coins = maxi(0, coins + amount)
	_changed()


## Soma a quantidade em todos os itens da categoria ("" = todos).
func dev_add_items(amount: int, category: String = "") -> void:
	if not BuildInfo.is_dev():
		return
	for id: String in Database.items:
		if category == "" or Database.items[id].get("category", "") == category:
			inventory.add(id, amount)
	_changed()


## Sobe todos os atributos para pelo menos este nível.
func dev_set_skills(target_level: int) -> void:
	if not BuildInfo.is_dev():
		return
	for id: String in Database.progression.skills:
		_dev_skill_at_least(id, target_level)
	_changed()


func dev_fill_needs() -> void:
	if not BuildInfo.is_dev():
		return
	var full := {}
	for id: String in Database.needs:
		full[id] = 100.0
	dog.apply(full, now())
	_changed()


## Libera uma melhoria e tudo o que ela exige (melhorias, missões e atributos), sem custo.
func dev_grant_upgrade(id: String) -> void:
	if not BuildInfo.is_dev():
		return
	_dev_satisfy_upgrade(id)
	_changed()


## Pula para o começo do capítulo: tudo dos capítulos anteriores fica liberado.
func dev_jump_to_chapter(index: int) -> void:
	if not BuildInfo.is_dev():
		return
	var chapters: Array = Database.progression.chapters
	for i in mini(index, chapters.size()):
		_dev_satisfy_upgrade(str(chapters[i].target))
		for id in progress.main_quests(i + 1):
			_dev_complete_quest(id)
	_changed()


## Conclui a missão (e as anteriores), dando as recompensas, sem cumprir objetivos.
func dev_complete_quest(id: String) -> void:
	if not BuildInfo.is_dev():
		return
	_dev_complete_quest(id)
	_changed()


## Tudo liberado: melhorias, terrenos, missões e atributos no máximo.
func dev_unlock_everything() -> void:
	if not BuildInfo.is_dev():
		return
	for id: String in Database.progression.upgrades:
		_dev_satisfy_upgrade(id)
	for id: String in Database.quests:
		_dev_complete_quest(id)
	for id: String in Database.progression.skills:
		_dev_skill_at_least(id, int(Database.progression.settings.max_skill_level))
	# Roupas também vêm das semanais (sorteadas): entrega a coleção inteira.
	for id: String in Database.collections:
		progress.collection[id] = true
	unlocked_plots = int(Database.farm.get("plots", 0))
	_changed()


## Recomeça as diárias e semanais do período (mesmas missões, progresso e recompensas zerados).
func dev_restart_routines() -> void:
	if not BuildInfo.is_dev():
		return
	progress.routines.clear()
	_changed()


## Termina agora plantações, estações, rota e recargas.
func dev_finish_timers() -> void:
	if not BuildInfo.is_dev():
		return
	var t := now()
	for entry: Dictionary in plots:
		if entry["crop"] != "":
			entry["ready_at"] = minf(float(entry["ready_at"]), t)
			entry["planted_at"] = minf(float(entry.get("planted_at", t)), float(entry["ready_at"]) - 1.0)
	for id: String in stations:
		for entry: Dictionary in stations[id].queue:
			entry["ready_at"] = minf(float(entry["ready_at"]), t)
	if not progress.activity.is_empty():
		progress.activity["ready_at"] = minf(float(progress.activity.ready_at), t)
	progress.cooldowns.clear()
	_changed()


## Viagem no tempo: tudo acontece como se `seconds` tivessem passado com o jogo fechado
## (necessidades caem, plantas crescem, filas andam).
func dev_advance_time(seconds: float) -> void:
	if not BuildInfo.is_dev():
		return
	dog.updated_at -= seconds
	for entry: Dictionary in plots:
		if entry["crop"] != "":
			entry["ready_at"] = float(entry["ready_at"]) - seconds
			if entry.has("planted_at"):
				entry["planted_at"] = float(entry["planted_at"]) - seconds
	for id: String in stations:
		for entry: Dictionary in stations[id].queue:
			entry["ready_at"] = float(entry["ready_at"]) - seconds
	progress.shift_time(seconds)
	_changed()


func _dev_skill_at_least(id: String, target_level: int) -> void:
	progress.skills[id] = maxi(int(progress.skills.get(id, 0)), progress.xp_for_level(target_level))


func _dev_satisfy(requirements: Dictionary) -> void:
	if progress.chapter_index() < int(requirements.get("chapter", 1)):
		dev_jump_to_chapter(int(requirements.chapter) - 1)
	for id: String in requirements.get("owned", []):
		_dev_satisfy_upgrade(id)
	for id: String in requirements.get("quests", []):
		_dev_complete_quest(id)
	for id: String in requirements.get("skills", {}):
		_dev_skill_at_least(id, int(requirements["skills"][id]))


func _dev_satisfy_upgrade(id: String) -> void:
	if has_upgrade(id) or not Database.progression.upgrades.has(id):
		return
	_dev_satisfy(Database.progression.upgrades[id].get("requirements", {}))
	_grant_upgrade(id)


func _dev_complete_quest(id: String) -> void:
	if progress.claimed_quests.has(id) or not Database.quests.has(id):
		return
	var quest: Dictionary = Database.quests[id]
	if quest.get("kind", "side") == "main":
		for chapter in range(1, int(quest.chapter) + 1):
			for previous in progress.main_quests(chapter):
				if previous == id:
					break
				if not progress.claimed_quests.has(previous):
					_finish_quest(previous)
	else:
		_dev_satisfy(quest.get("requirements", {}))
		for required: String in quest.get("requires", []):
			_dev_complete_quest(required)
	_finish_quest(id)


# --- Save ------------------------------------------------------------------

func to_dict() -> Dictionary:
	var station_data := {}
	for id: String in stations:
		station_data[id] = stations[id].to_dict()
	return {
		"dog": dog.to_dict(),
		"inventory": inventory.to_dict(),
		"stations": station_data,
		"animals": animals.duplicate(),
		"plots": plots,
		"unlocked_plots": unlocked_plots,
		"coins": coins,
		"xp": xp,
		"level": level,
		"progression": progress.to_dict(),
	}


func from_dict(data: Dictionary) -> void:
	if data.is_empty():
		reset()
		return
	dog = DogState.new()
	dog.from_dict(data.get("dog", {}), now())
	inventory = Inventory.new()
	inventory.from_dict(data.get("inventory", {}))
	stations = {}
	var station_data: Dictionary = data.get("stations", {})
	for id: String in station_data:
		var loaded := StationState.new()
		loaded.from_dict(station_data[id])
		stations[id] = loaded
	_ensure_stations()
	plots = []
	for entry: Dictionary in data.get("plots", []):
		var loaded_plot := { "crop": str(entry.get("crop", "")), "ready_at": float(entry.get("ready_at", 0.0)) }
		if entry.has("planted_at"):
			loaded_plot["planted_at"] = float(entry["planted_at"])
		plots.append(loaded_plot)
	# Saves anteriores à expansão mantêm todos os canteiros que já possuíam (ver SaveManager._migrate).
	unlocked_plots = clampi(int(data.get("unlocked_plots", maxi(plots.size(), int(Database.farm.get("initial_plots", 3))))), 0, int(Database.farm.get("plots", 0)))
	_ensure_plots()
	coins = int(data.get("coins", 0))
	xp = int(data.get("xp", 0))
	level = int(data.get("level", 1))
	progress = ProgressionState.new()
	progress.from_dict(data.get("progression", {}))
	animals = {}
	if data.has("animals"):
		for id: String in Database.animals:
			if has_upgrade(Database.animals[id].station):
				var remaining := int(Database.stations[Database.animals[id].station].animal_capacity) - animal_count(Database.animals[id].station)
				animals[id] = clampi(int(data.animals.get(id, 0)), 0, remaining)
	else:
		# Na versão anterior cada abrigo comprado já mostrava dois animais.
		for id: String in Database.animals:
			if has_upgrade(Database.animals[id].station) and Database.animals[id].get("legacy", false):
				animals[id] = 2
	# Save de antes das novidades: o que já estava aberto não vira "Novo!".
	if not data.get("progression", {}).has("seen"):
		_mark_all_seen()
	_changed()


func _ensure_stations() -> void:
	for id: String in Database.stations:
		if not stations.has(id):
			stations[id] = StationState.new()


func _changed() -> void:
	_sync_step()
	Events.state_changed.emit()


## Ao mudar o passo da história, guarda os contadores dos objetivos "fresh" (base = agora).
func _sync_step() -> void:
	var current := progress.current_main_quest()
	if progress.step.get("quest", "") == current:
		return
	var base := {}
	if current != "":
		for goal: Dictionary in Database.quests[current].goals:
			if goal.get("fresh", false):
				base[goal.key] = progress.stat(goal.key)
	progress.step = {"quest": current, "base": base}


## Conclui só o passo principal atual, com as mesmas recompensas e sinais.
func dev_complete_main_step() -> void:
	if not BuildInfo.is_dev():
		return
	var id := progress.current_main_quest()
	if id != "":
		_dev_complete_quest(id)
		_changed()
