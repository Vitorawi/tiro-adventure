class_name IntroScene
extends CanvasLayer
## Abertura da semana, só por gestos: tocar na caixinha e passar o dedo na cabeça do Tiro até ele sair.

const NPC := "lais"
const BACKGROUND := "res://assets/sprites/areas/house/apartment/room.webp"
const WAVE_FPS := 8.0
const SCRUB_DISTANCE := 900.0  ## quanto esfregar na cabeça (px) para ele sair
const HEART_EVERY := 200.0  ## um coraçãozinho a cada tanto de dedo
const HEAD_SIZE := Vector2(156, 120)

var _lines: Array = []
var _index := 0
var _wave: Array[Texture2D] = []
var _wave_frame := 0
var _avatar: TextureRect
var _text: Label
var _tiro: TextureRect
var _speaker: Label
var _root: Control
var _stage: Control
var _reveal_clip: Control
var _box: TextureRect
var _head: Control
var _cur := 0.0  ## quanto do Tiro já apareceu (0 a 1), suavizado
var _goal := 0.0
var _hop := 0.0
var _scrub := 0.0
var _hearts_acc := 0.0
var _dragging := false
var _last := Vector2.ZERO
var _mid_shown := false
var _emerged := false
var _busy := false
var _shake: Tween
var _finished: bool = false


## Mostrar só num jogo novo, antes de qualquer conversa com a Laís.
static func should_show() -> bool:
	return not GameState.progress.seen.has("intro") and GameState.progress.stat("talk:" + NPC) == 0


func _ready() -> void:
	layer = 20
	var npc: Dictionary = Database.npcs.get(NPC, {})
	_lines = Database.week_story.arrival.lines
	var folder: String = npc.get("intro_wave", "")
	if folder != "":
		var files := Array(ResourceLoader.list_directory(folder))
		files.sort()
		for file: String in files:
			if file.ends_with(".png"):
				_wave.append(load(folder + file))
	_index = clampi(int(GameState.week.tutorial.get("arrival_step", 0)), 0, _lines.size() - 1)
	_build()
	if _index >= 2:
		_settle_out()  # reaberto depois de ele sair: sem repetir o pulo
	_show_line()
	var timer := Timer.new()
	timer.wait_time = 1.0 / WAVE_FPS
	timer.timeout.connect(_animate)
	add_child(timer)
	timer.start()


