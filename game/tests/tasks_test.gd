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
		var before_reward: int = state.get("coins")
		check(state.call("claim_quest", id) == "", "Receber passo " + id)
		var expected: int = int(database.get("quests")[id].rewards.get("coins", 0))
		if id == first.back():
			expected += int(database.get("progression").chapters[0].get("rewards", {}).get("coins", 0))
		check(state.get("coins") == before_reward + expected, "Pagamento exato do passo e capítulo")
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
	await _ui_check()
	print("TASKS TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)


func _ui_check() -> void:
	state.call("reset")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.call("show_screen", &"tasks")
	await create_timer(0.2).timeout
	var card: Control = main.find_child("StoryCard", true, false)
	check(card != null and card.size.y < 570, "Cartão da história deve caber na tela")
	check(main.get("_tasks_pulse") != null, "Guia pulsa no começo")
	check(main.find_child("MoodLabel", true, false).text == "Veja suas tarefas aqui embaixo!", "Guia do Tiro aparece no começo")
	state.get("progress").stats["feed"] = 1
	root.get_node("Events").emit_signal("state_changed")
	check(main.get("_tasks_badge").text == "1", "Badge conta a principal pronta uma vez")
	state.get("progress").stats["feed"] = 0
	root.get_node("Events").emit_signal("state_changed")
	await create_timer(0.2).timeout
	_shot("tasks_start")
	state.call("dev_jump_to_chapter", 3)
	await create_timer(2.2).timeout
	main.get_node("Celebration").hide()
	await process_frame
	await process_frame
	main.call("show_screen", &"tasks")
	check(main.get("_tasks_pulse") == null, "Guia para após welcome")
	_shot("tasks_middle")
	var ui: Script = load("res://scripts/ui/progression_ui.gd")
	var events: Node = root.get_node("Events")
	events.emit_signal("sheet_requested", "História", ui.call("story_panel"))
	await create_timer(0.3).timeout
	_shot("tasks_story")
	events.emit_signal("sheet_close_requested")
	events.emit_signal("sheet_requested", "Missões secundárias", ui.call("side_panel"))
	await create_timer(0.3).timeout
	_shot("tasks_side")
	main.get_node("Celebration").call("show_chapter", 2, PackedStringArray(["Trilha do riacho"]))
	await create_timer(0.2).timeout
	_shot("tasks_celebration")
	main.get_node("Celebration").hide()
	events.emit_signal("sheet_close_requested")
	state.call("dev_unlock_everything")
	await create_timer(2.2).timeout
	main.get_node("Celebration").hide()
	await process_frame
	await process_frame
	main.call("show_screen", &"tasks")
	_shot("tasks_end")
	main.queue_free()
	await process_frame


func _shot(file_name: String) -> void:
	if not "--screenshots" in OS.get_cmdline_user_args():
		return
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + file_name + ".png")
