class_name FishingGame
extends Control
## Protótipo do minigame de pesca (etapa 00 do plano "Pesca na lagoa da vovó").
## PROVISÓRIO: retângulos e um ícone qualquer; a arte vem na etapa 03 e o visual final na 02.
## Segurar o dedo (em qualquer lugar da tela) sobe a barra, soltar a faz cair; peixe dentro da barra enche a
## rede, fora esvazia. Toda a regra está no `FishingSim`; aqui só entrada, desenho e a ferramenta de ajuste.
## Nada daqui toca save, missão, item ou a lagoa do Sítio.

signal closed
## Modo ao vivo (etapa 02): a partida que acabou, já no formato do `GameState.finish_fishing`.
signal ended(result: Dictionary)
## Modo ao vivo: o jogador soltou a linha ("Soltar o peixe").
signal released

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

## Modo ao vivo (etapa 02): filho de `Main`, entre o HUD e as abas, com o peixe/vara/semente da partida em
## `GameState.fishing.cast`. Sem ferramentas de ajuste; as medidas vêm do tamanho real da tela.
var live := false
const LIVE_PAD := 6.0      # folga da moldura de madeira até a borda da área do jogo
const FRAME_PAD := 18.0    # largura da moldura de madeira em volta de pista + rede
const LIVE_SIDE := 8.0
const FISH_ICON := 32.0

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
var _paused := false
var _pause_card: Control
var _pause_button: Button
var _hint: Label
var _hold_button: Button
var _button_held := false
var _info_card: Control
var _frame: Control
var _fish_texture: Texture2D
var _fish_sprite: Texture2D  ## peixe grande do minigame (ui/fishing/fish_<id>.png); sem ele usa o ícone
var _ending := false
var _tap_haptic_at := -10000
var _time := 0.0
var _result_ready_at := 0.0
var _live_result: Dictionary = {}


## Abre o minigame de verdade sobre o mundo (z 7: acima do mundo e do seletor, abaixo do HUD). Devolve a cena.
static func open_live(host: Control) -> FishingGame:
	var game := FishingGame.new()
	game.live = true
	game.z_index = 7
	host.add_child(game)
	return game


func _ready() -> void:
	name = "FishingGame"
	mouse_filter = Control.MOUSE_FILTER_STOP
	config = Database.fishing.duplicate(true)
	if live:
		_ready_live()
		return
	set_anchors_preset(Control.PRESET_FULL_RECT)
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
	if _paused:
		return false
	if live:
		return _button_held  # no jogo de verdade só o botão "Segurar" sobe a barra
	# o mouse é conferido no estado real: se o soltar se perdeu (saiu da janela, foco, botão por cima), solta
	if _mouse_down and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_mouse_down = false
	return not _touches.is_empty() or _mouse_down


## Jogo de um dedo só: qualquer soltar/cancelar limpa TODOS os dedos (o navegador às vezes avisa o mesmo
## dedo duas vezes, com índices diferentes, e um deles nunca soltava: a barra ficava presa em cima).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_touches.clear()
		_mouse_down = false
		if live and _running:
			pause()  # o app foi para o segundo plano: a partida espera


func _process(delta: float) -> void:
	if sim == null:
		return
	_time += delta
	if _running and not _paused and not frozen:
		var inside_before := sim.fish_y >= sim.bar_y and sim.fish_y <= sim.bar_y + sim.bar_h
		sim.step(_holding(), minf(delta, 0.1))
		var inside_now := sim.fish_y >= sim.bar_y and sim.fish_y <= sim.bar_y + sim.bar_h
		if live and inside_before and not inside_now and Time.get_ticks_msec() - _tap_haptic_at > 500:
			_tap_haptic_at = Time.get_ticks_msec()
			Haptics.tap()  # tic leve cada vez que o peixe sai da barra
		if sim.finished:
			_finish()
	elif live and _ending and _time >= _result_ready_at:
		_ending = false
		ended.emit(_live_result)
	queue_redraw()


func _finish() -> void:
	_running = false
	if live:
		_live_result = {"caught": sim.caught, "score": clampf(sim.score(), 0.0, 1.0), "perfect": sim.caught and sim.perfect, "chest": sim.caught and sim.chest_open}
		_ending = true
		_result_ready_at = _time + (0.0 if Motion.reduced else 0.55)
		if sim.caught:
			Haptics.success()
		else:
			Haptics.error()
		return
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
	if live:
		return  # o botão cuida do toque; o resto da tela não faz nada
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
	if live:
		var x := size.x - LIVE_SIDE - FRAME_PAD - TRACK_WIDTH
		return Rect2(x, LIVE_PAD + FRAME_PAD, TRACK_WIDTH, maxf(size.y - (LIVE_PAD + FRAME_PAD) * 2.0, 40.0))
	return Rect2(size.x - SIDE - TRACK_WIDTH, TOP_MARGIN, TRACK_WIDTH, maxf(size.y - TOP_MARGIN - BOTTOM_MARGIN, 40.0))


