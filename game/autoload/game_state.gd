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
## Último recolhimento de coletas da Natureza (não salvo): alimenta a animação de recolher.
var last_gain: Dictionary = {}
var last_coins: int = 0
var xp: int = 0
var level: int = 1
## Atributos, aquisições, missões, coleção, contadores e rota em andamento.
var progress := ProgressionState.new()
## Desejos do Tiro (até três espaços).
var wishes := WishState.new()
var finds := FindState.new()


func _ready() -> void:
	# Desejos novos aparecem com o tempo, mesmo sem nenhuma ação do jogador.
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(func() -> void:
		var changed_wishes := update_wishes()
		if update_finds() or changed_wishes:
			_changed())
	add_child(timer)


func now() -> float:
	return Time.get_unix_time_from_system()


## Soma ao contador e grava a primeira vez (alimenta o "Ritmo" do painel DEV).
func _count(key: String, amount: int = 1) -> void:
	if progress.stat(key) == 0 and amount > 0 and not progress.firsts.has(key):
		progress.firsts[key] = now()
	progress.count(key, amount)

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
	progress.started_at = now()
	wishes = WishState.new()
	finds = FindState.new()
	_mark_all_seen()
	_changed()


# --- Faro do Tiro ---------------------------------------------------------

## Só um achado por mundo, mesmo após dias fora. A semente pertence ao montinho,
## separada do próximo horário, e não muda ao avançar tempo ou recarregar.
func update_finds() -> bool:
	var changed := false
	for world: String in Database.finds.get("worlds", {}):
		var def: Dictionary = Database.finds.worlds[world]
		if requirement_error(def.get("requirements", {})) != "":
			continue
		if not finds.worlds.has(world):
			finds.worlds[world] = {"next_at": now() + float(Database.finds.settings.first_delay), "pending": 0, "spot": 0, "dug": 0, "seed": 0}
			changed = true
		var entry: Dictionary = finds.worlds[world]
		if float(entry.next_at) > now() or int(entry.pending) >= mini(1, int(def.get("max_pending", 1))):
			continue
		var spots: Array = Database.room(str(Database.worlds.get(world, {}).get("room", world))).get("dig_spots", [])
		if spots.is_empty():
			continue
		entry.seed = int(entry.next_at)
		entry.spot = Loot.amount([0, spots.size() - 1], int(entry.seed))
		entry.pending = 1
		entry.next_at = now() + float(def.interval)
		changed = true
	return changed

func find_reward(world: String) -> Dictionary:
	if not finds.worlds.has(world) or not Database.finds.worlds.has(world):
		return {}
	var entry: Dictionary = finds.worlds[world]
	var def: Dictionary = Database.finds.worlds[world]
	var guaranteed: Array = def.get("guaranteed", [])
	return guaranteed[int(entry.dug)].duplicate(true) if int(entry.dug) < guaranteed.size() else Loot.roll(def.get("table", []), 1, int(entry.seed))

func dig_error(world: String) -> String:
	if not finds.worlds.has(world) or int(finds.worlds[world].pending) <= 0 or requirement_error(Database.finds.worlds.get(world, {}).get("requirements", {})) != "":
		return "Nada para cavar aqui"
	return storage_error(find_reward(world).get("items", {}))

func dig(world: String, origin: Vector2 = Vector2(-1, -1)) -> Dictionary:
	if dig_error(world) != "":
		return {}
	var reward := find_reward(world)
	var fresh: Array[String] = []
	for id: String in reward.get("items", {}):
		if Database.items.get(id, {}).get("category", "") == "find" and progress.stat("find_item:" + id) == 0:
			fresh.append(id)
		_count("find_item:" + id, int(reward.items[id]))
	_apply_rewards(reward)
	finds.worlds[world].pending = 0
	finds.worlds[world].dug = int(finds.worlds[world].dug) + 1
	# Não gera outro na mesma ação depois de ficar muito tempo pendente.
	finds.worlds[world].next_at = now() + float(Database.finds.worlds[world].interval)
	_count("find")
	_count("find:" + world)
	_changed()
	var result := {"items": reward.get("items", {}), "coins": int(reward.get("coins", 0)), "label": reward.get("label", ""), "icon": reward.get("icon", ""), "new": fresh}
	result["announcement"] = reward.get("announcement", "")
	result["unlock_label"] = reward.get("unlock_label", "")
	Events.items_gained.emit(result.items, result.coins, origin)
	if not fresh.is_empty() or result.label != "":
		Events.find_discovered.emit(result)
	return result

func find_album_count() -> int:
	var total := 0
	for items: Array in Database.finds.get("album_groups", {}).values():
		for id: String in items:
			total += 1 if progress.stat("find_item:" + id) > 0 else 0
	return total

func find_set_progress(id: String) -> int:
	var total := 0
	for item: String in Database.finds.get("sets", {}).get(id, {}).get("items", []):
		total += 1 if progress.stat("find_item:" + item) > 0 else 0
	return total

func find_set_error(id: String) -> String:
	if not Database.finds.get("sets", {}).has(id):
		return "Conjunto desconhecido"
	if id in finds.claimed_sets:
		return "Já recebido"
	var def: Dictionary = Database.finds.sets[id]
	if find_set_progress(id) < def.items.size():
		return "Encontre todos os achados"
	return storage_error(def.get("rewards", {}).get("items", {}))

func claim_find_set(id: String) -> String:
	var error := find_set_error(id)
	if error != "":
		return error
	_apply_rewards(Database.finds.sets[id].rewards)
	finds.claimed_sets.append(id)
	_changed()
	return ""

