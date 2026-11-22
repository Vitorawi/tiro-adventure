class_name CookTogether
extends Control
## "Cozinhar junto" (Primeira semana, E04): o minigame do fogão à tigela, em tela cheia por cima de tudo.
## Três passos de 8 a 12 s — Picar (deslizar sobre a linha), Mexer (girar o dedo em volta da panela) e Servir (arrastar a
## concha até a tigela e jogar o coração) — rendem de 1 a 3 brilhos cada; a soma vira 1 a 3 estrelas, que cortam o tempo do
## lote na fila (`CookRules`, `data/cooking.json`). Nada queima e nada se perde: os ingredientes só são gastos no fim do
## Servir (ou ao Pular, que cozinha como o botão Cozinhar, 1 estrela e tempo cheio). Sair (X ou Esc) não gasta nada.
## No fim abre o cartão "Prato pronto!" (ModalCard de madeira): Dar ao Tiro (serve na hora) ou Guardar (fica na fila).
##
## Tudo é desenhado por código numa tela virtual de 360×780 (arte provisória, ver PROVISORIOS.md) escalada para caber.
## O toque é o mouse emulado: o overlay recebe `InputEventMouse*`.
##
## `open(host, spec)` com spec = {name, output, items (ids de item, um por unidade), check: Callable() -> String,
## cook: Callable(stars, together) -> String, on_done: Callable() (opcional)}.
## Nós: `CookTogether`, `SkipButton`, `QuitButton`, `CookResultHost` (cartão `GiveToTiro`, `KeepDish`, `ResultStars`, `TimeChip`).

const W := 360.0
const H := 780.0
const STRIP_START := 56.0
const STRIP_END := 304.0
const STRIP_Y := 322.0
const STRIP_H := 46.0
const BOARD := Rect2(30, 252, 300, 214)
const POT_CENTER := Vector2(180, 424)
const TRACK_R := 150.0
const POT_R := 112.0
const POT_RECT := Rect2(24, 348, 150, 112)
const BOWL_CENTER := Vector2(272, 566)
const HEART_HOME := Vector2(180, 690)
const STEP_X: Array[float] = [112.0, 170.0, 228.0]
const SKIP_RECT := Rect2(268, 27, 72, 44)
const QUIT_RECT := Rect2(18, 27, 44, 44)
const PAUSE_SECONDS := 0.55
const INK := Color("2f2414")
const CREAM := Color("fff8ea")
const GREEN := Color("3f7a2e")
const GOLD := Color("f0b429")
const BROWN := Color("8c5a33")

static var _current: CookTogether

var spec: Dictionary = {}
var phase := "picar"
var brilhos: Array[int] = []
var closing := false
var result: Dictionary = {}

var _time := 0.0
var _scale := 1.0
var _origin := Vector2.ZERO
var _items: Array[String] = []
var _font: Font
var _tiro: Texture2D
var _tiro_bounce := 0.0
var _pause := 0.0
var _next_phase := ""
var _skip_btn: Button
var _quit_btn: Button
var _popups: Array[Dictionary] = []

# Picar
var _cuts_each := 3
var _ing_index := 0
var _cut_index := 0
var _strip_start := STRIP_START
var _scores: Array[int] = []
var _pieces: Array[Dictionary] = []
var _bowl_pieces := 0
var _swiping := false
var _swipe_done := false
var _swipe_start := Vector2.ZERO
var _cuts_total := 0
var _cuts_done := 0

# Mexer
var ring := 0.0
var stir_elapsed := 0.0
var stir_zone_now := "slow"
var _stirring := false
var _stir_started := false
var _stir_prev := 0.0
var _stir_accum := 0.0
var _spoon_angle := -0.8
var _swirl := 0.0
var _splashes: Array[Dictionary] = []

# Servir
var scoops_done := 0
var heart_phase := false
var _misses := 0
var _dragging := ""
var _ladle_full := false
var _drag_pos := Vector2.ZERO
var _bowl_fill := 0.0
var _serve_scores: Array[int] = []


# --- Abrir / fechar ---------------------------------------------------------------------

