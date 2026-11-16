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
const FRAME_PAD := 18.0    # (o tutorial usa) folga entre a nota e a moldura
const FISH_ICON := 32.0

## Layout ao vivo = a página "Pesca" do Figma (guia 710×1536). Todas as medidas abaixo são em unidades do Figma, relativas
## ao canto do guia; `_layout_live` multiplica por `_s` e ancora o guia no canto de baixo da tela.
const DESIGN := Vector2(710, 1536)
const UI := "res://assets/sprites/ui/fishing_ui/"
const SX := 0.0  ## deslocamento horizontal do grupo (as posições já vêm centralizadas do Figma)
const R_BG := Rect2(-35, 332, 775, 1033)           ## fundominigame (atrás de tudo)
const R_PANEL := Rect2(23 + SX, 371, 420, 524)
const R_WATER := Rect2(406, 477, 330, 660)
const R_FRAME := Rect2(426, 435, 266, 726)
const R_TRACK := Rect2(525.2, 519.9, 106.0, 558.9)  ## janela da água na moldura (onde peixe e barra andam)
const R_METER := Rect2(476.4, 518.7, 16.3, 560.6)   ## a rede enche a canaleta estreita da moldura (passa um pouco do buraco: a moldura cobre a sobra)
const R_GROOVE := Rect2(474.5, 516.0, 20.2, 566.0)  ## fundo escuro por baixo da moldura: nada do fundo aparece pela canaleta
const R_PAUSE := Rect2(25, 849, 123, 123)
const R_HOLD_ART := Rect2(80, 1129, 550, 183)
const R_HOLD := Rect2(80, 1160.6, 516.3, 139.3)     ## parte visível do botão (o toque)
const R_TIPS: Array[Rect2] = [Rect2(172, 863, 300, 100), Rect2(195, 955, 255, 85), Rect2(180, 1042, 290, 94)]
const FISH_BOX := Vector2(64, 50)
## [nome, ícone, texto] das cinco linhas do painel (o ícone da vara, da isca e do peixe vem da partida)
const ROWS: Array = [
	["InfoRod", Rect2(93 + SX, 506, 50, 50), Rect2(175 + SX, 516, 240, 29)],
	["InfoBait", Rect2(94 + SX, 570, 50, 50), Rect2(175 + SX, 580, 240, 29)],
	["InfoFish", Rect2(87 + SX, 633, 64, 50), Rect2(175 + SX, 640, 240, 29)],
	["InfoRange", Rect2(94 + SX, 695, 50, 50), Rect2(175 + SX, 705, 240, 29)],
	["InfoRecord", Rect2(94 + SX, 748, 50, 50), Rect2(175 + SX, 758, 240, 29)],
]
var _s := 1.0              ## escala Figma → tela
var _o := Vector2.ZERO     ## canto do guia, em coordenadas do pai
var _slots: Array = []     ## [nó, retângulo em unidades do Figma, origem do pai em unidades do Figma ou null]
var _back: Control         ## água + rede (atrás da moldura)
var _play: Control         ## barra e peixe (acima da moldura)
var _hold_art: TextureRect
var _tips: Array[Control] = []
var _bar_texture: Texture2D
var _water_texture: Texture2D
var _hold_texture: Texture2D
var _hold_down_texture: Texture2D

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
		if live:
			_set_hold(false)
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
	if _back != null:
		_back.queue_redraw()
		_play.queue_redraw()


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
		return _lr(R_TRACK)
	return Rect2(size.x - SIDE - TRACK_WIDTH, TOP_MARGIN, TRACK_WIDTH, maxf(size.y - TOP_MARGIN - BOTTOM_MARGIN, 40.0))


## Retângulo em unidades do Figma → coordenadas deste nó.
func _lr(rect: Rect2) -> Rect2:
	return Rect2(rect.position * _s + _o - position, rect.size * _s)


func meter_rect() -> Rect2:
	if live:
		return _lr(R_METER)
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


## Área entre o HUD e as abas recebe os toques (o mundo atrás não); o desenho segue a página do Figma, ancorada embaixo.
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
	_update_scale(host)
	for slot: Array in _slots:
		_place(slot[0] as Control, slot[1] as Rect2, slot[2])
	if _pause_card != null:
		_pause_card.position = (size - _pause_card.size) / 2.0
	queue_redraw()


func _update_scale(host: Control) -> void:
	_s = minf(host.size.x / DESIGN.x, host.size.y / DESIGN.y)
	_o = Vector2((host.size.x - DESIGN.x * _s) / 2.0, host.size.y - DESIGN.y * _s)


## Põe um nó no retângulo do Figma (`parent_fig` = canto do pai em unidades do Figma, ou null para o nó raiz).
func _place(node: Control, rect: Rect2, parent_fig: Variant = null) -> void:
	var local := rect.position * _s
	if parent_fig == null:
		local += _o - position
	else:
		local -= (parent_fig as Vector2) * _s
	node.position = local
	node.size = rect.size * _s
	if node is Label:
		_fit_label(node as Label)


