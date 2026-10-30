class_name FarmDock
extends PanelContainer
## Menu de madeira da horta: abre EM CIMA do canteiro tocado (setinha verde apontando para ele) com as sementes
## liberadas numa fileira que rola para os lados e UM só espaço bloqueado no fim (a próxima semente), mais o Regar
## (modo `plant`), ou a foice + "Colher tudo (N)" (modo `harvest`). Substitui a antiga barra presa embaixo.
## Com o menu aberto, o dedo que COMEÇA num canteiro usa a ferramenta escolhida em todo canteiro por onde passar
## (a `RoomView` entrega o gesto por `press/move/release`); arrastar um espaço do menu para fora dele carrega a
## ficha (fantasma) até os canteiros. As entradas e as regras vêm do `PlotTray` e do `GameState`.
## Arte em `assets/sprites/ui/home/farm_*.png` (gerada por `tools/farm_tray_art.gd`, 3x; NinePatch em escala 1/3).

const HINT_KEY := "ui:tray_drag_hint"
const HINT_TIMES := 3
const SLOT := 62.0
const GAP := 6.0
const PAD := 4.0  # folga dentro da janela de rolagem: o brilho dourado do espaço escolhido não é cortado
const FRAME_MARGIN := 56  # canto do NinePatch (pixels guardados, 3x)
const BODY_MARGIN := Vector4(21.0, 13.0, 21.0, 12.0)  # esq, cima, dir, baixo
const VIEW_H := SLOT + 10.0
const WATER_W := SLOT + 14.0
const HEIGHT := 97.0
const ARROW := Vector2(32.0, 30.0)
const ARROW_OUT := 18.0  # quanto a seta passa da moldura
const X_PX := 34.0
const X_HIT := 44.0
const MARGIN_X := 8.0  # folga mínima da tela
const DOCK_TOP := 118.0  # topo mínimo do menu (abaixo da linha 1 do HUD; a linha 2 some enquanto ele está aberto)
const SLOP := 10.0
const EDGE := 36.0
const EDGE_SPEED := 6.0
const TOP_LIMIT := 120.0
const NAV_FALLBACK := 84.0
## Antigo: quanto a câmera subia para o canteiro ficar acima da barra de baixo. Mantido por compatibilidade.
const BAR_LIFT := 70.0
const GLIDE_TIME := 0.28
const DIM := 0.3

## Mexer na câmera NÃO fecha o menu (ele segue o canteiro): plantar fora da tela pede arrastar a câmera sem perder a
## semente. Só as bandejas presas ao objeto fecham.
static var _current: FarmDock

var room: RoomView
var mode := "plant"
var plot_index := -1
var closing := false
var entries: Array[Dictionary] = []
var selected := ""

var _host: Control
var _focus := ""
var _order: Array[String] = []
var _tiles: Dictionary = {}
var _captions: Dictionary = {}
var _view: Control
var _seeds: HBoxContainer
var _row: HBoxContainer
var _body: MarginContainer
var _art: Control
var _frame: NinePatchRect
var _overlay: Control
var _arrow: TextureRect
var _close: Button
var _fade_left: TextureRect
var _fade_right: TextureRect
var _hint: Control
var _hint_tween: Tween
var _hint_planted := 0
var _hint_plot := -1
var _hint_ref := Vector2.ZERO
var _signature := ""
var _gesture := DragGhost.new()
var _active := false
var _moved := false
var _press_plot := -1
var _finger := Vector2.ZERO
var _done: Dictionary = {}
var _total := 0
var _layer: GestureLayer
var _token: Control
var _count_label: Label
var _count_disc: PanelContainer
var _scroll := 0.0
var _scroll_max := 0.0
var _coast := 0.0
var _touch: Dictionary = {}
var _glide := 0.0
var _below := false
var _dim_tween: Tween
var _scroll_tween: Tween
var _bar: CanvasItem  # a barra do mundo (pílula e rostos) some enquanto o menu está aberto
var _bar_was := false


## Abre o menu (troca o que estiver aberto). `plot_index` = canteiro tocado (escolhe as sementes certas, estufa
## incluída); `focus` = semente pedida pelo "Ir" ou "water".
static func open(room: RoomView, mode: String, plot_index: int = -1, focus: String = "") -> FarmDock:
	if is_instance_valid(_current):
		_current.close(true)
	var dock := FarmDock.new()
	dock.name = "FarmDock"
	dock.room = room
	dock.mode = mode
	dock.plot_index = plot_index
	_current = dock
	dock._build(focus)
	return dock


static func current() -> FarmDock:
	return _current if is_instance_valid(_current) and not _current.closing else null


static func is_open_for(for_room: RoomView) -> bool:
	var dock := current()
	return dock != null and dock.room == for_room


## Topo mínimo (y da tela) que a parte de cima do canteiro precisa ter para o menu caber em cima dele.
static func plot_top_need() -> float:
	return DOCK_TOP + HEIGHT + ARROW_OUT + 6.0


