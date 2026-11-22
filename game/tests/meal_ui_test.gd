extends SceneTree
## Telas do relógio de refeições (primeira semana, E01c): reloginho, balão, folha Hoje, Deixar pronto.
##   godot --headless --path game -s res://tests/meal_ui_test.gd
var _failures: int = 0
var state: Node
var main: Node


func _initialize() -> void:
	_run.call_deferred()
	create_timer(60).timeout.connect(func() -> void: quit(1))


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)


func _at(day: int, hour: int) -> void:
	state.call("dev_week_goto", day)
	state.call("dev_week_hour", hour)
	state.call("update_week")


func _run() -> void:
	state = root.get_node("GameState")
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	if not load("res://scripts/util/build_info.gd").call("is_dev"):
		print("MEAL UI TEST: PASS (pulado fora da versão dev)")
		quit(0)
		return
	state.call("reset")
	state.get("progress").seen["intro"] = true
	load("res://scripts/ui/motion.gd").set("reduced", true)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.0).timeout
	var meal_ui: GDScript = load("res://scripts/ui/meal_ui.gd")
	_at(3, 9)
	await create_timer(0.3).timeout
	var clock := main.find_child("MealClock", true, false) as Button
	_check(clock != null, "Reloginho no HUD")
	_check(clock != null and clock.size.x >= 28.0, "Reloginho tem tamanho de toque")
	var bubble := main.find_child("MealBubble", true, false) as Button
	_check(bubble != null and not bubble.visible, "Sem janela aberta: sem balão")
	_at(3, 12)
	await create_timer(0.4).timeout
	_check(str(meal_ui.call("asking_period")) == "lunch", "12 h: o almoço está pedindo")
	_check(bubble.visible and bubble.text.contains("almoço"), "Balão 'Hora do almoço!'")
	_check(str(clock.get_meta("state")) == "asking", "Reloginho avisa")
	# Folha Hoje.
	var panel: Control = meal_ui.call("today_panel")
	root.add_child(panel)
	await create_timer(0.3).timeout
	var row := panel.find_child("Period_lunch", true, false)
	_check(row != null and str(row.get_meta("state")) == "open", "Hoje: almoço aberto")
	var dinner := panel.find_child("Period_dinner", true, false)
	_check(dinner != null and str(dinner.get_meta("state")) == "soon", "Hoje: jantar ainda vai abrir")
	_check(panel.find_child("OptionCard", true, false) != null, "Hoje: escolha do horário")
	_check(panel.find_child("NotebookTab_early", true, false) != null, "Mais cedo / Normal / Mais tarde")
	(panel.find_child("NotebookTab_late", true, false) as Button).pressed.emit()
	_check(str(state.get("week").option) == "late", "Escolher Mais tarde grava a opção")
	state.call("set_meal_option", "normal")
	panel.queue_free()
	# Deixar pronto: fora da janela, a refeição vira escolha.
	_at(3, 9)
	state.get("inventory").call("add", "puppy_mash", 1)
	_check(str(state.call("meal_error", "puppy_mash")) != "" and str(state.call("store_meal_error", "puppy_mash")) == "", "Fora da hora dá para guardar")
	_check(not bool(state.call("meal_ask_allowed", "puppy_mash")), "Primeira refeição do dia: sem pergunta")
	_at(3, 12)
	_check(bool(state.call("feed", "puppy_mash")), "Almoço dado na hora")
	state.get("inventory").call("add", "puppy_mash", 1)
	var tray := main.find_child("PetCareTray", true, false)
	if tray == null:
		for node in main.find_children("*", "Control", true, false):
			if node.has_method("open_food_menu"):
				tray = node
				break
	_check(tray != null, "Bandeja de cuidados existe")
	tray.call("_act", "puppy_mash")
	await create_timer(0.4).timeout
	_check(main.find_child("StoreMeal", true, false) != null and main.find_child("GiveNow", true, false) != null, "Escolha Deixar pronto / Dar agora")
	(main.find_child("StoreMeal", true, false) as Button).pressed.emit()
	await create_timer(0.4).timeout
	_check(not state.call("stored_meal").is_empty(), "Refeição guardada")
	tray.call("refresh")
	var lid := main.find_child("StoredLid", true, false) as Control
	_check(lid != null and lid.visible, "Tampinha na tigela")
	var today: Control = meal_ui.call("today_panel")
	root.add_child(today)
	await create_timer(0.3).timeout
	_check(str(today.find_child("Period_dinner", true, false).get_meta("state")) == "stored", "Hoje mostra o jantar guardado")
	_check(today.find_child("CancelStored", true, false) != null, "Dá para pegar de volta")
	(today.find_child("CancelStored", true, false) as Button).pressed.emit()
	_check(state.call("stored_meal").is_empty(), "Pegar de volta devolve à Mochila")
	today.queue_free()
	# Fraquinho.
	state.get("week").weak = true
	var weak_panel: Control = meal_ui.call("today_panel")
	root.add_child(weak_panel)
	await create_timer(0.3).timeout
	_check(weak_panel.find_child("WeakNote", true, false) != null, "Aviso do fraquinho na folha Hoje")
	print("MEAL UI TEST: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(0 if _failures == 0 else 1)