static func open(host: Node, options: Dictionary) -> CookTogether:
	if is_instance_valid(_current):
		_current.cancel()
	var err := ""
	if (options.get("check", Callable()) as Callable).is_valid():
		err = str((options.check as Callable).call())
	if err != "":
		Events.toast_requested.emit(err)
		return null
	var game := CookTogether.new()
	game.name = "CookTogether"
	game.spec = options
	_current = game
	host.add_child(game)
	game._start()
	return game


static func current() -> CookTogether:
	return _current if is_instance_valid(_current) and not _current.closing else null


func _start() -> void:
	z_index = 11
	z_as_relative = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_font = HomeUi.theme(16, INK).default_font
	_tiro = HomeUi.head_texture()
	for item: Variant in spec.get("items", []):
		_items.append(str(item))
	if _items.is_empty():
		_items.append("carrot")
	var rules: Dictionary = Database.cooking.get("picar", {})
	_cuts_each = clampi(ceili(float(rules.get("cuts", 6)) / _items.size()), int(rules.get("min_cuts_each", 2)), int(rules.get("max_cuts_each", 6)))
	_cuts_total = _cuts_each * _items.size()
	_skip_btn = _flat_button("SkipButton", "Pular")
	_quit_btn = _flat_button("QuitButton", "Sair")
	_skip_btn.pressed.connect(skip)
	_quit_btn.pressed.connect(cancel)
	resized.connect(_layout)
	_layout()
	_restore_tutorial_checkpoint()
	set_process(true)
	set_process_unhandled_key_input(true)


func _flat_button(node_name: String, hint: String) -> Button:
	var button := BagUi.plain_button(func() -> void: pass)
	button.name = node_name
	button.tooltip_text = hint
	button.focus_mode = Control.FOCUS_NONE
	add_child(button)
	return button


func _layout() -> void:
	_scale = minf(size.x / W, size.y / H)
	_origin = (size - Vector2(W, H) * _scale) / 2.0
	_place(_skip_btn, SKIP_RECT)
	_place(_quit_btn, QUIT_RECT)
	queue_redraw()


func _place(button: Control, rect: Rect2) -> void:
	if button != null:
		button.position = _origin + rect.position * _scale
		button.size = rect.size * _scale


## Ponto da tela virtual (360×780) em coordenadas do Control: serve ao desenho, ao toque e aos testes.
func to_screen(point: Vector2) -> Vector2:
	return _origin + point * _scale


func _to_virtual(point: Vector2) -> Vector2:
	return (point - _origin) / maxf(_scale, 0.001)


func cancel() -> void:
	if GameState.week.tutorial.erase("cooking"):
		Events.week_tutorial_changed.emit()
	_close()


## Pular: cozinha como o botão Cozinhar (1 estrela, tempo cheio) e fecha. Nada queima, nada se perde.
func skip() -> void:
	if closing or phase == "result":
		return
	var err := str((spec.cook as Callable).call(1, false))
	if err != "":
		Events.toast_requested.emit(err)
	else:
		Events.toast_requested.emit("%s na fila" % str(spec.get("name", "Prato")))
		_done()
	_close()


func _done() -> void:
	var on_done: Callable = spec.get("on_done", Callable())
	if on_done.is_valid():
		on_done.call()


func _close() -> void:
	if closing:
		return
	closing = true
	if _current == self:
		_current = null
	queue_free()


func _exit_tree() -> void:
	if _current == self:
		_current = null


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and key.keycode == KEY_ESCAPE and phase != "result" and not closing:
		cancel()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and phase != "result" and not closing:
		cancel()


# --- Tempo ------------------------------------------------------------------------------

func _process(delta: float) -> void:
	tick(delta)


## Avança o relógio do minigame (a cena chama a cada quadro; os testes chamam com um passo fixo).
func tick(delta: float) -> void:
	if closing:
		return
	_time += delta
	_tiro_bounce = maxf(0.0, _tiro_bounce - delta * 3.0)
	for popup in _popups:
		popup.t = float(popup.t) + delta
	_popups.assign(_popups.filter(func(p: Dictionary) -> bool: return float(p.t) < 0.9))
	for piece in _pieces:
		piece.t = float(piece.t) + delta
	_bowl_pieces += _pieces.filter(func(p: Dictionary) -> bool: return float(p.t) >= 0.35).size()
	_pieces.assign(_pieces.filter(func(p: Dictionary) -> bool: return float(p.t) < 0.35))
	for splash in _splashes:
		splash.t = float(splash.t) + delta
	_splashes.assign(_splashes.filter(func(s: Dictionary) -> bool: return float(s.t) < 0.5))
	if _pause > 0.0:
		_pause -= delta
		if _pause <= 0.0:
			_enter(_next_phase)
	elif phase == "mexer":
		_tick_stir(delta)
	queue_redraw()


