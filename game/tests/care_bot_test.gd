extends SceneTree
## Política de cuidado: necessidades, teto, desejo e consumo real dos copinhos.
var failures := 0
var sim
var gs

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	sim = load("res://tests/helpers/economy_sim.gd").new(root, {"profile": "reference", "seed": 1, "ledger": "off", "out": ""})
	sim.setup()
	gs = sim.gs
	gs.dev_fill_needs()
	check(sim.bot._care(false).is_empty(), "satisfeito não pede cuidado")
	gs.dog.needs.happiness = 40
	check(sim.bot._care(false).kind == "pet", "carência no início pede carinho")
	gs.dog.needs.happiness = 100
	check(sim.bot._pursue_moment("brave").get("action", {}).get("kind", "") != "pet", "não esfrega para ganhar momentos sem necessidade")
	gs.growth.phase = "explorer"
	gs.inventory.add("carrot_snack", 2)
	var before: Dictionary = gs.to_dict().duplicate(true)
	var result: Dictionary = sim.bot._pursue_moment("smart")
	check(result.get("action", {}).get("kind", "") == "hide", "Esperteza faltando e petisco permitem copinhos")
	check(gs.to_dict() == before, "planejador só consulta")
	sim.in_session = true
	sim._digest_after = sim.digest()
	if result.state == "act": sim.perform(result.action, sim.action_cost(result.action))
	check(gs.inventory.count("carrot_snack") == 1 and gs.progress.stat("hide") == 1, "copinhos consomem um petisco e concluem pela ação pública")
	check(int(gs.growth.phase_moments.get("smart", 0)) == 1 and sim.violations.is_empty(), "momento real com conservação")
	gs.growth.period_moments[gs.moment_period() + ":smart"] = int(root.get_node("Database").growth.moments.period_cap)
	check(sim.bot._pursue_moment("smart").state == "wait", "teto impede gastar outro petisco")
	gs.growth.phase = "puppy"
	gs.dev_complete_quest("lais_bed")
	gs.update_wishes()
	var action: Dictionary = sim.bot.ph_wish_goals([] as Array[String])
	check(action.get("kind", "") == "pet", "desejo de carinho é atendido mesmo satisfeito")
	gs.pet()
	check(sim.bot.ph_wishes([] as Array[String]).get("kind", "") == "fulfill_wish", "pega o momento do desejo concluído")
	gs.inventory.add("blueberry_treat", 1)
	var meal: Dictionary = sim.bot.pursue_stat("feed:blueberry_treat", 1, false, 1, "nina_blueberry")
	check(meal.get("action", {}).get("args", {}).get("item", "") == "blueberry_treat", "missão de alimento específico nunca usa comida genérica")
	sim._digest_after = sim.digest()
	if meal.state == "act": sim.perform(meal.action, sim.action_cost(meal.action))
	check(gs.progress.stat("feed:blueberry_treat") == 1 and gs.inventory.count("blueberry_treat") == 0, "ação real alimenta com o petisco da missão")
	check(sim.violations.is_empty(), "regressão do alimento específico mantém conservação")
	print("CARE BOT TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
