class_name MarketUi
extends RefCounted
## Vender excedentes, encomendas pequenas e contratos da banca têm acessos próprios.
## Seleção e paginação só na sessão; produção, pagamentos e esperas vêm do GameState.

static func is_contract(id: String) -> bool:
	return str(Database.progression.orders.get(id, {}).get("channel", "neighbors")) == "contracts"

static func stall_level() -> int:
	for level in [3, 2, 1]:
		if GameState.has_upgrade("stall" if level == 1 else "stall_%d" % level):
			return level
	return 0

static func order_ids(channel: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in Database.progression.orders:
		var data: Dictionary = Database.progression.orders[id]
		if is_contract(id) != (channel == "contracts"):
			continue
		if GameState.requirement_error(data.get("requirements", {})) == "":
			ids.append(id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var mission_a := not mission_quests(a).is_empty()
		var mission_b := not mission_quests(b).is_empty()
		if mission_a != mission_b: return mission_a
		var rank_a := _rank(a)
		var rank_b := _rank(b)
		return rank_a < rank_b if rank_a != rank_b else a < b)
	return ids


## Só objetivos pendentes das missões ativas; não promete avanço em tarefas futuras ou já feitas.
static func mission_quests(order_id: String) -> Array[String]:
	var result: Array[String] = []
	for quest_id: String in GameState.progress.active_steps().values():
		for goal: Dictionary in Database.quests[quest_id].goals:
			if str(goal.type) != "stat" or GameState.goal_value(goal) >= int(goal.get("target", 1)):
				continue
			var key := str(goal.key)
			if key == "order:" + order_id or key == "orders" or (key == "contracts" and is_contract(order_id)):
				if not quest_id in result: result.append(quest_id)
	return result

static func _rank(id: String) -> int:
	if GameState.order_error(id) == "": return 0
	return 2 if GameState.progress.cooldown_left("order:" + id, GameState.now()) > 0 else 1

static func orders(focus: String = "", channel: String = "neighbors") -> Control:
	if focus != "": channel = "contracts" if is_contract(focus) else "neighbors"
	var model := {"page": 0, "selected": focus}
	return SheetBuilder.tall(SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.name = "ContractBoard" if channel == "contracts" else "OrderBoard"
		if channel == "contracts":
			_stall_header(box)
		else:
			_customers_summary(box)
		var ids := order_ids(channel)
		if channel == "contracts" and ids.any(func(id: String) -> bool: return not mission_quests(id).is_empty()):
			box.add_child(UiKit.label("! Pedido de missão · aparece primeiro", &"SmallLabel"))
		if focus != "" and not focus in ids:
			var data: Dictionary = Database.progression.orders[focus]
			box.add_child(UiKit.label(str(data.name), &"StrongLabel"))
			box.add_child(UiKit.lock_hint(GameState.requirement_error(data.get("requirements", {})), TaskHelp.open.bind("order", focus)))
			return
		var count := 2 if channel == "contracts" else 4
		if focus != "" and model.selected == focus and model.page == 0 and focus in ids:
			model.page = floori(float(ids.find(focus)) / count)
		_page(box, model, ids.size(), count)
		var visible_ids := ids.slice(int(model.page) * count, (int(model.page) + 1) * count)
		if not str(model.selected) in visible_ids:
			model.selected = visible_ids[0] if not visible_ids.is_empty() else ""
		var grid := GridContainer.new()
		grid.name = "OrderGrid"
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		for id in visible_ids:
			grid.add_child(_order_tile(id, id == model.selected, func() -> void:
				model.selected = id
				(box as SheetBuilder.LiveBox).refresh()))
		box.add_child(grid)
		if str(model.selected) != "":
			_order_detail(box, str(model.selected))
		else:
			box.add_child(UiKit.label("Novos contratos chegam com a evolução da banca." if channel == "contracts" else "Os pedidos chegam depois da primeira colheita.", &"SmallLabel"))
		if channel == "contracts": _next_order(box, channel)
	))

## Selos de confiança do cliente (bronze/prata/ouro; o coração é do vínculo com o Tiro).
static func customer_seals(customer: String, px: int = 20) -> HBoxContainer:
	var row := UiKit.hbox(2)
	row.name = "Seals_" + customer
	var level := GameState.progress.customer_level(customer)
	var colors := [Palette.SEAL_BRONZE, Palette.SEAL_SILVER, Palette.SEAL_GOLD]
	for index in 3:
		# Disquinho bronze/prata/ouro com ✓; patamar ainda não ganho fica afundado.
		var earned := index < level
		var seal := UiKit.disc(UiKit.ctl_icon("check"), px, int(px * 0.65))
		seal.add_theme_stylebox_override("panel", UiKit.surface(colors[index] if earned else Palette.SUNKEN, px / 2))
		(seal.get_child(0) as Control).modulate = Palette.CARD if earned else Palette.INK_FAINT
		row.add_child(seal)
	return row

