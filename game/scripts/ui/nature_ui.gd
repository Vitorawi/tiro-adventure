class_name NatureUi
extends RefCounted
## Um painel reúne materiais e ferramentas: o jogador não troca de lugar para coletar.


static func open(section: String = "collect", focus: String = "") -> void:
	Events.sheet_requested.emit("Natureza", panel(section, focus))


static func best_route(resource_id: String) -> String:
	var routes: Array = Database.progression.nature_resources[resource_id].routes
	for id: String in routes:
		if GameState.requirement_error(Database.progression.activities[id].get("requirements", {})) == "":
			return id
	return str(routes.back())


static func tool_group(focus: String) -> String:
	var groups: Dictionary = Database.progression.nature_tool_groups
	if groups.has(focus):
		return focus
	for id: String in groups:
		if focus in groups[id].resources:
			return id
	return str(groups.keys()[0])


## Ferramenta realmente exigida pela rota, não a última compra da categoria.
static func route_tool(route_id: String) -> String:
	for id: String in Database.progression.activities[route_id].get("requirements", {}).get("owned", []):
		for group: Dictionary in Database.progression.nature_tool_groups.values():
			if id in group.tools:
				return id
	return ""


static func panel(section: String = "collect", focus: String = "") -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var tabs := UiKit.hbox(8)
		tabs.add_child(UiKit.button("Coletar", open.bind("collect", ""), &"PrimaryButton" if section == "collect" else &""))
		tabs.add_child(UiKit.button("Ferramentas", open.bind("tools", ""), &"PrimaryButton" if section == "tools" else &""))
		box.add_child(tabs)
		if section == "tools":
			var selected := tool_group(focus)
			var groups: Dictionary = Database.progression.nature_tool_groups
			var filters := UiKit.hbox(6)
			for group_id: String in groups:
				var button := UiKit.button(groups[group_id].name, open.bind("tools", group_id), &"PrimaryButton" if group_id == selected else &"")
				button.name = "ToolsTab_" + group_id
				button.add_theme_font_size_override("font_size", 16)
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				filters.add_child(button)
			box.add_child(filters)
			var group: Dictionary = groups[selected]
			box.add_child(UiKit.label(group.description, &"SmallLabel"))
			var materials := UiKit.flow(4)
			for item: String in group.resources:
				materials.add_child(UiKit.chip(Database.item_icon(item), Database.item_name(item)))
			box.add_child(materials)
			var next := ""
			for id: String in group.tools:
				if next == "" and not GameState.has_upgrade(id):
					next = id
			for id: String in group.tools:
				var block := UiKit.vbox(4)
				block.name = "Tool_" + id
				box.add_child(block)
				if id == next:
					block.add_child(UiKit.label("Próxima ferramenta", &"SectionLabel"))
				ProgressionUi.upgrade_card(block, id)
			return
		ProgressionUi.active_activity(box)
		box.add_child(UiKit.label("Escolha o material. Suas ferramentas definem a melhor coleta disponível.", &"SmallLabel"))
		for id: String in Database.progression.nature_resources:
			_resource_card(box, id))


static func _resource_card(box: VBoxContainer, id: String) -> void:
	var data: Dictionary = Database.progression.nature_resources[id]
	var route_id := best_route(id)
	var route: Dictionary = Database.progression.activities[route_id]
	var card := UiKit.card(box)
	card.name = "Collect_" + id
	var top := UiKit.hbox(8)
	top.add_child(UiKit.icon(UiKit.ui_icon(data.icon), 40))
	var info := UiKit.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UiKit.label(data.name, &"SectionLabel"))
	var required_tool := route_tool(route_id)
	var tool_row := UiKit.hbox(4)
	var tool_name := "À mão · sem ferramenta"
	if required_tool != "":
		var upgrade: Dictionary = Database.progression.upgrades[required_tool]
		tool_row.add_child(UiKit.icon(UiKit.ui_icon(upgrade.icon), 28))
		tool_name = ("Usa: " if GameState.has_upgrade(required_tool) else "Precisa: ") + str(upgrade.name)
	var caption := UiKit.fill_label(tool_name, &"SmallLabel")
	caption.name = "RequiredTool_" + id
	tool_row.add_child(caption)
	info.add_child(tool_row)
	top.add_child(info)
	card.add_child(top)
	var amounts := UiKit.flow(4)
	amounts.add_child(UiKit.chip(UiKit.ui_icon("timer"), TimeText.short(int(route.seconds))))
	for output: String in route.rewards.get("items", {}):
		amounts.add_child(UiKit.chip(Database.item_icon(output), "+%d" % int(route.rewards.items[output])))
	card.add_child(amounts)
	var actions := UiKit.hbox(8)
	var error := GameState.activity_error(route_id)
	var collect := UiKit.button("Coletar", func() -> void:
		var reason := GameState.start_activity(route_id)
		Events.toast_requested.emit(reason if reason != "" else "Coleta iniciada: " + route.name), &"PrimaryButton")
	collect.name = "Start_" + id
	collect.disabled = error != ""
	collect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(collect)
	var next_tool := ""
	for tool: String in data.tools:
		if not GameState.has_upgrade(tool):
			next_tool = tool
			break
	if next_tool != "":
		actions.add_child(UiKit.button("Ferramentas", open.bind("tools", tool_group(id))))
	card.add_child(actions)
	if next_tool != "":
		card.add_child(UiKit.label("Próxima: " + str(Database.progression.upgrades[next_tool].name), &"SmallLabel"))
	if error != "" and GameState.progress.activity.is_empty():
		card.add_child(UiKit.label(error, &"SmallLabel"))
