extends SceneTree
## Etapa 11 do plano Tiro: a história é conduzida pelo crescimento.
## Capítulo só abre depois da missão `growth_*`, objetivo reconhecido (inclusive se ele já cresceu),
## pares shared_with, saves de exemplo, liberações por fase e falas sem palavras proibidas.

const FORBIDDEN: Array[String] = ["Recolher", "Coletar", "Conclua:", " · Conclua", "Nv ", "Máx.", "capítulo %d", "x0", "Produzir"]
const GROWTH_QUESTS := {
	"growth_1_puppy": ["puppy", 1, 70],
	"growth_3_teething": ["teething", 3, 40],
	"growth_6_explorer": ["explorer", 6, 50],
	"growth_9_young": ["young", 9, 40],
	"growth_12_adult": ["adult", 12, 40],
}

var state: Node
var db: Node
var failures := 0


func _initialize() -> void:
	_run.call_deferred()
	create_timer(170).timeout.connect(func() -> void:
		print("GROWTH STORY TEST: TEMPO ESGOTADO")
		quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("História do Tiro: " + message)


func _fresh(phase: String = "newborn") -> void:
	state.reset()
	state.growth.phase = phase


func _reload() -> void:
	state.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/friend_clock.gd"))
	state.test_time = 1791936000.0
	_data()
	_chapter_one()
	_first_growth_care()
	_recognized()
	_pairs()
	_samples()
	_walks_before_nature()
	_unlocks()
	_task_help()
	_texts()
	print("GROWTH STORY TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


## Dados: nove missões novas da história, ordem e objetivos exatos.
func _walks_before_nature() -> void:
	_fresh("teething")
	for id: String in db.quests:
		var quest: Dictionary = db.quests[id]
		if quest.get("kind", "") == "main" and int(quest.get("chapter", 0)) <= 4 and id != "main_4_nina_chest":
			state.progress.claimed_quests[id] = true
	state._changed()
	check(state.progress.chapter_index() == 4 and state.progress.current_main_quest() == "main_4_nina_chest", "primeira encomenda mantém história nos passeios")
	check(state.progress.displayed_main_quest() == "nina_meet", "principal começa apresentando a Nina")
	check(state.requirement_error(db.worlds.park.requirements) == "" and state.requirement_error(db.worlds.village.requirements) == "", "Vila e Praça acessíveis sem Natureza")
	check(state.requirement_error(db.worlds.nature.requirements) != "" and not state.progress.npc_visible("guide"), "Natureza e Guia aguardam o baú")
	check(state.requirement_error(db.worlds.village.places.gate.requirements) != "" and state.requirement_error(db.progression.upgrades.forest_open.requirements) != "", "portão e Bosque também aguardam")
	state.talk_to("nina")
	check(state.claim_quest("nina_meet") == "", "conhece a Nina")
	check(state.progress.displayed_main_quest() == "nina_walk", "principal segue ao primeiro passeio")
	check(state.start_walk("park_loop") == "", "primeiro passeio não exige Natureza")
	state.test_time += float(db.walks.walks.park_loop.seconds) + 1.0
	check(state.return_due_walk(false), "Tiro volta do passeio")
	state.claim_walk_baggage()
	check(state.inventory.count("stick") >= 2, "passeio garante os gravetos sem madeira da Natureza")
	check(state.claim_quest("nina_walk") == "", "recebe missão do passeio")
	check(state.progress.displayed_main_quest() == "bloblo_chest", "principal aponta o baú da Nina")
	check(state.buy_upgrade("chest") == "", "constrói baú com os achados")
	_reload()
	check(state.progress.chapter_index() == 4 and state.requirement_error(db.worlds.nature.requirements) != "", "baú construído sem receber missão ainda não abre Natureza, inclusive após reload")
	var coins_before: int = state.coins
	check(state.claim_quest("bloblo_chest") == "", "recebe missão do baú")
	check(state.progress.claimed_quests.has("main_4_nina_chest") and state.progress.current_main_quest() == "lais_forest", "baú recebido leva diretamente a Além do portão")
	check(state.coins == coins_before + 10 + int(db.progression.chapters[3].rewards.coins), "só missão canônica e capítulo pagam, sem prêmio duplicado")
	check(state.progress.npc_visible("guide") and state.quest_unlocked("guide_meet") and state.requirement_error(db.worlds.nature.requirements) == "", "Natureza e Guia abrem juntos depois da missão")
	coins_before = state.coins
	state.progress.claimed_quests.erase("main_4_nina_chest")
	_reload()
	check(state.progress.current_main_quest() == "lais_forest" and state.coins == coins_before, "save com baú já recebido reconhece marco sem repetir prêmio")


func _data() -> void:
	check(db.quests.size() == 111, "111 missões com tutorial do primeiro desejo: %d" % db.quests.size())
	var mains := 0
	for id: String in db.quests:
		if db.quests[id].get("kind", "") == "main":
			mains += 1
	check(mains == 51, "51 missões principais: %d" % mains)
	for id: String in GROWTH_QUESTS:
		var quest: Dictionary = db.quests[id]
		var rule: Array = GROWTH_QUESTS[id]
		check(quest.goals.size() == 1 and quest.goals[0].type == "growth" and quest.goals[0].key == rule[0], id + ": objetivo growth " + str(rule[0]))
		check(int(quest.chapter) == rule[1] and int(quest.order) == rule[2], id + ": capítulo/ordem")
		check((quest.rewards as Dictionary).is_empty(), id + ": sem prêmio extra (o presente vem da fase)")
		var last: String = str(state.progress.main_quests(int(quest.chapter)).back())
		check(last == id, id + ": é o último passo do capítulo (último = %s)" % last)
	check(db.quests.teeth_3_ring.shared_with == "bloblo_chew_ring" and int(db.quests.teeth_3_ring.order) == 35, "teeth_3_ring orienta a argolinha")
	check(db.quests.explorer_6_eggs.shared_with == "main_9_eggs" and int(db.quests.explorer_6_eggs.order) == 45, "explorer_6_eggs orienta os ovos")
	check(db.quests.young_9_milk.shared_with == "main_9_flour" and int(db.quests.young_9_milk.order) == 35, "young_9_milk orienta o moinho")
	var shampoo: Dictionary = db.quests.young_8_shampoo
	check(int(shampoo.order) == 40 and int(shampoo.chapter) == 8 and shampoo.goals[0].key == "shampoo_bath" and int(shampoo.goals[0].target) == 1, "young_8_shampoo: 1 banho com xampu")
	check(db.growth.phases.size() == 6, "seis fases")
	check(str(state.growth_info().phase) == "newborn", "começa recém-chegado")


## Save novo: o capítulo 2 só abre depois de `growth_1_puppy`.
func _chapter_one() -> void:
	_fresh()
	var ids: Array = state.progress.main_quests(1)
	check(ids.size() == 7 and ids.back() == "growth_1_puppy", "capítulo 1 tem sete passos, o último é crescer")
	state.dev_complete_quest("lais_bed")
	check(state.progress.chapter_index() == 1 and state.progress.current_main_quest() == "growth_1_puppy", "caminha feita, falta crescer")
	check(state.progress.requirement_error({"chapter": 2}) != "", "capítulo 2 ainda fechado")
	check(state.quest_error("growth_1_puppy") != "", "sem a fase não dá para pegar")
	check(state.goal_value(db.quests.growth_1_puppy.goals[0]) == 0, "objetivo zerado")
	check(state.requirement_error({"growth": "puppy"}).begins_with("Quando ele for"), "requisito growth fala 'Quando ele for …'")
	state.growth.phase = "puppy"
	check(state.goal_value(db.quests.growth_1_puppy.goals[0]) == 1 and state.quest_error("growth_1_puppy") == "", "fase alcançada cumpre o objetivo")
	var coins: int = state.coins
	check(state.claim_quest("growth_1_puppy") == "", "pega a missão de crescer")
	check(state.progress.chapter_index() == 2 and state.progress.current_main_quest() == "lais_first_wish", "o capítulo 2 abriu")
	check(state.coins - coins == int(db.progression.chapters[0].rewards.coins), "só o prêmio do capítulo 1 (sem extra na missão)")
	# O botão Ir abre o painel de crescimento.
	var places: Script = load("res://scripts/ui/places.gd")
	check((places.call("goal_target", db.quests.growth_1_puppy.goals[0]) as Dictionary).has("growth"), "Ir abre o crescimento")


## O primeiro crescimento é alcançável só com os cuidados e presentes do capítulo 1.
func _first_growth_care() -> void:
	_fresh()
	state.note_world_visit("house")
	state.talk_to("lais")
	state.pet()  # terceiro momento: cuidado útil antes de a brincadeira satisfazer a felicidade
	check(state.claim_quest("welcome") == "", "recebe a ração da Laís")
	check(state.feed("dog_food"), "alimenta na missão Hora de comer")
	check(state.claim_quest("lais_feed") == "", "recebe Hora de comer")
	state.bathe()
	check(state.claim_quest("lais_bath") == "", "recebe Banho de espuma")
	state.play()
	check(state.claim_quest("lais_play") == "", "recebe Vamos brincar")
	state.note_screen_opened("bag")
	check(state.claim_quest("lais_bag") == "", "recebe a caminha")
	check(state.buy_upgrade("dog_bed") == "", "coloca a caminha")
	check(state.claim_quest("lais_bed") == "", "recebe Um cantinho para ele")
	var help: Script = load("res://scripts/ui/task_help.gd")
	check(state.requirement_error(db.worlds.farm.requirements) != "", "caminha não abre o Sítio antes do crescimento")
	check(state.requirement_error(db.worlds.house.places.door.requirements) != "", "porta da Casa também espera crescer")
	check(not state.progress.npc_visible("bloblo") and not state.quest_unlocked("bloblo_meet"), "vovó e sua linha não antecipam a horta")
	check(state.accessible_plots() == 0 and state.plant(0, "carrot") != "", "não planta antes de conhecer a vovó")
	var meals: Dictionary = help.call("describe", "growth_req", "meals")
	check("Qualquer comida" in str(meals.detail), "refeições explicam que não exigem receita")
	check("Corpo" in str(meals.detail), "refeições já completam Corpo")
	var care: Dictionary = help.call("describe", "growth_req", "pillars")
	check("carinho" in str(care.steps[0].hint).to_lower(), "ajuda explica momentos de carinho e novidades, inclusive depois de cumprir")
	var places: Script = load("res://scripts/ui/places.gd")
	check(care.target == {"screen": "pet"}, "Ir de Carinho leva ao Tiro")
	for i in 2:
		check(state.feed("dog_food"), "ração inicial restante %d" % i)
	check(state.growth.body_level == 1, "três refeições fecham o Corpo do primeiro crescimento")
	for i in 10:
		state.pet()
	check(state.growth_info().ready, "cuidados iniciais bastam, sem horta nem receita bloqueada")
	check(state.grow() == "", "cresce pelas ações reais")
	check(state.requirement_error(db.worlds.farm.requirements) != "", "crescer ainda pede receber a missão para concluir o capítulo")
	check(state.claim_quest("growth_1_puppy") == "", "termina Um novo lar")
	check(state.progress.chapter_index() == 2, "abre o sítio depois do primeiro crescimento")
	check(state.requirement_error(db.worlds.farm.requirements) == "" and state.requirement_error(db.worlds.house.places.door.requirements) == "", "mapa e porta abrem juntos")
	check(state.progress.npc_visible("bloblo") and state.quest_unlocked("bloblo_meet"), "vovó e missão abrem no capítulo 2")
	state.talk_to("bloblo")
	check(state.claim_quest("bloblo_meet") == "", "conhece a vovó depois do crescimento")
	check(state.accessible_plots() == 2 and state.plant(0, "carrot") == "", "vovó libera os primeiros canteiros")


## Cada `growth_*` é reconhecida quando a fase chega, inclusive se ele já cresceu antes de a missão ficar ativa.
func _recognized() -> void:
	for id: String in GROWTH_QUESTS:
		var phase: String = GROWTH_QUESTS[id][0]
		var goal: Dictionary = db.quests[id].goals[0]
		_fresh()
		var ids: Array = state.progress.main_quests(int(db.quests[id].chapter))
		var before: String = str(ids[ids.find(id) - 1]) if ids.find(id) > 0 else ""
		if before == "":
			before = "lais_bed"
		state.dev_complete_quest(before)
		# A fase da missão anterior (dev_complete_quest já a colocou); volta para a anterior à desta.
		var index: int = state.growth.phase_index(phase)
		state.growth.phase = db.growth.phases[index - 1].id
		check(state.progress.current_main_quest() == id, id + ": é a missão atual")
		check(state.goal_value(goal) == 0 and state.quest_error(id) != "", id + ": ainda não")
		state.growth.phase = phase
		check(state.goal_value(goal) == 1 and state.quest_error(id) == "", id + ": reconhecida ao chegar a fase")
		# Crescer antes de a missão estar ativa também vale (uma fase além).
		_fresh()
		state.dev_complete_quest(before)
		if index + 1 < db.growth.phases.size():
			state.growth.phase = db.growth.phases[index + 1].id
			check(state.goal_value(goal) == 1, id + ": fase além também cumpre")
		_reload()
		check(state.progress.current_main_quest() == id or state.progress.claimed_quests.has(id), id + ": sobrevive ao save")


## Pares shared_with: entrega e prêmio uma vez, só na missão do personagem.
func _pairs() -> void:
	# Argolinha da vovó.
	_fresh()
	state.dev_complete_quest("lais_stew")
	check(state.progress.current_main_quest() == "teeth_3_ring", "depois do ensopado vem 'Dentinhos coçando'")
	check(not state.quest_unlocked("teeth_3_ring"), "o alias não é entregável")
	check(state.progress.displayed_main_quest() == "bloblo_chew_ring", "a história mostra a missão da vovó")
	state.inventory.add("carrot", 6)
	state.inventory.add("strawberry", 3)
	var coins: int = state.coins
	var quests_before: int = state.progress.stat("quests")
	check(state.claim_quest("bloblo_chew_ring") == "", "vovó entrega a argolinha")
	check(state.progress.claimed_quests.has("teeth_3_ring"), "a história avança junto")
	check(state.coins - coins == 10 and state.progress.stat("quests") == quests_before + 1, "prêmio e contagem uma vez")
	check(state.inventory.count("chew_ring") == 1, "argolinha na mochila")
	check(state.progress.current_main_quest() == "growth_3_teething", "agora é crescer")
	check(state.claim_quest("teeth_3_ring") != "" and state.claim_quest("bloblo_chew_ring") != "", "sem segunda entrega")
	_reload()
	check(state.coins - coins == 10, "recarregar não paga de novo")
	# Ovos e farinha da vovó.
	_fresh("teething")
	state.dev_complete_quest("main_5_bricks")
	check(state.progress.current_main_quest() == "explorer_6_eggs", "depois dos tijolos vem a ração com ovo")
	state.dev_complete_quest("main_9_coop")
	state.progress.count("produce:egg", 2)
	coins = state.coins
	check(state.claim_quest("main_9_eggs") == "", "vovó recebe os ovos")
	check(state.progress.claimed_quests.has("explorer_6_eggs") and state.coins - coins == 35, "ovos: 35 moedas, uma vez")
	check(state.progress.current_main_quest() == "growth_6_explorer", "ovos feitos: agora é crescer")
	_fresh("explorer")
	state.dev_complete_quest("atelier_open")
	check(state.progress.current_main_quest() == "young_9_milk", "depois do ateliê vem o mingau")
	state.dev_complete_quest("main_9_cows")
	state.dev_complete_quest("bloblo_milk")
	state.progress.count("produce:flour", 2)
	state.progress.owned["mill"] = true
	coins = state.coins
	check(state.claim_quest("main_9_flour") == "", "vovó recebe a farinha")
	check(state.progress.claimed_quests.has("young_9_milk") and state.coins - coins == 45, "farinha: 45 moedas, uma vez")
	check(state.progress.current_main_quest() == "growth_9_young", "mingau feito: agora é crescer")
	# Banho de ervas (capítulo 8): objetivo comum, conta o xampu.
	_fresh("explorer")
	state.dev_complete_quest("main_7_greenhouse")
	check(state.progress.current_main_quest() == "young_8_shampoo", "depois da estufa vem o banho de ervas")
	check(state.quest_error("young_8_shampoo") != "", "sem banho não conclui")
	state.inventory.add("herb_shampoo", 1)
	state.bathe(true)
	check(state.quest_error("young_8_shampoo") == "", "um banho com xampu conclui")


## Saves de exemplo nos capítulos 2, 5, 8 e 11 entram na fase certa com a próxima missão certa.
func _samples() -> void:
	var cases := [
		[2, "puppy", "lais_first_wish"],
		[5, "teething", "lais_forest"],
		[8, "explorer", "main_7_orchard"],
		[11, "young", "community_11_garden"],
	]
	for entry: Array in cases:
		_fresh()
		state.dev_jump_to_chapter(int(entry[0]) - 1)
		check(state.progress.chapter_index() == int(entry[0]), "capítulo %d aberto" % int(entry[0]))
		check(state.growth.phase == entry[1], "capítulo %d: fase %s (veio %s)" % [int(entry[0]), entry[1], state.growth.phase])
		check(state.progress.current_main_quest() == entry[2], "capítulo %d: próxima missão %s (veio %s)" % [int(entry[0]), entry[2], state.progress.current_main_quest()])
		_reload()
		check(state.growth.phase == entry[1] and state.progress.current_main_quest() == entry[2], "capítulo %d sobrevive ao save" % int(entry[0]))
		check(str(state.growth_info().phase) == entry[1], "painel de crescimento na fase " + str(entry[1]))
	# Capítulo 12: o último passo é crescer; o final vem depois.
	_fresh()
	state.dev_jump_to_chapter(11)
	state.dev_complete_quest("community_12_memory")
	check(state.growth.phase == "young" and state.progress.current_main_quest() == "growth_12_adult", "festa feita: falta o Azul e Dourado")
	state.growth.phase = "adult"
	check(state.claim_quest("growth_12_adult") == "", "pega a última missão")
	check(state.progress.chapter_index() == db.progression.chapters.size() + 1, "história concluída")
	check(str(db.progression.final_chapter.description).contains("Guardião do Vale"), "capítulo final com a fala nova")


## Truques e passeios longos travam com "Quando ele for …".
func _unlocks() -> void:
	_fresh("newborn")
	state.dev_complete_quest("nina_pipoca")
	state.growth.phase = "newborn"  # o atalho dev também faz o Tiro crescer junto da história
	var expect := {"paw": "Dentinhos", "talk": "Dentinhos", "roll": "Aventureiro", "jump": "Aventureiro", "spin": "Mocinho"}
	for trick: String in expect:
		check(state.trick_available_error(trick) == "Quando ele for " + expect[trick], "truque %s: %s (veio %s)" % [trick, expect[trick], state.trick_available_error(trick)])
	state.growth.phase = "teething"
	check(state.trick_available_error("paw") == "" and state.trick_available_error("talk") == "", "dentinhos libera dá a pata e fala")
	check(state.trick_available_error("roll") == "Quando ele for Aventureiro", "rola ainda trava")
	state.growth.phase = "explorer"
	check(state.trick_available_error("roll") == "" and state.trick_available_error("jump") == "", "aventureiro libera rola e pula")
	check(state.trick_available_error("spin") == "Quando ele for Mocinho", "gira ainda trava")
	state.growth.phase = "young"
	check(state.trick_available_error("spin") == "", "mocinho libera gira")
	var walk_phase := {"creek_walk": ["explorer", "Aventureiro"], "bird_clearing": ["young", "Mocinho"], "hill_view": ["adult", "Azul e Dourado"]}
	for id: String in ["creek_walk", "bird_clearing", "hill_view"]:
		_fresh("teething")
		state.dev_unlock_everything()
		state.growth.phase = "teething"
		state.progress.stats["walk"] = 99
		check(state.walk_lock_error(id) == "Quando ele for " + walk_phase[id][1], "passeio %s trava (veio %s)" % [id, state.walk_lock_error(id)])
		state.growth.phase = walk_phase[id][0]
		check(state.walk_lock_error(id) == "", "passeio %s abre na fase (veio %s)" % [id, state.walk_lock_error(id)])
	check(db.progression.features.wishes.requirements.growth == "puppy", "Desejos só depois de filhotinho")
	_fresh("newborn")
	state.dev_complete_quest("lais_bed")
	check(not state.progress.feature_unlocked("wishes") or state.requirement_error(db.progression.features.wishes.requirements) != "", "Desejos esperam o Filhotinho")
	check(db.recipes.treat_box.requirements.growth == "explorer", "caixa de petiscos pelo Aventureiro")
	check(db.recipes.sew_topknot_bow.requirements.growth == "young", "lacinho pelo Mocinho")


## "Como fazer" do objetivo: mostra o que falta, cada item tocável.
func _task_help() -> void:
	var help: Script = load("res://scripts/ui/task_help.gd")
	_fresh("newborn")
	var data: Dictionary = help.call("describe", "growth", "puppy")
	check(data.title == "Filhotinho" and data.target.has("growth"), "descrição da fase aponta o painel")
	var ids: Array = (data.needs as Array).map(func(need: Dictionary) -> String: return str(need.id))
	check("bed" in ids and "meals" in ids and "pillars" in ids and not "home" in ids, "lista só o que falta (%s)" % str(ids))
	for need: Dictionary in data.needs:
		check(need.kind == "growth_req", "cada requisito é tocável (growth_req)")
		var detail: Dictionary = help.call("describe", need.kind, need.id, need.amount)
		check(not detail.is_empty() and detail.has("target"), "requisito %s abre o 'Como fazer'" % str(need.id))
	state.growth.phase = "puppy"
	check(str((help.call("describe", "growth", "puppy") as Dictionary).detail) == "Ele já cresceu!", "fase já alcançada")
	var goal_help: Dictionary = help.call("describe", "quest", "growth_3_teething")
	check(not goal_help.is_empty(), "descrição da missão de crescer")
	# Requisito `growth` também vira passo no "Como fazer" de um truque/passeio.
	var needs: Array = help.call("_requirements", {"growth": "explorer"})
	check(needs.size() == 1 and needs[0].kind == "growth", "requisito growth vira passo")


## Falas novas sem palavras proibidas; uma ideia, curtas.
func _texts() -> void:
	var texts: Array[String] = []
	for id: String in db.quests:
		var quest: Dictionary = db.quests[id]
		if quest.get("kind", "") == "main" or id == "bloblo_chew_ring":
			texts.append(str(quest.get("dialogue", "")))
			texts.append(str(quest.get("name", "")))
			for goal: Dictionary in quest.goals:
				texts.append(str(goal.get("label", "")))
	texts.append(str(db.progression.final_chapter.description))
	for text: String in texts:
		for word: String in FORBIDDEN:
			check(not word in text, "palavra proibida '%s': %s" % [word, text])
		check(text.length() <= 175, "fala curta (%d): %s" % [text.length(), text])
	check(str(db.quests.community_12_memory.dialogue).contains("Smoky"), "homenagem à Smoky")
	for id: String in ["welcome", "lais_feed", "lais_bath", "lais_play", "lais_bed"]:
		check(str(db.quests[id].dialogue) != "", id + ": fala")
	check(str(db.quests.welcome.dialogue).contains("caixinha"), "a Laís conta da caixinha")
