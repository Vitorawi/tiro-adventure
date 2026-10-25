class_name NatureUi
extends RefCounted
## Um toque coleta; usar cada região aumenta seu XP e libera materiais/espaços.


static func open(site: String = "trees", resource: String = "", focus_route: String = "") -> void:
	var data: Dictionary = Database.progression.nature_sites[site]
	Events.sheet_requested.emit(data.name, panel(site, resource, focus_route))


## Rota escolhida por material (só nesta sessão; não vai para o save). Escolher não começa a busca.
static var chosen: Dictionary = {}


## Rotas do material que já valem, da mais curta para a mais longa.
static func eligible_routes(resource: String) -> Array[String]:
	var result: Array[String] = []
	for id: String in Database.progression.nature_resources[resource].routes:
		if GameState.requirement_error(Database.progression.activities[id].get("requirements", {})) == "":
			result.append(id)
	result.sort_custom(func(a: String, b: String) -> bool:
		return int(Database.progression.activities[a].seconds) < int(Database.progression.activities[b].seconds))
	return result


## Rota usada pelo material: a escolhida (se ainda vale) ou a padrão, a elegível mais curta.
static func best_route(resource: String) -> String:
	var picked := str(chosen.get(resource, ""))
	if picked != "" and picked in eligible_routes(resource):
		return picked
	return GameState.default_gathering_route(resource)


## Guarda a escolha do jogador para o material. Rota bloqueada ou de outro material é recusada.
static func choose_route(resource: String, route_id: String) -> bool:
	if not Database.progression.nature_resources.has(resource) or not route_id in eligible_routes(resource):
		return false
	chosen[resource] = route_id
	return true


static func clear_choices() -> void:
	chosen.clear()


static func choice_count() -> int:
	return chosen.size()


## XP local que a rota dá ao local de busca.
static func route_xp(route_id: String) -> int:
	return GameState.route_nature_xp(route_id)


## Escolha explícita de duração: um botão por rota elegível (tempo), só quando há mais de uma.
## `changed` roda depois de guardar a escolha, para o chamador redesenhar.
static func route_choice(resource: String, changed: Callable) -> Control:
	var routes := eligible_routes(resource)
	if routes.size() < 2:
		return null
	var entries: Array[Dictionary] = []
	for id: String in routes:
		entries.append({"id": id, "text": TimeText.short(int(Database.progression.activities[id].seconds))})
	var row := UiKit.segmented(entries, best_route(resource), func(id: String) -> void:
		if choose_route(resource, id):
			changed.call())
	row.name = "RouteChoice_" + resource
	return row


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
			choose_route(resource, route_id)
			_open_route_view(site, resource, route_id)
			return
	for item: String in Database.progression.activities[route_id].rewards.get("items", {}):
		if item in Database.progression.nature_sites[site].resources:
			choose_route(item, route_id)
			_open_route_view(site, item, route_id)
			return
	_open_route_view(site, "", route_id)


## O Ir usa a mesma bandeja do toque no mundo; Ver tudo continua sendo a consulta completa.
static func _open_route_view(site: String, resource: String, route_id: String) -> void:
	for room: Node in (Engine.get_main_loop() as SceneTree).get_nodes_in_group("room_views"):
		if room is RoomView and room.is_visible_in_tree() and room.can_open_nature_tray(site):
			Events.sheet_close_requested.emit()
			room.open_nature_tray(site, resource)
			return
	open(site, resource, route_id)


