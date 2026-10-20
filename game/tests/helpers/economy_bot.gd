extends RefCounted
## Política do jogador simulado (etapa 01 do plano de economia).
##
## SÓ LEITURA: `plan()` consulta o GameState por métodos públicos e devolve a PRÓXIMA ação (um
## dicionário descritivo). Quem executa a ação, cobra o tempo de toque e escreve o ledger é o
## `economy_sim.gd`. O planejador nunca altera inventário, moedas, timers ou posses: o runner
## compara um resumo do estado antes e depois de cada `plan()` e aborta se algo mudou.
##
## Resultado de uma busca (`pursue_*`): {state: "done"|"act"|"wait"|"block", ...}
##   done  = o objetivo já vale; act = há uma ação agora; wait = só falta tempo (timer);
##   block = nada a fazer por este caminho agora (fonte inexistente, sorte, requisito de outro tipo).
## Falha da política (o bot não achou o caminho) é diferente de bloqueio do jogo: cada "block"
## traz um `why` com categoria para o relatório (ver Sim._classify_block).

const DONE := "done"
const ACT := "act"
const WAIT := "wait"
const BLOCK := "block"
const MAX_DEPTH := 28
var _walk_nesting := 0
const CARE_FEED_BELOW := 55.0
const CARE_BATHE_BELOW := 40.0
const CARE_PLAY_BELOW := 45.0
const SLEEP_BELOW := 25.0
const WAKE_ABOVE := 90.0
const FOOD_KEEP := 3
const WATER_MIN_LEFT := 20.0
## Compras que o jogador simulado nunca faz sozinho (o perfil Recuperação faz de propósito).
const AVOID_UPGRADES: Array[String] = ["sofa"]

var gs
var profile: Dictionary = {}
var rng := RandomNumberGenerator.new()
## Tempo restante da sessão e intervalo até a próxima (o jogador sabe a própria agenda).
var session_left: float = 0.0
var next_gap: float = 86400.0
## item -> quantidade protegida pela meta reservada (única); moedas reservadas para ela.
var protect: Dictionary = {}
var protect_coins: int = 0
## Motivo e meta de cada bloqueio visto no último plan() (para o relatório de gargalos).
var blocks: Array[Dictionary] = []
var focus_id: String = ""
## Pilha da primeira recursão profunda vista (diagnóstico; vazio se nunca houve).
var depth_stack: String = ""
## Depuração: com trace_on, cada busca registra "profundidade, o que buscou -> resultado".
var trace_on: bool = false
var trace: Array[String] = []
var focus_result: Dictionary = {}
## Ações recentes que falharam: chave -> até quando evitar.
var avoid: Dictionary = {}
## Memória do próprio jogador simulado (não é estado do jogo): erros de propósito já feitos.
var memory: Dictionary = {}
var _inflight: Dictionary = {}
var _inflight_ready: bool = false
var _made_space: bool = false
## Microssegundos por fase do plano (diagnóstico de desempenho do simulador).
var perf: Dictionary = {}


func _init(game_state, bot_profile: Dictionary, seed_value: int) -> void:
	gs = game_state
	profile = bot_profile
	rng.seed = seed_value


# --- Resultados -------------------------------------------------------------------------

func _done() -> Dictionary:
	return {"state": DONE}


func _act(action: Dictionary) -> Dictionary:
	return {"state": ACT, "action": action}


func _wait(why: String) -> Dictionary:
	return {"state": WAIT, "why": why}


func _block(why: String, goal: String = "") -> Dictionary:
	var entry := {"why": why, "goal": goal if goal != "" else focus_id}
	if why == "depth" and depth_stack.is_empty():
		# Diagnóstico: guarda a pilha da primeira recursão profunda (quem chamou quem).
		var names: Array[String] = []
		for frame: Dictionary in get_stack():
			names.append("%s:%d" % [frame.function, frame.line])
		depth_stack = " < ".join(names.slice(0, 60))
	blocks.append(entry)
	return {"state": BLOCK, "why": why}


func _combine(results: Array) -> Dictionary:
	## Primeira ação; senão o primeiro bloqueio... mas espera vence bloqueio (pode acabar).
	var waited: Dictionary = {}
	var blocked: Dictionary = {}
	for r: Dictionary in results:
		match str(r.state):
			ACT:
				return r
			WAIT:
				if waited.is_empty():
					waited = r
			BLOCK:
				if blocked.is_empty():
					blocked = r
	if not waited.is_empty():
		return waited
	if not blocked.is_empty():
		return blocked
	return _done()


func _action(kind: String, args: Dictionary, ctx: String, why: String) -> Dictionary:
	return {"kind": kind, "args": args, "ctx": ctx, "why": why, "goal": focus_id}


# --- Consultas básicas --------------------------------------------------------------------

func t() -> float:
	return gs.now()


func have(item: String) -> int:
	return gs.inventory.count(item)


func avail(item: String, shield: bool) -> int:
	return have(item) if shield else maxi(0, have(item) - int(protect.get(item, 0)))


func price(item: String) -> int:
	return int(Database.items.get(item, {}).get("sell_price", 0))


func item_value(item: String) -> int:
	return price(item)


func world_open(world: String) -> bool:
	return world == "" or gs.requirement_error(Database.worlds.get(world, {}).get("requirements", {})) == ""


func place_open(world: String, place: String) -> bool:
	if not world_open(world):
		return false
	return gs.requirement_error(Database.worlds.get(world, {}).get("places", {}).get(place, {}).get("requirements", {})) == ""


func panel_open(panel: String) -> bool:
	var at: Array[String] = Database.place_with_panel(panel)
	return at[0] != "" and place_open(at[0], at[1])


func market_open() -> bool:
	return panel_open("sell")


func orders_open() -> bool:
	return panel_open("orders")


func emergency_ready() -> bool:
	## Mesma regra de GameState.emergency_food: só sem comida na mochila e fora da recarga.
	for id: String in sorted_keys(gs.inventory.counts):
		if Database.items.get(id, {}).has("feed"):
			return false
	return gs.progress.cooldown_left("emergency_food", t()) <= 0


func inflight(item: String) -> int:
	if not _inflight_ready:
		_inflight.clear()
		for entry: Dictionary in gs.plots:
			var crop_id: String = str(entry.get("crop", ""))
			if crop_id == "":
				continue
			for id: String in Database.crops.get(crop_id, {}).get("yield", {}):
				_inflight[id] = int(_inflight.get(id, 0)) + int(Database.crops[crop_id].yield[id])
		for station_id: String in sorted_keys(gs.stations):
			for entry: Dictionary in gs.stations[station_id].queue:
				var recipe: Dictionary = Database.recipes.get(str(entry.recipe), {})
				var out: String = Database.recipe_output(recipe)
				if out != "":
					_inflight[out] = int(_inflight.get(out, 0)) + int(entry.get("qty", recipe.get("qty", 1)))
		for site: String in gs.progress.gathering:
			for entry: Dictionary in gs.progress.gathering[site]:
				if entry.is_empty():
					continue
				for id: String in entry.get("rewards", {}).get("items", {}):
					_inflight[id] = int(_inflight.get(id, 0)) + int(entry.rewards.items[id])
		if not gs.progress.activity.is_empty():
			var act_data: Dictionary = Database.progression.activities.get(str(gs.progress.activity.get("id", "")), {})
			for id: String in act_data.get("rewards", {}).get("items", {}):
				_inflight[id] = int(_inflight.get(id, 0)) + int(act_data.rewards.items[id])
		_inflight_ready = true
	return int(_inflight.get(item, 0))


func depot_pending(depot: String) -> int:
	## Unidades que ainda vão cair neste depósito (plantas, filas, coletas).
	var total := 0
	for item: String in Database.items:
		if gs.storage_of(item) == depot:
			total += inflight(item)
	return total


## Cabe a produção prevista? (espaço do depósito menos o que já está a caminho.)
func fits(items: Dictionary) -> bool:
	var needed: Dictionary = {}
	for item: String in items:
		var depot: String = gs.storage_of(item)
		if depot != "" and gs.storage_active(depot):
			needed[depot] = int(needed.get(depot, 0)) + int(items[item])
	for depot: String in needed:
		if int(needed[depot]) + depot_pending(depot) > gs.storage_space(depot):
			return false
	return true


## Chaves em ordem fixa: salvar/recarregar reordena os dicionários e a política não pode depender disso.
func sorted_keys(data: Dictionary) -> Array:
	var keys: Array = data.keys()
	keys.sort()
	return keys


## Chave genérica de uma ação (laços e falhas repetidas são evitados por ela).
func action_key(action: Dictionary) -> String:
	return "act:" + str(action.kind) + JSON.stringify(action.args)


func is_avoided(key: String) -> bool:
	return float(avoid.get(key, 0.0)) > t()


func remember_failure(key: String, seconds: float = 90.0) -> void:
	avoid[key] = t() + seconds


# --- Plano principal ---------------------------------------------------------------------

## Devolve {"action": {...}} ou {} (nada a fazer agora; o runner decide esperar ou encerrar).
func plan(left: float, gap: float) -> Dictionary:
	session_left = left
	next_gap = gap
	protect.clear()
	protect_coins = 0
	blocks.clear()
	_inflight_ready = false
	_made_space = false
	focus_id = ""
	focus_result = {}
	var steps: Array[String] = ordered_steps()
	for id: String in steps:
		if not gs.progress.claimed_quests.has(id):
			focus_id = id
			break
	var t_focus := Time.get_ticks_usec()
	if focus_id != "":
		_protect_step(focus_id)
		focus_result = pursue_step(focus_id, true, 0)
	perf["focus"] = int(perf.get("focus", 0)) + Time.get_ticks_usec() - t_focus
	for phase: String in profile.get("phases", []):
		var t_phase := Time.get_ticks_usec()
		var action: Dictionary = call(phase, steps)
		perf[phase] = int(perf.get(phase, 0)) + Time.get_ticks_usec() - t_phase
		if not action.is_empty():
			if is_avoided(action_key(action)):
				continue  # laço detectado pelo runner: tenta a próxima fase
			return {"action": action}
	return {}


func ordered_steps() -> Array[String]:
	var active: Dictionary = gs.progress.active_steps()
	var order: Array = profile.get("lines", ["main", "bloblo", "nina", "merchant", "guide"])
	var result: Array[String] = []
	for line: String in order:
		if active.has(line):
			result.append(str(active[line]))
	for line: String in active:
		if not str(active[line]) in result:
			result.append(str(active[line]))
	return result


## A meta reservada protege tudo o que a cadeia dela usa, também o que já está na mochila.
func _protect_all(amounts: Dictionary, shield: bool) -> void:
	if not shield:
		return
	for item: String in amounts:
		protect[item] = maxi(int(protect.get(item, 0)), int(amounts[item]))


