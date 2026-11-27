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
	state.week.tutorial["arrival"] = {"done": true}
	state.growth.phase = phase
	quest_id = str(state.progress.current_main_quest())
	db.week_story.food_lesson["quest"] = quest_id
	at(1 if hour >= 6 else 2, hour)  # madrugada (3h) é a lua do dia anterior do Tiro
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
	check(not shown("MealDay"), "antes da aula o potinho não aparece")
	check(guide() != null and str(guide().get("kind")) == "", "sem comida na Mochila a aula não começa")
	check(not state.food_lesson_startable(), "sem refeição na Mochila a aula não começa")
	state.inventory.add("puppy_mash", 1)
	check(state.food_lesson_startable(), "com o passo da aula e uma refeição, ela pode começar")

	for hour: int in [10, 22, 3]:
		await _lesson(hour)

	await _new_lessons()
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
	check(str(story.feed) != "" and str(story.paw) != "" and str(story.grow) != "" and not story.has("clock") and not story.has("today"), "três falas da aula (uma só, para qualquer hora)")
	check(not story.has("branch") and not state.has_method("food_lesson_branch"), "saíram as três versões por hora")
	state.call("reset")
	state.call("finish_week_arrival")
	state.call("finish_home_tour")
	for row: Array in [[12, "sun"], [6, "sun"], [15, "sun"], [16, "moon"], [23, "moon"], [2, "moon"], [5, "moon"]]:
		at(1, int(row[0]))
		check(str(state.call("meal_period_now")) == row[1], "metade às %dh = %s" % [row[0], row[1]])
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
	at(1, 9)
	state.inventory.add("puppy_mash", 1)
	check(state.feed("puppy_mash") and not state.meal_info().paw, "antes da aula a papinha não registra ✓")
	state.set_food_lesson_step(3)
	state.inventory.add("puppy_mash", 1)
	check(state.feed("puppy_mash") and state.meal_info().paw, "com a aula rodando: uma papinha já vale a patinha do dia da chegada")
	check(not state.grant_lesson_paw("puppy_mash") and state.well_fed_days() == 1, "a aula não duplica a patinha do dia da chegada")
	# Cartela: dia sem patinha vira carimbo tracejado vazio, sem consumir o espaço da patinha.
	state.week.days["2"] = {"missed": true}
	var stamps2: Array = state.paw_stamps()
	check(stamps2.size() == 2 and stamps2[1].kind == "missed", "dia sem patinha é um carimbo vazio")
	state.week.days.erase("2")
	# Próxima refeição: de dia sem ✓ pede a comidinha; com ✓ falta a da noite.
	state.call("reset")
	state.call("finish_week_arrival")
	state.call("finish_home_tour")
	at(1, 9)
	var next: Dictionary = state.next_meal_in()
	check(next.period == "sun" and next.open and int(next.seconds) == 0, "9h sem ✓: a comidinha do dia está aberta (%s)" % [next])
	state.dev_week_meal("sun")
	next = state.next_meal_in()
	check(next.period == "moon" and not next.open and int(next.seconds) >= 7 * 3600 - 120 and int(next.seconds) <= 7 * 3600 + 60, "9h com ✓: a noite em 7 h (%s)" % [next])
	var paw_card: Script = load("res://scripts/ui/paw_card.gd")
	check(str(paw_card.call("next_text")) == "", "a linha do próximo só existe depois da aula")
	state.week.food_lesson = true
	check(str(paw_card.call("next_text")) == "A da noite: 16h", "de dia com ✓: A da noite é a partir das 16h (%s)" % paw_card.call("next_text"))
	at(1, 16)
	check(str(paw_card.call("next_text")) == "Hora da comidinha da noite!", "16h sem ✓: Hora da comidinha da noite!")
	state.dev_week_meal("moon")
	check(str(paw_card.call("next_text")) == "Amanhã cedo", "noite com ✓: Amanhã cedo tem mais")
	var deal: Dictionary = state.first_deal_when()
	check(deal.when == "amanhã" and int(deal.hour) == 6, "o primeiro combinado começa amanhã às 6h")
	# O passo real da aula: só vira a vez dele depois da chegada e com refeição na Mochila.
	state.call("reset")
	state.call("finish_week_arrival")
	state.call("finish_home_tour")
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
	while str(state.progress.current_main_quest()) != real_quest and str(state.progress.current_main_quest()) != "" and guard < 160:
		state.progress.claimed_quests[str(state.progress.current_main_quest())] = true
		guard += 1
	check(state.food_step_active() and not state.auto_sleep_allowed(), "o passo da comida está ativo: não dorme sozinho")