func _tick_stir(delta: float) -> void:
	var speed := _stir_accum / maxf(delta, 0.0001)
	_stir_accum = 0.0
	if not _stir_started:
		return
	stir_elapsed += delta
	stir_zone_now = CookRules.stir_zone(speed) if _stirring else "slow"
	if stir_zone_now == "good":
		ring = minf(1.0, ring + delta / float(Database.cooking.get("mexer", {}).get("seconds_full", 8.0)))
		_swirl += delta * 2.0
	elif stir_zone_now == "fast" and not Motion.reduced and _splashes.size() < 8:
		_splashes.append({"t": 0.0, "angle": randf() * TAU})
	if ring >= 1.0:
		_finish_step(CookRules.stir_brilho(stir_elapsed))


# --- Passos -----------------------------------------------------------------------------

func _finish_step(value: int) -> void:
	brilhos.append(clampi(value, 1, 3))
	Haptics.success()
	_pause = PAUSE_SECONDS
	_next_phase = {"picar": "mexer", "mexer": "servir", "servir": "commit"}.get(phase, "commit")
	phase = "pause_" + phase
	_stirring = false
	_swiping = false
	_dragging = ""


func _enter(next: String) -> void:
	if next == "commit":
		_commit()
		return
	phase = next
	if WeekTutorial.enrolled() and not WeekTutorial.record("cook").get("done", false):
		GameState.week.tutorial.cooking = {"phase": phase, "brilhos": brilhos.duplicate(), "output": spec.get("output", ""), "items": _items.duplicate(), "key": spec.get("mastery_key", "")}
		Events.week_tutorial_changed.emit()
	_popups.clear()


func total_brilhos() -> int:
	var total := 0
	for value in brilhos:
		total += value
	return total


func _commit() -> void:
	var stars := CookRules.stars_for(total_brilhos())
	var queue_before := GameState.station("stove").queue.size()
	var err := str((spec.cook as Callable).call(stars, true))
	if err != "":
		Events.toast_requested.emit(err)
		_close()
		return
	var entry: Dictionary = GameState.station("stove").queue[queue_before]
	result = {"stars": stars, "index": queue_before, "output": Database.entry_output(entry), "seconds": Database.entry_seconds(entry)}
	phase = "result"
	if WeekTutorial.enrolled():
		WeekTutorial.finish("cook")
		GameState.week.tutorial.erase("cooking")
	_done()
	_show_result()


# --- Toque ------------------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	if button == null and motion == null:
		return
	accept_event()
	if _pause > 0.0 or phase == "result" or closing:
		return
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		var point := _to_virtual(button.position)
		if button.pressed:
			_press(point)
		else:
			_release(point)
	elif motion != null:
		_move(_to_virtual(motion.position))


func _press(point: Vector2) -> void:
	match phase:
		"picar":
			if BOARD.grow(24.0).has_point(point):
				_swiping = true
				_swipe_done = false
				_swipe_start = point
		"mexer":
			var distance := point.distance_to(POT_CENTER)
			if distance >= 40.0 and distance <= TRACK_R + 50.0:
				_stirring = true
				_stir_started = true
				_stir_prev = (point - POT_CENTER).angle()
				_spoon_angle = _stir_prev
		"servir":
			if heart_phase:
				if point.distance_to(HEART_HOME) <= 46.0:
					_dragging = "heart"
					_drag_pos = point
			elif POT_RECT.grow(14.0).has_point(point):
				_dragging = "ladle"
				_ladle_full = true
				_drag_pos = point