func _fit_label(label: Label) -> void:
	var px := maxi(int(round(24.0 * _s)), 9)
	label.add_theme_font_size_override("font_size", px)
	while px > 9 and label.get_minimum_size().x > label.size.x:
		px -= 1
		label.add_theme_font_size_override("font_size", px)


func _slot(node: Control, rect: Rect2, parent: Control = null, parent_fig: Variant = null) -> Control:
	(parent if parent != null else self).add_child(node)
	_slots.append([node, rect, parent_fig])
	return node


func _picture(file: String, rect: Rect2, node_name: String, parent: Control = null, parent_fig: Variant = null) -> TextureRect:
	var picture := TextureRect.new()
	picture.name = node_name
	picture.texture = load(UI + file) as Texture2D
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slot(picture, rect, parent, parent_fig)
	return picture


func _build_live() -> void:
	_update_scale(get_parent() as Control)
	_water_texture = load(UI + "fp_water.png") as Texture2D
	_bar_texture = load(UI + "fp_bar.png") as Texture2D
	_hold_texture = load(UI + "fp_hold.png") as Texture2D
	_hold_down_texture = load(UI + "fp_hold_down.png") as Texture2D
	# ordem do Figma, de baixo para cima: fundo, painel, dicas, pausa, botão, água, moldura, barra e peixe
	_picture("fp_bg.webp", R_BG, "MinigameBg")
	_build_info()
	var tips := ["Tip1", "Tip2", "Tip3"]
	for i in 3:
		var tip := _picture("fp_tip%d.png" % (i + 1), R_TIPS[i], tips[i])
		tip.visible = GameState.fishing_tutorial_done()  # no tutorial a vovó explica os mesmos passos
		_tips.append(tip)
	# pausa: o desenho é a imagem do Figma; o botão é transparente por cima
	_pause_button = BagUi.plain_button(pause)
	_pause_button.name = "PauseButton"
	var pause_art := TextureRect.new()
	pause_art.texture = load(UI + "fp_pause.png") as Texture2D
	pause_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pause_art.stretch_mode = TextureRect.STRETCH_SCALE
	pause_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	pause_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_button.add_child(pause_art)
	_slot(_pause_button, R_PAUSE)
	# "Segurar para pescar": a imagem do clicado entra na MESMA posição enquanto o dedo estiver no botão
	_hold_art = _picture("fp_hold.png", R_HOLD_ART, "HoldArt")
	_hold_button = BagUi.plain_button(func() -> void: pass)
	_hold_button.name = "HoldButton"
	_hold_button.set_meta("wood_primary", true)
	_hold_button.button_down.connect(func() -> void:
		_set_hold(true)
		Haptics.tap())
	_hold_button.button_up.connect(func() -> void: _set_hold(false))
	_slot(_hold_button, R_HOLD)
	_back = Control.new()
	_back.name = "WaterLayer"
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_back.set_anchors_preset(Control.PRESET_FULL_RECT)
	_back.draw.connect(_draw_back)
	add_child(_back)
	_picture("fp_frame.png", R_FRAME, "TrackFrame")
	_play = Control.new()
	_play.name = "PlayLayer"
	_play.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_play.set_anchors_preset(Control.PRESET_FULL_RECT)
	_play.draw.connect(_draw_play)
	add_child(_play)
	_build_pause_card()


func _set_hold(held: bool) -> void:
	_button_held = held
	if _hold_art != null:
		_hold_art.texture = _hold_down_texture if held else _hold_texture


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
	_set_hold(false)
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
	pass  # sem véu: o mundo fica como está; água e moldura são desenhadas pelas camadas `_back` e `_play`


## Camada de trás: a faixa de água e a rede (medidor) na canaleta estreita da moldura.
func _draw_back() -> void:
	if sim == null:
		return
	_back.draw_texture_rect(_water_texture, _lr(R_WATER), false)
	var meter := meter_rect()
	_back.draw_rect(_lr(R_GROOVE), Color(0.17, 0.09, 0.05))
	# rede: enche de baixo para cima, verde → amarelo → vermelho conforme cai
	var fraction := clampf(sim.meter, 0.0, 1.0)
	var tone := Palette.GO if fraction > 0.5 else (Palette.HONEY if fraction > 0.25 else Palette.ALERT)
	var shake := 0.0
	var outside := sim.fish_y < sim.bar_y or sim.fish_y > sim.bar_y + sim.bar_h
	if outside and not Motion.reduced:
		shake = sin(_time * 40.0) * 0.6
	var fill_h := meter.size.y * fraction
	_back.draw_rect(Rect2(meter.position.x + shake, meter.end.y - fill_h, meter.size.x, fill_h), tone)


## Camada da frente (acima da moldura): o retângulo que pesca (50% de opacidade, dá para ver o peixe atrás) e o peixe.
func _draw_play() -> void:
	if sim == null:
		return
	var track := track_rect()
	var bar_top := track.end.y - (sim.bar_y + sim.bar_h) * track.size.y
	_draw_bar(Rect2(track.position.x, bar_top, track.size.x, sim.bar_h * track.size.y))
	if sim.chest_shown:
		_draw_chest(track)
	var wiggle := 0.0 if Motion.reduced else sin(_time * 9.0) * 1.0
	var center := Vector2(track.get_center().x + wiggle, track.end.y - sim.fish_y * track.size.y)
	if _fish_texture != null:
		var box := FISH_BOX * _s
		var picture := Vector2(_fish_texture.get_size())
		var fit := minf(box.x / picture.x, box.y / picture.y)
		_play.draw_texture_rect(_fish_texture, Rect2(center - picture * fit / 2.0, picture * fit), false)
	else:
		_play.draw_circle(center, 14.0 * _s, Palette.INK)


