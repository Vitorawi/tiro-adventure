extends Node
## Estado global do jogador (autoload "GameState").
##
## Única fonte da verdade para dados que sobrevivem entre cenas e sessões,
## e ponto de entrada das ações do jogo (alimentar, brincar, cozinhar...).
## Não acessa disco: o SaveManager usa to_dict()/from_dict().
## Regras numéricas e conteúdo vêm do Database (game/data/*.json).

var dog := DogState.new()
var inventory := Inventory.new()
var stations: Dictionary = {}  # station_id -> StationState
## Canteiros do sítio: { "crop": id ou "", "ready_at": unix }. Quantidade em config "farm.plots".
var plots: Array[Dictionary] = []
var coins: int = 0
var xp: int = 0
var level: int = 1


func now() -> float:
	return Time.get_unix_time_from_system()


func reset() -> void:
	dog = DogState.new()
	dog.setup(now())
	inventory = Inventory.new()
	var start_items: Dictionary = Database.start.get("inventory", {})
	for id: String in start_items:
		inventory.add(id, int(start_items[id]))
	stations = {}
	_ensure_stations()
	plots = []
	_ensure_plots()
	coins = int(Database.start.get("coins", 0))
	xp = 0
	level = 1
	_changed()


# --- Ações do Tiro ---------------------------------------------------------

func feed(item_id: String) -> bool:
	var effects: Dictionary = Database.items.get(item_id, {}).get("feed", {})
	if effects.is_empty() or not inventory.remove(item_id):
		return false
	dog.apply(effects, now())
	_gain_xp("feed")
	_changed()
	return true


func pet() -> void:
	dog.apply(Database.actions.get("pet", {}), now())
	dog.affection += 1
	_changed()


func play() -> bool:
	if dog.sleeping or dog.get_need("energy", now()) < 15.0:
		return false
	dog.apply(Database.actions.get("play", {}), now())
	dog.affection += 2
	_gain_xp("play")
	_changed()
	return true


func bathe() -> void:
	dog.apply(Database.actions.get("bathe", {}), now())
	_gain_xp("bathe")
	_changed()


func set_sleeping(value: bool) -> void:
	dog.set_sleeping(value, now())
	_changed()


# --- Produção --------------------------------------------------------------

func station(station_id: String) -> StationState:
	_ensure_stations()
	return stations[station_id]


## Coloca uma receita na fila. Retorna "" se deu certo ou o motivo da falha.
func cook(recipe_id: String) -> String:
	var recipe: Dictionary = Database.recipes.get(recipe_id, {})
	var station_id: String = recipe.get("station", "")
	var slots := int(Database.stations.get(station_id, {}).get("slots", 1))
	var target := station(station_id)
	if target.queue.size() >= slots:
		return "Fila cheia"
	if not inventory.remove_all(recipe.get("inputs", {})):
		return "Faltam ingredientes"
	target.enqueue(recipe_id, float(recipe.get("seconds", 60)), now())
	_changed()
	return ""


## Coleta tudo o que está pronto na estação. Retorna os itens recebidos.
func collect(station_id: String) -> Dictionary:
	var received := {}
	for recipe_id in station(station_id).take_ready(now()):
		var recipe: Dictionary = Database.recipes[recipe_id]
		var output: String = recipe["output"]
		var qty := int(recipe.get("qty", 1))
		inventory.add(output, qty)
		received[output] = int(received.get(output, 0)) + qty
		_gain_xp("cook")
	if not received.is_empty():
		_changed()
	return received


# --- Horta (sítio) ---------------------------------------------------------

func plot(index: int) -> Dictionary:
	_ensure_plots()
	return plots[index]


## "empty", "growing" ou "ready".
func plot_status(index: int) -> String:
	var target := plot(index)
	if target["crop"] == "":
		return "empty"
	return "ready" if float(target["ready_at"]) <= now() else "growing"


## Planta no canteiro. Retorna "" se deu certo ou o motivo da falha.
func plant(index: int, crop_id: String) -> String:
	if not Database.crops.has(crop_id):
		return "Semente desconhecida"
	if plot_status(index) != "empty":
		return "Canteiro ocupado"
	plots[index] = { "crop": crop_id, "ready_at": now() + float(Database.crops[crop_id].get("seconds", 60)) }
	_changed()
	return ""


## Colhe um canteiro pronto. Retorna os itens recebidos (vazio se não estava pronto).
func harvest(index: int) -> Dictionary:
	if plot_status(index) != "ready":
		return {}
	var received: Dictionary = Database.crops[plot(index)["crop"]].get("yield", {})
	for item_id: String in received:
		inventory.add(item_id, int(received[item_id]))
	plots[index] = { "crop": "", "ready_at": 0.0 }
	_gain_xp("harvest")
	_changed()
	return received


func _ensure_plots() -> void:
	while plots.size() < int(Database.farm.get("plots", 0)):
		plots.append({ "crop": "", "ready_at": 0.0 })


# --- Progressão ------------------------------------------------------------

func xp_to_next_level() -> int:
	return int(Database.xp.get("per_level", 100)) * level


func _gain_xp(action: String) -> void:
	xp += int(Database.xp.get(action, 0))
	while xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		level += 1
		Events.toast_requested.emit("Nível %d!" % level)


# --- Save ------------------------------------------------------------------

func to_dict() -> Dictionary:
	var station_data := {}
	for id: String in stations:
		station_data[id] = stations[id].to_dict()
	return {
		"dog": dog.to_dict(),
		"inventory": inventory.to_dict(),
		"stations": station_data,
		"plots": plots,
		"coins": coins,
		"xp": xp,
		"level": level,
	}


func from_dict(data: Dictionary) -> void:
	if data.is_empty():
		reset()
		return
	dog = DogState.new()
	dog.from_dict(data.get("dog", {}), now())
	inventory = Inventory.new()
	inventory.from_dict(data.get("inventory", {}))
	stations = {}
	var station_data: Dictionary = data.get("stations", {})
	for id: String in station_data:
		var loaded := StationState.new()
		loaded.from_dict(station_data[id])
		stations[id] = loaded
	_ensure_stations()
	# "plots" chegou depois da v2 do save: saves antigos simplesmente começam com canteiros vazios.
	plots = []
	for entry: Dictionary in data.get("plots", []):
		plots.append({ "crop": str(entry.get("crop", "")), "ready_at": float(entry.get("ready_at", 0.0)) })
	_ensure_plots()
	coins = int(data.get("coins", 0))
	xp = int(data.get("xp", 0))
	level = int(data.get("level", 1))
	_changed()


func _ensure_stations() -> void:
	for id: String in Database.stations:
		if not stations.has(id):
			stations[id] = StationState.new()


func _changed() -> void:
	Events.state_changed.emit()