func _move(point: Vector2) -> void:
	match phase:
		"picar":
			if _swiping and not _swipe_done:
				var delta := point - _swipe_start
				var min_swipe := float(Database.cooking.get("picar", {}).get("min_swipe", 60))
				if absf(delta.y) >= min_swipe and absf(delta.y) >= absf(delta.x):
					_swipe_done = true
					_cut(_swipe_start.x + delta.x * 0.5)
		"mexer":
			if _stirring and point.distance_to(POT_CENTER) >= 20.0:
				var angle := (point - POT_CENTER).angle()
				_stir_accum += absf(wrapf(angle - _stir_prev, -PI, PI))
				_stir_prev = angle
				_spoon_angle = angle
		"servir":
			if _dragging != "":
				_drag_pos = point


func _release(point: Vector2) -> void:
	_swiping = false
	_stirring = false
	if phase != "servir" or _dragging == "":
		return
	var what := _dragging
	_dragging = ""
	if what == "heart":
		if point.distance_to(BOWL_CENTER) <= float(Database.cooking.get("servir", {}).get("target_outer", 64)) * 1.4:
			_finish_step(CookRules.average_brilho(_serve_scores))
		return
	if POT_RECT.grow(14.0).has_point(point):
		return  # só tocou na panela: a concha fica cheia, esperando o arrasto
	var distance := point.distance_to(BOWL_CENTER)
	var value := CookRules.serve_brilho(distance / _mastery_gesture_scale(), _misses)
	if value == 0:
		_misses += 1
		_ladle_full = false
		_popup(str(Database.cooking.lines.retry), point, GOLD)
		return
	_serve_scores.append(value)
	_misses = 0
	scoops_done += 1
	_ladle_full = false
	_bowl_fill = float(scoops_done) / float(Database.cooking.get("servir", {}).get("scoops", 2))
	_reward_popup(value, BOWL_CENTER + Vector2(0, -50))
	if scoops_done >= int(Database.cooking.get("servir", {}).get("scoops", 2)):
		heart_phase = true


# --- Picar ------------------------------------------------------------------------------

## x da linha tracejada do próximo corte: divide ao meio o que ainda sobra do ingrediente.
func _mastery_gesture_scale() -> float:
	return float(GameState.recipe_mastery(str(spec.get("mastery_key", ""))).get("gesture_scale", 1.0))


func guide_x() -> float:
	var left := _cuts_each - _cut_index
	return _strip_start + (STRIP_END - _strip_start) / float(left + 1)


func _cut(x: float) -> void:
	var score := CookRules.cut_brilho(absf(x - guide_x()) / _mastery_gesture_scale())
	_scores.append(score)
	var cut_x := clampf(x, _strip_start + 8.0, STRIP_END - 8.0)
	_pieces.append({"x0": _strip_start, "x1": cut_x, "t": 0.0, "color": _item_color(_items[_ing_index])})
	_strip_start = cut_x
	_cut_index += 1
	_cuts_done += 1
	_reward_popup(score, Vector2(clampf(cut_x, 60.0, 300.0), STRIP_Y + STRIP_H + 44.0))
	if _cut_index >= _cuts_each:
		_pieces.append({"x0": _strip_start, "x1": STRIP_END, "t": 0.0, "color": _item_color(_items[_ing_index])})
		_ing_index += 1
		_cut_index = 0
		_strip_start = STRIP_START
		if _ing_index >= _items.size():
			_finish_step(CookRules.average_brilho(_scores))


func _reward_popup(score: int, point: Vector2) -> void:
	var lines: Dictionary = Database.cooking.lines
	_popup(str(lines.perfect if score == 3 else (lines.good if score == 2 else lines.bad)), point, GREEN if score >= 2 else BROWN)
	Haptics.tap()
	if score == 3 and not Motion.reduced:
		_tiro_bounce = 1.0


func _popup(text: String, point: Vector2, color: Color) -> void:
	_popups.clear()  # um aviso por vez: o último corte cobre o anterior
	_popups.append({"text": text, "pos": point, "t": 0.0, "color": color})


func _item_color(item: String) -> Color:
	var colors: Dictionary = Database.cooking.get("colors", {})
	var ingredient := DishRules.ingredient_of_item(item)
	return Color(str(colors.get(ingredient, colors.get("default", "e0b070"))))


