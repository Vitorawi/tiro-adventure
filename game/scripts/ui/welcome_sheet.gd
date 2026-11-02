class_name WelcomeSheet
extends Control
## Folha das boas-vindas ("Bem-vindo de volta!") no visual "madeira ilustrada", no mesmo molde do detalhe de item
## (`ItemUi`) e do "Como fazer" (`HelpUi`): moldura com placa e X de madeira, um cartão creme compacto com o Tiro e o presente
## do dia (só quando há presente) e um painel de madeira com uma linha por novidade (pratinho, texto, ícones e botão Ir).
## Embaixo, um botão de madeira calmo ("Depois") ou o verde ("Vamos lá!" quando não há presente). Só monta: o que fazer
## (pegar o presente, ir até a novidade) chega pronto do `WelcomeBack`. A folha tem a altura do conteúdo e nunca passa da
## área entre o HUD e a base da tela; o painel rola por dentro se tiver muitas linhas.
##
## Nós preservados: `RewardSheet` (esta folha), `DailyGift`, `Line_<tipo>`; botões com o texto "Pegar", "Depois" e "Vamos lá!".
## Novos: `WelcomeFrame`, `WelcomeTitle`, `CloseButton`, `WelcomeGift`, `GiftPlate`, `GiftChips`, `WelcomePanel`,
## `WelcomeScroll`, `LineGo`.
##
## Opções de `open`: gift (Dictionary de prêmios, vazio = sem presente), on_gift (Callable do "Pegar"), lines (Array de
## {name, texture, title, icons: Array[Texture2D], go: Callable}), on_close (Callable), animate (true).

const SIDE := ItemUi.SIDE
const IN_L := ItemUi.IN_L
const IN_R := ItemUi.IN_R
const TOP := ItemUi.TOP
const BOTTOM := ItemUi.BOTTOM
const GAP := ItemUi.GAP
const TAIL := ItemUi.TAIL
const PANEL_TOP := ItemUi.PANEL_TOP
const PANEL_BOTTOM := ItemUi.PANEL_BOTTOM
const PANEL_SIDE := ItemUi.PANEL_SIDE
const LIST_PAD := ItemUi.LIST_PAD
const GUTTER := ItemUi.GUTTER
const CARD_PAD_X := 14.0
const CARD_PAD_Y := 12.0
const GIFT_PLATE := 56.0
const GIFT_BTN_W := 84.0
const ACTION_H := 44.0
const ROW_PLATE := 44.0
const ROW_PAD_X := 6.0
const ROW_PAD_Y := 7.0
const ROW_GAP := 8.0
const GO_W := 64.0
const DIVIDER := 2.0
const TITLE_PX := 15
const LINE_COLOR := Color("e2c08f")
const ICON_PX := 32.0
const ICON_GAP := 4.0

var host: Node
var dim: ColorRect
var frame: Control
var _on_close := Callable()
var _animate := true
var _rest_y := 0.0
var _width := 0.0
var _tween: Tween


static func open(host_node: Node, options: Dictionary) -> WelcomeSheet:
	for child: Node in host_node.get_children():
		host_node.remove_child(child)
		child.queue_free()
	var sheet := WelcomeSheet.new()
	sheet.name = "RewardSheet"
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host_node.add_child(sheet)
	sheet._build(host_node, options)
	return sheet


# --- Medidas --------------------------------------------------------------------------------

static func _screen() -> Vector2:
	return (Engine.get_main_loop() as SceneTree).root.get_visible_rect().size


static func _text_w(text: String, px: int) -> float:
	return HelpUi._text_w(text, px)


## Altura da linha: o título quebrado em até 3 linhas (medido de verdade) e, abaixo, os ícones em quantas fileiras couberem.
static func _row_plan(row: Dictionary, width: float) -> Dictionary:
	var body_w := width - ROW_PAD_X * 2.0 - ROW_PLATE - ROW_GAP * 2.0 - GO_W
	var title_m := HelpUi._measure(str(row.title), TITLE_PX, body_w, 3)
	var count := (row.get("icons", []) as Array).size()
	var per_row := maxi(1, floori((body_w + ICON_GAP) / (ICON_PX + ICON_GAP)))
	var icon_rows := ceili(count / float(per_row)) if count > 0 else 0
	var icons_h := icon_rows * ICON_PX + maxf(0.0, icon_rows - 1.0) * ICON_GAP
	var content := float(title_m.height) + (3.0 + icons_h if icon_rows > 0 else 0.0)
	return {"height": ROW_PAD_Y * 2.0 + maxf(ROW_PLATE, content), "body_w": body_w, "title_m": title_m}


