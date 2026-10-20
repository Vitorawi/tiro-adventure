extends SceneTree
## Refeições e Corpo: uma tarefa, nas cinco etapas, inclusive saves anteriores.

var state: Node
var db: Node
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Refeições do crescimento: " + message)

func fresh(phase: String) -> void:
	state.reset()
	state.growth.phase = phase
	state.growth.points = {}
	state.growth.reserve = {}
	for need: String in state.dog.needs: state.dog.needs[need] = 40.0
	state.dog.updated_at = state.now()

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	for index in range(1, db.growth.phases.size()):
		var phase: Dictionary = db.growth.phases[index]
		fresh(str(db.growth.phases[index - 1].id))
		var meals: Dictionary
		for req: Dictionary in phase.requirements:
			if req.type == "feed": meals = req
			if req.type == "pillars":
				check(req.levels.size() == 1 and not req.levels.has("body"), "cuidados independentes sem Corpo " + str(phase.id))
		var goal := int(db.growth.levels[int(meals.body_level) - 1])
		check(goal <= int(db.growth.levels[state.growth.cap() - 1]), "patamar cabe na fase atual")
		var item := str(meals.item)
		if item == "any": item = "carrot"  # Até comida sem XP próprio cumpre refeições comuns.
		elif item == "favorite": item = str(state.favorite_food())
		if meals.item != "any":
			state.inventory.add("carrot", 1)
			state.feed("carrot")
			check(not state.growth.firsts.has("meal_body:" + str(phase.id)), "comida diferente não cumpre a especial")
		state.inventory.add(item, int(meals.qty))
		for n in int(meals.qty):
			check(state.feed(item), "porção real " + str(phase.id))
			if n + 1 < int(meals.qty):
				check(not state.growth.firsts.has("meal_body:" + str(phase.id)), "parcial não antecipa a garantia")
		check(int(state.growth.points.get("body", 0)) >= goal, "porções completam Corpo " + str(phase.id))
		check(not state.growth_info().ready, "refeições não dispensam outros objetivos " + str(phase.id))
		var points := int(state.growth.points.body)
		var earned := int(state.progress.stat("pillar:body"))
		var reserve := int(state.growth.reserve.get("body", 0))
		var snapshot: Dictionary = state.to_dict().duplicate(true)
		state.growth_info()
		state.grow_error()
		check(state.to_dict() == snapshot, "consultas continuam puras")
		state.from_dict(snapshot)
		state._changed()
		check(state.growth.points.body == points and state.progress.stat("pillar:body") == earned, "reload não duplica pontos")
		check(int(state.growth.reserve.get("body", 0)) == reserve, "garantia não cria reserva repetida")
	# Save antigo: três refeições feitas, Corpo ainda em 6/10. Reconhece sem exigir repetir.
	fresh("newborn")
	state.progress.stats.feed = 3
	state.growth.points.body = 6
	state.growth.done = {"puppy": {"meals": true}}
	state.from_dict(state.to_dict())
	check(state.growth.points.body == 10, "save anterior com refeições completas recebe o Corpo faltante")
	state.from_dict(state.to_dict())
	check(state.growth.points.body == 10 and state.progress.stat("feed") == 3, "save não precisa de quarta refeição")
	# Grupo antigo confirmado preserva todos os cuidados, sem concluir os demais por engano.
	fresh("explorer")
	state.growth.firsts.erase("care_actions_v1")
	state.growth.done = {"young": {"pillars": true}}
	state.from_dict(state.to_dict())
	check(state.growth.done.young.care_smart and state.growth.done.young.care_coat, "confirmação antiga do grupo é preservada")
	fresh("explorer")
	state.growth.points.brave = 135
	state._changed()
	check(state.growth.done.young.get("pillars", false) and not state.growth.done.young.get("care_coat", false), "Carinho sozinho não completa Banhos")
	state.from_dict(state.to_dict())
	check(not state.growth.done.young.get("care_coat", false), "reload novo não espalha confirmação entre ações")
	print("GROWTH MEALS TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures else 0)
