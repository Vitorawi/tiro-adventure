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
## Pesca na lagoa: varas, iscas, recordes e a partida em andamento (plano docs/plans/pesca).
var fishing := FishingState.new()
var week := WeekState.new()
var _yard_round: Dictionary = {}
var _yard_serial := 0
## Refeição guardada (Deixar pronto) sendo comida: período e dia do jogo (só dentro de `_eat_stored`).
var _forced_meal: String = ""
var _forced_day: int = 0
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
var _week_story_clock := ""


func _ready() -> void:
	# Desejos novos aparecem com o tempo, mesmo sem nenhuma ação do jogador.
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(func() -> void:
		var week_changed := update_week()
		var changed_wishes := update_wishes()
		# A volta do passeio não depende de nenhuma tela aberta: o tick liquida a viagem vencida.
		return_due_walk()
		_auto_store_baggage()
		changed_wishes = _recover_projects() or changed_wishes
		changed_wishes = update_fishing() or changed_wishes
		var finds_changed := update_finds()
		if sync_friend_window() or finds_changed or changed_wishes or week_changed:
			_changed())
	add_child(timer)


func now() -> float:
	return Time.get_unix_time_from_system()


## Soma ao contador e grava a primeira vez (alimenta o "Ritmo" do painel DEV).
func _count(key: String, amount: int = 1) -> void:
	if progress.stat(key) == 0 and amount > 0 and not progress.firsts.has(key):
		progress.firsts[key] = now()
	progress.count(key, amount)
	_count_week_challenge(key, amount)
	_count_week_routine(key, amount)
	PersonalityRules.record(growth, key, amount, routine_period("daily"))

func reset() -> void:
	_week_story_clock = ""
	_yard_round.clear()
	_trick_lesson.clear()
	_trick_show.clear()
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
	fishing = FishingState.new()
	week = WeekState.new()
	week.started_day = week_day_number()
	week.high_day = week.started_day
	week.option = str(Database.meals.get("default_option", "normal"))
	_anchor_arrival()
	_week_init_settle()
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
	if _golden_worm_due(entry):
		var with_worm: Dictionary = reward.get("items", {}).duplicate()
		with_worm[str(secret_config().bait)] = 1
		reward["items"] = with_worm
	return reward


# --- Missão secreta da vovó: o Ensopado Dourado (F04b) ---------------------------------

func secret_config() -> Dictionary:
	return Database.meals.get("secret", {})


## A missão secreta existe só para quem fez toda a lista do Dentinhos e espera as patinhas (fase Filhotinho).
func secret_open() -> bool:
	return growth.phase == "puppy" and only_paws_left()


## Patinhas extras já ganhas com o Ensopado Dourado nesta fase.
func secret_bonus_total() -> int:
	var total := 0
	for key: String in week.bonus_paws:
		total += int(week.bonus_paws[key])
	return total


## A minhoca gorda pode cair: missão aberta e ainda cabem patinhas extras.
func _golden_worm_context() -> bool:
	var config := secret_config()
	return not config.is_empty() and secret_open() and secret_bonus_total() < int(config.max_extra)


func _golden_worm_due(entry: Dictionary) -> bool:
	if not _golden_worm_context() or inventory.count(str(secret_config().bait)) > 0:
		return false
	if week.worm_digs >= int(secret_config().worm_pity) - 1:
		return true
	return float(absi(hash("%d:worm" % int(entry.seed))) % 1000) / 1000.0 < float(secret_config().worm_chance)


## O peixe dourado já mordeu hoje (dia do Tiro, virada às 6 h)?
func golden_bitten_today() -> bool:
	return week.golden_day == week_day()


## Isca aceita pela vara: as da vara e a minhoca gorda (secreta, vale em qualquer vara).
func bait_allowed(rod: String, bait: String) -> bool:
	return bait in Database.fishing.rods[rod].baits or bait == str(secret_config().get("bait", ""))


## Peixe dourado só vale com pescaria Perfeita; senão escapa (e a minhoca já foi).
func _golden_rule(fish_id: String, use: Dictionary) -> Dictionary:
	if fish_id == str(secret_config().get("fish", "")) and bool(use.caught) and not bool(use.perfect):
		var copy := use.duplicate()
		copy["caught"] = false
		return copy
	return use


## Patinha extra do Ensopado Dourado: ao vivo na janela, uma por dia, teto por fase. Chamada pelo `_register_meal`.
func _secret_paw(item_id: String, day: int) -> void:
	var config := secret_config()
	if config.is_empty() or item_id != str(config.stew) or growth.phase != "puppy":
		return
	if week.bonus_paws.has(str(day)) or secret_bonus_total() >= int(config.max_extra):
		return
	week.bonus_paws[str(day)] = 1
	_count("well_fed_day")
	_count("secret_paw")
	Events.paw_earned.emit(day)
	Events.toast_requested.emit("Patinha extra!")


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
	if world == "farm":
		_recipe_source("dig")
	var reward := find_reward(world)
	if _golden_worm_context() and inventory.count(str(secret_config().bait)) == 0:
		week.worm_digs = 0 if reward.get("items", {}).has(str(secret_config().bait)) else week.worm_digs + 1
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
	# Regra do Vitor: o que o Tiro traz vai direto para a Mochila/depósitos; só o que não cabe espera na sacola.
	_auto_store_baggage()
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


## Guarda sozinho o que cabe da bagagem (ao voltar, ao carregar o save e a cada tick, assim que houver espaço). O que não
## couber continua seguro em `pending_return.left`. Idempotente: sem bagagem ou sem espaço não faz nada.
func _auto_store_baggage() -> void:
	if walk_ready() and walk_baggage_error() == "":
		claim_walk_baggage()


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

var _trick_lesson: Dictionary = {}
var _trick_show: Dictionary = {}


func trick_is_lesson(id: String) -> bool:
	return Database.progression.tricks.get(id, {}).has("lesson")


func trick_lesson_period() -> int:
	# Madrugada ainda é a noite do dia anterior.
	return week_day_number() * 3 + mini(floori(fposmod(_game_seconds(), 86400.0) / 21600.0), 2)


func trick_lesson_cookies() -> Array[String]:
	var ids: Array[String] = []
	var type := str(Database.progression.trick_settings.lesson.cookie_type)
	for id: String in inventory.counts:
		if str(dish_of_item(id).get("type", "")) == type:
			ids.append(id)
	ids.sort()
	return ids


func trick_lesson_error(id: String) -> String:
	if not trick_is_lesson(id):
		return "Truque desconhecido"
	var error := trick_available_error(id)
	if error != "":
		return error
	if tiro_weak():
		return "Ele quer comer primeiro"
	return "Falta Biscoito ×1" if trick_lesson_cookies().is_empty() else ""


func start_trick_lesson(id: String) -> String:
	if not _trick_lesson.is_empty() or not _trick_show.is_empty():
		return "Já tem um treino ou show em andamento"
	var error := trick_lesson_error(id)
	if error == "":
		_trick_lesson = {"id": id, "step": 0, "points": 0}
		var saved: Dictionary = week.tutorial.get("lesson", {})
		if saved.get("id") == id and int(saved.get("period", -1)) == trick_lesson_period():
			_trick_lesson.step = clampi(int(saved.step), 0, int(Database.progression.trick_settings.lesson.repetitions) * 3 - 1)
			_trick_lesson.points = clampi(int(saved.points), 0, 20)
	return error


func trick_lesson_position() -> int:
	return int(_trick_lesson.get("step", 0))


func cancel_trick_lesson(id: String) -> void:
	if _trick_lesson.get("id", "") == id:
		_trick_lesson.clear()


## Cada ação avança um passo. Marcar e premiar recebem segundos desde o início do passo.
func trick_lesson_step(id: String, step: String, value: float) -> Dictionary:
	var steps := ["show", "mark", "reward"]
	if _trick_lesson.get("id", "") != id or step != steps[int(_trick_lesson.step) % steps.size()] or not is_finite(value) or value < 0.0:
		return {"error": "Esse passo ainda não está pronto"}
	var error := trick_lesson_error(id)
	if error != "":
		cancel_trick_lesson(id)
		return {"error": error}
	var rules: Dictionary = Database.progression.trick_settings.lesson
	var points := 0
	match step:
		"show": points = 1 if value == 1.0 else 0
		"mark":
			var distance := absf(value - float(rules.mark_at))
			var tolerance := 0.8 if trick_level(id) >= 2 else 1.0
			if distance <= float(rules.mark_perfect) * tolerance:
				points = 2
			elif distance <= float(rules.mark_good) * tolerance:
				points = 1
		"reward": points = int(value <= float(rules.reward_seconds))
	_trick_lesson.points += points
	_trick_lesson.step += 1
	if int(_trick_lesson.step) < int(rules.repetitions) * steps.size():
		var tutorial_id: String = {"sit": "sit", "paw": "paw", "lie_down": "down"}.get(id, "")
		if tutorial_id != "" and week.tutorial.get("arrival", {}).get("done", false) and not week.tutorial.get(tutorial_id, {}).get("done", false):
			week.tutorial.lesson = _trick_lesson.merged({"period": trick_lesson_period()})
			week.tutorial.resume = tutorial_id
			Events.week_tutorial_changed.emit()
		return {"points": points}
	week.tutorial.erase("lesson")
	var stars := 0
	for threshold: Variant in rules.star_points:
		stars += int(int(_trick_lesson.points) >= int(threshold))
	_trick_lesson.clear()
	var items := trick_lesson_cookies()
	if items.is_empty() or not inventory.remove(items[0]):
		return {"error": "Falta Biscoito ×1"}
	var previous := trick_level(id)
	_count("trick:" + id, stars)
	_count("trick_lesson")
	var level := trick_level(id)
	var learned := previous == 0 and level > 0
	if learned:
		_record_trick_learned(id)
	if wish_id() == "train" and wish_error() == "":
		fulfill_wish()
	else:
		_changed()
	if learned:
		Events.trick_learned.emit(id)
	return {"points": points, "stars": stars, "level": level, "level_up": previous < level}


func learned_lesson_tricks() -> Array[String]:
	var learned: Array[String] = []
	for id: String in Database.progression.tricks:
		if trick_is_lesson(id) and bool(progress.tricks.get(id, false)):
			learned.append(id)
	return learned


## Oferta para o prato colocado na tigela, válida só para a janela atual.
func meal_trick_offer(item_id: String) -> Dictionary:
	var rules: Dictionary = Database.progression.trick_settings.meal
	var period := meal_period_now()
	if content_day() < int(rules.day) or period == "" or _forced_meal != "" or walking() or dog.sleeping:
		return {}
	if inventory.count(item_id) < 1 or meal_error(item_id) != "":
		return {}
	var learned := learned_lesson_tricks()
	if learned.is_empty():
		return {}
	var index := posmod((week_day() - int(rules.day)) * 2 + int(period == "dinner"), learned.size())
	return {"id": learned[index], "day": week_day(), "period": period, "item": item_id}


func trick_show_error(length: int) -> String:
	var rules: Dictionary = Database.progression.trick_settings.show
	if content_day() < int(rules.day):
		return "Continue a História"
	if has_upgrade("dairy"):
		return "O tapete deu lugar à queijaria"
	if walking(): return away_text()
	if dog.sleeping: return "Shh... ele está dormindo."
	if tiro_weak(): return "Ele quer comer primeiro"
	if int(week.last_trick_show_day) >= week_day():
		return "Já teve show hoje. Volte amanhã!"
	if learned_lesson_tricks().size() < int(rules.learned):
		return "Aprenda Senta, Dá a pata e Deita"
	if length < int(rules.min_length) or length > int(rules.max_length):
		return "Escolha de 3 a 5 truques"
	return ""


func start_trick_show(length: int) -> Dictionary:
	if not _trick_show.is_empty() or not _trick_lesson.is_empty():
		return {"error": "Já tem um treino ou show em andamento"}
	var error := trick_show_error(length)
	if error != "":
		return {"error": error}
	var learned := learned_lesson_tricks()
	var sequence: Array[String] = []
	for i in length:
		sequence.append(learned[i % learned.size()])
	_trick_show = {"sequence": sequence, "index": 0, "day": week_day(), "perfect": true}
	return {"sequence": sequence.duplicate()}


func cancel_trick_show() -> void:
	_trick_show.clear()


func trick_show_step(id: String, success: bool) -> Dictionary:
	if _trick_show.is_empty():
		return {"error": "O show ainda não começou"}
	var sequence: Array = _trick_show.sequence
	var index := int(_trick_show.index)
	var error := trick_show_error(sequence.size())
	if error != "" or int(_trick_show.day) != week_day():
		cancel_trick_show()
		return {"error": error if error != "" else "Comece o show de hoje"}
	if id != sequence[index] or not success:
		_trick_show.perfect = false
		return {"index": index, "retry": true}
	_trick_show.index += 1
	if index + 1 < sequence.size():
		return {"index": index + 1}
	var rules: Dictionary = Database.progression.trick_settings.show
	var perfect := bool(_trick_show.perfect) and sequence.size() == int(rules.max_length)
	cancel_trick_show()
	week.last_trick_show_day = week_day()
	for used: String in sequence:
		_count("trick_show_use:" + used)
	_count("trick_show")
	var coins := int(rules.rewards.coins)
	_grant_automatic("trick_show:%d" % week_day(), rules.rewards)
	var biscuits := 0
	if perfect:
		_count("trick_show_perfect")
		if _grant_automatic("trick_show_perfect", rules.perfect_rewards).paid:
			biscuits = int(rules.perfect_rewards.items.apple_biscuit)
	var photos := _album_event("trick_show", {"world": "farm"})
	_changed()
	return {"coins": coins, "biscuits": biscuits, "photo": not photos.is_empty()}


func trick_available_error(id: String) -> String:
	if not Database.progression.tricks.has(id):
		return "Truque desconhecido"
	if walking():
		return away_text()
	if dog.sleeping:
		return "Shh... ele está dormindo."
	return requirement_error(Database.progression.tricks[id].get("requirements", {}))


func learn_trick_error(id: String) -> String:
	if trick_is_lesson(id):
		return "Aprenda na Aula do Tiro"
	var error := trick_available_error(id)
	if error != "":
		return error
	if bool(progress.tricks.get(id, false)):
		return "Truque já aprendido"
	if tiro_weak():
		return "Ele quer comer primeiro"
	for previous: String in Database.progression.tricks:
		if previous == id:
			break
		if trick_is_lesson(previous):
			continue
		if not bool(progress.tricks.get(previous, false)):
			return "Aprenda " + str(Database.progression.tricks[previous].name)
	return ""


func learn_trick(id: String) -> String:
	var error := learn_trick_error(id)
	if error != "":
		return error
	_record_trick_learned(id)
	_changed()
	Events.trick_learned.emit(id)
	return ""


func _record_trick_learned(id: String) -> void:
	progress.tricks[id] = true
	_count("trick_learned")
	_count("trick_learned:" + id)
	_moment_source("learn_trick", id)
	_album_event("trick_learned", {"trick": id})


func perform_trick_error(id: String) -> String:
	if trick_is_lesson(id):
		return "Pratique na Aula do Tiro"
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

func feed(item_id: String, trick_offer: Dictionary = {}) -> bool:
	var useful := _need_is_low("hunger")
	var effects: Dictionary = Database.items.get(item_id, {}).get("feed", {})
	if (walking() and _forced_meal == "") or effects.is_empty() or inventory.count(item_id) < 1:
		return false
	var trick := str(trick_offer.id) if not trick_offer.is_empty() and trick_offer == meal_trick_offer(item_id) else ""
	var meal_before: Dictionary = {}
	for row: Dictionary in growth_info().requirements:
		# Só a refeição que esta comida alimenta (a papinha de peixe não é a cenoura gelada).
		if row.type == "feed" and not row.done and str(row.get("item", "")) in [item_id, "any", "favorite"]:
			meal_before = row
	var body_before := growth.body_level
	inventory.remove(item_id)
	dog.apply(effects, now())
	_register_meal(item_id, trick)
	if week.weak and is_meal_item(item_id) and food_lesson_done():
		# Qualquer refeição (mesmo fora da hora) tira o fraquinho: o dia fraco nunca trava aulas por horas.
		week.weak = false
		Events.toast_requested.emit("O Tiro ficou forte de novo!")
	if not is_meal_item(item_id) and food_lesson_done() and not progress.seen.has("snack_note"):
		progress.seen["snack_note"] = true  # primeira vez que ele ganha um lanche: ele não conta como refeição
		Events.toast_requested.emit(str(Database.week_story.get("food_lesson", {}).get("snack", "")))
	_count("feed")
	_count("feed:" + item_id)
	growth.firsts["food:" + item_id] = true
	_note_fed_dish(item_id)
	_taste(item_id)
	_album_event("fed", {"item": item_id, "growth_food": Database.items.get(item_id, {}).has("growth")})
	_care_useful("feed", useful)
	_care_reward("feed", useful)
	if item_id == "herb_fish":
		_moment_source("herb_fish")  # o ômega-3 deixa o pelo brilhante: 1 momento de Pelagem (com teto)
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


func yard_rules() -> Dictionary:
	return Database.growth.week_play


func yard_open(kind: String) -> bool:
	return content_day() >= int(yard_rules().days.get(kind, 999999))


func yard_error(kind: String) -> String:
	if kind not in ["ball", "rope", "name", "hide"]: return "Brincadeira desconhecida."
	if not yard_open(kind): return "Continue a História"
	if walking(): return away_text()
	if dog.sleeping: return "Shh... ele está dormindo."
	return ""


func _yard_period() -> String:
	return moment_period(week_now())


func yard_rewards_left(kind: String) -> int:
	var used := int(week.play.get("used", {}).get(_yard_period(), {}).get(kind, 0))
	return maxi(0, int(yard_rules().limit) - used)


func yard_record() -> int:
	return int(week.play.get("best", 0))


func start_yard_round(kind: String) -> Dictionary:
	var error := yard_error(kind)
	if error != "": return {"error": error}
	if not _yard_round.is_empty(): return {"error": "Termine a brincadeira aberta."}
	_yard_serial += 1
	var variant_day := {"fetch": yard_open("fetch"), "squeak": yard_open("squeak") and inventory.count("squeaky_ball") > 0, "lake": yard_open("lake")}
	_yard_round = {
		"id": _yard_serial, "kind": kind, "variant": variant_day, "turn": 0, "score": 0,
		"landing": {}, "hold_at": -1.0, "hideout": randi_range(0, yard_rules().hideouts.size() - 1),
		"since": _yard_seconds(),
	}
	return _yard_round.duplicate(true)


func cancel_yard_round(id: int) -> void:
	if _yard_round.get("id") == id:
		_yard_round.clear()


func _yard_valid(id: int, kind: String) -> bool:
	return _yard_round.get("id") == id and _yard_round.get("kind") == kind and yard_error(kind) == ""


func _yard_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0


func yard_flight(id: int, drag: Vector2) -> Dictionary:
	if _yard_round.get("id") != id or not drag.is_finite(): return {}
	var launch: Dictionary = yard_rules().launch
	var origin := Vector2(float(launch.origin[0]), float(launch.origin[1]))
	var variant_day: Dictionary = _yard_round.variant
	if drag.length() < 0.025:
		if variant_day.fetch: return {}
		drag = Vector2(float(launch.tap[0]), float(launch.tap[1]))
	if drag.y > -0.02: return {}
	var reach := float(launch.squeak_range if variant_day.squeak else launch.range)
	var end := (origin + drag.limit_length(float(launch.drag)) * reach / float(launch.drag)).clamp(Vector2(0.06, 0.09), Vector2(0.94, 0.79))
	var bridge: Array = yard_rules().bridge
	var bridge_rect := Rect2(bridge[0], bridge[1], bridge[2], bridge[3])
	var bounce := bool(variant_day.lake) and bridge_rect.has_point(end)
	var point := end + Vector2(0, -0.15) if bounce else end
	return {"end": point, "bounce": bounce, "bridge": end}


func yard_throw(id: int, drag: Vector2) -> Dictionary:
	if not _yard_valid(id, "ball") or not _yard_round.landing.is_empty(): return {}
	var flight := yard_flight(id, drag)
	if flight.is_empty(): return {}
	var base := 0
	var hit := ""
	var label := "Tiro foi atrás da bolinha!"
	if _yard_round.variant.fetch:
		for band: float in yard_rules().bands:
			if flight.end.y <= band: base += 1
		for target: Dictionary in yard_rules().targets:
			var at := Vector2(float(target.at[0]), float(target.at[1]))
			if at.distance_to(flight.end) > float(target.radius): continue
			hit = str(target.id)
			label = str(target.label)
			base = int(target.get("points", base))
			break
		if flight.bounce: label = "A bolinha quicou na ponte!"
	var landing := flight.merged({"base": base, "hit": hit, "label": label, "since": _yard_seconds()})
	_yard_round.landing = landing
	return landing.duplicate()


func yard_jump_elapsed(id: int) -> float:
	if _yard_round.get("id") != id or _yard_round.landing.is_empty(): return -1.0
	return _yard_seconds() - float(_yard_round.landing.since)


func yard_finish_throw(id: int, jump: bool) -> Dictionary:
	if not _yard_valid(id, "ball") or _yard_round.landing.is_empty(): return {}
	var elapsed := yard_jump_elapsed(id)
	var timing: Dictionary = yard_rules().jump
	var fetching := bool(_yard_round.variant.fetch)
	if jump and (not fetching or elapsed < float(timing.opens) or elapsed > float(timing.closes)):
		return {}
	if not jump and elapsed < (float(timing.closes) if fetching else float(timing.opens)):
		return {}
	var landed: Dictionary = _yard_round.landing
	var points := int(landed.base) * (int(timing.multiplier) if jump else 1)
	_yard_round.score += points
	_yard_round.turn += 1
	_yard_round.landing = {}
	var result := {"score": _yard_round.score, "turn": _yard_round.turn, "points": points, "jump": jump, "hit": landed.hit, "label": landed.label}
	if int(_yard_round.turn) == int(yard_rules().throws):
		result.merge(_finish_yard_round())
	return result


func yard_rope_hold(id: int) -> bool:
	if not _yard_valid(id, "rope") or float(_yard_round.hold_at) >= 0.0: return false
	_yard_round.hold_at = _yard_seconds()
	return true


func yard_rope_elapsed(id: int) -> float:
	if _yard_round.get("id") != id or float(_yard_round.hold_at) < 0.0: return -1.0
	return _yard_seconds() - float(_yard_round.hold_at)


func yard_rope_release(id: int, canceled: bool = false) -> Dictionary:
	if not _yard_valid(id, "rope"): return {}
	var elapsed := yard_rope_elapsed(id)
	if elapsed < 0.0: return {}
	var timing: Dictionary = yard_rules().rope
	if canceled or elapsed < 0.2:
		_yard_round.hold_at = -1.0
		return {}
	var hit := elapsed >= float(timing.opens) and elapsed <= float(timing.closes)
	_yard_round.score += int(hit)
	_yard_round.turn += 1
	_yard_round.hold_at = -1.0
	var result := {"hit": hit, "score": _yard_round.score, "turn": _yard_round.turn}
	if int(_yard_round.turn) == int(yard_rules().pulls):
		result.merge(_finish_yard_round())
	return result


func yard_find(id: int, spot: int) -> Dictionary:
	if not _yard_valid(id, "hide") or spot < 0 or spot >= yard_rules().hideouts.size():
		return {}
	if _yard_seconds() - float(_yard_round.since) < 1.1: return {}
	if spot != int(_yard_round.hideout): return {"found": false}
	var result := _finish_yard_round()
	result.found = true
	return result


func yard_answer_name(id: int) -> Dictionary:
	if not _yard_valid(id, "name") or _yard_seconds() - float(_yard_round.since) < 0.75:
		return {}
	return _finish_yard_round()


func _finish_yard_round() -> Dictionary:
	var kind := str(_yard_round.kind)
	var score := int(_yard_round.score)
	var squeak := bool(_yard_round.variant.squeak)
	_yard_round.clear()
	var left := yard_rewards_left(kind)
	var result := {"done": true, "rewarded": left > 0, "happiness": 0, "smart": 0, "coins": 0}
	if left > 0:
		var periods: Dictionary = week.play.get_or_add("used", {})
		var period := _yard_period()
		var oldest := Time.get_date_string_from_unix_time(_local_time(week_now()) - 86400)
		for key: String in periods.keys():
			if key < oldest: periods.erase(key)
		var usage: Dictionary = periods.get_or_add(period, {})
		usage[kind] = int(yard_rules().limit) - left + 1
		if kind == "name":
			_count("name_call")
		else:
			var happiness := int(yard_rules().happiness["squeak" if kind == "ball" and squeak else kind])
			var before := dog.get_need("happiness", now())
			dog.apply({"happiness": happiness}, now())
			result.happiness = roundi(dog.get_need("happiness", now()) - before)
			_care_useful("play", before < float(Database.needs.happiness.get("ask_below", 50)) and int(result.happiness) > 0)
			result.smart = _gain_moment("smart", "hide" if kind == "hide" else "play", true, true)
			_count("play")
			_count("yard:" + kind)
			if kind == "rope": _count("play_rope")
			if kind == "hide":
				_count("hide")
				_count("hide_found")
			_album_event("played")
	if kind == "ball":
		var day := maxi(week.high_day, week_day_number())
		var daily: Dictionary = week.play.get("daily", {})
		if day > int(daily.get("day", -1)):
			daily = {"day": day, "score": 0, "paid": false}
			week.play.daily = daily
		week.play["best"] = maxi(yard_record(), score)
		if day == int(daily.day) and score > int(daily.score):
			daily.score = score
			if left > 0 and not daily.paid:
				var payout := int(yard_rules().record_coins)
				daily.paid = true
				coins += payout
				result.coins = payout
		result.record = yard_record()
	_changed()
	return result


func _care_moment_info(pillar: String, action: String, need: String) -> Dictionary:
	var asking := _need_is_low(need)
	var left := maxi(0, int(Database.growth.moments.period_cap) - int(growth.period_moments.get(moment_period() + ":" + pillar, 0)))
	var hint := action + (" pode render um momento." if asking else ": ele está satisfeito.")
	if _moments_uncapped(): left = 99
	if left == 0: hint ="Momentos deste período completos. Conheça novidades ou volte no próximo período."
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


func bath_shampoo() -> String:
	return "puppy_shampoo" if inventory.count("puppy_shampoo") > 0 else "herb_shampoo"


