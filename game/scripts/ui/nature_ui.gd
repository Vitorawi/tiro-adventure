class_name NatureUi
extends RefCounted
## Local tocável -> ferramenta, três espaços e próxima melhoria no mesmo painel.


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
		if data.resources.size() > 1:
			var choices := UiKit.flow(6)
			for item: String in data.resources:
				var choice := UiKit.button(Database.item_name(item), open.bind(site, item), &"PrimaryButton" if item == selected else &"", Database.item_icon(item))
				choice.add_theme_constant_override("icon_max_width", 24)
				choice.add_theme_font_size_override("font_size", 16)
				choice.name = "Material_" + item
				choices.add_child(choice)
			box.add_child(choices)
		var route_id := focus_route if Database.gathering_site(focus_route) == site else best_route(selected)
		var route: Dictionary = Database.progression.activities[route_id]
		if focus_route != "":
			box.add_child(UiKit.label(route.name, &"SmallLabel"))
		var tool := route_tool(route_id)
		var tools := UiKit.hbox(6)
		if tool != "":
			tools.add_child(UiKit.icon(UiKit.ui_icon(Database.progression.upgrades[tool].icon), 32))
		var caption := UiKit.fill_label("À mão · sem ferramenta" if tool == "" else ("Usa: " if GameState.has_upgrade(tool) else "Precisa: ") + str(Database.progression.upgrades[tool].name), &"SmallLabel")
		caption.name = "RequiredTool_" + site
		tools.add_child(caption)
		var extra_tools := false
		for owned: String in data.tools:
			if GameState.has_upgrade(owned) and owned != tool:
				if not extra_tools:
					tools.add_child(UiKit.short_label("Tem:", &"SmallLabel"))
					extra_tools = true
				var icon := UiKit.icon(UiKit.ui_icon(Database.progression.upgrades[owned].icon), 24)
				icon.name = "OwnedTool_" + owned
				tools.add_child(icon)
		box.add_child(tools)
		var rewards := UiKit.flow(4)
		rewards.add_child(UiKit.chip(UiKit.ui_icon("timer"), TimeText.short(int(route.seconds))))
		for item: String in route.rewards.get("items", {}):
			rewards.add_child(UiKit.chip(Database.item_icon(item), "+%d" % int(route.rewards.items[item])))
		box.add_child(rewards)
		box.add_child(UiKit.label("Espaços · %d/3" % GameState.gathering_slots(site), &"SectionLabel"))
		var slots := UiKit.hbox(6)
		for index in 3:
			_slot(slots, site, index, route_id, selected)
		box.add_child(slots)
		var ready := GameState.gathering_ready_count(site)
		var free := GameState.gathering_free_count(site)
		if ready > 1:
			box.add_child(UiKit.button("Recolher prontos (%d)" % ready, func() -> void:
				_result(GameState.collect_gathering_all(site), "Materiais recolhidos!"), &"PrimaryButton"))
		elif free > 1:
			var all := UiKit.button("Coletar nos livres (%d)" % free, func() -> void:
				_result(GameState.start_gathering_all(site, route_id, selected), "Coletas iniciadas!"), &"PrimaryButton")
			all.name = "StartAll_" + site
			all.disabled = GameState.requirement_error(route.get("requirements", {})) != ""
			box.add_child(all)
		var reason := GameState.requirement_error(route.get("requirements", {}))
		if reason != "":
			box.add_child(UiKit.label(reason, &"SmallLabel", UiKit.BAD))
		for upgrade: String in data.tools:
			if not GameState.has_upgrade(upgrade):
				var next := UiKit.vbox(4)
				next.name = "NextTool_" + site
				box.add_child(next)
				next.add_child(UiKit.label("Melhorar ferramenta", &"SectionLabel"))
				ProgressionUi.upgrade_card(next, upgrade)
				break)


static func _slot(parent: HBoxContainer, site: String, index: int, route_id: String, selected: String) -> void:
	var card := UiKit.card(parent)
	card.get_parent().custom_minimum_size.x = 94
	var label := UiKit.label("%dº espaço" % (index + 1), &"SmallLabel")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(label)
	if index >= GameState.gathering_slots(site):
		var upgrade: String = Database.progression.nature_sites[site].slot_upgrades[index - 1]
		card.add_child(UiKit.label("Após o 2º" if index == 2 and GameState.gathering_slots(site) == 1 else "Fechado", &"SmallLabel"))
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
		return
	var entry := GameState.gathering_entry(site, index)
	var route: Dictionary = Database.progression.activities[route_id if entry.is_empty() else str(entry.id)]
	var items: Dictionary = route.rewards.get("items", {}) if entry.is_empty() else entry.get("rewards", route.rewards).get("items", {})
	if not items.is_empty():
		var item: String = items.keys()[0]
		var primary: String = selected if entry.is_empty() else str(entry.get("resource", ""))
		if items.has(primary):
			item = primary
		else:
			for candidate: String in items:
				if candidate in Database.progression.nature_sites[site].resources:
					item = candidate
					break
		var picture := UiKit.icon(Database.item_icon(item), 40)
		picture.name = "GatherItem_%s_%d" % [site, index]
		card.add_child(picture)
		var amount := UiKit.label("×%d" % int(items[item]), &"SmallLabel")
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(amount)
	var remaining := GameState.gathering_remaining(site, index)
	var status := UiKit.label("Livre" if entry.is_empty() else ("Pronto!" if remaining == 0 else TimeText.short(remaining)), &"SmallLabel")
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(status)
	var button := UiKit.button("Coletar" if entry.is_empty() else ("Recolher" if remaining == 0 else "Aguarde"), func() -> void:
		if GameState.gathering_entry(site, index).is_empty():
			_result(GameState.start_gathering(site, index, route_id, selected), "Coleta iniciada!")
		else:
			_result(GameState.collect_gathering(site, index), "Materiais recolhidos!"), &"PrimaryButton")
	button.name = "Gather_%s_%d" % [site, index]
	button.add_theme_font_size_override("font_size", 16)
	button.custom_minimum_size.y = 48
	button.disabled = GameState.gathering_error(site, index, route_id, selected) != "" if entry.is_empty() else remaining > 0
	card.add_child(button)


static func _result(error: String, done: String) -> void:
	Events.toast_requested.emit(error if error != "" else done)