## "Laís · Freguês · 5/8" (entregas até o próximo patamar; variedade quando falta tipo).
static func customer_text(customer: String) -> String:
	var tiers: Array = Database.progression.get("customer_tiers", [])
	var level := GameState.progress.customer_level(customer)
	var seen := GameState.progress.customer_orders(customer)
	var who := str(Database.npcs.get(customer, {}).get("name", customer))
	var title := "Novo cliente" if level == 0 else str(tiers[level - 1].name)
	if level >= tiers.size():
		return "%s · %s · %d entregas" % [who, title, int(seen.count)]
	var next: Dictionary = tiers[level]
	if int(seen.count) >= int(next.count):
		return "%s · %s · peça %d tipos" % [who, title, int(next.kinds)]
	return "%s · %s · %d/%d" % [who, title, int(seen.count), int(next.count)]

static func customer_row(customer: String) -> HBoxContainer:
	var row := UiKit.hbox(6)
	row.name = "Customer_" + customer
	row.add_child(customer_seals(customer))
	row.add_child(UiKit.fill_label(customer_text(customer), &"SmallLabel"))
	return row

static func _customers_summary(box: VBoxContainer) -> void:
	var seen: Array[String] = []
	for id: String in Database.progression.orders:
		var customer := str(Database.progression.orders[id].get("customer", ""))
		if customer != "" and not customer in seen and GameState.requirement_error(Database.progression.orders[id].get("requirements", {})) == "":
			seen.append(customer)
	var card := UiKit.hbox(6)
	card.name = "CustomerSummary"
	for customer in seen:
		var button := UiKit.secondary("Nv. %d" % GameState.progress.customer_level(customer), func() -> void:
			Events.sheet_requested.emit(str(Database.npcs[customer].name), _customer_info(customer)), ProgressionUi.npc_portrait(customer), true)
		button.name = "Customer_" + customer
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 24)
		button.tooltip_text = customer_text(customer)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_child(button)
	var help := UiKit.ctl_button("help", func() -> void:
		var content := UiKit.vbox(8)
		content.add_child(UiKit.label("Sem prazo. Pedidos com ! ajudam uma missão."))
		for customer in seen: content.add_child(customer_row(customer))
		_next_order(content, "neighbors")
		content.add_child(UiKit.secondary("Voltar às encomendas", func() -> void: Events.sheet_requested.emit("Encomendas", orders())))
		Events.sheet_requested.emit("Sobre as encomendas", content), 40)
	help.name = "OrdersHelp"
	card.add_child(help)
	box.add_child(card)

static func _customer_info(customer: String) -> Control:
	var box := UiKit.vbox(8)
	box.add_child(customer_row(customer))
	box.add_child(UiKit.secondary("Voltar às encomendas", func() -> void: Events.sheet_requested.emit("Encomendas", orders())))
	return box

static func _page(box: VBoxContainer, model: Dictionary, total: int, count: int) -> void:
	var pages := maxi(1, ceili(float(total) / count))
	model.page = clampi(int(model.page), 0, pages - 1)
	var row := UiKit.hbox(6)
	for direction in [-1, 1]:
		var button := UiKit.ctl_button("back" if direction < 0 else "chev", func() -> void:
			model.page = int(model.page) + direction
			model.selected = ""
			(box as SheetBuilder.LiveBox).refresh(), 36, "soft")
		button.name = "PreviousPage" if direction < 0 else "NextPage"
		button.disabled = int(model.page) == (0 if direction < 0 else pages - 1)
		button.modulate.a = 0.4 if button.disabled else 1.0
		row.add_child(button)
		if direction < 0:
			var caption := UiKit.fill_label("%d / %d" % [int(model.page) + 1, pages], &"SmallLabel")
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row.add_child(caption)
	row.visible = pages > 1
	box.add_child(row)