func _protect_step(qid: String) -> void:
	for goal: Dictionary in Database.quests[qid].goals:
		var key := str(goal.get("key", ""))
		var target := int(goal.get("target", 1))
		match str(goal.type):
			"deliver", "have":
				protect[key] = maxi(int(protect.get(key, 0)), target)
			"owned":
				if not gs.has_upgrade(key):
					var data: Dictionary = Database.progression.upgrades.get(key, {})
					protect_coins = maxi(protect_coins, int(data.get("cost", 0)))
					for item: String in data.get("materials", {}):
						protect[item] = maxi(int(protect.get(item, 0)), int(data.materials[item]))
			"coins":
				protect_coins = maxi(protect_coins, target)
			"project":
				_protect_project(key)
			"stat":
				if key.begins_with("project_use:"):
					_protect_project(key.trim_prefix("project_use:"))
				if key.begins_with("order:"):
					var order: Dictionary = Database.progression.orders.get(key.trim_prefix("order:"), {})
					for item: String in order.get("inputs", {}):
						protect[item] = maxi(int(protect.get(item, 0)), int(order.inputs[item]))


## A obra que a meta espera protege a taxa e o material das fases (nada vendido nem gasto por outra fase).
func _protect_project(id: String) -> void:
	if gs.project_completed(id):
		return
	var def: Dictionary = Database.project(id)
	if not gs.project_started(id):
		protect_coins = maxi(protect_coins, int(def.get("start_coins", 0)))
	for phase: Dictionary in def.get("phases", []):
		for item: String in phase.get("items", {}):
			protect[item] = maxi(int(protect.get(item, 0)), int(phase.items[item]))


## Obra comunitária como meta (capítulos 10–12): cumpre os requisitos, começa, entrega e busca o que falta
## pelo mesmo caminho de qualquer item (conclusão sempre por ações legais: `start_project`/`contribute_project`).
func pursue_project(id: String, shield: bool, depth: int, qid: String = "") -> Dictionary:
	if gs.project_completed(id):
		return _done()
	if depth > MAX_DEPTH:
		return _block("depth", qid)
	var def: Dictionary = Database.project(id)
	if def.is_empty():
		return _block("project:" + id, qid)
	if not gs.project_available(id):
		return pursue_reqs(def.get("requirements", {}), shield, depth + 1, qid)
	var go := "place:%s/%s" % [def.go.world, def.go.place]
	if not gs.project_started(id):
		var fee := int(def.get("start_coins", 0))
		if gs.project_error(id) == "":
			return _act(_action("start_project", {"id": id}, go, "project"))
		return earn_coins(fee - gs.coins, shield, depth + 1)
	var stage: Dictionary = gs.project_stage(id)
	if bool(stage.done):
		return _wait("project_done")
	var remaining: Dictionary = stage.remaining
	for item: String in sorted_keys(remaining):
		var qty := mini(int(remaining[item]), have(item))
		if qty > 0:
			return _act(_action("contribute_project", {"id": id, "item": item, "qty": qty}, go, "project"))
	var results: Array = []
	for item: String in sorted_keys(remaining):
		if int(remaining[item]) > 0:
			results.append(pursue_item(item, int(remaining[item]), true, depth + 1))
	return _combine(results)


# --- Fases (cada uma devolve uma ação ou {}) ---------------------------------------------------

func ph_claim(steps: Array[String]) -> Dictionary:
	for id: String in steps:
		if gs.quest_error(id) == "":
			return _action("claim_quest", {"id": id}, "tasks", "story")
	for kind: String in ["daily", "weekly"]:
		if not gs.routines_unlocked(kind):
			continue
		for id: String in gs.routine_ids(kind):
			if gs.routine_error(kind, id) == "":
				return _action("claim_routine", {"kind": kind, "id": id}, "tasks", "routine")
	if gs.daily_gift_error() == "":
		return _action("claim_daily_gift", {}, "pet", "gift")
	return {}


func ph_closing(_steps: Array[String]) -> Dictionary:
	## "Preparar saída": antes de fechar, o Tiro dorme se está cansado.
	if session_left > 60.0 or gs.walking() or gs.dog.sleeping:
		return {}
	if gs.dog.get_need("energy", t()) < 70.0 and next_gap > 3600.0:
		return _action("sleep", {"value": true}, "pet", "close")
	return {}


func ph_care_urgent(_steps: Array[String]) -> Dictionary:
	return _care(true)


func ph_care_optional(_steps: Array[String]) -> Dictionary:
	return _care(false)


func _care(urgent: bool) -> Dictionary:
	var now := t()
	var dog = gs.dog
	if dog.sleeping:
		if dog.get_need("energy", now) >= WAKE_ABOVE:
			return _action("sleep", {"value": false}, "pet", "care")
		return {}
	if gs.walking():
		return {}
	var hunger: float = dog.get_need("hunger", now)
	var limit_feed := 30.0 if urgent else CARE_FEED_BELOW
	if hunger < limit_feed:
		var food: String = best_food()
		if food != "":
			return _action("feed", {"item": food}, "pet", "care")
		if emergency_ready():
			return _action("emergency_food", {}, "pet", "care")
	if dog.get_need("hygiene", now) < (25.0 if urgent else CARE_BATHE_BELOW):
		return _action("bathe", {}, "pet", "care")
	var happy: float = dog.get_need("happiness", now)
	if happy < (30.0 if urgent else CARE_PLAY_BELOW):
		if dog.get_need("energy", now) >= 20.0:
			return _action("play", {}, "pet", "care")
		if not urgent:
			return _action("pet", {}, "pet", "care")
	if dog.get_need("energy", now) < SLEEP_BELOW:
		return _action("sleep", {"value": true}, "pet", "care")
	return {}


## Comida mais barata que o Tiro aceita e que a meta não reservou.
func best_food(shield: bool = false) -> String:
	var best := ""
	var best_cost := 1 << 30
	for item: String in sorted_keys(gs.inventory.counts):
		if not Database.items.get(item, {}).has("feed"):
			continue
		if avail(item, shield) <= 0:
			continue
		var cost := price(item) if price(item) > 0 else 1
		if cost < best_cost:
			best = item
			best_cost = cost
	return best


func ph_wishes(_steps: Array[String]) -> Dictionary:
	if gs.walking():
		return {}
	for i in gs.wishes.slots.size():
		if gs.wish_at(i).is_empty():
			continue
		if gs.wish_error(i) == "":
			var def: Dictionary = gs.wish_at(i)
			if str(def.get("type", "")) in ["feed", "give"] and avail(str(def.item), false) <= 0:
				continue
			if is_avoided("wish%d" % i):
				continue
			return _action("fulfill_wish", {"slot": i}, "wishes", "wish")
	return {}


## Desejos de ação (fazer carinho, brincar, passear...): o jogador faz o que o balão pede.
func ph_wish_goals(_steps: Array[String]) -> Dictionary:
	if gs.walking():
		return {}
	for i in gs.wishes.slots.size():
		var def: Dictionary = gs.wish_at(i)
		if def.is_empty() or str(def.get("type", "")) != "action" or gs.wish_error(i) == "":
			continue
		var remaining: int = gs.wish_target(i) - gs.wish_value(i)
		if remaining <= 0:
			continue
		var r: Dictionary = pursue_stat(str(def.goal.key), remaining, false, 1, "wish")
		if str(r.state) == ACT:
			r.action["why"] = "wish"
			return r.action
	return {}


## Colher o que está pronto, sempre antes de planejar mais.
func ph_collect(_steps: Array[String]) -> Dictionary:
	var ready: Array[int] = []
	for i: int in gs.usable_plot_indices():
		if gs.plot_status(i) == "ready":
			if gs.harvest_error(i) == "":
				ready.append(i)
			elif not _made_space:
				var space := _make_space_for_crop(str(gs.plot(i).crop))
				if not space.is_empty():
					return space
	if not ready.is_empty():
		return _action("harvest_many", {"plots": ready}, "farm", "collect")
	for id: String in sorted_keys(gs.stations):
		if gs.has_upgrade(id) and gs.station(id).ready_count(t()) > 0:
			if _station_collect_blocked(id):
				var space := _make_space_for_station(id)
				if not space.is_empty():
					return space
				continue
			return _action("collect_station", {"station": id}, "station:" + id, "collect")
	if not gs.progress.activity.is_empty() and gs.activity_remaining() == 0 and gs.storage_error(Database.progression.activities.get(str(gs.progress.activity.id), {}).get("rewards", {}).get("items", {})) == "":
		return _action("collect_activity", {}, "orchard", "collect")
	for site: String in Database.progression.get("nature_sites", {}):
		for index in gs.gathering_slots(site):
			if gs.collect_gathering_error(site, index) == "":
				return _action("collect_gathering", {"site": site, "index": index}, "nature:" + site, "collect")
	if gs.walk_ready() and gs.collect_walk_error() == "":
		return _action("collect_walk", {}, "walk", "collect")
	for world: String in sorted_keys(gs.finds.worlds):
		if gs.dig_error(world) == "" and not is_avoided("dig" + world):
			return _action("dig", {"world": world}, "dig:" + world, "collect")
	for id: String in Database.friends.friends:
		if gs.collect_friend_visit_error(id) == "":
			return _action("collect_friend_visit", {"id": id}, "pet", "collect")
	return {}


func _station_collect_blocked(id: String) -> bool:
	var needed: Dictionary = {}
	for entry: Dictionary in gs.station(id).queue:
		if float(entry.ready_at) <= t():
			var recipe: Dictionary = Database.recipes.get(str(entry.recipe), {})
			if recipe.has("output_collection"):
				continue
			var out: String = Database.recipe_output(recipe)
			needed[out] = int(needed.get(out, 0)) + int(entry.get("qty", recipe.get("qty", 1)))
	return gs.storage_error(needed) != ""


func ph_water(_steps: Array[String]) -> Dictionary:
	var thirsty: Array[int] = []
	for i: int in gs.usable_plot_indices():
		if gs.water_error(i) == "" and float(gs.plot(i).ready_at) - t() >= WATER_MIN_LEFT:
			thirsty.append(i)
	if not thirsty.is_empty():
		return _action("water_many", {"plots": thirsty}, "farm", "water")
	return {}


func ph_focus(_steps: Array[String]) -> Dictionary:
	if str(focus_result.get("state", "")) == ACT:
		return focus_result.action
	return {}


## Passos das outras linhas: usa só o que a meta reservada não protege.
func ph_others(steps: Array[String]) -> Dictionary:
	# Com a estufa e os quatro pedaços do mapa, o jogador abre o baú da Clareira (o mirtilo e a linha da Nina dependem dele).
	if gs.progress.stat("treasure") < 1 and gs.has_upgrade("greenhouse") and gs.open_treasure_error() == "":
		return _action("open_treasure", {}, "treasure", "goal")
	for id: String in steps:
		if id == focus_id:
			continue
		var r: Dictionary = pursue_step(id, false, 0)
		if str(r.state) == ACT:
			return r.action
	return {}


