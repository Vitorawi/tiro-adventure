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
## Passeio em andamento (o Tiro sai de casa).
var walk_state := WalkState.new()
var friend_state := FriendState.new()
## Obras comunitárias (contribuições persistentes; catálogo em Database.projects).
var projects := ProjectState.new()
var growth := GrowthState.new()
## Álbum de recordações: fotos tiradas e janelas de eventos (etapa 13 do plano Tiro).
var album := AlbumState.new()
var album_world: String = "house"
## Rodada do esconde-esconde em andamento (só em memória: o petisco já foi gasto).
var hide_pending := false
var album_sleep_spot: String:
	get: return album.sleep_spot
	set(value): album.sleep_spot = value
var album_water_drag: bool = false
## Economia protegida: revisão, piso legado de capacidade, presentes a guardar e recompensas já pagas.
var economy := EconomyState.new()


func _ready() -> void:
	# Desejos novos aparecem com o tempo, mesmo sem nenhuma ação do jogador.
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(func() -> void:
		var changed_wishes := update_wishes()
		# A volta do passeio não depende de nenhuma tela aberta: o tick liquida a viagem vencida.
		return_due_walk()
		changed_wishes = _recover_projects() or changed_wishes
		if sync_friend_window() or update_finds() or changed_wishes:
			_changed())
	add_child(timer)


func now() -> float:
	return Time.get_unix_time_from_system()


## Soma ao contador e grava a primeira vez (alimenta o "Ritmo" do painel DEV).
func _count(key: String, amount: int = 1) -> void:
	if progress.stat(key) == 0 and amount > 0 and not progress.firsts.has(key):
		progress.firsts[key] = now()
	progress.count(key, amount)
	PersonalityRules.record(growth, key, amount, routine_period("daily"))

func reset() -> void:
	_dev_moment_offset = 0.0
	hide_pending = false
	album_world = "house"
	album_sleep_spot = ""
	album_water_drag = false
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
	walk_state = WalkState.new()
	friend_state = FriendState.new()
	projects = ProjectState.new()
	growth = GrowthState.new()
	growth.reset()
	growth.firsts["care_actions_v1"] = true
	album = AlbumState.new()
	album.reset()
	growth.taste_seed = maxi(1, randi())
	growth.phase_since = now()
	growth.phase_stats = progress.stats.duplicate(true)
	economy = EconomyState.new()
	economy.reset()
	_mark_all_seen()
	_changed()


# --- Faro do Tiro ---------------------------------------------------------

## A missão garante o item que falta em cada mundo acessível, inclusive em saves antigos.
func _quest_find_item(world: String) -> String:
	var def: Dictionary = Database.finds.worlds.get(world, {}).get("quest_find", {})
	if def.is_empty() or not quest_unlocked(str(def.quest)):
		return ""
	if requirement_error(Database.worlds.get(world, {}).get("requirements", {})) != "":
		return ""
	var item := str(def.item)
	return item if inventory.count(item) == 0 else ""


## Só um achado pendente por mundo, mesmo após dias fora. A semente pertence ao montinho,
## separada do próximo horário, e não muda ao avançar tempo ou recarregar.
func update_finds() -> bool:
	var changed := false
	var period := moment_period()
	if finds.bonus_period != period:
		finds.bonus_period = period
		finds.bonus_used = 0
		changed = true
	for world: String in Database.finds.get("worlds", {}):
		var def: Dictionary = Database.finds.worlds[world]
		var quest_item := _quest_find_item(world)
		if quest_item == "" and requirement_error(def.get("requirements", {})) != "":
			continue
		if not finds.worlds.has(world):
			finds.worlds[world] = {"next_at": now() + float(Database.finds.settings.first_delay), "pending": 0, "spot": 0, "dug": 0, "seed": 0}
			changed = true
		var entry: Dictionary = finds.worlds[world]
		if int(entry.pending) >= mini(1, int(def.get("max_pending", 1))): continue
		var bonus := quest_item == "" and float(entry.next_at) > now() and int(entry.dug) > 0 and tiro_animated() and finds.bonus_used < int(Database.mood.animated.dig_extra_per_period) and requirement_error(Database.worlds.get(world, {}).get("requirements", {})) == ""
		if quest_item == "" and float(entry.next_at) > now() and not bonus: continue
		var spots: Array = Database.room(str(Database.worlds.get(world, {}).get("room", world))).get("dig_spots", [])
		if spots.is_empty():
			continue
		if bonus: finds.bonus_used += 1
		entry.seed = int(entry.next_at) + (7919 * finds.bonus_used if bonus else 0)
		entry.spot = Loot.amount([0, spots.size() - 1], int(entry.seed))
		entry.pending = 1
		entry["animated_bonus"] = bonus
		if not bonus: entry.next_at = now() + float(def.interval)
		changed = true
	return changed

func find_reward(world: String) -> Dictionary:
	if not finds.worlds.has(world) or not Database.finds.worlds.has(world):
		return {}
	var entry: Dictionary = finds.worlds[world]
	var def: Dictionary = Database.finds.worlds[world]
	var guaranteed: Array = def.get("guaranteed", [])
	var reward: Dictionary = guaranteed[int(entry.dug)].duplicate(true) if int(entry.dug) < guaranteed.size() else Loot.roll(def.get("table", []), 1, int(entry.seed))
	var quest_item := _quest_find_item(world)
	if quest_item != "":
		var items: Dictionary = reward.get("items", {}).duplicate()
		items[quest_item] = maxi(1, int(items.get(quest_item, 0)))
		reward["items"] = items
	if _milk_tooth_due():
		var with_tooth: Dictionary = reward.get("items", {}).duplicate()
		with_tooth["milk_tooth"] = 1
		reward["items"] = with_tooth
	return reward


## O primeiro montinho a partir da fase Dentinhos garante o dentinho de leite (uma vez só por save).
func _milk_tooth_due() -> bool:
	return growth.phase_index() >= growth.phase_index("teething") and progress.stat("find_item:milk_tooth") == 0

func dig_error(world: String) -> String:
	if walking():
		return away_text()
	if not finds.worlds.has(world) or int(finds.worlds[world].pending) <= 0:
		return "Nada para cavar aqui"
	if _quest_find_item(world) == "" and requirement_error(Database.finds.worlds.get(world, {}).get("requirements", {})) != "":
		return "Nada para cavar aqui"
	return storage_error(find_reward(world).get("items", {}))

func dig(world: String, origin: Vector2 = Vector2(-1, -1)) -> Dictionary:
	if dig_error(world) != "":
		return {}
	var reward := find_reward(world)
	var fresh: Array[String] = []
	for id: String in reward.get("items", {}):
		if progress.stat("find_item:" + id) == 0:
			fresh.append(id)
		_count("find_item:" + id, int(reward.items[id]))
		if Database.items.get(id, {}).get("rare", false): _diary("rare", Database.item_name(id))
	_apply_rewards(reward)
	finds.worlds[world].pending = 0
	finds.worlds[world].dug = int(finds.worlds[world].dug) + 1
	# O montinho normal reinicia o relógio; o extra preserva esse prazo.
	if not bool(finds.worlds[world].get("animated_bonus", false)):
		finds.worlds[world].next_at = now() + float(Database.finds.worlds[world].interval)
	_count("find")
	_count("find:" + world)
	for found: String in fresh:
		_moment_source("dig", found)
	_album_event("dug", {"world": world})
	for found: String in reward.get("items", {}):
		_album_event("dug", {"world": world, "item": found})
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
		return "Já pegou"
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

# --- Baú da Clareira (tesouro) ----------------------------------------------

func treasure_opened() -> bool:
	return bool(progress.seen.get("treasure_opened", false))


## Baú aparece com a missão "O mapa completo" e abre uma vez só.
func open_treasure_error() -> String:
	if treasure_opened():
		return "Já aberto"
	var def: Dictionary = Database.progression.get("treasure", {})
	var reason := requirement_error(def.get("requirements", {}))
	if reason != "":
		return reason
	return storage_error(def.get("rewards", {}).get("items", {}))


func open_treasure() -> String:
	var error := open_treasure_error()
	if error != "":
		return error
	var rewards: Dictionary = Database.progression.treasure.rewards
	_apply_rewards(rewards)
	progress.seen["treasure_opened"] = true
	_count("treasure")
	_changed()
	Events.treasure_opened.emit(rewards)
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


func dev_grant_cosmetics() -> void:
	if not BuildInfo.is_dev():
		return
	for id: String in Database.collections:
		progress.collection[id] = true
	_changed()

# --- Passeios ---------------------------------------------------------------
# Viagem e bagagem são estados diferentes (etapa 03): `walk_state.current` é a viagem; quando o tempo
# acaba, `return_due_walk` sorteia e congela o resultado UMA vez, aplica o que não é item (moedas, XP,
# afeto, coleção, cuidados do Tiro), conta o passeio e move os achados para `walk_state.pending_return`.
# O Tiro volta para casa mesmo que a bagagem não caiba; guardar os achados é uma ação à parte.

func walk_def(id: String) -> Dictionary:
	return Database.walks.get("walks", {}).get(id, {})


## O Tiro está fora de casa de verdade: viagem com tempo restante. Bagagem esperando NÃO conta.
func walking() -> bool:
	return walk_state.traveling(now())


func away_text() -> String:
	return str(Database.walks.get("settings", {}).get("away_text", "Tiro está passeando"))


## Motivo de o cuidado direto estar bloqueado ("" se o Tiro está em casa).
func away_error() -> String:
	return away_text() if walking() else ""


func walk_remaining() -> int:
	return walk_state.remaining(now())


## Há achados do passeio esperando para serem guardados (o Tiro já está em casa).
func walk_ready() -> bool:
	return walk_state.baggage_count() > 0


func walk_error(id: String) -> String:
	var def := walk_def(id)
	if def.is_empty():
		return "Passeio desconhecido"
	if walk_state.active():
		return "O Tiro já está passeando"
	if walk_ready():
		var hint := walk_baggage_hint()
		return hint if hint != "" else "Guarde os achados do último passeio"
	var closed := walk_lock_error(id)
	if closed != "":
		return closed
	var hours := walk_hours_error(id)
	if hours != "":
		return hours
	if dog.sleeping:
		return "Tiro está dormindo"
	if dog.get_need("energy", now()) < float(def.get("energy", 0)) + 5.0:
		return "Tiro está cansado: deixe ele dormir"
	return ""


## Requisitos do passeio sem o horário ("" = liberado; o horário só impede de começar).
func walk_lock_error(id: String) -> String:
	var requirements: Dictionary = walk_def(id).get("requirements", {}).duplicate()
	requirements.erase("hours")
	return requirement_error(requirements)


## "Abre às 17h" se o passeio tem janela de horário e agora está fora dela.
func walk_hours_error(id: String, local_hour: int = -1) -> String:
	var hours: Array = walk_def(id).get("requirements", {}).get("hours", [])
	if hours.is_empty():
		return ""
	var hour := int(Time.get_datetime_dict_from_unix_time(_local_time()).hour) if local_hour < 0 else local_hour
	var from_hour := int(hours[0])
	var to_hour := int(hours[1])
	var inside := from_hour <= hour and hour < to_hour if from_hour < to_hour else hour >= from_hour or hour < to_hour
	if inside:
		return ""
	return "Abre às %dh" % int(hours[0])


## Quantos passeios faltam, no máximo, para o raro vir com certeza (0 se o raro já é do jogador).
func walk_pity_left(id: String) -> int:
	var rare: Dictionary = walk_def(id).get("loot", {}).get("rare", {})
	if rare.is_empty() or progress.collection.has(str(rare.get("collection", ""))):
		return 0
	return maxi(1, int(rare.get("pity", 1)) - int(walk_state.pity.get(id, 0)))


## Passeios que valem "Novo!": liberados (fora o horário) e não silenciosos.
func walk_unlock_keys() -> Array[String]:
	var keys: Array[String] = []
	for id: String in Database.walks.get("walks", {}):
		if not walk_def(id).get("silent", false) and walk_lock_error(id) == "":
			keys.append("walk:" + id)
	return keys


func start_walk(id: String) -> String:
	return_due_walk()
	var error := walk_error(id)
	if error != "":
		return error
	var animated := tiro_animated()
	var def := walk_def(id)
	dog.apply({"energy": -float(def.get("energy", 0))}, now())
	var snapshot := WorkJobs.walk(id, Database.walks, Database.finds.get("worlds", {}))
	snapshot["animated"] = animated
	snapshot["animated_rolls"] = int(Database.mood.animated.walk_extra_rolls) if animated else 0
	# Uma bagagem já vazia (só o cartão dela ficou) não impede o próximo passeio.
	walk_state.pending_return = {}
	walk_state.current = {
		"id": id,
		"started_at": now(),
		"ready_at": now() + float(def.get("seconds", 60)),
		"seed": int(now()),
		"energy": int(def.get("energy", 0)),
		"snapshot": snapshot,
	}
	_changed()
	return ""


## Liquida a viagem cujo tempo acabou: idempotente (sem viagem vencida não faz nada). Roda no tick, ao
## carregar o save e antes de começar/cancelar/recolher; a interface nunca é dona do retorno.
## `announce` = emitir o resumo para a fila de cartões (falso ao carregar: o cartão sai da marca persistida).
## Devolve true se liquidou agora.
func return_due_walk(announce: bool = true) -> bool:
	if not walk_state.due(now()):
		return false
	var trip: Dictionary = walk_state.current
	var id := str(trip.get("id", ""))
	var snapshot := _walk_snapshot(trip)
	var def: Dictionary = snapshot.get("def", walk_def(id))
	var loot := _roll_walk(trip)
	var returned_at := minf(float(trip.get("ready_at", 0.0)), now())
	var fresh: Array[String] = []
	for item: String in loot.items:
		var category: String = Database.items.get(item, {}).get("category", "")
		if category == "find" and progress.stat("find_item:" + item) == 0:
			fresh.append(item)
		elif category == "trail" and progress.stat("walk_item:" + item) == 0:
			fresh.append(item)
	var costumes: Array[String] = []
	if str(loot.rare) != "":
		costumes.append(str(loot.rare))
	var legendary := str(loot.get("legendary", ""))
	if legendary != "":
		costumes.append(legendary)
	# Os cuidados do Tiro entram no instante da volta; o tempo depois dele segue normal.
	dog.apply(def.get("needs", {}), maxf(returned_at, dog.updated_at))
	var rewards: Dictionary = def.get("rewards", {}).duplicate(true)
	rewards["coins"] = int(rewards.get("coins", 0)) + int(loot.coins)
	rewards["collections"] = costumes
	rewards.erase("items")
	_apply_rewards(rewards)
	if legendary != "":
		_count("walk_legendary")
		walk_state.pity["legendary"] = 0
	elif requirement_error(snapshot.legendary.get("requirements", {})) == "" and snapshot.legendary.get("collections", []).any(func(collection: String) -> bool: return not progress.collection.has(collection)):
		walk_state.pity["legendary"] = int(walk_state.pity.get("legendary", 0)) + 1
	walk_state.history[id] = {"count": int(walk_state.history.get(id, {}).get("count", 0)) + 1}
	walk_state.pity[id] = 0 if str(loot.rare) != "" or bool(loot.rare_duplicate) else int(walk_state.pity.get(id, 0)) + 1
	_count("walk")
	_count("walk:" + id)
	_diary("walk", str(def.get("name", id)))
	_moment_source("walk", id)
	if str(loot.rare) != "":
		_diary("rare", Database.item_name(str(loot.rare)))
		_count("walk_rare")
		_count("walk_rare:" + id)
	_album_event("walk_returned", {"route": id, "rare": str(loot.rare) != ""})
	var result := {"id": id, "name": str(walk_def(id).get("name", id)), "postcard": walk_postcard(id), "items": loot.items.duplicate(), "coins": int(rewards.coins),
			"loot_coins": int(loot.coins), "needs": def.get("needs", {}).duplicate(), "new": fresh, "new_items": fresh,
			"first": bool(loot.first), "rare": str(loot.rare), "rare_item": str(loot.rare_item), "rare_duplicate": bool(loot.rare_duplicate), "legendary": legendary, "collections": costumes}
	walk_state.pending_return = {
		"id": id, "started_at": float(trip.get("started_at", returned_at)), "ready_at": float(trip.get("ready_at", returned_at)), "returned_at": returned_at, "seed": int(trip.get("seed", 0)),
		"result": result, "left": loot.items.duplicate(), "rewards_applied": true, "result_shown": false,
	}
	walk_state.current = {}
	if announce:
		_changed()
		if int(rewards.coins) > 0:
			Events.items_gained.emit({}, int(rewards.coins), Vector2(-1.0, -1.0))
		if str(loot.rare) != "":
			Events.dog_action.emit(&"wish")
		Events.walk_collected.emit(walk_result_view())
	return true


## Resumo da última volta para o cartão (itens = tudo o que veio; `left` = o que ainda espera). {} sem bagagem.
func walk_result_view() -> Dictionary:
	if not walk_state.has_baggage():
		return {}
	var view: Dictionary = (walk_state.pending_return.result as Dictionary).duplicate(true)
	view["left"] = walk_state.baggage_left().duplicate()
	view["items_claimed"] = walk_state.baggage_left().is_empty()
	view["result_shown"] = bool(walk_state.pending_return.result_shown)
	return view


## O cartão da volta foi apresentado: reabrir o resumo não premia de novo. Bagagem vazia some.
func mark_walk_result_shown() -> void:
	if not walk_state.has_baggage() or bool(walk_state.pending_return.result_shown):
		return
	walk_state.pending_return["result_shown"] = true
	if walk_state.baggage_left().is_empty():
		walk_state.pending_return = {}
	_changed()


## Há um resultado de volta que ainda não foi mostrado (carregar o save, outro slot...).
func walk_result_unseen() -> bool:
	return walk_state.has_baggage() and not bool(walk_state.pending_return.result_shown)


## Sorteio do passeio, estável: depende só da semente guardada, do contrato congelado e do que já foi
## recolhido (histórico e garantia só mudam na volta). Devolve moedas, itens, "first", "rare"
## (id do apetrecho, "" se não veio) e "rare_duplicate" (já era do jogador: vira prêmio de consolo).
## Com bagagem esperando devolve o resultado congelado; com viagem em curso, uma prévia do sorteio.
func walk_loot() -> Dictionary:
	if walk_state.active():
		return _roll_walk(walk_state.current)
	if walk_state.has_baggage():
		var frozen: Dictionary = (walk_state.pending_return.result as Dictionary).duplicate(true)
		frozen["coins"] = int(frozen.get("loot_coins", 0))
		return frozen
	return {"coins": 0, "items": {}, "first": false, "rare": "", "rare_item": "", "rare_duplicate": false}


func _roll_walk(trip: Dictionary) -> Dictionary:
	var id := str(trip.get("id", ""))
	var snapshot := _walk_snapshot(trip)
	var def: Dictionary = snapshot.def
	var loot: Dictionary = def.get("loot", {})
	var seed := int(trip.get("seed", 0))
	var coins := 0
	var items := {}
	var first := int(walk_state.history.get(id, {}).get("count", 0)) == 0 and loot.has("first")
	if first:
		coins += int(loot.first.get("coins", 0))
		_add_amounts(items, loot.first.get("items", {}))
	for i in int(loot.get("rolls", 1)) + (1 if has_upgrade("walk_bag") else 0) + friend_walk_bonus() + int(snapshot.get("animated_rolls", 0)):
		var entry := Loot.pick_weighted(loot.get("table", []), seed + i * 7919)
		var drop := Loot.roll([entry], 1, seed + i * 104729 + 1)
		if entry.has("find"):
			drop = Loot.roll(snapshot.find_tables.get(str(entry.find), Database.finds.get("worlds", {}).get(str(entry.find), {}).get("table", [])), 1, seed + i * 15485863 + 2)
		coins += int(drop.coins)
		_add_amounts(items, drop.items)
	# Garantia da rota inicial: até o baú existir, a volta completa os gravetos que ele pede (sem sorteio).
	var guarantee: Dictionary = loot.get("guarantee", {})
	if not guarantee.is_empty() and not has_upgrade(str(guarantee.get("until_owned", ""))):
		var guaranteed := str(guarantee.get("item", ""))
		var short := int(guarantee.get("count", 0)) - inventory.count(guaranteed) - int(items.get(guaranteed, 0))
		if short > 0:
			items[guaranteed] = int(items.get(guaranteed, 0)) + short
	var rare := ""
	var rare_item := ""
	var duplicate := false
	var rare_def: Dictionary = loot.get("rare", {})
	if not rare_def.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = seed + 999331
		if rng.randf() < float(rare_def.get("chance", 0.0)) or int(walk_state.pity.get(id, 0)) + 1 >= int(rare_def.get("pity", 1)):
			rare = str(rare_def.collection)
			rare_item = rare
			duplicate = progress.collection.has(rare)
			if duplicate:
				coins += int(rare_def.get("duplicate", {}).get("coins", 0))
				_add_amounts(items, rare_def.get("duplicate", {}).get("items", {}))
				rare = ""
	return {"coins": coins, "items": items, "first": first, "rare": rare, "rare_item": rare_item, "rare_duplicate": duplicate, "legendary": _walk_legendary(seed, snapshot.legendary)}