func bathe(with_shampoo: bool = false) -> bool:
	var shampoo := bath_shampoo() if with_shampoo else ""
	if walking() or (with_shampoo and inventory.count(shampoo) < 1):
		return false
	var useful := _need_is_low("hygiene")
	if with_shampoo: inventory.remove(shampoo)
	dog.apply(Database.actions.get("bathe", {}), now())
	_count("bathe")
	_album_event("bathed")
	var useful_bath := _care_useful("bathe", useful)
	if shampoo == "puppy_shampoo":
		_moment_source("puppy_shampoo_bath")
	elif useful_bath:
		_moment_source("shampoo_bath" if with_shampoo else "bath")
	if with_shampoo: _count("shampoo_bath")
	_care_reward("bathe", useful)
	_changed()
	Events.dog_action.emit(&"bathe")
	return true


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
	return maxi(result, int(chef_info().get("slots", 0))) if id == "stove" else result


## Coloca uma receita na fila. Retorna "" se deu certo ou o motivo da falha.
func cook(recipe_id: String) -> String:
	return cook_many(recipe_id, 1)


## Prepara N lotes iguais de uma vez (Etapa 12): cada um é um trabalho próprio na fila, com os
## ingredientes e o snapshot dele, começando quando o anterior termina. Tudo ou nada: se faltar
## vaga ou ingrediente para qualquer um dos N, nada é consumido nem enfileirado.
func cook_many(recipe_id: String, count: int, stars: int = 1, together: bool = false) -> String:
	var error := cook_many_error(recipe_id, count)
	if error != "":
		return error
	var recipe: Dictionary = Database.recipes[recipe_id]
	var station_id: String = recipe.station
	var animal: bool = Database.stations[station_id].get("kind", "") == "animal"
	var target := station(station_id)
	var paid := recipe_inputs(recipe_id)
	var tracked := station_id == "stove" and not bool(recipe.get("hidden", false))
	for i in count:
		var mastery := _recipe_preparation("recipe:" + recipe_id, stars, together) if tracked else {}
		var seconds := recipe_seconds(recipe_id) * float(mastery.get("time", 1.0))
		var qty := recipe_quantity(recipe_id) + int(mastery.get("gift", 0))
		inventory.remove_all(paid)
		target.enqueue(recipe_id, seconds, now())
		target.queue.back()["qty"] = qty
		var job := WorkJobs.batch(recipe_id, Database.recipes, Database.xp, Database.stations, qty, paid)
		job["seconds"] = seconds
		var secret := secret_config()
		if not secret.is_empty() and str(job.get("output", "")) == str(secret.stew) \
				and not (together and stars >= int(secret.stew_stars)):
			job["output"] = str(secret.stew_fallback)  # só o Cozinhar junto com 3 estrelas faz o Ensopado Dourado
			Events.toast_requested.emit(str(secret.fallback_text))
		if tracked:
			job["dish"] = {"stars": mastery.stars, "gift": mastery.gift, "specialty": mastery.specialty}
			_note_recipe(recipe_id, int(mastery.stars))
			if together:
				_count("together:" + recipe_id)
			if int(mastery.stars) >= 3:
				_count("week_three_stars")
			_record_recipe_preparation("recipe:" + recipe_id, mastery)
			var fixed := dish_of_item(str(job.output))
			var book_key := "dish:" + str(fixed.get("key", ""))
			if not fixed.is_empty():
				var fresh := int(dish_record("recipe:" + recipe_id).get("made", 0)) == 1 and not week.dishes.has(book_key)
				_note_daily_ingredient(fixed.ingredients, fresh)
				_note_routine_cooked(str(fixed.type), fixed.ingredients, int(mastery.stars))
		target.queue.back()["job"] = job
		if animal:
			target.queue.back()["animals"] = animal_roster(station_id)
	_changed()
	if animal:
		Events.world_activity.emit(&"feed_animal", station_id, -1)
	return ""


## Aba Inventar do fogão: receita do fogão (já liberada) cujos ingredientes são EXATAMENTE os escolhidos
## (multiconjunto {item: quantidade}); "" se nenhuma bate. Consulta pura.
func invent_match(chosen: Dictionary) -> String:
	if chosen.is_empty():
		return ""
	for id in Database.recipes_for("stove"):
		var recipe: Dictionary = Database.recipes[id]
		if Database.recipe_unique(recipe) or content_error("recipe", id, recipe) != "":
			continue
		var inputs := recipe_inputs(id)
		if inputs.size() != chosen.size():
			continue
		var same := true
		for item_id: String in inputs:
			if int(chosen.get(item_id, 0)) != int(inputs[item_id]):
				same = false
				break
		if same:
			return id
	return ""


## Consulta pura de `cook_invented`: "" ou o motivo (sem fogão, tipo fechado, regra do prato, fila cheia, falta ingrediente).
func cook_invented_error(chosen: Dictionary, type_id: String) -> String:
	if not has_upgrade("stove"):
		return "Abra o fogão pela História"
	if not invent_open():
		return "Continue a História"
	var recipe_id := dish_recipe_match(type_id, chosen)
	if recipe_id != "" and dish_plan(type_id, _expand_picks(chosen)).error == "":
		return cook_many_error(recipe_id, 1)
	return cook_dish_error(type_id, _expand_picks(chosen))


## Aba Inventar do fogão: cozinha o prato do tipo escolhido pelo motor de pratos (`DishRules`). Se a combinação é a de uma
## receita fixa do fogão do mesmo tipo (p. ex. a papinha de cenoura e batata), faz essa receita, para os pedidos e o
## crescimento que contam o item dela continuarem valendo. Devolve "" ou o motivo.
func cook_invented(chosen: Dictionary, type_id: String, stars: int = 1, together: bool = false) -> String:
	var error := cook_invented_error(chosen, type_id)
	if error != "":
		return error
	var picks := _expand_picks(chosen)
	var plan := dish_plan(type_id, picks)
	var recipe_id := dish_recipe_match(type_id, chosen)
	var key := dish_key(type_id, plan.ingredients)
	var novel: bool = plan.state == "dish" and not week.dishes.has(key) and (recipe_id == "" or not week.dishes.has("recipe:" + recipe_id))
	if recipe_id != "" and plan.state == "dish":
		error = cook_many(recipe_id, 1, stars, together)
	else:
		error = cook_dish(type_id, picks, stars, together)
	if error == "" and plan.state == "dish":
		_count("routine_invent")
		if novel:
			_count("week_invention")
		_changed()
	return error


## Receita fixa do fogão (já liberada) do MESMO tipo de prato cujos ingredientes são exatamente os escolhidos; "" se nenhuma.
func dish_recipe_match(type_id: String, chosen: Dictionary) -> String:
	var recipe_id := invent_match(chosen)
	if recipe_id != "" and str(Database.recipes[recipe_id].get("dish_type", "")) == type_id:
		return recipe_id
	return ""


# --- Motor de pratos (Primeira semana, E02) ---------------------------------------------------------------------
# Um prato é TIPO + INGREDIENTES + ESTRELAS e vira o item dinâmico `dish_<tipo>_<ingredientes>_<estrelas>`
# (ver `DishRules`). `Database.ensure_dish` registra o item quando ele entra no jogo; depois disso inventário,
# depósito, venda, Mochila e alimentação o tratam como qualquer item. Combinação que não forma o prato do tipo
# vira Gororoba (item fixo) e devolve 1 ingrediente.

## {item: quantidade} -> lista de itens (um por unidade), na ordem do dicionário.
func _expand_picks(chosen: Dictionary) -> Array:
	var picks: Array = []
	for item_id: String in chosen:
		for i in int(chosen[item_id]):
			picks.append(item_id)
	return picks


## Plano de um prato (consulta pura): {error, state, type, ingredients, stars, output, name, seconds, consume, refund}.
## `picks` = itens escolhidos, um por ingrediente (o mesmo item pode repetir). `error` vazio = dá para cozinhar
## (falta checar fogão, fila e estoque: `cook_dish_error`).
func dish_plan(type_id: String, picks: Array, stars: int = 1) -> Dictionary:
	var plan := {"error": "", "state": "", "type": type_id, "ingredients": [], "stars": clampi(stars, 1, 3), "output": "",
		"name": "", "seconds": 0.0, "consume": {}, "refund": {}}
	var def := DishRules.type_def(type_id)
	if def.is_empty():
		plan.error = "Prato desconhecido"
		return plan
	if picks.is_empty():
		plan.error = "Escolha ingredientes"
		return plan
	var ingredients: Array = []
	for pick: Variant in picks:
		var ingredient := DishRules.ingredient_of_item(str(pick))
		if ingredient == "":
			plan.error = "Ingrediente inválido"
			return plan
		ingredients.append(ingredient)
	var day := content_day()
	if DishRules.opens(type_id) > day:
		plan.error = "Continue a História"
		return plan
	if picks.size() > DishRules.max_count(type_id, day):
		plan.error = "Só cabem %d ingredientes" % DishRules.max_count(type_id, day)
		return plan
	var verdict := DishRules.evaluate(type_id, ingredients)
	plan.state = str(verdict.state)
	plan.ingredients = DishRules.canon(ingredients)
	if plan.state in ["incomplete", "invalid"]:
		plan.error = str(verdict.reason)
		return plan
	var consume := {}
	for pick: Variant in picks:
		consume[str(pick)] = int(consume.get(str(pick), 0)) + 1
	plan.consume = consume
	plan.seconds = float(def.get("seconds", 60))
	if plan.state == "gororoba":
		plan.output = str(Database.dishes.get("gororoba", {}).get("item", "gororoba"))
		plan.name = Database.item_name(plan.output)
		# Sem desperdício: volta o ingrediente que quebrou a regra (o último escolhido dessa família).
		var refund := {}
		var culprit := str(verdict.get("culprit", ""))
		for index in range(picks.size() - 1, -1, -1):
			if DishRules.ingredient_of_item(str(picks[index])) == culprit:
				refund[str(picks[index])] = int(Database.dishes.get("gororoba", {}).get("refund", 1))
				break
		if refund.is_empty() and bool(chef_info().get("save_ingredient", false)):
			refund[str(picks.back())] = 1
		plan.refund = refund
	else:
		plan.output = DishRules.make_id(type_id, ingredients, plan.stars)
		plan.name = DishRules.name_of(type_id, ingredients)
	return plan


## Motivo de não dar para cozinhar o prato agora ("" se dá): fogão, fila, regras do tipo e estoque.
func cook_dish_error(type_id: String, picks: Array, stars: int = 1) -> String:
	if not has_upgrade("stove"):
		return "Compre %s no seu lugar do mapa" % Database.stations.get("stove", {}).get("name", "o fogão")
	var plan := dish_plan(type_id, picks, stars)
	if plan.error != "":
		return str(plan.error)
	if station("stove").queue.size() >= station_slots("stove"):
		return "Fila cheia"
	if not inventory.has_all(plan.consume):
		return _missing_text(plan.consume, "Faltam ingredientes")
	return ""


## Cozinha o prato: gasta os ingredientes (menos o que volta, na Gororoba) e põe UM lote na fila do fogão pelo mesmo
## caminho do `cook_many` (snapshot do lote; `collect` entrega igual, com a saída guardada no `job`). Devolve ""
## ou o motivo. O lote conta como trabalho do fogão (maestria `station_jobs`).
func cook_dish(type_id: String, picks: Array, stars: int = 1, together: bool = false) -> String:
	var error := cook_dish_error(type_id, picks, stars)
	if error != "":
		return error
	var plan := dish_plan(type_id, picks, stars)
	var key := dish_key(type_id, plan.ingredients)
	var mastery := {}
	if str(plan.state) == "dish":
		mastery = _recipe_preparation(key, stars, together)
		plan.stars = mastery.stars
		plan.output = DishRules.make_id(type_id, plan.ingredients, int(plan.stars))
		plan.seconds = float(plan.seconds) * float(mastery.time)
	var recipe_id := Database.dish_recipe_id()
	if not Database.recipes.has(recipe_id) or not Database.ensure_dish(str(plan.output)):
		return "Receita desconhecida"
	var paid: Dictionary = (plan.consume as Dictionary).duplicate()
	for item_id: String in plan.refund:
		paid[item_id] = int(paid[item_id]) - int(plan.refund[item_id])
		if int(paid[item_id]) <= 0:
			paid.erase(item_id)
	var target := station("stove")
	inventory.remove_all(paid)
	target.enqueue(recipe_id, float(plan.seconds), now())
	var qty := 1 + int(mastery.get("gift", 0))
	var job := WorkJobs.batch(recipe_id, Database.recipes, Database.xp, Database.stations, qty, paid)
	job["output"] = str(plan.output)
	job["seconds"] = float(plan.seconds)
	job["dish"] = {"type": type_id, "stars": int(plan.stars), "state": str(plan.state), "gift": int(mastery.get("gift", 0)),
		"specialty": bool(mastery.get("specialty", false))}
	target.queue.back()["qty"] = qty
	target.queue.back()["job"] = job
	if str(plan.state) == "dish":
		_note_dish(type_id, plan.ingredients, int(plan.stars))
		_note_routine_cooked(type_id, plan.ingredients, int(plan.stars))
		if int(plan.stars) >= 3:
			_count("week_three_stars")
		_record_recipe_preparation(key, mastery)
	_changed()
	return ""


# --- Pratos conhecidos, prévia e estrelas (Primeira semana, E03) ------------------------------------------------
# O jogo lembra cada prato do motor (tipo + ingredientes, SEM estrelas) e cada receita fixa do fogão que já foi
# feita, com as melhores estrelas (1 por padrão; o minigame da E04 sobe até 3). O estado fica em `week.dishes`.

func dish_record(key: String) -> Dictionary:
	return week.dishes.get(key, {})


func dish_key(type_id: String, ingredients: Array) -> String:
	var key := DishRules.key_of(type_id, ingredients)
	return "dish:" + key if key != "" else ""


func dish_known(type_id: String, ingredients: Array) -> bool:
	return week.dishes.has(dish_key(type_id, ingredients))


## Melhores estrelas do prato (0 = nunca feito).
func dish_stars(type_id: String, ingredients: Array) -> int:
	return int(dish_record(dish_key(type_id, ingredients)).get("stars", 0))


## Estrelas da receita fixa do fogão (0 = nunca feita).
func recipe_stars(recipe_id: String) -> int:
	return int(dish_record("recipe:" + recipe_id).get("stars", 0))


## Pratos do motor já feitos, na ordem em que foram descobertos: [{key, type, ingredients, stars, made, day}].
func known_dishes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key: String in week.dishes:
		if not key.begins_with("dish:"):
			continue
		var parsed := DishRules.parse_key(key.substr(5))
		if parsed.is_empty():
			continue
		var record: Dictionary = week.dishes[key]
		result.append({"key": key, "type": parsed.type, "ingredients": parsed.ingredients, "stars": int(record.get("stars", 1)),
			"made": int(record.get("made", 1)), "day": int(record.get("day", 1))})
	return result


## Quantos pratos diferentes já foram feitos (de um tipo, ou de todos com `type_id` vazio).
func dishes_known_count(type_id: String = "") -> int:
	var total := 0
	for entry: Dictionary in known_dishes():
		if int(entry.made) > 0 and (type_id == "" or str(entry.type) == type_id):
			total += 1
	return total


func _note_dish(type_id: String, ingredients: Array, stars: int) -> void:
	var key := dish_key(type_id, ingredients)
	if key == "":
		return
	var fresh := _discover_book_dish(type_id, ingredients, "invent")
	var record := dish_record(key)
	record["stars"] = maxi(int(record.get("stars", 0)), clampi(stars, 1, 3))
	record["made"] = int(record.get("made", 0)) + 1
	week.dishes[key] = record
	_note_daily_ingredient(ingredients, fresh)


## Receita fixa do fogão preparada (uma vez por pedido de preparo).
func _note_recipe(recipe_id: String, stars: int = 1) -> void:
	var key := "recipe:" + recipe_id
	var record: Dictionary = week.dishes.get(key, {"stars": 0, "made": 0, "day": week_day()})
	record["stars"] = maxi(int(record.get("stars", 0)), clampi(stars, 1, 3))
	record["made"] = int(record.get("made", 0)) + 1
	week.dishes[key] = record


## Tipo está aberto no dia do jogo (`dishes.json → types.<tipo>.opens`).
func dish_type_open(type_id: String) -> bool:
	return DishRules.opens(type_id) <= content_day()


## Itens de inventário que pagam os ingredientes de um prato conhecido: de cada ingrediente, o item que mais tem
## (sem estoque, o item principal, para a lista mostrar o que falta).
func dish_inputs(ingredients: Array) -> Dictionary:
	var result := {}
	for ingredient_id: String in DishRules.canon(ingredients):
		var best := DishRules.main_item(ingredient_id)
		var best_left := -1
		for item: Variant in DishRules.ingredient(ingredient_id).get("items", []):
			var left := inventory.count(str(item)) - int(result.get(str(item), 0))
			if left > best_left:
				best_left = left
				best = str(item)
		result[best] = int(result.get(best, 0)) + 1
	return result


## "" ou o motivo de não dar para cozinhar de novo um prato já conhecido (chave de `known_dishes`).
func cook_known_dish_error(key: String) -> String:
	var parsed := DishRules.parse_key(key.trim_prefix("dish:"))
	if parsed.is_empty():
		return "Prato desconhecido"
	return cook_invented_error(dish_inputs(parsed.ingredients), str(parsed.type))


func cook_known_dish(key: String) -> String:
	var parsed := DishRules.parse_key(key.trim_prefix("dish:"))
	if parsed.is_empty():
		return "Prato desconhecido"
	return cook_invented(dish_inputs(parsed.ingredients), str(parsed.type))


## Prévia ao vivo do que está na panela (consulta pura). `state`: empty (nada), incomplete (faltam ingredientes),
## blocked (tipo fechado/regra), gororoba, new (prato novo!) ou known (já conhecido). Tem nome, item de saída,
## estrelas, nutrientes, se é refeição, notas de ingrediente-chave, o que volta (gororoba), tempo e o motivo.
func dish_preview(type_id: String, picks: Array) -> Dictionary:
	var preview := {"state": "empty", "type": type_id, "name": "", "output": "", "stars": 0, "nutrients": {}, "meal": false,
		"notes": [], "reason": "", "refund": {}, "counts_as": "", "seconds": 0.0, "recipe": ""}
	if picks.is_empty():
		return preview
	var plan := dish_plan(type_id, picks)
	preview.meal = DishRules.is_meal(type_id)
	if str(plan.error) != "":
		preview.state = "incomplete" if str(plan.state) == "incomplete" else "blocked"
		preview.reason = str(plan.error)
		return preview
	preview.output = str(plan.output)
	Database.ensure_dish(str(plan.output))  # o ícone e o nome do prato dinâmico dependem do registro
	preview.name = str(plan.name)
	preview.seconds = float(plan.seconds)
	if str(plan.state) == "gororoba":
		preview.state = "gororoba"
		preview.refund = plan.refund
		var ingredients: Array = []
		for pick: Variant in picks:
			ingredients.append(DishRules.ingredient_of_item(str(pick)))
		preview.reason = str(DishRules.evaluate(type_id, ingredients).get("reason", "Não forma o prato"))
		return preview
	var ingredients_list: Array = plan.ingredients
	var chosen := {}
	for pick: Variant in picks:
		chosen[str(pick)] = int(chosen.get(str(pick), 0)) + 1
	var recipe_id := dish_recipe_match(type_id, chosen)
	var stars := dish_stars(type_id, ingredients_list)
	if recipe_id != "":
		stars = maxi(stars, recipe_stars(recipe_id))
		preview.output = Database.recipe_output(Database.recipes[recipe_id])
		preview.seconds = float(Database.recipes[recipe_id].get("seconds", preview.seconds))
		preview.recipe = recipe_id
	var known := dish_known(type_id, ingredients_list) or stars > 0
	preview.state = "known" if known else "new"
	var named := DishRules.named(type_id, ingredients_list)
	if bool(named.get("secret", false)) and not known:
		preview.name = "Receita secreta"
		preview.output = DishRules.type_def(type_id).get("icon_item", "")
	var book_key := "recipe:" + recipe_id if recipe_id != "" else dish_key(type_id, ingredients_list)
	preview["mastery_key"] = book_key
	preview.seconds = float(preview.seconds) * float(recipe_mastery(book_key).time)
	preview.stars = maxi(stars, 1)
	preview.nutrients = DishRules.nutrients(type_id, ingredients_list, 1, growth.phase)
	preview.notes = DishRules.key_notes(type_id, ingredients_list)
	preview.counts_as = DishRules.counts_as(type_id, ingredients_list)
	return preview


## Prato pronto do Cozinhar junto. Recolhe o lote para oferecer na tigela.
func cook_plate_now(station_id: String, index: int) -> Dictionary:
	var queue := station(station_id).queue
	if index < 0 or index >= queue.size():
		return {"error": "Esse prato já saiu da fila"}
	if walking():
		return {"error": away_text()}
	if dog.sleeping:
		return {"error": "Shh... ele está dormindo."}
	var output := Database.entry_output(queue[index])
	queue[index]["ready_at"] = now()
	var got := collect(station_id)
	if int(got.get(output, 0)) < 1:
		return {"error": "Não coube na geladeira"}
	return {"item": output}


## Frase da prova do Tiro depois de comer `item` (a reação gravada em `growth.tastes`).
func taste_line(item: String) -> String:
	var name := Database.item_name(item)
	match str(growth.tastes.get(item, "")):
		"loved": return "Ele ama %s!" % name
		"liked": return "Ele gostou!"
		"odd": return "Hmm... tanto faz."
		"grimace": return "Eca! Mas foi engraçado."
	return ""


## Dados do prato de um item (`dish_...`): {type, ingredients, stars, name, meal, taste, nutrients (na fase atual)}; {} se não é prato.
func dish_info(item_id: String) -> Dictionary:
	var info := DishRules.parse(item_id)
	if info.is_empty():
		return {}
	var type := str(info.type)
	return {"type": type, "ingredients": info.ingredients, "stars": info.stars, "name": DishRules.name_of(type, info.ingredients),
		"meal": DishRules.is_meal(type), "taste": DishRules.taste(info.ingredients),
		"nutrients": DishRules.nutrients(type, info.ingredients, int(info.stars), growth.phase)}


## Registra os pratos dinâmicos que já estão nos lotes da fila (ao carregar o save; o inventário registra sozinho).
func _register_dishes() -> void:
	for id: String in stations:
		for entry: Dictionary in stations[id].queue:
			Database.ensure_dish(str(entry.get("job", {}).get("output", "")))


## DEV: um punhado de cada um dos 13 ingredientes (o primeiro item de cada). Devolve o aviso; "" fora da versão dev.
func dev_give_ingredients(each: int = 5) -> String:
	if not BuildInfo.is_dev(): return ""
	for ingredient: String in DishRules.order():
		inventory.add(DishRules.main_item(ingredient), each)
	_changed()
	return "13 ingredientes ×%d na Mochila" % each


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
	if Database.recipe_unique(recipe) or Database.stations[recipe.station].get("kind", "") == "animal":
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
	var seconds := recipe_seconds(recipe_id)
	if str(Database.recipes[recipe_id].station) == "stove":
		var key := "recipe:" + recipe_id
		var points := int(dish_record(key).get("points", 0))
		var rows: Array = Database.recipe_book.mastery
		for i in count:
			start += seconds * float(_recipe_tier(rows, points + i).time)
		return start
	return start + seconds * count


func recipe_seconds(recipe_id: String) -> float:
	var recipe: Dictionary = Database.recipes[recipe_id]
	if farm_week_active():
		if recipe.has("first_seconds") and week_day() <= int(Database.farm.early_through) and progress.stat("produce:" + Database.recipe_output(recipe)) == 0:
			return float(recipe.first_seconds)
		return float(recipe.get("week_seconds", recipe.seconds))
	return float(recipe.seconds)


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
	var rod := str(recipe.get("output_rod", ""))
	if count < 1:
		return "Escolha quantos"
	if rod != "":
		if fishing.has_rod(rod):
			return "Você já tem"
		for queue_state: StationState in stations.values():
			for entry: Dictionary in queue_state.queue:
				if str(Database.recipes.get(str(entry.recipe), {}).get("output_rod", "")) == rod:
					return "Já está sendo feita"
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
	if count > 1 and (animal or cosmetic != "" or rod != ""):
		return "Um por vez"
	if count > station_free_slots(station_id):
		return "Só cabem %d na fila" % station_free_slots(station_id)
	var needed := cook_inputs(recipe_id, count)
	if not inventory.has_all(needed):
		return _missing_text(needed, "Faltam ingredientes")
	return ""


## Coleta tudo o que está pronto na estação. Retorna os itens recebidos.
func collect(station_id: String) -> Dictionary:
	var specialty := false
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
		if bool(job.get("rod", false)):
			# Vara: sem item no inventário; entrega pela mesma regra da loja e das missões.
			if give_rod(output):
				_count("produce:" + output)
				_count("produce")
				_count("production_jobs")
				_discover("recipe:" + recipe_id, str(job.skill), int(job.skill_xp))
				_add_player_xp(int(job.player_xp))
				received[output] = 1
				Events.toast_requested.emit("Vara nova: %s!" % Database.item_name(output))
			continue
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
		specialty = specialty or bool(job.get("dish", {}).get("specialty", false))
		if output == "egg" and station_id == "chicken_coop":
			_recipe_source("eggs")
		_count("produce:" + output, qty)
		_count("produce", qty)
		var dish := dish_of_item(output)
		_link_key_quests(dish, output, "produce")
		if dish.get("type") == "biscoito" and "aveia" in dish.ingredients:
			_count("week_oat_biscuit", qty)
		if dish.get("type") == "sopinha":
			_count("week_soup", qty)
		_count("production_jobs")  # um lote = 1, mesmo que saiam 2 ou 3 unidades
		_count_station_job(station_id, recipe_id)
		_discover("recipe:" + recipe_id, str(job.skill), int(job.skill_xp))
		received[output] = int(received.get(output, 0)) + qty
		_add_player_xp(int(job.player_xp))
	if blocked != "":
		Events.toast_requested.emit(blocked)
	if not received.is_empty():
		_changed()
		if specialty:
			Events.world_activity.emit(&"specialty", station_id, -1)
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
		if Database.recipe_unique(recipe):
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
			if Database.recipe_unique(recipe):
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


