extends SceneTree
## Cozinhar junto (plano primeira_semana, E04): regras puras (brilhos, estrelas, corte de tempo), sair no meio sem gastar,
## Pular, os três passos por toque real (eventos de mouse empurrados pela viewport), estrelas 1, 2 e 3 e o tempo cortado
## gravado no lote, a tela Prato pronto (Dar ao Tiro serve na hora; Guardar deixa na fila), Gororoba sem minigame,
## Vibrar e os botões da cozinha.
##   godot --headless --path game -s res://tests/cook_together_test.gd

var failures := 0
var state: Node
var events: Node
var db: Node
var main: Control
var rules: Script
var cook: Script
var together: Script
var haptics: Script
var toasts: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("COOK TOGETHER: " + message)


func frames(count: int = 3) -> void:
	for i in count:
		await process_frame


func count(item: String) -> int:
	return int(state.get("inventory").call("count", item))


func give(item: String, amount: int) -> void:
	state.get("inventory").call("add", item, amount)
	events.state_changed.emit()


func queue() -> Array:
	return state.call("station", "stove").queue


func game() -> Control:
	return together.call("current") as Control


func reset_world(day: int = 1) -> void:
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.set("coins", 5000)
	state.call("dev_week_goto", day)
	state.call("dev_week_hour", 19)  # o Inventar do dia 1 abre no jantar
	for id: String in state.get("stations"):
		state.get("stations")[id].queue.clear()
	state.get("inventory").call("from_dict", {})
	state.set("animals", {})
	toasts.clear()


# --- Toque real -------------------------------------------------------------------------------

func at(point: Vector2) -> Vector2:
	return (game().call("to_screen", point) as Vector2) + game().global_position


func press(point: Vector2) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = at(point)
	click.global_position = click.position
	click.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(click)


func release(point: Vector2) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = false
	click.position = at(point)
	click.global_position = click.position
	root.push_input(click)


var _last := Vector2.ZERO


func move(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at(point)
	motion.global_position = motion.position
	motion.relative = motion.position - _last
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	_last = motion.position
	root.push_input(motion)


## Um corte: desliza de cima para baixo em x (a linha está em `guide_x`; `off` = quanto errar).
func cut(off: float = 0.0) -> void:
	var x: float = float(game().call("guide_x")) + off
	press(Vector2(x, 280))
	move(Vector2(x, 300))
	move(Vector2(x, 360))
	release(Vector2(x, 360))


func do_picar(off: float) -> void:
	var guard := 0
	while str(game().get("phase")) == "picar" and guard < 20:
		cut(off)
		guard += 1
	check(str(game().get("phase")) == "pause_picar", "os cortes fecham o passo (%s)" % game().get("phase"))
	game().call("tick", 0.6)
	check(str(game().get("phase")) == "mexer", "depois do Picar vem o Mexer (%s)" % game().get("phase"))


## Mexer: `idle` segundos parado depois do primeiro toque (anel não anda) e depois gira em velocidade boa até encher.
func do_mexer(idle: float = 0.0) -> void:
	var center := Vector2(180, 424)
	var angle := -PI / 2.0
	press(center + Vector2(cos(angle), sin(angle)) * 150.0)
	move(center + Vector2(cos(angle), sin(angle)) * 150.0)
	var waited := 0.0
	while waited < idle:
		game().call("tick", 0.1)
		waited += 0.1
	check(idle == 0.0 or float(game().get("ring")) == 0.0, "devagar demais o anel não anda (%s)" % game().get("ring"))
	var guard := 0
	while str(game().get("phase")) == "mexer" and guard < 400:
		angle += 0.3  # 3 rad/s com passo de 0,1 s: velocidade boa
		move(center + Vector2(cos(angle), sin(angle)) * 150.0)
		game().call("tick", 0.1)
		guard += 1
	release(center)
	check(str(game().get("phase")) == "pause_mexer", "o anel cheio fecha o passo (%s)" % game().get("phase"))
	game().call("tick", 0.6)
	check(str(game().get("phase")) == "servir", "depois do Mexer vem o Servir (%s)" % game().get("phase"))


func do_servir(misses: int) -> void:
	var pot := Vector2(99, 404)
	var bowl := Vector2(272, 566)
	for scoop in 2:
		for miss in misses:
			press(pot)
			move(Vector2(60, 700))
			release(Vector2(60, 700))  # longe do anel: a concha volta
		press(pot)
		move(bowl)
		release(bowl)
	check(bool(game().get("heart_phase")), "duas conchas servidas: vem o coração")
	press(Vector2(180, 690))
	move(bowl)
	release(bowl)
	check(str(game().get("phase")) == "pause_servir", "o coração fecha o prato (%s)" % game().get("phase"))
	game().call("tick", 0.6)


func quiet_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])