static func _order_tile(id: String, selected: bool, action: Callable) -> Button:
	var data: Dictionary = Database.progression.orders[id]
	var first: String = data.inputs.keys()[0]
	var tile := UiKit.grid_tile(Database.item_icon(first), str(data.name), action, 100, 28)
	tile.name = "Order_" + id
	tile.custom_minimum_size.y = 92
	if not mission_quests(id).is_empty():
		var badge := UiKit.alert_badge()
		badge.name = "OrderMissionBadge"
		tile.add_child(badge)
		badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		badge.position += Vector2(-28, 4)
	var body := tile.get_node("Visual") as VBoxContainer
	var caption := body.get_node("Caption") as Label
	caption.theme_type_variation = &"StrongLabel"
	caption.max_lines_visible = 1
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	body.get_node("Picture").hide()
	var products := UiKit.hbox(6)
	products.alignment = BoxContainer.ALIGNMENT_CENTER
	for item: String in data.inputs:
		var product := UiKit.vbox(0)
		product.add_child(UiKit.icon(Database.item_icon(item), 24))
		products.add_child(product)
	body.add_child(products)
	body.move_child(products, 0)
	_ignore(products)
	if selected:
		# Escolhido = contorno de tinta (nunca verde).
		var style := tile.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		style.border_color = Palette.INK
		style.set_border_width_all(2)
		for state: String in ["normal", "hover", "pressed"]:
			tile.add_theme_stylebox_override(state, style)
	# Prêmio em chip mel; o estado (pronto/tempo) aparece num chip ao lado.
	var status_kind := "have" if _rank(id) == 0 else ("time" if _rank(id) == 2 else "neutral")
	var status := "Pronto" if _rank(id) == 0 else "Preparar"
	if _rank(id) == 2:
		status = TimeText.short(GameState.progress.cooldown_left("order:" + id, GameState.now()))
	var summary := UiKit.flow(4)
	summary.alignment = FlowContainer.ALIGNMENT_CENTER
	summary.add_child(UiKit.chip(UiKit.ui_icon("coin"), "%d" % int(data.rewards.get("coins", 0)), null, "prize"))
	summary.add_child(UiKit.chip(null, status, null, status_kind))
	_ignore(summary)
	body.add_child(summary)
	tile.custom_minimum_size.y = 112
	return tile