## Chips do presente e a altura do cartão (nada é medido depois: a moldura depende dela).
static func _gift_plan(gift: Dictionary, cw: float) -> Dictionary:
	var inner_w := cw - CARD_PAD_X * 2.0
	var words_w := inner_w - GIFT_PLATE - 10.0
	var chips: Array[Control] = []
	var coins := int(gift.get("coins", 0))
	if coins > 0:
		var text := "+%d" % coins
		chips.append(StepCardUi.wood_chip(UiKit.ui_icon("coin"), text, "", Callable(), "GiftCoins"))
	var items: Dictionary = gift.get("items", {})
	for id: String in items:
		var text := "+%d" % int(items[id])
		var chip := StepCardUi.wood_chip(Database.item_icon(id), text, "", Callable(), "GiftItem_" + id)
		chips.append(chip)
	var rows := 0
	var used := 0.0
	for chip in chips:
		var w := 42.0 + _text_w(str((chip.get_child(0).get_child(-1) as Label).text), 15)  # 42 = ícone 24 + folgas do chip de madeira
		if rows == 0 or used + 6.0 + w > words_w:
			rows += 1
			used = w
		else:
			used += 6.0 + w
	var title_h := ACTION_H
	var chips_h := rows * 32.0 + maxf(0.0, rows - 1.0) * 4.0
	var words_h := title_h + (4.0 + chips_h if rows > 0 else 0.0)
	return {"height": CARD_PAD_Y * 2.0 + maxf(GIFT_PLATE, words_h), "chips": chips, "words_w": words_w, "inner_w": inner_w, "title_h": title_h}


# --- Montagem -------------------------------------------------------------------------------

func _build(host_node: Node, options: Dictionary) -> void:
	host = host_node
	_on_close = options.get("on_close", Callable()) as Callable
	_animate = bool(options.get("animate", true))
	dim = ColorRect.new()
	dim.name = "Dim"
	dim.color = Palette.SCRIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			close())
	var gift: Dictionary = options.get("gift", {})
	var has_gift := not gift.is_empty()
	var lines: Array[Dictionary] = []
	lines.assign(options.get("lines", []))
	_width = ItemUi.panel_width()
	var cw := _width - IN_L - IN_R
	var avail := _screen().y - Hud.SHEET_TOP - TAIL
	var gift_plan := _gift_plan(gift, cw) if has_gift else {}
	# Painel: altura natural das linhas; se não couber, rola por dentro (o resto da folha não muda de tamanho).
	var row_w := cw - PANEL_SIDE * 2.0 - LIST_PAD * 2.0
	var row_plans: Array[Dictionary] = []
	var list_h := 0.0
	for line in lines:
		var plan := _row_plan(line, row_w)
		row_plans.append(plan)
		list_h += float(plan.height)
	list_h += maxf(0.0, lines.size() - 1.0) * DIVIDER
	var has_panel := not lines.is_empty()
	var panel_h := PANEL_TOP + LIST_PAD * 2.0 + list_h + PANEL_BOTTOM if has_panel else 0.0
	var fixed := TOP + ACTION_H + GAP + BOTTOM + (float(gift_plan.height) + GAP if has_gift else 0.0) + (GAP if has_panel else 0.0)
	var scrolls := false
	if has_panel and fixed + panel_h > avail + 0.5:
		scrolls = true
		panel_h = maxf(avail - fixed, PANEL_TOP + LIST_PAD * 2.0 + 120.0 + PANEL_BOTTOM)
	var total := fixed + panel_h
	frame = Control.new()
	frame.name = "WelcomeFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_STOP
	frame.custom_minimum_size = Vector2(_width, total)
	frame.size = Vector2(_width, total)
	add_child(frame)
	var art := SellUi.nine("frame", ItemUi.FRAME_MARGINS, "Art", null, "item_")
	frame.add_child(art)
	StepCardUi.stretch(art)
	var y := TOP
	if has_gift:
		var card := _gift_card(gift, gift_plan, options.get("on_gift", Callable()) as Callable)
		frame.add_child(card)
		SellUi.place(card, 0.0, IN_L, 1.0, -IN_R, 0.0, y, 0.0, y + float(gift_plan.height))
		y += float(gift_plan.height) + GAP
	if has_panel:
		var panel := _panel(lines, row_plans, cw, row_w, list_h, panel_h, scrolls)
		frame.add_child(panel)
		SellUi.place(panel, 0.0, IN_L, 1.0, -IN_R, 0.0, y, 0.0, y + panel_h)
		y += panel_h + GAP
	var closing := _action(has_gift)
	frame.add_child(closing)
	var button_w := closing.custom_minimum_size.x
	SellUi.place(closing, 0.5, -button_w / 2.0, 0.5, button_w / 2.0, 0.0, y, 0.0, y + ACTION_H)
	frame.add_child(_overlay(_width, "Bem-vindo de volta!"))
	StepCardUi.stretch(frame.get_child(frame.get_child_count() - 1) as Control)
	resized.connect(layout)


