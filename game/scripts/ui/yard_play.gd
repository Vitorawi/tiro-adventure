class_name YardPlay
extends Control
## Brincadeiras do Sítio. O palco converte o toque em coordenadas relativas para o GameState.

const FARM := preload("res://assets/sprites/areas/farm/figma_cena.webp")
const GRASS := preload("res://assets/sprites/areas/common/grass_ground.png")
const HEN := preload("res://assets/sprites/areas/farm/chicken.png")
const FLOWER := preload("res://assets/sprites/ui/icons/item_wildflower.png")
const RUG := preload("res://assets/sprites/areas/house/paw_rug.png")
const INK := Color("59391e")
const PRESS_RADIUS := 31.0
static var current: YardPlay

var kind := ""
var round_data: Dictionary
var result: Dictionary = {}
var landing: Dictionary = {}
var _rules: Dictionary
var _stage: Control
var _dog: TextureRect
var _animator: PetAnimator
var _score: Label
var _record: Label
var _hint: Label
var _feedback: Label
var _jump: Button
var _again: Button
var _track: ProgressBar
var _finger := Vector2.ZERO
var _start := Vector2.ZERO
var _dragging := false
var _pointer := -1
var _jump_pose := false
var _dog_at := Vector2(0.70, 0.70)
var _motion: Tween
var _squeaker: AudioStreamPlayer


static func open() -> void:
	Places.open("farm", "week_yard")


static func menu() -> Control:
	var column := UiKit.vbox(8)
	column.set_meta("sheet_wood", true)
	var modes := [
		["ball", "Bolinha no quintal", "YardBall"],
		["rope", "Cabo de guerra", "YardRope"],
		["hide", "Esconde-esconde", "YardHide"],
		["name", "Tiro!", "YardName"],
	]
	for mode: Array in modes:
		var id := str(mode[0])
		var caption := str(mode[1])
		var locked := not GameState.yard_open(id)
		var button := StepCardUi.locked_button(caption) if locked else WelcomeSheet._button(caption, false, 240, str(mode[2]), start.bind(id))
		button.name = str(mode[2])
		button.disabled = locked
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 48.0
		column.add_child(button)
	return column


static func start(mode: String) -> void:
	if is_instance_valid(current): return
	if mode == "hide":
		var hide := HideSeekUi.new()
		hide.name = "YardHideSeek"
		var error := hide.start_yard()
		if error != "":
			hide.free()
			Events.toast_requested.emit(error)
		else:
			Events.sheet_requested.emit("Esconde-esconde", hide)
		return
	var round := GameState.start_yard_round(mode)
	if round.has("error"):
		Events.toast_requested.emit(str(round.error))
		return
	var game := YardPlay.new()
	game.kind = mode
	game.round_data = round
	game.name = "YardPlay"
	current = game
	Events.sheet_close_requested.emit()
	var root := GameState.get_tree().root
	var host := root.get_node_or_null("Main")
	(host if host != null else root).add_child(game)


