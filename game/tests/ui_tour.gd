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
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
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
	await _world("nature")
	places.call("open", "nature", "trees")
	await shot("b15_nature_trees")
	await _close()
	await _world("park")
	places.call("open", "park", "walk")
	await shot("b16_walks")
	await _close()
	await _world("house")
	places.call("open_npc", "lais")
	await shot("b17_npc_lais")
	await _close()
	await _sheet("Cenoura", sb.call("item_detail", "carrot"))  # o painel do item leva o nome dele no título
	await shot("b18_item_detail")
	await _close()
	await _sheet("Atributos", pu.call("skills_panel"))
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
	celebration.call("show_level", 6, {"coins": 50, "affection": 2, "items": {"carrot": 3}})
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
	await shot("e05_tray_sickle", 0.5)
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
	quit(0)


func _empty_plots() -> void:
	var plots: Array = state.get("plots")
	for i in plots.size():
		plots[i] = {"crop": "", "ready_at": 0.0}
	state.call("_changed")


## Posição do dedo que deixa o fantasma da bandeja sobre o canteiro `index`.
func _finger(room: Node, index: int) -> Vector2:
	return (room.call("world_to_screen", room.call("plot_center", index)) as Vector2) + Vector2(0, 40)
