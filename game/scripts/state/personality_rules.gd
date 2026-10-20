class_name PersonalityRules
extends RefCounted
## Pontuações relativas por dia jogado; histórico amortecido e janela de 14 dias ativos.

static func record(state: GrowthState, key: String, amount: int, day: String) -> void:
	var rule: Dictionary = Database.growth.get("personality", {})
	var weights := {}
	for id: String in rule.get("types", {}):
		var weight := float(rule.types[id].weights.get(key, 0))
		if weight > 0: weights[id] = weight
	if weights.is_empty() or amount <= 0: return
	var memory := state.personality
	if not memory.has("days"): memory["days"] = []
	if not memory.has("history"): memory["history"] = {}
	var days: Array = memory.days
	# Relógio atrasado fica no último dia: não reabre dias antigos nem cria dias extras.
	if not days.is_empty() and day < str(days.back().day): day = str(days.back().day)
	if days.is_empty() or str(days.back().day) != day:
		days.append({"day": day, "scores": {}})
		memory["played_days"] = int(memory.get("played_days", 0)) + 1
	while days.size() > int(rule.window_days): days.pop_front()
	var scores: Dictionary = days.back().scores
	for id: String in weights:
		var before := float(scores.get(id, 0))
		var after := minf(float(rule.daily_cap), before + float(weights[id]) * amount)
		scores[id] = after
		memory.history[id] = float(memory.history.get(id, 0)) + after - before
	var totals := relative_scores(state)
	var best := str(rule.default)
	for id: String in totals:
		if float(totals[id]) > float(totals.get(best, 0)): best = id
	var current := str(memory.get("current", ""))
	if current == "":
		memory["current"] = best
	elif current != best and float(totals[best]) > float(totals.get(current, 0)) + float(rule.switch_margin):
		var wins := 0
		for entry: Dictionary in days:
			if float(entry.scores.get(best, 0)) > float(entry.scores.get(current, 0)): wins += 1
		if wins >= int(rule.switch_days): memory["current"] = best


static func relative_scores(state: GrowthState) -> Dictionary:
	var rule: Dictionary = Database.growth.get("personality", {})
	var memory := state.personality
	var days: Array = memory.get("days", [])
	var result := {}
	for id: String in rule.get("types", {}):
		var recent := 0.0
		for entry: Dictionary in days: recent += float(entry.scores.get(id, 0))
		var historic := float(memory.get("history", {}).get(id, 0)) / maxi(1, int(memory.get("played_days", 0)))
		result[id] = recent / maxi(1, days.size()) * (1.0 - float(rule.history_weight)) + historic * float(rule.history_weight)
	return result


static func id(state: GrowthState) -> String:
	var rule: Dictionary = Database.growth.get("personality", {})
	if state.phase_index() < state.phase_index(str(rule.get("reveal_phase", "explorer"))): return ""
	var current := str(state.personality.get("current", rule.get("default", "calm")))
	return current if rule.get("types", {}).has(current) else str(rule.get("default", "calm"))


static func title(state: GrowthState) -> String:
	var current := id(state)
	if current == "": return ""
	var rule: Dictionary = Database.growth.personality
	return str(rule.title).format({"name": rule.types[current].name})


static func behavior(state: GrowthState) -> Dictionary:
	var data: Dictionary = Database.growth.behaviors
	var result: Dictionary = data.phases[state.phase].duplicate(true)
	var extra: Dictionary = data.personalities.get(id(state), {})
	for clip: String in extra.get("fidgets", {}):
		result.fidgets[clip] = float(result.fidgets.get(clip, 0)) + float(extra.fidgets[clip])
	for key: String in extra.get("world", {}):
		result.world[key] = minf(1.0, float(result.world.get(key, 0)) + float(extra.world[key]))
	return result
