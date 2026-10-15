class_name FriendState
extends RefCounted
## Amizades, janela monotônica local e presentes já sorteados. Sem acesso ao disco/UI.

var friends: Dictionary = {}
var window_index: int = 0
var visitor_window: String = ""
var visitor: String = ""
var last_active_at: float = 0.0


func entry(id: String) -> Dictionary:
	return friends.get(id, {"gifts": 0, "last_window": "", "claimed_hearts": 0, "best_at": 0.0, "last_visit": 0.0, "visit_pending": false, "visit_gift": {}})


func hearts(id: String, thresholds: Array) -> int:
	var total := 0
	for threshold: int in thresholds:
		if int(entry(id).gifts) >= threshold:
			total += 1
	return total


func to_dict() -> Dictionary:
	return {"friends": friends.duplicate(true), "window_index": window_index, "visitor_window": visitor_window, "visitor": visitor, "last_active_at": last_active_at}


func from_dict(data: Dictionary) -> void:
	friends = data.get("friends", {}).duplicate(true)
	window_index = int(data.get("window_index", 0))
	visitor_window = str(data.get("visitor_window", ""))
	visitor = str(data.get("visitor", ""))
	last_active_at = float(data.get("last_active_at", 0.0))
