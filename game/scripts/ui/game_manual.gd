class_name GameManual
extends RefCounted
## Consulta do catálogo: fontes dos itens e destinos, sem produzir/comprar nem alterar o progresso.
## Recursos, receitas, tempos e destinos são derivados do conteúdo do Database.


## Atalhos do Manual: o conteúdo mora no Caderninho (`CodexUi`, seções Recursos e Estações).
static func open(section: String = "resources") -> void:
	PetNotebook.open("stations" if section == "stations" else "resources")


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
	# Dentinho de leite: o primeiro montinho a partir de Dentinhos o garante (GameState._milk_tooth_due).
	if id == "milk_tooth":
		result.append({"kind": "find", "id": "farm"})
	for phase: Dictionary in Database.growth.get("phases", []):
		if phase.get("rewards", {}).get("items", {}).has(id) and Database.items.get(id, {}).get("category", "") == "keepsake":
			result.append({"kind": "growth", "id": str(phase.id)})
	for source: Dictionary in Database.item_sources(id):
		if source.key == "feed":
			result.append({"kind": "care", "id": id})
		elif str(source.key).begins_with("walk:"):
			result.append({"kind": "walk", "id": str(source.key).trim_prefix("walk:")})
	return result


static func focused(panel_id: String, focus: String = "") -> Dictionary:
	var location := Database.place_with_panel(panel_id)
	if location[0] == "":
		return {}
	return {"world": location[0], "place": focus if focus != "" else location[1], "spot": location[1]}
