class_name Loot
extends RefCounted
## Sorteios de tabelas de conteúdo (achados, passeios, presentes). Funções puras e
## determinísticas: a mesma semente dá sempre o mesmo resultado.

## Escolhe uma entrada pelo campo "weight" (padrão 1). Lista vazia devolve {}.
static func pick_weighted(entries: Array, seed: int) -> Dictionary:
	if entries.is_empty():
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return _pick(entries, rng)


## Número vira ele mesmo; [a, b] sorteia entre a e b (inclusive).
static func amount(value: Variant, seed: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return _amount(value, rng)


## Faz `rolls` sorteios e soma o que cada entrada dá: { "coins": int, "items": { id: qtd } }.
## Cada entrada pode ter "coins" e/ou "items" (quantidades fixas ou faixas [min, max]).
static func roll(entries: Array, rolls: int, seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var coins := 0
	var items := {}
	for i in rolls:
		var entry := _pick(entries, rng)
		coins += _amount(entry.get("coins", 0), rng)
		var given: Dictionary = entry.get("items", {})
		for id: String in given:
			items[id] = int(items.get(id, 0)) + _amount(given[id], rng)
	return {"coins": coins, "items": items}


static func _pick(entries: Array, rng: RandomNumberGenerator) -> Dictionary:
	if entries.is_empty():
		return {}
	var total := 0.0
	for entry: Dictionary in entries:
		total += maxf(0.0, float(entry.get("weight", 1)))
	if total <= 0.0:
		return entries[0]
	var point := rng.randf() * total
	for entry: Dictionary in entries:
		point -= maxf(0.0, float(entry.get("weight", 1)))
		if point < 0.0:
			return entry
	return entries.back()


static func _amount(value: Variant, rng: RandomNumberGenerator) -> int:
	if value is Array and value.size() >= 2:
		return rng.randi_range(mini(int(value[0]), int(value[1])), maxi(int(value[0]), int(value[1])))
	return int(value)