func _action(has_gift: bool) -> Button:
	var caption := "Depois" if has_gift else "Vamos lá!"
	return _button(caption, not has_gift, 132.0 if has_gift else 168.0, caption, close)


## Botão de madeira (verde = a ação principal; amarelo = calmo). O texto fica no próprio Button.
static func _button(caption: String, green: bool, width: float, node_name: String, on_pressed: Callable) -> Button:
	var button := BagUi.plain_button(on_pressed)
	button.name = node_name
	button.custom_minimum_size = Vector2(width, ACTION_H)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var art := SellUi.nine("btn_green" if green else "btn_gold", Vector4i(66, 66, 66, 66), "Art", null, "item_")
	art.show_behind_parent = true
	button.add_child(art)
	StepCardUi.stretch(art)
	button.text = caption
	button.clip_text = true
	var px := 18
	for candidate in [18, 16, 14]:
		px = candidate
		if _text_w(caption, candidate) <= width - 24.0:
			break
	button.theme = HomeUi.theme(px, Palette.WOOD_CREAM, ItemUi.GREEN_OUTLINE if green else Palette.WOOD_INK, 3)
	button.add_theme_constant_override("outline_size", 3)
	if green:
		button.set_meta("wood_primary", true)
	button.pressed.connect(func() -> void: Motion.bounce(button))
	return button


## Placa do título e X de madeira (fecha só esta folha).
func _overlay(width: float, title: String) -> Control:
	var layer := Control.new()
	layer.name = "Overlay"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var avail := width - ItemUi.PLAQUE_X * 2.0
	var px := 22
	for candidate in [22, 20, 18, 16, 14]:
		px = candidate
		if _text_w(title, candidate) <= avail:
			break
	var plaque := MissionUi.text(title, px, Palette.WOOD_CREAM, 3)
	plaque.name = "WelcomeTitle"
	plaque.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plaque.clip_text = true
	plaque.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	layer.add_child(plaque)
	SellUi.place(plaque, 0.0, ItemUi.PLAQUE_X, 1.0, -ItemUi.PLAQUE_X, 0.0, ItemUi.PLAQUE_Y, 0.0, ItemUi.PLAQUE_BASE)
	var x := BagUi.plain_button(close)
	x.name = "CloseButton"
	x.custom_minimum_size = Vector2(44, 44)
	var picture := SellUi.soft(TextureRect.new())
	picture.texture = MissionUi.tex("close")
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	x.add_child(picture)
	picture.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	picture.offset_left = -19.0
	picture.offset_right = 19.0
	picture.offset_top = -19.0
	picture.offset_bottom = 19.0
	x.pressed.connect(func() -> void: Motion.bounce(picture))
	layer.add_child(x)
	var box := ItemUi.CLOSE_BOX
	SellUi.place(x, 1.0, box.x, 1.0, box.z, 0.0, box.y, 0.0, box.w)
	return layer


