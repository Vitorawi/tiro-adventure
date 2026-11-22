extends SceneTree
## Relógio da semana (plano primeira_semana, E00): dia 1 no começo, DEV leva a qualquer dia/hora,
## o relógio persiste no save e na versão publicada as ferramentas não fazem nada.
##   godot --headless --path game -s res://tests/week_clock_test.gd [-- --prod]
var _failures: int = 0
var state: Node
var build_info: Script


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)


func _run() -> void:
	state = root.get_node("GameState")
	build_info = load("res://scripts/util/build_info.gd")
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	if build_info.call("is_dev"):
		_dev_mode()
	else:
		_prod_mode()
	print("WEEK CLOCK TEST (%s): " % build_info.call("channel"), "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(0 if _failures == 0 else 1)


func _dev_mode() -> void:
	state.call("reset")
	_check(int(state.call("week_day")) == 1, "Save novo começa no dia 1")
	_check(float(state.get("week").clock_offset) == 0.0, "Save novo sem deslocamento")
	for day: int in [3, 7, 9, 1]:
		state.call("dev_week_goto", day)
		_check(int(state.call("week_day")) == day, "DEV leva ao dia %d (veio %d)" % [day, int(state.call("week_day"))])
	for hour: int in [0, 8, 12, 18, 23]:
		var day_before: int = state.call("week_day")
		state.call("dev_week_hour", hour)
		_check(int(state.call("week_hour")) == hour, "DEV leva à hora %d (veio %d)" % [hour, int(state.call("week_hour"))])
		_check(int(state.call("week_day")) == day_before, "Mudar a hora não troca o dia")
	state.call("dev_week_hour", 22)
	state.call("dev_week_shift_hours", 3)
	_check(int(state.call("week_day")) == 1 and int(state.call("week_hour")) == 1, "+3 h às 22h é 1h: ainda é o mesmo dia do Tiro (a virada é às 6h)")
	state.call("dev_week_shift_hours", 5)
	_check(int(state.call("week_day")) == 2 and int(state.call("week_hour")) == 6, "1h + 5 h = 6h: vira o dia do Tiro")
	state.call("dev_week_goto", 4)
	state.call("dev_week_hour", 15)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("reset")
	_check(int(state.call("week_day")) == 1, "Novo jogo volta ao dia 1")
	state.call("from_dict", saved)
	_check(int(state.call("week_day")) == 4 and int(state.call("week_hour")) == 15, "Relógio da semana sobrevive ao save")
	state.call("dev_week_reset_clock")
	_check(int(state.call("week_day")) == 1, "Voltar ao relógio real: dia 1")
	_check(str(state.call("dev_week_meal", "lunch")).contains("dia 1"), "DEV marca a refeição do dia")
	_check(state.call("dev_week_kit", "caminha") == "" and state.call("has_upgrade", "dog_bed"), "DEV monta a caminha sem cobrar")
	state.call("from_dict", {})
	_check(int(state.call("week_day")) == 1, "Save sem chave week marca o dia 1")


func _prod_mode() -> void:
	state.call("reset")
	state.call("dev_week_goto", 5)
	state.call("dev_week_hour", 3)
	state.call("dev_week_shift_hours", 10)
	_check(float(state.get("week").clock_offset) == 0.0, "Prod bloqueia o deslocamento do relógio")
	_check(int(state.call("week_day")) == 1, "Prod fica no dia 1")
