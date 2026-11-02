class_name SellUi
extends RefCounted
## Tela de venda (Sítio e Vila) no visual "madeira ilustrada": moldura entalhada com a placa do lugar no topo, grade de
## cartões creme (2 colunas, só ela rola, barra fina à direita) e, separada embaixo, a tábua do vendedor com retrato,
## seletor de quantidade, total e o botão verde. As imagens `sell_*.png` vêm de `tools/sell_art.gd` (~3x o tamanho
## final: os NinePatch usam escala 1/3, então moram sempre num Control comum). Só monta; as regras ficam no `GameState`.
## Nós preservados: `SellBoard`, `SellGrid`, `Sell_<id>` (meta `selected`), `SellSelected`, `QuantityMax`.

const FRAME_MARGINS := Vector4i(340, 353, 329, 198)  # esq, topo, dir, base do NinePatch da moldura (px guardados, 3x)
const FRAME_NATURAL := 304.0   # largura da moldura sem esticar (913 / 3)
const MAX_WIDTH := 372.0       # em telas largas a moldura fica centrada neste tamanho
const SIDE := 2.0              # folga da moldura até a borda da tela
const IN_L := 28.0             # madeira da esquerda até o creme (px exibidos)
const IN_R := 26.0
const IN_T := 50.0             # topo da moldura até o creme (abaixo da placa)
const IN_B := 18.0
const PAD := 6.0               # folga entre o creme e os cartões
const GUTTER := 12.0           # coluna da barra de rolagem
const GAP := 6.0
const CARD_H := 76.0
const SLOT_PX := 42.0          # espaço do ícone no cartão
const BOARD_INSET := 16.0      # a tábua alinha com a madeira visível da moldura
const BOARD_PAD := Vector2(18.0, 8.0)
const GOLD := Color("e8a33a")
const MAX_ROWS := 5
const MIN_ROWS := 3          # a moldura nunca fica mais baixa que isso (o miolo do NinePatch só encolhe um pouco)
const MIN_SCROLL := 110.0


static func tex(file: String) -> Texture2D:
	return load(HomeUi.DIR + "sell_" + file + ".png") as Texture2D


static func panel_width() -> float:
	var screen := (Engine.get_main_loop() as SceneTree).root.get_visible_rect().size
	return minf(screen.x - SIDE * 2.0, MAX_WIDTH)


## Quem compra: o personagem cujo `services` tem o lugar de venda do mundo (Sítio: vovó Bloblo; Vila: Feirante).
static func seller(world_id: String) -> Dictionary:
	var place_id := ""
	var title := "Vender"
	var places: Dictionary = Database.worlds.get(world_id, {}).get("places", {})
	for id: String in places:
		if str(places[id].get("panel", "")) == "sell":
			place_id = id
			title = str(places[id].get("name", title))
			break
	var npc_id := ""
	for id: String in Database.npcs:
		if place_id != "" and place_id in Database.npcs[id].get("services", []):
			npc_id = id
			break
	var portrait := str(Database.npcs.get(npc_id, {}).get("portrait", ""))
	return {"place": place_id, "title": title, "npc": npc_id, "portrait": portrait}


## NinePatch (escala 1/3) que acompanha o tamanho do host; mora num Control comum.
static func nine(file: String, margins: Vector4i, node_name: String = "Art", host: Control = null, prefix: String = "sell_") -> Control:
	var art := host if host != null else Control.new()
	art.name = node_name
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var patch := NinePatchRect.new()
	patch.name = "Frame"
	patch.texture = load(HomeUi.DIR + prefix + file + ".png") as Texture2D
	patch.patch_margin_left = margins.x
	patch.patch_margin_top = margins.y
	patch.patch_margin_right = margins.z
	patch.patch_margin_bottom = margins.w
	patch.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patch.scale = Vector2.ONE / 3.0
	art.add_child(patch)
	art.resized.connect(func() -> void: patch.size = art.size * 3.0)
	return art


static func soft(rect: TextureRect) -> TextureRect:
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


# --- Tela ----------------------------------------------------------------------------------

