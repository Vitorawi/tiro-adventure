class_name StationTray
extends RefCounted
## Bandejas de estações, criações e Natureza (Etapa 08): receitas/materiais em grade, detalhe embaixo
## e um único botão principal. Só chamam o que já existe (`GameState.cook/start_next_gathering`).
## Montam no modo "pick" do `ActionTray`; o painel antigo continua em "Ver tudo".

## Última receita / material usados nesta sessão (voltam selecionados). Não é salvo.
static var last_recipe := {}
static var last_material := {}


# --- Estações de produção (fogão, liquidificador, bancada, moinho, queijaria, costura, ateliê) ---

## Estação comum: bolinhas da fila, receitas em grade e detalhe com "Cozinhar"/"Fazer"/"Costurar".
## `focus` = receita pedida pelo "Ir" (já selecionada). Criações (`kind: "animal"`) vão para `animal`.
static func station(room: RoomView, station_id: String, anchor: Dictionary, focus: String = "") -> ActionTray:
	if str(Database.stations[station_id].get("kind", "")) == "animal":
		return animal(room, station_id, anchor)
	var ids := recipe_ids(station_id)
	var entries: Array[Dictionary] = []
	for id in ids:
		var recipe: Dictionary = Database.recipes[id]
		entries.append({
			"id": id,
			"icon": Database.item_icon(Database.recipe_output(recipe)),
			"caption": TimeText.short(int(recipe.get("seconds", 60))),
			"badge_fn": func() -> String: return "!" if _missing(id) else "",
			"error": GameState.content_error("recipe", id, recipe),
			"error_fn": func() -> String: return GameState.content_error("recipe", id, recipe),
			"highlight": id == focus,
		})
	var selected := focus if focus in ids else str(last_recipe.get(station_id, ""))
	if not selected in ids:
		selected = _first_open(entries)
	var options := {
		"mode": "pick",
		"title": str(Database.stations[station_id].name),
		"selected": selected,
		"on_select": func(id: String) -> void: last_recipe[station_id] = id,
		"header": _header(station_id),
		"detail": func(id: String) -> Control: return recipe_detail(station_id, id),
		"below": anchor.below,
		"footer_ghost": {"text": "Ver tudo", "action": func() -> void:
			Events.sheet_requested.emit(str(Database.stations[station_id].name), SheetBuilder.station_view(station_id, focus))},
	}
	return ActionTray.open(room, anchor.above, entries, options)


## Receitas da estação: as que já dá para fazer primeiro (na ordem do JSON), as fechadas no fim.
static func recipe_ids(station_id: String) -> Array[String]:
	var open: Array[String] = []
	var closed: Array[String] = []
	for id in Database.recipes_for(station_id):
		if GameState.content_error("recipe", id, Database.recipes[id]) == "":
			open.append(id)
		else:
			closed.append(id)
	return open + closed


static func _first_open(entries: Array[Dictionary]) -> String:
	for entry in entries:
		if str(entry.get("error", "")) == "":
			return str(entry.id)
	return str(entries[0].id) if not entries.is_empty() else ""


## Falta algum ingrediente (e a receita está aberta)?
static func _missing(recipe_id: String) -> bool:
	return GameState.content_error("recipe", recipe_id, Database.recipes[recipe_id]) == "" \
			and not GameState.inventory.has_all(GameState.recipe_inputs(recipe_id))


## Cabeçalho: bolinhas da fila + ampliações ("+") e "Pegar tudo (N)" quando algo fica pronto.
static func _header(station_id: String) -> Control:
	var box := SheetBuilder.LiveBox.new(func(parent: VBoxContainer) -> void:
		var ready := GameState.station(station_id).ready_count(GameState.now())
		parent.add_child(SheetBuilder.slot_strip(SheetBuilder.station_slot_row(station_id)))
		if ready > 0:
			parent.add_child(_collect_button(station_id, ready)))
	box.name = "Header"
	return box


static func _collect_button(station_id: String, ready: int) -> Button:
	var collect := UiKit.secondary("Pegar tudo (%d)" % ready, func() -> void:
		Events.items_gained.emit(GameState.collect(station_id), 0, Vector2(-1.0, -1.0)), null, true)
	collect.name = "CollectAll_" + station_id
	return collect


