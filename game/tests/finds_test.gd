extends SceneTree
## Faro: persistência, sorteio, capacidade, álbum e integração no mapa.
var failures := 0
var state: Node
var db: Node

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Faro: " + message)

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.call("reset")
	check(state.get("finds").worlds.is_empty(), "antes da primeira colheita não há faro")
	state.get("progress").claimed_quests["bloblo_meet"] = true
	state.get("progress").claimed_quests["first_harvest"] = true
	state.get("progress").claimed_quests["bloblo_sell_surplus"] = true
	state.call("_changed")
	check(state.get("finds").worlds.farm.pending == 0, "primeiro espera vinte segundos")
	state.call("dev_advance_time", 21.0)
	check(state.get("finds").worlds.farm.pending == 1, "primeiro achado pronto")
	var reward: Dictionary = state.call("dig", "farm")
	check(reward.label == "Mudas de morango", "primeiro são mudas")
	check(state.get("progress").unlocks.has("crop:strawberry"), "desbloqueia morango")
	check(state.call("quest_error", "bloblo_dig") == "", "missão pronta")
	state.call("dev_advance_time", 7200.0)
	check(state.get("finds").worlds.farm.pending == 1, "duas horas dão só um montinho")
	reward = state.call("dig", "farm")
	check(reward.items.get("old_horseshoe", 0) == 1, "segundo ferradura")
	state.call("dev_advance_time", 481.0)
	reward = state.call("dig", "farm")
	check(reward.items.get("map_piece_1", 0) == 1, "terceiro pedaço")
	check(state.get("progress").stat("find") == 3 and state.get("progress").stat("find:farm") == 3, "contadores totais")
	state.call("dev_advance_time", 481.0)
	var before: Dictionary = state.call("find_reward", "farm")
	var saved: Dictionary = state.call("to_dict")
	state.call("from_dict", saved)
	check(before == state.call("find_reward", "farm"), "sorteio sobrevive recarga")
	state.call("dev_advance_time", 7200.0)
	check(before == state.call("find_reward", "farm"), "avanço não rerrola pendente")
	check(state.call("find_set_error", "farm_set") != "", "conjunto incompleto bloqueia")
	for id: String in db.get("finds").sets.farm_set.items:
		state.get("progress").count("find_item:" + id)
	check(state.call("claim_find_set", "farm_set") == "", "recebe conjunto")
	var coins: int = state.get("coins")
	check(state.call("claim_find_set", "farm_set") != "" and state.get("coins") == coins, "recebe uma vez")
	state.get("inventory").remove("old_horseshoe")
	check(state.call("find_set_progress", "farm_set") == 4, "álbum não depende mochila")
	# Força cenoura sem mudar dados globais depois do teste.
	var tables: Array = db.get("finds").worlds.farm.table.duplicate(true)
	db.get("finds").worlds.farm.table = [{"weight": 1, "items": {"carrot": 1}}]
	state.get("progress").owned["silo"] = true
	state.get("inventory").add("carrot", 10000)
	check(state.call("dig_error", "farm") != "" and state.call("dig", "farm").is_empty(), "silo cheio bloqueia")
	check(state.get("finds").worlds.farm.pending == 1, "silo cheio preserva montinho")
	db.get("finds").worlds.farm.table = tables
	var builder: Script = load("res://scripts/ui/sheet_builder.gd")
	for id: String in db.get("items"):
		if db.get("items")[id].category == "find":
			check(not builder.call("_fits_fridge", id), "achado não entra geladeira: " + id)
	await _map_checks()
	print("FINDS TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)

func _map_checks() -> void:
	state.call("reset")
	state.get("progress").claimed_quests["first_harvest"] = true
	state.get("progress").claimed_quests["bloblo_sell_surplus"] = true
	state.get("progress").claimed_quests["bloblo_dig"] = true
	state.get("progress").seen["intro"] = true
	state.call("_changed")
	for world: String in db.get("finds").worlds:
		var room: Control = load("res://scenes/levels/room/room.tscn").instantiate()
		room.set("room_id", world)
		room.set("world_id", world)
		root.add_child(room)
		await process_frame
		var data: Dictionary = db.call("room", world)
		for spot: Array in data.dig_spots:
			var point := Vector2(spot[0], spot[1])
			var nearest: Vector2 = room.call("nearest_floor_point", point)
			check(nearest.distance_to(point) < 10.0, "%s ponto alcançável %s -> %s" % [world, point, nearest])
			check(not room.call("find_path", room.get("_dog").position, point).is_empty(), "%s caminho ao montinho" % world)
		room.queue_free()
		await process_frame