## Pratinho redondo desenhado por `draw` (não é um TextureRect solto) com um ícone centrado por cima, se houver.
static func _plate(plate_px: float, icon: Texture2D, node_name: String, pixel_px: float = 0.0) -> Control:
	var hero := Control.new()
	hero.name = node_name
	hero.custom_minimum_size = Vector2(plate_px, plate_px)
	hero.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var plate_texture := ItemUi.tex("plate")
	hero.draw.connect(func() -> void: hero.draw_texture_rect(plate_texture, Rect2(Vector2.ZERO, hero.size), false))
	if icon != null:
		var picture := TextureRect.new()
		picture.name = "Icon"
		picture.texture = icon
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if icon.get_width() <= 32 else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var px := pixel_px if pixel_px > 0.0 else plate_px - 12.0
		hero.add_child(picture)
		picture.set_anchors_preset(Control.PRESET_CENTER)
		picture.offset_left = -px / 2.0
		picture.offset_right = px / 2.0
		picture.offset_top = -px / 2.0
		picture.offset_bottom = px / 2.0
	return hero


## Cartão do presente: o Tiro num pratinho, "Presente do dia", os chips do prêmio e o botão Pegar (único verde).
func _gift_card(gift: Dictionary, plan: Dictionary, on_gift: Callable) -> Control:
	var card := Control.new()
	card.name = "DailyGift"
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var art := SellUi.nine("card", Vector4i(75, 75, 75, 75), "Art", null, "item_")
	card.add_child(art)
	StepCardUi.stretch(art)
	var body := UiKit.hbox(10)
	body.name = "Body"
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(body)
	StepCardUi.stretch(body)
	body.offset_left = CARD_PAD_X
	body.offset_right = -CARD_PAD_X
	body.offset_top = CARD_PAD_Y
	body.offset_bottom = -CARD_PAD_Y
	var head := HomeUi.head_texture()
	body.add_child(_plate(GIFT_PLATE, head, "GiftPlate", 44.0))
	var words := UiKit.vbox(4)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var top := UiKit.hbox(8)
	top.custom_minimum_size.y = float(plan.title_h)
	var title := StationWood.text("Presente do dia", TITLE_PX)
	title.name = "GiftTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(title)
	top.add_child(_button("Pegar", true, GIFT_BTN_W, "Pegar", on_gift))
	words.add_child(top)
	var flow := UiKit.flow(6)
	flow.name = "GiftChips"
	flow.add_theme_constant_override("v_separation", 4)
	for chip: Control in plan.chips:
		flow.add_child(chip)
	if flow.get_child_count() > 0:
		words.add_child(flow)
	else:
		flow.free()
	body.add_child(words)
	return card


## Painel de madeira com uma linha por novidade (dividida por filetes). Rola por dentro quando `scrolls`.
func _panel(lines: Array[Dictionary], plans: Array[Dictionary], cw: float, row_w: float, list_h: float, height: float, scrolls: bool) -> Control:
	var panel := Control.new()
	panel.name = "WelcomePanel"
	panel.custom_minimum_size = Vector2(cw, height)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var art := SellUi.nine("panel", Vector4i(69, 150, 69, 88), "Art", null, "item_")
	panel.add_child(art)
	StepCardUi.stretch(art)
	var heading := MissionUi.text("Enquanto você estava fora", 17, Palette.WOOD_CREAM, 3)
	heading.name = "PanelTitle"
	heading.clip_text = true
	panel.add_child(heading)
	SellUi.place(heading, 0.0, PANEL_SIDE, 1.0, -PANEL_SIDE, 0.0, 8.0, 0.0, 42.0)
	var list := UiKit.vbox(0)
	list.name = "WelcomeList"
	list.mouse_filter = Control.MOUSE_FILTER_PASS
	for i in lines.size():
		if i > 0:
			list.add_child(HelpUi._divider(row_w))
		list.add_child(_row(lines[i], plans[i], row_w, not scrolls))
	var list_area_h := height - PANEL_TOP - PANEL_BOTTOM
	var inner_w := cw - PANEL_SIDE * 2.0
	var gutter := GUTTER if scrolls else 0.0
	if scrolls:
		list.custom_minimum_size.x = row_w - gutter
	var holder := MarginContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	holder.add_theme_constant_override("margin_top", int(LIST_PAD))
	holder.add_theme_constant_override("margin_bottom", int(LIST_PAD))
	holder.add_theme_constant_override("margin_left", int(LIST_PAD))
	holder.add_theme_constant_override("margin_right", int(LIST_PAD))
	holder.add_child(list)
	if scrolls:
		var area := SellUi.scrolled(holder, inner_w, list_area_h, true, {"scroll": 0}, "WelcomeScroll", "WelcomeBar", GUTTER)
		panel.add_child(area)
		SellUi.place(area, 0.0, PANEL_SIDE, 0.0, PANEL_SIDE + inner_w, 0.0, PANEL_TOP, 0.0, PANEL_TOP + list_area_h)
	else:
		panel.add_child(holder)
		SellUi.place(holder, 0.0, PANEL_SIDE, 1.0, -PANEL_SIDE, 0.0, PANEL_TOP, 0.0, PANEL_TOP + list_h + LIST_PAD * 2.0)
	return panel