## Contrato da viagem: o que valia quando o Tiro saiu (sem snapshot, a tabela viva).
func _walk_snapshot(trip: Dictionary = walk_state.current) -> Dictionary:
	var stored: Dictionary = trip.get("snapshot", {})
	if not stored.is_empty():
		return stored
	var live := WorkJobs.walk(str(trip.get("id", "")), Database.walks, Database.finds.get("worlds", {}))
	return live if not live.is_empty() else {"def": {}, "legendary": {}, "find_tables": {}}


## Sorteio independente: nunca ocupa o lugar do raro nem gasta a garantia dele.
func _walk_legendary(seed: int, data: Dictionary = Database.walks.get("legendary", {})) -> String:
	if data.is_empty() or requirement_error(data.get("requirements", {})) != "":
		return ""
	var missing: Array[String] = []
	for id: String in data.get("collections", []):
		if not progress.collection.has(id):
			missing.append(id)
	if missing.is_empty():
		return ""
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 130363
	if rng.randf() < float(data.get("chance", 0.01)) or int(walk_state.pity.get("legendary", 0)) + 1 >= int(data.get("pity", 30)):
		return missing[0]
	return ""


func _add_amounts(target: Dictionary, amounts: Dictionary) -> void:
	for item: String in amounts:
		target[item] = int(target.get(item, 0)) + int(amounts[item])


## Quanto da bagagem cabe agora, por parcelas, sem alterar nada: { moved: {item: qtd}, blocked: depósito,
## item e missing: o primeiro item que não coube e quantas unidades faltam de espaço }.
func walk_baggage_plan() -> Dictionary:
	var moved := {}
	var blocked := ""
	var blocked_item := ""
	var missing := 0
	var space := {}
	var left: Dictionary = walk_state.baggage_left()
	for item_id: String in left:
		var amount := int(left[item_id])
		var depot := storage_of(item_id)
		var fits := amount
		if depot != "" and storage_active(depot):
			fits = mini(amount, int(space.get(depot, storage_space(depot))))
			space[depot] = int(space.get(depot, storage_space(depot))) - fits
		if fits > 0:
			moved[item_id] = fits
		if fits < amount and blocked == "":
			blocked = depot
			blocked_item = item_id
			missing = amount - fits + storage_excess(depot)
	return {"moved": moved, "blocked": blocked, "item": blocked_item, "missing": missing}


## "Baú sem espaço: abra lugar para Graveto ×3" ("" se tudo cabe ou não há bagagem).
func walk_baggage_hint() -> String:
	var plan := walk_baggage_plan()
	return pending_blocked_text(plan) if plan.blocked != "" else ""


## Depósito que impede guardar a bagagem ("" se cabe).
func walk_baggage_depot() -> String:
	return str(walk_baggage_plan().blocked)


func walk_baggage_error() -> String:
	if not walk_ready():
		return "Nenhum achado para guardar"
	var plan := walk_baggage_plan()
	if not plan.moved.is_empty():
		return ""
	return pending_blocked_text(plan)


## Guarda na Mochila o que cabe da bagagem; o resto continua esperando, sem perder nem repetir nada.
## Os contadores de itens (`walk_item`, `find_item`) só andam com o que entrou. Devolve {item: qtd} guardados.
func claim_walk_baggage() -> Dictionary:
	if walk_baggage_error() != "":
		return {}
	var plan := walk_baggage_plan()
	var stored: Dictionary = plan.moved
	var total := 0
	for item: String in stored:
		var amount := int(stored[item])
		inventory.add(item, amount)
		if Database.items.get(item, {}).get("category", "") == "find":
			_count("find_item:" + item, amount)
		_count("walk_item:" + item, amount)
		total += amount
		var remaining_amount := int(walk_state.pending_return.left[item]) - amount
		if remaining_amount > 0:
			walk_state.pending_return.left[item] = remaining_amount
		else:
			walk_state.pending_return.left.erase(item)
	_count("walk_item", total)
	if walk_state.baggage_left().is_empty() and bool(walk_state.pending_return.result_shown):
		walk_state.pending_return = {}
	_changed()
	Events.items_gained.emit(stored, 0, Vector2(-1.0, -1.0))
	return stored


## Compatibilidade: motivo de não conseguir terminar o passeio e guardar os achados ("" = pode).
func collect_walk_error() -> String:
	if walk_state.traveling(now()):
		return "O passeio ainda não terminou"
	if walk_state.due(now()):
		return ""
	if not walk_state.has_baggage():
		return "Nenhum passeio"
	return walk_baggage_error() if walk_ready() else ""


## Compatibilidade: liquida a volta (se preciso) e tenta guardar a bagagem. Devolve o resumo da volta
## (vazio se nada foi guardado). O Tiro volta para casa mesmo quando a bagagem não cabe.
func collect_walk() -> Dictionary:
	var returned_now := return_due_walk()
	if walk_state.traveling(now()) or not walk_state.has_baggage() or (not returned_now and not walk_ready()):
		return {}
	var view := walk_result_view()
	if walk_ready() and claim_walk_baggage().is_empty():
		return {}
	view["left"] = walk_state.baggage_left().duplicate()
	return view


## Chama o Tiro de volta antes da hora: devolve a energia, sem prêmio. Só durante a viagem.
func cancel_walk() -> String:
	if not walk_state.traveling(now()):
		return "O Tiro já voltou" if walk_state.has_baggage() or walk_state.active() else "Nenhum passeio"
	dog.apply({"energy": float(walk_state.current.get("energy", 0))}, now())
	walk_state.current = {}
	_changed()
	return ""


func walk_postcard(id: String) -> String:
	var settings: Dictionary = Database.walks.get("settings", {})
	return str(settings.get("postcard_dir", "")) + str(walk_def(id).get("postcard", ""))


# --- Truques --------------------------------------------------------------

func trick_available_error(id: String) -> String:
	if not Database.progression.tricks.has(id):
		return "Truque desconhecido"
	if walking():
		return away_text()
	if dog.sleeping:
		return "Shh... ele está dormindo."
	return requirement_error(Database.progression.tricks[id].get("requirements", {}))


func learn_trick_error(id: String) -> String:
	var error := trick_available_error(id)
	if error != "":
		return error
	if bool(progress.tricks.get(id, false)):
		return "Truque já aprendido"
	for previous: String in Database.progression.tricks:
		if previous == id:
			break
		if not bool(progress.tricks.get(previous, false)):
			return "Aprenda " + str(Database.progression.tricks[previous].name)
	return ""


func learn_trick(id: String) -> String:
	var error := learn_trick_error(id)
	if error != "":
		return error
	progress.tricks[id] = true
	_count("trick_learned")
	_moment_source("learn_trick", id)
	_album_event("trick_learned", {"trick": id})
	_changed()
	Events.trick_learned.emit(id)
	return ""


func perform_trick_error(id: String) -> String:
	var error := trick_available_error(id)
	if error != "":
		return error
	if not bool(progress.tricks.get(id, false)):
		return "Aprenda com a Nina na Praça"
	var wait := progress.cooldown_left("trick:" + id, now())
	return "Descansa por " + TimeText.short(wait) if wait > 0 else ""


func perform_trick(id: String) -> String:
	var error := perform_trick_error(id)
	if error != "":
		return error
	var settings: Dictionary = Database.progression.trick_settings
	var effects: Dictionary = settings.perform.duplicate(true)
	dog.apply(effects, now())
	progress.cooldowns["trick:" + id] = now() + float(settings.cooldown)
	_count("trick")
	_count("trick:" + id)
	_moment_source("trick")
	_changed()
	Events.dog_action.emit(StringName(Database.progression.tricks[id].animation))
	return ""


# --- Ações do Tiro ---------------------------------------------------------

func feed(item_id: String) -> bool:
	var useful := _need_is_low("hunger")
	var effects: Dictionary = Database.items.get(item_id, {}).get("feed", {})
	if walking() or effects.is_empty() or inventory.count(item_id) < 1:
		return false
	var meal_before: Dictionary = {}
	for row: Dictionary in growth_info().requirements:
		if row.type == "feed" and not row.done:
			meal_before = row
	var body_before := growth.body_level
	inventory.remove(item_id)
	dog.apply(effects, now())
	_count("feed")
	_count("feed:" + item_id)
	growth.firsts["food:" + item_id] = true
	_taste(item_id)
	_album_event("fed", {"item": item_id, "growth_food": Database.items.get(item_id, {}).has("growth")})
	_care_useful("feed", useful)
	_care_reward("feed", useful)
	_changed()
	Events.dog_action.emit(&"feed")
	if not meal_before.is_empty():
		for row: Dictionary in growth_info().requirements:
			if row.id == meal_before.id and int(row.have) > int(meal_before.have):
				var message := "Refeições para crescer: %d/%d" % [mini(int(row.have), int(row.need)), int(row.need)]
				var body_gain := growth.body_level - body_before
				if body_gain > 0: message += " · Corpo +%d" % body_gain
				if row.done: message = "Refeições completas! Corpo pronto para crescer."
				Events.toast_requested.emit(message)
	return true


## Carinho útil rende um momento; devolve o ganho efetivo (0 ou 1). `zone` = onde o dedo ficou
## (`head`, `chin`, `belly`); o lugar favorito dá mais Felicidade, rola de barriga para cima e é revelado na 1ª vez.
func pet(zone: String = "") -> int:
	if walking(): return 0
	var useful := _need_is_low("happiness")
	var loved := zone != "" and zone == favorite_spot()
	dog.apply(Database.actions.get("pet_favorite" if loved else "pet", {}), now())
	_count("pet")
	_album_event("petted")
	var gained := 0
	if _care_useful("pet", useful):
		gained = _moment_source("pet")
	if loved:
		var first := not growth.firsts.has("fav_spot")
		var where := str(Database.growth.gestures.spots[zone])
		if first:
			growth.firsts["fav_spot"] = true
			_diary("spot", where)
			Events.toast_requested.emit("Ele ama carinho %s!" % where)
		Events.favorite_spot_loved.emit(zone, first)
	_changed()
	Events.dog_action.emit(&"pet")
	return gained


## Lugar favorito deste save, fixo pela semente (como a comida favorita).
func favorite_spot() -> String:
	var spots: Array = Database.growth.gestures.spots.keys()
	return str(spots[absi(hash("spot:%d" % growth.taste_seed)) % spots.size()])


func favorite_spot_found() -> bool:
	return growth.firsts.has("fav_spot")


# --- Esconde-esconde (Cuidar é crescer, etapa 04) ---

## Petiscos (`treat: true`) que há na mochila, na ordem do catálogo.
func hide_treats() -> Array[String]:
	var result: Array[String] = []
	for id: String in Database.items:
		if Database.items[id].get("treat", false) and inventory.count(id) > 0: result.append(id)
	return result


func hide_unlocked() -> bool:
	return growth.phase_index() >= growth.phase_index(str(Database.growth.gestures.hide_seek.phase))


## Trocas dos copinhos na fase atual.
func hide_swaps() -> int:
	return int(Database.growth.gestures.hide_seek.swaps.get(growth.phase, 0))


func hide_and_seek_error(item: String) -> String:
	if walking(): return away_text()
	if dog.sleeping: return "Shh... ele está dormindo."
	if not hide_unlocked(): return "Ele ainda é pequeno para esse jogo."
	if not Database.items.get(item, {}).get("treat", false): return "Isso não é um petisco."
	if inventory.count(item) < 1: return "Falta o petisco."
	return ""


## Começa uma rodada: consome 1 petisco e deixa a rodada pendente até `finish_hide_and_seek`.
func hide_and_seek(item: String) -> String:
	var error := hide_and_seek_error(item)
	if error != "": return error
	inventory.remove(item)
	hide_pending = true
	_changed()
	return ""


## Fim da rodada (acertando ou não): o Tiro come o petisco, ganha Felicidade e o momento de Esperteza
## (respeita o teto do período). Devolve o momento ganho (0 ou 1); sem rodada pendente não faz nada.
func finish_hide_and_seek(found: bool) -> int:
	if not hide_pending: return 0
	hide_pending = false
	dog.apply(Database.actions.get("hide", {}), now())
	_count("hide")
	if found: _count("hide_found")
	var gained := _moment_source("hide")
	_changed()
	Events.dog_action.emit(&"hide")
	return gained


func pet_growth_info() -> Dictionary:
	return _care_moment_info("brave", "Carinho", "happiness")


func play_growth_info() -> Dictionary:
	return _care_moment_info("smart", "Brincar", "happiness")


func _care_moment_info(pillar: String, action: String, need: String) -> Dictionary:
	var asking := _need_is_low(need)
	var left := maxi(0, int(Database.growth.moments.period_cap) - int(growth.period_moments.get(moment_period() + ":" + pillar, 0)))
	var hint := action + (" pode render um momento." if asking else ": ele está satisfeito.")
	if left == 0: hint = "Momentos deste período completos. Conheça novidades ou volte no próximo período."
	return {"have": int(growth.phase_moments.get(pillar, 0)), "need": growth.phase_need(pillar), "asking": asking, "left": left, "hint": hint, "status": hint}


func play() -> bool:
	if walking() or dog.sleeping or dog.get_need("energy", now()) < 15.0:
		return false
	var useful := _need_is_low("happiness")
	dog.apply(Database.actions.get("play", {}), now())
	_count("play")
	_album_event("played")
	if _care_useful("play", useful):
		_moment_source("play")
	_care_reward("play", useful)
	_changed()
	Events.dog_action.emit(&"play")
	return true


func bathe(with_shampoo: bool = false) -> void:
	if walking() or (with_shampoo and inventory.count("herb_shampoo") < 1):
		return
	var useful := _need_is_low("hygiene")
	if with_shampoo: inventory.remove("herb_shampoo")
	dog.apply(Database.actions.get("bathe", {}), now())
	_count("bathe")
	_album_event("bathed")
	if _care_useful("bathe", useful):
		_moment_source("shampoo_bath" if with_shampoo else "bath")
	if with_shampoo: _count("shampoo_bath")
	_care_reward("bathe", useful)
	_changed()
	Events.dog_action.emit(&"bathe")


func set_sleeping(value: bool, spot: String = "") -> void:
	if value and walking():
		return
	var started := value and not dog.sleeping
	if not value:
		album_sleep_spot = ""
	dog.set_sleeping(value, now())
	if value and not started and spot != "" and album_sleep_spot != spot:
		album_sleep_spot = spot
		_album_event("slept", {"spot": spot})
	if started:
		_count("sleep_started")
		album_sleep_spot = spot if spot != "" else default_sleep_spot()
		_album_event("slept", {"spot": album_sleep_spot})
	_changed()


## Ajuda sem moedas para nunca travar o cuidado com o Tiro (recarga em progression.json).
func emergency_food() -> String:
	var wait := progress.cooldown_left("emergency_food", now())
	if wait > 0:
		return "A ajuda volta em " + TimeText.short(wait)
	var settings: Dictionary = Database.progression.settings
	inventory.add("dog_food", int(settings.emergency_food_amount))
	progress.cooldowns["emergency_food"] = now() + float(settings.emergency_food_cooldown)
	_changed()
	return ""


# Cuidado útil (etapa 16): só conta quando recupera de verdade ou cumpre um pedido que ainda falta.
const CARE_NEEDS: Array[String] = ["hunger", "happiness", "hygiene", "energy"]





func _care_useful(action: String, useful: bool) -> bool:
	if not useful: return false
	_count("care_useful")
	_count("care_useful:" + action)
	return true


func _need_is_low(need_id: String) -> bool:
	return dog.get_need(need_id, now()) < float(Database.needs[need_id].get("ask_below", 50))


## Estado calculado: acordado e nenhuma necessidade pedindo.
func tiro_animated() -> bool:
	return not dog.sleeping and asking_need() == ""


func animated_help() -> String:
	return "Ajuda na horta, passeio e faro."


## A necessidade está pedindo cuidado (abaixo do `ask_below` dela)?
func need_asking(need_id: String) -> bool:
	return Database.needs.has(need_id) and _need_is_low(need_id)


## Pilar que o cuidado desta necessidade faz crescer ("" = nenhum): felicidade vai para o que mais falta
## (Coragem no empate); higiene é Pelagem; fome é Corpo; energia não rende momento.
func need_pillar(need_id: String) -> String:
	match need_id:
		"happiness": return "smart" if _pillar_missing("smart") > _pillar_missing("brave") else "brave"
		"hygiene": return "coat"
		"hunger": return "body"
	return ""


## A necessidade que mais pede cuidado agora ("" = nenhuma), a mais baixa primeiro.
func asking_need() -> String:
	var result := ""
	var lowest := 1000.0
	for need_id: String in CARE_NEEDS:
		var value := dog.get_need(need_id, now())
		if need_asking(need_id) and value < lowest:
			result = need_id
			lowest = value
	return result


func _care_reward(action_id: String, useful: bool) -> void:
	if useful: _gain_xp(action_id)


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
	return cook_many(recipe_id, 1)


## Prepara N lotes iguais de uma vez (Etapa 12): cada um é um trabalho próprio na fila, com os
## ingredientes e o snapshot dele, começando quando o anterior termina. Tudo ou nada: se faltar
## vaga ou ingrediente para qualquer um dos N, nada é consumido nem enfileirado.
func cook_many(recipe_id: String, count: int) -> String:
	var error := cook_many_error(recipe_id, count)
	if error != "":
		return error
	var recipe: Dictionary = Database.recipes[recipe_id]
	var station_id: String = recipe.station
	var animal: bool = Database.stations[station_id].get("kind", "") == "animal"
	var target := station(station_id)
	var paid := recipe_inputs(recipe_id)
	for i in count:
		inventory.remove_all(paid)
		target.enqueue(recipe_id, float(recipe.seconds), now())
		target.queue.back()["qty"] = recipe_quantity(recipe_id)
		target.queue.back()["job"] = WorkJobs.batch(recipe_id, Database.recipes, Database.xp, Database.stations, recipe_quantity(recipe_id), paid)
		if animal:
			target.queue.back()["animals"] = animal_roster(station_id)
	_changed()
	if animal:
		Events.world_activity.emit(&"feed_animal", station_id, -1)
	return ""


## Primeiro item que falta, como "Falta Cenoura ×2"; sem faltar nada devolve o texto geral.
func _missing_text(amounts: Dictionary, fallback: String) -> String:
	for id: String in amounts:
		var lack := int(amounts[id]) - inventory.count(id)
		if lack > 0:
			return "Falta %s ×%d" % [Database.item_name(id), lack]
	return fallback


## A mesma validação para alimentação dos animais e fabricação nas estações.
func cook_error(recipe_id: String) -> String:
	return cook_many_error(recipe_id, 1)


## Vagas livres da estação (as prontas e ainda não pegas continuam ocupando a vaga).
func station_free_slots(station_id: String) -> int:
	return maxi(0, station_slots(station_id) - station(station_id).queue.size())


## Quantos lotes dá para preparar agora: o menor entre vagas livres e lotes que os ingredientes pagam.
## Criações e costura de coleção são sempre um por vez. 0 = não dá nem um (ver `cook_error`).
func cook_max(recipe_id: String) -> int:
	if not Database.recipes.has(recipe_id) or cook_many_error(recipe_id, 1) != "":
		return 0
	var recipe: Dictionary = Database.recipes[recipe_id]
	if recipe.has("output_collection") or Database.stations[recipe.station].get("kind", "") == "animal":
		return 1
	var result := station_free_slots(str(recipe.station))
	var inputs := recipe_inputs(recipe_id)
	for id: String in inputs:
		result = mini(result, inventory.count(id) / maxi(1, int(inputs[id])))
	return result


## Ingredientes totais de N lotes.
func cook_inputs(recipe_id: String, count: int) -> Dictionary:
	var result := recipe_inputs(recipe_id)
	for id: String in result:
		result[id] = int(result[id]) * count
	return result


## Quando o último dos N lotes ficaria pronto (Unix), contando o que já está na fila.
func cook_finish_at(recipe_id: String, count: int) -> float:
	var queue := station(str(Database.recipes[recipe_id].station)).queue
	var start := now()
	if not queue.is_empty():
		start = maxf(start, float(queue.back()["ready_at"]))
	return start + float(Database.recipes[recipe_id].seconds) * count


