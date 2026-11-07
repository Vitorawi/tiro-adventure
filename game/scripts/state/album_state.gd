class_name AlbumState
extends RefCounted
## Álbum de recordações do Tiro (etapa 13): fotos tiradas, dicas, lupas e janelas de eventos.
## Só dados + consultas puras + to_dict/from_dict; as regras ficam em `AlbumRules` e no `GameState`.

var schema: int = 1
## id -> {at, phase, coat, seen, equipped, rarity (melhor), variants (estilos obtidos), shown (0 = o melhor), rolls, rerolls, best_at, rolled_at}.
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
## Raridade das fotos: garantias (sorteios seguidos sem Rara+ / sem Holográfica) e semente salva.
var pity_rare: int = 0
var pity_holo: int = 0
var rarity_seed: int = 0
## Varal da home (até `cards.featured_slots` ids) e o passo do tutorial das cartas.
var featured: Array[String] = []
var tutorial: Dictionary = {"step": 0, "done": false}


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
	pity_rare = 0
	pity_holo = 0
	rarity_seed = 0
	featured = []
	tutorial = {"step": 0, "done": false}


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
		"pity_rare": pity_rare, "pity_holo": pity_holo, "rarity_seed": rarity_seed,
		"featured": featured.duplicate(), "tutorial": tutorial.duplicate(),
	}


func from_dict(data: Dictionary) -> void:
	reset()
	if data.get("photos") is Dictionary:
		for id: String in data.photos:
			if data.photos[id] is Dictionary:
				var entry: Dictionary = data.photos[id]
				photos[id] = {"at": float(entry.get("at", 0.0)), "phase": str(entry.get("phase", "newborn")),
				"coat": float(entry.get("coat", 0.0)), "seen": bool(entry.get("seen", false)), "equipped": (entry.get("equipped", {}) as Dictionary).duplicate()}
				# Rarity 0 = carta ainda fechada (nunca aberta): sem nível nem versões.
				var rarity := clampi(int(entry.get("rarity", 0)), 0, 4)
				var kept: Array = []
				for v: Variant in entry.get("variants", []):
					if clampi(int(v), 1, 4) not in kept: kept.append(clampi(int(v), 1, 4))
				kept.sort()
				photos[id].merge({"rarity": rarity, "variants": kept, "shown": clampi(int(entry.get("shown", 0)), 0, 4),
						"rolls": int(entry.get("rolls", 0)), "rerolls": int(entry.get("rerolls", 0)),
						"best_at": float(entry.get("best_at", 0.0)), "rolled_at": float(entry.get("rolled_at", 0.0)),
						"sealed": maxi(0, int(entry.get("sealed", 0))), "sealed_at": float(entry.get("sealed_at", 0.0)),
						"upgrades": maxi(0, int(entry.get("upgrades", 0))), "opened_at": float(entry.get("opened_at", 0.0))})
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
	pity_rare = int(data.get("pity_rare", 0))
	pity_holo = int(data.get("pity_holo", 0))
	rarity_seed = int(data.get("rarity_seed", 0))
	if data.get("featured") is Array:
		for v: Variant in data.featured:
			if photos.has(str(v)) and str(v) not in featured: featured.append(str(v))
	if data.get("tutorial") is Dictionary:
		tutorial = {"step": clampi(int(data.tutorial.get("step", 0)), 0, 6), "done": bool(data.tutorial.get("done", false))}
