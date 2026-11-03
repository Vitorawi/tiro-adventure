class_name WorldSelector
extends Control
## "Para onde vamos?" em madeira ilustrada: moldura creme com a placa do título por cima da borda de cima, cartões
## quadrados em duas colunas (o último, quando sobra um, é largo) e o X de madeira. Um toque viaja; fundo, X e Escape
## fecham. A folha fica entre o HUD e a barra de abas; as fotos encolhem juntas (mesma proporção) se faltar altura.
## Imagens `map_*.png` de `tools/world_map_art.gd`. Nós: `WorldListPanel`, `WorldList`, `SelectorTitle`, `CloseSelector`.

signal chosen(world_id: String)
signal closed

const GAP := 8.0              # entre cartões
const IN_L := 28.0            # da borda da moldura ao creme (px exibidos; a moldura é o `sell_frame` sem a plaquinha)
const IN_R := 26.0
const IN_T := 38.0            # do topo da moldura ao creme
const IN_B := 21.0
const PAD := 6.0              # folga entre o creme e os cartões
const MAX_WIDTH := 440.0
const MIN_CARD := 56.0
const FRAME_MARGINS := Vector4i(215, 340, 215, 160)   # NinePatch (px guardados, 3x)
const RAIL_CENTER := 29.7     # centro do trilho de cima da moldura (px exibidos): a placa do título fica centrada nele
const PLATE_RATIO := 213.0 / 600.0
const SIDE := 2.0

var _panel: Control
var _frame_art: Control
var _plate: TextureRect
var _title: Label
var _close: Button
var _rows: Control
var _buttons: Array[WorldCard] = []
var _geometry := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Palette.SCRIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_background_input)
	add_child(dim)
	_panel = Control.new()
	_panel.name = "WorldListPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)
	_frame_art = SellUi.nine("frame", FRAME_MARGINS, "FrameArt", null, "map_")
	_panel.add_child(_frame_art)
	_rows = Control.new()
	_rows.name = "WorldList"
	_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_rows)
	for world_id: String in Database.worlds:
		var row := WorldCard.new()
		row.setup(world_id)
		row.pressed.connect(_choose.bind(world_id))
		_rows.add_child(row)
		_buttons.append(row)
	_plate = SellUi.soft(TextureRect.new())
	_plate.name = "TitlePlate"
	_plate.texture = WorldCard.tex("plate")
	_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_plate.stretch_mode = TextureRect.STRETCH_SCALE
	_panel.add_child(_plate)
	_title = StationWood.text("Para onde vamos?", 17)
	_title.name = "SelectorTitle"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.clip_text = true
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_panel.add_child(_title)
	_close = BagUi.plain_button(dismiss)
	_close.name = "CloseSelector"
	_close.custom_minimum_size = Vector2(44, 44)
	var art := SellUi.soft(TextureRect.new())
	art.texture = MissionUi.tex("close")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_close.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	art.offset_left = -19.0
	art.offset_right = 19.0
	art.offset_top = -19.0
	art.offset_bottom = 19.0
	_panel.add_child(_close)
	resized.connect(func() -> void: _layout.call_deferred())
	_layout.call_deferred()


## Limites verticais da folha (coordenadas deste Control): abaixo do HUD e acima da barra de abas.
func _limits() -> Vector2:
	var bottom := size.y - 88.0
	var lowest := INF
	for node_name: String in ["TabBar", "TabBarArt"]:
		var bar := get_tree().root.find_child(node_name, true, false) as Control
		if is_instance_valid(bar) and bar.size.y > 0:
			lowest = minf(lowest, bar.global_position.y - global_position.y)
	if lowest < INF:
		bottom = minf(size.y, lowest - 6.0)
	var top := maxf(0.0, Hud.SHEET_TOP - global_position.y)
	return Vector2(top, bottom)


