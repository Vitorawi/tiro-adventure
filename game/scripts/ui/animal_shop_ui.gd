class_name AnimalShopUi
extends RefCounted
## Loja de animais (galinheiro e curral) no visual "madeira ilustrada": moldura entalhada com a plaquinha do título e a
## barra de capacidade do abrigo, grade de 2 colunas de cartões creme (animal num disco bege, nome e pílula de preço) e,
## fora da moldura, a tábua com as casinhas e o botão laranja "Ver meus animais". As imagens `animalshop_*.png` vêm de
## `tools/animal_shop_art.gd` (~3x: os NinePatch usam escala 1/3); o cartão é o `sell_card.png`. Só monta; as regras
## ficam no `GameState` (`buy_animal`, `buy_animal_error`).
## Nós preservados: `AnimalGrid`, `AnimalCard_<id>`, `Buy_<id>` (o cartão inteiro é o botão) ou `Locked_Buy_<id>` (meta `reason`).

const FRAME_MARGINS := Vector4i(200, 430, 200, 180)  # esq, topo, dir, base do NinePatch da moldura (px guardados, 3x)
const FRAME_NATURAL := 372.0   # largura da moldura sem esticar (1116 / 3)
const MAX_WIDTH := 372.0
const SIDE := 2.0
const IN_L := 41.0             # madeira da esquerda até o creme
const IN_R := 37.0
const IN_T := 150.0            # topo da moldura até a grade (abaixo da barra de capacidade)
const IN_B := 54.0             # base da moldura até o fim da grade: a última linha fica dentro do papel, antes da dobra
const GAP := 8.0
const CARD_H := 92.0
const DISC := 68.0
const CARD_PAD := 4.0
const NAME_H := 36.0
const PILL_H := 34.0
## Medidas (px de exibição, moldura de 372) lidas por `tools/animal_shop_art.gd`.
const PLAQUE_X := Vector2(83.9, 294.2)
const PLAQUE_Y := Vector2(40.5, 71.6)
const LANE_X := Vector2(49.5, 304.5)
const LANE_Y := Vector2(108.9, 131.8)
const BOARD_INSET := 0.0
const TAB_BAR := 104.0         # barra de abas (104 com a arte): a loja inteira fica acima dela
const BOARD_H := 203.0 / 3.0
const BOARD_MARGINS := Vector4i(312, 80, 312, 80)
const NEST_EDGE := 99.7        # casinha e ninho da esquerda terminam aqui (px da borda esquerda)
const HOUSE_EDGE := 79.1       # a casinha da direita começa aqui (px da borda direita)
const BUTTON_W := 124.0
const SCREW_X := Vector2(102.3, 275.8)  # parafusos da plaquinha: borda direita do esquerdo e borda esquerda do direito
const SCREW_GAP := 6.0
const FIGURE_MARGIN := 2.5   # folga do animal até a borda do disco
const INK := Color("4a2a12")
const PILL_BG := Color("9a6232")
const PILL_EDGE := Color("6e4220")
const LOCK_BG := Color("65321f")
const DISC_BG := Color("f7e3bd")
const DISC_EDGE := Color("e6c58a")
const FILL := Color("f8d98a")
const FILL_EDGE := Color("e0a640")
const BADGE := Color("f3b440")
const MAX_ROWS := 4


static func tex(file: String) -> Texture2D:
	return load(HomeUi.DIR + "animalshop_" + file + ".png") as Texture2D


static func panel_width() -> float:
	var screen := (Engine.get_main_loop() as SceneTree).root.get_visible_rect().size
	return minf(screen.x - SIDE * 2.0, MAX_WIDTH)


## Posição x (px de exibição de uma moldura de 372) na moldura de `width`: as bordas ficam fixas e só o miolo estica.
static func map_x(x: float, width: float) -> float:
	var left := FRAME_MARGINS.x / 3.0
	var right := FRAME_MARGINS.z / 3.0
	if x <= left:
		return x
	if x >= FRAME_NATURAL - right:
		return width - (FRAME_NATURAL - x)
	return left + (x - left) * (width - left - right) / (FRAME_NATURAL - left - right)