## Depois da história, o jogador quer as melhorias que faltam: busca o caminho das mais baratas.
func ph_upgrade_goals(_steps: Array[String]) -> Dictionary:
	var ids: Array[String] = []
	for id: String in Database.progression.upgrades:
		if not gs.has_upgrade(id) and not id in AVOID_UPGRADES and not is_avoided("buy" + id) and not Database.progression.upgrades[id].has("nature_unlock"):
			ids.append(id)
	ids.sort_custom(func(a: String, b: String) -> bool: return int(Database.progression.upgrades[a].get("cost", 0)) < int(Database.progression.upgrades[b].get("cost", 0)))
	var tried := 0
	for id in ids:
		if tried >= 3:
			break
		tried += 1
		var r: Dictionary = pursue_upgrade(id, false, 2)
		if str(r.state) == ACT:
			r.action["why"] = "upgrade_goal"
			return r.action
	return {}


## Obras comunitárias (só nas execuções `until=projects`): começa a que dá para pagar sem tocar na reserva da meta,
## entrega o que já está sobrando na mochila e só então busca o que falta (sem atalho: o mesmo caminho de qualquer item,
## com escudo: os ingredientes da cadeia não são vendidos nem gastos por outra fase enquanto a obra os espera).
## A ordem entre jardim e piquenique é a do catálogo; quem estiver começada vem antes (não espalha entregas).
func ph_projects(_steps: Array[String]) -> Dictionary:
	var reserve := protect_coins if bool(profile.get("reserve_story", true)) else 0
	var open_ids: Array[String] = []
	for id: String in Database.project_ids():
		if gs.project_available(id) and not gs.project_completed(id):
			open_ids.append(id)
	open_ids.sort_custom(func(a: String, b: String) -> bool: return gs.project_started(a) and not gs.project_started(b))
	for id: String in open_ids:
		if is_avoided("project" + id):
			continue
		if not gs.project_started(id):
			var fee := int(Database.project(id).get("start_coins", 0))
			if gs.project_error(id) == "" and gs.coins - fee >= reserve:
				return _action("start_project", {"id": id}, "place:%s/%s" % [Database.project(id).go.world, Database.project(id).go.place], "project")
			continue
		var stage: Dictionary = gs.project_stage(id)
		if bool(stage.done):
			continue
		var remaining: Dictionary = stage.remaining
		for item: String in sorted_keys(remaining):
			var qty := mini(int(remaining[item]), avail(item, false))
			if qty > 0:
				return _action("contribute_project", {"id": id, "item": item, "qty": qty}, "place:%s/%s" % [Database.project(id).go.world, Database.project(id).go.place], "project")
		for item: String in sorted_keys(remaining):
			if int(remaining[item]) <= 0:
				continue
			var r: Dictionary = pursue_item(item, int(remaining[item]), true, 2)
			if str(r.state) == ACT:
				r.action["why"] = "project_goal"
				return r.action
	# Obra que ainda espera uma compra (ex.: a banca 3 da Festa): busca o requisito pelo caminho de sempre.
	for id: String in Database.project_ids():
		var def: Dictionary = Database.project(id)
		if gs.project_completed(id) or gs.project_available(id) or Database.project_issue(id) != "" or is_avoided("project" + id):
			continue
		var wanted: Array = def.get("requirements", {}).get("projects", [])
		if wanted.any(func(other: String) -> bool: return not gs.project_completed(other)):
			continue
		var reqs: Dictionary = pursue_reqs(def.get("requirements", {}), true, 2)
		if str(reqs.state) == ACT:
			reqs.action["why"] = "project_requirement"
			return reqs.action
	return {}


func ph_orders(_steps: Array[String]) -> Dictionary:
	if not orders_open():
		return {}
	var best := ""
	var best_gain := 0
	for id: String in Database.progression.orders:
		if gs.order_error(id) != "":
			continue
		var order: Dictionary = Database.progression.orders[id]
		var sale := 0
		var usable := true
		for item: String in order.inputs:
			sale += price(item) * int(order.inputs[item])
			if avail(item, false) < int(order.inputs[item]):
				usable = false
		if not usable:
			continue
		var gain := int(order.rewards.get("coins", 0)) + _bonus_value(order.rewards) - sale
		if gain > best_gain:
			best = id
			best_gain = gain
	if best != "":
		return _action("fulfill_order", {"id": best}, "orders", "order")
	return {}


func _bonus_value(rewards: Dictionary) -> int:
	return 12 * int(rewards.get("items", {}).get("bolt", 0)) + 25 * int(rewards.get("items", {}).get("iron_band", 0))


## Produção que o jogador faz sem meta: plantio, cozinha, coleta e passeio.
func ph_produce(_steps: Array[String]) -> Dictionary:
	var plant := _opportunistic_plant()
	if not plant.is_empty():
		return plant
	var cook := _opportunistic_cook()
	if not cook.is_empty():
		return cook
	var gather := _opportunistic_gather()
	if not gather.is_empty():
		return gather
	var activity := _opportunistic_activity()
	if not activity.is_empty():
		return activity
	var walk := _opportunistic_walk()
	if not walk.is_empty():
		return walk
	return {}


func ph_spend(_steps: Array[String]) -> Dictionary:
	var reserve := protect_coins if bool(profile.get("reserve_story", true)) else 0
	# Melhorias: a mais barata que dá para pagar sem tocar na reserva da meta.
	var best := ""
	var best_cost := 1 << 30
	for id: String in Database.progression.upgrades:
		if id in AVOID_UPGRADES or is_avoided("buy" + id):
			continue
		if gs.upgrade_error(id) != "":
			continue
		var data: Dictionary = Database.progression.upgrades[id]
		var cost := int(data.get("cost", 0))
		if gs.coins - cost < reserve:
			continue
		var shielded := false
		for item: String in data.get("materials", {}):
			if avail(item, false) < int(data.materials[item]):
				shielded = true
		if shielded:
			continue
		var at: Array[String] = Database.place_of_upgrade(id)
		if at[0] != "" and not place_open(at[0], at[1]):
			continue
		if cost < best_cost:
			best = id
			best_cost = cost
	if best != "":
		return _action("buy_upgrade", {"id": best}, _upgrade_ctx(best), "buy")
	if gs.has_upgrade("farm") and gs.unlocked_plots < int(Database.farm.get("plots", 0)) and gs.plot_cost(gs.unlocked_plots) >= 0 and gs.coins - gs.plot_cost(gs.unlocked_plots) >= reserve and not is_avoided("buyplot"):
		return _action("buy_plot", {"index": gs.unlocked_plots}, "farm", "buy")
	for id: String in Database.animals:
		if gs.buy_animal_error(id) == "" and gs.coins - int(Database.animals[id].price) >= reserve and not is_avoided("animal" + id):
			return _action("buy_animal", {"id": id}, "station:" + str(Database.animals[id].station), "buy")
	return {}


func _upgrade_ctx(id: String) -> String:
	var at: Array[String] = Database.place_of_upgrade(id)
	return "place:%s/%s" % [at[0], at[1]] if at[0] != "" else "build"


## Vender excedente: quando faltam moedas para algo que se quer comprar, o depósito está
## apertado ou a sessão vai fechar com sobra.
func ph_sell(_steps: Array[String]) -> Dictionary:
	if not market_open():
		return {}
	var want := _coin_target()
	var pressure := _storage_pressure()
	var closing := session_left < 120.0
	if gs.coins >= want and pressure == "" and not closing:
		return {}
	if gs.coins >= want and pressure == "" and closing and _surplus_value() < 40:
		return {}
	return _sell_best(pressure)


## Moedas que o bot quer ter: meta reservada ou a compra seguinte que falta só dinheiro.
func _coin_target() -> int:
	var target := protect_coins
	var best_cost := 1 << 30
	for id: String in Database.progression.upgrades:
		if id in AVOID_UPGRADES:
			continue
		var err: String = gs.upgrade_error(id)
		if err.begins_with("Faltam ") and err.ends_with("moedas"):
			best_cost = mini(best_cost, int(Database.progression.upgrades[id].get("cost", 0)))
	if best_cost < (1 << 30):
		target = maxi(target, best_cost)
	if gs.has_upgrade("farm") and gs.unlocked_plots < int(Database.farm.get("plots", 0)):
		target = maxi(target, mini(target if target > 0 else 1 << 30, gs.plot_cost(gs.unlocked_plots)))
	return target


func _storage_pressure() -> String:
	for depot: String in Database.progression.storage:
		if not gs.storage_active(depot):
			continue
		var cap: int = gs.storage_capacity(depot)
		if cap > 0 and gs.storage_used(depot) + depot_pending(depot) >= int(cap * 0.8):
			return depot
	return ""


func _surplus_value() -> int:
	var total := 0
	for item: String in sorted_keys(gs.inventory.counts):
		if _sellable(item):
			total += price(item) * avail(item, false)
	return total


func _sellable(item: String, force_trail: bool = false) -> bool:
	if price(item) <= 0:
		return false
	var category := str(Database.items.get(item, {}).get("category", ""))
	if category == "trail" and not force_trail and not bool(profile.get("sell_trail", false)):
		return false
	if Database.items.get(item, {}).has("feed") and gs.inventory.count(item) <= FOOD_KEEP and best_food() == item:
		return false
	return avail(item, false) > 0


func _sell_best(depot_filter: String) -> Dictionary:
	var best := ""
	var best_total := 0
	for item: String in sorted_keys(gs.inventory.counts):
		if not _sellable(item):
			continue
		if depot_filter != "" and gs.storage_of(item) != depot_filter and best_total > 0:
			continue
		var amount := avail(item, false)
		if Database.items.get(item, {}).has("feed"):
			amount = maxi(0, amount - FOOD_KEEP)
		var total := amount * price(item)
		if depot_filter != "" and gs.storage_of(item) == depot_filter:
			total += 1000000
		if amount > 0 and total > best_total:
			best = item
			best_total = total
	if best == "":
		return {}
	var qty := avail(best, false)
	if Database.items.get(best, {}).has("feed"):
		qty = maxi(0, qty - FOOD_KEEP)
	return _action("sell", {"item": best, "qty": qty}, "market", "sell")


func ph_bond_extras(_steps: Array[String]) -> Dictionary:
	## Perfil afetivo: truques e amigos quando dá, sem estragar a meta reservada.
	if gs.walking() or gs.dog.sleeping:
		return {}
	for id: String in Database.progression.tricks:
		if gs.perform_trick_error(id) == "":
			return _action("perform_trick", {"id": id}, "pet", "bond")
	for id: String in gs.friends_present():
		if gs.give_friend_error(id) == "" and avail(str(gs.friend_def(id).likes), false) > 0 and not is_avoided("friend" + id):
			return _action("give_friend", {"id": id}, "friends", "bond")
	return {}