func _ready() -> void:
	_rules = GameState.yard_rules()
	z_index = 13
	z_as_relative = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = HomeUi.theme(17)
	var background := ColorRect.new()
	background.color = Color("f1e4c8")
	add_child(background)
	StepCardUi.stretch(background)
	BagUi.frame(self, "frame", Vector4(14, 150, 14, 77), "YardFrame")
	var padding := MarginContainer.new()
	add_child(padding)
	StepCardUi.stretch(padding)
	for side: String in ["left", "right", "top", "bottom"]:
		padding.add_theme_constant_override("margin_" + side, 24)
	var column := UiKit.vbox(8)
	padding.add_child(column)
	var header := UiKit.hbox(8)
	column.add_child(header)
	var title := StepCardUi.wood(str({"ball": "Bolinha no quintal", "rope": "Cabo de guerra", "name": "Tiro!"}[kind]), 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(WelcomeSheet._button("Sair", false, 57.0, "YardExit", _close))
	var scoreboard := UiKit.hbox(6)
	column.add_child(scoreboard)
	var score_inset := Control.new()
	score_inset.custom_minimum_size.x = 10.0
	scoreboard.add_child(score_inset)
	_score = StepCardUi.wood("", 18)
	_score.name = "YardScore"
	_score.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scoreboard.add_child(_score)
	_record = StepCardUi.wood("", 17)
	_record.name = "YardRecord"
	_record.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	scoreboard.add_child(_record)
	scoreboard.visible = kind != "name"
	_stage = Control.new()
	_stage.name = "YardStage"
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.clip_contents = true
	_stage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_stage.draw.connect(_draw_stage)
	_stage.resized.connect(_stage.queue_redraw)
	_stage.gui_input.connect(_stage_input)
	column.add_child(_stage)
	_dog = UiKit.icon(null, 154)
	_dog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_dog)
	_animator = PetAnimator.new()
	add_child(_animator)
	_animator.setup(_dog)
	if kind == "ball":
		_squeaker = AudioStreamPlayer.new()
		_squeaker.stream = _squeak_sound()
		add_child(_squeaker)
	_track = ProgressBar.new()
	_track.max_value = 1.0
	_track.show_percentage = false
	_track.custom_minimum_size.y = 12
	_track.add_theme_stylebox_override("background", UiKit.surface(Color("dfc59a"), 5))
	_track.add_theme_stylebox_override("fill", UiKit.surface(Color("a86c38"), 5))
	_track.visible = kind == "rope"
	column.add_child(_track)
	_hint = _centered_copy(column, "YardHint", 16, 42)
	_feedback = _centered_copy(column, "YardFeedback", 17, 48)
	var actions := Control.new()
	actions.custom_minimum_size.y = 55
	column.add_child(actions)
	_jump = StepCardUi.go_button("Pula!", _jump_now)
	_jump.name = "YardJump"
	_again = StepCardUi.go_button("Jogar de novo", _restart)
	_again.name = "YardAgain"
	for button: Button in [_jump, _again]:
		actions.add_child(button)
		StepCardUi.stretch(button)
		button.hide()
	_begin()


func _centered_copy(parent: Control, node_name: String, font_size: int, height: int) -> Label:
	var copy := StepCardUi.wood("", font_size)
	copy.name = node_name
	copy.custom_minimum_size.y = height
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(copy)
	return copy


func _begin() -> void:
	result.clear()
	landing.clear()
	_feedback.text = ""
	_again.hide()
	_track.visible = kind == "rope"
	_track.value = 0.0
	_dog_at = Vector2(0.70, 0.70) if kind == "ball" else Vector2(0.50, 0.39)
	match kind:
		"ball":
			_hint.text = "Puxe a bolinha para trás e solte." if round_data.variant.fetch else "Toque na bolinha de pano ou puxe para jogar."
			_feedback.text = "Lagoa · a bolinha quica na ponte" if round_data.variant.lake else ("A bolinha que apita vai mais longe!" if round_data.variant.squeak else "")
		"rope":
			_hint.text = "Segure a cordinha. Solte quando a barra ficar verde!"
		"name":
			_hint.text = "Tiro ouviu você!"
			_animator.play_lesson_pose(&"head_tilt")
			_move_dog(Vector2(0.50, 0.75), 0.75)
	_sync_score(0, 0)
	_stage.queue_redraw()


func _squeak_sound() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 16000
	var samples := PackedByteArray()
	var length := 2240
	samples.resize(length * 2)
	var phase := 0.0
	for i in length:
		var t := float(i) / length
		phase += TAU * lerpf(1550.0, 680.0, t) / stream.mix_rate
		var envelope := sin(PI * t) * (1.0 - t)
		samples.encode_s16(i * 2, roundi((sin(phase) + 0.3 * sin(phase * 2.0)) * envelope * 7200))
	stream.data = samples
	return stream


func _sync_score(turn: int, points: int) -> void:
	if kind == "ball":
		_score.text = "%d pts   ·   %d/%d" % [points, turn, int(_rules.throws)]
		_record.text = "Recorde  %d" % GameState.yard_record()
	elif kind == "rope":
		_score.text = "Puxões  %d/%d" % [turn, int(_rules.pulls)]
		_record.text = "%d no ritmo" % points


func _origin() -> Vector2:
	return _point(_rules.launch.origin) * _stage.size


func _point(pair: Array) -> Vector2:
	return Vector2(float(pair[0]), float(pair[1]))