static func build(station_id: String) -> Control:
	var model := {"scroll": 0}
	var live := SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.name = "AnimalShop"
		box.add_theme_constant_override("separation", 6)
		var width := panel_width()
		box.add_child(_frame(station_id, model, width))
		box.add_child(_board(station_id, width))
		var tail := Control.new()
		tail.custom_minimum_size.y = TAB_BAR
		tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(tail))
	live.set_meta("sheet_bare", true)
	live.set_meta("sheet_fit_content", true)
	live.set_meta("tick_refresh", false)
	return live


static func animal_ids(station_id: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in Database.animals:
		if str(Database.animals[id].station) == station_id:
			ids.append(id)
	return ids


static func _visible_rows(rows: int) -> int:
	var screen_h := (Engine.get_main_loop() as SceneTree).root.get_visible_rect().size.y
	var chrome := 128.0 + IN_T + IN_B + BOARD_H + 6.0 + TAB_BAR
	var fit := int(floor((screen_h - chrome + GAP) / (CARD_H + GAP)))
	return clampi(mini(rows, MAX_ROWS), 1, maxi(1, fit))


# --- Moldura -------------------------------------------------------------------------------

static func _frame(station_id: String, model: Dictionary, width: float) -> Control:
	var frame := PanelContainer.new()
	frame.name = "AnimalFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_PASS
	frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	frame.custom_minimum_size.x = width
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.add_child(SellUi.nine("frame", FRAME_MARGINS, "Art", null, "animalshop_"))
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left", int(IN_L))
	margin.add_theme_constant_override("margin_right", int(IN_R))
	margin.add_theme_constant_override("margin_top", int(IN_T))
	margin.add_theme_constant_override("margin_bottom", int(IN_B))
	frame.add_child(margin)
	var inner_w := width - IN_L - IN_R
	margin.add_child(_grid_area(station_id, model, inner_w))
	frame.add_child(_overlay(station_id, width))
	return frame


## Plaquinha do título, X de madeira e a barra de capacidade ("Galinheiro · 2/4 animais" sobre a faixa, com preenchimento).
static func _overlay(station_id: String, width: float) -> Control:
	var left := map_x(SCREW_X.x, width) + SCREW_GAP
	var right := map_x(SCREW_X.y, width) - SCREW_GAP
	var layer := SellUi.overlay(width, "Comprar animais", Vector4(left, PLAQUE_Y.x, width - right, PLAQUE_Y.y), Vector4(-54.0, 19.0, -10.0, 63.0))
	var title := layer.find_child("SellTitle", true, false) as Label
	if title:
		title.name = "AnimalTitle"
		# Fonte automática: a maior (até 22) cujo texto cabe entre os parafusos, com folga de SCREW_GAP de cada lado.
		for px in range(22, 13, -1):
			title.theme = HomeUi.theme(px, Palette.WOOD_INK)
			if title.get_theme_font("font").get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x <= right - left:
				break
	var data: Dictionary = Database.stations[station_id]
	var count := GameState.animal_count(station_id)
	var capacity := maxi(1, int(data.animal_capacity))
	var lane_l := LANE_X.x
	var lane_r := map_x(LANE_X.y, width)
	var fill := Panel.new()
	fill.name = "CapacityFill"
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = FILL
	style.border_color = FILL_EDGE
	style.set_border_width_all(1)
	style.set_corner_radius_all(11)
	fill.add_theme_stylebox_override("panel", style)
	fill.visible = count > 0
	layer.add_child(fill)
	var fill_w := (lane_r - lane_l) * clampf(float(count) / capacity, 0.0, 1.0)
	SellUi.place(fill, 0.0, lane_l, 0.0, lane_l + maxf(fill_w, 23.0), 0.0, LANE_Y.x, 0.0, LANE_Y.y)
	var caption := "%s · %d/%d animais" % [data.name, count, capacity]
	if count >= capacity:
		caption = "%s cheio · %d/%d" % [data.name, count, capacity]
	var label := StationWood.text(caption, 14)
	label.name = "CapacityLabel"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	layer.add_child(label)
	SellUi.place(label, 0.0, lane_l + 10.0, 0.0, lane_r - 6.0, 0.0, LANE_Y.x, 0.0, LANE_Y.y)
	return layer


# --- Grade ---------------------------------------------------------------------------------

static func _grid_area(station_id: String, model: Dictionary, inner_w: float) -> Control:
	var ids := animal_ids(station_id)
	var rows := ceili(ids.size() / 2.0)
	var shown := _visible_rows(rows)
	var needs_bar := rows > shown
	var bar_w := SellUi.GUTTER if needs_bar else 0.0
	var card_w := floorf((inner_w - bar_w - GAP) / 2.0)
	var grid := GridContainer.new()
	grid.name = "AnimalGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", int(GAP))
	grid.add_theme_constant_override("v_separation", int(GAP))
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.custom_minimum_size.x = card_w * 2.0 + GAP
	for id in ids:
		grid.add_child(_card(station_id, id, card_w, figure_scale(station_id)))
	if not needs_bar:
		return grid
	var holder := VBoxContainer.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	holder.add_child(grid)
	return SellUi.scrolled(holder, inner_w, shown * CARD_H + (shown - 1) * GAP, true, model, "AnimalScroll", "AnimalBar")


