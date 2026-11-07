class_name MarketUi
extends RefCounted
## Vender excedentes, encomendas pequenas e contratos da banca têm acessos próprios.
## A escolha do pedido vale só na sessão; produção, pagamentos e esperas vêm do GameState.

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
	return OrdersUi.build(focus, channel)

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
	var row := UiKit.hbox(8)
	row.name = "Customer_" + customer
	row.add_child(customer_seals(customer))
	var text := StepCardUi.wood(customer_text(customer), 16)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.custom_minimum_size.x = 120.0
	row.add_child(text)
	return row

## Nível do cliente em madeira: folha `sheet_wood` com o cartão de papel (selos + texto) e um botão amarelo para voltar.
static func customer_info(customer: String) -> Control:
	var panel := SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var inner := StepCardUi.inner_card(box, "CustomerCard", Vector4i(14, 14, 14, 14))
		inner.add_child(customer_row(customer))
		var back := WelcomeSheet._button("Voltar às encomendas", false, 240.0, "BackToOrders", func() -> void: Events.sheet_requested.emit("Encomendas", orders()))
		box.add_child(back))
	panel.set_meta("sheet_wood", true)
	panel.set_meta("sheet_fit_content", true)
	return panel

static func next_order(box: VBoxContainer, channel: String) -> void:
	for id: String in Database.progression.orders:
		if is_contract(id) != (channel == "contracts"): continue
		var data: Dictionary = Database.progression.orders[id]
		var error := GameState.requirement_error(data.get("requirements", {}))
		if error != "":
			box.add_child(UiKit.lock_hint("Próximo: %s · %s" % [data.name, error], TaskHelp.open.bind("order", id)))
			return

## Tela de venda do Sítio (vovó Bloblo) e da Vila (Feirante): visual de madeira em `SellUi`.
static func sell(world_id: String = "village") -> Control:
	return SellUi.build(world_id)
