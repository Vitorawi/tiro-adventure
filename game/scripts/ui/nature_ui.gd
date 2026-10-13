class_name NatureUi
extends RefCounted
## Um toque coleta; usar cada região aumenta seu XP e libera materiais/espaços.


static func open(site: String = "trees", resource: String = "", focus_route: String = "") -> void:
	var data: Dictionary = Database.progression.nature_sites[site]
	Events.sheet_requested.emit(data.name, panel(site, resource, focus_route))


static func best_route(resource: String) -> String:
	var routes: Array = Database.progression.nature_resources[resource].routes
	for id: String in routes:
		if GameState.requirement_error(Database.progression.activities[id].get("requirements", {})) == "":
			return id
	return str(routes.back())


static func route_level(route_id: String) -> int:
	for id: String in Database.progression.activities[route_id].get("requirements", {}).get("owned", []):
		for site: Dictionary in Database.progression.nature_sites.values():
			if id in site.level_upgrades:
				return site.level_upgrades.find(id) + 1
	return 0


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
		var level := GameState.progress.nature_level(site)
		if level == 0:
			box.add_child(UiKit.label("Local fechado", &"SectionLabel"))
			ProgressionUi.upgrade_card(box, str(data.level_upgrades[0]))
			return
		_progress(box, site)
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
				var before := int(GameState.progress.nature_xp.get(site, 0))
				var previous_level := GameState.progress.nature_level(site)
				var error := GameState.collect_gathering_all(site)
				var level_now := GameState.progress.nature_level(site)
				if error == "":
					Events.items_gained.emit(GameState.last_gain, GameState.last_coins, Vector2(-1.0, -1.0))
				_result(error, "%s nível %d!" % [data.name, level_now] if level_now > previous_level else "+%d XP em %s" % [int(GameState.progress.nature_xp.get(site, 0)) - before, data.name]), &"PrimaryButton")
			collect.name = "CollectAll_" + site
			box.add_child(collect)
		elif free == 0:
			box.add_child(UiKit.label("Espaços ocupados · aguarde a coleta", &"SmallLabel"))
		var refine := UiKit.button("Refinar materiais", func() -> void:
			Events.sheet_requested.emit("Refinar · " + str(data.name), refining_panel(site)))
		refine.name = "Refine_" + site
		box.add_child(refine))


static func _progress(box: VBoxContainer, site: String) -> void:
	var data: Dictionary = Database.progression.nature_sites[site]
	var info := GameState.progress.nature_info(site)
	var heading := UiKit.hbox(6)
	var title := UiKit.fill_label("Nível %d · %s" % [info.level, "Máximo" if info.max else "%d/%d XP" % [info.xp, info.needed]], &"SectionLabel")
	title.name = "NatureProgress_" + site
	heading.add_child(title)
	heading.add_child(UiKit.square_button("?", func() -> void:
		Events.sheet_requested.emit("Evolução · " + str(data.name), levels_panel(site)), null, 44))
	box.add_child(heading)
	box.add_child(UiKit.bar(100.0 if info.max else 100.0 * info.xp / maxi(1, int(info.needed)), UiKit.GOOD, 10))
	if not info.max:
		box.add_child(UiKit.label("Próximo: " + str(data.levels[info.level].label), &"SmallLabel"))
		var count := ceili(float(info.remaining) / int(data.xp_per_collection))
		box.add_child(UiKit.label("Recolha mais %d %s · +%d XP cada" % [count, "coleta" if count == 1 else "coletas", int(data.xp_per_collection)], &"SmallLabel"))
	else:
		box.add_child(UiKit.label("Todos os materiais e espaços liberados", &"SmallLabel"))