## Consulta pura da ação `cook_many`: devolve "" ou o motivo, sem alterar nada.
func cook_many_error(recipe_id: String, count: int) -> String:
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
	var cosmetic := str(recipe.get("output_collection", ""))
	var animal: bool = Database.stations[station_id].get("kind", "") == "animal"
	if count < 1:
		return "Escolha quantos"
	if cosmetic != "":
		if progress.collection.has(cosmetic):
			return "Você já tem"
		for queue_state: StationState in stations.values():
			for entry: Dictionary in queue_state.queue:
				if str(Database.recipes.get(str(entry.recipe), {}).get("output_collection", "")) == cosmetic:
					return "Já está sendo costurado"
	if animal and animal_count(station_id) == 0:
		return "Compre um animal para começar"
	if target.queue.size() >= station_slots(station_id):
		return "Fila cheia"
	if count > 1 and (animal or cosmetic != ""):
		return "Um por vez"
	if count > station_free_slots(station_id):
		return "Só cabem %d na fila" % station_free_slots(station_id)
	var needed := cook_inputs(recipe_id, count)
	if not inventory.has_all(needed):
		return _missing_text(needed, "Faltam ingredientes")
	return ""


## Coleta tudo o que está pronto na estação. Retorna os itens recebidos.
func collect(station_id: String) -> Dictionary:
	var received := {}
	var blocked := ""
	for entry: Dictionary in station(station_id).take_ready_batches(now()):
		var recipe_id: String = entry.recipe
		# O contrato do lote vale o que foi pago ao começar; sem snapshot (entrada montada à mão), a receita atual.
		var job: Dictionary = entry.get("job", {})
		if job.is_empty():
			var live: Dictionary = Database.recipes.get(recipe_id, {})
			job = WorkJobs.batch(recipe_id, Database.recipes, Database.xp, Database.stations, int(entry.get("qty", live.get("qty", 1))), {})
		if job.is_empty():
			continue  # receita removida do JSON e sem snapshot: descarta sem travar a fila
		var output := str(job.output)
		if bool(job.collection):
			if not progress.collection.has(output):
				progress.collection[output] = true
				_count("sew")
				_count("produce:" + output)
				_count("produce")
				_count("production_jobs")
				_discover("recipe:" + recipe_id, str(job.skill), int(job.skill_xp))
				Events.cosmetic_received.emit(output)
				_changed()
			continue
		var qty := int(job.qty)
		var full := storage_error({output: qty})
		if full != "":
			# Não cabe: o lote continua pronto na fila, nada se perde.
			station(station_id).queue.append(entry)
			blocked = full
			continue
		inventory.add(output, qty)
		_count("produce:" + output, qty)
		_count("produce", qty)
		_count("production_jobs")  # um lote = 1, mesmo que saiam 2 ou 3 unidades
		_count_station_job(station_id, recipe_id)
		_discover("recipe:" + recipe_id, str(job.skill), int(job.skill_xp))
		received[output] = int(received.get(output, 0)) + qty
		_add_player_xp(int(job.player_xp))
	if blocked != "":
		Events.toast_requested.emit(blocked)
	if not received.is_empty():
		_changed()
		Events.world_activity.emit(&"collect", station_id, -1)
	return received


# --- Maestria das estações (etapa 18) -----------------------------------------------------------
# Reconhecimento de uso diverso, derivado de lotes concluídos e recolhidos (um lote = 1, qualquer que seja a
# saída). Sem XP farmável e sem efeito na produção: só selo e uma recompensa única por patamar.

func mastery_enabled(station_id: String) -> bool:
	return station_id in Database.progression.get("mastery", {}).get("stations", [])


func mastery_tiers() -> Array:
	return Database.progression.get("mastery", {}).get("tiers", [])


## Lotes recebidos nesta estação (sem animais nem costura de coleção).
func mastery_jobs(station_id: String) -> int:
	return progress.stat("station_jobs:" + station_id)


## Receitas da estação que já foram feitas ao menos uma vez.
func mastery_kinds_done(station_id: String) -> int:
	var done := 0
	for recipe_id: String in Database.recipes_for(station_id):
		if progress.stat("station_recipe_jobs:%s:%s" % [station_id, recipe_id]) > 0:
			done += 1
	return done


## Catálogo elegível: receitas comuns que já estão abertas para o jogador ou que ele já fez.
## Cosméticos únicos (costura de coleção) ficam de fora.
func mastery_catalog_size(station_id: String) -> int:
	var total := 0
	for recipe_id: String in Database.recipes_for(station_id):
		var recipe: Dictionary = Database.recipes[recipe_id]
		if recipe.has("output_collection"):
			continue
		if progress.stat("station_recipe_jobs:%s:%s" % [station_id, recipe_id]) > 0 or content_error("recipe", recipe_id, recipe) == "":
			total += 1
	return total


## Variedade pedida pelo patamar (índice 0..2): min(meta, catálogo elegível), nunca menos de 1.
func mastery_kinds_needed(station_id: String, index: int) -> int:
	var tiers := mastery_tiers()
	return maxi(1, mini(int(tiers[index].kinds), mastery_catalog_size(station_id)))


func _mastery_reached(station_id: String, index: int) -> bool:
	if economy.granted.has("mastery:%s:%d" % [station_id, index + 1]):
		return true  # o que já foi recebido não retrocede (receita nova no catálogo, por exemplo)
	return mastery_jobs(station_id) >= int(mastery_tiers()[index].jobs) 			and mastery_kinds_done(station_id) >= mastery_kinds_needed(station_id, index)


## Patamar atual (0 = nenhum, 3 = ouro).
func mastery_level(station_id: String) -> int:
	if not mastery_enabled(station_id):
		return 0
	var level := 0
	for index in mastery_tiers().size():
		if _mastery_reached(station_id, index):
			level = index + 1
	return level


## Conta um lote recebido (uma vez, no recolhimento) e paga os patamares novos.
func _count_station_job(station_id: String, recipe_id: String) -> void:
	if not mastery_enabled(station_id):
		return
	_count("station_jobs:" + station_id)
	_count("station_recipe_jobs:%s:%s" % [station_id, recipe_id])
	_pay_mastery(station_id)


func _pay_mastery(station_id: String) -> void:
	var tiers := mastery_tiers()
	var newest := -1
	for index in tiers.size():
		var auto_id := "mastery:%s:%d" % [station_id, index + 1]
		if economy.granted.has(auto_id) or not _mastery_reached(station_id, index):
			continue
		_grant_automatic(auto_id, tiers[index].rewards)
		newest = index
	if newest >= 0:
		Events.toast_requested.emit("%s: selo %s" % [str(Database.stations.get(station_id, {}).get("name", station_id)), str(tiers[newest].name)])


## Save anterior à maestria: o histórico de `produce:<item>` conta unidades, não lotes. Registra o MÍNIMO
## comprovável (unidades ÷ maior rendimento conhecido, arredondado para cima); nunca supõe um lote por unidade.
## Saída produzida por mais de uma receita da estação (tábua: bancada comum e madeira de lei) não diz qual
## receita foi feita: só o total da estação sobe e o medidor de variedade fica em 0 para ela.
## Não paga nada aqui: os patamares alcançados saem no próximo lote recolhido da estação.
func _seed_mastery() -> void:
	if economy.mastery_method != "":
		return
	var legacy_recipes: Dictionary = Database.legacy.get("recipes", {})
	var seeded := {}
	for station_id: String in Database.progression.get("mastery", {}).get("stations", []):
		var by_output := {}
		for recipe_id: String in Database.recipes_for(station_id):
			var recipe: Dictionary = Database.recipes[recipe_id]
			if recipe.has("output_collection"):
				continue
			var output := Database.recipe_output(recipe)
			if not by_output.has(output):
				by_output[output] = []
			by_output[output].append(recipe_id)
		var total := 0
		for output: String in by_output:
			var units := progress.stat("produce:" + output)
			var best := 1
			for recipe_id: String in by_output[output]:
				var recipe: Dictionary = Database.recipes[recipe_id]
				best = maxi(best, int(legacy_recipes.get(recipe_id, recipe).get("qty", recipe.get("qty", 1))))
			var jobs := ceili(float(units) / best) if units > 0 else 0
			if by_output[output].size() == 1:
				var key := "station_recipe_jobs:%s:%s" % [station_id, by_output[output][0]]
				if jobs > progress.stat(key):
					progress.stats[key] = jobs
				total += progress.stat(key)
			else:
				total += jobs
		var jobs_key := "station_jobs:" + station_id
		if total > progress.stat(jobs_key):
			progress.stats[jobs_key] = total
		seeded[station_id] = float(progress.stat(jobs_key))  # como o JSON devolve: o estado não muda ao recarregar
	economy.mastery_method = "min_units_v1"
	economy.legacy["mastery"] = {"method": "min_units_v1", "jobs": seeded}


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


## Canteiros da estufa vêm depois dos do sítio (índices a partir de farm.plots) e só valem com a estufa comprada.
func is_greenhouse_plot(index: int) -> bool:
	return index >= int(Database.farm.get("plots", 0)) and index < int(Database.farm.get("plots", 0)) + int(Database.farm.get("greenhouse_plots", 0))


## Canteiros do sítio liberados + os da estufa (quando comprada), na ordem do jogo.
func usable_plot_indices() -> Array[int]:
	var result: Array[int] = []
	for i in accessible_plots():
		result.append(i)
	if has_upgrade("greenhouse"):
		for i in int(Database.farm.get("greenhouse_plots", 0)):
			result.append(int(Database.farm.get("plots", 0)) + i)
	return result


## "locked", "empty", "growing" ou "ready".
func plot_status(index: int) -> String:
	if is_greenhouse_plot(index):
		if not has_upgrade("greenhouse"):
			return "locked"
	elif index < 0 or index >= accessible_plots():
		return "locked"
	var target := plot(index)
	if target["crop"] == "":
		return "empty"
	return "ready" if float(target["ready_at"]) <= now() else "growing"


## Por que não dá para plantar `crop_id` no canteiro ("" = pode). Mesmas checagens, na mesma ordem, de `plant`.
func plant_error(index: int, crop_id: String) -> String:
	if plot_status(index) == "locked":
		return "Compre este terreno primeiro"
	if not Database.crops.has(crop_id):
		return "Semente desconhecida"
	var reason := content_error("crop", crop_id, Database.crops[crop_id])
	if reason != "":
		return reason
	if plot_status(index) != "empty":
		return "Canteiro ocupado"
	return crop_plot_error(index, crop_id)


## Tempo real de crescimento no canteiro (estufa x0,7 aplicado UMA vez, aqui; a rega age depois sobre o que falta).
func crop_seconds(index: int, crop_id: String) -> float:
	var seconds := float(Database.crops.get(crop_id, {}).get("seconds", 60))
	if index >= 0 and is_greenhouse_plot(index):
		seconds *= float(Database.farm.get("greenhouse_speed", 1.0))
	return seconds


## Planta no canteiro. Retorna "" se deu certo ou o motivo da falha.
func plant(index: int, crop_id: String) -> String:
	var reason := plant_error(index, crop_id)
	if reason != "":
		return reason
	var planted_at := now()
	var seconds := crop_seconds(index, crop_id)
	plots[index] = { "crop": crop_id, "planted_at": planted_at, "ready_at": planted_at + seconds, "watered": false, "job": WorkJobs.crop(crop_id, Database.crops, Database.xp) }
	_changed()
	return ""


## Culturas com "greenhouse": "only" (delicadas) só crescem na estufa; "any" cresce nos dois (mais rápido na estufa).
func crop_plot_error(index: int, crop_id: String) -> String:
	var mode := str(Database.crops.get(crop_id, {}).get("greenhouse", ""))
	if mode == "only" and not is_greenhouse_plot(index):
		return "Esta planta só cresce na estufa"
	if is_greenhouse_plot(index) and mode == "":
		return "A estufa é para plantas delicadas"
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
	if album_water_drag:
		album.note("water_drag", now())
		_album_event("watered")
	_add_player_xp(int(Database.farm.water.get("xp", 0)))
	_changed()
	Events.world_activity.emit(&"water", str(target.crop), index)
	return ""


## Contrato da colheita: o que valia quando foi plantada (canteiro sem snapshot usa a tabela viva).
func plot_job(index: int) -> Dictionary:
	var target := plot(index)
	if target.get("job", {}).is_empty():
		return WorkJobs.crop(str(target.crop), Database.crops, Database.xp)
	return target.job


## Por que não dá para colher agora ("" = pode): não está pronto ou o depósito não comporta a colheita.
func harvest_error(index: int) -> String:
	if plot_status(index) != "ready":
		return "Ainda não está pronto"
	var yield_items: Dictionary = plot_job(index).get("yield", {})
	var shortage := storage_shortage(yield_items)
	if shortage.is_empty():
		return ""
	# "Cesto da horta sem espaço: abra lugar para Cenoura ×4": a falta real, não o tamanho do lote.
	var item_id := ""
	for candidate: String in yield_items:
		if storage_of(candidate) == str(shortage.depot):
			item_id = candidate
			break
	return "%s sem espaço: abra lugar para %s ×%d" % [storage_name(str(shortage.depot)), Database.item_name(item_id), int(shortage.missing)]


## Colhe um canteiro pronto. Retorna os itens recebidos (vazio se não estava pronto).
func harvest(index: int) -> Dictionary:
	if plot_status(index) != "ready":
		return {}
	var crop_id: String = plot(index)["crop"]
	var job := plot_job(index)
	var received: Dictionary = job.get("yield", {}).duplicate()
	var full := harvest_error(index)
	if full != "":
		Events.toast_requested.emit(full)
		return {}
	# Semente fixa do plantio: esperar, lotar o silo ou recarregar não refaz o sorteio.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("harvest:%s:%s:%s" % [growth.taste_seed, index, int(float(plot(index).get("planted_at", 0)) * 1000)])
	if tiro_animated() and rng.randf() < float(Database.mood.animated.harvest_chance):
		var extra := received.duplicate()
		var product := str(Database.crops[crop_id].get("item", crop_id))
		if not received.has(product) and not received.is_empty(): product = str(received.keys()[0])
		extra[product] = int(extra.get(product, 0)) + 1
		if storage_error(extra) == "":
			received = extra
			Events.toast_requested.emit("O Tiro ajudou!")
	_count("harvest")
	_count("harvest:" + crop_id)
	_album_event("harvested", {"crop": crop_id})
	_discover("crop:" + crop_id, str(job.get("skill", "agriculture")), int(job.get("skill_xp", 10)))
	coins += int(job.get("coins", 0))
	for item_id: String in received:
		inventory.add(item_id, int(received[item_id]))
	plots[index] = { "crop": "", "ready_at": 0.0 }
	_add_player_xp(int(job.get("player_xp", 0)))
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
	while plots.size() < int(Database.farm.get("plots", 0)) + int(Database.farm.get("greenhouse_plots", 0)):
		plots.append({ "crop": "", "ready_at": 0.0 })


# --- Nível do jogador e atributos ------------------------------------------------

func xp_to_next_level() -> int:
	return int(Database.xp.get("per_level", 100)) * level


func skill_info(id: String) -> Dictionary:
	return progress.skill_info(id)


func _gain_xp(action: String) -> void:
	_add_player_xp(int(Database.xp.get(action, 0)))


## Contador interno preservado para snapshots e ferramentas; não sobe nível nem paga presentes.
func _add_player_xp(amount: int) -> void:
	xp += amount

func level_reward(target_level: int) -> Dictionary:
	var table: Dictionary = Database.progression.get("level_rewards", {})
	if table.has(str(target_level)):
		return table[str(target_level)].duplicate(true)
	var fallback: Dictionary = table.get("default", {})
	var amount := int(fallback.get("coins_base", 0)) + int(fallback.get("coins_per_level", 0)) * target_level
	return {"coins": mini(amount, int(fallback.get("coins_max", amount)))}


func _award_skill(id: String, amount: int) -> void:
	if not Database.progression.skills.has(id) or amount <= 0:
		return
	progress.skills[id] = int(progress.skills.get(id, 0)) + amount


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
	if rewards.has("needs"):
		dog.apply(rewards.needs, now())


# --- Aquisições (Construir) -------------------------------------------------------

func has_upgrade(id: String) -> bool:
	return progress.has_upgrade(Database.station_upgrade(id))


## Só entra na Coleção o que já dá para vestir (tem arte de sobreposição no Tiro).
func has_overlay(id: String) -> bool:
	var path := str(Database.collections.get(id, {}).get("overlay", ""))
	return path != "" and ResourceLoader.exists(path)


func equip_error(id: String) -> String:
	if not Database.collections.has(id) or not progress.collection.has(id):
		return "Você ainda não tem esse apetrecho"
	var path := str(Database.collections[id].get("overlay", ""))
	if path == "" or not ResourceLoader.exists(path):
		return "Em breve no Tiro"
	if not progress.equipped.has(str(Database.collections[id].get("slot", ""))):
		return "Lugar de roupa desconhecido"
	return ""


func equip(id: String) -> String:
	var error := equip_error(id)
	if error != "":
		return error
	var slot := str(Database.collections[id].slot)
	if progress.equipped[slot] == id:
		return ""
	progress.equipped[slot] = id
	_count("equip")
	_album_event("equipped", {"item": id})
	_changed()
	return ""


func unequip_error(slot: String) -> String:
	return "" if progress.equipped.has(slot) else "Lugar de roupa desconhecido"


func unequip(slot: String) -> String:
	var error := unequip_error(slot)
	if error != "":
		return error
	progress.equipped[slot] = ""
	_changed()
	return ""


func buy_cosmetic_error(id: String) -> String:
	var data: Dictionary = Database.collections.get(id, {})
	if data.get("shop", "") != "petshop":
		return "Apetrecho não está à venda"
	if not has_upgrade("petshop"):
		return "Monte o pet shop"
	if progress.collection.has(id):
		return "Você já tem"
	return "Faltam moedas" if coins < int(data.get("price", 0)) else ""


func buy_cosmetic(id: String) -> String:
	var error := buy_cosmetic_error(id)
	if error != "":
		return error
	coins -= int(Database.collections[id].price)
	progress.collection[id] = true
	_count("buy_cosmetic")
	_changed()
	return ""


func buy_shop_item_error(id: String) -> String:
	var data: Dictionary = Database.progression.get("shop_items", {}).get(id, {})
	if data.is_empty():
		return "Produto desconhecido"
	if not has_upgrade(str(data.get("shop", ""))):
		return "Monte o pet shop"
	if coins < int(data.price):
		return "Faltam moedas"
	return storage_error(data.get("items", {}))


func buy_shop_item(id: String) -> String:
	var error := buy_shop_item_error(id)
	if error != "":
		return error
	var data: Dictionary = Database.progression.shop_items[id]
	coins -= int(data.price)
	for item: String in data.items:
		inventory.add(item, int(data.items[item]))
	_changed()
	return ""


# --- Armazenamento ----------------------------------------------------------------
# Cada item mora num depósito (items.json "storage" ou a categoria em progression.json → storage).
# O limite só vale depois de construir o depósito, ou desde já quando o depósito tem
# `prebuild_capacity` no JSON (a etapa de cada depósito liga o campo; sem ele vale a regra antiga).
# Capacidade = max(curva do estágio, piso legado COMPRADO). Excesso de estoque nunca some: só bloqueia
# novas entradas; consumir, vender e entregar continuam funcionando.
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


## O depósito tem limite agora? Construído ou com capacidade provisória (`prebuild_capacity`).
func storage_active(id: String) -> bool:
	if unlimited_storage:
		return false
	var data: Dictionary = Database.progression.storage.get(id, {})
	if data.is_empty():
		return false
	return data.has("prebuild_capacity") or has_upgrade(str(data.building))


## Capacidade provisória antes do prédio (0 = o depósito ainda não tem limite provisório).
func storage_prebuild(id: String) -> int:
	return int(Database.progression.storage.get(id, {}).get("prebuild_capacity", 0))


## Curva do estágio atual: base e ampliações compradas (ou a capacidade provisória sem o prédio).
func storage_curve(id: String) -> int:
	var data: Dictionary = Database.progression.storage.get(id, {})
	if not has_upgrade(str(data.get("building", ""))):
		return storage_prebuild(id)
	var total := int(data.get("base", 0))
	for upgrade_id: String in data.get("levels", []):
		if has_upgrade(upgrade_id):
			total += int(Database.progression.upgrades[upgrade_id].get("storage_capacity", 0))
	return total