func farm_week_active() -> bool:
	return growth.phase_index() < growth.phase_index("teething")


func animal_capacity(station_id: String) -> int:
	var data: Dictionary = Database.stations[station_id]
	if farm_week_active():
		return int(data.get("week_animal_capacity", data.animal_capacity))
	return int(data.animal_capacity)


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
	if animal_count(data.station) >= animal_capacity(data.station):
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
	var qty := int(recipe.get("qty", 1))
	return (int(recipe.get("week_qty", qty)) if farm_week_active() else qty) * factor


func recipe_inputs(recipe_id: String) -> Dictionary:
	var recipe: Dictionary = Database.recipes[recipe_id]
	var factor := animal_count(recipe.station) if Database.stations[recipe.station].get("kind", "") == "animal" else 1
	var inputs: Dictionary = recipe.get("inputs", {})
	if farm_week_active():
		inputs = recipe.get("week_inputs", inputs)
	var result := inputs.duplicate()
	for id: String in result:
		result[id] = int(result[id]) * factor
	return result


# --- Horta (sítio) ---------------------------------------------------------

func plot(index: int) -> Dictionary:
	_ensure_plots()
	return plots[index]


## Os canteiros da horta são sequenciais. O canteiro de milho vem junto com o galinheiro.
func accessible_plots() -> int:
	return mini(unlocked_plots, int(Database.farm.corn_plot)) + int(has_upgrade("chicken_coop"))


func plot_can_buy(index: int) -> bool:
	return ato2_done() and index >= unlocked_plots and index < int(Database.farm.corn_plot) and (
		index < int(Database.farm.week_extra_until) or has_upgrade("farm"))


func plot_open(index: int) -> bool:
	if index == int(Database.farm.corn_plot):
		return has_upgrade("chicken_coop")
	return index >= 0 and index < unlocked_plots


## Canteiros da estufa vêm depois dos do sítio (índices a partir de farm.plots) e só valem com a estufa comprada.
func is_greenhouse_plot(index: int) -> bool:
	return index >= int(Database.farm.get("plots", 0)) and index < int(Database.farm.get("plots", 0)) + int(Database.farm.get("greenhouse_plots", 0))


## Canteiros do sítio liberados + os da estufa (quando comprada), na ordem do jogo.
func usable_plot_indices() -> Array[int]:
	var result: Array[int] = []
	for i in mini(unlocked_plots, int(Database.farm.corn_plot)):
		result.append(i)
	if has_upgrade("chicken_coop"):
		result.append(int(Database.farm.corn_plot))
	if has_upgrade("greenhouse"):
		for i in int(Database.farm.get("greenhouse_plots", 0)):
			result.append(int(Database.farm.get("plots", 0)) + i)
	return result


## "locked", "empty", "growing" ou "ready".
func plot_status(index: int) -> String:
	if is_greenhouse_plot(index):
		if not has_upgrade("greenhouse"):
			return "locked"
	elif not plot_open(index):
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
	var crop: Dictionary = Database.crops.get(crop_id, {})
	var seconds := float(crop.get("seconds", 60))
	if week_day() <= int(Database.farm.early_through):
		seconds = float(crop.get("early_seconds", seconds))
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
	var seed := str(Database.week_routine.seed_items.get(crop_id, ""))
	if seed != "" and inventory.count(seed) > 0:
		inventory.remove(seed)
		plots[index].job["routine_seed_bonus"] = int(Database.week_routine.seed_bonus)
	_count("plant:" + crop_id)
	_changed()
	return ""


## Culturas com "greenhouse": "only" (delicadas) só crescem na estufa; "any" cresce nos dois (mais rápido na estufa).
func crop_plot_error(index: int, crop_id: String) -> String:
	if index == int(Database.farm.corn_plot) and crop_id != "corn":
		return "Este canteiro é para milho"
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
	# Minhoca na terra: só com a vara de bambu; mesma semente do plantio (recarregar não refaz o sorteio).
	if fishing.has_rod("bamboo_rod") and rng.randf() < float(Database.fishing.get("harvest_worm_chance", 0.0)):
		var with_worm := received.duplicate()
		with_worm["bait_worm"] = int(with_worm.get("bait_worm", 0)) + 1
		if storage_error(with_worm) == "":
			received = with_worm
			Events.toast_requested.emit("Achou uma minhoca!")
	var product_id := str(Database.crops[crop_id].get("item", crop_id))
	var seed_bonus := int(job.get("routine_seed_bonus", 0))
	var seed_pending := 0
	if seed_bonus > 0:
		var with_seed := received.duplicate()
		with_seed[product_id] = int(with_seed.get(product_id, 0)) + seed_bonus
		if storage_error(with_seed) == "":
			received = with_seed
		else:
			seed_pending = seed_bonus
	_count("routine_harvest", int(received.get(product_id, 0)))
	_count("harvest")
	_count("harvest:" + crop_id)
	_album_event("harvested", {"crop": crop_id})
	_discover("crop:" + crop_id, str(job.get("skill", "agriculture")), int(job.get("skill_xp", 10)))
	coins += int(job.get("coins", 0))
	for item_id: String in received:
		inventory.add(item_id, int(received[item_id]))
	if seed_pending > 0:
		_grant_automatic("week_seed:%s:%s" % [index, plot(index).get("planted_at", 0)], {"items": {product_id: seed_pending}})
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
	if index >= int(Database.farm.initial_plots) and index < int(Database.farm.week_extra_until):
		return int(shop_pack("week_plot").price)
	var costs: Array = Database.farm.get("unlock_costs", [])
	return int(costs[index]) if index >= 0 and index < costs.size() else -1


## Expansão em ordem fixa. Valida novamente no momento da compra.
func buy_plot(index: int) -> String:
	if index < 0 or index >= int(Database.farm.corn_plot):
		return "Terreno inválido"
	if index >= int(Database.farm.week_extra_until) and not has_upgrade("farm"):
		return "Compre a escritura do sítio primeiro"
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
	for id: String in rewards.get("upgrades", []):
		_grant_upgrade(id)
	for id: String in rewards.get("rods", []):
		give_rod(id)
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


# --- Lojas (banca da vovó, Feirante, pet shop): `progression.json → shops` e `shop_items` ---

## Motivo de a loja estar fechada ("" = aberta). Pet shop também exige a construção.
func shop_error(shop_id: String) -> String:
	var shop: Dictionary = Database.shop(shop_id)
	if shop.is_empty():
		return "Loja desconhecida"
	if shop_id == "petshop" and not has_upgrade("petshop"):
		return "Monte o pet shop"
	return requirement_error(shop.get("requirements", {}))


## Pacotes da loja: os revelados (requisitos ok) na ordem do JSON, mais UM bloqueado como dica.
func shop_items(shop_id: String) -> Array[String]:
	var result: Array[String] = []
	if shop_error(shop_id) != "":
		return result
	var hinted := false
	var items: Dictionary = Database.progression.get("shop_items", {})
	for id: String in items:
		if str(items[id].get("shop", "")) != shop_id:
			continue
		if _shop_pack_owned(id, items[id]):
			continue
		if shop_item_locked(id) == "":
			result.append(id)
		elif not hinted:
			hinted = true
			result.append(id)
	return result


## Pacote ainda não liberado (só dica na banca).
func shop_item_locked(id: String) -> String:
	return requirement_error(Database.progression.get("shop_items", {}).get(id, {}).get("requirements", {}))


func _shop_pack_owned(id: String, data: Dictionary) -> bool:
	if data.has("crop") and content_error("crop", str(data.crop), Database.crops[str(data.crop)]) == "":
		return true
	if data.get("plot", false):
		return unlocked_plots >= int(Database.farm.week_extra_until)
	var upgrade := str(data.get("upgrade", ""))
	if progress.collection.has(str(data.get("collection", ""))):
		return true
	return (upgrade != "" and has_upgrade(upgrade)) or (data.get("unique", false) and progress.stat("buy:" + id) > 0)


func _shop_today(shop_id: String = "") -> int:
	if shop_id == "week_cart":
		return cart_day()
	return maxi(int(floor(_local_time() / 86400.0)), progress.shop_day_max)


## Pacote como vale AGORA. Pacote com `rotation` (oferta do dia) devolve a entrada do dia — escolhida pelo dia local e
## pela semente do Tiro, pulando as entradas cujos requisitos ainda não valem — por cima dos campos do pacote.
func shop_pack(id: String) -> Dictionary:
	var data: Dictionary = Database.progression.get("shop_items", {}).get(id, {})
	var rotation: Array = data.get("rotation", [])
	if rotation.is_empty():
		return data
	var start := (_shop_today(str(data.shop)) + absi(hash(str(growth.taste_seed)))) % rotation.size()
	for step in rotation.size():
		var entry: Dictionary = rotation[(start + step) % rotation.size()]
		if requirement_error(entry.get("requirements", {})) == "":
			var merged: Dictionary = data.duplicate()
			merged.erase("rotation")
			merged.erase("requirements")
			merged["requirements"] = data.get("requirements", {})
			for key: String in entry:
				if key != "requirements":
					merged[key] = entry[key]
			return merged
	return data


## Quantos ainda hoje (-1 = sem limite).
func shop_daily_left(id: String) -> int:
	var data: Dictionary = Database.progression.get("shop_items", {}).get(id, {})
	if not data.has("daily"):
		return -1
	var entry: Dictionary = progress.shop_daily.get(id, {})
	var used := int(entry.get("n", 0)) if int(entry.get("day", -1)) == _shop_today(str(data.shop)) else 0
	return maxi(0, int(data.daily) - used)


## Maior quantidade que dá para comprar agora (0 = nenhuma).
func shop_max_qty(id: String) -> int:
	var data: Dictionary = shop_pack(id)
	if data.is_empty():
		return 0
	var best := int(data.get("max", 10))
	var left := shop_daily_left(id)
	if left >= 0:
		best = mini(best, left)
	best = mini(best, coins / maxi(1, int(data.price)))
	while best > 0 and (storage_error(_pack_items(data, best)) != "" or not inventory.has_all(_pack_materials(data, best))):
		best -= 1
	if best > 0 and buy_shop_item_error(id, best) == "Você já tem":
		return 0
	return best


func _pack_items(data: Dictionary, qty: int) -> Dictionary:
	var result := {}
	for item: String in data.get("items", {}):
		result[item] = int(data.items[item]) * qty
	return result


## Materiais cobrados junto com o preço (vara de molinete: fibras).
func _pack_materials(data: Dictionary, qty: int) -> Dictionary:
	var result := {}
	for item: String in data.get("materials", {}):
		result[item] = int(data.materials[item]) * qty
	return result


func buy_shop_item_error(id: String, qty: int = 1) -> String:
	var data: Dictionary = shop_pack(id)
	if data.is_empty():
		return "Produto desconhecido"
	var closed := shop_error(str(data.get("shop", "")))
	if closed != "":
		return closed
	var locked := requirement_error(data.get("requirements", {}))
	if locked != "":
		return locked
	if qty < 1 or qty > int(data.get("max", 10)):
		return "Quantidade inválida"
	var left := shop_daily_left(id)
	if left == 0:
		return "Volta amanhã"
	if left >= 0 and qty > left:
		return "Só mais %d hoje" % left
	var rods: Array = data.get("rods", [])
	if not rods.is_empty() and rods.all(func(rod: Variant) -> bool: return fishing.has_rod(str(rod))):
		return "Você já tem"
	if _shop_pack_owned(id, data):
		return "Você já tem"
	var cost := int(data.price) * qty
	if coins < cost:
		return "Faltam %d moedas" % (cost - coins)
	var materials := _pack_materials(data, qty)
	if not inventory.has_all(materials):
		return _missing_text(materials, "Faltam materiais")
	return storage_error(_pack_items(data, qty))


func buy_shop_item(id: String, qty: int = 1, expected_day: int = -1) -> String:
	if expected_day >= 0 and expected_day != cart_day():
		return "A oferta de hoje mudou"
	var error := buy_shop_item_error(id, qty)
	if error != "":
		return error
	var data: Dictionary = shop_pack(id)
	coins -= int(data.price) * qty
	if data.get("plot", false):
		unlocked_plots += 1
	inventory.remove_all(_pack_materials(data, qty))
	if data.has("purchase_rewards"):
		_grant_automatic("purchase:" + id, data.purchase_rewards)
	_apply_shop_pack(id, data, qty)
	return ""


func _apply_shop_pack(id: String, data: Dictionary, qty: int) -> void:
	var upgrade := str(data.get("upgrade", ""))
	if upgrade != "":
		_build_upgrade(upgrade)
	if data.has("crop"):
		progress.unlocks["crop:" + str(data.crop)] = true
	var gained := _pack_items(data, qty)
	for item: String in gained:
		inventory.add(item, int(gained[item]))
		_count("bought:" + item, int(gained[item]))
	for rod: String in data.get("rods", []):
		give_rod(rod)
	var collection := str(data.get("collection", ""))
	if collection != "":
		progress.collection[collection] = true
	_count("bought_shop:" + str(data.shop), qty)
	_count("buy:" + id, qty)
	if data.has("daily"):
		var today := _shop_today(str(data.shop))
		if data.shop == "week_cart":
			_week_touch()
		else:
			progress.shop_day_max = today
		var entry: Dictionary = progress.shop_daily.get(id, {})
		var used := int(entry.get("n", 0)) if int(entry.get("day", -1)) == today else 0
		progress.shop_daily[id] = {"day": today, "n": used + qty}
	_changed()
	if not gained.is_empty():
		Events.items_gained.emit(gained, 0, Vector2(-1, -1))
	if upgrade != "":
		Events.world_activity.emit(&"build", upgrade, -1)


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
		"week_challenge":
			return "Desafio do dia %d" % number
		"purchase":
			return str(shop_pack(auto_id.trim_prefix("purchase:")).get("name", "Compra na banca"))
		"level":
			return "Nível %d" % number
		"chapter":
			var chapters: Array = Database.progression.get("chapters", [])
			return str(chapters[number - 1].name) if number >= 1 and number <= chapters.size() else "Capítulo %d" % number
		"customer":
			return str(Database.npcs.get(auto_id.get_slice(":", 1), {}).get("name", auto_id.get_slice(":", 1)))
		"project":
			return "Projeto da vila"
		"album":
			return "Álbum de fotos"
		"fish_chest":
			return "Baú da lagoa"
		"week_bait":
			return "Iscas da vovó"
		"week_daily":
			return str(Database.week_routine.daily.get(auto_id.get_slice(":", 2), {}).get("label", Database.week_routine.text.list))
		"week_line":
			return str(_week_line_definition(auto_id.get_slice(":", 1)).get("name", Database.week_routine.text.open_lines))
		"week_seed":
			return str(Database.week_routine.text.seed) % int(Database.week_routine.seed_bonus)
		"trick_show", "trick_show_perfect":
			return "Show de truques"
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
	if requirements.has("story_day") and content_day() < int(requirements.story_day):
		return "Continue a História"
	if requirements.has("album_photo") and not album.has_photo(str(requirements.album_photo)):
		return "No Dia do Tiro"
	if requirements.has("rod") and not fishing.has_rod(str(requirements.rod)):
		return "Ganhe a " + str(Database.fishing.get("rods", {}).get(str(requirements.rod), {}).get("name", requirements.rod)).to_lower()
	if requirements.has("fishing_level") and fishing_level() < int(requirements.fishing_level):
		return "Pesca nível %d" % int(requirements.fishing_level)
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
	if data.has("kit"):
		var kit_error := requirement_error(data.get("requirements", {}))
		return kit_error if kit_error != "" else "Compre o kit na banca da vovó"
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
	_build_upgrade(id)
	_changed()
	Events.world_activity.emit(&"build", id, -1)
	return ""


func _build_upgrade(id: String) -> void:
	var data: Dictionary = Database.progression.upgrades[id]
	_grant_upgrade(id)
	_apply_rewards({"skill_xp": data.get("skill_xp", {})})
	_count("build")
	_add_player_xp(int(data.get("player_xp", 10)))


func _grant_upgrade(id: String) -> void:
	if has_upgrade(id):
		return
	progress.owned[id] = true
	var data: Dictionary = Database.progression.upgrades[id]
	var gift: String = data.get("gift_animal", "")
	if Database.animals.has(gift):
		var station_id: String = Database.animals[gift].station
		var amount := mini(int(data.get("gift_animal_count", 1)), animal_capacity(station_id) - animal_count(station_id))
		if amount > 0:
			animals[gift] = int(animals.get(gift, 0)) + amount
	if data.has("nature_unlock"):
		var site: String = data.nature_unlock.site
		var target := int(data.nature_unlock.level) - 1
		progress.nature_xp[site] = maxi(int(progress.nature_xp.get(site, 0)), int(Database.progression.nature_sites[site].levels[target].xp))
	for site: String in Database.progression.nature_sites:
		_sync_nature_unlocks(site)


# --- Feira (venda direta e encomendas) --------------------------------------------

func sale_price(item_id: String, world_id: String = "") -> int:
	var price := int(Database.items.get(item_id, {}).get("sell_price", 0))
	if world_id == "farm" and farm_week_active():
		return int(Database.farm.week_sell_prices.get(item_id, price))
	return price


func sell(item_id: String, amount: int = 1, world_id: String = "") -> String:
	if world_id not in ["", "farm", "village"]:
		return "Lugar de venda desconhecido"
	if world_id != "":
		var reason := requirement_error(Database.worlds[world_id].get("requirements", {}))
		if reason != "": return reason
	var price := sale_price(item_id, world_id)
	if amount <= 0 or price <= 0:
		return "Venda inválida"
	if not inventory.remove(item_id, amount):
		return "Você não tem essa quantidade"
	coins += price * amount
	_count("trade")
	_count("sold", amount)
	if world_id != "":
		_count("sold:" + world_id, amount)
		_count("sold:%s:%s" % [world_id, item_id], amount)
	_award_skill("commerce", int(Database.items[item_id].get("trade_xp", 1)) * amount)
	_changed()
	return ""


func cart_day() -> int:
	return maxi(week_day_number(), week.high_day)


func cart_order_ids() -> Array[String]:
	var ids: Array[String] = []
	if shop_error("week_cart") == "":
		var rotation: Array = Database.progression.cart_orders
		var first_day := int(Database.progression.get("cart_rotation_day", 5))  # só a fase da rotação; a carroça abre pelo capítulo
		var index := posmod(cart_day() - week.started_day + 1 - first_day, rotation.size())
		ids.assign(rotation[index])
	return ids


func cart_order_delivered(id: String) -> bool:
	return int(week.cart_deliveries.get(id, -1)) == cart_day()


func cart_order_offer(id: String) -> Dictionary:
	var order: Dictionary = Database.progression.cart_catalog.get(id, {})
	var trick := str(order.get("trick", ""))
	if trick == "" or trick not in learned_lesson_tricks() or walking() or dog.sleeping:
		return {}
	if order_error(id) != "":
		return {}
	return {"id": trick, "order": id, "day": cart_day(), "tip": int(order.tip)}


func _order_def(id: String) -> Dictionary:
	return Database.progression.orders.get(id, Database.progression.cart_catalog.get(id, {}))


func order_error(id: String) -> String:
	var order := _order_def(id)
	if order.is_empty():
		return "Pedido desconhecido"
	var reason := requirement_error(order.get("requirements", {}))
	if reason != "":
		return reason
	if Database.progression.cart_catalog.has(id):
		if id not in cart_order_ids(): return "Esse pedido ficou para outro dia"
		if cart_order_delivered(id): return "Já entregue"
	else:
		var wait := progress.cooldown_left("order:" + id, now())
		if wait > 0:
			return "Novo pedido em " + TimeText.short(wait)
	if not inventory.has_all(order.inputs):
		return _missing_text(order.inputs, "Faltam produtos")
	return storage_error(order.get("rewards", {}).get("items", {}), order.inputs)


func fulfill_order(id: String, offer: Dictionary = {}, expected_day: int = -1) -> String:
	if expected_day >= 0 and expected_day != cart_day():
		return "As encomendas de hoje mudaram"
	var reason := order_error(id)
	if reason != "":
		return reason
	var order := _order_def(id)
	if Database.progression.cart_catalog.has(id):
		# Confere o gesto antes de gravar o recibo. O pagamento e a baixa saem juntos.
		var tip := 0
		if not offer.is_empty() and offer == cart_order_offer(id):
			tip = int(offer.tip)
		_week_touch()
		week.cart_deliveries[id] = cart_day()
		coins += tip
		_count("cart_delivery")
		_recipe_source("cart")
		if tip > 0:
			_count("cart_tip")
	else:
		progress.cooldowns["order:" + id] = now() + float(order.get("cooldown", 0))
	inventory.remove_all(order.inputs)
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
		"week_plots":
			return unlocked_plots
		"week_delivered":
			return int(growth.delivered.get("teething", {}).get(goal.key, 0))
		"week_dish":
			return _growth_have({"type": "dish_key", "group": goal.key}, "teething") if growth.phase == "puppy" else 0
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
	note_recipe_hint(npc_id)
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


## Passos com "auto_claim": true (sem prêmio, como dar banho, ir ao Sítio, conhecer a vovó) se entregam sozinhos
## assim que ficam prontos: não há Pegar. A folha "Passo concluído" com o próximo destino continua, a não ser
## com "claim_sheet": false (a conversa da vovó já leva adiante). Chamado no começo de `_changed`.
func _auto_claim_quests() -> void:
	for _i in 8:
		var done := false
		for id: String in progress.active_steps().values():
			if Database.quests[id].get("auto_claim", false) and quest_error(id) == "":
				inventory.remove_all(_quest_deliveries(id))
				_finish_quest(id)
				var npc_id: String = Database.quests[id].get("npc", "")
				for next: String in progress.active_steps().values():
					if npc_id != "" and Database.quests[next].get("npc", "") == npc_id:
						progress.seen["quest:" + next] = true
				_sync_shared_quests()
				done = true
				break
		if not done:
			return


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
	_week_story_milestone(id)
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


## Já estavam à vista na tela do Tiro antes da fase: não há o que anunciar, só marcam como vistos.
## O Ato 1 (novo fluxo) revela os cuidados e as abas pelo passo da história, sem cartão "Novo!": a mão e a pílula
## do próximo passo já apresentam cada coisa.
const SILENT_UNLOCKS: Array[String] = ["feature:wishes", "feature:growth_tab", "feature:care_food", "feature:care_bath",
	"feature:care_play", "feature:care_sleep", "feature:tab_map", "feature:tab_tasks", "feature:bag"]


func new_unlocks() -> Array[String]:
	var result: Array[String] = []
	for key in _visible_unlock_keys():
		if progress.seen.has(key): continue
		if key in SILENT_UNLOCKS:
			progress.seen[key] = true
			continue
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
	if kind == "weekly" and farm_week_active():
		return false
	return progress.feature_unlocked(kind) or (kind == "daily" and not recipe_ingredient_day().is_empty())


## Missões do período (sorteia ao virar o dia ou a semana).
func routine_ids(kind: String) -> Array[String]:
	_ensure_routines(kind)
	var ids: Array[String] = []
	ids.assign(progress.routines.get(kind, {}).get("ids", []))
	return ids


## Modelo da rotina do catálogo atual (saves zerados).
func routine_data(kind: String, id: String) -> Dictionary:
	if kind == "daily" and id == "recipe_ingredient":
		var daily := recipe_ingredient_day()
		if daily.is_empty():
			return {}
		return {"name": "Ingrediente do dia", "text": "Faça um prato inédito com %s." % daily.name,
			"goal": {"type": "stat", "key": "ingredient_of_day", "target": 1},
			"rewards": {"coins": daily.coins}, "icon": "station_stove"}
	return Database.routines.get(kind, {}).get("missions", {}).get(id, {})


## Fase da jornada para as faixas de meta: começo (a semana e a Vila, até o capítulo 12), meio (13–17), comunidade (18+).
func routine_phase() -> String:
	var chapter := progress.chapter_index()
	return "start" if chapter <= 12 else ("middle" if chapter <= 17 else "community")


## Meta da rotina: a quantidade congelada na geração (fase) ou, em sorteio antigo, a do modelo.
func routine_target(kind: String, id: String) -> int:
	var frozen: Dictionary = progress.routines.get(kind, {}).get("targets", {})
	if frozen.has(id):
		return int(frozen[id])
	return int(routine_data(kind, id).get("goal", {}).get("target", 1))


func routine_value(kind: String, id: String) -> int:
	if kind == "daily" and id == "recipe_ingredient":
		return int(int(week.recipe_book.get("daily", {}).get("day", 0)) == int(recipe_ingredient_day().get("day", -1)))
	var key: String = routine_data(kind, id).get("goal", {}).get("key", "")
	var base: Dictionary = progress.routines.get(kind, {}).get("base", {})
	return maxi(0, progress.stat(key) - int(base.get(key, 0)))


func routine_claimed(kind: String, id: String) -> bool:
	if kind == "daily" and id == "recipe_ingredient":
		return int(week.recipe_book.get("daily", {}).get("claimed_day", 0)) == int(recipe_ingredient_day().get("day", -1))
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
	if kind == "daily" and id == "recipe_ingredient":
		_recipe_book_section("daily")["claimed_day"] = int(recipe_ingredient_day().day)
	else:
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
	return progress.feature_unlocked("wishes") and (progress.stat("arrival_box") == 0 or content_day() >= 3)


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
	if progress.stat("arrival_box") > 0 and wishes.done_count == 0 and str(wishes.current.get("id", "")) == str(wish_settings().get("first", "")):
		return false
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
	if bool(def.get("needs_lesson", false)):
		if has_upgrade("dairy"):
			return false
		for trick: String in Database.progression.tricks:
			if trick_is_lesson(trick) and trick_lesson_error(trick) == "":
				return true
		return false
	return id != "recipe_novelty" and (str(def.get("item", "")) == "meal" or str(def.get("type", "")) != "feed" or wish_item_reachable(def))


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
	var novelty: Dictionary = Database.recipe_book.novelty
	if content_day() >= int(novelty.from_chapter) and "recipe_novelty" not in recent and rng.randf() < float(novelty.chance):
		var tastes: Array = Database.dishes.tastes.keys()
		var start := rng.randi_range(0, tastes.size() - 1)
		for i in tastes.size():
			var taste := str(tastes[(start + i) % tastes.size()])
			if _novel_food(taste) != "" or not recipe_novelty([], taste).is_empty():
				return {"id": "recipe_novelty", "item": taste}
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
	if id == "recipe_novelty":
		var taste := str(Database.dishes.tastes.get(item, "novo"))
		def["taste"] = item
		def["name"] = "Quero provar algo %s" % taste.to_lower()
		def["item"] = _novel_food(item)
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
	return "Prepare um prato novo desse sabor" if def.has("taste") else "Falta " + Database.item_name(str(def.item))


