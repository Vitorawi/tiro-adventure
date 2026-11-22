extends SceneTree
## A primeira sessão permite plantar, cozinhar e brincar. Inventar espera pelo jantar.

var failures := 0


func _initialize() -> void:
	run.call_deferred()


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("Onboarding: " + message)


func run() -> void:
	root.get_node("SaveManager").free()
	var state := root.get_node("GameState")
	var database := root.get_node("Database")
	state.set_script(load("res://tests/helpers/week_story_clock.gd"))
	state.set_clock(1792411200.0)
	state.reset()
	var route: RefCounted = load("res://tests/helpers/week_story_route.gd").new(state, database, check)
	route.day_one(false)
	route.at(2, 9)
	check(state.quest_unlocked("lais_first_wish"), "Dia seguinte retoma a História sem repetir a abertura")
	check(state.progress.current_main_quest() == "lais_first_wish", "O dia 1 fecha o capítulo 2; o dia seguinte abre o desejo (capítulo 3)")
	print("ONBOARDING TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
