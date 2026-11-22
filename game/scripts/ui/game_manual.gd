class_name GameManual
extends RefCounted
## Consulta do catálogo: fontes dos itens e destinos, sem produzir/comprar nem alterar o progresso.
## Recursos, receitas, tempos e destinos são derivados do conteúdo do Database.


## Atalhos do Manual: o conteúdo mora no Caderninho (`CodexUi`, seções Recursos e Estações).
static func open(section: String = "resources") -> void:
	PetNotebook.open(section if section in ["stations", "tutorials"] else "resources")


static func open_item(id: String) -> void:
	CodexSections.open_item(id)


## Fontes completas (inclusive recompensas de missão e ajuda de comida).
static func sources(id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key: String in Database.crops:
		if Database.crops[key].get("yield", {}).has(id):
			result.append({"kind": "crop", "id": key})
	for key: String in Database.recipes:
		if Database.recipe_output(Database.recipes[key]) == id:
			result.append({"kind": "recipe", "id": key})
	for key: String in Database.progression.activities:
		if Database.progression.activities[key].get("rewards", {}).get("items", {}).has(id):
			result.append({"kind": "route", "id": key})
	for key: String in Database.quests:
		if Database.quests[key].get("rewards", {}).get("items", {}).has(id):
			result.append({"kind": "quest", "id": key})
	for world: String in Database.finds.worlds:
		var entry: Dictionary = Database.finds.worlds[world]
		var found := false
		for reward: Dictionary in entry.get("guaranteed", []) + entry.get("table", []):
			found = found or reward.get("items", {}).has(id)
		if found:
			result.append({"kind": "find", "id": world})
	# Minhoca gorda: o faro a garante com a missão secreta da vovó aberta (GameState._golden_worm_due).
	if id == str(Database.meals.get("secret", {}).get("bait", "")):
		result.append({"kind": "find", "id": "farm"})
	# Dentinho de leite: o primeiro montinho a partir de Dentinhos o garante (GameState._milk_tooth_due).
	if id == "milk_tooth":
		result.append({"kind": "find", "id": "farm"})
	for phase: Dictionary in Database.growth.get("phases", []):
		if phase.get("rewards", {}).get("items", {}).has(id) and Database.items.get(id, {}).get("category", "") == "keepsake":
			result.append({"kind": "growth", "id": str(phase.id)})
	# Ingredientes dos pratos (E02): de onde vêm está em `dishes.json` (a horta, a banca, o pomar... chegam na E06).
	for ingredient_id: String in Database.dishes.get("ingredients", {}):
		if id in Database.dishes.ingredients[ingredient_id].get("items", []):
			result.append({"kind": "ingredient", "id": ingredient_id})
	if id == str(Database.dishes.get("gororoba", {}).get("item", "")):
		result.append({"kind": "gororoba", "id": id})  # sai de uma combinação que não formou prato
	for source: Dictionary in Database.item_sources(id):
		if source.key == "feed":
			result.append({"kind": "care", "id": id})
		elif str(source.key).begins_with("walk:"):
			result.append({"kind": "walk", "id": str(source.key).trim_prefix("walk:")})
		elif str(source.key).begins_with("fish:"):
			result.append({"kind": "fishing", "id": str(source.key).trim_prefix("fish:")})  # lagoa do Sítio
		elif str(source.key).begins_with("shop:"):
			result.append({"kind": "shop", "id": str(source.key).trim_prefix("shop:")})
	result.append_array(Database.week_reward_sources(id))
	return result


static func focused(panel_id: String, focus: String = "") -> Dictionary:
	var location := Database.place_with_panel(panel_id)
	if location[0] == "":
		return {}
	return {"world": location[0], "place": focus if focus != "" else location[1], "spot": location[1]}
