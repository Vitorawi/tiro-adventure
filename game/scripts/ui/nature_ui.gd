class_name NatureUi
extends RefCounted
## Um toque no material inicia; fila visual e próxima ferramenta no mesmo painel.


static func open(site: String = "trees", resource: String = "", focus_route: String = "") -> void:
	var data: Dictionary = Database.progression.nature_sites[site]
	Events.sheet_requested.emit(data.name, panel(site, resource, focus_route))


static func best_route(resource: String) -> String:
	var routes: Array = Database.progression.nature_resources[resource].routes
	for id: String in routes:
		if GameState.requirement_error(Database.progression.activities[id].get("requirements", {})) == "":
			return id
	return str(routes.back())


static func route_tool(route_id: String) -> String:
	for id: String in Database.progression.activities[route_id].get("requirements", {}).get("owned", []):
		for site: Dictionary in Database.progression.nature_sites.values():
			if id in site.tools:
				return id
	return ""


static func open_route(route_id: String) -> void:
	var site := Database.gathering_site(route_id)
	var route: Dictionary = Database.progression.activities[route_id]
	for resource: String in Database.progression.nature_sites[site].resources:
		if route.get("icon", "") == Database.progression.nature_resources[resource].icon:
			open(site, resource, route_id)
			return
	for item: String in Database.progression.activities[route_id].rewards.get("items", {}):
		if item in Database.progression.nature_sites[site].resources:
			open(site, item, route_id)
			return
	open(site, "", route_id)


static func panel(site: String = "trees", resource: String = "", focus_route: String = "") -> Control:
	var data: Dictionary = Database.progression.nature_sites[site]
	var selected: String = resource if resource in data.resources else str(data.resources[0])
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.add_child(UiKit.label("Toque no material para coletar", &"SmallLabel"))
		var choices := UiKit.hbox(6)
		for item: String in data.resources:
			var route_id := focus_route if item == selected and Database.gathering_site(focus_route) == site else best_route(item)
			_material(choices, site, item, route_id, data.resources.size() > 1)
		box.add_child(choices)
		var ready := GameState.gathering_ready_count(site)
		var free := GameState.gathering_free_count(site)
		box.add_child(UiKit.label("Coletas · %d/%d" % [GameState.gathering_jobs(site).size(), GameState.gathering_slots(site)], &"SectionLabel"))
		var slots := UiKit.hbox(6)
		for index in 3:
			_slot(slots, site, index)
		box.add_child(slots)
		if ready > 0:
			var collect := UiKit.button("Recolher prontos (%d)" % ready, func() -> void:
				_result(GameState.collect_gathering_all(site), "Materiais recolhidos!"), &"PrimaryButton")
			collect.name = "CollectAll_" + site
			box.add_child(collect)
		elif free == 0:
			box.add_child(UiKit.label("Espaços ocupados · aguarde a coleta", &"SmallLabel"))
		for upgrade: String in data.tools:
			if not GameState.has_upgrade(upgrade):
				var next := UiKit.hbox(6)
				next.name = "NextTool_" + site
				next.add_child(UiKit.icon(UiKit.ui_icon(Database.progression.upgrades[upgrade].icon)))
				next.add_child(UiKit.fill_label(Database.progression.upgrades[upgrade].name, &"SmallLabel"))
				next.add_child(UiKit.button("Melhorar", func() -> void:
					Events.sheet_requested.emit("Melhorar ferramenta", ProgressionUi.purchase(upgrade))))
				box.add_child(next)
				break)