func _process(_delta: float) -> void:
	_dog.position = _dog_at * _stage.size - _dog.size * Vector2(0.5, 0.84)
	if _dragging or not landing.is_empty(): _stage.queue_redraw()
	if result.get("done", false): return
	match kind:
		"ball":
			if landing.is_empty(): return
			var elapsed := GameState.yard_jump_elapsed(int(round_data.id))
			var jumping := bool(round_data.variant.fetch) and elapsed >= float(_rules.jump.opens) and elapsed <= float(_rules.jump.closes)
			_jump.visible = jumping
			if jumping and not _jump_pose:
				_jump_pose = true
				_animator.play_lesson_pose(&"happy_jump")
				_hop()
			if elapsed >= float(_rules.jump.closes if round_data.variant.fetch else _rules.jump.opens):
				_accept_throw(GameState.yard_finish_throw(int(round_data.id), false))
		"rope":
			var elapsed := GameState.yard_rope_elapsed(int(round_data.id))
			if elapsed < 0.0: return
			var timing: Dictionary = _rules.rope
			_track.value = elapsed / float(timing.max_hold)
			var on_time := elapsed >= float(timing.opens) and elapsed <= float(timing.closes)
			_track.modulate = Color("9be797") if on_time else Color.WHITE
			_hint.text = "Solte agora!" if on_time else ("Solte para o próximo puxão." if elapsed > float(timing.closes) else "Segure…")
		"name":
			var answer := GameState.yard_answer_name(int(round_data.id))
			if not answer.is_empty():
				result = answer
				_hint.text = "Ele veio quando você chamou!"
				_animator.play_lesson_pose(&"pet_head")
				_again.text = "Chamar de novo"
				_again.show()


func _move_dog(destination: Vector2, seconds: float) -> void:
	if _motion and _motion.is_valid(): _motion.kill()
	if Motion.reduced:
		_dog_at = destination
		return
	_motion = create_tween()
	_motion.tween_property(self, "_dog_at", destination, seconds).set_trans(Tween.TRANS_SINE)


func _hop() -> void:
	if Motion.reduced: return
	var ground := _dog_at
	_move_dog(ground - Vector2(0, 0.085), 0.23)
	_motion.tween_property(self, "_dog_at", ground, 0.35).set_trans(Tween.TRANS_SINE)


func _stage_input(event: InputEvent) -> void:
	if result.get("done", false) or kind == "name" or not landing.is_empty(): return
	if event is InputEventScreenTouch:
		if event.pressed: _press(event.position, event.index)
		elif _dragging and event.index == _pointer: _release(event.position, event.canceled)
	elif event is InputEventScreenDrag and _dragging and event.index == _pointer:
		_finger = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: _press(event.position, -1)
		elif _dragging and _pointer == -1: _release(event.position, false)
	elif event is InputEventMouseMotion and _dragging and _pointer == -1:
		_finger = event.position
	_stage.accept_event()


func _press(point: Vector2, pointer: int) -> void:
	if _dragging: return
	if kind == "ball" and point.distance_to(_origin()) > PRESS_RADIUS: return
	if kind == "rope":
		if point.distance_to(_stage.size * Vector2(0.5, 0.68)) > 72.0: return
		if not GameState.yard_rope_hold(int(round_data.id)): return
	_dragging = true
	_pointer = pointer
	_start = point
	_finger = point


func _release(point: Vector2, canceled: bool) -> void:
	_dragging = false
	_stage.queue_redraw()
	if kind == "rope":
		var pull := GameState.yard_rope_release(int(round_data.id), canceled)
		_hint.text = "Segure a cordinha. Solte no verde!"
		if pull.is_empty(): return
		_track.value = 1.0
		_track.modulate = Color("9be797") if pull.hit else Color.WHITE
		_feedback.text = "No ritmo!" if pull.hit else "Tiro puxou primeiro!"
		_animator.play_lesson_pose(&"lick_paw" if pull.hit else &"head_tilt")
		_sync_score(int(pull.turn), int(pull.score))
		if pull.get("done", false): _finish(pull)
	elif not canceled:
		landing = GameState.yard_throw(int(round_data.id), (_start - point) / _stage.size)
		if landing.is_empty(): return
		_jump_pose = false
		if round_data.variant.squeak: _squeaker.play()
		if not round_data.variant.fetch: _animator.react(&"play")
		_hint.text = "Toque em Pula! quando Tiro saltar." if round_data.variant.fetch else "Tiro foi buscar!"
		var target: Vector2 = landing.end
		_move_dog(target + Vector2(0.06, 0.09), float(_rules.jump.opens))


func _jump_now() -> void:
	_accept_throw(GameState.yard_finish_throw(int(round_data.id), true))


