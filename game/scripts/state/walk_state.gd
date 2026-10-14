class_name WalkState
extends RefCounted
## Passeio do Tiro: um por vez (o Tiro é um só). Guarda timestamps Unix, então o passeio
## termina sozinho com o app fechado. `pity` e `history` preservam a garantia e as voltas por caminho.

## { "id", "started_at", "ready_at", "seed", "energy" } ou vazio.
var current: Dictionary = {}
## id do passeio -> passeios seguidos sem raro (garantia da Etapa 07).
var pity: Dictionary = {}
## id do passeio -> { "count": int }.
var history: Dictionary = {}


func reset() -> void:
	current = {}
	pity = {}
	history = {}


func active() -> bool:
	return not current.is_empty()


func remaining(now: float) -> int:
	return maxi(0, ceili(float(current.get("ready_at", 0.0)) - now)) if active() else 0


func ready(now: float) -> bool:
	return active() and float(current.ready_at) <= now


func shift_time(seconds: float) -> void:
	if active():
		current.started_at = float(current.started_at) - seconds
		current.ready_at = float(current.ready_at) - seconds


func to_dict() -> Dictionary:
	return {"current": current.duplicate(true), "pity": pity.duplicate(), "history": history.duplicate(true)}


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
	for id: String in data.get("pity", {}):
		pity[id] = maxi(0, int(data.pity[id]))
	for id: String in data.get("history", {}):
		history[id] = {"count": maxi(0, int(data.history[id].get("count", 0)))}
