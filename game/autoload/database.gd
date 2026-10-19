extends Node
## Conteúdo do jogo, lido de game/data/*.json (autoload "Database").
##
## Itens, receitas, necessidades, ações e valores iniciais vivem nos JSON.
## Para adicionar conteúdo, edite os JSON — não o código dos sistemas.

var items: Dictionary = {}
var recipes: Dictionary = {}
var needs: Dictionary = {}
## Proteção da ausência (config.json "offline"): fração da taxa e teto de horas de queda por ausência contínua.
var offline: Dictionary = {}
var actions: Dictionary = {}
var stations: Dictionary = {}
var animals: Dictionary = {}
## Plantas da horta (data/crops.json): tempo, colheita e sprite da planta madura.
var crops: Dictionary = {}
## Sítio: nome, quantidade de canteiros e sprite do broto (config.json "farm").
var farm: Dictionary = {}
var xp: Dictionary = {}
var start: Dictionary = {}
## Versão publicada (commit + data), gravada pelo deploy em data/version.json.
var version: Dictionary = {}
var progression: Dictionary = {}
var quests: Dictionary = {}
var npcs: Dictionary = {}
var collections: Dictionary = {}
## Mundos (casa, sítio, vila...): lugares, personagens e requisitos (data/worlds.json).
var worlds: Dictionary = {}
## Missões diárias e semanais (data/routines.json): modelos sorteados a cada período.
var routines: Dictionary = {}
## Desejos do Tiro (data/wishes.json): configurações e modelos de pedidos.
var wishes: Dictionary = {}
## Achados, sorteios e conjuntos do faro.
var finds: Dictionary = {}
## Passeios do Tiro (data/walks.json): configurações e caminhos.
var walks: Dictionary = {}
var friends: Dictionary = {}
## Obras comunitárias (data/projects.json): fases, taxa, prêmio. Vazio até as etapas 20–22.
var projects: Dictionary = {}
## Tabelas congeladas antes da R1 (data/legacy_r0.json): capacidades, rendimentos, mapa de missões. Só a migração lê.
var legacy: Dictionary = {}


func _init() -> void:
	# Carrega no _init para estar pronto antes do _ready dos outros autoloads.
	items = _load("res://data/items.json")
	recipes = _load("res://data/recipes.json")
	crops = _load("res://data/crops.json")
	var config := _load("res://data/config.json")
	needs = config.get("needs", {})
	offline = config.get("offline", {})
	actions = config.get("actions", {})
	stations = config.get("stations", {})
	animals = config.get("animals", {})
	farm = config.get("farm", {})
	xp = config.get("xp", {})
	start = config.get("start", {})
	version = _load("res://data/version.json")
	progression = _load("res://data/progression.json")
	quests = _load("res://data/quests.json")
	npcs = _load("res://data/npcs.json")
	collections = _load("res://data/collections.json")
	worlds = _load("res://data/worlds.json")
	routines = _load("res://data/routines.json")
	wishes = _load("res://data/wishes.json")
	finds = _load("res://data/finds.json")
	walks = _load("res://data/walks.json")
	friends = _load("res://data/friends.json")
	projects = _load("res://data/projects.json")
	legacy = _load("res://data/legacy_r0.json")


## Mundo onde o personagem mora ("" se nenhum).
func npc_world(npc_id: String) -> String:
	for id: String in worlds:
		if npc_id in worlds[id].get("npcs", []):
			return id
	return ""


func gathering_site(route_id: String) -> String:
	var group: String = progression.activities.get(route_id, {}).get("place", "")
	for id: String in progression.get("nature_sites", {}):
		if group in progression.nature_sites[id].groups:
			return id
	return ""


## Lugar do mundo que abre um painel (ex.: "station:stove" -> "stove" na casa). Devolve [mundo, lugar].
## Um lugar pode juntar painéis: "stations:stove+oven" atende "station:stove" e "station:oven";
## "market:<aba>" atende "sell" e "orders"; "routes:walk+mine" atende "routes:walk" e "routes:mine".
func place_with_panel(panel: String) -> Array[String]:
	# Um objeto com painel próprio é destino melhor que um agrupamento de estações.
	for world_id: String in worlds:
		for place_id: String in worlds[world_id].get("places", {}):
			if worlds[world_id].places[place_id].get("panel", "") == panel:
				return [world_id, place_id]
	for world_id: String in worlds:
		var places: Dictionary = worlds[world_id].get("places", {})
		for place_id: String in places:
			if panel in panel_parts(places[place_id].get("panel", "")):
				return [world_id, place_id]
	return ["", ""]


