extends SceneTree
## Testa o simulador de economia (etapa 01 do plano docs/plans/economia).
##
## Cobre: relógio injetável (todos os timestamps de regra andam juntos), fidelidade do runner contra
## o GameState direto (20+ ações, conservação), agenda 1×10 min contra 3×10 min, reload no meio de
## receita, semente repetida, ação com erro e as guardas (unlimited_storage, concessão dev,
## ready_at forçado, planejador que altera inventário, ação fora da sessão).
## Não grava o save pessoal: o SaveManager é removido pelo próprio simulador.

var _failures: int = 0
var SimScript: GDScript
var sim
var gs


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)
		print("FALHOU: ", message)


func _kinds(simulation) -> Array:
	return (simulation.violations as Array).map(func(v: Dictionary) -> String: return str(v.kind))


func _new_sim(options: Dictionary = {}):
	var merged := {"profile": "reference", "seed": 1, "days": 1, "ledger": "off", "out": ""}
	merged.merge(options, true)
	var instance = SimScript.new(root, merged)
	instance.setup()
	gs = instance.gs
	return instance


func _run() -> void:
	SimScript = load("res://tests/helpers/economy_sim.gd")
	_test_clock_mapping()
	_test_static_scan()
	_test_cached_progress()
	_test_fidelity()
	_test_guards()
	_test_error_action()
	_test_classification()
	_test_reload_recipe()
	_test_seed_and_agenda()
	_test_reload_run()
	_test_growth_bot()
	print("ECONOMY SIM TEST: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(0 if _failures == 0 else 1)


# --- 1. Relógio: cada subsistema anda junto -----------------------------------------------------

func _prepare_late_fixture() -> void:
	## Fixture de regras isoladas: prepara dados com as ferramentas dev. Relatório de campanha nunca faz isto.
	gs.dev_unlock_everything()
	gs.dev_add_coins(2000)
	gs.dev_fill_needs()
	gs.inventory.counts.clear()


func _test_clock_mapping() -> void:
	sim = _new_sim()
	_prepare_late_fixture()
	gs.inventory.add("carrot", 20)
	gs.inventory.add("corn", 10)
	var t: float = gs.now()
	# plantio e rega
	check(gs.plant(0, "carrot") == "", "fixture: plantar cenoura")
	check(absf(float(gs.plots[0].ready_at) - (t + 60.0)) < 0.001, "plantio nasce de now(): ready_at = agora + 60 s")
	gs.advance_clock(20.0)
	var water_at: float = gs.now()
	check(gs.water(0) == "", "fixture: regar")
	check(absf(float(gs.plots[0].ready_at) - (water_at + (t + 60.0 - water_at) * 0.7)) < 0.001, "rega: o tempo restante cai 30% a partir do relógio")
	# fila de estação: a segunda começa quando a primeira termina
	var cook_at: float = gs.now()
	check(gs.cook("carrot_snack") == "" and gs.cook("carrot_snack") == "", "fixture: duas receitas na fila")
	var queue: Array = gs.station("stove").queue
	check(absf(float(queue[0].ready_at) - (cook_at + 60.0)) < 0.001 and absf(float(queue[1].ready_at) - (cook_at + 120.0)) < 0.001, "fila sequencial: 60 s e 120 s a partir do relógio")
	# coleta da Natureza e passeio
	check(gs.start_gathering("trees", 0, "lane") == "", "fixture: coleta no bosque")
	check(absf(float(gs.gathering_entry("trees", 0).ready_at) - (gs.now() + 120.0)) < 0.001, "coleta da Natureza usa o relógio (lane = 120 s)")
	gs.dog.sleeping = false
	check(gs.start_walk("park_loop") == "", "fixture: passeio")
	check(absf(float(gs.walk_state.current.ready_at) - (gs.now() + 120.0)) < 0.001 and int(gs.walk_state.current.seed) == int(gs.now()), "passeio: ready_at e semente vêm do relógio")
	# necessidades, recarga e desejos
	var hunger_before: float = gs.dog.get_need("hunger", gs.now())
	gs.advance_clock(3600.0)
	check(absf(gs.dog.get_need("hunger", gs.now()) - (hunger_before - 8.0)) < 0.01, "necessidades caem pelo relógio (8 por hora)")
	gs.return_due_walk()  # o tick de 1 s do jogo real (bg_tick no simulador)
	check(gs.walk_ready() and gs.plot_status(0) == "ready" and gs.station("stove").ready_count(gs.now()) == 2 and gs.gathering_ready_count("trees") == 1, "uma hora depois tudo o que estava em andamento ficou pronto")
	check(gs.collect_walk().size() > 0, "passeio pronto pode ser recolhido")
	check(gs.fulfill_order("vegetables") == "", "fixture: pedido")
	check(gs.progress.cooldown_left("order:vegetables", gs.now()) == 60, "recarga do pedido = agora + 60 s")
	gs.advance_clock(61.0)
	check(gs.order_error("vegetables") == "" or gs.order_error("vegetables").begins_with("Falt"), "a recarga termina quando o relógio passa")
	gs.update_wishes()
	# faro e janela de amigos, dia e semana, hora local
	gs.update_finds()
	var world: String = str(gs.finds.worlds.keys()[0])
	gs.finds.worlds[world].pending = 1
	var dig_at: float = gs.now()
	check(gs.dig_error(world) == "" and not gs.dig(world).is_empty(), "fixture: cavar o montinho")
	var interval: float = float(root.get_node("Database").finds.worlds[world].interval)
	check(absf(float(gs.finds.worlds[world].next_at) - (dig_at + interval)) < 0.001, "faro: próximo montinho = relógio + intervalo")
	gs.advance_clock(interval + 1.0)
	gs.update_finds()
	check(int(gs.finds.worlds[world].pending) == 1, "faro: o montinho volta quando o relógio passa do intervalo")
	var window_before: String = gs.friend_window()
	gs.advance_clock(3.0 * 3600.0)
	check(gs.friend_window() != window_before, "janela de amigos muda a cada 3 h do relógio")
	var day_before: String = gs.routine_period("daily")
	gs.advance_clock(86400.0)
	check(gs.routine_period("daily") != day_before, "período das diárias muda no dia seguinte")
	var week_before: String = gs.routine_period("weekly")
	gs.advance_clock(7.0 * 86400.0)
	check(gs.routine_period("weekly") != week_before, "período das semanais muda na semana seguinte")
	var local_day0: float = gs.sim_time - fposmod(gs.sim_time + float(gs.zone_bias), 86400.0)
	gs.set_clock(local_day0 + 16.9 * 3600.0)
	check(gs.walk_hours_error("sunset_walk") != "", "Pôr do sol fechado às 16h54 locais")
	gs.set_clock(local_day0 + 17.2 * 3600.0)
	check(gs.walk_hours_error("sunset_walk") == "", "Pôr do sol aberto às 17h12 locais")
	check(gs.get_script().resource_path.ends_with("economy_clock.gd"), "o GameState usa o relógio de simulação")


# --- 2. Varredura: nenhuma regra lê o relógio do sistema fora de now()/_local_time -------------------

func _test_static_scan() -> void:
	var forbidden := ["Time.get_ticks", "Time.get_unix_time_from_system", "Time.get_datetime_dict_from_system", "Time.get_time_zone_from_system", "OS.get_unix_time"]
	var allowed := {
		"res://autoload/game_state.gd": ["Time.get_unix_time_from_system", "Time.get_time_zone_from_system"],
		"res://autoload/save_manager.gd": ["Time.get_unix_time_from_system"],
	}
	var scanned := 0
	for folder: String in ["res://autoload", "res://scripts/state", "res://scripts/util"]:
		for file_name in DirAccess.get_files_at(folder):
			if not file_name.ends_with(".gd"):
				continue
			var path := folder.path_join(file_name)
			var text := FileAccess.get_file_as_string(path)
			scanned += 1
			for needle: String in forbidden:
				if needle in text and not needle in allowed.get(path, []):
					check(false, "%s lê o relógio do sistema (%s) fora do GameState.now()" % [path, needle])
	check(scanned >= 15, "varredura estática leu os arquivos de regra (%d)" % scanned)
	var state_text := FileAccess.get_file_as_string("res://autoload/game_state.gd")
	check(state_text.count("Time.get_unix_time_from_system") == 1, "GameState lê o relógio real em um único lugar (now)")
	check(state_text.count("Time.get_time_zone_from_system") == 1, "GameState lê o fuso em um único lugar (_local_time)")


# --- 2b. A memória de consultas puras não muda nenhum resultado ------------------------------------------

func _test_cached_progress() -> void:
	sim = _new_sim()
	var plain_script: GDScript = load("res://scripts/state/progression_state.gd")
	check(gs.progress.get_script().resource_path.ends_with("economy_progress.gd"), "simulador usa a progressão com memória")
	var chapters: int = root.get_node("Database").progression.chapters.size()
	for index in range(0, chapters + 1):
		gs.dev_jump_to_chapter(index)
		var plain = plain_script.new()
		plain.from_dict(gs.progress.to_dict())
		check(plain.chapter_index() == gs.progress.chapter_index(), "chapter_index igual ao da classe original (capítulos feitos: %d)" % index)
		check(plain.current_main_quest() == gs.progress.current_main_quest(), "missão principal atual igual (capítulos feitos: %d)" % index)
		check(plain.active_steps() == gs.progress.active_steps(), "passos ativos iguais (capítulos feitos: %d)" % index)
		for chapter in range(1, chapters + 1):
			check(plain.main_quests(chapter) == gs.progress.main_quests(chapter), "main_quests(%d) igual" % chapter)


# --- 3. Fidelidade: runner × GameState direto ------------------------------------------------------

func _fixture_dict() -> Dictionary:
	gs.dev_jump_to_chapter(5)
	gs.dev_grant_upgrade("stove_queue_2")
	gs.dev_grant_upgrade("silo")  # etapa 05: o cesto provisório (16) não comporta o roteiro; o silo (32) sim
	gs.dev_add_coins(300)
	gs.dev_fill_needs()
	gs.inventory.counts.clear()
	gs.inventory.add("carrot", 9)
	gs.inventory.add("corn", 4)
	gs.inventory.add("carrot_snack", 22)
	gs.inventory.add("wood", 6)
	return JSON.parse_string(JSON.stringify(gs.to_dict()))


## Sequência de 24 ações. Cada item: {wait: segundos de espera antes, action: dicionário do runner}.
func _sequence() -> Array[Dictionary]:
	var a := func(kind: String, args: Dictionary, ctx: String = "x") -> Dictionary:
		return {"kind": kind, "args": args, "ctx": ctx, "why": "teste", "goal": ""}
	var steps: Array[Dictionary] = []
	steps.append({"wait": 0, "action": a.call("plant_many", {"plots": [0, 1, 2], "crop": "carrot"}, "farm")})
	steps.append({"wait": 0, "action": a.call("water_many", {"plots": [0, 1, 2]}, "farm")})
	steps.append({"wait": 45, "action": a.call("harvest_many", {"plots": [0, 1, 2]}, "farm")})
	steps.append({"wait": 0, "action": a.call("sell", {"item": "carrot", "qty": 3}, "market")})
	for i in 4:
		steps.append({"wait": 0, "action": a.call("cook", {"recipe": "carrot_snack"}, "station:stove")})
	steps.append({"wait": 70, "action": a.call("collect_station", {"station": "stove"}, "station:stove")})
	steps.append({"wait": 60, "action": a.call("collect_station", {"station": "stove"}, "station:stove")})
	steps.append({"wait": 60, "action": a.call("collect_station", {"station": "stove"}, "station:stove")})
	steps.append({"wait": 0, "action": a.call("sell", {"item": "carrot_snack", "qty": 5}, "market")})
	steps.append({"wait": 0, "action": a.call("collect_station", {"station": "stove"}, "station:stove")})
	steps.append({"wait": 0, "action": a.call("feed", {"item": "carrot_snack"}, "pet")})
	steps.append({"wait": 0, "action": a.call("fulfill_order", {"id": "vegetables"}, "orders")})
	steps.append({"wait": 0, "action": a.call("buy_upgrade", {"id": "cave_open"}, "place:nature/rocks")})
	steps.append({"wait": 0, "action": a.call("claim_quest", {"id": "main_5_pickaxe"}, "tasks")})
	steps.append({"wait": 0, "action": a.call("start_gathering", {"site": "rocks", "index": 0, "route": "quarry"}, "nature:rocks")})
	steps.append({"wait": 181, "action": a.call("collect_gathering", {"site": "rocks", "index": 0}, "nature:rocks")})
	steps.append({"wait": 0, "action": a.call("claim_quest", {"id": "stone_path"}, "tasks")})
	steps.append({"wait": 0, "action": a.call("talk", {"npc": "guide"}, "npc:guide")})
	steps.append({"wait": 0, "action": a.call("bathe", {}, "pet")})
	steps.append({"wait": 0, "action": a.call("play", {}, "pet")})
	steps.append({"wait": 0, "action": a.call("sleep", {"value": true}, "pet")})
	return steps


func _tick() -> void:
	## O Timer de 1 s do GameState (_ready): desejos, janela de amigos e faro.
	var changed_wishes: bool = gs.update_wishes()
	if gs.sync_friend_window() or gs.update_finds() or changed_wishes:
		gs.call("_changed")


func _direct(action: Dictionary) -> String:
	## Execução direta, escrita de forma independente do runner.
	var args: Dictionary = action.args
	match str(action.kind):
		"plant_many":
			var err := ""
			for i: int in args.plots:
				var e: String = gs.plant(i, str(args.crop))
				err = err if err != "" else e
			return err
		"water_many":
			for i: int in args.plots:
				gs.water(i)
			return ""
		"harvest_many":
			var got := 0
			for i: int in args.plots:
				got += gs.harvest(i).size()
			return "" if got > 0 else "Colheita recusada"
		"sell":
			var worlds: Dictionary = root.get_node("Database").get("worlds")
			var sale_world := str(args.get("world", "village" if gs.requirement_error(worlds.village.get("requirements", {})) == "" else "farm"))
			return gs.sell(str(args.item), mini(int(args.qty), gs.inventory.count(str(args.item))), sale_world)
		"cook":
			return gs.cook(str(args.recipe))
		"collect_station":
			return "" if gs.collect(str(args.station)).size() > 0 else "Nada recolhido"
		"feed":
			return "" if gs.feed(str(args.item)) else "Não aceitou a comida"
		"fulfill_order":
			return gs.fulfill_order(str(args.id))
		"buy_upgrade":
			return gs.buy_upgrade(str(args.id))
		"claim_quest":
			return gs.claim_quest(str(args.id))
		"start_gathering":
			return gs.start_gathering(str(args.site), int(args.index), str(args.route))
		"collect_gathering":
			return gs.collect_gathering(str(args.site), int(args.index))
		"talk":
			gs.talk_to(str(args.npc))
			return ""
		"bathe":
			gs.bathe()
			return ""
		"play":
			return "" if gs.play() else "Não pôde brincar"
		"sleep":
			gs.set_sleeping(bool(args.value))
			return ""
	return "ação desconhecida"


func _test_fidelity() -> void:
	sim = _new_sim()
	var fixture := _fixture_dict()
	# Isola a aritm?tica da cadeia; o b?nus animado tem teste pr?prio.
	fixture.dog.needs.happiness = 10.0
	var start_time: float = gs.now()
	# O runner e a execução direta partem do MESMO estado recarregado (from_dict) no mesmo instante.
	gs.from_dict(fixture)
	sim._snapshot_timers_initial()
	var steps := _sequence()
	check(steps.size() >= 20, "sequência tem 20+ ações (%d)" % steps.size())
	sim.in_session = true
	sim._digest_after = sim.digest()
	var via_runner: Array[Dictionary] = []
	for step: Dictionary in steps:
		gs.advance_clock(float(step.wait))
		sim.bg_tick()
		sim.check_between()
		var cost: float = sim.action_cost(step.action)
		sim.active_seconds += cost
		var coins_before: int = gs.coins
		sim.perform(step.action, cost)
		via_runner.append({"cost": cost, "dict": JSON.stringify(gs.to_dict(), "", true), "coins": gs.coins, "delta": gs.coins - coins_before, "failed": sim.failures.size(), "inv": gs.inventory.counts.duplicate(), "queue": gs.station("stove").queue.size()})
	var violations_runner: Array = _kinds(sim)
	check(violations_runner.is_empty(), "runner: nenhuma violação de guarda/conservação (%s)" % str(violations_runner))
	var end_time: float = gs.now()
	# marcos calculáveis à mão
	# Conferência manual (calculada à mão a partir dos JSON): entradas, saídas, tempos e moedas.
	var inv: Array = via_runner.map(func(v: Dictionary) -> Dictionary: return v.inv)
	check(via_runner[2].delta == 0 and inv[2].get("carrot") == 15, "colher 3 canteiros: +2 cenouras cada (9 → 15) e nenhuma moeda (etapa 09)")
	check(via_runner[3].delta == 9 and inv[3].get("carrot") == 12, "vender 3 cenouras a 3 moedas: +9 e 15 → 12")
	check(inv[7].get("carrot") == 6 and via_runner[7].queue == 3, "três receitas gastam 2 cenouras cada (12 → 6) e a quarta não entra (fila de 3)")
	check(inv[8].get("carrot_snack") == 23 and via_runner[8].queue == 2, "1º petisco depois de 60 s: 22 → 23, fila 3 → 2")
	check(inv[9].get("carrot_snack") == 24 and via_runner[9].queue == 1, "2º petisco: geladeira exatamente cheia (24/24)")
	check(inv[10].get("carrot_snack") == 24 and via_runner[10].queue == 1, "3º petisco com a geladeira cheia: nada recebido e o lote continua na fila")
	check(inv[11].get("carrot_snack") == 19, "vender 5 petiscos libera espaço (24 → 19)")
	check(inv[12].get("carrot_snack") == 20 and via_runner[12].queue == 0, "agora o 3º petisco cabe (19 → 20), fila vazia")
	check(inv[14].get("carrot") == 2 and via_runner[14].delta >= 18, "pedido da vizinhança: 4 cenouras viram +18 moedas (6 → 2)")
	check(via_runner[15].delta == -80 or via_runner[15].delta < 0, "comprar a Caverna custa 80 moedas")
	var failed_kinds := (sim.failures as Array).map(func(f: Dictionary) -> String: return str(f.kind) + ":" + str(f.err))
	check("cook:Fila cheia" in failed_kinds, "quarta receita no fogão: Fila cheia (%s)" % str(failed_kinds))
	check("collect_station:Nada recolhido" in failed_kinds, "recebimento com a geladeira cheia é recusado, sem perder o lote (%s)" % str(failed_kinds))
	# réplica direta com os mesmos custos de tempo, partindo do mesmo fixture
	check(absf(end_time - _total_time(steps, via_runner) - start_time) < 0.001, "o tempo cobrado pelo runner é exatamente toques + esperas")
	var direct: Array[Dictionary] = []
	gs.set_clock(start_time)
	gs.from_dict(fixture)
	for i in steps.size():
		gs.advance_clock(float(steps[i].wait))
		_tick()
		gs.advance_clock(float(via_runner[i].cost))
		_tick()
		var coins_before2: int = gs.coins
		_direct(steps[i].action)
		direct.append({"dict": JSON.stringify(gs.to_dict(), "", true), "delta": gs.coins - coins_before2})
	var same := 0
	for i in steps.size():
		var equal: bool = via_runner[i].dict == direct[i].dict
		same += 1 if equal else 0
		if not equal:
			var diffs: Array = []
			_diff(JSON.parse_string(via_runner[i].dict), JSON.parse_string(direct[i].dict), "", diffs)
			check(false, "ação %d (%s): estado do runner difere do GameState direto: %s" % [i + 1, steps[i].action.kind, str(diffs)])
	check(same == steps.size(), "as %d ações do runner deixam exatamente o mesmo estado que a execução direta" % steps.size())


func _diff(a: Variant, b: Variant, path: String, out: Array) -> void:
	if out.size() >= 8:
		return
	if typeof(a) == TYPE_DICTIONARY and typeof(b) == TYPE_DICTIONARY:
		for key in a:
			if not b.has(key):
				out.append("%s/%s só no runner" % [path, key])
			else:
				_diff(a[key], b[key], path + "/" + str(key), out)
		for key in b:
			if not a.has(key):
				out.append("%s/%s só no direto" % [path, key])
	elif typeof(a) == TYPE_ARRAY and typeof(b) == TYPE_ARRAY:
		if a.size() != b.size():
			out.append("%s: tamanhos %d × %d" % [path, a.size(), b.size()])
		else:
			for i in a.size():
				_diff(a[i], b[i], "%s[%d]" % [path, i], out)
	elif a != b:
		out.append("%s: %s × %s" % [path, str(a), str(b)])


func _total_time(steps: Array[Dictionary], via_runner: Array[Dictionary]) -> float:
	var total := 0.0
	for i in steps.size():
		total += float(steps[i].wait) + float(via_runner[i].cost)
	return total


# --- 4. Guardas ---------------------------------------------------------------------------------------

func _test_guards() -> void:
	# unlimited_storage
	sim = _new_sim()
	gs.unlimited_storage = true
	sim.check_static_guards("teste")
	check("unlimited_storage" in _kinds(sim), "guarda: unlimited_storage ligado é detectado")
	gs.unlimited_storage = false
	# concessão dev entre ações (moedas e itens)
	sim = _new_sim()
	sim.in_session = true
	sim._digest_after = sim.digest()
	gs.dev_add_coins(100)
	sim.check_between()
	check("mutacao_fora_de_acao" in _kinds(sim), "guarda: concessão dev de moedas é detectada")
	sim.violations.clear()
	gs.dev_add_items(3, "crop")
	sim.check_between()
	check("mutacao_fora_de_acao" in _kinds(sim), "guarda: concessão dev de itens é detectada")
	# ready_at forçado
	sim = _new_sim()
	sim.in_session = true
	_prepare_late_fixture()
	sim._digest_after = sim.digest()
	gs.advance_clock(10.0)
	var plant_action := {"kind": "plant_many", "args": {"plots": [0], "crop": "carrot"}, "ctx": "farm", "why": "teste", "goal": ""}
	sim.perform(plant_action, 3.0)
	check(_kinds(sim).is_empty(), "plantio legítimo não é violação")
	gs.plots[0]["ready_at"] = 1.0
	sim._digest_after = sim.digest()
	sim.check_between()
	check("ready_at_forcado" in _kinds(sim), "guarda: ready_at forçado é detectado")
	# ação fora da lista (dev_*) e fora da sessão
	sim = _new_sim()
	sim.in_session = true
	sim.perform({"kind": "dev_add_coins", "args": {"amount": 50}, "ctx": "x", "why": "teste", "goal": ""}, 3.0)
	check("acao_nao_permitida" in _kinds(sim) and gs.coins == 10, "guarda: dev_* é recusado e não executa")
	sim = _new_sim()
	sim.in_session = false
	sim.perform({"kind": "bathe", "args": {}, "ctx": "x", "why": "teste", "goal": ""}, 3.0)
	check("acao_fora_da_sessao" in _kinds(sim), "guarda: nenhuma ação durante a ausência")
	# planejador que mexe no inventário durante plan()
	sim = SimScript.new(root, {"profile": "reference", "seed": 1, "days": 1, "ledger": "off", "out": "", "bot_script": "res://tests/helpers/economy_bad_bot.gd", "max_actions": 6})
	var summary: Dictionary = sim.run()
	gs = sim.gs
	check("planejador_alterou_estado" in _kinds(sim), "guarda: planejador que altera inventário é detectado")
	check(int(summary.guards.violations) > 0, "o resumo conta as violações")
	# o runner normal não pode ter violações
	sim = _new_sim({"max_actions": 60})
	var clean: Dictionary = sim.run()
	check(int(clean.guards.violations) == 0, "execução normal de 60 ações sem violação (%s)" % str(clean.guards.details))
	check(not bool(clean.guards.unlimited_storage), "o resumo registra unlimited_storage desligado")


# --- 5. Erro de ação ------------------------------------------------------------------------------------

func _test_error_action() -> void:
	sim = _new_sim()
	sim.in_session = true
	sim._digest_after = sim.digest()
	var before: String = sim.digest()
	var active_before: float = sim.active_seconds
	var bad := {"kind": "cook", "args": {"recipe": "vegetable_soup"}, "ctx": "station:stove", "why": "teste", "goal": ""}
	var cost: float = sim.action_cost(bad)
	sim.active_seconds += cost
	sim.perform(bad, cost)
	check(sim.failures.size() == 1 and str(sim.failures[0].err) != "", "ação com erro é registrada com o motivo (%s)" % str(sim.failures))
	check(sim.digest() == before, "ação com erro não altera o estado")
	check(sim.active_seconds - active_before == cost, "o toque do erro custou tempo ativo")
	check(sim.violations.is_empty(), "erro de ação não é violação")
	check(sim.bot.is_avoided("cookvegetable_soup"), "o jogador simulado evita repetir a ação que falhou")


func _test_classification() -> void:
	sim = _new_sim()
	check(str(sim._classify_block("no_source:iron_band")).begins_with("jogo:"), "item sem fonte = bloqueio do jogo")
	check(str(sim._classify_block("luck:walk:ribbon")).begins_with("jogo:"), "dependência de sorte = bloqueio do jogo")
	check(str(sim._classify_block("no_path:plank")).begins_with("politica:"), "sem caminho achado = falha de política")
	check(str(sim._classify_block("depth")).begins_with("politica:"), "recursão profunda = falha de política")


# --- 6. Reload no meio da receita ------------------------------------------------------------------------

func _test_reload_recipe() -> void:
	sim = _new_sim()
	gs.dev_jump_to_chapter(5)
	gs.dev_grant_upgrade("stove_queue")
	gs.dev_add_coins(300)
	gs.inventory.counts.clear()
	gs.inventory.add("carrot", 6)
	check(gs.cook("carrot_snack") == "" and gs.cook("carrot_snack") == "", "fixture: duas receitas")
	gs.advance_clock(30.0)
	var queue_before: Array = JSON.parse_string(JSON.stringify(gs.station("stove").queue))
	gs.from_dict(JSON.parse_string(JSON.stringify(gs.to_dict())))
	var queue_after: Array = JSON.parse_string(JSON.stringify(gs.station("stove").queue))
	check(queue_before == queue_after, "reload no meio da receita preserva a fila e os horários")
	check(gs.inventory.count("carrot") == 2 and gs.inventory.count("carrot_snack") == 0, "ingredientes continuam gastos e nada foi entregue antes da hora")
	gs.advance_clock(31.0)
	check(gs.collect("stove").get("carrot_snack", 0) == 1, "primeira receita sai no horário depois do reload")
	gs.from_dict(JSON.parse_string(JSON.stringify(gs.to_dict())))
	gs.advance_clock(60.0)
	check(gs.collect("stove").get("carrot_snack", 0) == 1, "segunda receita sai depois de outro reload (sem duplicar)")
	check(gs.collect("stove").is_empty(), "nada a mais para recolher")


# --- 7. Semente repetida e agenda ----------------------------------------------------------------------------

func _ledger_hash(folder: String) -> String:
	return FileAccess.get_file_as_string(folder.path_join("ledger.jsonl")).md5_text()


func _test_seed_and_agenda() -> void:
	var base := ProjectSettings.globalize_path("res://../build/economy/etapa_01/_teste")
	var a = SimScript.new(root, {"profile": "reference", "seed": 4, "days": 1, "ledger": "full", "out": base.path_join("a"), "max_actions": 120})
	var sa: Dictionary = a.run()
	var b = SimScript.new(root, {"profile": "reference", "seed": 4, "days": 1, "ledger": "full", "out": base.path_join("b"), "max_actions": 120})
	var sb: Dictionary = b.run()
	var c = SimScript.new(root, {"profile": "reference", "seed": 5, "days": 1, "ledger": "full", "out": base.path_join("c"), "max_actions": 120})
	var sc: Dictionary = c.run()
	check(_ledger_hash(base.path_join("a")) == _ledger_hash(base.path_join("b")), "mesma semente e agenda: ledger idêntico byte a byte")
	check(JSON.stringify(sa.end) == JSON.stringify(sb.end), "mesma semente: mesmo resultado final")
	check(_ledger_hash(base.path_join("a")) != _ledger_hash(base.path_join("c")), "outra semente muda o ledger")
	check(sc.guards.violations == 0 and sa.guards.violations == 0, "execuções sem violações")
	# Compacto também precisa permitir auditoria de cada ação, sem inferir saldo/fila.
	var compact = SimScript.new(root, {"profile": "reference", "seed": 4, "days": 1, "ledger": "compact", "out": base.path_join("compact"), "max_actions": 5})
	compact.run()
	var log_file := FileAccess.open(base.path_join("compact/ledger.jsonl"), FileAccess.READ)
	var checked_action := false
	while not log_file.eof_reached():
		var row: Variant = JSON.parse_string(log_file.get_line())
		if row is Dictionary and row.get("ev") == "act":
			check(row.has("before") and row.has("after") and row.has("q") and row.has("dep"), "ledger compacto preserva saldo antes/depois, fila e depósitos")
			checked_action = true
			break
	log_file.close()
	check(checked_action, "ledger compacto contém uma ação auditável")
	# agenda: 1×10 min por dia (leve) contra 3×10 min por dia (referência)
	var light = SimScript.new(root, {"profile": "light", "seed": 1, "days": 2, "ledger": "off", "out": ""})
	var s1: Dictionary = light.run()
	var full = SimScript.new(root, {"profile": "reference", "seed": 1, "days": 2, "ledger": "off", "out": ""})
	var s3: Dictionary = full.run()
	check(int(s3.time.sessions) > int(s1.time.sessions), "3×10 min tem mais sessões que 1×10 min (%d × %d)" % [s3.time.sessions, s1.time.sessions])
	check(float(s3.time.active_min) > float(s1.time.active_min), "3×10 min age por mais tempo ativo")
	check(int(s3.end.quests) >= int(s1.end.quests), "3×10 min não avança menos que 1×10 min na história")
	for entry: Dictionary in s1.sessions + s3.sessions:
		check(float(entry.spent) <= float(entry.budget) + 0.01, "sessão %d não excede o orçamento (%s de %s)" % [entry.n, entry.spent, entry.budget])
	var budget1 := 0.0
	for entry: Dictionary in s1.sessions:
		budget1 += float(entry.budget)
	check(float(s1.time.active_min) * 60.0 <= budget1 + 0.01, "tempo ativo do perfil leve cabe na soma das sessões")
	check(s1.guards.violations == 0 and s3.guards.violations == 0, "agendas sem violações")


func _test_reload_run() -> void:
	var plain = SimScript.new(root, {"profile": "light", "seed": 2, "days": 3, "ledger": "off", "out": "", "reload": "none"})
	var s_plain: Dictionary = plain.run()
	var reloaded = SimScript.new(root, {"profile": "light", "seed": 2, "days": 3, "ledger": "off", "out": "", "reload": "session"})
	var s_reload: Dictionary = reloaded.run()
	check(JSON.stringify(s_plain.end) == JSON.stringify(s_reload.end), "salvar/recarregar a cada sessão não muda o resultado (%s × %s)" % [JSON.stringify(s_plain.end), JSON.stringify(s_reload.end)])
	check(s_reload.guards.violations == 0, "execução com reload sem violações")


# --- 9. O robô sabe crescer e entregar itens-chave (etapa 11 do plano Tiro) -----------------------------

## Roda o planejador do robô como o runner: cada ação passa por `perform` (guardas e conservação).
## Sem ação, o tempo anda (o Tiro suja, a recarga acaba). Devolve os tipos de ação executados.
func _bot_until(done: Callable, max_steps: int = 60, idle_seconds: float = 3600.0) -> Array[String]:
	var kinds: Array[String] = []
	sim.in_session = true
	sim._digest_after = sim.digest()
	for _i in max_steps:
		if done.call():
			break
		var plan: Dictionary = sim.bot.plan(900.0, 7200.0)
		if plan.is_empty() or str(plan.get("action", {}).get("kind", "")) == "":
			gs.advance_clock(idle_seconds)
			sim.bg_tick()
			sim._digest_after = sim.digest()
			continue
		var action: Dictionary = plan.action
		var cost: float = sim.action_cost(action)
		sim.active_seconds += cost
		sim.perform(action, cost)
		kinds.append(str(action.kind))
	return kinds


## Estado da história logo antes da missão de crescer (a história é o foco do robô).
func _growth_fixture(phase: String, previous_quest: String) -> void:
	sim = _new_sim()
	gs.dev_complete_quest(previous_quest)
	gs.dev_fill_needs()
	gs.dev_add_coins(500)
	gs.inventory.counts.clear()
	gs.growth.phase = phase
	gs.growth.phase_since = gs.now()
	gs.growth.phase_stats = gs.progress.stats.duplicate(true)


func _top_up_moments() -> void:
	for id: String in ["coat", "smart", "brave"]:
		for _i in gs.growth.phase_need(id): gs.dev_add_moment(id)


func _test_growth_bot() -> void:
	# Dentinhos: a vovó faz a argolinha, o robô dá a cenoura gelada três vezes, entrega a argolinha e cresce.
	_growth_fixture("puppy", "lais_stew")
	check(gs.progress.current_main_quest() == "teeth_3_ring", "fixture: capítulo 3 espera a argolinha")
	gs.inventory.add("carrot", 3)
	gs.inventory.add("potato", 1)
	gs.inventory.add("frozen_carrot", 3)
	_top_up_moments()
	var kinds := _bot_until(func() -> bool: return gs.growth.phase == "teething")
	check(gs.growth.phase == "teething", "o robô fez o Tiro crescer para Dentinhos (ações: %s)" % str(kinds))
	check(kinds.count("feed") >= 3 and "deliver_growth" in kinds and "grow" in kinds, "alimentou, entregou o item-chave e apertou Crescer (%s)" % str(kinds))
	check(gs.progress.claimed_quests.has("bloblo_chew_ring") and gs.growth.delivered.teething.get("chew_ring", 0) == 1, "a argolinha veio da missão da vovó e foi entregue")
	check(sim.violations.is_empty(), "Dentinhos sem violações de guarda/conservação (%s)" % str(sim.violations))
	# O robô também pega a missão de crescer (a história avança).
	_bot_until(func() -> bool: return gs.progress.claimed_quests.has("growth_3_teething"), 20)
	check(gs.progress.claimed_quests.has("growth_3_teething"), "pegou a missão 'As orelhinhas subiram!'")
	# Mocinho: refeição da fase, escova entregue e dois banhos com xampu (espera o Tiro sujar entre um e outro).
	_growth_fixture("explorer", "young_9_milk")
	check(gs.progress.current_main_quest() == "growth_9_young", "fixture: a história espera o Mocinho")
	_top_up_moments()
	gs.inventory.add("milk_porridge", 3)
	gs.inventory.add("soft_brush", 1)
	gs.inventory.add("herb_shampoo", 2)
	gs.dog.needs["hygiene"] = 30.0
	gs.dog.updated_at = gs.now()
	var kinds2 := _bot_until(func() -> bool: return gs.growth.phase == "young", 80)
	check(gs.growth.phase == "young", "o robô fez o Tiro crescer para Mocinho (ações: %s)" % str(kinds2))
	check(gs.progress.stat("shampoo_bath") >= 1 and gs.inventory.count("herb_shampoo") == 1, "banho útil gastou um xampu; a fase não exige dois banhos")
	check(kinds2.count("feed") >= 3 and "deliver_growth" in kinds2, "refeição de mocinho e escova entregue")
	check(sim.violations.is_empty(), "Mocinho sem violações (%s)" % str(sim.violations))
	# Azul e Dourado: medalhinha entregue, três refeições e o lacinho já feito.
	_growth_fixture("young", "community_12_memory")
	check(gs.progress.current_main_quest() == "growth_12_adult", "fixture: a história espera o Azul e Dourado")
	_top_up_moments()
	gs.inventory.add("courage_medal", 1)
	gs.inventory.add(gs.favorite_food(), 3)
	gs.progress.collection["topknot_bow"] = true
	var kinds3 := _bot_until(func() -> bool: return gs.growth.phase == "adult", 30)
	check(gs.growth.phase == "adult", "o robô fez o Tiro crescer para Azul e Dourado (ações: %s)" % str(kinds3))
	check(sim.violations.is_empty(), "Azul e Dourado sem violações (%s)" % str(sim.violations))
	# Do zero: em dois dias o robô cuida do Tiro, pega a missão e passa do Filhotinho (sem atalhos).
	var run = SimScript.new(root, {"profile": "reference", "seed": 1, "days": 2, "ledger": "off", "out": ""})
	run.setup()
	run.run()
	check(run.gs.growth.phase_index() >= run.gs.growth.phase_index("puppy"), "em dois dias o robô já cresceu o Tiro (fase %s)" % run.gs.growth.phase)
	check(run.gs.progress.claimed_quests.has("growth_1_puppy") and run.gs.progress.chapter_index() >= 2, "a missão de crescer abriu o capítulo 2")
	check(run.violations.is_empty() and int(run.action_counts.get("grow", 0)) >= 1, "campanha de dois dias com 'grow' e sem violações (%s)" % str(run.action_counts.get("grow", 0)))
