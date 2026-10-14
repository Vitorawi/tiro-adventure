class_name WishState
extends RefCounted
## Desejos do Tiro: até três espaços, cada um com um pedido (ou esperando outro).
##
## Só dados + consultas puras; as ações (sortear, cumprir, trocar) ficam no GameState.
## Espaço: { id, base, since, ready_at, special, last }.
##   id "" + ready_at > agora = esperando; id "" + ready_at <= agora = pronto para sortear.
##   base = contador do desejo de ação quando ele começou; last = último id (evita repetir ao trocar).

const SLOT_COUNT := 3

var slots: Array[Dictionary] = []
## Quantos desejos já foram cumpridos (os primeiros reabastecem rápido).
var done_count: int = 0
## O desejo inicial ("first" em wishes.json) já saiu.
var first_done: bool = false


func _init() -> void:
	reset()


func reset() -> void:
	slots = []
	for i in SLOT_COUNT:
		slots.append(empty_slot(0.0))
	done_count = 0
	first_done = false


static func empty_slot(ready_at: float, last: String = "") -> Dictionary:
	return {"id": "", "base": 0, "since": 0.0, "ready_at": ready_at, "special": false, "last": last}


## Ids dos desejos que estão em algum espaço.
func active_ids() -> Array[String]:
	var result: Array[String] = []
	for slot: Dictionary in slots:
		if str(slot.id) != "":
			result.append(str(slot.id))
	return result


## Desloca os timestamps (ferramenta de dev "avançar tempo").
func shift_time(seconds: float) -> void:
	for slot: Dictionary in slots:
		slot["ready_at"] = float(slot.ready_at) - seconds
		slot["since"] = float(slot.since) - seconds


func to_dict() -> Dictionary:
	return {"slots": slots.duplicate(true), "done_count": done_count, "first_done": first_done}


func from_dict(data: Dictionary) -> void:
	reset()
	var saved: Array = data.get("slots", [])
	for i in mini(saved.size(), SLOT_COUNT):
		var entry: Dictionary = saved[i]
		slots[i] = {
			"id": str(entry.get("id", "")), "base": int(entry.get("base", 0)), "since": float(entry.get("since", 0.0)),
			"ready_at": float(entry.get("ready_at", 0.0)), "special": bool(entry.get("special", false)), "last": str(entry.get("last", "")),
		}
	done_count = int(data.get("done_count", 0))
	first_done = bool(data.get("first_done", false))
