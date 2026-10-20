extends SceneTree
## Tour de capturas da interface (régua visual do plano "Interface nova"). NÃO é teste: não entra no test_all.
## Rodar SEM --headless (precisa de gráficos), no tamanho do celular:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/ui_tour.gd -- --out=etapaNN_antes
## PNGs numerados em build/screenshots/<out>/ (padrão "ui_tour"). Não grava o save pessoal.
## Cada etapa que cria tela nova acrescenta as capturas dela aqui.

var state: Node
var main: Node
var folder := "res://../build/screenshots/ui_tour/"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()


func shot(shot_name: String, wait: float = 0.8) -> void:
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path + shot_name + ".png")


func _sheet(title: String, content: Control) -> void:
	root.get_node("Events").emit_signal("sheet_requested", title, content)
	await create_timer(0.5).timeout


func _close() -> void:
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.3).timeout


## Esconde cartões modais (nível, boas-vindas, passeio, comemoração) que atrapalhariam a captura.
func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


func _world(id: String) -> void:
	main.call("_on_world_requested", id, "")
	await create_timer(2.0).timeout
	_hide_modals()


func _start_main(wait: float) -> void:
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.find_child("PetScreen", true, false).set("preview_hour", 12)
	await create_timer(wait).timeout
	_hide_modals()