## Piso legado: o que o save já tinha COMPRADO pela tabela congelada (nunca o estoque). Só sobe.
## Vem SÓ do que a migração gravou em `economy.storage_floor` (e do que foi comprado antes de a etapa
## do depósito trocar a curva): comprar agora, num jogo novo, vale a curva R1 (silo 32, não 40).
func storage_floor(id: String) -> int:
	return economy.floor_of(id)


## Nome do depósito para o jogador: "Cesto da horta" até o prédio existir (`prebuild_name`).
func storage_name(id: String) -> String:
	var data: Dictionary = Database.progression.storage.get(id, {})
	if not has_upgrade(str(data.get("building", ""))) and data.has("prebuild_name"):
		return str(data.prebuild_name)
	return str(data.get("name", id))


func storage_capacity(id: String) -> int:
	if not Database.progression.storage.has(id):
		return 0
	return maxi(storage_curve(id), storage_floor(id))


func storage_used(id: String) -> int:
	var total := 0
	for item_id: String in inventory.counts:
		if storage_of(item_id) == id:
			total += inventory.count(item_id)
	return total


func storage_space(id: String) -> int:
	return maxi(0, storage_capacity(id) - storage_used(id))


## Quantas unidades passam do limite (excesso legado ou de uma curva nova menor).
func storage_excess(id: String) -> int:
	return maxi(0, storage_used(id) - storage_capacity(id))


## Quanto o depósito passa a caber com esta compra ({} se a melhoria não mexe em depósito): "16 → 32".
func storage_upgrade_preview(upgrade_id: String) -> Dictionary:
	for depot: String in Database.progression.storage:
		var data: Dictionary = Database.progression.storage[depot]
		if upgrade_id != str(data.get("building", "")) and not upgrade_id in data.get("levels", []):
			continue
		var total := int(data.get("base", 0))
		for level_id: String in data.get("levels", []):
			if level_id == upgrade_id or has_upgrade(level_id):
				total += int(Database.progression.upgrades[level_id].get("storage_capacity", 0))
		return {"depot": depot, "from": storage_capacity(depot), "to": maxi(total, storage_floor(depot))}
	return {}


## Ampliações (`_2` em diante) já compradas, de qualquer depósito; o edifício inicial não conta.
## Derivado da posse (saves antigos entram sozinhos; comprar conta uma vez, abrir painel nunca).
func storage_upgrades_owned() -> int:
	var total := 0
	for depot: String in Database.progression.storage:
		for upgrade_id: String in Database.progression.storage[depot].get("levels", []):
			if has_upgrade(upgrade_id):
				total += 1
	return total


## Próxima ampliação do depósito ("" se já está no máximo).
func storage_next_upgrade(id: String) -> String:
	for upgrade_id: String in Database.progression.storage.get(id, {}).get("levels", []):
		if not has_upgrade(upgrade_id):
			return upgrade_id
	return ""


## VALIDAÇÃO ÚNICA do inventário projetado: depois de tirar `outgoing` e pôr `incoming`, cada depósito
## limitado ainda cabe? Consulta pura (sem RNG, contador, recarga nem efeito). Soma por depósito, e quem só
## consome ou vende nunca é bloqueado, mesmo acima do limite. Devolve {} se cabe ou
## {depot, missing}: `missing` é a falta REAL de espaço (não o tamanho do lote).
func storage_shortage(incoming: Dictionary, outgoing: Dictionary = {}) -> Dictionary:
	var gain := {}
	for item_id: String in incoming:
		var id := storage_of(item_id)
		if id != "" and storage_active(id) and int(incoming[item_id]) > 0:
			gain[id] = int(gain.get(id, 0)) + int(incoming[item_id])
	for id: String in gain:
		var loss := 0
		for item_id: String in outgoing:
			if storage_of(item_id) == id:
				loss += mini(int(outgoing[item_id]), inventory.count(item_id))
		var projected := storage_used(id) - loss + int(gain[id])
		if projected > storage_capacity(id):
			return {"depot": id, "missing": projected - storage_capacity(id)}
	return {}


## Nome do depósito que não comporta a entrada ("" se cabe).
func storage_full(items: Dictionary, outgoing: Dictionary = {}) -> String:
	return str(storage_shortage(items, outgoing).get("depot", ""))


## Texto pronto para toast quando os itens não cabem ("" se cabem).
func storage_error(items: Dictionary, outgoing: Dictionary = {}) -> String:
	var full := storage_full(items, outgoing)
	if full == "":
		return ""
	return "%s sem espaço" % storage_name(full)


## Transação manual: consome `take` e recebe `give` (e/ou gasta `coin_cost`) numa só validação.
## Falta de moeda/ingrediente ou de espaço projetado: nada é aplicado.
func transaction_error(take: Dictionary = {}, give: Dictionary = {}, coin_cost: int = 0) -> String:
	if coins < coin_cost:
		return "Faltam %d moedas" % (coin_cost - coins)
	if not inventory.has_all(take):
		return _missing_text(take, "Faltam itens")
	return storage_error(give, take)


# --- Presentes para guardar (recibos de recompensas automáticas) -------------------------------

## Recompensa AUTOMÁTICA (nível, capítulo, vínculo, cliente, projeto): `auto_id` é a identidade estável
## ("level:8", "chapter:6", "customer:lais:2", "project:park_bench"). Moedas, XP, coleções e
## desbloqueios saem UMA vez; só os itens que não cabem esperam num recibo persistente.
## Devolve {"paid": bool, "items": itens guardados agora, "pending": itens no recibo}.
func _grant_automatic(auto_id: String, rewards: Dictionary) -> Dictionary:
	if economy.granted.has(auto_id):
		return {"paid": false, "items": {}, "pending": {}}
	economy.granted[auto_id] = true
	var stored := {}
	var waiting := {}
	var space := {}
	var wanted: Dictionary = rewards.get("items", {})
	for item_id: String in wanted:
		var amount := int(wanted[item_id])
		var depot := storage_of(item_id)
		var fits := amount
		if depot != "" and storage_active(depot):
			fits = mini(amount, int(space.get(depot, storage_space(depot))))
			space[depot] = int(space.get(depot, storage_space(depot))) - fits
		if fits > 0:
			stored[item_id] = fits
		if amount > fits:
			waiting[item_id] = amount - fits
	var effects := rewards.duplicate(true)
	effects["items"] = stored
	_apply_rewards(effects)
	if not waiting.is_empty():
		economy.pending[auto_id] = {"items": waiting, "label": _receipt_label(auto_id), "source": auto_id.get_slice(":", 0)}
		Events.toast_requested.emit("Presente esperando na Mochila")
	return {"paid": true, "items": stored, "pending": waiting}


func _receipt_label(auto_id: String) -> String:
	var kind := auto_id.get_slice(":", 0)
	var number := int(auto_id.get_slice(":", 1)) if auto_id.get_slice(":", 1).is_valid_int() else 0
	match kind:
		"level":
			return "Nível %d" % number
		"chapter":
			var chapters: Array = Database.progression.get("chapters", [])
			return str(chapters[number - 1].name) if number >= 1 and number <= chapters.size() else "Capítulo %d" % number
		"customer":
			return str(Database.npcs.get(auto_id.get_slice(":", 1), {}).get("name", auto_id.get_slice(":", 1)))
		"project":
			return "Projeto da vila"
	return auto_id.get_slice(":", 1) if ":" in auto_id else auto_id


func pending_reward_count() -> int:
	return economy.pending_count()


func pending_reward_total() -> int:
	return economy.pending_total()


## Por que nada do(s) presente(s) pode ser guardado agora ("" = ao menos uma unidade cabe).
func pending_reward_error(receipt_id: String = "") -> String:
	var plan := _pending_plan(receipt_id)
	if not plan.moved.is_empty():
		return ""
	if plan.blocked == "":
		return "Nenhum presente para guardar"
	return pending_blocked_text(plan)


## "Armazém sem espaço: abra lugar para Tábua ×3" (a falta real do primeiro item que não coube).
func pending_blocked_text(plan: Dictionary) -> String:
	return "%s sem espaço: abra lugar para %s ×%d" % [storage_name(str(plan.blocked)),Database.item_name(str(plan.item)), int(plan.missing)]


## Aviso do que ainda não cabe ("" = tudo cabe ou nada pendente). Usado pela Mochila.
func pending_reward_hint(receipt_id: String = "") -> String:
	var plan := _pending_plan(receipt_id)
	return pending_blocked_text(plan) if plan.blocked != "" else ""


## Quanto de cada recibo cabe agora (sem alterar nada): {moved: {id: {item: qtd}}, blocked: depósito,
## item e missing: o primeiro item que não coube e quantas unidades faltam de espaço}.
func _pending_plan(receipt_id: String) -> Dictionary:
	var moved := {}
	var blocked := ""
	var blocked_item := ""
	var missing := 0
	var space := {}
	for id: String in economy.pending:
		if receipt_id != "" and id != receipt_id:
			continue
		for item_id: String in economy.pending[id].items:
			var amount := int(economy.pending[id].items[item_id])
			var depot := storage_of(item_id)
			var fits := amount
			if depot != "" and storage_active(depot):
				fits = mini(amount, int(space.get(depot, storage_space(depot))))
				space[depot] = int(space.get(depot, storage_space(depot))) - fits
			if fits > 0:
				if not moved.has(id):
					moved[id] = {}
				moved[id][item_id] = fits
			if fits < amount and blocked == "":
				blocked = depot
				blocked_item = item_id
				missing = amount - fits + storage_excess(depot)
	return {"moved": moved, "blocked": blocked, "item": blocked_item, "missing": missing}


## Guarda na Mochila o que cabe de cada presente (todos, ou só `receipt_id`). O restante continua no
## recibo, sem perda nem pagamento repetido. Devolve {item: qtd} guardados ({} se nada coube).
func claim_pending_rewards(receipt_id: String = "") -> Dictionary:
	if pending_reward_error(receipt_id) != "":
		return {}
	var plan := _pending_plan(receipt_id)
	var total := {}
	for id: String in plan.moved:
		for item_id: String in plan.moved[id]:
			var amount := int(plan.moved[id][item_id])
			inventory.add(item_id, amount)
			total[item_id] = int(total.get(item_id, 0)) + amount
			var left := int(economy.pending[id].items[item_id]) - amount
			if left > 0:
				economy.pending[id].items[item_id] = left
			else:
				economy.pending[id].items.erase(item_id)
		if economy.pending[id].items.is_empty():
			economy.pending.erase(id)
	_changed()
	Events.items_gained.emit(total, 0, Vector2(-1, -1))
	return total


## Requisitos que dependem de fora do ProgressionState (afeto do Tiro e hora local) são checados
## aqui; os demais vão para o `progress`. Todo conteúdo passa por este embrulho (content_error também).
func requirement_error(requirements: Dictionary) -> String:
	if requirements.has("album_photo") and not album.has_photo(str(requirements.album_photo)):
		return "No Dia do Tiro"
	if requirements.has("growth"):
		var target := growth.phase_index(str(requirements.growth))
		if target < 0:
			return "Fase desconhecida"
		if growth.phase_index() < target:
			return "Quando ele for " + str(Database.growth.phases[target].name)
	for house_id: String in requirements.get("house", []):
		if not house_has(house_id):
			return "Ainda não chegou: " + house_item_name(house_id)
	var reason := progress.requirement_error(requirements)
	if reason != "":
		return reason
	for project_id: String in requirements.get("projects", []):
		if not Database.projects.get("projects", {}).has(project_id):
			return "Projeto desconhecido"
		if not projects.is_completed(project_id):
			return "Depois de: " + str(Database.project(project_id).get("name", project_id))
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
		return "Busque em %s até o nível %d" % [Database.progression.nature_sites[unlock.site].name, int(unlock.level)]
	var reason := requirement_error(data.get("requirements", {}))
	if reason != "":
		return reason
	if coins < int(data.get("cost", 0)):
		return "Faltam %d moedas" % (int(data.cost) - coins)
	if not inventory.has_all(data.get("materials", {})):
		return _missing_text(data.get("materials", {}), "Faltam materiais")
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

func sell(item_id: String, amount: int = 1, world_id: String = "") -> String:
	if world_id not in ["", "farm", "village"]:
		return "Lugar de venda desconhecido"
	if world_id != "":
		var reason := requirement_error(Database.worlds[world_id].get("requirements", {}))
		if reason != "": return reason
	var price := int(Database.items.get(item_id, {}).get("sell_price", 0))
	if amount <= 0 or price <= 0:
		return "Venda inválida"
	if not inventory.remove(item_id, amount):
		return "Você não tem essa quantidade"
	coins += price * amount
	_count("trade")
	_count("sold", amount)
	if world_id != "": _count("sold:" + world_id, amount)
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
		return _missing_text(order.inputs, "Faltam produtos")
	return storage_error(order.get("rewards", {}).get("items", {}), order.inputs)


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
	if str(order.get("channel", "neighbors")) == "contracts":
		_count("contracts")
	_apply_rewards(order.rewards)
	_pay_customer_tiers(str(order.get("customer", "")))
	_album_event("customer_delivery")
	_changed()
	return ""


## Patamares de confiança do cliente ainda não pagos (id estável `customer:<npc>:<n>`, recibo se não couber).
## Histórico antigo só ganha o que nunca recebeu; avisa o mais alto alcançado agora.
func _pay_customer_tiers(customer: String) -> void:
	if customer == "":
		return
	var tiers: Array = Database.progression.get("customer_tiers", [])
	var reached := progress.customer_level(customer)
	var newest := 0
	for index in reached:
		var auto_id := "customer:%s:%d" % [customer, index + 1]
		if economy.granted.has(auto_id):
			continue
		_grant_automatic(auto_id, tiers[index].rewards)
		newest = index + 1
	if newest > 0:
		Events.toast_requested.emit("%s: %s" % [str(Database.npcs.get(customer, {}).get("name", customer)), str(tiers[newest - 1].name)])


# --- Rotas (passeios e mineração) --------------------------------------------------

func activity_error(id: String) -> String:
	if not progress.activity.is_empty():
		return "Termine o que está fazendo"
	var data: Dictionary = Database.progression.activities.get(id, {})
	if data.is_empty():
		return "Rota desconhecida"
	return requirement_error(data.get("requirements", {}))


func start_activity(id: String) -> String:
	var reason := activity_error(id)
	if reason != "":
		return reason
	var start := now()
	var job := WorkJobs.route(id, Database.progression.activities)
	progress.activity = {"id": id, "started_at": start, "ready_at": start + float(Database.progression.activities[id].seconds), "rewards": job.rewards, "player_xp": job.player_xp, "nature_xp": route_nature_xp(id)}
	_changed()
	return ""


## Segundos até a rota em andamento terminar (0 = pronta ou nenhuma).
func activity_remaining() -> int:
	if progress.activity.is_empty():
		return 0
	return maxi(0, int(ceil(float(progress.activity.ready_at) - now())))


func collect_activity_error() -> String:
	if progress.activity.is_empty():
		return "Nada em andamento"
	if activity_remaining() > 0:
		return "Ainda não terminou"
	var data: Dictionary = Database.progression.activities.get(str(progress.activity.id), {})
	if data.is_empty():
		return ""  # rota removida: collect_activity encerra sem prêmio
	return storage_error(progress.activity.get("rewards", data.rewards).get("items", {}))


func collect_activity() -> String:
	var error := collect_activity_error()
	if error != "":
		return error
	var id: String = progress.activity.id
	var data: Dictionary = Database.progression.activities.get(id, {})
	var job: Dictionary = progress.activity
	progress.activity = {}
	if data.is_empty():
		_changed()
		return "Rota indisponível"
	_count("activity:" + id)
	_count("explore")
	_apply_rewards(job.get("rewards", data.rewards))
	var site := Database.gathering_site(id)
	_award_nature_xp(site, int(job.get("nature_xp", Database.progression.nature_sites[site].xp_per_collection)) if site != "" else 0)
	_add_player_xp(int(job.get("player_xp", data.get("player_xp", 5))))
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
	progress.sync_nature_tokens(site)


## XP local que a rota dá ao local (fixado ao começar). Rota sem local (pomar) não dá nada;
## rota sem "nature_xp" usa o valor antigo do local (compatibilidade).
func route_nature_xp(route_id: String) -> int:
	var site := Database.gathering_site(route_id)
	if site == "":
		return 0
	var data: Dictionary = Database.progression.activities.get(route_id, {})
	return int(data.get("nature_xp", Database.progression.nature_sites[site].xp_per_collection))


## Rota padrão de um material: a elegível mais curta (ou, se nenhuma vale ainda, a mais curta do material).
func default_gathering_route(resource: String) -> String:
	var routes: Array = Database.progression.get("nature_resources", {}).get(resource, {}).get("routes", [])
	var best := ""
	var best_open := ""
	for id: String in routes:
		var seconds := int(Database.progression.activities[id].seconds)
		if best == "" or seconds < int(Database.progression.activities[best].seconds):
			best = id
		if requirement_error(Database.progression.activities[id].get("requirements", {})) == "" and (best_open == "" or seconds < int(Database.progression.activities[best_open].seconds)):
			best_open = id
	return best_open if best_open != "" else best


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


## `route_id` vazio = rota padrão do material (a elegível mais curta); chamadas antigas continuam valendo.
func gathering_error(site: String, index: int, route_id: String = "", resource: String = "") -> String:
	if route_id == "":
		route_id = default_gathering_route(resource)
	if not Database.progression.activities.has(route_id) or not Database.progression.nature_sites.has(site) or Database.gathering_site(route_id) != site:
		return "Este material não é deste local"
	if index < 0 or index >= gathering_slots(site):
		return "Libere este espaço primeiro"
	if not gathering_entry(site, index).is_empty():
		return "Espaço ocupado"
	if resource != "" and (not resource in Database.progression.nature_sites[site].resources or not Database.progression.activities[route_id].rewards.get("items", {}).has(resource)):
		return "Este material não vem desta busca"
	var reason := requirement_error(Database.worlds.nature.get("requirements", {}))
	return reason if reason != "" else requirement_error(Database.progression.activities[route_id].get("requirements", {}))


func start_gathering(site: String, index: int, route_id: String = "", resource: String = "") -> String:
	var error := gathering_error(site, index, route_id, resource)
	if error != "":
		return error
	if route_id == "":
		route_id = default_gathering_route(resource)
	var data: Dictionary = Database.progression.activities[route_id]
	var jobs: Array = progress.gathering.get(site, []).duplicate(true)
	while jobs.size() <= index:
		jobs.append({})
	var start := now()
	jobs[index] = {"id": route_id, "resource": resource, "started_at": start, "ready_at": start + float(data.seconds), "rewards": data.rewards.duplicate(true), "player_xp": int(data.get("player_xp", 5)), "nature_xp": route_nature_xp(route_id)}
	progress.gathering[site] = jobs
	_changed()
	return ""


## Um toque no material preenche só a primeira vaga livre, sem escolher o espaço.
func next_gathering_error(site: String, route_id: String = "", resource: String = "") -> String:
	if not Database.progression.nature_sites.has(site):
		return "Local de busca inválido"
	if progress.nature_level(site) == 0:
		return "Desbloqueie %s primeiro" % Database.progression.nature_sites[site].name
	for index in gathering_slots(site):
		if gathering_entry(site, index).is_empty():
			return gathering_error(site, index, route_id, resource)
	return "Todos os espaços estão ocupados"


func start_next_gathering(site: String, route_id: String = "", resource: String = "") -> String:
	var error := next_gathering_error(site, route_id, resource)
	if error != "":
		return error
	for index in gathering_slots(site):
		if gathering_entry(site, index).is_empty():
			return start_gathering(site, index, route_id, resource)
	return "Todos os espaços estão ocupados"


func start_gathering_all(site: String, route_id: String = "", resource: String = "") -> String:
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
		return "Nada pronto ainda"
	if gathering_remaining(site, index) > 0:
		return "Ainda não terminou"
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
	return "" if done else (blocked if blocked != "" else "Nada pronto ainda")

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
		"project":
			return 1 if projects.is_completed(str(goal.key)) else 0
		"growth":
			# Cumprido quando o Tiro já está nessa fase ou além (inclusive se cresceu antes da missão).
			var target := growth.phase_index(str(goal.key))
			return 1 if target >= 0 and growth.phase_index() >= target else 0
		"stat":
			# "fresh": conta só o que foi feito depois que o passo da linha começou.
			if goal.get("fresh", false):
				return maxi(0, progress.stat(goal.key) - int(_step_base(goal).get(goal.key, progress.stat(goal.key))))
			# Objetivos históricos podem aceitar outras rotas equivalentes já registradas no save.
			var total := progress.stat(goal.key)
			for key: String in goal.get("also_counts", []):
				total += progress.stat(key)
			return total
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
	if Database.npcs.has(npc_id) and not Database.npcs[npc_id].get("decor", false):
		_moment_source("talk", npc_id)
	# Passos atuais deste personagem deixam de ser "novos" (balão "!" no mapa).
	for id: String in progress.active_steps().values():
		if Database.quests[id].get("npc", "") == npc_id:
			progress.seen["quest:" + id] = true
	_changed()