## Atende o desejo: entrega a comida (se for o caso), dá o momento do pilar e espera o próximo período.
func fulfill_wish(trick_offer: Dictionary = {}, item: String = "") -> String:
	var error := wish_error()
	if error != "":
		return error
	var def := wish_now()
	var id := wish_id()
	if str(def.type) == "feed":
		var chosen := str(def.item) if item == "" else item
		if not wish_wants_item(chosen) or not feed(chosen, trick_offer):
			return "Ele não quer isso agora"
		_count("wish_item:" + chosen)
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
	if def.has("taste"):
		return not walking() and inventory.count(item_id) > 0 and _novel_food_matches(item_id, str(def.taste))
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
		var route_at := Database.place_with_panel("routes:" + str(route.get("place", "")))
		if route_at[0] == "":
			route_at = Database.place_with_panel(str(route.get("place", "")))  # ex.: o pomar tem painel próprio no Sítio
		_add_world_ready(counts, route_at[0], 1)
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
	var new_photos := sealed_photos()
	if photo_alerts_enabled() and not new_photos.is_empty():
		lines.append({"kind": "photo", "count": _sealed_photo_count(new_photos), "world": "", "target": ""})
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
				output = Database.entry_output(entry)
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
	var period := routine_period(kind, week_now()) if kind == "daily" else routine_period(kind)
	if progress.routines.get(kind, {}).get("period", "") == period:
		return
	var missions: Dictionary = Database.routines[kind].missions.duplicate()
	var daily := recipe_ingredient_day() if kind == "daily" else {}
	if kind == "daily" and not progress.feature_unlocked(kind):
		missions.clear()
	if not daily.is_empty():
		missions["recipe_ingredient"] = routine_data(kind, "recipe_ingredient")
	var pool: Array[String] = []
	for id: String in missions:
		if requirement_error(missions[id].get("requirements", {})) == "":
			pool.append(id)
	pool.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind + period)
	var ids: Array[String] = []
	if not daily.is_empty():
		pool.erase("recipe_ingredient")
		ids.append("recipe_ingredient")
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
		if Database.quests[id].get("kind") != "retired":
			_dev_complete_quest(id)
	for id: String in Database.animals:
		_dev_satisfy(Database.animals[id].get("requirements", {}))
	for id: String in Database.progression.skills:
		_dev_skill_at_least(id, int(Database.progression.settings.max_skill_level))
	# Roupas também vêm das semanais (sorteadas): entrega a coleção inteira.
	for id: String in Database.collections:
		progress.collection[id] = true
	unlocked_plots = int(Database.farm.corn_plot)
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
	for item: String in week.orchard_ready:
		week.orchard_ready[item] = minf(float(week.orchard_ready[item]), t)
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
	for item: String in week.orchard_ready:
		week.orchard_ready[item] = float(week.orchard_ready[item]) - seconds
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
		if req.has("hook") and not growth_hook_live(str(req.hook)):
			continue
		var row := req.duplicate(true)
		row["label"] = _growth_label(req)
		row["need"] = int(req.get("qty", 1))
		row["have"] = _growth_have(req, str(next.id))
		row["done"] = bool(growth.done.get(str(next.id), {}).get(str(req.id), false)) or int(row.have) >= int(row.need)
		if str(req.type) == "dishes" and req.has("types"):
			# "8 pratos diferentes de pelo menos 3 tipos": sem a variedade, o último prato não fecha a conta.
			row["types_need"] = int(req.types)
			row["types_have"] = _phase_dish_types(req).size()
			if int(row.have) >= int(row.need) and int(row.types_have) < int(row.types_need):
				row["dishes_have"] = int(row.have)
				row["have"] = int(row.need) - 1
				row["done"] = bool(growth.done.get(str(next.id), {}).get(str(req.id), false))
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


## Gancho de um sistema que ainda vai chegar (`growth.json → hooks`): sem `live`, o requisito não aparece.
func growth_hook_live(hook: String) -> bool:
	return bool(Database.growth.get("hooks", {}).get(hook, {}).get("live", true))


## Nível do truque (0 = nenhum) pelos acertos contados em `trick:<id>` (limiares em `growth.json → trick_levels`).
## A Aula do Tiro (E07) passa a contar os acertos nesse mesmo contador.
func trick_level(id: String) -> int:
	var total := progress.stat("trick:" + id)
	var level := 0
	var thresholds: Array = Database.growth.get("trick_levels", {}).get("thresholds", [3, 8, 15])
	for i in thresholds.size():
		if total >= int(thresholds[i]):
			level = i + 1
	return level


## Prato que o item representa (`{key, type, ingredients}`); `{}` se não é prato (ração, Gororoba, ingredientes).
## O prato do motor e a receita fixa de mesmos ingredientes têm a MESMA chave.
func dish_of_item(item_id: String) -> Dictionary:
	if item_id.begins_with(DishRules.PREFIX):
		var info := DishRules.parse(item_id)
		if info.is_empty():
			return {}
		return {"key": DishRules.key_of(str(info.type), info.ingredients), "type": str(info.type), "ingredients": info.ingredients}
	for recipe_id: String in Database.recipes:
		var recipe: Dictionary = Database.recipes[recipe_id]
		if str(recipe.get("dish_type", "")) == "" or Database.recipe_output(recipe) != item_id:
			continue
		var ingredients: Array[String] = []
		for input: Variant in recipe.get("inputs", {}):
			var ingredient_id := DishRules.ingredient_of_item(str(input))
			if ingredient_id == "":
				ingredients.clear()
				break
			ingredients.append(ingredient_id)
		var key := DishRules.key_of(str(recipe.dish_type), ingredients) if not ingredients.is_empty() else "recipe:" + recipe_id
		return {"key": key, "type": str(recipe.dish_type), "ingredients": DishRules.canon(ingredients)}
	return {}


func _dish_in_group(ingredients: Array, group: Dictionary) -> bool:
	for ingredient_id: Variant in ingredients:
		if group.has("ingredient") and str(ingredient_id) == str(group.ingredient):
			return true
		if group.has("category") and str(DishRules.ingredient(str(ingredient_id)).get("category", "")) == str(group.category):
			return true
	return false


## Tipos diferentes (dentro do `type_pool` do requisito) entre os pratos comidos na fase.
func _phase_dish_types(req: Dictionary) -> Array[String]:
	var types: Array[String] = []
	var pool: Array = req.get("type_pool", [])
	for key: String in growth.phase_dishes:
		var type := str(growth.phase_dishes[key].get("type", ""))
		if (pool.is_empty() or type in pool) and type not in types:
			types.append(type)
	return types


## Prato comido (chamado pelo `feed`): conta uma vez por fase, avisa o progresso e liga o prato-chave à missão.
func _note_fed_dish(item_id: String) -> void:
	var dish := dish_of_item(item_id)
	if dish.is_empty():
		return
	var key := str(dish.key)
	_note_book_taste(dish, item_id)
	if not growth.phase_dishes.has(key):
		growth.phase_dishes[key] = {"type": dish.type, "ingredients": dish.ingredients, "meal": DishRules.is_meal(str(dish.type))}
		for row: Dictionary in growth_info().requirements:
			if str(row.type) == "dishes" and not row.done:
				Events.toast_requested.emit("Pratos diferentes: %d/%d" % [mini(int(row.have), int(row.need)), int(row.need)])
	_link_key_quests(dish, item_id, "feed")


## O prato-chave e a missão são a mesma coisa: um prato com peixe vale também como a papinha de peixe da missão.
## `event` = "feed" (comeu) ou "produce" (recolheu). Só refeições.
func _link_key_quests(dish: Dictionary, item_id: String, event: String) -> void:
	if dish.is_empty() or not DishRules.is_meal(str(dish.type)):
		return
	for group_id: String in Database.growth.get("key_groups", {}):
		var group: Dictionary = Database.growth.key_groups[group_id]
		var quest_item := str(group.get("quest_item", ""))
		if quest_item != "" and quest_item != item_id and _dish_in_group(dish.ingredients, group):
			_count(event + ":" + quest_item)


## Grupos dos pratos-chave (ovo, fruta, peixe) que o próximo crescimento ainda pede.
func growth_pending_groups() -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	for row: Dictionary in growth_info().requirements:
		if str(row.type) == "dish_key" and not bool(row.done):
			groups.append(Database.growth.get("key_groups", {}).get(str(row.group), {}))
	return groups


## A refeição (tipo + ingredientes) serve a algum dos grupos pendentes (`growth_pending_groups`).
func dish_serves_groups(type_id: String, ingredients: Array, groups: Array[Dictionary]) -> bool:
	if groups.is_empty() or not DishRules.is_meal(type_id):
		return false
	for group: Dictionary in groups:
		if _dish_in_group(ingredients, group):
			return true
	return false


## Resumo congelado na cerimônia: o que a fase teve (dias, pratos, brincadeiras, truques).
func growth_summary() -> Dictionary:
	var result := {}
	for def: Dictionary in Database.growth.get("week_summary", []):
		var id := str(def.id)
		if id == "dishes":
			result[id] = growth.phase_dishes.size()
		else:
			var key := str(def.counter)
			# As patinhas contam desde o dia da chegada (requisito `total` do Dentinhos): o resumo mostra o mesmo número.
			var base := 0 if key == "well_fed_day" else int(growth.phase_stats.get(key, 0))
			result[id] = maxi(0, progress.stat(key) - base)
	return result


func _growth_have(req: Dictionary, target: String) -> int:
	match str(req.get("type", "")):
		"given": return 1
		"dishes": return growth.phase_dishes.size()
		"dish_stars":
			var starred := 0
			for key: String in week.dishes:
				if int(week.dishes[key].get("stars", 1)) >= int(req.get("stars", 2)):
					starred += 1
			return starred
		"invented_dish": return dishes_known_count()
		"dish_key":
			var group: Dictionary = Database.growth.get("key_groups", {}).get(str(req.group), {})
			var served := 0
			for key: String in growth.phase_dishes:
				var entry: Dictionary = growth.phase_dishes[key]
				if bool(entry.get("meal", false)) and _dish_in_group(entry.get("ingredients", []), group):
					served += 1
			return served
		"trick_level": return trick_level(str(req.trick))
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
			return maxi(0, progress.stat(key) - (0 if req.get("total", false) else int(growth.phase_stats.get(key, 0))))
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
	return week_growth_error(str(info.next.id))


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
		"delivered": growth.delivered.get(target, {}).duplicate(true), "summary": growth_summary()}
	if dog.sleeping and target in ["young", "adult"]:
		growth.pending_reveal = target
	growth.phase = target
	growth.phase_since = now()
	growth.phase_stats = progress.stats.duplicate(true)
	growth.phase_moments.clear()
	growth.phase_dishes.clear()
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
		if str(entry.section) not in active:
			continue
		var owned := album.has_photo(id)
		if owned and not photo_can_retake(id): continue
		if event == "app_opened" and str(entry.section) == "sleep" and not dog.sleeping: continue
		if AlbumRules.matches(entry, event, ctx, at):
			if owned:
				_seal_photo(id)
			else:
				_take_photo(id)
				taken.append(id)
	return taken


## Tira a foto pela primeira vez: a carta chega FECHADA (sem nível) e só ganha nível ao abrir.
func _take_photo(id: String) -> void:
	var at := now()
	album.photos[id] = {"at": at, "phase": growth.phase, "coat": dog_look().coat, "seen": false, "equipped": progress.equipped.duplicate(),
		"rarity": 0, "variants": [], "shown": 0, "rolls": 0, "rerolls": 0, "best_at": 0.0, "rolled_at": 0.0,
		"sealed": 1, "sealed_at": at, "upgrades": 0, "opened_at": 0.0}
	_diary("photo", str(Database.photo(id).get("title", id)), "photo:" + id)
	_count("photos")
	Events.photo_taken.emit(id)


## Retomada natural de uma foto repetível: mais uma carta fechada esperando para abrir.
func _seal_photo(id: String) -> void:
	var entry: Dictionary = album.photos[id]
	entry["sealed"] = int(entry.get("sealed", 0)) + 1
	entry["sealed_at"] = now()
	Events.photo_sealed.emit(id)


# --- Cartas das fotos (Fotos do Tiro, etapa 01) ------------------------------------------

## Regras das cartas em `album.json → cards`.
func _cards() -> Dictionary:
	return Database.album.get("cards", {})


func album_rarity_def(level: int) -> Dictionary:
	for def: Dictionary in _cards().get("levels", []):
		if int(def.get("level", 0)) == level:
			return def.duplicate()
	return {}


## Melhor nível da foto (1..4); 0 se a carta nunca foi aberta.
func photo_rarity(id: String) -> int:
	return int(album.photos.get(id, {}).get("rarity", 0))


## Cartas fechadas esperando para abrir.
func photo_sealed(id: String) -> int:
	return int(album.photos.get(id, {}).get("sealed", 0))


func _sealed_photo_count(ids: Array[String]) -> int:
	var count := 0
	for id in ids: count += photo_sealed(id)
	return count


func sealed_photos() -> Array[String]:
	var result: Array[String] = []
	for id: String in album.photos:
		if photo_sealed(id) > 0: result.append(id)
	return result


## Quantas fotos têm cada raridade (melhor versão): {1: n, 2: n, 3: n, 4: n}.
func rarity_counts() -> Dictionary:
	var counts := {1: 0, 2: 0, 3: 0, 4: 0}
	for id: String in album.photos:
		var level := photo_rarity(id)
		if counts.has(level): counts[level] += 1
	return counts


## Versões (níveis) já obtidas da foto, em ordem.
func photo_variants(id: String) -> Array:
	return (album.photos.get(id, {}).get("variants", []) as Array).duplicate()


func photo_styles_complete(id: String) -> bool:
	return album.has_photo(id) and photo_variants(id).size() >= (_cards().get("levels", []) as Array).size()


func styles_complete_count() -> int:
	var total := 0
	for id: String in album.photos:
		if photo_styles_complete(id): total += 1
	return total


## Versão mostrada (a escolhida, ou a melhor).
func photo_shown_rarity(id: String) -> int:
	var entry: Dictionary = album.photos.get(id, {})
	var shown := int(entry.get("shown", 0))
	return shown if shown > 0 and shown in entry.get("variants", []) else int(entry.get("rarity", 0))


func set_photo_variant_error(id: String, level: int) -> String:
	if not album.has_photo(id): return "Você ainda não tem essa foto"
	if level not in album.photos[id].get("variants", []): return "Você ainda não tem essa versão"
	return ""


func set_photo_variant(id: String, level: int) -> String:
	var error := set_photo_variant_error(id, level)
	if error != "": return error
	album.photos[id]["shown"] = 0 if level == photo_rarity(id) else level
	_changed()
	return ""


## Foto de momento repetível, já aberta, fora do tempo de espera e ainda com versões por conseguir.
func photo_can_retake(id: String) -> bool:
	if not album.has_photo(id) or not bool(Database.photo(id).get("repeatable", false)):
		return false
	var entry: Dictionary = album.photos[id]
	if float(entry.get("opened_at", 0.0)) <= 0.0 or photo_styles_complete(id): return false
	var hours := float(Database.photo(id).get("repeat_cooldown_hours", _cards().get("repeat_cooldown_hours", 20)))
	var last := maxf(float(entry.get("rolled_at", 0.0)), float(entry.get("sealed_at", 0.0)))
	return now() - last >= hours * 3600.0


## Sorteia o nível com semente salva, tabela da seção (ou da foto) e garantias.
func _roll_rarity(id: String) -> int:
	var data := _cards()
	var photo := Database.photo(id)
	var table: Dictionary = photo.get("rarity_weights", data.get("section_weights", {}).get(str(photo.get("section", "")), {}))
	var entries: Array = []
	for def: Dictionary in data.get("levels", []):
		var weight := float(table.get(str(int(def.level)), def.get("weight", 1)))
		entries.append({"level": int(def.level), "weight": weight})
	if entries.is_empty(): return 1
	if album.rarity_seed == 0: album.rarity_seed = (randi() & 0x7fffffff) | 1
	album.rarity_seed = (album.rarity_seed * 1103515245 + 12345) & 0x7fffffff
	var level := int(Loot.pick_weighted(entries, album.rarity_seed ^ hash(id)).get("level", 1))
	var pity: Dictionary = data.get("pity", {})
	if album.pity_holo >= int(pity.get("holo", 30)):
		level = 4
	elif album.pity_rare >= int(pity.get("rare_plus", 10)):
		level = maxi(level, 3)
	album.pity_rare = 0 if level >= 3 else album.pity_rare + 1
	album.pity_holo = 0 if level >= 4 else album.pity_holo + 1
	return level


## Aplica um nível a uma foto que existe: soma a versão e só sobe o melhor. `draw` = veio de um sorteio
## (abrir/tentar a sorte); Melhorar não é sorteio. `kind`: open, reroll, upgrade ou tutorial.
func _apply_photo_roll(id: String, level: int, kind: String, draw: bool = true, action: String = "") -> Dictionary:
	var entry: Dictionary = album.photos[id]
	var previous := int(entry.get("rarity", 0))
	var first := float(entry.get("opened_at", 0.0)) <= 0.0
	var variants: Array = entry.get("variants", [])
	var is_new := level not in variants
	if is_new:
		variants.append(level)
		variants.sort()
		if level == 4: _count("photo_holo")
	# Tirar uma raridade destrava também todas as versões abaixo dela.
	for lower in range(1, level):
		if lower not in variants: variants.append(lower)
	variants.sort()
	entry["variants"] = variants
	if draw:
		entry["rolls"] = int(entry.get("rolls", 0)) + 1
		entry["rolled_at"] = now()
	if first: entry["opened_at"] = now()
	var improved := level > previous
	if improved:
		entry["rarity"] = level
		entry["best_at"] = now()
	var result := {"rarity": maxi(level, previous), "previous": previous, "new_photo": first, "improved": improved,
		"new_variant": is_new, "rolled": level, "kind": kind, "action": action if action != "" else kind}
	Events.photo_rolled.emit(id, result)
	_check_album_rewards()
	_changed()
	return result


## Nível forçado pelo tutorial da carta (0 = nenhum). Só vale com o tutorial ativo, na foto da chegada
## e no passo da ação; nunca mexe nas garantias nem cobra. É o único caminho que força um nível.
func _tutorial_level(id: String, action: String) -> int:
	var config: Dictionary = _cards().get("tutorial", {})
	var forced: Array = config.get("forced", [])
	if id != str(config.get("photo", "")) or forced.size() < 3:
		return 0
	if not album.tutorial.get("done", false):
		# Parte 1: abrir a carta e Tentar a sorte (a primeira tentativa é presente).
		var step := int(album.tutorial.get("step", 0))
		match action:
			"open": return int(forced[0]) if step == 1 or step == 2 else 0
			"reroll": return int(forced[1]) if step == 3 else 0
		return 0
	if album.tutorial.get("more_done", false):
		return 0
	# Parte 2 (quando surgem os materiais): Melhorar de presente.
	return int(forced[2]) if action == "upgrade" and int(album.tutorial.get("more_step", 0)) == 4 else 0


func open_photo_card_error(id: String) -> String:
	if not album.has_photo(id): return "Você ainda não tem essa foto"
	if photo_sealed(id) <= 0: return "Essa carta já está aberta"
	return ""


## Abrir: gasta uma carta fechada e sorteia o nível (ou o nível do tutorial).
func open_photo_card(id: String) -> String:
	var error := open_photo_card_error(id)
	if error != "": return error
	# Abrir a carta da chegada antes de o tutorial começar também conta como o passo 1.
	if id == str(_cards().get("tutorial", {}).get("photo", "")) and not album_tutorial_done() and album_tutorial_step() == 0:
		advance_album_tutorial(1)
	var forced := _tutorial_level(id, "open")
	var level := forced if forced > 0 else _roll_rarity(id)
	album.photos[id]["sealed"] = photo_sealed(id) - 1
	_count("photo_opens")
	_apply_photo_roll(id, level, "tutorial" if forced > 0 else "open", true, "open")
	return ""


## Custo de "Tentar a sorte": só moedas, sobe a cada tentativa daquela foto até o teto (`cards.reroll`).
func reroll_cost(id: String) -> Dictionary:
	var data: Dictionary = _cards().get("reroll", {})
	var step := int(album.photos.get(id, {}).get("rerolls", 0))
	var coins := int(data.get("coins", 0)) + int(data.get("coins_step", 0)) * step
	return {"coins": mini(coins, int(data.get("coins_max", coins))), "items": {}}


func reroll_photo_error(id: String) -> String:
	if not album.has_photo(id): return "Você ainda não tem essa foto"
	if photo_rarity(id) <= 0: return "Abra a carta primeiro"
	if photo_styles_complete(id): return "Essa foto já tem todas as versões"
	if _tutorial_level(id, "reroll") > 0: return ""
	var cost := reroll_cost(id)
	return transaction_error(cost.items, {}, int(cost.coins))


## Tentar a sorte: paga moedas e sorteia outra versão (mesmas chances e garantias).
func reroll_photo(id: String) -> String:
	var error := reroll_photo_error(id)
	if error != "": return error
	var forced := _tutorial_level(id, "reroll")
	if forced <= 0:
		coins -= int(reroll_cost(id).coins)
		album.photos[id]["rerolls"] = int(album.photos[id].get("rerolls", 0)) + 1
	_count("photo_rerolls")
	_apply_photo_roll(id, forced if forced > 0 else _roll_rarity(id), "tutorial" if forced > 0 else "reroll", true, "reroll")
	return ""


## Custo de Melhorar: o do nível de destino (melhor + 1) em `cards.upgrade`; {} se não há destino.
func upgrade_cost(id: String) -> Dictionary:
	var target := photo_rarity(id) + 1
	var row: Dictionary = _cards().get("upgrade", {}).get(str(target), {})
	if photo_rarity(id) <= 0 or row.is_empty(): return {}
	return {"level": target, "coins": int(row.get("coins", 0)), "items": (row.get("items", {}) as Dictionary).duplicate()}


func upgrade_photo_error(id: String) -> String:
	if not album.has_photo(id): return "Você ainda não tem essa foto"
	if photo_rarity(id) <= 0: return "Abra a carta primeiro"
	var cost := upgrade_cost(id)
	if cost.is_empty(): return "Essa foto já é a melhor versão"
	if _tutorial_level(id, "upgrade") > 0: return ""
	return transaction_error(cost.items, {}, int(cost.coins))


## Melhorar: paga e sobe exatamente um nível acima do melhor (sem sorteio, sem mexer nas garantias).
func upgrade_photo(id: String) -> String:
	var error := upgrade_photo_error(id)
	if error != "": return error
	var cost := upgrade_cost(id)
	var free := _tutorial_level(id, "upgrade") > 0
	if not free:
		inventory.remove_all(cost.items)
		coins -= int(cost.coins)
	album.photos[id]["upgrades"] = int(album.photos[id].get("upgrades", 0)) + 1
	_count("photo_upgrades")
	_apply_photo_roll(id, int(cost.level), "tutorial" if free else "upgrade", false, "upgrade")
	return ""


# --- Recompensas de coleção (Fotos do Tiro, etapa 10) -------------------------------------

func _album_reward_table() -> Dictionary:
	return _cards().get("rewards", {})


## Seção ativa com todas as fotos já abertas (carta fechada não conta).
func album_section_complete(section: String) -> bool:
	var found := false
	for entry: Dictionary in Database.album.photos:
		if str(entry.section) != section: continue
		found = true
		if photo_rarity(str(entry.id)) <= 0: return false
	return found


## Fotos cuja melhor versão é Rara ou melhor.
func rare_plus_count() -> int:
	var total := 0
	for id: String in album.photos:
		if photo_rarity(id) >= 3: total += 1
	return total


func holo_owned() -> bool:
	for id: String in album.photos:
		if 4 in photo_variants(id): return true
	return false


## Prêmio de um marco (`kind`: section | styles | rare | holo; `key` = seção, foto ou quantidade).
func album_milestone_rewards(kind: String, key: String = "") -> Dictionary:
	var table := _album_reward_table()
	match kind:
		"section": return (table.get("section", {}) as Dictionary).duplicate(true)
		"styles": return (table.get("styles", {}) as Dictionary).duplicate(true)
		"rare": return (table.get("rare", {}).get(key, {}) as Dictionary).duplicate(true)
		"holo": return (table.get("holo_first", {}) as Dictionary).duplicate(true)
	return {}


## Quantidades de Raras+ que têm prêmio, em ordem.
func rare_milestones() -> Array[int]:
	var result: Array[int] = []
	for key: String in _album_reward_table().get("rare", {}):
		result.append(int(key))
	result.sort()
	return result


## Id estável do recibo/pagamento de um marco.
func album_milestone_id(kind: String, key: String) -> String:
	match kind:
		"section": return "album:section:" + key
		"styles": return "album:styles:" + key
		"rare": return "album:rare:" + key
	return "album:holo:first"


func album_milestone_paid(kind: String, key: String) -> bool:
	return economy.granted.has(album_milestone_id(kind, key))


func _pay_album_milestone(kind: String, key: String) -> void:
	var rewards := album_milestone_rewards(kind, key)
	if rewards.is_empty() or album_milestone_paid(kind, key): return
	if _grant_automatic(album_milestone_id(kind, key), rewards).paid:
		Events.album_milestone.emit(kind, key)


## Paga cada marco uma vez (abrir, tentar a sorte, melhorar e tutorial passam por aqui).
func _check_album_rewards() -> void:
	for section: String in Database.album.get("active_sections", []):
		if album_section_complete(section): _pay_album_milestone("section", section)
	for id: String in album.photos:
		if photo_styles_complete(id): _pay_album_milestone("styles", id)
	var rare := rare_plus_count()
	for need in rare_milestones():
		if rare >= need: _pay_album_milestone("rare", str(need))
	if holo_owned(): _pay_album_milestone("holo", "first")


