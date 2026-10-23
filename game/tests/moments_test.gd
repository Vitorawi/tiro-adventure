extends SceneTree
## Regras reais, relógio local injetável, sem espera de recargas nem acesso ao save pessoal.
var state: Node
var failures := 0
var signals: Array = []

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("MOMENTS: " + message)

func count(pillar: String) -> int:
	return int(state.growth.moments.get(pillar, 0))

func need(id: String, value: float) -> void:
	state.dog.commit(state.now())
	state.dog.needs[id] = value

func fresh() -> void:
	state.set_clock(1792746000.0)
	state.reset()
	state.set_process(false)
	signals.clear()

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.set_script(load("res://tests/helpers/economy_clock.gd"))
	root.get_node("Events").moment_gained.connect(func(pillar: String, source: String) -> void: signals.append([pillar, source]))
	fresh()
	check(state.dog.needs.hunger == 40 and state.dog.needs.happiness == 40 and state.dog.needs.hygiene == 70 and state.dog.needs.energy == 80, "necessidades iniciais")
	need("happiness", 100)
	check(state.pet() == 0 and count("brave") == 0, "carinho satisfeito só reage")
	need("happiness", 50)
	state.pet()
	check(count("brave") == 0, "limiar 50 é estrito")
	for n in 3:
		need("happiness", 40)
		state.pet()
	check(count("brave") == 2 and state.progress.stat("care_useful:pet") == 3, "dois momentos por período; utilidade independe do teto")
	var saved: Dictionary = state.to_dict().duplicate(true)
	state.from_dict(saved)
	need("happiness", 40)
	state.pet()
	check(count("brave") == 2, "reload não libera teto")
	state.talk_to("lais")
	state.talk_to("lais")
	check(count("brave") == 3, "primeira conversa passa do teto e não repete")
	state.note_world_visit("house")
	state.note_world_visit("house")
	check(count("brave") == 4, "primeira visita uma vez")
	var period: String = state.moment_period()
	state.advance_clock(6 * 3600)
	need("happiness", 40)
	state.pet()
	check(state.moment_period() != period and count("brave") == 5, "novo período libera carinho")
	state.advance_clock(3 * 86400)
	state._gain_moment("smart", "test", true)
	check(state.growth.period_moments.size() == 1, "descarta períodos além do atual e anterior")
	fresh()
	need("happiness", 100)
	state.play()
	check(count("smart") == 0, "brincar satisfeito não rende")
	need("happiness", 40)
	state.play()
	check(count("smart") == 1, "brincar útil rende Esperteza")
	state._moment_source("learn_trick", "paw")
	state._moment_source("learn_trick", "paw")
	state._moment_source("dig", "lost_button")
	state._moment_source("dig", "lost_button")
	check(count("smart") == 3, "truque e achado novos uma vez fora do teto")
	fresh()
	state.inventory.add("herb_shampoo", 4)
	need("hygiene", 40)
	state.bathe(true)
	check(count("coat") == 2 and state.inventory.count("herb_shampoo") == 3, "xampu útil vale dois")
	need("hygiene", 40)
	state.bathe(true)
	check(count("coat") == 2, "xampu respeita teto")
	state.inventory.add("basic_brush")
	check(state.brush() == "" and state.brush() == "", "escovar pode repetir animação")
	check(count("coat") == 3 and state.growth.brush_days.size() == 1, "escovar duas vezes no dia vale um, fora do teto")
	state.from_dict(state.to_dict())
	state.brush()
	check(count("coat") == 3, "recibo diário sobrevive ao save")
	state.advance_clock(86400)
	state.brush()
	check(count("coat") == 4 and state.growth.brush_days.size() == 2, "dia seguinte libera escova")
	fresh()
	need("hygiene", 40)
	state.bathe()
	state.inventory.add("herb_shampoo")
	need("hygiene", 40)
	state.bathe(true)
	check(count("coat") == 2, "xampu com só uma vaga rende só um")
	# Filhotinho em uma sessão: ações reais, sem avançar relógio e sem completar requisitos por DEV.
	fresh()
	state.progress.owned.dog_bed = true
	for n in 3: state.feed("dog_food")
	state.pet()
	state.talk_to("lais")
	check(state.growth_info().ready and state.grow_error() == "", "Filhotinho alcançável na primeira sessão")
	var lifetime := count("brave")
	check(lifetime == 2 and state.growth_info().pillars.brave.have == 2 and state.growth_info().pillars.brave.need == 2, "have/need de momentos")
	check(state.grow() == "", "cresce com os requisitos reais")
	check(state.growth.phase_moments.is_empty() and count("brave") == lifetime, "nova fase zera progresso e mantém total da vida")
	need("happiness", 40)
	state.pet()
	need("happiness", 40)
	state.pet()
	check(count("brave") == lifetime + 1, "crescer não burla teto do período")
	var snapshot: Dictionary = state.to_dict().duplicate(true)
	state.growth_info()
	state.pet_growth_info()
	check(state.to_dict() == snapshot, "consultas puras")
	check(signals.size() == 3, "um evento por momento concedido")
	# Fronteiras locais, inclusive a madrugada e a virada de data.
	var midnight := int(state._local_time()) - posmod(int(state._local_time()), 86400) - int(state.zone_bias)
	var periods: Array[String] = []
	for hour in [0, 6, 12, 18, 24]: periods.append(state.moment_period(midnight + hour * 3600))
	check(periods[0].ends_with(":dawn") and periods[1].ends_with(":morning") and periods[2].ends_with(":afternoon") and periods[3].ends_with(":night") and periods[0] != periods[4], "quatro períodos no horário local")
	# Fontes pelas ações reais: voltar, cavar, fazer amizade e concluir obra.
	fresh()
	state.progress.claimed_quests.nina_meet = true
	check(state.start_walk("park_loop") == "", "começa passeio real")
	state.advance_clock(121)
	check(state.return_due_walk(false) and count("brave") == 1, "volta rende um momento")
	check(not state.return_due_walk(false) and count("brave") == 1, "mesma volta não duplica")
	fresh()
	state.progress.claimed_quests.first_harvest = true
	state.finds.worlds.farm = {"pending": 1, "dug": 1, "seed": 1, "next_at": state.now(), "spot": 0}
	var found: Dictionary = state.dig("farm")
	check(not found.is_empty() and count("smart") == 1, "achado novo pelo faro real")
	# O mesmo primeiro achado garantido continua conhecido.
	state.finds.worlds.farm.pending = 1
	state.finds.worlds.farm.dug = 1
	state.dig("farm")
	check(count("smart") == 1, "achar o mesmo item não duplica momento")
	fresh()
	state.progress.claimed_quests.nina_sewing = true
	state.inventory.add("carrot_snack", 2)
	check(state.give_friend("pipoca") == "" and count("brave") == 1, "primeiro coração pelo presente real")
	state.advance_clock(10800)
	check(state.give_friend("pipoca") == "" and count("brave") == 1, "outro presente do mesmo amigo não repete novidade")
	fresh()
	state.progress.claimed_quests.atelier_open = true
	state.coins = 150
	check(state.start_project("park_bench") == "", "começa obra real")
	var database: Node = root.get_node("Database")
	for stage: Dictionary in database.project("park_bench").phases:
		for item: String in stage.items:
			state.inventory.add(item, int(stage.items[item]))
			check(state.contribute_project("park_bench", item, int(stage.items[item])) == "", "contribui para obra real")
	check(state.project_completed("park_bench") and count("brave") == 1, "conclusão da obra rende momento sem exigir uso")
	state.complete_project("park_bench")
	state.use_project("park_bench")
	check(count("brave") == 1, "usar e reconcluir obra não repetem momento")
	print("MOMENTS TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures else 0)
