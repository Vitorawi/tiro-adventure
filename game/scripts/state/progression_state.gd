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
## Roupas/apetrechos conquistados (collection_id -> true); slots vestidos em equipped.
var collection: Dictionary = {}
## Um apetrecho por lugar; saves anteriores começam sem roupa.
var equipped: Dictionary = {"head": "", "neck": "", "body": ""}
## Conteúdo liberado sem cumprir requisitos ("crop:potato", "recipe:pumpkin_mash"): saves antigos e recompensas.
var unlocks: Dictionary = {}
## Recargas em timestamp Unix: "care:feed", "order:<id>", "emergency_food".
var cooldowns: Dictionary = {}
## Truques aprendidos; sem campo em saves anteriores = nenhum.
var tricks: Dictionary = {}
## Rota em andamento: { id, started_at, ready_at } ou vazio.
var activity: Dictionary = {}
## Coletas por local: até três { id, resource, started_at, ready_at, rewards } independentes.
var gathering: Dictionary = {}
## XP próprio de cada região, ganho somente ao recolher uma coleta concluída.
var nature_xp: Dictionary = {}
## Diárias e semanais do período atual (kind = "daily" | "weekly"):
## { period: "2026-10-12", ids: [...], base: { contador: valor no início }, claimed: { id: true } }.
## Progresso = contador atual − base; não precisa de contador próprio.
var routines: Dictionary = {}
## Passo atual de cada linha ("main" = história da Laís, "bloblo"...) e o valor dos contadores
## quando ele começou (objetivos "fresh"): { linha: { quest: id, base: { contador: valor } } }.
var steps: Dictionary = {}
## Novidades já mostradas ao jogador ("feature:bag", "world:village", "place:village/gate", "npc:guide").
## O que está liberado e ainda não está aqui aparece na tela "Novo!".
var seen: Dictionary = {}
## A Casa que cresce (etapa 14): `toys` = brinquedos já no cesto; `arrived` = objetos que já chegaram
## (id -> Unix da chegada, anunciados uma vez só).
var house: Dictionary = {"toys": [], "arrived": {}}
## Momento em que o jogo começou (Unix) e a primeira vez de cada contador (chave -> Unix).
## Alimentam a seção "Ritmo" do painel DEV, para medir o começo do jogo.
var started_at: float = 0.0
var firsts: Dictionary = {}
## Presente do dia: { period: "AAAA-MM-DD" do último recebido, count: dias jogados que receberam }. Nunca zera.
var daily_gift: Dictionary = {"period": "", "count": 0}
## Maior nível de vínculo cujo presente já foi entregue (1 = nenhum).
var claimed_bond_level: int = 1


func setup() -> void:
	for id: String in Database.progression.settings.get("initial_owned", []):
		owned[id] = true


## Primeiras vezes em ordem, como "mm:ss  chave" (minutos desde o início do jogo).
func pace_lines() -> PackedStringArray:
	var keys: Array = firsts.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return float(firsts[a]) < float(firsts[b]))
	var lines := PackedStringArray()
	for key: String in keys:
		var seconds := maxi(0, int(float(firsts[key]) - started_at))
		lines.append("%02d:%02d  %s" % [seconds / 60, seconds % 60, key])
	return lines


## Nível de vínculo (1..N) para um afeto, pela lista progression.json → bond_levels.
func bond_level(affection: int) -> int:
	var level := 1
	var levels: Array = Database.progression.get("bond_levels", [])
	for i in levels.size():
		if affection >= int(levels[i].get("affection", 0)):
			level = i + 1
	return level


## Vínculo em detalhe: nível, afeto, base do nível, afeto do próximo (-1 = máximo) e o presente do próximo.
func bond_info(affection: int) -> Dictionary:
	var levels: Array = Database.progression.get("bond_levels", [])
	var level := bond_level(affection)
	var maximum := level >= levels.size()
	return {
		"level": level, "affection": affection, "floor": int(levels[level - 1].get("affection", 0)) if not levels.is_empty() else 0,
		"next": -1 if maximum else int(levels[level].get("affection", 0)), "max": maximum,
		"rewards": {} if maximum else levels[level].get("rewards", {}),
	}


func has_upgrade(id: String) -> bool:
	return bool(owned.get(id, false))


