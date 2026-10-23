extends SceneTree
## Etapa 03 da economia R1: viagem e bagagem do passeio são estados diferentes.
## --headless --path game -s res://tests/walk_return_test.gd
## Relógio injetado (friend_clock) e fixtures sintéticas; nunca usa o save do jogador.
## Depósitos de teste: os itens de trilha são mapeados para cada depósito com capacidade provisória
## (`prebuild_capacity`), porque hoje nenhum depósito recebe itens de passeio (isso chega na etapa 08).

const T0 := 1791936000.0
const DEPOTS: Array[String] = ["silo", "fridge", "warehouse", "chest"]

var state: Node
var db: Node
var failures := 0
var returned_events := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Volta do Tiro: " + message)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/friend_clock.gd"))
	root.get_node("Events").connect("walk_collected", func(_result: Dictionary) -> void: returned_events += 1)
	_clock_edges()
	_reload_at_every_transition()
	_full_depots()
	_partial_and_repeat()
	_rare_and_legendary()
	_dog_timeline()
	_compat_and_cancel()
	_surfaces()
	print("WALK RETURN TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# --- Utilitários -------------------------------------------------------------------

func _fresh() -> void:
	state.set("test_time", T0)
	state.set("unlimited_storage", false)
	state.call("reset")
	_p().claimed_quests["main_2_order"] = true
	_p().claimed_quests["nina_meet"] = true
	_p().claimed_quests["nina_walk"] = true
	state.get("dog").needs["energy"] = 100.0
	state.get("dog").updated_at = T0
	returned_events = 0


func _at(seconds: float) -> void:
	state.set("test_time", T0 + seconds)


func _p() -> RefCounted:
	return state.get("progress")


func _inv() -> RefCounted:
	return state.get("inventory")


func _json_roundtrip() -> void:
	state.call("from_dict", JSON.parse_string(JSON.stringify(state.call("to_dict"))))


func _walk() -> RefCounted:
	return state.get("walk_state")


## Tabela determinística: um sorteio que sempre dá 3 gravetos; a primeira volta soma 2 gravetos e 1 fita.
func _fixed_table() -> Dictionary:
	var def: Dictionary = db.get("walks").walks.park_loop
	var before: Dictionary = def.loot.duplicate(true)
	def.loot = {"rolls": 1, "table": [{"weight": 1, "items": {"stick": 3}}], "first": {"items": {"stick": 2, "ribbon": 1}},
			"rare": {"chance": 0.0, "pity": 6, "collection": "plaid_bow", "duplicate": {"coins": 20, "items": {"ribbon": 1}}}}
	return before


func _put_in_depot(depot: String, capacity: int) -> Dictionary:
	var saved := {"stick": db.get("items").stick.get("storage", ""), "ribbon": db.get("items").ribbon.get("storage", "")}
	db.get("items").stick["storage"] = depot
	db.get("items").ribbon["storage"] = depot
	db.get("progression").storage[depot]["prebuild_capacity"] = capacity
	saved["depot"] = depot
	return saved


func _restore_depot(saved: Dictionary) -> void:
	db.get("items").stick["storage"] = saved.stick
	db.get("items").ribbon["storage"] = saved.ribbon
	db.get("progression").storage[saved.depot].erase("prebuild_capacity")


func _leave_and_return(id: String = "park_loop") -> void:
	var error: String = state.call("start_walk", id)
	check(error == "", "sai para " + id + ": " + error)
	state.set("test_time", float(state.get("test_time")) + float(db.get("walks").walks[id].seconds))
	state.call("return_due_walk")


# --- Relógio: antes, no instante e depois de ready_at --------------------------------

func _clock_edges() -> void:
	_fresh()
	var before := _fixed_table()
	check(state.call("start_walk", "park_loop") == "", "sai")
	check(state.call("walking") and state.call("walk_remaining") == 120, "viagem em curso")
	_at(119.0)
	check(state.call("walking") and not state.call("return_due_walk"), "um segundo antes: ainda viaja e nada liquida")
	check(state.call("walk_error", "park_loop") == "O Tiro já está passeando", "um passeio por vez")
	var coins: int = state.get("coins")
	_at(120.0)
	check(not state.call("walking"), "no instante de ready_at o Tiro já não está fora")
	check(state.call("return_due_walk"), "no instante de ready_at a viagem é liquidada")
	check(not state.call("return_due_walk") and not state.call("return_due_walk"), "liquidar de novo não faz nada")
	_at(5000.0)
	check(not state.call("return_due_walk"), "muito depois também é idempotente")
	check(_walk().current.is_empty() and _walk().has_baggage(), "viagem vira uma única bagagem")
	check(state.get("coins") - coins == int(_walk().pending_return.result.coins), "moedas pagas uma vez")
	check(_p().stat("walk") == 1 and _p().stat("walk:park_loop") == 1 and int(_walk().history.park_loop.count) == 1, "contadores e histórico uma vez")
	check(_p().stat("walk_item") == 0 and _p().stat("walk_item:stick") == 0, "contador de itens só anda quando os itens entram")
	check(returned_events == 1, "um resultado visual por viagem")
	check(int(_walk().pending_return.left.stick) == 5 and int(_walk().pending_return.left.ribbon) == 1, "primeira volta traz 5 gravetos e 1 fita congelados")
	check(not state.call("walking") and state.call("away_error") == "", "cuidados liberados")
	state.get("dog").needs["energy"] = 100.0
	db.get("walks").walks.park_loop.loot = before


# --- Salvar e recarregar em cada transição ---------------------------------------------

func _reload_at_every_transition() -> void:
	_fresh()
	var before := _fixed_table()
	check(state.call("start_walk", "park_loop") == "", "sai")
	_at(30.0)
	var preview: Dictionary = state.call("walk_loot")
	_json_roundtrip()
	check(state.call("walking") and state.call("walk_loot") == preview, "recarregar durante a viagem mantém o sorteio")
	# App fechado até depois da hora: carregar liquida UMA vez, com o mesmo sorteio da prévia.
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	_at(9000.0)
	var coins: int = state.get("coins")
	state.call("from_dict", saved)
	check(not state.call("walking") and _walk().has_baggage() and _walk().current.is_empty(), "carregar com a viagem vencida liquida")
	check(_walk().pending_return.result.items == preview.items, "sem segundo sorteio ao carregar")
	check(returned_events == 0 and state.call("walk_result_unseen"), "carregar não dispara comemoração; o cartão sai da marca salva")
	var paid: int = state.get("coins")
	check(paid > coins and _p().stat("walk") == 1, "efeitos aplicados ao carregar")
	_json_roundtrip()
	_json_roundtrip()
	check(state.get("coins") == paid and state.get("progress").stat("walk") == 1 and int(_walk().history.park_loop.count) == 1, "recarregar a bagagem não repete efeitos")
	check(state.call("walk_result_unseen"), "resultado ainda não visto sobrevive ao reload")
	state.call("mark_walk_result_shown")
	state.call("mark_walk_result_shown")
	check(not state.call("walk_result_unseen") and _walk().has_baggage(), "marcar visto não premia nem some com itens esperando")
	_json_roundtrip()
	check(not state.call("walk_result_unseen") and _walk().baggage_count() == 6, "visto persiste")
	var stored: Dictionary = state.call("claim_walk_baggage")
	check(int(stored.stick) == 5 and int(stored.ribbon) == 1 and not _walk().has_baggage(), "guardar tudo encerra a bagagem já vista")
	_json_roundtrip()
	check(not _walk().has_baggage() and state.get("inventory").count("stick") == 5, "estado final persiste")
	check(state.call("claim_walk_baggage").is_empty() and state.get("inventory").count("stick") == 5, "guardar de novo não repete")
	db.get("walks").walks.park_loop.loot = before


# --- Depósito cheio, um por um ---------------------------------------------------------

func _full_depots() -> void:
	for depot in DEPOTS:
		_fresh()
		var before := _fixed_table()
		var saved := _put_in_depot(depot, 4)
		_inv().add("stick", 4)
		check(state.call("storage_space", depot) == 0, depot + ": depósito cheio")
		_leave_and_return()
		check(not state.call("walking"), depot + ": o Tiro volta mesmo com a bagagem impossível de guardar")
		check(_p().stat("walk") == 1 and returned_events == 1, depot + ": passeio contado e resultado emitido")
		check(_inv().count("stick") == 4 and _inv().count("ribbon") == 0, depot + ": nada entrou no inventário")
		check(state.call("walk_baggage_error") != "" and str(state.call("walk_baggage_error")).contains(str(state.call("storage_name", depot))), depot + ": motivo cita o depósito: " + str(state.call("walk_baggage_error")))
		check(state.call("walk_baggage_depot") == depot, depot + ": destino do Ir")
		check(state.call("claim_walk_baggage").is_empty() and _walk().baggage_count() == 6, depot + ": guardar sem espaço preserva a bagagem")
		check(_p().stat("walk_item") == 0, depot + ": contador de itens parado")
		var other: String = state.call("start_walk", "park_loop")
		check(other != "" and other.contains("sem espaço") and not _walk().active(), depot + ": outro passeio bloqueado com o destino: " + other)
		# Cuidar do Tiro nunca depende da bagagem.
		state.call("set_sleeping", true)
		check(state.get("dog").sleeping, depot + ": Tiro dorme com a bagagem esperando")
		state.call("set_sleeping", false)
		check(not state.get("dog").sleeping, depot + ": Tiro acorda")
		check(state.call("bathe") == "" or _p().stat("bathe") >= 1, depot + ": banho funciona")
		# Abrir espaço aos poucos: recebe parcelas que cabem.
		_inv().remove("stick", 2)
		var part: Dictionary = state.call("claim_walk_baggage")
		check(part == {"stick": 2}, depot + ": primeira parcela: " + str(part))
		check(int(_walk().pending_return.left.stick) == 3 and int(_walk().pending_return.left.ribbon) == 1, depot + ": resto preservado")
		check(_p().stat("walk_item:stick") == 2 and _p().stat("walk_item") == 2, depot + ": contadores só do que entrou")
		check(state.call("claim_walk_baggage").is_empty() and _p().stat("walk_item") == 2, depot + ": repetir sem espaço não conta de novo")
		_inv().remove("stick", 4)
		var rest: Dictionary = state.call("claim_walk_baggage")
		check(rest == {"stick": 3, "ribbon": 1}, depot + ": segunda parcela: " + str(rest))
		check(_p().stat("walk_item") == 6 and _p().stat("walk_item:ribbon") == 1, depot + ": total contado uma vez")
		check(_inv().count("stick") == 5 - 2 + 2 + 0 or _inv().count("stick") >= 3, depot + ": itens no inventário")
		check(not state.call("walk_ready"), depot + ": nada mais esperando")
		check(state.call("start_walk", "park_loop") == "" or state.call("walk_error", "park_loop") != "", depot + ": passeio liberado depois de esvaziar (ou só energia)")
		_restore_depot(saved)
		db.get("walks").walks.park_loop.loot = before


func _partial_and_repeat() -> void:
	_fresh()
	var before := _fixed_table()
	var saved := _put_in_depot("chest", 6)
	_inv().add("stick", 4)
	_leave_and_return()
	var plan: Dictionary = state.call("walk_baggage_plan")
	check(plan.moved == {"stick": 2} and plan.blocked == "chest" and int(plan.item) == 0 or str(plan.item) == "stick", "plano mostra a parcela que cabe")
	var stored: Dictionary = state.call("claim_walk_baggage")
	check(stored == {"stick": 2} and _walk().baggage_count() == 4, "recebe só a parcela que cabe")
	_json_roundtrip()
	check(_walk().baggage_count() == 4 and state.get("progress").stat("walk_item") == 2, "recarregar entre parcelas mantém saldo e contadores")
	check(state.call("claim_walk_baggage").is_empty(), "repetir sem espaço não faz nada")
	_inv().remove("stick", 6)
	check(state.call("claim_walk_baggage") == {"stick": 3, "ribbon": 1}, "o resto chega depois")
	check(state.get("progress").stat("walk_item") == 6, "soma final sem duplicar")
	_restore_depot(saved)
	db.get("walks").walks.park_loop.loot = before


# --- Raro e lendário garantidos --------------------------------------------------------

func _rare_and_legendary() -> void:
	_fresh()
	var before := _fixed_table()
	_p().owned["petshop"] = true
	_p().count("walk", 20)
	var saved := _put_in_depot("chest", 1)
	state.get("inventory").add("stick", 1)
	_walk().pity["park_loop"] = 5
	_walk().pity["legendary"] = 29
	_leave_and_return()
	check(not state.call("walking") and _p().collection.has("plaid_bow") and _p().stat("walk_rare") == 1, "raro garantido entra na coleção na volta, não na retirada")
	check(_p().collection.has("sponge_hat") and _p().stat("walk_legendary") == 1, "lendário garantido na volta")
	check(int(_walk().pity.park_loop) == 0 and int(_walk().pity.legendary) == 0, "garantias zeradas uma vez")
	var view: Dictionary = state.call("walk_result_view")
	check(view.rare == "plaid_bow" and view.legendary == "sponge_hat" and not (view.collections as Array).is_empty(), "resultado congelado traz os dois")
	_json_roundtrip()
	check(_p().stat("walk_rare") == 1 and state.get("progress").stat("walk_legendary") == 1, "recarregar não repete contadores")
	state.get("inventory").remove("stick", 1)
	state.call("claim_walk_baggage")
	check(state.get("progress").stat("walk_rare") == 1 and int(_walk().pity.park_loop) == 0, "retirar a bagagem não repaga o raro")
	# Sem raro: a garantia sobe uma vez, ao voltar, e não ao guardar.
	db.get("progression").storage["chest"]["prebuild_capacity"] = 100
	state.call("claim_walk_baggage")
	state.get("dog").needs["energy"] = 100.0
	state.call("mark_walk_result_shown")
	_walk().pity["park_loop"] = 0
	_at(2000.0)
	var pity_before: int = int(_walk().pity.park_loop)
	state.get("dog").needs["energy"] = 100.0
	state.get("dog").updated_at = state.call("now")
	_leave_and_return()
	var pity_after: int = int(_walk().pity.park_loop)
	check(pity_after == pity_before + 1, "garantia anda uma vez por volta")
	_restore_depot(saved)
	db.get("walks").walks.park_loop.loot = before


# --- O Tiro: dormir, cuidados e tempo --------------------------------------------------

func _dog_timeline() -> void:
	_fresh()
	var rate := float(db.get("needs").happiness.decay_per_hour)
	state.get("dog").needs["happiness"] = 95.0
	state.get("dog").updated_at = T0
	var def: Dictionary = db.get("walks").walks.park_loop
	check(state.call("start_walk", "park_loop") == "", "sai")
	var gain := float(def.needs.happiness)
	# O jogador só volta 3 h depois: os efeitos entram no instante da volta, não na hora da abertura.
	_at(3.0 * 3600.0)
	var coins: int = state.get("coins")
	state.call("return_due_walk")
	var at_return := clampf(95.0 - rate * (120.0 / 3600.0) + gain, 0.0, 100.0)
	var expected := clampf(at_return - rate * ((3.0 * 3600.0 - 120.0) / 3600.0), 0.0, 100.0)
	var naive := clampf(clampf(95.0 - rate * 3.0, 0.0, 100.0) + gain, 0.0, 100.0)
	var actual: float = state.get("dog").get_need("happiness", state.call("now"))
	check(absf(actual - expected) < 0.05, "efeitos entram em ready_at e o resto do tempo segue normal (%.2f vs %.2f)" % [actual, expected])
	check(absf(expected - naive) > 1.0, "a hora da abertura daria outro valor (%.2f)" % naive)
	check(float(_walk().pending_return.returned_at) == T0 + 120.0, "retorno gravado no instante certo")
	check(state.get("coins") > coins, "moedas pagas")
	# Dormir e acordar logo depois da volta.
	state.get("dog").needs["energy"] = 20.0
	state.get("dog").updated_at = state.call("now")
	state.call("set_sleeping", true)
	check(state.get("dog").sleeping, "dorme depois da volta")
	_at(3.0 * 3600.0 + 3600.0)
	state.call("set_sleeping", false)
	check(not state.get("dog").sleeping and state.get("dog").get_need("energy", state.call("now")) > 20.0, "acorda com energia recuperada")
	check(_walk().has_baggage(), "bagagem não atrapalhou o sono")


# --- Saves antigos ----------------------------------------------------------------------

func _compat_and_cancel() -> void:
	_fresh()
	var energy_start: float = state.get("dog").get_need("energy", T0)
	check(state.call("start_walk", "park_loop") == "", "sai")
	check(state.call("collect_walk_error") == "O passeio ainda não terminou" and state.call("collect_walk").is_empty(), "wrapper: antes da hora não faz nada")
	_at(60.0)
	check(state.call("cancel_walk") == "" and not _walk().active() and not _walk().has_baggage(), "chamar de volta durante a viagem")
	check(state.call("walk_error", "park_loop") == "", "livre para sair de novo")
	state.get("dog").updated_at = state.call("now")
	state.get("dog").needs["energy"] = 100.0
	_fresh()
	check(state.call("start_walk", "park_loop") == "", "sai de novo")
	_at(500.0)
	var energy_before: float = state.get("dog").get_need("energy", state.call("now"))
	var view: Dictionary = state.call("collect_walk")
	check(not view.is_empty() and view.id == "park_loop", "wrapper liquida e guarda")
	var energy_after: float = state.get("dog").get_need("energy", state.call("now"))
	check(state.call("cancel_walk") == "O Tiro já voltou", "cancelar depois de voltar é recusado")
	check(absf(state.get("dog").get_need("energy", state.call("now")) - energy_after) < 0.01 and energy_after <= energy_before + 0.5, "sem devolver energia")
	check(state.get("progress").stat("walk") == 1 and returned_events == 1, "nada em dobro")
	check(energy_start > 0.0, "estado inicial lido")


# --- Superfícies: contadores, boas-vindas, ações ----------------------------------------------

func _surfaces() -> void:
	_fresh()
	var before := _fixed_table()
	var saved := _put_in_depot("chest", 1)
	state.get("inventory").add("stick", 1)
	_leave_and_return()
	var counts: Dictionary = state.call("world_ready_counts")
	var park_with := int(counts.get("park", 0))
	check(park_with >= 1, "Mapa conta a bagagem na Praça: " + str(counts) + " pronto=" + str(state.call("walk_ready")))
	var lines: Array = state.call("welcome_ready_lines")
	check(lines.any(func(line: Dictionary) -> bool: return line.kind == "walk"), "boas-vindas lembra a bagagem")
	var actions: Array = state.call("available_actions")
	check(actions.any(func(action: Dictionary) -> bool: return action.kind == "walk_ready"), "ações disponíveis oferecem guardar")
	db.get("progression").storage["chest"]["prebuild_capacity"] = 100
	state.call("claim_walk_baggage")
	state.call("mark_walk_result_shown")
	check(int(state.call("world_ready_counts").get("park", 0)) == park_with - 1, "contador some depois de guardar")
	check(not (state.call("welcome_ready_lines") as Array).any(func(line: Dictionary) -> bool: return line.kind == "walk"), "boas-vindas some")
	_restore_depot(saved)
	db.get("walks").walks.park_loop.loot = before
