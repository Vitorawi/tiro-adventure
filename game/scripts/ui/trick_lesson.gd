class_name TrickLesson
extends Control
## A Aula do Tiro sobre o mapa. O GameState recebe cada passo e fecha a aula.

const RUG := preload("res://assets/sprites/areas/house/paw_rug.png")
const BOWL := preload("res://assets/sprites/ui/album/prop_bowl.png")
const HIT_RADIUS := 25.0
const STEPS := ["Mostrar", "Marcar", "Premiar"]
static var _current: TrickLesson

var trick_id: String
var repetition := 1
var phase := 0
var elapsed := 0.0
var result: Dictionary = {}
var _meal: Dictionary = {}
var _serve: Callable
var _sequence: Array = []
var _asking := false
var _serving := false
var _meal_buttons: HBoxContainer
var _meal_prompt: Label
var _meal_request: Button
var _def: Dictionary
var _rules: Dictionary
var _surface: Control
var _stage: Control
var _trail: Control
var _title: Label
var _hint: Label
var _feedback: Label
var _dots: HBoxContainer
var _steps: HBoxContainer
var _mark_track: ProgressBar
var _mark: Button
var _reward: Button
var _animator: PetAnimator
var _cookie: Texture2D
var _path := PackedVector2Array()
var _finger := Vector2.ZERO
var _checkpoint := 0
var _dragging := false
var _touch := -1
var _off_path := false
var _drag_seconds := 0.0
var _hold_seconds := 0.0
var _closing := false


static func current() -> TrickLesson:
	return _current if is_instance_valid(_current) and not _current._closing else null


static func open(host: Node, id: String) -> void:
	var error := GameState.start_trick_lesson(id)
	if error != "":
		Events.toast_requested.emit(error)
		return
	var lesson := TrickLesson.new()
	lesson.name = "TrickLesson"
	lesson.trick_id = id
	var position := GameState.trick_lesson_position()
	lesson.phase = position % STEPS.size()
	lesson.repetition = floori(float(position) / STEPS.size()) + 1
	lesson._present(host)


static func offer_meal(host: Node, offer: Dictionary, serve: Callable) -> void:
	var lesson := TrickLesson.new()
	lesson.name = "CartTrick" if offer.has("order") else "MealTrick"
	lesson.trick_id = str(offer.id)
	lesson._meal = offer
	lesson._serve = serve
	lesson._asking = true
	lesson._present(host)


static func open_show(host: Node, length: int) -> void:
	var offer := GameState.start_trick_show(length)
	if offer.has("error"):
		Events.toast_requested.emit(str(offer.error))
		return
	var lesson := TrickLesson.new()
	lesson.name = "TrickShow"
	lesson._sequence = offer.sequence
	lesson.trick_id = str(offer.sequence[0])
	lesson._present(host)


func _present(host: Node) -> void:
	_current = self
	Events.sheet_close_requested.emit()
	host.add_child(self)