func _run() -> void:
	# O SaveManager fica (o painel de configurações lista os saves), mas sem gravar nada do tour:
	# sem autosave nem batimento, e o caminho de escrita vai para um arquivo temporário.
	var saver: Node = root.get_node("SaveManager")
	var events: Node = root.get_node("Events")
	events.state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", "user://ui_tour_descartavel.json")
	state = root.get_node("GameState")
	var places: Script = load("res://scripts/ui/places.gd")
	var sb: Script = load("res://scripts/ui/sheet_builder.gd")
	var pu: Script = load("res://scripts/ui/progression_ui.gd")
	if "--ceremony-only" in OS.get_cmdline_user_args():
		state.call("reset")
		state.get("progress").seen["intro"] = true
		await _start_main(1.0)
		await _growth_panel_shots()
		await _ceremony_shots()
		quit(0)
		return
	if "--hud-growth-only" in OS.get_cmdline_user_args():
		state.call("reset")
		state.get("progress").seen["intro"] = true
		await _start_main(1.0)
		await shot("t05_hud_growth")
		main.find_child("TopBar", true, false).call("show_level_popover")
		await shot("t05_hud_popover", 0.3)
		main.get_node("PopoverCatcher").free()
		main.call("show_screen", &"tasks")
		await shot("t05_mission_rewards")
		quit(0)
		return
	if "--growth-panel-only" in OS.get_cmdline_user_args():
		state.call("reset")
		state.get("progress").seen["intro"] = true
		state.call("dev_unlock_everything")
		state.call("_mark_all_seen")
		await _start_main(1.0)
		await _growth_panel_shots()
		quit(0)
		return
	if "--growth-only" in OS.get_cmdline_user_args():
		state.call("reset")
		state.get("progress").seen["intro"] = true
		state.call("dev_unlock_everything")
		state.call("_mark_all_seen")
		await _start_main(1.0)
		await _growth_visual_shots()
		quit(0)
		return
	if "--pet-only" in OS.get_cmdline_user_args():
		state.call("reset")
		state.get("progress").seen["intro"] = true
		state.call("dev_unlock_everything")
		state.call("_mark_all_seen")
		await _start_main(2.5)
		await _pet_shots()
		quit(0)
		return
	if "--festa-only" in OS.get_cmdline_user_args():
		state.call("reset")
		state.get("progress").seen["intro"] = true
		state.call("dev_unlock_everything")
		state.call("_mark_all_seen")
		await _start_main(1.5)
		await _festa_shots()
		quit(0)
		return
	if "--lists-only" in OS.get_cmdline_user_args():
		state.call("reset")
		state.get("progress").seen["intro"] = true
		state.call("dev_unlock_everything")
		state.call("_mark_all_seen")
		await _start_main(1.5)
		main.call("show_screen", &"wishes")
		await shot("b02_wishes")
		main.call("show_screen", &"tasks")
		await shot("b03_tasks")
		main.call("show_screen", &"bag")
		await shot("b04_bag")
		await _list_shots()
		quit(0)
		return
	# --- Começo de jogo ---
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("_changed")
	await _start_main(1.0)
	await shot("a01_pet")
	main.call("show_screen", &"tasks")
	await shot("a02_tasks")
	main.call("show_screen", &"map")
	main.find_child("WorldsScreen", true, false).call("show_map")
	await process_frame
	await process_frame
	main.find_child("WorldsScreen", true, false).get_node("%MapView").call("center_on", "farm", false)
	await shot("a03_map")
	await _world("house")
	await shot("a04_house")
	places.call("open", "house", "fridge")
	await shot("a05_fridge_sheet")
	await _close()
	# --- Meio/fim de jogo ---
	main.queue_free()
	await create_timer(0.5).timeout
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.call("plant", 0, "carrot")
	state.call("plant", 1, "potato")
	state.call("plant", 2, "pumpkin")
	state.call("cook", "carrot_snack")
	state.call("_changed")
	await _start_main(1.5)
	await shot("b01_pet")
	main.call("show_screen", &"wishes")
	await shot("b02_wishes")
	main.call("show_screen", &"tasks")
	await shot("b03_tasks")
	main.call("show_screen", &"bag")
	await shot("b04_bag")
	# Presentes para guardar (etapa 02 da economia): geladeira cheia, presente automático esperando.
	var gift_fill := int(state.call("storage_space", "fridge"))
	state.get("inventory").add("egg", gift_fill)
	state.call("_grant_automatic", "customer:lais:1", {"items": {"carrot_snack": 2}})
	state.call("_changed")
	await shot("b04b_bag_gifts", 3.6)
	state.get("economy").pending.clear()
	state.get("economy").granted.erase("customer:lais:1")
	state.get("inventory").remove("egg", gift_fill)
	state.call("_changed")
	main.call("show_screen", &"map")
	main.find_child("WorldsScreen", true, false).call("show_map")
	await shot("b05_map_list")
	for w: String in ["house", "farm", "park", "village", "nature"]:
		await _world(w)
		await shot("b06_world_" + w)
	# Sítio: canteiro vazio, canteiro crescendo, painel do sítio.
	await _world("farm")
	var farm: Node = main.find_child("World_farm", true, false)
	farm.call("_on_object_tapped", "plot", farm.find_child("plot_3", true, false))
	await shot("b07_plot_empty_tap")
	await _close()
	farm.call("_on_object_tapped", "plot", farm.find_child("plot_0", true, false))
	await shot("b08_plot_growing_tap")
	await _close()
	places.call("open", "farm", "plots")
	await shot("b09_farm_view")
	await _close()
	places.call("open", "farm", "workbench")
	await shot("b10_workbench")
	await _close()
	places.call("open", "farm", "chicken_coop")
	await shot("b11_coop")
	await _close()
	await _world("house")
	places.call("open", "house", "stove")
	await shot("b12_stove")
	await _close()
	places.call("open", "house", "bowl")
	await shot("b13_bowl")
	await _close()
	await _world("village")
	places.call("open", "village", "market")
	await shot("b14_market")
	await _close()
	places.call("open", "village", "orders")
	await shot("b14b_neighbor_orders")
	await _close()
	places.call("open", "village", "stall")
	await shot("b14c_own_stall")
	await _close()
	await _world("nature")
	places.call("open", "nature", "trees")
	await shot("b15_nature_trees")
	await _close()
	await _world("park")
	places.call("open", "park", "walk")
	await shot("b16_walks")
	await _close()
	# Etapa 20 da economia: Nossa praça e as fases do Banco (marcação, base, conforto, pronto).
	places.call("open", "park", "community")
	await shot("b16b_community")
	await _close()
	var bench_ui: Script = load("res://scripts/ui/project_ui.gd")
	state.set("coins", maxi(int(state.get("coins")), 300))
	state.call("start_project", "park_bench")
	await _sheet("Banco da Praça", bench_ui.call("panel", "park_bench"))
	await shot("b16c_bench_start")
	await _close()
	for phase: Array in [["plank", 4, "b16d_bench_base"], ["fabric", 2, "b16e_bench_comfort"]]:
		var phase_items: Dictionary = state.call("project_stage", "park_bench").needed
		for item: String in phase_items:
			state.get("inventory").add(item, int(phase_items[item]))
			state.call("contribute_project", "park_bench", item, int(phase_items[item]))
		await _world("park")
		await shot(str(phase[2]))
	await _sheet("Banco da Praça", bench_ui.call("panel", "park_bench"))
	await shot("b16f_bench_last_phase")
	await _close()
	# Etapa 21: com o banco pronto, Jardim da Vila e Piquenique da Praça começam juntos.
	var last_items: Dictionary = state.call("project_stage", "park_bench").needed
	for item: String in last_items:
		state.get("inventory").add(item, int(last_items[item]))
		state.call("contribute_project", "park_bench", item, int(last_items[item]))
	state.set("coins", maxi(int(state.get("coins")), 600))
	state.call("start_project", "village_garden")
	state.call("start_project", "park_picnic")
	for id: String in ["village_garden", "park_picnic"]:
		var first_items: Dictionary = state.call("project_stage", id).needed
		for item: String in first_items:
			state.get("inventory").add(item, int(first_items[item]))
			state.call("contribute_project", id, item, int(first_items[item]))
	await _world("park")
	await shot("b16g_picnic_world")
	await _sheet("Piquenique da Praça", bench_ui.call("panel", "park_picnic"))
	await shot("b16h_picnic_panel")
	await _close()
	await _world("village")
	await shot("b16i_garden_world")
	places.call("open", "village", "community")
	await shot("b16j_community_village")
	await _close()
	await _sheet("Jardim da Vila", bench_ui.call("panel", "village_garden"))
	await shot("b16k_garden_panel")
	await _close()
	# Etapa 22: Festa da Vila pronta (obras anteriores concluídas, banca 3) e o Encontro da turma.
	state.call("dev_grant_upgrade", "stall_3")
	for id: String in ["village_garden", "park_picnic"]:
		for index in range(1, int(state.call("project_stage", id).count)):
			var phase: Dictionary = root.get_node("Database").project(id).phases[index]
			for item: String in phase.items:
				state.get("inventory").add(item, int(phase.items[item]))
			for item: String in phase.items:
				state.call("contribute_project", id, item, int(phase.items[item]))
	state.set("coins", 500)
	state.call("start_project", "village_festival")
	for index in 3:
		var festa_phase: Dictionary = root.get_node("Database").project("village_festival").phases[index]
		for item: String in festa_phase.items:
			state.get("inventory").add(item, int(festa_phase.items[item]))
		for item: String in festa_phase.items:
			state.call("contribute_project", "village_festival", item, int(festa_phase.items[item]))
	await _world("village")
	await shot("b16l_festival_world")
	await _sheet("Festa da Vila", bench_ui.call("panel", "village_festival"))
	await shot("b16m_festival_panel")
	await _close()
	await _world("house")
	places.call("open_npc", "lais")
	await shot("b17_npc_lais")
	await _close()
	await _sheet("Cenoura", sb.call("item_detail", "carrot"))  # o painel do item leva o nome dele no título
	await shot("b18_item_detail")
	await _close()
	await _sheet("Crescimento", pu.call("skills_panel"))
	await shot("b19_skills")
	await _close()
	await _sheet("Coleção", pu.call("collection_panel"))
	await shot("b20_collection")
	await _close()
	await _sheet("História", pu.call("story_panel"))
	await shot("b21_story")
	await _close()
	places.call("open", "farm", "orchard")
	await shot("b22_orchard")
	await _close()
	await _world("farm")
	await _sheet("O que tem aqui?", places.call("world_list", "farm"))
	await shot("b22b_places_list")
	await _close()
	load("res://scripts/ui/settings_panel.gd").call("open")
	await shot("b23_settings")
	await _close()
	load("res://scripts/ui/game_manual.gd").call("open")
	await shot("b24_manual")
	await _close()
	load("res://scripts/ui/game_manual.gd").call("open", "stations")
	await shot("b24b_manual_stations")
	await _close()
	# Fogão trabalhando: bolinhas em andamento, na fila e prontas (no fim das telas de painel: acrescenta itens ao jogo).
	state.call("dev_add_items", 20)
	for i in 3:
		state.call("cook", "carrot_snack")
	state.call("dev_advance_time", 40)
	await _world("house")
	places.call("open", "house", "stove")
	await shot("b25_stove_busy")
	await _close()
	# --- Cartões ---
	var celebration: CanvasLayer = main.get("_celebration")
	var welcome: CanvasLayer = main.get("_welcome")
	var walk_card: CanvasLayer = main.get("_walk_result")
	main.call("show_screen", &"pet")
	celebration.call("show_bond", 6, {"coins": 50, "affection": 2, "items": {"carrot": 3}})
	await shot("c01_level_up")
	celebration.hide()
	var unlocks: Array[String] = ["place:farm/orchard"]
	celebration.call("show_unlocks", unlocks)
	await shot("c02_unlocks")
	celebration.hide()
	var progress: RefCounted = state.get("progress")
	progress.daily_gift["period"] = ""
	for id: String in ["stick", "ribbon", "carrot"]:
		state.get("inventory").add(id, 1)
	welcome.call("open")
	await shot("c03_welcome_back")
	welcome.hide()
	var result := {"id": "park_loop", "name": "Volta na praça", "postcard": state.call("walk_postcard", "park_loop"),
		"items": {"stick": 2, "ribbon": 1}, "coins": 12, "affection": 3, "needs": {"happiness": 20, "hygiene": -10}, "new": []}
	walk_card.call("show_result", result)
	await shot("c04_walk_result")
	walk_card.hide()
	state.get("walk_state").current = {"id": "park_loop", "ready_at": 1.0, "seed": 42}
	state.call("_changed")
	await shot("c04b_home_walk_ready")
	state.get("walk_state").current = {}
	state.call("_changed")
	await _world("farm")
	root.get_node("Events").emit_signal("toast_requested", "Missão concluída!")
	await shot("c05_toast", 0.3)
	# Balão do nível (toque no avatar do HUD), sobre o mundo aberto.
	await create_timer(2.2).timeout
	main.get_node("TopBar").call("show_level_popover")
	await shot("c06_hud_popover", 0.4)
	# --- Etapa 04: câmera dos mundos (zoom mínimo, duplo toque, painel aberto sobre um objeto) ---
	await create_timer(2.2).timeout
	await _world("farm")
	var world_farm: Node = main.find_child("World_farm", true, false)
	world_farm.call("_zoom_at", world_farm.size / 2.0, 0.0)
	await shot("d01_farm_zoom_out", 0.5)
	# Duplo toque no céu (zoom mínimo, área sempre vazia): aproxima.
	world_farm.call("_on_tap_released", Vector2(10, 10))
	world_farm.call("_on_tap_released", Vector2(12, 12))
	await shot("d02_farm_doubletap", 0.6)
	world_farm.call("recenter")
	await create_timer(0.5).timeout
	world_farm.call("_on_object_tapped", "place:workbench", world_farm.find_child("workbench", true, false))
	await shot("d03_sheet_over_object", 1.0)
	await _close()
	# Etapa 05: cobertura no meio da viagem, abaixo do HUD.
	Motion.reduced = false
	main.find_child("WorldsScreen", true, false).call("enter", "park", "")
	await shot("d04_transition", 0.2)
	await create_timer(0.5).timeout
	# Etapa 06: colheitas prontas e visão afastada (cozinha pronta fica na Casa).
	Motion.reduced = true
	state.call("dev_finish_timers")
	await _world("farm")
	world_farm.call("recenter")
	await shot("d05_farm_ready", 0.5)
	world_farm.set("_label_intro_until", 0.0)
	world_farm.call("_zoom_at", world_farm.size / 2.0, 0.0)
	await shot("d06_farm_zoom_out", 0.5)
	await _world("house")
	await shot("d07_house_ready", 0.5)
	# --- Etapa 07: bandeja de ação da horta ---
	await _world("farm")
	world_farm.call("recenter")
	await create_timer(0.5).timeout
	var progress_seen: Dictionary = state.get("progress").seen
	progress_seen["ui:tray_drag_hint"] = true
	progress_seen["ui:tray_harvest_hint"] = true
	_empty_plots()
	world_farm.call("open_plot_tray", 4)
	await shot("e01_tray_seeds", 0.5)
	world_farm.call("close_tray")
	var tray_script: Script = load("res://scripts/ui/action_tray.gd")
	world_farm.call("open_plot_tray", 1)
	await create_timer(0.3).timeout
	var tray: Control = tray_script.get("current")
	var path: Array[Vector2] = []
	for i in [1, 2, 3]:
		path.append(_finger(world_farm, i))
	tray.call("drag_through", "carrot", path, false)
	await shot("e02_tray_drag", 0.4)
	tray.call("release_item", path[2])
	await create_timer(0.3).timeout
	_empty_plots()
	world_farm.call("open_plot_tray", 9)
	await shot("e03_tray_greenhouse", 0.5)
	world_farm.call("close_tray")
	world_farm.call("_on_object_tapped", "place:greenhouse", world_farm.find_child("greenhouse", true, false))
	await shot("e03b_greenhouse_area", 0.5)
	await _close()
	state.call("plant", 5, "carrot")
	state.call("water", 5)
	world_farm.call("_on_plot_tapped", 5)
	await shot("e04_tray_growing", 0.5)
	world_farm.call("close_tray")
	_empty_plots()
	# O depósito cheio (itens do fogão acima) impediria colher: esvazia a mochila para a foice aparecer.
	(state.get("inventory") as RefCounted).call("from_dict", {})
	for i in 4:
		state.call("plant", i, "carrot")
	state.call("dev_finish_timers")
	world_farm.call("_animate_objects")
	world_farm.call("_on_plot_tapped", 1)
	await shot("e05_harvest_no_tray", 0.5)
	world_farm.call("close_tray")
	_empty_plots()
	progress_seen.erase("ui:tray_drag_hint")
	Motion.reduced = false
	world_farm.call("open_plot_tray", 0)
	await shot("e06_drag_hint", 1.0)
	world_farm.call("close_tray")
	Motion.reduced = true
	# --- Etapa 08: bandeja nas estações, criações e Natureza ---
	var bag: RefCounted = state.get("inventory")
	bag.call("from_dict", {})
	for id: String in state.get("stations"):
		state.get("stations")[id].queue.clear()
	state.set("animals", {})
	await _world("house")
	var house: Node = main.find_child("World_house", true, false)
	house.call("_animate_objects")
	house.call("recenter")
	bag.call("add", "carrot", 5)
	bag.call("add", "potato", 1)
	state.call("cook", "carrot_snack")
	await create_timer(0.5).timeout
	house.call("_on_object_tapped", "place:stove", house.find_child("stove", true, false))
	await shot("e07_tray_stove", 0.6)
	house.call("close_tray")
	bag.call("from_dict", {})
	state.call("_changed")
	house.call("_on_object_tapped", "place:stove", house.find_child("stove", true, false))
	await shot("e08_tray_stove_missing", 0.6)
	house.call("close_tray")
	bag.call("add", "strawberry", 3)
	state.call("_changed")
	house.call("_on_object_tapped", "place:blender", house.find_child("blender", true, false))
	await shot("e12_tray_blender", 0.6)
	house.call("close_tray")
	await _world("farm")
	world_farm.call("recenter")
	await create_timer(0.5).timeout
	world_farm.call("_on_object_tapped", "place:chicken_coop", world_farm.find_child("chicken_coop", true, false))
	await shot("e09_tray_coop_empty", 0.6)
	world_farm.call("close_tray")
	state.call("buy_animal", "chicken_white")
	state.call("buy_animal", "chicken_brown")
	bag.call("add", "corn", 5)
	state.call("_changed")
	state.call("cook", "eggs")
	world_farm.call("_on_object_tapped", "place:chicken_coop", world_farm.find_child("chicken_coop", true, false))
	await shot("e10_tray_coop_feed", 0.6)
	world_farm.call("close_tray")
	await _world("nature")
	var nature_room: Node = main.find_child("World_nature", true, false)
	nature_room.call("recenter")
	await create_timer(0.5).timeout
	nature_room.call("_on_object_tapped", "place:trees")
	await shot("e11_tray_trees", 0.6)
	nature_room.call("close_tray")
	state.get("progress").claimed_quests["nina_sewing"] = true
	state.get("inventory").call("add", "carrot_snack", 2)
	state.get("friend_state").entry("pipoca").last_window = ""
	state.call("_changed")
	await _world("park")
	load("res://scripts/ui/friend_ui.gd").call("open", "pipoca")
	await shot("e12_tray_friend_treat", 0.6)
	main.find_child("World_park", true, false).call("close_tray")
	await _pet_shots()
	await _list_shots()
	await _festa_shots()
	await _growth_panel_shots()
	await _ceremony_shots()
	quit(0)