func meter_rect() -> Rect2:
	var track := track_rect()
	return Rect2(track.position.x - 8.0 - METER_WIDTH, track.position.y, METER_WIDTH, track.size.y)


func _draw() -> void:
	if live:
		_draw_live()
		return
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


# ---------- modo ao vivo (etapa 02) ----------

func _ready_live() -> void:
	var cast: Dictionary = GameState.fishing.cast
	var fish_id := str(cast.get("fish", ""))
	var fish: Dictionary = config.fish.get(fish_id, {}).duplicate()
	var rod: Dictionary = config.get("rods", {}).get(str(cast.get("rod", "")), {})
	_fish_texture = Database.item_icon(fish_id)
	var sprite_path := "res://assets/sprites/ui/fishing/" + fish_id.trim_prefix("item_") + ".png"
	_fish_sprite = load(sprite_path) as Texture2D if ResourceLoader.exists(sprite_path) else null
	if not GameState.fishing_tutorial_done():
		fish["difficulty"] = float(config.get("tutorial", {}).get("difficulty", 8))  # o lambari do tutorial é bem mansinho
	sim = FishingSim.new(config, fish, int(cast.get("seed", 1)), GameState.fishing_bar_height(), rod)
	sim.chest_enabled = bool(cast.get("chest", false)) and GameState.fishing_tutorial_done()
	if not GameState.fishing_tutorial_done():
		var rules: Dictionary = config.get("tutorial", {})
		sim.tutorial = {"drain_until": float(rules.get("drain_until", 0.5)), "meter_floor": float(rules.get("meter_floor", 0.2))}  # a primeira pesca não pode falhar
	_running = true
	_build_live()
	get_parent().resized.connect(_layout_live)
	_layout_live()
	resized.connect(queue_redraw)
	set_process(true)


## Área entre o HUD e as abas: o jogo nunca cobre nenhum dos dois (medido do tamanho real, sem constantes de tela).
func _layout_live() -> void:
	var host := get_parent() as Control
	if host == null:
		return
	var top := Hud.HEIGHT
	var bottom := host.size.y - 100.0
	var tabs := host.find_child("TabBarArt", true, false) as Control
	if tabs != null and tabs.is_visible_in_tree():
		bottom = tabs.global_position.y - host.global_position.y
	position = Vector2(0, top)
	size = Vector2(host.size.x, maxf(bottom - top, 120.0))
	if _frame != null:
		var track := track_rect()
		var frame_rect := Rect2(track.position.x - 8.0 - METER_WIDTH - FRAME_PAD, LIVE_PAD, TRACK_WIDTH + 8.0 + METER_WIDTH + FRAME_PAD * 2.0, size.y - LIVE_PAD * 2.0)
		_frame.position = frame_rect.position
		_frame.size = frame_rect.size
	var left_room := maxf(track_rect().position.x - METER_WIDTH - 8.0 - FRAME_PAD - 24.0, 120.0)
	if _hold_button != null:
		_hold_button.size = Vector2(left_room, 88.0)
		_hold_button.position = Vector2(12.0, size.y - 88.0 - 12.0)
	if _pause_button != null:
		_pause_button.position = Vector2(LIVE_SIDE + 4.0, size.y - 88.0 - 12.0 - 44.0 - 10.0)
	if _info_card != null:
		var room_width := maxf(track_rect().position.x - METER_WIDTH - 8.0 - FRAME_PAD - 24.0, 120.0)
		_info_card.custom_minimum_size.x = room_width
		_info_card.size = Vector2(room_width, _info_card.get_combined_minimum_size().y)
		_info_card.position = Vector2(12.0, LIVE_PAD + 6.0)
	if _hint != null:
		_hint.position = Vector2(16.0, size.y / 2.0 - 20.0)
		_hint.size = Vector2(maxf(size.x - 170.0, 120.0), 40.0)
	if _pause_card != null:
		_pause_card.position = (size - _pause_card.size) / 2.0 + Vector2(-30.0, 0.0)
	queue_redraw()