func _build() -> void:
	var root := Control.new()
	_root = root
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.gui_input.connect(_on_gui_input)
	add_child(root)
	var shade := ColorRect.new()
	shade.color = Palette.INTRO_SHADE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	var room := TextureRect.new()
	room.texture = load(BACKGROUND)
	room.set_anchors_preset(Control.PRESET_FULL_RECT)
	room.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	room.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	room.modulate = Color(0.85, 0.85, 0.85)
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(room)
	var title := UiKit.vbox(2)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 72
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Título em letras de creme com contorno escuro (fonte da madeira), sobre o quarto escurecido.
	title.add_child(MissionUi.text("Aventura do Tiro", 36, Palette.WOOD_CREAM, 5))
	title.add_child(MissionUi.text(str(Database.progression.chapters[0].name), 20, Palette.WOOD_CREAM, 4))
	root.add_child(title)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 16
	column.offset_right = -16
	column.offset_bottom = -24
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_theme_constant_override("separation", 12)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(column)
	var stage := Control.new()
	stage.name = "ArrivalStage"
	stage.custom_minimum_size = Vector2(228, 252)
	stage.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage = stage
	column.add_child(stage)
	var reveal := Control.new()
	reveal.name = "ArrivalReveal"
	reveal.position = Vector2(0, 0)
	reveal.size = Vector2(228, 187)
	reveal.clip_contents = true
	reveal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reveal_clip = reveal
	stage.add_child(reveal)
	_tiro = UiKit.icon(null, 176)
	_tiro.name = "ArrivalTiro"
	_tiro.position = Vector2(26, 187)
	_tiro.size = Vector2(176, 176)
	_tiro.pivot_offset = Vector2(88, 176)
	DogLook.bind(_tiro, "idle_front")
	reveal.add_child(_tiro)
	var box := UiKit.icon(load(str(Database.week_story.arrival.box)), 152)
	box.name = "ArrivalBox"
	box.position = Vector2(38, 116)
	box.size = Vector2(152, 152)
	box.pivot_offset = Vector2(76, 140)
	_box = box
	stage.add_child(box)
	# Alvo da cabeça: acompanha a parte visível do Tiro (a mão e o esfregar usam este retângulo).
	_head = Control.new()
	_head.name = "ArrivalHead"
	_head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_head.size = HEAD_SIZE
	_head.visible = false
	stage.add_child(_head)
	# Cartão de papel de madeira só com o retrato da Laís, o nome e a fala: nenhum botão, tudo é gesto.
	var card := MissionUi.card("card", Vector4i(14, 14, 14, 14), "IntroCard", 10)
	column.add_child(card)
	var row := UiKit.hbox(10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MissionUi.body(card).add_child(row)
	_avatar = TextureRect.new()
	_avatar.texture = _wave[0] if not _wave.is_empty() else ProgressionUi.npc_portrait(NPC)
	var framed := StepCardUi.portrait_frame(_avatar, 84.0, "IntroAvatar")
	framed.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(framed)
	var speech := UiKit.vbox(4)
	speech.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_speaker = StepCardUi.wood("", 20)
	speech.add_child(_speaker)
	_text = StepCardUi.wood("", 17)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.custom_minimum_size = Vector2(120, 56)
	speech.add_child(_text)
	row.add_child(speech)
	set_process(true)


func _show_line() -> void:
	var line: Dictionary = _lines[_index] if _index < _lines.size() else {}
	_text.text = str(line.get("text", ""))
	var npc := str(line.get("npc", NPC))
	_speaker.text = str(Database.npcs[npc].name)
	_avatar.texture = ProgressionUi.npc_portrait(npc)
	_goal = maxf(_goal, float(line.get("reveal", 0.0)))
	_head.visible = _index == 1
	if _index == 1:
		_scrub = 0.0
		_hearts_acc = 0.0
		_mid_shown = false
	elif _index >= 2:
		_play_emerge()


## A Laís acena na primeira fala; nas outras fica parada sorrindo.
func _animate() -> void:
	if _finished or _wave.is_empty() or str(_lines[_index].npc) != NPC:
		return
	var waving := _index == 0
	_wave_frame = (_wave_frame + 1) % _wave.size() if waving else 0
	_avatar.texture = _wave[_wave_frame]


func _process(delta: float) -> void:
	if _finished:
		return
	if Motion.reduced:
		_cur = _goal
	else:
		_cur = move_toward(_cur, _goal, delta * 2.0)
	var base := lerpf(187.0, 0.0, _cur)
	_tiro.position.y = base + _hop
	_head.position = Vector2(36.0, clampf(base, 0.0, 150.0))


## Toque e arrasto da abertura: a caixinha abre ao toque, a cabeça sai com o dedo passando, o Tiro responde ao toque.
func _on_gui_input(event: InputEvent) -> void:
	if _finished or _busy:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			_dragging = false
			return
		_dragging = true
		_last = event.position
		if _index == 0 and _box.get_global_rect().grow(12.0).has_point(event.position):
			_open_box()
		elif _index >= 2 and _tiro.get_global_rect().grow(8.0).has_point(event.position):
			_say_hi()
	elif event is InputEventMouseMotion and _dragging and _index == 1 and not _emerged:
		var moved: float = event.position.distance_to(_last)
		_last = event.position
		if moved <= 0.0 or not _head.get_global_rect().grow(28.0).has_point(event.position):
			return
		_scrub += moved
		_hearts_acc += moved
		while _hearts_acc >= HEART_EVERY:
			_hearts_acc -= HEART_EVERY
			_heart(event.position)
			Haptics.tap()
		var progress := clampf(_scrub / SCRUB_DISTANCE, 0.0, 1.0)
		_goal = lerpf(float(_lines[1].get("reveal", 0.28)), 1.0, progress)
		if progress >= 0.6 and not _mid_shown:
			_mid_shown = true
			_text.text = str(_lines[1].get("text_mid", _text.text))
		if progress >= 1.0:
			_advance()


func _open_box() -> void:
	_dragging = false
	_puff(Vector2(114.0, 130.0))
	Haptics.tap()
	if not Motion.reduced:
		if _shake:
			_shake.kill()
		_shake = create_tween()
		_shake.tween_property(_box, "rotation", 0.12, 0.06)
		_shake.tween_property(_box, "rotation", -0.12, 0.1)
		_shake.tween_property(_box, "rotation", 0.0, 0.08)
		_box.scale = Vector2(1.1, 0.9)
		_shake.parallel().tween_property(_box, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_advance()


## Poeirinha que sai da caixinha ao abrir (parada com Menos animação).
func _puff(at: Vector2) -> void:
	for i in 8:
		var dot := Panel.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Palette.WOOD_CREAM
		style.set_corner_radius_all(5)
		dot.add_theme_stylebox_override("panel", style)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.size = Vector2(10, 10)
		dot.pivot_offset = Vector2(5, 5)
		dot.position = at - dot.size * 0.5
		_stage.add_child(dot)
		if Motion.reduced:
			get_tree().create_timer(0.5).timeout.connect(dot.queue_free)
			continue
		var angle := TAU * float(i) / 8.0
		var tween := dot.create_tween().set_parallel()
		tween.tween_property(dot, "position", dot.position + Vector2.from_angle(angle) * 46.0 + Vector2(0, -14), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(dot, "modulate:a", 0.0, 0.55)
		tween.tween_property(dot, "scale", Vector2(0.3, 0.3), 0.55)
		tween.chain().tween_callback(dot.queue_free)


## Coraçãozinho que sai do dedo (ou do Tiro) e some.
func _heart(at: Vector2) -> void:
	var heart := UiKit.icon(UiKit.ui_icon("heart"), 22)
	heart.name = "ArrivalHeart"
	heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(heart)
	heart.position = at - Vector2(11, 30)
	if Motion.reduced:
		get_tree().create_timer(0.5).timeout.connect(heart.queue_free)
		return
	var tween := heart.create_tween().set_parallel()
	tween.tween_property(heart, "position:y", heart.position.y - 48.0, 0.8)
	tween.tween_property(heart, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(heart.queue_free)


## O Tiro sai da caixinha: pulinho com leve amassado, corações em volta e a caixa esvazia.
func _play_emerge() -> void:
	if _emerged:
		return
	_emerged = true
	_dragging = false
	_goal = 1.0
	_head.hide()
	_reveal_clip.clip_contents = false
	_stage.move_child(_box, 0)
	Haptics.success()
	var center := _stage.get_global_rect().get_center() + Vector2(0, -50)
	for i in 5:
		_heart(center + Vector2((i - 2) * 34.0, -float(absi(i - 2)) * 10.0))
	if Motion.reduced:
		_box.modulate.a = 0.0
		return
	_jump(34.0)
	var fade := create_tween()
	fade.tween_interval(0.35)
	fade.tween_property(_box, "modulate:a", 0.0, 0.5)


## Pulo curto e amassadinho na aterrissagem (o `_hop` entra na posição no `_process`).
func _jump(height: float) -> void:
	if Motion.reduced:
		return
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void: _hop = v, 0.0, -height, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(v: float) -> void: _hop = v, -height, 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(_tiro, "scale", Vector2(1.08, 0.92), 0.07)
	tween.tween_property(_tiro, "scale", Vector2.ONE, 0.12)


## Estado final sem animação (abertura reaberta depois de ele sair).
func _settle_out() -> void:
	_emerged = true
	_goal = 1.0
	_cur = 1.0
	_head.hide()
	_reveal_clip.clip_contents = false
	_stage.move_child(_box, 0)
	_box.modulate.a = 0.0


func _say_hi() -> void:
	_busy = true
	_dragging = false
	Haptics.success()
	var center := _tiro.get_global_rect().get_center()
	_heart(center + Vector2(-30, -30))
	_heart(center + Vector2(30, -40))
	_jump(26.0)
	if Motion.reduced:
		_advance()
		return
	get_tree().create_timer(0.5).timeout.connect(_advance)


func _advance() -> void:
	if _finished:
		return
	_index += 1
	GameState.week.tutorial.arrival_step = _index
	Events.week_tutorial_changed.emit()
	if _index < _lines.size():
		_show_line()
		return
	_finish()


func _finish() -> void:
	_finished = true
	WeekTutorial.finish("arrival")
	GameState.finish_week_arrival()
	queue_free()
	Events.sheet_close_requested.emit()
	# Ato 1: o jogo continua na tela do Tiro (o Mapa só aparece no passo 5). O primeiro passo já está guiado
	# pela pílula do próximo passo e pela mão da lição.
	Events.screen_requested.emit(&"pet")
	var tree := Engine.get_main_loop() as SceneTree
	tree.create_timer(0.4).timeout.connect(func() -> void:
		Events.world_activity.emit(&"arrive", "", -1))
