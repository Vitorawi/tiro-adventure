class_name OrdersUi
extends RefCounted
## Encomendas da Vila e contratos da banca no visual "madeira ilustrada": moldura de cipó com a faixa de pergaminho no topo,
## uma pílula creme (clientes ou nível da banca) e a lista de cartões que rola (barra fina à direita) dentro do papel; embaixo,
## separada, a tábua fixa com "Entrega" (um cartãozinho por ingrediente do pedido escolhido) e "Prêmio total" + o botão verde.
## As imagens `delivery_*.png` vêm de `tools/delivery_art.gd` (~3x o tamanho final: os NinePatch usam escala 1/3, então moram
## num Control comum). Só monta; as regras (entregar, recarga, requisitos) ficam no `GameState`.
## Nós preservados: `OrderBoard`/`ContractBoard`, `OrderGrid` (a lista), `Order_<id>`, `OrderMissionBadge`, `OrderMission_<missão>`,
## `OrderDetail` (a tábua), `DeliverOrder`/`Locked_DeliverOrder`, `CustomerSummary`, `Customer_<npc>`, `OrdersHelp`, `UpgradeStall`.

const FRAME_MARGINS := Vector4i(374, 474, 374, 212)  # esq, topo, dir, base do NinePatch da moldura (px guardados, 3x)
const IN_L := 38.0       # borda da moldura até o creme (px exibidos)
const IN_R := 38.0
const IN_T := 100.0      # topo da moldura até o creme (abaixo da faixa)
const IN_B := 22.0
const GAP := 6.0
const CARD_H := 90.0
const CARD_PAD := 10.0
const TOP_H := 44.0      # pílula do topo (alvo de toque inteiro)
const ICON := 32.0       # cada ingrediente: 32 px inteiros (pixel nítido), com espaço próprio
const ICON_GAP := 4.0
const ICON_W := 104.0    # três ícones + 2 folgas: mesma coluna em todos os cartões
const NAME_H := 28.0
const STATUS := Vector2(64.0, 34.0)
const REWARD := Vector2(70.0, 30.0)
const BOARD_INSET := 10.0
const BOARD_EST := 170.0  # altura estimada da tábua (para o quanto da lista cabe)
const PRIZE_W := 140.0
const NEED := Vector2(46.0, 76.0)
const MIN_LIST := 100.0
const GOLD := Color("e8a33a")
const AREA_BG := Color("9a5a36")
const AREA_EDGE := Color("c17b48")
const SLOT_BG := Color("65321f")


static func tex(file: String) -> Texture2D:
	return load(HomeUi.DIR + "delivery_" + file + ".png") as Texture2D


# --- Tela ----------------------------------------------------------------------------------

static func build(focus: String, channel: String) -> Control:
	var model := {"selected": focus, "scroll": 0, "focused": false}
	var live := SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.name = "ContractBoard" if channel == "contracts" else "OrderBoard"
		box.add_theme_constant_override("separation", 6)
		var ids := MarketUi.order_ids(channel)
		var width := SellUi.panel_width()
		var refresh := func() -> void: (box as SheetBuilder.LiveBox).refresh()
		if focus != "" and focus in ids and not bool(model.focused):
			model.focused = true
			model.scroll = maxi(0, int(ids.find(focus) * (CARD_H + GAP)))
		if not str(model.selected) in ids:
			model.selected = ids[0] if not ids.is_empty() else ""
		var title := "Minha banca" if channel == "contracts" else "Encomendas"
		box.add_child(_frame(ids, model, refresh, width, title, channel, focus))
		if str(model.selected) != "" and (focus == "" or focus in ids):
			box.add_child(_board(str(model.selected), width, refresh))
		var tail := Control.new()
		tail.custom_minimum_size.y = 6.0
		tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(tail))
	live.set_meta("sheet_bare", true)
	live.set_meta("sheet_fit_content", true)
	live.set_meta("tick_refresh", false)  # a lista rola: nada de refazer a cada segundo (a recarga tem o próprio relógio)
	return live


