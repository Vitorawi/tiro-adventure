extends SceneTree
## Etapa 04 da economia R1: ausência protegida (metade da taxa, teto de 8 h, pisos) sem apagar cuidados.
## --headless --path game -s res://tests/absence_test.gd
## Relógio injetado (friend_clock) e estado sintético; nunca usa o save do jogador.

const T0 := 1791936000.0
const H := 3600.0

var state: Node
var db: Node
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Ausência: " + message)


func near(a: float, b: float, message: String) -> void:
	check(absf(a - b) < 0.01, "%s (%.2f != %.2f)" % [message, a, b])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/friend_clock.gd"))
	_matrix()
	_floors()
	_sleep()
	_online_intact()
	_reload_and_focus()
	_crash_estimate()
	_walk_segments()
	_clock_back()
	_slot_and_visits()
	_dev_time()
	print("ABSENCE TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# --- Utilitários -------------------------------------------------------------------

func _fresh() -> void:
	state.set("test_time", T0)
	state.set("unlimited_storage", false)
	state.call("reset")
	_full()


func _full() -> void:
	var dog: RefCounted = state.get("dog")
	for id: String in db.get("needs"):
		dog.needs[id] = 100.0
	dog.updated_at = T0
	dog.away_since = 0.0
	dog.sleeping = false


func _at(seconds: float) -> void:
	state.set("test_time", T0 + seconds)


func _need(id: String) -> float:
	return state.get("dog").get_need(id, state.call("now"))


func _away(hours: float) -> void:
	state.call("begin_absence", T0)
	_at(hours * H)
	state.call("end_absence")


func _roundtrip() -> void:
	state.call("from_dict", JSON.parse_string(JSON.stringify(state.call("to_dict"))))


# --- Casos ---------------------------------------------------------------------------

func _matrix() -> void:
	for hours: float in [1.0, 8.0, 24.0, 72.0]:
		_fresh()
		_away(hours)
		var protected := minf(hours, 8.0)
		near(_need("hunger"), 100.0 - 8.0 * 0.5 * protected, "fome %s h" % hours)
		near(_need("happiness"), 100.0 - 5.0 * 0.5 * protected, "alegria %s h" % hours)
		near(_need("energy"), 100.0 - 6.0 * 0.5 * protected, "energia %s h" % hours)
		near(_need("hygiene"), 100.0 - 3.0 * 0.5 * protected, "higiene %s h" % hours)
		check(float(state.get("dog").away_since) == 0.0, "a ausência termina ao voltar (%s h)" % hours)
	_fresh()
	_away(8.0)
	near(_need("hunger"), 68.0, "8 h: fome 68")
	near(_need("happiness"), 80.0, "8 h: alegria 80")
	near(_need("energy"), 76.0, "8 h: energia 76")
	near(_need("hygiene"), 88.0, "8 h: higiene 88")


func _floors() -> void:
	_fresh()
	state.get("dog").needs["hunger"] = 30.0
	_away(24.0)
	near(_need("hunger"), 25.0, "fome 30 para no piso 25")
	_fresh()
	state.get("dog").needs["hunger"] = 10.0
	state.get("dog").needs["energy"] = 0.0
	_away(48.0)
	near(_need("hunger"), 10.0, "fome 10 não é curada pelo piso")
	near(_need("energy"), 0.0, "energia 0 acordado continua 0 (sem energia grátis)")
	_fresh()
	state.get("dog").needs["happiness"] = 36.0
	state.get("dog").needs["hygiene"] = 31.0
	_away(24.0)
	near(_need("happiness"), 35.0, "alegria para no piso 35")
	near(_need("hygiene"), 30.0, "higiene para no piso 30")


func _sleep() -> void:
	_fresh()
	state.get("dog").needs["energy"] = 0.0
	state.get("dog").sleeping = true
	state.call("begin_absence", T0)
	_at(8.0 * H)
	near(_need("energy"), 100.0, "sono 8 h recupera até 100")
	check(bool(state.get("dog").sleeping), "durante a ausência o Tiro não acorda")
	state.call("end_absence")
	check(not bool(state.get("dog").sleeping), "ao voltar com energia 100 ele acorda")
	_fresh()
	state.get("dog").needs["energy"] = 10.0
	state.get("dog").sleeping = true
	_away(24.0)
	near(_need("energy"), 100.0, "sono 24 h termina com energia 100 (sem cair depois)")
	near(_need("hunger"), 68.0, "sono 24 h: fome protegida")
	near(_need("happiness"), 80.0, "sono 24 h: alegria protegida")
	near(_need("hygiene"), 88.0, "sono 24 h: higiene protegida")
	# Dormindo e voltando depois de pouco tempo: sobe 40/h, sem decair a energia no mesmo trecho.
	_fresh()
	state.get("dog").needs["energy"] = 20.0
	state.get("dog").sleeping = true
	_away(1.0)
	near(_need("energy"), 60.0, "sono 1 h: +40")


func _online_intact() -> void:
	_fresh()
	_at(8.0 * H)
	near(_need("hunger"), 36.0, "online 8 h: fome na taxa cheia")
	near(_need("energy"), 52.0, "online 8 h: energia na taxa cheia")
	_fresh()
	state.get("dog").needs["hunger"] = 20.0
	state.call("begin_absence", T0)
	_at(2.0 * H)
	state.call("end_absence")
	# Cuidados continuam úteis logo depois da volta (taxas online).
	state.get("dog").apply({"hunger": 30.0}, state.call("now"))
	near(_need("hunger"), 50.0, "barra abaixo do piso fica como estava e alimentar soma")
	_at(3.0 * H)
	near(_need("hunger"), 42.0, "depois da volta a taxa online é a cheia")


func _reload_and_focus() -> void:
	# Foco+pausa+fechar: a ausência abre uma vez e o teto de 8 h não reinicia.
	_fresh()
	state.call("begin_absence", T0)
	state.call("begin_absence", T0 + 3600.0)
	state.call("begin_absence", T0 + 7200.0)
	near(float(state.get("dog").away_since), T0, "begin_absence repetido não reinicia")
	_at(8.0 * H)
	_roundtrip()
	_roundtrip()
	near(float(state.get("dog").away_since), T0, "a ausência sobrevive a recarregar")
	near(_need("hunger"), 68.0, "recarregar durante a ausência não muda o valor")
	state.call("end_absence")
	var after := _need("hunger")
	near(after, 68.0, "voltar projeta 8 h")
	check(not bool(state.call("end_absence")), "encerrar de novo não faz nada")
	for i in 3:
		_roundtrip()
		check(not bool(state.call("end_absence")), "recarregar depois de voltar não abre ausência")
	near(_need("hunger"), after, "recarregar não reduz de novo")
	_at(8.0 * H + 60.0)
	near(_need("hunger"), after - 8.0 / 60.0, "voltou ao relógio online")
	# Recarregar sem ausência não cura nada.
	_fresh()
	state.get("dog").needs["hunger"] = 40.0
	_roundtrip()
	near(_need("hunger"), 40.0, "recarregar online não cura")


func _crash_estimate() -> void:
	# Fechamento abrupto: o último instante ativo gravado vira o início estimado da ausência.
	_fresh()
	state.get("friend_state").last_active_at = T0 + 1.0 * H
	_at(24.0 * H)
	_roundtrip()
	near(float(state.get("dog").away_since), T0 + H, "início estimado pelo último instante ativo")
	state.call("end_absence")
	near(_need("hunger"), 100.0 - 8.0 - 32.0, "1 h online + 8 h protegidas (fome 60)")
	# Salvar de novo (heartbeat) com ausência aberta não a reinicia.
	_fresh()
	state.call("begin_absence", T0)
	_at(2.0 * H)
	state.get("friend_state").last_active_at = T0
	_roundtrip()
	near(float(state.get("dog").away_since), T0, "autosave não mexe no início")


func _walk_segments() -> void:
	_fresh()
	state.get("progress").claimed_quests["main_2_order"] = true
	state.get("progress").claimed_quests["nina_meet"] = true
	state.get("progress").claimed_quests["nina_walk"] = true
	check(state.call("start_walk", "park_loop") == "", "passeio começa")
	state.get("walk_state").current["ready_at"] = T0 + 1800.0
	state.get("dog").needs["energy"] = 100.0
	state.call("begin_absence", T0)
	_at(24.0 * H)
	state.call("return_due_walk", false)
	check(not state.get("walk_state").active(), "passeio liquidado no retorno")
	state.call("end_absence")
	# Higiene: 100 -> 99,25 em 30 min, -10 do passeio, depois 7,5 h de proteção (1,5/h): 78. Soma total 8 h.
	near(_need("hygiene"), 78.0, "passeio de 30 min: 8 h de proteção no total, não 9")
	# Alegria: 98,75 + 20 (teto 100) e depois 7,5 h x 2,5 = 81,25.
	near(_need("happiness"), 81.25, "efeitos do passeio entram em ready_at e a ausência continua")
	# Recarregar no meio: nada se aplica duas vezes.
	var snapshot: float = _need("hygiene")
	_roundtrip()
	state.call("end_absence")
	near(_need("hygiene"), snapshot, "recarregar depois do passeio não repete")


func _clock_back() -> void:
	_fresh()
	state.call("begin_absence", T0 + H)
	_at(0.0)
	near(_need("hunger"), 100.0, "relógio antes do início não perde")
	state.call("end_absence")
	near(_need("hunger"), 100.0, "voltar com o relógio para trás não ganha nem perde")
	near(_need("energy"), 100.0, "nem energia")
	_fresh()
	state.get("dog").needs["hunger"] = 50.0
	state.get("dog").updated_at = T0 + 2.0 * H
	near(_need("hunger"), 50.0, "atualização no futuro não vira tempo")


func _slot_and_visits() -> void:
	# Um slot parado evolui como offline ao abrir, sem fabricar visita nem presente.
	_fresh()
	state.get("friend_state").last_active_at = T0
	_at(24.0 * H)
	_roundtrip()
	state.call("end_absence")
	near(_need("hunger"), 68.0, "slot parado 24 h: proteção, não abandono online")
	check(not bool(state.get("friend_state").entry("pipoca").visit_pending), "carregar não cria visita")
	check(int(state.get("coins")) == int(db.get("start").get("coins", 0)), "carregar não paga nada")


func _dev_time() -> void:
	# A ferramenta DEV de viagem no tempo é uma ausência protegida (e termina sozinha).
	_fresh()
	state.call("dev_advance_time", 8.0 * H)
	near(_need("hunger"), 68.0, "dev_advance_time usa a proteção")
	check(float(state.get("dog").away_since) == 0.0, "dev_advance_time não deixa ausência aberta")