## Detalhe da receita escolhida: nome, tempo/saída, ingredientes tocáveis e o botão principal.
static func recipe_detail(station_id: String, recipe_id: String) -> Control:
	var box := UiKit.vbox(6)
	box.name = "RecipeDetail"
	if not Database.recipes.has(recipe_id):
		return box
	var recipe: Dictionary = Database.recipes[recipe_id]
	var output: String = Database.recipe_output(recipe)
	var qty := GameState.recipe_quantity(recipe_id)
	var title := UiKit.fill_label(Database.item_name(output) + (" ×%d" % qty if qty > 1 else ""), &"SectionLabel")
	title.name = "RecipeName"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var out := UiKit.flow(2)
	out.add_child(UiKit.chip(UiKit.ui_icon("timer"), TimeText.short(int(recipe.get("seconds", 60)))))
	if not recipe.has("output_collection"):
		out.add_child(UiKit.chip(Database.item_icon(output), "×%d" % qty))
	for effect in UiKit.effect_chip_list(Database.items.get(output, {}).get("feed", {})):
		out.add_child(effect)
	box.add_child(out)
	var inputs: Dictionary = GameState.recipe_inputs(recipe_id)
	if not inputs.is_empty():
		var needs := UiKit.flow(2)
		needs.name = "Ingredients"
		for item_id: String in inputs:
			needs.add_child(ProgressionUi.item_chip(item_id, int(inputs[item_id])))
		box.add_child(needs)
	var locked := GameState.content_error("recipe", recipe_id, recipe)
	if locked != "":
		box.add_child(UiKit.lock_hint(locked, TaskHelp.open.bind("recipe", recipe_id, int(recipe.get("qty", 1)))))
		return box
	var error := GameState.cook_error(recipe_id)
	var verb := str(Database.stations.get(station_id, {}).get("action_label", "Fazer"))
	var action := UiKit.primary(error if error != "" else verb, func() -> void: _cook(station_id, recipe_id))
	action.name = "Cook"
	action.disabled = error != ""
	box.add_child(action)
	return box


## Põe na fila; a bolinha nova acende e o ícone da receita voa da grade até ela. A receita continua selecionada.
static func _cook(station_id: String, recipe_id: String) -> void:
	var reason := GameState.cook(recipe_id)
	if reason != "":
		Events.toast_requested.emit(reason)
		return
	var tray := ActionTray.current
	if not is_instance_valid(tray):
		return
	last_recipe[station_id] = recipe_id
	var icon := Database.item_icon(Database.recipe_output(Database.recipes[recipe_id]))
	var from := tray.item_center(recipe_id)
	_light_new_slot(tray, station_id, icon, from)


## O cabeçalho se refaz no fim do quadro: espera e acende a bolinha da última vaga ocupada.
static func _light_new_slot(tray: ActionTray, station_id: String, icon: Texture2D, from: Vector2) -> void:
	var tree := tray.get_tree()
	await tree.process_frame
	await tree.process_frame
	if not is_instance_valid(tray) or tray.closing:
		return
	var index := GameState.station(station_id).queue.size() - 1
	var dot := tray.find_in_panel("Slot_%d" % index) as Control
	if dot == null:
		return
	Motion.pop_in(dot)
	tray.fly_icon(icon, from, dot.global_position + dot.size / 2.0)


# --- Criações (galinheiro, curral) ------------------------------------------------------

