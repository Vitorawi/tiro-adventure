extends RefCounted
## Motor da simulação de economia (etapa 01 do plano docs/plans/economia).
##
## Usa o GameState REAL com relógio injetável (economy_clock.gd), os métodos públicos, os requisitos
## e o to_dict/from_dict reais. Nunca força ready_at, owned, level nem saldo, e o limite de
## armazenamento fica LIGADO. Entre sessões só o relógio anda; o jogador simulado não age.
##
## Contrato de tempo (04_SIMULACAO_E_ACEITE.md, seção B): cada ação custa 3 s de toque, mais 2 s se
## trocou de painel/mundo; um arrasto (plantar, regar, colher vários) custa 3 s no primeiro alvo e
## 1 s em cada alvo seguinte. O relógio anda ANTES da ação, então o timer nasce no fim do gesto.

const ClockScript := preload("res://tests/helpers/economy_clock.gd")

const TOUCH_SECONDS := 3.0
const NAV_SECONDS := 2.0
const DRAG_SECONDS := 1.0
const DAY := 86400.0
const CR := "\r"
const LF := "\n"
## Ações que o jogador simulado pode pedir. Qualquer outra (inclusive dev_*) é violação de guarda.
const ALLOWED: Array[String] = [
	"claim_quest", "claim_routine", "claim_daily_gift", "talk", "open_screen", "feed", "bathe", "play", "pet",
	"sleep", "emergency_food", "plant_many", "water_many", "harvest_many", "cook", "collect_station",
	"start_gathering", "collect_gathering", "start_walk", "collect_walk", "dig", "give_friend",
	"collect_friend_visit", "fulfill_wish", "perform_trick", "learn_trick", "equip", "sell", "fulfill_order",
	"buy_upgrade", "buy_plot", "buy_animal", "start_activity", "collect_activity", "open_treasure",
	"start_project", "contribute_project", "use_project", "grow", "deliver_growth",
]

const PROFILES := {
	"reference": {
		"agenda": "reference", "lines": ["main", "bloblo", "nina", "merchant", "guide"], "reserve_story": true, "water": true,
		"phases": ["ph_claim", "ph_care_urgent", "ph_wishes", "ph_wish_goals", "ph_collect", "ph_water", "ph_focus", "ph_others", "ph_upgrade_goals", "ph_orders", "ph_produce", "ph_spend", "ph_sell", "ph_closing", "ph_care_optional"],
	},
	"light": {
		"agenda": "light", "lines": ["main", "bloblo", "nina", "merchant", "guide"], "reserve_story": true, "water": true,
		"phases": ["ph_claim", "ph_care_urgent", "ph_wishes", "ph_wish_goals", "ph_collect", "ph_water", "ph_focus", "ph_upgrade_goals", "ph_produce", "ph_spend", "ph_sell", "ph_closing"],
	},
	"active": {
		"agenda": "active", "lines": ["main", "bloblo", "nina", "merchant", "guide"], "reserve_story": true, "water": true,
		"phases": ["ph_claim", "ph_care_urgent", "ph_wishes", "ph_wish_goals", "ph_collect", "ph_water", "ph_focus", "ph_others", "ph_upgrade_goals", "ph_orders", "ph_produce", "ph_spend", "ph_sell", "ph_closing", "ph_care_optional"],
	},
	"affective": {
		"agenda": "reference", "lines": ["nina", "main", "bloblo", "merchant", "guide"], "reserve_story": true, "water": true,
		"phases": ["ph_claim", "ph_care_urgent", "ph_wishes", "ph_wish_goals", "ph_collect", "ph_bond_extras", "ph_care_optional", "ph_water", "ph_focus", "ph_others", "ph_upgrade_goals", "ph_orders", "ph_produce", "ph_spend", "ph_sell", "ph_closing"],
	},
	"commercial": {
		"agenda": "reference", "lines": ["merchant", "main", "bloblo", "nina", "guide"], "reserve_story": false, "water": true,
		"phases": ["ph_claim", "ph_care_urgent", "ph_collect", "ph_water", "ph_orders", "ph_spend", "ph_focus", "ph_others", "ph_upgrade_goals", "ph_produce", "ph_sell", "ph_wishes", "ph_wish_goals", "ph_closing", "ph_care_optional"],
	},
	"recovery": {
		"agenda": "reference", "lines": ["main", "bloblo", "nina", "merchant", "guide"], "reserve_story": true, "water": true,
		"phases": ["ph_claim", "ph_recovery_blunders", "ph_care_urgent", "ph_wishes", "ph_wish_goals", "ph_collect", "ph_water", "ph_focus", "ph_others", "ph_upgrade_goals", "ph_orders", "ph_produce", "ph_spend", "ph_sell", "ph_closing", "ph_care_optional"],
	},
}

var root: Node
var gs
var bot
var params: Dictionary = {}
var profile_name: String = "reference"
var profile: Dictionary = {}
var seed_value: int = 1
var out_dir: String = ""

var t0: float = 0.0
var ctx: String = ""
var action_index: int = 0
var session_index: int = 0
var active_seconds: float = 0.0
var wait_seconds: float = 0.0
var nav_seconds: float = 0.0
var session_start_time: float = 0.0
var session_budget: float = 0.0
var last_session_end: float = 0.0
var ledger: FileAccess = null
var violations: Array[Dictionary] = []
var failures: Array[Dictionary] = []
var milestones: Dictionary = {}
var daily: Array[Dictionary] = []
var coin_flow: Dictionary = {}
var item_flow: Dictionary = {}
var waits_by_reason: Dictionary = {}
var blocks_seen: Dictionary = {}
var action_counts: Dictionary = {}
var actions_by_why: Dictionary = {}
var pending_at_close: Array[Dictionary] = []
var quest_times: Dictionary = {}
## Obras comunitárias (etapa 21): uma linha por começo/entrega/conclusão, com o momento e o saldo.
var project_log: Array[Dictionary] = []
## Dia simulado (fração) em que cada fase do Tiro começou e moedas ao fechar cada capítulo (etapa 17 do plano Tiro).
var growth_days: Dictionary = {}
var chapter_coins: Dictionary = {}
var session_log: Array[Dictionary] = []
var status: String = "running"
var stall_reason: String = ""
var last_progress_day: int = 0
var last_progress_active: float = 0.0
var _digest_after: String = ""
var _legit_plots: Dictionary = {}
var _legit_queue: Dictionary = {}
var _legit_nature: Dictionary = {}
var _legit_walk: float = -1.0
var _last_kind: String = ""
var _recent: Array[String] = []
var _repeat: int = 0
var _first_session_wait: float = 0.0
var _next_day_mark: float = 0.0
var _rng := RandomNumberGenerator.new()
var _removed_saver: bool = false
var perf: Dictionary = {}
var final_trace: Array[String] = []
var final_debug: Dictionary = {}
## Verdadeiro só enquanto o jogador está com o app aberto: fora disso nenhuma ação é permitida.
var in_session: bool = false
var unused_no_action: float = 0.0
var budget_left_with_actions: float = 0.0


func _init(tree_root: Node, options: Dictionary) -> void:
	root = tree_root
	params = options
	profile_name = str(options.get("profile", "reference"))
	profile = PROFILES[profile_name].duplicate(true)
	if str(options.get("until", "days")) == "projects":
		# Só nas execuções "até as obras": o robô também começa e entrega obras (fora disso a campanha não muda).
		var phases: Array = profile.phases
		var at := phases.find("ph_upgrade_goals")
		phases.insert(at if at >= 0 else phases.find("ph_produce"), "ph_projects")
	seed_value = int(options.get("seed", 1))
	out_dir = str(options.get("out", ""))
	_rng.seed = seed_value * 7919 + 13


# --- Preparação --------------------------------------------------------------------------------

