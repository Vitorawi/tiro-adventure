class_name ItemUi
extends RefCounted
## Detalhe do item (aberto pela Mochila) no visual "madeira ilustrada": moldura com a placa do nome, um cartão creme
## COMPACTO em cima (ícone pequeno num pratinho, pílula "Quantidade: N", uma linha de uso, chips e a fileira de ações) e,
## embaixo, dois painéis de madeira lado a lado — "Origem" e "Usado em" — com os itens em pratinhos redondos. Cada painel
## rola por dentro quando a lista é longa; a folha nunca passa da área entre o HUD e a base da tela. As imagens `item_*.png`
## vêm de `tools/item_art.gd` (~3x: os NinePatch usam escala 1/3, então moram sempre num Control comum).
## Só monta; as regras ficam no `GameState`. Nós preservados: `ItemHero`, `ItemActions`, `GiveGrowth_<id>`, `GiveFood_<id>`,
## `GiveToy_<id>`, `KeepsakeGo`, `SellItem`, `DepotRow`, `LockHint`; novos: `ItemSources`/`ItemUses`, `Source_<i>`/`Use_<i>`.

const FRAME_MARGINS := Vector4i(380, 310, 382, 252)  # esq, topo, dir, base (px guardados, 3x)
const SIDE := 2.0
const IN_L := 24.5             # borda da moldura até o miolo de madeira clara (px de exibição)
const IN_R := 22.0
const TOP := 100.0             # topo da moldura até o cartão (abaixo da placa)
const BOTTOM := 46.0           # fim dos painéis até a base da moldura (as flores ficam abaixo)
const GAP := 8.0               # folga entre o cartão e os painéis, e entre os dois painéis
const TAIL := 6.0
const PLAQUE_X := 85.0         # texto da placa: folga até a moldura de cada lado (centrado)
const PLAQUE_Y := 38.0
const PLAQUE_BASE := 82.0
const CLOSE_BOX := Vector4(-46.0, 48.0, -2.0, 92.0)
# Cartão
const CARD_PAD_X := 16.0
const CARD_PAD_Y := 14.0
const PLATE := 76.0
const HERO_ICON := 64.0
const PILL_H := 29.0
const ACTION_H := 44.0
const ROW_GAP := 8.0
# Painéis
const PANEL_TOP := 47.5        # topo do painel até o creme (cabeçalho com o título)
const PANEL_BOTTOM := 20.4
const PANEL_SIDE := 13.0
const LIST_PAD := 1.0
const CELL_PLATE := 44.0
const NAME_LINE := 13.0
const CELL_GAP := 2.0
const GUTTER := 8.0
const GREEN_OUTLINE := Color("2b5560")


static func tex(file: String) -> Texture2D:
	return load(HomeUi.DIR + "item_" + file + ".png") as Texture2D


static func _font(px: int) -> Font:
	return HomeUi.theme(px).default_font


static func _text_w(text: String, px: int) -> float:
	return _font(px).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x


static func _screen() -> Vector2:
	return (Engine.get_main_loop() as SceneTree).root.get_visible_rect().size


static func panel_width() -> float:
	return minf(_screen().x - SIDE * 2.0, SellUi.MAX_WIDTH)


## Só o que tem nome (um destino sem nome viraria um pratinho vazio).
static func _named(links: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for link in links:
		if str(link.get("name", "")) != "":
			result.append(link)
	return result


## Linhas de um texto quebrado em `width` (no máximo `cap`), na fonte da madeira.
static func _lines(text: String, px: int, width: float, cap: int) -> int:
	if text == "":
		return 0
	var paragraph := TextParagraph.new()
	paragraph.add_string(text, _font(px), px)
	paragraph.width = width
	return clampi(paragraph.get_line_count(), 1, cap)


# --- Entrada -------------------------------------------------------------------------------

static func build(id: String) -> Control:
	var model := {"src": 0, "use": 0}
	var live := SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.name = "ItemBoard"
		box.add_theme_constant_override("separation", 0)
		box.add_child(_frame(id, model, panel_width()))
		var tail := Control.new()
		tail.custom_minimum_size.y = TAIL
		tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(tail))
	live.set_meta("sheet_bare", true)
	live.set_meta("sheet_fit_content", true)
	live.set_meta("tick_refresh", false)  # as listas rolam: nada de refazer a cada segundo
	return live