## Altura da folha para cartões quadrados de largura `card` (a plaquinha do título entra em `title_h`).
func _total_height(card: float, title_h: float) -> Dictionary:
	var count := _buttons.size()
	var square := _buttons[0]
	var plate := card * 0.74
	var plate_h := plate * WorldCard.PLATE_RATIO
	var extra := plate_h * (1.0 - WorldCard.PLATE_OVERLAP)
	var square_ratio := 580.0 / 600.0
	var wide_ratio := 445.0 / 1190.0
	var photo := square.get_node("WorldPhoto") as TextureRect
	if photo.texture != null:
		square_ratio = float(photo.texture.get_height()) / float(photo.texture.get_width())
	var wide_card := _buttons[count - 1]
	var wide_texture := (wide_card.get_node("WorldPhoto") as TextureRect).texture
	if wide_texture != null:
		wide_ratio = float(wide_texture.get_height()) / float(wide_texture.get_width())
	var rows_h := 0.0
	var pairs := count / 2
	var square_h := card * square_ratio + extra
	rows_h += pairs * square_h + (pairs - 1 if pairs > 0 else 0) * GAP
	var wide_h := 0.0
	if count % 2 == 1:
		wide_h = (2.0 * card + GAP) * wide_ratio + extra
		rows_h += GAP + wide_h
	var art_y := maxf(0.0, title_h / 2.0 - RAIL_CENTER)
	var top := maxf(art_y + IN_T + PAD, title_h + 4.0)
	return {"height": top + rows_h + PAD + IN_B + art_y, "top": top, "art_y": art_y, "square_h": square_h, "wide_h": wide_h, "plate": plate}


func _layout() -> void:
	if not is_instance_valid(_panel) or _buttons.is_empty(): return
	var limits := _limits()
	var available := maxf(0.0, limits.y - limits.x)
	var width_cap := minf(MAX_WIDTH, size.x - SIDE * 2.0)
	var card := floorf((width_cap - IN_L - IN_R - PAD * 2.0 - GAP) / 2.0)
	var title_w := 0.0
	var info := {}
	while true:
		var frame_w := 2.0 * card + GAP + IN_L + IN_R + PAD * 2.0
		title_w = clampf(frame_w * 0.54, 128.0, 190.0)
		info = _total_height(card, title_w * PLATE_RATIO)
		if float(info.height) <= available or card <= MIN_CARD: break
		card -= 1.0
	var frame_w := 2.0 * card + GAP + IN_L + IN_R + PAD * 2.0
	var title_h := title_w * PLATE_RATIO
	var art_y: float = info.art_y
	var panel_h: float = info.height
	_panel.size = Vector2(frame_w, panel_h)
	_panel.position = Vector2(roundf((size.x - frame_w) / 2.0), maxf(limits.x, limits.y - panel_h))
	_frame_art.position = Vector2(0, art_y)
	_frame_art.size = Vector2(frame_w, panel_h - art_y)
	_plate.size = Vector2(title_w, title_h)
	_plate.position = Vector2(roundf((frame_w - title_w) / 2.0), 0)
	_title.size = Vector2(title_w * 0.76, title_h * 0.58)
	_title.position = _plate.position + Vector2(title_w * 0.12, title_h * 0.20)
	var title_px := clampi(int(roundf(title_h * 0.36)), 13, 19)
	var title_font := _title.get_theme_font("font")
	while title_px > 11 and title_font.get_string_size(_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_px).x > _title.size.x - 2.0:
		title_px -= 1
	_title.add_theme_font_size_override("font_size", title_px)
	_close.position = Vector2(frame_w - 46.0, 0)
	_close.size = Vector2(44, 44)
	# Cartões: colunas iguais, centradas no creme.
	var x0 := IN_L + PAD
	var top: float = info.top
	_rows.position = Vector2(x0, top)
	var inner := 2.0 * card + GAP
	var y := 0.0
	for i: int in _buttons.size():
		var button := _buttons[i]
		var is_wide := i == _buttons.size() - 1 and _buttons.size() % 2 == 1
		button.wide = is_wide
		button.plate_width = float(info.plate)
		var height := button.fit(inner if is_wide else card)
		button.position = Vector2(0.0 if is_wide else (i % 2) * (card + GAP), y)
		if i % 2 == 1 or is_wide: y += height + GAP
	_rows.size = Vector2(inner, maxf(0.0, y - GAP))
	_rows.custom_minimum_size = _rows.size
	_geometry = {"card": card, "top": top, "inner": inner, "frame_w": frame_w, "title_h": title_h}


func open(current: String) -> void:
	show()
	refresh(current)
	_layout.call_deferred()


func refresh(current: String) -> void:
	for row: WorldCard in _buttons:
		row.refresh(current)


func dismiss() -> void:
	hide()
	closed.emit()


func _choose(id: String) -> void:
	if Places.world_error(id) == "":
		chosen.emit(id)


func _on_background_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
		dismiss()
		get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		dismiss()
		get_viewport().set_input_as_handled()
