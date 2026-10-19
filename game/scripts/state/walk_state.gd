class_name WalkState
extends RefCounted
## Passeio do Tiro: viagem e bagagem são estados diferentes (etapa 03 do plano de economia).
## - `current`: a VIAGEM, só enquanto o Tiro não voltou. Guarda timestamps Unix, então o passeio
##   termina sozinho com o app fechado.
## - `pending_return`: a BAGAGEM, no máximo uma. Nasce quando a viagem termina (`GameState.return_due_walk`),
##   já com o resultado sorteado e congelado; o Tiro está em casa mesmo que os achados não caibam.
## `pity` e `history` preservam a garantia e as voltas por caminho.

## { "id", "started_at", "ready_at", "seed", "energy", "snapshot" } ou vazio (`snapshot` = contrato congelado ao sair).
var current: Dictionary = {}
## Bagagem da última volta ou vazio:
## { "id", "started_at", "ready_at", "returned_at", "seed", "result": resultado congelado,
##   "left": { item: quantidade ainda por guardar }, "rewards_applied": bool, "result_shown": bool }.
var pending_return: Dictionary = {}
## id do passeio -> passeios seguidos sem raro (garantia da Etapa 07).
var pity: Dictionary = {}
## id do passeio -> { "count": int }.
var history: Dictionary = {}


func reset() -> void:
	current = {}
	pending_return = {}
	pity = {}
	history = {}


## Há viagem não retornada (andando ou já com o tempo vencido e ainda não liquidada).
func active() -> bool:
	return not current.is_empty()


func remaining(now: float) -> int:
	return maxi(0, ceili(float(current.get("ready_at", 0.0)) - now)) if active() else 0


## O tempo da viagem acabou (a liquidação `return_due_walk` ainda pode não ter rodado).
func due(now: float) -> bool:
	return active() and float(current.get("ready_at", 0.0)) <= now


## O Tiro está fora de verdade: viagem com tempo restante.
func traveling(now: float) -> bool:
	return active() and float(current.get("ready_at", 0.0)) > now


func has_baggage() -> bool:
	return not pending_return.is_empty()


## Achados que ainda esperam para ser guardados.
func baggage_left() -> Dictionary:
	return pending_return.get("left", {})


func baggage_count() -> int:
	var total := 0
	for amount: int in baggage_left().values():
		total += amount
	return total


func shift_time(seconds: float) -> void:
	if active():
		current.started_at = float(current.started_at) - seconds
		current.ready_at = float(current.ready_at) - seconds
	if has_baggage():
		pending_return.returned_at = float(pending_return.returned_at) - seconds


func to_dict() -> Dictionary:
	return {"current": current.duplicate(true), "pending_return": pending_return.duplicate(true), "pity": pity.duplicate(), "history": history.duplicate(true)}


func from_dict(data: Dictionary) -> void:
	reset()
	var entry: Dictionary = data.get("current", {})
	if not entry.is_empty() and Database.walks.walks.has(str(entry.get("id", ""))):
		current = {
			"id": str(entry.id),
			"started_at": float(entry.get("started_at", 0.0)),
			"ready_at": float(entry.get("ready_at", 0.0)),
			"seed": int(entry.get("seed", 0)),
			"energy": int(entry.get("energy", 0)),
		}
		if entry.has("snapshot"):
			current["snapshot"] = (entry.snapshot as Dictionary).duplicate(true)
	_load_return(data.get("pending_return", {}))
	for id: String in data.get("pity", {}):
		pity[id] = maxi(0, int(data.pity[id]))
	for id: String in data.get("history", {}):
		history[id] = {"count": maxi(0, int(data.history[id].get("count", 0)))}


func _load_return(entry: Dictionary) -> void:
	if entry.is_empty() or not entry.has("result"):
		return
	var left := {}
	for item: String in entry.get("left", {}):
		if int(entry.left[item]) > 0:
			left[item] = int(entry.left[item])
	var shown := bool(entry.get("result_shown", false))
	# Bagagem vazia cujo resultado já foi visto não tem mais o que mostrar.
	if left.is_empty() and shown:
		return
	pending_return = {
		"id": str(entry.get("id", "")),
		"started_at": float(entry.get("started_at", 0.0)),
		"ready_at": float(entry.get("ready_at", 0.0)),
		"returned_at": float(entry.get("returned_at", entry.get("ready_at", 0.0))),
		"seed": int(entry.get("seed", 0)),
		"result": (entry.result as Dictionary).duplicate(true),
		"left": left,
		"rewards_applied": bool(entry.get("rewards_applied", true)),
		"result_shown": shown,
	}