## Região aberta começa no nível 1; os demais vêm do XP de uso.
## Piso legado: ampliações já possuídas (tokens de nível e de vaga) nunca deixam o nível cair,
## mesmo que o XP guardado seja menor que o patamar novo (saves anteriores à etapa 11 da R1).
func nature_level(site: String) -> int:
	var data: Dictionary = Database.progression.nature_sites.get(site, {})
	if data.is_empty() or not has_upgrade(str(data.level_upgrades[0])):
		return 0
	var level := 1
	for i in data.levels.size():
		if int(nature_xp.get(site, 0)) >= int(data.levels[i].xp):
			level = i + 1
	for i in data.level_upgrades.size():
		if has_upgrade(str(data.level_upgrades[i])):
			level = maxi(level, i + 1)
	for i in data.slot_upgrades.size():
		if has_upgrade(str(data.slot_upgrades[i])):
			level = maxi(level, nature_slot_level(site, i))
	return mini(level, data.levels.size())


## Nível que libera a vaga extra `i` (0 = segunda vaga). Sem "slot_levels" vale o nível i + 2.
func nature_slot_level(site: String, index: int) -> int:
	var levels: Array = Database.progression.nature_sites[site].get("slot_levels", [])
	return int(levels[index]) if index < levels.size() else index + 2


## Marca as ampliações (nível e vaga) que o nível atual do local já contém.
func sync_nature_tokens(site: String) -> void:
	var config: Dictionary = Database.progression.nature_sites[site]
	var level := nature_level(site)
	for i in mini(level, config.level_upgrades.size()):
		owned[str(config.level_upgrades[i])] = true
	for i in config.slot_upgrades.size():
		if level >= nature_slot_level(site, i):
			owned[str(config.slot_upgrades[i])] = true


## Progresso até o próximo patamar. Quem está acima do que o XP mostra (piso legado) não perde nada:
## a barra fica no zero até o XP guardado alcançar o patamar, sem inventar XP retroativo.
func nature_info(site: String) -> Dictionary:
	var level := nature_level(site)
	var levels: Array = Database.progression.nature_sites[site].levels
	var total := maxi(0, int(nature_xp.get(site, 0)))
	var current := int(levels[maxi(0, level - 1)].xp)
	var maximum := level >= levels.size()
	var target := current if maximum else int(levels[level if level > 0 else 0].xp)
	return {"level":level, "total":total, "xp":clampi(total - current, 0, maxi(0, target - current)), "needed":target - current, "remaining":maxi(0, target - total), "max":maximum}


## Tipos de pedido já entregues num canal ("contracts" ou "neighbors"): ids com contador > 0.
func distinct_orders(channel: String) -> int:
	var kinds := 0
	for id: String in Database.progression.orders:
		if str(Database.progression.orders[id].get("channel", "neighbors")) == channel and stat("order:" + id) > 0:
			kinds += 1
	return kinds


## Confiança de um cliente: entregas totais e tipos distintos, derivados dos contadores `order:<id>`.
func customer_orders(customer: String) -> Dictionary:
	var total := 0
	var kinds := 0
	for id: String in Database.progression.orders:
		if str(Database.progression.orders[id].get("customer", "")) != customer:
			continue
		var done := stat("order:" + id)
		total += done
		if done > 0:
			kinds += 1
	return {"count": total, "kinds": kinds}


## Patamar de confiança (0..3) que o cliente já alcançou pelos contadores atuais.
func customer_level(customer: String) -> int:
	var seen := customer_orders(customer)
	var level := 0
	var tiers: Array = Database.progression.get("customer_tiers", [])
	for index in tiers.size():
		if int(seen.count) >= int(tiers[index].count) and int(seen.kinds) >= int(tiers[index].kinds):
			level = index + 1
	return level


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
	if not Database.progression.get("features", {}).has(id):
		return false
	var requirements: Dictionary = Database.progression.get("features", {}).get(id, {}).get("requirements", {})
	if requirements.has("growth"):
		return GameState.requirement_error(requirements) == ""
	return requirement_error(requirements) == ""


func skills_visible() -> bool:
	return false


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
		if not Database.npcs[id].get("requirements", {}).is_empty() and npc_visible(id) and not Database.npcs[id].get("decor", false):
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
	if Database.quests[id].has("shared_with"):
		return false  # marco da história, recebido junto da missão canônica
	if Database.quests[id].get("kind", "side") == "main":
		return id == current_main_quest()
	if Database.quests[id].get("kind", "side") == "line":
		return id == current_line_quest(str(Database.quests[id].line))
	if requirement_error(Database.quests[id].get("requirements", {})) != "":
		return false
	for required: String in Database.quests[id].get("requires", []):
		if not claimed_quests.has(required):
			return false
	return true


