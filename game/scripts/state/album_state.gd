class_name AlbumState
extends RefCounted
## Álbum de recordações do Tiro (etapa 13): fotos tiradas, dicas, lupas e janelas de eventos.
## Só dados + consultas puras + to_dict/from_dict; as regras ficam em `AlbumRules` e no `GameState`.

var schema: int = 1
## id -> {at, phase, coat, seen}: a foto guarda a fase e o pelo daquele dia.
var photos: Dictionary = {}
## id -> nível de dica já revelado (etapa 15).
var hints: Dictionary = {}
var lupa_day: String = ""
var lupas_used: int = 0
var photobomb_pity: int = 0
## Fotos penduradas na parede (etapa 14) e a foto principal do cantinho.
var wall: Array = []
var main_photo: String = ""
## evento -> lista de instantes Unix recentes (para `within` e `count_in_window`).
var recent: Dictionary = {}
var opened_at: Dictionary = {}
var spoken: Dictionary = {}
var years: Dictionary = {}
var party_from: float = 0.0
var party_until: float = 0.0
var sleep_spot: String = ""


func reset() -> void:
	schema = 1
	photos = {}
	hints = {}
	lupa_day = ""
	lupas_used = 0
	photobomb_pity = 0
	wall = []
	main_photo = ""
	recent = {}
	opened_at = {}
	spoken = {}
	years = {}
	party_from = 0.0
	party_until = 0.0
	sleep_spot = ""


func has_photo(id: String) -> bool:
	return photos.has(id)


func count() -> int:
	return photos.size()


## Fotos ainda não vistas pelo jogador (selo "Novo").
func unseen() -> Array[String]:
	var result: Array[String] = []
	for id: String in photos:
		if not bool(photos[id].get("seen", false)):
			result.append(id)
	return result


## Guarda o instante de um evento, mantendo só os últimos 16 (e nada com mais de uma hora).
func note(event: String, at: float) -> void:
	var list: Array = recent.get(event, [])
	list.append(at)
	var kept: Array = []
	for value: Variant in list:
		if at >= float(value) and at - float(value) <= 3600.0:
			kept.append(float(value))
	if kept.size() > 16:
		kept = kept.slice(kept.size() - 16)
	recent[event] = kept


## Quantas vezes o evento ocorreu nos últimos `seconds` (inclui o instante `at`).
func occurrences(event: String, seconds: float, at: float) -> int:
	var total := 0
	for value: Variant in recent.get(event, []):
		if at >= float(value) and at - float(value) <= seconds:
			total += 1
	return total


## Instante do evento anterior ao mais recente (0 = nunca), para `within`.
func last_before(event: String, at: float) -> float:
	var result := 0.0
	for value: Variant in recent.get(event, []):
		if float(value) <= at:
			result = maxf(result, float(value))
	return result


func to_dict() -> Dictionary:
	return {
		"schema": schema, "photos": photos.duplicate(true), "hints": hints.duplicate(), "lupa_day": lupa_day,
		"lupas_used": lupas_used, "photobomb_pity": photobomb_pity, "wall": wall.duplicate(), "main_photo": main_photo,
		"recent": recent.duplicate(true), "opened_at": opened_at.duplicate(), "spoken": spoken.duplicate(),
		"years": years.duplicate(), "party_from": party_from, "party_until": party_until, "sleep_spot": sleep_spot,
	}


func from_dict(data: Dictionary) -> void:
	reset()
	if data.get("photos") is Dictionary:
		for id: String in data.photos:
			if data.photos[id] is Dictionary:
				var entry: Dictionary = data.photos[id]
				photos[id] = {"at": float(entry.get("at", 0.0)), "phase": str(entry.get("phase", "newborn")),
					"coat": float(entry.get("coat", 0.0)), "seen": bool(entry.get("seen", false)), "equipped": (entry.get("equipped", {}) as Dictionary).duplicate()}
	if data.get("hints") is Dictionary: hints = data.hints.duplicate()
	lupa_day = str(data.get("lupa_day", ""))
	lupas_used = int(data.get("lupas_used", 0))
	photobomb_pity = int(data.get("photobomb_pity", 0))
	if data.get("wall") is Array: wall = data.wall.duplicate()
	main_photo = str(data.get("main_photo", ""))
	if data.get("recent") is Dictionary: recent = data.recent.duplicate(true)

	if data.get("opened_at") is Dictionary: opened_at = data.opened_at.duplicate()
	if data.get("spoken") is Dictionary: spoken = data.spoken.duplicate()
	if data.get("years") is Dictionary: years = data.years.duplicate()
	party_from = float(data.get("party_from", 0.0))
	party_until = float(data.get("party_until", 0.0))
	sleep_spot = str(data.get("sleep_spot", ""))