func dev_spawn_finds() -> void:
	if not BuildInfo.is_dev(): return
	update_finds()
	for world: String in finds.worlds:
		if requirement_error(Database.finds.worlds.get(world, {}).get("requirements", {})) == "":
			finds.worlds[world].pending = 1
			if int(finds.worlds[world].seed) == 0:
				finds.worlds[world].seed = int(finds.worlds[world].next_at)
	_changed()

# --- Ações do Tiro ---------------------------------------------------------

func feed(item_id: String) -> bool:
	var useful := _need_is_low("hunger")
	var effects: Dictionary = Database.items.get(item_id, {}).get("feed", {})
	if effects.is_empty() or not inventory.remove(item_id):
		return false
	dog.apply(effects, now())
	_count("feed")
	_count("feed:" + item_id)
	_care_reward("feed", useful)
	_changed()
	Events.dog_action.emit(&"feed")
	return true


func pet() -> void:
	dog.apply(Database.actions.get("pet", {}), now())
	dog.affection += 1
	_count("pet")
	_changed()
	Events.dog_action.emit(&"pet")


func play() -> bool:
	if dog.sleeping or dog.get_need("energy", now()) < 15.0:
		return false
	var useful := _need_is_low("happiness")
	dog.apply(Database.actions.get("play", {}), now())
	dog.affection += 2
	_count("play")
	_care_reward("play", useful)
	_changed()
	Events.dog_action.emit(&"play")
	return true


func bathe() -> void:
	var useful := _need_is_low("hygiene")
	dog.apply(Database.actions.get("bathe", {}), now())
	_count("bathe")
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


## Ampliações de espaço da estação ainda não compradas, na ordem do config.json.
func pending_slot_upgrades(id: String) -> Array[String]:
	var result: Array[String] = []
	for upgrade_id: String in Database.stations.get(id, {}).get("slot_upgrades", {}):
		if not has_upgrade(upgrade_id):
			result.append(upgrade_id)
	return result


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
	var blocked := ""
	for entry: Dictionary in station(station_id).take_ready_batches(now()):
		var recipe_id: String = entry.recipe
		var recipe: Dictionary = Database.recipes.get(recipe_id, {})
		if recipe.is_empty():
			continue  # receita removida do JSON: descarta sem travar a fila
		var output: String = recipe["output"]
		var qty := int(entry.get("qty", recipe.get("qty", 1)))
		var full := storage_error({output: qty})
		if full != "":
			# Não cabe: o lote continua pronto na fila, nada se perde.
			station(station_id).queue.append(entry)
			blocked = full
			continue
		inventory.add(output, qty)
		_count("produce:" + output, qty)
		_count("produce", qty)
		_discover("recipe:" + recipe_id, str(recipe.get("skill", "cooking")), int(recipe.get("skill_xp", 10)))
		received[output] = int(received.get(output, 0)) + qty
		_gain_xp("animal" if Database.stations.get(station_id, {}).get("kind", "") == "animal" else "cook")
	if blocked != "":
		Events.toast_requested.emit(blocked)
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
	var reason := requirement_error(data.get("requirements", {}))
	if reason != "":
		return reason
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
## Antes da escritura, a vovó Bloblo empresta canteiros conforme a linha dela (config farm.lent_plots).
func accessible_plots() -> int:
	if has_upgrade("farm"):
		return unlocked_plots
	var lent := 0
	for entry: Dictionary in Database.farm.get("lent_plots", []):
		if requirement_error(entry.get("requirements", {})) == "":
			lent = maxi(lent, int(entry.count))
	return lent


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
	plots[index] = { "crop": crop_id, "planted_at": planted_at, "ready_at": planted_at + float(Database.crops[crop_id].get("seconds", 60)), "watered": false }
	_changed()
	return ""


## Por que não dá para regar ("" = pode). Uma rega por plantio.
func water_error(index: int) -> String:
	if plot_status(index) == "locked":
		return "Compre este terreno primeiro"
	if plot_status(index) == "empty":
		return "Canteiro vazio"
	if plot_status(index) == "ready":
		return "Já está pronto"
	if bool(plot(index).get("watered", false)):
		return "Já foi regado"
	return ""


## Rega uma planta crescendo: o tempo que falta cai (config farm.water.speedup), uma vez por plantio.
func water(index: int) -> String:
	var reason := water_error(index)
	if reason != "":
		return reason
	var target := plot(index)
	var left := float(target.ready_at) - now()
	target.ready_at = now() + left * (1.0 - float(Database.farm.water.speedup))
	target.watered = true
	_count("water")
	_add_player_xp(int(Database.farm.water.get("xp", 0)))
	_changed()
	Events.world_activity.emit(&"water", str(target.crop), index)
	return ""


## Colhe um canteiro pronto. Retorna os itens recebidos (vazio se não estava pronto).
func harvest(index: int) -> Dictionary:
	if plot_status(index) != "ready":
		return {}
	var crop_id: String = plot(index)["crop"]
	var crop: Dictionary = Database.crops.get(crop_id, {})
	var received: Dictionary = crop.get("yield", {})
	var full := storage_error(received)
	if full != "":
		Events.toast_requested.emit(full)
		return {}
	_count("harvest")
	_count("harvest:" + crop_id)
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
	var gained := {}
	var leveled := false
	while xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		level += 1
		leveled = true
		var reward := level_reward(level)
		_apply_rewards(reward)
		gained["coins"] = int(gained.get("coins", 0)) + int(reward.get("coins", 0))
		gained["affection"] = int(gained.get("affection", 0)) + int(reward.get("affection", 0))
		var items: Dictionary = gained.get("items", {})
		for id: String in reward.get("items", {}):
			items[id] = int(items.get(id, 0)) + int(reward.items[id])
		gained["items"] = items
	if leveled:
		Events.level_up.emit(level, gained)


