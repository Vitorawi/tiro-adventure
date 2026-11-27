extends SceneTree
## Regras do relógio de refeições "dia e noite" (docs/plans/alimentacao, etapa A1): o dia do Tiro vira às 6h e tem duas
## metades (sun 6h–16h, moon 16h–6h), sempre uma aberta; ✓ ao vivo em cada metade e as duas valem a patinha; sobremesa;
## a tigela de dois lugares que come no começo da metade; nada acontece quando falta; a Barriga que segue o relógio;
## o aviso de fome por metade; o dia da chegada (uma refeição basta); o relógio só existe depois da aula da comida.
##   godot --headless --path game -s res://tests/meal_rules_test.gd
var _failures: int = 0
var state: Node
var _toasts: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)


func _feed(item: String = "puppy_mash") -> bool:
	state.get("inventory").call("add", item, 1)
	return bool(state.call("feed", item))


func _count_of(item: String) -> int:
	return int(state.get("inventory").call("count", item))


## Põe o relógio da semana em `dia` (0 = hoje no calendário) às hh:mm, e deixa o relógio conferir.
func _set_clock(day: int, hour: int, minute: int = 30) -> void:
	var local_now := int(state.call("_local_time", state.call("now")))
	var midnight := local_now - posmod(local_now, 86400)
	var target := midnight + day * 86400 + hour * 3600 + minute * 60
	state.get("week").set("clock_offset", float(target - local_now))
	state.call("_week_touch")
	state.call("_changed")


## Anda o relógio da semana `minutes` minutos (dentro do mesmo dia do Tiro quando não passa da virada das 6h).
func _advance(minutes: int) -> void:
	state.get("week").set("clock_offset", float(state.get("week").get("clock_offset")) + float(minutes) * 60.0)
	state.call("_week_touch")
	state.call("update_week")


## Hora do dia do Tiro `day` (número 1..) às `hour`h, com o relógio da semana andando.
func _at(day: int, hour: int) -> void:
	state.call("dev_week_goto", day)
	state.call("dev_week_hour", hour)
	state.call("update_week")


func _record(day: int) -> Dictionary:
	return state.get("week").call("day_record", day)


func _hunger() -> float:
	return float(state.get("dog").call("get_need", "hunger", state.call("now")))


func _hunger_toasts() -> int:
	var total := 0
	for text: String in _toasts:
		if text.begins_with("Hora da comidinha"):
			total += 1
	return total