static func _screen() -> Vector2:
	return (Engine.get_main_loop() as SceneTree).root.get_visible_rect().size


static func _frame(ids: Array[String], model: Dictionary, refresh: Callable, width: float, title: String, channel: String, focus: String) -> Control:
	var frame := PanelContainer.new()
	frame.name = "OrderFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_PASS
	frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	frame.custom_minimum_size.x = width
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.add_child(SellUi.nine("frame", FRAME_MARGINS, "Art", null, "delivery_"))
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left", int(IN_L))
	margin.add_theme_constant_override("margin_right", int(IN_R))
	margin.add_theme_constant_override("margin_top", int(IN_T))
	margin.add_theme_constant_override("margin_bottom", int(IN_B))
	frame.add_child(margin)
	var inner_w := width - IN_L - IN_R
	var column := UiKit.vbox(6)
	column.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(column)
	column.add_child(_top_row(channel, inner_w))
	var note := _mission_note(str(model.selected))
	if note != null:
		column.add_child(note)
	column.add_child(_list_area(ids, model, refresh, inner_w, channel, focus, note != null))
	frame.add_child(SellUi.overlay(width, title, Vector4(100.0, 22.0, 100.0, 62.0), Vector4(-52.0, 44.0, -8.0, 88.0)))
	return frame