## Próximos marcos para o álbum: {rare: {have, next, left, rewards}|{}, holo: {done}, section: {...}|{}}.
## `section` = quantas fotos faltam abrir naquela seção para o prêmio dela.
func album_milestones(section: String = "") -> Dictionary:
	var result := {"rare": {}, "holo": {"done": holo_owned(), "rewards": album_milestone_rewards("holo")}, "section": {}}
	var have := rare_plus_count()
	for need in rare_milestones():
		if have < need:
			result["rare"] = {"have": have, "next": need, "left": need - have, "rewards": album_milestone_rewards("rare", str(need))}
			break
	if section != "":
		var total := 0
		var opened := 0
		for entry: Dictionary in Database.album.photos:
			if str(entry.section) != section: continue
			total += 1
			opened += 1 if photo_rarity(str(entry.id)) > 0 else 0
		result["section"] = {"opened": opened, "total": total, "complete": total > 0 and opened >= total,
			"paid": album_milestone_paid("section", section), "rewards": album_milestone_rewards("section")}
	return result


# --- Varal da home (até `cards.featured_slots` fotos) -------------------------------------

func feature_photo_error(id: String) -> String:
	if not album.has_photo(id): return "Você ainda não tem essa foto"
	if photo_rarity(id) <= 0: return "Abra a carta primeiro"
	if id in album.featured: return "Ela já está no varal"
	if album.featured.size() >= int(_cards().get("featured_slots", 3)): return "Escolha qual sai"
	return ""


func feature_photo(id: String) -> String:
	var error := feature_photo_error(id)
	if error != "": return error
	album.featured.append(id)
	_changed()
	return ""


func unfeature_photo(id: String) -> String:
	if id not in album.featured: return "Ela não está no varal"
	album.featured.erase(id)
	_changed()
	return ""


func featured_photos() -> Array[String]:
	var result: Array[String] = []
	for id: String in album.featured:
		if photo_rarity(id) > 0: result.append(id)
	return result


# --- Tutorial das cartas (roteiro na etapa 09; aqui só o passo salvo) ---------------------

## Passo atual (0 = ainda não começou); a tela avança com `advance_album_tutorial`.
func album_tutorial_step() -> int:
	return int(album.tutorial.get("step", 0))


func album_tutorial_done() -> bool:
	return bool(album.tutorial.get("done", false))


## Só avança (nunca volta) e só enquanto o tutorial não terminou.
func advance_album_tutorial(step: int) -> void:
	if album_tutorial_done() or step <= album_tutorial_step(): return
	album.tutorial["step"] = clampi(step, 0, 6)
	_changed()


func finish_album_tutorial() -> void:
	if album_tutorial_done(): return
	album.tutorial["done"] = true
	_count("album_tutorial")
	_changed()


## A lição do painel de crescimento terminou (ou foi pulada): cumpre o passo "Como ele cresce" (que se entrega sozinho).
func note_growth_lesson() -> void:
	if progress.stat("growth_lesson") > 0: return
	_count("growth_lesson")
	_changed()


## Parte 2 da aula do Álbum (Melhorar) está esperando o jogador abrir o Álbum? Só quando ele já junta os materiais
## que melhorar a foto da chegada pede (a aula dá esse primeiro de presente).
func album_more_ready() -> bool:
	var photo := str(_cards().get("tutorial", {}).get("photo", ""))
	if not album_tutorial_done() or bool(album.tutorial.get("more_done", false)) or photo_rarity(photo) <= 0:
		return false
	var cost := upgrade_cost(photo)
	if cost.is_empty():
		return false
	for item: String in cost.items:
		if inventory.count(item) < int(cost.items[item]):
			return false
	return true


func album_more_step() -> int:
	return int(album.tutorial.get("more_step", 0))


func advance_album_more(step: int) -> void:
	if bool(album.tutorial.get("more_done", false)) or step <= album_more_step(): return
	album.tutorial["more_step"] = clampi(step, 0, 6)
	_changed()


func finish_album_more() -> void:
	if bool(album.tutorial.get("more_done", false)): return
	album.tutorial["more_done"] = true
	_changed()


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
	update_week()
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


## Consulta pura: segredos só entregam destino/progresso depois da lupa (ou da própria foto).
func photo_hint(id: String) -> Dictionary:
	var entry := Database.photo(id)
	if entry.is_empty(): return {}
	var secret := bool(entry.get("secret", false)) or str(entry.section) in ["tricks", "sleep"]
	var revealed := not secret or album.has_photo(id) or int(album.hints.get(id, 0)) > 0
	if not revealed:
		return {"text": str(entry.get("hint", "Uma lembrança espera por vocês.")), "icon": "", "have": 0, "need": 0, "go": {}, "revealed": false}
	var goal: Dictionary = entry.get("goal_hint", {})
	var counter: Dictionary = goal.get("progress", {})
	var stat := str(counter.get("stat", ""))
	var have := 0
	var need := maxi(0, int(counter.get("target", 0)))
	if stat != "" and need > 0:
		have = int(progress.customer_orders(stat.trim_prefix("customer_orders:")).count) if stat.begins_with("customer_orders:") else progress.stat(stat)
	return {"text": str(goal.get("text", "")), "icon": str(goal.get("icon", "")), "have": clampi(have, 0, need), "need": need, "go": goal.get("go", {}).duplicate(true), "revealed": true}


## Faltantes das seções ativas, mais perto primeiro; empate mantém a ordem do catálogo.
func near_photos(limit: int = 3) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in Database.album.photos:
		var id := str(entry.id)
		if album.has_photo(id) or str(entry.section) not in Database.album.active_sections: continue
		var hint := photo_hint(id)
		if not bool(hint.get("revealed", false)): continue
		hint["id"] = id
		result.append(hint)
	# Inserção estável: catálogos pequenos (54) e nenhum estado/sorteio é alterado.
	for i in range(1, result.size()):
		var j := i
		while j > 0:
			var current: Dictionary = result[j]
			var previous: Dictionary = result[j - 1]
			var ratio: float = float(current.have) / int(current.need) if int(current.need) > 0 else 0.0
			var prior: float = float(previous.have) / int(previous.need) if int(previous.need) > 0 else 0.0
			if ratio <= prior: break
			result[j] = previous
			result[j - 1] = current
			j -= 1
	return result.slice(0, maxi(0, limit))


func album_lupas_left() -> int:
	var day := Time.get_date_string_from_unix_time(int(_local_time()))
	var used := album.lupas_used if day <= album.lupa_day else 0
	return maxi(0, 1 + int(house_has("old_camera")) - used)


func reveal_photo_hint(id: String) -> String:
	var entry := Database.photo(id)
	if entry.is_empty() or (str(entry.section) not in ["tricks", "sleep"] and not bool(entry.get("secret", false))) or album.has_photo(id): return "Essa foto não precisa de lupa"
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
	var info: Dictionary = album.photos.get(id, {}).duplicate(true)
	if not info.is_empty():
		info["rarity"] = photo_rarity(id)
		info["shown_rarity"] = photo_shown_rarity(id)
		info["sealed"] = photo_sealed(id)
		info["opened"] = float(info.get("opened_at", 0.0)) > 0.0
		info["variants"] = photo_variants(id)
	return info


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


func dev_take_photo(id: String, rarity: int = 0) -> void:
	if not BuildInfo.is_dev(): return
	if Database.photo(id).is_empty(): return
	var level := clampi(rarity, 0, 4)
	if not album.has_photo(id): _take_photo(id)
	if level == 0:
		if photo_rarity(id) > 0: return
		level = _roll_rarity(id)
	elif level in photo_variants(id):
		return
	if photo_rarity(id) <= 0 and photo_sealed(id) > 0:
		album.photos[id]["sealed"] = photo_sealed(id) - 1
	_apply_photo_roll(id, level, "open", true)


## Cria uma carta fechada (ou soma mais uma) sem esperar o momento da foto.
func dev_seal_photo(id: String) -> void:
	if not BuildInfo.is_dev(): return
	if Database.photo(id).is_empty(): return
	if album.has_photo(id): _seal_photo(id)
	else: _take_photo(id)
	_changed()


func dev_reset_album_tutorial() -> void:
	if not BuildInfo.is_dev(): return
	album.tutorial = {"step": 0, "done": false}
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
	var local := _local_time(week_now() + _dev_moment_offset if at < 0 else at)
	var date := Time.get_date_string_from_unix_time(local)
	var hour := int(Time.get_time_dict_from_unix_time(local).hour)
	var period := ""
	for entry: Dictionary in Database.growth.moments.periods:
		if hour >= int(entry.start): period = str(entry.id)
	return date + ":" + period


func _prune_moment_periods() -> void:
	var at := week_now() + _dev_moment_offset
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
## Nas fases de `moments.uncapped_phases` (a primeira) o teto de momentos por período não vale:
## o primeiro carinho tem que render logo, sem esperar o período seguinte.
func _moments_uncapped() -> bool:
	return growth.phase in Database.growth.moments.get("uncapped_phases", [])


func _gain_moment(pillar: String, source: String, capped: bool, strict: bool = false) -> int:
	if pillar not in ["brave", "smart", "coat"]: return 0
	_prune_moment_periods()
	var key := moment_period() + ":" + pillar
	if capped:
		var used := int(growth.period_moments.get(key, 0))
		if used >= int(Database.growth.moments.period_cap) and (strict or not _moments_uncapped()): return 0
		growth.period_moments[key] = used + 1  # também conta na fase livre, para a fase seguinte não burlar o teto
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
	if reaction == "loved" and progress.stat("arrival_box") > 0:
		_routine_set("favorite", item)
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


# --- Pesca ------------------------------------------------------------------
# Regras da pesca na lagoa (plano docs/plans/pesca). O minigame roda ao vivo na UI; aqui ficam as
# validações, o sorteio do peixe, o tamanho, os recordes e o que o app fechado não pode perder.
# Ciclo: cast (espera) → hook (gasta a isca e sorteia o peixe) → finish_fishing (entrega) / cancel_fishing.

func fishing_level() -> int:
	return fishing.level(Database.fishing.get("levels", [0]))


func has_rod(id: String) -> bool:
	return fishing.has_rod(id)


## Vara em uso: a escolhida ou, sem escolha, a de maior nível ("" = nenhuma).
func current_rod() -> String:
	if fishing.rod != "" and fishing.has_rod(fishing.rod):
		return fishing.rod
	var best := ""
	var best_tier := -1
	for id: String in fishing.rods:
		var tier := int(Database.fishing.get("rods", {}).get(id, {}).get("tier", 0))
		if tier > best_tier:
			best_tier = tier
			best = id
	return best