## Etapa 09: usa os mesmos gestos públicos que o gui_input dos cuidados.
func _pet_shots() -> void:
	await _close()
	main.call("show_screen", &"pet")
	_hide_modals()
	var pet: Control = main.find_child("PetScreen", true, false)
	var care: Control = pet.find_child("CareTray", true, false)
	state.get("inventory").call("from_dict", {"dog_food": 5, "carrot": 3, "carrot_snack": 2})
	state.call("set_sleeping", false)
	pet.set("preview_hour", 12)
	state.call("_changed")
	await create_timer(0.5).timeout
	care.call("open_food_menu")
	await create_timer(0.3).timeout
	await shot("f08_pet_food_menu", 0.3)
	var head: Rect2 = pet.call("head_rect")
	care.call("press_item", "dog_food", care.call("item_center", "dog_food"))
	care.call("move_item", head.get_center() + Vector2(0, 40))
	await shot("f01_pet_drag_food", 0.3)
	care.call("release_item", head.get_center() + Vector2(0, 40))
	var dog: Rect2 = pet.call("dog_rect")
	var a := dog.get_center() + Vector2(-60, 40)
	var b := a + Vector2(120, 0)
	care.call("press_item", "sponge", care.call("item_center", "sponge"))
	care.call("move_item", a)
	for i in 5: care.call("move_item", b if i % 2 == 0 else a)
	await shot("f02_pet_sponge", 0.15)
	care.call("release_item", b)
	state.call("set_sleeping", true)
	await shot("f03_pet_sleep")
	state.call("set_sleeping", false)
	pet.set("preview_hour", 22)
	pet.call("_update_light")
	await shot("f04_pet_night")
	pet.set("preview_hour", 12)
	var notebook: Script = load("res://scripts/ui/pet_notebook.gd")
	notebook.call("open")
	await shot("f05_notebook_manual")
	state.get("growth").phase = "puppy"
	notebook.call("open", "growth")
	await shot("t06_notebook_growth")
	notebook.call("open", "collection")
	await shot("f06_notebook_collection")
	await _close()
	for id: String in ["hunger", "happiness", "energy", "hygiene"]: state.get("dog").needs[id] = 15.0
	state.get("dog").updated_at = state.call("now")
	state.call("_changed")
	await shot("f07_pet_low_needs")