## Tela aberta pelo jogador (objetivo "Abrir a Mochila" = "open:bag").
func note_screen_opened(screen: String) -> void:
	if screen == "pet": album_world = "house"
	var key := "open:" + screen
	if progress.stat(key) > 0:
		return
	_count(key)
	_changed()


## Objetivos e entregas separados do espaço para receber o prêmio.
func quest_objectives_error(id: String) -> String:
	if not quest_unlocked(id):
		return "Termine as missões anteriores"
	if progress.claimed_quests.has(id):
		return "Prêmio já pego"
	for goal: Dictionary in Database.quests[id].goals:
		if goal_value(goal) < int(goal.get("target", 1)):
			return "Falta cumprir os objetivos"
	if not inventory.has_all(_quest_deliveries(id)):
		return _missing_text(_quest_deliveries(id), "Faltam itens")
	return ""


func quest_reward_shortage(id: String) -> Dictionary:
	if quest_objectives_error(id) != "":
		return {}
	return storage_shortage(Database.quests[id].get("rewards", {}).get("items", {}), _quest_deliveries(id))


func quest_error(id: String) -> String:
	var reason := quest_objectives_error(id)
	if reason != "":
		return reason
	# Entrega e prêmio juntos: o espaço é o que sobra DEPOIS de entregar os ingredientes.
	return storage_error(Database.quests[id].get("rewards", {}).get("items", {}), _quest_deliveries(id))


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


func _finish_quest(id: String, grant_reward: bool = true) -> void:
	var chapter := progress.chapter_index()
	progress.claimed_quests[id] = true
	if grant_reward and not Database.quests[id].has("shared_with"):
		_apply_rewards(Database.quests[id].rewards)
		_count("quests")
		_add_player_xp(int(Database.quests[id].get("player_xp", 15)))
		Events.quest_completed.emit(id)
	_album_event("quest_claimed", {"quest": id})
	if Database.quests[id].get("kind", "side") == "main" and progress.chapter_index() > chapter:
		_album_event("chapter_done", {"chapter": chapter, "chapter_last": chapter >= Database.progression.chapters.size()})
		var chapter_paid := _grant_automatic("chapter:%d" % chapter, Database.progression.chapters[chapter - 1].get("rewards", {}))
		if chapter_paid.paid:
			Events.chapter_completed.emit(chapter)


# --- Novidades (revelar aos poucos) ---------------------------------------------------

## O que a história acabou de revelar e o jogador ainda não viu (chaves de ProgressionState.unlocked_keys).
func _visible_unlock_keys() -> Array[String]:
	var keys := progress.unlocked_keys() + walk_unlock_keys()
	if PersonalityRules.id(growth) != "": keys.append("personality:revealed")
	return keys


func new_unlocks() -> Array[String]:
	var result: Array[String] = []
	for key in _visible_unlock_keys():
		if not progress.seen.has(key):
			result.append(key)
	return result


## Conta apenas as duas apresentações de etiquetas, sem tocar nas regras de progressão.
func note_label_visit(world_id: String) -> bool:
	var key := "ui:labels:" + world_id
	var visits := int(progress.seen.get(key, 0))
	if visits >= 2: return false
	progress.seen[key] = visits + 1
	_changed()
	return true


func mark_seen(keys: Array[String]) -> void:
	for key in keys:
		progress.seen[key] = true
	if "intro" in keys:
		_album_event("intro_done")
	_changed()


func _mark_all_seen() -> void:
	for key in _visible_unlock_keys():
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


## Modelo da rotina do catálogo atual (saves zerados).
func routine_data(kind: String, id: String) -> Dictionary:
	return Database.routines.get(kind, {}).get("missions", {}).get(id, {})


## Fase da jornada para as faixas de meta: começo (até o capítulo 4), meio (5–9), comunidade (10+).
func routine_phase() -> String:
	var chapter := progress.chapter_index()
	return "start" if chapter <= 4 else ("middle" if chapter <= 9 else "community")


## Meta da rotina: a quantidade congelada na geração (fase) ou, em sorteio antigo, a do modelo.
func routine_target(kind: String, id: String) -> int:
	var frozen: Dictionary = progress.routines.get(kind, {}).get("targets", {})
	if frozen.has(id):
		return int(frozen[id])
	return int(routine_data(kind, id).get("goal", {}).get("target", 1))


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
		return "Prêmio já pego"
	if routine_value(kind, id) < routine_target(kind, id):
		return "Falta cumprir o objetivo"
	return storage_error(routine_data(kind, id).get("rewards", {}).get("items", {}))


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


# --- Desejos do Tiro ----------------------------------------------------------------
# Modelos em data/wishes.json; estado em `wishes` (WishState). Um desejo por período
# (manhã, tarde, noite). Atender dá um momento do pilar do desejo, fora do teto do período.

func wish_settings() -> Dictionary:
	return Database.wishes.get("settings", {})


func wish_def(id: String) -> Dictionary:
	return Database.wishes.get("wishes", {}).get(id, {})


## Os desejos aparecem depois da caminha (Novo! "Desejos").
func wishes_open() -> bool:
	return progress.feature_unlocked("wishes")


## Período em que um desejo novo chega ("" = madrugada).
func _wish_period() -> String:
	var period := moment_period()
	var id := period.get_slice(":", period.get_slice_count(":") - 1)
	return "" if id not in wish_settings().get("periods", []) else period


## Cria o desejo do período, se ainda não houve um. Devolve true se algo mudou (sem emitir `state_changed`).
func update_wishes() -> bool:
	if not wishes_open():
		return false
	var changed := false
	if wishes.has_current() and wish_def(str(wishes.current.id)).is_empty():  # desejo removido do JSON
		wishes.current = {}
		changed = true
	var first := not wishes.first_done and not wish_def(str(wish_settings().get("first", ""))).is_empty()
	var period := moment_period() if first else _wish_period()
	if period == "" or period == wishes.period:
		return changed
	var pick := _pick_wish(period)
	if pick.is_empty():
		return changed
	var def := _resolved_wish(str(pick.id), str(pick.get("item", "")))
	wishes.period = period
	wishes.first_done = true
	wishes.current = {
		"id": str(pick.id), "item": str(pick.get("item", "")), "period": period, "since": now(),
		"progress": progress.stat(str(def.goal.key)) if str(def.type) == "action" else 0,
	}
	Events.wish_changed.emit()
	return true


## Momentos que ainda faltam num pilar para a próxima fase (Corpo: porções da refeição da fase).
func _pillar_missing(pillar: String) -> int:
	if pillar == "body":
		for row: Dictionary in growth_info().requirements:
			if str(row.type) == "feed" and not row.done:
				return int(row.need) - int(row.have)
		return 0
	var data: Dictionary = growth_info().pillars.get(pillar, {})
	return maxi(0, int(data.get("need", 0)) - int(data.get("have", 0)))


## O desejo vale agora? Requisitos, item na mochila (`have_item`) e, para comida, uma fonte alcançável.
func _wish_available(id: String) -> bool:
	var def := wish_def(id)
	if def.is_empty() or requirement_error(def.get("requirements", {})) != "":
		return false
	if def.has("have_item") and inventory.count(str(def.have_item)) < 1:
		return false
	return str(def.get("item", "")) == "meal" or str(def.get("type", "")) != "feed" or wish_item_reachable(def)


## A fase que o Tiro está buscando (a próxima); no fim, a última.
func _wish_phase() -> String:
	var next: Dictionary = growth_info().next
	return str(next.id) if not next.is_empty() else growth.phase


func _wish_in_phase(id: String) -> bool:
	return _wish_phase() in wish_def(id).get("phases", [])


