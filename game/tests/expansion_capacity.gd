extends SceneTree
## Etapa 18 da economia: avalia a UTILIDADE de cada ampliação de depósito numa volta de ausência longa.
## NÃO é teste (gera o relatório build/economy/etapa_18/capacidade.md). Usa o GameState real:
## todas as vagas de cada estação/canteiro ficam cheias durante 24 h, o jogador volta com uma RESERVA já no
## depósito (o que guarda para encomendas/ingredientes) e recolhe tudo. Mede o que entrou e o que ficou
## pronto fora do depósito (lote que não cabe continua na fila, nada se perde).
##   & $env:GODOT_BIN --headless --path game -s res://tests/expansion_capacity.gd
## Limite: a bagagem do passeio não entra na carga do baú (só estações); a Natureza entra na do armazém.

const T0 := 1791936000.0
const STAGES := [3, 4, 5]
const RESERVES := {"silo": [24, 64], "fridge": [24, 48], "warehouse": [24, 64, 100], "chest": [12, 32, 60]}
const FILLER := {"silo": "carrot", "fridge": "carrot_snack", "warehouse": "wood", "chest": "stick"}

var state: Node
var db: Node
var lines: PackedStringArray = []


func _initialize() -> void:
	_run.call_deferred()


func _p() -> RefCounted:
	return state.get("progress")


func _depot_levels(depot: String) -> Array:
	return db.get("progression").storage[depot].levels


func _fresh_full(depot: String, stage: int) -> void:
	state.set("test_time", T0)
	state.set("unlimited_storage", true)
	state.call("reset")
	state.call("dev_unlock_everything")
	state.get("economy").storage_floor.clear()
	state.get("inventory").counts.clear()
	for other: String in RESERVES:
		for id: String in _depot_levels(other):
			_p().owned.erase(id)
		_p().owned[str(db.get("progression").storage[other].building)] = true
	for index in stage - 1:
		_p().owned[str(_depot_levels(depot)[index])] = true
	# Abrigos cheios (3 animais cada), sempre na primeira variedade da estação.
	var herd: Dictionary = {}
	var filled: Dictionary = {}
	for id: String in db.get("animals"):
		var station: String = db.get("animals")[id].station
		if not filled.has(station):
			filled[station] = true
			herd[id] = int(db.get("stations")[station].animal_capacity)
	state.set("animals", herd)
	state.set("coins", 100000)


## Melhor receita de cada estação para o depósito: a que mais entrega por lote (animais contam 3 animais).
func _best_recipes(depot: String) -> Dictionary:
	var result := {}
	var recipes: Dictionary = db.get("recipes")
	for id: String in recipes:
		var recipe: Dictionary = recipes[id]
		if recipe.has("output_collection"):
			continue
		var station: String = recipe.station
		if str(state.call("storage_of", str(recipe.output))) != depot:
			continue
		if str(state.call("content_error", "recipe", id, recipe)) != "":
			continue
		var animal: bool = db.get("stations")[station].get("kind", "") == "animal"
		var yield_units := int(recipe.get("qty", 1)) * (int(db.get("stations")[station].get("animal_capacity", 1)) if animal else 1)
		if not result.has(station) or yield_units > int(result[station].units):
			result[station] = {"recipe": id, "units": yield_units, "animal": animal}
	return result


func _load_queues(best: Dictionary) -> int:
	var jobs_units := 0
	for station: String in best:
		var info: Dictionary = best[station]
		var count: int = 1 if info.animal else int(state.call("station_free_slots", station))
		var inputs: Dictionary = state.call("cook_inputs", info.recipe, count)
		for item: String in inputs:
			state.get("inventory").counts[item] = int(inputs[item]) + int(state.get("inventory").counts.get(item, 0))
		var reason: String = state.call("cook_many", info.recipe, count)
		if reason == "":
			jobs_units += int(info.units) * count
	return jobs_units