# --- A aula, toque a toque --------------------------------------------------------------------

func _lesson(hour: int) -> void:
	await fresh(hour, true)
	var label := "(%dh) " % hour
	check(guide() != null and str(guide().get("kind")) == "food" and int(guide().get("beat")) == 1, label + "a aula começa no toque 1")
	check(state.food_lesson_running() and shown("MealDay"), label + "o potinho aparece na aula")
	check(guide().visible and node("TutorialVeil").visible, label + "véu e mão na tela")
	check(guide_text() == "Arraste a papinha até ele.", label + "fala 1: " + guide_text())
	check(not state.food_lesson_done() and state.progress.stat("feed") == 0, label + "nada de patinha antes de dar a papinha")
	check(state.dog.get_need("hunger", state.now()) <= 25.0, label + "o Tiro começa com fome (Barriga %d)" % int(state.dog.get_need("hunger", state.now())))
	var expected_half: String = "sun" if hour >= 6 and hour < 16 else "moon"
	check(str(state.meal_period_now()) == expected_half, label + "a metade é " + expected_half)
	var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var hud_bottom: float = 128.0
	check(guide().get("_target").position.y >= 0.0 and (guide().get("_target") as Rect2).has_area(), label + "a mão tem alvo")
	# Toque 1: arrastar a papinha (a aula abre o cardápio). Só se arrasta.
	await wait(0.8)
	check(shown("Care_puppy_mash"), label + "toque 1: a papinha no cardápio")
	var balloon := guide().get("_balloon") as Control
	check(balloon != null and screen.encloses(balloon.get_global_rect()) and balloon.get_global_rect().position.y >= hud_bottom - 60.0, label + "o balão está na tela, longe das abas " + str(balloon.get_global_rect()))
	check(not balloon.get_global_rect().intersects(node("FoodMenu").get_global_rect()), label + "o balão não cobre a janela de comida " + str(balloon.get_global_rect()) + str(node("FoodMenu").get_global_rect()))
	check(not (node("LessonNext") as Button).visible, label + "no toque 1 só se arrasta")
	var hand := node("TutorialHand")
	check(hand != null and hand.visible, label + "a mao do arrasto aparece (visivel=%s pos=%s)" % [hand.visible if hand else false, hand.global_position if hand else Vector2.ZERO])
	check(not state.meal_info().paw, label + "ainda sem patinha")
	check(state.feed("puppy_mash"), label + "dar a papinha")
	await wait(0.4)
	# Toque 2: o disco da metade ganha ✓ e a patinha (garantida) voa ao avatar.
	check(int(guide().get("beat")) == 2, label + "toque 2 depois de comer")
	check(bool(state.meal_info().paw) and state.progress.stat("well_fed_day") == 1, label + "a primeira patinha é garantida a qualquer hora")
	check(guide_text() == "Dia + noite = 1 patinha. Essa é presente!", label + "fala 2: " + guide_text())
	var period := str(state.meal_period_now())
	check(str(node("MealDay").find_child("Disc_" + period, true, false).get_meta("state")) == "done", label + "o disco da metade (%s) tem o ✓" % period)
	check((guide().get("_target") as Rect2).intersects(node("MealDay").get_global_rect()), label + "a mão aponta o potinho no toque 2")
	check(shown("LessonPaw") or Motion.reduced, label + "a patinha voa ao avatar")
	check(main.find_child("DayComplete", true, false) == null, label + "a aula mostra a própria patinha, sem o cartão Dia completo!")
	# Toque 3: painel Crescer na linha das patinhas.
	(node("LessonNext") as Button).pressed.emit()
	await wait(0.7)
	check(int(guide().get("beat")) == 3 and shown("GrowthPanel"), label + "toque 3: o painel Crescer abre")
	check(shown("GrowthReq_days") and str(node("GrowthPanel").get_meta("selected", "")) == "days", label + "na linha das patinhas")
	check(shown("PawCard") and node("PawSlot_0").get_meta("state") == "paw", label + "a cartela mostra o primeiro carimbo")
	check(shown("PawDone") and str(node("PawDone").get("text")) in ["Dia da chegada!", "Dia completo!"], label + "o primeiro carimbo é o Dia da chegada")
	check(any_shown("GrowthHelp"), label + "o ? da linha das patinhas")
	check(guide_text() == "6 patinhas = Dentinhos.", label + "fala 3: " + guide_text())
	(node("LessonNext") as Button).pressed.emit()
	await wait(0.4)
	check(state.food_lesson_done() and state.week.food_lesson and str(guide().get("kind")) == "", label + "a aula termina")
	check(shown("MealDay"), label + "depois da aula o potinho fica")
	await wait(2.8)
	check(not state.dog.sleeping, label + "a aula não manda mais dormir, a qualquer hora")