## Escolhe o desejo do período (02 D): o primeiro é carinho; depois, necessidade pedindo, pilar que mais falta, qualquer da fase.
func _pick_wish(period: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = growth.taste_seed + hash(period)
	var ids: Array = Database.wishes.wishes.keys()
	var recent: Array = wishes.last_ids.slice(maxi(0, wishes.last_ids.size() - int(wish_settings().get("keep_last", 2))))
	var first := str(wish_settings().get("first", ""))
	if wishes.done_count == 0 and not wishes.first_done:
		return {"id": first}
	# 1) Necessidade pedindo: a mais baixa; felicidade escolhe o pilar com mais falta.
	var asking := ""
	var lowest := 1000.0
	for need_id: String in CARE_NEEDS:
		var value := dog.get_need(need_id, now())
		if _need_is_low(need_id) and value < lowest:
			asking = need_id
			lowest = value
	if asking != "":
		var best := ""
		var best_missing := -1
		for id: String in ids:
			if str(wish_def(id).get("need", "")) != asking or id in recent or not _wish_available(id):
				continue
			var missing := _pillar_missing(str(wish_def(id).pillar))
			if missing > best_missing:
				best = id
				best_missing = missing
		if best != "":
			return {"id": best, "item": _meal_item() if best == "meal" else ""}
	# 2) O pilar com mais momentos faltando; 3) qualquer desejo da fase.
	var pillars: Array = ["brave", "smart", "coat"]
	pillars.sort_custom(func(a: String, b: String) -> bool: return _pillar_missing(a) > _pillar_missing(b))
	for pass_index in 2:
		for pillar: String in (pillars if pass_index == 0 else [""]):
			if pillar != "" and _pillar_missing(pillar) <= 0:
				continue
			var pool: Array[String] = []
			for id: String in ids:
				if (pillar == "" or str(wish_def(id).pillar) == pillar) and _wish_in_phase(id) and not id in recent and _wish_available(id):
					pool.append(id)
			if not pool.is_empty():
				var chosen := pool[rng.randi() % pool.size()]
				return {"id": chosen, "item": _meal_item() if chosen == "meal" else ""}
	# Só sobrou o que ele pediu há pouco: aceita repetir.
	var again: Array[String] = []
	for id: String in ids:
		if _wish_in_phase(id) and _wish_available(id):
			again.append(id)
	if again.is_empty():
		return {}
	var repeated := again[rng.randi() % again.size()]
	return {"id": repeated, "item": _meal_item() if repeated == "meal" else ""}


## A comida da refeição da fase, se dá para fazê-la; "" = qualquer comida.
func _meal_item() -> String:
	for row: Dictionary in growth_info().requirements:
		if str(row.type) != "feed" or row.done:
			continue
		var item := favorite_food() if str(row.item) == "favorite" and favorite_found() else str(row.item)
		if item not in ["any", "favorite", ""] and wish_item_reachable({"type": "feed", "item": item}):
			return item
	return ""


## O desejo como ele vale agora: a comida da refeição vira "Quero <comida>" ou "Tô com fome".
func _resolved_wish(id: String, item: String) -> Dictionary:
	var def := wish_def(id).duplicate(true)
	if id == "meal":
		if item == "":
			def["type"] = "action"
			def["name"] = "Tô com fome"
			def["goal"] = {"key": "feed", "target": 1}
			def["go"] = "screen:pet"
		else:
			def["item"] = item
			def["name"] = "Quero " + Database.item_name(item).to_lower()
	return def


## O item pedido existe na mochila ou tem uma fonte que já dá para usar agora (planta liberada ou receita com estação e requisitos).
## Itens de passeio/achado dependem só dos requisitos do próprio desejo. Desejos de ação sempre valem.
func wish_item_reachable(def: Dictionary) -> bool:
	if str(def.get("type", "")) == "action":
		return true
	var item := str(def.get("item", ""))
	if inventory.count(item) > 0:
		return true
	var gated := false
	for id: String in Database.crops:
		if Database.crops[id].get("yield", {}).has(item):
			gated = true
			if requirement_error(Database.crops[id].get("requirements", {})) == "":
				return true
	for id: String in Database.recipes:
		var recipe: Dictionary = Database.recipes[id]
		if Database.recipe_output(recipe) != item:
			continue
		gated = true
		var owner := Database.station_upgrade(str(recipe.get("station", "")))
		if (owner == "" or has_upgrade(owner)) and requirement_error(recipe.get("requirements", {})) == "":
			return true
	return not gated


## Desejo de agora, já resolvido (vazio se não há).
func wish_now() -> Dictionary:
	if not wishes_open() or not wishes.has_current():
		return {}
	return _resolved_wish(str(wishes.current.id), str(wishes.current.item))


## Id do desejo de agora ("" = nenhum).
func wish_id() -> String:
	return str(wishes.current.id) if wishes.has_current() and not wish_now().is_empty() else ""


## Pilar que o desejo faz crescer ("brave", "smart", "coat" ou "body").
func wish_pillar() -> String:
	return str(wish_now().get("pillar", ""))


## Quanto já foi feito (ação: contador desde o início; comida/item: quanto tem).
func wish_value() -> int:
	var def := wish_now()
	if def.is_empty():
		return 0
	if def.type == "action":
		return maxi(0, progress.stat(str(def.goal.key)) - int(wishes.current.progress))
	return mini(inventory.count(str(def.item)), 1)


func wish_target() -> int:
	var def := wish_now()
	return int(def.goal.get("target", 1)) if def.get("type", "") == "action" else 1


func wish_error() -> String:
	var def := wish_now()
	if def.is_empty():
		return "Espere"
	if def.type != "action" and walking():
		return "Quando ele voltar"
	if wish_value() >= wish_target():
		return ""
	if def.type == "action":
		return "Faça: " + str(def.name)
	return "Falta " + Database.item_name(str(def.item))


## Atende o desejo: entrega a comida (se for o caso), dá o momento do pilar e espera o próximo período.
func fulfill_wish() -> String:
	var error := wish_error()
	if error != "":
		return error
	var def := wish_now()
	var id := wish_id()
	if str(def.type) == "feed":
		if not feed(str(def.item)):
			return "Ele não quer isso agora"
		_count("wish_item:" + str(def.item))
	_count("wish")
	_count("wish:" + id)
	_gain_moment(str(def.pillar), "wish:" + id, false)
	wishes.done_count += 1
	wishes.last_ids.append(id)
	while wishes.last_ids.size() > 4:
		wishes.last_ids.pop_front()
	wishes.current = {}
	_changed()
	Events.wish_changed.emit()
	Events.dog_action.emit(&"wish")
	return ""


## Quantos desejos dá para atender agora (0 ou 1).
func fulfillable_wish_count() -> int:
	return 1 if not wish_now().is_empty() and wish_error() == "" else 0


## Id do desejo do balão ("" = nenhum).
func balloon_wish() -> String:
	return wish_id()


## O desejo de agora pede exatamente esta comida e dá para atender: "Ele quer!" no seletor de comida.
func wish_wants_item(item_id: String) -> bool:
	var def := wish_now()
	return def.get("type", "") == "feed" and str(def.item) == item_id and wish_error() == ""


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
		return "Já pegou hoje"
	return storage_error(daily_gift_rewards().get("items", {}))


func claim_daily_gift() -> String:
	var reason := daily_gift_error()
	if reason != "":
		return reason
	var rewards := daily_gift_rewards()
	_apply_rewards(rewards)
	progress.daily_gift = {"period": routine_period("daily"), "count": int(progress.daily_gift.count) + 1}
	_changed()
	return ""


## Coletas prontas por mundo, contadas por canteiro/lote/vaga, sem missões nem novidades.
func world_ready_counts() -> Dictionary:
	var counts: Dictionary = {}
	var farm_at := Database.place_with_panel("farm")
	for i: int in usable_plot_indices():
		if plot_status(i) == "ready":
			_add_world_ready(counts, farm_at[0], 1)
	for id: String in Database.stations:
		if has_upgrade(id):
			var at := Database.place_with_panel("station:" + id)
			_add_world_ready(counts, at[0], station(id).ready_count(now()))
	for site: String in Database.progression.get("nature_sites", {}):
		if gathering_slots(site) > 0:
			var at := Database.place_with_panel("routes:" + str(Database.progression.nature_sites[site].groups[0]))
			_add_world_ready(counts, at[0], gathering_ready_count(site))
	if walk_ready():
		_add_world_ready(counts, Database.place_with_panel("walks")[0], 1)
	if not progress.activity.is_empty() and activity_remaining() == 0:
		var route: Dictionary = Database.progression.activities.get(str(progress.activity.get("id", "")), {})
		_add_world_ready(counts, Database.place_with_panel("routes:" + str(route.get("place", "")))[0], 1)
	for id: String in Database.friends.friends:
		if bool(friend_state.entry(id).visit_pending):
			_add_world_ready(counts, "house", 1)
	for world: String in finds.worlds:
		if int(finds.worlds[world].pending) > 0:
			_add_world_ready(counts, world, 1)
	return counts


func _add_world_ready(counts: Dictionary, world: String, count: int) -> void:
	if count <= 0 or not Database.worlds.has(world): return
	if requirement_error(Database.worlds[world].get("requirements", {})) != "": return
	counts[world] = int(counts.get(world, 0)) + count


## Boas-vindas: visitas, passeio, achados agrupados e produções prontas por mundo.
## Todas trazem { kind, count, icon, world, target } (o destino do "Ir").
func welcome_ready_lines(limit: int = 5) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	var info := growth_info()
	if growth.pending_reveal != "" or (info.ready and growth.ready_seen != str(info.next.id)):
		lines.append({"kind": "growth", "count": 1, "world": "", "target": "", "sleeping": growth.pending_reveal != ""})
	var new_photos := photos_unseen()
	if photo_alerts_enabled() and not new_photos.is_empty():
		lines.append({"kind": "photo", "count": new_photos.size(), "world": "", "target": ""})
	for id: String in Database.friends.friends:
		if bool(friend_state.entry(id).visit_pending):
			lines.append({"kind": "friend_visit", "count": 1, "icon": "", "friend": id, "world": "house", "target": "friend_visit:" + id})
	if walk_ready():
		var park_at := Database.place_with_panel("walks")
		lines.append({"kind": "walk", "count": 1, "icon": "", "world": park_at[0], "target": park_at[1]})
	var dig_worlds: Array[String] = []
	for world: String in finds.worlds:
		if int(finds.worlds[world].pending) > 0:
			dig_worlds.append(world)
	if not dig_worlds.is_empty():
		lines.append({"kind": "dig", "count": dig_worlds.size(), "icon": "", "worlds": dig_worlds, "world": dig_worlds[0], "target": "find"})
	var groups: Dictionary = {}  # mundo -> { count, icons, target }
	var farm_at := Database.place_with_panel("farm")
	var ripe := 0
	var crop_item := ""
	for i in plots.size():
		if plot_status(i) == "ready":
			ripe += 1
			if crop_item == "":
				crop_item = str(Database.crops.get(plot(i).crop, {}).get("yield", {}).keys().front())
	if ripe > 0:
		_welcome_group(groups, farm_at[0], farm_at[1], ripe, crop_item)
	for id: String in Database.stations:
		if not has_upgrade(id) or station(id).ready_count(now()) == 0:
			continue
		var at := Database.place_with_panel("station:" + id)
		var output := ""
		for entry: Dictionary in station(id).queue:
			if output == "" and float(entry.ready_at) <= now():
				output = Database.recipe_output(Database.recipes.get(entry.recipe, {}))
		_welcome_group(groups, at[0], at[1], station(id).ready_count(now()), output)
	for site: String in Database.progression.get("nature_sites", {}):
		if gathering_slots(site) > 0 and gathering_ready_count(site) > 0:
			var at := Database.place_with_panel("nature:" + str(Database.progression.nature_sites[site].groups[0]))
			_welcome_group(groups, at[0], at[1], gathering_ready_count(site), "")
	for world: String in groups:
		var group: Dictionary = groups[world]
		lines.append({"kind": "ready", "count": group.count, "icon": group.icons[0] if not group.icons.is_empty() else "", "icons": group.icons, "world": world, "target": group.target})
	return lines.slice(0, limit)


## Soma o que está pronto num mundo (o destino é o primeiro lugar que apareceu; até 3 ícones diferentes).
func _welcome_group(groups: Dictionary, world: String, target: String, count: int, icon: String) -> void:
	if not groups.has(world):
		groups[world] = {"count": 0, "icons": [], "target": target}
	var group: Dictionary = groups[world]
	group.count = int(group.count) + count
	if icon != "" and not icon in group.icons and group.icons.size() < 3:
		group.icons.append(icon)


## O que dá para fazer agora (consulta pura). Cada item: { kind, world, target }; `target` é o
## lugar do mundo (mesmo alvo de Events.world_requested) ou a tela ("pet", "tasks") quando world = "".
func available_actions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in friends_present():
		if give_friend_error(id) == "":
			result.append({"kind": "friend", "world": "park", "target": "friend:" + id})
	for id: String in Database.friends.friends:
		if collect_friend_visit_error(id) == "":
			result.append({"kind": "friend_visit", "world": "house", "target": "friend_visit:" + id})
	var walk_at := Database.place_with_panel("walks")
	if walk_ready():
		result.append({"kind": "walk_ready", "world": walk_at[0], "target": walk_at[1]})
	elif not walking() and Database.walks.get("walks", {}).keys().any(func(id: String) -> bool: return walk_error(id) == ""):
		result.append({"kind": "walk", "world": walk_at[0], "target": walk_at[1]})
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
		result.append({"kind": "wish", "world": "", "target": "pet"})
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
	var targets := {}
	var phase := routine_phase()
	for id in ids:
		var goal: Dictionary = missions[id].goal
		base[str(goal.key)] = progress.stat(str(goal.key))
		targets[id] = int(goal.get("targets", {}).get(phase, goal.get("target", 1)))
	progress.routines[kind] = {"period": period, "ids": ids, "base": base, "targets": targets, "catalog": 2, "claimed": {}}
	# Adiado: pode ser chamado durante a montagem de uma tela.
	_changed.call_deferred()


## Hora do relógio local ("14:35") de um instante Unix, para "pronto às ...".
func clock_text(at: float) -> String:
	var parts := Time.get_datetime_dict_from_unix_time(_local_time(at))
	return "%02d:%02d" % [int(parts.hour), int(parts.minute)]


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


## Cria um presente automático de teste esperando na Mochila (sem moedas): serve para ver a seção
## "Presentes para guardar" e o botão Guardar mesmo com os depósitos vazios.
func dev_add_pending_gift() -> void:
	if not BuildInfo.is_dev():
		return
	var number := 1
	while economy.granted.has("dev:%d" % number):
		number += 1
	var id := "dev:%d" % number
	economy.granted[id] = true
	economy.pending[id] = {"items": {"carrot_snack": 2, "plank": 3}, "label": "Presente de teste", "source": "dev"}
	_changed()


## Passeio que acabou de voltar, com a bagagem esperando (só a versão dev; sorteio normal, sem prêmio extra).
## Libera o mínimo para passear (a Praça e a conversa com a Nina) quando o save ainda não chegou lá.
func dev_walk_return() -> void:
	if not BuildInfo.is_dev():
		return
	return_due_walk()
	if walk_state.active() or walk_ready():
		return
	for quest: String in ["main_2_order", "nina_meet", "nina_walk"]:
		progress.claimed_quests[quest] = true
	dog.set_sleeping(false, now())
	dog.apply({"energy": 100.0}, now())
	if start_walk("park_loop") != "":
		return
	walk_state.current["ready_at"] = now() - 1.0
	return_due_walk()


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


## Sorteia agora o desejo do período (esquece o período do último).
func dev_refresh_wishes() -> void:
	if not BuildInfo.is_dev():
		return
	wishes.period = ""
	wishes.current = {}
	update_wishes()
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
	if walking():
		walk_state.current["ready_at"] = minf(float(walk_state.current.ready_at), t)
	progress.cooldowns.clear()
	_changed()


## Viagem no tempo: tudo acontece como se `seconds` tivessem passado com o jogo fechado
## (necessidades caem, plantas crescem, filas andam).
func dev_advance_time(seconds: float) -> void:
	if not BuildInfo.is_dev():
		return
	# O tempo andou com o jogo fechado: o Tiro vive isso como ausência protegida.
	dog.commit(now())
	dog.updated_at -= seconds
	dog.away_since = dog.updated_at
	dog.end_absence(now())
	for entry: Dictionary in plots:
		if entry["crop"] != "":
			entry["ready_at"] = float(entry["ready_at"]) - seconds
			if entry.has("planted_at"):
				entry["planted_at"] = float(entry["planted_at"]) - seconds
	for id: String in stations:
		for entry: Dictionary in stations[id].queue:
			entry["ready_at"] = float(entry["ready_at"]) - seconds
	progress.shift_time(seconds)
	finds.shift_time(seconds)
	walk_state.shift_time(seconds)
	projects.shift_time(seconds)
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
		elif goal.type == "growth" and growth.phase_index() < growth.phase_index(str(goal.key)):
			dev_set_phase(str(goal.key))
	if not progress.claimed_quests.has(id):
		_finish_quest(id)



# --- Projetos comunitários (etapa 19) ------------------------------------------------------------
# Contrato estável para a interface das etapas 20–22: consultas puras (`project_*`), erros (`*_error`
# devolvem "" se vale) e ações. Taxa só ao começar; material entregue sai do inventário e vira
# contribuição no mesmo passo; a última entrega conclui e premia (uma vez) sem passo intermediário salvo.

## Projeto existe, tem definição coerente e os requisitos valem (a UI só mostra o que passa aqui ou já começou).
func project_available(id: String) -> bool:
	return Database.project_issue(id) == "" and (projects.entry(id).started or requirement_error(Database.project(id).get("requirements", {})) == "")


func project_started(id: String) -> bool:
	return bool(projects.entry(id).started)


func project_completed(id: String) -> bool:
	return projects.is_completed(id)


## Estágio atual (consulta pura): índice, id da fase, material pedido/entregue/restante e progressos 0..1.
## Obra inteira entregue (aguardando ou já concluída) devolve `done` verdadeiro e fase vazia.
func project_stage(id: String) -> Dictionary:
	var def := Database.project(id)
	if def.is_empty():
		return {}
	var phases: Array = def.get("phases", [])
	var entry := projects.entry(id)
	var index := clampi(int(entry.phase_index), 0, phases.size())
	var total := 0
	var delivered := 0
	for position: int in phases.size():
		var items: Dictionary = phases[position].get("items", {})
		for item: String in items:
			total += int(items[item])
			if position <= index:
				delivered += mini(int(items[item]), projects.given(id, str(phases[position].id), item))
	var stage := {"index": index, "count": phases.size(), "phase": "", "needed": {}, "given": {}, "remaining": {}, "progress": 1.0, "done": index >= phases.size(), "total_progress": float(delivered) / float(maxi(1, total))}
	if index >= phases.size():
		return stage
	var phase: Dictionary = phases[index]
	var needed: Dictionary = phase.get("items", {})
	var given := {}
	var remaining := {}
	var needed_total := 0
	var given_total := 0
	for item: String in needed:
		var have := mini(int(needed[item]), projects.given(id, str(phase.id), item))
		given[item] = have
		remaining[item] = int(needed[item]) - have
		needed_total += int(needed[item])
		given_total += have
	stage["phase"] = str(phase.id)
	stage["needed"] = needed
	stage["given"] = given
	stage["remaining"] = remaining
	stage["progress"] = float(given_total) / float(maxi(1, needed_total))
	return stage


## Desenho da obra no mapa (consulta pura): "" = ainda não existe para o jogador; "ghost" = marcação do
## lugar (nada entregue); senão o `visual_state` da última fase já entregue (obra concluída = o da última).
func project_visual(id: String) -> String:
	if not project_available(id):
		return ""
	var phases: Array = Database.project(id).get("phases", [])
	var done := phases.size() if projects.is_completed(id) else clampi(int(projects.entry(id).phase_index), 0, phases.size())
	if done <= 0:
		return "ghost"
	return str(phases[done - 1].get("visual_state", "ghost"))


## Todas as fases entregues e a conclusão/prêmio ainda por registrar (só acontece numa interrupção: recuperável).
func project_ready(id: String) -> bool:
	var entry := projects.entry(id)
	return bool(entry.started) and bool(project_stage(id).get("done", false)) and not (bool(entry.completed) and bool(entry.completion_rewarded))


func project_error(id: String) -> String:
	if Database.project(id).is_empty():
		return "Projeto desconhecido"
	if Database.project_issue(id) != "":
		return "Obra indisponível"
	var entry := projects.entry(id)
	if bool(entry.completed):
		return "Obra concluída"
	if bool(entry.started):
		return "A obra já começou"
	var reason := requirement_error(Database.project(id).get("requirements", {}))
	if reason != "":
		return reason
	var fee := int(Database.project(id).get("start_coins", 0))
	if coins < fee:
		return "Faltam %d moedas" % (fee - coins)
	return ""


## Começa a obra: valida requisitos e moedas e cobra a taxa numa só passada. Sem taxa por fase.
func start_project(id: String) -> String:
	var error := project_error(id)
	if error != "":
		return error
	coins -= int(Database.project(id).get("start_coins", 0))
	var entry := projects.entry(id)
	entry["started"] = true
	entry["paid_start"] = true
	projects.projects[id] = entry
	_count("project_start")
	_changed()
	return ""


## Quantidade inteira positiva (decimal só se for inteiro, ex. 2.0 vindo de JSON); senão 0.
func _whole_quantity(qty: Variant) -> int:
	if typeof(qty) == TYPE_INT:
		return maxi(0, int(qty))
	if typeof(qty) == TYPE_FLOAT and is_finite(float(qty)) and float(qty) == floorf(float(qty)):
		return maxi(0, int(qty))
	return 0


func project_contribution_error(id: String, item: String, qty: Variant) -> String:
	if Database.project(id).is_empty():
		return "Projeto desconhecido"
	if Database.project_issue(id) != "":
		return "Obra indisponível"
	var entry := projects.entry(id)
	if not bool(entry.started):
		return "Comece a obra primeiro"
	var stage := project_stage(id)
	if bool(entry.completed) or bool(stage.done):
		return "Obra concluída"
	var amount := _whole_quantity(qty)
	if amount <= 0:
		return "Escolha uma quantidade"
	var missing := int(stage.remaining.get(item, 0))
	if missing <= 0:
		return "Esta fase não precisa de " + Database.item_name(item)
	if amount > missing:
		return "Só faltam %d" % missing
	if inventory.count(item) < amount:
		return "Falta %s ×%d" % [Database.item_name(item), amount - inventory.count(item)]
	return ""


## Entrega `qty` de `item` à fase atual. Erro não consome nem avança. Fase completa avança uma vez; a última
## conclui e premia no mesmo passo (recibo se o prêmio não couber; nunca bloqueia a obra).
func contribute_project(id: String, item: String, qty: Variant) -> String:
	var error := project_contribution_error(id, item, qty)
	if error != "":
		return error
	var amount := _whole_quantity(qty)
	var phase_id := str(project_stage(id).phase)
	inventory.remove(item, amount)
	var entry := projects.entry(id)
	var contributions: Dictionary = entry.contributions
	var phase_given: Dictionary = contributions.get(phase_id, {})
	phase_given[item] = int(phase_given.get(item, 0)) + amount
	contributions[phase_id] = phase_given
	entry["contributions"] = contributions
	projects.projects[id] = entry
	_count("project_contribution", amount)
	var events := _advance_project(id)
	_changed()
	_emit_project_events(events)
	return ""


## Avança as fases cheias e conclui a obra se acabou. Devolve os eventos a emitir DEPOIS de salvar.
func _advance_project(id: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var phases: Array = Database.project(id).get("phases", [])
	var entry := projects.entry(id)
	var index := clampi(int(entry.phase_index), 0, phases.size())
	while index < phases.size():
		var phase: Dictionary = phases[index]
		var complete := true
		for item: String in phase.get("items", {}):
			if projects.given(id, str(phase.id), item) < int(phase.items[item]):
				complete = false
		if not complete:
			break
		events.append({"kind": "phase", "id": id, "phase": str(phase.id), "index": index})
		index += 1
	entry["phase_index"] = index
	projects.projects[id] = entry
	if index >= phases.size() and bool(entry.started):
		var finished := _finish_project(id)
		if not finished.is_empty():
			events.append({"kind": "completed", "id": id, "result": finished})
	return events


func _emit_project_events(events: Array[Dictionary]) -> void:
	for event: Dictionary in events:
		if event.kind == "phase":
			Events.project_phase_completed.emit(event.id, event.phase, event.index)
		else:
			Events.project_completed.emit(event.id, event.result)


## Conclusão + prêmio idempotentes: `completed`/`completion_rewarded` e o id `project:<id>` em
## `economy.granted` impedem pagar duas vezes. Devolve {} se já estava tudo registrado.
func _finish_project(id: String) -> Dictionary:
	var entry := projects.entry(id)
	if bool(entry.completed) and bool(entry.completion_rewarded):
		return {}
	var first := not bool(entry.completed)
	var rewards: Dictionary = Database.project(id).get("rewards", {})
	var paid := _grant_automatic("project:" + id, rewards)
	if bool(paid.paid) and int(rewards.get("xp", 0)) > 0:
		_add_player_xp(int(rewards.xp))
	entry = projects.entry(id)
	entry["completed"] = true
	entry["completion_rewarded"] = true
	if first:
		entry["completed_at"] = now()
	projects.projects[id] = entry
	if first:
		_moment_source("project", id)
		_count("projects")
	return paid


## Conclui uma obra cujas fases já estão todas entregues (interrupção). Idempotente: "" se já concluída.
func complete_project(id: String) -> String:
	if Database.project(id).is_empty():
		return "Projeto desconhecido"
	if not project_ready(id):
		return "" if projects.is_completed(id) else "A obra ainda não está pronta"
	var events := _advance_project(id)
	_changed()
	_emit_project_events(events)
	return ""


## Repara obras interrompidas entre a última entrega e o registro do prêmio (e fases cheias sem avanço).
## Roda ao carregar e no tick de 1 s; devolve se mudou algo. Projeto fora do catálogo é preservado intacto.
func _recover_projects() -> bool:
	var changed := false
	var events: Array[Dictionary] = []
	for id: String in projects.projects.keys():
		if Database.project_issue(id) != "" or not bool(projects.entry(id).started):
			continue
		var before: Dictionary = projects.entry(id).duplicate(true)
		events.append_array(_advance_project(id))
		if projects.entry(id) != before:
			changed = true
	_emit_project_events(events)
	return changed


func project_use_error(id: String) -> String:
	if Database.project(id).is_empty():
		return "Projeto desconhecido"
	if not projects.is_completed(id):
		return "A obra ainda não terminou"
	if walking():
		return away_text()
	if dog.sleeping:
		return "Tiro está dormindo"
	return ""


## Usar a obra pronta. Primeira vez: `used_once` + contador `project_use:<id>`; repetir só repete o visual
## (sem moedas, XP, afeto nem necessidades). A UI chama quando a reação do Tiro realmente começa.
func use_project(id: String) -> String:
	var error := project_use_error(id)
	if error != "":
		return error
	var entry := projects.entry(id)
	var first := not bool(entry.used_once)
	if first:
		entry["used_once"] = true
		projects.projects[id] = entry
		_count("project_use:" + id)
		_changed()
	_album_event("project_used", {"world": str(Database.project(id).get("world", album_world)), "object": id})
	_changed()
	Events.project_used.emit(id, first)
	return ""

## Encontro repetível depois da obra (`gathering` no projeto): intervalo mínimo desde a última conclusão,
## material da definição e XP pequeno. Sem afeto, moedas nem material de ampliação.
func meeting_def(id: String) -> Dictionary:
	return Database.project(id).get("gathering", {})


## Quando o encontro pode acontecer (Unix); 0 = a qualquer momento.
func meeting_ready_at(id: String) -> float:
	var def := meeting_def(id)
	if def.is_empty() or not projects.is_completed(id):
		return 0.0
	return projects.last_done_at(id) + float(def.get("hours", 24)) * 3600.0


func meeting_error(id: String) -> String:
	var def := meeting_def(id)
	if def.is_empty():
		return "Esta obra não tem encontro"
	if Database.project_issue(id) != "":
		return "Obra indisponível"
	if not projects.is_completed(id):
		return "A obra ainda não terminou"
	if walking():
		return away_text()
	if dog.sleeping:
		return "Tiro está dormindo"
	var wait := meeting_ready_at(id) - now()
	if wait > 0.0:
		return "Disponível em " + TimeText.short(int(ceil(wait)))
	for item: String in def.items:
		var missing := int(def.items[item]) - inventory.count(item)
		if missing > 0:
			return "Falta %s ×%d" % [Database.item_name(item), missing]
	return ""


## Confirma um ciclo: valida tudo antes, consome o material e registra o ciclo e o prêmio (id estável por
## ciclo em `economy.granted`) no mesmo passo salvo. Erro não consome nada.
func gather_project(id: String) -> String:
	var error := meeting_error(id)
	if error != "":
		return error
	var def := meeting_def(id)
	for item: String in def.items:
		inventory.remove(item, int(def.items[item]))
	var entry := projects.entry(id)
	var cycle := projects.cycle_count(id) + 1
	var cycles: Dictionary = entry.cycles
	cycles[str(cycle)] = {"at": now()}
	entry["cycles"] = cycles
	projects.projects[id] = entry
	var rewards: Dictionary = def.get("rewards", {})
	var paid := _grant_automatic("project_gather:%s:%d" % [id, cycle], rewards)
	if bool(paid.paid) and int(rewards.get("xp", 0)) > 0:
		_add_player_xp(int(rewards.xp))
	_count("project_gather")
	_count("project_gather:" + id)
	_changed()
	_album_event("project_gathered")
	Events.project_gathered.emit(id, cycle)
	return ""

# --- Crescimento do Tiro ---------------------------------------------------

## Requisitos pertencem à fase de destino; contadores têm a base da fase atual.
## Aparência única para todas as telas; consulta pura, inclusive a pelagem dinâmica do Mocinho.
func dog_look() -> Dictionary:
	var phase: Dictionary = Database.growth.phases[maxi(0, growth.phase_index())]
	var body := str(phase.body)
	var art: Dictionary = Database.growth.bodies[body]
	var coat := float(phase.coat)
	if growth.phase == "young":
		var total := 0.0
		for id: String in ["brave", "smart", "coat"]:
			total += minf(1.0, float(growth.phase_moments.get(id, 0)) / maxf(1.0, growth.phase_need(id)))
		coat = 0.3 + 0.4 * total / 3.0
	return {"body": body, "dir_pet": art.dir.pet, "dir_world": art.dir.world,
		"portrait": art.portrait, "idle_front": art.idle_front, "coat": coat,
		"clip_fallback": art.clip_fallback, "sheen": silk_sheen()}


## Brilho da Pelagem de seda (0 sem seda); só existe no adulto.
func silk_sheen() -> float:
	if growth.phase != "adult" or growth.silk <= 0:
		return 0.0
	return float(Database.growth.silk.levels[growth.silk - 1].sheen)


## Próximo nível da seda com requisitos (n/m) e se já dá para pedir "Mais brilho!". Consulta pura.
func silk_info() -> Dictionary:
	var levels: Array = Database.growth.get("silk", {}).get("levels", [])
	var adult: bool = growth.phase == "adult"
	var result := {"level": growth.silk, "max": levels.size(), "adult": adult, "next": {}, "requirements": [], "ready": false}
	if not adult or growth.silk >= levels.size():
		return result
	var def: Dictionary = levels[growth.silk]
	var rows: Array[Dictionary] = [
		{"id": "coat", "label": "Momentos de Pelagem", "have": int(growth.moments.get("coat", 0)), "need": int(def.coat)},
		{"id": "brush_days", "label": "Escovar em dias diferentes", "have": growth.brush_days.size(), "need": int(def.brush_days)},
		{"id": "shampoo", "label": "Banho com xampu", "have": progress.stat("shampoo_bath"), "need": int(def.shampoo)}]
	var ready := true
	for row: Dictionary in rows:
		row["done"] = int(row.have) >= int(row.need)
		ready = ready and bool(row.done)
	result["next"] = def
	result["requirements"] = rows
	result["ready"] = ready
	return result


func silk_error() -> String:
	var info := silk_info()
	if not info.adult:
		return "Só depois de adulto"
	if info.next.is_empty():
		return "A pelagem já está de seda"
	for row: Dictionary in info.requirements:
		if not row.done:
			return "Falta: " + str(row.label)
	return ""


func brighten() -> String:
	var reason := silk_error()
	if reason != "":
		return reason
	var def: Dictionary = silk_info().next
	growth.silk += 1
	_grant_automatic("silk:" + str(def.id), def.get("rewards", {}))
	_diary("silk", str(def.name), "silk:" + str(def.id))
	_changed()
	Events.silk_up.emit(growth.silk)
	return ""


func growth_info() -> Dictionary:
	var index := growth.phase_index()
	var phases: Array = Database.growth.get("phases", [])
	var next: Dictionary = phases[index + 1] if index >= 0 and index + 1 < phases.size() else {}
	var rows: Array[Dictionary] = []
	var ready := not next.is_empty()
	for req: Dictionary in next.get("requirements", []):
		var row := req.duplicate(true)
		row["label"] = _growth_label(req)
		row["need"] = int(req.get("qty", 1))
		row["have"] = _growth_have(req, str(next.id))
		row["done"] = bool(growth.done.get(str(next.id), {}).get(str(req.id), false)) or int(row.have) >= int(row.need)
		ready = ready and bool(row.done)
		rows.append(row)
	var pillars := {}
	for id: String in Database.growth.get("pillars", {}):
		pillars[id] = {"have": int(growth.phase_moments.get(id, 0)), "need": growth.phase_need(id), "total": int(growth.moments.get(id, 0)), "title": str(Database.growth.pillars[id].name), "icon": str(Database.growth.pillars[id].icon)}
	var catalog: Array[Dictionary] = []
	for i in phases.size():
		var phase: Dictionary = phases[i].duplicate(true)
		phase["art"] = Database.growth.bodies[phase.body].duplicate(true)
		phase["visited"] = i <= index
		phase["at"] = float(growth.ceremonies.get(str(phase.id), {}).get("at", 0.0))
		if i == index: phase["at"] = growth.phase_since
		catalog.append(phase)
	return {"phase": growth.phase, "current": catalog[index], "phases": catalog,
		"next": catalog[index + 1] if not next.is_empty() else {}, "requirements": rows, "pillars": pillars, "ready": ready}


func _growth_label(req: Dictionary) -> String:
	if req.has("label"): return str(req.label)
	match str(req.type):
		"moments": return str(Database.growth.pillars[req.pillar].name)
		"owned": return str(Database.progression.upgrades[req.upgrade].name)
		"feed":
			if req.item == "any": return "Dar comida"
			if req.item == "favorite": return "Comer " + Database.item_name(favorite_food()) if favorite_found() else "Descubra a favorita"
			return "Comer " + Database.item_name(str(req.item))
		"deliver": return Database.item_name(str(req.item))
		"quest": return str(Database.quests[req.quest].name)
		"project": return str(Database.project(str(req.project)).name)
		"collection": return str(Database.collections[req.collection].name)
		"stat": return str(Database.progression.settings.stat_labels.get(str(req.counter), "Passeios" if req.counter == "walk" else req.counter))
	return str(req.id)


func _growth_have(req: Dictionary, target: String) -> int:
	match str(req.get("type", "")):
		"given": return 1
		"owned": return int(has_upgrade(str(req.upgrade)))
		"quest": return int(progress.claimed_quests.has(str(req.quest)))
		"project": return int(projects.is_completed(str(req.project)))
		"collection": return int(progress.collection.has(str(req.collection)))
		"deliver": return int(growth.delivered.get(target, {}).get(str(req.item), 0))
		"moments": return int(growth.phase_moments.get(str(req.pillar), 0))
		"feed", "stat":
			var key := str(req.get("counter", ""))
			if str(req.type) == "feed":
				key = "feed" if str(req.item) == "any" else "feed:" + (favorite_food() if str(req.item) == "favorite" else str(req.item))
			return maxi(0, progress.stat(key) - int(growth.phase_stats.get(key, 0)))
	return 0


## Chamado nas mutações, nunca nas consultas. Um requisito visto cumprido fica definitivo.
func _sync_growth() -> void:
	_sync_meal_body()
	var info := growth_info()
	if info.next.is_empty():
		return
	var target := str(info.next.id)
	if not growth.done.has(target):
		growth.done[target] = {}
	var was_ready := true
	for row: Dictionary in info.requirements:
		was_ready = was_ready and bool(growth.done[target].get(str(row.id), false))
		if row.done and not growth.done[target].get(str(row.id), false):
			growth.done[target][str(row.id)] = true
			Events.growth_requirement_done.emit(target, str(row.id))
	if info.ready and not was_ready:
		Events.growth_ready.emit(target)


## Refeições e Corpo formam uma única tarefa. Completar as porções garante o patamar,
## sem moeda ou prêmio repetido ao recarregar.
func _sync_meal_body() -> void:
	var index := growth.phase_index() + 1
	if index <= 0 or index >= Database.growth.phases.size(): return
	var phase: Dictionary = Database.growth.phases[index]
	var receipt := "meal_body:" + str(phase.id)
	if growth.firsts.has(receipt): return
	for req: Dictionary in phase.requirements:
		if req.type != "feed" or not req.has("body_level"): continue
		var complete := bool(growth.done.get(str(phase.id), {}).get(str(req.id), false)) or _growth_have(req, str(phase.id)) >= int(req.qty)
		if not complete: return
		growth.firsts[receipt] = true
		growth.body_level = maxi(growth.body_level, int(req.body_level))


func grow_error() -> String:
	var info := growth_info()
	if info.next.is_empty():
		return "O Tiro já cresceu tudo"
	for row: Dictionary in info.requirements:
		if not row.done:
			return "Falta: " + str(row.get("label", row.id))
	return ""


func grow() -> String:
	var reason := grow_error()
	if reason != "":
		return reason
	_sync_growth()
	var next: Dictionary = growth_info().next
	var target := str(next.id)
	# Mesmo um clique repetido não cresce duas vezes com os mesmos requisitos.
	if growth.ceremonies.has(target):
		return "Já cresceu"
	growth.ceremonies[target] = {"at": now(), "seen": false, "before": growth.phase, "before_coat": dog_look().coat,
		"delivered": growth.delivered.get(target, {}).duplicate(true)}
	if dog.sleeping and target in ["young", "adult"]:
		growth.pending_reveal = target
	growth.phase = target
	growth.phase_since = now()
	growth.phase_stats = progress.stats.duplicate(true)
	growth.phase_moments.clear()
	_grant_automatic("growth:" + target, next.get("rewards", {}))
	growth.ceremonies[target]["after_coat"] = dog_look().coat
	_diary("grew", str(next.name), "growth:" + target)
	_album_event("grew", {"grew_to": target})
	_changed()
	Events.grew.emit(target)
	return ""


## Recibo confirmado apenas ao fechar o cartão: fechar o jogo durante a cena retoma uma única revelação.
func acknowledge_growth(phase: String) -> void:
	if not growth.ceremonies.has(phase): return
	growth.ceremonies[phase]["seen"] = true
	if growth.pending_reveal == phase: growth.pending_reveal = ""
	_changed()


func reveal_sleeping_growth() -> void:
	if growth.pending_reveal == "": return
	growth.pending_reveal = ""
	_changed()


func mark_growth_ready_seen() -> void:
	var info := growth_info()
	if info.ready:
		growth.ready_seen = str(info.next.id)
		_changed()


func deliver_growth_error(item: String) -> String:
	for row: Dictionary in growth_info().requirements:
		if str(row.type) == "deliver" and str(row.item) == item:
			if row.done:
				return "Já entregue"
			return "" if inventory.count(item) > 0 else "Falta " + Database.item_name(item)
	return "O Tiro não precisa disso para crescer"


func deliver_growth(item: String) -> String:
	var reason := deliver_growth_error(item)
	if reason != "":
		return reason
	var info := growth_info()
	var target := str(info.next.id)
	if not growth.delivered.has(target):
		growth.delivered[target] = {}
	for row: Dictionary in info.requirements:
		if str(row.type) == "deliver" and str(row.item) == item:
			var amount := mini(inventory.count(item), int(row.need) - int(row.have))
			inventory.remove(item, amount)
			growth.delivered[target][item] = int(row.have) + amount
			break
	_changed()
	return ""


# --- Álbum de recordações (etapa 13) -----------------------------------------------

## Único avaliador do álbum: as ações do jogo avisam o evento e as fotos cujas condições valem são tiradas.
## Foto tirada uma vez (`album.photos[id]`); devolve os ids novos. Quem chama grava (`_changed`) depois.
func _album_event(event: String, ctx: Dictionary = {}) -> Array[String]:
	var taken: Array[String] = []
	if not Database.album.has("photos"):
		return taken
	var at := now()
	ctx = ctx.duplicate()
	if not ctx.has("world"): ctx["world"] = album_world
	ctx["dog_world"] = "" if walking() else album_world
	if not ctx.has("spot"): ctx["spot"] = album_sleep_spot if album_sleep_spot != "" else default_sleep_spot()
	if event == "album_opened" and album.has_photo(str(ctx.get("photo", ""))) and friend_hearts("pipoca") >= 1 and not album.has_photo("s_photobomb"):
		album.photobomb_pity += 1
		var chance: Dictionary = Database.photo("s_photobomb").get("when", {}).get("chance", {})
		ctx["photobomb"] = album.photobomb_pity >= int(chance.get("pity", 8)) or randi_range(1, maxi(1, int(chance.get("one_in", 8)))) == 1
	album.note(event, at)
	var active: Array = Database.album.get("active_sections", [])
	for entry: Dictionary in Database.album.photos:
		var id := str(entry.id)
		if str(entry.section) not in active or album.has_photo(id):
			continue
		if event == "app_opened" and str(entry.section) == "sleep" and not dog.sleeping: continue
		if AlbumRules.matches(entry, event, ctx, at):
			_take_photo(id)
			taken.append(id)
	return taken


func _take_photo(id: String) -> void:
	album.photos[id] = {"at": now(), "phase": growth.phase, "coat": dog_look().coat, "seen": false, "equipped": progress.equipped.duplicate()}
	_diary("photo", str(Database.photo(id).get("title", id)), "photo:" + id)
	_count("photos")
	Events.photo_taken.emit(id)


## Local escolhido para a soneca. No mapa, DogWorld confirma o lugar ao chegar.
func default_sleep_spot() -> String:
	if album_world == "house":
		return "bed" if has_upgrade("dog_bed") else "box"
	return "sofa" if has_upgrade("sofa") else "floor"


func note_sleep_spot(spot: String) -> void:
	if not dog.sleeping: return
	album_sleep_spot = spot
	_album_event("slept", {"spot": spot})
	if bool(friend_state.entry("pipoca").get("visit_pending", false)):
		_album_event("friend_visit", {"item": "pipoca", "world": "house"})
	_changed()


func note_dog_tapped(world: String) -> void:
	album_world = world
	_album_event("tapped_dog", {"world": world})
	_changed()


func note_object_tapped(id: String, world: String) -> void:
	album_world = world
	album.note("tapped_object:" + id, now())
	_album_event("tapped_object", {"object": id, "world": world})
	_changed()


## Só o arrasto atual conta; toque em Tudo e arrastos separados não se somam.
func begin_album_water_drag() -> void:
	album.recent.erase("water_drag")
	album_water_drag = true


func end_album_water_drag() -> void:
	album_water_drag = false
	album.recent.erase("water_drag")


func note_app_opened() -> void:
	var window := float(Database.photo("d_gotcha").get("when", {}).get("anniversary", 7))
	var year := AlbumRules.anniversary_year(now(), window)
	if year > int(album.years.get("gotcha", 0)):
		album.years["gotcha"] = year
		album.party_from = now()
		var local := _local_time()
		var date := Time.get_datetime_dict_from_unix_time(local)
		var started := Time.get_datetime_dict_from_unix_time(_local_time(progress.started_at))
		var day := int(started.day)
		if int(started.month) == 2 and day == 29 and not (year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)): day = 28
		var anniversary := Time.get_unix_time_from_datetime_dict({"year": date.year, "month": started.month, "day": day, "hour": 0, "minute": 0, "second": 0})
		album.party_until = now() + anniversary + window * 86400.0 - local
		Events.toast_requested.emit("É o Dia do Tiro! Vamos comemorar juntos.")
	_album_event("app_opened")
	if dog.sleeping and bool(friend_state.entry("pipoca").get("visit_pending", false)):
		_album_event("friend_visit", {"item": "pipoca", "world": "house"})
	_changed()


func tiro_party() -> bool:
	return album.party_from > 0.0 and now() >= album.party_from and now() < album.party_until


func note_album_section(section: String) -> void:
	note_screen_opened("album")
	var changed := false
	for entry: Dictionary in Database.album.photos:
		if str(entry.section) == section and section in ["tricks", "sleep"] and not album.opened_at.has(str(entry.id)):
			album.opened_at[str(entry.id)] = now()
			changed = true
	if changed: _changed()


func album_lupas_left() -> int:
	var day := Time.get_date_string_from_unix_time(int(_local_time()))
	var used := album.lupas_used if day <= album.lupa_day else 0
	return maxi(0, 1 + int(house_has("old_camera")) - used)


func reveal_photo_hint(id: String) -> String:
	var entry := Database.photo(id)
	if entry.is_empty() or str(entry.section) not in ["tricks", "sleep"] or album.has_photo(id): return "Essa foto não precisa de lupa"
	if int(album.hints.get(id, 0)) > 0: return ""
	if album_lupas_left() <= 0: return "A lupa volta amanhã"
	var day := Time.get_date_string_from_unix_time(int(_local_time()))
	if day > album.lupa_day:
		album.lupa_day = day
		album.lupas_used = 0
	album.lupas_used += 1
	album.hints[id] = 1
	_changed()
	return ""


## Uma fala por conversa; recibo persistido antes de exibir, inclusive após recarregar.
func album_talk(npc: String) -> String:
	for entry: Dictionary in Database.album.photos:
		var id := str(entry.id)
		var key := "photo:" + id + ":" + npc
		var people: Array = entry.get("photo", {}).get("friends", []).duplicate()
		people.append(str(entry.get("photo", {}).get("friend", "")))
		if album.has_photo(id) and npc in people and entry.has("photo_talk") and not album.spoken.has(key):
			album.spoken[key] = true
			_changed()
			return str(entry.photo_talk)
	var config: Dictionary = Database.album_config
	if album.count() < int(config.get("hint_photos", 5)): return ""
	for entry: Dictionary in Database.album.photos:
		var id := str(entry.id)
		if album.has_photo(id) or str(entry.get("hint_npc", "")) != npc or album.spoken.has("hint:" + id): continue
		var opened := float(album.opened_at.get(id, now()))
		if now() - opened < float(config.get("hint_days", 3)) * 86400.0: continue
		album.spoken["hint:" + id] = true
		_changed()
		return str(entry.get("hint_talk", entry.get("hint", "")))
	return ""


func album_hint_glow(object: String) -> bool:
	return bool(album_hint_glow_map().get(object, false))


## {objeto: brilha} de todas as fotos com pista, numa só passada (a sala guarda o resultado
## e só o recalcula em state_changed e a cada segundo).
func album_hint_glow_map() -> Dictionary:
	var glow := {}
	var dog_world := "" if walking() else album_world
	var moment := now()
	for entry: Dictionary in Database.album.photos:
		var object := str(entry.get("hint_object", ""))
		if object == "" or glow.has(object) or album.has_photo(str(entry.id)): continue
		var when: Dictionary = entry.get("when", {})
		if when.size() != 3: continue
		var ctx := {"world": album_world, "dog_world": dog_world, "object": object, "spot": album_sleep_spot}
		var valid := 0
		for key: String in when:
			valid += int(AlbumRules.holds(key, when[key], ctx, "", moment))
		if valid == 2: glow[object] = true
	return glow


## Foto tirada ({} se ainda não): data, fase e pelo gravados no dia.
func photo_info(id: String) -> Dictionary:
	return album.photos.get(id, {}).duplicate()


func photo_count() -> int:
	return album.count()


## Fotos novas que o jogador ainda não abriu.
func photos_unseen() -> Array[String]:
	return album.unseen()


## Fotos são registradas desde a chegada; avisos começam só depois de conhecer o Álbum.
## Saves que já têm fotos vistas/seções exploradas preservam essa descoberta.
func photo_alerts_enabled() -> bool:
	return progress.stat("open:album") > 0 or not album.opened_at.is_empty() or album.photos.values().any(func(photo: Dictionary) -> bool: return bool(photo.get("seen", false)))


# --- A Casa que cresce (etapa 14) --------------------------------------------------

## O objeto da Casa já chegou? Regra viva, em `data/house.json` (fase, fotos, lembranças entregues ou melhoria).
func house_has(id: String) -> bool:
	var def: Dictionary = Database.house.get("items", {}).get(id, {})
	if def.is_empty():
		return false
	var rule: Dictionary = def.get("rule", {})
	if rule.has("before_house") and house_has(str(rule.before_house)):
		return false
	if rule.has("growth") and growth.phase_index() < growth.phase_index(str(rule.growth)):
		return false
	if rule.has("keepsakes") and keepsakes_delivered().size() < int(rule.keepsakes):
		return false
	if rule.has("photos") and album.count() < int(rule.photos):
		return false
	if rule.has("upgrade") and not has_upgrade(str(rule.upgrade)):
		return false
	return true


func house_item_name(id: String) -> String:
	return str(Database.house.get("items", {}).get(id, {}).get("name", id))


## Lembrança entregue ao Tiro (item-chave dado ao crescer).
func keepsake_delivered(item: String) -> bool:
	for phase: String in growth.delivered:
		if int((growth.delivered[phase] as Dictionary).get(item, 0)) > 0:
			return true
	return false


func keepsakes_delivered() -> Array[String]:
	var result: Array[String] = []
	for entry: Dictionary in Database.house.get("shelf", []):
		var id := str(entry.id)
		if Database.items.get(id, {}).get("category", "") == "keepsake" and keepsake_delivered(id):
			result.append(id)
	return result


## Bônus de energia dormindo da melhor caminha comprada (0 / 0,1 / 0,2).
func house_sleep_bonus() -> float:
	var best := 0.0
	var bonuses: Dictionary = Database.house.get("sleep_bonus", {})
	for id: String in bonuses:
		if has_upgrade(id):
			best = maxf(best, float(bonuses[id]))
	return best


## Anuncia cada objeto uma vez só e mantém o bônus da caminha no `DogState`.
func _sync_house() -> void:
	if Database.house.is_empty():
		return
	var bonus := house_sleep_bonus()
	if not is_equal_approx(dog.sleep_bonus, bonus):
		dog.commit(now())  # o trecho anterior vale com o bônus antigo
		dog.sleep_bonus = bonus
	var arrived: Dictionary = progress.house.arrived
	for id: String in Database.house.items:
		if arrived.has(id) or not house_has(id):
			continue
		arrived[id] = now()
		if not bool(Database.house.items[id].get("silent", false)):
			Events.house_item_arrived.emit(id)


func toy_basket_count() -> int:
	return mini(progress.house.toys.size(), int(Database.house.get("toy_basket_max", 3)))


func give_toy_error(item: String) -> String:
	if not bool(Database.items.get(item, {}).get("toy", false)):
		return "Esse não é um brinquedo"
	if not house_has("toy_basket"):
		return "Falta o cesto de brinquedos"
	if progress.house.toys.has(item):
		return "Esse já está no cesto"
	if inventory.count(item) < 1:
		return "Falta " + Database.item_name(item)
	return ""


func give_toy(item: String) -> String:
	var reason := give_toy_error(item)
	if reason != "":
		return reason
	inventory.remove(item)
	progress.house.toys.append(item)
	progress.seen["house:" + item] = true
	_count("toy")
	_changed()
	return ""


func hang_photo_error(id: String, slot: int = -1) -> String:
	if not house_has("photo_wall"):
		return "Falta a parede de fotos"
	if not album.has_photo(id):
		return "Essa foto ainda não existe"
	if album.wall.has(id):
		return "Já está na parede"
	var slots := int(Database.house.get("wall_slots", 3))
	if slot >= slots:
		return "A parede só tem %d lugares" % slots
	if slot < 0 and album.wall.filter(func(entry: Variant) -> bool: return str(entry) != "").size() >= slots:
		return "A parede está cheia"
	return ""


## Pendura a foto no lugar `slot` (ou no primeiro vazio). Trocar um lugar ocupado substitui a foto.
func hang_photo(id: String, slot: int = -1) -> String:
	var reason := hang_photo_error(id, slot)
	if reason != "":
		return reason
	var slots := int(Database.house.get("wall_slots", 3))
	while album.wall.size() < slots:
		album.wall.append("")
	if slot < 0:
		slot = album.wall.find("")
	album.wall[slot] = id
	_changed()
	return ""


func unhang_photo(id: String) -> void:
	var index := album.wall.find(id)
	if index < 0:
		return
	album.wall[index] = ""
	_changed()


func main_photo_error(id: String) -> String:
	if not house_has("gold_frame"):
		return "Falta a moldura dourada"
	if id != "" and not album.has_photo(id):
		return "Essa foto ainda não existe"
	return ""


## Foto principal do cantinho do Tiro ("" tira a escolha).
func set_main_photo(id: String) -> String:
	var reason := main_photo_error(id)
	if reason != "":
		return reason
	album.main_photo = id
	_changed()
	return ""


## Lupas grátis por dia nas dicas do álbum (a lupa entra na etapa 15; aqui só o dado).
func lupas_per_day() -> int:
	return 1 + (1 if house_has("old_camera") else 0)


func open_album_photo(id: String) -> void:
	if not album.has_photo(id): return
	note_screen_opened("album")
	_album_event("album_opened", {"photo": id})
	mark_photo_seen(id)
	_changed()


func mark_photo_seen(id: String) -> void:
	if album.photos.has(id) and not bool(album.photos[id].get("seen", false)):
		album.photos[id]["seen"] = true
		_changed()


func dev_take_photo(id: String) -> void:
	if not BuildInfo.is_dev(): return
	if Database.photo(id).is_empty() or album.has_photo(id): return
	_take_photo(id)
	_changed()


func dev_reset_album() -> void:
	if not BuildInfo.is_dev(): return
	album = AlbumState.new()
	album.reset()
	progress.stats.erase("photos")
	_changed()


func dev_set_phase(id: String) -> void:
	if not BuildInfo.is_dev(): return
	if growth.phase_index(id) < 0:
		return
	growth.phase = id
	growth.phase_since = now()
	growth.phase_stats = progress.stats.duplicate(true)
	_changed()


## DEV muda somente a consulta de período; produção e necessidades mantêm o relógio real.
var _dev_moment_offset: float = 0.0


func moment_period(at: float = -1.0) -> String:
	var local := _local_time(now() + _dev_moment_offset if at < 0 else at)
	var date := Time.get_date_string_from_unix_time(local)
	var hour := int(Time.get_time_dict_from_unix_time(local).hour)
	var period := ""
	for entry: Dictionary in Database.growth.moments.periods:
		if hour >= int(entry.start): period = str(entry.id)
	return date + ":" + period


func _prune_moment_periods() -> void:
	var at := now() + _dev_moment_offset
	var local := _local_time(at)
	var hour := int(Time.get_time_dict_from_unix_time(local).hour)
	var start := 0
	for entry: Dictionary in Database.growth.moments.periods:
		if hour >= int(entry.start): start = int(entry.start)
	var midnight := local - posmod(local, 86400)
	var previous := moment_period(at - (local - midnight - start * 3600) - 1)
	var current := moment_period()
	for key: String in growth.period_moments.keys():
		if not key.begins_with(current + ":") and not key.begins_with(previous + ":"):
			growth.period_moments.erase(key)


## Única entrada de momentos; xampu passa por ela duas vezes, limitado pelo mesmo teto.
func _gain_moment(pillar: String, source: String, capped: bool) -> int:
	if pillar not in ["brave", "smart", "coat"]: return 0
	_prune_moment_periods()
	var key := moment_period() + ":" + pillar
	if capped:
		var used := int(growth.period_moments.get(key, 0))
		if used >= int(Database.growth.moments.period_cap): return 0
		growth.period_moments[key] = used + 1
	growth.moments[pillar] = int(growth.moments.get(pillar, 0)) + 1
	growth.phase_moments[pillar] = int(growth.phase_moments.get(pillar, 0)) + 1
	_count("moment:" + pillar)
	Events.moment_gained.emit(pillar, source)
	return 1


func _moment_source(source: String, key: String = "") -> int:
	var rule: Dictionary = Database.growth.moments.sources.get(source, {})
	if rule.is_empty(): return 0
	var guard := source + (":" + key if key != "" else "")
	if rule.get("first", false):
		if growth.firsts.has(guard): return 0
		growth.firsts[guard] = true
	var gained := 0
	for i in int(rule.qty): gained += _gain_moment(str(rule.pillar), guard, bool(rule.capped))
	return gained


## Comida favorita deste save: fixa pela semente, entre o `favorite_pool`.
func favorite_food() -> String:
	var pool: Array = Database.growth.get("tastes", {}).get("favorite_pool", [])
	if pool.is_empty(): return ""
	return str(pool[growth.taste_seed % pool.size()])


func favorite_found() -> bool:
	var fav := favorite_food()
	return fav != "" and growth.tastes.has(fav)


## Reação fixa pela semente: loved (favorita), liked, odd ou grimace.
func taste_reaction_for(item: String) -> String:
	var rules: Dictionary = Database.growth.get("tastes", {})
	if item == favorite_food(): return "loved"
	if item in rules.get("grimace", []): return "grimace"
	var roll := absi(hash("%d:%s" % [growth.taste_seed, item])) % 100
	var odds: Dictionary = rules.get("odds", {"liked": 60, "odd": 30, "grimace": 10})
	if roll < int(odds.liked): return "liked"
	if roll < int(odds.liked) + int(odds.odd): return "odd"
	return "grimace"


## Primeira prova grava a reação; a favorita reage sempre. Devolve a reação a tocar ("" = nenhuma).
func _taste(item: String) -> String:
	if not Database.growth.has("tastes"): return ""
	var first := not growth.tastes.has(item)
	var reaction := taste_reaction_for(item)
	if first:
		growth.tastes[item] = reaction
		_diary("taste", Database.item_name(item), "taste:" + item)
		if Database.items.get(item, {}).has("growth"):
			PersonalityRules.record(growth, "growth_food", 1, routine_period("daily"))
		Events.taste_discovered.emit(item, reaction)
	elif reaction != "loved":
		return ""
	Events.taste_reacted.emit(item, reaction)
	return reaction


## Comidas que ele ainda não provou e que podem ser a favorita ou estar na Mochila.
func untasted_foods() -> Array[String]:
	var result: Array[String] = []
	var have: Array[String] = []
	var pool: Array = Database.growth.get("tastes", {}).get("favorite_pool", [])
	for id: String in Database.items:
		if not Database.items[id].has("feed") or growth.tastes.has(id): continue
		if inventory.count(id) > 0: have.append(id)
		elif id in pool: result.append(id)
	have.append_array(result)
	return have


# --- Escovar (etapa 12) ---

func brush_owned() -> bool:
	return inventory.count("basic_brush") > 0


func soft_brush_given() -> bool:
	for target: String in growth.delivered:
		if int(growth.delivered[target].get("soft_brush", 0)) > 0: return true
	return false


func brush_error() -> String:
	if not brush_owned(): return "Falta a escovinha"
	if walking(): return away_text()
	if dog.sleeping: return "Shh... ele está dormindo."
	return ""


func brush() -> String:
	var error := brush_error()
	if error != "": return error
	var day := Time.get_date_string_from_unix_time(_local_time())
	growth.brush_days[day] = true
	_count("brush")
	_album_event("brushed")
	_moment_source("brush", day)
	_changed()
	Events.dog_action.emit(&"brush")
	return ""


func note_world_visit(world: String) -> void:
	if walking() or not Database.worlds.has(world) or requirement_error(Database.worlds[world].get("requirements", {})) != "": return
	album_world = world
	_album_event("world_entered", {"world": world})
	_changed()
	if walking() or not Database.worlds.has(world) or requirement_error(Database.worlds[world].get("requirements", {})) != "": return
	var guard := "world:" + world
	if growth.firsts.has(guard): return
	PersonalityRules.record(growth, "world", 1, routine_period("daily"))
	_moment_source("world", world)
	_changed()


func dev_add_moment(id: String) -> void:
	if not BuildInfo.is_dev(): return
	_gain_moment(id, "dev", false)
	_changed()


func dev_set_need(id: String, value: float) -> void:
	if not BuildInfo.is_dev() or not Database.needs.has(id): return
	dog.commit(now())
	dog.needs[id] = clampf(value, 0.0, 100.0)
	_changed()


func dev_next_period() -> void:
	if not BuildInfo.is_dev(): return
	var current := moment_period()
	while moment_period() == current: _dev_moment_offset += 3600.0
	_prune_moment_periods()
	_changed()


func dev_complete_growth_reqs() -> void:
	if not BuildInfo.is_dev(): return
	var info := growth_info()
	if info.next.is_empty():
		return
	var target := str(info.next.id)
	if not growth.done.has(target):
		growth.done[target] = {}
	for row: Dictionary in info.requirements:
		if not growth.done[target].get(str(row.id), false):
			growth.done[target][str(row.id)] = true
			Events.growth_requirement_done.emit(target, str(row.id))
	if not info.ready:
		Events.growth_ready.emit(target)
	_changed()


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
		"walks": walk_state.to_dict(),
		"friends": friend_state.to_dict(),
		"projects": projects.to_dict(),
		"growth": growth.to_dict(),
		"album": album.to_dict(),
		"economy": economy.to_dict(),
	}


