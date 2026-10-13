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
## Coletas por local: até três { id, resource, started_at, ready_at, rewards } independentes.
var gathering: Dictionary = {}
## Diárias e semanais do período atual (kind = "daily" | "weekly"):
## { period: "2026-10-12", ids: [...], base: { contador: valor no início }, claimed: { id: true } }.
## Progresso = contador atual − base; não precisa de contador próprio.
var routines: Dictionary = {}
## Passo atual da história e o valor dos contadores quando ele começou (objetivos "fresh"):
## { quest: id, base: { contador: valor } }.
var step: Dictionary = {}
## Novidades já mostradas ao jogador ("feature:bag", "world:village", "place:village/gate", "npc:guide").
## O que está liberado e ainda não está aqui aparece na tela "Novo!".
var seen: Dictionary = {}


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


## Recurso revelado pela história (progression.json → features: bag, daily, weekly, skills).
func feature_unlocked(id: String) -> bool:
	return requirement_error(Database.progression.get("features", {}).get(id, {}).get("requirements", {})) == ""


func skills_visible() -> bool:
	return feature_unlocked("skills")


func npc_visible(id: String) -> bool:
	return requirement_error(Database.npcs.get(id, {}).get("requirements", {})) == ""


## Tudo o que a história já revelou: recursos e mundos, lugares e personagens que têm requisito.
func unlocked_keys() -> Array[String]:
	var keys: Array[String] = []
	for id: String in Database.progression.get("features", {}):
		if feature_unlocked(id):
			keys.append("feature:" + id)
	for world_id: String in Database.worlds:
		var world: Dictionary = Database.worlds[world_id]
		if not world.get("requirements", {}).is_empty() and requirement_error(world.requirements) == "":
			keys.append("world:" + world_id)
		for place_id: String in world.get("places", {}):
			var requirements: Dictionary = world.places[place_id].get("requirements", {})
			if not requirements.is_empty() and requirement_error(requirements) == "":
				keys.append("place:%s/%s" % [world_id, place_id])
	for id: String in Database.npcs:
		if not Database.npcs[id].get("requirements", {}).is_empty() and npc_visible(id):
			keys.append("npc:" + id)
	return keys


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
	if Database.quests[id].get("kind", "side") == "main":
		return id == current_main_quest()
	if requirement_error(Database.quests[id].get("requirements", {})) != "":
		return false
	for required: String in Database.quests[id].get("requires", []):
		if not claimed_quests.has(required):
			return false
	return true


## Um único validador para lojas, culturas, receitas, rotas e pedidos.
## requirements = { "owned": [...], "quests": [...], "skills": { id: nível } }
func requirement_error(requirements: Dictionary) -> String:
	if chapter_index() < int(requirements.get("chapter", 1)):
		return "Disponível no capítulo %d" % int(requirements.chapter)
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


## História derivada apenas das recompensas recebidas.
func main_quests(chapter: int) -> Array[String]:
	var result: Array[String] = []
	for id: String in Database.quests:
		var quest: Dictionary = Database.quests[id]
		if quest.get("kind", "side") == "main" and int(quest.get("chapter", 0)) == chapter:
			result.append(id)
	result.sort_custom(func(a: String, b: String) -> bool:
		return int(Database.quests[a].order) < int(Database.quests[b].order))
	return result


func chapter_index() -> int:
	for index in range(1, Database.progression.chapters.size() + 1):
		for id in main_quests(index):
			if not claimed_quests.has(id):
				return index
	return Database.progression.chapters.size() + 1


func current_main_quest() -> String:
	for id in main_quests(chapter_index()):
		if not claimed_quests.has(id):
			return id
	return ""


func current_chapter() -> Dictionary:
	var index := chapter_index()
	if index <= Database.progression.chapters.size():
		return Database.progression.chapters[index - 1]
	return Database.progression.get("final_chapter", {})


## Desloca todos os timestamps (ferramenta de dev "avançar tempo").
func shift_time(seconds: float) -> void:
	for key: String in cooldowns:
		cooldowns[key] = float(cooldowns[key]) - seconds
	if not activity.is_empty():
		activity["started_at"] = float(activity.started_at) - seconds
		activity["ready_at"] = float(activity.ready_at) - seconds
	for jobs: Array in gathering.values():
		for entry: Dictionary in jobs:
			if not entry.is_empty():
				entry["started_at"] = float(entry.started_at) - seconds
				entry["ready_at"] = float(entry.ready_at) - seconds


func to_dict() -> Dictionary:
	return {
		"skills": skills, "owned": owned, "stats": stats,
		"claimed_quests": claimed_quests, "discoveries": discoveries,
		"collection": collection, "unlocks": unlocks,
		"cooldowns": cooldowns, "activity": activity, "gathering": gathering, "routines": routines, "step": step, "seen": seen,
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
	gathering = {}
	for site: String in data.get("gathering", {}):
		if not Database.progression.nature_sites.has(site):
			continue
		var jobs: Array[Dictionary] = []
		for entry: Dictionary in data.gathering[site]:
			if jobs.size() >= 3:
				break
			jobs.append(entry.duplicate(true) if entry.is_empty() or Database.gathering_site(str(entry.get("id", ""))) == site else {})
		gathering[site] = jobs
	routines = data.get("routines", {}).duplicate(true)
	step = data.get("step", {}).duplicate(true)
	seen = data.get("seen", {}).duplicate(true)
	# Rota removida do JSON não pode travar o jogador para sempre.
	if not activity.is_empty() and not Database.progression.activities.has(str(activity.get("id", ""))):
		activity = {}
	# Save anterior: mantém a coleta em curso no primeiro espaço do local correto.
	if not data.has("gathering") and not activity.is_empty():
		var site := Database.gathering_site(str(activity.id))
		if site != "":
			gathering[site] = [activity.duplicate(true)]
			activity = {}
