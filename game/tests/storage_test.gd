extends SceneTree
## Teste do armazenamento com limite (geladeira, silo, armazém, baú).
## --headless --path game -s res://tests/storage_test.gd

var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)


func _run() -> void:
	var state: Node = root.get_node("GameState")
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state.call("reset")
	var progress: Object = state.get("progress")
	var inventory: Object = state.get("inventory")
	_check(state.call("storage_of", "egg") == "fridge", "Ovo mora na geladeira")
	_check(state.call("storage_of", "milk") == "fridge", "Leite mora na geladeira")
	_check(state.call("storage_of", "carrot") == "silo", "Colheita mora no silo")
	_check(state.call("storage_of", "wood") == "warehouse", "Material mora no armazém")
	_check(state.call("storage_of", "treat_box") == "chest", "Produto mora no baú")
	_check(state.call("storage_of", "dog_food") == "", "Ração não tem limite")
	# Etapa 05: a horta já nasce com um cesto de 16; o silo construído sobe para 32.
	_check(state.call("storage_capacity", "silo") == 16, "Cesto da horta provisório = 16")
	_check(state.call("storage_error", {"carrot": 16}) == "", "Cabe exatamente no cesto")
	_check(state.call("storage_error", {"carrot": 17}) != "", "Sem silo o cesto é finito")
	_check(state.call("storage_name", "silo") == "Cesto da horta", "Antes do silo: Cesto da horta")
	# Geladeira: limite 24 por padrão.
	progress.owned["fridge"] = true
	_check(state.call("storage_capacity", "fridge") == 24, "Geladeira base = 24")
	inventory.counts.clear()
	inventory.add("egg", 19)
	inventory.add("dog_food", 50)
	_check(state.call("storage_used", "fridge") == 19, "Ração não conta na geladeira")
	_check(state.call("storage_space", "fridge") == 5, "Sobram 5 vagas")
	_check(state.call("storage_error", {"milk": 5}) == "", "Cabe exatamente")
	_check(state.call("storage_error", {"milk": 6}) != "", "Não cabe")
	_check(state.call("storage_error", {"milk": 3, "egg": 3}) != "", "Soma por depósito")
	# Ampliação via melhoria comum.
	_check(state.call("storage_next_upgrade", "fridge") == "fridge_2", "Próxima ampliação")
	progress.owned["fridge_2"] = true
	_check(state.call("storage_capacity", "fridge") == 40, "Geladeira nível 2 = 40")
	_check(state.call("storage_error", {"milk": 6}) == "", "Cabe depois de ampliar")
	# Colheita: bloqueada se não couber, sem perder nada.
	progress.owned["silo"] = true
	progress.owned["farm"] = true
	inventory.add("carrot", state.call("storage_capacity", "silo"))
	state.set("unlocked_plots", 3)
	state.call("_ensure_plots")
	_check(state.call("plant", 0, "carrot") == "", "Plantou")
	(state.get("plots") as Array)[0]["ready_at"] = 0.0
	_check((state.call("harvest", 0) as Dictionary).is_empty(), "Silo cheio bloqueia a colheita")
	_check(state.call("plot_status", 0) == "ready", "A planta continua pronta")
	inventory.remove("carrot", 10)
	_check(not (state.call("harvest", 0) as Dictionary).is_empty(), "Colhe quando abre espaço")
	# Estação: lote que não cabe fica pronto na fila.
	progress.owned["stove"] = true
	var station: Object = state.call("station", "stove")
	inventory.counts.clear()
	inventory.add("egg", 40)
	progress.owned["fridge_2"] = true
	station.queue.append({"recipe": "vegetable_soup", "ready_at": 0.0, "qty": 1})
	var got: Dictionary = state.call("collect", "stove")
	_check(got.is_empty() and station.ready_count(state.call("now")) == 1, "Lote que não cabe continua pronto na fila")
	inventory.remove("egg", 10)
	_check(not (state.call("collect", "stove") as Dictionary).is_empty(), "Entrega quando abre espaço")
	print("STORAGE TEST: %s" % ("PASS" if _failures == 0 else "FAIL"))
	quit(1 if _failures > 0 else 0)
