class_name IntroScene
extends CanvasLayer
## Abertura da semana. Cada carinho revela mais da pose aprovada, por trás da caixa.

const NPC := "lais"
const BACKGROUND := "res://assets/sprites/areas/house/apartment/room.webp"
const WAVE_FPS := 8.0

var _lines: Array = []
var _index := 0
var _wave: Array[Texture2D] = []
var _wave_frame := 0
var _avatar: TextureRect
var _text: Label
var _tiro: TextureRect
var _next: Button
var _speaker: Label
var _reveal: Tween
var _pet_hold: Timer
var _held_to_advance := false
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
	_show_line()
	var timer := Timer.new()
	timer.wait_time = 1.0 / WAVE_FPS
	timer.timeout.connect(_animate)
	add_child(timer)
	timer.start()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
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
	column.add_child(stage)
	var reveal := Control.new()
	reveal.name = "ArrivalReveal"
	reveal.position = Vector2(0, 0)
	reveal.size = Vector2(228, 187)
	reveal.clip_contents = true
	reveal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(reveal)
	_tiro = UiKit.icon(null, 176)
	_tiro.position = Vector2(26, 187)
	_tiro.size = Vector2(176, 176)
	DogLook.bind(_tiro, "idle_front")
	reveal.add_child(_tiro)
	var box := UiKit.icon(load(str(Database.week_story.arrival.box)), 152)
	box.name = "ArrivalBox"
	box.position = Vector2(38, 116)
	box.size = Vector2(152, 152)
	stage.add_child(box)
	# Cartão de papel de madeira: retrato da Laís na moldura, nome, fala e o botão verde (o único da tela).
	var card := MissionUi.card("card", Vector4i(14, 14, 14, 14), "IntroCard", 10)
	column.add_child(card)
	var inner := UiKit.vbox(10)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MissionUi.body(card).add_child(inner)
	var row := UiKit.hbox(10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar = TextureRect.new()
	_avatar.texture = _wave[0] if not _wave.is_empty() else ProgressionUi.npc_portrait(NPC)
	var framed := StepCardUi.portrait_frame(_avatar, 104.0, "IntroAvatar")
	framed.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(framed)
	var speech := UiKit.vbox(6)
	speech.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_speaker = StepCardUi.wood("", 20)
	speech.add_child(_speaker)
	_text = StepCardUi.wood("", 17)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.custom_minimum_size = Vector2(120, 72)
	speech.add_child(_text)
	row.add_child(speech)
	inner.add_child(row)
	_next = StepCardUi.go_button("Continuar", _tap_next)
	_next.custom_minimum_size = Vector2(0, 56)
	inner.add_child(_next)
	_pet_hold = Timer.new()
	_pet_hold.one_shot = true
	_pet_hold.wait_time = 0.65
	_pet_hold.timeout.connect(func() -> void:
		_held_to_advance = true
		_advance())
	add_child(_pet_hold)
	_next.button_down.connect(func() -> void:
		_held_to_advance = false
		if _index in [1, 2]:
			_pet_hold.start())
	_next.button_up.connect(func() -> void: _pet_hold.stop())


func _notification(what: int) -> void:
	if is_instance_valid(_pet_hold) and what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		_pet_hold.stop()


func _tap_next() -> void:
	if _pet_hold.is_stopped() and not _held_to_advance and _index in [0, 3]:
		_advance()


func _show_line() -> void:
	var line: Dictionary = _lines[_index] if _index < _lines.size() else {}
	_text.text = str(line.get("text", ""))
	_next.name = ["ArrivalOpen", "ArrivalPet", "ArrivalPet", "ArrivalGo"][_index]
	_next.text = "Segure para fazer carinho" if _index in [1, 2] else str(line.get("button", "Continuar"))
	var npc := str(line.get("npc", NPC))
	_speaker.text = str(Database.npcs[npc].name)
	_avatar.texture = ProgressionUi.npc_portrait(npc)
	var end := lerpf(187.0, 0.0, float(line.get("reveal", 0.0)))
	if _reveal:
		_reveal.kill()
	if Motion.reduced:
		_tiro.position.y = end
	else:
		_reveal = create_tween()
		_reveal.tween_property(_tiro, "position:y", end, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## A Laís acena na primeira e na última fala; nas outras fica parada sorrindo.
func _animate() -> void:
	if _finished or _wave.is_empty() or str(_lines[_index].npc) != NPC:
		return
	var waving := _index == 0
	_wave_frame = (_wave_frame + 1) % _wave.size() if waving else 0
	_avatar.texture = _wave[_wave_frame]


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
	_next.hide()
	WeekTutorial.finish("arrival")
	GameState.finish_week_arrival()
	queue_free()
	Events.sheet_close_requested.emit()
	Events.world_requested.emit("house", "")
	# Solta o Tiro: ele entra correndo pela porta; depois a seta mostra a Laís.
	var tree := Engine.get_main_loop() as SceneTree
	tree.create_timer(0.4).timeout.connect(func() -> void:
		Events.world_activity.emit(&"arrive", "", -1))
	tree.create_timer(2.6).timeout.connect(func() -> void:
		Events.world_requested.emit("house", "look:npc:" + NPC))