static func _frame(id: String, model: Dictionary, width: float) -> Control:
	var item: Dictionary = Database.items.get(id, {})
	var cw := width - IN_L - IN_R
	var card_data := _card_plan(id, item, cw)
	var sources := _named(SheetBuilder._sources(id))
	var uses := _named(SheetBuilder._uses(id))
	var avail := _screen().y - float((load("res://scripts/ui/hud.gd") as GDScript).get_script_constant_map()["SHEET_TOP"]) - TAIL
	var has_panels := not sources.is_empty() or not uses.is_empty()
	var panels_h := 0.0
	var plan := {}
	if has_panels:
		var room := avail - (TOP + float(card_data.height) + GAP + BOTTOM)
		plan = _panel_plan(sources, uses, cw, room)
		panels_h = float(plan.height)
	var total := TOP + float(card_data.height) + (GAP + panels_h if has_panels else 0.0) + BOTTOM
	var frame := Control.new()
	frame.name = "ItemFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_PASS
	frame.custom_minimum_size = Vector2(width, total)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.set_meta("est_card_h", float(card_data.height))
	var art := SellUi.nine("frame", FRAME_MARGINS, "Art", null, "item_")
	frame.add_child(art)
	StepCardUi.stretch(art)
	var card := _card(id, item, card_data, cw)
	frame.add_child(card)
	SellUi.place(card, 0.0, IN_L, 1.0, -IN_R, 0.0, TOP, 0.0, TOP + float(card_data.height))
	if has_panels:
		var row := UiKit.hbox(int(GAP))
		row.name = "ItemPanels"
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		frame.add_child(row)
		var top := TOP + float(card_data.height) + GAP
		SellUi.place(row, 0.0, IN_L, 1.0, -IN_R, 0.0, top, 0.0, top + panels_h)
		var pw := float(plan.panel_width)
		if not sources.is_empty():
			row.add_child(_panel("Origem", "ItemSources", "Source_", "SourcesScroll", "SourcesBar", sources, pw, panels_h, plan, model, "src"))
		if not uses.is_empty():
			row.add_child(_panel("Usado em", "ItemUses", "Use_", "UsesScroll", "UsesBar", uses, pw, panels_h, plan, model, "use"))
	var overlay := _overlay(width, Database.item_name(id))
	frame.add_child(overlay)
	StepCardUi.stretch(overlay)
	return frame


# --- Placa e fechar --------------------------------------------------------------------------

static func _overlay(width: float, title: String) -> Control:
	var layer := Control.new()
	layer.name = "Overlay"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var avail := width - PLAQUE_X * 2.0
	var px := 22
	for candidate in [22, 20, 18, 16, 14]:
		px = candidate
		if _text_w(title, candidate) <= avail:
			break
	var plaque := MissionUi.text(title, px, Palette.WOOD_CREAM, 3)
	plaque.name = "ItemTitle"
	plaque.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plaque.clip_text = true
	plaque.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	layer.add_child(plaque)
	SellUi.place(plaque, 0.0, PLAQUE_X, 1.0, -PLAQUE_X, 0.0, PLAQUE_Y, 0.0, PLAQUE_BASE)
	var close := BagUi.plain_button(func() -> void: Events.sheet_close_requested.emit())
	close.name = "CloseButton"
	close.custom_minimum_size = Vector2(44, 44)
	var picture := SellUi.soft(TextureRect.new())
	picture.texture = MissionUi.tex("close")
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	close.add_child(picture)
	picture.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	picture.offset_left = -19.0
	picture.offset_right = 19.0
	picture.offset_top = -19.0
	picture.offset_bottom = 19.0
	close.pressed.connect(func() -> void: Motion.bounce(picture))
	layer.add_child(close)
	SellUi.place(close, 1.0, CLOSE_BOX.x, 1.0, CLOSE_BOX.z, 0.0, CLOSE_BOX.y, 0.0, CLOSE_BOX.w)
	return layer


# --- Cartão ----------------------------------------------------------------------------------