func _ready() -> void:
	_def = Database.progression.tricks[trick_id]
	_rules = Database.progression.trick_settings.lesson
	_cookie = Database.item_icon(str(_rules.cookie_icon))
	z_index = 13
	z_as_relative = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = HomeUi.theme(17)

	var background := ColorRect.new()
	background.color = Color("e1dabc")
	add_child(background)
	StepCardUi.stretch(background)
	_surface = Control.new()
	add_child(_surface)
	StepCardUi.stretch(_surface)
	BagUi.frame(_surface, "frame", Vector4(14, 150, 14, 77), "LessonFrame")

	var padding := MarginContainer.new()
	_surface.add_child(padding)
	StepCardUi.stretch(padding)
	for side: String in ["left", "right", "top", "bottom"]:
		padding.add_theme_constant_override("margin_" + side, 22)
	var column := UiKit.vbox(10)
	padding.add_child(column)
	var top := UiKit.hbox(6)
	column.add_child(top)
	var title := "Aula do Tiro"
	if not _sequence.is_empty():
		title = "O show do Tiro"
	elif _meal.has("order"):
		title = "Truque para o cliente"
	elif not _meal.is_empty():
		title = MealUi.period_name(str(_meal.period))
	var heading := StepCardUi.wood(title, 25)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(heading)
	if _meal.is_empty():
		top.add_child(WelcomeSheet._button("Sair", false, 64.0, "LessonExit", _back))
	if _is_lesson():
		ProgressionUi.npc_header(column, "bloblo", "Vamos praticar %s, meu bem?" % str(_def.name), false, true)
	elif not _sequence.is_empty():
		_audience(column)
	else:
		var ask := StepCardUi.inner_card(column, "MealTrickOffer", Vector4i(12, 9, 12, 9))
		_meal_prompt = StepCardUi.wood("Um truque pela gorjeta?" if _meal.has("order") else "Pedir um truque antes?", 21)
		_meal_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ask.add_child(_meal_prompt)
		_meal_buttons = UiKit.hbox(8)
		_meal_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
		ask.add_child(_meal_buttons)
		_meal_request = StepCardUi.go_button(str(_def.name) + "!", _start_meal_gesture)
		_meal_request.name = "MealTrickAsk"
		_meal_buttons.add_child(_meal_request)
		_meal_buttons.add_child(WelcomeSheet._button("Só entregar" if _meal.has("order") else "Só dar", false, 120.0 if _meal.has("order") else 80.0, "MealTrickSkip", _serve_meal.bind(false)))

	var status := UiKit.hbox(6)
	column.add_child(status)
	_title = StepCardUi.wood("", 19)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_child(_title)
	if _is_lesson():
		status.add_child(StepCardUi.wood_chip(_cookie, "1 biscoito"))
	_dots = UiKit.hbox(8)
	_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(_dots)
	_dots.visible = _meal.is_empty()
	if _is_lesson():
		for i in int(_rules.repetitions):
			_dots.add_child(UiKit.icon(UiKit.ui_icon("rare_star"), 25))
	else:
		for id: String in _sequence:
			_dots.add_child(StepCardUi.wood_chip(UiKit.ui_icon(str(Database.progression.tricks[id].icon)), ""))
	_steps = UiKit.hbox(6)
	_steps.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(_steps)
	_steps.visible = _is_lesson()
	if _is_lesson():
		for step: String in STEPS:
			_steps.add_child(StepCardUi.wood_chip(null, step, "have"))

	_stage = Control.new()
	_stage.name = "LessonStage"
	_stage.custom_minimum_size.y = 235
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_stage)
	_stage.gui_input.connect(_stage_input)
	_stage.resized.connect(_layout_stage)
	_stage.draw.connect(_draw_stage)

	var tiro := TextureRect.new()
	tiro.name = "LessonTiro"
	tiro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tiro.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tiro.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_stage.add_child(tiro)
	SellUi.place(tiro, 0.03, 0.0, 0.97, 0.0, 0.12, 0.0, 0.88, 0.0)
	_animator = PetAnimator.new()
	_animator.allow_illustrated_puppy = true
	add_child(_animator)
	_animator.setup(tiro)
	_trail = Control.new()
	_trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_trail)
	StepCardUi.stretch(_trail)
	_trail.draw.connect(_draw_trail)
	_reward = BagUi.plain_button(_reward_tiro)
	_reward.name = "LessonReward"
	_reward.tooltip_text = "Premiar o Tiro"
	_stage.add_child(_reward)
	SellUi.place(_reward, 0.2, 0.0, 0.8, 0.0, 0.27, 0.0, 0.80, 0.0)

	_hint = _label(17, 46)
	column.add_child(_hint)
	_feedback = _label(16, 26)
	column.add_child(_feedback)
	var timing := UiKit.vbox(8)
	timing.custom_minimum_size.y = 68 if _is_lesson() else 20
	column.add_child(timing)
	_mark_track = ProgressBar.new()
	_mark_track.name = "LessonTiming"
	_mark_track.show_percentage = false
	_mark_track.custom_minimum_size.y = 16
	_mark_track.add_theme_stylebox_override("background", UiKit.surface(Color("deca9e"), 8))
	_mark_track.add_theme_stylebox_override("fill", UiKit.surface(Color("608c45"), 8))
	if _is_lesson():
		_mark_track.draw.connect(_draw_mark_target)
	timing.add_child(_mark_track)
	_mark = StepCardUi.go_button("Isso!", _mark_trick)
	_mark.name = "LessonMark"
	timing.add_child(_mark)
	_refresh_step()