func from_dict(data: Dictionary) -> void:
	if data.is_empty():
		reset()
		return
	# Migração de economia (pura e idempotente): piso de capacidade, snapshots de trabalhos, prêmios já pagos.
	data = EconomyMigration.migrate(data)
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
		if entry.has("job") and loaded_plot.crop != "":
			loaded_plot["job"] = (entry.job as Dictionary).duplicate(true)
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
	walk_state = WalkState.new()
	walk_state.from_dict(data.get("walks", {}))
	friend_state = FriendState.new()
	friend_state.from_dict(data.get("friends", {}))
	projects = ProjectState.new()
	projects.from_dict(data.get("projects", {}))
	growth = GrowthState.new()
	growth.from_dict(data.get("growth", {}))
	_prune_moment_periods()
	album = AlbumState.new()
	album.from_dict(data.get("album", {}))
	dog.sleep_bonus = house_sleep_bonus()  # sem commit: o tempo salvo já vale com a caminha atual
	if growth.taste_seed == 0:
		growth.taste_seed = maxi(1, absi(hash("taste:" + str(int(progress.started_at)))))
	economy = EconomyState.new()
	economy.from_dict(data.get("economy", {}))
	_seed_mastery()
	_recover_projects()
	_sync_friend_level()
	# Fechamento abrupto: sem início de ausência salvo, o último instante ativo gravado é o início estimado.
	# Só estima; quem encerra a ausência é o SaveManager (carregar não cura nem repete).
	if dog.away_since <= 0.0 and friend_state.last_active_at > 0.0 and friend_state.last_active_at < now():
		dog.away_since = maxf(friend_state.last_active_at, dog.updated_at)
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
	# Viagem vencida com o jogo fechado volta agora (sem segundo sorteio); o cartão sai da marca persistida.
	return_due_walk(false)
	_changed()


