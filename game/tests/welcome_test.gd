extends SceneTree
## Presente do dia, nível com presente e cartão "bem-vindo de volta", sem gravar o save pessoal.

var failures: int = 0
var state: Node


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Welcome: " + message)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	var progress: RefCounted = state.get("progress")
	# Antes de lais_bed não há presente nem cartão.
	check(state.call("daily_gift_error") != "", "Sem presente antes de lais_bed")
	var card_script: Script = load("res://scenes/ui/welcome_back/welcome_back.gd")
	check(not card_script.call("has_content"), "Cartão não abre antes de lais_bed")
	state.call("dev_complete_quest", "lais_bed")
	check(state.call("daily_gift_error") == "", "Presente liberado depois de lais_bed")
	# Presente do dia: uma vez por dia; o ciclo anda só em dia jogado.
	var cycle: Array = root.get_node("Database").get("progression").daily_gift
	var first: Dictionary = state.call("daily_gift_rewards")
	check(first == cycle[0], "Primeiro dia = primeira entrada do ciclo")
	var food_before: int = state.get("inventory").count("dog_food")
	check(state.call("claim_daily_gift") == "", "Recebe o presente")
	check(state.get("inventory").count("dog_food") == food_before + 3, "Presente entra na mochila")
	check(state.call("claim_daily_gift") == "Já pegou hoje", "Só uma vez por dia")
	check(int(progress.daily_gift.count) == 1, "Contador avançou uma vez")
	var saved: Dictionary = state.call("to_dict")
	state.call("from_dict", saved)
	check(state.call("daily_gift_error") == "Já pegou hoje", "Save preserva o presente recebido")
	progress = state.get("progress")
	progress.daily_gift.period = "2000-01-01"
	var coins: int = state.get("coins")
	check(state.call("claim_daily_gift") == "" and state.get("coins") == coins + 15, "Dia seguinte: segunda entrada (15 moedas)")
	# Faltar dias não zera nem pula: o ciclo continua de onde parou.
	progress.daily_gift.period = "1999-01-01"
	check(state.call("daily_gift_rewards") == cycle[2], "Ciclo continua depois de faltar dias")
	for i in cycle.size():
		progress.daily_gift.period = ""
		state.call("claim_daily_gift")
	check(int(progress.daily_gift.count) == 2 + cycle.size(), "Ciclo dá a volta sem zerar")
	# Lista do que ficou pronto: canteiro pronto aparece.
	progress.owned["farm"] = true
	state.call("plant", 0, "carrot")
	state.get("plots")[0]["ready_at"] = float(state.call("now")) - 1.0
	var lines: Array = state.call("welcome_ready_lines")
	check(lines.size() == 1 and lines[0].kind == "ready" and lines[0].world == "farm" and int(lines[0].count) == 1 and lines[0].icon == "carrot", "Canteiro pronto vira linha do mundo com ícone e número")
	check(card_script.call("has_content") == true, "Cartão abre com algo pronto")
	# Nível: dois níveis juntos somam as recompensas e emitem um evento só.
	var events: Node = root.get_node("Events")
	var got: Array = []
	events.connect("level_up", func(level: int, rewards: Dictionary) -> void: got.append([level, rewards]))
	state.set("xp", 0)
	state.set("level", 1)
	coins = state.get("coins")
	state.call("_add_player_xp", 100 + 200)
	check(state.get("level") == 3 and got.size() == 1 and got[0][0] == 3, "Dois níveis, um evento")
	check(int(got[0][1].coins) == 35 and got[0][1].items.dog_food == 2 and got[0][1].items.carrot_snack == 1, "Soma das recompensas dos níveis 2 e 3")
	check(state.get("coins") == coins + 35, "Recompensa entra uma vez")
	state.call("_add_player_xp", 1000)
	check(state.get("level") >= 4, "Continua subindo")
	check(int(state.call("level_reward", 15).coins) == 65 and int(state.call("level_reward", 30).coins) == 80, "Níveis acima da tabela: min(80, 20 + 3 × nível) vindo do JSON")
	var persisted: Dictionary = state.call("to_dict")
	state.call("from_dict", persisted)
	check(state.get("level") >= 4, "Save preserva o nível")
	# Tela: cartão abre, recebe presente e fecha.
	state.call("reset")
	state.call("dev_complete_quest", "lais_bed")
	# Algo pronto enquanto estava fora: um canteiro e uma sopa no fogão.
	state.get("progress").owned["farm"] = true
	state.get("progress").owned["stove"] = true
	state.call("plant", 0, "carrot")
	state.get("plots")[0]["ready_at"] = float(state.call("now")) - 1.0
	state.call("station", "stove").call("enqueue", "vegetable_soup", 1.0, float(state.call("now")) - 10.0)
	state.get("progress").seen["intro"] = true
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var welcome: Node = main.get("_welcome")
	welcome.call("open")
	await process_frame
	check(welcome.visible, "Cartão visível")
	check(_find_button(welcome, "Pegar") != null, "Botão Pegar presente")
	_shot("welcome_back")
	_find_button(welcome, "Pegar").emit_signal("pressed")
	await process_frame
	check(state.call("daily_gift_error") == "Já pegou hoje" and _find_button(welcome, "Pegar") == null, "Pegar entrega e some o botão")
	_find_button(welcome, "Vamos lá!").emit_signal("pressed")
	check(not welcome.visible, "Vamos lá fecha")
	main.get("_celebration").call("show_level", 3, {"coins": 20, "items": {"carrot_snack": 1}})
	await process_frame
	_shot("level_up")
	print("WELCOME TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)


func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text:
		return node as Button
	for child in node.get_children():
		var found := _find_button(child, text)
		if found:
			return found
	return null


func _shot(name: String) -> void:
	if not "--screenshots" in OS.get_cmdline_user_args():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../build/screenshots"))
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../build/screenshots/%s.png" % name))
