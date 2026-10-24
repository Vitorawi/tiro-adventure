class_name QuestGuide
extends RefCounted
## Qual passo da HISTÓRIA a pílula do próximo passo mostra e em que estado. Sem estado próprio: lê o GameState.

## {id, npc, goal, value, target, state, shared}; state ∈ "hidden", "progress", "talk", "ready",
## "shared_ready", "blocked_storage".
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
	return result