static func panel(site: String = "trees", resource: String = "", focus_route: String = "") -> Control:
	var data: Dictionary = Database.progression.nature_sites[site]
	var selected: String = resource if resource in data.resources else str(data.resources[0])
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var level := GameState.progress.nature_level(site)
		if level == 0:
			box.add_child(UiKit.lock_hint("Ainda não aberto"))
			ProgressionUi.upgrade_card(box, str(data.level_upgrades[0]))
			return
		var ready := GameState.gathering_ready_count(site)
		var slots := SheetBuilder.slot_flow()
		for index in 3:
			slot(slots, site, index)
		box.add_child(SheetBuilder.slot_strip(slots, "Pegar tudo (%d)" % ready if ready > 0 else "", func() -> void:
			var before := int(GameState.progress.nature_xp.get(site, 0))
			var previous_level := GameState.progress.nature_level(site)
			var error := GameState.collect_gathering_all(site)
			var level_now := GameState.progress.nature_level(site)
			if error == "":
				Events.items_gained.emit(GameState.last_gain, GameState.last_coins, Vector2(-1.0, -1.0))
			_result(error, "%s nível %d!" % [data.name, level_now] if level_now > previous_level else "+%d XP em %s" % [int(GameState.progress.nature_xp.get(site, 0)) - before, data.name]), "CollectAll_" + site))
		_progress(box, site)
		box.add_child(UiKit.section("Materiais"))
		for item: String in data.resources:
			var route_id := best_route(item)
			_material(box, site, item, route_id)
			var choice := route_choice(item, func() -> void: (box as SheetBuilder.LiveBox).refresh())
			if choice != null:
				box.add_child(choice)
		var refine := UiKit.soft("Refinar materiais", func() -> void:
			Events.sheet_requested.emit("Refinar · " + str(data.name), refining_panel(site)))
		refine.name = "Refine_" + site
		box.add_child(refine))


static func _progress(box: VBoxContainer, site: String) -> void:
	var data: Dictionary = Database.progression.nature_sites[site]
	var info := GameState.progress.nature_info(site)
	var heading := UiKit.hbox(6)
	var title := UiKit.fill_label(("Nível %d ★" % info.level) if info.max else "Nível %d · %d/%d XP" % [info.level, info.xp, info.needed], &"StrongLabel")
	title.name = "NatureProgress_" + site
	heading.add_child(title)
	heading.add_child(UiKit.ctl_button("help", func() -> void:
		Events.sheet_requested.emit("Evolução · " + str(data.name), levels_panel(site)), 40))
	box.add_child(heading)
	box.add_child(UiKit.bar(100.0 if info.max else 100.0 * info.xp / maxi(1, int(info.needed)), Palette.SKY, 10))
	if not info.max:
		box.add_child(UiKit.label("Próximo: " + str(data.levels[info.level].label), &"SmallLabel"))
		box.add_child(UiKit.label("Faltam %d XP" % int(info.remaining), &"SmallLabel"))
	else:
		box.add_child(UiKit.label("Tudo liberado", &"SmallLabel"))


static func levels_panel(site: String) -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var data: Dictionary = Database.progression.nature_sites[site]
		var info := GameState.progress.nature_info(site)
		box.add_child(UiKit.steps(data.levels.size(), int(info.level)))
		var cards := UiKit.list_card(box)
		for i in data.levels.size():
			var milestone: Dictionary = data.levels[i]
			var done: bool = info.level > i
			var chips: Array[Control] = []
			if done:
				chips.append(UiKit.chip(null, "Liberado", null, "have"))
			elif i == 0:
				chips.append(UiKit.chip(UiKit.ui_icon("coin"), "%d" % int(Database.progression.upgrades[data.level_upgrades[0]].cost), null, "prize"))
			else:
				chips.append(UiKit.chip(UiKit.ui_icon("xp"), "faltam %d" % maxi(0, int(milestone.xp) - int(info.total)), null, "time"))
			var row := UiKit.list_row(Database.item_icon(str(milestone.materials[0])), "Nível %d · %s" % [i + 1, milestone.label], chips, null, Callable(), done)
			(row.find_children("*", "Label", true, false)[0] as Label).theme_type_variation = &"StrongLabel"
			row.name = "NatureLevel_%s_%d" % [site, i + 1]
			cards.add_child(row)
		var go := UiKit.primary("Ir ao local", func() -> void:
			Events.sheet_close_requested.emit()
			Events.world_requested.emit("nature", "place:" + site))
		box.add_child(go))


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
		var button := UiKit.soft("%s ×%d · %s" % [Database.item_name(Database.recipe_output(recipe)), int(recipe.get("qty", 1)), Database.stations[recipe.station].name], func() -> void:
			Events.sheet_close_requested.emit()
			Events.world_requested.emit(place[0], "place:" + place[1]), Database.item_icon(Database.recipe_output(recipe)), true)
		button.name = "RefineRecipe_" + id
		button.add_theme_constant_override("icon_max_width", 32)
		box.add_child(button)
	return box