# --- Cartão --------------------------------------------------------------------------------

static func _card(station_id: String, id: String, card_w: float, figure_factor: float) -> Control:
	var animal: Dictionary = Database.animals[id]
	var error := GameState.buy_animal_error(id)
	var card := Control.new()
	card.name = "AnimalCard_" + id
	card.custom_minimum_size = Vector2(card_w, CARD_H)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var art := SellUi.nine("card", Vector4i(40, 40, 40, 40), "Art")
	card.add_child(art)
	StepCardUi.stretch(art)
	if error != "":
		art.modulate = Color(1, 1, 1, 0.7)
	# Disco bege com o animal (pixel art: nearest, escala inteira, centrado).
	var disc := Panel.new()
	disc.name = "Disc"
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var disc_style := StyleBoxFlat.new()
	disc_style.bg_color = DISC_BG
	disc_style.border_color = DISC_EDGE
	disc_style.set_border_width_all(2)
	disc_style.set_corner_radius_all(int(DISC / 2.0))
	disc.add_theme_stylebox_override("panel", disc_style)
	card.add_child(disc)
	disc.position = Vector2(CARD_PAD, (CARD_H - DISC) / 2.0)
	disc.size = Vector2(DISC, DISC)
	disc.add_child(_figure(load(str(animal.sprite)) as Texture2D, error != "", figure_factor))
	var owned := int(GameState.animals.get(id, 0))
	if error != "":
		disc.add_child(_lock_badge())
	if owned > 0:
		disc.add_child(_owned_badge(owned))
	# Coluna da direita: nome (até 2 linhas) e a pílula de preço (ou o motivo do bloqueio), na mesma borda esquerda.
	var column_x := CARD_PAD + DISC + 2.0
	var text_w := card_w - column_x - CARD_PAD
	var top := (CARD_H - NAME_H - 3.0 - PILL_H) / 2.0
	var name_label := StationWood.text(str(animal.name), 13)
	name_label.name = "AnimalName"
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	SellUi._fit_name(name_label, text_w)
	name_label.modulate.a = 0.75 if error != "" else 1.0
	card.add_child(name_label)
	name_label.position = Vector2(column_x, top)
	name_label.size = Vector2(text_w, NAME_H)
	var pill := _lock_pill(animal, error, text_w) if error != "" else _price_pill(int(animal.price), text_w)
	card.add_child(pill)
	pill.position = Vector2(column_x, top + NAME_H + 3.0)
	pill.size = Vector2(text_w, PILL_H)
	# O cartão inteiro é o alvo de toque: compra, ou mostra o que falta.
	if error == "":
		var buy := BagUi.plain_button(func() -> void:
			var reason := GameState.buy_animal(id)
			if reason != "":
				Events.toast_requested.emit(reason)
			else:
				Haptics.success())
		buy.name = "Buy_" + id
		card.add_child(buy)
		StepCardUi.stretch(buy)
	else:
		var help := Control.new()
		help.name = "Locked_Buy_" + id
		help.set_meta("reason", error)
		help.mouse_filter = Control.MOUSE_FILTER_STOP
		help.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_explain(station_id, animal, error))
		card.add_child(help)
		StepCardUi.stretch(help)
	return card


## Falta recolher produtos: abre o "Como fazer" do primeiro; outros motivos viram aviso.
static func _explain(station_id: String, animal: Dictionary, error: String) -> void:
	var produced: Dictionary = animal.get("requirements", {}).get("produced", {})
	for item_id: String in produced:
		if GameState.progress.stat("produce:" + item_id) < int(produced[item_id]):
			TaskHelp.open("item", item_id)
			return
	Events.toast_requested.emit(error)


