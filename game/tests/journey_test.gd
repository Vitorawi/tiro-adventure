extends SceneTree
## Etapa 13 do plano de economia: capítulos 1–9 sem tarefas repetidas.
## Cobre: todos os pares shared_with reais (grafo e entrega única), as missões ajustadas (cozinha, feira, estufa,
## tábuas, ateliê), ervas sem Horta 5, saves no meio dos capítulos 3/5/7/9 e antigos, bases fresh que sobram,
## e a medição de repetição (build/economy/etapa_13/repeticao.md).
## --headless --path game -s res://tests/journey_test.gd

const T0 := 1791936000.0

var failures := 0
var state: Node
var db: Node
var report: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("JORNADA: " + message)


func _p() -> RefCounted:
	return state.get("progress")


func _quests() -> Dictionary:
	return db.get("quests")


func _fresh() -> void:
	state.set("test_time", T0)
	state.set("unlimited_storage", true)
	state.call("reset")


func _roundtrip() -> void:
	state.call("from_dict", JSON.parse_string(JSON.stringify(state.call("to_dict"))))


## Marca como recebidas todas as missões da história e das linhas anteriores a `alias` (sem pagar).
func _claim_before(alias: String) -> void:
	var quests := _quests()
	var chapter: int = int(quests[alias].chapter)
	for c in range(1, chapter + 1):
		for previous: String in _p().main_quests(c):
			if previous == alias:
				break
			_p().claimed_quests[previous] = true
	var target: String = str(quests[alias].get("shared_with", ""))
	if target != "":
		var line: String = str(quests[target].line)
		for previous: String in _p().line_quests(line):
			if previous == target:
				break
			_p().claimed_quests[previous] = true
	# Os cruzamentos de capítulos anteriores já aconteceram: as linhas dos outros personagens avançam junto.
	for id: String in quests:
		var q: Dictionary = quests[id]
		if q.has("shared_with") and int(q.chapter) < chapter or (q.has("shared_with") and int(q.chapter) == chapter and int(q.order) < int(quests[alias].order)):
			_p().claimed_quests[str(q.shared_with)] = true
	state.call("_changed")