static func levels_panel(site: String) -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var data: Dictionary = Database.progression.nature_sites[site]
		var info := GameState.progress.nature_info(site)
		box.add_child(UiKit.label("Recolha coletas para ganhar XP neste local", &"SmallLabel"))
		for i in data.levels.size():
			var milestone: Dictionary = data.levels[i]
			var card := UiKit.card(box, &"ReadyCardPanel" if info.level > i else &"CardPanel")
			card.name = "NatureLevel_%s_%d" % [site, i + 1]
			var row := UiKit.hbox(6)
			row.add_child(UiKit.icon(Database.item_icon(str(milestone.materials[0]))))
			row.add_child(UiKit.fill_label("Nível %d · %s" % [i + 1, milestone.label], &"SmallLabel"))
			card.add_child(row)
			card.add_child(UiKit.label("Liberado" if info.level > i else ("Desbloquear: %d moedas" % int(Database.progression.upgrades[data.level_upgrades[0]].cost) if i == 0 else "Faltam %d XP · %d coleta(s)" % [maxi(0, int(milestone.xp) - int(info.total)), ceili(float(maxi(0, int(milestone.xp) - int(info.total))) / int(data.xp_per_collection))]), &"SmallLabel"))
		box.add_child(UiKit.button("Ir ao local", func() -> void:
			Events.sheet_close_requested.emit()
			Events.world_requested.emit("nature", "place:" + site), &"PrimaryButton")))


## Receitas existentes que usam os materiais deste local, com destino direto à estação.
static func refining_panel(site: String) -> Control:
	var box := UiKit.vbox(6)
	for id: String in Database.recipes:
		var recipe: Dictionary = Database.recipes[id]
		var uses := false
		for item: String in recipe.inputs:
			if item in Database.progression.nature_sites[site].resources:
				uses = true
		if not uses:
			continue
		var place := Database.place_with_panel("station:" + str(recipe.station))
		var ingredients := UiKit.flow(4)
		for item: String in recipe.inputs:
			ingredients.add_child(UiKit.chip(Database.item_icon(item), str(int(recipe.inputs[item]))))
		box.add_child(ingredients)
		var button := UiKit.button("%s ×%d · %s" % [Database.item_name(recipe.output), int(recipe.qty), Database.stations[recipe.station].name], func() -> void:
			Events.sheet_close_requested.emit()
			Events.world_requested.emit(place[0], "place:" + place[1]), &"", Database.item_icon(recipe.output))
		button.add_theme_font_size_override("font_size", 16)
		button.name = "RefineRecipe_" + id
		button.add_theme_constant_override("icon_max_width", 32)
		box.add_child(button)
	return box


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
	extras.custom_minimum_size.y = 18
	for bonus: String in route.rewards.get("items", {}):
		if bonus != primary:
			extras.add_child(UiKit.icon(Database.item_icon(bonus), 16))
			var amount := UiKit.short_label("+%d" % int(route.rewards.items[bonus]), &"SmallLabel")
			amount.add_theme_font_size_override("font_size", 13)
			extras.add_child(amount)
	column.add_child(extras)
	var level := route_level(route_id)
	var caption := "Nível %d" % level
	var tool_label := UiKit.label(caption, &"SmallLabel", UiKit.BAD if GameState.progress.nature_level(site) < level else null)
	tool_label.name = "RequiredLevel_" + item
	tool_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tool_label.add_theme_font_size_override("font_size", 13)
	column.add_child(tool_label)


static func _slot(parent: HBoxContainer, site: String, index: int) -> void:
	var entry := GameState.gathering_entry(site, index)
	var remaining := GameState.gathering_remaining(site, index)
	var card := UiKit.card(parent, &"ReadyCardPanel" if not entry.is_empty() and remaining == 0 else &"CardPanel")
	card.add_theme_constant_override("separation", 4)
	if index >= GameState.gathering_slots(site):
		var title := UiKit.label("Nível %d" % (index + 1), &"SmallLabel")
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(title)
		var target := int(Database.progression.nature_sites[site].levels[index].xp)
		var missing := maxi(0, target - int(GameState.progress.nature_xp.get(site, 0)))
		var needed := UiKit.label("%d XP" % missing, &"SmallLabel")
		needed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(needed)
		var how := UiKit.label("Coletando", &"SmallLabel")
		how.add_theme_font_size_override("font_size", 13)
		how.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(how)
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
