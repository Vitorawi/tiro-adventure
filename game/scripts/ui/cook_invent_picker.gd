class_name CookInventPicker
extends Control
## Janelinha "FogaoIngredientes": abre por cima do cartão grande ao tocar num espaço. Cabeçalho "Combina com o espaço" com os
## ingredientes RECOMENDADOS (fixos; os que acabaram ficam cinza com "Acabou" e não se escolhem), cabeçalho "Outros
## ingredientes" com os que combinam com o espaço e que o jogador tem; escolher marca a célula (dourada); "Selecionar" põe no
## espaço, "Remover" esvazia, o X e o toque fora fecham sem mudar nada. O fundo, a rolagem e os botões descem com `extra`.
## Coordenadas em unidades do Figma relativas ao quadro (a mesma raiz do CookPanel).
##
## Nós: `InvPicker` (esta), `InvPickerScroll`, `InvCell_<item>` (metas `selected`, `recommended`, `out`, `in_pot`),
## `InvSelect`, `InvRemove`, `InvPickerClose`, `InvPickerBar`.

const PANEL_POS := Vector2(9, 526)
const PANEL_SIZE := Vector2(665.33, 538)
const WIN_POS := Vector2(50, 582)
const WIN_W := 546.0
const WIN_H := 370.0
const COL_X: Array[float] = [12.0, 141.0, 268.0, 394.0]
const CELL := Vector2(126, 132)
const ROW_STEP := 140.0
const BAR_POS := Vector2(598.67, 634)
const BAR_SIZE := Vector2(22.67, 337.33)
const BAR_ARROW := 22.0

var owner_view: CookInvent
var slot_index := 0
var kind := ""
var selected := ""
var extra := 0.0

var _catcher: Control
var _panel: CookPanel.Nine
var _scroll: CookScroll
var _select: Control
var _remove: Control
var _bar: Control
var _track: CookPanel.Nine
var _thumb: CookPanel.Nine
var _down: Control
var _thumb_drag := false
var _closing := false


func _init(view: CookInvent, index: int) -> void:
	owner_view = view
	slot_index = index
	kind = CookInvent.slot_kind(index)
	selected = str(CookInvent.slot_items()[index])
	name = "InvPicker"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	extra = view.extra


func _ready() -> void:
	# Toque fora: fecha só a janelinha (o toque é engolido).
	_catcher = Control.new()
	_catcher.name = "InvPickerCatcher"
	_catcher.position = Vector2(-3000, -3000)
	_catcher.size = Vector2(7000, 7000)
	_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	_catcher.gui_input.connect(_on_catcher_input)
	add_child(_catcher)
	var backing := Control.new()  # o toque dentro da janela nunca chega ao catcher
	backing.name = "Backing"
	backing.position = PANEL_POS
	backing.size = PANEL_SIZE
	backing.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backing)
	_panel = CookPanel.Nine.new(CookPanel.tex("inv_pick"), Vector4i(0, 150, 0, 150))
	_panel.name = "Panel"
	_panel.position = PANEL_POS
	_panel.size = PANEL_SIZE
	add_child(_panel)
	_scroll = CookScroll.new()
	_scroll.name = "InvPickerScroll"
	_scroll.position = WIN_POS
	_scroll.size = Vector2(WIN_W, WIN_H)
	_scroll.scrolled.connect(_sync_bar)
	add_child(_scroll)
	_build_bar()
	_select = CookPanel.pic("inv_pick_select", Vector2(90, 969), "InvSelect")
	CookPanel.widen(_select, Vector4(0, 17, 0, 17), _confirm)
	add_child(_select)
	_remove = CookPanel.pic("inv_pick_remove", Vector2(354, 955), "InvRemove")
	CookPanel.widen(_remove, Vector4(0, 4, 0, 4), _clear_slot)
	add_child(_remove)
	var close_button := CookPanel.pic("inv_pick_close", Vector2(582, 546), "InvPickerClose")
	CookPanel.widen(close_button, Vector4(4, 4, 4, 4), close)
	add_child(close_button)
	refresh()
	set_extra(extra, true)


