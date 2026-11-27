extends SceneTree

var failures := 0
var state: Node
var db: Node


func _initialize() -> void:
	run.call_deferred()


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("E12 · " + message)


func run() -> void:
	root.get_node("SaveManager").free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/helpers/week_story_clock.gd"))
	state.set_clock(1792411200.0)
	state.reset()
	var route: RefCounted = load("res://tests/helpers/week_story_route.gd").new(state, db, check)
	var chapters := 0
	for i in range(1, 12):
		chapters += state.progress.main_quests(i).size()
	check(chapters == 41, "Onze capítulos com quarenta e um passos (o capítulo 1 junta o Ato 1 e o Ato 2)")
	for world: String in ["village", "park", "nature"]:
		check(state.requirement_error(db.worlds[world].requirements) != "", world + " fechada")
	route.run()
	check(state.growth.phase == "teething", "Fase Dentinhos")
	for photo: String in ["h_arrival", "f_bath", "h_growth_puppy", "h_first_trick", "h_week_group", "h_growth_teething"]:
		check(state.album.has_photo(photo), "Foto " + photo)
	for day in range(1, 8):
		check(state.progress.seen.has("week_surprise:%d" % day), "Surpresa do dia %d" % day)
	check(state.requirement_error(db.worlds.village.requirements) == "", "Vila aberta")
	check(state.requirement_error(db.worlds.park.requirements) != "" and state.requirement_error(db.worlds.nature.requirements) != "", "As travas seguintes continuam ligadas à história")
	route.restore(route.after_day_two)
	route.at(4, 11)
	check(state.progress.chapter_index() == 6 and state.quest_unlocked("week_bridge"), "Voltar depois de faltar retoma a lagoa")
	check(not state.progress.seen.has("week_surprise:3"), "A surpresa espera o capítulo")
	route.lake(4)
	check(state.quest_unlocked("week_orchard"), "O capítulo seguinte abre sem esperar o dia")
	var returned: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
	state.from_dict(returned)
	check(state.quest_unlocked("week_orchard"), "O capítulo aberto persiste após salvar e voltar")
	route.at(5, 11)
	check(state.progress.seen.has("week_surprise:3"), "Volta tardia libera a surpresa")
	check(state.economy.granted.has("week_morning:2") and state.economy.granted.has("purchase:week_coop"), "Recibos sobrevivem ao save")
	print("WEEK STORY TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
