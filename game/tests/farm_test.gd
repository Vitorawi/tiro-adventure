extends SceneTree
## Teste dos canteiros e terrenos. Desliga o SaveManager antes de alterar o estado.
## --headless --path game -s res://tests/farm_test.gd
## Sem --headless e com -- --screenshots: salva prévias em build/screenshots.

var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)


func _run() -> void:
	var state: Node = root.get_node("GameState")
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state.call("reset")
	_check(state.call("accessible_plots") == 0, "Sem canteiros antes de conhecer a vovó Bloblo")
	state.call("reset")
	state.get("progress").owned["farm"] = true
	state.set("coins", 50)
	_check(state.get("unlocked_plots") == 4, "Jogo novo começa com quatro terrenos")
	_check(state.call("plant", 4, "carrot") != "", "Não pode plantar em terreno bloqueado")
	_check(state.call("buy_plot", 5) != "", "Não pode pular a ordem de compra")
	_check(state.call("buy_plot", -1) != "", "Índice inválido deve ser recusado")
	_check(state.call("buy_plot", 4) == "", "Primeira expansão deve funcionar")
	_check(state.get("coins") == 10, "Compra deve descontar uma única vez")
	_check(state.call("buy_plot", 4) != "" and state.get("coins") == 10, "Compra repetida não deve cobrar")
	_check(state.call("buy_plot", 5) != "" and state.get("unlocked_plots") == 5, "Saldo insuficiente não pode liberar terreno")
	_check(state.call("plant", 4, "carrot") == "", "Terreno comprado deve aceitar plantação")
	_check((state.call("harvest", 4) as Dictionary).is_empty(), "Não pode colher antes da hora")
	var plots: Array = state.get("plots")
	var now: float = state.call("now")
	plots[4]["planted_at"] = now - 30.0
	plots[4]["ready_at"] = now + 30.0
	_check(absf(float(state.call("plot_progress", 4)) - 0.5) < 0.02, "Progresso deve refletir o tempo decorrido")
	var saved: Dictionary = (state.call("to_dict") as Dictionary).duplicate(true)
	state.call("from_dict", saved)
	_check(state.get("unlocked_plots") == 5 and absf(float(state.call("plot_progress", 4)) - 0.5) < 0.02, "Save deve preservar expansão e crescimento")
	plots = state.get("plots")
	plots[4]["ready_at"] = now - 1.0
	var before: int = state.get("coins")
	_check(not (state.call("harvest", 4) as Dictionary).is_empty(), "Plantação offline pronta deve render colheita")
	_check(state.get("coins") == before + 3, "Colheita deve conceder moedas")
	_check((state.call("harvest", 4) as Dictionary).is_empty() and state.get("coins") == before + 3, "Colheita repetida não pode duplicar moedas")
	# Regar: acelera uma vez por plantio, por timestamps.
	_check(state.call("water_error", 0) == "Canteiro vazio", "Não rega canteiro vazio")
	state.call("plant", 0, "carrot")
	_check(state.call("water_error", 0) == "", "Planta crescendo pode ser regada")
	var left_before: float = float(state.call("plot", 0).ready_at) - float(state.call("now"))
	var water_xp: int = state.get("xp")
	_check(state.call("water", 0) == "", "Regar funciona")
	var left_after: float = float(state.call("plot", 0).ready_at) - float(state.call("now"))
	_check(absf(left_after - left_before * 0.7) < 1.0, "Rega tira 30% do tempo que falta")
	_check(state.call("water", 0) == "Já foi regado" and state.get("xp") == water_xp + 1, "Só uma rega por plantio (1 XP)")
	_check(state.get("progress").stat("water") == 1, "Rega conta no contador")
	var kept: Dictionary = (state.call("to_dict") as Dictionary).duplicate(true)
	state.call("from_dict", kept)
	_check(state.call("water_error", 0) == "Já foi regado", "Save preserva a rega")
	state.get("plots")[0]["ready_at"] = float(state.call("now")) - 1.0
	_check(state.call("water_error", 0) == "Já está pronto", "Planta pronta não precisa de rega")
	state.call("harvest", 0)
	state.call("plant", 0, "carrot")
	_check(state.call("water_error", 0) == "", "Novo plantio pode ser regado de novo")
	state.set("coins", 10000)
	for i in range(5, 9):
		_check(state.call("buy_plot", i) == "", "Todas as expansões devem ser acessíveis")
	_check(state.call("buy_plot", 9) != "", "Não deve ultrapassar o total de terrenos")
	if "--screenshots" in OS.get_cmdline_user_args():
		await _screenshots(state)
	print("FARM TEST: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(0 if _failures == 0 else 1)


func _screenshots(state: Node) -> void:
	state.call("reset")
	state.get("progress").owned["farm"] = true
	state.get("progress").skills["agriculture"] = 500
	state.get("progress").seen["intro"] = true
	state.get("progress").claimed_quests["lais_bag"] = true
	state.get("progress").claimed_quests["lais_bed"] = true
	state.get("progress").claimed_quests["bloblo_meet"] = true
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.call("_on_world_requested", "farm", "")
	state.call("plant", 0, "carrot")
	state.call("plant", 1, "potato")
	state.call("plant", 2, "pumpkin")
	var plots: Array = state.get("plots")
	var now: float = state.call("now")
	plots[0]["planted_at"] = now - 30
	plots[0]["ready_at"] = now + 30
	plots[1]["planted_at"] = now - 240
	plots[1]["ready_at"] = now + 60
	plots[2]["ready_at"] = now - 1
	# Antes da escritura: só o próximo canteiro fechado mostra a etiqueta "Vovó".
	state.get("progress").owned.erase("farm")
	state.get("progress").claimed_quests["lais_bag"] = true
	state.get("progress").claimed_quests["lais_bed"] = true
	state.get("progress").claimed_quests["bloblo_meet"] = true
	await create_timer(0.5).timeout
	_shot("farm_progress_vovo")
	state.get("progress").owned["farm"] = true
	await create_timer(0.5).timeout
	_shot("farm_progress")
	var farm: Node = main.find_child("World_farm", true, false)
	farm.call("_zoom_at", Vector2(165, 190), 3.0)
	await create_timer(0.3).timeout
	_shot("farm_progress_zoom")
	farm.call("_on_plot_tapped", 4)
	await create_timer(0.4).timeout
	_shot("farm_purchase")
	root.get_node("Events").emit_signal("sheet_close_requested")
	state.call("water", 0)  # já regado: tocar abre o progresso
	farm.call("_on_plot_tapped", 0)
	await create_timer(0.4).timeout
	_shot("farm_growth_sheet")
	root.get_node("Events").emit_signal("sheet_close_requested")
	main.find_child("WorldsScreen").call("enter", "farm", "plots")
	await create_timer(0.4).timeout
	_shot("farm_summary")


func _shot(file_name: String) -> void:
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + file_name + ".png")