## Um único validador para lojas, culturas, receitas, rotas e pedidos.
## requirements = { "owned": [...], "quests": [...], "skills": { id: nível } }
func requirement_error(requirements: Dictionary) -> String:
	for item: String in requirements.get("produced", {}):
		var needed := int(requirements.produced[item])
		if stat("produce:" + item) < needed:
			return "Faça %d × %s" % [needed, Database.item_name(item)]
	for key: String in requirements.get("stats", {}):
		var missing := int(requirements.stats[key]) - stat(key)
		if missing > 0:
			var label: String = Database.progression.settings.get("stat_labels", {}).get(key, key)
			return "Faça mais %d %s" % [missing, label]
	for channel: String in requirements.get("distinct_orders", {}):
		var kinds := distinct_orders(channel)
		var wanted := int(requirements.distinct_orders[channel])
		if kinds < wanted:
			return "Faça %d tipos de contrato (tem %d)" % [wanted, kinds]
	if chapter_index() < int(requirements.get("chapter", 1)):
		var chapters: Array = Database.progression.get("chapters", [])
		var opens := int(requirements.chapter) - 1
		return "Abre em: " + str(chapters[opens].name) if opens >= 0 and opens < chapters.size() else "Ainda não"
	for id: String in requirements.get("owned", []):
		if not has_upgrade(id):
			return "Precisa de " + str(Database.progression.upgrades.get(id, {}).get("name", id))
	for id: String in requirements.get("quests", []):
		if not claimed_quests.has(id):
			return "Depois de: " + str(Database.quests.get(id, {}).get("name", id))
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


## Passo do personagem a seguir quando a história aponta para um marco de sua linha.
func displayed_main_quest() -> String:
	var id := current_main_quest()
	var shared := str(Database.quests.get(id, {}).get("shared_with", ""))
	if shared == "":
		return id
	var line := str(Database.quests[shared].get("line", ""))
	return current_line_quest(line) if line != "" else shared


## Linhas secundárias (kind "line"), na ordem em que aparecem em quests.json.
func lines() -> Array[String]:
	var result: Array[String] = []
	for id: String in Database.quests:
		var quest: Dictionary = Database.quests[id]
		if quest.get("kind", "side") == "line" and not result.has(str(quest.line)):
			result.append(str(quest.line))
	return result


func line_quests(line: String) -> Array[String]:
	var result: Array[String] = []
	for id: String in Database.quests:
		var quest: Dictionary = Database.quests[id]
		if quest.get("kind", "side") == "line" and str(quest.line) == line:
			result.append(id)
	result.sort_custom(func(a: String, b: String) -> bool:
		return int(Database.quests[a].order) < int(Database.quests[b].order))
	return result


## Passo ativo da linha: primeira missão não recebida, se os requisitos dela já valem.
## "" = linha concluída ou esperando (ex.: Bloblo antes de a Laís apresentar).
func current_line_quest(line: String) -> String:
	for id in line_quests(line):
		if claimed_quests.has(id):
			continue
		return id if requirement_error(Database.quests[id].get("requirements", {})) == "" else ""
	return ""


## Passo ativo de cada linha, com a história ("main") primeiro: { linha: quest_id }.
func active_steps() -> Dictionary:
	var result := {}
	var main := current_main_quest()
	if main != "" and not Database.quests[main].has("shared_with"):
		result["main"] = main
	for line in lines():
		var id := current_line_quest(line)
		if id != "":
			result[line] = id
	return result


## Linha dona da missão ("main" para a história).
func quest_line(id: String) -> String:
	var quest: Dictionary = Database.quests.get(id, {})
	return "main" if quest.get("kind", "side") == "main" else str(quest.get("line", ""))


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
		"skills": skills, "owned": owned, "stats": stats, "nature_levels_version": 2, "nature_xp": nature_xp,
		"claimed_quests": claimed_quests, "discoveries": discoveries,
		"collection": collection, "equipped": equipped, "unlocks": unlocks,
		"tricks": tricks, "cooldowns": cooldowns, "activity": activity, "gathering": gathering, "routines": routines, "steps": steps, "seen": seen, "house": house.duplicate(true),
			"started_at": started_at, "firsts": firsts, "daily_gift": daily_gift, "claimed_bond_level": claimed_bond_level,
	}


