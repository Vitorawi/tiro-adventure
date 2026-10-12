extends Node
## Conteúdo do jogo, lido de game/data/*.json (autoload "Database").
##
## Itens, receitas, necessidades, ações e valores iniciais vivem nos JSON.
## Para adicionar conteúdo, edite os JSON — não o código dos sistemas.

var items: Dictionary = {}
var recipes: Dictionary = {}
var needs: Dictionary = {}
var actions: Dictionary = {}
var stations: Dictionary = {}
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


func _init() -> void:
	# Carrega no _init para estar pronto antes do _ready dos outros autoloads.
	items = _load("res://data/items.json")
	recipes = _load("res://data/recipes.json")
	crops = _load("res://data/crops.json")
	var config := _load("res://data/config.json")
	needs = config.get("needs", {})
	actions = config.get("actions", {})
	stations = config.get("stations", {})
	farm = config.get("farm", {})
	xp = config.get("xp", {})
	start = config.get("start", {})
	version = _load("res://data/version.json")
	progression = _load("res://data/progression.json")
	quests = _load("res://data/quests.json")
	npcs = _load("res://data/npcs.json")
	collections = _load("res://data/collections.json")


## Layout de um ambiente (fundo, piso, móveis, pontos): game/data/rooms/<id>.json
func room(id: String) -> Dictionary:
	return _load("res://data/rooms/%s.json" % id)


func item_name(id: String) -> String:
	return items.get(id, {}).get("name", id)


## Ícone do item (campo "icon" em items.json); null se não tiver.
func item_icon(id: String) -> Texture2D:
	return _texture(items.get(id, {}).get("icon", ""))


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
