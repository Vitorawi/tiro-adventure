extends SceneTree
## Relógio de refeições do filhote (plano primeira_semana, E01a): janelas, refeição na hora, patinha,
## dia bem alimentado, regra do dia da chegada, dia que só avança e persistência.
##   godot --headless --path game -s res://tests/day_clock_test.gd
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


func _run() -> void:
	state = root.get_node("GameState")
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var build_info: Script = load("res://scripts/util/build_info.gd")
	if not build_info.call("is_dev"):
		print("DAY CLOCK TEST: PASS (pulado fora da versão dev)")
		quit(0)
		return
	_windows()
	_arrival_day()
	_regular_day()
	_snack_and_outside()
	_day_only_advances()
	_weak_day_and_lunchbox()
	_stored_meal()
	_persistence()
	_persistence_stored()
	print("DAY CLOCK TEST: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(0 if _failures == 0 else 1)


func _windows() -> void:
	state.call("reset")
	for row: Array in [[10, ""], [11, "lunch"], [14, "lunch"], [15, ""], [17, ""], [18, "dinner"], [21, "dinner"], [22, ""]]:
		_check(str(state.call("meal_period_at", row[0])) == row[1], "Hora %d: período '%s' (veio '%s')" % [row[0], row[1], state.call("meal_period_at", row[0])])
	_check(state.call("set_meal_option", "early") == true, "Opção Mais cedo existe")
	_check(str(state.call("meal_period_at", 10)) == "lunch" and str(state.call("meal_period_at", 14)) == "", "Mais cedo desloca a janela 1 h")
	state.call("set_meal_option", "late")
	_check(str(state.call("meal_period_at", 15)) == "lunch" and str(state.call("meal_period_at", 11)) == "", "Mais tarde desloca a janela 1 h")
	_check(state.call("set_meal_option", "xyz") == false, "Opção desconhecida é recusada")


func _arrival_day() -> void:
	state.call("reset")
	state.call("dev_week_hour", 23)  # depois das 22 h: nenhuma janela aberta
	_check(int(state.call("week_day")) == 1, "Começa no dia 1")
	_check(str(state.call("meal_error", "puppy_mash")) == "", "Dia da chegada: refeição vale a qualquer horário")
	_check(_feed("puppy_mash"), "Alimenta com a papinha")
	_check(int(state.call("meals_on_time", 1)) == 1, "Dia 1: uma refeição na hora")
	_check(bool(state.call("day_well_fed", 1)), "Dia 1: uma refeição basta para o dia bem alimentado")
	_check(int(state.call("well_fed_days")) == 1, "Uma patinha")
	_check(int(state.get("progress").call("stat", "well_fed_day")) == 1, "Contador well_fed_day")
	_check(_feed("puppy_mash"), "Segunda papinha alimenta")
	_check(int(state.call("meals_on_time", 1)) == 2, "Dia 1: a segunda vai para o outro período")
	_check(int(state.call("well_fed_days")) == 1, "A patinha não duplica")
	_check(str(state.call("meal_error", "puppy_mash")) != "", "Dia 1: depois de duas refeições, não conta mais")


func _regular_day() -> void:
	state.call("reset")
	state.call("dev_week_goto", 3)
	state.call("dev_week_hour", 9)
	_check(str(state.call("meal_error", "puppy_mash")) != "", "Dia 3, 9 h: ainda não é hora")
	_check(_feed("puppy_mash"), "Comer fora da hora ainda alimenta")
	_check(int(state.call("meals_on_time", 3)) == 0, "…mas não conta na hora")
	state.call("dev_week_hour", 12)
	_check(_feed("puppy_mash"), "Almoço")
	_check(int(state.call("meals_on_time", 3)) == 1 and not bool(state.call("day_well_fed", 3)), "Almoço na hora, dia ainda não está completo")
	_check(str(state.call("meal_error", "puppy_mash")).contains("almoço"), "Segundo almoço não conta")
	state.call("dev_week_hour", 19)
	var paws: Array = []
	var event_state: Node = root.get_node("Events")
	event_state.connect("paw_earned", func(day: int) -> void: paws.append(day))
	_check(_feed("puppy_mash"), "Jantar")
	_check(bool(state.call("day_well_fed", 3)) and paws == [3], "Jantar fecha o dia: patinha do dia 3")
	_check(int(state.call("well_fed_days")) == 1, "Uma patinha no dia 3")
	var info: Dictionary = state.call("meal_info")
	_check(info.day == 3 and info.paw and info.on_time == 2 and info.needed == 2, "meal_info do dia 3")


func _snack_and_outside() -> void:
	state.call("reset")
	state.call("dev_week_goto", 2)
	state.call("dev_week_hour", 12)
	_check(str(state.call("meal_error", "apple_biscuit")) != "", "Petisco é lanche, não refeição")
	_check(_feed("apple_biscuit"), "Petisco alimenta")
	_check(int(state.call("meals_on_time", 2)) == 0, "Petisco não conta como refeição")
	_check(str(state.call("dev_week_meal", "lunch")).contains("dia 2"), "DEV marca o almoço")
	_check(int(state.call("meals_on_time", 2)) == 1, "DEV: almoço na hora")
	state.call("dev_week_meal", "dinner")
	_check(bool(state.call("day_well_fed", 2)), "DEV: almoço + jantar = dia bem alimentado")


func _day_only_advances() -> void:
	state.call("reset")
	state.call("dev_week_goto", 4)
	var week: Object = state.get("week")
	week.set("clock_offset", float(week.get("clock_offset")) - 2.0 * 86400.0)  # o relógio do aparelho volta 2 dias
	state.call("_week_touch")
	_check(int(state.call("week_day")) == 4, "Relógio atrasado: o dia não volta (veio %d)" % int(state.call("week_day")))
	week.set("clock_offset", float(week.get("clock_offset")) + 2.0 * 86400.0 + 86400.0)
	_check(int(state.call("week_day")) == 5, "Relógio que avança: dia 5")


func _persistence() -> void:
	state.call("reset")
	state.call("dev_week_goto", 2)
	state.call("set_meal_option", "early")
	state.call("dev_week_meal", "lunch")
	state.call("dev_week_meal", "dinner")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("reset")
	state.call("from_dict", saved)
	_check(bool(state.call("day_well_fed", 2)) and int(state.call("meals_on_time", 2)) == 2, "Refeições do dia sobrevivem ao save")
	_check(str(state.get("week").get("option")) == "early", "Opção de horário sobrevive ao save")
	_check(int(state.call("well_fed_days")) == 1, "Patinha sobrevive ao save")
	state.call("from_dict", {})
	_check(int(state.call("well_fed_days")) == 0, "Save vazio: sem patinhas")


## Põe o relógio no dia e hora pedidos e deixa o fechamento das janelas rodar (como o tick de 1 s).
func _at(day: int, hour: int) -> void:
	state.call("dev_week_goto", day)
	state.call("dev_week_hour", hour)
	state.call("update_week")


func _count_of(item: String) -> int:
	return int(state.get("inventory").call("count", item))


func _weak_day_and_lunchbox() -> void:
	state.call("reset")
	_at(2, 12)
	_check(not bool(state.call("tiro_weak")), "Dia 2 ainda aberto: sem dia fraco")
	state.get("dog").needs["hunger"] = 10.0
	_at(2, 23)
	var rec: Dictionary = state.get("week").call("day_record", 2)
	_check(rec.get("lunch", {}).get("item", "") == "ration" and rec.get("dinner", {}).get("item", "") == "ration", "Janela fechou sem refeição: ração sozinho")
	_check(not bool(rec.lunch.on_time), "A ração não conta como refeição na hora")
	_check(float(state.get("dog").needs["hunger"]) >= 25.0, "A ração alimenta o Tiro")
	_check(bool(rec.get("weak", false)) and bool(state.call("tiro_weak")), "Dia 2 sem refeições = dia fraco, Tiro fraquinho")
	_check(not bool(state.call("day_well_fed", 2)) and int(state.call("well_fed_days")) == 0, "Dia fraco não conta e não tira patinha")
	_check(int(state.get("week").weak_streak) == 1, "Um dia fraco na sequência")
	state.call("update_week")
	_check(int(state.get("week").weak_streak) == 1, "Conferir de novo não duplica o dia fraco")
	# Fraquinho até a próxima refeição na hora.
	_at(3, 12)
	_check(bool(state.call("tiro_weak")), "Continua fraquinho até comer na hora")
	state.get("inventory").call("add", "puppy_mash", 1)
	state.call("feed", "puppy_mash")
	_check(not bool(state.call("tiro_weak")), "Refeição na hora tira o fraquinho")
	# Dois dias fracos seguidos: marmita.
	state.call("reset")
	_at(2, 23)
	_check(int(state.get("week").weak_streak) == 1 and int(state.get("week").lunchboxes) == 0, "Sem marmita no primeiro dia fraco")
	_at(3, 23)
	_check(int(state.get("week").lunchboxes) == 1, "Dois dias fracos seguidos: marmita da vovó")
	_check(not bool(state.call("tiro_weak")) and int(state.get("week").weak_streak) == 0, "A marmita tira o fraquinho e zera a sequência")
	_check(int(state.get("progress").call("stat", "weak_day")) == 2 and int(state.get("progress").call("stat", "lunchbox")) == 1, "Contadores weak_day e lunchbox")
	# Jogo fechado vários dias: tudo é conferido de uma vez, sem punir o dia da chegada.
	state.call("reset")
	_at(5, 9)
	_check(int(state.call("well_fed_days")) == 0, "Jogo fechado: nenhuma patinha de graça")
	var week: Object = state.get("week")
	_check(not bool(week.call("day_record", 1).get("weak", false)), "Dia da chegada nunca é fraco")
	_check(bool(week.call("day_record", 2).get("weak", false)) and bool(week.call("day_record", 3).get("weak", false)) and bool(week.call("day_record", 4).get("weak", false)), "Dias 2 a 4 ficaram fracos com o jogo fechado")
	_check(int(week.lunchboxes) == 1 and int(week.weak_streak) == 1, "Marmita no dia 3 e nova contagem no dia 4")
	# Dia bem alimentado zera a sequência.
	state.call("reset")
	_at(2, 23)
	_check(int(week.call("day_record", 2).size()) > 0 and int(state.get("week").weak_streak) == 1, "Sequência 1")
	state.call("dev_week_goto", 3)
	state.call("dev_week_hour", 12)
	state.call("dev_week_meal", "lunch")
	state.call("dev_week_meal", "dinner")
	_at(3, 23)
	_check(int(state.get("week").weak_streak) == 0 and bool(state.call("day_well_fed", 3)), "Dia bem alimentado zera a sequência de dias fracos")


func _stored_meal() -> void:
	state.call("reset")
	_at(1, 12)
	_check(str(state.call("store_meal_error", "puppy_mash")) != "", "Dia da chegada: dar agora, sem guardar")
	state.call("reset")
	_at(3, 9)
	state.get("inventory").call("add", "puppy_mash", 1)
	var before := _count_of("puppy_mash")
	_check(str(state.call("store_meal_error", "apple_biscuit")) != "", "Lanche não pode ser guardado")
	_check(str(state.call("store_meal", "puppy_mash")) == "", "Guarda a papinha para o almoço")
	_check(_count_of("puppy_mash") == before - 1, "A refeição guardada sai da Mochila")
	var stored: Dictionary = state.call("stored_meal")
	_check(stored.get("period", "") == "lunch", "Guardada para o almoço")
	_check(str(state.call("store_meal", "puppy_mash")) != "", "Só uma refeição guardada por vez")
	_check(str(state.call("cancel_stored_meal")) == "" and _count_of("puppy_mash") == before, "Cancelar devolve a refeição")
	state.call("store_meal", "puppy_mash")
	_at(3, 12)
	_check(state.call("stored_meal").is_empty() and int(state.call("meals_on_time", 3)) == 1, "Janela abriu: o Tiro comeu sozinho, almoço na hora")
	_check(bool(state.get("week").call("day_record", 3).lunch.get("stored", false)), "Registro marca refeição guardada")
	_check(_count_of("puppy_mash") == before - 1, "Comeu a refeição guardada")
	_check(str(state.call("store_meal_error", "puppy_mash")).contains("jantar") == false, "Depois do almoço dado, dá para guardar o jantar")
	# Jogo fechado: abre e fecha a janela sem ninguém ver.
	state.call("reset")
	_at(3, 9)
	state.get("inventory").call("add", "puppy_mash", 1)
	state.call("store_meal", "puppy_mash")
	_at(3, 16)
	_check(int(state.call("meals_on_time", 3)) == 1 and state.call("stored_meal").is_empty(), "Jogo fechado: comeu ao abrir a janela e conta na hora")
	var rec: Dictionary = state.get("week").call("day_record", 3)
	_check(rec.lunch.item == "puppy_mash", "O almoço foi a refeição guardada, não a ração")
	# Dentro da janela: dar agora.
	state.call("reset")
	_at(3, 12)
	state.get("inventory").call("add", "puppy_mash", 1)
	_check(str(state.call("store_meal_error", "puppy_mash")).contains("agora"), "Com a janela aberta: dar agora")




func _persistence_stored() -> void:
	state.call("reset")
	_at(3, 9)
	state.get("inventory").call("add", "puppy_mash", 1)
	state.call("store_meal", "puppy_mash")
	state.get("week").weak = true
	state.get("week").weak_streak = 1
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("reset")
	state.call("from_dict", saved)
	_check(str(state.call("stored_meal").get("period", "")) == "lunch", "Refeição guardada sobrevive ao save")
	_check(bool(state.call("tiro_weak")) and int(state.get("week").weak_streak) == 1, "Fraquinho e sequência sobrevivem ao save")
