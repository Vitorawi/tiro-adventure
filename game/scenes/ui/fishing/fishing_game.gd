class_name FishingGame
extends Control
## Protótipo do minigame de pesca (etapa 00 do plano "Pesca na lagoa da vovó").
## PROVISÓRIO: retângulos e um ícone qualquer; a arte vem na etapa 03 e o visual final na 02.
## Segurar o dedo (em qualquer lugar da tela) sobe a barra, soltar a faz cair; peixe dentro da barra enche a
## rede, fora esvazia. Toda a regra está no `FishingSim`; aqui só entrada, desenho e a ferramenta de ajuste.
## Nada daqui toca save, missão, item ou a lagoa do Sítio.

signal closed

const TOP_MARGIN := 168.0   # `Hud.HEIGHT`
const BOTTOM_MARGIN := 100.0  # barra de abas
const SIDE := 16.0
const TRACK_WIDTH := 72.0
const METER_WIDTH := 14.0
## [bloco do JSON, campo, passo, rótulo]
const PARAMS: Array = [
	["physics", "thrust", 0.1, "subida"],
	["physics", "gravity", 0.1, "gravidade"],
	["physics", "drag", 0.1, "atrito"],
	["meter", "fill", 0.01, "enche"],
	["meter", "drain", 0.01, "esvazia"],
	["physics", "bar_base", 0.01, "barra"],
]

var profile := "mixed"
var seed_value := 1

var config: Dictionary = {}
var sim: FishingSim
var _touches: Dictionary = {}   # índice do dedo -> true
var _mouse_down := false
var _touch_seen_at := -10000
var _round := 0
var _running := false
var _info: Label
var _result: PanelContainer
var _result_text: Label
var _values: Dictionary = {}    # "bloco.campo" -> Label
var _gravity_button: Button
var _plate: Texture2D


func _ready() -> void:
	name = "FishingGame"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	config = Database.fishing.duplicate(true)
	_plate = UiKit.ui_icon("item_carrot")
	_build_tools()
	_build_result()
	_start()
	resized.connect(queue_redraw)


# ---------- partida ----------

func _start() -> void:
	_round += 1
	var fish: Dictionary = config.proto_fish.get(profile, config.proto_fish.mixed)
	sim = FishingSim.new(config, fish, seed_value + _round - 1, float(config.physics.bar_base))
	_touches.clear()
	_mouse_down = false
	_running = true
	if _result:
		_result.hide()
	_refresh_labels()


func _holding() -> bool:
	# o mouse é conferido no estado real: se o soltar se perdeu (saiu da janela, foco, botão por cima), solta
	if _mouse_down and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_mouse_down = false
	return not _touches.is_empty() or _mouse_down


## Jogo de um dedo só: qualquer soltar/cancelar limpa TODOS os dedos (o navegador às vezes avisa o mesmo
## dedo duas vezes, com índices diferentes, e um deles nunca soltava: a barra ficava presa em cima).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_touches.clear()
		_mouse_down = false


func _process(delta: float) -> void:
	if sim == null:
		return
	if _running:
		sim.step(_holding(), minf(delta, 0.1))
		if sim.finished:
			_finish()
	queue_redraw()


func _finish() -> void:
	_running = false
	var fish: Dictionary = config.proto_fish.get(profile, {})
	var lines: PackedStringArray = [
		"Pegou!" if sim.caught else "Escapou",
		str(fish.get("name", profile)),
		"Tempo: %.1f s" % sim.elapsed,
		"Pontuação: %d%%" % int(round(sim.score() * 100.0)),
	]
	if sim.caught and sim.perfect:
		lines.append("Perfeita!")
	_result_text.text = "\n".join(lines)
	_result.show()
	if sim.caught:
		Haptics.success()
	else:
		Haptics.error()


# ---------- entrada ----------

func _gui_input(event: InputEvent) -> void:
	_handle(event)


func _unhandled_input(event: InputEvent) -> void:
	_handle(event)


func _handle(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_touch_seen_at = Time.get_ticks_msec()
		if touch.pressed and not touch.canceled:
			_touches[touch.index] = true
		else:
			_touches.clear()
		accept_event()
	elif event is InputEventScreenDrag:
		_touch_seen_at = Time.get_ticks_msec()
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index != MOUSE_BUTTON_LEFT:
			return
		# toque e mouse chegam duplicados em alguns navegadores: se houve toque, o mouse emulado é ignorado
		if not _touches.is_empty() or Time.get_ticks_msec() - _touch_seen_at < 600:
			accept_event()
			return
		_mouse_down = button.pressed
		accept_event()


# ---------- desenho ----------

func track_rect() -> Rect2:
	return Rect2(size.x - SIDE - TRACK_WIDTH, TOP_MARGIN, TRACK_WIDTH, maxf(size.y - TOP_MARGIN - BOTTOM_MARGIN, 40.0))


func meter_rect() -> Rect2:
	var track := track_rect()
	return Rect2(track.position.x - 8.0 - METER_WIDTH, track.position.y, METER_WIDTH, track.size.y)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.PAPER)  # fundo próprio do protótipo
	var track := track_rect()
	draw_rect(track, Palette.SUNKEN)
	draw_rect(track, Palette.LINE, false, 2.0)
	var meter := meter_rect()
	draw_rect(meter, Palette.SUNKEN)
	draw_rect(meter, Palette.LINE, false, 2.0)
	if sim == null:
		return
	var fill_h := meter.size.y * sim.meter
	draw_rect(Rect2(meter.position.x, meter.end.y - fill_h, meter.size.x, fill_h), Palette.HONEY)
	# barra verde translúcida (y = 0 é o fundo da pista)
	var bar_top := track.end.y - (sim.bar_y + sim.bar_h) * track.size.y
	var bar := Rect2(track.position.x + 2.0, bar_top, track.size.x - 4.0, sim.bar_h * track.size.y)
	draw_rect(bar, Color(Palette.GO, 0.45))
	draw_rect(bar, Palette.GO_INK, false, 2.0)
	var fish_center := Vector2(track.get_center().x, track.end.y - sim.fish_y * track.size.y)
	draw_circle(fish_center, 19.0, Palette.INK)
	draw_circle(fish_center, 17.0, Palette.CARD)
	if _plate:
		draw_texture_rect(_plate, Rect2(fish_center - Vector2(16, 16), Vector2(32, 32)), false)