func setup() -> void:
	var saver: Node = root.get_node_or_null("SaveManager")
	if saver != null:
		root.remove_child(saver)
		saver.free()
		_removed_saver = true
	gs = root.get_node("GameState")
	gs.set_script(ClockScript)
	# Dia 0 = segunda-feira 19/10/2026; início às 12h locais mais um desvio de semente.
	var day0: float = Time.get_unix_time_from_datetime_string("2026-10-19T00:00:00") - float(gs.zone_bias)
	var offset: float = float(posmod((seed_value - 1) * 977, 1800))
	t0 = day0 + 12.0 * 3600.0 + offset
	gs.set_clock(t0)
	gs.reset()
	_apply_scenario()
	var bot_script: GDScript = load(str(params.get("bot_script", "res://tests/helpers/economy_bot.gd")))
	bot = bot_script.new(gs, profile, seed_value * 104729 + 7)
	_next_day_mark = day0 + DAY
	_snapshot_timers_initial()
	_digest_after = digest()
	if params.get("ledger", "compact") != "off" and out_dir != "":
		DirAccess.make_dir_recursive_absolute(out_dir)
		ledger = FileAccess.open(out_dir.path_join("ledger.jsonl"), FileAccess.WRITE)
	check_static_guards("setup")
	_row({"ev": "start", "profile": profile_name, "seed": seed_value, "t0": t0, "params": params.get("days", 0), "rare": params.get("rare", "normal")})


## Cenários declarados (não são atalhos): pior caso de raro usa chance 0 e mantém a garantia.
func _apply_scenario() -> void:
	if str(params.get("rare", "normal")) == "worst":
		for id: String in Database.walks.get("walks", {}):
			var rare: Dictionary = Database.walks.walks[id].get("loot", {}).get("rare", {})
			if not rare.is_empty():
				rare["chance"] = 0.0
		if Database.walks.has("legendary"):
			Database.walks.legendary["chance"] = 0.0


# --- Guardas ------------------------------------------------------------------------------------

func violate(kind: String, detail: String) -> void:
	violations.append({"kind": kind, "detail": detail, "action": action_index, "t": rel(gs.now())})
	push_warning("GUARDA [%s] %s" % [kind, detail])


func check_static_guards(where: String) -> void:
	if bool(gs.unlimited_storage):
		violate("unlimited_storage", "unlimited_storage ligado (%s)" % where)
	if not (gs.get_script() as Script).resource_path.ends_with("economy_clock.gd"):
		violate("relogio", "GameState sem o relógio de simulação (%s)" % where)


func digest() -> String:
	var stations_state: Dictionary = {}
	for id: String in gs.stations:
		stations_state[id] = gs.stations[id].queue
	var data := {
		"c": gs.coins, "x": gs.xp, "l": gs.level, "i": gs.inventory.counts, "o": gs.progress.owned,
		"p": gs.plots, "s": stations_state, "a": gs.animals, "g": gs.progress.gathering, "ac": gs.progress.activity,
		"w": gs.walk_state.current, "q": gs.progress.claimed_quests, "u": gs.unlocked_plots, "st": gs.progress.stats,
		"sk": gs.progress.skills, "cd": gs.progress.cooldowns, "col": gs.progress.collection,
		"d": [gs.dog.needs, gs.dog.updated_at, gs.dog.affection, gs.dog.sleeping],
	}
	return JSON.stringify(data, "", true).md5_text()


func _snapshot_timers_initial() -> void:
	_legit_plots.clear()
	_legit_queue.clear()
	_legit_nature.clear()
	_legit_walk = -1.0
	for i in gs.plots.size():
		if str(gs.plots[i].get("crop", "")) != "":
			_legit_plots[i] = float(gs.plots[i].ready_at)
	for id: String in gs.stations:
		for entry: Dictionary in gs.stations[id].queue:
			_legit_queue["%s|%s|%s" % [id, entry.recipe, entry.ready_at]] = true
	for site: String in gs.progress.gathering:
		for index in gs.progress.gathering[site].size():
			var entry: Dictionary = gs.progress.gathering[site][index]
			if not entry.is_empty():
				_legit_nature["%s|%d" % [site, index]] = float(entry.ready_at)
	if gs.walking():
		_legit_walk = float(gs.walk_state.current.ready_at)


## ready_at só pode ter nascido de plantar/regar/cozinhar/coletar/passear pelas regras reais.
func check_timers() -> void:
	for i in gs.plots.size():
		var crop: String = str(gs.plots[i].get("crop", ""))
		if crop == "":
			_legit_plots.erase(i)
			continue
		if not _legit_plots.has(i) or absf(float(_legit_plots[i]) - float(gs.plots[i].ready_at)) > 0.001:
			violate("ready_at_forcado", "canteiro %d (%s) com ready_at fora das regras" % [i, crop])
			_legit_plots[i] = float(gs.plots[i].ready_at)
	for id: String in gs.stations:
		for entry: Dictionary in gs.stations[id].queue:
			var key := "%s|%s|%s" % [id, entry.recipe, entry.ready_at]
			if not _legit_queue.has(key):
				violate("ready_at_forcado", "fila %s: %s com ready_at fora das regras" % [id, entry.recipe])
				_legit_queue[key] = true
	for site: String in gs.progress.gathering:
		for index in gs.progress.gathering[site].size():
			var entry: Dictionary = gs.progress.gathering[site][index]
			if entry.is_empty():
				_legit_nature.erase("%s|%d" % [site, index])
				continue
			var key := "%s|%d" % [site, index]
			if not _legit_nature.has(key) or absf(float(_legit_nature[key]) - float(entry.ready_at)) > 0.001:
				violate("ready_at_forcado", "coleta %s[%d] com ready_at fora das regras" % [site, index])
				_legit_nature[key] = float(entry.ready_at)
	if gs.walking():
		if _legit_walk < 0.0 or absf(_legit_walk - float(gs.walk_state.current.ready_at)) > 0.001:
			violate("ready_at_forcado", "passeio com ready_at fora das regras")
			_legit_walk = float(gs.walk_state.current.ready_at)
	else:
		_legit_walk = -1.0


# --- Relógio e agenda ---------------------------------------------------------------------------

func rel(time_value: float) -> float:
	return time_value - t0


func local_hour(time_value: float) -> float:
	return fposmod(time_value + float(gs.zone_bias), DAY) / 3600.0


## Sessões: [{start, budget}] em Unix. A semente muda o início e o desvio de cada sessão.
func build_agenda(days: int) -> Array[Dictionary]:
	var sessions: Array[Dictionary] = []
	var day0: float = t0 - fposmod(t0 + float(gs.zone_bias), DAY)
	sessions.append({"start": t0, "budget": 20.0 * 60.0})
	var kind: String = str(profile.agenda)
	for d in range(0, days + 1):
		var base: float = day0 + float(d) * DAY
		var slots: Array = []
		match kind:
			"light":
				slots = [[19.0, 10.0 * 60.0]]
			"active":
				slots = [[8.5, 2.0 * 3600.0], [13.5, 2.0 * 3600.0], [19.0, 2.0 * 3600.0]]
			_:
				slots = [[8.0, 10.0 * 60.0], [14.0, 10.0 * 60.0], [20.0, 10.0 * 60.0]]
		for slot: Array in slots:
			var jitter: float = _rng.randf_range(-15.0, 15.0) * 60.0
			var start: float = base + float(slot[0]) * 3600.0 + jitter
			var last: Dictionary = sessions[sessions.size() - 1]
			if start < float(last.start) + float(last.budget) + 600.0:
				continue
			sessions.append({"start": start, "budget": float(slot[1])})
	return sessions


# --- Execução ----------------------------------------------------------------------------------

func run() -> Dictionary:
	setup()
	var days: int = int(params.get("days", 30))
	var agenda := build_agenda(days)
	var campaign_target: bool = str(params.get("until", "days")) == "campaign"
	var projects_target: bool = str(params.get("until", "days")) == "projects"
	for session: Dictionary in agenda:
		if rel(float(session.start)) > float(days) * DAY:
			break
		_session(session)
		if str(params.get("reload", "none")) == "session":
			reload_through_json()
		if status != "running":
			break
		if campaign_target and gs.progress.claimed_quests.size() >= Database.quests.size():
			status = "complete"
			break
		if projects_target and _projects_all_done():
			status = "complete"
			break
		var days_now := int(rel(gs.now()) / DAY)
		var stall_limit: int = int(params.get("stall_days", 21))
		var stall_active: float = float(params.get("stall_active_min", 600)) * 60.0
		if days_now - last_progress_day >= stall_limit or active_seconds - last_progress_active >= stall_active:
			status = "stalled"
			stall_reason = _stall_text()
			break
		if action_index >= int(params.get("max_actions", 400000)):
			status = "max_actions"
			break
	if status == "running":
		status = "horizon"
	if int(params.get("trace_end", 0)) == 1:
		# Depuração: refaz o último plano com rastreio de buscas (não executa nada).
		bot.trace_on = true
		bot.trace.clear()
		bot.plan(600.0, 36000.0)
		bot.trace_on = false
		final_trace = bot.trace.duplicate()
		var queues := {}
		for id: String in gs.stations:
			if not gs.stations[id].queue.is_empty():
				queues[id] = gs.stations[id].queue.map(func(e: Dictionary) -> String: return "%s@%d" % [e.recipe, int(float(e.ready_at) - gs.now())])
		final_debug = {"inventory": gs.inventory.counts.duplicate(), "protect": bot.protect.duplicate(), "protect_coins": bot.protect_coins, "depots": depot_state(), "queues": queues, "coins": gs.coins, "avoid": bot.avoid.keys().slice(0, 20), "plots": gs.plots.map(func(p: Dictionary) -> String: return str(p.get("crop", "")))}
	finish()
	return summary()