func _empty_plots() -> void:
	var plots: Array = state.get("plots")
	for i in plots.size():
		plots[i] = {"crop": "", "ready_at": 0.0}
	state.call("_changed")


## Etapa 05: só as telas que receberam os novos corpos, na mesma cena.
func _growth_visual_shots() -> void:
	Motion.reduced = true
	var pet: Node = main.find_child("PetScreen", true, false)
	var animator: Node = pet.get("_animator")
	animator.set_process(false)
	state.get("dog").sleeping = false
	state.get("progress").equipped = {"head": "", "neck": "", "body": ""}
	for entry: Array in [["puppy", "t12_pet_puppy"], ["teething", "t13_pet_young"], ["adult", "t15_pet_adult"]]:
		state.call("dev_set_phase", entry[0])
		animator.call("_play", &"idle_breathe", 1)
		_hide_modals()
		await shot(entry[1], 0.3)
	# Igualdade do adulto renderizado com coat=1 e sem shader, mesma textura/tamanho/fundo.
	var target: TextureRect = animator.get("_target")
	var material := target.material
	await RenderingServer.frame_post_draw
	var with_shader := root.get_texture().get_image().get_region(Rect2i(target.get_global_rect()))
	target.material = null
	await process_frame
	await RenderingServer.frame_post_draw
	var original := root.get_texture().get_image().get_region(Rect2i(target.get_global_rect()))
	var differences := 0
	for y in original.get_height():
		for x in original.get_width():
			if original.get_pixel(x, y) != with_shader.get_pixel(x, y): differences += 1
	var path := ProjectSettings.globalize_path(folder)
	with_shader.save_png(path + "adult_shader.png")
	original.save_png(path + "adult_original.png")
	FileAccess.open(path + "adult_comparison.txt", FileAccess.WRITE).store_string("Pixels diferentes coat=1 vs sem shader: %d\n" % differences)
	assert(differences == 0, "O adulto deve continuar idêntico")
	target.material = material
	state.call("dev_set_phase", "teething")
	for id: String in ["red_scarf", "yellow_bow", "sponge_uniform"]:
		state.get("progress").collection[id] = true
		state.call("equip", id)
	animator.call("_play", &"idle_breathe", 1)
	await shot("t14_pet_young_outfit", 0.3)
	await _world("farm")
	var room: Node = main.find_child("World_farm", true, false)
	var dog: Node = room.get("_dog")
	dog.set_process(false)
	for entry: Array in [["puppy", "t16_farm_puppy"], ["adult", "t17_farm_adult"]]:
		state.call("dev_set_phase", entry[0])
		dog.call("_play", "idle", "south")
		(dog.get("_sprite") as AnimatedSprite2D).pause()
		_hide_modals()
		await shot(entry[1], 0.3)