## Painéis simples que um painel de lugar atende (ver place_with_panel).
func panel_parts(panel: String) -> PackedStringArray:
	var kind := panel.get_slice(":", 0)
	var args := panel.get_slice(":", 1).split("+") if ":" in panel else PackedStringArray()
	match kind:
		"petshop":
			return PackedStringArray(["petshop"])
		"stations":
			var parts: PackedStringArray = []
			for id in args:
				parts.append("station:" + id)
			return parts
		"market":
			return PackedStringArray(["sell", "orders"])
		"sell":
			return PackedStringArray(["sell", "market:sell"])
		"orders":
			return PackedStringArray(["orders", "market:orders"])
		"routes", "nature":
			var parts: PackedStringArray = []
			for id in args:
				parts.append("routes:" + id)
			return parts
	return PackedStringArray([panel])


## Lugar onde se compra a construção: o que a tem como "upgrade" (ou na lista "upgrades").
func place_of_upgrade(upgrade_id: String) -> Array[String]:
	for world_id: String in worlds:
		var places: Dictionary = worlds[world_id].get("places", {})
		for place_id: String in places:
			var place: Dictionary = places[place_id]
			if place.get("upgrade", "") == upgrade_id or upgrade_id in place.get("upgrades", []):
				return [world_id, place_id]
	for world_id: String in worlds:
		var places: Dictionary = worlds[world_id].get("places", {})
		for place_id: String in places:
			if "station:" + upgrade_id in panel_parts(places[place_id].get("panel", "")):
				return [world_id, place_id]
	return ["", ""]


## Layout de um ambiente (fundo, piso, móveis, pontos): game/data/rooms/<id>.json
func room(id: String) -> Dictionary:
	return _load("res://data/rooms/%s.json" % id)


func item_name(id: String) -> String:
	return items.get(id, collections.get(id, {})).get("name", id)


## Ícone do item (campo "icon" em items.json); null se não tiver.
func item_icon(id: String) -> Texture2D:
	if collections.has(id):
		return _texture("res://assets/sprites/ui/icons/%s.png" % str(collections[id].get("icon", "")))
	return _texture(items.get(id, {}).get("icon", ""))


## Saída comum para receitas de inventário e de roupas (estas nunca viram itens).
func recipe_output(recipe: Dictionary) -> String:
	return str(recipe.get("output_collection", recipe.get("output", "")))


func station_upgrade(id: String) -> String:
	if id == "":
		return ""
	for key: String in progression.get("upgrades", {}):
		if progression.upgrades[key].get("station", "") == id:
			return key
	return id


func need_icon(id: String) -> Texture2D:
	return _texture(needs.get(id, {}).get("icon", ""))


func need_color(id: String) -> Color:
	return Color.from_string(needs.get(id, {}).get("color", ""), Color(0.45, 0.8, 0.4))


## Sprite da planta madura no canteiro.
func crop_texture(crop_id: String) -> Texture2D:
	return _texture(crops.get(crop_id, {}).get("sprite", ""))


## Sprites gerais do sítio (ex.: "sprout" = broto crescendo).
func farm_texture(key: String) -> Texture2D:
	return _texture(farm.get(key, ""))


func _texture(path: String) -> Texture2D:
	return load(path) if path != "" and ResourceLoader.exists(path) else null


func recipes_for(station_id: String) -> Array[String]:
	var result: Array[String] = []
	for id: String in recipes:
		if recipes[id].get("station") == station_id:
			result.append(id)
	return result


## De onde vem um item (para o detalhe da Mochila): culturas, receitas, rotas, recompensas.
func sources_of(item_id: String) -> PackedStringArray:
	var lines: PackedStringArray = []
	for id: String in crops:
		if crops[id].get("yield", {}).has(item_id):
			lines.append("Plantar e colher no Sítio")
			break
	for id: String in recipes:
		if recipe_output(recipes[id]) == item_id:
			lines.append("%s: %s" % [stations.get(recipes[id].station, {}).get("name", ""), describe_amounts(recipes[id].get("inputs", {}))])
	for id: String in progression.get("activities", {}):
		if progression.activities[id].get("rewards", {}).get("items", {}).has(item_id):
			lines.append("Rota: " + str(progression.activities[id].name))
	for id: String in quests:
		if quests[id].get("rewards", {}).get("items", {}).has(item_id):
			lines.append("Missão: " + str(quests[id].name))
	if item_id == "dog_food":
		lines.append("A Bloblo ajuda quando a comida acaba (Tigela)")
	return lines


## Onde um item é usado: receitas, construções, encomendas e entregas de missão.
func uses_of(item_id: String) -> PackedStringArray:
	var lines: PackedStringArray = []
	for id: String in recipes:
		if recipes[id].get("inputs", {}).has(item_id):
			lines.append("%s: %s" % [stations.get(recipes[id].station, {}).get("name", ""), item_name(recipe_output(recipes[id]))])
	for id: String in progression.get("upgrades", {}):
		if progression.upgrades[id].get("materials", {}).has(item_id):
			lines.append("Construir: " + str(progression.upgrades[id].name))
	for id: String in progression.get("orders", {}):
		if progression.orders[id].get("inputs", {}).has(item_id):
			lines.append("Encomenda: " + str(progression.orders[id].name))
	for id: String in quests:
		for goal: Dictionary in quests[id].get("goals", []):
			if goal.get("type", "") == "deliver" and goal.get("key", "") == item_id:
				lines.append("Missão: " + str(quests[id].name))
	if items.get(item_id, {}).has("feed"):
		lines.append("Comida para o Tiro")
	for id: String in friends.get("friends", {}):
		if friends.friends[id].get("likes", "") == item_id:
			lines.append("Petisco favorito: " + str(friends.friends[id].name))
	return lines


