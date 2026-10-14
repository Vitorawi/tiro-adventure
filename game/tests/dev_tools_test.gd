extends SceneTree
## Testa as ferramentas da versão dev (GameState.dev_*) e o canal da build.
## Rodar nos dois modos:
##   godot --headless --path game -s res://tests/dev_tools_test.gd            (dev: ferramentas funcionam)
##   godot --headless --path game -s res://tests/dev_tools_test.gd -- --prod  (prod: não fazem nada)
## Não grava o save pessoal: remove SaveManager antes de qualquer mutação.
var _failures: int = 0
var state: Node
var database: Node
## Carregado em tempo de execução: o script de teste compila antes dos autoloads existirem.
var build_info: Script


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)


func _run() -> void:
	state = root.get_node("GameState")
	database = root.get_node("Database")
	build_info = load("res://scripts/util/build_info.gd")
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	if build_info.call("is_dev"):
		_check(build_info.call("save_path") == "user://save_dev.json", "Versão dev deve usar save separado")
		_dev_mode()
		if "--screenshots" in OS.get_cmdline_user_args():
			await _screenshots()
	else:
		_check(build_info.call("save_path") == "user://save.json", "Versão publicada usa o save normal")
		_prod_mode()
	print("DEV TOOLS TEST (%s): " % build_info.call("channel"), "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(0 if _failures == 0 else 1)


func _progress() -> Variant:
	return state.get("progress")


func _dev_mode() -> void:
	state.call("reset")
	state.call("dev_complete_main_step")
	_check(_progress().claimed_quests.has("welcome") and _progress().current_main_quest() == "lais_feed", "Concluir passo DEV avança apenas um passo")
	state.call("reset")
	state.call("dev_complete_quest", "main_2_order")
	_check(_progress().current_main_quest() == "lais_forest", "Concluir main respeita capítulos e ordem")
	_check(_progress().claimed_quests.has("bloblo_stew"), "Concluir main também conclui o cruzamento com a vovó")
	state.call("reset")
	state.call("dev_add_coins", 1000)
	_check(state.get("coins") == int(database.get("start").coins) + 1000, "Deve somar moedas")
	state.call("dev_add_items", 5, "material")
	_check(state.get("inventory").count("plank") == 5 and state.get("inventory").count("carrot") == 0, "Deve somar só a categoria pedida")

	state.call("dev_jump_to_chapter", 4)
	for id: String in ["stove", "fridge"]:
		_check(state.call("has_upgrade", id), "Pular capítulo deve liberar " + id)
	_check(not state.call("has_upgrade", "workbench"), "Pular capítulo não libera o alvo do próprio capítulo")
	_check(_progress().claimed_quests.has("first_sale") and _progress().claimed_quests.has("welcome"), "Requisitos de missão (e anteriores) devem ser concluídos")
	_check(state.call("accessible_plots") == 4, "Vovó empresta quatro canteiros")
	_check(state.call("current_chapter").target == "workbench", "Capítulo atual deve ser o 5")

	state.call("dev_grant_upgrade", "greenhouse")
	_check(state.call("has_upgrade", "greenhouse"), "Deve liberar a estufa")
	_check(state.call("upgrade_error", "greenhouse") == "Já adquirido", "Melhoria liberada conta como comprada")

	_check(state.call("plant", 0, "carrot") == "", "Deve plantar")
	state.call("dev_finish_timers")
	_check(state.call("plot_status", 0) == "ready", "Terminar timers deixa a plantação pronta")
	_check(is_equal_approx(float(state.call("plot_progress", 0)), 1.0), "Progresso deve ficar completo")
	state.call("harvest", 0)

	var hunger_before: float = state.get("dog").get_need("hunger", state.call("now"))
	_check(state.call("plant", 1, "carrot") == "", "Deve plantar de novo")
	state.call("dev_advance_time", 3600.0)
	_check(state.call("plot_status", 1) == "ready", "Avançar 1 h faz a cenoura (1 min) amadurecer")
	var hunger_after: float = state.get("dog").get_need("hunger", state.call("now"))
	_check(hunger_after < hunger_before - 5.0, "Avançar o tempo deve baixar a fome")
	state.call("dev_add_coins", 40)
	state.call("buy_upgrade", "forest_open")
	_check(state.call("start_activity", "lane") == "", "Deve começar rota no Bosque desbloqueado")
	state.call("dev_advance_time", 120.0)
	_check(state.call("collect_activity") == "", "Rota avança junto com o tempo")

	state.call("dev_fill_needs")
	_check(state.get("dog").get_need("hunger", state.call("now")) >= 99.0, "Necessidades devem encher")

	state.call("dev_unlock_everything")
	for id: String in database.get("progression").upgrades:
		_check(state.call("has_upgrade", id), "Liberar tudo deve incluir " + id)
	_check(_progress().claimed_quests.size() == database.get("quests").size(), "Liberar tudo conclui as missões")
	_check(_progress().collection.size() == database.get("collections").size(), "Liberar tudo entrega a coleção")
	_check(state.get("unlocked_plots") == int(database.get("farm").plots), "Liberar tudo compra os terrenos")
	_check(_progress().skill_info("cooking").max, "Liberar tudo leva atributos ao máximo")

	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	_check(state.call("has_upgrade", "atelier") and _progress().skill_info("adventure").max, "Estado dev deve sobreviver ao save")


func _prod_mode() -> void:
	state.call("reset")
	var coins: int = state.get("coins")
	var wishes_before: Dictionary = state.get("wishes").to_dict()
	state.call("dev_add_affection", 100)
	state.call("dev_refresh_wishes")
	_check(state.get("dog").affection == 0 and state.get("wishes").to_dict() == wishes_before, "Prod não pode alterar vínculo nem desejos via DEV")
	state.call("dev_add_coins", 1000)
	state.call("dev_unlock_everything")
	state.call("dev_complete_main_step")
	state.call("dev_complete_quest", "main_2_order")
	state.call("dev_jump_to_chapter", 5)
	_check(state.get("coins") == coins, "Versão publicada não pode ganhar moedas pelo dev")
	_check(not state.call("has_upgrade", "stove"), "Versão publicada não pode liberar melhorias pelo dev")
	_check(_progress().claimed_quests.is_empty(), "Prod não pode concluir história via DEV")


## Capturas do painel DEV (rodar sem --headless e com "-- --screenshots").
## A aba "Save" fica de fora: o teste remove o SaveManager para não tocar no save real.
func _screenshots() -> void:
	state.call("reset")
	state.call("dev_add_coins", 16000)  # barra superior com selo DEV + 5 dígitos
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.3).timeout
	main.find_child("DevButton").emit_signal("pressed")
	var panel_script: Script = load("res://scripts/ui/dev_panel.gd")
	for page: String in ["resources", "progress", "time"]:
		panel_script.set("_page", page)
		state.get_node("/root/Events").emit_signal("state_changed")
		await create_timer(0.4).timeout
		_shot("dev_panel_" + page)


func _shot(file_name: String) -> void:
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + file_name + ".png")
