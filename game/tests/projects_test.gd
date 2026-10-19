extends SceneTree
## Etapa 19 do plano de economia: motor transacional das obras comunitárias (`projects.json`, ProjectState,
## GameState.start/contribute/complete/use_project). Catálogo REAL vazio; o projeto de teste entra por fixture.
## --headless --path game -s res://tests/projects_test.gd

var failures := 0
var checks := 0
var state: Node
var database: Node
var events: Dictionary = {"phase": [], "done": [], "used": []}
var toasts: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PROJECTS: " + message)


func _inv(id: String) -> int:
	return int(state.get("inventory").count(id))


func _coins() -> int:
	return int(state.get("coins"))


func _stage(id: String = "test_bench") -> Dictionary:
	return state.call("project_stage", id)


func _fixture() -> Dictionary:
	return {"schema": 1, "projects": {
		"test_bench": {
			"id": "test_bench", "name": "Banco de teste", "npc": "lais", "world": "park", "requirements": {}, "start_coins": 150,
			"phases": [
				{"id": "base", "items": {"plank": 4, "brick": 2}, "visual_state": "base"},
				{"id": "comfort", "items": {"fabric": 2, "braided_toy": 1}, "visual_state": "comfort"},
				{"id": "welcome", "items": {"carrot_snack": 3}, "visual_state": "welcome"},
			],
			"rewards": {"xp": 5, "coins": 10, "items": {"carrot": 5}},
			"go": {"world": "park", "place": "place:training"}, "interaction": "sit",
		},
		"test_garden": {
			"id": "test_garden", "name": "Jardim de teste", "npc": "lais", "world": "park", "requirements": {"projects": ["test_bench"]}, "start_coins": 0,
			"phases": [{"id": "beds", "items": {"plank": 1}, "visual_state": "beds"}], "rewards": {"coins": 1}, "go": {}, "interaction": "sniff",
		},
		"cycle_a": {"id": "cycle_a", "name": "A", "requirements": {"projects": ["cycle_b"]}, "start_coins": 0, "phases": [{"id": "p", "items": {"plank": 1}}], "rewards": {}},
		"cycle_b": {"id": "cycle_b", "name": "B", "requirements": {"projects": ["cycle_a"]}, "start_coins": 0, "phases": [{"id": "p", "items": {"plank": 1}}], "rewards": {}},
		"ghost_ref": {"id": "ghost_ref", "name": "Fantasma", "requirements": {"projects": ["nao_existe"]}, "start_coins": 0, "phases": [{"id": "p", "items": {"plank": 1}}], "rewards": {}},
		"bad_item": {"id": "bad_item", "name": "Ruim", "requirements": {}, "start_coins": 0, "phases": [{"id": "p", "items": {"item_que_nao_existe": 1}}], "rewards": {}},
	}}


func _fresh() -> void:
	state.call("reset")
	state.set("unlimited_storage", false)
	state.get("inventory").counts.clear()
	state.set("coins", 1000)
	for key: String in events:
		events[key] = []


## Salva e recarrega como o disco faria (JSON transforma inteiros em decimais).
func _reload() -> void:
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)


func _snapshot() -> String:
	return JSON.stringify(state.call("to_dict"))


