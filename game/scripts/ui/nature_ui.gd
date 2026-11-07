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
	var selected := best_route(resource)
	var row := UiKit.hbox(CodexUi.FILTER_GAP)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for id: String in routes:
		var text := TimeText.short(int(Database.progression.activities[id].seconds))
		var width := CodexUi.filter_width(text, 13, 28.0)
		var tab := CodexUi._filter_tile({"id": id, "text": text}, id == selected, Vector2(maxf(width, 64.0), CodexUi.FILTER_H), 13, func() -> void:
			if choose_route(resource, id):
				changed.call())
		row.add_child(tab)
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


## Painel do local em madeira ilustrada: espaços, nível, materiais (um cartão de papel cada) e "Refinar".
static func panel(site: String = "trees", resource: String = "", focus_route: String = "") -> Control:
	var data: Dictionary = Database.progression.nature_sites[site]
	var selected: String = resource if resource in data.resources else str(data.resources[0])
	var view := SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var level := GameState.progress.nature_level(site)
		if level == 0:
			ProgressionUi.upgrade_card(box, str(data.level_upgrades[0]), true)
			return
		var ready := GameState.gathering_ready_count(site)
		var slots: Array[Control] = []
		for index in 3:
			slots.append(StationWood.nature_slot(site, index))
		box.add_child(StationWood.tray_strip(StationWood.even_rows(slots)))
		if ready > 0:
			var collect := StepCardUi.go_button("Pegar tudo (%d)" % ready, func() -> void:
				var before := int(GameState.progress.nature_xp.get(site, 0))
				var previous_level := GameState.progress.nature_level(site)
				var error := GameState.collect_gathering_all(site)
				var level_now := GameState.progress.nature_level(site)
				if error == "":
					Events.items_gained.emit(GameState.last_gain, GameState.last_coins, Vector2(-1.0, -1.0))
				_result(error, "%s nível %d!" % [data.name, level_now] if level_now > previous_level else "+%d XP em %s" % [int(GameState.progress.nature_xp.get(site, 0)) - before, data.name]))
			collect.name = "CollectAll_" + site
			box.add_child(collect)
		_progress(box, site)
		var section := StationWood.text("Materiais", 16)
		section.name = "MaterialsSection"
		box.add_child(section)
		for item: String in data.resources:
			var route_id := best_route(item)
			var choice := route_choice(item, func() -> void: (box as SheetBuilder.LiveBox).refresh())
			_material(box, site, item, route_id, choice)
		var refine := WelcomeSheet._button("Refinar materiais", false, 220.0, "Refine_" + site, func() -> void:
			Events.sheet_requested.emit("Refinar · " + str(data.name), refining_panel(site)))
		refine.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(refine))
	view.set_meta("sheet_wood", true)
	view.set_meta("sheet_fit_content", true)
	return view


## Nível do local: título (XP até o próximo), "?" da evolução e barra de madeira.
static func _progress(box: VBoxContainer, site: String) -> void:
	var data: Dictionary = Database.progression.nature_sites[site]
	var info := GameState.progress.nature_info(site)
	var heading := UiKit.hbox(6)
	var title := StationWood.text(("Nível %d ★" % info.level) if info.max else "Nível %d · %d/%d XP" % [info.level, info.xp, info.needed], 18)
	title.name = "NatureProgress_" + site
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	heading.add_child(StepCardUi.help_button(func() -> void:
		Events.sheet_requested.emit("Evolução · " + str(data.name), levels_panel(site))))
	box.add_child(heading)
	box.add_child(StepCardUi.bar(1.0 if info.max else float(info.xp) / maxf(1.0, float(info.needed)), 22.0, "NatureBar"))
	var next := "Tudo liberado" if info.max else "Próximo: %s · faltam %d XP" % [str(data.levels[info.level].label), int(info.remaining)]
	var note := StationWood.text(next, 14)
	note.name = "NatureNext"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = 40.0
	box.add_child(note)