func _scenario(depot: String, stage: int, reserve: int) -> Dictionary:
	_fresh_full(depot, stage)
	var load_units := 0
	var capacity := int(state.call("storage_capacity", depot))
	if depot == "silo":
		# Todos os canteiros com a melhor cultura que cabe em cada um.
		for index: int in state.call("usable_plot_indices"):
			var best_crop := ""
			var best_yield := 0
			for crop_id: String in db.get("crops"):
				if str(state.call("plant_error", index, crop_id)) != "":
					continue
				var units := 0
				for amount: int in db.get("crops")[crop_id].yield.values():
					units += amount
				if units > best_yield:
					best_yield = units
					best_crop = crop_id
			if best_crop != "" and str(state.call("plant", index, best_crop)) == "":
				load_units += best_yield
	else:
		load_units = _load_queues(_best_recipes(depot))
	if depot == "warehouse":
		# Natureza: todas as vagas de Bosque, Caverna e Prado com a rota padrão.
		for site: String in db.get("progression").nature_sites:
			var started: String = state.call("start_gathering_all", site, "", {"trees": "wood", "rocks": "stone", "fibers": "fiber"}[site])
			if OS.get_cmdline_user_args().has("--debug"):
				print("  gathering ", site, ": ", started, " vagas ", state.call("gathering_slots", site))
			for job: Dictionary in state.call("gathering_jobs", site):
				for item: String in job.get("rewards", {}).get("items", {}):
					if str(state.call("storage_of", item)) == "warehouse":
						load_units += int(job.rewards.items[item])
	state.call("dev_advance_time", 86400.0)
	state.set("unlimited_storage", false)
	state.get("inventory").counts.clear()
	state.get("inventory").counts[FILLER[depot]] = reserve
	var arrived := 0
	var stored_before := int(state.call("storage_used", depot)) if state.has_method("storage_used") else reserve
	if depot == "silo":
		for index: int in state.call("usable_plot_indices"):
			var got: Dictionary = state.call("harvest", index)
			for amount: int in got.values():
				arrived += amount
	else:
		if depot == "warehouse":
			for site: String in db.get("progression").nature_sites:
				state.call("collect_gathering_all", site)
		for station: String in _best_recipes(depot):
			var got_here := 0
			for amount: int in (state.call("collect", station) as Dictionary).values():
				arrived += amount
				got_here += amount
			if OS.get_cmdline_user_args().has("--debug"):
				print("  ", depot, " _", stage, " ", station, " ", _best_recipes(depot)[station], " recolheu ", got_here, " fila restante ", state.call("station", station).queue.size())
	arrived = _depot_units(depot) - reserve
	return {"capacity": capacity, "reserve": reserve, "load": load_units, "arrived": arrived, "blocked": maxi(0, load_units - arrived), "stored_before": stored_before}


func _depot_units(depot: String) -> int:
	var total := 0
	for item: String in state.get("inventory").counts:
		if str(state.call("storage_of", item)) == depot:
			total += int(state.get("inventory").counts[item])
	return total


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/friend_clock.gd"))
	lines.append("# Etapa 18: capacidade na volta de uma ausência longa (24 h, GameState real)")
	lines.append("")
	lines.append("Todas as vagas e canteiros cheios, volta com a reserva já no depósito. `cabe` = entrou na hora; `fora` = ficou pronto na fila/canteiro esperando espaço. A carga do armazém inclui as rotas da Natureza; a bagagem do passeio não entra na do baú.")
	lines.append("")
	for depot: String in RESERVES:
		lines.append("## %s" % depot)
		lines.append("")
		lines.append("| estágio | capacidade | reserva | carga | cabe | fora |")
		lines.append("|---:|---:|---:|---:|---:|---:|")
		for reserve: int in RESERVES[depot]:
			for stage: int in STAGES:
				var r := _scenario(depot, stage, reserve)
				lines.append("| _%d | %d | %d | %d | %d | %d |" % [stage, r.capacity, reserve, r.load, r.arrived, r.blocked])
		lines.append("")
	var path := ProjectSettings.globalize_path("res://../build/economy/etapa_18/capacidade.md")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	print("\n".join(lines))
	print("EXPANSION CAPACITY: pronto")
	quit()
