extends SceneTree
## Contratos da história e da migração, sem escrever o save pessoal.
var failures: int = 0
var state: Node
var database: Node
var quest_signals: Array[String] = []
var chapter_signals: Array[int] = []

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _run() -> void:
	state = root.get_node("GameState")
	database = root.get_node("Database")
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	state.call("reset")
	var old: Dictionary = state.call("to_dict").duplicate(true)
	old.coins = 137
	old.progression.owned = {"stove": true, "fridge": true, "farm": true}
	old.progression.claimed_quests = {"trail_friend": true}
	var migrated: Dictionary = saver.call("_migrate", {"save_version": 4, "state": old})
	state.call("from_dict", migrated.state)
	check(state.get("progress").chapter_index() == 4, "Save v4 deve abrir no capítulo 4")
	check(state.get("coins") == 137, "Migração não paga recompensas")
	check(state.get("progress").claimed_quests.has("trail_friend"), "Migração preserva secundárias")
	check(saver.call("_migrate", migrated) == migrated, "Migração é idempotente")
	saver.free()
	state.call("reset")
	var events: Node = root.get_node("Events")
	events.connect("quest_completed", func(id: String) -> void: quest_signals.append(id))
	events.connect("chapter_completed", func(index: int) -> void: chapter_signals.append(index))
	check(state.get("progress").current_main_quest() == "welcome", "História começa em welcome")
	check(not state.call("quest_unlocked", "first_harvest"), "Passo futuro não está liberado")
	check(state.call("requirement_error", {"chapter": 3}) != "", "Requisito de capítulo bloqueia")
	state.call("dev_add_coins", 1000)
	state.call("dev_add_items", 20)
	state.call("dev_set_skills", 10)
	var first: Array = state.get("progress").main_quests(1)
	for id: String in first:
		for goal: Dictionary in database.get("quests")[id].goals:
			match str(goal.type):
				"stat": state.get("progress").stats[goal.key] = int(goal.get("target", 1))
				"owned": state.get("progress").owned[goal.key] = true
		check(state.call("claim_quest", id) == "", "Receber passo " + id)
	check(quest_signals.size() == first.size() and chapter_signals == [1], "Sinais de passos e capítulo uma vez")
	var coins: int = state.get("coins")
	check(state.call("claim_quest", first.back()) != "" and state.get("coins") == coins, "Capítulo não paga duas vezes")
	# Missões sintéticas isolam consumo dos novos tipos.
	for kind: String in ["coins", "have", "deliver", "chapter"]:
		database.get("quests")["test_goal"] = {"kind": "side", "goals": [{"type": kind, "key": "carrot", "target": 1}], "rewards": {}}
		state.get("progress").claimed_quests.erase("test_goal")
		var before: int = state.get("inventory").count("carrot")
		coins = state.get("coins")
		check(state.call("claim_quest", "test_goal") == "", "Objetivo " + kind)
		check(state.get("coins") == coins, "Objetivo não consome moedas")
		check(state.get("inventory").count("carrot") == before - (1 if kind == "deliver" else 0), "Consumo de " + kind)
	database.get("quests").erase("test_goal")
	print("TASKS TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
