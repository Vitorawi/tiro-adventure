class_name WorkJobs
extends RefCounted
## Snapshots (contratos) de trabalhos iniciados: o que foi pago, o que vai sair, quanto XP vale.
## O mesmo construtor serve ao GameState (tabelas vivas, ao iniciar) e à migração (tabelas congeladas
## de data/legacy_r0.json, para trabalhos de saves antigos). Só dados; sem RNG nem efeitos.
##
## Colheita (`job` no canteiro): { crop, yield, coins, skill, skill_xp, player_xp }
## Lote de estação (`job` na fila): { output, qty, inputs, seconds, skill, skill_xp, player_xp_key,
##   player_xp, collection } — `collection` = true quando a saída é roupa/apetrecho.
## Rota (`rewards`/`player_xp` guardados em progress.activity/gathering) e passeio (`snapshot`).


static func crop(crop_id: String, crops: Dictionary, xp: Dictionary) -> Dictionary:
	var data: Dictionary = crops.get(crop_id, {})
	if data.is_empty():
		return {}
	return {
		"crop": crop_id,
		"yield": data.get("yield", {}).duplicate(),
		"coins": int(data.get("coins", 0)),
		"skill": "agriculture",
		"skill_xp": int(data.get("skill_xp", 10)),
		"player_xp": int(xp.get("harvest", 0)),
	}


## `qty` e `inputs` são o que o lote realmente produz/consome (já multiplicados pelos animais).
static func batch(recipe_id: String, recipes: Dictionary, xp: Dictionary, stations: Dictionary, qty: int, inputs: Dictionary) -> Dictionary:
	var recipe: Dictionary = recipes.get(recipe_id, {})
	if recipe.is_empty():
		return {}
	var collection := recipe.has("output_collection")
	var animal := str(stations.get(str(recipe.get("station", "")), {}).get("kind", "")) == "animal"
	var key := "animal" if animal else "cook"
	# `player_xp` na receita substitui o XP global da ação (nunca soma os dois).
	var player_xp := int(recipe.player_xp) if recipe.has("player_xp") else int(xp.get(key, 0))
	if recipe.has("player_xp"):
		key = "recipe"
	return {
		"output": str(recipe.get("output_collection", recipe.get("output", ""))),
		"collection": collection,
		"qty": qty,
		"inputs": inputs.duplicate(),
		"seconds": float(recipe.get("seconds", 0)),
		"skill": str(recipe.get("skill", "adventure" if collection else "cooking")),
		"skill_xp": int(recipe.get("skill_xp", 20 if collection else 10)),
		"player_xp_key": key,
		"player_xp": player_xp,
	}


## Lote de um save antigo, reconstruído UMA vez com a tabela congelada.
static func legacy_batch(entry: Dictionary, recipes: Dictionary, xp: Dictionary, stations: Dictionary) -> Dictionary:
	var recipe: Dictionary = recipes.get(str(entry.get("recipe", "")), {})
	if recipe.is_empty():
		return {}
	var base_qty := maxi(1, int(recipe.get("qty", 1)))
	var qty := int(entry.get("qty", base_qty))
	var factor := maxi(1, qty / base_qty)
	var inputs: Dictionary = recipe.get("inputs", {}).duplicate()
	for id: String in inputs:
		inputs[id] = int(inputs[id]) * factor
	return batch(str(entry.recipe), recipes, xp, stations, qty, inputs)


## Rota/coleta: moedas, itens e XP que o trabalho vai pagar.
static func route(route_id: String, activities: Dictionary) -> Dictionary:
	var data: Dictionary = activities.get(route_id, {})
	if data.is_empty():
		return {}
	return {"rewards": data.get("rewards", {}).duplicate(true), "player_xp": int(data.get("player_xp", 5))}


## Passeio: congela o caminho (tempo, necessidades, prêmios, sorteio), o lendário e as tabelas de
## achados citadas. O resultado em si ainda sai do sorteio com a semente guardada no passeio.
static func walk(walk_id: String, walks: Dictionary, find_worlds: Dictionary) -> Dictionary:
	var def: Dictionary = walks.get("walks", {}).get(walk_id, {})
	if def.is_empty():
		return {}
	var tables := {}
	for entry: Dictionary in def.get("loot", {}).get("table", []):
		var world := str(entry.get("find", ""))
		if world != "" and find_worlds.has(world):
			tables[world] = find_worlds[world].get("table", []).duplicate(true)
	return {"def": def.duplicate(true), "legendary": walks.get("legendary", {}).duplicate(true), "find_tables": tables}
