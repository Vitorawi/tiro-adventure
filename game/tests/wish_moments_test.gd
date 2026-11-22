extends SceneTree
## Desejos com propósito (etapa 02): um por período, escolha pela fase e pelo que falta, prêmio = momento.
## Regras reais e relógio local injetável; sem acesso ao save pessoal.
var state: Node
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("WISH_MOMENTS: " + message)

func count(pillar: String) -> int:
	return int(state.growth.moments.get(pillar, 0))

func need(id: String, value: float) -> void:
	state.dog.commit(state.now())
	state.dog.needs[id] = value

func all_needs(value: float) -> void:
	for id: String in ["hunger", "happiness", "hygiene", "energy"]:
		need(id, value)

func to_period(id: String) -> void:
	var guard := 0
	while not state.moment_period().ends_with(":" + id) and guard < 100:
		state.advance_clock(3600)
		guard += 1

func fresh(phase: String = "puppy") -> void:
	state.set_clock(1792746000.0)
	state.reset()
	state.set_process(false)
	state.growth.phase = phase
	state.progress.claimed_quests["lais_bed"] = true
	to_period("morning")
	all_needs(100.0)

## Cria o desejo do período já com as necessidades como estão.
func wish_now() -> String:
	state.update_wishes()
	return state.wish_id()

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.set_script(load("res://tests/helpers/economy_clock.gd"))
	# Sem caminha não há desejo.
	state.set_clock(1792746000.0)
	state.reset()
	state.set_process(false)
	check(not state.update_wishes() and state.wish_id() == "", "nada antes da caminha")
	# Primeiro desejo: carinho, logo depois da caminha.
	fresh()
	all_needs(100.0)
	check(wish_now() == "pet" and state.wish_pillar() == "brave", "primeiro desejo é carinho (Coragem)")
	check(state.wish_error() != "" and state.fulfillable_wish_count() == 0, "carinho ainda por fazer")
	# Atender dá +1 momento mesmo com o teto do período cheio.
	need("happiness", 40)
	state.pet()
	need("happiness", 40)
	state.pet()
	need("happiness", 40)
	state.pet()
	check(count("brave") == 2 and state.wish_error() == "", "teto do período: 2 momentos, desejo atendível")
	check(state.fulfill_wish() == "" and count("brave") == 3, "atender dá +1 fora do teto")
	check(state.wish_id() == "" and state.progress.stat("wish") == 1, "sem desejo até o próximo período")
	# Um por período.
	check(not state.update_wishes() and state.wish_id() == "", "só um desejo por período")
	var saved: Dictionary = state.to_dict().duplicate(true)
	state.from_dict(saved)
	check(not state.update_wishes() and state.wish_id() == "", "recarregar não cria outro")
	state.advance_clock(6 * 3600)
	all_needs(100.0)
	check(state.moment_period().ends_with(":afternoon") or state.moment_period().ends_with(":night"), "relógio mudou de período")
	check(wish_now() != "", "novo período traz desejo")
	var last: String = state.wishes.last_ids[state.wishes.last_ids.size() - 1]
	check(last == "pet" and state.wish_id() != "pet", "não repete o último")
	# Madrugada não traz desejo, e o da noite continua.
	fresh()
	wish_now()
	to_period("night")
	all_needs(100.0)
	var night_wish := wish_now()
	to_period("dawn")
	state.update_wishes()
	check(night_wish != "" and state.wish_id() == night_wish, "o desejo da noite continua na madrugada")
	to_period("morning")
	all_needs(100.0)
	state.update_wishes()
	check(state.wishes.current.period.ends_with(":morning"), "desejo não atendido é trocado no período seguinte")
	# Necessidade pedindo escolhe o desejo dela.
	fresh()
	wish_now()
	state.wishes.current = {}
	state.wishes.done_count = 1
	state.advance_clock(6 * 3600)
	all_needs(100.0)
	need("hygiene", 20)
	check(wish_now() == "bath", "higiene pedindo → banho")
	state.wishes.current = {}
	state.wishes.period = ""
	all_needs(100.0)
	need("hunger", 20)
	check(wish_now() == "meal" and str(state.wish_now().type) == "action", "fome sem comida da fase → qualquer comida")
	# Sem necessidade e sem momentos pedidos (a lista de Filhotinho da semana 1 não os pede): qualquer desejo da fase.
	fresh("puppy")
	state.wishes.done_count = 1
	state.wishes.first_done = true
	state.wishes.period = ""
	all_needs(100.0)
	check(wish_now() != "" and state.wish_pillar() != "", "sem necessidade e sem pilar faltando: qualquer desejo da fase")
	fresh("teething")
	state.wishes.done_count = 1
	state.wishes.first_done = true
	state.growth.phase_moments["brave"] = 99
	all_needs(100.0)
	check(wish_now() != "" and state.wish_pillar() == "smart", "Coragem completa: Esperteza é a que falta")
	# Felicidade pedindo escolhe carinho ou brincar pelo que falta.
	fresh("teething")
	state.wishes.done_count = 1
	state.wishes.first_done = true
	state.growth.phase_moments["brave"] = 99
	need("happiness", 20)
	check(wish_now() == "play", "felicidade pedindo e Esperteza faltando → brincar")
	fresh("teething")
	state.wishes.done_count = 1
	state.wishes.first_done = true
	state.growth.phase_moments["smart"] = 99
	need("happiness", 20)
	check(wish_now() == "pet", "felicidade pedindo e Coragem faltando → carinho")
	# Não repete os dois últimos ids.
	fresh("puppy")
	state.wishes.done_count = 3
	state.wishes.first_done = true
	state.wishes.last_ids.assign(["pet", "play"])
	all_needs(100.0)
	var pick := wish_now()
	check(pick != "" and pick != "pet" and pick != "play", "não repete os dois últimos (%s)" % pick)
	# Desejo de comida da fase conta como refeição.
	fresh("puppy")
	state.wishes.done_count = 1
	state.wishes.first_done = true
	state.inventory.add("frozen_carrot", 2)
	need("hunger", 20)
	# A lista da primeira semana (E05) não pede uma comida específica em Filhotinho: a fome vira "Tô com fome" (qualquer comida).
	check(wish_now() == "meal" and str(state.wish_now().type) == "action" and str(state.wish_now().name) == "Tô com fome", "fome: qualquer comida resolve")
	var meals_before: int = state.progress.stat("feed:frozen_carrot")
	check(state.feed("frozen_carrot"), "dá a comida")
	check(state.wish_error() == "" and state.fulfill_wish() == "", "atende com a comida")
	check(state.progress.stat("feed:frozen_carrot") == meals_before + 1 and state.inventory.count("frozen_carrot") == 1, "conta como refeição e consome uma")
	# Truque e passeio longo abrem pela fase.
	fresh("explorer")
	check(state.requirement_error({"growth": "young"}) != "", "fase Mocinho ainda fechada no Aventureiro")
	var walks: Dictionary = root.get_node("Database").walks.walks
	var long_phases: Array = []
	for id: String in walks:
		var growth_req := str(walks[id].get("requirements", {}).get("growth", ""))
		if growth_req != "":
			long_phases.append(growth_req)
	check("explorer" in long_phases and "young" in long_phases and "adult" in long_phases, "passeios longos abrem por Aventureiro/Mocinho/Azul e Dourado")
	var tricks: Dictionary = root.get_node("Database").progression.tricks
	for id: String in tricks:
		var requirements: Dictionary = tricks[id].requirements
		if state.call("trick_is_lesson", id):
			check(int(requirements.get("story_day", 0)) > 0 and not requirements.has("bond"), "aula de %s abre pelo dia" % id)
		else:
			check(str(requirements.get("growth", "")) != "" and not requirements.has("bond"), "truque da Nina %s abre pela fase" % id)
	# Vínculo saiu.
	check(not state.dog.to_dict().has("affection") and not root.get_node("Database").progression.has("bond_levels"), "afeto e níveis de vínculo removidos")
	check(not JSON.stringify(walks).contains("affection") and not JSON.stringify(walks).contains("\"bond\""), "passeios sem afeto nem vínculo")
	print("WISH MOMENTS TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures else 0)