## Pílula creme sob a faixa: clientes (rosto + nível, tocáveis) e o "?" ou, na banca, o nível dela.
static func _top_row(channel: String, inner_w: float) -> Control:
	var row := UiKit.hbox(4)
	row.name = "CustomerSummary" if channel != "contracts" else "StallSummary"
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var pill := PanelContainer.new()
	pill.name = "TopPill"
	pill.mouse_filter = Control.MOUSE_FILTER_PASS
	pill.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pill.custom_minimum_size = Vector2(0.0, TOP_H)
	pill.add_child(SellUi.nine("card", Vector4i(48, 48, 48, 48), "Art", null, "delivery_"))
	var inside := UiKit.hbox(2)
	inside.mouse_filter = Control.MOUSE_FILTER_PASS
	var inset := MarginContainer.new()
	inset.mouse_filter = Control.MOUSE_FILTER_PASS
	inset.add_theme_constant_override("margin_left", 8)
	inset.add_theme_constant_override("margin_right", 8)
	inset.add_child(inside)
	pill.add_child(inset)
	row.add_child(pill)
	if channel == "contracts":
		var level := MarketUi.stall_level()
		var label := StationWood.text("Banca · nível %d/3" % level, 15)
		label.name = "StallLevel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inside.add_child(label)
		if level < 3:
			var upgrade := "stall" if level == 0 else "stall_%d" % (level + 1)
			var button := StationWood.wood_button("Montar" if level == 0 else "Ampliar", func() -> void:
				Events.sheet_requested.emit(str(Database.progression.upgrades[upgrade].name), ProgressionUi.purchase(upgrade)), 15, 84.0)
			button.name = "UpgradeStall"
			row.add_child(button)
		return row
	var seen := _customers()
	for customer in seen:
		var button := BagUi.plain_button(func() -> void:
			Events.sheet_requested.emit(str(Database.npcs[customer].name), MarketUi.customer_info(customer)))
		button.name = "Customer_" + customer
		button.tooltip_text = MarketUi.customer_text(customer)
		button.custom_minimum_size = Vector2(60.0, 44.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var line := UiKit.hbox(4)
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(line)
		StepCardUi.stretch(line)
		line.add_child(_face(customer, 26.0))
		var level := StationWood.text("Nv. %d" % GameState.progress.customer_level(customer), 14)
		level.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		line.add_child(level)
		inside.add_child(button)
	if seen.is_empty():
		var empty := StationWood.text("Pedidos dos vizinhos", 15)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inside.add_child(empty)
	var help := StepCardUi.help_button(func() -> void: _help(seen))
	help.name = "OrdersHelp"
	row.add_child(help)
	return row


static func _customers() -> Array[String]:
	var seen: Array[String] = []
	for id: String in Database.progression.orders:
		var customer := str(Database.progression.orders[id].get("customer", ""))
		if customer != "" and not customer in seen and GameState.requirement_error(Database.progression.orders[id].get("requirements", {})) == "":
			seen.append(customer)
	return seen


static func _help(seen: Array[String]) -> void:
	var content := UiKit.vbox(8)
	content.add_child(UiKit.label("Sem prazo. Pedidos com ! ajudam uma missão."))
	for customer in seen:
		content.add_child(MarketUi.customer_row(customer))
	MarketUi.next_order(content, "neighbors")
	content.add_child(UiKit.soft("Voltar às encomendas", func() -> void: Events.sheet_requested.emit("Encomendas", MarketUi.orders())))
	Events.sheet_requested.emit("Sobre as encomendas", content)


## Rostinho redondo do cliente.
static func _face(npc_id: String, px: float) -> TextureRect:
	var face := TextureRect.new()
	face.name = "Face"
	face.texture = ProgressionUi.npc_portrait(npc_id)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.custom_minimum_size = Vector2(px, px)
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return face


## Linha fixa (não rola) com a missão que o pedido escolhido ajuda: "! Missão: ...".
static func _mission_note(id: String) -> Control:
	if id == "":
		return null
	var quests := MarketUi.mission_quests(id)
	if quests.is_empty():
		return null
	var holder := UiKit.vbox(0)
	holder.name = "MissionNote"
	for quest_id in quests:
		var line := UiKit.hbox(6)
		line.name = "OrderMission_" + quest_id
		line.add_child(UiKit.alert_badge())
		var text := StationWood.text("Missão: " + str(Database.quests[quest_id].name), 13)
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.clip_text = true
		text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		line.add_child(text)
		holder.add_child(line)
	return holder


# --- Lista ---------------------------------------------------------------------------------

static func _list_area(ids: Array[String], model: Dictionary, refresh: Callable, inner_w: float, channel: String, focus: String, with_note: bool) -> Control:
	var shown_ids := ids if (focus == "" or focus in ids) else ([] as Array[String])
	# Rodapé da lista (dentro do papel): próximo pedido e, na banca, o texto e o botão de ampliação.
	var tail_h := 0.0
	var tail := UiKit.vbox(6)
	tail.name = "OrderFooter"
	tail.mouse_filter = Control.MOUSE_FILTER_PASS
	if channel == "contracts":
		tail_h += _stall_footer(tail)
	tail_h += _next_footer(tail, channel)
	var locked_focus := focus != "" and not focus in ids
	var count := shown_ids.size()
	var content_h := count * CARD_H + maxi(0, count - 1) * GAP + (GAP + tail_h if tail.get_child_count() > 0 else 0.0)
	var max_h := _screen().y - 128.0 - IN_T - IN_B - TOP_H - GAP - (BOARD_EST + 12.0 if str(model.selected) != "" else 0.0) - (24.0 if with_note else 0.0) - GAP
	var list_h := clampf(content_h, MIN_LIST, maxf(MIN_LIST, max_h))
	if shown_ids.is_empty():
		list_h = maxf(MIN_LIST, minf(content_h, maxf(MIN_LIST, max_h)))
	var needs_bar := content_h > list_h + 1.0
	var bar_w := SellUi.GUTTER if needs_bar else 0.0
	var card_w := inner_w - bar_w
	var holder := VBoxContainer.new()
	holder.name = "OrderGrid"
	holder.add_theme_constant_override("separation", int(GAP))
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	if locked_focus:
		var data: Dictionary = Database.progression.orders[focus]
		var name_label := StationWood.text(str(data.name), 18)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		holder.add_child(name_label)
		holder.add_child(UiKit.lock_hint(GameState.requirement_error(data.get("requirements", {})), TaskHelp.open.bind("order", focus)))
	elif shown_ids.is_empty():
		var empty := StationWood.text("Novos contratos chegam com a evolução da banca." if channel == "contracts" else "Os pedidos chegam depois da primeira colheita.", 16)
		empty.name = "OrdersEmpty"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size = Vector2(card_w, MIN_LIST)
		holder.add_child(empty)
	for id in shown_ids:
		var card := _card(id, id == str(model.selected), card_w, func() -> void:
			model.selected = id
			refresh.call(), refresh)
		holder.add_child(card)
	if tail.get_child_count() > 0:
		holder.add_child(tail)
	else:
		tail.free()
	return SellUi.scrolled(holder, inner_w, list_h, needs_bar, model, "OrderScroll", "OrderBar")


## Banca: texto do nível, progresso da ampliação e o botão. Devolve a altura estimada.
static func _stall_footer(tail: VBoxContainer) -> float:
	var level := MarketUi.stall_level()
	var height := 0.0
	var text := StationWood.text(["Monte sua banca para receber contratos.", "Banca de bairro · primeiros contratos.", "Banca ampliada · novos produtos e materiais.", "Banca da vila · contratos especiais."][level], 14)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tail.add_child(text)
	height += 40.0
	if level < 3:
		var upgrade := "stall" if level == 0 else "stall_%d" % (level + 1)
		var need: Dictionary = Database.progression.upgrades[upgrade].get("requirements", {})
		var goal := int(need.get("stats", {}).get("contracts", 0))
		if goal > 0:
			var kinds := int(need.get("distinct_orders", {}).get("contracts", 0))
			var progress := StationWood.text("Próxima ampliação: %d/%d contratos · %d/%d tipos" % [mini(GameState.progress.stat("contracts"), goal), goal, mini(GameState.progress.distinct_orders("contracts"), kinds), kinds], 13)
			progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tail.add_child(progress)
			height += 38.0
	return height


static func _next_footer(tail: VBoxContainer, channel: String) -> float:
	var before := tail.get_child_count()
	MarketUi.next_order(tail, channel)
	return 56.0 if tail.get_child_count() > before else 0.0


# --- Cartão --------------------------------------------------------------------------------

## Cartão do pedido: ingredientes soltos à esquerda, nome + prêmio no meio, estado (Preparar/Pronto/tempo) à direita.
static func _card(id: String, selected: bool, card_w: float, choose: Callable, refresh: Callable) -> Button:
	var data: Dictionary = Database.progression.orders[id]
	var result := BagUi.plain_button(choose)
	result.name = "Order_" + id
	result.custom_minimum_size = Vector2(card_w, CARD_H)
	result.set_meta("selected", selected)
	var art := SellUi.nine("card", Vector4i(60, 60, 60, 60), "Art", null, "delivery_")
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
	var body := UiKit.vbox(6)
	body.name = "Visual"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_child(body)
	StepCardUi.stretch(body)
	body.offset_left = CARD_PAD
	body.offset_right = -CARD_PAD
	body.offset_top = 8.0
	body.offset_bottom = -8.0
	# Linha de cima: rosto do cliente + nome do pedido (uma linha, reticências).
	var name_row := UiKit.hbox(6)
	name_row.name = "NameRow"
	name_row.custom_minimum_size.y = NAME_H
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var customer := str(data.get("customer", ""))
	if customer != "":
		var face := _face(customer, 28.0)
		face.name = "Customer_" + customer
		name_row.add_child(face)
	var caption := StationWood.text(str(data.name), 14)
	caption.name = "Caption"
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	caption.clip_text = true
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.tooltip_text = str(data.name)
	var name_w := card_w - CARD_PAD * 2.0 - (34.0 if customer != "" else 0.0) - 30.0
	_fit_caption(caption, name_w)
	name_row.add_child(caption)
	if not MarketUi.mission_quests(id).is_empty():
		var badge := UiKit.alert_badge()
		badge.name = "OrderMissionBadge"
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		name_row.add_child(badge)
	body.add_child(name_row)
	# Linha de baixo: ingredientes | prêmio | estado, centrados entre si na vertical.
	var row := UiKit.hbox(3)
	row.name = "BottomRow"
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(row)
	var icons := UiKit.hbox(ICON_GAP)
	icons.name = "Ingredients"
	icons.custom_minimum_size.x = ICON_W
	icons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for item: String in data.inputs:
		var icon := _ingredient_icon(item)
		icon.name = "Need_" + item
		icons.add_child(icon)
	row.add_child(icons)
	var reward := _reward_box(int(data.rewards.get("coins", 0)))
	row.add_child(reward)
	row.add_child(SellUi.spacer())
	var status := _status(id, refresh)
	row.add_child(status)
	return result


## Nome do pedido em uma linha: 14, ou 13 se assim couber inteiro; senão 13 com reticências (nunca menor que 13).
static func _fit_caption(label: Label, width: float) -> void:
	var font := label.get_theme_font("font")
	for px in [14, 13]:
		label.theme = HomeUi.theme(px, Palette.WOOD_INK)
		if font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x <= width:
			return


## Ícone do ingrediente num quadrado de 32 px (pixel no tamanho original; ilustrado reduzido e suave).
static func _ingredient_icon(item: String) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(ICON, ICON)
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var food := StationWood.food_texture(item)
	var source: Texture2D = food if food != null else Database.item_icon(item)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = source
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if source != null and source.get_width() <= 32 else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.custom_minimum_size = Vector2(ICON, ICON)
	slot.add_child(icon)
	icon.size = Vector2(ICON, ICON)
	return slot


## Caixinha creme com a moeda desenhada e o valor do prêmio na parte clara.
static func _reward_box(coins: int) -> Control:
	var box := pill("reward", REWARD, 130, 60, "Reward")
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var amount := StationWood.text(str(coins), 15)
	amount.name = "RewardValue"
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount.clip_text = true
	box.add_child(amount)
	var cap := REWARD.y * 130.0 / float(tex("reward").get_height())
	amount.position = Vector2(cap - 2.0, 0.0)
	amount.size = Vector2(REWARD.x - cap - 6.0, REWARD.y - 3.0)
	return box


## Estado à direita: "Preparar" (laranja, falta algo), "Pronto" (verde) ou o tempo da recarga (caixinha com relógio).
static func _status(id: String, refresh: Callable) -> Control:
	var rank := _rank(id)
	if rank == 2:
		return _cooldown(id, refresh)
	var box := pill("green" if rank == 0 else "orange", STATUS, 70, 70, "Status")
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var label := MissionUi.text("Pronto" if rank == 0 else "Preparar", 12, Palette.WOOD_CREAM, 3)
	label.name = "StatusLabel"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	box.add_child(label)
	label.position = Vector2(2.0, 0.0)
	label.size = Vector2(STATUS.x - 4.0, STATUS.y - 4.0)
	return box


static func _rank(id: String) -> int:
	if GameState.order_error(id) == "":
		return 0
	return 2 if GameState.progress.cooldown_left("order:" + id, GameState.now()) > 0 else 1


## Recarga: caixinha creme com relógio e o tempo, que anda sozinha e reconstrói a lista quando acaba.
static func _cooldown(id: String, refresh: Callable) -> Control:
	var box := Control.new()
	box.name = "Status"
	box.custom_minimum_size = STATUS
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = StationWood.INSET
	style.border_color = StationWood.CARD_EDGE
	style.set_border_width_all(2)
	style.set_corner_radius_all(15)
	panel.add_theme_stylebox_override("panel", style)
	box.add_child(panel)
	StepCardUi.stretch(panel)
	var row := UiKit.hbox(3)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	StepCardUi.stretch(row)
	row.add_child(StationWood.pic("clock", Vector2(14, 14), "Clock"))
	var time := StationWood.text("", 12)
	time.name = "StatusLabel"
	time.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(time)
	var update := func() -> void:
		var left := int(GameState.progress.cooldown_left("order:" + id, GameState.now()))
		if left <= 0:
			refresh.call()
		else:
			time.text = TimeText.short(left)
	update.call()
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(update)
	box.add_child(timer)
	return box


## Pílula ilustrada de altura fixa: as tampas (`cap_left`/`cap_right`, em px do arquivo) não esticam, só o miolo; nunca distorce.
static func pill(file: String, size: Vector2, cap_left: int, cap_right: int, node_name: String = "Pill") -> Control:
	var texture := tex(file)
	var host := Control.new()
	host.name = node_name
	host.custom_minimum_size = size
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var factor := float(texture.get_height()) / size.y
	var patch := NinePatchRect.new()
	patch.name = "Frame"
	patch.texture = texture
	patch.patch_margin_left = cap_left
	patch.patch_margin_right = cap_right
	patch.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patch.scale = Vector2.ONE / factor
	patch.size = size * factor
	host.add_child(patch)
	host.resized.connect(func() -> void: patch.size = host.size * factor)
	return host


# --- Tábua ---------------------------------------------------------------------------------

static func _board(id: String, width: float, refresh: Callable) -> Control:
	var data: Dictionary = Database.progression.orders[id]
	var panel := PanelContainer.new()
	panel.name = "OrderDetail"
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel.custom_minimum_size.x = width - BOARD_INSET * 2.0
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_child(StationWood.backing("board", 70, 60))
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var row := UiKit.hbox(8)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(row)
	# Entrega: um cartãozinho por ingrediente.
	var needs := UiKit.hbox(6)
	needs.name = "Needs"
	needs.alignment = BoxContainer.ALIGNMENT_CENTER
	needs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for item: String in data.inputs:
		needs.add_child(_need(item, int(data.inputs[item])))
	var customer := str(data.get("customer", ""))
	var tag: Control = null
	if customer != "":
		tag = _face(customer, 24.0)
		tag.name = "Customer_" + customer
		tag.tooltip_text = MarketUi.customer_text(customer)
	row.add_child(_area("delivery", "Entrega", needs, null, 0.0))
	if tag != null:
		# Etiqueta do cliente pregada no canto da tábua, fora das áreas (não empurra os títulos).
		var pin := Control.new()
		pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pin.add_child(tag)
		tag.position = Vector2(18.0, 12.0)
		tag.size = Vector2(24.0, 24.0)
		panel.add_child(pin)
	# Prêmio total: moeda, XP, itens e o botão.
	var prize := UiKit.vbox(2)
	prize.name = "Prize"
	prize.size_flags_vertical = Control.SIZE_EXPAND_FILL
	prize.alignment = BoxContainer.ALIGNMENT_CENTER
	_prize(prize, data.rewards)
	row.add_child(_area("prize", "Prêmio total", prize, _deliver(id, data), PRIZE_W))
	return panel


## Área afundada da tábua: título creme com contorno centralizado na área, conteúdo e (opcional) a ação no pé.
static func _area(key: String, title: String, content: Control, action: Control, min_width: float, tag: Control = null) -> PanelContainer:
	var area := PanelContainer.new()
	area.name = "Area_" + key
	area.mouse_filter = Control.MOUSE_FILTER_PASS
	if min_width > 0.0:
		area.custom_minimum_size.x = min_width
	else:
		area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = AREA_BG
	style.border_color = AREA_EDGE
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 8.0
	area.add_theme_stylebox_override("panel", style)
	var column := UiKit.vbox(4)
	column.mouse_filter = Control.MOUSE_FILTER_PASS
	area.add_child(column)
	var heading := MissionUi.text(title, 15, Palette.WOOD_CREAM, 3)
	heading.name = "AreaTitle_" + key
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.custom_minimum_size.y = 20.0
	if tag != null:
		# O rosto do cliente fica no canto da área, sem tirar o título do centro.
		var top := Control.new()
		top.custom_minimum_size.y = 22.0
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(heading)
		heading.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		top.add_child(tag)
		tag.position = Vector2(0.0, 0.0)
		tag.size = Vector2(22.0, 22.0)
		column.add_child(top)
	else:
		column.add_child(heading)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(content)
	if action != null:
		column.add_child(action)
	return area


## Ingrediente do pedido: cartãozinho creme com o ícone e a pílula "tem/precisa" (verde se tem, laranja se falta); toque = "Como fazer".
static func _need(item: String, need: int) -> Button:
	var have := GameState.inventory.count(item)
	var ok := have >= need
	var result := BagUi.plain_button(TaskHelp.open.bind("item", item, need))
	result.name = "Ingredient_" + item
	result.custom_minimum_size = NEED
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Cartãozinho creme dentro da área escura (como na referência): quebra o escuro sobre escuro.
	var face := Panel.new()
	face.name = "Art"
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fdf0d8")
	style.border_color = Color("d39a62")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.25, 0.12, 0.04, 0.35)
	style.shadow_size = 0
	style.shadow_offset = Vector2(0, 2)
	face.add_theme_stylebox_override("panel", style)
	face.show_behind_parent = true
	result.add_child(face)
	StepCardUi.stretch(face)
	var column := UiKit.vbox(4)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_child(column)
	StepCardUi.stretch(column)
	var slot := Control.new()
	slot.name = "Picture"
	slot.custom_minimum_size = Vector2(NEED.x, 36.0)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := SellUi.item_icon(item)
	slot.add_child(icon)
	icon.position = (slot.custom_minimum_size - icon.size) / 2.0
	column.add_child(slot)
	var count := pill("green" if ok else "orange", Vector2(42.0, 20.0), 65, 65, "Count")
	count.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var label := MissionUi.text("%d/%d" % [have, need], 12, Palette.WOOD_CREAM, 3)
	label.name = "CountLabel"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.add_child(label)
	label.position = Vector2(0.0, 0.0)
	label.size = Vector2(42.0, 18.0)
	column.add_child(count)
	return result