## Texto "2x Cenoura, 1x Batata" a partir de um dicionário item -> quantidade.
func describe_amounts(amounts: Dictionary) -> String:
	var parts: PackedStringArray = []
	for id: String in amounts:
		parts.append("%dx %s" % [int(amounts[id]), item_name(id)])
	return ", ".join(parts)


func _load(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Database: falha ao ler %s" % path)
		return {}
	return parsed

## Definição de um projeto ({} se o id não existe).
func project(id: String) -> Dictionary:
	return projects.get("projects", {}).get(id, {})


## Ids dos projetos do catálogo.
func project_ids() -> Array:
	return projects.get("projects", {}).keys()


## Por que o projeto não pode existir para o jogador ("" = definição válida e sem pendência quebrada):
## fase sem id/repetida/sem material, item ou quantidade inválidos, requisito de projeto ausente ou cíclico.
func project_issue(id: String) -> String:
	return _project_issue(id, [])


func _project_issue(id: String, trail: Array) -> String:
	var def := project(id)
	if def.is_empty():
		return "Projeto desconhecido: " + id
	if id in trail:
		return "Requisito cíclico: " + " > ".join(trail) + " > " + id
	var phases: Array = def.get("phases", [])
	if phases.is_empty():
		return id + ": sem fases"
	var seen := {}
	for phase: Dictionary in phases:
		var phase_id := str(phase.get("id", ""))
		if phase_id == "" or seen.has(phase_id):
			return id + ": fase sem id ou repetida"
		seen[phase_id] = true
		var wanted: Dictionary = phase.get("items", {})
		if wanted.is_empty():
			return "%s/%s: fase sem material" % [id, phase_id]
		for item: String in wanted:
			if not self.items.has(item) or int(wanted[item]) <= 0 or float(wanted[item]) != float(int(wanted[item])):
				return "%s/%s: material inválido %s" % [id, phase_id, item]
	var gathering: Dictionary = def.get("gathering", {})
	if not gathering.is_empty():
		if float(gathering.get("hours", 0)) <= 0.0 or gathering.get("items", {}).is_empty():
			return id + ": encontro sem intervalo ou sem material"
		for item: String in gathering.items:
			if not self.items.has(item) or int(gathering.items[item]) <= 0:
				return "%s/encontro: material inválido %s" % [id, item]
	var next_trail := trail.duplicate()
	next_trail.append(id)
	for required: String in def.get("requirements", {}).get("projects", []):
		var reason := _project_issue(required, next_trail)
		if reason != "":
			return reason
	return ""


## Todos os problemas do catálogo (lista vazia = esquema coerente). Usado por testes e conteúdo.
func project_problems() -> Array[String]:
	var problems: Array[String] = []
	for id: String in project_ids():
		var reason := project_issue(id)
		if reason != "":
			problems.append(reason)
	return problems


## Fontes como objetivos, compartilhadas pela navegação das missões.
func item_sources(item_id: String) -> Array[Dictionary]:
	var sources: Array[Dictionary] = []
	for id: String in crops:
		if crops[id].get("yield", {}).has(item_id):
			sources.append({"type": "stat", "key": "harvest:" + id})
	for id: String in recipes:
		if recipe_output(recipes[id]) == item_id:
			sources.append({"type": "stat", "key": "produce:" + item_id})
	for id: String in progression.activities:
		if progression.activities[id].get("rewards", {}).get("items", {}).has(item_id):
			sources.append({"type": "stat", "key": "activity:" + id})
	if item_id == "dog_food":
		sources.append({"type": "stat", "key": "feed"})
	# Achados (pedaços do mapa...): onde o Tiro cava no mundo que os garante ou sorteia.
	for world: String in (finds.get("worlds", {}) if items.get(item_id, {}).get("category", "") == "find" else {}):
		var entries: Array = finds.worlds[world].get("guaranteed", []) + finds.worlds[world].get("table", [])
		if entries.any(func(entry: Dictionary) -> bool: return entry.get("items", {}).has(item_id)):
			sources.append({"type": "stat", "key": "find:" + world})
	for id: String in (walks.get("walks", {}) if items.get(item_id, {}).get("category", "") == "trail" else {}):
		var loot: Dictionary = walks.walks[id].get("loot", {})
		var found: bool = loot.get("first", {}).get("items", {}).has(item_id)
		for entry: Dictionary in loot.get("table", []):
			found = found or entry.get("items", {}).has(item_id)
		if found:
			sources.append({"type": "stat", "key": "walk:" + id})
	return sources
