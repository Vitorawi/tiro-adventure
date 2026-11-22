extends SceneTree
## F00 do plano "Novo fluxo do começo": o conteúdo abre pelo capítulo da história (`content_day()`),
## nunca pelo dia do calendário. O relógio das refeições continua igual.

var failures := 0
var state: Node
var db: Node
var db_file_checks := 0


func _initialize() -> void:
	run.call_deferred()


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("F00 · " + message)


func _fresh() -> void:
	state.reset()
	state.set_clock(1792411200.0)  # 9h do dia 1
	state.reset()
	state.dev_week_goto(1)
	state.dev_week_hour(9)
	check(state.week_day() == 1, "começa no dia 1")


func run() -> void:
	root.get_node("SaveManager").free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	load("res://tests/helpers/old_day_rules.gd").new().apply(db)
	state.set_script(load("res://tests/helpers/week_story_clock.gd"))

	# 1. A história flui sem avançar o relógio (capítulos 1 a 3).
	_fresh()
	var rules := load("res://scripts/state/dish_rules.gd")
	check(state.content_day() == 1, "capítulo 1 = content_day 1")
	for chapter in range(1, 4):
		for id: String in state.progress.main_quests(chapter):
			check(state.progress.current_main_quest() == id, "passo na ordem: " + id)
			if db.quests[id].has("shared_with"):
				# Passo da história que acompanha o marco de uma linha (a vovó): vale o marco dela.
				var shared := str(db.quests[id].shared_with)
				check(state.quest_unlocked(shared), "marco compartilhado liberado sem esperar o relógio: " + shared)
				state.dev_complete_quest(shared)
				check(state.progress.claimed_quests.has(id), "o marco fecha o passo da história: " + id)
				continue
			check(state.quest_unlocked(id), "passo liberado sem esperar o relógio: " + id)
			var error: String = state.quest_objectives_error(id)
			check(not error.contains("volta"), "sem espera de dia: " + id + " · " + error)
			var stats_only := true
			for goal: Dictionary in db.quests[id].goals:
				stats_only = stats_only and goal.type == "stat"
			if stats_only:
				for goal: Dictionary in db.quests[id].goals:
					state.call("_count", str(goal.key), int(goal.get("target", 1)))
				var claimed: String = state.claim_quest(id)
				check(claimed == "" or claimed.contains("espaço"), "pegar o prêmio de " + id + " · " + claimed)
				if claimed != "":
					state.dev_complete_quest(id)
			else:
				state.dev_complete_quest(id)
			check(state.progress.claimed_quests.has(id), "concluído: " + id)
	check(state.progress.chapter_index() == 4 and state.content_day() == 4, "três capítulos feitos")
	check(state.week_day() == 1, "o calendário não andou")

	# 2. Conteúdo do capítulo 3 aberto com o calendário no dia 1.
	_fresh()
	state.dev_jump_to_chapter(2)
	check(state.content_day() == 3 and state.week_day() == 1, "capítulo 3 com o calendário no dia 1")
	check(state.farm_lake_open(), "lagoa aberta")
	check(state.fishing_error() != "Continue a História" and state.requirement_error({"story_day": 3}) == "", "requisito story_day 3 vale")
	check(state.requirement_error({"story_day": 4}) == "Continue a História", "story_day 4 ainda fechado")
	for type: String in rules.call("types"):
		var opens: int = rules.call("opens", type)
		check(state.dish_type_open(type) == (opens <= 3), "tipo %s (abre em %d)" % [type, opens])
	check(rules.call("max_count", "papinha", state.content_day()) == 3, "terceira vaga da papinha")
	check(state.yard_open("ball") and state.yard_open("fetch") and not state.yard_open("rope"), "brincadeiras do capítulo 3")
	check(state.yard_error("rope") == "Continue a História", "motivo é Continue a História")
	state.dev_jump_to_chapter(3)
	check(state.yard_open("rope") and state.content_day() == 4, "corda abre no capítulo 4")
	check(state.requirement_error(db.progression.tricks.paw.requirements) == "", "Dá a pata no capítulo 4")

	# 3. Duas aulas do Tiro no mesmo período, com 2 biscoitos.
	_fresh()
	state.dev_jump_to_chapter(2)
	state.progress.seen["intro"] = true
	state.inventory.add("apple_biscuit", 2)
	for round in 2:
		check(state.trick_lesson_error("sit") == "", "aula %d liberada" % (round + 1))
		check(state.start_trick_lesson("sit") == "", "aula %d começa" % (round + 1))
		var result: Dictionary = {}
		for step in int(db.progression.trick_settings.lesson.repetitions):
			state.trick_lesson_step("sit", "show", 1.0)
			state.trick_lesson_step("sit", "mark", 1.0)
			result = state.trick_lesson_step("sit", "reward", 0.1)
		check(result.has("stars"), "aula %d terminou: %s" % [round + 1, str(result)])
	check(state.inventory.count("apple_biscuit") == 0, "só os biscoitos seguram")
	check(state.trick_lesson_error("sit") == "Falta Biscoito ×1", "sem biscoito é o único motivo")

	# 4. O relógio das refeições continua.
	_fresh()
	state.dev_jump_to_chapter(2)
	state.dev_week_hour(9)
	check(state.meal_period_now() == "", "9h está fora das janelas")
	state.inventory.add("puppy_mash", 2)
	var before: int = state.progress.stat("well_fed_day")
	state.dev_week_hour(12)
	check(state.meal_period_now() == "lunch", "12h é o almoço")
	check(state.feed("puppy_mash"), "almoço servido")
	check(state.progress.stat("well_fed_day") == before + 1, "dia 1: uma refeição basta (regra do relógio, intacta)")
	state.dev_week_hour(19)
	check(state.meal_period_now() == "dinner" and state.feed("puppy_mash"), "jantar servido")
	check(state.progress.stat("well_fed_day") == before + 1, "o mesmo dia real não conta duas vezes")
	state.dev_week_goto(2)
	state.dev_week_hour(12)
	state.inventory.add("puppy_mash", 1)
	check(state.feed("puppy_mash") and state.progress.stat("well_fed_day") == before + 1, "dia 2: só o almoço ainda não fecha o dia")
	state.dev_week_hour(19)
	state.inventory.add("puppy_mash", 1)
	check(state.feed("puppy_mash") and state.progress.stat("well_fed_day") == before + 2, "dia 2: almoço + jantar na hora fecham o dia")
	check(state.week_day() == 2 and state.content_day() == 3, "calendário no dia 2, conteúdo no capítulo 3")

	# 5. Nenhum JSON de conteúdo guarda travas por dia do calendário.
	var banned := ["\"week_day\"", "\"fishing_day\"", "\"orchard_day\"", "\"from_day\"", "\"meal_open\""]
	_scan("res://data", banned)
	check(db_file_checks > 20, "varreu os JSON (%d)" % db_file_checks)

	print("NO DAY GATES TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)


func _scan(path: String, banned: Array) -> void:
	for file: String in DirAccess.get_files_at(path):
		if not file.ends_with(".json"):
			continue
		var text := FileAccess.get_file_as_string(path.path_join(file))
		db_file_checks += 1
		for key: String in banned:
			check(not text.contains(key), "%s ainda tem %s" % [path.path_join(file), key])
	for folder: String in DirAccess.get_directories_at(path):
		_scan(path.path_join(folder), banned)
