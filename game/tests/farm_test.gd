extends SceneTree
## Teste de progressão/migração. Desliga o SaveManager antes de alterar o estado.
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
	var old_save := {"save_version": 2, "state": {"coins": 77, "plots": []}}
	for i in 6:
		old_save["state"]["plots"].append({"crop": "carrot" if i == 5 else "", "ready_at": 1.0})
	var migrated: Dictionary = saver.call("_migrate", old_save)
	root.remove_child(saver)
	saver.free()
	state.call("from_dict", migrated["state"])
	_check(state.get("unlocked_plots") == 6, "Migração deve preservar seis terrenos")
	_check(state.call("plot_status", 5) == "ready", "Migração deve preservar a plantação")
	_check(state.get("coins") == 77, "Migração deve preservar moedas")
	state.call("reset")
	state.get("progress").owned["farm"] = true
	state.set("coins", 50)
	_check(state.get("unlocked_plots") == 3, "Jogo novo começa com três terrenos")
	_check(state.call("plant", 3, "carrot") != "", "Não pode plantar em terreno bloqueado")
	_check(state.call("buy_plot", 4) != "", "Não pode pular a ordem de compra")
	_check(state.call("buy_plot", -1) != "", "Índice inválido deve ser recusado")
	_check(state.call("buy_plot", 3) == "", "Primeira expansão deve funcionar")
	_check(state.get("coins") == 30, "Compra deve descontar uma única vez")
	_check(state.call("buy_plot", 3) != "" and state.get("coins") == 30, "Compra repetida não deve cobrar")
	_check(state.call("buy_plot", 4) != "" and state.get("unlocked_plots") == 4, "Saldo insuficiente não pode liberar terreno")
	_check(state.call("plant", 3, "carrot") == "", "Terreno comprado deve aceitar plantação")
	_check((state.call("harvest", 3) as Dictionary).is_empty(), "Não pode colher antes da hora")
	var plots: Array = state.get("plots")
	var now: float = state.call("now")
	plots[3]["planted_at"] = now - 30.0
	plots[3]["ready_at"] = now + 30.0
	_check(absf(float(state.call("plot_progress", 3)) - 0.5) < 0.02, "Progresso deve refletir o tempo decorrido")
	var saved: Dictionary = (state.call("to_dict") as Dictionary).duplicate(true)
	state.call("from_dict", saved)
	_check(state.get("unlocked_plots") == 4 and absf(float(state.call("plot_progress", 3)) - 0.5) < 0.02, "Save deve preservar expansão e crescimento")
	plots = state.get("plots")
	plots[3]["ready_at"] = now - 1.0
	var before: int = state.get("coins")
	_check(not (state.call("harvest", 3) as Dictionary).is_empty(), "Plantação offline pronta deve render colheita")
	_check(state.get("coins") == before + 3, "Colheita deve conceder moedas")
	_check((state.call("harvest", 3) as Dictionary).is_empty() and state.get("coins") == before + 3, "Colheita repetida não pode duplicar moedas")
	state.set("coins", 10000)
	for i in range(4, 9):
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
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.call("show_screen", &"farm")
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
	await create_timer(0.5).timeout
	_shot("farm_progress")
	var farm: Node = main.find_child("Farm")
	farm.call("_zoom_at", Vector2(180, 330), 1.5)
	var content: Control = farm.get_node("Content")
	content.position = farm.get("size") / 2.0 - Vector2(275, 245) * 1.5
	farm.call("_clamp_content")
	await create_timer(0.3).timeout
	_shot("farm_progress_zoom")
	farm.call("_on_plot_tapped", 3)
	await create_timer(0.4).timeout
	_shot("farm_purchase")
	root.get_node("Events").emit_signal("sheet_close_requested")
	farm.call("_on_plot_tapped", 0)
	await create_timer(0.4).timeout
	_shot("farm_growth_sheet")
	root.get_node("Events").emit_signal("sheet_close_requested")
	var farm_button: Button = farm.get("_farm_button")
	farm_button.pressed.emit()
	await create_timer(0.4).timeout
	_shot("farm_summary")


func _shot(file_name: String) -> void:
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + file_name + ".png")