## Presente de subir de nível (progression.json → level_rewards; "default": coins_per_level × nível).
func level_reward(target_level: int) -> Dictionary:
	var table: Dictionary = Database.progression.get("level_rewards", {})
	if table.has(str(target_level)):
		return table[str(target_level)].duplicate(true)
	return {"coins": int(table.get("default", {}).get("coins_per_level", 0)) * target_level}


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
	dog.affection += int(rewards.get("affection", 0))
	if rewards.has("needs"):
		dog.apply(rewards.needs, now())


# --- Aquisições (Construir) -------------------------------------------------------

func has_upgrade(id: String) -> bool:
	return progress.has_upgrade(id)


# --- Armazenamento ----------------------------------------------------------------
# Cada item mora num depósito (items.json "storage" ou a categoria em progression.json → storage).
# O limite só vale depois de construir o depósito; antes disso entra sem limite.
# Níveis de ampliação são melhorias comuns (`owned`) com "storage_capacity": sem estado novo no save.

## Depósito do item ("" = sem limite: ração, itens fora de qualquer categoria).
func storage_of(item_id: String) -> String:
	var item: Dictionary = Database.items.get(item_id, {})
	var forced := str(item.get("storage", ""))
	if forced != "":
		return "" if forced == "none" or not Database.progression.storage.has(forced) else forced
	var category := str(item.get("category", "product"))
	for id: String in Database.progression.storage:
		if category in Database.progression.storage[id].get("categories", []):
			return id
	return ""


## Desliga os limites (só testes automatizados que enchem a mochila).
var unlimited_storage := false


## O depósito já foi construído (e, portanto, tem limite)?
func storage_active(id: String) -> bool:
	if unlimited_storage:
		return false
	return Database.progression.storage.has(id) and has_upgrade(str(Database.progression.storage[id].building))


func storage_capacity(id: String) -> int:
	var data: Dictionary = Database.progression.storage.get(id, {})
	var total := int(data.get("base", 0))
	for upgrade_id: String in data.get("levels", []):
		if has_upgrade(upgrade_id):
			total += int(Database.progression.upgrades[upgrade_id].get("storage_capacity", 0))
	return total


func storage_used(id: String) -> int:
	var total := 0
	for item_id: String in inventory.counts:
		if storage_of(item_id) == id:
			total += inventory.count(item_id)
	return total


func storage_space(id: String) -> int:
	return maxi(0, storage_capacity(id) - storage_used(id))


## Próxima ampliação do depósito ("" se já está no máximo).
func storage_next_upgrade(id: String) -> String:
	for upgrade_id: String in Database.progression.storage.get(id, {}).get("levels", []):
		if not has_upgrade(upgrade_id):
			return upgrade_id
	return ""


## Nome do depósito que não comporta os itens ("" se cabem). Soma por depósito.
func storage_full(items: Dictionary) -> String:
	var needed := {}
	for item_id: String in items:
		var id := storage_of(item_id)
		if id != "" and storage_active(id):
			needed[id] = int(needed.get(id, 0)) + int(items[item_id])
	for id: String in needed:
		if int(needed[id]) > storage_space(id):
			return id
	return ""


## Texto pronto para toast quando os itens não cabem ("" se cabem).
func storage_error(items: Dictionary) -> String:
	var full := storage_full(items)
	if full == "":
		return ""
	return "%s sem espaço" % Database.progression.storage[full].name


## Requisitos que dependem de fora do ProgressionState (afeto do Tiro e hora local) são checados
## aqui; os demais vão para o `progress`. Todo conteúdo passa por este embrulho (content_error também).
func requirement_error(requirements: Dictionary) -> String:
	var reason := progress.requirement_error(requirements)
	if reason != "":
		return reason
	if requirements.has("bond") and progress.bond_level(dog.affection) < int(requirements.bond):
		return "Vínculo %d" % int(requirements.bond)
	if requirements.has("hours"):
		var from_hour := int(requirements.hours[0])
		var to_hour := int(requirements.hours[1])
		var hour := int(Time.get_datetime_dict_from_unix_time(_local_time()).hour)
		var inside := from_hour <= hour and hour < to_hour if from_hour < to_hour else hour >= from_hour or hour < to_hour
		if not inside:
			return "Só das %dh às %dh" % [from_hour, to_hour]
	return ""

func content_error(kind: String, id: String, data: Dictionary) -> String:
	if progress.unlocks.has(kind + ":" + id):
		return ""
	return requirement_error(data.get("requirements", {}))


func current_chapter() -> Dictionary:
	return progress.current_chapter()


func upgrade_error(id: String) -> String:
	var data: Dictionary = Database.progression.upgrades.get(id, {})
	if data.is_empty():
		return "Melhoria desconhecida"
	if has_upgrade(id):
		return "Já adquirido"
	if data.has("nature_unlock"):
		var unlock: Dictionary = data.nature_unlock
		return "Colete em %s até o nível %d" % [Database.progression.nature_sites[unlock.site].name, int(unlock.level)]
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
	_count("build")
	_add_player_xp(int(data.get("player_xp", 10)))
	_changed()
	Events.world_activity.emit(&"build", id, -1)
	return ""


