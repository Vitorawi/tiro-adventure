class_name Inventory
extends RefCounted
## Itens do jogador: item_id -> quantidade.

var counts: Dictionary = {}


func count(id: String) -> int:
	return int(counts.get(id, 0))


func add(id: String, amount: int = 1) -> void:
	counts[id] = count(id) + amount


func remove(id: String, amount: int = 1) -> bool:
	if count(id) < amount:
		return false
	counts[id] = count(id) - amount
	if counts[id] == 0:
		counts.erase(id)
	return true


func has_all(amounts: Dictionary) -> bool:
	for id: String in amounts:
		if count(id) < int(amounts[id]):
			return false
	return true


func remove_all(amounts: Dictionary) -> bool:
	if not has_all(amounts):
		return false
	for id: String in amounts:
		remove(id, int(amounts[id]))
	return true


func to_dict() -> Dictionary:
	return counts.duplicate()


func from_dict(data: Dictionary) -> void:
	counts.clear()
	for id: String in data:
		if int(data[id]) > 0:
			counts[id] = int(data[id])