## Posição do dedo que deixa o fantasma da bandeja sobre o canteiro `index`.
func _finger(room: Node, index: int) -> Vector2:
	return (room.call("world_to_screen", room.call("plot_center", index)) as Vector2) + Vector2(0, 40)


## Etapa 10: rotinas prontas, filtro de colheitas e toque nas roupas.
func _list_shots() -> void:
	await _close()
	state.call("dev_restart_routines")
	for kind: String in ["daily", "weekly"]:
		for id: String in state.call("routine_ids", kind):
			var goal: Dictionary = state.call("routine_data", kind, id).goal
			state.get("progress").stats[goal.key] = state.get("progress").stat(goal.key) + int(goal.target)
	state.call("_changed")
	_hide_modals()
	main.call("show_screen", &"tasks")
	await shot("g01_tasks_ready_many")
	state.get("inventory").call("from_dict", {"carrot": 4, "wheat": 3, "dog_food": 5, "plank": 2})
	main.call("show_screen", &"bag")
	await create_timer(0.3).timeout
	main.find_child("InventoryList", true, false).call("choose_category", "crop")
	await shot("g02_bag_filter")
	state.get("progress").collection.red_scarf = true
	state.call("equip", "red_scarf")
	await _sheet("Coleção", load("res://scripts/ui/progression_ui.gd").call("collection_panel"))
	await shot("g03_collection_grid")
	await _close()


