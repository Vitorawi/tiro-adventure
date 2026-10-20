extends SceneTree
## Teste focado. Mutação de disco restrita à subpasta growth_test_fixture.
var failures := 0
var state: Node
var db: Node
var saver: Node
var events: Node
var ready_count := 0
var done_count := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Growth: " + message)

func row(id: String) -> Dictionary:
	for req: Dictionary in state.call("growth_info").requirements:
		if req.id == id:
			return req
	return {}

func _run() -> void:
	state = root.get_node("GameState")
	db = root.get_node("Database")
	saver = root.get_node("SaveManager")
	events = root.get_node("Events")
	root.remove_child(saver)
	saver.free()
	saver = load("res://tests/helpers/growth_test_save_manager.gd").new()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://growth_test_fixture"))
	events.growth_ready.connect(func(_id: String) -> void: ready_count += 1)
	events.growth_requirement_done.connect(func(_id: String, _req: String) -> void: done_count += 1)
	state.call("reset")
	check(state.get("growth").phase == "newborn" and row("home").done, "novo e progresso concedido")
	check(state.get("growth").done.puppy.home, "given persistido no reset")
	check(not state.call("grow_error").is_empty(), "crescimento incompleto tem motivo")
	var snapshot: Dictionary = state.call("to_dict").duplicate(true)
	state.call("growth_info")
	state.call("grow_error")
	check(state.call("to_dict") == snapshot, "consultas puras")
	# Alimentações reais, sem esperar o jogo; antes da fase não contam.
	state.get("inventory").add("dog_food", 6)
	for i in 3:
		check(state.call("feed", "dog_food") == true, "alimentação real")
	check(row("meals").have == 3 and row("meals").done, "três comidas nesta fase")
	state.get("progress").stats["feed"] = 0
	check(row("meals").done, "done permanece quando contador cai")
	state.get("progress").stats["feed"] = 3
	state.call("dev_grant_upgrade", "dog_bed")
	state.get("progress").claimed_quests["lais_bed"] = true
	# A partir da 03 feed ganha pontos; esta fixture isola a transferência exata de reserva.
	state.get("growth").points["body"] = 0
	state.get("growth").reserve["body"] = 0
	state.call("dev_add_pillar", "body", 30)
	state.call("dev_add_pillar", "brave", 10)
	check(state.call("grow_error") == "", "todos os requisitos reais cumpridos")
	check(ready_count == 1, "pronto uma vez")
	state.call("_changed")
	check(ready_count == 1, "não repete pronto")
	var before_coins: int = state.get("coins")
	var before_food: int = state.get("inventory").count("dog_food")
	check(state.call("grow") == "", "cresce")
	var growth: Variant = state.get("growth")
	check(growth.phase == "puppy" and growth.ceremonies.puppy.seen == false, "fase e cerimônia")
	check(growth.points.body == 25 and growth.reserve.body == 5, "reserva entra até teto novo")
	check(state.get("coins") == before_coins + 30 and state.get("inventory").count("dog_food") == before_food + 3, "presente exato")
	check(state.call("grow") != "" and state.get("coins") == before_coins + 30, "clique repetido não paga")
	check(row("meals").have == 0, "fase nova começa sem refeições antigas")
	state.get("inventory").add("frozen_carrot", 2)
	state.call("feed", "frozen_carrot")
	state.call("feed", "dog_food")
	check(row("meals").have == 1, "refeição específica só conta o item pedido")
	state.get("growth").cooldowns["bath"] = 123.0
	state.get("growth").firsts["npc:lais"] = true
	var growth_saved: Dictionary = state.get("growth").to_dict()
	state.call("from_dict", state.call("to_dict"))
	check(state.get("growth").to_dict() == growth_saved, "todos os campos de crescimento sobrevivem à recarga")
	check(state.get("growth").reserve.body == growth_saved.reserve.body and state.get("economy").granted.has("growth:puppy"), "reload mantém reserva e recibo")
	check(state.get("coins") == before_coins + 30, "reload não premia")
	check(state.call("requirement_error", {"growth": "teething"}) == "Quando ele for Dentinhos", "texto do requisito")
	check(state.call("requirement_error", {"growth": "puppy"}) == "", "fase já alcançada")
	var content: Dictionary = db.get("growth").duplicate(true)
	# Fixture de tipos já implementados, sem introduzir conteúdo futuro no JSON.
	db.get("growth").phases[2].requirements = [
		{"id": "gift", "type": "deliver", "item": "stick", "qty": 3},
		{"id": "walks", "type": "stat", "counter": "walk", "qty": 3},
		{"id": "outfit", "type": "collection", "collection": "community_ribbon"},
		{"id": "quest", "type": "quest", "quest": "lais_bed"},
		{"id": "project", "type": "project", "project": "village_festival"}]
	check(state.call("deliver_growth_error", "stick") != "", "sem item não entrega")
	state.get("inventory").add("stick", 1)
	check(state.call("deliver_growth", "stick") == "" and row("gift").have == 1, "entrega parcial")
	check(state.get("inventory").count("stick") == 0, "consome entrega")
	var mid: Dictionary = state.call("to_dict").duplicate(true)
	state.call("from_dict", mid)
	check(row("gift").have == 1 and not row("gift").done, "reload no meio da entrega")
	state.get("inventory").add("stick", 5)
	state.call("deliver_growth", "stick")
	check(row("gift").done and state.get("inventory").count("stick") == 3, "entrega só o restante")
	check(state.call("deliver_growth", "stick") != "", "entrega definitiva não repete")
	state.get("progress").stats["walk"] = 9
	state.get("growth").phase_stats["walk"] = 7
	check(row("walks").have == 2 and not row("walks").done, "contador usa diferença da fase")
	state.get("progress").stats["walk"] = 10
	state.get("progress").collection["community_ribbon"] = true
	state.get("projects").projects["village_festival"] = {"completed": true}
	state.call("_changed")
	check(row("walks").done and row("outfit").done and row("project").done and row("quest").done, "stat, coleção e projeto")
	state.get("projects").projects.clear()
	check(row("project").done, "projeto cumprido não regride")
	db.set("growth", content.duplicate(true))
	check(db.call("growth_problems").is_empty(), "JSON válido")
	for mutation: String in ["phase", "levels", "item", "quest", "owned", "project", "type", "req_id"]:
		db.set("growth", content.duplicate(true))
		var broken: Dictionary = db.get("growth")
		match mutation:
			"phase": broken.phases[1].id = "newborn"
			"levels": broken.levels[1] = 1
			"item": broken.phases[2].requirements[1].item = "missing"
			"quest": broken.phases[1].requirements.append({"id": "quest", "type": "quest", "quest": "missing"})
			"owned": broken.phases[1].requirements[1].upgrade = "missing"
			"project": broken.phases[5].requirements.append({"id": "extra_project", "type": "project", "project": "missing"})
			"type": broken.phases[1].requirements[0].type = "missing"
			"req_id": broken.phases[1].requirements[1].id = "home"
		check(not db.call("growth_problems").is_empty(), "detecta JSON quebrado: " + mutation)
	db.set("growth", content)
	# As cinco transições pagam cada recompensa uma única vez; adulto não tem próxima fase.
	state.call("reset")
	before_coins = state.get("coins")
	for phase: String in ["puppy", "teething", "explorer", "young", "adult"]:
		state.call("dev_complete_growth_reqs")
		check(state.call("grow") == "" and state.get("growth").phase == phase, "transição para " + phase)
	check(state.get("coins") == before_coins + 590, "soma dos cinco presentes")
	check(not state.call("growth_info").ready and state.call("grow") != "", "adulto sem sexta transição")
	await _reset_saves()
	check(done_count > 0, "eventos de requisito")
	print("GROWTH TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	saver.free()
	quit(0 if failures == 0 else 1)

func _reset_saves() -> void:
	var settings_path: String = saver.call("_settings_path")
	saver.call("set_vibrate", false)
	saver.call("set_reduced_motion", true)
	var settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(settings_path))
	settings.erase("last_session_active")
	var real_save := {"save_version": 12, "state": state.call("to_dict")}
	for path: String in ["res://../tiro02/vitor_save_copy.json", "res://../build/tiro02/vitor_save_copy.json"]:
		if FileAccess.file_exists(path):
			real_save = JSON.parse_string(FileAccess.get_file_as_string(path))
			print("Cópia do save atual: ", path)
			break
	for slot: int in [4, 5]:
		var path: String = saver.call("slot_path", slot)
		var file := FileAccess.open(path, FileAccess.WRITE)
		real_save["save_version"] = 12
		file.store_string(JSON.stringify(real_save))
		file.close()
		saver.set("active_slot", slot)
		saver.set("_save_path", path)
		saver.call("load_game")
		check(state.get("growth").phase == "newborn" and state.get("progress").claimed_quests.is_empty(), "slot v12 zerado: %d" % slot)
		check(state.get("coins") == int(db.get("start").get("coins", 0)), "saldo inicial")
		check(int(JSON.parse_string(FileAccess.get_file_as_string(path)).save_version) == 13, "regrava v13")
		check(saver.call("take_reset_notice") == "O Tiro chegou de novo, filhotinho!", "aviso carinhoso")
		check(saver.call("take_reset_notice") == "", "aviso uma vez")
		saver.call("load_game")
		check(saver.call("take_reset_notice") == "", "reabrir não repete aviso")
	var after_settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(settings_path))
	after_settings.erase("last_session_active")
	check(after_settings == settings, "todas as preferências de settings preservadas (timestamp de atividade é atualizado)")
	# Imagem somente da nova página DEV em 360×780.
	if "--shot" in OS.get_cmdline_user_args():
		state.get("progress").seen["intro"] = true
		var main: Node = load("res://scenes/main/main.tscn").instantiate()
		root.add_child(main)
		var panel: Script = load("res://scripts/ui/dev_panel.gd")
		panel.set("_page", "growth")
		events.sheet_requested.emit("Ferramentas DEV", panel.call("panel"))
		await create_timer(0.5).timeout
		root.get_texture().get_image().save_png("res://../tiro02/dev_growth.png")
		main.queue_free()
		await process_frame
		# O aviso de reset espera a introdução sair, para não ficar escondido atrás dela.
		state.get("progress").seen.erase("intro")
		saver.name = "SaveManager"
		saver.set("reset_notice_pending", true)
		root.add_child(saver)
		main = load("res://scenes/main/main.tscn").instantiate()
		root.add_child(main)
		await process_frame
		var intro: Node = main.get("_intro")
		check(is_instance_valid(intro), "reset reapresenta a chegada")
		check(not main.find_child("Toast", true, false).visible, "aviso espera a introdução")
		intro.call("_finish")
		await create_timer(0.5).timeout
		check(main.find_child("ToastText", true, false).text == "O Tiro chegou de novo, filhotinho!", "aviso visível após a chegada")
		root.get_texture().get_image().save_png("res://../tiro02/reset_notice.png")
		main.queue_free()
		root.remove_child(saver)
		await process_frame

