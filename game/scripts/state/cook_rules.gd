class_name CookRules
extends RefCounted
## Regras puras do minigame "Cozinhar junto" (Primeira semana, E04). Números em `data/cooking.json`.
## Cada gesto (Picar, Mexer, Servir) rende de 1 a 3 brilhos; a soma dos três vira de 1 a 3 estrelas; as estrelas
## cortam o tempo do lote na fila. Nada aqui lê estado do jogo.


static func data() -> Dictionary:
	return Database.cooking


## Ids dos passos na ordem.
static func steps() -> Array:
	return data().get("steps", ["picar", "mexer", "servir"])


## Maior limite de uma lista `[[mínimo, valor], ...]` (ordenada do maior para o menor) que `amount` alcança.
static func _band(list: Array, amount: float, fallback: int) -> int:
	for entry: Variant in list:
		if amount >= float((entry as Array)[0]):
			return int((entry as Array)[1])
	return fallback


## Brilhos de um corte: `distance` = quanto o corte ficou longe da linha (unidades da tela de 360 de largura).
static func cut_brilho(distance: float) -> int:
	var rules: Dictionary = data().get("picar", {})
	if distance <= float(rules.get("perfect", 14)):
		return 3
	if distance <= float(rules.get("good", 34)):
		return 2
	return 1


## Média dos brilhos de um gesto repetido (cortes ou conchas) -> 1 a 3.
static func average_brilho(scores: Array) -> int:
	if scores.is_empty():
		return 1
	var total := 0.0
	for score: Variant in scores:
		total += float(score)
	return _band(data().get("brilho", {}).get("average", []), total / scores.size(), 1)


## Brilhos do Mexer pelo tempo que o anel levou para encher (`seconds_full` é o melhor tempo possível).
static func stir_brilho(elapsed: float) -> int:
	var rules: Dictionary = data().get("mexer", {})
	var ratio := float(rules.get("seconds_full", 8.0)) / maxf(elapsed, 0.01)
	return _band(rules.get("elapsed", []), ratio, 1)


## Zona da velocidade do giro (rad/s): "slow", "good" ou "fast".
static func stir_zone(speed: float, scale: float = 1.0) -> String:
	var rules: Dictionary = data().get("mexer", {})
	if speed < float(rules.get("min_speed", 1.2)) / scale:
		return "slow"
	if speed > float(rules.get("max_speed", 6.5)) * scale:
		return "fast"
	return "good"


## Brilhos de uma concha: dentro do centro 3, dentro do anel 2; cada tentativa errada antes tira 1 (mínimo 1).
## `distance` = distância do centro do anel; fora do anel devolve 0 (a concha volta).
static func serve_brilho(distance: float, misses: int) -> int:
	var rules: Dictionary = data().get("servir", {})
	if distance > float(rules.get("target_outer", 64)):
		return 0
	var base := 3 if distance <= float(rules.get("target_inner", 30)) else 2
	return maxi(1, base - misses)


## Estrelas (1 a 3) pela soma dos brilhos dos três passos.
static func stars_for(total: int) -> int:
	return _band(data().get("stars", {}).get("min_total", []), float(total), 1)


## Quanto do tempo da fila SOBRA com as estrelas (1 = 75%, 2 = 50%, 3 = 25%).
static func time_factor(stars: int) -> float:
	return 1.0 - time_cut(stars)


## Quanto do tempo as estrelas cortam (0,25 / 0,5 / 0,75).
static func time_cut(stars: int) -> float:
	return float(data().get("time_cut", {}).get(str(clampi(stars, 1, 3)), 0.0))