func _session(session: Dictionary) -> void:
	var start: float = float(session.start)
	if start > gs.now():
		gs.set_clock(start)
	if session_index > 0:
		gs.update_friend_visits(last_session_end)
	bg_tick()
	session_start_time = gs.now()
	session_budget = float(session.budget)
	session_index += 1
	var used_active := 0.0
	var first_wait := 0.0
	var spent := 0.0
	check_static_guards("session")
	_digest_after = digest()
	in_session = true
	var closed_reason := "budget"
	while true:
		var t_a := Time.get_ticks_usec()
		bg_tick()
		var t_b := Time.get_ticks_usec()
		check_between()
		_perf("bg", t_b - t_a)
		_perf("digest", Time.get_ticks_usec() - t_b)
		var left: float = session_budget - spent
		if left <= 0.5:
			closed_reason = "budget"
			break
		var next_start := _next_session_gap(start + session_budget)
		var before_plan := _digest_after
		var t_p := Time.get_ticks_usec()
		var plan: Dictionary = bot.plan(left, next_start)
		_perf("plan", Time.get_ticks_usec() - t_p)
		var after_plan := digest()
		if after_plan != before_plan:
			violate("planejador_alterou_estado", "plan() mudou o estado")
			_digest_after = after_plan
		if not plan.is_empty():
			var action: Dictionary = plan.action
			var cost := action_cost(action)
			if cost > left:
				closed_reason = "budget"
				break
			spent += cost
			active_seconds += cost
			used_active += cost
			var t_x := Time.get_ticks_usec()
			perform(action, cost)
			_perf("perform", Time.get_ticks_usec() - t_x)
			if status != "running":
				break
			continue
		# Nada a fazer agora: espera o próximo evento do jogo, se couber na sessão.
		var event := next_event()
		if event.is_empty() or float(event.at) - gs.now() > left:
			closed_reason = "idle" if event.is_empty() else "next_event_after_close"
			break
		var wait_s: float = maxf(0.5, float(event.at) - gs.now())
		gs.advance_clock(wait_s)
		spent += wait_s
		wait_seconds += wait_s
		waits_by_reason[event.label] = float(waits_by_reason.get(event.label, 0.0)) + wait_s
		if session_index == 1:
			first_wait += wait_s
		_row({"ev": "wait", "reason": event.label, "seconds": snappedf(wait_s, 0.1)})
	if session_index == 1:
		_first_session_wait = first_wait
	in_session = false
	last_session_end = gs.now()
	_record_blocks()
	_collect_pending_at_close()
	# Ao fechar: o que o próprio jogo ainda oferecia (separa "ausência voluntária" de "nada a fazer").
	var legal: Array = []
	for item: Dictionary in gs.available_actions():
		legal.append(str(item.kind))
	if closed_reason == "idle" or closed_reason == "next_event_after_close":
		unused_no_action += maxf(0.0, session_budget - spent)
	else:
		budget_left_with_actions += maxf(0.0, session_budget - spent)
	_row({"ev": "session_end", "reason": closed_reason, "spent": snappedf(spent, 1.0), "budget": session_budget, "legal": legal.slice(0, 8), "legal_count": legal.size()})
	session_log.append({"n": session_index, "start": rel(start), "budget": session_budget, "spent": snappedf(spent, 1.0), "active": snappedf(used_active, 1.0), "reason": closed_reason, "legal_at_close": legal.size(), "coins": gs.coins, "claimed": gs.progress.claimed_quests.size(), "focus": bot.focus_id, "focus_state": str(bot.focus_result.get("state", "")), "focus_why": str(bot.focus_result.get("why", ""))})
	_mark_days()


## Nada muda o estado entre duas ações (só o relógio e os sorteios por tempo do próprio jogo).
func check_between() -> void:
	var current := digest()
	if current != _digest_after:
		violate("mutacao_fora_de_acao", "estado mudou entre ações (sessão %d)" % session_index)
		_digest_after = current
	check_timers()


func _perf(key: String, usec: int) -> void:
	perf[key] = int(perf.get(key, 0)) + usec


func _next_session_gap(session_end: float) -> float:
	## O jogador conhece a própria agenda: tempo até a próxima abertura do app.
	var kind: String = str(profile.agenda)
	var local := fposmod(session_end + float(gs.zone_bias), DAY) / 3600.0
	var hours: Array = [8.0, 14.0, 20.0]
	if kind == "light":
		hours = [19.0]
	elif kind == "active":
		hours = [8.5, 13.5, 19.0]
	for h: float in hours:
		if h > local:
			return (h - local) * 3600.0
	return (24.0 - local + float(hours[0])) * 3600.0


func bg_tick() -> void:
	## Equivale ao Timer de 1 s do GameState (_ready): desejos, volta do passeio, janela de amigos e faro.
	var changed_wishes: bool = gs.update_wishes()
	# A volta do passeio é uma regra do próprio jogo por tempo (como os desejos): paga moedas/vínculo uma vez e
	# deixa a bagagem esperando; não é mutação fora de ação, então a referência do guarda acompanha.
	if gs.return_due_walk():
		_digest_after = digest()
		_row({"ev": "walk_return", "baggage": gs.walk_state.baggage_count()})
	if gs.sync_friend_window() or gs.update_finds() or changed_wishes:
		gs.call("_changed")


func action_cost(action: Dictionary) -> float:
	var cost := TOUCH_SECONDS
	var targets: int = 1
	var args: Dictionary = action.args
	if args.has("plots"):
		targets = maxi(1, (args.plots as Array).size())
	cost += float(targets - 1) * DRAG_SECONDS
	if str(action.ctx) != ctx:
		cost += NAV_SECONDS
	return cost


func perform(action: Dictionary, cost: float) -> void:
	var kind: String = str(action.kind)
	if not kind in ALLOWED:
		violate("acao_nao_permitida", kind)
		status = "guard"
		return
	if not in_session:
		violate("acao_fora_da_sessao", kind)
		status = "guard"
		return
	if str(action.ctx) != ctx:
		nav_seconds += NAV_SECONDS
	gs.advance_clock(cost)
	bg_tick()
	var before := snap()
	var t_action: float = gs.now()
	var outcome: Dictionary = execute(action)
	var after := snap()
	var ok: bool = str(outcome.get("err", "")) == ""
	if ok:
		ctx = str(action.ctx)
	_account(action, before, after, outcome)
	_update_legit(action, outcome, t_action)
	_digest_after = digest()
	action_index += 1
	action_counts[kind] = int(action_counts.get(kind, 0)) + 1
	actions_by_why[action.why] = int(actions_by_why.get(action.why, 0)) + 1
	_detect_progress(kind, ok)
	_log_project(action, ok)
	_track_repeat(action, ok)
	_row({"ev": "act", "kind": kind, "why": action.why, "goal": action.goal, "args": action.args, "cost": cost, "ok": ok, "err": outcome.get("err", ""), "before": before.coins, "after": after.coins, "di": _item_delta(before, after), "dep": depot_state(), "q": queue_state(), "nav": str(action.ctx)})
	if not ok:
		failures.append({"t": rel(gs.now()), "kind": kind, "err": outcome.err, "args": action.args})
		bot.remember_failure(_failure_key(action), 120.0)
		bot.remember_failure(bot.action_key(action), 120.0)
		_row_available()
	if bool(action.args.get("blunder", false)):
		bot.memory["blunder_" + ("sofa" if kind == "buy_upgrade" else "dump")] = true
	_milestones()


