extends SceneTree
## F04 Parte B do plano "Novo fluxo": lições presas ao passo da história, Manual por capítulo, desafio do dia quando só
## faltam as patinhas (`only_paws_left`), placas "Em breve" do Sítio e a mão da aba Missões. O seletor de mundos é do
## `world_selector_test`.

var failures := 0
var state: Node
var db: Node


func _initialize() -> void:
	run.call_deferred()


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("F04B · " + message)


func run() -> void:
	root.get_node("SaveManager").free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/helpers/week_story_clock.gd"))
	state.reset()
	state.set_clock(1792411200.0)
	state.reset()
	state.call("_count", "arrival_box")

	# 1. Cada lição não nativa dispara por um passo da história (nunca só pelo dia) e o passo existe; sem repetidas.
	var ids := {}
	var by_chapter := {}
	for lesson: Dictionary in db.week_tutorials:
		var id := str(lesson.id)
		check(not ids.has(id), "lição repetida: " + id)
		ids[id] = true
		by_chapter[int(lesson.day)] = int(by_chapter.get(int(lesson.day), 0)) + 1
		var quest := str(lesson.get("quest", lesson.get("after_quest", "")))
		if id == "arrival" or lesson.get("native", false):
			continue
		check(quest != "" and db.quests.has(quest), "a lição %s está presa a um passo da história (%s)" % [id, quest])
		if quest != "" and db.quests.has(quest) and db.quests[quest].get("kind") == "main":
			check(int(db.quests[quest].get("chapter", 0)) == int(lesson.day), "a lição %s fica no capítulo do passo %s" % [id, quest])
	for gone: String in ["eggs", "snack", "tricks", "growth", "soup", "key_dish", "meal_trick", "pair", "paw", "down", "clue", "checklist", "name", "bath"]:
		check(not ids.has(gone), "lição que repetia saiu: " + gone)
	check(db.week_tutorials.size() <= 34, "lições enxutas: %d" % db.week_tutorials.size())
	for balloon: String in ["missions", "bag"]:
		for lesson: Dictionary in db.week_tutorials:
			if lesson.id == balloon:
				check(bool(lesson.get("point", false)), "o balão %s também aponta (mão e anel) para a aba" % balloon)

	# 2. Manual: um grupo por capítulo, com o nome do capítulo.
	var model := {}
	var manual: Control = load("res://scripts/ui/week_tutorial.gd").call("manual_body", model, func() -> void: pass)
	root.add_child(manual)
	check(manual.find_child("TutorialChapter_1", true, false) != null, "Manual tem o grupo do capítulo 1")
	var heading := manual.find_child("TutorialChapter_5", true, false) as Label
	check(heading != null and "Senta" in heading.text, "grupo do capítulo 5 leva o nome do capítulo")
	for lesson: Dictionary in db.week_tutorials:
		check(manual.find_child("TutorialReview_" + str(lesson.id), true, false) != null, "página da lição no Manual: " + str(lesson.id))
	manual.queue_free()

	# 3. Só faltam as patinhas: o desafio do dia aparece na pílula; sem isso, não.
	state.reset()
	state.call("_count", "arrival_box")
	state.dev_content_day(11)
	state.growth.phase = "puppy"
	check(not state.only_paws_left(), "com a lista cheia, não é só as patinhas")
	var info: Dictionary = state.growth_info()
	for row: Dictionary in info.requirements:
		if str(row.get("counter", "")) != "well_fed_day":
			if not state.growth.done.has(str(info.next.id)):
				state.growth.done[str(info.next.id)] = {}
			state.growth.done[str(info.next.id)][str(row.id)] = true
	check(state.only_paws_left(), "só faltam as patinhas")
	var guide: Dictionary = load("res://scripts/ui/quest_guide.gd").call("current")
	check(guide.state == "challenge" and guide.npc == "bloblo", "a pílula mostra o desafio da vovó")
	check(int(guide.target) >= 1 and guide.challenge.has("label"), "o desafio tem objetivo e texto")
	var card: Control = load("res://scripts/ui/step_card_ui.gd").call("build_challenge", guide.challenge, true)
	root.add_child(card)
	check(card.find_child("ChallengeLabel", true, false) != null and card.find_child("ChallengeCount", true, false) != null, "cartão do desafio")
	var speech := card.find_child("StepSpeech", true, false) as Label
	check(speech != null and "esperar as patinhas" in speech.text, "na primeira vez a vovó diz que é só esperar as patinhas")
	card.queue_free()
	# Desafio cumprido (prêmio pago): volta o passo normal.
	state.economy.granted["week_challenge:%d" % state.week_day()] = true
	guide = load("res://scripts/ui/quest_guide.gd").call("current")
	check(guide.state != "challenge", "desafio pago: a pílula volta ao passo")
	# Depois da primeira semana o dia do calendário recomeça a lista (nunca fica sem desafio).
	check(not state.call("_challenge_entry", 9).is_empty(), "o 9º dia recomeça a lista de desafios")

	# 4. Placas do Sítio: "Em breve" só no capítulo anterior ao da área, sem "dia N".
	var farm: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/rooms/farm.json"))
	var plaques := {"chicken_coop": 4, "lake": 6, "orchard": 7}
	for region: Dictionary in farm.regions:
		if region.has("text"):
			check("dia" not in str(region.text).to_lower(), "placa sem número de dia: " + str(region.text))
		if plaques.has(str(region.id)):
			check(int(region.get("plaque_from", 0)) == int(plaques[region.id]) - 1, "placa %s aparece no capítulo %d" % [region.id, int(plaques[region.id]) - 1])
			check(str(region.text) == "Em breve", "placa %s diz só Em breve" % region.id)
		else:
			check(not region.has("plaque"), "área da vila/pós-semana sem placa: " + str(region.id))

	# 5. O formato do save subiu (saves zerados).
	check(int(load("res://autoload/save_manager.gd").get("SAVE_VERSION")) >= 38, "SAVE_VERSION 38")

	print("ATO3 HELP TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