func open_game(items: Array, chosen: Dictionary, type: String) -> Control:
	quiet_modals()
	var spec := {"name": "Prato", "output": "", "items": items,
		"check": func() -> String: return state.call("cook_invented_error", chosen, type),
		"cook": func(stars: int, together_flag: bool) -> String: return state.call("cook_invented", chosen, type, stars, together_flag)}
	together.call("open", main, spec)
	await frames(2)
	return game()


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	events = root.get_node("Events")
	db = root.get_node("Database")
	rules = load("res://scripts/state/cook_rules.gd")
	cook = load("res://scripts/ui/cook_panel.gd")
	together = load("res://scripts/ui/cook_together.gd")
	haptics = load("res://scripts/ui/haptics.gd")
	Motion.reduced = true
	events.toast_requested.connect(func(text: String) -> void: toasts.append(text))
	check((db.call("cooking_problems") as Array).is_empty(), "cooking.json coerente: %s" % [db.call("cooking_problems")])
	_pure_rules()
	reset_world()
	root.size = Vector2i(360, 780)  # toque real no tamanho do celular
	await frames(2)
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await frames(4)
	quiet_modals()
	await _cancel_and_skip()
	await _perfect_run()
	await _mixed_runs()
	await _keep_and_gororoba()
	await _buttons()
	print("COOK TOGETHER: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# --- Regras puras -----------------------------------------------------------------------------

func _pure_rules() -> void:
	check(int(rules.call("cut_brilho", 5.0)) == 3 and int(rules.call("cut_brilho", 20.0)) == 2 and int(rules.call("cut_brilho", 60.0)) == 1, "brilho do corte pela distância da linha")
	check(int(rules.call("average_brilho", [3, 3, 2])) == 3 and int(rules.call("average_brilho", [3, 2, 2])) == 2 and int(rules.call("average_brilho", [1, 2, 1])) == 1, "média dos brilhos")
	check(int(rules.call("stir_brilho", 8.0)) == 3 and int(rules.call("stir_brilho", 10.0)) == 3 and int(rules.call("stir_brilho", 12.0)) == 2 and int(rules.call("stir_brilho", 20.0)) == 1, "brilho do Mexer pelo tempo")
	check(str(rules.call("stir_zone", 0.5)) == "slow" and str(rules.call("stir_zone", 3.0)) == "good" and str(rules.call("stir_zone", 9.0)) == "fast", "zonas de velocidade do giro")
	check(int(rules.call("serve_brilho", 10.0, 0)) == 3 and int(rules.call("serve_brilho", 50.0, 0)) == 2 and int(rules.call("serve_brilho", 10.0, 1)) == 2 and int(rules.call("serve_brilho", 10.0, 5)) == 1 and int(rules.call("serve_brilho", 100.0, 0)) == 0, "brilho da concha (fora do anel = 0, tentativa errada tira 1)")
	var expected := {3: 1, 4: 1, 5: 2, 6: 2, 7: 2, 8: 3, 9: 3}
	for total: int in expected:
		check(int(rules.call("stars_for", total)) == int(expected[total]), "soma %d = %d estrela(s)" % [total, expected[total]])
	check(is_equal_approx(float(rules.call("time_cut", 1)), 0.25) and is_equal_approx(float(rules.call("time_cut", 2)), 0.5) and is_equal_approx(float(rules.call("time_cut", 3)), 0.75), "cada estrela corta 25%, 50%, 75%")
	check(is_equal_approx(float(rules.call("time_factor", 3)), 0.25), "3 estrelas deixam 25% do tempo")


# --- Sair no meio e Pular ----------------------------------------------------------------------

func _cancel_and_skip() -> void:
	reset_world()
	give("carrot", 2)
	give("potato", 2)
	var chosen := {"carrot": 1, "potato": 1}
	var playing := await open_game(["carrot", "potato"], chosen, "papinha")
	check(playing != null and str(playing.get("phase")) == "picar", "o minigame abre no Picar")
	check(playing.find_child("SkipButton", true, false) != null and playing.find_child("QuitButton", true, false) != null, "tem Pular e Sair")
	var skip_button := playing.find_child("SkipButton", true, false) as Control
	check(skip_button.size.x >= 44.0 and skip_button.size.y >= 44.0, "Pular tem alvo de toque ≥ 44 (%s)" % skip_button.size)
	check(count("carrot") == 2 and count("potato") == 2 and queue().is_empty(), "abrir não gasta nada")
	cut()
	cut()
	check(int(playing.get("_cuts_done")) == 2, "dois cortes por toque real (%s)" % playing.get("_cuts_done"))
	check(count("carrot") == 2 and count("potato") == 2 and queue().is_empty(), "no meio do Picar nada foi gasto")
	playing.call("cancel")
	await frames(2)
	check(game() == null and count("carrot") == 2 and queue().is_empty(), "sair no meio não gasta ingredientes nem entra na fila")
	# Esc também sai.
	playing = await open_game(["carrot", "potato"], chosen, "papinha")
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	root.push_input(key)
	await frames(2)
	check(game() == null and queue().is_empty(), "Esc sai sem gastar")
	# Pular: cozinha como o botão (1 estrela, tempo cheio).
	playing = await open_game(["carrot", "potato"], chosen, "papinha")
	playing.call("skip")
	await frames(2)
	check(game() == null and queue().size() == 1 and str(queue()[0].recipe) == "puppy_mash", "Pular põe a papinha na fila")
	check(count("carrot") == 1 and count("potato") == 1, "Pular gasta os ingredientes (1 prato)")
	check(int(state.call("recipe_stars", "puppy_mash")) == 1, "Pular sai com 1 estrela")
	check(float(db.call("entry_seconds", queue()[0])) == float(db.get("recipes")["puppy_mash"].seconds), "Pular usa o tempo cheio da receita")
	# Sem ingrediente o minigame nem abre e o motivo vira aviso.
	state.get("inventory").call("from_dict", {})
	toasts.clear()
	together.call("open", main, {"items": ["carrot"], "check": func() -> String: return state.call("cook_invented_error", {"carrot": 1, "potato": 1}, "papinha"), "cook": func(_s: int, _t: bool) -> String: return ""})
	check(game() == null and toasts.size() == 1, "sem ingrediente o minigame não abre e avisa (%s)" % [toasts])


# --- Os três passos, 3 estrelas ----------------------------------------------------------------

func _perfect_run() -> void:
	reset_world()
	give("carrot", 2)
	give("potato", 2)
	var chosen := {"carrot": 1, "potato": 1}
	var playing := await open_game(["carrot", "potato"], chosen, "papinha")
	haptics.set("calls", [] as Array[int])
	cut()
	check(not (haptics.get("calls") as Array).is_empty(), "Vibrar: cada brilho dá um toque leve")
	haptics.set("enabled", false)
	haptics.set("calls", [] as Array[int])
	cut()
	check((haptics.get("calls") as Array).is_empty(), "Vibrar desligado não vibra")
	haptics.set("enabled", true)
	# O Picar tem 6 cortes no total (3 por ingrediente); o passo só fecha com todos.
	check(int(playing.get("_cuts_total")) == 6, "6 cortes no total (%s)" % playing.get("_cuts_total"))
	await do_picar(0.0)
	check(count("carrot") == 2 and queue().is_empty(), "antes do fim do Servir nada foi gasto")
	await do_mexer()
	await do_servir(0)
	await frames(2)
	check(str(playing.get("phase")) == "result", "depois do Servir vem o Prato pronto (%s)" % playing.get("phase"))
	check((playing.get("brilhos") as Array) == [3, 3, 3], "três passos perfeitos: 3 brilhos cada (%s)" % [playing.get("brilhos")])
	check(count("carrot") == 1 and count("potato") == 1 and queue().size() == 1, "ao fechar o Servir os ingredientes saíram e o lote entrou na fila")
	var entry: Dictionary = queue()[0]
	var full := float(db.get("recipes")["puppy_mash"].seconds)
	check(float(db.call("entry_seconds", entry)) == full * 0.25 and float(entry.job.seconds) == full * 0.25, "3 estrelas cortam 75%% do tempo e o lote guarda (%s de %s)" % [db.call("entry_seconds", entry), full])
	check(int(state.call("recipe_stars", "puppy_mash")) == 3, "a receita fica com 3 estrelas")
	var give_button := playing.find_child("GiveToTiro", true, false) as Button
	var keep_button := playing.find_child("KeepDish", true, false) as Button
	check(give_button != null and keep_button != null, "Prato pronto tem Dar ao Tiro e Guardar")
	var stars := playing.find_child("ResultStars", true, false)
	check(stars != null and int(stars.get_meta("count")) == 3, "o cartão mostra 3 estrelas")
	var chip := playing.find_child("TimeChip", true, false)
	check(chip != null and _texts(chip).any(func(t: String) -> bool: return t.contains("75")), "chip do tempo cortado (−75%%): %s" % [_texts(chip) if chip != null else []])
	# Dar ao Tiro: recolhe e usa a tigela, inclusive com Senta aprendido.
	state.call("dev_week_goto", 3)
	state.call("dev_week_hour", 12)
	state.get("progress").tricks["sit"] = true
	state.get("progress").stats["trick:sit"] = 3
	var fed_before: int = int(state.get("progress").call("stat", "feed:puppy_mash"))
	give_button.pressed.emit()
	await frames(2)
	var skip := main.find_child("MealTrickSkip", true, false) as Button
	check(skip != null and count("puppy_mash") == 1, "prato pronto também abre o pedido e espera para servir")
	if skip != null:
		skip.pressed.emit()
		await frames(2)
	check(queue().is_empty() and count("puppy_mash") == 0, "Dar ao Tiro: o lote saiu da fila na hora e foi comido")
	check(int(state.get("progress").call("stat", "feed:puppy_mash")) == fed_before + 1, "o Tiro comeu a papinha")
	check(game() == null, "o minigame fecha depois de dar")
	check(main.get("_current_screen") == &"pet", "abre a tela do Tiro")


func _texts(node: Node) -> Array[String]:
	var result: Array[String] = []
	for label in node.find_children("*", "Label", true, false):
		result.append((label as Label).text)
	return result


# --- 1 e 2 estrelas, retry da concha ------------------------------------------------------------

func _mixed_runs() -> void:
	# 1 estrela: cortes tortos (60 de erro), Mexer parado 12 s antes de girar e duas conchas erradas por vez.
	reset_world()
	give("carrot", 2)
	give("potato", 2)
	var chosen := {"carrot": 1, "potato": 1}
	var playing := await open_game(["carrot", "potato"], chosen, "papinha")
	await do_picar(-70.0)
	await do_mexer(12.0)
	await do_servir(2)
	await frames(2)
	check((playing.get("brilhos") as Array) == [1, 1, 1], "tudo torto, parado e errado: 1 brilho cada (%s)" % [playing.get("brilhos")])
	var one: Dictionary = queue()[0]
	var full := float(db.get("recipes")["puppy_mash"].seconds)
	check(float(db.call("entry_seconds", one)) == full * 0.75, "1 estrela corta 25%% (%s)" % db.call("entry_seconds", one))
	check(int(state.call("recipe_stars", "puppy_mash")) == 1, "1 estrela na receita")
	playing.call("cancel")
	await frames(2)
	# 2 estrelas num prato do motor: picar perfeito (3) + Mexer 1 + Servir 1 = 5.
	reset_world(2)
	give("carrot", 2)
	give("corn", 2)
	var corn := {"carrot": 1, "corn": 1}
	playing = await open_game(["carrot", "corn"], corn, "papinha")
	await do_picar(0.0)
	await do_mexer(12.0)
	await do_servir(2)
	await frames(2)
	check(int(playing.get("_misses")) == 0 and (playing.get("brilhos") as Array) == [3, 1, 1], "perfeito + 1 + 1 (%s)" % [playing.get("brilhos")])
	var entry: Dictionary = queue()[0]
	check(str(entry.job.output) == "dish_papinha_cenoura+milho_2", "5 brilhos = 2 estrelas no prato do motor (%s)" % entry.job.output)
	check(float(entry.job.seconds) == 300.0 * 0.5 and int(state.call("dish_stars", "papinha", ["cenoura", "milho"])) == 2, "2 estrelas cortam 50%% e viram a melhor estrela do prato")
	playing.call("cancel")
	await frames(2)
	# Mexer rápido demais: respinga, o anel não anda e nada queima.
	reset_world()
	give("carrot", 2)
	give("potato", 2)
	playing = await open_game(["carrot", "potato"], chosen, "papinha")
	await do_picar(0.0)
	var center := Vector2(180, 424)
	press(center + Vector2(0, -150))
	var angle := -PI / 2.0
	for i in 12:
		angle += 0.9  # 9 rad/s: rápido demais
		move(center + Vector2(cos(angle), sin(angle)) * 150.0)
		playing.call("tick", 0.1)
	check(str(playing.get("stir_zone_now")) == "fast" and float(playing.get("ring")) == 0.0, "rápido demais: zona fast e o anel não anda (%s)" % playing.get("ring"))
	release(center)
	check(count("carrot") == 2 and queue().is_empty(), "nada queima nem se gasta no meio")
	playing.call("cancel")
	await frames(2)


# --- Guardar, Gororoba ----------------------------------------------------------------------------

func _keep_and_gororoba() -> void:
	reset_world()
	give("carrot", 2)
	give("potato", 2)
	var chosen := {"carrot": 1, "potato": 1}
	var playing := await open_game(["carrot", "potato"], chosen, "papinha")
	await do_picar(0.0)
	await do_mexer()
	await do_servir(0)
	await frames(2)
	(playing.find_child("KeepDish", true, false) as Button).pressed.emit()
	await frames(2)
	check(game() == null and queue().size() == 1 and count("puppy_mash") == 0, "Guardar deixa o lote na fila com o tempo cortado")
	check(float(state.call("station", "stove").queue[0].job.seconds) == float(db.get("recipes")["puppy_mash"].seconds) * 0.25, "o tempo cortado fica no lote")
	# Gororoba: cozinha direto pelo botão da aba Inventar, sem minigame.
	reset_world()
	give("carrot", 2)
	give("apple", 2)
	var house := main.find_child("World_house", true, false) as Control
	main.call("_on_world_requested", "house", "")
	main.call("show_screen", &"map")
	await frames(4)
	quiet_modals()
	house = main.find_child("World_house", true, false) as Control
	house.call("close_tray")
	house.call("open_station_tray", "stove", "")
	await frames(4)
	cook.set("invent_mode", true)
	var panel := cook.call("current") as Control
	check(panel != null, "painel do fogão aberto")
	if panel == null:
		return
	panel.call("_set_mode", true)
	var view := panel.find_child("InventView", true, false)
	view.call("set_slot", 0, "carrot")
	view.call("set_slot", 1, "apple")
	await frames(2)
	check(str(panel.find_child("InvCard", true, false).get_meta("state")) == "gororoba", "cenoura + maçã na papinha: Gororoba")
	var button := panel.find_child("InvCookButton", true, false) as Control
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = button.size / 2.0
		button.gui_input.emit(click)
	await frames(2)
	check(game() == null, "Gororoba não abre o minigame")
	check(queue().size() == 1 and str(db.call("entry_output", queue()[0])) == "gororoba", "Gororoba entra direto na fila")
	panel.call("close", true)
	await frames(2)


# --- Botões da cozinha ---------------------------------------------------------------------------

func _buttons() -> void:
	reset_world()
	give("carrot", 2)
	give("potato", 2)
	main.call("_on_world_requested", "house", "")
	main.call("show_screen", &"map")
	await frames(4)
	quiet_modals()
	var house := main.find_child("World_house", true, false) as Control
	house.call("close_tray")
	house.call("open_station_tray", "stove", "")
	await frames(4)
	cook.set("invent_mode", false)
	var panel := cook.call("current") as Control
	check(panel != null, "painel do fogão aberto (Pratos)")
	if panel == null:
		return
	panel.call("_set_mode", false)
	await frames(2)
	panel.call("_select_dish", "puppy_mash")
	await frames(2)
	var together_button := panel.find_child("TogetherButton", true, false) as Control
	check(together_button != null, "Pratos tem o botão Cozinhar junto")
	var hit := together_button.get_node_or_null("Hit") as Control
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = (hit if hit != null else together_button).size / 2.0
		(hit if hit != null else together_button).gui_input.emit(click)
	await frames(2)
	check(game() != null and str(game().get("phase")) == "picar", "Cozinhar junto da aba Pratos abre o minigame")
	game().call("cancel")
	await frames(2)
	check(count("carrot") == 2 and queue().is_empty(), "sair não gasta nada")
	# Inventar: o botão do cartão abre o minigame e, ao Pular, os espaços esvaziam.
	cook.set("invent_mode", true)
	panel.call("_set_mode", true)
	var view := panel.find_child("InventView", true, false)
	view.call("set_slot", 0, "carrot")
	view.call("set_slot", 1, "potato")
	await frames(2)
	var button := panel.find_child("InvCookButton", true, false) as Control
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = button.size / 2.0
		button.gui_input.emit(click)
	await frames(2)
	check(game() != null, "Cozinhar junto da aba Inventar abre o minigame")
	game().call("skip")
	await frames(2)
	check(queue().size() == 1 and str(panel.find_child("InvCard", true, false).get_meta("state")) == "empty", "Pular no Inventar cozinha e esvazia os espaços")
	panel.call("close", true)
	await frames(2)
