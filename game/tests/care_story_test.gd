extends SceneTree
## História e rotinas do ciclo de cuidado, com ações reais e save descartável.
var state: Node
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("CARE_STORY: " + message)

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.set_script(load("res://tests/helpers/economy_clock.gd"))
	state.set_clock(1792746000.0)
	state.reset()
	state.set_process(false)
	check(not state.quest_unlocked("lais_first_wish"), "desejo não antecipa a caminha")
	state.dev_complete_quest("lais_bed")
	check(not state.quest_unlocked("lais_first_wish"), "primeiro crescimento precede o desejo, sem ciclo")
	state.growth.phase = "puppy"
	check(state.claim_quest("growth_1_puppy") == "", "fecha o primeiro crescimento")
	check(state.quest_unlocked("lais_first_wish"), "Laís apresenta o desejo após a caminha e crescimento")
	check(state.quest_error("lais_first_wish") != "", "não termina sem atender")
	state.update_wishes()
	check(state.wish_id() == "pet", "primeiro pedido real é carinho")
	state.pet()
	check(state.quest_error("lais_first_wish") != "", "fazer carinho ainda pede Pegar no desejo")
	check(state.fulfill_wish() == "", "atende o desejo real")
	check(state.claim_quest("lais_first_wish") == "", "recebe o tutorial do desejo")
	check(state.progress.current_main_quest() == "lais_meet_bloblo", "história segue para a vovó")
	var help: Script = load("res://scripts/ui/task_help.gd")
	var wish_help: Dictionary = help.describe("stat", "wish")
	check(wish_help.target == {"screen": "pet"} and wish_help.action == "Ir" and "balão" in wish_help.detail, "ajuda do objetivo wish explica o balão e leva ao Tiro")
	for pillar: String in ["brave", "smart", "coat"]:
		var data: Dictionary = help.describe("moments", pillar)
		check(data.target == {"screen": "pet"} and data.action == "Ir", pillar + ": Ir leva ao Tiro")
		for source: Dictionary in root.get_node("Database").growth.moments.sources.values():
			if source.pillar == pillar and source.has("label"):
				check(str(source.label) in data.detail, pillar + ": fonte real explicada")
	for row: Dictionary in state.growth_info().requirements:
		if row.type != "moments": continue
		var data: Dictionary = help.describe("growth_req", str(row.id))
		check("De onde vêm" in str(data.steps[0].hint), "requisito real mostra as fontes no Como fazer")
	# Rotinas reais em vários períodos, com todo o catálogo liberado.
	state.dev_jump_to_chapter(12)
	state.progress.owned["stove"] = true
	var db := root.get_node("Database")
	for kind: String in ["daily", "weekly"]:
		check(not db.routines[kind].has("legacy"), kind + ": sem catálogo morto de cuidados")
		for mission: Dictionary in db.routines[kind].missions.values():
			check(mission.goal.key in ["harvest", "production_jobs", "orders"], kind + ": só fazenda")
		for period in 12:
			state.advance_clock(7 * 86400)
			var ids: Array = state.routine_ids(kind)
			check(ids.size() == int(db.routines[kind].count), kind + ": quantidade disponível")
			for id: String in ids:
				check(state.routine_data(kind, id).goal.key in ["harvest", "production_jobs", "orders"], kind + ": sorteio sem cuidado")
	var clothes: Array = db.routines.weekly.missions.big_harvest.rewards.collections + db.routines.weekly.missions.orders_week.rewards.collections
	for id: String in ["clean_bow", "heart_collar", "walker_bandana"]:
		check(id in clothes, id + ": continua disponível nas semanais")
	check("Tiro animado" in db.quests.lais_first_crops.dialogue, "Sítio apresenta o Tiro animado")
	# Progresso histórico atual: atender antes de abrir o passo também vale.
	state.reset()
	state.set_process(false)
	state.progress.stats["wish"] = 1
	state.dev_complete_quest("growth_1_puppy")
	check(state.quest_error("lais_first_wish") == "", "primeiro desejo já atendido não exige outro período")
	print("CARE STORY TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
