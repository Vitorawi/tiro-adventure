class_name ProjectState
extends RefCounted
## Obras comunitárias (etapa 19 do plano R1): começou, taxa paga, fase atual, material já entregue por
## fase, conclusão e prêmio. Só dados + consultas puras + to_dict/from_dict; as AÇÕES ficam no GameState.
## Ids de projeto/fase são estáveis: entradas de ids que o catálogo atual não conhece são PRESERVADAS.

## Versão do esquema salvo (não confundir com SAVE_VERSION nem com a revisão da economia).
const SCHEMA := 1

var schema: int = SCHEMA
## id do projeto -> entrada (ver `blank`).
var projects: Dictionary = {}


## Entrada de um projeto que ainda não começou.
static func blank() -> Dictionary:
	return {
		"started": false,
		"paid_start": false,
		"phase_index": 0,
		"contributions": {},
		"completed": false,
		"completion_rewarded": false,
		"used_once": false,
		"completed_at": 0.0,
		"cycles": {},
	}


func reset() -> void:
	schema = SCHEMA
	projects = {}


## Cópia da entrada (nunca cria nada no estado: consultar não muda).
func entry(id: String) -> Dictionary:
	var base := blank()
	if projects.has(id):
		var saved: Dictionary = projects[id]
		for key: String in saved:
			base[key] = saved[key]
	return base


## Quanto do material já foi entregue na fase.
func given(id: String, phase_id: String, item: String) -> int:
	return int(projects.get(id, {}).get("contributions", {}).get(phase_id, {}).get(item, 0))


## Instante (Unix) da última conclusão: a da obra ou a do último ciclo do encontro repetível.
func last_done_at(id: String) -> float:
	var entry := entry(id)
	var last := float(entry.get("completed_at", 0.0))
	var cycles: Dictionary = entry.get("cycles", {}) if typeof(entry.get("cycles", {})) == TYPE_DICTIONARY else {}
	for key: String in cycles:
		if typeof(cycles[key]) == TYPE_DICTIONARY:
			last = maxf(last, float(cycles[key].get("at", 0.0)))
	return last


## Quantos ciclos do encontro já foram confirmados.
func cycle_count(id: String) -> int:
	var cycles: Variant = projects.get(id, {}).get("cycles", {})
	return cycles.size() if typeof(cycles) == TYPE_DICTIONARY else 0


func is_completed(id: String) -> bool:
	return bool(projects.get(id, {}).get("completed", false))


## Desloca os instantes de conclusão e de cada ciclo (ferramenta de dev "avançar tempo").
func shift_time(seconds: float) -> void:
	for id: String in projects:
		var entry: Dictionary = projects[id]
		if float(entry.get("completed_at", 0.0)) > 0.0:
			entry["completed_at"] = float(entry.completed_at) - seconds
		var cycles: Variant = entry.get("cycles", {})
		if typeof(cycles) == TYPE_DICTIONARY:
			for key: String in cycles:
				if typeof(cycles[key]) == TYPE_DICTIONARY and cycles[key].has("at"):
					cycles[key]["at"] = float(cycles[key].at) - seconds


func to_dict() -> Dictionary:
	return {"schema": schema, "projects": projects.duplicate(true)}


func from_dict(data: Dictionary) -> void:
	reset()
	# Save sem projetos (ou de versão mais nova): lê o que entender, sem apagar nada.
	schema = maxi(SCHEMA, int(data.get("schema", SCHEMA)))
	var saved: Dictionary = data.get("projects", {})
	for id: String in saved:
		if typeof(saved[id]) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = saved[id]
		var loaded: Dictionary = blank()
		for key: String in source:
			loaded[key] = source[key]
		loaded["started"] = bool(source.get("started", false))
		loaded["paid_start"] = bool(source.get("paid_start", false))
		loaded["phase_index"] = maxi(0, int(source.get("phase_index", 0)))
		loaded["completed"] = bool(source.get("completed", false))
		loaded["completion_rewarded"] = bool(source.get("completion_rewarded", false))
		loaded["used_once"] = bool(source.get("used_once", false))
		var contributions := {}
		var raw: Dictionary = source.get("contributions", {}) if typeof(source.get("contributions", {})) == TYPE_DICTIONARY else {}
		for phase_id: String in raw:
			var items := {}
			for item: String in raw[phase_id]:
				if int(raw[phase_id][item]) > 0:
					items[item] = int(raw[phase_id][item])
			contributions[phase_id] = items
		loaded["contributions"] = contributions
		projects[id] = loaded