## Sorteio independente e estável por partida: a mesma semente e o mesmo `salt` dão sempre o mesmo número.
func _fishing_rng(salt: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%s" % [int(fishing.cast.get("seed", 0)), salt])
	return rng


func _lower_name(id: String) -> String:
	return Database.item_name(id).to_lower()


## Altura da barra do minigame (fração da pista): nível, vara e Tiro animado, limitada a `bar_max`.
func fishing_bar_height() -> float:
	var physics: Dictionary = Database.fishing.physics
	var rod_id := str(fishing.cast.get("rod", "")) if not fishing.cast.is_empty() else current_rod()
	var bonus := float(Database.fishing.get("rods", {}).get(rod_id, {}).get("bar_bonus", 0.0))
	var height := float(physics.bar_base) + float(physics.bar_per_level) * (fishing_level() - 1) + bonus
	if tiro_animated():
		height += float(physics.animated_bonus)
	return minf(height, float(physics.bar_max))


## Consulta pura para a UI.
func fishing_info() -> Dictionary:
	var levels: Array = Database.fishing.get("levels", [0])
	var level := fishing_level()
	var baits := {}
	for id: String in Database.fishing.get("baits", {}):
		baits[id] = inventory.count(id)
	return {
		"rod": current_rod(), "rods": fishing.rods.duplicate(), "bait": fishing.bait, "baits": baits,
		"level": level, "xp": fishing.xp, "next_xp": int(levels[level]) if level < levels.size() else -1,
		"bar": fishing_bar_height(), "cast_state": str(fishing.cast.get("state", "")),
		"bubble": fishing.bubble.duplicate(),
	}


func fishing_error() -> String:
	if not farm_lake_open():
		return "Continue a História"
	if current_rod() == "":
		return "Você ainda não tem uma vara"
	if dog.sleeping:
		return "Ele está dormindo"
	if walking():
		return away_text()
	return ""


func choose_rod_error(id: String) -> String:
	if not fishing.has_rod(id):
		return "Você ainda não tem essa vara"
	return "Termine a pesca primeiro" if _fishing_busy() else ""


func choose_rod(id: String) -> String:
	var error := choose_rod_error(id)
	if error != "":
		return error
	fishing.rod = id
	var accepted: Array = Database.fishing.rods[id].baits
	if fishing.bait != "" and fishing.bait not in accepted:
		fishing.bait = ""
	Events.fishing_changed.emit()
	_changed()
	return ""


func choose_bait_error(id: String) -> String:
	if not Database.fishing.get("baits", {}).has(id):
		return "Isca desconhecida"
	var rod := current_rod()
	if rod == "":
		return "Você ainda não tem uma vara"
	if not bait_allowed(rod, id):
		return "Essa vara não usa " + _lower_name(id)
	return "Termine a pesca primeiro" if _fishing_busy() else ""


func choose_bait(id: String) -> String:
	var error := choose_bait_error(id)
	if error != "":
		return error
	fishing.bait = id
	Events.fishing_changed.emit()
	_changed()
	return ""


## Há partida de verdade em andamento (uma interrompida pelo fechamento do app não conta).
func _fishing_busy() -> bool:
	return not fishing.cast.is_empty() and str(fishing.cast.get("state", "")) != "interrupted"


func cast_error(bait: String, zone: int, on_bubble: bool = false) -> String:
	var error := fishing_error()
	if error != "":
		return error
	if _fishing_busy():
		return "Já tem uma pesca em andamento"
	if not Database.fishing.get("baits", {}).has(bait):
		return "Isca desconhecida"
	if not bait_allowed(current_rod(), bait):
		return "Essa vara não usa " + _lower_name(bait)
	if inventory.count(bait) <= 0:
		return "Sem " + _lower_name(bait)
	if bait == str(secret_config().get("bait", "")) and golden_bitten_today():
		return "O peixe dourado só volta amanhã"
	if zone < 1 or zone > int(Database.fishing.cast.zones):
		return "Zona inválida"
	return ""


## Arremessa: cria a partida em espera. NÃO gasta a isca (só a fisgada gasta).
func cast(bait: String, zone: int, on_bubble: bool = false) -> String:
	var error := cast_error(bait, zone, on_bubble)
	if error != "":
		return error
	var config: Dictionary = Database.fishing
	var on_hot_spot := on_bubble and not fishing.bubble.is_empty()
	var effective_zone := zone
	if on_hot_spot:
		effective_zone = mini(zone + int(config.bubbles.zone_bonus), int(config.cast.zones))
	var seed_value := hash("fish:%s:%s:%s" % [growth.taste_seed, fishing.seq, int(now() * 1000.0)])
	fishing.cast = {
		"seed": seed_value, "n": fishing.seq, "bait": bait, "rod": current_rod(), "zone": effective_zone,
		"bubble": on_hot_spot, "at": now(), "state": "waiting", "fish": "", "spent": false,
	}
	fishing.seq += 1
	var span: Array = config.cast.wait
	var wait := _fishing_rng("wait").randf_range(float(span[0]), float(span[1]))
	if not fishing.tutorial.done:
		wait = float(config.cast.get("tutorial_wait", wait))
	if on_hot_spot:
		wait *= float(config.bubbles.wait_mult)
	fishing.cast["wait"] = wait
	fishing.bait = bait
	Events.fishing_changed.emit()
	_changed()
	return ""


## A boia já deve ter afundado?
func bite_due() -> bool:
	var c: Dictionary = fishing.cast
	return str(c.get("state", "")) == "waiting" and now() >= float(c.at) + float(c.wait)


## No tutorial a janela da fisgada não acaba.
func _bite_window_open() -> bool:
	if not fishing.tutorial.done:
		return true
	var c: Dictionary = fishing.cast
	return now() <= float(c.at) + float(c.wait) + float(Database.fishing.cast.bite_window)


func hook_error() -> String:
	var c: Dictionary = fishing.cast
	if str(c.get("state", "")) != "waiting":
		return "Nada para fisgar"
	if not bite_due():
		return "Ainda não mordeu"
	if not _bite_window_open():
		return "O peixe foi embora"
	if inventory.count(str(c.bait)) <= 0:
		return "Sem " + _lower_name(str(c.bait))
	return ""


## Fisga: gasta 1 isca (a artificial só em parte das vezes), sorteia o peixe e abre a luta.
func hook() -> String:
	var error := hook_error()
	if error != "":
		return error
	var c: Dictionary = fishing.cast
	var bait := str(c.bait)
	var keep := float(Database.fishing.baits.get(bait, {}).get("keep_chance", 0.0))
	# No tutorial a minhoca não se gasta: a partida pode recomeçar do passo da mordida sem custo.
	if fishing.tutorial.done and (keep <= 0.0 or _fishing_rng("keep").randf() >= keep):
		inventory.remove(bait, 1)
		c["spent"] = true
	if bait == str(secret_config().get("bait", "")):
		week.golden_day = week_day()  # no máximo uma mordida do peixe dourado por dia
	c["fish"] = _pick_fish(c)
	c["chest"] = _chest_due(c)
	c["state"] = "fighting"
	fishing.bait_casts[bait] = int(fishing.bait_casts.get(bait, 0)) + 1
	_count("fish_hook")
	Events.fishing_changed.emit()
	_changed()
	return ""


## Prêmio do baú da última pesca entregue ({coins, items}; vazio = sem baú). Só para a tela do resultado.
var last_fish_chest: Dictionary = {}


## Baú da lagoa: só com vara de tier ≥ `chest.from_rod`, nunca no tutorial nem na primeira vez da espécie;
## a chance sai da semente da partida (decidido na fisgada, para valer também ao recarregar o save).
func _chest_due(c: Dictionary) -> bool:
	var config: Dictionary = Database.fishing
	var chest: Dictionary = config.get("chest", {})
	if not fishing.tutorial.done or chest.is_empty() or fishing.record(str(c.fish)).is_empty():
		return false
	var rods: Dictionary = config.get("rods", {})
	if int(rods.get(str(c.rod), {}).get("tier", 0)) < int(rods.get(str(chest.get("from_rod", "")), {}).get("tier", 99)):
		return false
	return _fishing_rng("chest").randf() < float(chest.get("chance", 0.0))


## Mordida perdida ou toque antes da hora: recolhe a linha sem gastar nada.
func miss_bite() -> String:
	if str(fishing.cast.get("state", "")) != "waiting":
		return ""
	fishing.cast = {}
	_count("fish_miss")
	Events.fishing_changed.emit()
	_changed()
	return ""


## Missões ativas que pedem peixe (`stat` com chave `fish:<id>` ainda não cumprida).
func _quest_fish_wanted() -> Array[String]:
	var wanted: Array[String] = []
	for quest_id: String in progress.active_steps().values():
		for goal: Dictionary in Database.quests.get(quest_id, {}).get("goals", []):
			var key := str(goal.get("key", ""))
			if str(goal.get("type", "")) == "stat" and key.begins_with("fish:") and progress.stat(key) < int(goal.get("target", 1)):
				wanted.append(key.trim_prefix("fish:"))
	return wanted


func _pick_fish(c: Dictionary) -> String:
	var config: Dictionary = Database.fishing
	var bait := str(c.bait)
	var zone := clampi(int(c.zone), 1, int(config.cast.zones))
	var entries: Array = []
	var total := 0.0
	for id: String in config.fish:
		var def: Dictionary = config.fish[id]
		if str(def.bait) != bait:
			continue
		var weights: Array = def.weights
		var weight := float(weights[mini(zone, weights.size()) - 1])
		entries.append({"id": id, "weight": weight})
		total += weight
	if entries.is_empty():
		return ""
	# Tutorial: o primeiro peixe é sempre o lambari.
	if not fishing.tutorial.done and bait == "bait_worm" and config.fish.has("fish_lambari"):
		return "fish_lambari"
	# Garantia da história: nunca pegou a espécie e já gastou as pescas combinadas com essa isca.
	var guarantees: Dictionary = config.get("story_guarantee", {})
	for id: String in guarantees:
		if str(config.fish.get(id, {}).get("bait", "")) == bait and fishing.record(id).is_empty() \
				and int(fishing.bait_casts.get(bait, 0)) >= int(guarantees[id]) - 1:
			return id
	# Missão ativa: a espécie pedida vale pelo menos `story_share` do grupo.
	var share := clampf(float(config.get("story_share", 0.5)), 0.0, 0.95)
	for wanted_id in _quest_fish_wanted():
		for entry: Dictionary in entries:
			if entry.id == wanted_id:
				var others := total - float(entry.weight)
				entry.weight = maxf(float(entry.weight), others * share / (1.0 - share))
				break
	var picked := Loot.pick_weighted(entries, hash("%d:fish" % int(c.seed)))
	return str(picked.get("id", entries[0].id))


## Tamanho: pontuação + sorte + zona; perfeita sobe uma classe; garantia de Grande+ depois de 8 seguidas.
func _fishing_size(c: Dictionary, result: Dictionary) -> Dictionary:
	var config: Dictionary = Database.fishing
	var def: Dictionary = config.fish[str(c.fish)]
	var formula: Dictionary = config.size_formula
	var classes: Array = config.classes
	var f := float(formula.quality) * float(result.score) + float(formula.luck) * _fishing_rng("luck").randf() \
			+ float(formula.zone) * (int(c.zone) - 1)
	f = clampf(f, 0.0, 1.0)
	if fishing.since_large >= int(config.pity_large):
		f = maxf(f, float(formula.pity_min))
	var index := 0
	for i in classes.size():
		if f >= float(classes[i].min):
			index = i
	if bool(result.get("perfect", false)) and index < classes.size() - 1:
		index += 1
		f = maxf(f, float(classes[index].min))
	var low := float(def.cm[0])
	var high := float(def.cm[1])
	var cm := clampf(snappedf(low + f * (high - low), 0.5), low, high)
	var cls: Dictionary = classes[index]
	return {"cm": cm, "class": str(cls.id), "index": index, "qty": int(def.get("qty", cls.get("qty", 1))), "f": f}


## Validação do que a UI mandou (o minigame roda ao vivo: nunca se confia cegamente).
func _fishing_result_error(result: Dictionary) -> String:
	if str(fishing.cast.get("state", "")) != "fighting":
		return "Nenhuma pesca em andamento"
	var score: Variant = result.get("score", null)
	if typeof(result.get("caught", null)) != TYPE_BOOL or (typeof(score) != TYPE_FLOAT and typeof(score) != TYPE_INT) \
			or float(score) < 0.0 or float(score) > 1.0:
		return "Resultado inválido"
	for key: String in ["perfect", "chest"]:
		if result.has(key) and typeof(result[key]) != TYPE_BOOL:
			return "Resultado inválido"
		if bool(result.get(key, false)) and not bool(result.caught):
			return "Resultado inválido"
	return ""


func _normalize_result(result: Dictionary) -> Dictionary:
	return {"caught": bool(result.caught), "score": float(result.score), "perfect": bool(result.get("perfect", false)), "chest": bool(result.get("chest", false))}


## Resultado já guardado (geladeira cheia) vale no lugar do novo: não dá para tentar de novo uma nota melhor.
func _effective_result(result: Dictionary) -> Dictionary:
	return fishing.cast.pending_result if fishing.cast.has("pending_result") else result


func finish_fishing_error(result: Dictionary) -> String:
	var error := _fishing_result_error(result)
	if error != "":
		return error
	var use := _golden_rule(str(fishing.cast.fish), _normalize_result(_effective_result(result)))
	if not use.caught:
		return ""
	var size := _fishing_size(fishing.cast, use)
	return storage_error({str(fishing.cast.fish): int(size.qty)})


## `result` = {caught, score 0..1, perfect, chest}. Com a geladeira cheia nada muda e a partida continua.
func finish_fishing(result: Dictionary) -> String:
	var error := _fishing_result_error(result)
	if error != "":
		return error
	var c: Dictionary = fishing.cast
	var fish_id := str(c.fish)
	var use := _golden_rule(fish_id, _normalize_result(_effective_result(result)))
	if not use.caught:
		_count("fish_escape")
		_count("fish_escape:" + fish_id)
		fishing.cast = {}
		Events.fish_escaped.emit(fish_id)
		Events.fishing_changed.emit()
		_changed()
		return ""
	var config: Dictionary = Database.fishing
	var def: Dictionary = config.fish[fish_id]
	var size := _fishing_size(c, use)
	var full := storage_error({fish_id: int(size.qty)})
	if full != "":
		c["pending_result"] = use
		Events.fishing_changed.emit()
		_changed()
		return full
	var level_before := fishing_level()
	inventory.add(fish_id, int(size.qty))
	var record: Dictionary = fishing.records.get(fish_id, {})
	var first := record.is_empty()
	var previous_cm := float(record.get("best_cm", 0.0))
	if first:
		record = {"best_cm": 0.0, "best_class": "", "count": 0, "gigantes": 0, "perfects": 0, "first_at": now()}
	record.count = int(record.count) + 1
	if size.class == "giant":
		record.gigantes = int(record.gigantes) + 1
	if bool(use.perfect):
		record.perfects = int(record.perfects) + 1
	if float(size.cm) > float(record.best_cm):
		record.best_cm = float(size.cm)
		record.best_class = str(size.class)
	fishing.records[fish_id] = record
	var cls: Dictionary = config.classes[int(size.index)]
	var gain := roundi(float(def.xp) * float(cls.get("xp", 1.0)) * (float(config.meter.perfect_xp_mult) if bool(use.perfect) else 1.0))
	fishing.xp += gain
	if int(size.index) >= 2:
		fishing.since_large = 0
	else:
		fishing.since_large += 1
	_count("fish")
	_count("fish:" + fish_id)
	_recipe_source("fish")
	_count("fish_size:" + str(size.class))
	_count("fish_size:%s:%s" % [size.class, fish_id])
	if size.class == "giant":
		_count("fish_size:large")
		_count("fish_size:large:" + fish_id)
		_count("fish_gigante")
	if bool(use.perfect):
		_count("fish_perfect")
	if first:
		_moment_source(str(config.moment_first.source), fish_id)
	last_fish_chest = {}
	if bool(use.chest) and bool(c.get("chest", false)) \
			and int(config.rods.get(str(c.rod), {}).get("tier", 0)) >= int(config.rods.get(str(config.chest.from_rod), {}).get("tier", 99)):
		var loot := Loot.roll(config.chest.loot, 1, hash("%d:chest" % int(c.seed)))
		if bool(_grant_automatic("fish_chest:%d" % int(c.n), loot).paid):
			last_fish_chest = loot
			_count("fish_chest")
	fishing.cast = {}
	var level_after := fishing_level()
	Events.fish_caught.emit(fish_id, float(size.cm), str(size.class), previous_cm)
	_album_event("fished", {"item": fish_id})
	if level_after > level_before:
		Events.fishing_level_up.emit(level_after)
	Events.fishing_changed.emit()
	_changed()
	return ""


func release_fish_error() -> String:
	var c: Dictionary = fishing.cast
	return "" if str(c.get("state", "")) == "fighting" and c.has("pending_result") else "Não há peixe para soltar"


## Desiste do peixe que não cabia: sem prêmio, a isca já foi.
func release_fish() -> String:
	var error := release_fish_error()
	if error != "":
		return error
	_count("fish_release")
	fishing.cast = {}
	Events.fishing_changed.emit()
	_changed()
	return ""


## Fecha a partida em qualquer estado (app fechado, troca de aba): devolve a isca se já tinha sido gasta.
func cancel_fishing() -> String:
	var c: Dictionary = fishing.cast
	if c.is_empty():
		return ""
	if bool(c.get("spent", false)):
		inventory.add(str(c.bait), 1)
	fishing.cast = {}
	Events.fishing_changed.emit()
	_changed()
	return ""


## Ao carregar: linha lançada e sem fisgada não gastou nada (some); luta sem resultado guardado devolve a
## isca e fica "interrupted" (o peixe sorteado continua no save, mas já dá para lançar de novo).
func _settle_fishing_on_load() -> void:
	var c: Dictionary = fishing.cast
	if not c.is_empty():
		match str(c.get("state", "")):
			"waiting":
				fishing.cast = {}
			"fighting":
				if not c.has("pending_result"):
					if bool(c.get("spent", false)):
						inventory.add(str(c.bait), 1)
						c["spent"] = false
					c["state"] = "interrupted"
			"interrupted":
				pass
			_:
				fishing.cast = {}
	update_fishing()


## Dá a vara (recompensa de missão/loja/receita). Conta `rod:<id>`; devolve se era nova.
func give_rod(id: String) -> bool:
	if not Database.fishing.get("rods", {}).has(id) or fishing.has_rod(id):
		return false
	fishing.rods.append(id)
	_count("rod:" + id)
	if fishing.next_bubble_at <= 0.0:
		_schedule_bubble(now())
	return true


# --- Tutorial da pesca (etapa 05; a tela é o `AnglerTutorial`) ---------------------------------

func fishing_tutorial_step() -> int:
	return int(fishing.tutorial.get("step", 0))


func fishing_tutorial_done() -> bool:
	return bool(fishing.tutorial.get("done", false))


## Só avança (nunca volta) e só enquanto o tutorial não terminou. Passos 1–13 do desenho.
func advance_fishing_tutorial(step: int) -> void:
	if fishing_tutorial_done() or step <= fishing_tutorial_step():
		return
	fishing.tutorial["step"] = clampi(step, 0, 13)
	_changed()


func finish_fishing_tutorial() -> void:
	if fishing_tutorial_done():
		return
	fishing.tutorial["step"] = 13
	fishing.tutorial["done"] = true
	_changed()


## Tutorial: a mordida chega já (retomar do passo 6 depois de fechar o app).
func fishing_tutorial_bite_now() -> void:
	if fishing_tutorial_done() or str(fishing.cast.get("state", "")) != "waiting":
		return
	fishing.cast["wait"] = 0.0
	update_fishing()


## Dica de primeira vez da vovó (`npcs.json → bloblo.lines.tips`): devolve o texto UMA vez e marca como vista.
func fishing_tip(id: String) -> String:
	var key := "fishing_tip:" + id
	if bool(progress.seen.get(key, false)) or not fishing_tutorial_done() or current_rod() == "":
		return ""
	var text := str(Database.npcs.get("bloblo", {}).get("lines", {}).get("tips", {}).get(id, ""))
	if text == "":
		return ""
	mark_seen([key] as Array[String])
	return text


func _bubble_rng(salt: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("bubble:%s:%d:%d" % [growth.taste_seed, fishing.seq, salt])
	return rng


## Marca a próxima bolha para daqui a `every_min` (sorteado) a partir de `from`.
func _schedule_bubble(from: float) -> void:
	var span: Array = Database.fishing.bubbles.every_min
	fishing.next_bubble_at = from + _bubble_rng(int(from)).randf_range(float(span[0]), float(span[1])) * 60.0


## Tick de 1 s (e ao carregar): bolhas quentes pelo relógio e mordida da partida. Devolve se mudou algo.
func update_fishing() -> bool:
	var changed := false
	if current_rod() != "":
		var current := now()
		if not fishing.bubble.is_empty() and current >= float(fishing.bubble.until):
			fishing.bubble = {}
			changed = true
		if fishing.next_bubble_at <= 0.0:
			_schedule_bubble(current)
			changed = true
		elif fishing.bubble.is_empty() and current >= fishing.next_bubble_at:
			var config: Dictionary = Database.fishing.bubbles
			var started := fishing.next_bubble_at
			var until := started + float(config.lasts_min) * 60.0
			if current < until:
				fishing.bubble = {"at": started, "until": until, "spot": _bubble_rng(int(started) + 1).randi() % maxi(1, int(config.spots))}
				_schedule_bubble(started)
			else:
				_schedule_bubble(current)
			changed = true
	var c: Dictionary = fishing.cast
	if str(c.get("state", "")) == "waiting" and bite_due():
		if not bool(c.get("bitten", false)):
			c["bitten"] = true
			Events.fish_bite.emit()
			changed = true
		elif not _bite_window_open():
			fishing.cast = {}
			_count("fish_miss")
			changed = true
	if changed:
		Events.fishing_changed.emit()
	return changed


func dev_give_rod(id: String) -> void:
	if not BuildInfo.is_dev():
		return
	give_rod(id)
	fishing.tutorial["done"] = true
	_changed()


func dev_give_baits() -> void:
	if not BuildInfo.is_dev():
		return
	for id: String in Database.fishing.get("baits", {}):
		inventory.add(id, 10)
	_changed()


func dev_bubble_now() -> void:
	if not BuildInfo.is_dev():
		return
	var config: Dictionary = Database.fishing.bubbles
	var current := now()
	fishing.bubble = {"at": current, "until": current + float(config.lasts_min) * 60.0, "spot": _bubble_rng(int(current)).randi() % maxi(1, int(config.spots))}
	_changed()


func dev_fish_xp(amount: int) -> void:
	if not BuildInfo.is_dev():
		return
	fishing.xp = maxi(0, fishing.xp + amount)
	_changed()


func dev_reset_fishing() -> void:
	if not BuildInfo.is_dev():
		return
	fishing = FishingState.new()
	_changed()


# --- Relógio da semana (primeira semana, E00) -------------------------------------

## Agora, no relógio da semana: o real mais o deslocamento DEV (sempre 0 fora da versão dev).
func week_now() -> float:
	return now() + week.clock_offset


## Hora (0..23) em que o dia do Tiro vira (`config.json → meals.day_starts_at`, 6): 00h–05h59 ainda é a noite do dia anterior.
func _day_start_hour() -> int:
	return int(Database.meals.get("day_starts_at", 6))


## Segundos desde a meia-noite de 1970 no fuso do aparelho, já deslocados pela virada do dia do Tiro:
## `floor(x / 86400)` é o número do dia do Tiro e `x mod 86400` os segundos desde as 6h.
func _game_seconds() -> float:
	return float(_local_time(week_now())) - float(_day_start_hour()) * 3600.0


## Segundos desde o começo do dia do Tiro em que uma hora do relógio (11 = 11h) acontece.
func _window_offset(hour: int) -> float:
	return float(posmod(hour - _day_start_hour(), 24)) * 3600.0


## Instante (mesma escala de `week_now()`) de um ponto do dia do Tiro medido em `_game_seconds()`.
func _week_time_of(game_seconds: float) -> float:
	return game_seconds + float(_day_start_hour()) * 3600.0 - float(_local_time(0.0))


## Número do dia do Tiro (dias desde 1970 no fuso do aparelho, com a virada às 6h) do relógio da semana.
func week_day_number() -> int:
	return int(floor(_game_seconds() / 86400.0))


## Dia da semana do jogo: 1 = dia em que o save começou. Só avança (nunca passa de 99), mesmo
## se o relógio do aparelho voltar: vale o maior dia já visto (`week.high_day`).
func week_day() -> int:
	return clampi(maxi(week_day_number(), week.high_day) - week.started_day + 1, 1, 99)


## "Dia" de CONTEÚDO: o capítulo da história em que o jogador está. A semana tem os capítulos 1 a 11 (um sistema novo
## por capítulo, F04), então o "dia N" que antes abria conteúdo pelo calendário agora é "capítulo N". O calendário
## (`week_day`) só manda no relógio das refeições e no que renova a cada dia (desafio, oferta, limites diários).
func content_day() -> int:
	return clampi(progress.chapter_index(), 1, 99)


## Último capítulo da "primeira semana" (o do almoço de despedida e dos Dentinhos); depois dele a história segue para a Vila.
func week_last_chapter() -> int:
	return int(Database.week_story.get("last_chapter", Database.week_story.days.size()))


## O Livro de receitas e a aba Inventar do fogão abrem juntos, no capítulo em que a história os apresenta.
func recipe_book_open() -> bool:
	return content_day() >= int(Database.recipe_book.get("open_chapter", 1))


func invent_open() -> bool:
	return recipe_book_open()


## Grava o maior dia visto. Roda no tick, ao carregar e nas ações de refeição (não emite `state_changed`).
func _week_touch() -> void:
	week.high_day = maxi(week.high_day, week_day_number())


func farm_lake_open() -> bool:
	return content_day() >= int(Database.farm.fishing_chapter)


## Entregas diárias e abertura do pomar valem também em uma volta ao jogo depois do dia de estreia.
func _sync_week_farm() -> bool:
	var changed := false
	if farm_lake_open():
		changed = give_rod("bamboo_rod")
		var day := maxi(week_day_number(), week.high_day)
		if day > week.bait_day and farm_week_active():
			week.bait_day = day
			_grant_automatic("week_bait:%d" % day, {"items": Database.farm.fishing_daily_bait})
			changed = true
	if content_day() >= int(Database.farm.orchard_chapter) and not has_upgrade("orchard"):
		_grant_upgrade("orchard")
		changed = true
	return changed


func orchard_remaining(item: String) -> int:
	return maxi(0, ceili(float(week.orchard_ready.get(item, 0.0)) - now()))


func orchard_harvest_error(item: String) -> String:
	if not Database.farm.orchard_fruit.has(item):
		return "Fruta desconhecida"
	if content_day() < int(Database.farm.orchard_chapter):
		return "Continue a História"
	var remaining := orchard_remaining(item)
	if remaining > 0:
		return "Fica pronto em " + TimeText.short(remaining)
	return storage_error({item: Database.farm.orchard_fruit[item]})


func harvest_orchard(item: String, origin: Vector2 = Vector2(-1, -1)) -> String:
	var error := orchard_harvest_error(item)
	if error != "":
		return error
	var amount := int(Database.farm.orchard_fruit[item])
	week.orchard_ready[item] = now() + float(Database.farm.orchard_seconds)
	inventory.add(item, amount)
	_count("routine_harvest", amount)
	_count("harvest:" + item, amount)
	_count("orchard:" + item)
	_recipe_source("orchard")
	_changed()
	Events.items_gained.emit({item: amount}, 0, origin)
	return ""


# --- Relógio de refeições (primeira semana, E01a) -----------------------------------

## Horas (de, até) da janela do período no dia, já deslocadas pela opção Mais cedo/Normal/Mais tarde.
## Janela: de `from` (inclusive) até `to` (exclusive). Período desconhecido = (0, 0).
func meal_window(period: String) -> Vector2i:
	var cfg: Dictionary = Database.meals.get("periods", {}).get(period, {})
	if cfg.is_empty():
		return Vector2i.ZERO
	var shift := int(Database.meals.get("options", {}).get(week.option, {}).get("shift", 0))
	return Vector2i(int(cfg.from) + shift, int(cfg.to) + shift)


## Período ("lunch"/"dinner") cuja janela contém a hora; "" fora das janelas.
func meal_period_at(hour: int) -> String:
	for period: String in Database.meals.get("periods", {}):
		var window := meal_window(period)
		if hour >= window.x and hour < window.y:
			return period
	return ""


## Período da janela aberta agora no relógio da semana; "" se nenhuma.
func meal_period_now() -> String:
	return meal_period_at(week_hour())


## Comida que conta como refeição (não como lanche). Prato do motor: pelo tipo (papinha, sopinha e mingau são refeição;
## petisco, biscoito e Gororoba são lanche). Os demais itens seguem a regra antiga (tem `growth` e não é `treat`).
func is_meal_item(item_id: String) -> bool:
	if item_id.begins_with(DishRules.PREFIX):
		var info := DishRules.parse(item_id)
		return not info.is_empty() and DishRules.is_meal(str(info.type))
	var item: Dictionary = Database.items.get(item_id, {})
	return item.has("growth") and not bool(item.get("treat", false))


## Escolhe a opção de horário (`early`/`normal`/`late`); devolve false se não existir.
func set_meal_option(option: String) -> bool:
	if not Database.meals.get("options", {}).has(option):
		return false
	week.option = option
	_changed()
	return true


## Ponto de partida do dia da chegada: o dia do Tiro 1 é o da caixinha. Faltando menos de `meals.arrival_min_hours`
## para a virada das 6h, o dia da chegada se estende até a virada seguinte (para não começar com pressa).
func _anchor_arrival() -> void:
	week.arrival_at = week_now()
	var left := float(week.started_day + 1) * 86400.0 - _game_seconds()
	week.arrival_extended = left < float(Database.meals.get("arrival_min_hours", 3)) * 3600.0


## O dia do Tiro é "da chegada" (qualquer refeição vale a patinha, sem combinado)? Normalmente só o dia 1; estendido, também o 2.
func is_arrival_day(day: int) -> bool:
	var first := int(Database.meals.get("arrival_day", 1))
	return day == first or (week.arrival_extended and day == first + 1)


## Instante (escala de `week_now()`) em que o dia da chegada termina: a virada das 6h seguinte (ou a depois dela, se estendido).
func arrival_day_ends_at() -> float:
	var days := 2 if week.arrival_extended else 1
	return _week_time_of(float(week.started_day + days) * 86400.0)


## Início do primeiro almoço do combinado (primeiro dia que não é da chegada), para o Boa noite do dia 1:
## {"at" (escala de `week_now()`), "hour", "period", "day" (número do dia do Tiro)}.
func first_deal_at() -> Dictionary:
	var period := str(Database.meals.periods.keys()[0])
	var day := int(Database.meals.get("arrival_day", 1)) + (2 if week.arrival_extended else 1)
	var hour := meal_window(period).x
	var game_day := week.started_day + day - 1
	return {"at": _week_time_of(float(game_day) * 86400.0 + _window_offset(hour)), "hour": hour, "period": period, "day": day}


## Quantas refeições na hora o dia precisa para ficar bem alimentado (a chegada pede só uma).
func meals_needed(day: int) -> int:
	if is_arrival_day(day):
		return int(Database.meals.get("arrival_on_time_needed", 1))
	return int(Database.meals.get("on_time_needed", 2))


func meals_on_time(day: int) -> int:
	var record := week.day_record(day)
	var total := 0
	for period: String in Database.meals.get("periods", {}):
		if bool(record.get(period, {}).get("on_time", false)):
			total += 1
	return total


func day_well_fed(day: int) -> bool:
	return bool(week.day_record(day).get("paw", false))


## Dias bem alimentados (patinhas) até agora.
func well_fed_days() -> int:
	var total := 0
	for key: String in week.days:
		if bool(week.days[key].get("paw", false)):
			total += 1
	return total + secret_bonus_total()


## Situação das refeições de hoje, para o HUD e a tela Hoje (E01c): dia, período aberto,
## o que já foi dado (`done[period]` = {at, on_time, item}) e a patinha.
func meal_info() -> Dictionary:
	var day := _routine_day_number()
	var record := week.day_record(day)
	var done := {}
	for period: String in Database.meals.get("periods", {}):
		if record.has(period):
			done[period] = record[period]
	return {
		"day": day,
		"period": meal_period_now(),
		"done": done,
		"on_time": meals_on_time(day),
		"needed": meals_needed(day),
		"paw": bool(record.get("paw", false)),
		"arrival": is_arrival_day(day),
	}


## Por que a refeição não conta agora ("" = conta). Consulta pura.
func meal_error(item_id: String) -> String:
	if not is_meal_item(item_id):
		return "Isso é um lanche"
	if _forced_meal != "":
		return ""  # o Tiro está comendo a refeição guardada (Deixar pronto)
	var info := meal_info()
	if info.arrival:
		return "" if meals_on_time(int(info.day)) < Database.meals.get("periods", {}).size() else "Já comeu hoje"
	var period := str(info.period)
	if period == "":
		return "Ainda não é hora de comer"
	return "Já comeu no %s" % str(Database.meals.periods[period].name).to_lower() if bool(info.done.get(period, {}).get("on_time", false)) else ""


## Registra a refeição na hora para o dia (chamada pelo `feed`). Devolve o período contado ("" = não contou).
## Dia da chegada: a primeira refeição vale a qualquer horário. Depois: só dentro da janela, uma por período.
## Refeição guardada (`_forced_meal`): conta para o período e o dia da janela que abriu.
func _register_meal(item_id: String, trick: String = "") -> String:
	if meal_error(item_id) != "":
		return ""
	_week_touch()
	var info := meal_info()
	var day: int = info.day
	var period := str(info.period)
	var forced := _forced_meal != ""
	if forced:
		day = _forced_day
		period = _forced_meal
	elif info.arrival:
		var order: Array = Database.meals.periods.keys()
		period = str(order[0]) if week_hour() < 16 else str(order[order.size() - 1])
		if bool(info.done.get(period, {}).get("on_time", false)):
			period = str(order[1] if period == order[0] else order[0])
	var record: Dictionary = week.day_record(day).duplicate(true)
	record[period] = {"at": week_now(), "on_time": true, "item": item_id}
	if forced:
		record[period]["stored"] = true
	else:
		dog.apply(Database.meals.get("on_time_bonus", {}), now())  # quem dá na hora ganha mais Felicidade
		if trick != "":
			record[period]["trick"] = trick
			var rules: Dictionary = Database.progression.trick_settings.meal
			dog.apply(rules.bonus_good if trick_level(trick) >= 2 else rules.bonus, now())
			_count("trick_meal")
			_count("trick_meal:" + trick)
	week.days[str(day)] = record
	if trick != "":
		_moment_source("trick_meal")
	week.weak = false  # a próxima refeição na hora tira o "fraquinho"
	_count("meal_on_time")
	Events.meal_given.emit(period, true)
	# Dia da chegada estendido (dias 1 e 2): a patinha é uma só.
	var paw_taken := week.arrival_extended and day == int(Database.meals.get("arrival_day", 1)) + 1 and day_well_fed(day - 1)
	if not bool(record.get("paw", false)) and not paw_taken and meals_on_time(day) >= meals_needed(day):
		record["paw"] = true
		week.days[str(day)] = record
		_count("well_fed_day")
		Events.paw_earned.emit(day)
	if not forced:
		_secret_paw(item_id, day)
	return period


# --- Fechamento do dia, marmita e Deixar pronto (primeira semana, E01b) -------------

## Tiro fraquinho (dia fraco): vale até a próxima refeição na hora.
func tiro_weak() -> bool:
	return week.weak and food_lesson_done()


## A aula da comida (F02) já foi dada? Antes dela o relógio das refeições não existe para o jogador (sem reloginho,
## folha Hoje, pergunta Dar agora/Deixar pronto, ração sozinho, dia fraco, marmita, Bom dia/Boa noite); a patinha do dia da
## chegada continua contando por baixo. Vale também se o passo da aula (`week_story.json → food_lesson.quest`) já foi
## pego, e para saves que nunca abriram a caixinha (testes e saves de antes do Ato 1).
func food_lesson_done() -> bool:
	if progress.stat("arrival_box") == 0 or week.food_lesson:
		return true
	var quest := str(Database.week_story.get("food_lesson", {}).get("quest", ""))
	return quest != "" and progress.claimed_quests.has(quest)


## Marca a aula da comida como dada (chamado pela aula ao terminar).
func finish_food_lesson() -> void:
	if week.food_lesson:
		return
	week.food_lesson = true
	_changed()


## Algum passo da história ativo pede comida ao Tiro (`feed:*`/`together:*` ainda não cumprido) ou a aula da comida está
## em andamento? Nesse caso nada pode mandar o Tiro dormir sozinho (a Parte B usa isto antes do "boceja e vai dormir").
func food_step_active() -> bool:
	if progress.stat("arrival_box") == 0:
		return false
	var lesson := str(Database.week_story.get("food_lesson", {}).get("quest", ""))
	for id: String in progress.active_steps().values():
		if id == lesson and not food_lesson_done():
			return true
		for goal: Dictionary in Database.quests.get(id, {}).get("goals", []):
			var key := str(goal.get("key", ""))
			if str(goal.type) == "stat" and (key == "feed" or key.begins_with("feed:") or key.begins_with("together:")) \
					and goal_value(goal) < int(goal.get("target", 1)):
				return true
	return false


## O Tiro pode ir dormir sozinho agora? (Hoje nenhuma regra o manda dormir; é o guarda que a cena de "boa noite" consulta.)
func auto_sleep_allowed() -> bool:
	return not food_step_active()


## Tigela de dois lugares: refeições guardadas esperando a janela, em ordem ({"item", "day", "period"}).
func stored_meals() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for entry: Dictionary in week.stored:
		list.append(entry.duplicate())
	return list


## A refeição guardada que come primeiro (vazio = nenhuma). Compatível com a tigela de um lugar.
func stored_meal() -> Dictionary:
	var list := stored_meals()
	return list[0] if not list.is_empty() else {}


## Recados da tigela que ainda não foram mostrados: o Tiro comeu sozinho ({"period", "hour", "minute", "item", "day"}).
func served_notes() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for note: Dictionary in week.served:
		if not bool(note.get("seen", false)):
			list.append(note.duplicate())
	return list


## Marca os recados como vistos (o Bom dia ou as boas-vindas já mostraram).
func mark_served_notes_seen() -> void:
	var changed := false
	for note: Dictionary in week.served:
		if not bool(note.get("seen", false)):
			note["seen"] = true
			changed = true
	if changed:
		_changed()


func _slot_period(slot: int) -> String:
	return str(Database.meals.periods.keys()[posmod(slot, 2)])


## Segundos (`_game_seconds()`) em que a janela do espaço fecha.
func _slot_end(slot: int) -> float:
	return float(floori(float(slot) / 2.0)) * 86400.0 + _window_offset(meal_window(_slot_period(slot)).y)


## Marca como conferido tudo que já fechou antes de agora (começo do save, sem punir o passado).
func _week_init_settle() -> void:
	var local := _game_seconds()
	var today := int(floor(local / 86400.0))
	var slot := today * 2 + 1
	while slot > today * 2 - 4 and _slot_end(slot) > local:
		slot -= 1
	week.settled = slot


## Confere as janelas que fecharam (também com o jogo fechado): ração sozinho, dia fraco, marmita,
## e a refeição guardada que o Tiro come ao abrir a janela. Devolve true se algo mudou.
func update_week() -> bool:
	_week_touch()
	if week.settled < 0:
		_week_init_settle()
	var clock := "%d:%d:%s" % [week_day(), content_day(), meal_period_now()]
	var changed := _sync_week_farm() or clock != _week_story_clock
	_week_story_clock = clock
	var local := _game_seconds()
	var lesson := food_lesson_done()
	var guard := 0
	while guard < 400 and _slot_end(week.settled + 1) <= local:
		guard += 1
		week.settled += 1
		if lesson:  # antes da aula nada é cobrado: o passado só é marcado como conferido
			_settle_slot(week.settled)
		changed = true
	var today := int(floor(local / 86400.0))
	if lesson and not week.stored.is_empty():
		for entry: Dictionary in stored_meals():
			if int(entry.day) == today and meal_period_now() == str(entry.period):
				changed = _eat_stored(entry) or changed
	if changed:
		_changed()
	return changed


func _settle_slot(slot: int) -> void:
	var local_day := floori(float(slot) / 2.0)
	var period := _slot_period(slot)
	var day := local_day - week.started_day + 1
	if day < 1:
		return
	for entry: Dictionary in stored_meals():
		if int(entry.day) == local_day and str(entry.period) == period:
			_eat_stored(entry)
	var record: Dictionary = week.day_record(day).duplicate(true)
	if not record.has(period):
		record[period] = {"at": week_now(), "on_time": false, "item": "ration", "auto": true}
		dog.apply(Database.meals.get("ration", {}), now())
		week.days[str(day)] = record
		Events.meal_missed.emit(period)
	if posmod(slot, 2) == 1 and not is_arrival_day(day):
		_close_day(day)
	_sync_week_dailies(day)


## Fim do dia: bem alimentado zera a sequência; senão é dia fraco (não conta, Tiro fraquinho).
func _close_day(day: int) -> void:
	var record: Dictionary = week.day_record(day).duplicate(true)
	if bool(record.get("paw", false)):
		week.weak_streak = 0
		return
	record["weak"] = true
	week.days[str(day)] = record
	week.weak = true
	week.weak_streak += 1
	_count("weak_day")
	Events.weak_day.emit(day)
	if week.weak_streak >= int(Database.meals.get("lunchbox_after_weak_days", 2)):
		# A vovó manda a marmita: o Tiro nunca passa fome nem adoece por um dia ruim.
		dog.apply(Database.meals.get("lunchbox", {}), now())
		week.weak = false
		week.weak_streak = 0
		week.lunchboxes += 1
		_count("lunchbox")
		Events.lunchbox_given.emit(day)


## Próximas janelas ainda fechadas onde cabe uma refeição guardada, em ordem, uma por período ainda sem refeição guardada:
## [{"day" (dia do Tiro, número absoluto), "period", "week_day"}]. Hoje: almoço e jantar de hoje se ainda não abriram;
## às 20h: o almoço (e o jantar) de amanhã; à meia-noite: os dois do dia que começa às 6h.
func meal_targets() -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	var local := _game_seconds()
	var today := int(floor(local / 86400.0))
	var taken: Array[String] = []
	for entry: Dictionary in week.stored:
		taken.append(str(entry.period))
	for d in range(today, today + 3):
		for period: String in Database.meals.periods:
			if period in taken:
				continue
			if local < float(d) * 86400.0 + _window_offset(meal_window(period).x):
				targets.append({"day": d, "period": period, "week_day": d - week.started_day + 1})
				taken.append(period)
	return targets


## Próxima janela livre para guardar a refeição: {"day", "period", "week_day"}; vazio = nenhuma.
func meal_next_target() -> Dictionary:
	var targets := meal_targets()
	return targets[0] if not targets.is_empty() else {}


## Por que não dá para guardar a refeição ("" = dá). Consulta pura.
func store_meal_error(item_id: String) -> String:
	if not food_lesson_done():
		return "Ainda não"
	if not is_meal_item(item_id):
		return "Só uma refeição pode ficar guardada"
	if inventory.count(item_id) < 1:
		return "Você não tem isso"
	if week.stored.size() >= int(Database.meals.get("stored_slots", 2)):
		return "A tigela já está cheia"
	var info := meal_info()
	if info.arrival and int(info.on_time) < Database.meals.periods.size():
		return "No primeiro dia, dê agora"
	var period := str(info.period)
	if period != "" and not bool(info.done.get(period, {}).get("on_time", false)):
		return "É hora de comer: dê agora"
	return "" if not meal_next_target().is_empty() else "Sem janela à vista"


## Primeira refeição do dia do Tiro (nenhuma dada na hora ainda)? Nela a pergunta Dar agora/Deixar pronto não aparece.
func first_meal_of_day() -> bool:
	return meals_on_time(_routine_day_number()) == 0


## A pergunta "Dar agora / Deixar pronto" deve aparecer para esta comida? Só depois da aula, só quando a refeição não conta
## agora e dá para guardar, e nunca na primeira refeição de um dia (aí ele simplesmente come).
func meal_ask_allowed(item_id: String) -> bool:
	return food_lesson_done() and is_meal_item(item_id) and meal_error(item_id) != "" \
		and store_meal_error(item_id) == "" and not first_meal_of_day()


## Deixar pronto: guarda a refeição para a próxima janela livre; o Tiro come sozinho ao abrir, mesmo com o jogo fechado.
func store_meal(item_id: String) -> String:
	var error := store_meal_error(item_id)
	if error != "":
		return error
	var target := meal_next_target()
	inventory.remove(item_id)
	week.stored.append({"item": item_id, "day": int(target.day), "period": str(target.period)})
	var order: Array = Database.meals.periods.keys()
	week.stored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.day) < int(b.day) or (int(a.day) == int(b.day) and order.find(str(a.period)) < order.find(str(b.period))))
	_count("meal_stored")
	Events.meal_stored.emit(str(target.period))
	_changed()
	return ""