func _failure_key(action: Dictionary) -> String:
	var args: Dictionary = action.args
	match str(action.kind):
		"plant_many":
			return "plant"
		"start_gathering":
			return "gather"
		"cook":
			return "cook" + str(args.recipe)
		"dig":
			return "dig" + str(args.world)
		"buy_upgrade":
			return "buy" + str(args.id)
		"buy_plot":
			return "buyplot"
		"buy_animal":
			return "animal" + str(args.id)
		"start_walk":
			return "walk" + str(args.id)
		"fulfill_wish":
			return "wish%d" % int(args.slot)
		"give_friend":
			return "friend" + str(args.id)
	return str(action.kind) + JSON.stringify(args)


func _track_repeat(action: Dictionary, ok: bool) -> void:
	var key := str(action.kind) + JSON.stringify(action.args)
	# Vai-e-volta entre duas ações (A, B, A, B...) também é laço de política.
	_recent.append(key)
	if _recent.size() > 8:
		_recent.pop_front()
	if _recent.size() == 8 and _recent[0] == _recent[2] and _recent[2] == _recent[4] and _recent[4] == _recent[6] and _recent[1] == _recent[3] and _recent[3] == _recent[5] and _recent[5] == _recent[7] and _recent[0] != _recent[1]:
		bot.remember_failure(_failure_key(action), 900.0)
		bot.remember_failure(bot.action_key(action), 900.0)
		_recent.clear()
		_row({"ev": "policy_loop", "key": "alternating:" + key})
		blocks_seen["politica:alternating:" + str(action.kind)] = int(blocks_seen.get("politica:alternating:" + str(action.kind), 0)) + 1
	if ok and key != _last_kind:
		_repeat = 0
	elif key == _last_kind:
		_repeat += 1
	_last_kind = key
	if _repeat >= 8:
		bot.remember_failure(_failure_key(action), 600.0)
		bot.remember_failure(bot.action_key(action), 600.0)
		_repeat = 0
		_row({"ev": "policy_loop", "key": key})
		blocks_seen["policy_loop:" + str(action.kind)] = int(blocks_seen.get("policy_loop:" + str(action.kind), 0)) + 1


func execute(action: Dictionary) -> Dictionary:
	var args: Dictionary = action.args
	var out := {"err": "", "extra": {}}
	match str(action.kind):
		"claim_quest":
			var quest: Dictionary = Database.quests[str(args.id)]
			out.extra = {"rewards": quest.rewards.duplicate(true) if not quest.has("shared_with") else {}, "deliveries": gs.call("_quest_deliveries", str(args.id))}
			out.err = gs.claim_quest(str(args.id))
		"claim_routine":
			var data: Dictionary = gs.routine_data(str(args.kind), str(args.id))
			out.extra = {"rewards": data.get("rewards", {}).duplicate(true)}
			out.err = gs.claim_routine(str(args.kind), str(args.id))
		"claim_daily_gift":
			out.extra = {"rewards": gs.daily_gift_rewards()}
			out.err = gs.claim_daily_gift()
		"talk":
			gs.talk_to(str(args.npc))
		"open_screen":
			gs.note_screen_opened(str(args.screen))
		"feed":
			out.extra = {"consumed": {str(args.item): 1}}
			if not gs.feed(str(args.item)):
				out.err = "Não aceitou a comida"
		"bathe":
			var shampoo := bool(args.get("shampoo", false))
			out.extra = {"consumed": {"herb_shampoo": 1} if shampoo else {}}
			gs.bathe(shampoo)
		"grow":
			out.err = gs.grow()
		"deliver_growth":
			var key_item := str(args.item)
			var needed := 0
			for row: Dictionary in gs.growth_info().requirements:
				if str(row.type) == "deliver" and str(row.item) == key_item:
					needed = mini(gs.inventory.count(key_item), int(row.need) - int(row.have))
			out.extra = {"consumed": {key_item: needed}}
			out.err = gs.deliver_growth(key_item)
		"play":
			if not gs.play():
				out.err = "Não pôde brincar"
		"pet":
			gs.pet()
		"sleep":
			gs.set_sleeping(bool(args.value))
		"emergency_food":
			out.extra = {"gained": {"dog_food": int(Database.progression.settings.emergency_food_amount)}}
			out.err = gs.emergency_food()
		"plant_many":
			var planted: Array[int] = []
			for i: int in args.plots:
				var e: String = gs.plant(i, str(args.crop))
				if e == "":
					planted.append(i)
				elif out.err == "":
					out.err = e
			out.extra = {"planted": planted, "crop": str(args.crop)}
			if not planted.is_empty():
				out.err = ""
		"water_many":
			var watered: Array = []
			var before_ready: Dictionary = {}
			for i: int in args.plots:
				before_ready[i] = float(gs.plot(i).ready_at)
				var e2: String = gs.water(i)
				if e2 == "":
					watered.append(i)
				elif out.err == "":
					out.err = e2
			out.extra = {"watered": watered, "before_ready": before_ready}
			if not watered.is_empty():
				out.err = ""
		"harvest_many":
			var gained: Dictionary = {}
			var coins_gained := 0
			for i: int in args.plots:
				var crop_id: String = str(gs.plot(i).get("crop", ""))
				var got: Dictionary = gs.harvest(i)
				if got.is_empty():
					if out.err == "":
						out.err = "Colheita recusada"
				else:
					coins_gained += int(Database.crops[crop_id].get("coins", 0))
					for id: String in got:
						gained[id] = int(gained.get(id, 0)) + int(got[id])
			out.extra = {"gained": gained, "coins": coins_gained}
			if not gained.is_empty():
				out.err = ""
		"cook":
			var rid: String = str(args.recipe)
			out.extra = {"consumed": gs.recipe_inputs(rid).duplicate(), "recipe": rid, "station": str(Database.recipes[rid].station)}
			out.err = gs.cook(rid)
		"collect_station":
			var mastery_before := _mastery_ids()
			var received: Dictionary = gs.collect(str(args.station))
			out.extra = {"gained": received, "coins": _new_mastery_coins(mastery_before)}
			if received.is_empty() and not _station_had_cosmetic(args):
				out.err = "Nada recolhido"
		"start_gathering":
			out.err = gs.start_gathering(str(args.site), int(args.index), str(args.route))
		"collect_gathering":
			var entry: Dictionary = gs.gathering_entry(str(args.site), int(args.index)).duplicate(true)
			out.extra = {"rewards": entry.get("rewards", {})}
			out.err = gs.collect_gathering(str(args.site), int(args.index))
		"start_activity":
			out.err = gs.start_activity(str(args.route))
		"collect_activity":
			var act_data: Dictionary = Database.progression.activities.get(str(gs.progress.activity.get("id", "")), {})
			out.extra = {"rewards": act_data.get("rewards", {}).duplicate(true)}
			out.err = gs.collect_activity()
		"start_walk":
			out.err = gs.start_walk(str(args.id))
		"collect_walk":
			var result: Dictionary = gs.collect_walk()
			out.extra = {"loot": true}
			if result.is_empty():
				out.err = "Passeio não recolhido"
		"dig":
			var found: Dictionary = gs.dig(str(args.world))
			out.extra = {"loot": true}
			if found.is_empty():
				out.err = "Nada cavado"
		"give_friend":
			var liked: String = str(gs.friend_def(str(args.id)).likes)
			out.extra = {"loot": true, "consumed": {liked: 1}}
			out.err = gs.give_friend(str(args.id))
		"collect_friend_visit":
			out.extra = {"loot": true}
			out.err = gs.collect_friend_visit(str(args.id))
		"open_treasure":
			out.extra = {"rewards": Database.progression.get("treasure", {}).get("rewards", {}).duplicate(true)}
			out.err = gs.open_treasure()
		"fulfill_wish":
			var slot: int = int(args.slot)
			var def: Dictionary = gs.wish_at(slot)
			var consumed: Dictionary = {}
			if str(def.get("type", "")) in ["feed", "give"]:
				consumed[str(def.item)] = 1
			out.extra = {"rewards": gs.wish_rewards(slot), "consumed": consumed}
			out.err = gs.fulfill_wish(slot)
		"perform_trick":
			out.err = gs.perform_trick(str(args.id))
		"learn_trick":
			out.err = gs.learn_trick(str(args.id))
		"equip":
			out.err = gs.equip(str(args.id))
		"sell":
			var qty: int = mini(int(args.qty), gs.inventory.count(str(args.item)))
			out.extra = {"sold": {str(args.item): qty}, "coins": qty * int(Database.items[str(args.item)].get("sell_price", 0))}
			var sale_world := str(args.get("world", "village" if gs.requirement_error(Database.worlds.village.get("requirements", {})) == "" else "farm"))
			out.err = gs.sell(str(args.item), qty, sale_world)
		"fulfill_order":
			var order: Dictionary = Database.progression.orders[str(args.id)]
			var order_rewards: Dictionary = order.rewards.duplicate(true)
			_add_customer_tiers(order_rewards, str(args.id), order)
			out.extra = {"rewards": order_rewards, "consumed": order.inputs.duplicate()}
			out.err = gs.fulfill_order(str(args.id))
		"start_project":
			out.extra = {"spend": int(Database.project(str(args.id)).get("start_coins", 0))}
			out.err = gs.start_project(str(args.id))
		"contribute_project":
			out.extra = {"delivered": {str(args.item): int(args.qty)}}
			out.err = gs.contribute_project(str(args.id), str(args.item), int(args.qty))
		"use_project":
			out.err = gs.use_project(str(args.id))
		"buy_upgrade":
			var data2: Dictionary = Database.progression.upgrades[str(args.id)]
			out.extra = {"spend": int(data2.get("cost", 0)), "consumed": data2.get("materials", {}).duplicate()}
			out.err = gs.buy_upgrade(str(args.id))
		"buy_plot":
			out.extra = {"spend": gs.plot_cost(int(args.index))}
			out.err = gs.buy_plot(int(args.index))
		"buy_animal":
			out.extra = {"spend": int(Database.animals[str(args.id)].price)}
			out.err = gs.buy_animal(str(args.id))
	return out


