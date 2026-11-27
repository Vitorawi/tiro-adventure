extends SceneTree
## Relógio de refeições do filhote (plano alimentação, A1): as duas metades do dia, ✓ ao vivo, patinha, dia bem alimentado,
## regra do dia da chegada, dia que só avança, dia sem patinha (`missed`), tigela e persistência.
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
	_missed_days()
	_stored_meal()
	_persistence()
	_persistence_stored()
	print("DAY CLOCK TEST: ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(0 if _failures == 0 else 1)


func _windows() -> void:
	state.call("reset")
	for row: Array in [[5, "moon"], [6, "sun"], [10, "sun"], [15, "sun"], [16, "moon"], [21, "moon"], [23, "moon"], [0, "moon"]]:
		_check(str(state.call("meal_period_at", row[0])) == row[1], "Hora %d: metade '%s' (veio '%s')" % [row[0], row[1], state.call("meal_period_at", row[0])])
	_check(not state.has_method("set_meal_option"), "Saiu a opção de horário")


func _arrival_day() -> void:
	state.call("reset")
	state.call("dev_week_hour", 23)
	_check(int(state.call("week_day")) == 1, "Começa no dia 1")
	_check(str(state.call("meal_error", "puppy_mash")) == "", "Dia da chegada: a refeição conta")
	_check(_feed("puppy_mash"), "Alimenta com a papinha")
	_check(int(state.call("meals_on_time", 1)) == 1, "Dia 1: uma refeição na hora")
	_check(bool(state.call("day_well_fed", 1)), "Dia 1: uma refeição basta para o dia bem alimentado")
	_check(int(state.call("well_fed_days")) == 1, "Uma patinha")
	_check(int(state.get("progress").call("stat", "well_fed_day")) == 1, "Contador well_fed_day")
	_check(str(state.call("meal_error", "puppy_mash")) != "", "Mesma metade: a segunda comida não conta como ✓")
	state.call("dev_week_hour", 9)
	_check(_feed("puppy_mash"), "De dia a outra metade registra")
	_check(int(state.call("meals_on_time", 1)) == 2, "Dia 1: as duas metades têm ✓")
	_check(int(state.call("well_fed_days")) == 1, "A patinha não duplica")


func _regular_day() -> void:
	state.call("reset")
	state.call("dev_week_goto", 3)
	state.call("dev_week_hour", 9)
	_check(str(state.call("meal_error", "puppy_mash")) == "", "Dia 3, 9 h: a metade do dia está aberta")
	_check(_feed("puppy_mash"), "Comidinha do dia")
	_check(int(state.call("meals_on_time", 3)) == 1 and not bool(state.call("day_well_fed", 3)), "De dia ✓, dia ainda não está completo")
	_check(str(state.call("meal_error", "puppy_mash")).contains("de dia"), "Segunda comida da metade não conta ✓")
	state.call("dev_week_hour", 19)
	var paws: Array = []
	var event_state: Node = root.get_node("Events")
	event_state.connect("paw_earned", func(day: int) -> void: paws.append(day))
	_check(_feed("puppy_mash"), "Comidinha da noite")
	_check(bool(state.call("day_well_fed", 3)) and paws == [3], "A noite fecha o dia: patinha do dia 3")
	_check(int(state.call("well_fed_days")) == 1, "Uma patinha no dia 3")
	var info: Dictionary = state.call("meal_info")
	_check(info.day == 3 and info.paw and info.on_time == 2 and info.needed == 2 and info.period == "moon", "meal_info do dia 3")


func _snack_and_outside() -> void:
	state.call("reset")
	state.call("dev_week_goto", 2)
	state.call("dev_week_hour", 12)
	_check(str(state.call("meal_error", "apple_biscuit")) != "", "Petisco é lanche, não refeição")
	_check(_feed("apple_biscuit"), "Petisco alimenta")
	_check(int(state.call("meals_on_time", 2)) == 0, "Petisco não conta como refeição")
	_check(str(state.call("dev_week_meal", "sun")).contains("dia 2"), "DEV marca a comidinha do dia")
	_check(int(state.call("meals_on_time", 2)) == 1, "DEV: um ✓")
	state.call("dev_week_meal", "moon")
	_check(bool(state.call("day_well_fed", 2)), "DEV: sol + lua = dia bem alimentado")


func _day_only_advances() -> void:
	state.call("reset")
	state.call("dev_week_goto", 4)
	var week: Object = state.get("week")
	week.set("clock_offset", float(week.get("clock_offset")) - 2.0 * 86400.0)  # o relógio do aparelho volta 2 dias
	state.call("_week_touch")
	_check(int(state.call("week_day")) == 4, "Relógio atrasado: o dia não volta (veio %d)" % int(state.call("week_day")))
	week.set("clock_offset", float(week.get("clock_offset")) + 2.0 * 86400.0 + 86400.0)
	_check(int(state.call("week_day")) == 5, "Relógio que avança: dia 5")


## Põe o relógio no dia e hora pedidos e deixa o fechamento das metades rodar (como o tick de 1 s).
func _at(day: int, hour: int) -> void:
	state.call("dev_week_goto", day)
	state.call("dev_week_hour", hour)
	state.call("update_week")


func _count_of(item: String) -> int:
	return int(state.get("inventory").call("count", item))


func _missed_days() -> void:
	state.call("reset")
	_at(2, 12)
	var week: Object = state.get("week")
	_check(not bool(week.call("day_record", 2).get("missed", false)), "Dia 2 ainda aberto: nada marcado")
	_at(3, 9)
	var rec: Dictionary = week.call("day_record", 2)
	_check(bool(rec.get("missed", false)) and not rec.has("sun") and not rec.has("moon"), "Dia sem comida: só `missed`, sem ração")
	_check(not bool(state.call("day_well_fed", 2)) and int(state.call("well_fed_days")) == 0, "Dia sem patinha não tira patinha")
	state.call("update_week")
	_check(bool(week.call("day_record", 2).get("missed", false)), "Conferir de novo não muda o dia")
	_check(not week.call("day_record", 1).has("missed"), "O dia da chegada nunca é `missed`")
	# Jogo fechado vários dias: tudo é conferido de uma vez.
	state.call("reset")
	_at(5, 9)
	_check(int(state.call("well_fed_days")) == 0, "Jogo fechado: nenhuma patinha de graça")
	week = state.get("week")
	_check(bool(week.call("day_record", 2).get("missed", false)) and bool(week.call("day_record", 3).get("missed", false))
		and bool(week.call("day_record", 4).get("missed", false)), "Dias 2 a 4 ficaram sem patinha com o jogo fechado")
	_check(not state.has_method("tiro_weak") and not week.get_property_list().any(func(p: Dictionary) -> bool: return p.name in ["weak", "lunchboxes"]),
		"Sem fraquinho nem marmita")
	# Dia com patinha não é `missed`.
	state.call("reset")
	_at(2, 12)
	state.call("dev_week_meal", "sun")
	state.call("dev_week_meal", "moon")
	_at(3, 9)
	_check(not bool(state.get("week").call("day_record", 2).get("missed", false)) and bool(state.call("day_well_fed", 2)), "Dia com patinha não é `missed`")


func _stored_meal() -> void:
	state.call("reset")
	_at(3, 9)
	state.get("inventory").call("add", "puppy_mash", 1)
	var before := _count_of("puppy_mash")
	_check(str(state.call("store_meal_error", "puppy_mash")) != "", "De dia sem ✓: dar agora, sem guardar")
	_feed("puppy_mash")
	_check(str(state.call("store_meal_error", "apple_biscuit")) != "", "Lanche não pode ser guardado")
	_check(str(state.call("store_meal", "puppy_mash")) == "", "Guarda a papinha para a noite")
	_check(_count_of("puppy_mash") == before - 1, "A refeição guardada sai da Mochila")
	var stored: Dictionary = state.call("stored_meal")
	_check(stored.get("period", "") == "moon", "Guardada para a noite")
	state.get("inventory").call("add", "puppy_mash", 2)
	_check(str(state.call("store_meal", "puppy_mash")) == "", "A tigela tem dois lugares: guarda também o dia de amanhã")
	_check(str(state.call("store_meal", "puppy_mash")) != "", "Só duas refeições guardadas por vez")
	state.call("cancel_stored_meal", "sun")
	state.get("inventory").call("remove", "puppy_mash")
	state.get("inventory").call("remove", "puppy_mash")
	_check(str(state.call("cancel_stored_meal")) == "" and _count_of("puppy_mash") == before, "Cancelar devolve a refeição")
	state.call("store_meal", "puppy_mash")
	_at(3, 16)
	_check(state.call("stored_meal").is_empty() and int(state.call("meals_on_time", 3)) == 2, "A noite começou: o Tiro comeu sozinho, ✓ da lua")
	_check(bool(state.get("week").call("day_record", 3).moon.get("stored", false)), "Registro marca refeição guardada")
	_check(bool(state.call("day_well_fed", 3)), "Sol ✓ + lua da tigela = patinha")
	_check(_count_of("puppy_mash") == before - 1, "Comeu a refeição guardada")


func _persistence() -> void:
	state.call("reset")
	state.call("dev_week_goto", 2)
	state.call("dev_week_meal", "sun")
	state.call("dev_week_meal", "moon")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("reset")
	state.call("from_dict", saved)
	_check(bool(state.call("day_well_fed", 2)) and int(state.call("meals_on_time", 2)) == 2, "Refeições do dia sobrevivem ao save")
	_check(int(state.call("well_fed_days")) == 1, "Patinha sobrevive ao save")
	state.call("from_dict", {})
	_check(int(state.call("well_fed_days")) == 0, "Save vazio: sem patinhas")


func _persistence_stored() -> void:
	state.call("reset")
	_at(3, 9)
	_feed("puppy_mash")
	state.get("inventory").call("add", "puppy_mash", 1)
	state.call("store_meal", "puppy_mash")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("reset")
	state.call("from_dict", saved)
	_check(str(state.call("stored_meal").get("period", "")) == "moon", "Refeição guardada sobrevive ao save")