## Sem animais: abrigo vazio e "Comprar animais". Com animais: a fileirinha deles, a bolinha da produção
## e um item de ração (tocar alimenta, a bandeja fica um instante para mostrar a bolinha e fecha).
static func animal(room: RoomView, station_id: String, anchor: Dictionary) -> ActionTray:
	var data: Dictionary = Database.stations[station_id]
	var buy := func() -> void: SheetBuilder.open_animal_shop(station_id)
	var see_all := {"text": "Ver tudo", "action": func() -> void:
		Events.sheet_requested.emit(str(data.name), SheetBuilder.station_view(station_id))}
	if GameState.animal_count(station_id) == 0:
		var empty := UiKit.vbox(6)
		empty.name = "EmptyShelter"
		var note := UiKit.label("Abrigo vazio", &"SectionLabel")
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_child(note)
		var shop := UiKit.primary("Comprar animais", buy)
		shop.name = "BuyAnimals"
		empty.add_child(shop)
		return ActionTray.open(room, anchor.above, [], {"mode": "pick", "title": str(data.name), "header": empty, "below": anchor.below, "footer_ghost": see_all})
	var entries: Array[Dictionary] = []
	for id in Database.recipes_for(station_id):
		var recipe: Dictionary = Database.recipes[id]
		var inputs: Dictionary = GameState.recipe_inputs(id)
		var first: String = inputs.keys()[0] if not inputs.is_empty() else ""
		entries.append({
			"id": id,
			"icon": Database.item_icon(first) if first != "" else Database.item_icon(Database.recipe_output(recipe)),
			"caption_fn": func() -> String:
				var need := int(GameState.recipe_inputs(id).get(first, 0))
				return "%d/%d" % [GameState.inventory.count(first), need],
			"error": GameState.content_error("recipe", id, recipe),
			"help": TaskHelp.open.bind("recipe", id, int(recipe.get("qty", 1))),
			"keep_open": true,
			"tap": func() -> String:
				var tray := ActionTray.current
				var from := tray.item_center(id)
				var reason := GameState.cook(id)
				if reason == "":
					tray.close_after(1.5)
					_light_new_slot(tray, station_id, Database.item_icon(first), from)
				return reason,
		})
	var header := SheetBuilder.LiveBox.new(func(parent: VBoxContainer) -> void:
		var herd := UiKit.hbox(4)
		herd.name = "Herd"
		herd.alignment = BoxContainer.ALIGNMENT_CENTER
		for animal_id: String in GameState.animal_roster(station_id):
			herd.add_child(UiKit.icon(load(Database.animals[animal_id].sprite), 32))
		parent.add_child(herd)
		var ready := GameState.station(station_id).ready_count(GameState.now())
		parent.add_child(SheetBuilder.slot_strip(SheetBuilder.station_slot_row(station_id)))
		if ready > 0:
			parent.add_child(_collect_button(station_id, ready))
		var shop := UiKit.ghost("Comprar animais", buy)
		shop.name = "BuyAnimals"
		parent.add_child(shop))
	header.name = "Header"
	return ActionTray.open(room, anchor.above, entries, {"header": header, "below": anchor.below, "footer_ghost": see_all, "auto_close": 6.0})


# --- Natureza (Bosque, Caverna, Prado) --------------------------------------------------

## Local aberto: 3 bolinhas de coleta, nível com anel de XP e "?", materiais em grade e detalhe com "Buscar".
static func nature(room: RoomView, site: String, anchor: Dictionary, focus: String = "") -> ActionTray:
	var data: Dictionary = Database.progression.nature_sites[site]
	var entries: Array[Dictionary] = []
	for item: String in data.resources:
		var route_id := NatureUi.best_route(item)
		var level := NatureUi.route_level(route_id)
		var locked := GameState.progress.nature_level(site) < level
		var route: Dictionary = Database.progression.activities[route_id]
		entries.append({
			"id": item,
			"icon": Database.item_icon(_primary_item(route, item)),
			"caption": "Nível %d" % level if locked else TimeText.short(int(route.seconds)),
			"caption_fn": func() -> String:
				var needed := NatureUi.route_level(NatureUi.best_route(item))
				return "Nível %d" % needed if GameState.progress.nature_level(site) < needed else TimeText.short(int(Database.progression.activities[NatureUi.best_route(item)].seconds)),
			"error": "Nível %d" % level if locked else "",
			"error_fn": func() -> String:
				var needed := NatureUi.route_level(NatureUi.best_route(item))
				return "Nível %d" % needed if GameState.progress.nature_level(site) < needed else "",
			"highlight": item == focus,
		})
	var selected := focus if focus in data.resources else str(last_material.get(site, ""))
	if not selected in data.resources:
		selected = _first_open(entries)
	var options := {
		"mode": "pick",
		"title": str(data.name),
		"selected": selected,
		"on_select": func(id: String) -> void: last_material[site] = id,
		"header": _nature_header(site),
		"detail": func(id: String) -> Control: return material_detail(site, id),
		"below": anchor.below,
		"footer_ghost": {"text": "Ver tudo", "action": func() -> void:
			Events.sheet_requested.emit(str(data.name), NatureUi.panel(site))},
	}
	return ActionTray.open(room, anchor.above, entries, options)


