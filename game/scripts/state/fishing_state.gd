class_name FishingState
extends RefCounted
## Pesca persistente: varas, isca escolhida, XP, recordes por espécie e a partida em andamento.
## Só dados e consultas puras; as regras (cast/hook/finish_fishing) ficam no GameState.

var rods: Array[String] = []  ## varas possuídas, em ordem de chegada
var rod: String = ""  ## vara escolhida ("" = a melhor)
var bait: String = ""  ## última isca escolhida
var xp: int = 0
## fish_id -> {best_cm, best_class, count, gigantes, perfects, first_at}
var records: Dictionary = {}
## Partida em andamento ({} = nenhuma): seed, bait, rod, zone, bubble, at, wait, state, fish, spent, pending_result.
var cast: Dictionary = {}
var since_large: int = 0  ## capturas seguidas sem Grande+ (garantia)
var bait_casts: Dictionary = {}  ## isca -> pescas com ela (garantia da história)
var bubble: Dictionary = {}  ## {"at": unix, "until": unix, "spot": i} ou {}
var next_bubble_at: float = 0.0
var tutorial: Dictionary = {"step": 0, "done": false}
var seq: int = 0  ## contador de partidas (entra na semente)


func reset() -> void:
	rods.clear()
	rod = ""
	bait = ""
	xp = 0
	records = {}
	cast = {}
	since_large = 0
	bait_casts = {}
	bubble = {}
	next_bubble_at = 0.0
	tutorial = {"step": 0, "done": false}
	seq = 0


func has_rod(id: String) -> bool:
	return id in rods


## Nível pela tabela de XP (`levels` = XP mínimo de cada nível, em ordem crescente).
func level(levels: Array) -> int:
	var result := 1
	for i in levels.size():
		if xp >= int(levels[i]):
			result = i + 1
	return result


func record(id: String) -> Dictionary:
	return records.get(id, {})


## Desloca os timestamps (ferramenta de dev "avançar tempo").
func shift_time(seconds: float) -> void:
	next_bubble_at -= seconds
	if not bubble.is_empty():
		bubble["at"] = float(bubble.at) - seconds
		bubble["until"] = float(bubble.until) - seconds
	if not cast.is_empty():
		cast["at"] = float(cast.get("at", 0.0)) - seconds


func to_dict() -> Dictionary:
	return {
		"rods": rods.duplicate(), "rod": rod, "bait": bait, "xp": xp,
		"records": records.duplicate(true), "cast": cast.duplicate(true),
		"since_large": since_large, "bait_casts": bait_casts.duplicate(),
		"bubble": bubble.duplicate(), "next_bubble_at": next_bubble_at,
		"tutorial": tutorial.duplicate(), "seq": seq,
	}


func from_dict(data: Dictionary) -> void:
	reset()
	for id: Variant in data.get("rods", []):
		if str(id) not in rods:
			rods.append(str(id))
	rod = str(data.get("rod", ""))
	bait = str(data.get("bait", ""))
	xp = maxi(0, int(data.get("xp", 0)))
	var loaded: Dictionary = data.get("records", {})
	for id: String in loaded:
		var entry: Dictionary = loaded[id]
		records[id] = {
			"best_cm": float(entry.get("best_cm", 0.0)), "best_class": str(entry.get("best_class", "")),
			"count": maxi(0, int(entry.get("count", 0))), "gigantes": maxi(0, int(entry.get("gigantes", 0))),
			"perfects": maxi(0, int(entry.get("perfects", 0))), "first_at": float(entry.get("first_at", 0.0)),
		}
	var saved_cast: Variant = data.get("cast", {})
	if saved_cast is Dictionary:
		cast = (saved_cast as Dictionary).duplicate(true)
	since_large = maxi(0, int(data.get("since_large", 0)))
	var casts: Dictionary = data.get("bait_casts", {})
	for id: String in casts:
		bait_casts[id] = maxi(0, int(casts[id]))
	var saved_bubble: Variant = data.get("bubble", {})
	if saved_bubble is Dictionary and not (saved_bubble as Dictionary).is_empty():
		bubble = {"at": float(saved_bubble.get("at", 0.0)), "until": float(saved_bubble.get("until", 0.0)), "spot": maxi(0, int(saved_bubble.get("spot", 0)))}
	next_bubble_at = float(data.get("next_bubble_at", 0.0))
	var saved_tutorial: Dictionary = data.get("tutorial", {})
	tutorial = {"step": maxi(0, int(saved_tutorial.get("step", 0))), "done": bool(saved_tutorial.get("done", false))}
	seq = maxi(0, int(data.get("seq", 0)))