func _broth_color() -> Color:
	var total := Color(0, 0, 0, 1)
	for item in _items:
		var c := _item_color(item)
		total += Color(c.r, c.g, c.b, 0.0)
	var n := float(_items.size())
	return Color(total.r / n, total.g / n, total.b / n, 1.0).lerp(Color.WHITE, 0.35)


# --- Desenho ----------------------------------------------------------------------------

func _draw() -> void:
	if _font == null:
		return
	var bg := Color("c99a64")
	var shown := phase.trim_prefix("pause_")
	if shown == "mexer":
		bg = Color("4a4a4a")
	draw_rect(Rect2(Vector2.ZERO, size), bg)
	draw_set_transform(_origin, 0.0, Vector2(_scale, _scale))
	match shown:
		"picar": _draw_picar()
		"mexer": _draw_mexer()
		_: _draw_servir()
	_draw_tiro()
	_draw_bar(shown)
	for popup in _popups:
		var t := float(popup.t)
		var color: Color = popup.color
		color.a = 1.0 - t / 0.9
		var rise := 0.0 if Motion.reduced else t * 30.0
		_text(str(popup.text), (popup.pos as Vector2) + Vector2(0, -rise), 20, color, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _text(value: String, point: Vector2, px: int, color: Color = INK, center: bool = false, width: float = 0.0) -> void:
	var at := point
	var align := HORIZONTAL_ALIGNMENT_LEFT
	if center:
		align = HORIZONTAL_ALIGNMENT_CENTER
		at = point - Vector2(150.0 if width <= 0.0 else width / 2.0, 0)
	var box := 300.0 if width <= 0.0 else width
	draw_string_outline(_font, at, value, align, box, px, 5, Color(1, 1, 1, color.a) if color.get_luminance() < 0.5 else Color(0.18, 0.14, 0.08, color.a))
	draw_string(_font, at, value, align, box, px, color)


func _pill(rect: Rect2, fill: Color, border: Color, radius: int = 18) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	draw_style_box(style, rect)


func _draw_bar(shown: String) -> void:
	_pill(Rect2(12, 14, 336, 72), CREAM, INK)
	_pill(QUIT_RECT, Color.WHITE, BROWN, 22)
	var c := QUIT_RECT.get_center()
	draw_line(c + Vector2(-8, -8), c + Vector2(8, 8), INK, 4.0, true)
	draw_line(c + Vector2(-8, 8), c + Vector2(8, -8), INK, 4.0, true)
	_pill(SKIP_RECT, Color.WHITE, INK, 12)
	_text("Pular", SKIP_RECT.get_center() + Vector2(0, 6), 16, INK, true, SKIP_RECT.size.x)
	var steps: Array = CookRules.steps()
	for i in steps.size():
		var x := STEP_X[i]
		var done: bool = i < steps.find(shown) or phase == "result"
		var current: bool = str(steps[i]) == shown
		if i > 0:
			draw_line(Vector2(STEP_X[i - 1] + 18.0, 42), Vector2(x - 18.0, 42), Color("9a8a72"), 3.0)
		var fill := GREEN if done else (GOLD if current else CREAM)
		draw_circle(Vector2(x, 42), 15.0, fill)
		draw_arc(Vector2(x, 42), 15.0, 0.0, TAU, 24, BROWN if current else Color("9a8a72"), 3.0)
		if done:
			draw_polyline(PackedVector2Array([Vector2(x - 6, 42), Vector2(x - 1, 48), Vector2(x + 7, 36)]), Color.WHITE, 3.5)
		else:
			_text(str(i + 1), Vector2(x, 48), 15, INK, true, 30.0)
		_text(str(Database.cooking.step_names[steps[i]]), Vector2(x, 78), 12, INK, true, 70.0)
	var line := str(Database.cooking.lines.get(shown, ""))
	if shown == "servir" and heart_phase:
		line = str(Database.cooking.lines.heart)
	if line != "":
		_pill(Rect2(40, 96, 280, 36), INK, INK, 18)
		_text(line, Vector2(180, 120), 16, CREAM, true, 280.0)


func _draw_tiro() -> void:
	if _tiro == null:
		return
	var hop := 0.0 if Motion.reduced else sin(_time * 3.0) * 3.0 - _tiro_bounce * 22.0
	draw_texture_rect(_tiro, Rect2(238, 668 + hop, 112, 112), false)
	draw_rect(Rect2(230, 768, 130, 30), Color("8c5a33"))


func _draw_picar() -> void:
	draw_rect(Rect2(0, 0, W, 160), Color("f3e2c0"))
	draw_rect(Rect2(0, 154, W, 6), BROWN)
	_pill(BOARD, Color("e8c68f"), BROWN, 26)
	_text("%d/%d" % [_cuts_done, _cuts_total], Vector2(BOARD.end.x - 40, BOARD.position.y + 24), 18, INK, true, 60.0)
	var item := _items[mini(_ing_index, _items.size() - 1)]
	var icon := Database.item_icon(item)
	if icon != null:
		draw_texture_rect(icon, Rect2(44, 258, 40, 40), false)
	_text(Database.item_name(item), Vector2(92, 286), 18, INK)
	var color := _item_color(item)
	for piece in _pieces:
		var t := float(piece.t) / 0.35
		var rect := Rect2(float(piece.x0), STRIP_Y + t * 190.0, maxf(2.0, float(piece.x1) - float(piece.x0)), STRIP_H)
		var tint: Color = piece.color
		tint.a = 1.0 - t * 0.5
		draw_rect(rect, tint)
	if _strip_start < STRIP_END - 1.0:
		_pill(Rect2(_strip_start, STRIP_Y, STRIP_END - _strip_start, STRIP_H), color, color.darkened(0.35), 14)
	var gx := guide_x()
	var y := STRIP_Y - 20.0
	while y < STRIP_Y + STRIP_H + 20.0:
		draw_line(Vector2(gx, y), Vector2(gx, y + 8.0), Color.WHITE, 3.0)
		y += 14.0
	draw_rect(Rect2(gx - 3, STRIP_Y - 6, 6, STRIP_H + 12), Color(1.0, 0.96, 0.69, 0.55))
	if _cuts_done == 0:
		var bob := 0.0 if Motion.reduced else fmod(_time * 60.0, 56.0)
		draw_circle(Vector2(gx, BOARD.position.y + 8.0 + bob), 16.0, Color(1, 1, 1, 0.9))
		draw_arc(Vector2(gx, BOARD.position.y + 8.0 + bob), 16.0, 0.0, TAU, 20, INK, 3.0)
	# tigela com os pedaços
	var bowl := Rect2(36, 520, 130, 66)
	for n in mini(_bowl_pieces, 14):
		draw_rect(Rect2(bowl.position.x + 22.0 + (n % 7) * 12.0, bowl.position.y - 6.0 - (n / 7) * 8.0, 14, 14), _item_color(_items[n % _items.size()]).darkened(0.1))
	_pill(Rect2(bowl.position.x, bowl.position.y + 20.0, bowl.size.x, 46), Color("f6f1e4"), BROWN, 30)
	if _ing_index + 1 < _items.size():
		_pill(Rect2(176, 540, 140, 32), CREAM, INK, 12)
		_text("Depois: %s" % Database.item_name(_items[_ing_index + 1]), Vector2(246, 562), 13, INK, true, 136.0)


func _draw_mexer() -> void:
	draw_circle(POT_CENTER, TRACK_R + 28.0, Color("3a3a3a"))
	draw_arc(POT_CENTER, TRACK_R + 18.0, -PI / 2.0, -PI / 2.0 + TAU * ring, 72, Color("3f9a2e"), 14.0, true)
	var a := 0.0
	while a < TAU:
		draw_arc(POT_CENTER, TRACK_R, a, a + 0.1, 4, Color(1, 1, 1, 0.75), 3.0)
		a += 0.22
	draw_circle(POT_CENTER, POT_R + 8.0, Color("7e8794"))
	draw_circle(POT_CENTER, POT_R, Color("b9c0c9"))
	draw_circle(POT_CENTER, POT_R - 14.0, _broth_color())
	for i in 7:
		var angle := _swirl + float(i) * TAU / 7.0
		var radius := 28.0 + float(i % 3) * 22.0
		draw_circle(POT_CENTER + Vector2(cos(angle), sin(angle)) * radius, 8.0, _item_color(_items[i % _items.size()]).darkened(0.1))
	var dir := Vector2(cos(_spoon_angle), sin(_spoon_angle))
	draw_line(POT_CENTER + dir * 10.0, POT_CENTER + dir * (POT_R + 40.0), Color("b98a54"), 18.0, true)
	draw_circle(POT_CENTER + dir * 28.0, 22.0, Color("b98a54"))
	for splash in _splashes:
		var s: Dictionary = splash
		var at := POT_CENTER + Vector2(cos(float(s.angle)), sin(float(s.angle))) * (POT_R + 12.0 + float(s.t) * 60.0)
		draw_circle(at, 6.0, Color(1, 1, 1, 0.7 - float(s.t)))
	if not Motion.reduced:
		for i in 3:
			var rise := fmod(_time * 24.0 + i * 20.0, 60.0)
			draw_circle(POT_CENTER + Vector2(-30.0 + i * 30.0, -POT_R - 6.0 - rise), 7.0, Color(1, 1, 1, 0.5 - rise / 140.0))
	if _stir_started:
		var good := stir_zone_now == "good"
		var line := str(Database.cooking.lines.in_point) if good else str(Database.cooking.lines.too_fast if stir_zone_now == "fast" else Database.cooking.lines.too_slow)
		_pill(Rect2(70, 626, 220, 38), GREEN if good else INK, Color.WHITE, 19)
		_text(line, Vector2(180, 652), 16, Color.WHITE, true, 220.0)


func _draw_servir() -> void:
	draw_rect(Rect2(0, 0, W, 470), Color("f6e7c8"))
	draw_rect(Rect2(0, 470, W, 320), Color("c99a64"))
	draw_rect(Rect2(0, 462, W, 10), BROWN)
	# panela
	_pill(POT_RECT, Color("b9c0c9"), Color("7e8794"), 22)
	_pill(Rect2(POT_RECT.position + Vector2(10, 8), POT_RECT.size - Vector2(20, 24)), _broth_color(), Color("e08f45"), 18)
	_text("Panela", POT_RECT.get_center() + Vector2(0, 52), 13, INK, true, 100.0)
	# trilha e anel da tigela
	var from := POT_RECT.get_center() + Vector2(60, 0)
	var steps := 12
	for i in steps:
		var t0 := float(i) / steps
		draw_circle(from.lerp(BOWL_CENTER, t0), 3.0, Color(1, 1, 1, 0.8))
	var outer := float(Database.cooking.get("servir", {}).get("target_outer", 64))
	var inner := float(Database.cooking.get("servir", {}).get("target_inner", 30))
	draw_arc(BOWL_CENTER, outer, 0.0, TAU, 40, Color(0.23, 0.18, 0.13, 0.85), 3.0)
	draw_arc(BOWL_CENTER, inner, 0.0, TAU, 28, Color(0.25, 0.6, 0.2, 0.85), 3.0)
	# tigela
	_pill(Rect2(BOWL_CENTER.x - 60.0, BOWL_CENTER.y - 6.0, 120, 54), Color("f6f1e4"), BROWN, 28)
	if _bowl_fill > 0.0:
		_pill(Rect2(BOWL_CENTER.x - 48.0, BOWL_CENTER.y - 2.0, 96, 8.0 + 22.0 * _bowl_fill), _broth_color(), Color.TRANSPARENT, 8)
	if _dragging == "ladle" or _dragging == "heart":
		draw_arc(BOWL_CENTER, outer + 4.0, 0.0, TAU, 48, GREEN, 4.0, true)
	# concha
	var ladle := POT_RECT.get_center() + Vector2(0, -50) if _dragging != "ladle" else _drag_pos
	draw_line(ladle + Vector2(10, -50), ladle, Color("b98a54"), 8.0, true)
	draw_circle(ladle, 17.0, Color("b98a54"))
	if _ladle_full:
		draw_circle(ladle, 12.0, _broth_color())
	if heart_phase:
		var heart := _drag_pos if _dragging == "heart" else HEART_HOME
		_draw_heart(heart, 22.0)


func _draw_heart(center: Vector2, r: float) -> void:
	draw_circle(center + Vector2(-r * 0.5, -r * 0.3), r * 0.55, Color("e04a5a"))
	draw_circle(center + Vector2(r * 0.5, -r * 0.3), r * 0.55, Color("e04a5a"))
	draw_colored_polygon(PackedVector2Array([center + Vector2(-r * 1.02, -r * 0.1), center + Vector2(r * 1.02, -r * 0.1), center + Vector2(0, r * 0.95)]), Color("e04a5a"))


# --- Prato pronto -----------------------------------------------------------------------

func _show_result() -> void:
	var host := Control.new()
	host.name = "CookResultHost"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	var output := str(result.output)
	var stars := int(result.stars)
	var icon: Texture2D = StationWood.food_texture(output)
	if icon == null:
		icon = Database.item_icon(output)
	var card := ModalCard.open(host, {"title": "Prato pronto!", "icon": icon, "icon_px": 96, "confetti": stars == 3, "haptic": "success"})
	card.add_text(Database.item_name(output), &"TitleLabel")
	var row := Control.new()
	row.name = "ResultStars"
	row.custom_minimum_size = Vector2(150, 44)
	row.set_meta("count", stars)
	var picture := TextureRect.new()
	picture.texture = CookPanel.stars_texture(stars, true)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(picture)
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add(row)
	var chips := HFlowContainer.new()
	chips.alignment = FlowContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 4)
	chips.add_child(StepCardUi.wood_chip(UiKit.ctl_icon("clock"), "Tempo −%d%%" % int(round(CookRules.time_cut(stars) * 100.0)), "", Callable(), "TimeChip"))
	chips.add_child(StepCardUi.wood_chip(UiKit.ctl_icon("clock"), "Pronta em %s" % TimeText.short(int(result.seconds)), "", Callable(), "ReadyChip"))
	card.add(chips)
	var info := GameState.dish_info(output)
	if not info.is_empty():
		card.add_text(CookInvent.nutrient_text(info.nutrients, bool(info.meal)), &"SmallLabel")
	card.add_primary("Dar ao Tiro", _give).name = "GiveToTiro"
	card.add_ghost("Guardar", _keep).name = "KeepDish"


