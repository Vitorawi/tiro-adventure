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


static func panel(section: String = "collect", focus: String = "") -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var tabs := UiKit.hbox(8)
		tabs.add_child(UiKit.button("Coletar", open.bind("collect", ""), &"PrimaryButton" if section == "collect" else &""))
		tabs.add_child(UiKit.button("Ferramentas", open.bind("tools", ""), &"PrimaryButton" if section == "tools" else &""))
		box.add_child(tabs)
		if section == "tools":
			box.add_child(UiKit.label("Melhore as ferramentas para coletar mais e encontrar materiais melhores.", &"SmallLabel"))
			var seen: Array[String] = []
			for resource: String in Database.progression.nature_resources:
				if focus != "" and resource != focus:
					continue
				for id: String in Database.progression.nature_resources[resource].tools:
					if id in seen:
						continue
					seen.append(id)
					ProgressionUi.upgrade_card(box, id)
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
	var tool_name := "Coleta à mão"
	for tool: String in data.tools:
		if GameState.has_upgrade(tool):
			tool_name = Database.progression.upgrades[tool].name
	info.add_child(UiKit.label(tool_name, &"SmallLabel"))
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
		actions.add_child(UiKit.button("Melhorar", open.bind("tools", id)))
	card.add_child(actions)
	if error != "" and GameState.progress.activity.is_empty():
		card.add_child(UiKit.label(error, &"SmallLabel"))