func _give(items: Dictionary) -> void:
	for id: String in items:
		state.get("inventory").add(id, int(items[id]))


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	database = root.get_node("Database")
	var bus: Node = root.get_node("Events")
	bus.toast_requested.connect(func(text: String) -> void: toasts.append(text))
	bus.project_phase_completed.connect(func(id: String, phase: String, index: int) -> void: events.phase.append([id, phase, index]))
	bus.project_completed.connect(func(id: String, _result: Dictionary) -> void: events.done.append(id))
	bus.project_used.connect(func(id: String, first: bool) -> void: events.used.append([id, first]))
	_empty_catalog()
	database.set("projects", _fixture())
	_catalog_problems()
	_start()
	_contributions()
	_full_flow()
	_full_storage()
	_repeated_and_completed()
	_interruptions()
	_goals_and_requirements()
	_use()
	_schema()
	print("PROJECTS TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures, " (%d verificações)" % checks)
	quit(0 if failures == 0 else 1)


# --- catálogo vazio e saves antigos -------------------------------------------------------------

func _empty_catalog() -> void:
	# Etapas 20–22: banco, jardim, piquenique e festa estão no catálogo real.
	check((database.get("projects").get("projects", {}) as Dictionary).keys() == ["park_bench", "village_garden", "park_picnic", "village_festival"], "catálogo real: banco, jardim, piquenique e festa")
	check((database.call("project_problems") as Array).is_empty(), "catálogo real não tem problemas")
	_fresh()
	check((state.get("projects").projects as Dictionary).is_empty(), "jogo novo sem projetos")
	var old: Dictionary = state.call("to_dict")
	old.erase("projects")
	state.call("from_dict", old)
	check((state.get("projects").projects as Dictionary).is_empty(), "save antigo (sem a chave) = sem projetos")
	check(state.get("projects").schema == 1, "esquema padrão 1")
	check((state.call("project_stage", "qualquer") as Dictionary).is_empty(), "consultar projeto inexistente não quebra")
	check(state.call("project_error", "qualquer") != "", "projeto inexistente não começa")
	check((state.call("to_dict") as Dictionary).has("projects"), "save novo grava a chave projects")


func _catalog_problems() -> void:
	var problems: Array = database.call("project_problems")
	check(database.call("project_issue", "test_bench") == "", "projeto de teste é válido")
	check(database.call("project_issue", "test_garden") == "", "jardim de teste é válido")
	check(str(database.call("project_issue", "cycle_a")).contains("cíclico"), "requisito cíclico é detectado (A)")
	check(str(database.call("project_issue", "cycle_b")).contains("cíclico"), "requisito cíclico é detectado (B)")
	check(str(database.call("project_issue", "ghost_ref")).contains("desconhecido"), "referência ausente é detectada")
	check(str(database.call("project_issue", "bad_item")).contains("inválido"), "material inexistente é detectado")
	check(problems.size() == 4, "quatro problemas no catálogo de teste (tem %d)" % problems.size())
	for id: String in ["cycle_a", "ghost_ref", "bad_item"]:
		_fresh()
		var before := _snapshot()
		check(state.call("start_project", id) == "Obra indisponível", "%s não começa" % id)
		check(_snapshot() == before and _coins() == 1000, "%s: recusa não muda nada" % id)
		check(not state.call("project_available", id), "%s nunca aparece para o jogador" % id)


# --- começar -------------------------------------------------------------------------------------

func _start() -> void:
	_fresh()
	state.set("coins", 149)
	var before := _snapshot()
	check(state.call("start_project", "test_bench") == "Faltam 1 moedas", "sem moedas: erro com a falta")
	check(_snapshot() == before, "sem moedas: nada muda")
	check(not state.call("project_started", "test_bench"), "sem moedas: não começou")
	state.set("coins", 400)
	check(state.call("project_error", "test_garden").begins_with("Depois de"), "requisito de projeto anterior bloqueia o jardim")
	check(not state.call("project_available", "test_garden"), "jardim ainda não disponível")
	check(state.call("start_project", "test_garden") != "", "jardim não começa antes do banco")
	check(state.call("start_project", "test_bench") == "", "começa com moedas")
	check(_coins() == 250, "taxa de 150 cobrada uma vez (tem %d)" % _coins())
	check(state.call("start_project", "test_bench") == "A obra já começou", "começar duas vezes é recusado")
	check(_coins() == 250, "segunda tentativa não cobra de novo")
	check(bool(state.get("projects").entry("test_bench").paid_start), "taxa registrada")
	_reload()
	check(state.call("project_started", "test_bench") and _coins() == 250, "começo persiste")
	check(state.call("start_project", "test_bench") != "" and _coins() == 250, "depois de recarregar, continua sem cobrar")
	# Obra sem taxa começa de graça, mas continua registrando o pagamento (zero).
	state.get("projects").projects["test_bench"]["completed"] = true
	check(state.call("start_project", "test_bench") == "Obra concluída", "concluída não recomeça")


# --- contribuições ---------------------------------------------------------------------------------

func _contributions() -> void:
	_fresh()
	check(state.call("contribute_project", "test_bench", "plank", 1) == "Comece a obra primeiro", "sem começar não entrega")
	state.call("start_project", "test_bench")
	var coins_after_start := _coins()
	_give({"plank": 3, "brick": 5})
	var before := _snapshot()
	var bad_cases := [["plank", 0], ["plank", -2], ["plank", 1.5], ["plank", 5], ["plank", 4], ["fabric", 1], ["ghost", 1], ["plank", "2"], ["plank", NAN]]
	for pair: Array in bad_cases:
		var error: String = state.call("contribute_project", "test_bench", pair[0], pair[1])
		check(error != "", "recusa %s ×%s" % [pair[0], str(pair[1])])
		check(_snapshot() == before, "recusa %s ×%s não consome nem avança" % [pair[0], str(pair[1])])
	check(state.call("contribute_project", "test_bench", "plank", 4) != "", "quatro madeiras sem ter só 3")
	check(state.call("contribute_project", "test_bench", "plank", 2.0) == "", "decimal inteiro (2.0) é aceito como 2")
	check(_inv("plank") == 1 and _stage().given.plank == 2 and _stage().remaining.plank == 2, "entrega parcial consome só o escolhido")
	check(float(_stage().progress) == 2.0 / 6.0, "progresso da fase 2/6")
	var stage_snapshot := _snapshot()
	for _i in 5:
		state.call("project_stage", "test_bench")
		state.call("project_ready", "test_bench")
		state.call("project_error", "test_bench")
		state.call("project_contribution_error", "test_bench", "plank", 1)
	check(_snapshot() == stage_snapshot, "consultar estágio/restante/erro não faz mutação")
	_reload()
	check(_inv("plank") == 1, "material aceito não reaparece no inventário após reload (tem %d)" % _inv("plank"))
	check(_stage().given.plank == 2 and _stage().index == 0, "contribuição persiste")
	check(_coins() == coins_after_start, "nenhuma taxa por fase")
	check(state.call("contribute_project", "test_bench", "plank", 3) == "Só faltam 2", "excesso depois do reload")
	check(state.call("contribute_project", "test_bench", "plank", 1) == "", "mais uma madeira")
	check(_inv("plank") == 0 and int(_stage().remaining.plank) == 1, "estoque zerou")
	check(state.call("contribute_project", "test_bench", "plank", 1) == "Falta Tábua ×1" or str(state.call("contribute_project", "test_bench", "plank", 1)).begins_with("Falta"), "sem estoque")


# --- fluxo completo --------------------------------------------------------------------------------

func _full_flow() -> void:
	_fresh()
	state.call("start_project", "test_bench")
	var after_start := _coins()
	_give({"plank": 4, "brick": 2, "fabric": 2, "braided_toy": 1, "carrot_snack": 3})
	var level_before := int(state.get("level"))
	var xp_before := int(state.get("xp"))
	var step := 0
	for pair: Array in [["plank", 4], ["brick", 1], ["brick", 1], ["fabric", 2], ["braided_toy", 1], ["carrot_snack", 2]]:
		check(state.call("contribute_project", "test_bench", pair[0], pair[1]) == "", "entrega %s ×%d" % [pair[0], pair[1]])
		_reload()
		step += 1
		check(not state.call("project_completed", "test_bench"), "passo %d: ainda não concluiu" % step)
	check(events.phase.size() == 2 and events.phase[0] == ["test_bench", "base", 0] and events.phase[1] == ["test_bench", "comfort", 1], "dois eventos de fase, uma vez cada (%s)" % str(events.phase))
	check(_stage().phase == "welcome" and _stage().index == 2, "terceira fase ativa")
	check(not state.call("project_ready", "test_bench"), "ainda não pronta")
	check(_coins() == after_start, "sem prêmio nem cobrança antes da última entrega")
	check(state.call("contribute_project", "test_bench", "carrot_snack", 1) == "", "última entrega")
	check(state.call("project_completed", "test_bench"), "última entrega conclui na hora")
	check(bool(state.get("projects").entry("test_bench").completion_rewarded), "prêmio registrado junto")
	check(_coins() == after_start + 10, "prêmio de moedas uma vez (%d)" % (_coins() - after_start))
	check(_inv("carrot") == 5, "item do prêmio entregue")
	check(int(state.get("level")) > level_before or int(state.get("xp")) == xp_before + 5, "XP do prêmio entregue")
	check(events.done == ["test_bench"], "evento de conclusão uma vez")
	check(events.phase.size() == 3 and events.phase[2] == ["test_bench", "welcome", 2], "evento da última fase")
	check(int(state.get("progress").stat("projects")) == 1, "contador projects = 1")
	check(state.get("economy").granted.has("project:test_bench"), "prêmio com id estável project:test_bench")
	check(bool(_stage().done) and float(_stage().total_progress) == 1.0, "estágio final: done, progresso 1")
	_reload()
	check(state.call("project_completed", "test_bench") and _coins() == after_start + 10 and events.done.size() == 1, "reload não premia nem emite de novo")


# --- prêmio sem espaço -------------------------------------------------------------------------------

func _full_storage() -> void:
	_fresh()
	state.get("progress").owned["farm"] = true
	var depot: String = state.call("storage_of", "carrot")
	check(depot != "" and bool(state.call("storage_active", depot)), "cenoura tem depósito limitado")
	state.call("start_project", "test_bench")
	var capacity: int = state.call("storage_capacity", depot)
	state.get("inventory").add("carrot", capacity)
	_give({"plank": 4, "brick": 2, "fabric": 2, "braided_toy": 1, "carrot_snack": 3})
	for pair: Array in [["plank", 4], ["brick", 2], ["fabric", 2], ["braided_toy", 1]]:
		state.call("contribute_project", "test_bench", pair[0], pair[1])
	var coins_before := _coins()
	check(state.call("contribute_project", "test_bench", "carrot_snack", 3) == "", "última entrega aceita com depósito cheio")
	check(state.call("project_completed", "test_bench"), "obra concluída mesmo sem espaço para o prêmio")
	check(_coins() == coins_before + 10, "moedas do prêmio entram")
	var receipt: Dictionary = state.get("economy").pending.get("project:test_bench", {})
	check(not receipt.is_empty() and int(receipt.items.get("carrot", 0)) > 0, "item que não coube vira recibo project:test_bench")
	check(_inv("carrot") == capacity, "estoque cheio não passou do teto")
	_reload()
	check(state.get("economy").pending.has("project:test_bench"), "recibo persiste")
	check(state.call("contribute_project", "test_bench", "carrot_snack", 1) == "Obra concluída", "obra concluída não é bloqueada nem reaberta")


# --- repetição --------------------------------------------------------------------------------------

func _repeated_and_completed() -> void:
	_fresh()
	state.call("start_project", "test_bench")
	_give({"plank": 9, "brick": 2, "fabric": 2, "braided_toy": 1, "carrot_snack": 4})
	for pair: Array in [["plank", 4], ["brick", 2], ["fabric", 2], ["braided_toy", 1], ["carrot_snack", 3]]:
		state.call("contribute_project", "test_bench", pair[0], pair[1])
	var coins_done := _coins()
	var snapshot := _snapshot()
	check(state.call("contribute_project", "test_bench", "carrot_snack", 1) == "Obra concluída", "última entrega repetida é recusada")
	check(state.call("contribute_project", "test_bench", "plank", 1) == "Obra concluída", "entrega em obra concluída é recusada")
	check(state.call("start_project", "test_bench") == "Obra concluída", "concluída não recomeça")
	check(state.call("complete_project", "test_bench") == "", "complete_project em obra já concluída é idempotente")
	check(_snapshot() == snapshot and _coins() == coins_done, "nada muda nem paga de novo")
	check(events.done.size() == 1, "um único evento de conclusão")
	check(state.call("complete_project", "test_garden") == "A obra ainda não está pronta", "complete_project não conclui obra que não começou")
	check(state.call("complete_project", "inexistente") != "", "complete_project de id ausente é erro")


# --- interrupções nas fronteiras de persistência -----------------------------------------------------

func _interruptions() -> void:
	# a) Última contribuição gravada, mas fase/conclusão/prêmio não: recuperado uma única vez ao carregar.
	_fresh()
	state.call("start_project", "test_bench")
	_give({"plank": 4, "brick": 2, "fabric": 2, "braided_toy": 1, "carrot_snack": 3})
	for pair: Array in [["plank", 4], ["brick", 2], ["fabric", 2], ["braided_toy", 1], ["carrot_snack", 2]]:
		state.call("contribute_project", "test_bench", pair[0], pair[1])
	var crashed: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	crashed.inventory["carrot_snack"] = 1
	crashed.projects.projects.test_bench.contributions.welcome["carrot_snack"] = 3
	var coins_start := int(crashed.coins)
	state.call("from_dict", crashed)
	check(state.call("project_completed", "test_bench"), "interrupção (a): obra concluída na recuperação")
	check(_coins() == coins_start + 10, "interrupção (a): prêmio pago uma vez")
	check(int(state.get("projects").entry("test_bench").phase_index) == 3, "interrupção (a): fase avançou")
	_reload()
	check(_coins() == coins_start + 10 and events.done.size() == 1, "interrupção (a): segundo carregamento não paga de novo")
	state.call("_recover_projects")
	check(_coins() == coins_start + 10, "interrupção (a): o tick de recuperação também é idempotente")
	# b) Concluída, mas o prêmio não foi registrado: paga uma vez.
	var half: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	half.projects.projects.test_bench["completion_rewarded"] = false
	half.economy.granted.erase("project:test_bench")
	var coins_b := int(half.coins)
	state.call("from_dict", half)
	check(_coins() == coins_b + 10 and bool(state.get("projects").entry("test_bench").completion_rewarded), "interrupção (b): prêmio pendente pago na recuperação")
	# c) Marca de prêmio feita, flag da obra não: não paga duas vezes.
	var flag: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	flag.projects.projects.test_bench["completion_rewarded"] = false
	var coins_c := int(flag.coins)
	state.call("from_dict", flag)
	check(_coins() == coins_c and bool(state.get("projects").entry("test_bench").completion_rewarded), "interrupção (c): id em economy.granted impede pagar de novo")
	# d) Contribuição consumida sem ter sido gravada é impossível: o inventário e a contribuição saem juntos no mesmo to_dict.
	_fresh()
	state.call("start_project", "test_bench")
	_give({"plank": 2})
	state.call("contribute_project", "test_bench", "plank", 2)
	var saved: Dictionary = state.call("to_dict")
	check(int(saved.inventory.get("plank", 0)) == 0 and int(saved.projects.projects.test_bench.contributions.base.plank) == 2, "interrupção (d): estoque e contribuição saem no mesmo save")


# --- objetivos, requisitos e TaskHelp ----------------------------------------------------------------

func _goals_and_requirements() -> void:
	_fresh()
	var goal := {"type": "project", "key": "test_bench", "target": 1}
	var requirement := {"projects": ["test_bench"]}
	check(int(state.call("goal_value", goal)) == 0, "objetivo de projeto começa em 0")
	check(state.call("requirement_error", requirement) == "Depois de: Banco de teste", "requisito de projeto bloqueia com o nome")
	check(state.call("requirement_error", {"projects": ["nao_existe"]}) == "Projeto desconhecido", "requisito com referência ausente nunca vale")
	check(state.call("requirement_error", {"projects": ["cycle_a"]}) != "", "requisito de projeto cíclico nunca vale")
	check(state.call("content_error", "crop", "x", {"requirements": requirement}) != "", "content_error usa o mesmo avaliador")
	var help_script: Script = load("res://scripts/ui/task_help.gd")
	var before := _snapshot()
	var help: Dictionary = help_script.call("describe", "project", "test_bench", 1)
	check(help.title == "Banco de teste" and help.target == {"world": "park", "place": "place:training"}, "TaskHelp: título e destino do projeto")
	check((help.needs as Array).any(func(n: Dictionary) -> bool: return n.kind == "coins" and int(n.amount) == 150), "TaskHelp: antes de começar pede a taxa")
	var garden: Dictionary = help_script.call("describe", "project", "test_garden", 1)
	check((garden.needs as Array).any(func(n: Dictionary) -> bool: return n.kind == "project" and n.id == "test_bench"), "TaskHelp: projeto anterior aparece como pendência")
	var places_script: Script = load("res://scripts/ui/places.gd")
	check(places_script.call("goal_target", goal) == {"world": "park", "place": "place:training"}, "Places.goal_target resolve o destino da obra")
	check(_snapshot() == before, "TaskHelp/Places não fazem mutação")
	state.call("start_project", "test_bench")
	var started: Dictionary = help_script.call("describe", "project", "test_bench", 1)
	check((started.needs as Array).any(func(n: Dictionary) -> bool: return n.kind == "item" and n.id == "plank" and int(n.amount) == 4), "TaskHelp: depois de começar pede o material da fase")
	# Concluir: objetivo reconhece uma vez e requisito passa.
	_give({"plank": 4, "brick": 2, "fabric": 2, "braided_toy": 1, "carrot_snack": 3})
	for pair: Array in [["plank", 4], ["brick", 2], ["fabric", 2], ["braided_toy", 1], ["carrot_snack", 3]]:
		state.call("contribute_project", "test_bench", pair[0], pair[1])
	check(int(state.call("goal_value", goal)) == 1, "objetivo reconhece a conclusão")
	check(state.call("requirement_error", requirement) == "", "requisito de projeto passa depois de concluído")
	check(state.call("project_available", "test_garden"), "jardim disponível depois do banco")
	check(state.call("project_error", "test_garden") == "", "jardim liberado pelo banco concluído")
	_reload()
	check(int(state.call("goal_value", goal)) == 1 and int(state.get("progress").stat("projects")) == 1, "objetivo continua 1 após recarregar, sem contar de novo")
	check(state.call("project_error", "test_garden") == "", "jardim continua liberado após recarregar")
	var done_help: Dictionary = help_script.call("describe", "project", "test_bench", 1)
	check(done_help.detail == "Obra pronta!", "TaskHelp: obra pronta")


# --- uso ---------------------------------------------------------------------------------------------

func _use() -> void:
	_fresh()
	check(state.call("use_project", "test_bench") == "A obra ainda não terminou", "só usa obra concluída")
	state.call("start_project", "test_bench")
	_give({"plank": 4, "brick": 2, "fabric": 2, "braided_toy": 1, "carrot_snack": 3})
	for pair: Array in [["plank", 4], ["brick", 2], ["fabric", 2], ["braided_toy", 1], ["carrot_snack", 3]]:
		state.call("contribute_project", "test_bench", pair[0], pair[1])
	state.get("dog").sleeping = true
	var before := _snapshot()
	check(state.call("use_project", "test_bench") == "Tiro está dormindo", "dormindo não usa")
	check(_snapshot() == before and events.used.is_empty(), "uso recusado não muda nada nem emite")
	state.get("dog").sleeping = false
	var coins_before := _coins()
	var xp_before := int(state.get("xp"))
	var affection_before: float = state.get("dog").affection
	check(state.call("use_project", "test_bench") == "", "primeira vez")
	check(events.used == [["test_bench", true]], "evento de uso com first verdadeiro")
	check(int(state.get("progress").stat("project_use:test_bench")) == 1 and bool(state.get("projects").entry("test_bench").used_once), "contador e used_once na primeira vez")
	check(state.call("use_project", "test_bench") == "", "repetição permitida")
	check(events.used.size() == 2 and events.used[1] == ["test_bench", false], "repetição emite first falso")
	check(int(state.get("progress").stat("project_use:test_bench")) == 1, "repetição não infla o contador")
	check(_coins() == coins_before and int(state.get("xp")) == xp_before and is_equal_approx(state.get("dog").affection, affection_before), "uso não dá moedas, XP nem afeto")
	_reload()
	check(bool(state.get("projects").entry("test_bench").used_once), "used_once persiste")
	state.call("use_project", "test_bench")
	check(int(state.get("progress").stat("project_use:test_bench")) == 1, "depois de recarregar, continua contando uma vez")


# --- esquema e ids preservados -------------------------------------------------------------------------

func _schema() -> void:
	_fresh()
	var data: Dictionary = state.call("to_dict")
	data.projects = {"schema": 2, "projects": {"futuro": {"started": true, "paid_start": true, "phase_index": 1, "contributions": {"fase_x": {"plank": 3}}, "extra_novo": "valor"}}}
	state.call("from_dict", data)
	var saved: Dictionary = state.call("to_dict").projects
	check(int(saved.schema) == 2, "esquema mais novo é preservado")
	check(saved.projects.has("futuro") and int(saved.projects.futuro.contributions.fase_x.plank) == 3, "projeto/fase fora do catálogo não perdem contribuição")
	check(saved.projects.futuro.get("extra_novo", "") == "valor", "campos desconhecidos sobrevivem")
	_reload()
	check(int(state.get("projects").entry("futuro").contributions.fase_x.plank) == 3, "preservado depois de outro ciclo de save")
	check(not state.call("project_completed", "futuro"), "projeto desconhecido não conclui sozinho")
	# Entrada limpa: não cria estado ao consultar.
	check(not (state.get("projects").projects as Dictionary).has("test_bench"), "consultar não cria entrada")
	var blank: Dictionary = state.get("projects").entry("test_bench")
	check(blank.keys().size() == 9 and not bool(blank.started) and int(blank.phase_index) == 0, "entrada em branco tem os 9 campos do esquema")