static func _ignore(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		if child is Control: _ignore(child)

static func _order_detail(box: VBoxContainer, id: String) -> void:
	var data: Dictionary = Database.progression.orders[id]
	var detail := UiKit.vbox(6)
	detail.name = "OrderDetail"
	var heading := UiKit.hbox(6)
	heading.add_child(UiKit.fill_label(str(data.name), &"StrongLabel"))
	if str(data.get("customer", "")) != "":
		var portrait := UiKit.icon(ProgressionUi.npc_portrait(str(data.customer)), 24)
		portrait.name = "Customer_" + str(data.customer)
		portrait.tooltip_text = customer_text(str(data.customer))
		heading.add_child(portrait)
	detail.add_child(heading)
	for quest_id in mission_quests(id):
		var row := UiKit.hbox(6)
		row.name = "OrderMission_" + quest_id
		row.add_child(UiKit.alert_badge())
		row.add_child(UiKit.fill_label("Missão: " + str(Database.quests[quest_id].name), &"SmallLabel"))
		detail.add_child(row)
	var ingredients := UiKit.flow(2)
	for item: String in data.inputs:
		ingredients.add_child(ProgressionUi.item_chip(item, int(data.inputs[item]), true))
	var rewards := ProgressionUi.reward_chips(data.rewards)
	for chip in rewards.get_children():
		rewards.remove_child(chip)
		ingredients.add_child(chip)
	rewards.free()
	detail.add_child(ingredients)
	var reason := GameState.order_error(id)
	var action := UiKit.primary("Entregar contrato" if is_contract(id) else "Entregar", func() -> void:
		var error := GameState.fulfill_order(id)
		if error != "":
			Events.toast_requested.emit(error)
		else:
			Events.items_gained.emit(data.rewards.get("items", {}), int(data.rewards.get("coins", 0)), Vector2(-1, -1))
			Haptics.success())
	action.name = "DeliverOrder"
	var missing: Texture2D = null
	for item: String in data.inputs:
		if GameState.inventory.count(item) < int(data.inputs[item]):
			missing = Database.item_icon(item)
			break
	detail.add_child(UiKit.action_or_hint(action, reason, TaskHelp.open.bind("order", id), missing))
	box.add_child(detail)

static func _next_order(box: VBoxContainer, channel: String) -> void:
	for id: String in Database.progression.orders:
		if is_contract(id) != (channel == "contracts"): continue
		var data: Dictionary = Database.progression.orders[id]
		var error := GameState.requirement_error(data.get("requirements", {}))
		if error != "":
			box.add_child(UiKit.lock_hint("Próximo: %s · %s" % [data.name, error], TaskHelp.open.bind("order", id)))
			return

static func _stall_header(box: VBoxContainer) -> void:
	var level := stall_level()
	box.add_child(UiKit.label("Minha banca · nível %d/3" % level, &"StrongLabel"))
	box.add_child(UiKit.label(["Monte sua banca para receber contratos.", "Banca de bairro · primeiros contratos.", "Banca ampliada · novos produtos e materiais.", "Banca da vila · contratos especiais."][level], &"SmallLabel"))
	if level < 3:
		var next_id := "stall" if level == 0 else "stall_%d" % (level + 1)
		var need: Dictionary = Database.progression.upgrades[next_id].get("requirements", {})
		var goal := int(need.get("stats", {}).get("contracts", 0))
		if goal > 0:
			box.add_child(UiKit.label("Próxima ampliação: %d/%d contratos · %d/%d tipos" % [mini(GameState.progress.stat("contracts"), goal), goal, mini(GameState.progress.distinct_orders("contracts"), int(need.get("distinct_orders", {}).get("contracts", 0))), int(need.get("distinct_orders", {}).get("contracts", 0))], &"SmallLabel"))
		var upgrade := "stall" if level == 0 else "stall_%d" % (level + 1)
		var button := UiKit.secondary("Montar banca" if level == 0 else "Ampliar banca", func() -> void:
			Events.sheet_requested.emit(str(Database.progression.upgrades[upgrade].name), ProgressionUi.purchase(upgrade)), UiKit.ui_icon("station_stall"), true)
		button.name = "UpgradeStall"
		box.add_child(button)

static func sell(world_id: String = "village") -> Control:
	var model := {"page": 0, "selected": "", "quantity": 1}
	return SheetBuilder.tall(SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.name = "SellBoard"
		box.add_child(UiKit.label("Venda excedentes e receba moedas na hora.", &"SmallLabel"))
		var ids: Array[String] = []
		for id: String in Database.items:
			if int(Database.items[id].get("sell_price", 0)) > 0 and GameState.inventory.count(id) > 0: ids.append(id)
		_page(box, model, ids.size(), 4)
		var visible_ids := ids.slice(int(model.page) * 4, (int(model.page) + 1) * 4)
		if not str(model.selected) in visible_ids:
			model.selected = visible_ids[0] if not visible_ids.is_empty() else ""
			model.quantity = 1
		var grid := GridContainer.new()
		grid.name = "SellGrid"
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		for id in visible_ids:
			var tile := _sell_tile(id, id == model.selected, func() -> void:
				model.selected = id
				model.quantity = 1
				(box as SheetBuilder.LiveBox).refresh())
			tile.name = "Sell_" + id
			grid.add_child(tile)
		box.add_child(grid)
		var id := str(model.selected)
		if id == "":
			box.add_child(UiKit.label("Colha para ter produtos para vender.", &"SmallLabel"))
			return
		model.quantity = clampi(int(model.quantity), 1, GameState.inventory.count(id))
		box.add_child(UiKit.label(Database.item_name(id), &"StrongLabel"))
		var row := UiKit.hbox(8)
		row.add_child(UiKit.stepper(int(model.quantity), 1, GameState.inventory.count(id), func(value: int) -> void:
			model.quantity = value
			(box as SheetBuilder.LiveBox).refresh(), "Tudo"))
		box.add_child(row)
		var qty := int(model.quantity)
		var action := UiKit.primary("Vender ×%d · +%d moedas" % [qty, qty * int(Database.items[id].sell_price)], func() -> void:
			var error := GameState.sell(id, qty, world_id)
			if error != "":
				Events.toast_requested.emit(error)
			else:
				Events.items_gained.emit({}, qty * int(Database.items[id].sell_price), Vector2(-1, -1)))
		action.name = "SellSelected"
		box.add_child(action)
	))


## Produto vendável: a seleção da primeira abertura usa o mesmo contorno das seleções por toque.
static func _sell_tile(id: String, selected: bool, choose: Callable) -> Button:
	var tile := UiKit.tile(Database.item_icon(id), "%s ×%d" % [Database.item_name(id), GameState.inventory.count(id)], "selected" if selected else "normal")
	tile.custom_minimum_size = Vector2(0, 120)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.set_meta("selected", selected)
	tile.pressed.connect(choose)
	var surface := tile.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	surface.bg_color = Palette.CARD
	for phase: String in ["normal", "hover", "pressed", "hover_pressed"]:
		tile.add_theme_stylebox_override(phase, surface)
	var body := tile.get_node("Visual") as VBoxContainer
	body.offset_left = 8
	body.offset_right = -8
	var picture := body.get_node("Picture")
	body.remove_child(picture)
	picture.free()
	var disc := UiKit.disc(Database.item_icon(id), 48, 40)
	disc.name = "Picture"
	disc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(disc)
	body.move_child(disc, 0)
	var title := body.get_child(1) as Label
	title.name = "Caption"
	title.theme_type_variation = &"StrongLabel"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.max_lines_visible = 2
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return tile