func _ensure_stations() -> void:
	for id: String in Database.stations:
		if not stations.has(id):
			stations[id] = StationState.new()


func _changed() -> void:
	sync_friend_window()
	# Contratos antigos já entregues contam na evolução da banca, sem repetir prêmios.
	var contracts := 0
	for order_id: String in Database.progression.orders:
		if str(Database.progression.orders[order_id].get("channel", "neighbors")) == "contracts":
			contracts += progress.stat("order:" + order_id)
	progress.stats["contracts"] = contracts
	progress.stats["storage_upgrades"] = storage_upgrades_owned()
	_sync_shared_quests()
	_sync_step()
	update_wishes()
	update_finds()
	_sync_growth()
	_sync_house()
	Events.state_changed.emit()


## IDs antigos continuam válidos para requisitos/saves; só a missão do personagem paga prêmio.
func _sync_shared_quests() -> void:
	# Um marco antigo recebido equivale à sua nova missão canônica; não paga outra vez.
	for alias: String in Database.quests:
		var target := str(Database.quests[alias].get("shared_with", ""))
		if target != "" and progress.claimed_quests.has(alias):
			progress.claimed_quests[target] = true
	for _i in Database.quests.size():
		var id := progress.current_main_quest()
		var shared := str(Database.quests.get(id, {}).get("shared_with", ""))
		if shared == "" or not progress.claimed_quests.has(shared):
			break
		_finish_quest(id, false)


## Ao mudar o passo de uma linha, guarda os contadores dos objetivos "fresh" (base = agora).
func _sync_step() -> void:
	var active := progress.active_steps()
	for line: String in progress.steps.keys():
		if not active.has(line):
			progress.steps.erase(line)
	for line: String in active:
		var current: String = active[line]
		var base := {}
		for goal: Dictionary in Database.quests[current].goals:
			if goal.get("fresh", false):
				base[goal.key] = progress.stat(goal.key)
		if progress.steps.get(line, {}).get("quest", "") == current:
			# Mesmo passo (save antigo): a base só mantém os contadores que ainda são "fresh".
			var kept: Dictionary = progress.steps[line].get("base", {})
			for key: String in kept.keys():
				if not base.has(key):
					kept.erase(key)
			continue
		progress.steps[line] = {"quest": current, "base": base}


## Conclui só o passo principal atual, com as mesmas recompensas e sinais.
func dev_complete_main_step() -> void:
	if not BuildInfo.is_dev():
		return
	var id := progress.current_main_quest()
	if id != "":
		_dev_complete_quest(id)
		_changed()

# --- Amigos do Tiro --------------------------------------------------------

func friend_def(id: String) -> Dictionary:
	return Database.friends.get("friends", {}).get(id, {})


func friend_unlocked(id: String) -> bool:
	var def := friend_def(id)
	return not def.is_empty() and requirement_error(def.get("requirements", {})) == ""


## O maior bloco local já observado impede voltar uma janela ao atrasar relógio/fuso.
func friend_window_index() -> int:
	var seconds := int(Database.friends.settings.window_hours) * 3600
	return maxi(friend_state.window_index, floori(float(_local_time()) / seconds))


func friend_window() -> String:
	var local := friend_window_index() * int(Database.friends.settings.window_hours) * 3600
	return Time.get_date_string_from_unix_time(local) + "-%d" % (int(Time.get_datetime_dict_from_unix_time(local).hour) / int(Database.friends.settings.window_hours))


func _friend_visitor() -> String:
	if friend_state.visitor_window == friend_window() and friend_state.visitor != "":
		return friend_state.visitor
	var ids: Array[String] = []
	for id: String in Database.friends.friends:
		if not bool(friend_def(id).get("always", false)) and friend_unlocked(id):
			ids.append(id)
	ids.sort()
	return ids[posmod(friend_window_index(), ids.size())] if not ids.is_empty() else ""


## Fixa o visitante inclusive se novos requisitos forem cumpridos durante a janela.
func sync_friend_window() -> bool:
	var window := friend_window()
	if friend_state.visitor_window == window and (friend_state.visitor != "" or _friend_visitor() == ""):
		return false
	friend_state.visitor = _friend_visitor()
	friend_state.window_index = friend_window_index()
	friend_state.visitor_window = window
	return true


func friends_present() -> Array[String]:
	var ids: Array[String] = []
	for id: String in Database.friends.friends:
		if bool(friend_def(id).get("always", false)) and friend_unlocked(id):
			ids.append(id)
	var visitor := _friend_visitor()
	if visitor != "" and friend_unlocked(visitor):
		ids.append(visitor)
	return ids


func friend_hearts(id: String) -> int:
	return friend_state.hearts(id, Database.friends.settings.hearts)


func friend_walk_bonus() -> int:
	var total := 0
	for id: String in Database.friends.friends:
		var bonus: Dictionary = friend_def(id).get("walk_bonus", {})
		if not bonus.is_empty() and friend_hearts(id) >= int(bonus.hearts):
			total += int(bonus.rolls)
	return total


func _sync_friend_level() -> void:
	var total := 0
	for id: String in Database.friends.friends:
		total += friend_hearts(id)
	progress.stats["friend_level"] = total


func _friend_heart_reward(id: String, gifts: int) -> Dictionary:
	var reward: Dictionary = {"coins": 0, "items": {}, "collections": []}
	var claimed := int(friend_state.entry(id).claimed_hearts)
	var thresholds: Array = Database.friends.settings.hearts
	for i in thresholds.size():
		if gifts < int(thresholds[i]) or i < claimed:
			continue
		var next: Dictionary = friend_def(id).heart_rewards[i]
		reward.coins += int(next.get("coins", 0))
		_add_amounts(reward.items, next.get("items", {}))
		reward.collections.append_array(next.get("collections", []))
	return reward


func give_friend_error(id: String) -> String:
	if not friend_unlocked(id):
		return requirement_error(friend_def(id).get("requirements", {})) if not friend_def(id).is_empty() else "Amigo desconhecido"
	if id not in friends_present():
		return str(friend_def(id).name) + " não está na praça agora"
	var entry := friend_state.entry(id)
	if str(entry.last_window) == friend_window():
		return "Já ganhou petisco nesta janela"
	var item := str(friend_def(id).likes)
	if inventory.count(item) < 1:
		return "Falta " + Database.item_name(item)
	return storage_error(_friend_heart_reward(id, int(entry.gifts) + 1).items, {item: 1})


func give_friend(id: String) -> String:
	var reason := give_friend_error(id)
	if reason != "":
		return reason
	var entry := friend_state.entry(id).duplicate(true)
	var reward := _friend_heart_reward(id, int(entry.gifts) + 1)
	inventory.remove(str(friend_def(id).likes))
	entry.gifts = int(entry.gifts) + 1
	entry.last_window = friend_window()
	friend_state.friends[id] = entry
	entry.claimed_hearts = friend_hearts(id)
	if friend_hearts(id) == Database.friends.settings.hearts.size() and float(entry.best_at) == 0.0:
		entry.best_at = now()
	_apply_rewards(reward)
	_count("friend_gift")
	_count("friend_gift:" + id)
	if friend_hearts(id) >= 1: _moment_source("friend", id)
	_album_event("friend_heart", {"friend": id})
	_sync_friend_level()
	_changed()
	Events.items_gained.emit(reward.items, int(reward.coins), Vector2(-1, -1))
	return ""


## O app saiu de cena (segundo plano/fechar): fixa o Tiro e abre a ausência protegida. Idempotente.
func begin_absence(at: float) -> void:
	dog.begin_absence(minf(at, now()))


## O app voltou (ou o save foi carregado): projeta a ausência uma única vez e volta às taxas online.
## Devolve true se havia ausência. Não cria visitas nem presentes: isso é do `update_friend_visits`.
func end_absence() -> bool:
	if not dog.end_absence(now()):
		return false
	_changed()
	return true


## Só o ciclo de presença do SaveManager chama esta ação. Não é atualização por timer,
## nem parte de from_dict/troca de slot. Uma ausência contínua de oito horas é necessária.
func update_friend_visits(away_since: float = -1.0) -> void:
	var since := friend_state.last_active_at if away_since < 0.0 else away_since
	var interval := float(Database.friends.settings.visit_hours) * 3600.0
	if since <= 0.0 or now() - since < interval:
		return
	var changed := false
	for id: String in Database.friends.friends:
		var entry := friend_state.entry(id).duplicate(true)
		if friend_hearts(id) < Database.friends.settings.hearts.size() or bool(entry.visit_pending):
			continue
		if now() - maxf(since, maxf(float(entry.best_at), float(entry.last_visit))) < interval:
			continue
		var gift: Dictionary = friend_def(id).visit_gift
		var seed := hash(id + ":" + str(entry.last_visit) + ":" + str(since))
		var reward := Loot.roll(gift.get("loot", []), 1, seed)
		reward.coins += Loot.amount(gift.get("coins", 0), seed + 1)
		entry.visit_pending = true
		_album_event("friend_visit", {"item": id, "world": "house"})
		entry.visit_gift = reward
		entry.last_visit = now()
		friend_state.friends[id] = entry
		changed = true
	if changed:
		_changed()


func collect_friend_visit_error(id: String) -> String:
	var entry := friend_state.entry(id)
	if not bool(entry.visit_pending):
		return "Nenhuma visita"
	return storage_error(entry.visit_gift.get("items", {}))


func collect_friend_visit(id: String) -> String:
	var reason := collect_friend_visit_error(id)
	if reason != "":
		return reason
	var entry := friend_state.entry(id)
	var reward: Dictionary = entry.visit_gift.duplicate(true)
	entry.visit_pending = false
	entry.visit_gift = {}
	_album_event("friend_visit", {"item": id, "world": "house"})
	_apply_rewards(reward)
	_changed()
	Events.items_gained.emit(reward.get("items", {}), int(reward.get("coins", 0)), Vector2(-1, -1))
	return ""


# Jeito e diário são lembranças: nunca concedem prêmios nem alteram necessidades.
func _diary(kind: String, title: String, receipt: String = "") -> void:
	if receipt != "" and growth.diary_receipts.has(receipt): return
	var rule: Dictionary = Database.growth.get("diary", {})
	var template := str(rule.get("templates", {}).get(kind, ""))
	if template == "": return
	if receipt != "": growth.diary_receipts[receipt] = true
	growth.diary.append({"at": now(), "day": routine_period("daily"), "kind": kind, "text": template.format({"name": title})})
	while growth.diary.size() > int(rule.get("limit", 20)): growth.diary.pop_front()
