extends SceneTree
## Aula do primeiro desejo (passo lais_first_wish): balão → cartão → carinho → balão pronto → Pegar.
## Com "-- --screenshots" grava build/screenshots/desejo/aula_<passo>_<largura>x<altura>.png.
var failures := 0
var state: Node
var main: Control
var guide: Node
var shots := "--screenshots" in OS.get_cmdline_user_args()

func _initialize() -> void:
	_run.call_deferred()
	create_timer(120).timeout.connect(func() -> void: quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("WISH LESSON: " + message)

func frames(n: int = 12) -> void:
	for i: int in n: await process_frame

func wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func shot(kind: String) -> void:
	if not shots: return
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/desejo")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join("aula_%s_%dx%d.png" % [kind, root.size.x, root.size.y]))

func showing(step: int) -> bool:
	return guide.visible and str(guide.get("active")) == "wish" and int(guide.get("step")) == step

func tap_at(point: Vector2) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = point
		root.push_input(event, true)
		await process_frame
	await frames()

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.set_script(load("res://tests/helpers/economy_clock.gd"))
	state.set_clock(1792746000.0)
	state.reset()
	state.set_process(false)
	state.finish_week_arrival()
	state.finish_home_tour()
	state.dev_week_goto(3)
	state.growth.phase = "puppy"
	state.dev_complete_quest("week_soup")
	state.progress.seen.intro = true
	state._mark_all_seen()
	for seen: String in ["arrival", "missions", "home_tour", "home_claim", "food", "clock", "morning", "weak"]:
		state.week.tutorial[seen] = {"done": true}
	state.week.food_lesson = true
	state.update_wishes()
	state.wishes.current = {"id": "pet", "item": "", "period": state.moment_period(), "progress": state.progress.stat("pet"), "since": state.now()}
	check(str(state.progress.current_main_quest()) == "lais_first_wish", "o passo da vez é o primeiro desejo (%s)" % state.progress.current_main_quest())
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	main.call("show_screen", &"pet")
	state._changed()
	guide = main.find_child("WeekTutorial", true, false)
	var pet: Control = main.find_child("PetScreen", true, false)
	await wait(1.0)
	check(showing(0), "1: a mão aponta o balão do desejo (%s/%s)" % [guide.get("active"), guide.get("step")])
	await shot("1_balao")
	# Toque no balão abre o cartão: a Laís diz o que ele quer.
	pet.call("_open_wish_card")
	await wait(0.6)
	check(showing(1), "2: com o cartão aberto, a aula explica o pedido (%s/%s)" % [guide.get("active"), guide.get("step")])
	await shot("2_cartao")
	# Fecha o cartão (toque fora): agora a mão ensina o carinho no Tiro.
	var catcher := main.find_child("PopoverCatcher", true, false)
	if catcher: catcher.call("emit_signal", "gui_input", InputEventMouseButton.new())
	for c: Node in main.find_children("PopoverCatcher", "", true, false):
		c.queue_free()
	for card: Node in main.find_children("WishCard", "", true, false):
		var popover := card.get_parent()
		while popover != null and not popover.has_method("close"):
			popover = popover.get_parent()
		if popover: popover.call("close")
	await wait(0.8)
	check(showing(2), "3: depois do cartão, a mão faz o carinho no Tiro (%s/%s)" % [guide.get("active"), guide.get("step")])
	await shot("3_carinho")
	# Carinho de verdade: o desejo fica pronto e a aula volta ao balão.
	state.pet("head")
	state._changed()
	await wait(2.5)
	check(state.wish_error() == "", "o carinho deixa o desejo pronto: " + str(state.wish_error()))
	check(showing(3), "4: desejo pronto: a mão volta ao balão (%s/%s)" % [guide.get("active"), guide.get("step")])
	await shot("4_pronto")
	pet.call("_open_wish_card")
	await wait(0.6)
	check(showing(4), "5: no cartão, a mão aponta Pegar (%s/%s)" % [guide.get("active"), guide.get("step")])
	await shot("5_pegar")
	var take := main.find_child("WishTake", true, false) as Button
	check(take != null, "botão Pegar no cartão")
	if take:
		take.pressed.emit()
	await wait(0.8)
	check(state.progress.stat("wish") >= 1, "o desejo foi atendido")
	check(not (guide.visible and str(guide.get("active")) == "wish"), "a aula termina")
	print("WISH LESSON TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
