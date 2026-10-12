class_name ProgressionState
extends RefCounted
## Dados da progressão (Jornada): atributos, aquisições, missões, coleção,
## contadores, recargas e a atividade (rota) em andamento.
##
## Só dados + consultas puras. As AÇÕES (comprar, entregar, concluir...) ficam no
## GameState, que valida, altera estes dados e emite state_changed.
## Regras e números vêm de game/data/progression.json (Database.progression).

## XP total por atributo (skill_id -> int). Nível é derivado por skill_info().
var skills: Dictionary = {}
## Melhorias compradas (upgrade_id -> true): fogão, geladeira, sítio, bancada...
var owned: Dictionary = {}
## Contadores de ações ("feed", "harvest", "produce:plank", "activity:lane"...) usados pelas missões.
var stats: Dictionary = {}
## Missões cuja recompensa já foi recebida (quest_id -> true).
var claimed_quests: Dictionary = {}
## Primeira vez de cada coisa ("crop:carrot", "recipe:plank") rende XP em dobro.
var discoveries: Dictionary = {}
## Roupas/apetrechos conquistados (collection_id -> true). Vestir fica em DogState.outfit.
var collection: Dictionary = {}
## Conteúdo liberado sem cumprir requisitos ("crop:potato", "recipe:pumpkin_mash"): saves antigos e recompensas.
var unlocks: Dictionary = {}
## Recargas em timestamp Unix: "care:feed", "order:<id>", "emergency_food".
var cooldowns: Dictionary = {}
## Rota em andamento: { id, started_at, ready_at } ou vazio.
var activity: Dictionary = {}


func setup() -> void:
	for id: String in Database.progression.settings.get("initial_owned", []):
		owned[id] = true


func has_upgrade(id: String) -> bool:
	return bool(owned.get(id, false))


func stat(key: String) -> int:
	return int(stats.get(key, 0))


func count(key: String, amount: int = 1) -> void:
	stats[key] = stat(key) + amount


## Segundos até a recarga acabar (0 = disponível).
func cooldown_left(key: String, now: float) -> int:
	return maxi(0, int(ceil(float(cooldowns.get(key, 0.0)) - now)))


## XP total é salvo; nível e progresso são derivados da curva configurável:
## nível N -> N+1 custa skill_base_xp + (N-1) * skill_xp_step.
func skill_info(id: String) -> Dictionary:
	var settings: Dictionary = Database.progression.settings
	var remaining := maxi(0, int(skills.get(id, 0)))
	var current_level := 1
	var limit := int(settings.max_skill_level)
	var needed := _level_cost(1)
	while current_level < limit and remaining >= needed:
		remaining -= needed
		current_level += 1
		needed = _level_cost(current_level)
	return {"level": current_level, "xp": remaining, "needed": needed, "max": current_level >= limit}


func skill_level(id: String) -> int:
	return int(skill_info(id).level)


## XP total necessário para chegar ao nível pedido (usado pelas ferramentas de dev).
func xp_for_level(target: int) -> int:
	var total := 0
	for current in range(1, mini(target, int(Database.progression.settings.max_skill_level))):
		total += _level_cost(current)
	return total


func _level_cost(current_level: int) -> int:
	var settings: Dictionary = Database.progression.settings
	return int(settings.skill_base_xp) + (current_level - 1) * int(settings.skill_xp_step)


## Missão disponível = todas as anteriores ("requires") concluídas.
func quest_unlocked(id: String) -> bool:
	if not Database.quests.has(id):
		return false
	for required: String in Database.quests[id].get("requires", []):
		if not claimed_quests.has(required):
			return false
	return true


## Um único validador para lojas, culturas, receitas, rotas e pedidos.
## requirements = { "owned": [...], "quests": [...], "skills": { id: nível } }
func requirement_error(requirements: Dictionary) -> String:
	for id: String in requirements.get("owned", []):
		if not has_upgrade(id):
			return "Precisa de " + str(Database.progression.upgrades.get(id, {}).get("name", id))
	for id: String in requirements.get("quests", []):
		if not claimed_quests.has(id):
			return "Conclua: " + str(Database.quests.get(id, {}).get("name", id))
	for id: String in requirements.get("skills", {}):
		var needed := int(requirements["skills"][id])
		if skill_level(id) < needed:
			return "%s nível %d" % [Database.progression.skills.get(id, {}).get("name", id), needed]
	return ""


## Conteúdo (kind = "crop", "recipe"...) liberado por unlocks ou pelos requisitos do JSON.
func content_error(kind: String, id: String, data: Dictionary) -> String:
	if unlocks.has(kind + ":" + id):
		return ""
	return requirement_error(data.get("requirements", {}))


## Capítulo atual da história: o primeiro cujo alvo ainda não foi comprado.
func current_chapter() -> Dictionary:
	for chapter: Dictionary in Database.progression.chapters:
		if not has_upgrade(chapter.target):
			return chapter
	return Database.progression.get("final_chapter", {"name": "", "description": "", "target": ""})


## Desloca todos os timestamps (ferramenta de dev "avançar tempo").
func shift_time(seconds: float) -> void:
	for key: String in cooldowns:
		cooldowns[key] = float(cooldowns[key]) - seconds
	if not activity.is_empty():
		activity["started_at"] = float(activity.started_at) - seconds
		activity["ready_at"] = float(activity.ready_at) - seconds


func to_dict() -> Dictionary:
	return {
		"skills": skills, "owned": owned, "stats": stats,
		"claimed_quests": claimed_quests, "discoveries": discoveries,
		"collection": collection, "unlocks": unlocks,
		"cooldowns": cooldowns, "activity": activity,
	}


func from_dict(data: Dictionary) -> void:
	skills = data.get("skills", {}).duplicate(true)
	owned = data.get("owned", {}).duplicate(true)
	stats = data.get("stats", {}).duplicate(true)
	claimed_quests = data.get("claimed_quests", {}).duplicate(true)
	discoveries = data.get("discoveries", {}).duplicate(true)
	collection = data.get("collection", {}).duplicate(true)
	unlocks = data.get("unlocks", {}).duplicate(true)
	cooldowns = data.get("cooldowns", {}).duplicate(true)
	activity = data.get("activity", {}).duplicate(true)
	# Rota removida do JSON não pode travar o jogador para sempre.
	if not activity.is_empty() and not Database.progression.activities.has(str(activity.get("id", ""))):
		activity = {}