# --- Lições novas: potinho, tigela e sobremesa (cada uma dispara uma vez) ------------------------------

func _new_lessons() -> void:
	await fresh(12, true)
	for lesson: Dictionary in db.week_tutorials:
		if str(lesson.id) not in ["meal_day", "bowl"]:
			state.week.tutorial[str(lesson.id)] = {"done": true}  # só as lições novas estão em jogo
	state.finish_food_lesson()
	state.progress.claimed_quests["first_meal"] = true  # as duas lições ficam presas ao passo da aula (`after_quest`)
	state.inventory.add("puppy_mash", 4)
	await wait(1.6)
	var week_tutorial := main.find_child("WeekTutorial", true, false)
	check(week_tutorial != null and str(week_tutorial.get("active")) == "meal_day" and week_tutorial.visible, "depois da aula o potinho ganha a lição meal_day (%s)" % [str(week_tutorial.get("active")) if week_tutorial else "-"])
	check(str(week_tutorial.get("_label").text if week_tutorial.get("_label") else "").contains("Sol e lua"), "fala do potinho")
	(node("MealDay") as Button).pressed.emit()
	await wait(0.8)
	check(shown("TodayPanel") and state.week.tutorial.get("meal_day", {}).get("done", false), "tocar no potinho abre Hoje e conclui a lição")
	root.get_node("Events").sheet_close_requested.emit()
	await wait(1.6)
	check(not (week_tutorial.visible and str(week_tutorial.get("active")) == "meal_day"), "a lição do potinho não volta")
	# Primeira sobremesa: a metade já tem ✓.
	var toasts: Array[String] = []
	var catcher := func(text: String) -> void: toasts.append(text)
	root.get_node("Events").tiro_said.connect(catcher)
	state.feed("puppy_mash")
	state.feed("puppy_mash")
	check(toasts.any(func(x: String) -> bool: return x.begins_with("Sobremesa!")), "a sobremesa avisa que não vale patinha (%s)" % [toasts])
	root.get_node("Events").tiro_said.disconnect(catcher)
	# Tigela: a mão vai no botão verde da pergunta, uma vez só.
	var tray: Node = null
	for found in main.find_children("*", "Control", true, false):
		if found.has_method("open_food_menu"):
			tray = found
			break
	dismiss_cards()
	main.set("_modal_queue", [] as Array[Callable])
	tray.call("_act", "puppy_mash")
	await wait(1.4)
	check(shown("StoreMeal") and str(week_tutorial.get("active")) == "bowl", "a lição da tigela aponta o Guardar (%s)" % str(week_tutorial.get("active")))
	check((week_tutorial.get("_anchor_rect") as Rect2).intersects(node("StoreMeal").get_global_rect()), "a mão está no botão verde")
	(node("StoreMeal") as Button).pressed.emit()
	await wait(0.8)
	check(state.week.tutorial.get("bowl", {}).get("done", false) and state.progress.stat("meal_stored") == 1, "guardar conclui a lição da tigela")
	state.cancel_stored_meal("")
	tray.call("_act", "puppy_mash")
	await wait(1.4)
	check(not (week_tutorial.visible and str(week_tutorial.get("active")) == "bowl"), "a lição da tigela não volta")
	root.get_node("Events").sheet_close_requested.emit()
	await wait(0.4)


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
	check(guide_text().contains("Cada quadradinho"), "fala 1: " + guide_text())
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
	state.progress.claimed_quests["lais_bed"] = true  # fim da casa (Ato 1)
	state.grant_lesson_paw("puppy_mash")
	state.inventory.add("puppy_mash", 2)
	at(1, 23)
	var night: Array = state.week_card_candidates().filter(func(c: Dictionary) -> bool: return c.kind == "night")
	check(night.size() == 1, "Boa noite do dia 1 disponível à noite")
	var report: Dictionary = state.take_week_card(night[0])
	check(report.arrival and report.first_night and report.deal.when == "amanhã" and int(report.deal.hour) == 6, "combinado: começa amanhã, de dia (6h)")
	check(not report.has("reminder_offer"), "sem oferta de aviso")
	var report_again: Dictionary = state.take_week_card({"kind": "night", "day": 1, "civil": int(night[0].civil)})
	check(report_again.is_empty(), "o cartão não repete")
	main.get("_celebration").call("show_week_card", report)
	await wait(0.4)
	check(shown("TomorrowEquation") and shown("WeekNightMeals") and not shown("DealNeed"), "Boa noite do dia 1: a conta de amanhã desenhada, sem frase")
	check(not shown("DealOptions") and not shown("NotebookTab_early") and not shown("MealReminderOffer") and not shown("DealHours"), "Boa noite: sem opção de horário nem pergunta do aviso")
	check(shown("WeekNightPaw") and shown("StoreOffer"), "Boa noite do dia 1: patinha e a dica de deixar a comida na tigela")
	main.get("_celebration").hide()
	await frames(2)
	# Bom dia do dia 2: o combinado de verdade e a dica da tampinha.
	at(2, 9)
	var morning: Array = state.week_card_candidates().filter(func(c: Dictionary) -> bool: return c.kind == "morning")
	check(morning.size() == 1, "Bom dia do dia 2")
	var morning_report: Dictionary = state.take_week_card(morning[0])
	check(morning_report.first_day and morning_report.before_lunch and not morning_report.has("offer") and not morning_report.has("still_weak"), "primeiro dia de verdade, de manhã")
	main.get("_celebration").call("show_week_card", morning_report)
	await wait(0.4)
	var copy: Dictionary = db.week_routine.text
	check(main.find_child("WeekMorning", true, false) != null, "cartão do Bom dia")
	var has_first := false
	for label: Node in main.find_children("*", "Label", true, false):
		if str((label as Label).text).begins_with("Hoje é o primeiro dia"):
			has_first = true
	check(not has_first and not shown("StoreTip"), "Bom dia direto: sem manchete, sem frase da regra, sem dica da tigela")
	main.get("_celebration").hide()
	await frames(2)
	# De dia sem ✓ a comida vai para ele; com ✓ dá para deixar a da noite na tigela da folha Hoje.
	check(state.store_meal_error("puppy_mash") == "Ele está com fome: dê agora", "com fome a tigela não aceita")
	check(state.feed("puppy_mash"), "Dá a comidinha do dia")
	load("res://scripts/ui/meal_ui.gd").call("open_today")
	await wait(0.5)
	check(shown("StoreNow_puppy_mash") and shown("PawCardBox"), "folha Hoje: botão direto para guardar a papinha")
	var before: int = state.stored_meals().size()
	(node("StoreNow_puppy_mash") as Button).pressed.emit()
	await frames(3)
	check(state.stored_meals().size() == before + 1 and state.stored_meals()[0].period == "moon", "a papinha foi para a noite de hoje")
	check(shown("StoredCard"), "a tigela mostra o que ficou guardado")
	root.get_node("Events").sheet_close_requested.emit()
	await frames(2)
	at(2, 16)
	check(state.served_notes().size() == 1 and state.meals_on_time(2) == 2, "o Tiro comeu sozinho às 16h")
	var served: Dictionary = state.served_notes()[0]
	check(served.period == "moon" and int(served.hour) == 16 and int(served.minute) == 0, "recado: comeu às 16h")
	state.progress.claimed_quests["lais_bed"] = true  # fim da casa (Ato 1)
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
	check(shown("HungerBowl"), "de dia sem ✓ a tigela brilha")
	at(2, 12)
	await wait(0.5)
	check(shown("HungerBowl"), "com a metade aberta e sem ✓, a tigela brilha")
	check(str(root.get_node("Database").call("item_name", "puppy_mash")) != "" and shown("MealBubble"), "o balão Hora da comidinha continua")
	state.inventory.add("puppy_mash", 1)
	check(state.feed("puppy_mash"), "comidinha do dia")
	await wait(0.5)
	check(not shown("HungerBowl"), "período feito: a tigela para de brilhar")
	var meal_ui: Script = load("res://scripts/ui/meal_ui.gd")
	check(str(meal_ui.call("fed_text")) == "Barriga cheia!", "tocar nele diz que a barriga está cheia")
	at(2, 19)
	state.inventory.add("puppy_mash", 1)
	state.feed("puppy_mash")
	check(str(meal_ui.call("fed_text")) == "Barriga cheia!", "à noite: amanhã cedo tem mais")
	# Lanche: balão curto na primeira vez, e só nela.
	var toasts: Array[String] = []
	var catcher := func(text: String) -> void: toasts.append(text)
	root.get_node("Events").tiro_said.connect(catcher)
	var snack := ""
	for id: String in ["oat_biscuit", "apple_biscuit", "carrot_snack"]:
		if db.items.has(id) and db.items[id].has("feed"):
			snack = id
			break
	check(snack != "", "há um lanche no jogo para provar")
	state.inventory.add(snack, 2)
	check(state.feed(snack), "dar o primeiro petisco")
	check(toasts.any(func(t: String) -> bool: return t.begins_with("Petisco não é refeição")), "balão: lanche não é refeição (%s)" % [toasts])
	toasts.clear()
	check(state.feed(snack), "dar o segundo petisco")
	check(not toasts.any(func(t: String) -> bool: return t.begins_with("Petisco não é refeição")), "só na primeira vez")
	root.get_node("Events").tiro_said.disconnect(catcher)
	# "?" da folha Hoje e da linha das patinhas, e a página do Manual.
	load("res://scripts/ui/meal_ui.gd").call("open_today")
	await wait(0.5)
	check(shown("MealHelp"), "a folha Hoje tem o ?")
	(node("MealHelp") as Button).pressed.emit()
	await wait(0.5)
	check(shown("MealReview") and shown("Window_sun") and shown("Window_moon") and shown("Rule_paw") and shown("Rule_grow"), "o ? abre a aula em uma tela: dia de 24 h, ✓ ✓ → patinha → crescer")
	root.get_node("Events").sheet_close_requested.emit()
	await frames(2)
	load("res://scripts/ui/growth_ui.gd").call("open", "days")
	await wait(0.6)
	check(shown("PawCard") and shown("PawNext") and any_shown("GrowthHelp"), "linha das patinhas: cartela, próxima refeição e o ?")
	check(shown("PawSlot_5"), "seis espaços na cartela")
	root.get_node("Events").sheet_close_requested.emit()
	await frames(2)
	var manual: Control = load("res://scripts/ui/week_tutorial.gd").call("manual_body", {"tutorial": "food"}, func() -> void: pass)
	root.add_child(manual)
	check(manual.find_child("TutorialReview_food", true, false) != null and manual.find_child("MealReview", true, false) != null, "Manual: página Comida e crescimento com o desenho")
	manual.queue_free()
	var lessons: Array = db.week_tutorials
	var ids: Array = lessons.map(func(row: Dictionary) -> String: return str(row.id))
	check(ids.count("food") == 1 and not ids.has("clock") and not ids.has("weak") and bool(lessons[ids.find("food")].get("native", false)),
		"lições do relógio e do dia fraco saíram; a da comida segue nativa (dada pela aula)")
	db.week_story.food_lesson["quest"] = quest_id