func ph_recovery_blunders(_steps: Array[String]) -> Dictionary:
	## Perfil Recuperação: compra o sofá cedo e vende ingrediente que ainda é necessário.
	if not bool(memory.get("blunder_sofa", false)) and gs.upgrade_error("sofa") == "":
		return _action("buy_upgrade", {"id": "sofa", "blunder": true}, _upgrade_ctx("sofa"), "blunder")
	if not bool(memory.get("blunder_dump", false)) and market_open():
		for item: String in ["carrot", "potato", "pumpkin", "wheat", "corn"]:
			if have(item) > 0:
				return _action("sell", {"item": item, "qty": have(item), "blunder": true}, "market", "blunder")
	return {}


# --- Produção oportunista ----------------------------------------------------------------

func crop_value(crop_id: String) -> int:
	var crop: Dictionary = Database.crops[crop_id]
	var total := int(crop.get("coins", 0))
	for item: String in crop.get("yield", {}):
		total += price(item) * int(crop.yield[item])
	return total


func crop_unlocked(crop_id: String) -> bool:
	return gs.content_error("crop", crop_id, Database.crops[crop_id]) == ""


## Nota da cultura para plantar agora: valor por tempo, considerando quando o jogador volta.
func crop_score(crop_id: String) -> float:
	var crop: Dictionary = Database.crops[crop_id]
	var seconds := float(crop.get("seconds", 60)) * (0.7 if bool(profile.get("water", true)) else 1.0)
	var value := float(crop_value(crop_id))
	if seconds <= session_left * 0.8:
		return value / seconds
	return value / (session_left + next_gap)


func empty_plots(crop_id: String) -> Array[int]:
	var result: Array[int] = []
	for i: int in gs.usable_plot_indices():
		if gs.plant_error(i, crop_id) == "":
			result.append(i)
	return result


func _opportunistic_plant() -> Dictionary:
	if is_avoided("plant"):
		return {}
	var best := ""
	var best_score := 0.0
	for crop_id: String in Database.crops:
		if not crop_unlocked(crop_id) or empty_plots(crop_id).is_empty():
			continue
		if not fits(Database.crops[crop_id].yield):
			continue
		var score := crop_score(crop_id)
		if score > best_score:
			best = crop_id
			best_score = score
	if best == "":
		return {}
	var chosen: Array[int] = empty_plots(best)
	var room := _max_batches_fitting(Database.crops[best].yield, chosen.size())
	if room <= 0:
		return {}
	return _action("plant_many", {"plots": chosen.slice(0, room), "crop": best}, "farm", "produce")


func _max_batches_fitting(items: Dictionary, limit: int) -> int:
	var count := limit
	while count > 0:
		var scaled: Dictionary = {}
		for item: String in items:
			scaled[item] = int(items[item]) * count
		if fits(scaled):
			return count
		count -= 1
	return 0


func _opportunistic_cook() -> Dictionary:
	var best := ""
	var best_score := 0.0
	for station_id: String in Database.stations:
		if not gs.has_upgrade(station_id):
			continue
		if gs.station(station_id).queue.size() >= gs.station_slots(station_id):
			continue
		for rid: String in Database.recipes_for(station_id):
			var recipe: Dictionary = Database.recipes[rid]
			if recipe.has("output_collection") or gs.cook_error(rid) != "" or is_avoided("cook" + rid):
				continue
			var inputs: Dictionary = gs.recipe_inputs(rid)
			var cost := 0
			var ok := true
			for item: String in inputs:
				if avail(item, false) < int(inputs[item]):
					ok = false
				cost += price(item) * int(inputs[item])
			if not ok:
				continue
			var out: String = Database.recipe_output(recipe)
			var qty: int = gs.recipe_quantity(rid)
			if not fits({out: qty}):
				continue
			# Só cozinha se rende mais que vender os ingredientes (o que o jogador percebe).
			var margin := price(out) * qty - cost
			var feed_value := 0
			if Database.items.get(out, {}).has("feed") and best_food(false) == "":
				feed_value = 10
			if margin + feed_value <= 0:
				continue
			var seconds := float(recipe.seconds)
			var score := float(margin + feed_value) / maxf(seconds, 30.0)
			if session_left < seconds and next_gap > seconds:
				score = float(margin + feed_value) / (session_left + next_gap)
			if score > best_score:
				best = rid
				best_score = score
	if best == "":
		return {}
	return _action("cook", {"recipe": best}, "station:" + str(Database.recipes[best].station), "produce")


func _opportunistic_gather() -> Dictionary:
	if is_avoided("gather"):
		return {}
	var best := {}
	var best_score := 0.0
	for site: String in Database.progression.get("nature_sites", {}):
		if gs.gathering_free_count(site) <= 0:
			continue
		for route: String in Database.progression.activities:
			if Database.gathering_site(route) != site:
				continue
			var index := _first_free_slot(site)
			if index < 0 or gs.gathering_error(site, index, route) != "":
				continue
			var data: Dictionary = Database.progression.activities[route]
			if not fits(data.get("rewards", {}).get("items", {})):
				continue
			var value := float(data.get("rewards", {}).get("coins", 0))
			for item: String in data.get("rewards", {}).get("items", {}):
				# Materiais valem mais que o preço de venda: constroem a casa.
				value += float(maxi(price(item), 6)) * float(data.rewards.items[item])
			var seconds := float(data.seconds)
			var score := value / maxf(seconds, 30.0)
			if session_left < seconds and next_gap > seconds:
				score = value / (session_left + next_gap)
			if score > best_score:
				best = {"site": site, "index": index, "route": route}
				best_score = score
	if best.is_empty():
		return {}
	return _action("start_gathering", best, "nature:" + str(best.site), "produce")


func _opportunistic_activity() -> Dictionary:
	## Rota única sem local da Natureza (pomar): uma de cada vez.
	if not gs.progress.activity.is_empty() or is_avoided("activity"):
		return {}
	for route: String in Database.progression.activities:
		if Database.gathering_site(route) != "" or gs.activity_error(route) != "":
			continue
		var data: Dictionary = Database.progression.activities[route]
		if fits(data.get("rewards", {}).get("items", {})):
			return _action("start_activity", {"route": route}, "orchard", "produce")
	return {}


func _first_free_slot(site: String) -> int:
	for index in gs.gathering_slots(site):
		if gs.gathering_entry(site, index).is_empty():
			return index
	return -1


func _opportunistic_walk() -> Dictionary:
	var id := best_walk()
	if id == "":
		return {}
	return _action("start_walk", {"id": id}, "walk", "produce")


## Passeio que o jogador escolheria: o mais longo que cabe antes da próxima volta; novos primeiro.
func best_walk(wanted: String = "", rare: bool = false) -> String:
	if gs.walking() or not place_open("park", "walk"):
		return ""
	var best := ""
	var best_score := -1.0
	for id: String in Database.walks.get("walks", {}):
		if wanted != "" and id != wanted:
			continue
		if gs.walk_error(id) != "" or is_avoided("walk" + id):
			continue
		var seconds := float(Database.walks.walks[id].seconds)
		var fresh := int(gs.walk_state.history.get(id, {}).get("count", 0)) == 0
		var score := seconds / 100.0 + (1000.0 if fresh else 0.0)
		if rare:
			# Atrás do raro: repete o caminho mais perto da garantia (pity), desempate pelo mais curto.
			score = 10000.0 - float(gs.walk_pity_left(id)) * 100.0 - seconds / 100.0
		if seconds > next_gap + session_left:
			score -= 500.0
		if score > best_score:
			best = id
			best_score = score
	return best


# --- Espaço: vender o que atrapalha a colheita -----------------------------------------------

func _make_space_for_crop(crop_id: String) -> Dictionary:
	return _make_space_for(Database.crops.get(crop_id, {}).get("yield", {}))


func _make_space_for_station(station_id: String) -> Dictionary:
	var needed: Dictionary = {}
	for entry: Dictionary in gs.station(station_id).queue:
		if float(entry.ready_at) <= t():
			var recipe: Dictionary = Database.recipes.get(str(entry.recipe), {})
			needed[Database.recipe_output(recipe)] = int(entry.get("qty", recipe.get("qty", 1)))
	return _make_space_for(needed)


func _make_space_for(items: Dictionary) -> Dictionary:
	var sale := _make_space_pass(items, false)
	if not sale.is_empty():
		return sale
	# Depósito cheio só de achados de passeio que o perfil guardaria: o jogador vende o que sobra (etapa 13).
	return _make_space_pass(items, true)


func _make_space_pass(items: Dictionary, force_trail: bool) -> Dictionary:
	if not market_open():
		return {}
	for item: String in items:
		var depot: String = gs.storage_of(item)
		if depot == "":
			continue
		var best := ""
		var best_amount := 0
		for other: String in sorted_keys(gs.inventory.counts):
			if gs.storage_of(other) != depot or not _sellable(other, force_trail):
				continue
			if force_trail and str(Database.items.get(other, {}).get("category", "")) != "trail":
				continue
			var amount := avail(other, false)
			if Database.items.get(other, {}).has("feed"):
				amount = maxi(0, amount - FOOD_KEEP)
			if amount > best_amount:
				best = other
				best_amount = amount
		if best != "":
			var need := int(items[item])
			return _action("sell", {"item": best, "qty": mini(best_amount, maxi(need, best_amount / 2)), "space": true}, "market", "space")
	return {}


# --- Busca de objetivos ------------------------------------------------------------------------

func pursue_step(qid: String, shield: bool, depth: int) -> Dictionary:
	if depth > MAX_DEPTH or not Database.quests.has(qid):
		return _block("depth", qid)
	if gs.progress.claimed_quests.has(qid):
		return _done()
	if gs.quest_error(qid) == "":
		return _act(_action("claim_quest", {"id": qid}, "tasks", "story"))
	var results: Array = []
	for goal: Dictionary in Database.quests[qid].goals:
		var r: Dictionary = pursue_goal(goal, shield, depth + 1, qid)
		if str(r.state) == ACT:
			return r
		results.append(r)
	return _combine(results)


func pursue_goal(goal: Dictionary, shield: bool, depth: int, qid: String) -> Dictionary:
	if depth > MAX_DEPTH:
		return _block("depth", qid)
	var target := int(goal.get("target", 1))
	var value: int = gs.goal_value(goal)
	var key := str(goal.get("key", ""))
	match str(goal.type):
		"owned":
			return pursue_upgrade(key, shield, depth + 1)
		"quest":
			return pursue_quest(key, shield, depth + 1)
		"project":
			return pursue_project(key, shield, depth + 1, qid)
		"growth":
			return _done() if value >= target else pursue_growth(key, shield, depth + 1, qid)
		"have", "deliver":
			return pursue_item(key, target, shield, depth + 1)
		"coins":
			return _done() if value >= target else earn_coins(target - value, shield, depth + 1)
		"skill":
			return _done() if value >= target else _block("skill:" + key, qid)
		"chapter":
			return _done() if value >= target else _block("chapter", qid)
		"stat":
			if value >= target:
				return _done()
			return pursue_stat(key, target - value, shield, depth + 1, qid)
	return _block("goal:" + str(goal.type), qid)