static func _primary_item(route: Dictionary, item: String) -> String:
	return item if route.rewards.get("items", {}).has(item) else str(route.rewards.items.keys()[0])


static func _nature_header(site: String) -> Control:
	var data: Dictionary = Database.progression.nature_sites[site]
	var box := SheetBuilder.LiveBox.new(func(parent: VBoxContainer) -> void:
		var ready := GameState.gathering_ready_count(site)
		var slots := SheetBuilder.slot_flow()
		for index in 3:
			NatureUi.slot(slots, site, index)
		parent.add_child(SheetBuilder.slot_strip(slots))
		if ready > 0:
			var collect := UiKit.secondary("Pegar tudo (%d)" % ready, func() -> void:
				var error := GameState.collect_gathering_all(site)
				if error == "":
					Events.items_gained.emit(GameState.last_gain, GameState.last_coins, Vector2(-1.0, -1.0)), null, true)
			collect.name = "CollectAll_" + site
			parent.add_child(collect)
		var info := GameState.progress.nature_info(site)
		var level_row := UiKit.hbox(8)
		level_row.name = "LevelRow"
		level_row.alignment = BoxContainer.ALIGNMENT_CENTER
		var ring := RingProgress.new()
		ring.name = "LevelRing"
		ring.progress = 1.0 if info.max else float(info.xp) / maxf(1.0, float(info.needed))
		ring.texture = Database.item_icon(str(data.resources[0]))
		level_row.add_child(ring)
		var level_label := UiKit.short_label("Nível %d" % info.level, &"SectionLabel")
		level_label.name = "NatureLevel"
		level_row.add_child(level_label)
		var help := UiKit.icon_button(null, func() -> void:
			Events.sheet_requested.emit("Evolução · " + str(data.name), NatureUi.levels_panel(site)), 44, "?")
		help.name = "LevelsHelp"
		level_row.add_child(help)
		parent.add_child(level_row))
	box.name = "Header"
	return box


## Detalhe do material: tempo, extras e XP; "Buscar" começa na primeira vaga livre.
static func material_detail(site: String, item: String) -> Control:
	var box := UiKit.vbox(6)
	box.name = "MaterialDetail"
	if item == "":
		return box
	var data: Dictionary = Database.progression.nature_sites[site]
	var route_id := NatureUi.best_route(item)
	var route: Dictionary = Database.progression.activities[route_id]
	var primary := _primary_item(route, item)
	var title := UiKit.fill_label("%s ×%d" % [Database.item_name(primary), int(route.rewards.items[primary])], &"SectionLabel")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var chips := UiKit.flow(2)
	chips.add_child(UiKit.chip(UiKit.ui_icon("timer"), TimeText.short(int(route.seconds))))
	for bonus: String in route.rewards.get("items", {}):
		if bonus != primary:
			chips.add_child(UiKit.chip(Database.item_icon(bonus), "+%d" % int(route.rewards.items[bonus]), UiKit.GOOD))
	chips.add_child(UiKit.chip(UiKit.ui_icon("xp"), "+%d XP" % int(data.xp_per_collection)))
	box.add_child(chips)
	var level := NatureUi.route_level(route_id)
	if GameState.progress.nature_level(site) < level:
		var hint := UiKit.lock_hint("Nível %d" % level)
		hint.name = "RequiredLevel_" + item
		box.add_child(hint)
		return box
	var error := GameState.next_gathering_error(site, route_id, item)
	var action := UiKit.primary(error if error != "" else "Buscar", func() -> void:
		var reason := GameState.start_next_gathering(site, route_id, item)
		if reason != "":
			Events.toast_requested.emit(reason))
	action.name = "Material_" + item
	action.disabled = error != ""
	box.add_child(action)
	return box