func _accept_throw(outcome: Dictionary) -> void:
	if outcome.is_empty(): return
	landing.clear()
	_stage.queue_redraw()
	_jump.hide()
	_feedback.text = str(outcome.label)
	if outcome.jump: _feedback.text = "Pegou no ar! ×2 · +%d pts" % int(outcome.points)
	elif int(outcome.points) > 0: _feedback.text += " · +%d pts" % int(outcome.points)
	match str(outcome.hit):
		"mud": _animator.play_lesson_pose(&"shake_off")
		"hen": _animator.play_lesson_pose(&"bark")
		"pot": _animator.play_lesson_pose(&"look_around")
	_move_dog(Vector2(0.70, 0.70), 0.55)
	_hint.text = "Puxe a bolinha para trás e solte." if round_data.variant.fetch else "Toque na bolinha de pano ou puxe para jogar."
	_sync_score(int(outcome.turn), int(outcome.score))
	if outcome.get("done", false): _finish(outcome)


func _finish(outcome: Dictionary) -> void:
	result = outcome
	var rewards := PackedStringArray()
	if int(outcome.happiness) > 0: rewards.append("+%d Felicidade" % int(outcome.happiness))
	if int(outcome.smart) > 0: rewards.append("Momento de Esperteza")
	if int(outcome.coins) > 0: rewards.append("+%d moedas pelo recorde" % int(outcome.coins))
	_hint.text = "Só por diversão neste período." if not outcome.rewarded else " · ".join(rewards)
	if _hint.text == "": _hint.text = "Contou para crescer!"
	_feedback.text = "Fim da partida!" if kind == "ball" else "Três puxões!"
	_track.hide()
	_animator.play_lesson_pose(&"belly_enter")
	_again.show()


func _restart() -> void:
	var new_round := GameState.start_yard_round(kind)
	if new_round.has("error"):
		Events.toast_requested.emit(str(new_round.error))
		return
	round_data = new_round
	_begin()


func _close() -> void:
	GameState.cancel_yard_round(int(round_data.id))
	current = null
	hide()
	queue_free()


func _exit_tree() -> void:
	GameState.cancel_yard_round(int(round_data.id))
	if current == self: current = null


func _draw_stage() -> void:
	var extent := _stage.size
	var horizon := extent.y * 0.23
	_stage.draw_texture_rect(GRASS, Rect2(Vector2.ZERO, extent), true, Color("dce1a5"))
	var farm_crop := Rect2(478, 697, 630, 630 * horizon / maxf(extent.x, 1))
	_stage.draw_texture_rect_region(FARM, Rect2(0, 0, extent.x, horizon), farm_crop)
	_stage.draw_line(Vector2(0, horizon), Vector2(extent.x, horizon), Color("704d2f"), 3)
	match kind:
		"ball": _draw_ball_field(extent)
		"rope":
			var center := extent * Vector2(0.50, 0.68)
			var upper := extent * Vector2(0.5, 0.42)
			if _dragging: center.y += 20
			_stage.draw_line(upper, center, INK, 16.0, true)
			_stage.draw_line(upper, center, Color("d6a454"), 10.0, true)
			for i: int in 12:
				var mark := upper.lerp(center, float(i) / 11.0)
				_stage.draw_line(mark + Vector2(-5, -2), mark + Vector2(5, 2), Color("9f653a"), 2.0, true)
			_stage.draw_circle(center, 23, INK, false, 5, true)
			_stage.draw_circle(center, 23, Color("d6a454"), false, 3, true)
		"name":
			var rug := Rect2(extent * Vector2(0.5, 0.80) - Vector2(53, 24), Vector2(106, 48))
			_stage.draw_texture_rect(RUG, rug, false)