func pursue_quest(qid: String, shield: bool, depth: int) -> Dictionary:
	var result: Dictionary = _pursue_quest_inner(qid, shield, depth)
	if trace_on:
		trace.append("%s%s -> %s %s" % ["  ".repeat(mini(depth, 20)), "quest %s"%[qid], str(result.state), str(result.get("why", result.get("action", {}).get("kind", "")))])
	return result


func _pursue_quest_inner(qid: String, shield: bool, depth: int) -> Dictionary:
	if gs.progress.claimed_quests.has(qid):
		return _done()
	var quest: Dictionary = Database.quests.get(qid, {})
	if quest.is_empty():
		return _block("quest:" + qid)
	var line: String = gs.progress.quest_line(qid)
	var current: String = ""
	if line == "main":
		current = gs.progress.current_main_quest()
		var shared := str(Database.quests.get(current, {}).get("shared_with", ""))
		if shared != "":
			return pursue_quest(shared, shield, depth + 1)
	else:
		current = gs.progress.current_line_quest(line)
	if current == "":
		# Linha esperando um requisito (ex.: Bloblo depois da Laís).
		for id: String in gs.progress.line_quests(line):
			if not gs.progress.claimed_quests.has(id):
				return pursue_reqs(Database.quests[id].get("requirements", {}), shield, depth + 1, qid)
		return _done()
	return pursue_step(current, shield, depth + 1)


func pursue_reqs(requirements: Dictionary, shield: bool, depth: int, who: String = "") -> Dictionary:
	if depth > MAX_DEPTH:
		return _block("depth", who)
	var results: Array = []
	for item: String in requirements.get("produced", {}):
		if gs.progress.stat("produce:" + item) < int(requirements.produced[item]):
			results.append(pursue_stat("produce:" + item, int(requirements.produced[item]) - gs.progress.stat("produce:" + item), shield, depth + 1, who))
	for key: String in requirements.get("stats", {}):
		var missing: int = int(requirements.stats[key]) - gs.progress.stat(key)
		if missing > 0:
			results.append(pursue_stat(key, missing, shield, depth + 1, who))
	for channel: String in requirements.get("distinct_orders", {}):
		if gs.progress.distinct_orders(channel) < int(requirements.distinct_orders[channel]):
			results.append(_pursue_any_order(channel == "contracts", shield, depth + 1, true))
	if gs.progress.chapter_index() < int(requirements.get("chapter", 1)):
		results.append(_block("chapter", who))
	for id: String in requirements.get("owned", []):
		if not gs.has_upgrade(id):
			results.append(pursue_upgrade(id, shield, depth + 1))
	for id: String in requirements.get("quests", []):
		if not gs.progress.claimed_quests.has(id):
			results.append(pursue_quest(id, shield, depth + 1))
	for id: String in requirements.get("projects", []):
		if not gs.project_completed(id):
			results.append(pursue_project(id, shield, depth + 1, who))
	if requirements.has("growth") and gs.growth.phase_index() < gs.growth.phase_index(str(requirements.growth)):
		results.append(pursue_growth(str(requirements.growth), shield, depth + 1, who))
	for id: String in requirements.get("skills", {}):
		if gs.progress.skill_level(id) < int(requirements.skills[id]):
			results.append(_block("skill:" + id, who))
	if requirements.has("bond") and gs.progress.bond_level(gs.dog.affection) < int(requirements.bond):
		results.append(_block("bond", who))
	if requirements.has("hours") and gs.requirement_error({"hours": requirements.hours}) != "":
		results.append(_wait("hours"))
	return _combine(results)


func pursue_upgrade(id: String, shield: bool, depth: int) -> Dictionary:
	var result: Dictionary = _pursue_upgrade_inner(id, shield, depth)
	if trace_on:
		trace.append("%s%s -> %s %s" % ["  ".repeat(mini(depth, 20)), "upgrade %s"%[id], str(result.state), str(result.get("why", result.get("action", {}).get("kind", "")))])
	return result


func _pursue_upgrade_inner(id: String, shield: bool, depth: int) -> Dictionary:
	if gs.has_upgrade(id):
		return _done()
	if depth > MAX_DEPTH:
		return _block("depth", id)
	var data: Dictionary = Database.progression.upgrades.get(id, {})
	if data.is_empty():
		return _block("upgrade:" + id)
	if data.has("nature_unlock"):
		return _pursue_nature_xp(str(data.nature_unlock.site), shield, depth + 1)
	if gs.requirement_error(data.get("requirements", {})) != "":
		return pursue_reqs(data.requirements, shield, depth + 1, id)
	var results: Array = []
	_protect_all(data.get("materials", {}), shield)
	for item: String in data.get("materials", {}):
		if avail(item, shield) < int(data.materials[item]):
			results.append(pursue_item(item, int(data.materials[item]), shield, depth + 1))
	if not results.is_empty():
		var merged: Dictionary = _combine(results)
		if str(merged.state) != DONE:
			return merged
	if gs.coins < int(data.get("cost", 0)):
		return earn_coins(int(data.cost) - gs.coins, shield, depth + 1)
	var at: Array[String] = Database.place_of_upgrade(id)
	if at[0] != "" and not place_open(at[0], at[1]):
		return _block("place:" + at[0], id)
	return _act(_action("buy_upgrade", {"id": id}, _upgrade_ctx(id), "goal"))


## Rotas que rendem `item` (ou, sem item, as do local), da melhor para a pior no ritmo do jogador:
## cabendo na sessão vale a taxa por segundo; senão só dá para colher na próxima visita (taxa por intervalo).
func _routes_by_rate(item: String, site: String = "") -> Array[String]:
	var ranked: Array = []
	var order := 0
	for route: String in Database.progression.activities:
		var data: Dictionary = Database.progression.activities[route]
		if site != "" and Database.gathering_site(route) != site:
			continue
		if site == "" and not data.get("rewards", {}).get("items", {}).has(item):
			continue
		var amount := float(data.get("nature_xp", 1)) if site != "" else float(data.rewards.items[item])
		var seconds := maxf(1.0, float(data.seconds))
		var rate := amount / seconds
		if seconds > session_left * 0.8 and next_gap > seconds:
			rate = amount / (session_left + next_gap)
		ranked.append([rate, order, route])
		order += 1
	ranked.sort_custom(func(x: Array, y: Array) -> bool:
		return x[0] > y[0] or (x[0] == y[0] and x[1] < y[1]))
	var result: Array[String] = []
	for entry: Array in ranked:
		result.append(str(entry[2]))
	return result


func _pursue_nature_xp(site: String, shield: bool, depth: int) -> Dictionary:
	var results: Array = []
	for route: String in _routes_by_rate("", site):
		# Rota que só abre quando o próprio local sobe de nível não ajuda a subir de nível (laço).
		var circular := false
		for needed: String in Database.progression.activities[route].get("requirements", {}).get("owned", []):
			if not gs.has_upgrade(needed) and Database.progression.upgrades.get(needed, {}).has("nature_unlock") and str(Database.progression.upgrades[needed].nature_unlock.site) == site:
				circular = true
		if circular:
			continue
		var r: Dictionary = _pursue_route(route, shield, depth + 1)
		if str(r.state) == ACT:
			return r
		results.append(r)
	return _combine(results) if not results.is_empty() else _block("site:" + site)


## Uma coleta numa rota. Se a rota ainda não está liberada, busca o requisito.
## Rotas sem local da Natureza (o pomar) usam a rota única de progress.activity.
func _pursue_route(route: String, shield: bool, depth: int) -> Dictionary:
	var result: Dictionary = _pursue_route_inner(route, shield, depth)
	if trace_on:
		trace.append("%s%s -> %s %s" % ["  ".repeat(mini(depth, 20)), "route %s"%[route], str(result.state), str(result.get("why", result.get("action", {}).get("kind", "")))])
	return result


func _pursue_route_inner(route: String, shield: bool, depth: int) -> Dictionary:
	var data: Dictionary = Database.progression.activities.get(route, {})
	var site: String = Database.gathering_site(route)
	if data.is_empty():
		return _block("route:" + route)
	var reqs: Dictionary = data.get("requirements", {})
	if gs.requirement_error(reqs) != "":
		return pursue_reqs(reqs, shield, depth + 1, route)
	var reward_items: Dictionary = data.get("rewards", {}).get("items", {})
	if site == "":
		if not gs.progress.activity.is_empty():
			return _wait("activity")
		if gs.activity_error(route) != "":
			return _block("route_error:" + route)
		if not fits(reward_items):
			return _space_or_block(reward_items)
		return _act(_action("start_activity", {"route": route}, "orchard", "goal"))
	if gs.progress.nature_level(site) == 0:
		return _block("site_closed:" + site)
	var index := _first_free_slot(site)
	if index < 0:
		return _wait_gathering(site)
	if gs.gathering_error(site, index, route) != "":
		return _block("route_error:" + route)
	if not fits(reward_items):
		return _space_or_block(reward_items)
	return _act(_action("start_gathering", {"site": site, "index": index, "route": route}, "nature:" + site, "goal"))


## Falta espaço no depósito: o jogador vende o que sobra; se não há o que vender, é bloqueio do jogo.
func _space_or_block(items: Dictionary) -> Dictionary:
	var sale := _make_space_for(items)
	if not sale.is_empty():
		return _act(sale)
	return _block("storage:" + _depot_of_items(items))


func _wait_gathering(_site: String) -> Dictionary:
	return _wait("gathering")


func _depot_of_items(items: Dictionary) -> String:
	for item: String in items:
		var depot: String = gs.storage_of(item)
		if depot != "":
			return depot
	return ""


## Fontes de um item, na ordem em que o jogador tenta: plantar, fabricar, coletar, pedido, passeio.
func pursue_item(item: String, qty: int, shield: bool, depth: int) -> Dictionary:
	var result: Dictionary = _pursue_item_inner(item, qty, shield, depth)
	if trace_on:
		trace.append("%s%s -> %s %s" % ["  ".repeat(mini(depth, 20)), "item %s x%d"%[item, qty], str(result.state), str(result.get("why", result.get("action", {}).get("kind", "")))])
	return result


