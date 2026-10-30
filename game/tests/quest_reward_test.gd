extends SceneTree
## Entrega única, voo, folha, destinos, capítulo e falha por depósito cheio.
var failures := 0
var state: Node
var main: Control
var events: Node
var ui: Script
var gains: Array[Dictionary] = []
var destinations: Array[String] = []

func _initialize() -> void: _run.call_deferred()
func frames() -> void:
	for i in 6: await process_frame
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("QUEST REWARD: " + message)
func clear_modals() -> void:
	main.set("_modal_queue", [] as Array[Callable])
	main.set("_quest_rewards", [] as Array[Dictionary])
	for member: String in ["_celebration", "_quest_reward", "_growth_ceremony", "_welcome", "_walk_result"]: main.get(member).hide()
func flush() -> void:
	await frames()
	main.call("_flush_modals")
	await frames()
func has_text(node: Node, value: String) -> bool:
	for label: Label in node.find_children("*", "Label", true, false):
		if label.text == value: return true
	return false

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	events = root.get_node("Events")
	ui = load("res://scripts/ui/progression_ui.gd")
	Motion.reduced = true
	state.call("reset")
	state.get("progress").seen.intro = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	events.items_gained.connect(func(items: Dictionary, coins: int, origin: Vector2) -> void: gains.append({"items": items.duplicate(), "coins": coins, "origin": origin}))
	events.world_requested.connect(func(world: String, spot: String) -> void: destinations.append(world + ":" + spot))
	await _welcome()
	await _chapter()
	await _character()
	await _other_claim_paths()
	await _full_storage()
	main.queue_free()
	await frames()
	Motion.reduced = false
	print("QUEST REWARD TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _welcome() -> void:
	main.call("show_screen", &"tasks")
	state.call("talk_to", "lais")
	await frames()
	var card: Control = main.find_child("StoryCard", true, false)
	var rect := card.get_global_rect()
	var coins: int = state.get("coins")
	var food: int = state.get("inventory").count("dog_food")
	var button: Button = card.find_child("ClaimQuest_welcome", true, false)
	check(button != null, "cartão pronto tem Pegar")
	if button: button.pressed.emit()
	await flush()
	var reward: CanvasLayer = main.get("_quest_reward")
	check(reward.visible, "folha aparece")
	check(main.find_children("QuestReward", "CanvasLayer", true, false).size() == 1, "uma única folha")
	check(has_text(reward.find_child("RewardChip_coins", true, false), "+5"), "chip +5 moedas")
	check(has_text(reward.find_child("RewardChip_dog_food", true, false), "+2"), "chip +2 rações")
	check(state.get("coins") == coins + 5 and state.get("inventory").count("dog_food") == food + 2, "ganhos exatos uma vez")
	check(gains.size() == 1 and gains[0].coins == 5 and gains[0].items.size() == 1 and int(gains[0].items.get("dog_food", 0)) == 2 and rect.has_point(gains[0].origin), "um voo com prêmios e origem no cartão")
	check(reward.find_child("NextStepCard", true, false).get_meta("quest") == "lais_feed", "próximo passo é alimentação")
	reward.find_child("RewardGo", true, false).pressed.emit()
	await frames()
	check("house:bowl" in destinations or "house:place:bowl" in destinations, "Ir usa destino da alimentação")
	check(not reward.visible, "Ir fecha a folha")
	# Reabre apenas a apresentação para testar Depois sem entregar de novo.
	reward.call("open", "welcome")
	check(reward.find_child("NextStepCard", true, false).get_meta("quest") == "lais_feed", "open(id) resolve o próximo passo atual")
	reward.find_child("RewardLater", true, false).pressed.emit()
	check(not reward.visible and state.get("coins") == coins + 5 and state.get("progress").current_main_quest() == "lais_feed", "Depois mantém o prêmio e o próximo passo")
	check(ui.call("claim_quest_fx", "welcome", Vector2.ZERO) != "", "segunda entrega recusada")
	await flush()
	check(not reward.visible and gains.size() == 1 and state.get("coins") == coins + 5, "sem duplicar voo, folha ou moedas")
	events.sheet_close_requested.emit()
	clear_modals()

func _chapter() -> void:
	state.call("reset")
	state.get("progress").seen.intro = true
	for id: String in state.get("progress").main_quests(1):
		if id == "growth_1_puppy": break
		state.call("dev_complete_quest", id)
	await frames()
	clear_modals()
	state.call("dev_set_phase", "puppy")
	await frames()
	clear_modals()
	check(state.get("progress").current_main_quest() == "growth_1_puppy", "último passo real do capítulo")
	check(ui.call("claim_quest_fx", "growth_1_puppy", Vector2(100, 200)) == "", "entrega último passo")
	await flush()
	check(main.get("_celebration").visible and not main.get("_quest_reward").visible, "só festa de capítulo")
	check(main.get("_celebration").find_child("NextStepCard", true, false) != null, "capítulo inclui próximo passo")
	clear_modals()

func _character() -> void:
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.get("progress").claimed_quests.erase("main_9_coop")
	state.call("_changed")
	await frames()
	clear_modals()
	main.call("show_screen", &"tasks")
	var tasks := main.find_child("TasksScreen", true, false)
	tasks.call("choose_group", "characters")
	await frames()
	var count := gains.size()
	var button := tasks.find_child("ClaimQuest_main_9_coop", true, false) as Button
	check(button != null, "Pessoas tem Pegar na linha pronta")
	if button: button.pressed.emit()
	await flush()
	check(not main.get("_quest_reward").visible and gains.size() == count + 1, "personagem tem voo sem folha")
	check(tasks.find_child("LineCard_bloblo", true, false) == null, "linha recebida some")
	clear_modals()

func _other_claim_paths() -> void:
	# A mesma entrega, agora pela pílula e pelo cartão usado nas conversas.
	for path: String in ["pill", "conversation", "help"]:
		state.call("reset")
		state.get("progress").seen.intro = true
		state.call("talk_to", "lais")
		main.call("show_screen", &"pet")
		await frames()
		clear_modals()
		var before := gains.size()
		if path == "pill": main.find_child("NextStep", true, false).pressed.emit()
		elif path == "help": load("res://scripts/ui/task_help.gd").call("_go", {"claim": "welcome"})
		else:
			var card := VBoxContainer.new()
			main.add_child(card)
			ui.call("quest_card", card, "welcome")
			card.find_child("ClaimQuest_welcome", true, false).pressed.emit()
			card.queue_free()
		await flush()
		check(gains.size() == before + 1 and main.get("_quest_reward").visible, path + " entrega com voo e folha")
		clear_modals()
	# Pegar tudo de Pessoas não mistura missões ou diárias e sai do HUD ao trocar de tela.
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	for id: String in ["main_9_coop", "lais_album"]: state.get("progress").claimed_quests.erase(id)
	state.get("progress").stats["open:album"] = 1
	state.call("_changed")
	await frames()
	clear_modals()
	main.call("show_screen", &"tasks")
	main.find_child("TasksScreen", true, false).call("choose_group", "characters")
	await frames()
	var all := main.find_child("ClaimAllCharacters", true, false) as Button
	check(all != null and main.find_child("TasksScreen", true, false).is_ancestor_of(all), "Pegar tudo de Pessoas fica no topo da lista (fora do HUD)")
	var before := gains.size()
	if all: all.pressed.emit()
	await flush()
	check(gains.size() == before + 2 and state.get("progress").claimed_quests.has("main_9_coop") and state.get("progress").claimed_quests.has("lais_album"), "Pegar tudo recebe as duas linhas uma vez")
	check(not main.get("_quest_reward").visible, "Pegar tudo de Pessoas não abre folha")
	main.call("show_screen", &"pet")
	await frames()
	var leftover := main.find_child("ClaimAllCharacters", true, false) as Control
	check(leftover == null or not leftover.is_visible_in_tree(), "atalho de Pessoas some fora da aba Missões")
	clear_modals()

func _full_storage() -> void:
	state.call("reset")
	state.get("progress").seen.intro = true
	var db := root.get_node("Database")
	# Fixture só em memória: mantém objetivo real e força prêmio de depósito finito.
	var rewards: Dictionary = db.get("quests").welcome.rewards.duplicate(true)
	db.get("quests").welcome.rewards = {"coins": 5, "items": {"egg": 1}}
	state.get("inventory").add("egg", int(state.call("storage_capacity", "fridge")))
	state.call("talk_to", "lais")
	main.call("show_screen", &"tasks")
	main.find_child("TasksScreen", true, false).call("choose_group", "story")
	await frames()
	check(not (state.call("quest_reward_shortage", "welcome") as Dictionary).is_empty(), "motor informa depósito cheio")
	var button := main.find_child("QuestSpace_welcome", true, false) as Button
	check(button != null and button.text == "Liberar espaço", "cartão oferece liberar espaço")
	var coins: int = state.get("coins")
	var count := gains.size()
	check(ui.call("claim_quest_fx", "welcome", Vector2.ZERO) != "", "falha não entrega")
	await flush()
	check(state.get("coins") == coins and gains.size() == count and not main.get("_quest_reward").visible, "sem pagamento, voo ou folha no erro")
	db.get("quests").welcome.rewards = rewards
