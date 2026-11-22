class_name QuestGuide
extends RefCounted
## Qual passo da HISTÓRIA a pílula do próximo passo mostra e em que estado. Sem estado próprio: lê o GameState.

## {id, npc, goal, value, target, state, shared}; state ∈ "hidden", "progress", "talk", "ready",
## "shared_ready", "blocked_storage", "challenge" (só faltam as patinhas: desafio do dia em `challenge`).
static func current() -> Dictionary:
	var progress: ProgressionState = GameState.progress
	var id := progress.displayed_main_quest()
	var result := {"id": "", "npc": "", "goal": {}, "value": 0, "target": 1, "state": "hidden", "shared": false}
	if id == "" or not Database.quests.has(id) or progress.chapter_index() > Database.progression.chapters.size():
		return result
	var quest: Dictionary = Database.quests[id]
	var goal := ProgressionUi.current_goal(id)
	var target := int(goal.get("target", 1))
	result.id = id
	result.npc = str(quest.get("npc", ""))
	result.goal = goal
	result.target = target
	result.value = mini(GameState.goal_value(goal), target)
	result.shared = id != progress.current_main_quest()
	if not GameState.quest_reward_shortage(id).is_empty():
		result.state = "blocked_storage"
	elif GameState.quest_error(id) == "":
		result.state = "shared_ready" if result.shared else "ready"
	elif str(goal.get("type", "")) == "stat" and str(goal.get("key", "")).begins_with("talk:"):
		result.state = "talk"
	else:
		result.state = "progress"
	# Só faltam as patinhas: a pílula mostra o desafio do dia da vovó (nada a pegar nem a fazer na história).
	if result.state == "progress" and GameState.only_paws_left():
		var challenge := GameState.week_challenge()
		if not challenge.is_empty() and not challenge.paid:
			result.state = "challenge"
			result.npc = "bloblo"
			result.challenge = challenge
			result.goal = {"type": "stat", "key": str(challenge.counter), "label": str(challenge.label), "target": int(challenge.target)}
			result.target = int(challenge.target)
			result.value = mini(int(challenge.count), int(challenge.target))
	return result
