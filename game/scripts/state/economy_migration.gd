class_name EconomyMigration
extends RefCounted
## Migração de economia (etapa 02 do plano R1): pura, idempotente e SEM reset.
##
## Recebe o `state` do save (Dictionary) e devolve uma cópia carimbada com `economy.revision`.
## Não paga nada, não mexe em timestamps e não gera visita: só registra o que o save JÁ tinha,
## usando as tabelas congeladas (Database.legacy = data/legacy_r0.json), nunca os números vivos:
##   - piso de capacidade dos depósitos (compras, nunca estoque);
##   - recompensas automáticas já pagas (níveis, capítulos, vínculo) para não pagar de novo;
##   - snapshots dos trabalhos em andamento (canteiros, filas, rotas, passeio) com os rendimentos
##     e prazos do momento em que começaram;
##   - capítulo concluído segundo o mapa de missões ANTIGO, antes de inserir missões novas.
## Rodar duas vezes dá o mesmo resultado (a segunda encontra a revisão e não faz nada).


static func needs(state: Dictionary) -> bool:
	return not state.is_empty() and int(state.get("economy", {}).get("revision", 0)) < EconomyState.CURRENT_REVISION


static func migrate(state: Dictionary) -> Dictionary:
	if not needs(state):
		return state
	var data: Dictionary = state.duplicate(true)
	var legacy: Dictionary = Database.legacy
	var progression: Dictionary = data.get("progression", {})
	var economy: Dictionary = data.get("economy", {})
	var granted: Dictionary = economy.get("granted", {}).duplicate()
	# Recompensas automáticas que o save já recebeu (identidade estável por nível/capítulo/vínculo).
	for reached in range(2, int(data.get("level", 1)) + 1):
		granted["level:%d" % reached] = true
	var chapter := legacy_chapter_index(progression.get("claimed_quests", {}))
	for done in range(1, chapter):
		granted["chapter:%d" % done] = true
	# Piso legado: capacidade anterior comprada.
	var floors: Dictionary = economy.get("storage_floor", {}).duplicate()
	var owned: Dictionary = progression.get("owned", {})
	for depot: String in legacy.get("storage", {}):
		var floor_value := legacy_capacity(depot, owned)
		if floor_value > int(floors.get(depot, 0)):
			floors[depot] = floor_value
	# Trabalhos em andamento com o contrato do momento em que começaram.
	_freeze_plots(data, legacy)
	_freeze_stations(data, legacy)
	_freeze_routes(data, legacy)
	_freeze_walk(data, legacy)
	economy["revision"] = EconomyState.CURRENT_REVISION
	economy["storage_floor"] = floors
	economy["granted"] = granted
	economy["pending"] = economy.get("pending", {})
	economy["legacy"] = {"map": str(legacy.get("tabelas", "r0")), "chapter": chapter, "claimed": (progression.get("claimed_quests", {}) as Dictionary).size()}
	data["economy"] = economy
	return data


## Capacidade que o save TINHA comprada (0 = depósito não construído: continua sem limite).
static func legacy_capacity(depot: String, owned: Dictionary) -> int:
	var table: Dictionary = Database.legacy.get("storage", {}).get(depot, {})
	if table.is_empty() or not bool(owned.get(str(table.building), false)):
		return 0
	var total := int(table.base)
	for level: Dictionary in table.levels:
		if bool(owned.get(str(level.id), false)):
			total += int(level.capacity)
	return total


## Capítulo atual segundo o mapa congelado (mesma regra de ProgressionState.chapter_index).
static func legacy_chapter_index(claimed: Dictionary) -> int:
	var map: Dictionary = Database.legacy.get("quest_map", {})
	var chapters: int = Database.legacy.get("chapters", []).size()
	for index in range(1, chapters + 1):
		for id: String in map:
			if str(map[id].kind) == "main" and int(map[id].get("chapter", 0)) == index and not claimed.has(id):
				return index
	return chapters + 1


static func _freeze_plots(data: Dictionary, legacy: Dictionary) -> void:
	for entry: Dictionary in data.get("plots", []):
		if str(entry.get("crop", "")) == "" or entry.has("job"):
			continue
		var job := WorkJobs.crop(str(entry.crop), legacy.get("crops", {}), legacy.get("xp", {}))
		if not job.is_empty():
			entry["job"] = job


static func _freeze_stations(data: Dictionary, legacy: Dictionary) -> void:
	for station: Dictionary in data.get("stations", {}).values():
		for entry: Dictionary in station.get("queue", []):
			if entry.has("job"):
				continue
			var job := WorkJobs.legacy_batch(entry, legacy.get("recipes", {}), legacy.get("xp", {}), Database.stations)
			if not job.is_empty():
				entry["job"] = job


static func _freeze_routes(data: Dictionary, legacy: Dictionary) -> void:
	var progression: Dictionary = data.get("progression", {})
	var activities: Dictionary = legacy.get("activities", {})
	var jobs: Array = []
	var single: Dictionary = progression.get("activity", {})
	if not single.is_empty():
		jobs.append(single)
	for site_jobs: Array in progression.get("gathering", {}).values():
		for entry: Dictionary in site_jobs:
			if not entry.is_empty():
				jobs.append(entry)
	for entry: Dictionary in jobs:
		var route := WorkJobs.route(str(entry.get("id", "")), activities)
		if route.is_empty():
			continue
		if not entry.has("rewards"):
			entry["rewards"] = route.rewards
		if not entry.has("player_xp"):
			entry["player_xp"] = route.player_xp


static func _freeze_walk(data: Dictionary, legacy: Dictionary) -> void:
	var current: Dictionary = data.get("walks", {}).get("current", {})
	if current.is_empty() or current.has("snapshot"):
		return
	var snapshot := WorkJobs.walk(str(current.get("id", "")), legacy.get("walks", {}), legacy.get("find_worlds", {}))
	if not snapshot.is_empty():
		current["snapshot"] = snapshot