func _grant_upgrade(id: String) -> void:
	if has_upgrade(id):
		return
	progress.owned[id] = true
	var data: Dictionary = Database.progression.upgrades[id]
	var gift: String = data.get("gift_animal", "")
	if Database.animals.has(gift):
		var station_id: String = Database.animals[gift].station
		if animal_count(station_id) < int(Database.stations[station_id].animal_capacity):
			animals[gift] = int(animals.get(gift, 0)) + 1
	if data.has("nature_unlock"):
		var site: String = data.nature_unlock.site
		var target := int(data.nature_unlock.level) - 1
		progress.nature_xp[site] = maxi(int(progress.nature_xp.get(site, 0)), int(Database.progression.nature_sites[site].levels[target].xp))
	for site: String in Database.progression.nature_sites:
		_sync_nature_unlocks(site)
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
	_count("trade")
	_count("sold", amount)
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
	_count("trade")
	_count("orders")
	_count("order:" + id)
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
	_count("activity:" + id)
	_count("explore")
	_apply_rewards(data.rewards)
	_award_nature_xp(Database.gathering_site(id))
	_add_player_xp(int(data.get("player_xp", 5)))
	_changed()
	return ""


# --- Coleta por local ---------------------------------------------------------------

## Coletas independentes da Natureza: um a três espaços em cada local.
func gathering_slots(site: String) -> int:
	if not Database.progression.nature_sites.has(site):
		return 0
	var level := progress.nature_level(site)
	return int(Database.progression.nature_sites[site].levels[maxi(0, level - 1)].slots) if level > 0 else 0


func _sync_nature_unlocks(site: String) -> void:
	var config: Dictionary = Database.progression.nature_sites[site]
	var level := progress.nature_level(site)
	for i in level:
		progress.owned[str(config.level_upgrades[i])] = true
	for i in maxi(0, level - 1):
		progress.owned[str(config.slot_upgrades[i])] = true


func _award_nature_xp(site: String, amount: int = -1) -> void:
	if site == "":
		return
	var reward := int(Database.progression.nature_sites[site].xp_per_collection) if amount < 0 else amount
	progress.nature_xp[site] = maxi(0, int(progress.nature_xp.get(site, 0))) + maxi(0, reward)
	_sync_nature_unlocks(site)


func gathering_entry(site: String, index: int) -> Dictionary:
	var jobs: Array = progress.gathering.get(site, [])
	return jobs[index] if index >= 0 and index < jobs.size() else {}


