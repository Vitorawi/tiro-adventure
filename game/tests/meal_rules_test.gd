extends SceneTree
## Regras do relógio de refeições da F02 (parte A): o dia do Tiro vira às 6h, o dia da chegada (e sua extensão),
## o relógio que só existe depois da aula da comida, a pergunta que nunca aparece na primeira refeição do dia,
## a tigela de dois lugares e o Tiro que não dorme sozinho com passo de comida ativo.
##   godot --headless --path game -s res://tests/meal_rules_test.gd
var _failures: int = 0
var state: Node


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)


func _feed(item: String) -> bool:
	state.get("inventory").call("add", item, 1)
	return bool(state.call("feed", item))


func _count_of(item: String) -> int:
	return int(state.get("inventory").call("count", item))


## Põe o relógio da semana em `dia` (0 = hoje no calendário) às hh:mm, e deixa as janelas conferirem.
func _set_clock(day: int, hour: int, minute: int = 30) -> void:
	var local_now := int(state.call("_local_time", state.call("now")))
	var midnight := local_now - posmod(local_now, 86400)
	var target := midnight + day * 86400 + hour * 3600 + minute * 60
	state.get("week").set("clock_offset", float(target - local_now))
	state.call("_week_touch")


## Hora do dia do Tiro `day` (número 1..) às `hour`h, com o relógio da semana andando.
func _at(day: int, hour: int) -> void:
	state.call("dev_week_goto", day)
	state.call("dev_week_hour", hour)
	state.call("update_week")


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
	_day_flip()
	_arrival_table()
	_arrival_paw()
	_nothing_before_lesson()
	_first_meal_no_question()
	_two_place_bowl()
	_bowl_targets()
	_no_auto_sleep()
	_persistence()
	print("MEAL RULES TEST: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(0 if _failures == 0 else 1)


func _day_flip() -> void:
	state.call("reset")
	_set_clock(0, 5)
	var before := int(state.call("week_day_number"))
	_set_clock(0, 6)
	var after := int(state.call("week_day_number"))
	_check(after == before + 1, "O dia do Tiro vira às 6h (5h30 = %d, 6h30 = %d)" % [before, after])
	# A madrugada é a noite do dia anterior: um jantar dado às 23h30 e o relógio à 0h30 continuam no mesmo dia.
	state.call("reset")
	_set_clock(0, 12)
	var day := int(state.call("week_day"))
	_set_clock(1, 0)
	_check(int(state.call("week_day")) == day, "0h30 ainda é o mesmo dia do Tiro")
	_check(str(state.call("meal_period_now")) == "", "Madrugada: nenhuma janela aberta")
	_set_clock(1, 5)
	_check(int(state.call("week_day")) == day, "5h30 ainda é o mesmo dia do Tiro")
	_set_clock(1, 6)
	_check(int(state.call("week_day")) == day + 1, "6h30 já é o dia seguinte")
	# Janela de refeição na hora real: 11h–15h e 18h–22h, sem mudar com a virada.
	state.call("reset")
	for row: Array in [[10, ""], [11, "lunch"], [14, "lunch"], [15, ""], [18, "dinner"], [21, "dinner"], [22, ""], [2, ""]]:
		_check(str(state.call("meal_period_at", row[0])) == row[1], "Janela às %dh" % row[0])


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
	# [dia, hora, minuto, termina em (dias a partir de hoje, às 6h), primeiro almoço em (dias a partir de hoje, às 11h)]
	var rows := [
		[0, 9, 30, 1, 1, "9h: termina às 6h do dia seguinte, combinado no almoço do dia seguinte"],
		[0, 20, 30, 1, 1, "20h: termina às 6h do dia seguinte, combinado no almoço do dia seguinte"],
		[0, 0, 10, 0, 0, "0h10: é a noite de ontem, termina às 6h de hoje e o combinado é o almoço de hoje"],
		[0, 4, 5, 1, 1, "4h: faltam menos de 3 h, estende até as 6h do dia seguinte"],
	]
	for row: Array in rows:
		_anchor_at(int(row[0]), int(row[1]), int(row[2]))
		var ends := _local_of(float(state.call("arrival_day_ends_at")))
		var deal: Dictionary = state.call("first_deal_at")
		_check(ends == midnight + int(row[3]) * 86400 + 6 * 3600, "Fim do dia da chegada: " + str(row[5]))
		_check(_local_of(float(deal.at)) == midnight + int(row[4]) * 86400 + 11 * 3600 and int(deal.hour) == 11 and str(deal.period) == "lunch",
			"Primeiro combinado: " + str(row[5]))
	_anchor_at(0, 4, 5)
	_check(bool(state.get("week").get("arrival_extended")) and bool(state.call("is_arrival_day", 2)) and not bool(state.call("is_arrival_day", 3)),
		"Chegada estendida: os dias 1 e 2 são da chegada")
	_anchor_at(0, 9, 30)
	_check(not bool(state.get("week").get("arrival_extended")) and not bool(state.call("is_arrival_day", 2)), "Chegada de dia: só o dia 1")
	# O combinado ganha o horário da opção escolhida.
	state.call("set_meal_option", "early")
	_check(int(state.call("first_deal_at").hour) == 10, "Mais cedo: o primeiro almoço do combinado é às 10h")


func _arrival_paw() -> void:
	# Dia da chegada: uma refeição a qualquer hora vale a patinha (23h, fora de janela).
	_anchor_at(0, 9, 30)
	state.call("dev_week_hour", 23)
	_check(_feed("puppy_mash") and bool(state.call("day_well_fed", 1)), "Chegada: refeição às 23h vale a patinha")
	# Estendida: a patinha é uma só, mesmo comendo nos dois dias da chegada.
	_anchor_at(0, 4, 5)
	_check(_feed("puppy_mash") and bool(state.call("day_well_fed", 1)), "Chegada estendida: patinha no dia 1")
	state.call("dev_week_goto", 2)
	state.call("dev_week_hour", 12)
	_check(_feed("puppy_mash"), "Come no dia 2 da chegada")
	_check(not bool(state.call("day_well_fed", 2)) and int(state.call("well_fed_days")) == 1, "A patinha da chegada não duplica no dia 2")


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
	_check(str(state.call("store_meal_error", "puppy_mash")) != "", "Antes da aula: nada de Deixar pronto")
	state.get("inventory").call("add", "puppy_mash", 1)
	_check(not bool(state.call("meal_ask_allowed", "puppy_mash")), "Antes da aula: sem pergunta Dar agora/Deixar pronto")
	_check(bool(state.call("feed", "puppy_mash")), "Comer nunca trava: dá a papinha antes da aula")
	_check(bool(state.call("day_well_fed", 1)), "A patinha do dia da chegada conta por baixo")
	_at(2, 23)
	_at(4, 23)
	var week: Object = state.get("week")
	_check(week.call("day_record", 2).is_empty() and week.call("day_record", 3).is_empty(), "Antes da aula: sem ração sozinho nem dia fraco")
	week.set("weak", true)
	week.set("weak_streak", 1)
	_check(not bool(state.call("tiro_weak")), "Antes da aula: sem fraquinho")
	_check(int(week.get("lunchboxes")) == 0 and state.call("week_card_candidates").is_empty(), "Antes da aula: sem marmita, Bom dia nem Boa noite")
	_at(5, 12)
	_check(str(meal_ui.call("asking_period")) == "", "Antes da aula, no dia 5: o relógio continua quieto")
	state.call("finish_food_lesson")
	_check(bool(state.call("food_lesson_done")) and str(meal_ui.call("asking_period")) == "lunch", "Depois da aula: o relógio existe")
	_check(bool(state.call("tiro_weak")), "Depois da aula o fraquinho volta a valer")
	# O passo da aula já pego também vale como aula dada.
	_begin_arrival()
	_check(not bool(state.call("food_lesson_done")), "Sem aula de novo")
	state.get("progress").claimed_quests["first_meal"] = true
	_check(bool(state.call("food_lesson_done")), "Passo da aula pego = aula dada")
	state.call("reset")
	_check(bool(state.call("food_lesson_done")), "Save que nunca abriu a caixinha: o relógio existe")


func _first_meal_no_question() -> void:
	state.call("reset")
	_at(3, 9)
	state.get("inventory").call("add", "puppy_mash", 2)
	_check(str(state.call("meal_error", "puppy_mash")) != "" and str(state.call("store_meal_error", "puppy_mash")) == "", "9h: não é hora e dá para guardar")
	_check(not bool(state.call("meal_ask_allowed", "puppy_mash")), "Primeira refeição do dia: sem pergunta")
	_at(3, 12)
	_check(_feed("puppy_mash"), "Almoço na hora")
	state.get("inventory").call("add", "puppy_mash", 1)
	_check(bool(state.call("meal_ask_allowed", "puppy_mash")), "Segunda refeição do dia, fora da regra: aparece a pergunta")


func _two_place_bowl() -> void:
	state.call("reset")
	_at(3, 9)
	state.get("inventory").call("add", "puppy_mash", 3)
	_check(str(state.call("store_meal", "puppy_mash")) == "", "Deixa o almoço pronto")
	_check(str(state.call("store_meal", "puppy_mash")) == "", "Deixa o jantar pronto (segundo lugar)")
	var stored: Array = state.call("stored_meals")
	_check(stored.size() == 2 and stored[0].period == "lunch" and stored[1].period == "dinner" and stored[0].day == stored[1].day,
		"Duas refeições guardadas: almoço e jantar de hoje")
	_check(str(state.call("store_meal", "puppy_mash")) != "", "A tigela só tem dois lugares")
	_check(_count_of("puppy_mash") == 1, "As duas refeições saíram da Mochila")
	_at(3, 12)
	var week: Object = state.get("week")
	_check(int(state.call("meals_on_time", 3)) == 1 and state.call("stored_meals").size() == 1, "Almoço servido sozinho, jantar ainda guardado")
	_check(bool(week.call("day_record", 3).lunch.get("stored", false)), "Registro do almoço marca a tigela (sem bônus ao vivo)")
	_at(3, 19)
	_check(state.call("stored_meals").is_empty() and bool(state.call("day_well_fed", 3)), "Jantar servido sozinho: a patinha do dia conta")
	_check(not bool(week.call("day_record", 3).dinner.get("auto", false)), "O jantar foi a refeição guardada, não a ração")
	# Recados para o Bom dia.
	var notes: Array = state.call("served_notes")
	_check(notes.size() == 2 and notes[0].period == "lunch" and int(notes[0].hour) == 11 and int(notes[0].minute) < 20, "Recado do almoço às 11h e poucos minutos")
	_check(notes[1].period == "dinner" and int(notes[1].hour) == 18, "Recado do jantar às 18h")
	state.call("mark_served_notes_seen")
	_check(state.call("served_notes").is_empty(), "Recados vistos não repetem")
	# Pegar de volta um só.
	state.call("reset")
	_at(3, 9)
	state.get("inventory").call("add", "puppy_mash", 2)
	state.call("store_meal", "puppy_mash")
	state.call("store_meal", "puppy_mash")
	_check(str(state.call("cancel_stored_meal", "dinner")) == "" and state.call("stored_meals").size() == 1 and _count_of("puppy_mash") == 1,
		"Pegar de volta só o jantar")
	# Jogo fechado: abre as duas janelas sem ninguém ver.
	state.call("reset")
	_at(3, 9)
	state.get("inventory").call("add", "puppy_mash", 2)
	state.call("store_meal", "puppy_mash")
	state.call("store_meal", "puppy_mash")
	_at(3, 23)
	_check(int(state.call("meals_on_time", 3)) == 2 and bool(state.call("day_well_fed", 3)), "Jogo fechado: os dois foram comidos na hora")
	_check(state.call("served_notes").size() == 2, "Com o jogo fechado o recado também fica guardado")


func _bowl_targets() -> void:
	# Quem joga às 20h dá o jantar ao vivo e deixa o almoço de amanhã.
	state.call("reset")
	_at(3, 20)
	state.get("inventory").call("add", "puppy_mash", 3)
	_check(_feed("puppy_mash") and bool(state.call("meals_on_time", 3) >= 1), "20h: jantar ao vivo")
	var next: Dictionary = state.call("meal_next_target")
	_check(next.period == "lunch" and int(next.week_day) == 4, "20h: a tigela guarda o almoço de amanhã (dia %s)" % str(next.get("week_day")))
	# Quem joga à meia-noite deixa os dois do dia que começa às 6h.
	state.call("reset")
	_at(3, 0)
	var targets: Array = state.call("meal_targets")
	_check(targets.size() == 2 and int(targets[0].week_day) == 4 and int(targets[1].week_day) == 4, "0h: almoço e jantar do dia seguinte")
	state.get("inventory").call("add", "puppy_mash", 2)
	_check(str(state.call("store_meal", "puppy_mash")) == "" and str(state.call("store_meal", "puppy_mash")) == "", "À meia-noite cabem os dois")
	# Tigela cheia e os dois períodos ocupados: sem alvo livre.
	_check(state.call("meal_next_target").is_empty(), "Tigela cheia: sem alvo livre")


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
	state.get("inventory").call("add", "puppy_mash", 2)
	state.call("store_meal", "puppy_mash")
	state.call("store_meal", "puppy_mash")
	state.call("finish_food_lesson")
	var week: Object = state.get("week")
	week.set("arrival_extended", true)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("reset")
	state.call("from_dict", saved)
	week = state.get("week")
	_check(state.call("stored_meals").size() == 2, "A tigela de dois lugares sobrevive ao save")
	_check(bool(week.get("food_lesson")) and bool(week.get("arrival_extended")), "Aula dada e chegada estendida sobrevivem ao save")
	state.call("from_dict", {})
	_check(state.call("stored_meals").is_empty() and not bool(state.get("week").get("food_lesson")), "Save vazio: tigela vazia")