func _pursue_item_inner(item: String, qty: int, shield: bool, depth: int) -> Dictionary:
	if depth > MAX_DEPTH:
		return _block("depth", item)
	# A meta reservada protege o item MESMO quando já está na mochila (senão um pedido o gasta antes da compra).
	if shield:
		protect[item] = maxi(int(protect.get(item, 0)), qty)
	var have_now := avail(item, shield)
	if have_now >= qty:
		return _done()
	var missing := qty - have_now - inflight(item)
	if missing <= 0:
		return _wait("inflight:" + item)
	var results: Array = []
	# 1. cultura
	for crop_id: String in Database.crops:
		var yield_per: int = int(Database.crops[crop_id].get("yield", {}).get(item, 0))
		if yield_per > 0:
			results.append(_pursue_crop(crop_id, item, missing, yield_per, shield, depth))
	# 2. receita
	for rid: String in Database.recipes:
		if Database.recipe_output(Database.recipes[rid]) == item and not Database.recipes[rid].has("output_collection"):
			results.append(_pursue_recipe(rid, missing, shield, depth))
	# 3. rota da Natureza (a que rende mais pelo tempo que a sessão deixa; empate: ordem dos dados)
	for route: String in _routes_by_rate(item):
		results.append(_pursue_route(route, shield, depth + 1))
	# 4. recompensa de pedido (parafuso, aro)
	for oid: String in Database.progression.orders:
		if Database.progression.orders[oid].get("rewards", {}).get("items", {}).has(item):
			results.append(_pursue_order(oid, shield, depth + 1))
	# 5. passeio / faro (sorte): trilha e achados
	var category := str(Database.items.get(item, {}).get("category", ""))
	if category == "trail":
		results.append(_pursue_walk_for(item))
	elif category == "find":
		results.append(_pursue_find())
	# 6. lembrança do Tiro sem receita (argolinha, medalhinha): vem do prêmio de uma missão
	if category == "keepsake":
		for qid: String in Database.quests:
			if Database.quests[qid].get("rewards", {}).get("items", {}).has(item) and not gs.progress.claimed_quests.has(qid):
				results.append(pursue_quest(qid, shield, depth + 1))
	if results.is_empty():
		return _block("no_source:" + item)
	var merged: Dictionary = _combine(results)
	if str(merged.state) == BLOCK and category not in ["trail", "find"]:
		return _block("no_path:" + item)
	return merged


func _pursue_crop(crop_id: String, item: String, missing: int, yield_per: int, shield: bool, depth: int) -> Dictionary:
	var crop: Dictionary = Database.crops[crop_id]
	if not crop_unlocked(crop_id):
		return pursue_reqs(crop.get("requirements", {}), shield, depth + 1, crop_id)
	var spots := empty_plots(crop_id)
	if spots.is_empty():
		if _any_planted(crop_id) or _any_planted(""):
			return _wait("plot")
		return _block("no_plot:" + crop_id)
	var count := mini(spots.size(), ceili(float(missing) / float(yield_per)))
	count = _max_batches_fitting(crop.yield, count)
	if count <= 0:
		return _space_or_block(crop.yield)
	return _act(_action("plant_many", {"plots": spots.slice(0, count), "crop": crop_id}, "farm", "goal"))


func _any_planted(crop_id: String) -> bool:
	for i: int in gs.usable_plot_indices():
		if gs.plot_status(i) in ["growing", "ready"] and (crop_id == "" or str(gs.plot(i).crop) == crop_id):
			return true
	return false


func _pursue_recipe(rid: String, missing_units: int, shield: bool, depth: int) -> Dictionary:
	var result: Dictionary = _pursue_recipe_inner(rid, missing_units, shield, depth)
	if trace_on:
		trace.append("%s%s -> %s %s" % ["  ".repeat(mini(depth, 20)), "recipe %s"%[rid], str(result.state), str(result.get("why", result.get("action", {}).get("kind", "")))])
	return result


func _pursue_recipe_inner(rid: String, missing_units: int, shield: bool, depth: int) -> Dictionary:
	var recipe: Dictionary = Database.recipes[rid]
	var station_id: String = recipe.station
	if not gs.has_upgrade(station_id):
		return pursue_upgrade(Database.station_upgrade(station_id), shield, depth + 1)
	if gs.content_error("recipe", rid, recipe) != "":
		return pursue_reqs(recipe.get("requirements", {}), shield, depth + 1, rid)
	if Database.stations[station_id].get("kind", "") == "animal" and gs.animal_count(station_id) == 0:
		return _pursue_animal(station_id)
	var batches := ceili(float(missing_units) / float(maxi(1, gs.recipe_quantity(rid))))
	var inputs: Dictionary = gs.recipe_inputs(rid)
	var results: Array = []
	var complete := true
	_protect_all(inputs, shield)
	for item: String in inputs:
		var need: int = int(inputs[item])
		if avail(item, shield) < need:
			complete = false
			results.append(pursue_item(item, need, shield, depth + 1))
	if not complete:
		return _combine(results)
	var error: String = gs.cook_error(rid)
	if error == "Fila cheia":
		return _wait("queue:" + station_id)
	if error != "":
		return _block("cook:" + error)
	if is_avoided("cook" + rid):
		return _wait("avoid")
	var out: String = Database.recipe_output(recipe)
	if not fits({out: gs.recipe_quantity(rid)}):
		return _space_or_block({out: gs.recipe_quantity(rid)})
	if batches > 0:
		return _act(_action("cook", {"recipe": rid}, "station:" + station_id, "goal"))
	return _done()


func _pursue_animal(station_id: String) -> Dictionary:
	for id: String in Database.animals:
		if str(Database.animals[id].station) == station_id and gs.buy_animal_error(id) == "":
			return _act(_action("buy_animal", {"id": id}, "station:" + station_id, "goal"))
	for id: String in Database.animals:
		if str(Database.animals[id].station) == station_id:
			if gs.buy_animal_error(id) == "Faltam moedas":
				return earn_coins(int(Database.animals[id].price) - gs.coins, true, 3)
	return _block("animal:" + station_id)


func _pursue_order(oid: String, shield: bool, depth: int) -> Dictionary:
	var result: Dictionary = _pursue_order_inner(oid, shield, depth)
	if trace_on:
		trace.append("%s%s -> %s %s" % ["  ".repeat(mini(depth, 20)), "order %s"%[oid], str(result.state), str(result.get("why", result.get("action", {}).get("kind", "")))])
	return result


func _pursue_order_inner(oid: String, shield: bool, depth: int) -> Dictionary:
	var order: Dictionary = Database.progression.orders[oid]
	if gs.requirement_error(order.get("requirements", {})) != "":
		return pursue_reqs(order.requirements, shield, depth + 1, oid)
	var wait: int = gs.progress.cooldown_left("order:" + oid, t())
	if wait > 0:
		return _wait("cooldown:" + oid)
	var results: Array = []
	var complete := true
	_protect_all(order.inputs, shield)
	for item: String in order.inputs:
		if avail(item, shield) < int(order.inputs[item]):
			complete = false
			results.append(pursue_item(item, int(order.inputs[item]), shield, depth + 1))
	if not complete:
		return _combine(results)
	if not orders_open():
		return _block("place:orders")
	return _act(_action("fulfill_order", {"id": oid}, "orders", "goal"))


func _pursue_walk_for(item: String) -> Dictionary:
	var ids: Array[String] = []
	for source: Dictionary in Database.item_sources(item):
		var key := str(source.key)
		if key.begins_with("walk:"):
			ids.append(key.trim_prefix("walk:"))
	for id in ids:
		var r := _pursue_walk(id)
		if str(r.state) != BLOCK:
			return r
	return _block("luck:walk:" + item)


func _pursue_find() -> Dictionary:
	for world: String in sorted_keys(gs.finds.worlds):
		if gs.dig_error(world) == "":
			return _act(_action("dig", {"world": world}, "dig:" + world, "goal"))
	return _wait("find")


## Um passeio (wanted vazio = qualquer): resolve horário, energia, sono e volta.
func _pursue_walk(wanted: String, rare: bool = false) -> Dictionary:
	if not place_open("park", "walk"):
		return _block("place:park")
	if gs.walking():
		return _wait("walk")
	var id := best_walk(wanted, rare)
	if id != "":
		return _act(_action("start_walk", {"id": id}, "walk", "goal"))
	# Por que não há passeio liberado agora?
	var ids: Array = [wanted] if wanted != "" else Database.walks.walks.keys()
	var reasons: Array = []
	for walk_id: String in ids:
		var lock: String = gs.walk_lock_error(walk_id)
		if lock != "":
			reasons.append(lock)
			continue
		var error: String = gs.walk_error(walk_id)
		if error.begins_with("Abre às"):
			return _wait("hours")
		if error == "Tiro está dormindo":
			return _act(_action("sleep", {"value": false}, "pet", "goal")) if gs.dog.get_need("energy", t()) >= 40.0 else _wait("sleep")
		if error.begins_with("Tiro está cansado"):
			if gs.dog.sleeping:
				return _wait("sleep")
			return _act(_action("sleep", {"value": true}, "pet", "goal"))
	if wanted != "":
		var def: Dictionary = gs.walk_def(wanted)
		if not def.is_empty() and gs.walk_lock_error(wanted) != "" and _walk_nesting < 2:
			# O passeio trancado pode pedir fase do Tiro, que pede item de passeio: limita a reentrada.
			_walk_nesting += 1
			var r: Dictionary = pursue_reqs(_walk_reqs(def), false, 4, wanted)
			_walk_nesting -= 1
			return r
	return _block("walk_locked")


func _walk_reqs(def: Dictionary) -> Dictionary:
	var reqs: Dictionary = def.get("requirements", {}).duplicate()
	reqs.erase("hours")
	return reqs


func earn_coins(amount: int, shield: bool, depth: int) -> Dictionary:
	if amount <= 0:
		return _done()
	if depth > MAX_DEPTH:
		return _block("coins", focus_id)
	# 1. vender o que sobra
	if market_open() and _surplus_value() > 0:
		var sale := _sell_best("")
		if not sale.is_empty():
			return _act(sale)
	# 2. pedido que paga
	if orders_open():
		var order := _best_order_to_make(shield, depth)
		if str(order.state) == ACT:
			return order
	# 3. plantar o que mais rende
	var plant := _opportunistic_plant()
	if not plant.is_empty():
		plant["why"] = "earn"
		return _act(plant)
	var cook := _opportunistic_cook()
	if not cook.is_empty():
		cook["why"] = "earn"
		return _act(cook)
	if _any_planted(""):
		return _wait("coins:growing")
	return _wait("coins")


## Pedido com melhor ganho sobre vender os ingredientes e que dá para montar já.
func _best_order_to_make(shield: bool, depth: int) -> Dictionary:
	var best := ""
	var best_gain := 0
	for id: String in Database.progression.orders:
		if gs.requirement_error(Database.progression.orders[id].get("requirements", {})) != "":
			continue
		var order: Dictionary = Database.progression.orders[id]
		var sale := 0
		for item: String in order.inputs:
			sale += price(item) * int(order.inputs[item])
		var gain := int(order.rewards.get("coins", 0)) - sale
		if gain > best_gain:
			best = id
			best_gain = gain
	if best == "":
		return _wait("no_order")
	return _pursue_order(best, shield, depth + 1)