func _build(focus: String) -> void:
	_host = _find_host()
	_focus = focus if focus != "water" else ""
	if mode == "harvest":
		entries = PlotTray.sickle_entries(room)
		selected = "sickle"
	else:
		entries = _plant_entries()
		entries.append(PlotTray.water_entry(room))
		selected = _initial_selection(focus)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	z_index = 4
	z_as_relative = false
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_host.add_child(self)
	_art = Control.new()
	_art.name = "Art"
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)
	_frame = NinePatchRect.new()
	_frame.name = "Frame"
	_frame.texture = tex("frame")
	_frame.patch_margin_left = FRAME_MARGIN
	_frame.patch_margin_right = FRAME_MARGIN
	_frame.patch_margin_top = FRAME_MARGIN
	_frame.patch_margin_bottom = FRAME_MARGIN
	_frame.scale = Vector2.ONE / 3.0
	_frame.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.add_child(_frame)
	_art.resized.connect(_fit_frame)
	_body = MarginContainer.new()
	_body.name = "Body"
	_body.mouse_filter = Control.MOUSE_FILTER_PASS
	_body.add_theme_constant_override("margin_left", int(BODY_MARGIN.x))
	_body.add_theme_constant_override("margin_top", int(BODY_MARGIN.y))
	_body.add_theme_constant_override("margin_right", int(BODY_MARGIN.z))
	_body.add_theme_constant_override("margin_bottom", int(BODY_MARGIN.w))
	add_child(_body)
	_row = UiKit.hbox(6)
	_row.name = "DockRow"
	_row.mouse_filter = Control.MOUSE_FILTER_PASS
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_body.add_child(_row)
	_build_overlay()
	_rebuild()
	_host.resized.connect(_layout)
	Events.state_changed.connect(_on_state_changed)
	var joined := _find_main()
	if joined:
		joined.call("set_row2_blocker", "farm_dock", true)  # a linha 2 do HUD dá lugar ao menu
	_bar = _host.find_child("WorldBar", true, false) as CanvasItem
	if _bar != null:
		_bar_was = _bar.visible
		_bar.visible = false
	_fit.call_deferred()
	_open_motion.call_deferred()
	_show_hint.call_deferred()


static func tex(file: String) -> Texture2D:
	return load(HomeUi.DIR + "farm_" + file + ".png") as Texture2D


func _find_host() -> Control:
	var screen := room.get_tree().root.find_child("WorldsScreen", true, false) as Control
	return screen if screen else room.get_parent() as Control


func _find_main() -> Node:
	var node: Node = room
	while node:
		if node.has_method("set_row2_blocker"):
			return node
		node = node.get_parent()
	return null


func _first_empty() -> int:
	for index in room.plot_indices():
		if GameState.plot_status(index) == "empty":
			return index
	var all := room.plot_indices()
	return all[0] if not all.is_empty() else 0


## Canteiro que o menu aponta: o tocado; sem ele, o primeiro vazio (plantar), regável (regar) ou pronto (colher).
func _anchor_plot() -> int:
	if mode == "harvest":
		var ready := room.ready_plots()
		if plot_index >= 0 and GameState.plot_status(plot_index) == "ready":
			return plot_index
		return ready[0] if not ready.is_empty() else plot_index
	if plot_index >= 0:
		return plot_index
	if selected == "water":
		var waterable := room.waterable_plots()
		if not waterable.is_empty():
			return waterable[0]
	return _first_empty()


## Sementes na ordem do `PlotTray`; ao reconstruir, a ordem já mostrada se mantém (nada pula de lugar sob o dedo).
func _plant_entries() -> Array[Dictionary]:
	var index := plot_index if plot_index >= 0 else _first_empty()
	var fresh := PlotTray.dock_seed_entries(room, index, _focus)
	if _order.is_empty():
		for entry: Dictionary in fresh:
			_order.append(str(entry.id))
		return fresh
	var by_id: Dictionary = {}
	var open_ids: Array[String] = []
	var lock_id := ""
	for entry: Dictionary in fresh:
		by_id[str(entry.id)] = entry
		if str(entry.get("error", "")) == "":
			open_ids.append(str(entry.id))
		else:
			lock_id = str(entry.id)
	var merged: Array[String] = []
	for id: String in _order:
		if id in open_ids:
			merged.append(id)
	for id: String in open_ids:
		if not id in merged:
			merged.append(id)
	if lock_id != "":
		merged.append(lock_id)
	_order = merged
	var result: Array[Dictionary] = []
	for id: String in merged:
		result.append(by_id[id])
	return result


## Foco > última semente usada > a primeira liberada.
func _initial_selection(focus: String) -> String:
	var ids: Array[String] = []
	for entry: Dictionary in entries:
		if str(entry.get("error", "")) == "":
			ids.append(str(entry.id))
	if focus != "" and focus in ids:
		return focus
	if PlotTray.last_crop in ids:
		return PlotTray.last_crop
	for id in ids:
		if id != "water":
			return id
	return "water" if "water" in ids else ""


func _fit_frame() -> void:
	if not is_instance_valid(_frame):
		return
	_frame.position = Vector2.ZERO
	_frame.size = _art.size.max(Vector2.ONE) * 3.0


func _fit() -> void:
	if closing:
		return
	size = get_combined_minimum_size()
	_fit_frame()
	_follow_plot(true)


## Largura que a janela de rolagem pode ter nesta tela (descontados a moldura e o Regar).
func _view_limit() -> float:
	var frame_max := (_host.size.x if is_instance_valid(_host) else 360.0) - MARGIN_X * 2.0
	var water := WATER_W if mode == "plant" else 0.0
	return frame_max - (BODY_MARGIN.x + BODY_MARGIN.z) - water


func _layout() -> void:
	if closing or not is_instance_valid(_host):
		return
	_rebuild()
	_fit.call_deferred()


# --- Conteúdo ------------------------------------------------------------------------

