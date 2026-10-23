class_name WishState
extends RefCounted
## Desejo do Tiro: um por vez, escolhido a cada período (manhã, tarde e noite).
##
## Só dados + consultas puras; as ações (sortear, cumprir) ficam no GameState.
## current = { id, item, period, progress, since }; vazio = sem desejo agora.
##   item = a comida resolvida quando o desejo é de comida; progress = contador do objetivo quando começou.
## last_ids = os últimos desejos (para não repetir).

var current: Dictionary = {}
## Período ("data:período") do último desejo criado: só um por período.
var period: String = ""
var last_ids: Array[String] = []
## Quantos desejos já foram atendidos.
var done_count: int = 0
## O primeiro desejo (logo depois da caminha) já saiu.
var first_done: bool = false


func _init() -> void:
	reset()


func reset() -> void:
	current = {}
	period = ""
	last_ids = []
	done_count = 0
	first_done = false


func has_current() -> bool:
	return not current.is_empty()


func to_dict() -> Dictionary:
	return {"current": current.duplicate(true), "period": period, "last_ids": last_ids.duplicate(), "done_count": done_count, "first_done": first_done}


func from_dict(data: Dictionary) -> void:
	reset()
	var saved: Variant = data.get("current", {})
	if saved is Dictionary and not (saved as Dictionary).is_empty():
		var entry: Dictionary = saved
		current = {
			"id": str(entry.get("id", "")), "item": str(entry.get("item", "")), "period": str(entry.get("period", "")),
			"progress": int(entry.get("progress", 0)), "since": float(entry.get("since", 0.0)),
		}
	period = str(data.get("period", ""))
	for id: Variant in data.get("last_ids", []):
		last_ids.append(str(id))
	done_count = int(data.get("done_count", 0))
	first_done = bool(data.get("first_done", false))