func _on_catcher_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT and not button.pressed:
		close()
	_catcher.accept_event()


func close() -> void:
	if _closing:
		return
	_closing = true
	if owner_view != null and owner_view.picker == self:
		owner_view.picker = null
	queue_free()


# --- Conteúdo ---------------------------------------------------------------------------

## Ingredientes recomendados do espaço (fixos, na ordem do JSON) e os outros que combinam e que o jogador tem.
func _lists() -> Dictionary:
	var rec: Array = CookInvent.recommended(slot_index)
	var others: Array = []
	for item: String in Database.invent.get("items", {}):
		if item in rec or not CookInvent.fits(item, kind):
			continue
		if CookInvent.remaining(item, slot_index) > 0 or item == str(CookInvent.slot_items()[slot_index]):
			others.append(item)
	return {"rec": rec, "others": others}


func refresh() -> void:
	if _scroll == null:
		return
	var offset := _scroll.offset
	for child in _scroll.content.get_children():
		_scroll.content.remove_child(child)
		child.queue_free()
	var lists := _lists()
	var rec: Array = lists.rec
	var others: Array = lists.others
	var y := 6.0
	if not rec.is_empty():
		_scroll.content.add_child(CookPanel.pic("inv_pick_head_match", Vector2(12, y), "HeadMatch"))
		y += 52.0
		y = _grid(rec, y, true)
	if not others.is_empty():
		_scroll.content.add_child(CookPanel.pic("inv_pick_head_other", Vector2(15, y + 6.0), "HeadOther"))
		y += 6.0 + 49.0
		y = _grid(others, y, false)
	_scroll.content.size = Vector2(WIN_W, y + 6.0)
	_scroll.move_to(offset)
	_sync_bar()


## Grade de células (4 por linha, passo vertical 140); devolve o y do fim da última linha.
func _grid(list: Array, top: float, is_recommended: bool) -> float:
	var bottom := top
	for i in list.size():
		var cell := _cell(str(list[i]), is_recommended)
		cell.position = Vector2(COL_X[i % COL_X.size()], top + float(i / COL_X.size()) * ROW_STEP)
		_scroll.content.add_child(cell)
		bottom = cell.position.y + CELL.y
	return bottom


