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
		_progress(box, site)
		box.add_child(UiKit.label("Materiais", &"SectionLabel"))
		for item: String in data.resources:
			var route_id := focus_route if item == selected and Database.gathering_site(focus_route) == site else best_route(item)
			_material(box, site, item, route_id)
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
	heading.add_child(UiKit.icon_button(null, func() -> void:
		Events.sheet_requested.emit("Evolução · " + str(data.name), levels_panel(site)), 44, "?"))
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
		var button := UiKit.button("%s ×%d · %s" % [Database.item_name(Database.recipe_output(recipe)), int(recipe.get("qty", 1)), Database.stations[recipe.station].name], func() -> void:
			Events.sheet_close_requested.emit()
			Events.world_requested.emit(place[0], "place:" + place[1]), &"", Database.item_icon(Database.recipe_output(recipe)))
		button.add_theme_font_size_override("font_size", 16)
		button.name = "RefineRecipe_" + id
		button.add_theme_constant_override("icon_max_width", 32)
		box.add_child(button)
	return box


## Material para coletar, no mesmo molde das receitas das estações: ícone, tempo, nível e botão.
static func _material(parent: VBoxContainer, site: String, item: String, route_id: String) -> void:
	var route: Dictionary = Database.progression.activities[route_id]
	var primary := item if route.rewards.get("items", {}).has(item) else str(route.rewards.items.keys()[0])
	var body := UiKit.card(parent)
	var top := UiKit.hbox(10)
	top.add_child(UiKit.icon(Database.item_icon(primary), 64))
	var info := UiKit.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UiKit.label("%s  x%d" % [Database.item_name(primary), int(route.rewards.items[primary])]))
	var details := UiKit.flow()
	details.add_child(UiKit.chip(UiKit.ui_icon("timer"), TimeText.short(int(route.seconds))))
	for bonus: String in route.rewards.get("items", {}):
		if bonus != primary:
			details.add_child(UiKit.chip(Database.item_icon(bonus), "+%d" % int(route.rewards.items[bonus]), UiKit.GOOD))
	info.add_child(details)
	top.add_child(info)
	body.add_child(top)
	var level := route_level(route_id)
	var locked := GameState.progress.nature_level(site) < level
	var button := UiKit.secondary("Coletar", func() -> void:
		_result(GameState.start_next_gathering(site, route_id, item), "Coleta iniciada!"), null, true)
	button.name = "Material_" + item
	button.disabled = GameState.next_gathering_error(site, route_id, item) != ""
	if locked:
		# Nível ainda não alcançado: cartão apagado e cadeado no lugar do botão (que fica escondido e desabilitado).
		body.get_parent().modulate.a = 0.55
		var hint := UiKit.lock_hint("Nível %d" % level)
		hint.name = "RequiredLevel_" + item
		body.add_child(hint)
		button.visible = false
	else:
		var tool_label := UiKit.label("Nível %d" % level, &"SmallLabel")
		tool_label.name = "RequiredLevel_" + item
		body.add_child(tool_label)
	body.add_child(button)


## Espaço de coleta, igual ao das estações: ícone, tempo e barra; fechado mostra o que falta.
static func _slot(parent: HBoxContainer, site: String, index: int) -> void:
	var entry := GameState.gathering_entry(site, index)
	var remaining := GameState.gathering_remaining(site, index)
	if index >= GameState.gathering_slots(site):
		parent.add_child(_locked_slot(site, index))
		return
	if entry.is_empty():
		parent.add_child(SheetBuilder.slot_frame(null, "Livre", 0.0, false, true))
		return
	var route: Dictionary = Database.progression.activities[str(entry.id)]
	var items: Dictionary = entry.get("rewards", route.rewards).get("items", {})
	var item := str(entry.get("resource", ""))
	if not items.has(item):
		item = str(items.keys()[0])
	var text := "Pronto! · ×%d" % int(items[item]) if remaining == 0 else "%s · ×%d" % [TimeText.short(remaining), int(items[item])]
	var duration := maxf(1.0, float(entry.ready_at) - float(entry.started_at))
	var frame := SheetBuilder.slot_frame(Database.item_icon(item), text, 1.0 - remaining / duration, remaining == 0, false)
	(frame.get_child(0).get_child(0) as Control).name = "GatherItem_%s_%d" % [site, index]
	parent.add_child(frame)


## Espaço ainda fechado: nível e XP que faltam (aqui o espaço abre usando, não comprando).
static func _locked_slot(site: String, index: int) -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"CardPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.modulate.a = 0.75
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var box := UiKit.vbox(4)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := UiKit.label("Nv %d" % (index + 1), &"TitleLabel")
	title.add_theme_font_size_override("font_size", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(0, 64)
	box.add_child(title)
	var missing := maxi(0, int(Database.progression.nature_sites[site].levels[index].xp) - int(GameState.progress.nature_xp.get(site, 0)))
	var chip := UiKit.chip(UiKit.ui_icon("xp"), str(missing))
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(chip)
	panel.add_child(box)
	return panel


static func _result(error: String, done: String) -> void:
	Events.toast_requested.emit(error if error != "" else done)
