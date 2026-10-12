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
## Canteiros: crop, planted_at e ready_at (Unix). Quantidade em config "farm.plots".
var plots: Array[Dictionary] = []
var unlocked_plots: int = 0
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
	unlocked_plots = int(Database.farm.get("initial_plots", 3))
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
	Events.dog_action.emit(&"feed")
	return true


func pet() -> void:
	dog.apply(Database.actions.get("pet", {}), now())
	dog.affection += 1
	_changed()
	Events.dog_action.emit(&"pet")


func play() -> bool:
	if dog.sleeping or dog.get_need("energy", now()) < 15.0:
		return false
	dog.apply(Database.actions.get("play", {}), now())
	dog.affection += 2
	_gain_xp("play")
	_changed()
	Events.dog_action.emit(&"play")
	return true


func bathe() -> void:
	dog.apply(Database.actions.get("bathe", {}), now())
	_gain_xp("bathe")
	_changed()
	Events.dog_action.emit(&"bathe")


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


## "locked", "empty", "growing" ou "ready".
func plot_status(index: int) -> String:
	if index < 0 or index >= unlocked_plots:
		return "locked"
	var target := plot(index)
	if target["crop"] == "":
		return "empty"
	return "ready" if float(target["ready_at"]) <= now() else "growing"


## Planta no canteiro. Retorna "" se deu certo ou o motivo da falha.
func plant(index: int, crop_id: String) -> String:
	if plot_status(index) == "locked":
		return "Compre este terreno primeiro"
	if not Database.crops.has(crop_id):
		return "Semente desconhecida"
	if plot_status(index) != "empty":
		return "Canteiro ocupado"
	var planted_at := now()
	plots[index] = { "crop": crop_id, "planted_at": planted_at, "ready_at": planted_at + float(Database.crops[crop_id].get("seconds", 60)) }
	_changed()
	return ""


## Colhe um canteiro pronto. Retorna os itens recebidos (vazio se não estava pronto).
func harvest(index: int) -> Dictionary:
	if plot_status(index) != "ready":
		return {}
	var received: Dictionary = Database.crops[plot(index)["crop"]].get("yield", {})
	coins += int(Database.crops[plot(index)["crop"]].get("coins", 0))
	for item_id: String in received:
		inventory.add(item_id, int(received[item_id]))
	plots[index] = { "crop": "", "ready_at": 0.0 }
	_gain_xp("harvest")
	_changed()
	return received


func _ensure_plots() -> void:
	while plots.size() < int(Database.farm.get("plots", 0)):
		plots.append({ "crop": "", "ready_at": 0.0 })


## Progresso calculado por timestamps; continua com o jogo fechado.
func plot_progress(index: int) -> float:
	if plot_status(index) in ["locked", "empty"]:
		return 0.0
	var target := plot(index)
	var end := float(target["ready_at"])
	var start := float(target.get("planted_at", end - float(Database.crops[target["crop"]]["seconds"])))
	return clampf((now() - start) / maxf(end - start, 0.001), 0.0, 1.0)


func plot_cost(index: int) -> int:
	var costs: Array = Database.farm.get("unlock_costs", [])
	return int(costs[index]) if index >= 0 and index < costs.size() else -1


## Expansão em ordem fixa. Valida novamente no momento da compra.
func buy_plot(index: int) -> String:
	if index < 0 or index >= int(Database.farm.get("plots", 0)):
		return "Terreno inválido"
	if index < unlocked_plots:
		return "Este terreno já é seu"
	if index != unlocked_plots:
		return "Compre o terreno %d primeiro" % (unlocked_plots + 1)
	var cost := plot_cost(index)
	if cost < 0:
		return "Terreno indisponível"
	if coins < cost:
		return "Faltam %d moedas" % (cost - coins)
	coins -= cost
	unlocked_plots += 1
	_changed()
	return ""


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
		"unlocked_plots": unlocked_plots,
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
		var loaded_plot := { "crop": str(entry.get("crop", "")), "ready_at": float(entry.get("ready_at", 0.0)) }
		if entry.has("planted_at"):
			loaded_plot["planted_at"] = float(entry["planted_at"])
		plots.append(loaded_plot)
	# Saves anteriores mantêm todos os canteiros que já possuíam.
	unlocked_plots = clampi(int(data.get("unlocked_plots", maxi(plots.size(), int(Database.farm.get("initial_plots", 3))))), 0, int(Database.farm.get("plots", 0)))
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