# ---------- ferramentas de ajuste (só protótipo) ----------

func _build_tools() -> void:
	var left := VBoxContainer.new()
	left.name = "Tools"
	left.position = Vector2(SIDE, TOP_MARGIN)
	left.size = Vector2(maxf(get_viewport_rect().size.x - SIDE * 2.0 - TRACK_WIDTH - METER_WIDTH - 24.0, 150.0), 10.0)
	left.add_theme_constant_override("separation", 4)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(left)
	_info = UiKit.label("", &"SmallLabel", Palette.INK)
	_info.name = "Info"
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_info)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	left.add_child(grid)
	for id: String in config.proto_fish:
		var fish: Dictionary = config.proto_fish[id]
		var button := UiKit.button(str(fish.name).replace(" (teste)", ""), func() -> void:
			profile = id
			_start())
		button.name = "Proto_" + id
		button.custom_minimum_size = Vector2(0, 36)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		grid.add_child(button)
	_gravity_button = UiKit.button("", func() -> void:
		config.physics.gravity_on_hold = not bool(config.physics.get("gravity_on_hold", false))
		_start())
	_gravity_button.name = "ProtoGravity"
	_gravity_button.custom_minimum_size = Vector2(0, 36)
	_gravity_button.clip_text = true
	left.add_child(_gravity_button)
	for param: Array in PARAMS:
		left.add_child(_param_row(str(param[0]), str(param[1]), float(param[2]), str(param[3])))
	var dump := UiKit.button("Copiar JSON", func() -> void:
		var text := json_block()
		print(text)
		DisplayServer.clipboard_set(text)
		Events.toast_requested.emit("JSON copiado e impresso"))
	dump.name = "ProtoDump"
	dump.custom_minimum_size = Vector2(0, 36)
	left.add_child(dump)


func _param_row(block: String, key: String, step: float, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var caption := UiKit.label(text, &"SmallLabel", Palette.INK)
	caption.custom_minimum_size = Vector2(62, 0)
	row.add_child(caption)
	var minus := UiKit.button("−", func() -> void: _tweak(block, key, -step))
	minus.name = "ProtoMinus_" + key
	var value := UiKit.label("", &"SmallLabel", Palette.INK)
	value.custom_minimum_size = Vector2(44, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var plus := UiKit.button("+", func() -> void: _tweak(block, key, step))
	plus.name = "ProtoPlus_" + key
	for button: Button in [minus, plus]:
		button.custom_minimum_size = Vector2(36, 36)
	_values[block + "." + key] = value
	row.add_child(minus)
	row.add_child(value)
	row.add_child(plus)
	return row


func _tweak(block: String, key: String, delta: float) -> void:
	config[block][key] = snappedf(maxf(float(config[block][key]) + delta, 0.0), 0.001)
	_start()


func _refresh_labels() -> void:
	if _info:
		_info.text = "%s · semente %d" % [str(config.proto_fish.get(profile, {}).get("name", profile)), seed_value + _round - 1]
	for param: Array in PARAMS:
		var key := str(param[0]) + "." + str(param[1])
		if _values.has(key):
			(_values[key] as Label).text = "%.3f" % float(config[param[0]][param[1]]) if float(param[2]) < 0.05 else "%.2f" % float(config[param[0]][param[1]])
	if _gravity_button:
		_gravity_button.text = "Segurar: " + ("pesado" if bool(config.physics.get("gravity_on_hold", false)) else "leve")


## Bloco para colar no `fishing.json` (só os números que o ajuste mexe).
func json_block() -> String:
	var phys: Dictionary = config.physics
	var meter: Dictionary = config.meter
	return JSON.stringify({
		"physics": {
			"bar_base": phys.bar_base, "thrust": phys.thrust, "gravity": phys.gravity,
			"drag": phys.drag, "gravity_on_hold": bool(phys.get("gravity_on_hold", false)),
		},
		"meter": {"fill": meter.fill, "drain": meter.drain},
	}, "  ")


func _build_result() -> void:
	_result = PanelContainer.new()
	_result.name = "Result"
	_result.theme_type_variation = &"CardPanel"
	_result.position = Vector2(SIDE, TOP_MARGIN + 60.0)
	_result.custom_minimum_size = Vector2(190, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_result.add_child(box)
	_result_text = UiKit.label("", &"StrongLabel")
	_result_text.name = "ResultText"
	box.add_child(_result_text)
	var again := UiKit.primary("De novo", _start)
	again.name = "Again"
	box.add_child(again)
	var leave := UiKit.ghost("Sair", func() -> void:
		print(json_block())
		closed.emit())
	leave.name = "Leave"
	box.add_child(leave)
	_result.hide()
	add_child(_result)