# --- Metas do tipo contador (stat) ------------------------------------------------------------------

func pursue_stat(key: String, remaining: int, shield: bool, depth: int, qid: String) -> Dictionary:
	if depth > MAX_DEPTH:
		return _block("depth", qid)
	var prefix := key.get_slice(":", 0)
	var arg := key.get_slice(":", 1) if ":" in key else ""
	match prefix:
		"talk":
			if not gs.progress.npc_visible(arg):
				return pursue_reqs(Database.npcs.get(arg, {}).get("requirements", {}), shield, depth + 1, qid)
			var world: String = Database.npc_world(arg)
			if world != "" and not world_open(world):
				return pursue_reqs(Database.worlds[world].get("requirements", {}), shield, depth + 1, qid)
			return _act(_action("talk", {"npc": arg}, "npc:" + arg, "goal"))
		"project_use":
			if not gs.project_completed(arg):
				return pursue_project(arg, shield, depth + 1, qid)
			if gs.project_use_error(arg) != "":
				return _wait("project_use")
			var use_go: Dictionary = Database.project(arg).get("go", {})
			return _act(_action("use_project", {"id": arg}, "place:%s/%s" % [use_go.get("world", ""), use_go.get("place", "")], "goal"))
		"open":
			var feature: Dictionary = Database.progression.get("features", {}).get(arg, {})
			if not feature.is_empty() and not gs.progress.feature_unlocked(arg):
				return pursue_reqs(feature.get("requirements", {}), shield, depth + 1, qid)
			if Database.worlds.has(arg) and not world_open(arg):
				return pursue_reqs(Database.worlds[arg].get("requirements", {}), shield, depth + 1, qid)
			return _act(_action("open_screen", {"screen": arg}, "screen:" + arg, "goal"))
		"feed":
			return _pursue_feed(shield, depth)
		"bathe":
			if gs.walking():
				return _wait("walk")
			return _act(_action("bathe", {}, "pet", "goal"))
		"shampoo_bath":
			return _pursue_shampoo_bath(shield, depth)
		"play":
			return _pursue_play()
		"pet":
			if gs.walking():
				return _wait("walk")
			return _act(_action("pet", {}, "pet", "goal"))
		"trick":
			for id: String in Database.progression.tricks:
				if gs.perform_trick_error(id) == "":
					return _act(_action("perform_trick", {"id": id}, "pet", "goal"))
			return _wait("trick")
		"water":
			return _pursue_water(shield, depth)
		"harvest":
			return _pursue_harvest(arg, remaining, shield, depth)
		"produce":
			return _pursue_produce(arg, remaining, shield, depth)
		"sold":
			return _pursue_sold(remaining, shield, depth)
		"orders", "contracts":
			return _pursue_any_order(prefix == "contracts", shield, depth)
		"order":
			return _pursue_order(arg, shield, depth + 1)
		"activity":
			return _pursue_route(arg, shield, depth + 1)
		"explore":
			return _pursue_any_route(shield, depth)
		"walk":
			return _pursue_walk(arg)
		"walk_rare", "walk_legendary":
			return _pursue_walk("", true)
		"walk_item":
			return _pursue_walk("")
		"find":
			return _pursue_find_world(arg)
		"equip":
			return _pursue_equip(shield, depth)
		"sew":
			return _pursue_sew(shield, depth)
		"friend_gift":
			return _pursue_friend(arg, shield, depth)
		"friend_level":
			return _pursue_friend("", shield, depth)
		"trick_learned":
			return _pursue_trick(shield, depth)
		"treasure":
			if gs.open_treasure_error() == "":
				return _act(_action("open_treasure", {}, "treasure", "goal"))
			return pursue_quest("guide_treasure", shield, depth + 1)
		"wish_item":
			return _pursue_wish_item(arg, shield, depth)
	return _block("stat:" + key, qid)


## Desejo de um item (missão `wish_item:<item>`): faz o item, entrega no espaço que o pede e, sem pedido, espera a vaga.
func _pursue_wish_item(item: String, shield: bool, depth: int) -> Dictionary:
	if gs.walking():
		return _wait("walk")
	var slot: int = gs.wish_slot_for_item(item)
	if slot >= 0:
		return _act(_action("fulfill_wish", {"slot": slot}, "wish", "goal"))
	var made: Dictionary = pursue_item(item, 1, shield, depth + 1)
	if str(made.state) != DONE:
		return made
	return _wait("wish")


func _pursue_feed(shield: bool, depth: int) -> Dictionary:
	if gs.walking():
		return _wait("walk")
	var food := best_food(shield)
	if food != "":
		return _act(_action("feed", {"item": food}, "pet", "goal"))
	if emergency_ready():
		return _act(_action("emergency_food", {}, "pet", "goal"))
	return pursue_item("carrot", 1, shield, depth + 1)


func _pursue_play() -> Dictionary:
	if gs.walking():
		return _wait("walk")
	var energy: float = gs.dog.get_need("energy", t())
	if gs.dog.sleeping:
		# Só acorda o Tiro quando já descansou o bastante para brincar (senão os dois pedidos brigam).
		if energy < 40.0:
			return _wait("sleep")
		return _act(_action("sleep", {"value": false}, "pet", "goal"))
	if energy < 15.0:
		return _act(_action("sleep", {"value": true}, "pet", "goal"))
	return _act(_action("play", {}, "pet", "goal"))


func _pursue_water(shield: bool, depth: int) -> Dictionary:
	for i: int in gs.usable_plot_indices():
		if gs.water_error(i) == "":
			return _act(_action("water_many", {"plots": [i]}, "farm", "goal"))
	for i: int in gs.usable_plot_indices():
		if gs.plot_status(i) == "growing":
			return _wait("plot")
	return _pursue_crop("carrot", "carrot", 1, 2, shield, depth)


func _pursue_harvest(crop_id: String, remaining: int, shield: bool, depth: int) -> Dictionary:
	var ready: Array[int] = []
	var growing := 0
	for i: int in gs.usable_plot_indices():
		var status: String = gs.plot_status(i)
		if status == "empty" or (crop_id != "" and str(gs.plot(i).crop) != crop_id):
			continue
		if status == "ready" and gs.harvest_error(i) == "":
			ready.append(i)
		elif status in ["growing", "ready"]:
			growing += 1
	if not ready.is_empty():
		return _act(_action("harvest_many", {"plots": ready}, "farm", "goal"))
	var chosen := crop_id
	if chosen == "":
		chosen = _fastest_crop()
	if chosen == "":
		return _block("no_crop")
	if growing >= remaining:
		return _wait("plot")
	var crop: Dictionary = Database.crops[chosen]
	if not crop_unlocked(chosen):
		return pursue_reqs(crop.get("requirements", {}), shield, depth + 1, chosen)
	var spots := empty_plots(chosen)
	if spots.is_empty():
		return _wait("plot") if growing > 0 or _any_planted("") else _block("no_plot")
	var item: String = str(crop.yield.keys()[0])
	return _pursue_crop(chosen, item, maxi(1, remaining - growing), int(crop.yield[item]), shield, depth)


func _fastest_crop() -> String:
	var best := ""
	var best_seconds := 1.0e9
	for id: String in Database.crops:
		if crop_unlocked(id) and not empty_plots(id).is_empty() and float(Database.crops[id].seconds) < best_seconds and fits(Database.crops[id].yield):
			best = id
			best_seconds = float(Database.crops[id].seconds)
	if best == "":
		for id: String in Database.crops:
			if crop_unlocked(id) and float(Database.crops[id].seconds) < best_seconds:
				best = id
				best_seconds = float(Database.crops[id].seconds)
	return best


func _pursue_produce(item: String, remaining: int, shield: bool, depth: int) -> Dictionary:
	if item != "":
		# O contador só sobe ao recolher: o que já está na fila conta como a caminho.
		var made := inflight(item)
		var ready_stations := 0
		for id: String in sorted_keys(gs.stations):
			ready_stations += gs.station(id).ready_count(t())
		if made >= remaining:
			return _wait("inflight:" + item) if ready_stations == 0 else _done()
		var results: Array = []
		for rid: String in Database.recipes:
			if Database.recipe_output(Database.recipes[rid]) == item:
				results.append(_pursue_recipe(rid, remaining - made, shield, depth + 1))
		return _combine(results) if not results.is_empty() else _block("no_recipe:" + item)
	# "produce" genérico: a receita mais barata que dá para fazer.
	var ranked: Array[String] = []
	for rid: String in Database.recipes:
		if not Database.recipes[rid].has("output_collection"):
			ranked.append(rid)
	ranked.sort_custom(func(a: String, b: String) -> bool: return _recipe_cost(a) < _recipe_cost(b))
	var results2: Array = []
	for rid: String in ranked:
		var r: Dictionary = _pursue_recipe(rid, 1, shield, depth + 1)
		if str(r.state) == ACT:
			return r
		results2.append(r)
	return _combine(results2)


func _recipe_cost(rid: String) -> float:
	var recipe: Dictionary = Database.recipes[rid]
	var total := float(recipe.seconds) / 60.0
	for item: String in recipe.get("inputs", {}):
		total += float(maxi(price(item), 1)) * float(recipe.inputs[item])
	return total


func _pursue_sold(remaining: int, shield: bool, depth: int) -> Dictionary:
	if not market_open():
		return pursue_reqs(Database.worlds.get("farm", {}).get("places", {}).get("early_market", {}).get("requirements", {}), shield, depth + 1, "sold")
	var units := 0
	for item: String in sorted_keys(gs.inventory.counts):
		if price(item) > 0 and avail(item, shield) > 0 and (_sellable(item) or shield):
			units += avail(item, shield)
	if units > 0:
		var best := ""
		var best_price := 1 << 30
		for item: String in sorted_keys(gs.inventory.counts):
			if price(item) > 0 and avail(item, shield) > 0 and price(item) < best_price and (_sellable(item) or shield):
				best = item
				best_price = price(item)
		var qty := mini(avail(best, shield), remaining)
		if Database.items.get(best, {}).has("feed") and not shield:
			qty = mini(qty, maxi(0, avail(best, false) - FOOD_KEEP))
		if qty > 0:
			return _act(_action("sell", {"item": best, "qty": qty}, "market", "goal"))
	return pursue_item("carrot", remaining, true, depth + 1)