static func build(world_id: String) -> Control:
	var model := {"selected": "", "quantity": 1, "scroll": 0}
	var who := seller(world_id)
	var live := SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.name = "SellBoard"
		box.add_theme_constant_override("separation", 6)
		var ids: Array[String] = []
		for id: String in Database.items:
			if int(Database.items[id].get("sell_price", 0)) > 0 and GameState.inventory.count(id) > 0:
				ids.append(id)
		if not str(model.selected) in ids:
			model.selected = ids[0] if not ids.is_empty() else ""
			model.quantity = 1
		var width := panel_width()
		var refresh := func() -> void: (box as SheetBuilder.LiveBox).refresh()
		box.add_child(_frame(ids, model, refresh, width, str(who.title)))
		if str(model.selected) != "":
			box.add_child(_board(who, model, refresh, width, world_id))
		var tail := Control.new()
		tail.custom_minimum_size.y = 6.0
		tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(tail))
	live.set_meta("sheet_bare", true)
	live.set_meta("sheet_fit_content", true)
	live.set_meta("tick_refresh", false)  # a grade rola: nada de refazer a cada segundo
	return live


## Quantas linhas de cartões cabem sem passar do HUD: o resto rola.
static func _visible_rows(rows: int) -> int:
	var screen_h := (Engine.get_main_loop() as SceneTree).root.get_visible_rect().size.y
	var chrome := 128.0 + IN_T + IN_B + PAD * 2.0 + 150.0  # HUD + moldura + tábua com folga
	var fit := int(floor((screen_h - chrome + GAP) / (CARD_H + GAP)))
	return clampi(mini(rows, MAX_ROWS), MIN_ROWS, maxi(MIN_ROWS, fit))


static func _frame(ids: Array[String], model: Dictionary, refresh: Callable, width: float, title: String) -> Control:
	var frame := PanelContainer.new()
	frame.name = "SellFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_PASS
	frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	frame.custom_minimum_size.x = width
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.add_child(nine("frame", FRAME_MARGINS))
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left", int(IN_L + PAD))
	margin.add_theme_constant_override("margin_right", int(IN_R + PAD))
	margin.add_theme_constant_override("margin_top", int(IN_T + PAD - 2.0))
	margin.add_theme_constant_override("margin_bottom", int(IN_B + PAD))
	frame.add_child(margin)
	var inner_w := width - (IN_L + PAD) - (IN_R + PAD)
	if ids.is_empty():
		var empty := StationWood.text("Colha para ter produtos para vender.", 17)
		empty.name = "SellEmpty"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size = Vector2(inner_w, MIN_ROWS * CARD_H + (MIN_ROWS - 1) * GAP)
		margin.add_child(empty)
	else:
		margin.add_child(_grid_area(ids, model, refresh, inner_w))
	frame.add_child(overlay(width, title))
	return frame


## Placa do lugar (texto sobre a placa creme do topo) e o X de madeira no canto de cima. `plaque` e `close` são
## (esquerda, topo, direita, base) em px da moldura; direita/base negativas contam da borda direita (a base do X é o topo + 44).
static func overlay(width: float, title: String, plaque_box: Vector4 = Vector4(84.0, 8.0, 84.0, 38.0), close_box: Vector4 = Vector4(-46.0, -2.0, -2.0, 42.0)) -> Control:
	var layer := Control.new()
	layer.name = "Overlay"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plaque := StationWood.text(title, 22)
	plaque.name = "SellTitle"
	plaque.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plaque.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plaque.clip_text = true
	plaque.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	layer.add_child(plaque)
	place(plaque, 0.0, plaque_box.x, 1.0, -plaque_box.z, 0.0, plaque_box.y, 0.0, plaque_box.w)
	var close := BagUi.plain_button(func() -> void: Events.sheet_close_requested.emit())
	close.name = "CloseButton"
	close.custom_minimum_size = Vector2(44, 44)
	var art := soft(TextureRect.new())
	art.texture = MissionUi.tex("close")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	close.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	art.offset_left = -19.0
	art.offset_right = 19.0
	art.offset_top = -19.0
	art.offset_bottom = 19.0
	close.pressed.connect(func() -> void: Motion.bounce(art))
	layer.add_child(close)
	place(close, 1.0, close_box.x, 1.0, close_box.z, 0.0, close_box.y, 0.0, close_box.w)
	return layer