func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.name = "Overlay"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_arrow = TextureRect.new()
	_arrow.name = "DockArrow"
	_arrow.texture = tex("arrow")
	_arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_arrow.stretch_mode = TextureRect.STRETCH_SCALE
	_arrow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.size = ARROW
	_overlay.add_child(_arrow)
	_fade_left = _make_fade(false)
	_fade_right = _make_fade(true)
	_close = BagUi.plain_button(func() -> void: close())
	_close.name = "CloseDock"
	_close.custom_minimum_size = Vector2(X_HIT, X_HIT)
	_close.size = Vector2(X_HIT, X_HIT)
	_close.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	# O disco (34) fica no canto de cima à direita, 3 px para fora da moldura; o alvo de toque tem 44.
	_close.offset_left = -36.0
	_close.offset_right = 8.0
	_close.offset_top = -16.0
	_close.offset_bottom = 28.0
	var disc := TextureRect.new()
	disc.name = "Disc"
	disc.texture = tex("x")
	disc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	disc.stretch_mode = TextureRect.STRETCH_SCALE
	disc.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_close.add_child(disc)
	disc.set_anchors_preset(Control.PRESET_CENTER)
	disc.offset_left = -X_PX / 2.0
	disc.offset_right = X_PX / 2.0
	disc.offset_top = -X_PX / 2.0
	disc.offset_bottom = X_PX / 2.0
	_close.pressed.connect(func() -> void: Motion.bounce(disc))
	_overlay.add_child(_close)


