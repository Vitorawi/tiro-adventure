extends SceneTree
## Regras de janela, progresso, ausência real, transações e persistência da Etapa 09.
var state: Node
var db: Node
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Amigos: " + message)

func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/friend_clock.gd"))
	state.set("test_time", 1791936000.0)
	state.call("reset")
	check(state.call("friends_present").is_empty(), "nada antes da história")
	var p: RefCounted = state.get("progress")
	for id: String in db.get("quests"):
		if id.begins_with("nina") and id not in ["nina_pipoca", "nina_friends"]:
			p.claimed_quests[id] = true
	p.claimed_quests["main_2_order"] = true
	state.call("_changed")
	check(p.current_line_quest("nina") == "nina_pipoca" and "pipoca" in state.call("friends_present"), "Pipoca acessível com missão ativa")
	var inventory: RefCounted = state.get("inventory")
	inventory.add("carrot_snack", 20)
	var before: int = state.get("coins")
	check(state.call("give_friend", "pipoca") == "", "primeiro petisco")
	check(state.get("coins") == before + 10 and state.call("friend_hearts", "pipoca") == 1, "primeiro coração paga dez uma vez")
	check(state.call("give_friend", "pipoca") != "" and inventory.count("carrot_snack") == 19, "janela bloqueia sem consumir")
	check(state.call("claim_quest", "nina_pipoca") == "", "missão concluível sem ciclo")
	p.owned["blender"] = true
	p.claimed_quests["bloblo_potato"] = true
	p.claimed_quests["bloblo_sweet_potato"] = true
	state.call("_changed")
	var present: Array = state.call("friends_present")
	check(present.size() == 2, "Pipoca e só um visitante")
	state.set("test_time", state.get("test_time") + 30)
	check(state.call("friends_present") == present, "visitante estável na janela")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	check(state.call("friends_present") == present and state.call("give_friend_error", "pipoca") != "", "persistência da janela")
	var prior_visitor: String = str(present[1])
	state.set("test_time", state.get("test_time") + 10800)
	state.call("_changed")
	check(state.call("friends_present")[1] != prior_visitor, "próxima janela troca visitante com mesmo conjunto liberado")
	for n in range(2, 7):
		state.set("test_time", state.get("test_time") + 10800)
		state.call("_changed")
		check(state.call("give_friend", "pipoca") == "", "petisco em janela nova %d" % n)
		check(state.call("friend_hearts", "pipoca") == (1 if n < 3 else (2 if n < 6 else 3)), "limiares 1/3/6")
	p = state.get("progress")
	check(p.stat("friend_level") == 3 and p.collection.has("caramel_bandana"), "corações somados e bandana única")
	check(int(state.get("coins")) == before + 80 and int(state.get("friend_state").entry("pipoca").claimed_hearts) == 3, "três recompensas e missão pagas uma vez")
	check(state.call("equip_error", "caramel_bandana") == "Em breve no Tiro", "bandana sem overlay não veste arte invisível")
	var window: String = state.call("friend_window")
	state.set("test_time", state.get("test_time") - 86400)
	check(state.call("friend_window") == window and state.call("give_friend_error", "pipoca") != "", "atrasar relógio não reabre janela")
	state.set("zone_bias", -7200)
	check(state.call("friend_window") == window, "trocar fuso para trás não reabre janela")
	state.set("zone_bias", 0)
	state.set("test_time", state.get("test_time") + 86400)
	var entry: Dictionary = state.get("friend_state").entry("pipoca")
	var since: float = state.get("test_time")
	state.get("friend_state").last_active_at = since
	state.set("test_time", since + 28801)
	# from_dict e updates online não criam visitas.
	saved = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	check(not state.get("friend_state").entry("pipoca").visit_pending, "carregar estado não inventa ausência")
	state.call("update_friend_visits", state.get("test_time") - 60)
	check(not state.get("friend_state").entry("pipoca").visit_pending, "online por oito horas não basta")
	state.call("update_friend_visits", since)
	entry = state.get("friend_state").entry("pipoca")
	check(entry.visit_pending, "ausência contínua de oito horas gera visita")
	for id: String in ["mel", "bolota", "fred"]:
		check(not state.get("friend_state").entry(id).visit_pending, "sem amizade máxima não visita: " + id)
	var gift: Dictionary = entry.visit_gift.duplicate(true)
	saved = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	state.call("update_friend_visits", since)
	check(state.get("friend_state").entry("pipoca").visit_gift == JSON.parse_string(JSON.stringify(gift)), "presente persistido sem ressorteio")
	check(state.call("collect_friend_visit", "pipoca") == "", "recolhe visita")
	before = state.get("coins")
	check(state.call("collect_friend_visit", "pipoca") != "" and state.get("coins") == before, "presente uma única vez")
	state.call("from_dict", JSON.parse_string(JSON.stringify(state.call("to_dict"))))
	check(state.call("collect_friend_visit_error", "pipoca") != "", "recebimento persiste")
	await _walks()
	_storage()
	_lifecycle()
	_calendar()
	await _ui()
	print("FRIENDS TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)

func _walks() -> void:
	var p: RefCounted = state.get("progress")
	p.owned["walk_bag"] = true
	p.owned["petshop"] = true
	p.stats["walk"] = 20
	state.get("dog").needs.energy = 100.0
	state.get("dog").updated_at = state.get("test_time")
	check(state.call("start_walk", "park_loop") == "", "inicia passeio")
	state.get("walk_state").current.ready_at = 1.0
	var loot: Dictionary = state.call("walk_loot")
	var table: Array = db.get("walks").walks.park_loop.loot.table
	var original: Array = table.duplicate(true)
	table.clear()
	table.append({"weight": 1, "items": {"stick": 1}})
	var bonus: Dictionary = state.call("walk_loot")
	var first_sticks: int = int(db.get("walks").walks.park_loop.loot.first.items.stick) if bonus.first else 0
	check(int(bonus.items.stick) == int(db.get("walks").walks.park_loop.loot.rolls) + 2 + first_sticks, "base + bolsinha + Pipoca somam dois sorteios extras")
	check(state.call("walk_loot") == bonus, "mesma seed mesmo resultado")
	table.clear()
	table.append_array(original)
	check(state.call("walk_loot") == loot, "tabelas restauradas mantêm raro e lendário")
	check(state.call("collect_walk_error") == "", "mesmo resultado na validação")
	var result: Dictionary = state.call("collect_walk")
	check(result.items == loot.items, "coleta exatamente o previsto")
	# Os sorteios extras não deslocam os sete raros nem os dois lendários.
	for id: String in db.get("walks").walks:
		var def: Dictionary = db.get("walks").walks[id]
		var rare_id: String = def.loot.rare.collection
		p.collection.erase(rare_id)
		for legendary: String in db.get("walks").legendary.collections:
			p.collection.erase(legendary)
		state.get("walk_state").current = {"id": id, "seed": 1234, "energy": 0, "started_at": 1.0, "ready_at": 1.0}
		state.get("walk_state").pity[id] = int(def.loot.rare.pity) - 1
		state.get("walk_state").pity.legendary = 29
		var with_bonus: Dictionary = state.call("walk_loot")
		var gifts: int = state.get("friend_state").entry("pipoca").gifts
		state.get("friend_state").entry("pipoca").gifts = 0
		p.owned.erase("walk_bag")
		var without_bonus: Dictionary = state.call("walk_loot")
		check(with_bonus.rare_item == rare_id and with_bonus.rare_item == without_bonus.rare_item and with_bonus.legendary == without_bonus.legendary and str(with_bonus.legendary) != "", id + ": raro e lendário independentes dos extras")
		state.get("friend_state").entry("pipoca").gifts = gifts
		p.owned.walk_bag = true
		state.call("cancel_walk")
		check(int(state.get("walk_state").pity[id]) == int(def.loot.rare.pity) - 1, id + ": cancelar preserva garantia")
	# A mesma soma de itens é usada no erro e na coleta, inclusive com a geladeira cheia.
	p.owned.fridge = true
	state.get("inventory").add("carrot_snack", int(state.call("storage_capacity", "fridge")))
	state.get("walk_state").current = {"id": "park_loop", "seed": 1, "energy": 0, "started_at": 1.0, "ready_at": 1.0}
	table.clear()
	table.append({"weight": 1, "items": {"carrot_snack": 1}})
	var snapshot: Dictionary = state.get("walk_state").to_dict()
	check(state.call("collect_walk_error") != "" and state.call("collect_walk").is_empty(), "bônus não contorna armazenamento")
	check(state.get("walk_state").to_dict() == snapshot, "falha preserva passeio, histórico e todas as garantias")
	table.clear()
	table.append_array(original)
	state.call("cancel_walk")

func _storage() -> void:
	var p: RefCounted = state.get("progress")
	p.owned["fridge"] = true
	var entry: Dictionary = state.get("friend_state").entry("pipoca")
	entry.visit_pending = true
	entry.visit_gift = {"coins": 9, "items": {"carrot_snack": 2}}
	var inv: RefCounted = state.get("inventory")
	inv.add("carrot_snack", int(state.call("storage_capacity", "fridge")))
	check(state.call("collect_friend_visit_error", "pipoca") != "", "cheio bloqueia presente")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	check(state.call("collect_friend_visit", "pipoca") != "" and state.get("friend_state").entry("pipoca").visit_pending, "cheio não consome visita")
	state.call("from_dict", saved)
	check(state.get("friend_state").entry("pipoca").visit_gift == JSON.parse_string(JSON.stringify(entry.visit_gift)), "falha e save mantêm presente")

func _ui() -> void:
	var room: Control = load("res://scenes/levels/room/room.tscn").instantiate()
	room.set("room_id", "park")
	room.set("world_id", "park")
	root.add_child(room)
	await process_frame
	var npc: Node = room.call("npc_node", "dog_pipoca")
	check(npc != null and not npc.call("is_decor"), "Pipoca reutiliza NpcWorld e vira amiga")
	var p: RefCounted = state.get("progress")
	p.claimed_quests.erase("nina_sewing")
	check(npc.call("is_decor"), "antes da missão Pipoca continua decorativa")
	p.claimed_quests["nina_sewing"] = true
	var target: Vector2 = room.call("nearest_floor_point", Vector2(370, 230))
	var start: Vector2 = room.call("nearest_floor_point", Vector2(238, 262))
	check(target.distance_to(Vector2(370, 230)) < 16 and not room.call("find_path", start, target).is_empty(), "visitante em chão alcançável sem mudar obstáculos")
	var visitors := 0
	for n: Node in room.get("_npcs"):
		if n.get("npc_id") == "":
			visitors += 1
	check(visitors == 1, "um NpcWorld visitante na Praça")
	room.queue_free()
	var friend_ui: Script = load("res://scripts/ui/friend_ui.gd")
	var card: Control = friend_ui.call("panel", "pipoca")
	root.add_child(card)
	await process_frame
	check(card.get_child_count() > 0, "cartão montado")
	card.queue_free()

func _lifecycle() -> void:
	var fs: RefCounted = state.get("friend_state")
	var entry: Dictionary = fs.entry("pipoca")
	entry.visit_pending = false
	entry.visit_gift = {}
	entry.last_visit = 0.0
	entry.best_at = float(state.get("test_time")) - 90000
	fs.last_active_at = float(state.get("test_time")) - 30000
	var saver: Node = load("res://tests/friend_save_clock.gd").new()
	saver.set("_save_path", saver.call("slot_path", 1))
	# save_game grava presença atual: constrói o snapshot ausente com uma pausa simulada.
	saver.set("_away_since", fs.last_active_at)
	saver.call("save_game")
	saver.set("_away_since", 0.0)
	saver.set("_last_session_active", float(state.get("test_time")) - 30)
	saver.call("load_game")
	check(not state.get("friend_state").entry("pipoca").visit_pending, "atividade em outro slot impede visita por save velho")
	fs = state.get("friend_state")
	fs.last_active_at = float(state.get("test_time")) - 30000
	saver.set("_away_since", fs.last_active_at)
	saver.call("save_game")
	saver.set("_away_since", 0.0)
	saver.set("_first_load", true)
	saver.call("load_game")
	check(state.get("friend_state").entry("pipoca").visit_pending, "primeira abertura após ausência cria visita")
	var visit: Dictionary = state.get("friend_state").entry("pipoca").visit_gift.duplicate(true)
	saver.set("_first_load", true)
	saver.call("load_game")
	check(state.get("friend_state").entry("pipoca").visit_gift == JSON.parse_string(JSON.stringify(visit)), "reabrir não muda presente pendente")
	state.get("friend_state").entry("pipoca").visit_pending = false
	saver.call("save_game")
	state.set("test_time", state.get("test_time") + 30000)
	saver.call("load_game")
	check(not state.get("friend_state").entry("pipoca").visit_pending, "troca de slot não cria visita")
	saver.call("_notification", Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var left_at: float = saver.get("_away_since")
	state.set("test_time", state.get("test_time") + 28801)
	saver.call("_notification", Node.NOTIFICATION_APPLICATION_PAUSED)
	check(float(saver.get("_away_since")) == left_at, "notificações duplicadas não reiniciam ausência")
	saver.call("_notification", Node.NOTIFICATION_APPLICATION_RESUMED)
	check(state.get("friend_state").entry("pipoca").visit_pending and float(saver.get("_away_since")) == 0.0, "retorno real do segundo plano gera visita uma vez")
	var resumed: Dictionary = state.get("friend_state").entry("pipoca").visit_gift.duplicate(true)
	saver.call("_notification", Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(state.get("friend_state").entry("pipoca").visit_gift == resumed, "resumed/focus-in não ressorteiam")
	for path: String in [str(saver.call("slot_path", 1)), str(saver.call("_settings_path"))]:
		DirAccess.remove_absolute(path)
	saver.free()

func _calendar() -> void:
	# Bloco 7 -> bloco 0 do dia seguinte, fuso e avanço do relógio.
	var index: int = state.call("friend_window_index")
	var midnight := float((index / 8 + 2) * 86400)
	state.set("test_time", midnight - 1)
	state.call("_changed")
	var previous: String = state.call("friend_window")
	state.set("test_time", midnight)
	state.call("_changed")
	check(state.call("friend_window") != previous and str(state.call("friend_window")).ends_with("-0"), "virada do dia abre janela local zero")
	var window: String = state.call("friend_window")
	state.set("zone_bias", -10800)
	state.call("_changed")
	check(state.call("friend_window") == window, "fuso para trás não duplica janela")
	state.set("zone_bias", 10800)
	state.call("_changed")
	check(state.call("friend_window") != window, "fuso para frente avança uma janela")
	state.set("zone_bias", 0)