## Grade que rola + barra fina de madeira na coluna da direita (a barra do ScrollContainer fica escondida e esta a segue).
static func _grid_area(ids: Array[String], model: Dictionary, refresh: Callable, inner_w: float) -> Control:
	var rows := ceili(ids.size() / 2.0)
	var shown := _visible_rows(rows)
	var needs_bar := rows > shown
	var bar_w := GUTTER if needs_bar else 0.0
	var area_w := inner_w - bar_w
	var card_w := floorf((area_w - GAP) / 2.0)
	var grid := GridContainer.new()
	grid.name = "SellGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", int(GAP))
	grid.add_theme_constant_override("v_separation", int(GAP))
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.custom_minimum_size.x = card_w * 2.0 + GAP
	for id in ids:
		var card := _card(id, id == str(model.selected), card_w, func() -> void:
			model.selected = id
			model.quantity = 1
			refresh.call())
		card.name = "Sell_" + id
		grid.add_child(card)
	var holder := VBoxContainer.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	holder.add_child(grid)
	return scrolled(holder, inner_w, shown * CARD_H + (shown - 1) * GAP, needs_bar, model, "SellScroll", "SellBar")


## Rolagem com a barra fina da madeira numa coluna fixa à direita (`GUTTER`): a largura não muda com o conteúdo. `model.scroll`
## guarda a posição entre as reconstruções. Compartilhada pela venda e pelas encomendas.
static func scrolled(holder: Control, inner_w: float, height: float, needs_bar: bool, model: Dictionary, scroll_name: String, bar_name: String, gutter_w: float = GUTTER) -> Control:
	var row := UiKit.hbox(0)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var scroll := ScrollContainer.new()
	scroll.name = scroll_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bar_w := gutter_w if needs_bar else 0.0
	scroll.custom_minimum_size = Vector2(inner_w - bar_w, height)
	row.add_child(scroll)
	scroll.add_child(holder)
	# Barra: trilho creme fino e pegador cor de mel, numa coluna fixa.
	var gutter := Control.new()
	gutter.name = "ScrollGutter"
	gutter.custom_minimum_size.x = bar_w
	gutter.visible = needs_bar
	gutter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(gutter)
	var bar := VScrollBar.new()
	bar.name = bar_name
	style_bar(bar)
	gutter.add_child(bar)
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar.offset_left = maxf(0.0, gutter_w - 8.0)
	bar.offset_right = -2.0
	bar.offset_top = 6.0
	bar.offset_bottom = -6.0
	var inner := scroll.get_v_scroll_bar()
	var sync := func() -> void:
		bar.min_value = inner.min_value
		bar.max_value = inner.max_value
		bar.page = inner.page
		bar.set_value_no_signal(inner.value)
		bar.modulate.a = 1.0 if inner.max_value - inner.page > 1.0 else 0.0
	inner.changed.connect(sync)
	inner.value_changed.connect(func(value: float) -> void:
		bar.set_value_no_signal(value)
		model.scroll = int(value))
	bar.value_changed.connect(func(value: float) -> void: scroll.scroll_vertical = int(value))
	var restore := func() -> void:
		var tree := Engine.get_main_loop() as SceneTree
		await tree.process_frame
		await tree.process_frame
		if is_instance_valid(scroll):
			scroll.scroll_vertical = int(model.scroll)
			sync.call()
	restore.call()
	return row


static func style_bar(bar: VScrollBar) -> void:
	# Trilho: linha clarinha de 2 px no meio; pegador: pílula cor de mel com contorno, como na referência.
	var track := StyleBoxLine.new()
	track.vertical = true
	track.color = Color("ecd3ab")
	track.thickness = 2
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("scroll_focus", track)
	for key: String in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var grabber := StyleBoxFlat.new()
		grabber.bg_color = Color("f3cf98") if key == "grabber" else Color("eabd78")
		grabber.border_color = Color("d9a467")
		grabber.set_border_width_all(1)
		grabber.set_corner_radius_all(4)
		bar.add_theme_stylebox_override(key, grabber)
	bar.custom_minimum_size.x = 6.0


# --- Cartão --------------------------------------------------------------------------------

