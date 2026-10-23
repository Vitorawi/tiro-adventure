extends SceneTree
## Refeições e Corpo: uma tarefa, nas cinco etapas, nas regras atuais.

var state: Node
var db: Node
var failures := 0
var feedback: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Refeições do crescimento: " + message)

func fresh(phase: String) -> void:
	state.reset()
	state.growth.phase = phase
	for need: String in state.dog.needs: state.dog.needs[need] = 40.0
	state.dog.updated_at = state.now()

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	root.get_node("Events").toast_requested.connect(func(message: String) -> void: feedback.append(message))
	for index in range(1, db.growth.phases.size()):
		var phase: Dictionary = db.growth.phases[index]
		fresh(str(db.growth.phases[index - 1].id))
		var meals: Dictionary
		for req: Dictionary in phase.requirements:
			if req.type == "feed": meals = req
			if req.type == "moments":
				check(req.pillar != "body", "cuidados independentes sem Corpo " + str(phase.id))
		var goal := int(meals.body_level)
		var item := str(meals.item)
		if item == "any": item = "carrot"  # Até comida sem XP próprio cumpre refeições comuns.
		elif item == "favorite": item = str(state.favorite_food())
		if meals.item != "any":
			state.inventory.add("carrot", 1)
			state.feed("carrot")
			check(not state.growth.firsts.has("meal_body:" + str(phase.id)), "comida diferente não cumpre a especial")
		state.inventory.add(item, int(meals.qty))
		for n in int(meals.qty):
			feedback.clear()
			check(state.feed(item), "porção real " + str(phase.id))
			check(feedback.any(func(message: String) -> bool: return message.begins_with("Refeições")), "porção anuncia impacto no crescimento " + str(phase.id))
			if n + 1 < int(meals.qty):
				check(not state.growth.firsts.has("meal_body:" + str(phase.id)), "parcial não antecipa a garantia")
		check(state.growth.body_level >= goal, "porções completam Corpo " + str(phase.id))
		check(not state.growth_info().ready, "refeições não dispensam outros objetivos " + str(phase.id))
		var body_level: int = state.growth.body_level
		var earned := int(state.progress.stat("moment:body"))
		var snapshot: Dictionary = state.to_dict().duplicate(true)
		state.growth_info()
		state.grow_error()
		check(state.to_dict() == snapshot, "consultas continuam puras")
		state.from_dict(snapshot)
		state._changed()
		check(state.growth.body_level == body_level and state.progress.stat("moment:body") == earned, "reload mantém Corpo")
	fresh("explorer")
	state.growth.phase_moments.brave = 4
	state._changed()
	check(state.growth.done.young.get("pillars", false) and not state.growth.done.young.get("care_coat", false), "Carinho sozinho não completa Banhos")
	state.from_dict(state.to_dict())
	check(not state.growth.done.young.get("care_coat", false), "reload novo não espalha confirmação entre ações")
	fresh("teething")
	state.growth.phase_moments.smart = 2
	state._changed()
	var smart_req: Dictionary
	for req: Dictionary in state.growth_info().requirements:
		if req.id == "care_smart": smart_req = req
	check(smart_req.need == 3 and not smart_req.done, "três momentos de Esperteza pedidos")
	state.growth.phase_moments.smart = 3
	state._changed()
	check(state.growth.done.explorer.care_smart, "três momentos completam brincadeiras")
	check(not state.growth.done.explorer.get("meals", false) and not state.growth_info().ready, "momentos não dispensam refeições")
	print("GROWTH MEALS TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures else 0)