## Degradê da cor do sulco nas pontas da janela de rolagem: avisa que tem mais para o lado.
func _make_fade(right: bool) -> TextureRect:
	var gradient := Gradient.new()
	var groove := Color("b0764a")
	gradient.colors = PackedColorArray([Color(groove, 0.0 if right else 1.0), Color(groove, 1.0 if right else 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(1, 0)
	texture.width = 32
	texture.height = 8
	var fade := TextureRect.new()
	fade.name = "FadeRight" if right else "FadeLeft"
	fade.texture = texture
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.size = Vector2(22.0, VIEW_H - 8.0)
	fade.visible = false
	_overlay.add_child(fade)
	return fade


func _rebuild() -> void:
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	_tiles.clear()
	_captions.clear()
	_view = null
	_seeds = null
	if mode == "plant":
		entries = _plant_entries()
		entries.append(PlotTray.water_entry(room))
	if mode == "harvest":
		_build_harvest()
	else:
		_build_plant()
	_signature = _make_signature()
	_update_states()
	_layout_overlay()


func _build_plant() -> void:
	_view = Control.new()
	_view.name = "SeedScroll"
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.clip_contents = true
	_seeds = UiKit.hbox(int(GAP))
	_seeds.name = "Seeds"
	_seeds.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.add_child(_seeds)
	_seeds.add_child(_spacer(PAD))
	var count := 0
	for entry: Dictionary in entries:
		if str(entry.id) != "water":
			_seeds.add_child(_tile(entry))
			count += 1
	_seeds.add_child(_spacer(PAD))
	var content_w := PAD * 2.0 + count * SLOT + maxf(0.0, count - 1.0) * GAP + GAP * 2.0
	var view_w := minf(content_w, _view_limit())
	_view.custom_minimum_size = Vector2(view_w, VIEW_H)
	_view.size = Vector2(view_w, VIEW_H)
	_seeds.size = Vector2(content_w, VIEW_H)
	_seeds.position = Vector2(-_scroll, 0.0)
	_scroll_max = maxf(0.0, content_w - view_w)
	_scroll = clampf(_scroll, 0.0, _scroll_max)
	_seeds.position.x = -_scroll
	_row.add_child(_view)
	var divider := ColorRect.new()
	divider.name = "Divider"
	divider.color = Color(0.36, 0.2, 0.09, 0.55)
	divider.custom_minimum_size = Vector2(2, SLOT - 10.0)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_row.add_child(divider)
	for entry: Dictionary in entries:
		if str(entry.id) == "water":
			var water := _tile(entry)
			water.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			_row.add_child(water)
	_reveal_selected.call_deferred(false)


func _spacer(width: float) -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(width, 0.0)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gap


func _build_harvest() -> void:
	_scroll_max = 0.0
	var sickle: Dictionary = entries[0]
	var sickle_tile := _tile(sickle)
	sickle_tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_row.add_child(sickle_tile)
	var all: Dictionary = entries[1]
	var count := room.ready_plots().size()
	var blocked := _harvest_block()
	var holder := Control.new()
	holder.name = "HarvestHolder"
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	holder.custom_minimum_size = Vector2(minf(190.0, _view_limit() - SLOT - 6.0), VIEW_H)  # mesma altura do plantar: a foice cabe no sulco
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_row.add_child(holder)
	if blocked != "":
		var paper := PanelContainer.new()
		var style := UiKit.surface(Color("ffedc9"), 14)
		style.set_content_margin_all(8)
		style.border_color = Color("c9783b")
		style.set_border_width_all(2)
		paper.add_theme_stylebox_override("panel", style)
		paper.mouse_filter = Control.MOUSE_FILTER_PASS
		paper.add_child(StepCardUi.lock_note(blocked.get_slice(":", 0), Callable(), all.icon as Texture2D))  # só o motivo curto: "Silo sem espaço"
		holder.add_child(paper)
		_inset_in_groove(paper)
	else:
		var button := StepCardUi.go_button("Colher tudo (%d)" % count, func() -> void: _harvest_all())
		button.name = "HarvestAll"
		holder.add_child(button)
		_inset_in_groove(button)


## Botão/nota ao lado da foice: a mesma folga dos espaços dentro do sulco, sem encostar na borda escura da moldura.
func _inset_in_groove(node: Control) -> void:
	StepCardUi.stretch(node)
	node.offset_left = PAD
	node.offset_right = -(PAD + 8.0)
	node.offset_top = 6.0
	node.offset_bottom = -6.0


## Depósito sem lugar para nenhum dos prontos: devolve o motivo; senão "".
func _harvest_block() -> String:
	var ready := room.ready_plots()
	if ready.is_empty():
		return ""
	var first := ""
	for index in ready:
		var error := GameState.harvest_error(index)
		if error == "":
			return ""
		if first == "":
			first = error
	return first


func _harvest_all() -> void:
	var reason := str((entries[1].tap as Callable).call())
	if reason != "":
		Events.toast_requested.emit(reason)


## Espaço de madeira: fundo creme (escolhido leva o contorno dourado; o bloqueado é bege com o cadeado dourado),
## ícone e legenda embaixo. Quem recebe o toque é o menu (`_gui_input`): o botão só guarda o sinal `pressed`.
func _tile(entry: Dictionary) -> Button:
	var id := str(entry.id)
	var locked := str(entry.get("error", "")) != ""
	var caption := str(entry.get("caption", ""))
	var caption_fn: Variant = entry.get("caption_fn")
	var count_fn: Variant = entry.get("count_fn")
	if caption_fn is Callable and not count_fn is Callable:
		caption = (caption_fn as Callable).call()
	if locked:
		caption = str(entry.get("lock_caption", "Bloqueada"))
	var tile := Button.new()
	tile.name = "Tile_" + id
	tile.flat = true
	tile.focus_mode = Control.FOCUS_NONE
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.custom_minimum_size = Vector2(SLOT, SLOT)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for phase: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		tile.add_theme_stylebox_override(phase, StyleBoxEmpty.new())
	tile.set_meta("locked", locked)
	var art := TextureRect.new()
	art.name = "Art"
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(art)
	var visual := VBoxContainer.new()
	visual.name = "Visual"
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_theme_constant_override("separation", 0)
	visual.alignment = BoxContainer.ALIGNMENT_CENTER
	tile.add_child(visual)
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual.offset_top = 3.0
	visual.offset_bottom = -3.0
	var picture := TextureRect.new()
	picture.name = "Picture"
	picture.texture = entry.icon as Texture2D
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(38, 38)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var big: bool = picture.texture != null and picture.texture.get_width() > 64
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS if big else CanvasItem.TEXTURE_FILTER_NEAREST
	visual.add_child(picture)
	var label := StepCardUi.wood(caption, 12)
	label.name = "Caption"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	visual.add_child(label)
	_captions[id] = label
	if locked:
		picture.modulate.a = 0.35
		picture.visible = false
		var lock := TextureRect.new()
		lock.name = "LockIcon"
		lock.texture = tex("lock")
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock.custom_minimum_size = Vector2(24, 31)
		visual.add_child(lock)
		visual.move_child(lock, 0)
	if count_fn is Callable:
		# "Regar" na legenda e a quantidade de canteiros para regar num selo no canto.
		var seal := UiKit.chip(null, "×%d" % (count_fn as Callable).call())
		seal.name = "Count"
		tile.add_child(seal)
		seal.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		seal.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		seal.offset_left = 4.0
		seal.offset_right = 4.0
		seal.offset_top = -7.0
		seal.offset_bottom = -7.0
		seal.visible = int((count_fn as Callable).call()) > 0
	_tiles[id] = tile
	tile.pressed.connect(func() -> void: _on_tile(id))
	return tile


## Visual de cada espaço conforme o estado: normal, escolhido (contorno dourado) ou bloqueado.
func _update_states() -> void:
	for id: String in _tiles:
		var tile := _tiles[id] as Control
		if not is_instance_valid(tile):
			continue
		var art := tile.get_node("Art") as TextureRect
		var state := "lock" if bool(tile.get_meta("locked", false)) else ("on" if id == selected else "normal")
		var texture := tex("slot_lock" if state == "lock" else ("slot_on" if state == "on" else "slot"))
		art.texture = texture
		var box := texture.get_size() / 3.0
		art.set_anchors_preset(Control.PRESET_CENTER)
		art.offset_left = -box.x / 2.0
		art.offset_right = box.x / 2.0
		art.offset_top = -box.y / 2.0
		art.offset_bottom = box.y / 2.0
		if state == "on":
			tile.z_index = 1
		else:
			tile.z_index = 0


func _on_tile(id: String) -> void:
	var entry := _entry(id)
	if str(entry.get("error", "")) != "":
		var help: Variant = entry.get("help")
		if help is Callable and (help as Callable).is_valid():
			(help as Callable).call()
		else:
			Events.toast_requested.emit(str(entry.error))
		return
	select.call_deferred(id)


func _entry(id: String) -> Dictionary:
	for entry: Dictionary in entries:
		if str(entry.id) == id:
			return entry
	return {}


# --- API pública (toque, testes e capturas) ------------------------------------------------

func entry_ids() -> Array[String]:
	var ids: Array[String] = []
	for entry: Dictionary in entries:
		ids.append(str(entry.id))
	return ids


func selected_entry() -> Dictionary:
	return _entry(selected)


func tile_node(id: String) -> Control:
	return _tiles.get(id)


func select(id: String) -> void:
	if closing or _entry(id).is_empty() or str(_entry(id).get("error", "")) != "":
		return
	if id != selected:
		selected = id
		_update_states()
		_signature = _make_signature()
		_reveal_selected(true)


func tap_tile(id: String) -> void:
	_on_tile(id)


## Para o menu seguir outro canteiro (tocou noutro vazio): as sementes se refazem se a estufa muda, e ele desliza.
func retarget(index: int) -> void:
	if closing or mode != "plant" or index == plot_index:
		return
	var previous_greenhouse := GameState.is_greenhouse_plot(plot_index) if plot_index >= 0 else false
	plot_index = index
	if GameState.is_greenhouse_plot(index) != previous_greenhouse:
		_order.clear()
		_rebuild()
		if _entry(selected).is_empty() or str(_entry(selected).get("error", "")) != "":
			selected = _initial_selection("")
			_update_states()
		_fit.call_deferred()
	_glide = GLIDE_TIME


func close(immediate: bool = false) -> void:
	if closing:
		return
	closing = true
	_cancel_gesture()
	_stop_hint()
	if _current == self:
		_current = null
	if Events.state_changed.is_connected(_on_state_changed):
		Events.state_changed.disconnect(_on_state_changed)
	if is_instance_valid(_host) and _host.resized.is_connected(_layout):
		_host.resized.disconnect(_layout)
	var main := _find_main() if is_instance_valid(room) else null
	if main:
		main.call("set_row2_blocker", "farm_dock", false)
	_restore_bar()
	if is_instance_valid(room):
		room.dock_closed()
	if immediate or Motion.reduced or not is_inside_tree():
		queue_free()
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "modulate:a", 0.0, Motion.POP_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * 0.92, Motion.POP_OUT)
	tween.chain().tween_callback(queue_free)


func _exit_tree() -> void:
	_restore_bar()
	if _current == self:
		_current = null
	_cancel_gesture()
	_stop_hint()


func _restore_bar() -> void:
	if is_instance_valid(_bar) and _bar_was:
		_bar.visible = true
	_bar = null


func _on_state_changed() -> void:
	if closing:
		return
	if mode == "harvest" and room.ready_plots().is_empty():
		close()
		return
	for id: String in _captions:
		var entry := _entry(id)
		var caption_fn: Variant = entry.get("caption_fn")
		var count_fn: Variant = entry.get("count_fn")
		if count_fn is Callable:
			var seal := (_tiles[id] as Control).get_node_or_null("Count") as Control
			if seal != null:
				var amount := int((count_fn as Callable).call())
				seal.visible = amount > 0
				((seal.get_child(0) as Control).get_child(-1) as Label).text = "×%d" % amount
		elif caption_fn is Callable and is_instance_valid(_captions[id]) and not bool((_tiles[id] as Control).get_meta("locked", false)):
			(_captions[id] as Label).text = (caption_fn as Callable).call()
	if _make_signature() != _signature and not _active and _touch.is_empty():
		_refresh.call_deferred()
	_check_hint_progress()


## Refaz só o que mudou (semente liberada, depósito cheio...), mantendo a rolagem e a escolha.
func _refresh() -> void:
	if closing:
		return
	_rebuild()
	_fit.call_deferred()


func _make_signature() -> String:
	if mode == "harvest":
		return "h:%d:%s" % [room.ready_plots().size(), _harvest_block()]
	var shown := ""
	for entry: Dictionary in _plant_entries_preview():
		shown += "%s%s," % [str(entry.id), "1" if str(entry.get("error", "")) != "" else "0"]
	return "p:%s" % shown


func _plant_entries_preview() -> Array[Dictionary]:
	var index := plot_index if plot_index >= 0 else _first_empty()
	return PlotTray.dock_seed_entries(room, index, _focus)


# --- Entrada: rolar para os lados, tocar e arrastar a semente -----------------------------------

func _gui_input(event: InputEvent) -> void:
	if closing:
		return
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_touch_press(button.global_position)
		else:
			_touch_release(button.global_position)
		accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_touch_move(motion.global_position)
		accept_event()


func _tile_at(point: Vector2) -> String:
	for id: String in _tiles:
		var tile := _tiles[id] as Control
		if not is_instance_valid(tile) or not tile.is_visible_in_tree():
			continue
		if not tile.get_global_rect().has_point(point):
			continue
		if is_instance_valid(_view) and _view.is_ancestor_of(tile) and not _view.get_global_rect().has_point(point):
			continue
		return id
	return ""


func _in_view(point: Vector2) -> bool:
	return is_instance_valid(_view) and _view.get_global_rect().grow(4.0).has_point(point)


func _touch_press(point: Vector2) -> void:
	_coast = 0.0
	if is_instance_valid(_scroll_tween):
		_scroll_tween.kill()
	_touch = {"id": _tile_at(point), "start": point, "last": point, "scroll0": _scroll, "mode": "", "time": Time.get_ticks_msec(), "vel": 0.0, "in_view": _in_view(point)}


func _touch_move(point: Vector2) -> void:
	if _active:
		move(point)
		return
	if _touch.is_empty():
		return
	var delta: Vector2 = point - (_touch.start as Vector2)
	if str(_touch.mode) == "":
		if delta.length() <= SLOP:
			return
		var id := str(_touch.id)
		var movable := id != "" and not bool((_tiles[id] as Control).get_meta("locked", false))
		if bool(_touch.in_view) and _scroll_max > 0.0 and absf(delta.x) >= absf(delta.y):
			_touch.mode = "scroll"
		elif movable:
			_touch.mode = "ghost"
			_begin_tile_drag(id, point)
			return
		elif bool(_touch.in_view) and _scroll_max > 0.0:
			_touch.mode = "scroll"
		else:
			_touch.mode = "ignore"
	if str(_touch.mode) == "scroll":
		var now := Time.get_ticks_msec()
		var dt := maxf(0.001, float(now - int(_touch.time)) / 1000.0)
		var step: float = (_touch.last as Vector2).x - point.x
		_touch.vel = lerpf(float(_touch.vel), step / dt, 0.5)
		_touch.time = now
		_touch.last = point
		_set_scroll(float(_touch.scroll0) - delta.x)


func _touch_release(point: Vector2) -> void:
	if _active:
		release(point)
		_touch.clear()
		return
	if _touch.is_empty():
		return
	var info := _touch
	_touch = {}
	match str(info.mode):
		"":
			if str(info.id) != "":
				_on_tile(str(info.id))
		"scroll":
			var fresh := Time.get_ticks_msec() - int(info.time) < 120
			_coast = float(info.vel) if fresh else 0.0
			if absf(_coast) < 40.0:
				_coast = 0.0


func _set_scroll(value: float) -> void:
	_scroll = clampf(value, 0.0, _scroll_max)
	if is_instance_valid(_seeds):
		_seeds.position.x = -_scroll
	_update_fades()


func _update_fades() -> void:
	if is_instance_valid(_fade_left):
		_fade_left.visible = _scroll_max > 0.0 and _scroll > 2.0
		_fade_right.visible = _scroll_max > 0.0 and _scroll < _scroll_max - 2.0


## Rola (com animação) até o espaço escolhido aparecer inteiro na janela.
func _reveal_selected(animate: bool) -> void:
	if not is_instance_valid(_view) or not _tiles.has(selected) or _scroll_max <= 0.0:
		return
	var tile := _tiles[selected] as Control
	if not is_instance_valid(tile) or not _seeds.is_ancestor_of(tile):
		return
	var left := tile.position.x - PAD
	var right := tile.position.x + tile.size.x + PAD
	var target := _scroll
	if left < _scroll:
		target = left
	elif right > _scroll + _view.size.x:
		target = right - _view.size.x
	target = clampf(target, 0.0, _scroll_max)
	if is_equal_approx(target, _scroll):
		return
	if not animate or Motion.reduced or not is_inside_tree():
		_set_scroll(target)
		return
	if is_instance_valid(_scroll_tween):
		_scroll_tween.kill()
	_scroll_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_scroll_tween.tween_method(_set_scroll, _scroll, target, 0.22)


## Posição das pontas esmaecidas e da seta/X em relação à moldura (a moldura muda de tamanho com a janela).
func _layout_overlay() -> void:
	if not is_instance_valid(_view) or not is_instance_valid(_fade_left):
		if is_instance_valid(_fade_left):
			_fade_left.visible = false
			_fade_right.visible = false
		return
	var origin := _view.global_position - global_position
	_fade_left.position = origin + Vector2(0.0, 4.0)
	_fade_right.position = origin + Vector2(_view.size.x - _fade_right.size.x, 4.0)
	_update_fades()


# --- Posição: em cima do canteiro, seguindo a câmera ------------------------------------------------

func _nav_top() -> float:
	var nav := _host.get_tree().root.find_child("TabBar", true, false) as Control if is_instance_valid(_host) else null
	if nav and nav.is_visible_in_tree():
		return nav.global_position.y
	return (_host.global_position.y + _host.size.y if is_instance_valid(_host) else 780.0) - NAV_FALLBACK


## Acompanha o canteiro todo quadro: centralizado sobre ele, preso a 8 px das bordas; em cima, ou embaixo (seta
## para cima) se em cima não houver lugar abaixo do HUD.
func _follow_plot(snap: bool = false) -> void:
	if closing or not is_instance_valid(room) or not is_instance_valid(_host) or size.x <= 1.0:
		return
	var index := _anchor_plot()
	if index < 0:
		return
	var anchor := room.plot_anchor(index)
	var top := room.world_to_screen(anchor.above as Vector2)
	var base := room.world_to_screen(anchor.below as Vector2)
	var center_x := room.world_to_screen(room.plot_center(index)).x
	var host_left := _host.global_position.x
	var x := clampf(center_x - size.x / 2.0, host_left + MARGIN_X, maxf(host_left + MARGIN_X, host_left + _host.size.x - size.x - MARGIN_X))
	var y := top.y - ARROW_OUT - 3.0 - size.y
	var below := false
	if y < DOCK_TOP:
		var y_below := base.y + ARROW_OUT + 3.0
		if y_below + size.y <= _nav_top() - 6.0:
			y = y_below
			below = true
		else:
			y = DOCK_TOP
	var target := Vector2(x, y)
	if _glide > 0.0 and not snap and is_inside_tree():
		_glide = maxf(0.0, _glide - get_process_delta_time())
		global_position = global_position.lerp(target, 1.0 - exp(-22.0 * get_process_delta_time()))
	else:
		global_position = target
	var arrow_x := clampf(center_x - global_position.x, 30.0, maxf(30.0, size.x - 30.0))
	_set_arrow(arrow_x, below)
	pivot_offset = Vector2(arrow_x, size.y + ARROW_OUT if not below else -ARROW_OUT)


func _set_arrow(arrow_x: float, below: bool) -> void:
	if not is_instance_valid(_arrow):
		return
	_below = below
	_arrow.flip_v = below
	_arrow.position = Vector2(arrow_x - ARROW.x / 2.0, -ARROW_OUT if below else size.y - (ARROW.y - ARROW_OUT))


func _open_motion() -> void:
	if closing:
		return
	_fit()
	if Motion.reduced:
		return
	modulate.a = 0.0
	scale = Vector2.ONE * 0.9
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "modulate:a", 1.0, Motion.POP_IN)
	tween.tween_property(self, "scale", Vector2.ONE, Motion.POP_IN).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Dica do primeiro uso ------------------------------------------------------------------

## "Arraste até a terra": nas três primeiras aberturas em `plant` com 2+ canteiros vazios, uma ficha da semente sai
## do primeiro espaço aberto e passa por dois canteiros vazios, até o jogador plantar (ou tocar/arrastar).
func _show_hint() -> void:
	if closing or mode != "plant":
		return
	var times := 0
	var stored: Variant = GameState.progress.seen.get(HINT_KEY, 0)
	if stored is bool:
		times = HINT_TIMES if stored else 0
	else:
		times = int(stored)
	if times >= HINT_TIMES:
		return
	var empty: Array[int] = []
	for index in room.plot_indices():
		if GameState.plot_status(index) == "empty" and (selected == "" or GameState.plant_error(index, selected) == ""):
			empty.append(index)
	if empty.size() < 2:
		return
	GameState.progress.seen[HINT_KEY] = times + 1
	GameState.mark_seen([] as Array[String])
	_hint_planted = _planted_count()
	_hint = Control.new()
	_hint.name = "DragHint"
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.z_index = 4
	_hint.z_as_relative = false
	_host.add_child(_hint)
	var caption := PanelContainer.new()
	caption.name = "HintLabel"
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UiKit.surface(Palette.INK, 20)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	caption.add_theme_stylebox_override("panel", style)
	var row := UiKit.hbox(6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(UiKit.ctl("spark", 18, Palette.HONEY))
	var text := UiKit.short_label("Arraste até a terra", &"SmallLabel", Color.WHITE)
	text.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(text)
	caption.add_child(row)
	_hint.add_child(caption)
	var token := DragGhost.make_token(_entry(selected).get("icon") as Texture2D)
	token.name = "HintHand"
	token.modulate.a = 0.0
	_hint.add_child(token)
	_animate_hint.call_deferred(token, caption, empty)


func _animate_hint(token: Control, caption: Control, empty: Array[int]) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if closing or not is_instance_valid(_hint) or not is_instance_valid(token) or not _tiles.has(selected):
		return
	var tile := _tiles[selected] as Control
	var points: Array[Vector2] = []
	for index: int in empty:
		if points.size() < 2:
			points.append(room.world_to_screen(room.plot_center(index)))
	var offset := Vector2(DragGhost.PX / 2.0, DragGhost.PX)
	var start := tile.get_global_rect().get_center() - Vector2(DragGhost.PX / 2.0, DragGhost.PX / 2.0)
	_hint_plot = empty[0]
	_hint_ref = points[0]
	var last := points[points.size() - 1]
	caption.reset_size()
	var cx := clampf(last.x - caption.size.x / 2.0, MARGIN_X, _host.size.x - caption.size.x - MARGIN_X)
	caption.position = Vector2(cx, minf(last.y + 34.0, _nav_top() - caption.size.y - 8.0)) - _host.global_position
	if Motion.reduced:
		token.global_position = points[0] - offset + Vector2(0.0, DragGhost.LIFT * 0.5)
		token.modulate.a = 0.85
		return
	_hint_tween = create_tween().set_loops()
	_hint_tween.tween_callback(func() -> void: token.global_position = start)
	_hint_tween.tween_property(token, "modulate:a", 0.9, 0.2)
	for point: Vector2 in points:
		var target := point - offset + Vector2(0.0, DragGhost.LIFT * 0.5)
		_hint_tween.tween_property(token, "global_position", target, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_hint_tween.tween_interval(0.2)
	_hint_tween.tween_property(token, "modulate:a", 0.0, 0.2)
	_hint_tween.tween_interval(0.5)


func _planted_count() -> int:
	var total := 0
	for index in room.plot_indices():
		if GameState.plot_status(index) != "empty":
			total += 1
	return total


## A ficha some assim que o jogador planta (ou mexe no menu).
func _check_hint_progress() -> void:
	if is_instance_valid(_hint) and _planted_count() > _hint_planted:
		_stop_hint()


func _stop_hint() -> void:
	if is_instance_valid(_hint_tween):
		_hint_tween.kill()
	_hint_tween = null
	if is_instance_valid(_hint):
		_hint.queue_free()
	_hint = null


# --- Gesto: a ferramenta escolhida começa no canteiro (ou sai do menu) -----------------------------

func gesture_active() -> bool:
	return _active


## A `RoomView` chama no `pressed`. Devolve true se o dedo caiu num canteiro (a ferramenta assume o gesto e a
## câmera não mexe); a primeira ação já acontece no canteiro tocado.
func press(global_point: Vector2) -> bool:
	if closing or selected == "":
		return false
	var plot := room.plot_at(room.screen_to_world(global_point))
	if plot < 0:
		return false
	_active = true
	_moved = false
	_press_plot = plot
	_done.clear()
	_total = 0
	_finger = global_point
	_gesture.press(global_point)
	_begin_visuals()
	_act(global_point)
	return true


## Começa o arrasto de uma semente (ou do regador/foice) que saiu do menu: a ficha vai acima do dedo.
func _begin_tile_drag(id: String, global_point: Vector2) -> void:
	if id != selected:
		select(id)
	_stop_hint()
	_active = true
	_moved = true
	_press_plot = -1
	_done.clear()
	_total = 0
	_finger = global_point
	_gesture.press(global_point)
	_begin_visuals()
	_set_dim(true)
	_follow()
	_act(global_point)


func move(global_point: Vector2) -> void:
	if not _active:
		return
	if room._is_pinching():  # a pinça tem prioridade: o gesto acaba sem agir mais
		_cancel_gesture()
		return
	_finger = global_point
	if _gesture.move(global_point) and not _moved:
		_moved = true
		_set_dim(true)
		_stop_hint()
	_follow()
	_act(global_point)


func release(global_point: Vector2) -> void:
	if not _active:
		return
	var plot := _press_plot
	var tapped := not _moved and plot >= 0
	var acted := _total > 0
	_cancel_gesture()
	if tapped and not acted:
		room.dock_plot_tap(plot, self)
	elif tapped and mode == "plant":
		retarget(plot)  # um toque que plantou: o menu desliza para o canteiro novo
		room._lift_for_dock(plot)


## Para o gesto sem agir (fecha a ficha e o rastro).
func _cancel_gesture() -> void:
	if not _active:
		return
	_active = false
	if is_instance_valid(_token):
		Motion.pop_out(_token)
	_token = null
	if is_instance_valid(_count_disc):
		_count_disc.queue_free()
	_count_disc = null
	if is_instance_valid(_layer):
		_layer.queue_free()
	_layer = null
	_set_dim(false)


## O menu esmaece enquanto o dedo arrasta (vê-se a horta) e volta quando o gesto acaba.
func _set_dim(on: bool) -> void:
	if closing:
		return
	if is_instance_valid(_dim_tween):
		_dim_tween.kill()
	var alpha := DIM if on else 1.0
	if Motion.reduced or not is_inside_tree():
		modulate.a = alpha
		return
	_dim_tween = create_tween()
	_dim_tween.tween_property(self, "modulate:a", alpha, 0.12)


func _begin_visuals() -> void:
	_layer = GestureLayer.new()
	_layer.name = "FarmGesture"
	room.add_child(_layer)
	_token = _gesture.begin(_layer, selected_entry().get("icon") as Texture2D)
	_count_disc = PanelContainer.new()
	_count_disc.name = "GestureCount"
	_count_disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count_disc.add_theme_stylebox_override("panel", UiKit.surface(Palette.GO, 12))
	_count_label = UiKit.short_label("0", &"BadgeLabel", Color.WHITE)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_disc.add_child(_count_label)
	_count_disc.custom_minimum_size = Vector2(24, 24)
	_layer.add_child(_count_disc)
	_refresh_visuals()


func _follow() -> void:
	_gesture.finger = _finger
	if is_instance_valid(_layer):
		_gesture.follow(_layer)
		_refresh_visuals()


func _refresh_visuals() -> void:
	if not is_instance_valid(_layer):
		return
	if is_instance_valid(_count_label):
		_count_label.text = str(_total)
	if is_instance_valid(_token):
		_count_disc.position = _token.position + Vector2(_token.size.x - 14.0, -8.0)
	_layer.targets.clear()
	for index in room.plot_indices():
		if _accepts(index) and not _done.has(index):
			_layer.targets.append(_screen_polygon(index))
	_layer.queue_redraw()


func _screen_polygon(index: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in room.plot_diamond(index):
		result.append(room.world_to_screen(point) - room.global_position)
	return result


## Este canteiro ainda aceita a ferramenta escolhida?
func _accepts(index: int) -> bool:
	match selected:
		"water":
			return GameState.water_error(index) == ""
		"sickle":
			return GameState.plot_status(index) == "ready" and GameState.harvest_error(index) == ""
		_:
			return GameState.plot_status(index) == "empty" and GameState.plant_error(index, selected) == ""


func _act(global_point: Vector2) -> void:
	var world := room.screen_to_world(global_point)
	var index := room.plot_at(world)
	if index < 0 or _done.has(index):
		return
	var drag: Variant = selected_entry().get("drag")
	if not (drag is Callable) or not (drag as Callable).is_valid():
		return
	if (drag as Callable).call(world) == true:
		_done[index] = true
		_total += 1
		Haptics.tap()
		if is_instance_valid(_layer):
			_layer.trail.append(room.world_to_screen(room.plot_center(index)) - room.global_position)
		_refresh_visuals()
		_stop_hint()


func _process(delta: float) -> void:
	if closing:
		return
	_follow_plot()
	if is_instance_valid(_hint) and _hint_plot >= 0 and room.world_to_screen(room.plot_center(_hint_plot)).distance_to(_hint_ref) > 8.0:
		_stop_hint()  # a câmera mexeu: o caminho da ficha ficaria no lugar errado
	if absf(_coast) > 12.0 and _touch.is_empty():
		_set_scroll(_scroll + _coast * delta)
		_coast *= exp(-5.0 * delta)
		if _scroll <= 0.0 or _scroll >= _scroll_max:
			_coast = 0.0
	else:
		_coast = 0.0
	_layout_overlay()
	if not _active:
		return
	# Rolagem na borda: o dedo perto da lateral/de baixo (ou a ficha perto do HUD) anda a câmera.
	var local := _finger - room.global_position
	var top := local.y - DragGhost.LIFT - DragGhost.PX
	var direction := Vector2.ZERO
	if local.x < EDGE:
		direction.x = -1.0
	elif local.x > room.size.x - EDGE:
		direction.x = 1.0
	if _nav_top() - _finger.y < EDGE:
		direction.y = 1.0
	elif top < TOP_LIMIT - EDGE:
		direction.y = -1.0
	if direction != Vector2.ZERO:
		room.scroll_by(direction * EDGE_SPEED)
		_follow()
		_act(_finger)


## Simulação de gesto (testes e capturas): começa no centro do primeiro canteiro, passa pelos demais e solta.
func drag_plots(indices: Array, release_at_end: bool = true) -> void:
	var points: Array[Vector2] = []
	for index: int in indices:
		points.append(room.world_to_screen(room.plot_center(index)))
	drag_points(points, release_at_end)


func drag_points(points: Array[Vector2], release_at_end: bool = true) -> void:
	if points.is_empty():
		return
	press(points[0])
	for i in range(1, points.size()):
		move(points[i])
	if release_at_end:
		release(points[points.size() - 1])


func release_drag() -> void:
	release(_finger)


## Rastro claro e losangos tracejados dos canteiros que ainda aceitam a ferramenta (coordenadas locais da sala).
class GestureLayer extends Control:
	var trail := PackedVector2Array()
	var targets: Array[PackedVector2Array] = []

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		z_index = 5
		z_as_relative = false

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		if trail.size() >= 2:
			draw_polyline(trail, Color(Palette.HONEY_SOFT, 0.55), 14.0, true)
		for polygon in targets:
			for i in polygon.size():
				draw_dashed_line(polygon[i], polygon[(i + 1) % polygon.size()], Color.WHITE, 2.0, 6.0)
