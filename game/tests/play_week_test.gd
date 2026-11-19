extends SceneTree
## E09: calendário DEV, regras de recompensa e os gestos no Quintal.

var state: Node
var main: Node
var events: Node
var yard: Script
var failures := 0
var screenshots := false


func _initialize() -> void:
	screenshots = "--screenshots" in OS.get_cmdline_user_args()
	Engine.max_fps = 60
	create_timer(145).timeout.connect(func() -> void:
		push_error("PLAY WEEK: tempo do teste excedido")
		quit(1))
	_run.call_deferred()


func check(ok: bool, label: String) -> void:
	if ok: return
	failures += 1
	push_error("PLAY WEEK: " + label)


func pause(seconds: float) -> void:
	await create_timer(seconds).timeout


func shot(name: String) -> void:
	if not screenshots: return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/e09_play")
	DirAccess.make_dir_recursive_absolute(folder)
	check(image.save_png(folder.path_join("%dx%d_%s.png" % [image.get_width(), image.get_height(), name])) == OK, "captura " + name)


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		var layer: Variant = main.get(member)
		if layer is CanvasLayer: layer.hide()
	main.set("_modal_queue", [] as Array[Callable])


func day(date: int, hour: int) -> void:
	state.call("dev_week_goto", date)
	state.call("dev_week_hour", hour)
	_hide_modals()


func stat(id: String) -> int:
	return state.get("progress").stat(id)


func row(id: String) -> Dictionary:
	for requirement: Dictionary in state.call("growth_info").requirements:
		if requirement.id == id: return requirement
	return {}


func button(id: String) -> Button:
	for node: Node in main.find_children(id, "Button", true, false):
		if node.is_visible_in_tree(): return node
	return null


func tap(id: String) -> void:
	var control := button(id)
	check(control != null, "botão " + id)
	if control == null: return
	var point := control.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		event.position = point
		event.global_position = point
		root.push_input(event, true)