## O material já é a ação: usa a primeira vaga livre, sem trocar de painel.
static func _material(parent: HBoxContainer, site: String, item: String, route_id: String, compact: bool) -> void:
	var route: Dictionary = Database.progression.activities[route_id]
	var column := UiKit.vbox(4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_stretch_ratio = 1.0
	parent.add_child(column)
	var primary := item if route.rewards.get("items", {}).has(item) else str(route.rewards.items.keys()[0])
	var text := "%s ×%d\n%s" % [Database.item_name(primary), int(route.rewards.items[primary]), TimeText.short(int(route.seconds))]
	var button := UiKit.button(text, func() -> void:
		_result(GameState.start_next_gathering(site, route_id, item), "Coleta iniciada!"), &"PrimaryButton", Database.item_icon(primary))
	button.name = "Material_" + item
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_constant_override("icon_max_width", 32)
	button.expand_icon = true
	button.custom_minimum_size.y = 64
	if compact:
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.custom_minimum_size.y = 96
	button.disabled = GameState.next_gathering_error(site, route_id, item) != ""
	column.add_child(button)
	var extras := UiKit.hbox(2)
	extras.alignment = BoxContainer.ALIGNMENT_CENTER
	for bonus: String in route.rewards.get("items", {}):
		if bonus != primary:
			extras.add_child(UiKit.icon(Database.item_icon(bonus), 16))
			var amount := UiKit.short_label("+%d" % int(route.rewards.items[bonus]), &"SmallLabel")
			amount.add_theme_font_size_override("font_size", 13)
			extras.add_child(amount)
	if extras.get_child_count() > 0:
		column.add_child(extras)
	else:
		extras.free()
	var tool := route_tool(route_id)
	var caption := "À mão" if tool == "" else str(Database.progression.upgrades[tool].name)
	var tool_label := UiKit.label(caption, &"SmallLabel", UiKit.BAD if tool != "" and not GameState.has_upgrade(tool) else null)
	tool_label.name = "RequiredTool_" + item
	tool_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tool_label.add_theme_font_size_override("font_size", 13)
	column.add_child(tool_label)
	var reason := GameState.requirement_error(route.get("requirements", {}))
	if reason != "":
		var help := UiKit.square_button("?", TaskHelp.open.bind("route", route_id), null, 44)
		column.add_child(help)


static func _slot(parent: HBoxContainer, site: String, index: int) -> void:
	var entry := GameState.gathering_entry(site, index)
	var remaining := GameState.gathering_remaining(site, index)
	var card := UiKit.card(parent, &"ReadyCardPanel" if not entry.is_empty() and remaining == 0 else &"CardPanel")
	card.add_theme_constant_override("separation", 4)
	if index >= GameState.gathering_slots(site):
		var upgrade: String = Database.progression.nature_sites[site].slot_upgrades[index - 1]
		var title := UiKit.label("+ Espaço", &"SmallLabel")
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(title)
		var buy := UiKit.button(str(int(Database.progression.upgrades[upgrade].cost)), func() -> void:
			_result(GameState.buy_upgrade(upgrade), "Espaço liberado!"), &"", UiKit.ui_icon("coin"))
		buy.name = "Unlock_%s_%d" % [site, index]
		buy.add_theme_constant_override("icon_max_width", 20)
		buy.add_theme_font_size_override("font_size", 16)
		buy.custom_minimum_size.y = 48
		buy.disabled = GameState.upgrade_error(upgrade) != ""
		if GameState.coins < int(Database.progression.upgrades[upgrade].cost):
			buy.add_theme_color_override("font_disabled_color", UiKit.BAD)
		card.add_child(buy)
		if index == 2 and GameState.gathering_slots(site) == 1:
			var after := UiKit.label("Após o 2º", &"SmallLabel")
			after.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			card.add_child(after)
		return
	if entry.is_empty():
		card.add_child(UiKit.icon(UiKit.ui_icon("timer")))
		var empty := UiKit.label("Livre", &"SmallLabel")
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(empty)
		return
	var route: Dictionary = Database.progression.activities[str(entry.id)]
	var items: Dictionary = entry.get("rewards", route.rewards).get("items", {})
	var item := str(entry.get("resource", ""))
	if not items.has(item):
		item = str(items.keys()[0])
	var picture := UiKit.icon(Database.item_icon(item), 32)
	picture.name = "GatherItem_%s_%d" % [site, index]
	card.add_child(picture)
	var status := UiKit.label("×%d · %s" % [int(items[item]), "Pronto" if remaining == 0 else TimeText.short(remaining)], &"SmallLabel")
	status.add_theme_font_size_override("font_size", 14)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(status)
	if remaining > 0:
		var duration := maxf(1.0, float(entry.ready_at) - float(entry.started_at))
		card.add_child(UiKit.bar(100.0 * (1.0 - remaining / duration), UiKit.GOOD, 6))


static func _result(error: String, done: String) -> void:
	Events.toast_requested.emit(error if error != "" else done)
