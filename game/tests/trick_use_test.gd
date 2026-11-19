extends SceneTree
## E08 pelo calendário DEV e entradas reais. Use -- --screenshots para gravar o viewport.

const FOOD := "puppy_mash"
const TRICKS := ["sit", "paw", "lie_down"]
var state: Node
var main: Node
var events: Node
var failures := 0
var screenshots := false


func _initialize() -> void:
	screenshots = "--screenshots" in OS.get_cmdline_user_args()
	create_timer(110).timeout.connect(func() -> void: quit(1))
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("TRICK USE: " + message)


func pause(seconds: float = 0.2) -> void:
	await create_timer(seconds).timeout


func shot(id: String) -> void:
	if not screenshots:
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/e08_tricks")
	DirAccess.make_dir_recursive_absolute(folder)
	check(image.save_png(folder.path_join("%dx%d_%s.png" % [image.get_width(), image.get_height(), id])) == OK, "captura " + id)


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		var layer: Variant = main.get(member)
		if layer is CanvasLayer:
			layer.hide()
	main.set("_modal_queue", [] as Array[Callable])


func _day(day: int, hour: int) -> void:
	state.call("dev_week_goto", day)
	state.call("dev_week_hour", hour)


func _stat(id: String) -> int:
	return state.get("progress").stat(id)


func _stock(id: String = FOOD) -> int:
	return state.get("inventory").count(id)


func _caderno() -> Array[int]:
	var scores: Array[int] = []
	for id: String in TRICKS:
		scores.append(_stat("trick:" + id))
	return scores


func _lesson(id: String) -> void:
	check(state.call("start_trick_lesson", id) == "", "abre aula " + id)
	var outcome: Dictionary
	for i in 5:
		state.call("trick_lesson_step", id, "show", 1.0)
		state.call("trick_lesson_step", id, "mark", 1.0)
		outcome = state.call("trick_lesson_step", id, "reward", 0.1)
	check(outcome.get("stars") == 3, "conclui aula " + id)


func _button(id: String) -> Button:
	for button: Node in main.find_children(id, "Button", true, false):
		if button.is_visible_in_tree():
			return button
	return null


func _tap(id: String) -> void:
	var button := _button(id)
	check(button != null, "botão " + id)
	if button == null:
		return
	var position := button.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var touch := InputEventMouseButton.new()
		touch.button_index = MOUSE_BUTTON_LEFT
		touch.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		touch.pressed = pressed
		touch.position = position
		touch.global_position = position
		root.push_input(touch, true)


func _screen_touch(point: Vector2, pressed: bool) -> void:
	var touch := InputEventScreenTouch.new()
	touch.position = point
	touch.pressed = pressed
	root.push_input(touch, true)


func _gesture(overlay: Node, success: bool = true) -> void:
	var stage := overlay.find_child("LessonStage", true, false) as Control
	var path: PackedVector2Array = overlay.get("_path")
	var origin := stage.global_position
	var last := origin + path[0]
	_screen_touch(last, true)
	if success:
		var down: bool = overlay.get("trick_id") == "lie_down"
		for i in range(1, path.size()):
			if down:
				await pause(0.35)
			var point := origin + path[i]
			var drag := InputEventScreenDrag.new()
			drag.position = point
			drag.relative = point - last
			root.push_input(drag, true)
			last = point
		if down:
			await pause(2.15)
	_screen_touch(last, false)
	await process_frame
	await process_frame


func _pick_meal() -> Node:
	_hide_modals()
	var builder := load("res://scripts/ui/sheet_builder.gd")
	events.sheet_requested.emit("Tigela", builder.call("food_picker"))
	await pause(0.55)
	_tap("Give_" + FOOD)
	await pause(0.35)
	var overlay := main.get_node_or_null("MealTrick")
	check(overlay != null, "pedido abriu ao servir pela tigela")
	return overlay