static func levels_panel(site: String) -> Control:
	var view := SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var data: Dictionary = Database.progression.nature_sites[site]
		var info := GameState.progress.nature_info(site)
		for i in data.levels.size():
			var milestone: Dictionary = data.levels[i]
			var done: bool = info.level > i
			var chips: Array[Control] = []
			if done:
				chips.append(StepCardUi.wood_chip(null, "Liberado", "have"))
			elif i == 0:
				chips.append(StepCardUi.wood_chip(UiKit.ui_icon("coin"), "%d" % int(Database.progression.upgrades[data.level_upgrades[0]].cost)))
			else:
				chips.append(StepCardUi.wood_chip(UiKit.ui_icon("xp"), "faltam %d" % maxi(0, int(milestone.xp) - int(info.total))))
			var item := str(milestone.materials[0])
			var card := SheetBuilder._wood_row(box, "NatureLevel_%s_%d" % [site, i + 1], SheetBuilder._plate(item, Database.item_icon(item), 48.0), "Nível %d · %s" % [i + 1, milestone.label], chips)
			if not done:
				card.modulate.a = 0.8
		var go := StepCardUi.go_button("Ir ao local", func() -> void:
			Events.sheet_close_requested.emit()
			Events.world_requested.emit("nature", "place:" + site))
		box.add_child(go))
	view.set_meta("sheet_wood", true)
	view.set_meta("sheet_fit_content", true)
	return view


## Receitas existentes que usam os materiais deste local, com destino direto à estação.
static func refining_panel(site: String) -> Control:
	var box := UiKit.vbox(8)
	box.set_meta("sheet_wood", true)
	box.set_meta("sheet_fit_content", true)
	for id: String in Database.recipes:
		var recipe: Dictionary = Database.recipes[id]
		var uses := false
		for item: String in recipe.inputs:
			if item in Database.progression.nature_sites[site].resources:
				uses = true
		if not uses:
			continue
		var place := Database.place_with_panel("station:" + str(recipe.station))
		var chips: Array[Control] = []
		for item: String in recipe.inputs:
			chips.append(StepCardUi.wood_chip(Database.item_icon(item), str(int(recipe.inputs[item]))))
		var output: String = Database.recipe_output(recipe)
		var go := WelcomeSheet._button("Ir", false, 76.0, "RefineRecipe_" + id, func() -> void:
			Events.sheet_close_requested.emit()
			Events.world_requested.emit(place[0], "place:" + place[1]))
		SheetBuilder._wood_row(box, "Refine_" + id, SheetBuilder._plate(output, Database.item_icon(output)), "%s ×%d · %s" % [Database.item_name(output), int(recipe.get("qty", 1)), Database.stations[recipe.station].name], chips, go)
	return box


## Material para buscar, em cartão de papel: prato, tempo, bônus, escolha de rota e botão (nível fechado = cadeado).
static func _material(parent: VBoxContainer, site: String, item: String, route_id: String, choice: Control = null) -> void:
	var route: Dictionary = Database.progression.activities[route_id]
	var primary := item if route.rewards.get("items", {}).has(item) else str(route.rewards.items.keys()[0])
	var chips: Array[Control] = [StepCardUi.wood_chip(UiKit.ctl_icon("clock"), TimeText.short(int(route.seconds)))]
	for bonus: String in route.rewards.get("items", {}):
		if bonus != primary:
			chips.append(StepCardUi.wood_chip(Database.item_icon(bonus), "+%d" % int(route.rewards.items[bonus]), "have"))
	chips.append(StepCardUi.wood_chip(UiKit.ui_icon("xp"), "+%d XP" % route_xp(route_id)))
	var level := route_level(route_id)
	var locked := GameState.progress.nature_level(site) < level
	var error := GameState.next_gathering_error(site, route_id, item)
	var action: Button = null
	var note: Control = null
	if error == "":
		action = WelcomeSheet._button("Buscar", false, 92.0, "Material_" + item, func() -> void:
			_result(GameState.start_next_gathering(site, route_id, item), ""))
	else:
		note = StepCardUi.lock_note(error, TaskHelp.open.bind("route", route_id), Database.item_icon(item))
		note.name = "Locked_Material_" + item
		note.set_meta("reason", error)
	var card := SheetBuilder._wood_row(parent, "Material_%s_Card" % item, SheetBuilder._plate(primary, Database.item_icon(primary)), "%s ×%d" % [Database.item_name(primary), int(route.rewards.items[primary])], chips, action, note)
	if choice != null:
		card.find_child("RowChips", true, false).get_parent().add_child(choice)
	if error != "" and locked:
		card.modulate.a = 0.55


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
