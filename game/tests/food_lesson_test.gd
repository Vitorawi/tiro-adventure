extends SceneTree
## F02 Parte B do "Novo fluxo": lição do painel de crescimento, aula da comida nas três faixas de hora (a primeira patinha
## é garantida), cartela de patinhas, Boa noite do dia 1 (combinado, horário, aviso, tigela), Bom dia do dia 2, lanche,
## fome, "?" e a página do Manual. Joga pelas ações reais; os cartões saem da casca.
##   godot --headless --path game -s res://tests/food_lesson_test.gd
var failures := 0
var state: Node
var db: Node
var main: Control
var quest_id := ""


func _initialize() -> void:
	_run.call_deferred()
	create_timer(150).timeout.connect(func() -> void:
		push_error("FOOD LESSON: tempo esgotado")
		quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FOOD LESSON: " + message)


func frames(count: int = 3) -> void:
	for i in count:
		await process_frame


func node(node_name: String) -> Control:
	return main.find_child(node_name, true, false) as Control


func shown(node_name: String) -> bool:
	var control := node(node_name)
	return control != null and control.is_visible_in_tree()


## Algum nÃ³ com esse nome estÃ¡ na tela (o painel Crescer tem um detalhe por passo, todos com os mesmos nomes).
func any_shown(node_name: String) -> bool:
	for found: Node in main.find_children(node_name, "Control", true, false):
		if (found as Control).is_visible_in_tree():
			return true
	return false


func at(day: int, hour: int) -> void:
	state.call("dev_week_goto", day)
	state.call("dev_week_hour", hour)
	state.call("update_week")


func guide() -> Node:
	return main.find_child("LessonGuide", true, false)


func guide_text() -> String:
	return str(guide().get("_text"))


## Espera `seconds` de relógio de teste.
func wait(seconds: float) -> void:
	await create_timer(seconds).timeout


## Save novo na caixinha, com o passo da aula preso ao passo atual (`welcome`), a mochila com uma papinha e o relógio na hora.
func fresh(hour: int, with_meal: bool, phase: String = "puppy") -> void:
	if main != null:
		main.queue_free()
		main = null
		await frames(2)
	state.call("reset")
	state.call("finish_week_arrival")
	state.call("finish_home_tour")
	state.week.arrival_extended = false
	state.week.tutorial["arrival"] = {"done": true}
	state.growth.phase = phase
	quest_id = str(state.progress.current_main_quest())
	db.week_story.food_lesson["quest"] = quest_id
	at(1, hour)
	if with_meal:
		state.inventory.add("puppy_mash", 1)
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await wait(0.8)


func dismiss_cards() -> void:
	for card_name: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var layer: Variant = main.get(card_name)
		if layer is CanvasItem and (layer as CanvasItem).visible:
			(layer as CanvasItem).hide()
		elif layer is CanvasLayer and (layer as CanvasLayer).visible:
			(layer as CanvasLayer).hide()


func _run() -> void:
	root.size = Vector2i(360, 780)
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	Motion.reduced = true
	var original_quest: String = str(db.week_story.food_lesson.quest)

	_data_and_rules()
	await fresh(12, false)
	check(not shown("MealClock"), "antes da aula o reloginho não aparece")
	check(guide() != null and str(guide().get("kind")) == "", "sem comida na Mochila a aula não começa")
	check(not state.food_lesson_startable(), "sem refeição na Mochila a aula não começa")
	state.inventory.add("puppy_mash", 1)
	check(state.food_lesson_startable(), "com o passo da aula e uma refeição, ela pode começar")

	for row: Array in [[12, "window", "É hora do"], [9, "day", "dia da chegada"], [23, "night", "antes de dormir"]]:
		await _lesson(int(row[0]), str(row[1]), str(row[2]))

	await _growth_lesson()
	await _evening_and_morning()
	await _hunger_snack_review()
	db.week_story.food_lesson["quest"] = original_quest
	check(db.quests.has(original_quest), "a aula está presa a um passo que existe (%s)" % original_quest)
	print("FOOD LESSON TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures else 0)


# --- Regras sem tela ---------------------------------------------------------------------------

func _data_and_rules() -> void:
	var story: Dictionary = db.week_story.food_lesson
	check(story.growth.size() == 3, "três falas da lição do painel")
	for key: String in ["window", "day", "night"]:
		check(str(story.today.get(key, "")) != "" and str(story.paw.get(key, "")) != "", "falas 2 e 4 da faixa " + key)
	state.call("reset")
	state.call("finish_week_arrival")
	state.call("finish_home_tour")
	state.week.arrival_extended = false
	for row: Array in [[12, "window"], [11, "window"], [20, "window"], [9, "day"], [16, "day"], [23, "night"], [2, "night"], [22, "night"], [6, "day"]]:
		at(1, int(row[0]))
		check(str(state.call("food_lesson_branch")) == row[1], "faixa às %dh = %s (deu %s)" % [row[0], row[1], state.call("food_lesson_branch")])
	# A primeira patinha é garantida a qualquer hora, uma vez só.
	for hour: int in [3, 9, 12, 16, 23]:
		state.call("reset")
		state.call("finish_week_arrival")
		state.call("finish_home_tour")
		at(1, hour)
		check(state.grant_lesson_paw("puppy_mash"), "patinha da aula às %dh" % hour)
		check(not state.grant_lesson_paw("puppy_mash"), "a patinha da aula não repete (%dh)" % hour)
		check(state.well_fed_days() == 1 and state.progress.stat("well_fed_day") == 1, "uma patinha contada (%dh)" % hour)
		var stamps: Array = state.paw_stamps()
		check(stamps.size() == 1 and stamps[0].kind == "paw" and stamps[0].arrival and stamps[0].item == "puppy_mash", "carimbo do dia da chegada (%dh)" % hour)
	# Refeição na hora registra a patinha por baixo; a aula só completa.
	state.call("reset")
	state.call("finish_week_arrival")
	state.call("finish_home_tour")
	state.week.arrival_extended = false
	at(1, 9)
	state.inventory.add("puppy_mash", 1)
	check(state.feed("puppy_mash") and state.meal_info().paw, "o dia da chegada: uma papinha a qualquer hora já vale a patinha")
	check(not state.grant_lesson_paw("puppy_mash") and state.well_fed_days() == 1, "a aula não duplica a patinha do dia da chegada")
	# Cartela: dia fraco vira carimbo tracejado vazio, sem consumir o espaço da patinha.
	state.week.days["2"] = {"weak": true}
	var stamps2: Array = state.paw_stamps()
	check(stamps2.size() == 2 and stamps2[1].kind == "weak", "dia fraco é um carimbo vazio")
	state.week.days.erase("2")
	# Próximo almoço/jantar.
	state.call("reset")
	state.call("finish_week_arrival")
	state.call("finish_home_tour")
	state.week.arrival_extended = false
	at(1, 9)
	var next: Dictionary = state.next_meal_in()
	check(next.period == "lunch" and not next.open and int(next.seconds) >= 2 * 3600 - 120 and int(next.seconds) <= 2 * 3600 + 60, "9h: o almoço em 2 h (%s)" % [next])
	at(1, 12)
	check(state.next_meal_in().open and state.next_meal_in().period == "lunch", "12h: a janela do almoço aberta")
	var paw_card: Script = load("res://scripts/ui/paw_card.gd")
	check(str(paw_card.call("next_text")) == "", "a linha do próximo almoço só existe depois da aula")
	state.week.food_lesson = true
	check(str(paw_card.call("next_text")) == "Hora do almoço!", "12h: Hora do almoço!")
	at(1, 16)
	check(str(paw_card.call("next_text")) == "Próximo jantar em 2 h", "16h: Próximo jantar em 2 h (%s)" % paw_card.call("next_text"))
	var deal: Dictionary = state.first_deal_when()
	check(deal.when == "amanhã" and int(deal.hour) == 11, "o primeiro combinado começa amanhã às 11h")
	# O passo real da aula: só vira a vez dele depois da chegada e com refeição na Mochila.
	state.call("reset")
	state.call("finish_week_arrival")
	state.call("finish_home_tour")
	state.week.arrival_extended = false
	var real_quest := str(db.week_story.food_lesson.quest)
	check(not state.food_lesson_startable(), "no começo (caixinha) a aula não começa")
	var guard := 0
	while str(state.progress.current_main_quest()) != real_quest and str(state.progress.current_main_quest()) != "" and guard < 80:
		state.progress.claimed_quests[str(state.progress.current_main_quest())] = true
		guard += 1
	state.inventory.add("puppy_mash", 1)
	check(str(state.progress.current_main_quest()) == real_quest and state.food_lesson_startable(), "no passo %s e com a papinha, a aula pode começar" % real_quest)
	state.progress.claimed_quests[real_quest] = true
	check(not state.food_lesson_startable() and state.food_lesson_done(), "pegar o passo encerra a aula (saves que já passaram dele)")
	# Tiro não dorme sozinho com o passo da comida ativo (consulta da Parte A).
	state.call("reset")
	state.call("finish_week_arrival")
	state.call("finish_home_tour")
	state.week.arrival_extended = false
	while str(state.progress.current_main_quest()) != real_quest and str(state.progress.current_main_quest()) != "" and guard < 160:
		state.progress.claimed_quests[str(state.progress.current_main_quest())] = true
		guard += 1
	check(state.food_step_active() and not state.auto_sleep_allowed(), "o passo da comida está ativo: não dorme sozinho")


# --- A aula, toque a toque --------------------------------------------------------------------

func _lesson(hour: int, branch: String, fragment: String) -> void:
	await fresh(hour, true)
	var label := "(%dh, %s) " % [hour, branch]
	check(guide() != null and str(guide().get("kind")) == "food" and int(guide().get("beat")) == 1, label + "a aula começa no toque 1")
	check(state.food_lesson_running() and shown("MealClock"), label + "o reloginho aparece na aula, pulsando no toque 1")
	check(guide().visible and node("TutorialVeil").visible, label + "véu e mão na tela")
	check(guide_text().contains("reloginho"), label + "fala 1: " + guide_text())
	check(state.food_lesson_data().get("branch", "") == branch, label + "a faixa da hora fica salva")
	check(not state.food_lesson_done() and state.progress.stat("feed") == 0, label + "nada de patinha antes de dar a papinha")
	# Toque 2: a folha Hoje abre com os dois espaços.
	(node("LessonNext") as Button).pressed.emit()
	await wait(0.6)
	check(int(guide().get("beat")) == 2 and shown("TodayPanel") and shown("TodayCard"), label + "toque 2: a folha Hoje abre")
	check(shown("Period_lunch") and shown("Period_dinner"), label + "os dois espaços do dia")
	check(guide_text().contains(fragment), label + "fala 2 pela hora: " + guide_text())
	check(shown("PawCardBox") and shown("PawSlot_0"), label + "a cartela de patinhas na folha Hoje")
	# Toque 3: arrastar a papinha (a aula abre o cardápio).
	(node("LessonNext") as Button).pressed.emit()
	await wait(0.8)
	check(int(guide().get("beat")) == 3 and shown("Care_puppy_mash"), label + "toque 3: a papinha no cardápio")
	check(guide_text().contains("Arraste"), label + "fala 3: " + guide_text())
	check(not (node("LessonNext") as Button).visible, label + "no toque 3 só se arrasta")
	var hand := node("TutorialHand")
	check(hand != null and hand.visible, label + "a mao do arrasto aparece (visivel=%s pos=%s)" % [hand.visible if hand else false, hand.global_position if hand else Vector2.ZERO])
	check(not state.meal_info().paw, label + "ainda sem patinha")
	check(state.feed("puppy_mash"), label + "dar a papinha")
	await wait(0.4)
	check(int(guide().get("beat")) == 4, label + "toque 4 depois de comer")
	check(bool(state.meal_info().paw) and state.progress.stat("well_fed_day") == 1, label + "a primeira patinha é garantida a qualquer hora")
	check(guide_text().contains("patinha"), label + "fala 4: " + guide_text())
	if branch == "day":
		check(guide_text().contains("O próximo é o"), label + "a fala diz qual é a próxima refeição: " + guide_text())
	if branch == "night":
		check(guide_text().contains("dormir"), label + "à noite a fala manda dormir: " + guide_text())
	# Toque 5: painel Crescer na linha das patinhas.
	(node("LessonNext") as Button).pressed.emit()
	await wait(0.7)
	check(int(guide().get("beat")) == 5 and shown("GrowthPanel"), label + "toque 5: o painel Crescer abre")
	check(shown("GrowthReq_days") and str(node("GrowthPanel").get_meta("selected", "")) == "days", label + "na linha das patinhas")
	check(shown("PawCard") and node("PawSlot_0").get_meta("state") == "paw", label + "a cartela mostra o primeiro carimbo")
	check(shown("PawDone") and str(node("PawDone").get("text")) == "Dia da chegada!", label + "o primeiro carimbo é o Dia da chegada")
	check(any_shown("GrowthHelp"), label + "o ? da linha das patinhas")
	check(guide_text().contains("Seis patinhas"), label + "fala 5: " + guide_text())
	(node("LessonNext") as Button).pressed.emit()
	await wait(0.4)
	check(state.food_lesson_done() and state.week.food_lesson and str(guide().get("kind")) == "", label + "a aula termina")
	check(shown("MealClock"), label + "depois da aula o reloginho fica")
	if branch == "night":
		await wait(2.8)
		check(state.dog.sleeping, label + "à noite ele boceja e vai dormir")
	else:
		check(not state.dog.sleeping, label + "de dia ele continua acordado")


# --- Lição do painel de crescimento -------------------------------------------------------------

func _growth_lesson() -> void:
	await fresh(10, false, "newborn")
	db.week_story.food_lesson["quest"] = "lais_photo"
	for id: String in ["welcome", "lais_feed", "lais_bath", "lais_play", "lais_bed", "lais_photo", "lais_farm", "lais_meet_bloblo", "lais_first_crops", "place_stove", "first_kitchen", "first_meal"]:
		state.progress.claimed_quests[id] = true
	check(str(state.progress.current_main_quest()) == "lais_growth", "o passo da vez é lais_growth (%s)" % state.progress.current_main_quest())
	check(guide() != null and str(guide().get("kind")) == "", "nada antes de abrir o painel")
	# Tudo do Filhotinho feito (como no fim do capítulo 1): a lição mostra exemplos e a mão leva ao Crescer.
	for counter: String in ["feed", "bathe", "play", "together:puppy_mash"]:
		state.progress.stats[counter] = 1
	state.progress.owned["dog_bed"] = true
	for seen: String in ["missions", "home_tour", "home_claim", "food"]:
		state.week.tutorial[seen] = {"done": true}  # balões do começo já vistos
	state.mark_seen(state.new_unlocks())  # as novidades do passo anterior já apareceram no prêmio dele
	load("res://scripts/ui/growth_ui.gd").call("open")
	await wait(0.7)
	check(str(guide().get("kind")) == "growth" and int(guide().get("beat")) == 1, "abrir o painel começa a lição")
	check(guide_text().contains("precisa cumprir os passos"), "fala 1: " + guide_text())
	check(guide().visible and node("GrowthSteps") != null, "a mão aponta a grade de passos")
	(node("LessonNext") as Button).pressed.emit()
	await wait(0.2)
	check(int(guide().get("beat")) == 2 and guide_text().contains("caminha"), "fala 2: " + guide_text())
	check((guide().get("_target") as Rect2).is_equal_approx(node("GrowthReq_bed").get_global_rect()), "fala 2 aponta a caminha feita")
	# Fechar o painel faz a lição sumir sozinha; reabrir começa de novo.
	root.get_node("Events").sheet_close_requested.emit()
	await wait(0.8)
	check(str(guide().get("kind")) == "" and not guide().visible, "a lição some se o painel fechar")
	check(not state.week.tutorial.get("growth_lesson", {}).get("done", false), "fechar não conta como concluída")
	load("res://scripts/ui/growth_ui.gd").call("open")
	await wait(0.8)
	check(str(guide().get("kind")) == "growth" and int(guide().get("beat")) == 1, "reabrir recomeça a lição")
	(node("LessonNext") as Button).pressed.emit()
	await wait(0.2)
	(node("LessonNext") as Button).pressed.emit()
	await wait(0.2)
	check(int(guide().get("beat")) == 3 and guide_text().contains("papinha"), "fala 3: " + guide_text())
	check((guide().get("_target") as Rect2).is_equal_approx(node("GrowthReq_home_mash").get_global_rect()), "fala 3 aponta a papinha caseira")
	(node("LessonNext") as Button).pressed.emit()
	await wait(0.3)
	check(str(guide().get("kind")) == "" and state.week.tutorial.get("growth_lesson", {}).get("done", false), "a lição termina e não volta")
	check(state.progress.claimed_quests.has("lais_growth") and str(state.progress.current_main_quest()) == "growth_1_puppy", "a lição completa o passo e a missão vira Crescer")
	await wait(1.0)
	var hand := main.find_child("WeekTutorial", true, false)
	check(hand != null and hand.visible and str(hand.get("active")) == "home_grow" and shown("GrowButton"), "a mão leva ao Crescer! (%s)" % (str(hand.get("active")) if hand else "-"))
	# Fechar o painel sem crescer: a missão continua esperando o primeiro crescimento.
	root.get_node("Events").sheet_close_requested.emit()
	await wait(0.6)
	check(str(state.progress.current_main_quest()) == "growth_1_puppy" and state.growth.phase == "newborn", "sem crescer, a história espera")
	check(state.grow() == "" and state.progress.claimed_quests.has("growth_1_puppy"), "crescer completa a missão sozinho")
	root.get_node("Events").sheet_close_requested.emit()
	await wait(0.5)
	load("res://scripts/ui/growth_ui.gd").call("open")
	await wait(0.8)
	check(str(guide().get("kind")) == "", "concluída, não repete")
	db.week_story.food_lesson["quest"] = quest_id


# --- Boa noite do dia 1 e Bom dia do dia 2 -------------------------------------------------------

func _evening_and_morning() -> void:
	await fresh(15, true)
	db.week_story.food_lesson["quest"] = "lais_photo"
	state.week.food_lesson = true
	state.progress.claimed_quests["lais_photo"] = true
	state.grant_lesson_paw("puppy_mash")
	state.inventory.add("puppy_mash", 2)
	check(not state.week_meal_reminder_offered(), "o aviso de hora de comer ainda não foi oferecido")
	at(1, 23)
	var night: Array = state.week_card_candidates().filter(func(c: Dictionary) -> bool: return c.kind == "night")
	check(night.size() == 1, "Boa noite do dia 1 disponível depois do jantar")
	var report: Dictionary = state.take_week_card(night[0])
	check(report.arrival and report.first_night and report.deal.when == "amanhã" and int(report.deal.hour) == 11, "combinado: começa amanhã, no almoço das 11h")
	check(report.reminder_offer and not report.store_offer, "oferece o aviso; a tigela fica para depois do dia 1")
	check(state.week_meal_reminder_offered() and not state.week_meal_reminder_enabled(), "oferta feita: aviso desligado até aceitar")
	var report_again: Dictionary = state.take_week_card({"kind": "night", "day": 1, "civil": int(night[0].civil)})
	check(report_again.is_empty(), "o cartão não repete")
	main.get("_celebration").call("show_week_card", report)
	await wait(0.4)
	check(shown("DealNeed") and str(node("DealNeed").get("text")).begins_with("Amanhã começa o combinado: almoço e jantar na hora valem uma patinha"), "Boa noite: o que vale a patinha amanhã")
	check(not shown("DealStart"), "Boa noite: uma frase só para o combinado")
	check(str(node("DealHours").get("text")).contains("Almoço 11h–15h"), "Boa noite: os dois horários (%s)" % node("DealHours").get("text"))
	check(shown("DealOptions") and shown("NotebookTab_early") and shown("NotebookTab_late"), "Boa noite: Mais cedo · Normal · Mais tarde")
	check(shown("MealReminderOffer") and not shown("StoreOffer") and shown("WeekNightPaw"), "Boa noite do dia 1: aviso e patinha, sem a tigela")
	(node("NotebookTab_early") as Button).pressed.emit()
	await frames(2)
	check(str(state.week.option) == "early" and str(node("DealHours").get("text")).contains("Almoço 10h–14h"), "Mais cedo muda os horários na hora (%s)" % node("DealHours").get("text"))
	var early_box := (node("NotebookTab_early") as Button).get_theme_stylebox("normal") as StyleBoxFlat
	var normal_box := (node("NotebookTab_normal") as Button).get_theme_stylebox("normal") as StyleBoxFlat
	check(early_box.bg_color != normal_box.bg_color and early_box.bg_color.v > normal_box.bg_color.v, "Mais cedo fica aceso no seletor")
	(node("NotebookTab_normal") as Button).pressed.emit()
	await frames(2)
	check(str(state.week.option) == "normal", "Normal volta o horário")
	check(shown("ReminderYes") and shown("ReminderNo") and (node("ReminderYes") as Control).size.y >= 44.0, "Boa noite: Sim e Agora não (alvo 44)")
	(node("ReminderYes") as Button).pressed.emit()
	await frames(2)
	check(state.week_meal_reminder_enabled() and shown("ReminderAnswer") and not shown("ReminderYes"), "Sim liga o aviso e troca os botões pela resposta")
	state.set_week_meal_reminder(false)
	state.set_week_meal_reminder(false)
	main.get("_celebration").hide()
	await frames(2)
	# Bom dia do dia 2 antes do almoço: combinado de verdade e a dica da tampinha.
	at(2, 9)
	var morning: Array = state.week_card_candidates().filter(func(c: Dictionary) -> bool: return c.kind == "morning")
	check(morning.size() == 1, "Bom dia do dia 2")
	# Guardar a comida no almoço de hoje; ela é comida ao abrir a janela e deixa um recado.
	var morning_report: Dictionary = state.take_week_card(morning[0])
	check(morning_report.first_day and morning_report.before_lunch, "primeiro dia de verdade, antes do almoço")
	main.get("_celebration").call("show_week_card", morning_report)
	await wait(0.4)
	var copy: Dictionary = db.week_routine.text
	check(main.find_child("WeekMorning", true, false) != null, "cartão do Bom dia")
	var has_first := false
	for label: Node in main.find_children("*", "Label", true, false):
		if str((label as Label).text) == str(copy.first_day):
			has_first = true
	check(has_first, "Bom dia: Hoje é o primeiro dia de verdade")
	check(shown("StoreTip"), "Bom dia: a dica da tampinha leva a Deixar pronto")
	main.get("_celebration").hide()
	await frames(2)
	load("res://scripts/ui/meal_ui.gd").call("open_today")
	await wait(0.5)
	check(shown("StoreNow_puppy_mash") and shown("PawCardBox"), "folha Hoje: botão direto para guardar a papinha")
	var before: int = state.stored_meals().size()
	(node("StoreNow_puppy_mash") as Button).pressed.emit()
	await frames(3)
	check(state.stored_meals().size() == before + 1 and state.stored_meals()[0].period == "lunch", "a papinha foi para o almoço de hoje")
	check(shown("StoredCard"), "a tigela mostra o que ficou guardado")
	root.get_node("Events").sheet_close_requested.emit()
	await frames(2)
	at(2, 12)
	check(state.served_notes().size() == 1 and state.meals_on_time(2) == 1, "o Tiro comeu sozinho na hora")
	var served: Dictionary = state.served_notes()[0]
	check(served.period == "lunch" and int(served.hour) == 11, "recado: comeu às 11h e poucos")
	state.progress.claimed_quests["lais_photo"] = true
	var lines := PackedStringArray()
	for note: Dictionary in state.served_notes():
		lines.append(str(copy.served) % ["almoço", int(note.hour), int(note.minute)])
	check(lines.size() == 1 and lines[0].begins_with("Ele comeu o almoço às 11h"), "texto do recado: " + lines[0])
	state.mark_served_notes_seen()
	check(state.served_notes().is_empty(), "o recado é mostrado uma vez")
	db.week_story.food_lesson["quest"] = quest_id


# --- Fome, lanche, "?" e Manual -----------------------------------------------------------------

func _hunger_snack_review() -> void:
	await fresh(9, false)
	db.week_story.food_lesson["quest"] = "lais_photo"
	state.week.food_lesson = true
	at(2, 9)
	main.call("show_screen", &"pet")
	await wait(0.5)
	check(not shown("HungerBowl"), "fora da janela ele fica satisfeito: sem tigela brilhando")
	at(2, 12)
	await wait(0.5)
	check(shown("HungerBowl"), "com a janela aberta e o período sem ✓, a tigela brilha")
	check(str(root.get_node("Database").call("item_name", "puppy_mash")) != "" and shown("MealBubble"), "o balão Hora do almoço continua")
	state.inventory.add("puppy_mash", 1)
	check(state.feed("puppy_mash"), "almoço na hora")
	await wait(0.5)
	check(not shown("HungerBowl"), "período feito: a tigela para de brilhar")
	var meal_ui: Script = load("res://scripts/ui/meal_ui.gd")
	check(str(meal_ui.call("fed_text")) == "Já almocei!", "tocar nele diz Já almocei!")
	at(2, 19)
	state.inventory.add("puppy_mash", 1)
	state.feed("puppy_mash")
	check(str(meal_ui.call("fed_text")) == "Já jantei!", "no jantar: Já jantei!")
	# Lanche: balão curto na primeira vez, e só nela.
	var toasts: Array[String] = []
	var catcher := func(text: String) -> void: toasts.append(text)
	root.get_node("Events").toast_requested.connect(catcher)
	var snack := ""
	for id: String in ["oat_biscuit", "apple_biscuit", "carrot_snack"]:
		if db.items.has(id) and db.items[id].has("feed"):
			snack = id
			break
	check(snack != "", "há um lanche no jogo para provar")
	state.inventory.add(snack, 2)
	check(state.feed(snack), "dar o primeiro petisco")
	check(toasts.any(func(t: String) -> bool: return t.begins_with("Petisco é lanche")), "balão: lanche não é refeição (%s)" % [toasts])
	toasts.clear()
	check(state.feed(snack), "dar o segundo petisco")
	check(not toasts.any(func(t: String) -> bool: return t.begins_with("Petisco é lanche")), "só na primeira vez")
	root.get_node("Events").toast_requested.disconnect(catcher)
	# "?" da folha Hoje e da linha das patinhas, e a página do Manual.
	load("res://scripts/ui/meal_ui.gd").call("open_today")
	await wait(0.5)
	check(shown("MealHelp"), "a folha Hoje tem o ?")
	(node("MealHelp") as Button).pressed.emit()
	await wait(0.5)
	check(shown("MealReview") and shown("Window_lunch") and shown("Window_dinner") and shown("MealFlow"), "o ? abre a aula em uma tela: dia de 24 h, ✓ ✓ → patinha → crescer")
	root.get_node("Events").sheet_close_requested.emit()
	await frames(2)
	load("res://scripts/ui/growth_ui.gd").call("open", "days")
	await wait(0.6)
	check(shown("PawCard") and shown("PawNext") and any_shown("GrowthHelp"), "linha das patinhas: cartela, próximo almoço e o ?")
	check(shown("PawSlot_5"), "seis espaços na cartela")
	root.get_node("Events").sheet_close_requested.emit()
	await frames(2)
	var manual: Control = load("res://scripts/ui/week_tutorial.gd").call("manual_body", {"tutorial": "food"}, func() -> void: pass)
	root.add_child(manual)
	check(manual.find_child("TutorialReview_food", true, false) != null and manual.find_child("MealReview", true, false) != null, "Manual: página Comida e crescimento com o desenho")
	manual.queue_free()
	var lessons: Array = db.week_tutorials
	var ids: Array = lessons.map(func(row: Dictionary) -> String: return str(row.id))
	check(ids.count("food") == 1 and bool(lessons[ids.find("clock")].get("native", false)) and bool(lessons[ids.find("snack")].get("native", false)),
		"lições antigas do relógio e do lanche presas à aula")
	db.week_story.food_lesson["quest"] = quest_id