## Retângulo dos pixels visíveis (alfa > 0) do sprite, em px do próprio sprite.
static func opaque_rect(texture: Texture2D) -> Rect2i:
	return texture.get_image().get_used_rect()


## Posição (centro do retângulo visível) dentro do disco e se todo pixel visível, na escala `factor`, cabe no círculo do disco.
static func _fits(texture: Texture2D, factor: float) -> bool:
	var image := texture.get_image()
	var used := image.get_used_rect()
	var center := Vector2(used.position) + Vector2(used.size) / 2.0
	var radius := DISC / 2.0 - FIGURE_MARGIN
	for y in range(used.position.y, used.end.y):
		for x in range(used.position.x, used.end.x):
			if image.get_pixel(x, y).a < 0.1:
				continue
			# canto mais distante do pixel (cada pixel vira um quadrado de `factor` px)
			var offset := (Vector2(x, y) + Vector2(0.5, 0.5) - center) * factor
			if offset.length() + factor * 0.7072 > radius:
				return false
	return true


## Escala comum a todos os animais do abrigo: o maior fator em que todo animal fica inteiro dentro do círculo do disco
## com folga. Inteiro = nítido (pixel); fracionário = filtro suave.
static func figure_scale(station_id: String) -> float:
	var textures: Array[Texture2D] = []
	for id in animal_ids(station_id):
		textures.append(load(str(Database.animals[id].sprite)) as Texture2D)
	# Inteiros primeiro (nítido); entre eles, passos de 0,1 com filtro suave para o bicho não ficar minúsculo no disco.
	var candidates: Array[float] = [4.0, 3.0, 2.0]
	for step in range(19, 9, -1):
		candidates.append(step * 0.1)
	for step in range(19, 2, -1):
		candidates.append(step * 0.05)
	for factor in candidates:
		var ok := true
		for texture in textures:
			if not _fits(texture, factor):
				ok = false
				break
		if ok:
			return factor
	return 0.15


static func _figure(texture: Texture2D, dim: bool, factor: float) -> Control:
	var picture := TextureRect.new()
	picture.name = "Figure"
	picture.texture = texture
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if is_equal_approx(factor, roundf(factor)) else CanvasItem.TEXTURE_FILTER_LINEAR
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	var used := opaque_rect(texture)
	var center := Vector2(used.position) + Vector2(used.size) / 2.0
	picture.size = Vector2(texture.get_size()) * factor
	# o retângulo visível (não a imagem inteira) fica no centro do disco
	picture.position = (Vector2(DISC, DISC) / 2.0 - center * factor).round()
	picture.modulate.a = 0.75 if dim else 1.0
	return picture


## Peça de tamanho fixo (Panel, sem tamanho mínimo do conteúdo) com um HBox centrado dentro; o conteúdo nunca a estica.
static func _capsule(node_name: String, color: Color, edge: Color, size: Vector2, gap: int) -> Panel:
	var capsule := Panel.new()
	capsule.name = node_name
	capsule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capsule.clip_contents = true
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = edge
	style.set_border_width_all(2)
	style.set_corner_radius_all(int(size.y / 2.0))
	capsule.add_theme_stylebox_override("panel", style)
	capsule.custom_minimum_size = size
	capsule.size = size
	var row := UiKit.hbox(gap)
	row.name = "Row"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capsule.add_child(row)
	StepCardUi.stretch(row)
	row.offset_left = 2.0
	row.offset_right = -2.0
	return capsule


static func _owned_badge(count: int) -> Control:
	var size := Vector2(28.0, 22.0)
	var badge := _capsule("Owned", BADGE, PILL_EDGE, size, 0)
	var label := StationWood.text("×%d" % count, 12)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.custom_minimum_size = Vector2.ZERO
	badge.get_node("Row").add_child(label)
	badge.position = Vector2(DISC - size.x, DISC - size.y)
	return badge


## Cadeado no canto de cima do disco: marca o cartão que ainda não dá para comprar.
static func _lock_badge() -> Control:
	var size := Vector2(22.0, 22.0)
	var badge := _capsule("LockBadge", LOCK_BG, PILL_EDGE, size, 0)
	var lock := TextureRect.new()
	lock.name = "LockIcon"
	lock.texture = load(HomeUi.DIR + "farm_lock.png") as Texture2D
	lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	lock.custom_minimum_size = Vector2(12.0, 12.0)
	lock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.get_node("Row").add_child(lock)
	badge.position = Vector2.ZERO
	return badge