## Material para buscar, em linha de lista: ícone, tempo, bônus e botão (nível fechado = cadeado).
static func _material(parent: VBoxContainer, site: String, item: String, route_id: String) -> void:
	var route: Dictionary = Database.progression.activities[route_id]
	var primary := item if route.rewards.get("items", {}).has(item) else str(route.rewards.items.keys()[0])
	var chips: Array[Control] = [UiKit.chip(UiKit.ctl_icon("clock"), TimeText.short(int(route.seconds)))]
	for bonus: String in route.rewards.get("items", {}):
		if bonus != primary:
			chips.append(UiKit.chip(Database.item_icon(bonus), "+%d" % int(route.rewards.items[bonus]), UiKit.GOOD))
	chips.append(UiKit.chip(UiKit.ui_icon("xp"), "+%d XP" % route_xp(route_id)))
	var level := route_level(route_id)
	var locked := GameState.progress.nature_level(site) < level
	var button := UiKit.small_go("Buscar", func() -> void:
		_result(GameState.start_next_gathering(site, route_id, item), ""))
	button.name = "Material_" + item
	button.disabled = GameState.next_gathering_error(site, route_id, item) != ""
	button.custom_minimum_size.x = 88
	var row := UiKit.list_row(Database.item_icon(primary), "%s ×%d" % [Database.item_name(primary), int(route.rewards.items[primary])], chips, null if locked else button)
	(row.find_children("*", "Label", true, false)[0] as Label).theme_type_variation = &"StrongLabel"
	parent.add_child(row)
	var footer := row.get_child(0) as VBoxContainer
	if locked:
		# Nível ainda não alcançado: linha apagada e cadeado no lugar do botão (que fica escondido e desabilitado).
		row.modulate.a = 0.55
		var hint := UiKit.lock_hint("Nível %d" % level)
		hint.name = "RequiredLevel_" + item
		footer.add_child(hint)
		button.visible = false
		footer.add_child(button)


## Espaço de coleta, igual ao das estações: bolinha com ícone e tempo; fechado mostra o nível.
static func slot(parent: Control, site: String, index: int) -> void:
	var entry := GameState.gathering_entry(site, index)
	var remaining := GameState.gathering_remaining(site, index)
	if index >= GameState.gathering_slots(site):
		parent.add_child(_locked_slot(site, index))
		return
	if entry.is_empty():
		parent.add_child(SheetBuilder.slot_frame(null, "", 0.0, false, true))
		return
	var route: Dictionary = Database.progression.activities[str(entry.id)]
	var items: Dictionary = entry.get("rewards", route.rewards).get("items", {})
	var item := str(entry.get("resource", ""))
	if not items.has(item):
		item = str(items.keys()[0])
	var duration := maxf(1.0, float(entry.ready_at) - float(entry.started_at))
	var frame := SheetBuilder.slot_frame(Database.item_icon(item), "Pronto!" if remaining == 0 else TimeText.short(remaining), 1.0 - remaining / duration, remaining == 0, false)
	frame.find_child("Icon", true, false).name = "GatherItem_%s_%d" % [site, index]
	parent.add_child(frame)


## Espaço ainda fechado: cadeado e o nível (aqui o espaço abre usando, não comprando).
static func _locked_slot(site: String, index: int) -> Control:
	var level := GameState.progress.nature_slot_level(site, index - 1) if index > 0 else 1
	return UiKit.slot_dot(SlotDot.LEVEL, null, 0.0, "Nível %d" % level)


static func _result(error: String, done: String) -> void:
	if error != "" or done != "":
		Events.toast_requested.emit(error if error != "" else done)