## Ações possíveis, na ordem de prioridade (a primeira vira o botão verde-água; "Vender" é sempre o amarelo).
static func _actions(id: String, item: Dictionary, amount: int, price: int) -> Dictionary:
	var actions: Array[Dictionary] = []
	var lock := ""
	var growth_delivery := false
	for req: Dictionary in GameState.growth_info().requirements:
		if req.type == "deliver" and str(req.item) == id and not req.done:
			growth_delivery = true
	if growth_delivery and amount > 0:
		actions.append({"name": "GiveGrowth_" + id, "text": "Dar", "fn": GrowthUi._deliver.bind(id)})
	elif item.has("feed") and amount > 0:
		actions.append({"name": "GiveFood_" + id, "text": "Dar ao Tiro", "fn": func() -> void:
			var error := SheetBuilder.give_food(id)
			if error != "":
				Events.toast_requested.emit(error)})
	if bool(item.get("toy", false)) and amount > 0:
		if GameState.give_toy_error(id) == "":
			actions.append({"name": "GiveToy_" + id, "text": "Dar ao Tiro", "fn": func() -> void:
				var reason := GameState.give_toy(id)
				if reason == "":
					Events.sheet_close_requested.emit()
				Events.toast_requested.emit(reason if reason != "" else "Foi para o cesto de brinquedos")})
		elif not GameState.house_has("toy_basket"):
			lock = "Chega com o cesto de brinquedos"
	if str(item.get("category", "")) == "keepsake":
		actions.append({"name": "KeepsakeGo", "text": "Ir", "fn": GrowthUi.open})
	if price > 0 and amount > 0:
		var place := Database.place_with_panel("sell")
		if place[0] != "" and Places.world_error(place[0]) == "":
			actions.append({"name": "SellItem", "text": "Vender", "gold": true, "fn": Places.go.bind({"world": place[0], "place": "market:sell"})})
	return {"list": actions, "lock": lock}


## Chips (vende por, efeitos da comida, depósito) e quantas linhas eles ocupam no fluxo.
static func _chips(id: String, item: Dictionary, price: int) -> Dictionary:
	var chips: Array[Control] = []
	var widths: Array[float] = []
	if price > 0:
		var text := "Vende por %d" % price
		chips.append(StepCardUi.wood_chip(UiKit.ui_icon("coin"), text, "", Callable(), "PriceChip"))
		widths.append(51.0 + _text_w(text, 15))
	if item.has("feed"):
		for need_id: String in item.feed:
			var amount := int(item.feed[need_id])
			var text := "%+d" % amount
			chips.append(StepCardUi.wood_chip(Database.need_icon(need_id), text, "have" if amount > 0 else "missing"))
			widths.append(51.0 + _text_w(text, 15))
	var depot := _depot_chip(id)
	if depot.control != null:
		chips.append(depot.control)
		widths.append(51.0 + _text_w(str(depot.text), 15))
	return {"chips": chips, "widths": widths}


## Onde o item fica guardado, em chip: "Geladeira 4/24" (só com o limite ligado). Nó `DepotRow`; com lugar no mundo,
## tocar leva até o depósito. Cheio = texto vermelho.
static func _depot_chip(id: String) -> Dictionary:
	var depot := GameState.storage_of(id)
	if depot == "" or not GameState.storage_active(depot):
		return {"control": null, "text": ""}
	var data: Dictionary = Database.progression.storage[depot]
	var building: Dictionary = Database.progression.upgrades.get(str(data.get("building", "")), {})
	var used := GameState.storage_used(depot)
	var capacity := GameState.storage_capacity(depot)
	var text := "%s %d/%d" % [GameState.storage_name(depot), used, capacity]
	var icon := UiKit.ui_icon(str(building.get("icon", "station_" + depot)))
	var tone := "missing" if used >= capacity else ""
	var go := Callable()
	if str(data.get("place", "")) != "" and Places.world_error(str(data.get("world", "house"))) == "":
		go = Places.go.bind({"world": str(data.get("world", "house")), "place": str(data.place)})
	return {"control": StepCardUi.wood_chip(icon, text, tone, go, "DepotRow"), "text": text}