func _station_had_cosmetic(_args: Dictionary) -> bool:
	return false


# --- Conservação e contabilidade --------------------------------------------------------------------

func snap() -> Dictionary:
	return {
		"coins": gs.coins, "inv": gs.inventory.counts.duplicate(), "level": gs.level,
		"bond": gs.progress.claimed_bond_level, "chapter": gs.progress.chapter_index(),
		"claimed": gs.progress.claimed_quests.size(),
	}


func _item_delta(before: Dictionary, after: Dictionary) -> Dictionary:
	var delta := {}
	for id: String in after.inv:
		var d: int = int(after.inv[id]) - int(before.inv.get(id, 0))
		if d != 0:
			delta[id] = d
	for id: String in before.inv:
		if not after.inv.has(id):
			delta[id] = -int(before.inv[id])
	return delta


## Efeitos colaterais determinísticos de subir de nível/vínculo/capítulo.
func side_effects(before: Dictionary, after: Dictionary) -> Dictionary:
	var coins := 0
	var items := {}
	var parts := {"level": 0, "bond": 0, "chapter": 0}
	for lv in range(int(before.level) + 1, int(after.level) + 1):
		var reward: Dictionary = gs.level_reward(lv)
		coins += int(reward.get("coins", 0))
		parts.level = int(parts.level) + int(reward.get("coins", 0))
		for id: String in reward.get("items", {}):
			items[id] = int(items.get(id, 0)) + int(reward.items[id])
	var levels: Array = Database.progression.get("bond_levels", [])
	for reached in range(int(before.bond) + 1, int(after.bond) + 1):
		var reward2: Dictionary = levels[reached - 1].get("rewards", {}) if reached - 1 < levels.size() else {}
		coins += int(reward2.get("coins", 0))
		parts.bond = int(parts.bond) + int(reward2.get("coins", 0))
		for id: String in reward2.get("items", {}):
			items[id] = int(items.get(id, 0)) + int(reward2.items[id])
	for chapter in range(int(before.chapter), int(after.chapter)):
		var reward3: Dictionary = Database.progression.chapters[chapter - 1].get("rewards", {}) if chapter - 1 < Database.progression.chapters.size() else {}
		coins += int(reward3.get("coins", 0))
		parts.chapter = int(parts.chapter) + int(reward3.get("coins", 0))
		for id: String in reward3.get("items", {}):
			items[id] = int(items.get(id, 0)) + int(reward3.items[id])
	return {"coins": coins, "items": items, "parts": parts}


## Selos de maestria (etapa 18) já pagos: o efeito declarado de um recolhimento inclui os selos novos.
func _mastery_ids() -> Array:
	var ids: Array = []
	for id: String in gs.economy.granted:
		if id.begins_with("mastery:"):
			ids.append(id)
	return ids


func _new_mastery_coins(before: Array) -> int:
	var coins := 0
	var tiers: Array = Database.progression.get("mastery", {}).get("tiers", [])
	for id: String in gs.economy.granted:
		if id.begins_with("mastery:") and not id in before:
			coins += int(tiers[int(id.get_slice(":", 2)) - 1].rewards.get("coins", 0))
	return coins


## Patamares de confiança que esta entrega vai pagar (efeito declarado pela regra da etapa 15).
func _add_customer_tiers(rewards: Dictionary, order_id: String, order: Dictionary) -> void:
	var customer := str(order.get("customer", ""))
	if customer == "":
		return
	var seen: Dictionary = gs.progress.customer_orders(customer)
	var count := int(seen.count) + 1
	var kinds := int(seen.kinds) + (1 if gs.progress.stat("order:" + order_id) == 0 else 0)
	var tiers: Array = Database.progression.get("customer_tiers", [])
	for index in tiers.size():
		if gs.economy.granted.has("customer:%s:%d" % [customer, index + 1]):
			continue
		if count < int(tiers[index].count) or kinds < int(tiers[index].kinds):
			continue
		rewards["coins"] = int(rewards.get("coins", 0)) + int(tiers[index].rewards.get("coins", 0))
		var items: Dictionary = rewards.get("items", {}).duplicate()
		for item: String in tiers[index].rewards.get("items", {}):
			items[item] = int(items.get(item, 0)) + int(tiers[index].rewards.items[item])
		if not items.is_empty():
			rewards["items"] = items


func _expected(action: Dictionary, outcome: Dictionary) -> Dictionary:
	## {coins, items, exact}: efeito direto que a regra declara. Exato = confere até a unidade.
	var kind: String = str(action.kind)
	var extra: Dictionary = outcome.get("extra", {})
	var coins := 0
	var items: Dictionary = {}
	var exact := true
	match kind:
		"harvest_many":
			coins = int(extra.get("coins", 0))
			items = extra.get("gained", {}).duplicate()
		"cook", "feed", "bathe", "deliver_growth":
			for id: String in extra.get("consumed", {}):
				items[id] = -int(extra.consumed[id])
		"collect_station":
			coins = int(extra.get("coins", 0))
			items = extra.get("gained", {}).duplicate()
		"emergency_food":
			items = extra.get("gained", {}).duplicate()
		"sell":
			coins = int(extra.get("coins", 0))
			for id: String in extra.get("sold", {}):
				items[id] = -int(extra.sold[id])
		"fulfill_order", "claim_routine", "claim_daily_gift", "claim_quest", "fulfill_wish", "collect_gathering", "collect_activity", "open_treasure":
			var rewards: Dictionary = extra.get("rewards", {})
			coins = int(rewards.get("coins", 0))
			for id: String in rewards.get("items", {}):
				items[id] = int(items.get(id, 0)) + int(rewards.items[id])
			for id: String in extra.get("consumed", {}):
				items[id] = int(items.get(id, 0)) - int(extra.consumed[id])
			for id: String in extra.get("deliveries", {}):
				items[id] = int(items.get(id, 0)) - int(extra.deliveries[id])
		"buy_upgrade", "buy_plot", "buy_animal", "start_project":
			coins = -int(extra.get("spend", 0))
			for id: String in extra.get("consumed", {}):
				items[id] = -int(extra.consumed[id])
		"contribute_project":
			for id: String in extra.get("delivered", {}):
				items[id] = -int(extra.delivered[id])
		"dig", "collect_walk", "collect_friend_visit", "give_friend", "grow":
			exact = false  # "grow": o presente da fase pode virar recibo se a mochila estiver cheia
	return {"coins": coins, "items": items, "exact": exact}