func touch(point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.pressed = pressed
	root.push_input(event, true)


func drag(from: Vector2, to: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.position = to
	event.relative = to - from
	root.push_input(event, true)


func launch(game: Node, aim: Vector2, screenshot: String = "") -> void:
	var stage := game.find_child("YardStage", true, false) as Control
	var origin := stage.get_global_rect().position + (game.call("_origin") as Vector2)
	var end := origin - aim * stage.size
	touch(origin, true)
	if aim != Vector2.ZERO:
		drag(origin, end)
		if screenshot != "":
			await process_frame
			await process_frame
			await shot(screenshot)
	touch(end, false)
	await process_frame
	check(not game.get("landing").is_empty(), "toque e arrasto lançam")


func wait_landing(game: Node) -> void:
	var deadline := Time.get_ticks_msec() + 4000
	while not game.get("landing").is_empty() and Time.get_ticks_msec() < deadline:
		await process_frame
	check(game.get("landing").is_empty(), "o lançamento terminou")


func open_mode(id: String) -> Node:
	_hide_modals()
	yard.call("open")
	await pause(0.3)
	tap(id)
	await pause(0.22)
	var game := main.get_node_or_null("YardPlay")
	if id != "YardHide": check(game != null, "menu abriu " + id)
	return game


func _run() -> void:
	if not screenshots:
		root.size = Vector2i(360, 780)
		Motion.reduced = true
	state = root.get_node("GameState")
	events = root.get_node("Events")
	yard = load("res://scripts/ui/yard_play.gd")
	var saver := root.get_node("SaveManager")
	events.state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer: child.queue_free()
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("finish_fishing_tutorial")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await pause(0.7)
	day(1, 9)
	check(not state.call("yard_open", "fetch") and not state.call("yard_open", "rope"), "dia 1 só bolinha de pano e nome")
	check(not row("name").is_empty() and not row("name").done, "gancho do nome pendente")
	var game := await open_mode("YardName")
	if game == null:
		quit(1)
		return
	await shot("02_tiro")
	await pause(0.8)
	check(stat("name_call") == 1 and row("name").done, "Tiro atende e conta no Para crescer")
	tap("YardExit")
	yard.call("open")
	await pause(0.4)
	check(button("YardRope").disabled and button("YardHide").disabled, "menu mostra os dias de abertura")
	await shot("01_quintal")
	tap("YardBall")
	await pause(0.24)
	game = main.get_node_or_null("YardPlay")
	if game == null:
		quit(1)
		return
	await shot("03_bolinha_de_pano")
	for i in 5:
		await launch(game, Vector2.ZERO)
		await wait_landing(game)
	var first_result: Dictionary = game.get("result")
	check(first_result.get("score") == 0 and stat("play") == 1 and row("play").have == 1, "cinco toques no dia 1 contam uma partida sem pontos")
	tap("YardExit")
	await process_frame

	day(2, 9)
	# A mesma mira do palco é a posição que o motor pontua.
	var rules: Dictionary = state.call("yard_rules")
	var origin := Vector2(0.5, 0.82)
	var reach := float(rules.launch.range)
	var max_drag := float(rules.launch.drag)
	for target: Dictionary in rules.targets:
		var fixture: Dictionary = state.call("start_yard_round", "ball")
		var aim := (Vector2(target.at[0], target.at[1]) - origin) * max_drag / reach
		var throw: Dictionary = state.call("yard_throw", int(fixture.id), aim)
		check(throw.get("hit") == target.id, "atinge " + str(target.id))
		if target.has("points"): check(throw.get("base") == int(target.points), str(target.id) + " vale os pontos da referência")
		else: check(int(throw.get("base", -1)) >= 0, "trapalhada não tira pontos")
		check(state.call("yard_throw", int(fixture.id), aim).is_empty(), "uma bolinha em voo por vez")
		state.call("cancel_yard_round", int(fixture.id))
	var arch := (Vector2(0.27, 0.34) - origin) * max_drag / reach
	var bucket := (Vector2(0.73, 0.48) - origin) * max_drag / reach
	var coins: int = state.get("coins")
	var smart := stat("moment:smart")
	var play_count := stat("play")
	state.get("dog").needs.happiness = 5.0
	var happiness_before: float = state.get("dog").needs.happiness
	game = await open_mode("YardBall")
	if game == null:
		quit(1)
		return
	for part in 4:
		if part > 0:
			tap("YardAgain")
			await process_frame
		for i in 5:
			var first := part == 0 and i == 0
			var aiming := arch if part == 0 else bucket
			await launch(game, aiming, "04_mira" if first else "")
			if first:
				var id := int(game.get("round_data").id)
				check(state.call("yard_finish_throw", id, true).is_empty(), "Pula! antes da janela é ignorado")
				var deadline := Time.get_ticks_msec() + 2000
				while button("YardJump") == null and Time.get_ticks_msec() < deadline:
					await process_frame
				check(button("YardJump") != null, "Pula! só na janela")
				await shot("05_pula")
				tap("YardJump")
				await process_frame
				check(str((game.find_child("YardScore", true, false) as Label).text).begins_with("6 pts"), "Pula! dobra os três pontos do arco")
			else:
				await wait_landing(game)
		var outcome: Dictionary = game.get("result")
		check(outcome.get("turn") == 5, "partida %d fecha no quinto lançamento" % part)
		check(outcome.get("rewarded") == (part < 3), "recibo de prêmio da partida %d" % part)
		check(outcome.get("smart") == int(part < 2), "teto de Esperteza da partida %d" % part)
		if part == 0:
			check(outcome.get("score") == 18 and outcome.get("record") == 18 and outcome.get("coins") == int(rules.record_coins), "placar, recorde e moedas")
			await shot("06_resultado")
		else:
			check(outcome.get("coins") == 0, "recorde só paga uma vez no dia")
		if part == 3:
			check(outcome.get("happiness") == 0, "quarta partida sem Felicidade")
	check(state.get("dog").needs.happiness >= happiness_before + 28.0, "três partidas dão Felicidade")
	check(state.get("coins") == coins + int(rules.record_coins) and stat("moment:smart") == smart + 2, "moedas e teto do período")
	check(stat("play") == play_count + 3 and row("play").done, "só três partidas progridem")
	tap("YardExit")
	await process_frame
	var save: Dictionary = state.call("to_dict")
	state.call("from_dict", save)
	check(state.call("yard_record") == 18 and state.call("yard_rewards_left", "ball") == 0, "save guarda recorde e limite")
	day(2, 15)
	check(state.call("yard_rewards_left", "ball") == 3, "renova no próximo período")
	game = await open_mode("YardBall")
	if game == null:
		quit(1)
		return
	for i in 5:
		await launch(game, bucket)
		await wait_landing(game)
	check(game.get("result").rewarded and game.get("result").smart == 1 and stat("play") == play_count + 4, "primeiro prêmio e momento novos")
	tap("YardExit")
	await process_frame

	day(3, 9)
	check(state.call("start_yard_round", "rope").has("error"), "cordinha fechada no dia 3")
	state.call("dev_set_phase", "puppy")
	day(4, 9)
	game = await open_mode("YardRope")
	if game == null:
		quit(1)
		return
	var stage := game.find_child("YardStage", true, false) as Control
	var hold := stage.get_global_rect().position + stage.size * Vector2(0.5, 0.68)
	for i in 3:
		touch(hold, true)
		await pause(0.45 if i == 1 else 1.12)
		if i == 0: await shot("07_cordinha")
		touch(hold, false)
		await process_frame
	check(game.get("result").score == 2 and stat("play_rope") == 1 and row("rope").done, "três puxões, dois no ritmo e gancho da cordinha")
	tap("YardExit")
	await process_frame
	var normal: Dictionary = state.call("start_yard_round", "ball")
	var distance := Vector2(0, -0.18)
	var regular: Dictionary = state.call("yard_flight", int(normal.id), distance)
	state.call("cancel_yard_round", int(normal.id))
	day(5, 9)
	check(state.call("start_yard_round", "hide").has("error"), "esconde-esconde fechado no dia 5")
	var loan_ended: Dictionary = state.call("start_yard_round", "ball")
	check(not loan_ended.variant.squeak, "dia 5 ainda usa a bolinha de pano antes da compra")
	state.call("cancel_yard_round", int(loan_ended.id))
	state.set("coins", 35)
	check(state.call("buy_shop_item", "cart_ball") == "", "compra a bolinha na carroça")
	var squeak: Dictionary = state.call("start_yard_round", "ball")
	var squeaky: Dictionary = state.call("yard_flight", int(squeak.id), distance)
	check(squeak.variant.squeak and not squeak.variant.lake and squeaky.end.y < regular.end.y, "bolinha que apita vai mais longe no dia 5")
	state.call("cancel_yard_round", int(squeak.id))
	day(6, 9)
	game = await open_mode("YardBall")
	if game == null:
		quit(1)
		return
	var bridge := (Vector2(0.5, 0.34) - origin) * max_drag / float(rules.launch.squeak_range)
	await launch(game, bridge, "08_lagoa")
	check(game.get("landing").bounce, "quica na ponte no dia 6")
	tap("YardExit")
	await process_frame
	var treats: Dictionary = state.get("inventory").counts.duplicate()
	state.call("finish_fishing_tutorial")
	await open_mode("YardHide")
	var hide_game := main.find_child("YardHideSeek", true, false)
	check(hide_game != null, "Esconde-esconde abre no dia 6")
	if hide_game != null:
		await pause(1.15)
		var spot := int(hide_game.get("_yard_round").hideout)
		await shot("09_esconde_esconde")
		tap("Hideout_%d" % ((spot + 1) % 3))
		check(stat("hide_found") == 0 and not hide_game.get("finished"), "esconderijo errado permite procurar")
		tap("Hideout_%d" % spot)
		check(stat("hide_found") == 1 and hide_game.get("finished"), "toque no rabo revela o Tiro")
		check(row("play").have == 2 and state.get("inventory").counts == treats, "cordinha e esconderijo contam; sem custo de petisco")
		await shot("10_achou")
	print("PLAY WEEK: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
