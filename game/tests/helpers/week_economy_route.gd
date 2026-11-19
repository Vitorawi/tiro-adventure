extends "res://tests/helpers/week_story_route.gd"
## Percurso reproduzível da E15. Só o relógio avança entre sessões.
## Os valores de caixa e ocupação são observados no GameState real.

var rows: Array[Dictionary] = []
var profile: String
var initial_midnight: float
var last_balance: int
var collecting_purchase := false
var errors: Array[String] = []
var day: Dictionary
var last_panel := ""
var session_start: float
var active_session := false
var origin: float
var touch_total := 0.0
var phases := {}
var chapters := {}


func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
		push_error(message)


func open_day(number: int) -> void:
	day = {"day": number, "opening": state.coins, "income": 0, "expense": 0,
		"ending": state.coins, "purchases": {}, "transactions": [], "peak": {}, "capacity": {},
		"sessions": 0, "touches": 0, "navigation_seconds": 0.0, "sessions_seconds": 0.0, "touch_seconds": 0.0, "wait_seconds": 0.0, "state_changes": 0, "space_sales": 0}
	rows.append(day)
	observe(false)


func observe(changed: bool = true) -> void:
	if changed:
		day.state_changes += 1
	if not collecting_purchase:
		var delta: int = state.coins - last_balance
		day.income += maxi(0, delta)
		day.expense += maxi(0, -delta)
		if delta != 0:
			day.transactions.append({"context": last_panel, "net": delta, "balance": state.coins})
		last_balance = state.coins
	day.ending = state.coins
	var elapsed := snappedf((state.now() - origin) / 86400.0, 0.01)
	var phase: String = state.growth.phase
	if phase != "newborn" and not phases.has(phase):
		phases[phase] = {"day": elapsed, "active_min": snappedf(touch_total / 60.0, 0.1)}
	var chapter: int = state.progress.chapter_index()
	for n in range(1, chapter):
		if not chapters.has(str(n)):
			chapters[str(n)] = {"coins": state.coins, "day": elapsed}
	day.snapshot = {"coins": state.coins, "level": state.level, "chapter": chapter,
		"quests": state.progress.claimed_quests.size(), "owned": state.progress.owned.size(),
		"active_min": snappedf(touch_total / 60.0, 0.1), "plots": state.unlocked_plots}
	for depot in ["silo", "fridge", "warehouse", "chest"]:
		var used: int = state.storage_used(depot)
		var cap: int = state.storage_capacity(depot)
		day.peak[depot] = maxi(day.peak.get(depot, 0), used)
		day.capacity[depot] = cap
		check(used <= cap, "Capacidade excedida: " + depot)


func time_action(panel: String, touches: int) -> void:
	var seconds := 3.0 * touches + (2.0 if panel != last_panel else 0.0)
	day.touches += touches
	day.navigation_seconds += seconds - 3.0 * touches
	touch_total += seconds
	day.touch_seconds += seconds
	state.advance_clock(seconds)
	last_panel = panel


func wait_for_work(seconds: float) -> void:
	day.wait_seconds += seconds
	super.wait_for_work(seconds)


func close_session() -> void:
	if active_session:
		day.sessions_seconds += state.now() - session_start
		active_session = false


func at(story_day: int, hour: int) -> void:
	var offset := 0
	if story_day >= 3:
		offset = {"tranquilo": 2, "regular": 1, "dedicado": 0}[profile]
	var number := story_day + offset
	var target := initial_midnight + (number - 1) * 86400 + hour * 3600
	if active_session and target <= state.now():
		return
	close_session()
	while rows.size() < number:
		open_day(rows.size() + 1)
	if state.now() < target:
		state.begin_absence(state.now())
		state.advance_clock(target - state.now())
		state.end_absence()
	state.update_week()
	day.sessions += 1
	session_start = state.now()
	active_session = true


func buy(id: String, qty: int = 1) -> void:
	make_space(state._pack_items(state.shop_pack(id), qty))
	action("banca")
	var cost := int(state.shop_pack(id).price) * qty
	var before: int = state.coins
	collecting_purchase = true
	var error: String = state.buy_shop_item(id, qty)
	collecting_purchase = false
	ok(error, "Comprar " + id)
	if error == "":
		day.purchases[id] = int(day.purchases.get(id, 0)) + cost
		day.transactions.append({"purchase": id, "before": before, "cost": cost, "credit": state.coins - before + cost, "balance": state.coins})
		day.expense += cost
		day.income += state.coins - before + cost
	last_balance = state.coins
	observe(false)


func make_space(gain: Dictionary) -> void:
	var sold_before: int = state.coins
	super.make_space(gain)
	day.space_sales += state.coins - sold_before


## Fechar a sessão com milho no comedouro evita esperar meia hora na carroça.
func prepare_eggs() -> void:
	if not state.station("chicken_coop").queue.is_empty():
		collect("chicken_coop")
	crop("corn", 2)
	action("galinheiro")
	ok(state.cook("eggs"), "Deixar os ovos para o próximo dia")


func eggs(qty: int) -> void:
	if not state.station("chicken_coop").queue.is_empty():
		collect("chicken_coop")
	super.eggs(qty)


func measure(name: String, horizon: int = 99) -> Dictionary:
	profile = name
	on_action = time_action
	first_dish_stars = 3 if name == "dedicado" else 2
	cooking_stars = {"tranquilo": 1, "regular": 2, "dedicado": 3}[name]
	verify = check
	origin = state.now()
	initial_midnight = state.now() - fposmod(state.now() + state.zone_bias, 86400.0)
	last_balance = state.coins
	open_day(1)
	var events := state.get_node("/root/Events")
	events.state_changed.connect(observe)
	var missed: int = {"tranquilo": 2, "regular": 1, "dedicado": 0}[profile]
	var steps: Array[Callable] = [day_one.bind(false), day_two, lake.bind(3), day_four, day_five, day_six, day_seven]
	for i in steps.size():
		var calendar_day: int = i + 1 + (missed if i >= 2 else 0)
		if calendar_day > horizon or not errors.is_empty():
			break
		steps[i].call()
		if i in [1, 2, 3]:
			prepare_eggs()
	close_session()
	observe(false)
	events.state_changed.disconnect(observe)
	for row in rows:
		check(row.opening + row.income - row.expense == row.ending, "Conservação do saldo")
	if horizon >= 7 + missed:
		check(state.growth.phase == "teething" and state.requirement_error(db.worlds.village.requirements) == "" and state.progress.claimed_quests.has("lais_village"), "Dentinhos e capítulo 8")
	check(not state.unlimited_storage and state.week.clock_offset == 0, "Depósitos e relógio de produção")
	return {"profile": profile, "phases": phases, "chapters": chapters, "days": rows, "errors": errors, "phase": state.growth.phase,
		"village": state.progress.claimed_quests.has("lais_village"), "paws": state.well_fed_days(),
		"growth_day": state.week_day() if state.growth.phase == "teething" else 0}