func _account(action: Dictionary, before: Dictionary, after: Dictionary, outcome: Dictionary) -> void:
	var ok: bool = str(outcome.get("err", "")) == ""
	var delta_coins: int = int(after.coins) - int(before.coins)
	var delta_items := _item_delta(before, after)
	var side := side_effects(before, after)
	var expected := _expected(action, outcome)
	if not ok:
		expected = {"coins": 0, "items": {}, "exact": true}
		side = {"coins": side.coins, "items": side.items, "parts": side.parts}
		if delta_coins != int(side.coins) or not _items_match(delta_items, side.items):
			# Falha parcial (alguns alvos entraram): usa o que foi feito.
			if str(action.kind) not in ["plant_many", "water_many", "harvest_many"]:
				violate("falha_alterou_estado", "%s falhou (%s) mas mudou saldo/itens" % [action.kind, outcome.err])
		return
	_check_negative(action)
	if bool(expected.exact):
		var want_coins: int = int(expected.coins) + int(side.coins)
		var want_items: Dictionary = {}
		for id: String in expected.items:
			want_items[id] = int(expected.items[id])
		for id: String in side.items:
			want_items[id] = int(want_items.get(id, 0)) + int(side.items[id])
		var ok_items := _items_match(delta_items, want_items)
		if delta_coins != want_coins or not ok_items:
			violate("conservacao", "%s: moedas %+d (esperado %+d), itens %s (esperado %s)" % [action.kind, delta_coins, want_coins, JSON.stringify(delta_items), JSON.stringify(want_items)])
	else:
		if delta_coins < int(side.coins):
			violate("conservacao", "%s: moedas diminuíram sem gasto (%+d)" % [action.kind, delta_coins])
		for id: String in delta_items:
			var consumed: int = int(outcome.get("extra", {}).get("consumed", {}).get(id, 0))
			if int(delta_items[id]) < -consumed:
				violate("conservacao", "%s: item %s diminuiu %d sem consumo declarado" % [action.kind, id, int(delta_items[id])])
	_classify_flow(action, delta_coins, delta_items, side, outcome)


func _items_match(a: Dictionary, b: Dictionary) -> bool:
	for id: String in a:
		if int(a[id]) != int(b.get(id, 0)):
			return false
	for id: String in b:
		if int(b[id]) != int(a.get(id, 0)):
			return false
	return true


func _check_negative(action: Dictionary) -> void:
	if gs.coins < 0:
		violate("moeda_negativa", str(action.kind))
	for id: String in gs.inventory.counts:
		if int(gs.inventory.counts[id]) < 0:
			violate("inventario_negativo", "%s em %s" % [id, action.kind])


func _classify_flow(action: Dictionary, delta_coins: int, delta_items: Dictionary, side: Dictionary, outcome: Dictionary) -> void:
	var kind: String = str(action.kind)
	var direct: int = delta_coins - int(side.coins)
	var source := kind
	var unique := false
	match kind:
		"claim_quest", "open_treasure":
			unique = true
			source = "quest"
		"harvest_many":
			source = "harvest"
		"sell":
			source = "sale"
		"fulfill_order":
			source = "order"
		"claim_routine":
			source = "routine"
		"claim_daily_gift":
			source = "daily_gift"
		"fulfill_wish":
			source = "wish"
		"collect_walk":
			source = "walk"
		"dig":
			source = "find"
		"collect_gathering":
			source = "gather"
		"give_friend", "collect_friend_visit":
			source = "friends"
	if direct > 0:
		var bucket := ("unique:" if unique else "recurring:") + source
		coin_flow[bucket] = int(coin_flow.get(bucket, 0)) + direct
	elif direct < 0:
		coin_flow["spend:" + source] = int(coin_flow.get("spend:" + source, 0)) + direct
	for part: String in side.parts:
		if int(side.parts[part]) > 0:
			coin_flow["unique:" + part] = int(coin_flow.get("unique:" + part, 0)) + int(side.parts[part])
	for id: String in delta_items:
		var d: int = int(delta_items[id])
		var bucket2 := ("gained:" if d > 0 else "used:") + (("sold" if kind == "sell" else kind) if d < 0 else kind)
		item_flow[bucket2] = int(item_flow.get(bucket2, 0)) + absi(d)
		var per_item := ("made:" if d > 0 else "gone:") + id
		item_flow[per_item] = int(item_flow.get(per_item, 0)) + absi(d)


## Registra o ready_at legítimo e confere a fórmula da regra no instante da ação.
func _update_legit(action: Dictionary, outcome: Dictionary, t_action: float) -> void:
	var extra: Dictionary = outcome.get("extra", {})
	match str(action.kind):
		"plant_many":
			for i: int in extra.get("planted", []):
				var crop: Dictionary = Database.crops[str(extra.crop)]
				var seconds: float = float(crop.get("seconds", 60))
				if gs.is_greenhouse_plot(i):
					seconds *= float(Database.farm.get("greenhouse_speed", 1.0))
				var expected_ready := t_action + seconds
				if absf(float(gs.plots[i].ready_at) - expected_ready) > 0.001:
					violate("timer_fora_da_regra", "plantio %d: ready_at %.1f != %.1f" % [i, float(gs.plots[i].ready_at), expected_ready])
				_legit_plots[i] = float(gs.plots[i].ready_at)
		"water_many":
			for i: int in extra.get("watered", []):
				var left: float = float(extra.before_ready[i]) - t_action
				var expected_ready2: float = t_action + left * (1.0 - float(Database.farm.water.speedup))
				if absf(float(gs.plots[i].ready_at) - expected_ready2) > 0.001:
					violate("timer_fora_da_regra", "rega %d" % i)
				_legit_plots[i] = float(gs.plots[i].ready_at)
		"harvest_many":
			for i in gs.plots.size():
				if str(gs.plots[i].get("crop", "")) == "":
					_legit_plots.erase(i)
		"cook":
			var st: Object = gs.station(str(extra.station))
			if not st.queue.is_empty():
				var last: Dictionary = st.queue.back()
				var previous := t_action
				if st.queue.size() > 1:
					previous = maxf(t_action, float(st.queue[st.queue.size() - 2].ready_at))
				var seconds2: float = float(Database.recipes[str(extra.recipe)].seconds)
				if absf(float(last.ready_at) - (previous + seconds2)) > 0.001:
					violate("timer_fora_da_regra", "fila %s: %s" % [extra.station, extra.recipe])
		"start_walk":
			if gs.walking():
				var expected_walk: float = t_action + float(Database.walks.walks[str(action.args.id)].seconds)
				if absf(float(gs.walk_state.current.ready_at) - expected_walk) > 0.001:
					violate("timer_fora_da_regra", "passeio %s" % action.args.id)
		"start_gathering":
			var entry: Dictionary = gs.gathering_entry(str(action.args.site), int(action.args.index))
			if not entry.is_empty():
				var expected_g: float = t_action + float(Database.progression.activities[str(action.args.route)].seconds)
				if absf(float(entry.ready_at) - expected_g) > 0.001:
					violate("timer_fora_da_regra", "coleta %s" % action.args.route)
	_snapshot_timers_initial()


# --- Relatórios por ação --------------------------------------------------------------------------

func depot_state() -> Dictionary:
	var result := {}
	for depot: String in Database.progression.storage:
		if gs.storage_active(depot):
			result[depot] = [gs.storage_used(depot), gs.storage_capacity(depot)]
	return result


func queue_state() -> Dictionary:
	var busy := 0
	var ready := 0
	for id: String in gs.stations:
		for entry: Dictionary in gs.stations[id].queue:
			if float(entry.ready_at) <= gs.now():
				ready += 1
			else:
				busy += 1
	var plots_growing := 0
	var plots_ready := 0
	for i: int in gs.usable_plot_indices():
		var status_text: String = gs.plot_status(i)
		plots_growing += 1 if status_text == "growing" else 0
		plots_ready += 1 if status_text == "ready" else 0
	return {"st_busy": busy, "st_ready": ready, "pl_grow": plots_growing, "pl_ready": plots_ready, "walk": gs.walking()}