## Etapa 12: cartões de festa (com animação ligada, para ver os raios e o confete), boas-vindas
## agrupado e as preferências novas nas configurações.
func _festa_shots() -> void:
	await _close()
	main.call("show_screen", &"pet")
	_hide_modals()
	Motion.reduced = false
	var celebration: CanvasLayer = main.get("_celebration")
	celebration.call("show_bond", 6, {"coins": 50, "affection": 2, "items": {"carrot": 3}})
	await shot("h01_level_card", 1.0)
	celebration.hide()
	celebration.call("show_chapter", 2, ["world:village", "feature:bag"] as Array[String])
	await shot("h02_chapter_card", 1.0)
	celebration.hide()
	celebration.call("show_treasure", {"coins": 200, "items": {"carrot": 3}, "collections": ["explorer_hat"], "unlocks": ["crop:blueberry"]})
	await shot("h03_treasure_confetti", 0.45)
	celebration.hide()
	Motion.reduced = true
	var welcome: CanvasLayer = main.get("_welcome")
	var progress: RefCounted = state.get("progress")
	progress.daily_gift["period"] = ""
	var finds: RefCounted = state.get("finds")
	var world_ids: Array = root.get_node("Database").get("finds").worlds.keys()
	for i in mini(3, world_ids.size()):
		finds.worlds[world_ids[i]] = {"next_at": 0.0, "pending": 1, "spot": 0, "dug": 0, "seed": 0}
	_empty_plots()
	for i in 3:
		state.call("plant", i, "carrot")
	state.call("dev_finish_timers")
	welcome.call("open")
	await shot("h04_welcome_grouped", 0.8)
	welcome.hide()
	load("res://scripts/ui/settings_panel.gd").call("open")
	await shot("h05_settings_haptics", 0.8)
	await _close()


