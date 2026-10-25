extends SceneTree
## Praça: abertura depois da Vila, Nina e Pipoca, motor de passeios (sair, recolher, cancelar,
## app fechado), Tiro fora das salas e telas (painel, cartão de volta, tela do Tiro).

var failures := 0
var state: Node
var db: Node


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Praça: " + message)


func _tire() -> void:
	state.get("dog").needs["energy"] = 5.0
	state.get("dog").updated_at = state.call("now")


func _rest() -> void:
	state.get("dog").needs["energy"] = 80.0
	state.get("dog").updated_at = state.call("now")


func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	seed(12345)
	state.call("reset")
	var places: Script = load("res://scripts/ui/places.gd")
	var progress: Object = state.get("progress")

	# --- Abertura -------------------------------------------------------------
	check(places.call("world_error", "park") != "", "Praça fechada no começo")
	check(not progress.npc_visible("nina") and not progress.npc_visible("dog_pipoca"), "Nina e Pipoca escondidas")
	check(not (progress.unlocked_keys() as Array).has("world:park"), "Novo! ainda não lista a Praça")
	var order: Array = db.get("worlds").keys()
	check(order.find("park") == order.find("village") + 1 and order.find("park") == order.find("nature") - 1, "Praça depois da Vila: " + str(order))
	progress.claimed_quests["main_2_order"] = true
	state.call("_changed")
	check(places.call("world_error", "park") == "", "Praça abre depois da primeira encomenda")
	var keys: Array = progress.unlocked_keys()
	check(keys.has("world:park") and keys.has("npc:nina"), "Novo! lista Praça e Nina")
	check(not keys.has("npc:dog_pipoca"), "Pipoca é decor: fora do Novo!")
	check((places.call("visible_npcs", "park") as Array) == ["nina"], "Pipoca não aparece como personagem: " + str(places.call("visible_npcs", "park")))
	check(places.call("npc_badge", "dog_pipoca") == "", "Pipoca sem balão")

	# --- Conversa e missões ---------------------------------------------------
	check(state.call("quest_error", "nina_meet") != "", "nina_meet pede conversa")
	check(places.call("npc_badge", "nina") == "new", "Nina chama com !")
	var discard := func(_title: String, content: Control) -> void: content.free()
	root.get_node("Events").sheet_requested.connect(discard)
	places.call("open_npc", "nina")
	root.get_node("Events").sheet_requested.disconnect(discard)
	check(state.call("quest_error", "nina_meet") == "", "conversa conclui nina_meet")
	check((db.get("npcs").nina.introduction as Array).size() == 3, "apresentação com 3 falas")
	check(state.call("claim_quest", "nina_meet") == "", "recebe nina_meet")
	check(progress.current_line_quest("nina") == "nina_walk", "nina_walk é o próximo passo")
	check(state.call("quest_error", "nina_walk") != "", "nina_walk exige passear")
	check(progress.current_main_quest() != "" and progress.current_line_quest("lais") != "nina_walk", "linha da Nina não bloqueia a Laís")
	var target: Dictionary = places.call("goal_target", {"type": "stat", "key": "walk"})
	check(target.get("world", "") == "park" and target.get("place", "") == "walk", "Ir leva ao portão do passeio: " + str(target))
	check(places.call("goal_target", {"type": "stat", "key": "talk:nina"}).get("world", "") == "park", "talk:nina leva à Praça")

	# --- Sair para o passeio --------------------------------------------------
	check(state.call("walking") == false, "ninguém passeando")
	state.get("dog").sleeping = true
	check(state.call("walk_error", "park_loop") == "Tiro está dormindo", "dormindo bloqueia")
	state.get("dog").sleeping = false
	_tire()
	check(state.call("walk_error", "park_loop") == "Tiro está cansado: deixe ele dormir", "cansado bloqueia")
	_rest()
	check(state.call("walk_error", "park_loop") == "", "descansado pode sair")
	check(state.call("start_walk", "park_loop") == "", "sai para passear")
	check(state.call("walking") and not state.call("walk_ready"), "passeio em andamento")
	var energy: float = state.get("dog").get_need("energy", state.call("now"))
	check(absf(energy - 72.0) < 0.5, "gasta 8 de energia: %s" % energy)
	check(state.call("walk_error", "park_loop") == "O Tiro já está passeando", "um passeio por vez")
	var fed: bool = state.call("feed", "dog_food")
	check(not fed, "comer bloqueado")
	state.call("set_sleeping", true)
	check(not state.get("dog").sleeping, "dormir bloqueado")
	state.call("bathe")
	check(not state.call("play"), "brincar bloqueado")
	check(state.call("dig_error", "farm") == "Tiro está passeando", "cavar bloqueado")
	check(state.call("away_error") == "Tiro está passeando", "texto do motivo")
	check(state.call("collect_walk_error") == "O passeio ainda não terminou", "recolher antes do tempo")
	check(state.call("collect_walk").is_empty(), "recolher antes devolve vazio")

	# --- Persistência e app fechado ------------------------------------------
	var saved: Dictionary = state.call("to_dict").duplicate(true)
	state.call("from_dict", saved)
	check(state.call("walking"), "passeio sobrevive à recarga")
	var loot_before: Dictionary = state.call("walk_loot")
	state.call("from_dict", state.call("to_dict").duplicate(true))
	check(loot_before == state.call("walk_loot"), "sorteio estável ao recarregar")
	progress = state.get("progress")
	state.get("walk_state").current["ready_at"] = state.call("now") - 1.0  # "app fechado": só o relógio andou
	var had_coins: int = state.get("coins")
	var happy_before: float = state.get("dog").get_need("happiness", state.call("now"))
	var hygiene_before: float = state.get("dog").get_need("hygiene", state.call("now"))
	check(not state.call("walking"), "tempo vencido: o Tiro já não está fora")
	check(state.call("return_due_walk"), "o tick liquida a viagem")
	check(state.call("walk_ready") and not state.call("return_due_walk"), "terminou sozinho, uma vez só")

	# --- Recolher -------------------------------------------------------------
	var result: Dictionary = state.call("collect_walk")
	check(not result.is_empty() and result.id == "park_loop", "guarda a bagagem do passeio")
	check(not state.call("walking"), "Tiro de volta")
	check(state.get("coins") >= had_coins + 6, "moedas do passeio")
	check(state.get("dog").get_need("happiness", state.call("now")) > happy_before - 0.01, "volta mais feliz")
	check(state.get("dog").get_need("hygiene", state.call("now")) < hygiene_before, "volta sujinho")
	check(progress.stat("walk") == 1 and progress.stat("walk:park_loop") == 1, "contadores walk")
	check(state.get("walk_state").history.park_loop.count == 1, "histórico")
	check(state.call("quest_error", "nina_walk") == "", "nina_walk pronta")
	check(state.call("collect_walk").is_empty() and progress.stat("walk") == 1, "recolhe uma vez só")

	# --- Cancelar -------------------------------------------------------------
	_rest()
	state.call("start_walk", "park_loop")
	check(state.call("cancel_walk") == "", "chama de volta")
	check(not state.call("walking") and absf(state.get("dog").get_need("energy", state.call("now")) - 80.0) < 0.5, "devolve a energia")
	check(progress.stat("walk") == 1, "cancelar não conta passeio")

	# --- Sorteio com achados do mundo ----------------------------------------
	var table: Dictionary = db.get("walks").walks.park_loop.loot
	var original: Array = table.table.duplicate(true)
	table["table"] = [{"weight": 1, "find": "park"}]
	state.call("start_walk", "park_loop")
	var loot: Dictionary = state.call("walk_loot")
	var park_items: Array = (db.get("finds").worlds.park.table as Array).filter(func(e: Dictionary) -> bool: return e.has("items")).map(func(e: Dictionary) -> Array: return e.items.keys())
	var allowed: Array = []
	for keys_list: Array in park_items:
		allowed.append_array(keys_list)
	for id: String in loot.items:
		if db.get("items")[id].category == "find":
			check(id in allowed, "achado vem da tabela da praça: " + id)
	state.get("walk_state").current["ready_at"] = 0.0
	var was_new: Dictionary = {}
	for id: String in loot.items:
		was_new[id] = progress.stat("find_item:" + id) == 0
	var found: Dictionary = state.call("collect_walk")
	for id: String in found.items:
		if db.get("items")[id].category == "find":
			check(progress.stat("find_item:" + id) > 0, "álbum conta o achado: " + id)
			check((found.new as Array).has(id) == bool(was_new.get(id, false)), "Novo! só na primeira vez: " + id)
	check(not state.get("finds").worlds.has("park") or state.get("finds").worlds.park.dug == 0, "passeio não gasta montinho")
	table["table"] = original
	_rest()

	# --- Armazenamento cheio mantém o passeio pronto -------------------------
	var previous_loot: Dictionary = db.get("walks").walks.park_loop.loot.duplicate(true)
	# Só cenoura: garantias e consolo do raro poderiam caber parcialmente em outro depósito.
	db.get("walks").walks.park_loop.loot = {"rolls": 1, "table": [{"weight": 1, "items": {"carrot": 1}}]}
	state.get("progress").owned["silo"] = true
	state.get("inventory").add("carrot", 100000)
	state.call("start_walk", "park_loop")
	state.get("walk_state").current["ready_at"] = 0.0
	state.call("return_due_walk")
	check(not state.call("walking") and state.call("walk_ready"), "sem espaço: o Tiro volta e a bagagem espera")
	check(state.call("collect_walk_error") != "", "sem espaço: não guarda")
	state.get("inventory").remove("carrot", 100000)
	state.get("progress").owned.erase("silo")
	check(state.call("collect_walk_error") == "", "com espaço volta a guardar")
	state.call("collect_walk")
	db.get("walks").walks.park_loop.loot = previous_loot
	_rest()

	# --- Desejo, diária e desejos de comida ----------------------------------
	check(db.get("wishes").wishes.has("walk") and not db.get("routines").daily.missions.has("tiro_walk"), "passeio pertence ao desejo; rotinas são da fazenda")
	# Este caso mede o temporizador DEV e a bagagem, não o sorteio (que pode trazer só moedas).
	var timer_loot: Dictionary = db.get("walks").walks.park_loop.loot.duplicate(true)
	db.get("walks").walks.park_loop.loot = {"rolls": 1, "table": [{"weight": 1, "items": {"stick": 1}}]}
	check(state.call("start_walk", "park_loop") == "", "inicia o passeio do teste de temporizador DEV")
	state.call("dev_finish_timers")
	check(state.call("return_due_walk") and state.call("walk_ready"), "dev termina o passeio")
	state.call("collect_walk")
	db.get("walks").walks.park_loop.loot = timer_loot

	# --- Salas, navegação e telas --------------------------------------------
	await _room_checks()
	print("PARK TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


func _room_checks() -> void:
	state.call("reset")
	state.get("progress").claimed_quests["main_2_order"] = true
	state.get("progress").claimed_quests["nina_meet"] = true
	state.get("progress").seen["intro"] = true
	state.call("_changed")
	var data: Dictionary = db.call("room", "park")
	var park: Control = load("res://scenes/levels/room/room.tscn").instantiate()
	park.set("room_id", "park")
	park.set("world_id", "park")
	root.add_child(park)
	var house: Control = load("res://scenes/levels/room/room.tscn").instantiate()
	house.set("room_id", "house")
	house.set("world_id", "house")
	root.add_child(house)
	await process_frame
	await process_frame
	check(park.get("_dog") != null and house.get("_dog") != null, "Tiro nas salas antes do passeio")
	for spot: Array in data.dig_spots:
		var point := Vector2(spot[0], spot[1])
		check((park.call("nearest_floor_point", point) as Vector2).distance_to(point) < 10.0, "montinho alcançável %s" % point)
		check(not park.call("find_path", (park.get("_dog") as Node2D).position, point).is_empty(), "caminho do Tiro até o montinho %s" % point)
	check(data.dig_spots.size() >= 6, "6 a 8 montinhos")
	for id: String in ["dog_start", "npc_nina", "npc_dog_pipoca", "walk_marker"]:
		check(data.points.has(id), "ponto " + id)
	var nina: Node2D = park.call("npc_node", "nina")
	var pipoca: Node2D = park.call("npc_node", "dog_pipoca")
	check(nina != null and pipoca != null, "Nina e Pipoca na praça")
	if nina and pipoca:
		check(pipoca.call("is_decor") and not nina.call("is_decor"), "Pipoca é decor")
		for npc: Node2D in [nina, pipoca]:
			var floor_point: Vector2 = park.call("nearest_floor_point", npc.position)
			check(floor_point.distance_to(npc.position) < 12.0, "personagem no chão: %s" % npc.position)
		# O sorteio retorna o centro da célula: admite meia diagonal de arredondamento.
		var rounding := (park.get("_nav") as AStarGrid2D).cell_size.length() / 2.0
		for attempt in 8:
			var near: Vector2 = park.call("floor_point_near", nina.position, 40.0)
			check(near.distance_to(nina.position) <= 40.0 + rounding + 0.01, "destino da Pipoca perto da Nina")
	# O Tiro some das salas durante o passeio e volta ao recolher.
	state.call("start_walk", "park_loop")
	await process_frame
	check(park.get("_dog") == null and house.get("_dog") == null, "Tiro fora das salas passeando")
	state.get("walk_state").current["ready_at"] = 0.0
	state.call("return_due_walk")
	await process_frame
	check(park.get("_dog") != null and house.get("_dog") != null, "pronto: o Tiro já voltou às salas, com a bagagem esperando")
	# Painel do portão, no molde das estações.
	var panel: Control = load("res://scripts/ui/progression_ui.gd").call("walks_panel")
	root.add_child(panel)
	await process_frame
	check(panel.find_child("WalkSlot", true, false) != null, "espaço do passeio")
	check(panel.find_child("CollectWalk", true, false) != null, "botão Recolher")
	check(panel.find_child("StartWalk_park_loop", true, false) != null, "cartão do passeio")
	panel.queue_free()
	var results: Array = []
	var events: Node = root.get_node("Events")
	events.connect("walk_collected", func(r: Dictionary) -> void: results.append(r))
	park.call("_collect_walk")
	await process_frame
	check(results.is_empty() and not state.call("walk_ready"), "guardar pelo mapa recebe a bagagem sem repetir o cartão")
	check(park.get("_dog") != null and house.get("_dog") != null, "Tiro segue em casa")
	# Painel andando e cancelamento com dois toques.
	_rest()
	state.call("start_walk", "park_loop")
	panel = load("res://scripts/ui/progression_ui.gd").call("walks_panel")
	root.add_child(panel)
	await process_frame
	var cancel: Button = panel.find_child("CancelWalk", true, false)
	check(cancel != null, "Chamar de volta aparece")
	if cancel:
		cancel.pressed.emit()
		check(state.call("walking"), "primeiro toque só arma")
		cancel.pressed.emit()
		check(not state.call("walking"), "segundo toque chama de volta")
	panel.queue_free()
	# Cartão "Volta do passeio".
	var card: CanvasLayer = load("res://scenes/ui/walk_result/walk_result.tscn").instantiate()
	root.add_child(card)
	card.call("show_result", {"id": "park_loop", "name": "Volta na praça", "postcard": state.call("walk_postcard", "park_loop"), "items": {"lost_ball": 1, "dog_food": 2}, "coins": 5, "needs": {"happiness": 20, "hygiene": -10}, "new": ["lost_ball"]})
	await process_frame
	check(card.visible and card.find_child("Found_lost_ball", true, false) != null, "cartão mostra achados")
	card.queue_free()
	park.queue_free()
	house.queue_free()
	await process_frame