## Estado observado, sem reconstrução por deltas: usado pelo Atlas local.
func economy_checkpoint() -> Dictionary:
	var targets: Array = []
	for id: String in Database.progression.get("upgrades", {}):
		if gs.has_upgrade(id):
			continue
		var definition: Dictionary = Database.progression.upgrades[id]
		var materials: Dictionary = definition.get("materials", {})
		var missing: Dictionary = {}
		for item: String in materials:
			var gap := maxi(0, int(materials[item]) - int(gs.inventory.counts.get(item, 0)))
			if gap > 0:
				missing[item] = gap
		var price := int(definition.get("cost", 0))
		targets.append({"id": id, "name": definition.get("name", id), "cost": price,
			"materials": materials.duplicate(), "missing_items": missing,
			"missing_coins": maxi(0, price - int(gs.coins)),
			"requirement_error": gs.requirement_error(definition.get("requirements", {})),
			"error": gs.upgrade_error(id)})
	return {"schema": 1, "inventory": gs.inventory.counts.duplicate(),
		"coins": gs.coins, "targets": targets}


func _row(extra: Dictionary) -> void:
	if ledger == null:
		return
	var row := {"i": action_index, "t": snappedf(rel(gs.now()), 0.1), "d": int(rel(gs.now()) / DAY), "s": session_index, "act": snappedf(active_seconds, 0.1), "coins": gs.coins}
	row.merge(extra, true)
	if str(extra.get("ev", "")) in ["start", "session_end"]:
		row["checkpoint"] = economy_checkpoint()
	# Mesmo o modo compacto preserva saldo anterior e fila: são evidência por ação,
	# não detalhes dispensáveis. `compact` permanece como alias para scripts antigos.
	ledger.store_line(JSON.stringify(row))


func _row_available() -> void:
	if ledger == null:
		return
	var kinds: Array = []
	for item: Dictionary in gs.available_actions():
		kinds.append(str(item.kind))
		if kinds.size() >= 4:
			break
	_row({"ev": "available", "legal": kinds})


func _record_blocks() -> void:
	for entry: Dictionary in bot.blocks:
		var key := _classify_block(str(entry.why))
		blocks_seen[key] = int(blocks_seen.get(key, 0)) + 1
		var detail: String = "%s@%s" % [entry.why, entry.goal]
		blocks_seen[detail] = int(blocks_seen.get(detail, 0)) + 1


## Separa bloqueio do jogo (fonte/ requisito inexistente) de falha de política (o bot não achou caminho).
func _classify_block(why: String) -> String:
	var head := why.get_slice(":", 0)
	match head:
		"no_source", "chapter", "bond", "skill", "luck":
			return "jogo:" + head
		"storage":
			return "jogo:storage"
		"no_path", "depth", "route_error", "no_crop", "no_plot", "cook", "goal", "stat", "no_recipe", "no_overlay", "walk_locked", "site_closed", "animal", "place", "no_sewing", "route", "upgrade", "quest":
			return "politica:" + head
	return "outro:" + head


func _stall_text() -> String:
	var keys: Array = blocks_seen.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return int(blocks_seen[a]) > int(blocks_seen[b]))
	return ", ".join(keys.slice(0, 6))


func _collect_pending_at_close() -> void:
	var ready_plots := 0
	for i: int in gs.usable_plot_indices():
		if gs.plot_status(i) == "ready":
			ready_plots += 1
	var ready_stations := 0
	for id: String in gs.stations:
		ready_stations += gs.station(id).ready_count(gs.now())
	var ready_nature := 0
	for site: String in Database.progression.get("nature_sites", {}):
		ready_nature += gs.gathering_ready_count(site)
	var items_outside := 0
	for item: String in gs.inventory.counts:
		var depot: String = gs.storage_of(item)
		if depot == "" or not gs.storage_active(depot):
			items_outside += int(gs.inventory.counts[item])
	pending_at_close.append({"s": session_index, "t": snappedf(rel(gs.now()), 1.0), "plots": ready_plots, "stations": ready_stations, "nature": ready_nature, "walk": 1 if gs.walk_ready() else 0, "outside_depots": items_outside})


func _mark_days() -> void:
	while gs.now() >= _next_day_mark:
		daily.append({"day": daily.size(), "coins": gs.coins, "level": gs.level, "chapter": gs.progress.chapter_index(), "quests": gs.progress.claimed_quests.size(), "owned": gs.progress.owned.size(), "active_min": snappedf(active_seconds / 60.0, 0.1), "plots": gs.unlocked_plots})
		_next_day_mark += DAY


func _projects_all_done() -> bool:
	for id: String in Database.project_ids():
		if not gs.project_completed(id):
			return false
	return true


## Registro das obras: começo, cada entrega e a conclusão (com o saldo e o momento, para a etapa 23).
func _log_project(action: Dictionary, ok: bool) -> void:
	var kind: String = str(action.kind)
	if not ok or kind not in ["start_project", "contribute_project"]:
		return
	var id: String = str(action.args.id)
	project_log.append({"ev": kind, "id": id, "item": str(action.args.get("item", "")), "qty": int(action.args.get("qty", 0)), "coins": gs.coins, "day": int(rel(gs.now()) / DAY), "hours": snappedf(rel(gs.now()) / 3600.0, 0.1), "active_min": snappedf(active_seconds / 60.0, 0.1), "session": session_index, "done": gs.project_completed(id)})


func _detect_progress(kind: String, ok: bool) -> void:
	if ok and kind in ["claim_quest", "start_project", "contribute_project"]:
		last_progress_day = int(rel(gs.now()) / DAY)
		last_progress_active = active_seconds
	for id: String in gs.progress.claimed_quests:
		if not quest_times.has(id):
			quest_times[id] = {"active_min": snappedf(active_seconds / 60.0, 0.1), "hours": snappedf(rel(gs.now()) / 3600.0, 0.1), "session": session_index}


func _milestones() -> void:
	var checks := {
		"first_harvest": gs.progress.stat("harvest") >= 1,
		"first_wish": gs.progress.stat("wish") >= 1,
		"first_find": gs.progress.stat("find") >= 1,
		"first_walk": gs.progress.stat("walk") >= 1,
		"stove": gs.has_upgrade("stove"),
		"village_open": bot.world_open("village"),
		"workbench": gs.has_upgrade("workbench"),
		"stall": gs.has_upgrade("stall"),
		"chapter_9_done": gs.progress.chapter_index() > 9,
		"all_depots": gs.has_upgrade("silo") and gs.has_upgrade("warehouse") and gs.has_upgrade("fridge") and gs.has_upgrade("chest"),
		"campaign_all_quests": gs.progress.claimed_quests.size() >= Database.quests.size(),
		"bench_done": gs.project_completed("park_bench"),
		"garden_done": gs.project_completed("village_garden"),
		"picnic_done": gs.project_completed("park_picnic"),
		"projects_all": _projects_all_done(),
	}
	for key: String in checks:
		if bool(checks[key]) and not milestones.has(key):
			milestones[key] = {"active_min": snappedf(active_seconds / 60.0, 0.1), "hours": snappedf(rel(gs.now()) / 3600.0, 0.1), "session": session_index, "day": int(rel(gs.now()) / DAY)}
	var reached: int = gs.growth.phase_index()
	for i in range(1, reached + 1):
		var phase_id := str(Database.growth.phases[i].id)
		if not growth_days.has(phase_id):
			growth_days[phase_id] = {"day": snappedf(rel(gs.now()) / DAY, 0.01), "active_min": snappedf(active_seconds / 60.0, 0.1)}
	for chapter in range(1, gs.progress.chapter_index()):
		if not chapter_coins.has(str(chapter)):
			chapter_coins[str(chapter)] = {"coins": gs.coins, "day": snappedf(rel(gs.now()) / DAY, 0.01)}


# --- Próximo evento do jogo -------------------------------------------------------------------------