## Altura do cartão a partir do que ele mostra (nada medido depois: a moldura e os painéis dependem disto).
static func _card_plan(id: String, item: Dictionary, cw: float) -> Dictionary:
	var amount := GameState.inventory.count(id)
	var price := int(item.get("sell_price", 0))
	var inner_w := cw - CARD_PAD_X * 2.0
	var text_w := inner_w - PLATE - 10.0
	var note := str(item.get("note", ""))
	var note_lines := _lines(note, 13, text_w, 3)
	var line_h := ceilf(_font(13).get_height(13))
	var chips := _chips(id, item, price)
	var widths: Array[float] = []
	widths.assign(chips.widths)
	var rows := 0
	var used := 0.0
	for w in widths:
		if rows == 0 or used + 6.0 + w > inner_w:
			rows += 1
			used = w
		else:
			used += 6.0 + w
	var actions := _actions(id, item, amount, price)
	var words_h := PILL_H + 3.0 + note_lines * line_h if note_lines > 0 else PILL_H
	var height := CARD_PAD_Y * 2.0 + maxf(PLATE, words_h)
	var chips_h := rows * 32.0 + maxf(0.0, rows - 1.0) * 4.0
	if rows > 0:
		height += ROW_GAP + chips_h
	if str(actions.lock) != "":
		height += ROW_GAP + 44.0
	if not (actions.list as Array).is_empty():
		height += ROW_GAP + ACTION_H
	return {"height": height, "words_h": maxf(PLATE, words_h), "note_lines": note_lines, "line_h": line_h, "chips": chips, "actions": actions, "amount": amount, "price": price, "text_w": text_w, "inner_w": inner_w}


static func _card(id: String, item: Dictionary, plan: Dictionary, cw: float) -> Control:
	var card := Control.new()
	card.name = "ItemCard"
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var art := SellUi.nine("card", Vector4i(75, 75, 75, 75), "Art", null, "item_")
	card.add_child(art)
	StepCardUi.stretch(art)
	var body := UiKit.vbox(int(ROW_GAP))
	body.name = "Body"
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(body)
	StepCardUi.stretch(body)
	body.offset_left = CARD_PAD_X
	body.offset_right = -CARD_PAD_X
	body.offset_top = CARD_PAD_Y
	body.offset_bottom = -CARD_PAD_Y
	# Linha do topo: pratinho com o ícone e, ao lado, a pílula de quantidade + a linha de uso.
	var top := UiKit.hbox(10)
	top.custom_minimum_size.y = maxf(PLATE, float(plan.words_h))
	body.add_child(top)
	top.add_child(_hero(id))
	var words := UiKit.vbox(3)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var amount := int(plan.amount)
	words.add_child(_pill("Quantidade: %d" % amount if amount > 0 else "Você não tem"))
	var note := str(item.get("note", ""))
	if note != "":
		var line := StationWood.text(note, 13)
		line.name = "ItemNote"
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.max_lines_visible = int(plan.note_lines)
		line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		line.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		line.custom_minimum_size = Vector2(float(plan.text_w), int(plan.note_lines) * float(plan.line_h))
		words.add_child(line)
	top.add_child(words)
	var chips: Array[Control] = []
	chips.assign(plan.chips.chips)
	if not chips.is_empty():
		var flow := UiKit.flow(6)
		flow.name = "ItemChips"
		flow.alignment = FlowContainer.ALIGNMENT_CENTER
		flow.add_theme_constant_override("v_separation", 4)
		for chip in chips:
			flow.add_child(chip)
		body.add_child(flow)
	var lock := str(plan.actions.lock)
	if lock != "":
		var hint := StepCardUi.lock_note(lock)
		body.add_child(hint)
	var actions: Array[Dictionary] = []
	actions.assign(plan.actions.list)
	if not actions.is_empty():
		body.add_child(_action_row(actions, float(plan.inner_w)))
	return card


## Pratinho com o ícone (pixel em escala inteira e nítido; ilustração reduzida e suave). Nó `ItemHero`.
static func _hero(id: String) -> Control:
	var hero := Control.new()
	hero.name = "ItemHero"
	hero.custom_minimum_size = Vector2(PLATE, PLATE)
	hero.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plate := SellUi.soft(TextureRect.new())
	plate.texture = tex("plate")
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode = TextureRect.STRETCH_SCALE
	hero.add_child(plate)
	StepCardUi.stretch(plate)
	var food := StationWood.food_texture(id)
	var source: Texture2D = food if food != null else Database.item_icon(id)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = source
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var px := HERO_ICON
	if source != null and source.get_width() <= 32:
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # 32 -> 64: dobro exato
	else:
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		px = 58.0
	hero.add_child(icon)
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.offset_left = -px / 2.0
	icon.offset_right = px / 2.0
	icon.offset_top = -px / 2.0
	icon.offset_bottom = px / 2.0
	return hero