func gathering_jobs(site: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in progress.gathering.get(site, []):
		if not entry.is_empty():
			result.append(entry)
	return result


func gathering_remaining(site: String, index: int) -> int:
	var entry := gathering_entry(site, index)
	return maxi(0, ceili(float(entry.get("ready_at", 0)) - now()))


func gathering_ready_count(site: String) -> int:
	var count := 0
	for entry: Dictionary in gathering_jobs(site):
		if float(entry.ready_at) <= now():
			count += 1
	return count


func gathering_free_count(site: String) -> int:
	var count := 0
	for i in gathering_slots(site):
		if gathering_entry(site, i).is_empty():
			count += 1
	return count


func gathering_error(site: String, index: int, route_id: String, resource: String = "") -> String:
	if not Database.progression.nature_sites.has(site) or Database.gathering_site(route_id) != site:
		return "Coleta não pertence a este local"
	if index < 0 or index >= gathering_slots(site):
		return "Libere este espaço primeiro"
	if not gathering_entry(site, index).is_empty():
		return "Espaço ocupado"
	if resource != "" and (not resource in Database.progression.nature_sites[site].resources or not Database.progression.activities[route_id].rewards.get("items", {}).has(resource)):
		return "Este material não vem desta coleta"
	var reason := requirement_error(Database.worlds.nature.get("requirements", {}))
	return reason if reason != "" else requirement_error(Database.progression.activities[route_id].get("requirements", {}))


func start_gathering(site: String, index: int, route_id: String, resource: String = "") -> String:
	var error := gathering_error(site, index, route_id, resource)
	if error != "":
		return error
	var data: Dictionary = Database.progression.activities[route_id]
	var jobs: Array = progress.gathering.get(site, []).duplicate(true)
	while jobs.size() <= index:
		jobs.append({})
	var start := now()
	jobs[index] = {"id": route_id, "resource": resource, "started_at": start, "ready_at": start + float(data.seconds), "rewards": data.rewards.duplicate(true), "player_xp": int(data.get("player_xp", 5)), "nature_xp": int(Database.progression.nature_sites[site].xp_per_collection)}
	progress.gathering[site] = jobs
	_changed()
	return ""


## Um toque no material preenche só a primeira vaga livre, sem escolher o espaço.
func next_gathering_error(site: String, route_id: String, resource: String = "") -> String:
	if not Database.progression.nature_sites.has(site):
		return "Local de coleta inválido"
	if progress.nature_level(site) == 0:
		return "Desbloqueie %s primeiro" % Database.progression.nature_sites[site].name
	for index in gathering_slots(site):
		if gathering_entry(site, index).is_empty():
			return gathering_error(site, index, route_id, resource)
	return "Todos os espaços estão ocupados"


func start_next_gathering(site: String, route_id: String, resource: String = "") -> String:
	var error := next_gathering_error(site, route_id, resource)
	if error != "":
		return error
	for index in gathering_slots(site):
		if gathering_entry(site, index).is_empty():
			return start_gathering(site, index, route_id, resource)
	return "Todos os espaços estão ocupados"


func start_gathering_all(site: String, route_id: String, resource: String = "") -> String:
	var started := false
	var reason := "Todos os espaços estão ocupados"
	for index in gathering_slots(site):
		if gathering_entry(site, index).is_empty():
			reason = start_gathering(site, index, route_id, resource)
			if reason != "":
				return reason
			started = true
	return "" if started else reason


func collect_gathering_error(site: String, index: int) -> String:
	if gathering_entry(site, index).is_empty():
		return "Nada para recolher"
	if gathering_remaining(site, index) > 0:
		return "A coleta ainda está em andamento"
	var entry := gathering_entry(site, index)
	var data: Dictionary = Database.progression.activities.get(entry.get("id", ""), {})
	return storage_error(entry.get("rewards", data.get("rewards", {})).get("items", {}))


func collect_gathering(site: String, index: int) -> String:
	var error := collect_gathering_error(site, index)
	if error != "":
		return error
	var entry := gathering_entry(site, index).duplicate(true)
	var data: Dictionary = Database.progression.activities[entry.id]
	progress.gathering[site][index] = {}
	_count("activity:" + str(entry.id))
	_count("explore")
	var rewards: Dictionary = entry.get("rewards", data.rewards)
	for id: String in rewards.get("items", {}):
		last_gain[id] = int(last_gain.get(id, 0)) + int(rewards.items[id])
	last_coins += int(rewards.get("coins", 0))
	_apply_rewards(rewards)
	_award_nature_xp(site, int(entry.get("nature_xp", Database.progression.nature_sites[site].xp_per_collection)))
	_add_player_xp(int(entry.get("player_xp", data.get("player_xp", 5))))
	_changed()
	return ""


## Recolhe todas as coletas prontas do local; o que veio fica em last_gain/last_coins
## (para a animação de recolher).
func collect_gathering_all(site: String) -> String:
	last_gain = {}
	last_coins = 0
	var done := false
	var blocked := ""
	for index in gathering_slots(site):
		var error := collect_gathering_error(site, index)
		if error == "":
			collect_gathering(site, index)
			done = true
		elif error.ends_with("sem espaço"):
			blocked = error
	return "" if done else (blocked if blocked != "" else "Nenhuma coleta pronta")

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
		"quest":
			return 1 if progress.claimed_quests.has(goal.key) else 0
		"stat":
			# "fresh": conta só o que foi feito depois que o passo da linha começou.
			if goal.get("fresh", false):
				return maxi(0, progress.stat(goal.key) - int(_step_base(goal).get(goal.key, progress.stat(goal.key))))
			return progress.stat(goal.key)
	return 0


## Base dos contadores do passo ativo que contém este objetivo (cada linha tem o seu).
func _step_base(goal: Dictionary) -> Dictionary:
	for line: String in progress.steps:
		var id: String = progress.steps[line].get("quest", "")
		if id != "" and Database.quests.has(id) and Database.quests[id].goals.has(goal):
			return progress.steps[line].get("base", {})
	return {}


## Conversa aberta com o personagem (objetivos "Falar com…").
func talk_to(npc_id: String) -> void:
	_count("talk:" + npc_id)
	# Passos atuais deste personagem deixam de ser "novos" (balão "!" no mapa).
	for id: String in progress.active_steps().values():
		if Database.quests[id].get("npc", "") == npc_id:
			progress.seen["quest:" + id] = true
	_changed()


## Tela aberta pelo jogador (objetivo "Abrir a Mochila" = "open:bag").
func note_screen_opened(screen: String) -> void:
	var key := "open:" + screen
	if progress.stat(key) > 0:
		return
	_count(key)
	_changed()


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
	# Recebeu conversando com o personagem: o próximo passo dele já aparece na mesma conversa.
	var npc_id: String = Database.quests[id].get("npc", "")
	for next: String in progress.active_steps().values():
		if npc_id != "" and Database.quests[next].get("npc", "") == npc_id:
			progress.seen["quest:" + next] = true
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
	_count("quests")
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
	_count("routines")
	_add_player_xp(int(data.get("player_xp", 10 if kind == "daily" else 30)))
	_changed()
	return ""


# --- Desejos do Tiro e vínculo --------------------------------------------------------
# Modelos em data/wishes.json; estado em `wishes` (WishState). Nada vence nem pune: trocar é grátis.

func wish_settings() -> Dictionary:
	return Database.wishes.get("settings", {})


func wish_def(id: String) -> Dictionary:
	return Database.wishes.get("wishes", {}).get(id, {})


## Espaço de desejo aberto? (requisitos de settings.slots[i]).
func wish_slot_open(i: int) -> bool:
	if not progress.feature_unlocked("wishes"):
		return false
	var slots: Array = wish_settings().get("slots", [])
	return i >= 0 and i < slots.size() and i < wishes.slots.size() and requirement_error(slots[i].get("requirements", {})) == ""


## Requisito que falta para abrir o espaço ("" = aberto).
func wish_slot_error(i: int) -> String:
	var slots: Array = wish_settings().get("slots", [])
	if i < 0 or i >= slots.size():
		return "Espaço inexistente"
	return requirement_error(slots[i].get("requirements", {}))


## Sorteia desejos nos espaços abertos que estão prontos. Devolve true se algo mudou (sem emitir sinal).
func update_wishes() -> bool:
	var changed := false
	var t := now()
	for i in wishes.slots.size():
		if not wish_slot_open(i):
			continue
		var slot: Dictionary = wishes.slots[i]
		if str(slot.id) != "":
			if wish_def(str(slot.id)).is_empty():  # desejo removido do JSON: libera o espaço
				wishes.slots[i] = WishState.empty_slot(0.0)
				changed = true
			continue
		if float(slot.ready_at) > t:
			continue
		var pick := _pick_wish(i, slot)
		if pick.is_empty():
			continue
		var def := wish_def(str(pick.id))
		wishes.slots[i] = {
			"id": pick.id, "base": progress.stat(str(def.goal.key)) if def.get("type", "") == "action" else 0,
			"since": t, "ready_at": float(slot.ready_at), "special": bool(pick.get("special", false)), "last": str(slot.get("last", "")),
		}
		changed = true
	return changed


func _wish_eligible(id: String, taken: Array[String], last: String) -> bool:
	var def := wish_def(id)
	return not def.is_empty() and not id in taken and id != last and not def.get("special", false) and requirement_error(def.get("requirements", {})) == ""


## Escolhe o desejo do espaço: o inicial, depois necessidade baixa, especial raro e sorteio por peso.
func _pick_wish(i: int, slot: Dictionary) -> Dictionary:
	var settings := wish_settings()
	var taken := wishes.active_ids()
	var last := str(slot.get("last", ""))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(float(slot.ready_at)) + i
	var first := str(settings.get("first", ""))
	if not wishes.first_done and not wish_def(first).is_empty() and not first in taken:
		return {"id": first}
	var needs: Dictionary = settings.get("need_wishes", {})
	for need_id: String in needs:
		if dog.get_need(need_id, now()) < float(settings.get("need_threshold", 35)) and _wish_eligible(str(needs[need_id]), taken, ""):
			return {"id": needs[need_id]}
	if requirement_error(settings.get("special_requirements", {})) == "" and rng.randf() < float(settings.get("special_chance", 0.0)):
		var specials: Array = []
		for id: String in Database.wishes.wishes:
			var def := wish_def(id)
			if def.get("special", false) and not id in taken and requirement_error(def.get("requirements", {})) == "":
				specials.append({"id": id, "weight": def.get("weight", 1)})
		if not specials.is_empty():
			var chosen := Loot.pick_weighted(specials, rng.randi())
			return {"id": chosen.id, "special": true}
	var pool: Array = []
	for id: String in Database.wishes.wishes:
		if _wish_eligible(id, taken, last):
			pool.append({"id": id, "weight": wish_def(id).get("weight", 1)})
	if pool.is_empty():  # só sobrou o último desejo: aceita repetir
		for id: String in Database.wishes.wishes:
			if _wish_eligible(id, taken, ""):
				pool.append({"id": id, "weight": wish_def(id).get("weight", 1)})
	if pool.is_empty():
		return {}
	return {"id": Loot.pick_weighted(pool, rng.randi()).id}


## Desejo do espaço (vazio se esperando ou fechado).
func wish_at(i: int) -> Dictionary:
	if i < 0 or i >= wishes.slots.size() or not wish_slot_open(i):
		return {}
	return wish_def(str(wishes.slots[i].id))


## Segundos até um espaço esperando ter outro desejo.
func wish_wait(i: int) -> int:
	if i < 0 or i >= wishes.slots.size():
		return 0
	return maxi(0, ceili(float(wishes.slots[i].ready_at) - now()))


## Quanto já foi feito (ação: contador desde o início; comida/item: quanto tem).
func wish_value(i: int) -> int:
	var def := wish_at(i)
	if def.is_empty():
		return 0
	if def.type == "action":
		return maxi(0, progress.stat(str(def.goal.key)) - int(wishes.slots[i].base))
	return mini(inventory.count(str(def.item)), 1)


func wish_target(i: int) -> int:
	var def := wish_at(i)
	return int(def.goal.get("target", 1)) if def.get("type", "") == "action" else 1


func wish_error(i: int) -> String:
	var def := wish_at(i)
	if def.is_empty():
		return "Espere"
	if wish_value(i) >= wish_target(i):
		return ""
	if def.type == "action":
		return "Faça: " + str(def.name)
	return "Falta " + Database.item_name(str(def.item))


## Prêmio do desejo (dobrado nos especiais).
func wish_rewards(i: int) -> Dictionary:
	var def := wish_at(i)
	if def.is_empty():
		return {}
	var rewards: Dictionary = def.get("rewards", {}).duplicate(true)
	if bool(wishes.slots[i].special):
		var factor := int(wish_settings().get("special_multiplier", 2))
		for key: String in ["coins", "affection"]:
			if rewards.has(key):
				rewards[key] = int(rewards[key]) * factor
	return rewards


## Cumpre o desejo do espaço: entrega a comida/item (se for o caso), paga e começa a esperar o próximo.
func fulfill_wish(i: int) -> String:
	var error := wish_error(i)
	if error != "":
		return error
	var def := wish_at(i)
	var id := str(wishes.slots[i].id)
	var rewards := wish_rewards(i)
	match str(def.type):
		"feed":
			if not feed(str(def.item)):
				return "Ele não quer isso agora"
		"give":
			inventory.remove(str(def.item))
			_count("give:" + str(def.item))
	_apply_rewards(rewards)
	_count("wish")
	_count("wish:" + id)
	wishes.done_count += 1
	wishes.first_done = true
	var settings := wish_settings()
	var wait := float(settings.get("first_refill_seconds", 60)) if wishes.done_count <= int(settings.get("first_count", 3)) else float(settings.get("refill_seconds", 600))
	wishes.slots[i] = WishState.empty_slot(now() + wait, id)
	_changed()
	Events.dog_action.emit(&"wish")
	Events.items_gained.emit(rewards.get("items", {}), int(rewards.get("coins", 0)), Vector2(-1, -1))
	return ""


func swap_wish_error(i: int) -> String:
	return "" if not wish_at(i).is_empty() else "Nada para trocar"


## Troca o desejo por outro, sem custo; o espaço espera `swap_seconds`.
func swap_wish(i: int) -> String:
	var error := swap_wish_error(i)
	if error != "":
		return error
	wishes.slots[i] = WishState.empty_slot(now() + float(wish_settings().get("swap_seconds", 300)), str(wishes.slots[i].id))
	_changed()
	return ""


## Quantos desejos dá para cumprir agora (badge da aba).
func fulfillable_wish_count() -> int:
	var total := 0
	for i in wishes.slots.size():
		if not wish_at(i).is_empty() and wish_error(i) == "":
			total += 1
	return total


## Espaço do desejo que o balão mostra: o primeiro que dá para cumprir ou, senão, o primeiro com pedido (-1 = nenhum).
func balloon_slot() -> int:
	var first := -1
	for i in wishes.slots.size():
		if wish_at(i).is_empty():
			continue
		if wish_error(i) == "":
			return i
		if first < 0:
			first = i
	return first


## Id do desejo do balão ("" = nenhum).
func balloon_wish() -> String:
	var slot := balloon_slot()
	return str(wishes.slots[slot].id) if slot >= 0 else ""


## Espaço que pede exatamente esta comida e dá para cumprir (-1 = nenhum): "Ele quer!" no seletor de comida.
func wish_slot_for_item(item_id: String) -> int:
	for i in wishes.slots.size():
		var def := wish_at(i)
		if def.get("type", "") == "feed" and str(def.item) == item_id and wish_error(i) == "":
			return i
	return -1


## Nível de vínculo atual (1..N).
func bond_level() -> int:
	return progress.bond_level(dog.affection)


## Entrega o presente dos níveis de vínculo novos (uma vez) e avisa a tela.
func _check_bond() -> void:
	var level := bond_level()
	if level <= progress.claimed_bond_level:
		return
	var levels: Array = Database.progression.get("bond_levels", [])
	var gained := {"coins": 0, "items": {}}
	for reached in range(progress.claimed_bond_level + 1, level + 1):
		var reward: Dictionary = levels[reached - 1].get("rewards", {}) if reached - 1 < levels.size() else {}
		_apply_rewards(reward)
		gained["coins"] = int(gained.coins) + int(reward.get("coins", 0))
		for id: String in reward.get("items", {}):
			gained.items[id] = int(gained.items.get(id, 0)) + int(reward.items[id])
	progress.claimed_bond_level = level
	Events.bond_up.emit(level, gained)


# --- Presente do dia ----------------------------------------------------------------
# Ciclo de progression.json → daily_gift, um por DIA JOGADO (nunca zera por faltar).

## O presente que vale hoje (vazio se o ciclo não existe).
func daily_gift_rewards() -> Dictionary:
	var cycle: Array = Database.progression.get("daily_gift", [])
	if cycle.is_empty():
		return {}
	return cycle[int(progress.daily_gift.count) % cycle.size()].duplicate(true)


func daily_gift_error() -> String:
	if requirement_error(Database.progression.settings.get("welcome_requirements", {})) != "":
		return "Ainda não disponível"
	if daily_gift_rewards().is_empty():
		return "Sem presente"
	if str(progress.daily_gift.period) == routine_period("daily"):
		return "Já recebido hoje"
	return ""


func claim_daily_gift() -> String:
	var reason := daily_gift_error()
	if reason != "":
		return reason
	var rewards := daily_gift_rewards()
	_apply_rewards(rewards)
	progress.daily_gift = {"period": routine_period("daily"), "count": int(progress.daily_gift.count) + 1}
	_changed()
	return ""


## O que ficou pronto para o cartão "bem-vindo de volta": até `limit` linhas
## { kind, count, icon (id de item), world, target }: colheitas, estações e coletas da Natureza.
func welcome_ready_lines(limit: int = 4) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	for world: String in finds.worlds:
		if int(finds.worlds[world].pending) > 0:
			lines.append({"kind": "dig", "count": 1, "icon": "", "world": world, "target": "find"})
	var farm_at := Database.place_with_panel("farm")
	var ripe := 0
	var crop_item := ""
	for i in plots.size():
		if plot_status(i) == "ready":
			ripe += 1
			if crop_item == "":
				crop_item = str(Database.crops.get(plot(i).crop, {}).get("yield", {}).keys().front())
	if ripe > 0:
		lines.append({"kind": "harvest", "count": ripe, "icon": crop_item, "world": farm_at[0], "target": farm_at[1]})
	for id: String in Database.stations:
		if not has_upgrade(id) or station(id).ready_count(now()) == 0:
			continue
		var at := Database.place_with_panel("station:" + id)
		var output := ""
		for entry: Dictionary in station(id).queue:
			if output == "" and float(entry.ready_at) <= now():
				output = str(Database.recipes.get(entry.recipe, {}).get("output", ""))
		lines.append({"kind": "collect", "count": station(id).ready_count(now()), "icon": output, "world": at[0], "target": at[1]})
	for site: String in Database.progression.get("nature_sites", {}):
		if gathering_slots(site) > 0 and gathering_ready_count(site) > 0:
			var at := Database.place_with_panel("nature:" + str(Database.progression.nature_sites[site].groups[0]))
			lines.append({"kind": "gather_ready", "count": gathering_ready_count(site), "icon": "", "world": at[0], "target": at[1]})
	return lines.slice(0, limit)


## O que dá para fazer agora (consulta pura). Cada item: { kind, world, target }; `target` é o
## lugar do mundo (mesmo alvo de Events.world_requested) ou a tela ("pet", "tasks") quando world = "".
func available_actions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for world: String in finds.worlds:
		if dig_error(world) == "":
			result.append({"kind": "dig", "world": world, "target": "find"})
	var farm_at := Database.place_with_panel("farm")
	var can_plant := Database.crops.keys().any(func(id: String) -> bool: return content_error("crop", id, Database.crops[id]) == "")
	var planted := false
	var ready := false
	var thirsty := false
	for i in plots.size():
		match plot_status(i):
			"empty":
				planted = planted or can_plant
			"ready":
				ready = true
		thirsty = thirsty or water_error(i) == ""
	if planted:
		result.append({"kind": "plant", "world": farm_at[0], "target": farm_at[1]})
	if thirsty:
		result.append({"kind": "water", "world": farm_at[0], "target": farm_at[1]})
	if ready:
		result.append({"kind": "harvest", "world": farm_at[0], "target": farm_at[1]})
	for id: String in Database.stations:
		if not has_upgrade(id):
			continue
		var at := Database.place_with_panel("station:" + id)
		if station(id).ready_count(now()) > 0:
			result.append({"kind": "collect", "world": at[0], "target": at[1]})
		if Database.recipes.keys().any(func(r: String) -> bool: return Database.recipes[r].get("station", "") == id and cook_error(r) == ""):
			result.append({"kind": "cook", "world": at[0], "target": at[1]})
	for site: String in Database.progression.get("nature_sites", {}):
		if gathering_slots(site) == 0:
			continue
		var at := Database.place_with_panel("nature:" + str(Database.progression.nature_sites[site].groups[0]))
		if gathering_ready_count(site) > 0:
			result.append({"kind": "gather_ready", "world": at[0], "target": at[1]})
		if gathering_free_count(site) > 0:
			result.append({"kind": "gather", "world": at[0], "target": at[1]})
	if ready_quest_count() > 0:
		result.append({"kind": "quest_ready", "world": "", "target": "tasks"})
	if ready_routine_count() > 0:
		result.append({"kind": "routine_ready", "world": "", "target": "tasks"})
	if fulfillable_wish_count() > 0:
		result.append({"kind": "wish", "world": "", "target": "wishes"})
	for need: String in dog.needs:
		if dog.get_need(need, now()) < 60.0:
			result.append({"kind": "care", "world": "", "target": "pet"})
			break
	return result


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
	for id: String in Database.animals:
		_dev_satisfy(Database.animals[id].get("requirements", {}))
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


## Soma afeto ao Tiro (sobe o vínculo e entrega os presentes dele).
func dev_add_affection(amount: int) -> void:
	if not BuildInfo.is_dev():
		return
	dog.affection = maxi(0, dog.affection + amount)
	_changed()


## Sorteia agora os desejos dos espaços que estão esperando.
func dev_refresh_wishes() -> void:
	if not BuildInfo.is_dev():
		return
	for slot: Dictionary in wishes.slots:
		if str(slot.id) == "":
			slot["ready_at"] = 0.0
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
	for jobs: Array in progress.gathering.values():
		for entry: Dictionary in jobs:
			if not entry.is_empty():
				entry["ready_at"] = minf(float(entry.ready_at), t)
	progress.cooldowns.clear()
	for slot: Dictionary in wishes.slots:
		slot["ready_at"] = minf(float(slot.ready_at), t)
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
	wishes.shift_time(seconds)
	finds.shift_time(seconds)
	_changed()


func _dev_skill_at_least(id: String, target_level: int) -> void:
	progress.skills[id] = maxi(int(progress.skills.get(id, 0)), progress.xp_for_level(target_level))


func _dev_satisfy(requirements: Dictionary) -> void:
	for item: String in requirements.get("produced", {}):
		progress.stats["produce:" + item] = maxi(progress.stat("produce:" + item), int(requirements.produced[item]))
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
					_dev_complete_quest(previous)
	elif quest.get("kind", "side") == "line":
		_dev_satisfy(quest.get("requirements", {}))
		for previous in progress.line_quests(str(quest.line)):
			if previous == id:
				break
			_dev_complete_quest(previous)
	else:
		_dev_satisfy(quest.get("requirements", {}))
		for required: String in quest.get("requires", []):
			_dev_complete_quest(required)
	# Cruzamento entre linhas: o passo da outra linha também é concluído.
	for goal: Dictionary in quest.goals:
		if goal.type == "quest":
			_dev_complete_quest(goal.key)
	if not progress.claimed_quests.has(id):
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
		"wishes": wishes.to_dict(),
		"finds": finds.to_dict(),
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
		if entry.has("watered"):
			loaded_plot["watered"] = bool(entry["watered"])
		plots.append(loaded_plot)
	# Saves anteriores à expansão mantêm todos os canteiros que já possuíam (ver SaveManager._migrate).
	unlocked_plots = clampi(int(data.get("unlocked_plots", maxi(plots.size(), int(Database.farm.get("initial_plots", 3))))), 0, int(Database.farm.get("plots", 0)))
	_ensure_plots()
	coins = int(data.get("coins", 0))
	xp = int(data.get("xp", 0))
	level = int(data.get("level", 1))
	progress = ProgressionState.new()
	progress.from_dict(data.get("progression", {}))
	wishes = WishState.new()
	wishes.from_dict(data.get("wishes", {}))
	finds = FindState.new()
	finds.from_dict(data.get("finds", {}))
	# Save sem o campo de vínculo: o que já valia não paga presente de novo.
	if not data.get("progression", {}).has("claimed_bond_level"):
		progress.claimed_bond_level = bond_level()
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
	update_wishes()
	update_finds()
	_check_bond()
	Events.state_changed.emit()


## Ao mudar o passo de uma linha, guarda os contadores dos objetivos "fresh" (base = agora).
func _sync_step() -> void:
	var active := progress.active_steps()
	for line: String in progress.steps.keys():
		if not active.has(line):
			progress.steps.erase(line)
	for line: String in active:
		var current: String = active[line]
		if progress.steps.get(line, {}).get("quest", "") == current:
			continue
		var base := {}
		for goal: Dictionary in Database.quests[current].goals:
			if goal.get("fresh", false):
				base[goal.key] = progress.stat(goal.key)
		progress.steps[line] = {"quest": current, "base": base}


## Conclui só o passo principal atual, com as mesmas recompensas e sinais.
func dev_complete_main_step() -> void:
	if not BuildInfo.is_dev():
		return
	var id := progress.current_main_quest()
	if id != "":
		_dev_complete_quest(id)
		_changed()
