extends SceneTree
## Avisos de conclusão separados por aba; usa a interface real sem gravar o save pessoal.
var failures := 0
var state: Node
var main: Control

func _initialize() -> void: _run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("READY BADGES: " + message)

func frames() -> void:
	for i in 4: await process_frame

func shot(file: String) -> void:
	if DisplayServer.get_name() == "headless": return
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	(main.get("_toast") as Control).hide()
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://").path_join("../build/screenshots/ready_badges").simplify_path()
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join(file + ".png"))

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	var places: Script = load("res://scripts/ui/places.gd")
	var initial: Dictionary = places.call("world_summary", "house")
	check(initial.missions > 0 and initial.collections == 0 and initial.finds == 0, "missão disponível não vira coleta nem achado")
	check(not main.get("_map_badge").visible, "missão nova não avisa no Mapa")
	state.get("progress").stats["talk:lais"] = 1
	root.get_node("Events").emit_signal("state_changed")
	main.call("show_screen", &"tasks")
	await frames()
	check(main.get("_tasks_badge").text == "1", "uma missão pronta, sem duplicar")
	check(main.find_child("StoryCard", true, false).find_child("ReadyDot", true, false) != null, "bolinha na missão pronta")
	await shot("mission_ready")
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	for kind: String in ["daily", "weekly"]:
		for id: String in state.call("routine_ids", kind):
			state.get("progress").routines[kind].claimed[id] = true
	for world: String in state.get("finds").worlds:
		state.get("finds").worlds[world].pending = 0
		state.get("finds").worlds[world].next_at = state.call("now") + 99999
	for id: String in state.get("stations"): state.get("stations")[id].queue.clear()
	var future: float = state.call("now") + 1000
	for i in 2:
		state.get("plots")[i] = {"crop": "carrot", "planted_at": future - 10, "ready_at": future}
	state.call("station", "stove").enqueue("carrot_snack", 1000, state.call("now"))
	state.call("station", "sewing").enqueue("sew_flower_crown", 1000, state.call("now"))
	state.get("progress").gathering["rocks"] = [{"id": "quarry", "ready_at": future}]
	state.get("progress").activity = {"id": "orchard_harvest", "ready_at": future}
	state.get("walk_state").current = {"id": "park_loop", "ready_at": future}
	main.call("_refresh_tasks_badge")
	check(not main.get("_map_badge").visible, "produção em andamento não avisa")
	check(not main.get("_tasks_badge").visible, "campanha e rotinas recebidas não avisam")
	state.call("dev_finish_timers")
	state.get("walk_state").current.ready_at = state.call("now") - 1
	state.call("return_due_walk")
	var counts: Dictionary = state.call("world_ready_counts")
	check(counts.get("farm", 0) == 3, "Sítio: dois canteiros e pomar")
	check(counts.get("house", 0) == 1, "Casa: fogão, sem contar lugares duplicados")
	check(counts.get("park", 0) == 2, "Praça: costura e passeio")
	check(counts.get("nature", 0) == 1, "Natureza: coleta pronta")
	main.call("_refresh_tasks_badge")
	check(main.get("_map_badge").text == "7", "Mapa soma sete coletas")
	check(not main.get("_tasks_badge").visible, "sete coletas não viram sete missões")
	main.call("show_screen", &"map")
	var worlds: Control = main.find_child("WorldsScreen", true, false)
	worlds.call("show_map")
	await frames()
	var farm := main.find_child("WorldCard_farm", true, false)
	var village := main.find_child("WorldCard_village", true, false)
	check(farm.find_child("WorldStatus_collections", true, false) != null, "linha identifica coletas do mundo")
	check(village.find_child("WorldStatus_collections", true, false) == null, "mundo sem coleta não avisa por missão nova")
	await frames()
	await shot("world_collections")
	state.get("inventory").from_dict({})
	check(not (state.call("harvest", 0) as Dictionary).is_empty(), "colheita real")
	main.call("_refresh_tasks_badge")
	check(main.get("_map_badge").text == "6", "contagem diminui depois de colher")
	# Sem sinal de ação: o temporizador atualiza também o seletor aberto.
	state.get("plots")[1].crop = ""
	state.get("progress").activity = {}
	await create_timer(1.15).timeout
	check(farm.find_child("WorldStatus_collections", true, false) == null, "coletas somem enquanto seletor está aberto")
	check(main.get("_map_badge").text == "4", "temporizador atualiza total")
	# O carrossel separa achados das coletas sem alterar o total legado da aba.
	state.get("finds").worlds["house"] = {"pending": 1, "next_at": state.call("now") + 99999, "seed": 1, "spot": 0, "dug": 0}
	state.get("progress").claimed_quests.erase("welcome")
	state.get("progress").stats["talk:lais"] = 1
	var summary: Dictionary = places.call("world_summary", "house")
	check(summary.collections == 1 and summary.finds == 1 and summary.rewards == 1, "produção, achado e prêmio de missão têm contagens independentes")
	check(state.call("world_ready_counts").get("house", 0) == 2, "total existente continua somando produção e achado uma vez")
	worlds.call("show_map")
	await frames()
	var house: Control = main.find_child("WorldCard_house", true, false)
	house.call("refresh", "farm")
	await frames()
	for category: String in ["rewards", "collections", "finds"]:
		var row: Control = house.find_child("WorldStatus_" + category, true, false)
		check(row != null, "cartão mostra categoria " + category)
		if row: check(house.get_global_rect().encloses(row.get_global_rect()), "categoria cabe no cartão: " + category)
	await shot("world_categories_house_%d" % root.size.x)
	state.get("progress").claimed_quests["welcome"] = true
	var nature_before: Dictionary = places.call("world_summary", "nature")
	state.get("progress").seen.erase("treasure_opened")
	var nature_summary: Dictionary = places.call("world_summary", "nature")
	check(nature_summary.treasure == 1 and nature_summary.collections == nature_before.collections, "baú disponível não é coleta")
	var nature_card: Control = main.find_child("WorldCard_nature", true, false)
	nature_card.call("refresh", "house")
	await frames()
	check(nature_card.find_child("WorldStatus_treasure", true, false) != null, "cartão de Natureza identifica tesouro separado")
	await shot("world_categories_nature_%d" % root.size.x)
	state.get("finds").worlds.house.pending = 0
	state.get("progress").seen["treasure_opened"] = true
	await create_timer(1.15).timeout
	check(house.find_child("WorldStatus_finds", true, false) == null, "achado some da lista quando não está mais pendente")
	check(places.call("world_summary", "nature").treasure == 0, "baú aberto deixa de avisar")
	print("READY BADGES TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