## A imagem do retângulo em 3 fatias na vertical (os cantos arredondados mantêm a proporção; só o meio estica).
func _draw_bar(rect: Rect2) -> void:
	var texture := _bar_texture
	var scale_x := rect.size.x / texture.get_width()
	var corner := texture.get_width() * 0.2216  # px da imagem (cantos redondos)
	if rect.size.y < corner * scale_x * 2.0:
		corner = rect.size.y / scale_x / 2.0
	var edge := corner * scale_x
	var tint := Color(1, 1, 1, 0.5)
	var width := float(texture.get_width())
	var height := float(texture.get_height())
	_play.draw_texture_rect_region(texture, Rect2(rect.position, Vector2(rect.size.x, edge)), Rect2(0, 0, width, corner), tint)
	_play.draw_texture_rect_region(texture, Rect2(rect.position.x, rect.position.y + edge, rect.size.x, rect.size.y - edge * 2.0), Rect2(0, corner, width, height - corner * 2.0), tint)
	_play.draw_texture_rect_region(texture, Rect2(rect.position.x, rect.end.y - edge, rect.size.x, edge), Rect2(0, height - corner, width, corner), tint)


func _draw_chest(track: Rect2) -> void:
	var tilt := 0.0 if Motion.reduced else sin(_time * 2.2) * 0.07
	var center := Vector2(track.get_center().x, track.end.y - sim.chest_y * track.size.y)
	var texture := load("res://assets/sprites/ui/fishing/chest.png") as Texture2D
	_play.draw_set_transform(center, tilt, Vector2.ONE)
	if texture != null:
		var half := Vector2(texture.get_size()) / 2.0
		_play.draw_texture_rect(texture, Rect2(-half, Vector2(texture.get_size())), false, Color.WHITE if sim.chest_open else Color(1, 1, 1, 0.9))
	_play.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var radius := 30.0
	_play.draw_arc(center, radius, 0.0, TAU, 32, Color(0, 0, 0, 0.35), 4.0)
	var tone := Palette.GO if sim.chest_open else Palette.HONEY
	if sim.chest_meter > 0.0:
		_play.draw_arc(center, radius, -PI / 2.0, -PI / 2.0 + TAU * clampf(sim.chest_meter, 0.0, 1.0), 32, tone, 4.0)


## Painel "Pesca" (Figma): vara, isca, peixe, faixa de tamanho e recorde. Ícones e textos da partida em curso.
func _build_info() -> void:
	var cast: Dictionary = GameState.fishing.cast
	var rod_def: Dictionary = config.get("rods", {}).get(str(cast.get("rod", "")), {})
	var fish_id := str(cast.get("fish", ""))
	var fish_def: Dictionary = config.fish.get(fish_id, {})
	var panel := _picture("fp_panel.png", R_PANEL, "InfoCard")
	_info_card = panel
	var range_cm: Array = fish_def.get("cm", [0, 0])
	var record := GameState.fishing.record(fish_id)
	var rod_icon := str(rod_def.get("icon", ""))
	var icons: Array = [
		load(rod_icon) as Texture2D if rod_icon != "" else null,
		Database.item_icon(str(cast.get("bait", ""))),
		_fish_texture,
		load(UI + "fp_ico_ruler.png") as Texture2D,
		load(UI + "fp_ico_record.png") as Texture2D,
	]
	var texts: Array = [
		str(rod_def.get("name", "Vara")),
		Database.item_name(str(cast.get("bait", ""))),
		Database.item_name(fish_id),
		"%d–%d cm" % [int(range_cm[0]), int(range_cm[1])],
		("%s cm" % str(snappedf(float(record.best_cm), 0.5)).replace(".", ",")) if not record.is_empty() else "Sem recorde",
	]
	for i in ROWS.size():
		var row: Array = ROWS[i]
		var icon := TextureRect.new()
		icon.name = str(row[0]) + "Icon"
		icon.texture = icons[i] as Texture2D
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_slot(icon, row[1] as Rect2, panel, R_PANEL.position)
		var label := StationWood.text(str(texts[i]), 12)
		label.name = str(row[0])
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_slot(label, row[2] as Rect2, panel, R_PANEL.position)


static var _boxes: Dictionary = {}

## Moldura/barra de madeira (NinePatch de ui/home, montadas por tools/fishing_art.py).
static func _wood_box(file: String, margin: int) -> StyleBoxTexture:
	if not _boxes.has(file):
		var box := StyleBoxTexture.new()
		box.texture = load("res://assets/sprites/ui/home/%s.png" % file) as Texture2D
		box.set_texture_margin_all(margin)
		_boxes[file] = box
	return _boxes[file]