func from_dict(data: Dictionary) -> void:
	skills = data.get("skills", {}).duplicate(true)
	owned = data.get("owned", {}).duplicate(true)
	stats = data.get("stats", {}).duplicate(true)
	# Ferramentas antigas passam a valer como ampliações, sem cobrar novamente.
	for old: String in Database.progression.get("nature_legacy_upgrades", {}):
		if bool(owned.get(old, false)):
			owned[Database.progression.nature_legacy_upgrades[old]] = true
		owned.erase(old)
	if not data.has("nature_levels_version"):
		for site: String in Database.progression.nature_sites:
			var levels: Array = Database.progression.nature_sites[site].level_upgrades
			var highest := -1
			for i in levels.size():
				if has_upgrade(str(levels[i])):
					highest = i
			for route: String in Database.progression.activities:
				if Database.gathering_site(route) == site and stat("activity:" + route) > 0:
					highest = maxi(0, highest)
			var previous: Array = data.get("gathering", {}).get(site, []).duplicate(true)
			previous.append(data.get("activity", {}))
			for entry: Dictionary in previous:
				if Database.gathering_site(str(entry.get("id", ""))) == site:
					highest = maxi(0, highest)
			for i in highest + 1:
				owned[str(levels[i])] = true
	nature_xp = data.get("nature_xp", {}).duplicate(true)
	if int(data.get("nature_levels_version", 0)) < 2:
		# Mantém níveis/vagas adquiridos e transforma as coletas anteriores em experiência.
		for site: String in Database.progression.nature_sites:
			var config: Dictionary = Database.progression.nature_sites[site]
			var total := 0
			for route: String in Database.progression.activities:
				if Database.gathering_site(route) == site:
					total += stat("activity:" + route) * int(config.xp_per_collection)
			for i in config.level_upgrades.size():
				if has_upgrade(str(config.level_upgrades[i])):
					total = maxi(total, int(config.levels[i].xp))
			for i in config.slot_upgrades.size():
				if has_upgrade(str(config.slot_upgrades[i])):
					owned[str(config.level_upgrades[0])] = true
					total = maxi(total, int(config.levels[nature_slot_level(site, i) - 1].xp))
			nature_xp[site] = total
	for site: String in Database.progression.nature_sites:
		sync_nature_tokens(site)
	claimed_quests = data.get("claimed_quests", {}).duplicate(true)
	discoveries = data.get("discoveries", {}).duplicate(true)
	collection = data.get("collection", {}).duplicate(true)
	equipped = {"head": "", "neck": "", "body": ""}
	for slot: String in equipped:
		var id := str(data.get("equipped", {}).get(slot, ""))
		if collection.has(id) and Database.collections.get(id, {}).get("slot", "") == slot:
			equipped[slot] = id
	unlocks = data.get("unlocks", {}).duplicate(true)
	cooldowns = data.get("cooldowns", {}).duplicate(true)
	tricks = {}
	for id: String in data.get("tricks", {}):
		if Database.progression.tricks.has(id) and bool(data.tricks[id]):
			tricks[id] = true
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
	steps = data.get("steps", {}).duplicate(true)
	seen = data.get("seen", {}).duplicate(true)
	var saved_house: Dictionary = data.get("house", {}) if data.get("house") is Dictionary else {}
	house = {"toys": saved_house.get("toys", []).duplicate() if saved_house.get("toys") is Array else [],
		"arrived": saved_house.get("arrived", {}).duplicate() if saved_house.get("arrived") is Dictionary else {}}
	started_at = float(data.get("started_at", 0.0))
	firsts = data.get("firsts", {}).duplicate(true)
	daily_gift = {"period": str(data.get("daily_gift", {}).get("period", "")), "count": int(data.get("daily_gift", {}).get("count", 0))}
	claimed_bond_level = int(data.get("claimed_bond_level", 1))
	# Rota removida do JSON não pode travar o jogador para sempre.
	if not activity.is_empty() and not Database.progression.activities.has(str(activity.get("id", ""))):
		activity = {}
	# Save anterior: mantém a coleta em curso no primeiro espaço do local correto.
	if not data.has("gathering") and not activity.is_empty():
		var site := Database.gathering_site(str(activity.id))
		if site != "":
			gathering[site] = [activity.duplicate(true)]
			activity = {}