static func _price_pill(price: int, width: float) -> Control:
	var pill := _capsule("PricePill", PILL_BG, PILL_EDGE, Vector2(width, PILL_H), 2)
	var row := pill.get_node("Row")
	row.add_child(SellUi.soft(SellUi.coin(14.0)))
	var amount := MissionUi.text(str(price), 14, Palette.WOOD_CREAM, 3)
	amount.name = "Price"
	amount.autowrap_mode = TextServer.AUTOWRAP_OFF
	amount.custom_minimum_size = Vector2.ZERO
	row.add_child(amount)
	return pill


## Bloqueado: cadeado + o que falta (produto 3/8 em ícone, ou o motivo curto em até 2 linhas).
static func _lock_pill(animal: Dictionary, error: String, width: float) -> Control:
	var pill := _capsule("LockPill", LOCK_BG, PILL_EDGE, Vector2(width, PILL_H), 2)
	var row := pill.get_node("Row")
	var produced: Dictionary = animal.get("requirements", {}).get("produced", {})
	for item_id: String in produced:
		var done := GameState.progress.stat("produce:" + item_id)
		if done < int(produced[item_id]):
			var icon := TextureRect.new()
			icon.name = "MissingIcon"
			icon.texture = Database.item_icon(item_id)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.custom_minimum_size = Vector2(20.0, 20.0)
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(icon)
			var count := MissionUi.text("%d/%d" % [done, int(produced[item_id])], 12, Palette.WOOD_CREAM, 3)
			count.name = "LockText"
			count.autowrap_mode = TextServer.AUTOWRAP_OFF
			count.custom_minimum_size = Vector2.ZERO
			row.add_child(count)
			return pill
	if error == "Faltam moedas":
		# Falta dinheiro: o preço que ainda não dá para pagar, com a moeda ao lado do cadeado.
		row.add_child(SellUi.soft(SellUi.coin(14.0)))
		var need := MissionUi.text(str(int(animal.price)), 14, Palette.WOOD_CREAM, 3)
		need.name = "LockText"
		need.autowrap_mode = TextServer.AUTOWRAP_OFF
		need.custom_minimum_size = Vector2.ZERO
		row.add_child(need)
		return pill
	var short := str({"Abrigo cheio": "Cheio", "Compre o abrigo primeiro": "Sem abrigo"}.get(error, error))
	var text := MissionUi.text(short, 13 if short.length() <= 10 else 12, Palette.WOOD_CREAM, 3)
	text.name = "LockText"
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.max_lines_visible = 2
	text.add_theme_constant_override("line_spacing", -3)
	text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.custom_minimum_size = Vector2(width - 8.0, 0.0)
	row.add_child(text)
	return pill


# --- Tábua ---------------------------------------------------------------------------------

## Tábua com as casinhas e o botão laranja "Ver meus animais" centrado no miolo liso.
static func _board(station_id: String, width: float) -> Control:
	var board := Control.new()
	board.name = "AnimalBoard"
	board.mouse_filter = Control.MOUSE_FILTER_PASS
	var board_w := width - BOARD_INSET * 2.0
	board.custom_minimum_size = Vector2(board_w, BOARD_H)
	board.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var art := SellUi.nine("board", BOARD_MARGINS, "Art", null, "animalshop_")
	board.add_child(art)
	StepCardUi.stretch(art)
	var button := BagUi.plain_button(func() -> void:
		Events.sheet_requested.emit(Database.stations[station_id].name, SheetBuilder.station_view(station_id)))
	button.name = "ViewAnimals"
	button.custom_minimum_size = Vector2(BUTTON_W, 44.0)
	button.pressed.connect(func() -> void: Motion.bounce(button))
	var shape := SellUi.nine("button", Vector4i(62, 58, 62, 58), "Art", null, "animalshop_")
	button.add_child(shape)
	StepCardUi.stretch(shape)
	var caption := MissionUi.text("Ver meus animais", 14, Palette.WOOD_CREAM, 3)
	caption.name = "ViewAnimalsLabel"
	caption.clip_text = true
	button.add_child(caption)
	StepCardUi.stretch(caption)
	board.add_child(button)
	button.set_anchors_preset(Control.PRESET_CENTER)
	button.offset_left = -BUTTON_W / 2.0
	button.offset_right = BUTTON_W / 2.0
	button.offset_top = -22.0
	button.offset_bottom = 22.0
	return board