## Pílula creme vazia (NinePatch) com o texto por cima; a largura segue o texto.
static func _pill(text: String) -> Control:
	var pill := Control.new()
	pill.name = "QuantityPill"
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	pill.custom_minimum_size = Vector2(maxf(_text_w(text, 15) + 28.0, 80.0), PILL_H)
	var art := SellUi.nine("pill", Vector4i(32, 43, 28, 43), "Art", null, "item_")
	pill.add_child(art)
	StepCardUi.stretch(art)
	var label := StationWood.text(text, 15)
	label.name = "QuantityText"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_child(label)
	StepCardUi.stretch(label)
	return pill


## Fileira de ações: todos os botões do mesmo tamanho, centralizados (um só = largura de metade).
static func _action_row(actions: Array[Dictionary], inner_w: float) -> Control:
	var row := UiKit.hbox(8)
	row.name = "ItemActions"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var count := actions.size()
	var each := floorf((inner_w - 8.0) / 2.0) if count <= 2 else floorf((inner_w - 8.0 * (count - 1)) / count)
	for entry in actions:
		var button := _action_button(str(entry.text), bool(entry.get("gold", false)), each, entry.fn)
		button.name = str(entry.name)
		row.add_child(button)
	return row


static func _action_button(caption: String, gold: bool, width: float, on_pressed: Callable) -> Button:
	var button := BagUi.plain_button(on_pressed)
	button.custom_minimum_size = Vector2(width, ACTION_H)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if not gold: button.set_meta("wood_primary", true)  # o verde-água é a ação principal da tela
	var art := SellUi.nine("btn_gold" if gold else "btn_green", Vector4i(66, 66, 66, 66), "Art", null, "item_")
	art.show_behind_parent = true
	button.add_child(art)
	StepCardUi.stretch(art)
	var px := 18
	for candidate in [18, 16, 14, 12]:
		px = candidate
		if _text_w(caption, candidate) <= width - 24.0:
			break
	var label := Label.new()
	label.name = "Caption"
	label.text = caption
	label.theme = HomeUi.theme(px, Palette.WOOD_CREAM, Palette.WOOD_INK if gold else GREEN_OUTLINE, 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	StepCardUi.stretch(label)
	label.offset_bottom = -3.0  # o desenho do botão tem uma sombra embaixo: o texto fica no miolo
	button.pressed.connect(func() -> void: Motion.bounce(button))
	return button


# --- Painéis ---------------------------------------------------------------------------------

## Medidas dos painéis: colunas, largura e altura (a mesma nos dois), e se a barra de rolagem é reservada.
static func _panel_plan(sources: Array[Dictionary], uses: Array[Dictionary], cw: float, room: float) -> Dictionary:
	var both := not sources.is_empty() and not uses.is_empty()
	var cols := 2 if both else 4
	var pw := (cw - GAP) / 2.0 if both else cw
	var rows := maxi(ceili(sources.size() / float(cols)), ceili(uses.size() / float(cols)))
	# Linhas de nome (1 ou 2) pela célula mais estreita (com a barra): a altura da célula acompanha o texto.
	var narrow := floorf((pw - PANEL_SIDE * 2.0 - GUTTER - LIST_PAD * 2.0 - CELL_GAP * (cols - 1)) / cols)
	var lines := 1
	for link in sources + uses:
		lines = maxi(lines, _lines(str(link.name), 10, narrow, 2))
	var cell_h := CELL_PLATE + 2.0 + lines * NAME_LINE
	var full := PANEL_TOP + LIST_PAD * 2.0 + rows * cell_h + (rows - 1) * CELL_GAP + PANEL_BOTTOM
	var min_rows := 1.0 if rows <= 1 else 1.5
	var minimum := PANEL_TOP + LIST_PAD * 2.0 + min_rows * cell_h + (min_rows - 1.0) * CELL_GAP + PANEL_BOTTOM
	var height := clampf(full, minimum, maxf(minimum, room))
	return {"cols": cols, "panel_width": pw, "height": height, "scrolls": full > height + 0.5, "cell_h": cell_h, "name_h": lines * NAME_LINE}


static func _panel(title: String, node_name: String, prefix: String, scroll_name: String, bar_name: String, links: Array[Dictionary], width: float, height: float, plan: Dictionary, model: Dictionary, key: String) -> Control:
	var panel := Control.new()
	panel.name = node_name
	panel.custom_minimum_size = Vector2(width, height)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var art := SellUi.nine("panel", Vector4i(69, 150, 69, 88), "Art", null, "item_")
	panel.add_child(art)
	StepCardUi.stretch(art)
	var heading := MissionUi.text(title, 17, Palette.WOOD_CREAM, 3)
	heading.name = "PanelTitle"
	heading.clip_text = true
	panel.add_child(heading)
	SellUi.place(heading, 0.0, PANEL_SIDE, 1.0, -PANEL_SIDE, 0.0, 8.0, 0.0, 42.0)
	var scrolls := bool(plan.scrolls)
	var list_w := width - PANEL_SIDE * 2.0
	var list_h := height - PANEL_TOP - PANEL_BOTTOM
	var gutter := GUTTER if scrolls else 0.0
	var cols := int(plan.cols)
	var cell_w := floorf((list_w - gutter - LIST_PAD * 2.0 - CELL_GAP * (cols - 1)) / cols)
	var flow := UiKit.flow(int(CELL_GAP))
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.custom_minimum_size.x = list_w - gutter
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.mouse_filter = Control.MOUSE_FILTER_PASS
	for i in links.size():
		var cell := _cell(links[i], cell_w, float(plan.cell_h), float(plan.name_h))
		cell.name = prefix + str(i)
		flow.add_child(cell)
	var holder := MarginContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	holder.add_theme_constant_override("margin_top", int(LIST_PAD))
	holder.add_theme_constant_override("margin_bottom", int(LIST_PAD))
	holder.add_child(flow)
	var area := SellUi.scrolled(holder, list_w, list_h, scrolls, model.get_or_add(key + "_state", {"scroll": 0}), scroll_name, bar_name, GUTTER)
	panel.add_child(area)
	SellUi.place(area, 0.0, PANEL_SIDE, 0.0, PANEL_SIDE + list_w, 0.0, PANEL_TOP, 0.0, PANEL_TOP + list_h)
	return panel


## Pratinho com o ícone do lugar/receita e o nome curto embaixo; tocar leva até lá. Mundo fechado = apagado.
static func _cell(link: Dictionary, cell_w: float, cell_h: float, name_h: float) -> Button:
	var target: Dictionary = link.target
	var cell := BagUi.plain_button(Places.go.bind(target))
	cell.custom_minimum_size = Vector2(cell_w, cell_h)
	cell.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var plate := SellUi.soft(TextureRect.new())
	plate.name = "Plate"
	plate.texture = tex("plate")
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode = TextureRect.STRETCH_SCALE
	cell.add_child(plate)
	SellUi.place(plate, 0.5, -CELL_PLATE / 2.0, 0.5, CELL_PLATE / 2.0, 0.0, 0.0, 0.0, CELL_PLATE)
	var icon_texture: Texture2D = link.get("icon")
	if icon_texture != null:
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.texture = icon_texture
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var px := 32.0
		if icon_texture.get_width() <= 32:
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		else:
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			px = 34.0
		cell.add_child(icon)
		SellUi.place(icon, 0.5, -px / 2.0, 0.5, px / 2.0, 0.0, (CELL_PLATE - px) / 2.0, 0.0, (CELL_PLATE + px) / 2.0)
	var name_label := StationWood.text(str(link.name), 10)
	name_label.name = "Name"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = int(name_h / NAME_LINE)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cell.add_child(name_label)
	SellUi.place(name_label, 0.0, 0.0, 1.0, 0.0, 0.0, CELL_PLATE + 2.0, 0.0, CELL_PLATE + 2.0 + name_h)
	if target.has("world") and Places.world_error(str(target.world)) != "":
		cell.modulate.a = 0.55
	cell.pressed.connect(func() -> void: Motion.bounce(plate))
	return cell