## Célula de ingrediente (igual em todas): fundo, figura, nome e quantidade (ou "Acabou"); só o fundo/selo mudam.
func _cell(item: String, is_recommended: bool) -> Control:
	var left := CookInvent.remaining(item, slot_index)
	var out := left <= 0
	var on := item == selected and not out
	var in_pot := item == str(CookInvent.slot_items()[slot_index])
	var cell := CookInvent._node("InvCell_" + item, Vector2.ZERO, CELL)
	var art := "inv_cell_out" if out else ("inv_cell_on" if on else ("inv_cell_rec" if is_recommended else "inv_cell_plain"))
	cell.add_child(CookPanel.pic(art, Vector2(0, -4 if on else 0), "Art"))
	cell.add_child(CookPanel.dish_pic(item, Rect2(32, 18, 59, 55), "Figure"))
	var title := CookPanel.label(Database.item_name(item), Rect2(4, 73, 118, 20), 16, 10, 1, CookPanel.INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.name = "Name"
	cell.add_child(title)
	if out:
		cell.add_child(CookPanel.pic("inv_out_pill", Vector2(19, 95), "OutPill"))
	else:
		cell.add_child(CookPanel.pic("inv_qty_pill", Vector2(37, 93), "QtyPill"))
		var count := CookPanel.label("x%d" % left, Rect2(37, 93, 49, 20), 15, 10, 1, CookPanel.INK, HORIZONTAL_ALIGNMENT_CENTER)
		count.name = "Qty"
		cell.add_child(count)
	if in_pot:
		cell.add_child(CookPanel.pic("inv_tag_pot", Vector2(-5, -4), "PotTag"))
	cell.set_meta("item", item)
	cell.set_meta("selected", on)
	cell.set_meta("recommended", is_recommended)
	cell.set_meta("out", out)
	cell.set_meta("in_pot", in_pot)
	if not out:
		cell.set_meta("on_tap", _pick.bind(item))
	return cell


func _pick(item: String) -> void:
	selected = item
	refresh()


# --- Botões -----------------------------------------------------------------------------

func _confirm() -> void:
	if selected == "":
		Events.toast_requested.emit("Toque em um ingrediente")
		Motion.shake(_select)
		return
	var view := owner_view
	var index := slot_index
	var item := selected
	close()
	view.set_slot(index, item)


func _clear_slot() -> void:
	var view := owner_view
	var index := slot_index
	close()
	view.set_slot(index, "")


# --- Barra de rolagem própria -----------------------------------------------------------

func _build_bar() -> void:
	_bar = CookInvent._node("InvPickerBar", BAR_POS, BAR_SIZE)
	_track = CookPanel.Nine.new(CookPanel.tex("inv_pick_track"), Vector4i(0, 40, 0, 40))
	_track.name = "Track"
	_track.size = BAR_SIZE
	_bar.add_child(_track)
	_thumb = CookPanel.Nine.new(CookPanel.tex("inv_pick_thumb"), Vector4i(0, 24, 0, 24))
	_thumb.name = "Thumb"
	CookPanel.widen(_thumb, Vector4(14, 0, 14, 0), Callable(), _on_thumb_input)
	_bar.add_child(_thumb)
	var up := CookInvent._node("Up", Vector2.ZERO, Vector2(BAR_SIZE.x, BAR_ARROW))
	CookPanel.widen(up, Vector4(14, 12, 14, 0), func() -> void: _scroll.scroll_to(_scroll.offset - CELL.y))
	_bar.add_child(up)
	_down = CookInvent._node("Down", Vector2(0, BAR_SIZE.y - BAR_ARROW), Vector2(BAR_SIZE.x, BAR_ARROW))
	CookPanel.widen(_down, Vector4(14, 0, 14, 12), func() -> void: _scroll.scroll_to(_scroll.offset + CELL.y))
	_bar.add_child(_down)
	add_child(_bar)


func _thumb_geometry() -> Rect2:
	var travel := _bar.size.y - BAR_ARROW * 2.0
	var content := maxf(_scroll.content_length(), 1.0)
	var view := _scroll.view_length()
	var height := travel if content <= view else clampf(travel * view / content, 40.0, travel)
	var share := 0.0 if _scroll.max_offset() <= 0.0 else _scroll.offset / _scroll.max_offset()
	return Rect2(0, BAR_ARROW + (travel - height) * share, BAR_SIZE.x, height)


func _sync_bar() -> void:
	if _thumb == null or _bar == null:
		return
	var rect := _thumb_geometry()
	_thumb.position = rect.position
	_thumb.size = rect.size
	_thumb.visible = _scroll.max_offset() > 0.0


func _on_thumb_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		_thumb_drag = button.pressed
		_thumb.accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion != null and _thumb_drag:
		var rect := _thumb_geometry()
		var travel := _bar.size.y - BAR_ARROW * 2.0 - rect.size.y
		if travel > 0.0:
			_scroll.scroll_to(_scroll.offset + motion.relative.y * _scroll.max_offset() / travel, false)
		_thumb.accept_event()


# --- Tamanho ----------------------------------------------------------------------------

## O painel, a rolagem, a barra e os botões descem/crescem com a altura extra do painel do fogão.
func set_extra(value: float, force: bool = false) -> void:
	if _panel == null or (not force and is_equal_approx(extra, value)):
		return
	extra = value
	var grown := PANEL_SIZE + Vector2(0, extra)
	_panel.size = grown
	(get_node("Backing") as Control).size = grown
	_scroll.size = Vector2(WIN_W, WIN_H + extra)
	_scroll.move_to(_scroll.offset)
	_bar.size = Vector2(BAR_SIZE.x, BAR_SIZE.y + extra)
	_track.size = _bar.size
	_down.position.y = _bar.size.y - BAR_ARROW
	_select.position.y = 969.0 + extra
	_remove.position.y = 955.0 + extra
	_sync_bar()