## Menor instante futuro em que algo muda e pode liberar uma ação. {} = nada pendente.
func next_event() -> Dictionary:
	var now: float = gs.now()
	# Lambdas do GDScript copiam variáveis simples: o melhor evento mora num dicionário.
	var best := {"at": INF, "label": ""}
	var consider := func(at: float, label: String) -> void:
		if at > now + 0.01 and at < float(best.at):
			best.at = at
			best.label = label
	for i: int in gs.usable_plot_indices():
		if str(gs.plots[i].get("crop", "")) != "":
			consider.call(float(gs.plots[i].ready_at), "lavoura")
	for id: String in gs.stations:
		for entry: Dictionary in gs.stations[id].queue:
			consider.call(float(entry.ready_at), "estacao")
	for site: String in gs.progress.gathering:
		for entry: Dictionary in gs.progress.gathering[site]:
			if not entry.is_empty():
				consider.call(float(entry.ready_at), "natureza")
	if not gs.progress.activity.is_empty():
		consider.call(float(gs.progress.activity.ready_at), "natureza")
	if gs.walking():
		consider.call(float(gs.walk_state.current.ready_at), "passeio")
	for i in gs.wishes.slots.size():
		if gs.wish_slot_open(i) and str(gs.wishes.slots[i].id) == "":
			consider.call(float(gs.wishes.slots[i].ready_at), "desejo")
	for world: String in gs.finds.worlds:
		consider.call(float(gs.finds.worlds[world].next_at), "faro")
	for key: String in gs.progress.cooldowns:
		consider.call(float(gs.progress.cooldowns[key]), "recarga:" + key.get_slice(":", 0))
	var dog = gs.dog
	for need: String in Database.needs:
		var rate: float = float(Database.needs[need].get("decay_per_hour", 0.0))
		var value: float = dog.get_need(need, now)
		if dog.sleeping and Database.needs[need].has("sleep_regen_per_hour"):
			var target: float = bot.WAKE_ABOVE
			var up: float = float(Database.needs[need].sleep_regen_per_hour)
			if value < target and up > 0.0:
				consider.call(now + (target - value) / up * 3600.0 + 1.0, "sono")
		elif rate > 0.0:
			for threshold: float in [bot.CARE_FEED_BELOW, bot.CARE_BATHE_BELOW, bot.CARE_PLAY_BELOW, bot.SLEEP_BELOW, 30.0, 25.0]:
				if value > threshold:
					consider.call(now + (value - threshold) / rate * 3600.0 + 1.0, "necessidade")
	# Virada do dia local (diárias, presente do dia, janela de passeio) e janela de amigos.
	var local: float = fposmod(now + float(gs.zone_bias), DAY)
	consider.call(now + (DAY - local) + 1.0, "meia_noite")
	for hour: float in [17.0, 21.0]:
		var at_hour: float = hour * 3600.0
		consider.call(now + fposmod(at_hour - local, DAY) + 1.0, "janela_hora")
	var window: float = float(Database.friends.settings.window_hours) * 3600.0
	consider.call(now + (window - fposmod(now + float(gs.zone_bias), window)) + 1.0, "janela_amigos")
	if str(best.label) == "":
		return {}
	return {"at": float(best.at), "label": str(best.label)}


# --- Fim ---------------------------------------------------------------------------------------------

func reload_through_json() -> void:
	var text: String = JSON.stringify(gs.to_dict())
	gs.from_dict(JSON.parse_string(text))
	_snapshot_timers_initial()
	_digest_after = digest()


func finish() -> void:
	if ledger != null:
		ledger.close()
		ledger = null
	var path := out_dir.path_join("summary.json")
	if out_dir != "":
		DirAccess.make_dir_recursive_absolute(out_dir)
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(summary(), "  ", true))
			file.close()


func summary() -> Dictionary:
	var upgrades_owned := 0
	for id: String in Database.progression.upgrades:
		if gs.has_upgrade(id):
			upgrades_owned += 1
	return {
		"schema": 1,
		"content_hash": content_hash(),
		"engine": str(Engine.get_version_info().get("string", "")),
		"label": "SIMULADO (GameState real, relógio injetado); não confundir com a estimativa estática do auditor",
		"profile": profile_name, "seed": seed_value, "status": status, "stall": stall_reason,
		"params": {"days": params.get("days", 30), "until": params.get("until", "days"), "rare": params.get("rare", "normal"), "reload": params.get("reload", "none")},
		"end": {
			"days": snappedf(rel(gs.now()) / DAY, 0.01), "coins": gs.coins, "level": gs.level, "chapter": gs.progress.chapter_index(),
			"quests": gs.progress.claimed_quests.size(), "quests_total": Database.quests.size(),
			"upgrades": upgrades_owned, "upgrades_total": Database.progression.upgrades.size(), "missing_upgrades": _missing_upgrades(), "plots": gs.unlocked_plots,
			"affection": gs.dog.affection, "walks": gs.progress.stat("walk"), "finds": gs.progress.stat("find"),
			"phase": gs.growth.phase, "silk": gs.growth.silk, "pillars": _pillar_levels(),
		},
		"growth_days": growth_days, "chapter_coins": chapter_coins,
		"time": {
			"active_min": snappedf(active_seconds / 60.0, 0.1), "forced_wait_min": snappedf(wait_seconds / 60.0, 0.1),
			"nav_min": snappedf(nav_seconds / 60.0, 0.1), "sessions": session_index, "actions": action_index,
			"first_session_idle_pct": snappedf(_first_session_wait / 1200.0 * 100.0, 0.1),
			"unused_no_action_min": snappedf(unused_no_action / 60.0, 0.1), "left_with_actions_min": snappedf(budget_left_with_actions / 60.0, 0.1),
			"longest_gap_active_min": _longest_gap(),
		},
		"guards": {"violations": violations.size(), "details": violations.slice(0, 20), "unlimited_storage": bool(gs.unlimited_storage)},
		"milestones": milestones,
		"coin_flow": coin_flow, "item_flow": item_flow, "waits_by_reason": waits_by_reason,
		"blocks": blocks_seen, "actions": action_counts, "actions_by_why": actions_by_why,
		"failures": {"count": failures.size(), "sample": failures.slice(0, 15)},
		"pending_at_close": pending_at_close.slice(maxi(0, pending_at_close.size() - 12)),
		"daily": daily, "sessions": session_log.slice(0, 40), "last_sessions": session_log.slice(maxi(0, session_log.size() - 6)), "quest_times": quest_times,
		"unclaimed": _unclaimed(),
		"projects": project_log,
		"depth_stack": bot.depth_stack,
		"final_trace": final_trace.slice(0, 400),
		"final_debug": final_debug,
		"perf_ms": _perf_ms(),
	}


func _pillar_levels() -> Dictionary:
	var result := {}
	for id: String in Database.growth.pillars:
		result[id] = {"level": gs.growth.level(id), "points": int(gs.growth.points.get(id, 0))}
	return result


## Maior intervalo (em minutos ativos) entre duas missões recebidas seguidas: "tempo sem progresso" da história.
func _longest_gap() -> float:
	var times: Array = []
	for id: String in quest_times:
		times.append(float(quest_times[id].active_min))
	times.sort()
	var longest := 0.0
	for i in range(1, times.size()):
		longest = maxf(longest, float(times[i]) - float(times[i - 1]))
	return snappedf(longest, 0.1)


func _perf_ms() -> Dictionary:
	var result := {}
	for key: String in perf:
		result[key] = int(perf[key]) / 1000
	for key: String in bot.perf:
		result["bot." + key] = int(bot.perf[key]) / 1000
	return result


## Identifica o conteúdo medido (game/data/**/*.json, sem version.json): comparar só execuções de mesmo conteúdo.
func content_hash() -> String:
	var parts: Array[String] = []
	var folders: Array[String] = ["res://data", "res://data/rooms"]
	for folder in folders:
		var names := DirAccess.get_files_at(folder)
		var sorted_names: Array = Array(names)
		sorted_names.sort()
		for file_name: String in sorted_names:
			if file_name.ends_with(".json") and file_name != "version.json":
				parts.append(folder.path_join(file_name).trim_prefix("res://") + ":" + FileAccess.get_file_as_string(folder.path_join(file_name)).replace(CR + LF, LF).sha256_text())
	return LF.join(parts).sha256_text()


func _missing_upgrades() -> Array:
	var result: Array = []
	for id: String in Database.progression.upgrades:
		if not gs.has_upgrade(id):
			result.append(id)
	return result


func _unclaimed() -> Array:
	var result: Array = []
	for id: String in Database.quests:
		if not gs.progress.claimed_quests.has(id):
			result.append(id)
	return result