static func _prize(box: VBoxContainer, rewards: Dictionary) -> void:
	var coins := HBoxContainer.new()
	coins.name = "PrizeCoins"
	coins.alignment = BoxContainer.ALIGNMENT_CENTER
	coins.add_theme_constant_override("separation", 4)
	coins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coins.add_child(_icon_pic("coin", 22.0))
	var amount := MissionUi.text(str(int(rewards.get("coins", 0))), 18, Palette.WOOD_CREAM, 3)
	amount.name = "PrizeValue"
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coins.add_child(amount)
	box.add_child(coins)
	var extras := HFlowContainer.new()
	extras.name = "PrizeExtras"
	extras.alignment = FlowContainer.ALIGNMENT_CENTER
	extras.add_theme_constant_override("h_separation", 6)
	extras.add_theme_constant_override("v_separation", 0)
	extras.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for item: String in rewards.get("items", {}):
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(32.0, 32.0)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := SellUi.item_icon(item)
		holder.add_child(icon)
		icon.position = (Vector2(32.0, 32.0) - icon.size) / 2.0
		var line := _extra(holder, "×%d" % int(rewards.items[item]))
		line.name = "PrizeItem_" + item
		extras.add_child(line)
	box.add_child(extras)


static func _extra(icon: Control, value: String) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 2)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(icon)
	var label := MissionUi.text(value, 15, Palette.WOOD_CREAM, 3)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(label)
	return line


static func _icon_pic(file: String, px: float) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = tex(file)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	picture.custom_minimum_size = Vector2(px, px)
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return picture


## Entregar (verde) ou, se não dá, o motivo com cadeado (`Locked_DeliverOrder`, tocável: abre o "Como fazer").
static func _deliver(id: String, data: Dictionary) -> Control:
	var reason := GameState.order_error(id)
	var action := StepCardUi.go_button("Entregar", func() -> void:
		var error := GameState.fulfill_order(id)
		if error != "":
			Events.toast_requested.emit(error)
		else:
			Events.items_gained.emit(data.rewards.get("items", {}), int(data.rewards.get("coins", 0)), Vector2(-1, -1))
			Haptics.success())
	action.name = "DeliverOrder"
	if reason == "":
		return action
	action.free()
	var hint := StepCardUi.locked_button(reason, null, TaskHelp.open.bind("order", id))
	(hint as LockedButton).compact()  # a coluna da entrega é estreita
	hint.name = "Locked_DeliverOrder"
	return hint