func _build_live() -> void:
	_frame = StationWood.backing("frame", 60, 60, "TrackFrame", 0.0, true)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	# botão de pausa: disco de madeira 44 com as duas barrinhas
	_pause_button = StationWood.icon_button("box", Vector2(44, 44), pause, "PauseButton", 44.0)
	_pause_button.size = Vector2(44, 44)
	for i in 2:
		var bar := ColorRect.new()
		bar.color = Palette.WOOD_INK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.position = Vector2(14 + i * 10, 13)
		bar.size = Vector2(6, 18)
		_pause_button.add_child(bar)
	add_child(_pause_button)
	_build_info()
	_hold_button = StepCardUi.go_button("Segurar para pescar", func() -> void: pass)
	_hold_button.name = "HoldButton"
	_hold_button.set_meta("wood_primary", true)
	_hold_button.set_meta("art_height", 84.0)
	_hold_button.custom_minimum_size = Vector2(0, 88)
	_hold_button.clip_text = false
	_hold_button.button_down.connect(func() -> void:
		_button_held = true
		Haptics.tap())
	_hold_button.button_up.connect(func() -> void: _button_held = false)
	add_child(_hold_button)
	_build_pause_card()


func _build_pause_card() -> void:
	var card := PanelContainer.new()
	card.name = "PauseCard"
	card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	card.add_child(StationWood.backing("frame", 60, 60, "Frame"))
	var pad := MarginContainer.new()
	for side: String in ["left", "right"]:
		pad.add_theme_constant_override("margin_" + side, 26)
	for side: String in ["top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 22)
	var column := UiKit.vbox(8)
	column.custom_minimum_size.x = 170.0
	var title := StationWood.text("Pausado", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var go := StepCardUi.go_button("Continuar", resume)
	go.name = "ResumeButton"
	go.set_meta("wood_primary", true)
	column.add_child(go)
	var drop := StationWood.wood_button("Soltar o peixe", func() -> void: release(), 16)
	drop.name = "ReleaseButton"
	drop.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(drop)
	pad.add_child(column)
	card.add_child(pad)
	card.visible = false
	_pause_card = card
	add_child(card)
	card.reset_size()


func is_paused() -> bool:
	return _paused


## Tutorial (etapa 05): a vovó para o tempo para explicar. O `FishingSim` não anda enquanto estiver congelado.
var frozen := false


## O dedo está no botão "Segurar para pescar" (o tutorial confere o passo "segure").
func is_holding() -> bool:
	return _button_held


func hold_button_rect() -> Rect2:
	return _hold_button.get_global_rect() if _hold_button != null and _hold_button.is_inside_tree() else Rect2()


func track_global_rect() -> Rect2:
	var rect := track_rect()
	return Rect2(global_position + rect.position, rect.size)


func pause() -> void:
	if not live or _paused or not _running:
		return
	_paused = true
	_touches.clear()
	_mouse_down = false
	_button_held = false
	if _pause_card != null:
		_pause_card.reset_size()
		_pause_card.show()
		_layout_live()


func resume() -> void:
	_paused = false
	_touches.clear()
	_mouse_down = false
	if _pause_card != null:
		_pause_card.hide()


## O jogador soltou a linha ("Soltar o peixe"): termina sem captura (a isca já foi).
func release() -> void:
	if not live or _ending:
		return
	_running = false
	_paused = false
	if _pause_card != null:
		_pause_card.hide()
	_live_result = {"caught": false, "score": clampf(sim.score(), 0.0, 1.0), "perfect": false, "chest": false}
	released.emit()


## Fecha sem entregar nada (a casca chama ao trocar de aba; o GameState devolve a isca).
func abandon() -> void:
	_running = false
	queue_free()


func _draw_live() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.SCRIM)  # a lagoa escurecida: o mundo continua desenhado atrás
	var track := track_rect()
	var meter := meter_rect()
	# água
	draw_rect(track, Color("3f8fb8"))
	if not Motion.reduced:
		for i in 9:
			var y := track.position.y + track.size.y * (float(i) / 9.0) + fposmod(_time * 6.0, track.size.y / 9.0)
			if y < track.end.y - 2.0:
				draw_line(Vector2(track.position.x + 6, y), Vector2(track.end.x - 6, y), Color(1, 1, 1, 0.12), 2.0)
	draw_style_box(_wood_box("fishing_track", 12), track.grow(6.0))
	# rede (medidor): enche de baixo para cima, verde → amarelo → vermelho conforme cai
	draw_rect(meter, Palette.SUNKEN)
	var fraction := clampf(sim.meter, 0.0, 1.0)
	var tone := Palette.GO if fraction > 0.5 else (Palette.HONEY if fraction > 0.25 else Palette.ALERT)
	var shake := 0.0
	var outside := sim.fish_y < sim.bar_y or sim.fish_y > sim.bar_y + sim.bar_h
	if outside and not Motion.reduced:
		shake = sin(_time * 40.0) * 1.0
	var fill_h := meter.size.y * fraction
	draw_rect(Rect2(meter.position.x + shake, meter.end.y - fill_h, meter.size.x, fill_h), tone)
	draw_style_box(_wood_box("fishing_meter", 12), meter.grow(6.0))
	# barra do jogador
	var bar_top := track.end.y - (sim.bar_y + sim.bar_h) * track.size.y
	var bar := Rect2(track.position.x + 2.0, bar_top, track.size.x - 4.0, sim.bar_h * track.size.y)
	draw_style_box(_wood_box("fishing_bar", 8), bar)
	# baú (só nas partidas com baú): balança de leve, anelzinho próprio enche enquanto a barra cobre
	if sim.chest_shown:
		_draw_chest(track)
	# peixe (leve rabeada)
	var wiggle := 0.0 if Motion.reduced else sin(_time * 9.0) * 2.0
	var center := Vector2(track.get_center().x + wiggle, track.end.y - sim.fish_y * track.size.y)
	if _fish_sprite != null:
		var fish_size := Vector2(_fish_sprite.get_size())
		draw_texture_rect(_fish_sprite, Rect2(center - fish_size / 2.0, fish_size), false)
	elif _fish_texture != null:
		draw_texture_rect(_fish_texture, Rect2(center - Vector2(FISH_ICON, FISH_ICON) / 2.0, Vector2(FISH_ICON, FISH_ICON)), false)
	else:
		draw_circle(center, 14.0, Palette.INK)


func _draw_chest(track: Rect2) -> void:
	var tilt := 0.0 if Motion.reduced else sin(_time * 2.2) * 0.07
	var center := Vector2(track.get_center().x, track.end.y - sim.chest_y * track.size.y)
	var texture := load("res://assets/sprites/ui/fishing/chest.png") as Texture2D
	draw_set_transform(center, tilt, Vector2.ONE)
	if texture != null:
		var half := Vector2(texture.get_size()) / 2.0
		draw_texture_rect(texture, Rect2(-half, Vector2(texture.get_size())), false, Color.WHITE if sim.chest_open else Color(1, 1, 1, 0.9))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var radius := 30.0
	draw_arc(center, radius, 0.0, TAU, 32, Color(0, 0, 0, 0.35), 4.0)
	var tone := Palette.GO if sim.chest_open else Palette.HONEY
	if sim.chest_meter > 0.0:
		draw_arc(center, radius, -PI / 2.0, -PI / 2.0 + TAU * clampf(sim.chest_meter, 0.0, 1.0), 32, tone, 4.0)


## Cartão da esquerda: vara em uso, isca e o peixe da luta (nome, tamanho possível, recorde).
func _build_info() -> void:
	var cast: Dictionary = GameState.fishing.cast
	var rod_def: Dictionary = config.get("rods", {}).get(str(cast.get("rod", "")), {})
	var fish_id := str(cast.get("fish", ""))
	var fish_def: Dictionary = config.fish.get(fish_id, {})
	var card := PanelContainer.new()
	card.name = "InfoCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	card.add_child(StationWood.backing("tray", 36, 36))
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	for side: String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	var column := UiKit.vbox(6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_info_line("InfoRod", load(str(rod_def.get("icon", ""))) as Texture2D if str(rod_def.get("icon", "")) != "" else null, str(rod_def.get("name", "Vara"))))
	column.add_child(_info_line("InfoBait", Database.item_icon(str(cast.get("bait", ""))), Database.item_name(str(cast.get("bait", "")))))
	column.add_child(_info_line("InfoFish", _fish_texture, Database.item_name(fish_id)))
	var range_cm: Array = fish_def.get("cm", [0, 0])
	var detail := StationWood.text("%d–%d cm" % [int(range_cm[0]), int(range_cm[1])], 14)
	detail.name = "InfoRange"
	column.add_child(detail)
	var record := GameState.fishing.record(fish_id)
	var best := StationWood.text("Recorde: " + ("%s cm" % str(snappedf(float(record.best_cm), 0.5)).replace(".", ",") if not record.is_empty() else "ainda não"), 14)
	best.name = "InfoRecord"
	column.add_child(best)
	margin.add_child(column)
	card.add_child(margin)
	_info_card = card
	add_child(card)


func _info_line(node_name: String, texture: Texture2D, text: String) -> Control:
	var row := UiKit.hbox(6)
	row.name = node_name
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := UiKit.icon(texture, 28)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var label := StationWood.text(text, 16)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return row


static var _boxes: Dictionary = {}

## Moldura/barra de madeira (NinePatch de ui/home, montadas por tools/fishing_art.py).
static func _wood_box(file: String, margin: int) -> StyleBoxTexture:
	if not _boxes.has(file):
		var box := StyleBoxTexture.new()
		box.texture = load("res://assets/sprites/ui/home/%s.png" % file) as Texture2D
		box.set_texture_margin_all(margin)
		_boxes[file] = box
	return _boxes[file]