## Devolve à Mochila uma refeição guardada (a do período dado; vazio = a que come primeiro), se ainda não foi comida.
func cancel_stored_meal(period: String = "") -> String:
	for i in week.stored.size():
		if period == "" or str(week.stored[i].period) == period:
			inventory.add(str(week.stored[i].item), 1)
			week.stored.remove_at(i)
			_changed()
			return ""
	return "Não tem refeição guardada"


## O Tiro come uma refeição guardada (a janela abriu). Conta como refeição na hora do período guardado, ao contrário
## do que ao vivo mantém `on_time_bonus` e o pedido de truque só para quem dá na hora (`_register_meal` pula os dois).
func _eat_stored(entry: Dictionary) -> bool:
	var index := -1
	for i in week.stored.size():
		if int(week.stored[i].day) == int(entry.day) and str(week.stored[i].period) == str(entry.period):
			index = i
	if index < 0:
		return false
	var item := str(entry.item)
	var period := str(entry.period)
	var day := int(entry.day) - week.started_day + 1
	week.stored.remove_at(index)
	inventory.add(item, 1)
	_forced_meal = period
	_forced_day = day
	var ok := feed(item)
	_forced_meal = ""
	_forced_day = 0
	if not ok:
		inventory.remove(item)
		return false
	_note_served(entry)
	_sync_week_dailies(day)
	_count("meal_stored_eaten")
	Events.stored_meal_eaten.emit(period)
	return true


## Guarda o recado "Ele comeu o almoço às 11h12": a hora cai nos primeiros 20 minutos da janela, fixa por dia e semente
## (o jogo pode estar fechado; mostra a hora real só quando já passou).
func _note_served(entry: Dictionary) -> void:
	var window_start := _week_time_of(float(int(entry.day)) * 86400.0 + _window_offset(meal_window(str(entry.period)).x))
	var minutes := posmod(hash([growth.taste_seed, int(entry.day), str(entry.period)]), 20)
	var at := minf(week_now(), window_start + float(minutes) * 60.0)
	var parts := Time.get_time_dict_from_unix_time(_local_time(at))
	week.served.append({"period": str(entry.period), "item": str(entry.item), "day": int(entry.day) - week.started_day + 1,
		"hour": int(parts.hour), "minute": int(parts.minute), "seen": false})
	while week.served.size() > 6:
		week.served.pop_front()


# --- Aula da comida (primeira semana, F02B) -----------------------------------------

## Toque em que a aula da comida está (0 = ainda não começou; 1 a 5 = o toque). Só quem guarda é o estado: a tela é do `LessonGuide`.
func food_lesson_step() -> int:
	return int(week.tutorial.get("food_lesson", {}).get("step", 0))


## Dados salvos da aula: {"step", "branch" (hora em que começou), "feed0" (refeições dadas antes do toque 3)}.
func food_lesson_data() -> Dictionary:
	return week.tutorial.get("food_lesson", {}).duplicate()


func set_food_lesson_step(step: int, extra: Dictionary = {}) -> void:
	var before := food_lesson_data()
	var data := before.duplicate()
	data["step"] = step
	data.merge(extra, true)
	if data == before:
		return
	week.tutorial["food_lesson"] = data
	_changed()


## A aula começou e ainda não terminou: o relógio já aparece (para o toque 1 apontar para ele), mesmo antes de a aula acabar.
func food_lesson_running() -> bool:
	return progress.stat("arrival_box") > 0 and not week.food_lesson and food_lesson_step() > 0


## O relógio das refeições já existe para o jogador? Depois da aula, e durante ela (o toque 1 aponta o reloginho).
func food_clock_on() -> bool:
	return food_lesson_done() or food_lesson_running()


## A refeição que a aula manda arrastar (`week_story.json → food_lesson.item`, a papinha).
func food_lesson_item() -> String:
	return str(Database.week_story.get("food_lesson", {}).get("item", "puppy_mash"))


## Refeições que o Tiro tem na Mochila agora, na ordem do catálogo (a aula e o Deixar pronto escolhem entre elas).
func meal_items_owned() -> Array[String]:
	var list: Array[String] = []
	for id: String in Database.items:
		if inventory.count(id) > 0 and Database.items[id].has("feed") and is_meal_item(id):
			list.append(id)
	return list


## A aula da comida pode começar agora? O passo dela (`week_story.json → food_lesson.quest`) é o da vez, o Tiro ainda não a
## viu e já há uma refeição na Mochila para arrastar.
func food_lesson_startable() -> bool:
	if progress.stat("arrival_box") == 0 or week.food_lesson:
		return false
	var quest := str(Database.week_story.get("food_lesson", {}).get("quest", ""))
	if quest == "" or progress.claimed_quests.has(quest) or not progress.active_steps().values().has(quest):
		return false
	return inventory.count(food_lesson_item()) > 0


## Hora do dia para as falas da aula: "window" (dentro do almoço ou do jantar), "day" (de dia, fora das janelas) ou
## "night" (da janela do jantar até a virada do dia, 22h às 6h).
func food_lesson_branch() -> String:
	if meal_period_now() != "":
		return "window"
	var order: Array = Database.meals.periods.keys()
	if week_hour() >= meal_window(str(order[order.size() - 1])).y or week_hour() < _day_start_hour():
		return "night"
	return "day"


## A primeira patinha da aula é garantida a qualquer hora (dia da chegada ou aula dada tarde): se a refeição dada na aula
## ainda não deu a patinha do dia, ela dá. Devolve true se agora concedeu.
func grant_lesson_paw(item_id: String = "") -> bool:
	_week_touch()
	var day := _routine_day_number()
	var record: Dictionary = week.day_record(day).duplicate(true)
	if bool(record.get("paw", false)):
		return false
	if meals_on_time(day) == 0:
		var order: Array = Database.meals.periods.keys()
		var period := str(order[0]) if week_hour() < 16 else str(order[order.size() - 1])
		record[period] = {"at": week_now(), "on_time": true, "item": item_id if item_id != "" else "lesson", "lesson": true}
		_count("meal_on_time")
	record["paw"] = true
	week.days[str(day)] = record
	week.weak = false
	_count("well_fed_day")
	Events.paw_earned.emit(day)
	_changed()
	return true


## Carimbos da cartela de patinhas, em ordem de dia: {"kind": "paw"|"weak", "day", "item" (prato do dia), "arrival"}.
func paw_stamps() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var days: Array[int] = []
	for key: String in week.days:
		days.append(int(key))
	days.sort()
	for day: int in days:
		var record: Dictionary = week.days[str(day)]
		if bool(record.get("paw", false)):
			var item := "puppy_mash"
			for period: String in Database.meals.periods:
				var entry: Dictionary = record.get(period, {})
				if bool(entry.get("on_time", false)) and str(entry.get("item", "")) not in ["", "ration", "lesson"]:
					item = str(entry.item)
			list.append({"kind": "paw", "day": day, "item": item, "arrival": is_arrival_day(day)})
		elif bool(record.get("weak", false)):
			list.append({"kind": "weak", "day": day, "item": "", "arrival": false})
		if week.bonus_paws.has(str(day)):
			list.append({"kind": "bonus", "day": day, "item": str(secret_config().get("stew", "")), "arrival": false})
	return list


## Próxima janela de refeição, para "Próximo almoço em 2 h": {"period", "seconds", "open"}. Aberta agora e ainda sem ✓ = open.
func next_meal_in() -> Dictionary:
	var info := meal_info()
	var now_s := float(week_hour() * 3600 + week_minute() * 60)
	var best := {}
	for period: String in Database.meals.periods:
		var window := meal_window(period)
		var start := float(window.x) * 3600.0
		if now_s >= start and now_s < float(window.y) * 3600.0 and not bool(info.done.get(period, {}).get("on_time", false)):
			return {"period": period, "seconds": 0, "open": true}
		var wait := start - now_s
		if wait <= 0.0:
			wait += 86400.0
		if best.is_empty() or wait < float(best.seconds):
			best = {"period": period, "seconds": int(wait), "open": false}
	return best


## Quando começa o primeiro combinado, para o Boa noite do dia 1: {"when": "hoje"|"amanhã"|"depois de amanhã", "hour"}.
func first_deal_when() -> Dictionary:
	var deal := first_deal_at()
	var today := floori(float(_local_time(week_now())) / 86400.0)
	var that := floori(float(_local_time(float(deal.at))) / 86400.0)
	var when := "hoje" if that <= today else ("amanhã" if that == today + 1 else "depois de amanhã")
	return {"when": when, "hour": int(deal.hour), "period": str(deal.period)}


## Hora local (0..23) do relógio da semana.
func week_hour() -> int:
	return int(Time.get_time_dict_from_unix_time(_local_time(week_now())).hour)


func week_minute() -> int:
	return int(Time.get_time_dict_from_unix_time(_local_time(week_now())).minute)


## DEV: leva o relógio da semana ao dia N (1..9), mantendo a hora.
func dev_week_goto(day: int) -> void:
	if not BuildInfo.is_dev(): return
	week.clock_offset += float(day - week_day()) * 86400.0
	week.high_day = week_day_number()  # DEV pode voltar no tempo
	_changed()


## DEV: põe a história no capítulo N, para cima ou para baixo, só marcando os passos
## principais como pegos: sem prêmios, sem comemoração, sem mexer no relógio da semana.
func dev_content_day(chapter: int) -> void:
	if not BuildInfo.is_dev(): return
	for index in range(1, Database.progression.chapters.size() + 1):
		for id: String in progress.main_quests(index):
			if index < chapter:
				progress.claimed_quests[id] = true
			else:
				progress.claimed_quests.erase(id)
	_changed()


## DEV: leva o relógio da semana à hora H (0..23) do mesmo dia do Tiro (a virada é às 6h: de 0h a 5h59 é o fim do dia).
func dev_week_hour(hour: int) -> void:
	if not BuildInfo.is_dev(): return
	week.clock_offset += _window_offset(hour) - fposmod(_game_seconds(), 86400.0)
	week.high_day = week_day_number()
	_changed()


## DEV: soma (ou tira) horas ao relógio da semana.
func dev_week_shift_hours(hours: int) -> void:
	if not BuildInfo.is_dev(): return
	week.clock_offset += float(hours) * 3600.0
	week.high_day = maxi(week.high_day, week_day_number()) if hours > 0 else week_day_number()
	_changed()


## DEV: volta o relógio da semana ao real.
func dev_week_reset_clock() -> void:
	if not BuildInfo.is_dev(): return
	week.clock_offset = 0.0
	week.high_day = week_day_number()
	_changed()


## DEV: marca a refeição do período ("lunch" ou "dinner") de hoje como dada na hora, sem gastar comida.
## Devolve o aviso; "" fora da versão dev.
func dev_week_meal(period: String) -> String:
	if not BuildInfo.is_dev(): return ""
	if not Database.meals.get("periods", {}).has(period):
		return "Período desconhecido: %s" % period
	_week_touch()
	var day := week_day()
	var record: Dictionary = week.day_record(day).duplicate(true)
	record[period] = {"at": week_now(), "on_time": true, "item": "dev"}
	week.days[str(day)] = record
	if not bool(record.get("paw", false)) and meals_on_time(day) >= meals_needed(day):
		record["paw"] = true
		week.days[str(day)] = record
		_count("well_fed_day")
		Events.paw_earned.emit(day)
	_changed()
	return "Refeição (%s) do dia %d marcada" % [str(Database.meals.periods[period].name).to_lower(), day]


## DEV: entrega o mesmo kit da banca, sem cobrar nem exigir o dia.
func dev_week_kit(kit: String) -> String:
	if not BuildInfo.is_dev():
		return ""
	var id: String = {"galinheiro": "week_coop", "caminha": "week_bed", "mordedor": "week_teether"}.get(kit, "")
	if id == "":
		return "Kit desconhecido"
	var data := shop_pack(id)
	if _shop_pack_owned(id, data):
		return "Você já tem"
	var error := storage_error(_pack_items(data, 1))
	if error != "":
		return error
	_apply_shop_pack(id, data, 1)
	return ""


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
		"fishing": fishing.to_dict(),
		"week": week.to_dict(),
		"album": album.to_dict(),
		"economy": economy.to_dict(),
	}


func from_dict(data: Dictionary) -> void:
	_yard_round.clear()
	_trick_lesson.clear()
	_trick_show.clear()
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
	_register_dishes()
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
	unlocked_plots = clampi(int(data.get("unlocked_plots", maxi(plots.size(), int(Database.farm.get("initial_plots", 3))))), 0, int(Database.farm.corn_plot))
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
	fishing = FishingState.new()
	fishing.from_dict(data.get("fishing", {}))
	week = WeekState.new()
	week.from_dict(data.get("week", {}))
	_prune_moment_periods()
	if week.started_day < 0:
		week.started_day = week_day_number()
		_anchor_arrival()
	_week_touch()
	if week.settled < 0:
		_week_init_settle()
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
				var remaining := animal_capacity(Database.animals[id].station) - animal_count(Database.animals[id].station)
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
	_auto_store_baggage()
	_settle_fishing_on_load()
	_changed()


func _ensure_stations() -> void:
	for id: String in Database.stations:
		if not stations.has(id):
			stations[id] = StationState.new()


func _changed() -> void:
	_auto_claim_quests()
	_sync_week_farm()
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
	_sync_week_story()
	_sync_week_routine()
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


# --- Livro de receitas (Primeira semana, E11) --------------------------------------------------------------

func _recipe_tier(rows: Array, points: int) -> Dictionary:
	var result: Dictionary = {}
	for row: Dictionary in rows:
		if points < int(row.points):
			break
		result = row
	return result


func recipe_mastery(key: String) -> Dictionary:
	var rows: Array = Database.recipe_book.mastery
	var record := dish_record(key)
	var points := int(record.get("points", 0))
	var tier := _recipe_tier(rows, points)
	var every := int(tier.get("gift_every", 0)) if _recipe_gift_allowed(key) else 0
	var next := 0
	for row: Dictionary in rows:
		if int(row.points) > points:
			next = int(row.points)
			break
	return tier.merged({"score": points, "next": next,
		"until_gift": every - int(record.get("gift_progress", 0)) if every > 0 else 0})


func _recipe_gift_allowed(key: String) -> bool:
	if key.begins_with("recipe:"):
		var def: Dictionary = Database.recipes.get(key.trim_prefix("recipe:"), {})
		return DishRules.is_meal(str(def.get("dish_type", ""))) or str(def.get("dish_type", "")) in ["petisco", "biscoito"]
	var type_id := key.get_slice(":", 1)
	return DishRules.is_meal(type_id) or type_id in ["petisco", "biscoito"]


func chef_info() -> Dictionary:
	var points := 0
	for record: Dictionary in week.dishes.values():
		points += int(record.get("points", 0))
	return _recipe_tier(Database.recipe_book.chef, points).merged({"score": points})


func _recipe_preparation(key: String, stars: int, together: bool) -> Dictionary:
	var mastery := recipe_mastery(key)
	var quality := clampi(stars, 1, 3) if together else int(mastery.stars)
	var time := CookRules.time_factor(quality) if together else float(mastery.time)
	return {"stars": quality, "time": time, "points": quality if together else 1,
		"tier": int(mastery.points), "specialty": int(mastery.points) == 30, "gift": int(int(mastery.until_gift) == 1),
		"gift_progress": 0 if int(mastery.until_gift) <= 1 else int(dish_record(key).get("gift_progress", 0)) + 1}


func _record_recipe_preparation(key: String, preparation: Dictionary) -> void:
	var record := dish_record(key)
	var rows: Array = Database.recipe_book.mastery
	record["points"] = mini(int(rows.back().points), int(record.get("points", 0)) + int(preparation.points))
	var next_tier := _recipe_tier(rows, int(record.points))
	record["gift_progress"] = int(preparation.gift_progress) if int(next_tier.points) == int(preparation.tier) else 0


func _discover_book_dish(type_id: String, ingredients: Array, source: String) -> bool:
	var key := dish_key(type_id, ingredients)
	if key == "" or week.dishes.has(key):
		return false
	week.dishes[key] = {"stars": 0, "made": 0, "day": week_day(), "source": source}
	_count("dishes_known")
	Events.dish_discovered.emit(key, DishRules.name_of(type_id, ingredients))
	Events.toast_requested.emit("Prato novo: %s!" % DishRules.name_of(type_id, ingredients))
	return true


func _recipe_book_section(id: String) -> Dictionary:
	if not week.recipe_book.has(id):
		week.recipe_book[id] = {}
	return week.recipe_book[id]


func _named_book_recipe(id: String) -> Dictionary:
	for entry: Dictionary in Database.dishes.named:
		if str(entry.id) == id:
			return entry
	return {}


func recipe_secret(id: String) -> Dictionary:
	var config: Dictionary = Database.recipe_book.secrets.get(id, {})
	var entry := _named_book_recipe(id)
	if config.is_empty() or entry.is_empty():
		return {}
	var key := dish_key(str(entry.type), entry.ingredients)
	var owns: Dictionary = week.recipe_book.get("pieces", {})
	var pieces: Array = owns.get(id, [])
	var hinted: bool = week.recipe_book.get("hints", {}).has(id)
	var state := recipe_book_state(key)
	var hint: Dictionary = config.hint
	var revealed: Array[String] = []
	if hinted:
		revealed.append(str(hint.ingredient))
	var ingredients := DishRules.canon(entry.ingredients)
	ingredients.erase(str(hint.ingredient))
	for i: int in pieces:
		if i < ingredients.size() and ingredients[i] not in revealed:
			revealed.append(ingredients[i])
	var next := {}
	for i in config.pieces.size():
		if i in pieces:
			continue
		var origin: Array = config.pieces[i]
		var source: Dictionary = Database.recipe_book.sources[origin[0]]
		var so_far := int(week.recipe_book.get("sources", {}).get(origin[0], 0))
		next = source.merged({"left": maxi(0, int(origin[1]) - so_far)})
		break
	return {"id": id, "key": key, "state": state, "name": str(entry.name) if state not in ["pista", "desconhecida"] else "Receita secreta",
		"pieces": pieces.duplicate(), "hinted": hinted, "hint": hint, "revealed": revealed, "next": next}


func recipe_book_state(key: String) -> String:
	var record := dish_record(key)
	var tasted: bool = week.recipe_book.get("tasted", {}).has(_book_taste_key(key))
	if not record.is_empty() or tasted:
		var tiers: Array = Database.recipe_book.mastery
		if int(record.get("points", 0)) >= int(tiers[2].points):
			return "dominada"
		return "provada" if tasted else "descoberta"
	var parsed := DishRules.parse_key(key.trim_prefix("dish:"))
	if not parsed.is_empty():
		var id := str(DishRules.named(str(parsed.type), parsed.ingredients).get("id", ""))
		if week.recipe_book.get("hints", {}).has(id) or week.recipe_book.get("pieces", {}).has(id):
			return "pista"
	return "desconhecida"


func note_recipe_hint(source: String) -> void:
	if source == "lais":
		var made_mingau := recipe_book_entries().any(func(entry: Dictionary) -> bool: return entry.type == "mingau" and int(dish_record(str(entry.key)).get("made", 0)) > 0)
		if not made_mingau:
			return
	for id: String in Database.recipe_book.secrets:
		var hint: Dictionary = Database.recipe_book.secrets[id].hint
		if str(hint.source) != source or week.recipe_book.get("hints", {}).has(id):
			continue
		_recipe_book_section("hints")[id] = true
		Events.toast_requested.emit("Pista de receita: %s" % str(hint.text))
		_changed()


func _recipe_source(source: String) -> void:
	var counts := _recipe_book_section("sources")
	counts[source] = int(counts.get(source, 0)) + 1
	for id: String in Database.recipe_book.secrets:
		var origins: Array = Database.recipe_book.secrets[id].pieces
		for i in origins.size():
			var origin: Array = origins[i]
			if str(origin[0]) != source or int(counts[source]) < int(origin[1]):
				continue
			var found := _recipe_book_section("pieces")
			var pieces: Array = found.get(id, [])
			if i in pieces:
				continue
			pieces.append(i)
			found[id] = pieces
			if pieces.size() == origins.size():
				var recipe := _named_book_recipe(id)
				_discover_book_dish(str(recipe.type), recipe.ingredients, "pieces")
			Events.recipe_piece_found.emit(id, pieces.size())


func _book_taste_key(key: String) -> String:
	if not key.begins_with("recipe:"):
		return key
	var recipe: Dictionary = Database.recipes.get(key.trim_prefix("recipe:"), {})
	var dish := dish_of_item(Database.recipe_output(recipe))
	return "dish:" + str(dish.key) if not dish.is_empty() else key


func _note_book_taste(dish: Dictionary, item: String) -> void:
	_note_routine_taste(dish, item)
	var key := "dish:" + str(dish.key)
	var tasted := _recipe_book_section("tasted")
	if tasted.has(key):
		return
	tasted[key] = item


func recipe_ingredient_stock(ingredient: String) -> int:
	var stock := 0
	for item: String in DishRules.ingredient(ingredient).get("items", []):
		stock += inventory.count(item)
	return stock


func recipe_book_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var seen := {}
	for recipe_id: String in Database.recipes_for("stove"):
		var output := Database.recipe_output(Database.recipes[recipe_id])
		var dish := dish_of_item(output)
		if dish.is_empty() or dish.ingredients.is_empty():
			continue
		var key := "recipe:" + recipe_id
		if dish_record(key).is_empty() and recipe_book_state(key) != "provada":
			continue
		entries.append({"key": key, "type": dish.type, "ingredients": dish.ingredients, "recipe": recipe_id, "item": output})
		seen["dish:" + str(dish.key)] = true
	for entry: Dictionary in known_dishes():
		if not seen.has(str(entry.key)):
			entries.append(entry)
	for key: String in week.recipe_book.get("tasted", {}):
		if week.dishes.has(key) or seen.has(key):
			continue
		var parsed := DishRules.parse_key(key.trim_prefix("dish:"))
		if not parsed.is_empty():
			entries.append(parsed.merged({"key": key}))
	return entries


func recipe_book_rows(selected: Array = [], include_secrets: bool = true) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for entry: Dictionary in recipe_book_entries():
		if not selected.all(func(id: String) -> bool: return id in entry.ingredients):
			continue
		var type_id := str(entry.type)
		var named := DishRules.named(type_id, entry.ingredients)
		if not include_secrets and bool(named.get("secret", false)):
			continue
		var row := entry.duplicate()
		var recipe := str(row.get("recipe", ""))
		row["inputs"] = dish_inputs(row.ingredients) if recipe == "" else recipe_inputs(recipe)
		row["missing"] = 0
		for item: String in row.inputs:
			row.missing += maxi(0, int(row.inputs[item]) - inventory.count(item))
		row["name"] = DishRules.name_of(type_id, row.ingredients) if recipe == "" else Database.item_name(str(row.item))
		row["item"] = row.get("item", DishRules.icon_item(type_id, row.ingredients))
		row["stars"] = int(dish_record(str(row.key)).get("stars", 0))
		row["state"] = recipe_book_state(str(row.key))
		rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.name).naturalnocasecmp_to(str(b.name)) < 0 if a.missing == b.missing else int(a.missing) < int(b.missing))
	return rows


var _book_combinations: Dictionary = {}