## Cartão do produto: ícone no quadradinho afundado à esquerda; nome, "Preço: N" (com moeda) e "Tem: N" à direita.
static func _card(id: String, selected: bool, card_w: float, choose: Callable) -> Button:
	var result := BagUi.plain_button(choose)
	result.custom_minimum_size = Vector2(card_w, CARD_H)
	result.set_meta("selected", selected)
	var art := nine("card", Vector4i(40, 40, 40, 40), "Art")
	art.show_behind_parent = true
	result.add_child(art)
	StepCardUi.stretch(art)
	if selected:
		(art.get_child(0) as CanvasItem).self_modulate = Color(1.0, 0.86, 0.56)
		var ring := Panel.new()
		ring.name = "Selected"
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		style.border_color = GOLD
		style.set_border_width_all(3)
		style.set_corner_radius_all(14)
		ring.add_theme_stylebox_override("panel", style)
		result.add_child(ring)
		StepCardUi.stretch(ring)
	var body := UiKit.hbox(5)
	body.name = "Visual"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_child(body)
	StepCardUi.stretch(body)
	body.offset_left = 7.0
	body.offset_right = -6.0
	body.offset_top = 2.0
	body.offset_bottom = -3.0
	# Ícone solto no cartão, como na referência: pixel no tamanho original (32 px, nítido).
	var slot := Control.new()
	slot.name = "Picture"
	slot.custom_minimum_size = Vector2(SLOT_PX, SLOT_PX)
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := item_icon(id)
	slot.add_child(icon)
	icon.position = (Vector2(SLOT_PX, SLOT_PX) - icon.size) / 2.0
	body.add_child(slot)
	var text_w := card_w - 7.0 - 6.0 - SLOT_PX - 5.0
	var column := UiKit.vbox(0)
	column.name = "Info"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.custom_minimum_size.x = text_w
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(column)
	var name_label := StationWood.text(Database.item_name(id), 13)
	name_label.name = "Caption"
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(text_w, 0.0)
	name_label.size_flags_horizontal = Control.SIZE_FILL
	_fit_name(name_label, text_w)
	column.add_child(name_label)
	var price_row := UiKit.hbox(2)
	price_row.name = "PriceRow"
	price_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var price := StationWood.text("Preço: %d" % int(Database.items[id].sell_price), 12)
	price.name = "Price"
	price.autowrap_mode = TextServer.AUTOWRAP_OFF
	price_row.add_child(price)
	price_row.add_child(soft(coin(13.0)))
	column.add_child(price_row)
	var have := StationWood.text("Tem: %d" % GameState.inventory.count(id), 12)
	have.name = "Have"
	have.autowrap_mode = TextServer.AUTOWRAP_OFF
	column.add_child(have)
	return result


static func coin(px: float) -> TextureRect:
	var coin := TextureRect.new()
	coin.name = "Coin"
	coin.texture = StepCardUi.tex("coin")
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.custom_minimum_size = Vector2(px, px)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return coin


## Nome em até 2 linhas: começa em 13 e desce até 11 se ainda não couber (palavra inteira numa linha); só então reticências.
static func _fit_name(label: Label, width: float) -> void:
	var font := label.get_theme_font("font")
	for px in [13, 12, 11]:
		var paragraph := TextParagraph.new()
		paragraph.add_string(label.text, font, px)
		paragraph.width = width
		var widest := 0.0
		for word in label.text.split(" "):
			widest = maxf(widest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x)
		label.theme = HomeUi.theme(px, Palette.WOOD_INK)
		if paragraph.get_line_count() <= 2 and widest <= width:
			return


## Ícone do produto: pixel de 32 px no tamanho original (nítido); ilustração maior (comida, colheita) reduzida e suave.
static func item_icon(id: String) -> TextureRect:
	var food := StationWood.food_texture(id)
	var source: Texture2D = food if food != null else Database.item_icon(id)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = source
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if source != null and source.get_width() <= 32:
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.size = Vector2(32, 32)
	else:
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		icon.size = Vector2(SLOT_PX - 4.0, SLOT_PX - 4.0)
	icon.custom_minimum_size = icon.size
	return icon


# --- Tábua ---------------------------------------------------------------------------------