func _draw_ball_field(extent: Vector2) -> void:
	if bool(round_data.variant.lake):
		_stage.draw_texture_rect_region(FARM, Rect2(extent * Vector2(0.30, 0.20), extent * Vector2(0.37, 0.23)), Rect2(245, 1050, 385, 300))
		var b: Array = _rules.bridge
		var bridge := Rect2(Vector2(b[0], b[1]) * extent, Vector2(b[2], b[3]) * extent)
		_stage.draw_rect(bridge, INK)
		for i: int in 7:
			var width := bridge.size.x / 7.0
			_stage.draw_rect(Rect2(bridge.position + Vector2(i * width + 1, 2), Vector2(width - 2, bridge.size.y - 4)), Color("d29b53"))
	if round_data.variant.fetch:
		for band: float in _rules.bands:
			_stage.draw_dashed_line(Vector2(0, band * extent.y), Vector2(extent.x, band * extent.y), Color("f9eec5b0"), 2, 8, true, true)
		for target: Dictionary in _rules.targets:
			_draw_target(str(target.id), _point(target.at) * extent)
	if result.get("done", false): return
	var ball_at := _origin()
	if not landing.is_empty():
		var elapsed := GameState.yard_jump_elapsed(int(round_data.id))
		var path_time := clampf(elapsed / float(_rules.jump.opens), 0.0, 1.0)
		var target: Vector2 = landing.end
		if landing.bounce:
			var bridge: Vector2 = landing.bridge
			ball_at = _origin().lerp(bridge * extent, path_time * 2) if path_time < 0.5 else (bridge * extent).lerp(target * extent, path_time * 2 - 1)
		else:
			ball_at = _origin().lerp(target * extent, path_time)
		if not Motion.reduced: ball_at.y -= sin(path_time * PI) * 51.0
	elif _dragging:
		var flight := GameState.yard_flight(int(round_data.id), (_start - _finger) / extent)
		if not flight.is_empty():
			var target: Vector2 = flight.end
			var first := flight.get("bridge", target) as Vector2
			_stage.draw_dashed_line(ball_at, first * extent, Color("fff5d8"), 4, 8, true, true)
			if flight.bounce: _stage.draw_dashed_line(first * extent, target * extent, Color("f5d470"), 4, 8, true, true)
			ball_at += (_finger - _start).limit_length(42)
	var color := Color("efa84a") if round_data.variant.squeak else Color("be553e")
	_stage.draw_circle(ball_at + Vector2(0, 4), 17, Color("633c2855"), true, -1, true)
	_stage.draw_circle(ball_at, 16, INK, true, -1, true)
	_stage.draw_circle(ball_at, 13, color, true, -1, true)
	_stage.draw_arc(ball_at + Vector2(-3, 0), 8, -1.2, 1.1, 9, Color("ffdda4"), 2, true)


func _draw_target(id: String, at: Vector2) -> void:
	match id:
		"arch":
			_stage.draw_arc(at, 22, PI, TAU, 20, Color("49643b"), 7, true)
			for offset: Vector2 in [Vector2(-20, -10), Vector2(0, -22), Vector2(20, -10)]:
				_stage.draw_texture_rect(FLOWER, Rect2(at + offset - Vector2(11, 11), Vector2(22, 22)), false)
			_draw_points(at, "3")
		"bucket":
			_stage.draw_colored_polygon(PackedVector2Array([at + Vector2(-20, -10), at + Vector2(20, -10), at + Vector2(14, 17), at + Vector2(-14, 17)]), Color("b9d3d5"))
			_stage.draw_line(at + Vector2(-20, -10), at + Vector2(20, -10), Color("46676b"), 5, true)
			_draw_points(at, "2")
		"mud":
			_stage.draw_set_transform(at, 0, Vector2(1.6, 0.58))
			_stage.draw_circle(Vector2.ZERO, 19, Color("8a6240"), true, -1, true)
			_stage.draw_set_transform(Vector2.ZERO)
		"hen":
			_stage.draw_texture_rect(HEN, Rect2(at - Vector2(21, 23), Vector2(42, 42)), false)
		"pot":
			_stage.draw_colored_polygon(PackedVector2Array([at + Vector2(-16, -9), at + Vector2(16, -9), at + Vector2(10, 16), at + Vector2(-10, 16)]), Color("aa5635"))
			_stage.draw_texture_rect(FLOWER, Rect2(at - Vector2(15, 30), Vector2(30, 30)), false)


func _draw_points(at: Vector2, caption: String) -> void:
	_stage.draw_circle(at + Vector2(0, 11), 10, INK, true, -1, true)
	_stage.draw_string(ThemeDB.fallback_font, at + Vector2(-4, 16), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("fff4dc"))


func tutorial_rect() -> Rect2:
	if kind == "ball" and not landing.is_empty():
		return Rect2()
	var at := _stage.get_global_rect()
	var point := at.position + _origin()
	return Rect2(point - Vector2(40, 56), Vector2(84, 100)) if kind == "ball" else at
