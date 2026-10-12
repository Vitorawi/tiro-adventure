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
var xp: Dictionary = {}
var start: Dictionary = {}


func _init() -> void:
	# Carrega no _init para estar pronto antes do _ready dos outros autoloads.
	items = _load("res://data/items.json")
	recipes = _load("res://data/recipes.json")
	var config := _load("res://data/config.json")
	needs = config.get("needs", {})
	actions = config.get("actions", {})
	stations = config.get("stations", {})
	xp = config.get("xp", {})
	start = config.get("start", {})


func item_name(id: String) -> String:
	return items.get(id, {}).get("name", id)


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
