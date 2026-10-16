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
		var rank_a := _rank(a)
		var rank_b := _rank(b)
		return rank_a < rank_b if rank_a != rank_b else a < b)
	return ids

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
			box.add_child(UiKit.label("Pedidos pequenos dos vizinhos. Sem prazo para entregar.", &"SmallLabel"))
		var ids := order_ids(channel)
		if focus != "" and not focus in ids:
			var data: Dictionary = Database.progression.orders[focus]
			box.add_child(UiKit.label(str(data.name), &"SectionLabel"))
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
		_next_order(box, channel)
	))

static func _page(box: VBoxContainer, model: Dictionary, total: int, count: int) -> void:
	var pages := maxi(1, ceili(float(total) / count))
	model.page = clampi(int(model.page), 0, pages - 1)
	var row := UiKit.hbox(6)
	for direction in [-1, 1]:
		var button := UiKit.secondary("‹" if direction < 0 else "›", func() -> void:
			model.page = int(model.page) + direction
			model.selected = ""
			(box as SheetBuilder.LiveBox).refresh(), null, true)
		button.name = "PreviousPage" if direction < 0 else "NextPage"
		button.disabled = int(model.page) == (0 if direction < 0 else pages - 1)
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
	tile.custom_minimum_size.y = 122
	var body := tile.get_node("Visual") as VBoxContainer
	body.get_node("Picture").hide()
	var products := UiKit.hbox(6)
	products.alignment = BoxContainer.ALIGNMENT_CENTER
	for item: String in data.inputs:
		var product := UiKit.vbox(0)
		product.add_child(UiKit.icon(Database.item_icon(item), 24))
		var amount := UiKit.short_label("%d/%d" % [GameState.inventory.count(item), int(data.inputs[item])], &"SmallLabel", Palette.GOOD if GameState.inventory.count(item) >= int(data.inputs[item]) else Palette.BAD)
		amount.add_theme_font_size_override("font_size", 12)
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		product.add_child(amount)
		products.add_child(product)
	body.add_child(products)
	body.move_child(products, 0)
	_ignore(products)
	if selected:
		var style := tile.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		style.border_color = Palette.GOOD
		style.set_border_width_all(3)
		for state: String in ["normal", "hover", "pressed"]:
			tile.add_theme_stylebox_override(state, style)
	var label := body.find_child("Caption", true, false) as Label
	if label: label.add_theme_font_size_override("font_size", 16)
	var status := "Pronto ✓" if _rank(id) == 0 else "Preparar"
	if _rank(id) == 2:
		status = TimeText.short(GameState.progress.cooldown_left("order:" + id, GameState.now()))
	var summary := UiKit.short_label("%d moedas · %s" % [int(data.rewards.get("coins", 0)), status], &"SmallLabel")
	summary.add_theme_font_size_override("font_size", 14)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(summary)
	return tile

static func _ignore(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		if child is Control: _ignore(child)

static func _order_detail(box: VBoxContainer, id: String) -> void:
	var data: Dictionary = Database.progression.orders[id]
	var detail := UiKit.vbox(6)
	detail.name = "OrderDetail"
	detail.add_child(UiKit.label(str(data.name), &"SectionLabel"))
	var ingredients := UiKit.flow(2)
	for item: String in data.inputs:
		ingredients.add_child(ProgressionUi.item_chip(item, int(data.inputs[item])))
	detail.add_child(ingredients)
	detail.add_child(ProgressionUi.reward_chips(data.rewards))
	var reason := GameState.order_error(id)
	var action := UiKit.primary("Entregar contrato" if is_contract(id) else "Entregar", func() -> void:
		var error := GameState.fulfill_order(id)
		if error != "":
			Events.toast_requested.emit(error)
		else:
			Events.items_gained.emit(data.rewards.get("items", {}), int(data.rewards.get("coins", 0)), Vector2(-1, -1))
			Haptics.success())
	action.name = "DeliverOrder"
	action.disabled = reason != ""
	detail.add_child(action)
	if reason != "": detail.add_child(UiKit.label(reason, &"SmallLabel"))
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
	box.add_child(UiKit.label("Minha banca · nível %d/3" % level, &"SectionLabel"))
	box.add_child(UiKit.label(["Monte sua banca para receber contratos.", "Banca de bairro · primeiros contratos.", "Banca ampliada · novos produtos e materiais.", "Banca da vila · contratos especiais."][level], &"SmallLabel"))
	if level < 3:
		box.add_child(UiKit.label("Próxima ampliação: %d/%d contratos" % [mini(GameState.progress.stat("contracts"), 2 if level <= 1 else 5), 2 if level <= 1 else 5], &"SmallLabel"))
		var upgrade := "stall" if level == 0 else "stall_%d" % (level + 1)
		var button := UiKit.secondary("Montar banca" if level == 0 else "Ampliar banca", func() -> void:
			Events.sheet_requested.emit(str(Database.progression.upgrades[upgrade].name), ProgressionUi.purchase(upgrade)), UiKit.ui_icon("station_stall"), true)
		button.name = "UpgradeStall"
		box.add_child(button)
	box.add_child(UiKit.label("Contratos maiores, com moedas e materiais. Sem prazo para entregar.", &"SmallLabel"))

static func sell() -> Control:
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
			var tile := UiKit.grid_tile(Database.item_icon(id), "%s ×%d" % [Database.item_name(id), GameState.inventory.count(id)], func() -> void:
				model.selected = id
				model.quantity = 1
				(box as SheetBuilder.LiveBox).refresh(), 100, 32)
			tile.name = "Sell_" + id
			grid.add_child(tile)
		box.add_child(grid)
		var id := str(model.selected)
		if id == "":
			box.add_child(UiKit.label("Colha para ter produtos para vender.", &"SmallLabel"))
			return
		model.quantity = clampi(int(model.quantity), 1, GameState.inventory.count(id))
		box.add_child(UiKit.label(Database.item_name(id), &"SectionLabel"))
		var row := UiKit.hbox(6)
		for entry: Dictionary in [{"label": "−", "change": -1}, {"label": "+", "change": 1}, {"label": "Tudo", "change": 0}]:
			var button := UiKit.secondary(str(entry.label), func() -> void:
				model.quantity = GameState.inventory.count(id) if int(entry.change) == 0 else clampi(int(model.quantity) + int(entry.change), 1, GameState.inventory.count(id))
				(box as SheetBuilder.LiveBox).refresh(), null, true)
			row.add_child(button)
		box.add_child(row)
		var qty := int(model.quantity)
		var action := UiKit.primary("Vender ×%d · +%d moedas" % [qty, qty * int(Database.items[id].sell_price)], func() -> void:
			var error := GameState.sell(id, qty)
			if error != "":
				Events.toast_requested.emit(error)
			else:
				Events.items_gained.emit({}, qty * int(Database.items[id].sell_price), Vector2(-1, -1)))
		action.name = "SellSelected"
		box.add_child(action)
	))