func _run() -> void:
	if not screenshots:
		root.size = Vector2i(360, 780)
	state = root.get_node("GameState")
	events = root.get_node("Events")
	var saver := root.get_node("SaveManager")
	events.state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.get("inventory").add("apple_biscuit", 12)
	state.get("inventory").add(FOOD, 12)
	_day(2, 12)
	state.call("update_week")
	check(state.call("meal_trick_offer", FOOD).is_empty(), "pedido ainda fechado")
	_lesson("sit")
	_day(4, 12)
	state.call("update_week")
	if state.call("tiro_weak"):
		check(state.call("feed", FOOD), "almoço recupera o Tiro no dia 4")
	_lesson("paw")
	_day(5, 9)
	_lesson("lie_down")
	var scores := _caderno()
	check(scores == [3, 3, 3], "três truques aprendidos")
	check(state.call("meal_trick_offer", FOOD).is_empty(), "fora de hora não pede truque")
	check(state.call("trick_show_error", 3) == "Abre no dia 6", "show fechado no dia 5")
	state.call("finish_fishing_tutorial")

	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await pause(0.7)
	_day(5, 12)
	state.get("dog").needs["happiness"] = 20
	var smart := _stat("moment:smart")
	var food := _stock()
	var overlay := await _pick_meal()
	if overlay == null:
		quit(1)
		return
	var offer: Dictionary = overlay.get("_meal")
	check(offer.period == "lunch" and _stock() == food, "almoço aguarda o gesto")
	await shot("01_pedido_almoco")
	_tap("MealTrickAsk")
	await pause()
	await shot("02_gesto_tigela")
	await _gesture(overlay)
	await pause(0.8)
	var lunch: Dictionary = state.call("meal_info").done.lunch
	check(lunch.get("trick") == offer.id and _stock() == food - 1, "acerto serve o almoço")
	check(_stat("trick_meal") == 1 and _stat("moment:smart") == smart + 1, "acerto dá um momento de Esperteza")
	var lunch_happiness: float = state.get("dog").needs.happiness
	check(state.call("meal_trick_offer", FOOD).is_empty(), "refeição concluída não oferece outra tentativa")
	check(state.call("feed", FOOD, offer) and _stat("trick_meal") == 1, "repetir oferta serve sem bônus")

	_day(5, 19)
	state.get("dog").needs["happiness"] = 20
	overlay = await _pick_meal()
	if overlay == null:
		quit(1)
		return
	check(overlay.get("_meal").period == "dinner", "pedido no jantar")
	await shot("03_pedido_jantar")
	_tap("MealTrickAsk")
	await pause()
	await _gesture(overlay, false)
	await pause(0.8)
	check(not state.call("meal_info").done.dinner.has("trick") and _stat("trick_meal") == 1, "erro serve jantar sem bônus")
	check(lunch_happiness > float(state.get("dog").needs.happiness) + 4.0, "felicidade extra no acerto")

	_day(6, 12)
	overlay = await _pick_meal()
	if overlay == null:
		quit(1)
		return
	_tap("MealTrickSkip")
	await pause(0.45)
	check(state.call("meal_info").done.lunch.on_time and _stat("trick_meal") == 1, "Só dar alimenta na hora")
	_day(6, 19)
	overlay = await _pick_meal()
	if overlay == null:
		quit(1)
		return
	_tap("MealTrickAsk")
	await pause()
	await _gesture(overlay)
	await pause(0.8)
	check(state.call("meal_info").done.dinner.has("trick") and _stat("trick_meal") == 2 and _stat("moment:smart") == smart + 2, "jantar também premia acerto")

	await _show()
	check(_caderno() == scores and _stat("trick_lesson") == 3, "refeições e shows preservam níveis e acertos")
	await _wish()
	await _show_photo()
	print("TRICK USE TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


func _show() -> void:
	var coins: int = state.get("coins")
	var cookie := _stock("apple_biscuit")
	main.call("_on_world_requested", "farm", "week_show")
	await pause(1.0)
	_hide_modals()
	await shot("04_escolha_show")
	_tap("ShowLength_3")
	await pause(0.4)
	var overlay := main.get_node_or_null("TrickShow")
	check(overlay != null, "show abriu com a plateia no dia 6")
	if overlay == null:
		return
	var sequence: Array = overlay.get("_sequence")
	check(sequence == TRICKS and overlay.find_child("ShowAudience", true, false).get_child_count() > 0, "fila inicial e público")
	check(state.call("trick_show_step", "paw", true).get("retry") == true, "gesto fora de ordem não avança")
	await shot("05_palco")
	for id: String in sequence:
		check(overlay.get("trick_id") == id, "próximo truque " + id)
		await _gesture(overlay)
	await pause(0.55)
	await shot("06_aplausos")
	var result: Dictionary = overlay.get("result")
	check(result.get("photo") == true and state.get("album").has_photo("h_trick_show"), "primeiro show registra foto")
	check(_stat("trick_show") == 1 and _stat("trick_show_use:lie_down") == 1, "contadores próprios do show")
	check(state.get("coins") == coins + int(result.get("coins", 0)) and _stock("apple_biscuit") == cookie, "moedas uma vez e sem custo de aula")
	check(state.call("start_trick_show", 5).has("error"), "segundo show no mesmo dia bloqueado")
	_tap("ShowDone")
	await pause(0.45)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	check(state.call("start_trick_show", 3).has("error"), "prêmio diário persiste ao carregar")
	_day(7, 12)
	check(state.call("start_trick_show", 2).has("error"), "comprimento fora da faixa é rejeitado")
	var four: Dictionary = state.call("start_trick_show", 4)
	check(four.get("sequence", []).size() == 4, "quatro truques no segundo dia")
	state.call("cancel_trick_show")
	var five: Dictionary = state.call("start_trick_show", 5)
	check(five.get("sequence", []).size() == 5, "cinco truques no desafio")
	var next: Dictionary
	for id: String in five.get("sequence", []):
		next = state.call("trick_show_step", id, true)
	var pending: Dictionary = state.get("economy").pending.get("trick_show_perfect", {})
	var reserved := int(pending.get("items", {}).get("apple_biscuit", 0))
	check(_stat("trick_show") == 2 and _stat("trick_show_perfect") == 1 and _stock("apple_biscuit") + reserved == cookie + 3, "dia seguinte paga três biscoitos, inclusive com a Despensa cheia")
	check(next.get("photo") == false and _stat("trick_show_use:sit") == 3, "foto não duplica e fila pode repetir truques")
	check(state.call("trick_show_step", "sit", true).has("error"), "conclusão repetida não paga")


func _wish() -> void:
	var wishes: Variant = state.get("wishes")
	state.get("growth").phase = "puppy"
	state.get("progress").claimed_quests["lais_bed"] = true
	# O relógio de momentos já acompanha a semana DEV.
	state.set("_dev_moment_offset", 0.0)
	state.get("dog").commit(state.call("now"))
	for need: String in ["hunger", "happiness", "hygiene", "energy"]:
		state.get("dog").needs[need] = 100
	wishes.first_done = true
	wishes.last_ids.assign(["pet", "play"])
	var period: String = state.call("moment_period")
	for attempt in 40:
		if state.call("_pick_wish", period).get("id") == "train":
			break
		state.get("growth").taste_seed += 1
	check(state.call("_wish_available", "train"), "treino concorre no sorteio com aula disponível")
	var chosen: Dictionary = state.call("_pick_wish", period)
	check(chosen.get("id") == "train", "sorteio seleciona treino")
	state.call("dev_refresh_wishes")
	check(state.call("balloon_wish") == "train", "desejo chega ao balão pela rotina")
	events.sheet_close_requested.emit()
	events.screen_requested.emit(&"pet")
	await pause(0.55)
	_hide_modals()
	_tap("WishBubble")
	await pause(0.3)
	await shot("07_desejo")
	_tap("WishGo")
	await pause(0.9)
	check(_button("LessonTrain_sit") != null, "Ir abre o caderno no tapete")
	var before := _stat("moment:smart")
	state.call("start_trick_lesson", "sit")
	state.call("cancel_trick_lesson", "sit")
	check(state.call("wish_id") == "train", "cancelar aula não cumpre o pedido")
	_lesson("sit")
	check(state.call("wish_id") == "" and _stat("wish:train") == 1 and _stat("moment:smart") == before + 1, "aula válida cumpre o desejo e dá Esperteza")


func _show_photo() -> void:
	_hide_modals()
	events.sheet_close_requested.emit()
	check(state.call("open_photo_card", "h_trick_show") == "", "foto do show abre no Álbum")
	load("res://scripts/ui/album_screen.gd").call("open", "story")
	await pause(0.5)
	var viewer: Node = load("res://scripts/ui/card_viewer.gd").call("open", "h_trick_show")
	check(viewer != null, "visualizador da foto do show")
	if viewer == null:
		return
	await pause(0.55)
	check(viewer.find_child("Friend_bloblo", true, false) != null and viewer.find_child("Friend_lais", true, false) != null, "foto composta tem vovó e Laís")
	await shot("08_foto_show")
	viewer.call("close")
	await pause(0.5)