func _recipe_combinations() -> Array:
	var day := mini(11, content_day())
	if not _book_combinations.has(day):
		_book_combinations[day] = DishRules.combinations(day)
	return _book_combinations[day]


func recipe_undiscovered_count(ingredient: String) -> int:
	var known := {}
	for entry: Dictionary in recipe_book_entries():
		known[dish_key(str(entry.type), entry.ingredients)] = true
	var total := 0
	for entry: Dictionary in _recipe_combinations():
		if ingredient in entry.ingredients and not known.has(dish_key(str(entry.type), entry.ingredients)):
			total += 1
	return total


func recipe_novelty(selected: Array = [], taste: String = "", limit: int = 1) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not has_upgrade("stove"):
		return result
	var tasted: Dictionary = week.recipe_book.get("tasted", {})
	var stocks := {}
	for id: String in DishRules.order():
		stocks[id] = recipe_ingredient_stock(id)
	for entry: Dictionary in _recipe_combinations():
		var type_id := str(entry.type)
		if not selected.all(func(id: String) -> bool: return id in entry.ingredients):
			continue
		if not entry.ingredients.all(func(id: String) -> bool: return int(stocks[id]) >= entry.ingredients.count(id)):
			continue
		if tasted.has(dish_key(type_id, entry.ingredients)):
			continue
		if taste != "" and (not DishRules.is_meal(type_id) or DishRules.taste(entry.ingredients) != taste):
			continue
		result.append(entry)
		if result.size() >= limit:
			break
	return result


var _recipe_sniff_signature := ""
var _recipe_sniff_possible := false


func recipe_can_sniff() -> bool:
	var signature := "%d:%d:%s:%s" % [content_day(), int(has_upgrade("stove")),
		week.recipe_book.get("tasted", {}).size(), inventory.counts.hash()]
	if signature != _recipe_sniff_signature:
		_recipe_sniff_signature = signature
		_recipe_sniff_possible = not recipe_novelty().is_empty()
	return _recipe_sniff_possible


func recipe_ingredient_day() -> Dictionary:
	var config: Dictionary = Database.recipe_book.daily
	var day := week_day()  # o ingrediente renova a cada dois dias de calendário; só abre pelo capítulo
	if not has_upgrade("stove") or content_day() < int(config.from_chapter) or posmod(day - int(config.from_chapter), 2) != 0:
		return {}
	var cycle: Array = config.cycle
	var start := posmod(day - int(config.from_chapter), cycle.size() * 2) / 2
	var available := DishRules.available(content_day())
	for offset in cycle.size():
		var id := str(cycle[(start + offset) % cycle.size()])
		if id in available:
			return {"id": id, "name": DishRules.ingredient(id).name, "day": day, "coins": int(config.base_coins) * 2}
	return {}


func _note_daily_ingredient(ingredients: Array, fresh: bool) -> void:
	var daily := recipe_ingredient_day()
	if not fresh or daily.is_empty() or str(daily.id) not in ingredients:
		return
	var completed := _recipe_book_section("daily")
	if int(completed.get("day", 0)) == int(daily.day):
		return
	completed["day"] = int(daily.day)
	_count("ingredient_of_day")
	Events.toast_requested.emit("Ingrediente do dia! Pegue o prêmio nas Diárias.")


func _novel_food_matches(item: String, taste: String) -> bool:
	var dish := dish_of_item(item)
	return not dish.is_empty() and DishRules.is_meal(str(dish.type)) and not dish.ingredients.is_empty() \
		and not week.recipe_book.get("tasted", {}).has("dish:" + str(dish.key)) and DishRules.taste(dish.ingredients) == taste


func _novel_food(taste: String) -> String:
	for item: String in inventory.counts:
		if inventory.count(item) > 0 and _novel_food_matches(item, taste):
			return item
	return ""

# --- História da primeira semana --------------------------------------------------

func finish_week_arrival() -> void:
	if progress.seen.has("intro"):
		return
	_count("arrival_box")
	# Antes da caixinha as portas do Ato 1 (`story_gate`) valem abertas e o `reset` as marcou como vistas:
	# agora que fecham, o Sítio volta a ser novidade e é anunciado quando o passo 8 for pego.
	for world_id: String in Database.worlds:
		if Database.worlds[world_id].get("requirements", {}).has("story_gate"):
			progress.seen.erase("world:" + world_id)
	mark_seen(["intro"])


## Fim do passeio guiado pela casa (primeira missão): conta o objetivo e libera o Pegar.
func finish_home_tour() -> void:
	if progress.stat("home_tour") > 0:
		return
	_count("home_tour")
	_changed()


## O passeio da casa já chegou ao passo do botão Cuidar: ele aparece (vazio, com a roleta fechada) antes de ser liberado pela história.
func home_tour_shows_care() -> bool:
	return progress.stat("arrival_box") > 0 and int(week.tutorial.get("home_tour", {}).get("seq", 0)) >= 1


func week_quest_day(id: String) -> int:
	var quest: Dictionary = Database.quests.get(id, {})
	var day := int(quest.get("chapter", 0))
	return day if quest.get("kind") == "main" and day >= 1 and day <= week_last_chapter() else 0


func note_week_pier() -> void:
	if farm_lake_open() and progress.stat("week_pier") == 0:
		_count("week_pier")
		_changed()


func week_growth_error(target: String) -> String:
	# O save real passa pela caixinha; as outras fases usam só o painel de crescimento.
	if progress.stat("arrival_box") == 0:
		return ""
	var step := str(Database.week_story.growth_steps.get(target, ""))
	if step == "":
		return ""
	if progress.current_main_quest() != step:
		# O passo anterior já está feito e só falta pegar o prêmio: o texto aponta para a pílula do alto.
		return "Pegue o prêmio do passo" if quest_error(progress.current_main_quest()) == "" else "Continue a História"
	if target == "teething" and not week_farewell_complete():
		return "Sirva o almoço de despedida"
	return ""


func week_meal_in_group(item: String, group: String) -> bool:
	var dish := dish_of_item(item)
	return not dish.is_empty() and DishRules.is_meal(str(dish.type)) and _dish_in_group(dish.ingredients, Database.growth.key_groups[group])


func week_farewell_complete() -> bool:
	return week.farewell.size() == Database.week_story.farewell.roles.size()


func week_farewell_error(role: String, item: String) -> String:
	if progress.current_main_quest() != str(Database.week_story.farewell.step) or content_day() < week_last_chapter():
		return "O almoço é no último capítulo da semana"
	if not Database.week_story.farewell.roles.has(role):
		return "Lugar desconhecido"
	if week.farewell.has(role):
		return "Prato já servido"
	if not is_meal_item(item) or inventory.count(item) == 0:
		return "Escolha uma refeição da Mochila"
	if role == "tiro" and (walking() or dog.sleeping):
		return "Sirva quando o Tiro estiver por perto e acordado"
	return ""


func serve_week_farewell(role: String, item: String) -> String:
	var error := week_farewell_error(role, item)
	if error != "":
		return error
	week.farewell[role] = item
	if role == "tiro":
		if not feed(item):
			week.farewell.erase(role)
			return "O Tiro não pôde comer"
	else:
		inventory.remove(item)
	if week_farewell_complete():
		_count("week_farewell")
		_album_event("week_farewell", {"world": "farm"})
	_changed()
	return ""


# --- Rotina e linhas da primeira semana --------------------------------------------

func _routine_day_number() -> int:
	return maxi(week.high_day, week_day_number()) - week.started_day + 1


func _week_routine_day(day: int, create: bool = false) -> Dictionary:
	if create and not week.routine.has("days"):
		week.routine["days"] = {}
	var days: Dictionary = week.routine.get("days", {})
	var key := str(week.started_day + day - 1)
	if create and not days.has(key):
		days[key] = {}
	return days.get(key, {})


func _week_routine_pick(day: int) -> void:
	if not farm_week_active() or day != _routine_day_number():
		return
	var record := _week_routine_day(day, true)
	if record.has("activity"):
		return
	var available: Array[String] = []
	for id: String in Database.week_routine.daily_counters:
		var def: Dictionary = Database.week_routine.daily[id]
		var upgrade := str(def.get("upgrade", ""))
		if content_day() < int(def.day) or (upgrade != "" and not has_upgrade(upgrade)):
			continue
		if id == "play" and not yard_open("ball"):
			continue
		if id == "fish" and not farm_lake_open():
			continue
		if id == "harvest" and accessible_plots() == 0:
			continue
		available.append(id)
	if not available.is_empty():
		record["activity"] = available[posmod(hash([growth.taste_seed, week.started_day + day - 1]), available.size())]


func week_daily_rows(day: int = -1) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if day < 0:
		day = _routine_day_number()
	var record := _week_routine_day(day)
	if not record.has("activity"):
		return rows
	var meals := week.day_record(day)
	var counters: Dictionary = record.get("counts", {})
	for id: String in ["lunch", "dinner", str(record.activity)]:
		var def: Dictionary = Database.week_routine.daily[id]
		var counter := str(Database.week_routine.daily_counters.get(id, ""))
		var value := int(meals.get(id, {}).get("on_time", false)) if counter == "" else int(counters.get(counter, 0))
		rows.append(def.merged({"id": id, "value": mini(int(def.target), value), "done": value >= int(def.target)}))
	return rows


func _sync_week_dailies(day: int) -> void:
	var rows := week_daily_rows(day)
	for row: Dictionary in rows:
		if row.done:
			# Nos Atos 1 e 2 a atividade conta como já considerada, mas não paga moeda (nem depois).
			_grant_automatic("week_daily:%d:%s" % [week.started_day + day - 1, row.id], row.rewards if ato2_done() else {})
	if not rows.is_empty() and rows.all(func(row: Dictionary) -> bool: return row.done):
		_grant_automatic("week_daily_seal:%d" % (week.started_day + day - 1), {})


func _routine_period_index() -> int:
	var hour := week_hour()
	var boundaries: Array = Database.week_routine.periods
	for index: int in range(boundaries.size() - 1, -1, -1):
		if hour >= int(boundaries[index]):
			return index
	return boundaries.size() - 1


func _routine_set(key: String, value: String) -> void:
	if not week.routine.has("sets"):
		week.routine["sets"] = {}
	var sets: Dictionary = week.routine.sets
	if not sets.has(key):
		sets[key] = {}
	sets[key][value] = true


func _count_week_routine(counter: String, amount: int) -> void:
	if progress.stat("arrival_box") == 0:
		return
	var is_period_action := counter in ["pet", "play", "trick_lesson"]
	if not is_period_action and counter not in Database.week_routine.daily_counters.values():
		return
	var day := _forced_day if _forced_day > 0 else _routine_day_number()
	if not is_period_action and not farm_week_active() and not _week_routine_day(day).has("activity"):
		return
	var record := _week_routine_day(day, true)
	if not record.has("counts"):
		record["counts"] = {}
	record.counts[counter] = int(record.counts.get(counter, 0)) + amount
	if counter in ["pet", "play"]:
		var period := _routine_period_index()
		var field := counter + "_periods"
		record[field] = int(record.get(field, 0)) | (1 << period)
		if counter == "pet":
			_routine_set("pet", "%d:%d" % [day, period])


func _note_routine_cooked(type: String, ingredients: Array, stars: int) -> void:
	if progress.stat("arrival_box") == 0:
		return
	for pair: Dictionary in DishRules.duples_of(ingredients):
		_routine_set("pairs", "%s:%s" % [pair.a, pair.b])
	var nutrients := DishRules.nutrients(type, ingredients, stars, growth.phase)
	if DishRules.nutrient_ids().all(func(id: String) -> bool: return int(nutrients.get(id, 0)) > 0):
		_routine_set("complete_dish", "yes")
	var recipe := DishRules.named(type, ingredients)
	var id := str(recipe.get("id", ""))
	if Database.recipe_book.secrets.has(id):
		_routine_set("secret", id)


func _note_routine_taste(dish: Dictionary, item: String) -> void:
	if progress.stat("arrival_box") == 0:
		return
	var flavor := DishRules.taste(dish.ingredients)
	if flavor in Database.week_routine.flavors:
		_routine_set("flavors", flavor)
	if dish.type in Database.week_routine.meal_types:
		_routine_set("types", str(dish.type))
	if week.recipe_book.get("tasted", {}).has("dish:" + str(dish.key)):
		return
	var day := _forced_day if _forced_day > 0 else _routine_day_number()
	if farm_week_active() or _week_routine_day(day).has("activity"):
		var record := _week_routine_day(day, true)
		record["dish"] = item
		_count("routine_new_dish")


func _week_line_definition(id: String) -> Dictionary:
	for line: Dictionary in Database.week_routine.lines.values():
		for step: Dictionary in line.steps:
			if step.id == id:
				return step
	return {}


func _week_line_value(id: String) -> int:
	var sets: Dictionary = week.routine.get("sets", {})
	match id:
		"invention": return progress.stat("routine_invent")
		"flavors", "types", "complete_dish", "favorite", "pet", "secret":
			return sets.get(id, {}).size()
		"pair", "pairs": return sets.get("pairs", {}).size()
		"five", "chef": return int(week.routine.get("book_count", 0))
		"sit_meal": return progress.stat("trick_meal:sit")
		"shows": return progress.stat("trick_show")
		"paw", "full_week": return well_fed_days()
		"skilled", "tricks":
			var level := int(Database.week_routine.skilled_level if id == "skilled" else Database.week_routine.learned_level)
			var result := 0
			for trick: String in Database.week_routine.tricks:
				result += int(trick_level(trick) >= level)
			return result
		"lunches", "streak":
			var total := 0
			for key: String in week.days:
				var meals: Dictionary = week.days[key]
				if id == "lunches":
					total += int(meals.get("lunch", {}).get("on_time", false))
				elif bool(meals.get("paw", false)) and bool(week.day_record(int(key) - 1).get("paw", false)):
					return 2
			return total
		"train", "nights", "play", "perfect":
			var result := 0
			var play_mask: int = (1 << Database.week_routine.periods.size()) - 1
			var days: Dictionary = week.routine.get("days", {})
			for civil: String in days:
				var record: Dictionary = days[civil]
				var counts: Dictionary = record.get("counts", {})
				match id:
					"train": result += int(int(counts.get("trick_lesson", 0)) > 0)
					"nights": result += int(bool(record.get("night", false)))
					"play":
						var bits := int(record.get("play_periods", 0))
						var periods := 0
						for index: int in Database.week_routine.periods.size():
							periods += int((bits & (1 << index)) != 0)
						result = maxi(result, periods)
						if bits == play_mask:
							return result
					"perfect":
						var day := int(civil) - week.started_day + 1
						if meals_on_time(day) >= Database.meals.periods.size() and int(counts.get("play", 0)) > 0 \
								and int(counts.get("pet", 0)) > 0 and int(counts.get("trick_lesson", 0)) > 0:
							return 1
			return result
	return 0


func week_line_rows(line: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var def: Dictionary = Database.week_routine.lines.get(line, {})
	var copy: Dictionary = Database.week_routine.text
	for step: Dictionary in def.get("steps", []):
		var done := economy.granted.has("week_line:" + str(step.id))
		var value := int(step.target) if done else mini(int(step.target), _week_line_value(str(step.id)))
		var lock_text := ""
		if content_day() < int(step.day):
			lock_text = str(copy.locked)
		elif step.go.has("kitchen") and not has_upgrade("stove"):
			lock_text = str(copy.stove_locked)
		rows.append(step.merged({"value": value, "done": done, "locked": lock_text != "",
			"lock_text": lock_text, "line": str(def.title)}))
	return rows


func week_routine_next_step() -> Dictionary:
	var available: Array[Dictionary] = []
	for line: String in Database.week_routine.lines:
		for row: Dictionary in week_line_rows(line):
			if not row.done and not row.locked:
				available.append(row)
				break
	if available.is_empty():
		return {}
	return available[posmod(hash([growth.taste_seed, week.started_day, week_day()]), available.size())]


func _sync_week_routine() -> void:
	if progress.stat("arrival_box") == 0:
		return
	var day := _routine_day_number()
	_week_routine_pick(day)
	_sync_week_dailies(day)
	if int(week.routine.get("book_size", -1)) != week.dishes.size():
		# Todas as chaves de prato são canônicas, incluindo as receitas fixas.
		var keys := {}
		for key: String in week.dishes:
			keys[_book_taste_key(key)] = true
		week.routine["book_size"] = week.dishes.size()
		week.routine["book_count"] = keys.size()
	for line: String in Database.week_routine.lines:
		for row: Dictionary in week_line_rows(line):
			if row.done or content_day() < int(row.day) or int(row.value) < int(row.target):
				continue
			var receipt := "week_line:" + str(row.id)
			_grant_automatic(receipt, row.get("rewards", {}) if ato2_done() else {})
			if row.has("photo"):
				_album_event("week_line_done", {"quest": str(row.id)})
			if row.has("hint"):
				_recipe_book_section("hints")[str(row.hint)] = true


## O Ato 1 (passos 1 a 8, só em casa) já acabou? Até lá a rotina do dia (moedas, Bom dia, Boa noite, reloginho)
## fica quieta: o jogador cuida do Tiro sem moeda e sem relógio. Saves que nunca abriram a caixinha não esperam.
func ato1_done() -> bool:
	return progress.stat("arrival_box") == 0 or progress.claimed_quests.has("lais_bed")


## O Ato 2 (passos 9 a 14: Sítio, vovó, fogão e primeira papinha) já acabou? Até lá não há moeda, banca nem compra de canteiro:
## tudo isso é do capítulo 2. Saves que nunca abriram a caixinha não esperam.
func ato2_done() -> bool:
	return progress.stat("arrival_box") == 0 or progress.claimed_quests.has("first_meal")


func week_card_candidates() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	if progress.stat("arrival_box") == 0 or not ato1_done() or not food_lesson_done():
		return cards  # Antes da aula da comida o relógio (Bom dia/Boa noite incluídos) não existe para o jogador.
	var day := _routine_day_number()
	var civil := week.started_day + day - 1
	if week_day_number() != civil or week.settled < civil * 2 - 1:
		return cards  # A volta após faltar precisa fechar as refeições de ontem antes do Bom dia.
	var record := _week_routine_day(day)
	if not farm_week_active() and not record.has("activity"):
		return cards
	var arrival := is_arrival_day(day)
	# No dia da chegada o "Bom dia" não faz sentido (ele acabou de chegar): o primeiro é o do dia 2 (F02 refaz os cartões).
	if not record.get("morning", false) and not arrival:
		cards.append({"kind": "morning", "day": day, "civil": civil})
	if not record.get("night", false) and week.settled >= civil * 2 + 1 \
			and (not arrival or week.day_record(day).get("paw", false)):
		cards.append({"kind": "night", "day": day, "civil": civil})
	return cards


func take_week_card(candidate: Dictionary) -> Dictionary:
	if candidate not in week_card_candidates():
		return {}
	var day := int(candidate.day)
	var kind := str(candidate.kind)
	var record := _week_routine_day(day, true)
	record[kind] = true
	var news: Array = Database.week_routine.news
	var chapter := clampi(progress.chapter_index(), 1, news.size())  # as novidades acompanham o capítulo, não o calendário
	var report := candidate.merged({"news": news[chapter - 1], "next": news[mini(chapter + 1, news.size()) - 1]})
	if kind == "morning":
		var yesterday := week.day_record(day - 1)
		report["weak"] = bool(yesterday.get("weak", false))
		report["still_weak"] = tiro_weak()
		report["yesterday"] = yesterday
		report["offer"] = progress.stat("weak_day") > 0 and not week.routine.get("offer_seen", false)
		if report.offer:
			week.routine["offer_seen"] = true
		var morning: Dictionary = Database.week_story.morning
		var reward_day := int(morning.day)
		var receipt := "week_morning:%d" % reward_day
		report["gift"] = day >= reward_day and economy.granted.has(receipt) and not progress.seen.has(receipt)
		if report.gift:
			progress.seen[receipt] = true
		# Primeiro dia de verdade: o combinado começa hoje (F02B). Antes do almoço, a dica da tampinha.
		report["first_day"] = is_arrival_day(day - 1) and not is_arrival_day(day)
		report["before_lunch"] = report.first_day and week_hour() < meal_window(str(Database.meals.periods.keys()[0])).x \
			and week.stored.size() < int(Database.meals.get("stored_slots", 2)) and not meal_items_owned().is_empty()
		report["served"] = served_notes()
		mark_served_notes_seen()
	else:
		report["arrival"] = is_arrival_day(day)
		# Boa noite do dia da chegada: o combinado de amanhã, o horário e o aviso (F8). Só uma vez cada.
		report["first_night"] = is_arrival_day(day) and not is_arrival_day(day + 1)
		report["deal"] = first_deal_when()
		report["reminder_offer"] = not week.routine.get("offer_seen", false)
		if report.reminder_offer:
			week.routine["offer_seen"] = true  # a oferta vale aqui: o aviso fica desligado até aceitar
		# A tigela é ensinada no Bom dia do dia 2; o lembrete fica para os Boa noite seguintes (o do dia 1 já é cheio).
		report["store_offer"] = not report.first_night and food_lesson_done() and not week.routine.get("store_offered", false) \
			and week.stored.size() < int(Database.meals.get("stored_slots", 2)) and not meal_items_owned().is_empty()
		if report.store_offer:
			week.routine["store_offered"] = true
		report["paw_total"] = well_fed_days()
		var meals := week.day_record(day)
		var rows := week_daily_rows(day)
		report["meals"] = meals
		report["dish"] = str(record.get("dish", ""))
		report["done"] = rows.filter(func(row: Dictionary) -> bool: return row.done).size()
		report["seal"] = economy.granted.has("week_daily_seal:%d" % int(candidate.civil))
	_changed()
	return report


func week_meal_reminder_enabled() -> bool:
	return bool(week.routine.get("reminders", false))


func week_meal_reminder_offered() -> bool:
	return bool(week.routine.get("offer_seen", false))


func week_routine_badge(id: String) -> String:
	return str(_week_line_definition(id).get("badge", "")) if economy.granted.has("week_line:" + id) else ""


func week_routine_pairs() -> Array[Dictionary]:
	var pairs: Array[Dictionary] = []
	var found: Dictionary = week.routine.get("sets", {}).get("pairs", {})
	for pair: Dictionary in Database.dishes.duples:
		if found.has("%s:%s" % [pair.a, pair.b]):
			pairs.append(pair)
	return pairs


func set_week_meal_reminder(enabled: bool) -> void:
	week.routine["reminders"] = enabled
	_changed()


func take_week_meal_reminder() -> String:
	if not week_meal_reminder_enabled() or progress.stat("arrival_box") == 0 or not food_lesson_done() or week_day_number() < week.high_day:
		return ""
	var period := meal_period_now()
	var day := _routine_day_number()
	if period == "" or not week.day_record(day).get(period, {}).is_empty():
		return ""
	var record := _week_routine_day(day, true)
	var key := "reminded_" + period
	if record.has(key):
		return ""
	record[key] = true
	_changed()
	return period


func week_story_surprise() -> String:
	var day := mini(progress.chapter_index(), Database.week_story.days.size())
	while day > 0:
		var entry: Dictionary = Database.week_story.days[day - 1]
		if progress.seen.has("week_surprise:%d" % day):
			return str(entry.surprise)
		day -= 1
	return ""


func _week_story_milestone(id: String) -> void:
	if progress.stat("arrival_box") == 0:
		return
	for i in Database.week_story.days.size():
		var entry: Dictionary = Database.week_story.days[i]
		if entry.trigger != id:
			continue
		var key := "week_surprise:%d" % (i + 1)
		if not progress.seen.has(key):
			progress.seen[key] = true
			Events.toast_requested.emit(str(entry.surprise))


## O desafio do dia da vovó segue o dia do calendário (o 8º dia recomeça a lista).
func _challenge_entry(day: int) -> Dictionary:
	var days: Array = Database.week_story.days
	return days[(maxi(day, 1) - 1) % days.size()]


## Só faltam as patinhas para a próxima fase (todo o resto da lista já está feito): é quando o desafio do dia aparece
## na pílula do próximo passo e a missão secreta da F04b pode surgir.
func only_paws_left() -> bool:
	var info := growth_info()
	if info.next.is_empty():
		return false
	var paws := false
	for row: Dictionary in info.requirements:
		if row.done:
			continue
		if str(row.get("counter", "")) != "well_fed_day":
			return false
		paws = true
	return paws


func week_challenge() -> Dictionary:
	var day := week_day()
	if progress.chapter_index() > week_last_chapter():
		return {}
	var entry := _challenge_entry(day)
	var count := int(week.story_challenge.get("count", 0)) if day == int(week.story_challenge.get("day", 0)) else 0
	return entry.merged({"count": count, "paid": economy.granted.has("week_challenge:%d" % day)})


func _count_week_challenge(key: String, amount: int) -> void:
	var day := week_day()
	if progress.stat("arrival_box") == 0:
		return
	var entry := _challenge_entry(day)
	if key != entry.counter:
		return
	if int(week.story_challenge.get("day", 0)) != day:
		week.story_challenge = {"day": day, "count": 0}
	week.story_challenge.count += amount


func _sync_week_story() -> void:
	if progress.stat("arrival_box") == 0:
		return
	# A surpresa de cada passo-gatilho aparece quando o objetivo dele fica pronto (a lista não depende mais do capítulo).
	var current := progress.current_main_quest()
	for entry: Dictionary in Database.week_story.days:
		var trigger := str(entry.trigger)
		if current == trigger and quest_objectives_error(trigger) == "":
			_week_story_milestone(trigger)
	var morning: Dictionary = Database.week_story.morning
	if week_day() >= int(morning.day):
		_grant_automatic("week_morning:%d" % int(morning.day), morning.rewards)
	var challenge := week_challenge()
	if challenge.is_empty() or challenge.paid:
		return
	if challenge.counter == "week_dishes_ready" and growth.phase == "puppy" and week_hour() < meal_window("dinner").x:
		for row: Dictionary in growth_info().requirements:
			if row.id == "dishes" and row.done:
				_count("week_dishes_ready")
				challenge = week_challenge()
				break
	if int(challenge.count) >= int(challenge.target):
		var shared := str(challenge.get("shared_receipt", ""))
		var reward: Dictionary = {} if economy.granted.has(shared) else challenge.rewards
		if _grant_automatic("week_challenge:%d" % week_day(), reward).paid:
			Events.toast_requested.emit("Desafio do dia concluído!")
