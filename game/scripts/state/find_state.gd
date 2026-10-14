class_name FindState
extends RefCounted
## Faro persistente; o álbum vem dos contadores find_item, mesmo após vender.
var worlds: Dictionary = {}
var claimed_sets: Array[String] = []

func reset() -> void:
	worlds.clear()
	claimed_sets.clear()

func shift_time(seconds: float) -> void:
	for entry: Dictionary in worlds.values():
		entry.next_at = float(entry.next_at) - seconds

func to_dict() -> Dictionary:
	return {"worlds": worlds.duplicate(true), "claimed_sets": claimed_sets.duplicate()}

func from_dict(data: Dictionary) -> void:
	reset()
	for id: String in data.get("worlds", {}):
		var entry: Dictionary = data.worlds[id]
		worlds[id] = {"next_at": float(entry.get("next_at", 0)), "pending": clampi(int(entry.get("pending", 0)), 0, 1), "spot": maxi(0, int(entry.get("spot", 0))), "dug": maxi(0, int(entry.get("dug", 0))), "seed": int(entry.get("seed", 0))}
	for id: String in data.get("claimed_sets", []):
		if not id in claimed_sets:
			claimed_sets.append(id)
