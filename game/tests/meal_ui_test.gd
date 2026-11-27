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
	var clock := main.find_child("MealDay", true, false) as Button
	_check(clock != null, "Potinho do dia no HUD")
	_check(clock != null and clock.size.x >= 44.0 and clock.size.y >= 44.0, "Potinho tem alvo de toque >= 44")
	_check(clock != null and clock.find_child("Disc_sun", true, false) != null and clock.find_child("Disc_moon", true, false) != null, "Potinho tem os discos do sol e da lua")
	_check(main.find_child("MealClock", true, false) == null, "O reloginho antigo saiu")
	var bubble := main.find_child("MealBubble", true, false) as Button
	_at(3, 12)
	await create_timer(0.4).timeout
	_check(str(meal_ui.call("asking_period")) == "sun", "12 h: a comidinha do dia está pedindo")
	_check(bubble != null and bubble.visible and bubble.text.to_lower().contains("comidinha do dia"), "Balão Hora da comidinha do dia!")
	_check(str(clock.get_meta("state")) == "asking", "Potinho avisa")
	_check(str(clock.find_child("Disc_sun", true, false).get_meta("state")) == "open" and str(clock.find_child("Disc_moon", true, false).get_meta("state")) == "soon", "12h: sol com fome, lua mais tarde")
	# Folha Hoje.
	var panel: Control = meal_ui.call("today_panel")
	root.add_child(panel)
	await create_timer(0.3).timeout
	var row := panel.find_child("Slot_sun", true, false)
	_check(row != null and str(row.get_meta("state")) == "open", "Hoje: de dia aberto")
	var night := panel.find_child("Slot_moon", true, false)
	_check(night != null and str(night.get_meta("state")) == "soon", "Hoje: a noite ainda vai começar")
	_check(panel.find_child("PawEquation", true, false) != null and panel.find_child("PawCard", true, false) != null, "Hoje: a conta sol + lua = patinha e a cartela")
	_check(panel.find_child("SlotState", true, false) != null and (panel.find_children("SlotState", "Label", true, false)[0] as Label).text == "Com fome!", "Hoje: o dia diz Com fome!")
	_check(panel.find_child("OptionCard", true, false) == null and panel.find_child("NotebookTab_early", true, false) == null, "Sem escolha de horário")
	_check(panel.find_child("WeakNote", true, false) == null and panel.find_child("MealReminder", true, false) == null, "Sem fraquinho nem configuração de aviso")
	panel.queue_free()
	# Deixar pronto: com fome a comida vai para ele; com ✓ na metade a refeição vira escolha.
	_at(3, 9)
	state.get("inventory").call("add", "puppy_mash", 1)
	_check(str(state.call("store_meal_error", "puppy_mash")) != "" and not bool(state.call("meal_ask_allowed", "puppy_mash")), "Com fome: sem pergunta, dá agora")
	_at(3, 12)
	_check(bool(state.call("feed", "puppy_mash")), "Comidinha do dia dada")
	_check(str(meal_ui.call("asking_period")) == "" and str(meal_ui.call("fed_text")) == "Barriga cheia!", "Já comeu: não pede e diz que a barriga está cheia")
	state.get("inventory").call("add", "puppy_mash", 1)
	_check(bool(state.call("meal_ask_allowed", "puppy_mash")), "Com ✓ na metade: aparece a pergunta")
	var tray := main.find_child("PetCareTray", true, false)
	if tray == null:
		for node in main.find_children("*", "Control", true, false):
			if node.has_method("open_food_menu"):
				tray = node
				break
	_check(tray != null, "Bandeja de cuidados existe")
	tray.call("_act", "puppy_mash")
	await create_timer(0.4).timeout
	_check(main.find_child("StoreMeal", true, false) != null and main.find_child("GiveNow", true, false) != null, "Escolha Guardar / Dar assim mesmo")
	_check(main.find_child("StoreNote", true, false) == null and main.find_child("StoreItem", true, false) != null, "A pergunta é só o ícone e dois botões")
	_check(str(meal_ui.call("target_phrase", state.call("meal_next_target"))) == "a noite", "De dia a comida guardada vai para a noite")
	(main.find_child("StoreMeal", true, false) as Button).pressed.emit()
	await create_timer(0.4).timeout
	_check(not state.call("stored_meal").is_empty(), "Refeição guardada")
	tray.call("refresh")
	var lid := main.find_child("StoredLid", true, false) as Control
	_check(lid != null and lid.visible, "Tampinha na tigela")
	var today: Control = meal_ui.call("today_panel")
	root.add_child(today)
	await create_timer(0.3).timeout
	_check(str(today.find_child("Slot_moon", true, false).get_meta("state")) == "stored" and today.find_child("StoredLabel", true, false) != null, "Hoje mostra a comida guardada para a noite")
	_check((today.find_children("SlotState", "Label", true, false)[1] as Label).text == "Na tigela", "Hoje: a noite diz Na tigela")
	_check(clock.find_child("Disc_moon", true, false).find_child("Seal", true, false) != null, "Potinho: selo de reloginho na lua guardada")
	_check(today.find_child("CancelStored", true, false) != null, "Dá para pegar de volta")
	(today.find_child("CancelStored", true, false) as Button).pressed.emit()
	_check(state.call("stored_meal").is_empty(), "Pegar de volta devolve à Mochila")
	today.queue_free()
	# Guia de comida: refeições com selo e contorno verde quando a metade conta; petiscos depois da divisória.
	state.get("inventory").call("add", "apple_biscuit", 1)
	state.get("inventory").call("add", "fish_mash", 1)
	_at(4, 12)
	tray.call("refresh")
	await create_timer(0.3).timeout
	var meal_tile := main.find_child("Care_fish_mash", true, false) as Control
	_check(meal_tile != null and meal_tile.find_child("MealSeal", true, false) != null, "Guia: a refeição tem o selo sol/lua")
	_check(meal_tile != null and meal_tile.find_child("CountsRing", true, false) != null and meal_tile.find_child("CountsCheck", true, false) != null, "Guia: sem ✓ na metade a refeição ganha contorno verde e ✓")
	var snack_tile := main.find_child("Care_apple_biscuit", true, false) as Control
	_check(snack_tile != null and snack_tile.find_child("MealSeal", true, false) == null and snack_tile.find_child("CountsRing", true, false) == null, "Guia: petisco sem selo nem contorno")
	_check(main.find_child("SnackHeart", true, false) != null, "Guia: divisória com coração entre refeições e petiscos")
	_check(bool(state.call("feed", "fish_mash")), "Dá a refeição")
	tray.call("refresh")
	await create_timer(0.3).timeout
	var after := main.find_child("Care_puppy_mash", true, false) as Control
	_check(after != null and after.find_child("CountsRing", true, false) == null, "Guia: com ✓ na metade o contorno some")
	# Dia completo: só ao vivo e com o jogo aberto; a aula e o relógio fechado não mostram.
	_at(5, 12)
	state.call("feed", "puppy_mash")
	state.get("inventory").call("add", "puppy_mash", 1)
	_at(5, 17)
	main.set("_modal_queue", [] as Array[Callable])
	state.call("feed", "puppy_mash")
	_check(not meal_ui.call("live_paw", 5).is_empty() and not (meal_ui.call("live_paw", 5) as Dictionary).from_bowl, "A patinha de agora é ao vivo")
	_check((main.get("_modal_queue") as Array).is_empty(), "A patinha ao vivo não abre tela (só aviso)")
	var notice: Object = main.get("_notice")
	var texts: Array[String] = [str((notice.get("_current") as Dictionary).get("text", ""))]
	for waiting: Dictionary in notice.get("_queue"): texts.append(str(waiting.get("text", "")))
	_check("Dia completo! +1 patinha" not in texts, "A patinha ao vivo não vira pílula de texto (o aviso é a patinha voando ao potinho)")
	var pot := main.find_child("MealDay", true, false) as Control
	if pot != null and pot.is_visible_in_tree() and not Motion.reduced:
		_check(main.find_child("DayPawFly", true, false) != null, "A patinha ao vivo voa até o potinho do HUD")
	main.set("_modal_queue", [] as Array[Callable])
	# Patinha de um dia fechado (o jogo estava fechado): vazio.
	state.get("week").days["4"] = {"paw": true, "sun": {"on_time": true, "at": 1.0, "item": "puppy_mash"}, "moon": {"on_time": true, "at": 2.0, "item": "puppy_mash", "stored": true}}
	_check((meal_ui.call("live_paw", 4) as Dictionary).is_empty(), "Patinha do jogo fechado não é ao vivo (o Bom dia conta)")
	# Aviso do ✓ ao vivo com a outra metade pendente.
	_at(6, 12)
	state.get("inventory").call("add", "puppy_mash", 2)
	state.call("feed", "puppy_mash")
	_check(str(meal_ui.call("counted_notice", "sun")) == "Comidinha do dia ✓", "Aviso do ✓ de dia")
	_at(7, 17)
	state.call("feed", "puppy_mash")
	_check(str(meal_ui.call("counted_notice", "moon")) == "Comidinha da noite ✓", "Aviso do ✓ de noite")
	print("MEAL UI TEST: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(0 if _failures == 0 else 1)