## Etapa 06: mesmos estados nas três resoluções, incluindo a caderneta em rolagem.
func _growth_panel_shots() -> void:
	var growth_ui: Script = load("res://scripts/ui/growth_ui.gd")
	state.call("dev_set_phase", "puppy")
	state.get("growth").done = {}
	state.get("growth").points = {}
	state.get("growth").reserve = {}
	state.get("progress").owned.erase("blender")
	state.call("_changed")
	_hide_modals()
	await shot("t00_growth_badge", 0.3)
	growth_ui.call("open")
	await shot("t01_growth_panel")
	state.get("growth").points = {"body": 25, "brave": 25}
	state.get("progress").owned["blender"] = true
	state.call("_changed")
	await shot("t02_growth_almost")
	await _close()
	await shot("t02b_growth_badge")
	growth_ui.call("open")
	await create_timer(0.3).timeout
	state.get("progress").stats["feed:carrot_snack"] = int(state.get("growth").phase_stats.get("feed:carrot_snack", 0)) + 3
	state.call("_changed")
	await shot("t03_growth_ready")
	var scroll := main.find_child("Sheet", true, false).find_child("Scroll", true, false) as ScrollContainer
	scroll.scroll_vertical = 420
	await shot("t03b_growth_notebook")
	scroll.scroll_vertical = 1200
	await shot("t03c_future_cards")
	await _close()
	for phase: String in ["newborn", "teething", "explorer", "young", "adult"]:
		state.call("dev_set_phase", phase)
		_hide_modals()
		growth_ui.call("open")
		await shot("t_phase_" + phase, 0.4)
		await _close()


## Portão 08: as cinco revelações reais pelo DEV, sem salvar o progresso pessoal.
func _ceremony_shots() -> void:
	await _close()
	main.call("show_screen", &"pet")
	var phases: Array = root.get_node("Database").get("growth").phases
	for index in range(1, phases.size()):
		_hide_modals()
		state.call("dev_set_phase", str(phases[index - 1].id))
		state.get("growth").ceremonies.erase(str(phases[index].id))
		main.get("_growth_queued").erase(str(phases[index].id))
		state.call("dev_complete_growth_reqs")
		state.call("_mark_all_seen")
		Motion.reduced = false
		state.call("grow")
		await create_timer(4.8).timeout
		await shot("t04_ceremony_" + str(phases[index].id), 0.1)
		if index == 2: await shot("t04_ceremony_before_after", 0.1)
		main.get("_growth_ceremony").call("_close")
		await create_timer(0.4).timeout
	Motion.reduced = true
