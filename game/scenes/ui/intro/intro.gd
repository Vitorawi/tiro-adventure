class_name IntroScene
extends CanvasLayer
## Início da história (uma vez por jogo): a Laís chega com o Tiro na casa nova,
## se apresenta e solta o Tiro. Falas em npcs.json → lais.intro (texto, "show": "tiro",
## "button"). No fim marca "intro" como visto, entra na Casa, o Tiro corre porta adentro
## e a seta aponta para a Laís (primeira missão).

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
var _finished: bool = false


## Mostrar só num jogo novo, antes de qualquer conversa com a Laís.
static func should_show() -> bool:
	return not GameState.progress.seen.has("intro") and GameState.progress.stat("talk:" + NPC) == 0


func _ready() -> void:
	layer = 20
	var npc: Dictionary = Database.npcs.get(NPC, {})
	_lines = npc.get("intro", [])
	var folder: String = npc.get("intro_wave", "")
	if folder != "":
		var files := Array(ResourceLoader.list_directory(folder))
		files.sort()
		for file: String in files:
			if file.ends_with(".png"):
				_wave.append(load(folder + file))
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
	root.gui_input.connect(_on_tap)
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
	_tiro = UiKit.icon(null, 150)
	DogLook.bind(_tiro, "idle_front")
	_tiro.modulate.a = 0.0
	column.add_child(_tiro)
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
	speech.add_child(StepCardUi.wood(str(Database.npcs.get(NPC, {}).get("name", "")), 20))
	_text = StepCardUi.wood("", 17)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.custom_minimum_size = Vector2(120, 72)
	speech.add_child(_text)
	row.add_child(speech)
	inner.add_child(row)
	_next = StepCardUi.go_button("Continuar", _advance)
	_next.custom_minimum_size = Vector2(0, 56)
	inner.add_child(_next)


func _show_line() -> void:
	var line: Dictionary = _lines[_index] if _index < _lines.size() else {}
	_text.text = str(line.get("text", ""))
	_next.text = str(line.get("button", "Continuar"))
	if line.get("show", "") == "tiro" and _tiro.modulate.a < 1.0:
		_tiro.pivot_offset = _tiro.custom_minimum_size / 2.0
		_tiro.scale = Vector2.ONE * 0.4
		var pop := create_tween().set_parallel()
		pop.tween_property(_tiro, "modulate:a", 1.0, 0.25)
		pop.tween_property(_tiro, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## A Laís acena na primeira e na última fala; nas outras fica parada sorrindo.
func _animate() -> void:
	if _wave.is_empty():
		return
	var waving := _index == 0 or _index == _lines.size() - 1
	_wave_frame = (_wave_frame + 1) % _wave.size() if waving else 0
	_avatar.texture = _wave[_wave_frame]


func _on_tap(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
		_advance()


func _advance() -> void:
	if _finished:
		return
	_index += 1
	if _index < _lines.size():
		_show_line()
		return
	_finish()


func _finish() -> void:
	_finished = true
	_next.hide()
	GameState.mark_seen(["intro"])
	queue_free()
	Events.sheet_close_requested.emit()
	Events.world_requested.emit("house", "")
	# Solta o Tiro: ele entra correndo pela porta; depois a seta mostra a Laís.
	var tree := Engine.get_main_loop() as SceneTree
	tree.create_timer(0.4).timeout.connect(func() -> void:
		Events.world_activity.emit(&"arrive", "", -1))
	tree.create_timer(2.6).timeout.connect(func() -> void:
		Events.world_requested.emit("house", "look:npc:" + NPC))