func _is_lesson() -> bool:
	return _meal.is_empty() and _sequence.is_empty()


func _audience(column: VBoxContainer) -> void:
	var audience := StepCardUi.inner_card(column, "ShowAudience", Vector4i(10, 8, 10, 8))
	var row := UiKit.hbox(18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for npc: String in ["bloblo", "lais"]:
		for object: Dictionary in Database.room("farm").objects:
			if str(object.id) == "week_audience_" + npc:
				var person := UiKit.vbox(2)
				var art := UiKit.icon(load(str(object.sprite)) as Texture2D, 55)
				person.add_child(art)
				var name_label := StepCardUi.wood("Vovó" if npc == "bloblo" else "Laís", 15)
				name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				person.add_child(name_label)
				row.add_child(person)
				break
	audience.add_child(row)


func _start_meal_gesture() -> void:
	_asking = false
	_meal_prompt.hide()
	_meal_request.hide()
	_feedback.text = ""
	_refresh_step()


func _label(px: int, height: int) -> Label:
	var label := StepCardUi.wood("", px)
	label.custom_minimum_size.y = height
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _refresh_step() -> void:
	if not _is_lesson():
		_title.text = "%s · %d de %d" % [_def.name, repetition, _sequence.size()] if _meal.is_empty() else ("" if _asking else str(_def.name) + "!")
		for i in _dots.get_child_count():
			_dots.get_child(i).modulate.a = 1.0 if i < repetition else 0.45
		_hint.text = str(_def.lesson.hint)
		if _asking:
			_hint.text = "Acertou? +%d moedas" % int(_meal.tip) if _meal.has("order") else "Acertou? Mais Felicidade e +1 Esperteza"
		_mark.visible = false
		_mark_track.visible = not _asking
		_reward.visible = false
		elapsed = 0.0
		_mark_track.value = 100
		_layout_stage()
		return
	_title.text = "%s · %d/%d" % [_def.name, repetition, int(_rules.repetitions)]
	for i in _dots.get_child_count():
		_dots.get_child(i).modulate.a = 1.0 if i < repetition else 0.35
	for i in _steps.get_child_count():
		_steps.get_child(i).modulate.a = 1.0 if i == phase else 0.55
	_hint.text = [str(_def.lesson.hint), "Toque em Isso! quando a barra chegar na marca.", "Toque no Tiro para dar o prêmio."][phase]
	_mark.visible = phase == 1
	_mark_track.visible = phase == 1
	_reward.visible = phase == 2
	elapsed = 0.0
	_mark_track.value = 0
	_layout_stage()


func _layout_stage() -> void:
	if _trail == null:
		return
	_path.clear()
	var mirror := bool(_def.lesson.get("alternate_side", false)) and repetition % 2 == 0
	var path: Array = _def.lesson.path
	for i in path.size():
		var point := Vector2(float(path[i][0]), float(path[i][1]))
		if i == path.size() - 1 and GameState.trick_level(trick_id) >= 2:
			point += (point - Vector2(float(path[i - 1][0]), float(path[i - 1][1]))).normalized() * 0.06
		if mirror:
			point.x = 1.0 - point.x
		_path.append(point * _stage.size)
	_stage.queue_redraw()
	_trail.queue_redraw()


func _draw_stage() -> void:
	var rect := Rect2(Vector2.ZERO, _stage.size)
	_stage.draw_style_box(UiKit.surface(Color("f5eacf"), 20), rect)
	if _is_lesson() and phase == 2:
		_stage.draw_circle(_stage.size * Vector2(0.5, 0.54), minf(_stage.size.x, _stage.size.y) * 0.27, Color("ffdf91"))
	var rug_width := _stage.size.x * 0.72
	if _meal.is_empty() or _meal.has("order"):
		_stage.draw_texture_rect(RUG, Rect2((_stage.size.x - rug_width) * 0.5, _stage.size.y * 0.64, rug_width, _stage.size.y * 0.31), false)
	else:
		var bowl_rect := Rect2((_stage.size.x - 106) * 0.5, _stage.size.y - 85, 106, 70)
		_stage.draw_texture_rect(BOWL, bowl_rect, false)
		var icon := Database.item_icon(str(_meal.item))
		if icon:
			_stage.draw_texture_rect(icon, Rect2(bowl_rect.get_center() - Vector2(23, 36), Vector2(46, 46)), false)


func _draw_trail() -> void:
	if phase != 0 or _path.is_empty() or _asking or _serving or not result.is_empty():
		return
	for i in range(1, _path.size()):
		_trail.draw_dashed_line(_path[i - 1], _path[i], Color("fff2ca"), 7.0, 9.0, true, true)
		_trail.draw_dashed_line(_path[i - 1], _path[i], Color("88613a"), 3.0, 9.0, true, true)
	_trail.draw_circle(_path[-1], 15.0, Color("f7d375"), true, -1.0, true)
	_trail.draw_arc(_path[-1], 15.0, 0, TAU, 28, Palette.WOOD_INK, 2.0, true)
	if _dragging and _hold_seconds > 0.0:
		_trail.draw_arc(_path[-1], 21.0, -PI / 2.0, -PI / 2.0 + TAU * minf(1.0, _hold_seconds / float(_def.lesson.hold)), 32, Color("48733e"), 5.0, true)
	var where := _finger if _dragging else _path[0]
	_trail.draw_texture_rect(_cookie, Rect2(where - Vector2(22, 22), Vector2(44, 44)), false)


func _draw_mark_target() -> void:
	var x := _mark_track.size.x * (float(_rules.mark_at) / _mark_timeout())
	_mark_track.draw_line(Vector2(x, 1), Vector2(x, 15), Palette.WOOD_INK, 3.0)


func _mark_timeout() -> float:
	return float(_rules.mark_at) + float(_rules.mark_good) + 0.18


func _stage_input(event: InputEvent) -> void:
	if phase != 0 or _path.is_empty() or _asking or _serving or not result.is_empty():
		return
	if event is InputEventScreenTouch:
		if event.pressed and not _dragging:
			_press(event.position, event.index)
		elif not event.pressed and _dragging and event.index == _touch:
			_release(event.position, event.canceled)
	elif event is InputEventScreenDrag and _dragging and event.index == _touch:
		_move(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not _dragging:
			_press(event.position, -1)
		elif not event.pressed and _dragging and _touch == -1:
			_release(event.position, false)
	elif event is InputEventMouseMotion and _dragging and _touch == -1:
		_move(event.position)
	_stage.accept_event()


func _press(point: Vector2, index: int) -> void:
	if point.distance_to(_path[0]) > HIT_RADIUS:
		return
	_dragging = true
	_touch = index
	_finger = point
	_checkpoint = 1
	_off_path = false
	_drag_seconds = 0.0
	_hold_seconds = 0.0
	_trail.queue_redraw()


func _move(point: Vector2) -> void:
	while _checkpoint < _path.size():
		var nearest := Geometry2D.get_closest_point_to_segment(_path[_checkpoint], _finger, point)
		if nearest.distance_to(_path[_checkpoint]) > 14.0:
			break
		_checkpoint += 1
	var end := mini(_checkpoint, _path.size() - 1)
	if point.distance_to(Geometry2D.get_closest_point_to_segment(point, _path[end - 1], _path[end])) > HIT_RADIUS:
		_off_path = true
	if point.distance_to(_path[-1]) > HIT_RADIUS:
		_hold_seconds = 0.0
	_finger = point
	_trail.queue_redraw()


func _release(point: Vector2, canceled: bool) -> void:
	_move(point)
	_dragging = false
	_trail.queue_redraw()
	if canceled:
		return
	var hold := float(_def.lesson.get("hold", 0.0))
	var success := not _off_path and _checkpoint == _path.size() and point.distance_to(_path[-1]) <= HIT_RADIUS
	success = success and _drag_seconds - _hold_seconds >= float(_def.lesson.get("min_drag", 0.0)) and _hold_seconds >= hold
	if _is_lesson():
		_advance("show", float(success))
	elif not _meal.is_empty():
		_finish_meal_gesture(success)
	else:
		_show_gesture(success)


func _process(delta: float) -> void:
	if not result.is_empty() or _closing or _serving:
		return
	elapsed += delta
	if not _is_lesson():
		var use_rules: Dictionary = Database.progression.trick_settings["show" if _meal.is_empty() else "meal"]
		var limit := float(use_rules.offer_seconds if _asking else use_rules.gesture_seconds)
		_mark_track.value = 100.0 * (1.0 - elapsed / limit)
		if elapsed >= limit:
			if _meal.is_empty():
				_back()
				Events.toast_requested.emit("O tempo acabou. Tente o show de novo!")
			else:
				_serve_meal(false)
			return
	if _dragging:
		_drag_seconds += delta
		if _def.lesson.has("hold") and _checkpoint == _path.size() and _finger.distance_to(_path[-1]) <= HIT_RADIUS:
			_hold_seconds += delta
			_trail.queue_redraw()
	if phase == 1:
		_mark_track.value = 100.0 * elapsed / _mark_timeout()
		if elapsed >= _mark_timeout():
			_advance("mark", elapsed)


func _mark_trick() -> void:
	if phase == 1:
		_advance("mark", elapsed)


func _reward_tiro() -> void:
	if phase == 2:
		if GameState.dog_look().body == "puppy":
			_animator.play_lesson_pose(&"pet_head")
		_advance("reward", elapsed)


func _advance(step: String, value: float) -> void:
	var outcome := GameState.trick_lesson_step(trick_id, step, value)
	if outcome.has("error"):
		_back()
		Events.toast_requested.emit(str(outcome.error))
		return
	var points := int(outcome.points)
	if outcome.has("stars"):
		result = outcome
		_show_result()
		return
	match phase:
		0:
			_feedback.text = "Muito bem!" if points == 1 else "Quase! Siga o tracejado na próxima."
			_play_pose()
		1:
			_feedback.text = ["Quase!", "Bom!", "Perfeito!"][points]
			if points > 0:
				Haptics.tap()
		2:
			_feedback.text = "Biscoito e carinho!" if points > 0 else "Biscoito para o Tiro!"
			repetition += 1
	phase = (phase + 1) % STEPS.size()
	_refresh_step()


func _play_pose() -> void:
	var clip := StringName(_def.lesson.get("puppy_clip", _def.animation) if GameState.dog_look().body == "puppy" else _def.animation)
	_animator.play_lesson_pose(clip)


func _finish_meal_gesture(success: bool) -> void:
	_serving = true
	_meal_buttons.hide()
	_feedback.text = "Muito bem!" if success else ("Quase! Vamos entregar." if _meal.has("order") else "Quase! Vamos comer.")
	if success:
		_play_pose()
	await get_tree().create_timer(0.65).timeout
	_serve_meal(success)


func _serve_meal(success: bool) -> void:
	if _closing:
		return
	_close()
	if WeekTutorial.enrolled() and not _meal.has("order") and not _asking:
		WeekTutorial.finish("meal_trick")
	_serve.call(_meal if success else {})


func _show_gesture(success: bool) -> void:
	var outcome := GameState.trick_show_step(trick_id, success)
	if outcome.has("error"):
		_back()
		Events.toast_requested.emit(str(outcome.error))
		return
	if outcome.get("retry", false):
		_feedback.text = "Quase! Tente esse truque de novo."
		return
	_play_pose()
	_feedback.text = "Muito bem!"
	if outcome.has("coins"):
		result = outcome
		_show_applause()
		return
	repetition = int(outcome.index) + 1
	trick_id = str(_sequence[int(outcome.index)])
	_def = Database.progression.tricks[trick_id]
	_refresh_step()


func _show_applause() -> void:
	var host := Control.new()
	host.name = "ShowResult"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(host)
	StepCardUi.stretch(host)
	var card := ModalCard.open(host, {"title": "Aplausos para o Tiro!", "icon": UiKit.ui_icon("trick_paw"),
		"haptic": "success", "confetti": true})
	card.add_text("A vovó e a Laís adoraram o show!")
	card.add_text("+%d moedas" % int(result.coins), &"TitleLabel")
	if int(result.biscuits) > 0:
		card.add_text("Show sem erros · +%d biscoitos" % int(result.biscuits))
	if bool(result.photo):
		card.add_text("Nova foto no Álbum · O show do Tiro")
	card.add_primary("Voltar ao tapete", _back).name = "ShowDone"


func _show_result() -> void:
	var host := Control.new()
	host.name = "LessonResult"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(host)
	StepCardUi.stretch(host)
	var stars := int(result.stars)
	var card := ModalCard.open(host, {
		"title": "Aula concluída!",
		"icon": UiKit.ui_icon(str(_def.icon)),
		"haptic": "success",
		"confetti": stars == 3,
	})
	card.add_text(str(_def.name), &"TitleLabel")
	var art := UiKit.icon(CookPanel.stars_texture(stars, true), 48)
	art.name = "LessonStars"
	art.custom_minimum_size.x = 150
	card.add(art)
	card.add_text("+%d %s" % [stars, "acerto" if stars == 1 else "acertos"], &"TitleLabel")
	card.add_text(TrickUi.level_name(trick_id) + " · " + TrickUi.level_progress(trick_id))
	card.add_text("Gastou 1 biscoito", &"SmallLabel")
	card.add_primary("Voltar ao caderno", _back).name = "LessonDone"


func _back() -> void:
	if _closing:
		return
	if _meal.has("order"):
		_serve_meal(false)
		return
	_close()
	if _is_lesson():
		if GameState.week.tutorial.erase("lesson"):
			Events.week_tutorial_changed.emit()
		GameState.cancel_trick_lesson(trick_id)
		TrickUi.open_lessons()
	elif not _sequence.is_empty():
		GameState.cancel_trick_show()
		TrickUi.open_show_panel()


func _close() -> void:
	_closing = true
	hide()
	queue_free()


func _exit_tree() -> void:
	if _current == self:
		_current = null
		if _is_lesson():
			GameState.cancel_trick_lesson(trick_id)
		elif not _sequence.is_empty():
			GameState.cancel_trick_show()


func tutorial_rect(id: String) -> Rect2:
	if not result.is_empty():
		return Rect2()
	match id:
		"meal_gesture":
			return _stage.get_global_rect() if name == "MealTrick" and not _asking and not _serving else Rect2()
		"show":
			return _stage.get_global_rect() if name == "TrickShow" else Rect2()
	if not _is_lesson() or id != "lesson_%s_%s" % [["show", "mark", "reward"][phase], trick_id]:
		return Rect2()
	match phase:
		1: return _mark.get_global_rect()
		2: return _reward.get_global_rect()
	return _stage.get_global_rect()