func _satisfy(id: String) -> void:
	for goal: Dictionary in _quests()[id].goals:
		match str(goal.type):
			"stat":
				_p().stats[str(goal.key)] = maxi(_p().stat(str(goal.key)), int(goal.get("target", 1)))
			"deliver", "have":
				state.get("inventory").add(str(goal.key), int(goal.get("target", 1)))
			"owned":
				_p().owned[str(goal.key)] = true
	state.call("_changed")


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	_pairs()
	_data()
	_new_pairs_flow()
	_old_saves()
	_midway_saves()
	_stale_base()
	_atelier_goal()
	_repetition_report()
	print("JOURNEY TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# --- grafo -----------------------------------------------------------------------------------------

func _pairs() -> void:
	var quests := _quests()
	var pairs: Array[String] = []
	var targets := {}
	for id: String in quests:
		var q: Dictionary = quests[id]
		if not q.has("shared_with"):
			continue
		var target := str(q.shared_with)
		pairs.append("%s→%s" % [id, target])
		check(quests.has(target), id + ": canônica existe")
		check(str(q.get("kind", "")) == "main", id + ": o alias é da história")
		check(not quests.get(target, {}).has("shared_with"), id + ": a canônica não é outro alias")
		check(str(quests.get(target, {}).get("kind", "")) == "line", id + ": a canônica é de uma linha")
		check(q.goals.size() == 1 and str(q.goals[0].type) == "quest" and str(q.goals[0].key) == target, id + ": um único objetivo aponta a canônica")
		check((q.get("rewards", {}) as Dictionary).is_empty(), id + ": alias sem prêmio próprio")
		check(not targets.has(target), id + ": duas missões da história não dividem a mesma canônica")
		targets[target] = id
	# Capítulo: a ordem dos alias na história acompanha a ordem das canônicas na linha.
	var last := {}
	var ids: Array = quests.keys().filter(func(i: String) -> bool: return quests[i].has("shared_with"))
	ids.sort_custom(func(a: String, b: String) -> bool:
		return int(quests[a].chapter) * 1000 + int(quests[a].order) < int(quests[b].chapter) * 1000 + int(quests[b].order))
	for id: String in ids:
		var line := str(quests[str(quests[id].shared_with)].line)
		var order := int(quests[str(quests[id].shared_with)].order)
		check(order > int(last.get(line, -1)), id + ": ordem da canônica cresce na linha " + line)
		last[line] = order
	check(pairs.size() == 13, "treze pares shared_with (dez antigos + três do Tiro; hoje: %s)" % str(pairs))
	for required: String in ["teeth_3_ring→bloblo_chew_ring", "explorer_6_eggs→main_9_eggs", "young_9_milk→main_9_flour", "main_5_pickaxe→guide_open_cave", "stone_path→guide_stone", "main_6_commerce→merchant_variety", "market_day→merchant_regular", "own_business→merchant_stall"]:
		check(pairs.has(required), "par " + required)
	report.append("Pares shared_with (%d): %s" % [pairs.size(), ", ".join(pairs)])


func _data() -> void:
	var quests := _quests()
	for id: String in ["main_5_cooking", "main_8_building", "merchant_variety", "atelier_open", "main_7_greenhouse", "main_5_pickaxe", "stone_path", "main_6_commerce"]:
		for goal: Dictionary in quests[id].goals:
			check(not goal.get("fresh", false), id + ": objetivo sem fresh (" + str(goal.key) + ")")
	var cooking: Array = quests.main_5_cooking.goals
	check(cooking.size() == 3 and str(cooking[0].key) == "produce:carrot_snack" and int(cooking[0].target) == 2, "cozinha: 2 lanches de cenoura")
	check(str(cooking[1].key) == "produce:vegetable_soup" and int(cooking[1].target) == 1 and str(cooking[2].key) == "produce:strawberry_juice" and int(cooking[2].target) == 1, "cozinha: sopa e suco")
	var variety: Dictionary = quests.merchant_variety
	check(str(variety.line) == "merchant" and int(variety.order) == 45 and int(variety.rewards.coins) == 10, "merchant_variety: linha merchant, ordem 45, 10 moedas")
	check(str(variety.goals[0].key) == "order:vegetables" and str(variety.goals[1].key) == "order:snacks", "merchant_variety: dois pedidos diferentes")
	check(int(quests.merchant_regular.order) < 45 and int(quests.merchant_stall.order) > 45, "variedade entre freguês e banca")
	check(quests.main_7_greenhouse.goals.size() == 2 and str(quests.main_7_greenhouse.goals[1].key) == "harvest:herbs", "estufa pede a primeira erva")
	var herbs: Dictionary = db.get("crops").herbs
	check(not herbs.requirements.has("skills"), "ervas sem atributo de Horta")
	check(herbs.requirements.owned == ["greenhouse"] and str(herbs.greenhouse) == "only", "ervas só na estufa")
	var atelier: Array = quests.atelier_open.goals
	check(atelier.size() == 3 and str(atelier[1].key) == "produce:fabric" and int(atelier[1].target) == 2 and str(atelier[2].key) == "produce:accessory_set", "ateliê: tecido 2 + conjunto 1")
	check(int(quests.atelier_open.rewards.coins) == 40 and quests.atelier_open.rewards.collections == ["artisan_outfit"], "ateliê: prêmio mantido")
	# Cada objetivo de produzir/entregar existe de verdade e cada texto diz um verbo.
	for id: String in ["main_5_cooking", "atelier_open", "merchant_variety", "main_7_greenhouse"]:
		for goal: Dictionary in quests[id].goals:
			check(str(goal.get("label", "")) != "", id + ": objetivo com texto")
			if str(goal.key).begins_with("produce:"):
				var made := false
				for recipe: Dictionary in (db.get("recipes") as Dictionary).values():
					if str(db.call("recipe_output", recipe)) == str(goal.key).trim_prefix("produce:"):
						made = true
				check(made, id + ": existe receita de " + str(goal.key))
			if str(goal.key).begins_with("order:"):
				check(db.get("progression").orders.has(str(goal.key).trim_prefix("order:")), id + ": existe o pedido " + str(goal.key))
			if str(goal.key).begins_with("harvest:"):
				check(db.get("crops").has(str(goal.key).trim_prefix("harvest:")), id + ": existe a planta " + str(goal.key))


# --- cruzamentos ------------------------------------------------------------------------------------

func _new_pairs_flow() -> void:
	var quests := _quests()
	for alias: String in quests.keys():
		if not quests[alias].has("shared_with"):
			continue
		_fresh()
		var target: String = str(quests[alias].shared_with)
		_claim_before(alias)
		check(_p().displayed_main_quest() == _p().current_line_quest(str(quests[target].line)), alias + ": história mostra o passo da linha")
		check(_p().current_main_quest() == alias, alias + ": é o passo atual da história")
		_satisfy(target)
		var before: int = state.get("coins")
		var count_before: int = _p().stat("quests")
		var chapter: int = _p().chapter_index()
		var chapter_coins := 0
		if _p().main_quests(chapter).back() == alias:
			chapter_coins = int(db.get("progression").chapters[chapter - 1].get("rewards", {}).get("coins", 0))
		var error: String = state.call("claim_quest", target)
		check(error == "", alias + ": entrega canônica (" + error + ")")
		check(_p().claimed_quests.has(alias), alias + ": história avança junto")
		check(int(state.get("coins")) == before + int(quests[target].rewards.get("coins", 0)) + chapter_coins, alias + ": só o prêmio canônico (+capítulo)")
		check(_p().stat("quests") == count_before + 1, alias + ": conta uma missão")
		check(state.call("claim_quest", alias) != "" and state.call("claim_quest", target) != "", alias + ": sem segunda entrega")
		_roundtrip()
		check(int(state.get("coins")) == before + int(quests[target].rewards.get("coins", 0)) + chapter_coins, alias + ": recarregar não paga de novo")


func _old_saves() -> void:
	# Save antigo: o marco da história foi recebido pelo objetivo antigo; a canônica não vale prêmio de novo.
	var pairs := {"main_5_pickaxe": "guide_open_cave", "stone_path": "guide_stone", "main_6_commerce": "merchant_variety"}
	for alias: String in pairs:
		_fresh()
		_claim_before(alias)
		_p().claimed_quests[alias] = true
		var coins_before: int = state.get("coins")
		_roundtrip()
		check(_p().claimed_quests.has(pairs[alias]), alias + ": save antigo resolve a canônica")
		check(int(state.get("coins")) == coins_before, alias + ": migrar não paga")
		check(not state.call("quest_unlocked", pairs[alias]) and state.call("quest_error", pairs[alias]) != "", alias + ": a canônica não volta a ficar ativa")
		_roundtrip()
		check(_p().claimed_quests.has(pairs[alias]) and int(state.get("coins")) == coins_before, alias + ": idempotente")
	# Save antigo com a banca montada e a variedade ainda pendente: a missão aparece uma vez, paga 10 e não trava o resto.
	_fresh()
	_claim_before("main_6_commerce")
	_p().claimed_quests.erase("merchant_variety")
	_p().claimed_quests["merchant_regular"] = true
	_p().claimed_quests["merchant_stall"] = true
	state.call("_changed")
	_roundtrip()
	check(_p().current_line_quest("merchant") == "merchant_variety", "banca antiga: a variedade pendente aparece na linha")
	_satisfy("merchant_variety")
	var before: int = state.get("coins")
	var chapter_seven: int = int(db.get("progression").chapters[6].rewards.coins)
	check(state.call("claim_quest", "merchant_variety") == "" and int(state.get("coins")) == before + 10 + chapter_seven, "banca antiga: variedade paga 10 uma vez (+capítulo 7 que fecha junto)")
	check(_p().current_line_quest("merchant") == "merchant_contracts", "banca antiga: a linha segue para os contratos")


func _midway_saves() -> void:
	# Capítulos 3, 5, 7 e 9 no meio: salvar/recarregar não muda o passo nem repete prêmio.
	for chapter in [3, 5, 7, 9]:
		_fresh()
		for c in range(1, chapter):
			for id: String in _p().main_quests(c):
				_p().claimed_quests[id] = true
		var first: String = _p().main_quests(chapter)[0]
		_p().claimed_quests[first] = true
		for id: String in _quests():
			var q: Dictionary = _quests()[id]
			if q.has("shared_with") and int(q.chapter) < chapter:
				_p().claimed_quests[str(q.shared_with)] = true
		state.call("_changed")
		var current: String = _p().current_main_quest()
		var coins: int = state.get("coins")
		var active_before: Dictionary = _p().active_steps().duplicate(true)
		_roundtrip()
		check(_p().current_main_quest() == current, "capítulo %d: passo atual igual após recarregar (%s)" % [chapter, current])
		check(int(state.get("coins")) == coins, "capítulo %d: recarregar não paga" % chapter)
		check(_p().active_steps() == active_before, "capítulo %d: passos ativos iguais" % chapter)
		check(_p().chapter_index() == chapter, "capítulo %d: continua no capítulo" % chapter)


func _stale_base() -> void:
	# main_5_cooking era fresh em "produce": a base antiga some e o histórico passa a valer.
	_fresh()
	_claim_before("main_5_cooking")
	_p().claimed_quests["main_5_pickaxe"] = true
	_p().claimed_quests["stone_path"] = true
	_p().stats["produce"] = 9
	_p().stats["produce:carrot_snack"] = 2
	_p().stats["produce:vegetable_soup"] = 1
	_p().stats["produce:strawberry_juice"] = 1
	_p().steps = {"main": {"quest": "main_5_cooking", "base": {"produce": 9}}}
	state.call("_changed")
	check(_p().current_main_quest() == "main_5_cooking", "base antiga: cozinha é o passo")
	check((_p().steps.main.base as Dictionary).is_empty(), "base antiga: contador fresh obsoleto some")
	check(state.call("quest_error", "main_5_cooking") == "", "base antiga: produção anterior já conta")
	var before: int = state.get("coins")
	check(state.call("claim_quest", "main_5_cooking") == "" and int(state.get("coins")) == before + 10, "base antiga: paga 10 uma vez")
	# Quem ainda tem fresh de verdade mantém a base (guide_stone).
	_fresh()
	_claim_before("stone_path")
	_p().stats["activity:quarry"] = 3
	_p().steps["guide"] = {"quest": "guide_stone", "base": {"activity:quarry": 3}}
	state.call("_changed")
	check(int(_p().steps.guide.base.get("activity:quarry", -1)) == 3, "fresh que continua fresh mantém a base")
	check(state.call("quest_error", "guide_stone") != "", "pedreira antiga não conta como nova")


func _atelier_goal() -> void:
	_fresh()
	_p().claimed_quests["main_8_building"] = true
	var id := "atelier_open"
	_p().stats["produce:plank"] = 6
	for previous in range(1, 9):
		for q: String in _p().main_quests(previous):
			_p().claimed_quests[q] = true
	for q: String in _p().main_quests(9):
		if q != id:
			_p().claimed_quests[q] = true
	for alias: String in _quests():
		if _quests()[alias].has("shared_with") and _p().claimed_quests.has(alias):
			_p().claimed_quests[str(_quests()[alias].shared_with)] = true
	state.call("_changed")
	check(state.call("quest_error", id) != "", "ateliê: só montar não basta")
	_p().owned["atelier"] = true
	_p().stats["produce:fabric"] = 2
	check(state.call("quest_error", id) != "", "ateliê: falta o conjunto")
	_p().stats["produce:accessory_set"] = 1
	var before: int = state.get("coins")
	var chapter_coins: int = int(db.get("progression").chapters[8].rewards.coins)
	check(state.call("claim_quest", id) == "" and int(state.get("coins")) == before + 40 + chapter_coins, "ateliê: 40 moedas + prêmio do capítulo")
	# Etapa 22: depois do ateliê a história segue para o capítulo 10 (banco da Praça).
	check(_p().current_main_quest() == "community_10_meet", "ateliê: o capítulo 9 termina e abre o 10")


func _repetition_report() -> void:
	var quests := _quests()
	var fresh: Array[String] = []
	for c in range(1, 10):
		for id: String in _p().main_quests(c):
			for goal: Dictionary in quests[id].goals:
				if goal.get("fresh", false):
					fresh.append("%s(%s)" % [id, str(goal.key)])
	report.append("Objetivos fresh remanescentes na história 1–9: %d → %s" % [fresh.size(), ", ".join(fresh)])
	var dir := ProjectSettings.globalize_path("res://").path_join("../build/economy/etapa_13")
	DirAccess.make_dir_recursive_absolute(dir)
	var file := FileAccess.open(dir.path_join("repeticao.md"), FileAccess.WRITE)
	if file != null:
		file.store_string("# Etapa 13 — grafo da jornada\n\n" + "\n\n".join(report) + "\n")
		file.close()
	print("\n".join(report))