func _run() -> void:
	state = root.get_node("GameState")
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var build_info: Script = load("res://scripts/util/build_info.gd")
	if not build_info.call("is_dev"):
		print("MEAL RULES TEST: PASS (pulado fora da versão dev)")
		quit(0)
		return
	root.get_node("Events").connect("toast_requested", func(text: String) -> void: _toasts.append(text))
	root.get_node("Events").connect("tiro_said", func(text: String) -> void: _toasts.append(text))
	root.get_node("Events").connect("notice_requested", func(_kind: String, text: String, _item: String) -> void: _toasts.append(text))
	_halves()
	_arrival_table()
	_arrival_paw()
	_nothing_before_lesson()
	_live_check_and_paw()
	_dessert()
	_bowl_targets()
	_bowl_eats_at_start()
	_nothing_when_missing()
	_belly()
	_hunger_notice()
	_no_auto_sleep()
	_persistence()
	print("MEAL RULES TEST: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(0 if _failures == 0 else 1)


func _halves() -> void:
	state.call("reset")
	_set_clock(0, 5)
	var before := int(state.call("week_day_number"))
	_set_clock(0, 6)
	var after := int(state.call("week_day_number"))
	_check(after == before + 1, "O dia do Tiro vira às 6h (5h30 = %d, 6h30 = %d)" % [before, after])
	# A madrugada é a noite do dia anterior: a lua vai até a virada das 6h.
	state.call("reset")
	_set_clock(0, 12)
	var day := int(state.call("week_day"))
	_set_clock(1, 0)
	_check(int(state.call("week_day")) == day, "0h30 ainda é o mesmo dia do Tiro")
	_check(str(state.call("meal_period_now")) == "moon", "Madrugada: ainda é a metade da noite")
	_set_clock(1, 5)
	_check(int(state.call("week_day")) == day and str(state.call("meal_period_now")) == "moon", "5h30 ainda é o mesmo dia, de noite")
	_set_clock(1, 6)
	_check(int(state.call("week_day")) == day + 1 and str(state.call("meal_period_now")) == "sun", "6h30 já é o dia seguinte, de dia")
	# Sempre existe uma metade aberta: sol das 6h às 16h, lua das 16h às 6h.
	for row: Array in [[6, "sun"], [10, "sun"], [15, "sun"], [16, "moon"], [18, "moon"], [23, "moon"], [0, "moon"], [2, "moon"], [5, "moon"]]:
		_check(str(state.call("meal_period_at", row[0])) == row[1], "Metade às %dh = %s" % [row[0], row[1]])
	for hour in 24:
		_check(str(state.call("meal_period_at", hour)) != "", "Nenhuma hora fica sem metade (%dh)" % hour)
	_check(state.call("meal_window", "sun") == Vector2i(6, 16) and state.call("meal_window", "moon") == Vector2i(16, 6),
		"Horas das metades: sol 6–16, lua 16–6")
	var periods: Dictionary = root.get_node("Database").get("meals").periods
	_check(periods.keys() == ["sun", "moon"] and str(periods.sun.meal) == "comidinha do dia" and str(periods.moon.when) == "de noite",
		"Config das metades")
	var meals: Dictionary = root.get_node("Database").get("meals")
	_check(not meals.has("options") and not meals.has("ration") and not meals.has("lunchbox") and not meals.has("arrival_min_hours"),
		"Saíram as opções de horário, ração e marmita da config")


func _anchor_at(day: int, hour: int, minute: int) -> void:
	state.call("reset")
	_set_clock(day, hour, minute)
	var week: Object = state.get("week")
	week.set("started_day", int(state.call("week_day_number")))
	week.set("high_day", int(week.get("started_day")))
	state.call("_anchor_arrival")


func _local_of(timestamp: float) -> int:
	return int(state.call("_local_time", timestamp))


func _arrival_table() -> void:
	var local_now := int(state.call("_local_time", state.call("now")))
	var midnight := local_now - posmod(local_now, 86400)
	# [dia, hora, minuto, termina em (dias a partir de hoje, às 6h)]: sem extensão, o dia da chegada vai até a virada seguinte.
	var rows := [
		[0, 9, 30, 1, "9h"],
		[0, 20, 30, 1, "20h"],
		[0, 0, 10, 0, "0h10: ainda é a noite de ontem"],
		[0, 4, 5, 0, "4h: sem extensão, termina às 6h de hoje"],
	]
	for row: Array in rows:
		_anchor_at(int(row[0]), int(row[1]), int(row[2]))
		var ends := _local_of(float(state.call("arrival_day_ends_at")))
		var deal: Dictionary = state.call("first_deal_at")
		_check(ends == midnight + int(row[3]) * 86400 + 6 * 3600, "Fim do dia da chegada: " + str(row[4]))
		_check(_local_of(float(deal.at)) == midnight + int(row[3]) * 86400 + 6 * 3600 and int(deal.hour) == 6 and str(deal.period) == "sun" and int(deal.day) == 2,
			"Primeiro combinado: a comidinha do dia, às 6h seguintes (" + str(row[4]) + ")")
	_anchor_at(0, 4, 5)
	_check(bool(state.call("is_arrival_day", 1)) and not bool(state.call("is_arrival_day", 2)), "O dia da chegada é só o dia da caixinha (sem extensão)")
	_check(not state.get("week").get_property_list().any(func(p: Dictionary) -> bool: return p.name in ["arrival_extended", "weak", "weak_streak", "lunchboxes", "option"]),
		"WeekState não tem mais extensão, fraquinho, marmita nem opção de horário")


func _arrival_paw() -> void:
	# Dia da chegada: uma refeição vale a patinha, de dia ou de noite.
	_anchor_at(0, 9, 30)
	_check(_feed() and bool(state.call("day_well_fed", 1)), "Chegada: uma refeição de dia vale a patinha")
	_anchor_at(0, 9, 30)
	state.call("dev_week_hour", 23)
	_check(_feed() and bool(state.call("day_well_fed", 1)), "Chegada: uma refeição de noite vale a patinha")
	_check(int(state.call("meals_needed", 1)) == 1 and int(state.call("meals_needed", 2)) == 2, "Chegada pede 1, os outros dias pedem 2")
	# No dia 2 vale a regra normal: uma só não dá patinha.
	state.call("dev_week_goto", 2)
	state.call("dev_week_hour", 12)
	_check(_feed() and not bool(state.call("day_well_fed", 2)) and int(state.call("well_fed_days")) == 1, "Depois da chegada uma refeição só não dá patinha")


func _begin_arrival() -> void:
	state.call("reset")
	state.call("_count", "arrival_box")
	state.get("progress").claimed_quests["lais_photo"] = true


func _nothing_before_lesson() -> void:
	_begin_arrival()
	_check(not bool(state.call("food_lesson_done")), "Caixinha aberta, aula ainda não dada")
	_at(1, 12)
	var meal_ui: Script = load("res://scripts/ui/meal_ui.gd")
	_check(str(meal_ui.call("asking_period")) == "", "Antes da aula: o reloginho não pede refeição")
	_check(str(state.call("store_meal_error", "puppy_mash")) == "Ainda não", "Antes da aula: nada de Deixar pronto")
	_check(not bool(state.get("dog").get("belly_clock")), "Antes da aula a Barriga ainda cai por hora")
	state.get("inventory").call("add", "puppy_mash", 1)
	_check(not bool(state.call("meal_ask_allowed", "puppy_mash")), "Antes da aula: sem pergunta")
	_check(bool(state.call("feed", "puppy_mash")), "Comer nunca trava: dá a papinha antes da aula")
	_check(int(state.call("meals_on_time", 1)) == 0 and not bool(state.call("day_well_fed", 1)), "Antes da aula comer NÃO registra o ✓")
	_at(2, 23)
	_at(4, 23)
	_check(_record(2).is_empty() and _record(3).is_empty(), "Antes da aula nada é conferido (sem dia perdido)")
	_check(state.call("week_card_candidates").is_empty(), "Antes da aula: sem Bom dia nem Boa noite")
	_at(5, 12)
	state.call("finish_food_lesson")
	_check(bool(state.call("food_lesson_done")) and str(meal_ui.call("asking_period")) == "sun", "Depois da aula o relógio existe")
	_check(bool(state.get("dog").get("belly_clock")) and absf(_hunger() - 20.0) < 0.01, "Depois da aula a Barriga é o relógio: sem ✓ = 20")
	# O passo da aula já pego também vale como aula dada.
	_begin_arrival()
	_check(not bool(state.call("food_lesson_done")), "Sem aula de novo")
	state.get("progress").claimed_quests["first_meal"] = true
	_check(bool(state.call("food_lesson_done")), "Passo da aula pego = aula dada")
	state.call("reset")
	_check(bool(state.call("food_lesson_done")), "Save que nunca abriu a caixinha: o relógio existe")


func _live_check_and_paw() -> void:
	state.call("reset")
	_at(3, 9)
	_check(not bool(state.call("meal_current_done")), "9h: a metade do dia ainda não tem ✓")
	_check(_feed(), "Comida de dia ao vivo")
	var sun: Dictionary = _record(3).get("sun", {})
	_check(bool(sun.get("on_time", false)) and not bool(_record(3).get("paw", false)), "De dia: ✓ do sol, ainda sem patinha")
	_check(_record(3).get("moon", {}).is_empty(), "A lua continua vazia")
	_check(int(state.call("meals_on_time", 3)) == 1, "Um ✓ no dia")
	state.call("dev_week_hour", 20)
	_check(_feed() and bool(_record(3).get("moon", {}).get("on_time", false)), "De noite: ✓ da lua")
	_check(bool(_record(3).get("paw", false)) and bool(state.call("day_well_fed", 3)), "Sol ✓ + lua ✓ no mesmo dia = patinha")
	# 15h50 e 16h10 valem (decisão do Vitor): duas comidas perto da virada.
	state.call("reset")
	_at(3, 9)
	_at(3, 15)
	_advance(50)
	_check(str(state.call("meal_period_now")) == "sun" and _feed(), "15h50: ✓ do dia")
	_advance(20)
	_check(str(state.call("meal_period_now")) == "moon" and _feed(), "16h10: ✓ da noite")
	_check(bool(state.call("day_well_fed", 3)), "15h50 + 16h10 valem a patinha")
	# Lanche (petisco) não é refeição: nunca registra ✓.
	state.call("reset")
	_at(3, 9)
	_check(_feed("carrot_snack") and int(state.call("meals_on_time", 3)) == 0, "Petisco é carinho: não conta ✓")
	_check(str(state.call("meal_error", "carrot_snack")) == "Isso é um lanche" and not bool(state.call("meal_dessert", "carrot_snack")), "Petisco não é sobremesa")
	# Antes da aula (relógio desligado) não há erro de hora: só "Ainda não".
	_check(str(state.call("meal_error", "puppy_mash")) == "", "Com o relógio ligado e a metade sem ✓, a comida conta")


func _dessert() -> void:
	state.call("reset")
	_at(3, 9)
	_toasts.clear()
	_check(_feed(), "Primeira comida do dia: ✓")
	var at_before: float = float(_record(3).sun.at)
	var feed_before := int(state.get("progress").call("stat", "feed"))
	state.get("inventory").call("add", "puppy_mash", 1)
	_check(bool(state.call("meal_dessert", "puppy_mash")), "A segunda comida da mesma metade é sobremesa")
	_check(bool(state.call("meal_ask_allowed", "puppy_mash")), "Com ✓ na metade e lugar na tigela, pergunta (guardar ou dar assim mesmo)")
	_check(bool(state.call("feed", "puppy_mash")), "Dar assim mesmo funciona")
	_check(int(state.call("meals_on_time", 3)) == 1 and not bool(_record(3).get("paw", false)), "Sobremesa não vira ✓ nem patinha")
	_check(float(_record(3).sun.at) == at_before, "O ✓ original fica como estava")
	_check(int(state.get("progress").call("stat", "feed")) == feed_before + 1, "Sobremesa conta como prato (contador de comida)")
	_check(_toasts.has("Sobremesa! Não vale patinha."), "Aviso de sobremesa")
	# Tigela cheia: a pergunta não aparece e ele come de sobremesa.
	state.get("inventory").call("add", "puppy_mash", 4)
	state.call("store_meal", "puppy_mash")
	state.call("store_meal", "puppy_mash")
	_check(str(state.call("store_meal_error", "puppy_mash")) == "A tigela já está cheia" and not bool(state.call("meal_ask_allowed", "puppy_mash")),
		"Tigela cheia: sem pergunta")
	# Comida da tigela sendo servida não avisa sobremesa e nunca é sobremesa.
	_toasts.clear()
	_at(3, 16)
	_check(not _toasts.has("Sobremesa! Não vale patinha."), "A comida da tigela não avisa sobremesa")


func _bowl_targets() -> void:
	state.call("reset")
	_at(3, 9)
	state.get("inventory").call("add", "puppy_mash", 3)
	_check(str(state.call("store_meal_error", "puppy_mash")) == "Ele está com fome: dê agora", "De dia sem ✓: a comida vai para ele, não para a tigela")
	_check(_feed(), "Ele come de dia")
	var targets: Array = state.call("meal_targets")
	_check(targets.size() == 2 and targets[0].period == "moon" and int(targets[0].week_day) == 3 and targets[1].period == "sun" and int(targets[1].week_day) == 4,
		"De dia: a noite de hoje e o dia de amanhã")
	_check(str(state.call("store_meal_error", "puppy_mash")) == "", "Com ✓ na metade e comida na Mochila, dá para guardar")
	_check(str(state.call("store_meal_error", "lambari_crunch")) == "Isso é um lanche", "Petisco não vai para a tigela")
	_check(str(state.call("store_meal_error", "fish_stew")) == "Você não tem isso", "Sem o item: avisa")
	_check(str(state.call("store_meal", "puppy_mash")) == "" and str(state.call("store_meal", "puppy_mash")) == "", "Cabem dois lugares")
	var stored: Array = state.call("stored_meals")
	_check(stored.size() == 2 and stored[0].period == "moon" and stored[1].period == "sun" and int(stored[1].day) == int(stored[0].day) + 1,
		"Guardadas em ordem: noite de hoje, dia de amanhã")
	_check(str(state.call("store_meal", "puppy_mash")) == "A tigela já está cheia", "A tigela só tem dois lugares")
	_check(_count_of("puppy_mash") == 1, "As duas refeições saíram da Mochila")
	# De noite o destino muda: o dia de amanhã e a noite de amanhã.
	state.call("reset")
	_at(3, 20)
	_check(_feed(), "Ele come de noite")
	targets = state.call("meal_targets")
	_check(targets.size() == 2 and targets[0].period == "sun" and targets[1].period == "moon" and int(targets[0].week_day) == 4 and int(targets[1].week_day) == 4,
		"De noite: o dia de amanhã e a noite de amanhã")
	# Madrugada ainda é a noite do mesmo dia: os alvos seguem os dias do Tiro.
	state.call("reset")
	_at(3, 0)
	_check(_feed(), "Ele come de madrugada (metade da noite)")
	targets = state.call("meal_targets")
	_check(int(targets[0].week_day) == 4 and targets[0].period == "sun", "0h: o próximo é o dia de amanhã (6h)")
	# Metade já com comida guardada não é alvo de novo; pegar de volta devolve o lugar.
	state.call("reset")
	_at(3, 9)
	state.get("inventory").call("add", "puppy_mash", 3)
	_feed()
	state.call("store_meal", "puppy_mash")
	_check(state.call("meal_targets").size() == 1 and state.call("meal_targets")[0].period == "sun", "Com a noite guardada sobra o dia de amanhã")
	_check(str(state.call("cancel_stored_meal", "moon")) == "" and state.call("stored_meals").is_empty() and state.call("meal_targets").size() == 2,
		"Pegar de volta devolve a comida e o lugar")


func _bowl_eats_at_start() -> void:
	state.call("reset")
	_at(3, 9)
	state.get("inventory").call("add", "puppy_mash", 4)
	_feed()
	state.call("store_meal", "puppy_mash")
	state.call("store_meal", "puppy_mash")
	_at(3, 15)
	_check(state.call("stored_meals").size() == 2 and int(state.call("meals_on_time", 3)) == 1, "Às 15h nada saiu da tigela")
	_at(3, 16)
	_check(state.call("stored_meals").size() == 1 and int(state.call("meals_on_time", 3)) == 2, "Às 16h ele come a da noite sozinho")
	var moon: Dictionary = _record(3).moon
	_check(bool(moon.get("stored", false)) and bool(moon.get("on_time", false)) and not moon.has("trick"), "Registro da lua marca a tigela, sem truque")
	_check(is_equal_approx(float(moon.at), float(state.call("half_start_time", int(state.get("week").get("started_day")) + 2, "moon"))),
		"O ✓ da tigela fica no instante em que a metade começou (16h)")
	_check(bool(state.call("day_well_fed", 3)), "Sol ✓ + lua ✓ da tigela = patinha")
	_check(not _record(3).moon.has("auto"), "Não é ração: não existe mais")
	_at(4, 6)
	_check(state.call("stored_meals").is_empty() and bool(_record(4).get("sun", {}).get("on_time", false)), "Às 6h do dia seguinte ele come o dia guardado")
	var notes: Array = state.call("served_notes")
	_check(notes.size() == 2 and notes[0].period == "moon" and int(notes[0].hour) == 16 and int(notes[0].minute) == 0
		and notes[1].period == "sun" and int(notes[1].hour) == 6, "Recados: 16h e 6h")
	state.call("mark_served_notes_seen")
	_check(state.call("served_notes").is_empty(), "Recados vistos não repetem")
	# Jogo fechado por horas: abre e come em ordem, dia a dia.
	state.call("reset")
	_at(3, 9)
	state.get("inventory").call("add", "puppy_mash", 4)
	_feed()
	state.call("store_meal", "puppy_mash")
	state.call("store_meal", "puppy_mash")
	_at(5, 12)
	_check(state.call("stored_meals").is_empty(), "Jogo fechado: as duas foram comidas")
	_check(bool(_record(3).get("paw", false)) and bool(_record(3).moon.get("stored", false)), "Dia 3 fechou com patinha (sol ao vivo + lua da tigela)")
	_check(bool(_record(4).get("sun", {}).get("stored", false)) and bool(_record(4).get("missed", false)), "Dia 4: só o sol da tigela, dia sem patinha")
	var closed: Array = state.call("served_notes")
	_check(closed.size() == 2 and closed[0].period == "moon" and closed[1].period == "sun", "Com o jogo fechado os recados saem em ordem")


func _nothing_when_missing() -> void:
	state.call("reset")
	_at(3, 9)
	_toasts.clear()
	_at(4, 12)
	_check(bool(_record(3).get("missed", false)) and not _record(3).has("sun") and not _record(3).has("moon"), "Dia sem comida: só `missed`, sem ração")
	_check(bool(_record(2).get("missed", false)) and not _record(1).has("missed"), "O dia da chegada nunca é `missed`")
	_check(not _record(3).has("weak") and not bool(_record(3).get("paw", false)), "Sem fraquinho nem patinha")
	var stamps: Array = state.call("paw_stamps")
	_check(stamps.any(func(entry: Dictionary) -> bool: return entry.kind == "missed"), "A cartela mostra o espaço vazio (`missed`)")
	_check(not stamps.any(func(entry: Dictionary) -> bool: return entry.kind == "weak"), "Não existe mais carimbo fraco")
	_check(float(state.get("dog").call("get_need", "happiness", state.call("now"))) > 0.0, "Nenhum castigo nas necessidades")
	# Metade que passa sem comer não faz nada nem estraga o dia seguinte.
	_check(_feed() and bool(_record(4).sun.get("on_time", false)), "No dia seguinte tudo funciona normalmente")
	# A aula de truques e a Casa não travam mais por fome.
	_check(str(state.call("trick_lesson_error", "sit")).find("comer primeiro") < 0, "Sem fraquinho: o treino não pede comida")


func _belly() -> void:
	state.call("reset")
	_at(3, 9)
	var dog: Object = state.get("dog")
	_check(bool(dog.get("belly_clock")), "Com o relógio ligado a Barriga é calculada")
	_check(absf(_hunger() - 20.0) < 0.01 and bool(state.call("need_asking", "hunger")), "Metade sem ✓: Barriga 20 e pedindo")
	_feed()
	_check(absf(_hunger() - 100.0) < 1.0 and not bool(state.call("need_asking", "hunger")), "Comeu: Barriga ~100 e não pede")
	state.call("dev_week_hour", 12)
	var mid := _hunger()
	_check(mid > 55.0 and mid < 100.0, "No meio da metade a Barriga desce em linha reta (%.1f)" % mid)
	state.call("dev_week_hour", 15)
	var late := _hunger()
	_check(late < mid and late > 50.0, "Perto do fim da metade fica acima de 50 (%.1f)" % late)
	_at(3, 15)
	_advance(59)
	_check(_hunger() >= 55.0 and _hunger() < 58.0, "No fim da metade chega perto de 55 (%.1f)" % _hunger())
	# A comida e o passeio não mexem na Barriga do relógio.
	dog.call("apply", {"hunger": -40}, state.call("now"))
	var after_apply := _hunger()
	dog.call("apply", {"hunger": 40}, state.call("now"))
	_check(is_equal_approx(_hunger(), after_apply), "Efeitos sobre `hunger` são ignorados com o relógio")
	_advance(6)
	_check(absf(_hunger() - 20.0) < 0.01 and bool(state.call("need_asking", "hunger")), "Começou a noite sem ✓: Barriga volta a 20")
	_feed()
	_check(_hunger() > 95.0, "Comeu de noite: enche de novo")
	# A Barriga também vale com o jogo fechado (cálculo puro): salvar e carregar no meio da noite.
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	_check(bool(state.get("dog").get("belly_clock")) and _hunger() > 90.0, "Depois de carregar a Barriga segue o relógio")
	# Cuidado útil: comer com fome rende; a sobremesa não.
	state.call("reset")
	_at(3, 9)
	var useful := int(state.get("progress").call("stat", "care_useful:feed"))
	_feed()
	_check(int(state.get("progress").call("stat", "care_useful:feed")) == useful + 1, "Comer com fome é cuidado útil")
	_feed()
	_check(int(state.get("progress").call("stat", "care_useful:feed")) == useful + 1, "Sobremesa não rende cuidado útil")


func _hunger_notice() -> void:
	state.call("reset")
	_at(3, 10)
	_toasts.clear()
	_feed()
	_at(3, 15)
	state.call("update_week")
	_check(_hunger_toasts() == 0, "Antes da virada nenhum aviso de fome")
	_at(3, 16)
	_check(_hunger_toasts() == 1 and _toasts.has("Hora da comidinha!"), "16h sem ✓: um aviso de fome")
	state.call("update_week")
	state.call("update_week")
	_check(_hunger_toasts() == 1, "Só um aviso por metade")
	_feed()
	_at(4, 6)
	_check(_hunger_toasts() == 2 and _toasts.back() == "Hora da comidinha!", "6h sem ✓: aviso do dia")
	# Com comida na tigela para a metade, ele come sozinho e não há aviso.
	state.get("inventory").call("add", "puppy_mash", 3)
	_feed()
	state.call("store_meal", "puppy_mash")
	_at(4, 16)
	_check(_hunger_toasts() == 2, "Metade com a comida da tigela: sem aviso")
	# Carregar o save não dispara aviso.
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	state.call("update_week")
	_check(_hunger_toasts() == 2, "Carregar o save não avisa")
	# Antes da aula nunca avisa.
	_begin_arrival()
	_toasts.clear()
	_at(1, 9)
	_at(1, 16)
	_check(_hunger_toasts() == 0, "Antes da aula não há aviso de fome")


func _no_auto_sleep() -> void:
	state.call("reset")
	state.call("_count", "arrival_box")
	var progress: Object = state.get("progress")
	_check(not bool(state.call("food_step_active")) and bool(state.call("auto_sleep_allowed")), "Sem passo de comida: pode dormir")
	for id: String in progress.call("main_quests", 1):
		if id == "lais_feed":
			break
		progress.claimed_quests[id] = true
	_check(bool(state.call("food_step_active")) and not bool(state.call("auto_sleep_allowed")), "Passo 'dar a papinha' ativo: o Tiro não dorme sozinho")
	for id: String in progress.call("main_quests", 1):
		if id == "first_meal":
			break
		progress.claimed_quests[id] = true
	_check(bool(state.call("food_step_active")), "Passo da aula ativo: o Tiro não dorme sozinho")
	progress.claimed_quests["first_meal"] = true
	_check(not bool(state.call("food_step_active")), "Aula feita: pode dormir")


func _persistence() -> void:
	state.call("reset")
	_at(3, 9)
	state.get("inventory").call("add", "puppy_mash", 3)
	_feed()
	state.call("store_meal", "puppy_mash")
	state.call("store_meal", "puppy_mash")
	state.call("finish_food_lesson")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	var week_data: Dictionary = saved.week
	_check(not week_data.has("option") and not week_data.has("weak") and not week_data.has("weak_streak") and not week_data.has("lunchboxes")
		and not week_data.has("arrival_extended"), "O save não guarda mais opção, fraquinho, marmita nem extensão")
	state.call("reset")
	state.call("from_dict", saved)
	_check(state.call("stored_meals").size() == 2, "A tigela de dois lugares sobrevive ao save")
	_check(bool(state.get("week").get("food_lesson")), "Aula dada sobrevive ao save")
	state.call("from_dict", {})
	_check(state.call("stored_meals").is_empty() and not bool(state.get("week").get("food_lesson")), "Save vazio: tigela vazia")