static func _board(who: Dictionary, model: Dictionary, refresh: Callable, width: float, world_id: String) -> Control:
	var id := str(model.selected)
	var owned := GameState.inventory.count(id)
	model.quantity = clampi(int(model.quantity), 1, owned)
	var qty := int(model.quantity)
	var unit := int(Database.items[id].sell_price)
	var panel := PanelContainer.new()
	panel.name = "SellPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel.custom_minimum_size.x = width - BOARD_INSET * 2.0
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_child(StationWood.backing("board", 70, 60))
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left", int(BOARD_PAD.x))
	margin.add_theme_constant_override("margin_right", int(BOARD_PAD.x))
	margin.add_theme_constant_override("margin_top", int(BOARD_PAD.y + 6.0))
	margin.add_theme_constant_override("margin_bottom", int(BOARD_PAD.y + 3.0))
	panel.add_child(margin)
	# Título da tábua: creme com contorno, centralizado na tábua inteira.
	var stack := UiKit.vbox(6)
	margin.add_child(stack)
	var summary := MissionUi.text("%d × %s" % [qty, Database.item_name(id)], 15, Palette.WOOD_CREAM, 3)
	summary.name = "SellSummary"
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.clip_text = true
	summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	summary.custom_minimum_size.y = 20.0
	stack.add_child(summary)
	# Retrato centralizado na altura das duas linhas de controles.
	var row := UiKit.hbox(10)
	stack.add_child(row)
	if str(who.portrait) != "" and ResourceLoader.exists(str(who.portrait)):
		var face := MissionUi.portrait(load(str(who.portrait)) as Texture2D, 64.0)
		face.name = "SellerPortrait"
		face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(face)
	var column := UiKit.vbox(6)
	column.name = "SellControls"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	column.add_child(_quantity_row(qty, owned, func(value: int) -> void:
		model.quantity = value
		refresh.call()))
	var last := UiKit.hbox(6)
	last.name = "SellAction"
	var total := qty * unit
	last.add_child(_total_pill(total))
	last.add_child(spacer())
	var action := StepCardUi.go_button("Vender", func() -> void:
		var error := GameState.sell(id, qty, world_id)
		if error != "":
			Events.toast_requested.emit(error)
		else:
			Events.items_gained.emit({}, total, Vector2(-1, -1)))
	action.name = "SellSelected"
	action.custom_minimum_size.x = 104.0
	action.size_flags_horizontal = Control.SIZE_SHRINK_END
	last.add_child(action)
	column.add_child(last)
	return panel


## − [N] + e a pílula Máx: nós `Quantity` (Minus/QuantityValue/Plus) e `QuantityMax`.
static func _quantity_row(value: int, max_value: int, on_change: Callable) -> Control:
	var line := UiKit.hbox(6)
	line.name = "QuantityRow"
	var stepper := UiKit.hbox(0)
	stepper.name = "Quantity"
	var minus := StationWood.icon_button("minus", Vector2(36, 40), func() -> void: on_change.call(clampi(value - 1, 1, max_value)), "Minus")
	minus.disabled = value <= 1
	minus.modulate.a = 0.5 if minus.disabled else 1.0
	stepper.add_child(minus)
	var box := Control.new()
	box.custom_minimum_size = Vector2(44, 44)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var well := StationWood.pic("slot", Vector2(40, 40), "Well", true)
	box.add_child(well)
	well.position = Vector2(2, 2)
	well.size = Vector2(40, 40)
	var amount := StationWood.text(str(value), 19)
	amount.name = "QuantityValue"
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(amount)
	amount.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stepper.add_child(box)
	var plus := StationWood.icon_button("plus", Vector2(36, 40), func() -> void: on_change.call(clampi(value + 1, 1, max_value)), "Plus")
	plus.disabled = value >= max_value
	plus.modulate.a = 0.5 if plus.disabled else 1.0
	stepper.add_child(plus)
	line.add_child(stepper)
	line.add_child(spacer())
	var all :=StationWood.wood_button("Máx", func() -> void: on_change.call(max_value), 15, 52.0)
	all.name = "QuantityMax"
	if value >= max_value:
		all.modulate.a = 0.5
		all.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(all)
	return line


## Empurra o último controle da linha para a borda direita: as linhas da tábua alinham nas duas pontas.
static func spacer() -> Control:
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gap


## Caixinha creme com a moeda desenhada (proporção fixa 509:163) e o total na parte clara.
static func _total_pill(total: int) -> Control:
	var pill := Control.new()
	pill.name = "SellTotal"
	pill.custom_minimum_size = Vector2(104, 44)
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var picture := soft(TextureRect.new())
	picture.texture = tex("total")
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	pill.add_child(picture)
	picture.size = Vector2(104, 104.0 * 100.0 / 312.0)
	picture.position = Vector2(0, (44.0 - picture.size.y) / 2.0)
	var amount := StationWood.text(str(total), 18)
	amount.name = "SellTotalValue"
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount.clip_text = true
	pill.add_child(amount)
	amount.position = Vector2(104.0 * 0.34, picture.position.y)
	amount.size = Vector2(104.0 * 0.62, picture.size.y)
	return pill


## Âncoras e margens de uma vez (esquerda, direita, topo, base): evita o empurrão entre lados do `set_anchor_and_offset`.
static func place(node: Control, left_anchor: float, left: float, right_anchor: float, right: float, top_anchor: float, top: float, bottom_anchor: float, bottom: float) -> void:
	node.anchor_left = left_anchor
	node.anchor_right = right_anchor
	node.anchor_top = top_anchor
	node.anchor_bottom = bottom_anchor
	node.offset_left = left
	node.offset_right = right
	node.offset_top = top
	node.offset_bottom = bottom