func _keep() -> void:
	_close()


func _give() -> void:
	var plate := GameState.cook_plate_now("stove", int(result.index))
	_close()
	if plate.has("error"):
		Events.toast_requested.emit(str(plate.error))
		return
	CookPanel.close_current(true)
	Events.screen_requested.emit(&"pet")
	var output := str(plate.item)
	# Antes da aula da comida (F02B) a papinha não é comida na hora: vai para a Mochila e a aula manda arrastá-la até ele.
	if output == GameState.food_lesson_item() and not GameState.food_lesson_done():
		# Passo 13 (Cozinhar junto) cumprido e ainda não pego: pega agora, para o passo 14 (a aula da comida) abrir já.
		var step := GameState.progress.current_main_quest()
		if step != "" and not GameState.progress.active_steps().values().has(str(Database.week_story.food_lesson.get("quest", ""))) \
				and GameState.quest_objectives_error(step) == "":
			ProgressionUi.claim_quest_fx(step, Vector2(180.0, 600.0))
			return
		Events.care_requested.emit("feed")
		return
	SheetBuilder.request_food(output, func() -> void:
		var line := GameState.taste_line(output)
		if line != "":
			Events.toast_requested.emit(line))


func tutorial_rect() -> Rect2:
	var target: Rect2 = {
		"picar": Rect2(STRIP_START, STRIP_Y, STRIP_END - STRIP_START, STRIP_H + 15),
		"mexer": Rect2(POT_CENTER - Vector2.ONE * TRACK_R, Vector2.ONE * TRACK_R * 2),
		"servir": Rect2(22, 342, 310, 375),
	}.get(phase, Rect2())
	return Rect2(global_position + to_screen(target.position), target.size * _scale)


func _restore_tutorial_checkpoint() -> void:
	var checkpoint: Dictionary = GameState.week.tutorial.get("cooking", {})
	if WeekTutorial.record("cook").get("done", false) or checkpoint.get("output", "") != spec.get("output", "") or checkpoint.get("items", []) != _items:
		return
	brilhos.assign(checkpoint.brilhos)
	phase = str(checkpoint.phase)