func _pursue_any_order(contracts_only: bool, shield: bool, depth: int, new_kind := false) -> Dictionary:
	var candidates: Array[String] = []
	for id: String in Database.progression.orders:
		var channel := str(Database.progression.orders[id].get("channel", "neighbors"))
		if contracts_only != (channel == "contracts"):
			continue
		if gs.requirement_error(Database.progression.orders[id].get("requirements", {})) != "":
			# Tipo novo de contrato ainda inacessível (ex.: banquete pede laticínio): persegue seus requisitos, menos os que dependem da própria banca seguinte.
			var needs: Array = Database.progression.orders[id].get("requirements", {}).get("owned", [])
			if not new_kind or gs.progress.stat("order:" + id) > 0 or ("stall_2" in needs and not gs.has_upgrade("stall_2")) or "stall_3" in needs:
				continue
		candidates.append(id)
	candidates.sort_custom(func(a: String, b: String) -> bool: return _order_rank(a, contracts_only) < _order_rank(b, contracts_only))
	var results: Array = []
	for id: String in candidates:
		var r := _pursue_order(id, shield, depth + 1)
		if str(r.state) == ACT:
			return r
		results.append(r)
	if results.is_empty():
		var any: Dictionary = {}
		for id: String in Database.progression.orders:
			if (str(Database.progression.orders[id].get("channel", "neighbors")) == "contracts") == contracts_only:
				any = Database.progression.orders[id]
				break
		return pursue_reqs(any.get("requirements", {}), shield, depth + 1, "orders")
	return _combine(results)


## Contratos de tipo ainda não entregue vêm primeiro (a banca pede variedade); depois o mais barato.
func _order_rank(id: String, contracts_only: bool) -> float:
	var fresh := 0.0 if not contracts_only or gs.progress.stat("order:" + id) == 0 else 1.0e9
	return fresh + _order_cost(id)


func _order_cost(id: String) -> float:
	var total := 0.0
	for item: String in Database.progression.orders[id].inputs:
		total += float(maxi(price(item), 1)) * float(Database.progression.orders[id].inputs[item])
	return total


func _pursue_any_route(shield: bool, depth: int) -> Dictionary:
	var results: Array = []
	for route: String in Database.progression.activities:
		var r := _pursue_route(route, shield, depth + 1)
		if str(r.state) == ACT:
			return r
		results.append(r)
	return _combine(results)


func _pursue_find_world(world: String) -> Dictionary:
	if world != "":
		if not gs.finds.worlds.has(world):
			return pursue_reqs(Database.finds.worlds.get(world, {}).get("requirements", {}), false, 4, "find")
		if gs.dig_error(world) == "":
			return _act(_action("dig", {"world": world}, "dig:" + world, "goal"))
		return _wait("find")
	return _pursue_find()


func _pursue_equip(shield: bool, depth: int) -> Dictionary:
	for id: String in sorted_keys(gs.progress.collection):
		if gs.equip_error(id) == "":
			return _act(_action("equip", {"id": id}, "pet", "goal"))
	if not gs.progress.collection.is_empty() or gs.progress.stat("walk_rare") > 0:
		return _block("no_overlay", "equip")
	return _pursue_walk("", true)


func _pursue_sew(shield: bool, depth: int) -> Dictionary:
	var results: Array = []
	for rid: String in Database.recipes:
		var recipe: Dictionary = Database.recipes[rid]
		if not recipe.has("output_collection") or gs.progress.collection.has(str(recipe.output_collection)):
			continue
		results.append(_pursue_recipe_sewing(rid, shield, depth))
	return _combine(results) if not results.is_empty() else _block("no_sewing")


func _pursue_recipe_sewing(rid: String, shield: bool, depth: int) -> Dictionary:
	var recipe: Dictionary = Database.recipes[rid]
	var station_id: String = recipe.station
	if not gs.has_upgrade(station_id):
		return pursue_upgrade(Database.station_upgrade(station_id), shield, depth + 1)
	var inputs: Dictionary = recipe.inputs
	var results: Array = []
	var complete := true
	_protect_all(inputs, shield)
	for item: String in inputs:
		if avail(item, shield) < int(inputs[item]):
			complete = false
			results.append(pursue_item(item, int(inputs[item]), shield, depth + 1))
	if not complete:
		return _combine(results)
	if gs.cook_error(rid) != "":
		return _wait("sewing")
	return _act(_action("cook", {"recipe": rid}, "station:" + station_id, "goal"))


func _pursue_friend(friend: String, shield: bool, depth: int) -> Dictionary:
	var ids: Array = [friend] if friend != "" else Database.friends.friends.keys()
	var results: Array = []
	for id: String in ids:
		if not gs.friend_unlocked(id):
			results.append(pursue_reqs(gs.friend_def(id).get("requirements", {}), shield, depth + 1, "friend"))
			continue
		var likes := str(gs.friend_def(id).likes)
		if avail(likes, shield) < 1:
			results.append(pursue_item(likes, 1, shield, depth + 1))
			continue
		var error: String = gs.give_friend_error(id)
		if error == "":
			return _act(_action("give_friend", {"id": id}, "friends", "goal"))
		results.append(_wait("window"))
	return _combine(results)


func _pursue_trick(shield: bool, depth: int) -> Dictionary:
	for id: String in Database.progression.tricks:
		if bool(gs.progress.tricks.get(id, false)):
			continue
		var error: String = gs.learn_trick_error(id)
		if error == "":
			return _act(_action("learn_trick", {"id": id}, "tricks", "goal"))
		if gs.walking() or gs.dog.sleeping:
			return _wait("walk")
		return pursue_reqs(Database.progression.tricks[id].get("requirements", {}), shield, depth + 1, "trick")
	return _done()


# --- Crescimento do Tiro (etapa 11) ---------------------------------------------------------
# Mesmas ações do jogador: dar a refeição da fase, banho com xampu, entregar o item-chave, passear,
# cuidar dos pilares quando a recarga deixa e, por fim, apertar Crescer. Nada de dev_*.

## Meta "o Tiro chega à fase X": cumpre os requisitos da próxima fase e aperta Crescer.
func pursue_growth(phase: String, shield: bool, depth: int, qid: String) -> Dictionary:
	if depth > MAX_DEPTH:
		return _block("depth", qid)
	var target: int = gs.growth.phase_index(phase)
	if target < 0 or gs.growth.phase_index() >= target:
		return _done()
	if gs.grow_error() == "":
		return _act(_action("grow", {}, "pet", "goal"))
	var results: Array = []
	for row: Dictionary in gs.growth_info().requirements:
		if not row.done:
			results.append(_pursue_growth_req(row, shield, depth + 1, qid))
	return _combine(results)


func _pursue_growth_req(row: Dictionary, shield: bool, depth: int, qid: String) -> Dictionary:
	match str(row.type):
		"owned":
			return pursue_upgrade(str(row.upgrade), shield, depth + 1)
		"quest":
			return pursue_quest(str(row.quest), shield, depth + 1)
		"project":
			return pursue_project(str(row.project), shield, depth + 1, qid)
		"collection":
			return _pursue_collection(str(row.collection), shield, depth + 1)
		"deliver":
			var item := str(row.item)
			if gs.deliver_growth_error(item) == "":
				return _act(_action("deliver_growth", {"item": item}, "pet", "goal"))
			return pursue_item(item, int(row.need) - int(row.have), shield, depth + 1)
		"feed":
			return _pursue_growth_feed(str(row.item), int(row.need) - int(row.have), shield, depth + 1)
		"stat":
			return pursue_stat(str(row.counter), int(row.need) - int(row.have), shield, depth + 1, qid)
		"pillars":
			return _pursue_pillars(row.levels, shield, depth + 1)
	return _block("growth:" + str(row.type), qid)


func _pursue_collection(collection: String, shield: bool, depth: int) -> Dictionary:
	var results: Array = []
	for rid: String in Database.recipes:
		if str(Database.recipes[rid].get("output_collection", "")) == collection:
			results.append(_pursue_recipe_sewing(rid, shield, depth + 1))
	return _combine(results) if not results.is_empty() else _block("no_sewing:" + collection)


## Refeição pedida pela fase ("any" = qualquer comida): dá a que tem; senão faz a comida.
func _pursue_growth_feed(item: String, remaining: int, shield: bool, depth: int) -> Dictionary:
	if gs.walking():
		return _wait("walk")
	if item == "any":
		return _pursue_feed(shield, depth)
	if item == "favorite":
		item = str(gs.call("favorite_food"))
	if have(item) > 0:
		return _act(_action("feed", {"item": item}, "pet", "goal"))
	return pursue_item(item, maxi(1, remaining), shield, depth + 1)


## Banho com xampu de ervas: só quando o Tiro está mesmo sujo (vale pela pelagem e conta o banho).
func _pursue_shampoo_bath(shield: bool, depth: int) -> Dictionary:
	if gs.walking():
		return _wait("walk")
	if gs.dog.sleeping:
		return _wait("sleep")
	if have("herb_shampoo") < 1:
		return pursue_item("herb_shampoo", 1, shield, depth + 1)
	if gs.dog.get_need("hygiene", t()) >= 92.0:
		return _wait("hygiene")
	return _act(_action("bathe", {"shampoo": true}, "pet", "goal"))


## Pilares que ainda faltam: cada gesto no momento em que a recarga e a necessidade dão pontos.
func _pursue_pillars(levels: Dictionary, _shield: bool, _depth: int) -> Dictionary:
	var lacking: Array[String] = []
	for id: String in levels:
		if gs.growth.level(id) < int(levels[id]):
			lacking.append(id)
	if lacking.is_empty():
		return _done()
	if gs.walking():
		return _wait("walk")
	if gs.dog.sleeping:
		return _wait("sleep")
	var now := t()
	if "coat" in lacking and float(gs.growth.cooldowns.get("bath", 0.0)) <= now and gs.dog.get_need("hygiene", now) < 90.0:
		return _act(_action("bathe", {"shampoo": have("herb_shampoo") > 0}, "pet", "goal"))
	if "body" in lacking:
		var food := _growth_food()
		if food != "":
			return _act(_action("feed", {"item": food}, "pet", "goal"))
	if ("smart" in lacking or "brave" in lacking) and float(gs.growth.cooldowns.get("play", 0.0)) <= now \
			and gs.dog.get_need("energy", now) >= 20.0 and gs.dog.get_need("happiness", now) < 90.0:
		return _act(_action("play", {}, "pet", "goal"))
	if "brave" in lacking and gs.progress.cooldown_left("affection:pet", now) <= 0.0:
		return _act(_action("pet", {}, "pet", "goal"))
	return _wait("pillars")


## Comida da fase que mais cresce o corpo e que a meta reservada não protege.
func _growth_food() -> String:
	var best := ""
	var best_body := 0.0
	for item: String in sorted_keys(gs.inventory.counts):
		var data: Dictionary = Database.items.get(item, {}).get("growth", {})
		if data.is_empty() or avail(item, false) <= 0 or not gs.growth.phase in data.get("phases", []):
			continue
		var body := float(data.get("pillars", {}).get("body", 0))
		if body > best_body:
			best = item
			best_body = body
	return best
