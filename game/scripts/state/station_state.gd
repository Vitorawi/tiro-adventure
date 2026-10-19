class_name StationState
extends RefCounted
## Fila de produção de uma estação (fogão, forno...), estilo Hay Day:
## um item por vez, cada um começa quando o anterior termina.
## Tempos são timestamps Unix, então a produção continua com o app fechado.

var queue: Array[Dictionary] = []  # { "recipe": String, "ready_at": float }


func enqueue(recipe_id: String, seconds: float, now: float) -> void:
	var start := now
	if not queue.is_empty():
		start = maxf(now, float(queue.back()["ready_at"]))
	queue.append({ "recipe": recipe_id, "ready_at": start + seconds })


## Tem receita em preparo (ainda não pronta)?
func is_busy(now: float) -> bool:
	for entry in queue:
		if float(entry["ready_at"]) > now:
			return true
	return false


func ready_count(now: float) -> int:
	var total := 0
	for entry in queue:
		if float(entry["ready_at"]) <= now:
			total += 1
	return total


## Remove e devolve as receitas prontas.
func take_ready(now: float) -> Array[String]:
	var done: Array[String] = []
	for entry: Dictionary in take_ready_batches(now):
		done.append(str(entry.recipe))
	return done


## Mantém a quantidade do lote alimentado, mesmo se novos animais forem comprados.
func take_ready_batches(now: float) -> Array[Dictionary]:
	var done: Array[Dictionary] = []
	var pending: Array[Dictionary] = []
	for entry in queue:
		if float(entry["ready_at"]) <= now:
			done.append(entry)
		else:
			pending.append(entry)
	queue = pending
	return done


func to_dict() -> Dictionary:
	return { "queue": queue }


func from_dict(data: Dictionary) -> void:
	queue.clear()
	for entry: Dictionary in data.get("queue", []):
		queue.append({ "recipe": str(entry["recipe"]), "ready_at": float(entry["ready_at"]) })
		if entry.has("qty"):
			queue.back()["qty"] = int(entry.qty)
		if entry.has("animals"):
			queue.back()["animals"] = entry.animals.duplicate()
		if entry.has("job"):
			queue.back()["job"] = (entry.job as Dictionary).duplicate(true)