## Uma linha: pratinho com o ícone do tipo, título (até 3 linhas) + ícones pequenos embaixo e o botão Ir à direita.
## Tocar na linha também vai (só quando a lista não rola, para o arrasto não disparar o Ir).
func _row(line: Dictionary, plan: Dictionary, width: float, tap_row: bool) -> Control:
	var holder := Control.new()
	holder.name = str(line.name)
	holder.custom_minimum_size = Vector2(width, float(plan.height))
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	var go: Callable = line.go
	if tap_row:
		holder.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				go.call())
	var box := UiKit.hbox(int(ROW_GAP))
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	holder.add_child(box)
	StepCardUi.stretch(box)
	box.offset_left = ROW_PAD_X
	box.offset_right = -ROW_PAD_X
	box.offset_top = ROW_PAD_Y
	box.offset_bottom = -ROW_PAD_Y
	box.add_child(_plate(ROW_PLATE, line.get("texture"), "RowPlate", 32.0))
	var body := UiKit.vbox(3)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	body.add_child(HelpUi._label(str(line.title), TITLE_PX, plan.title_m, float(plan.body_w), "RowName"))
	var icons: Array = line.get("icons", [])
	if not icons.is_empty():
		var flow := UiKit.flow(int(ICON_GAP))
		flow.name = "RowIcons"
		flow.mouse_filter = Control.MOUSE_FILTER_PASS
		flow.custom_minimum_size.x = float(plan.body_w)
		flow.add_theme_constant_override("v_separation", int(ICON_GAP))
		for texture: Texture2D in icons:
			var icon := UiKit.icon(texture, int(ICON_PX))
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if texture.get_width() <= 32 else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			flow.add_child(icon)
		body.add_child(flow)
	box.add_child(body)
	var button := _button("Ir", false, GO_W, "LineGo", go)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	box.add_child(button)
	return holder


# --- Entrada, saída e posição ---------------------------------------------------------------

func present() -> void:
	layout.call_deferred()
	if not Motion.reduced and _animate:
		_animate_open.call_deferred()


func close() -> void:
	if _tween:
		_tween.kill()
	if _on_close.is_valid():
		_on_close.call()
	elif is_instance_valid(host) and host is CanvasLayer:
		(host as CanvasLayer).hide()


## Folha centrada, encostada na base da tela.
func layout() -> void:
	if not is_instance_valid(frame) or not is_inside_tree():
		return
	var area := get_viewport().get_visible_rect().size
	_rest_y = area.y - frame.size.y - TAIL
	if _tween == null or not _tween.is_running():
		frame.position = Vector2((area.x - frame.size.x) / 2.0, _rest_y)


func _animate_open() -> void:
	if not is_instance_valid(frame) or not is_inside_tree():
		return
	layout()
	if _tween:
		_tween.kill()
	frame.position.y = get_viewport().get_visible_rect().size.y
	_tween = create_tween()
	_tween.tween_property(frame, "position:y", _rest_y, Motion.SHEET_IN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		close()
