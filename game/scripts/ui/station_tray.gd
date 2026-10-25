class_name StationTray
extends RefCounted
## Bandejas de estações, criações e Natureza (Etapa 08): receitas/materiais em grade, detalhe embaixo
## e um único botão principal. Só chamam o que já existe (`GameState.cook/start_next_gathering`).
## Montam no modo "pick" do `ActionTray`; o painel antigo continua em "Ver tudo".

## Última receita / material usados nesta sessão (voltam selecionados). Não é salvo.
static var last_recipe := {}
static var last_material := {}
## Quantos lotes o jogador escolheu por receita nesta sessão (Preparar N). Não é salvo e nunca começa produção.
static var quantity := {}


# --- Estações de produção (fogão, liquidificador, bancada, moinho, queijaria, costura, ateliê) ---

## Estação comum: bolinhas da fila, receitas em grade e detalhe com "Cozinhar"/"Fazer"/"Costurar".
## `focus` = receita pedida pelo "Ir" (já selecionada). Criações (`kind: "animal"`) vão para `animal`.
static func station(room: RoomView, station_id: String, anchor: Dictionary, focus: String = "") -> ActionTray:
	if str(Database.stations[station_id].get("kind", "")) == "animal":
		return animal(room, station_id, anchor)
	var ids := recipe_ids(station_id, focus)
	var entries: Array[Dictionary] = []
	for id in ids:
		var recipe: Dictionary = Database.recipes[id]
		entries.append({
			"id": id,
			"icon": Database.item_icon(Database.recipe_output(recipe)),
			"caption": TimeText.short(int(recipe.get("seconds", 60))),
			"error": GameState.content_error("recipe", id, recipe),
			"error_fn": func() -> String: return GameState.content_error("recipe", id, recipe),
			"missing_fn": func() -> Texture2D: return missing_icon(id),
			"highlight": id == focus,
		})
	var selected := focus if focus in ids else str(last_recipe.get(station_id, ""))
	if not selected in ids:
		selected = _first_open(entries)
	var options := {
		"mode": "pick",
		"title": str(Database.stations[station_id].name),
		"icon": station_icon(station_id),
		"badge": mastery_badge(station_id),
		"selected": selected,
		"on_select": func(id: String) -> void: last_recipe[station_id] = id,
		"header": _header(station_id),
		"detail": func(id: String) -> Control: return recipe_detail(station_id, id),
		"below": anchor.below,
		"see_all": func() -> void:
			Events.sheet_requested.emit(str(Database.stations[station_id].name), SheetBuilder.station_view(station_id, focus)),
	}
	return ActionTray.open(room, anchor.above, entries, options)


## Ícone da estação (o mesmo da compra no mapa); sem ícone próprio, a bandeja abre só com o nome.
static func station_icon(station_id: String) -> Texture2D:
	return UiKit.ui_icon(str(Database.progression.upgrades.get(station_id, {}).get("icon", "")))


## Selo pequeno de maestria ao lado do nome: disquinho bronze/prata/ouro com o número do patamar (some no zero).
static func mastery_badge(station_id: String) -> Control:
	if not GameState.mastery_enabled(station_id) or not GameState.has_upgrade(station_id):
		return null
	var level := GameState.mastery_level(station_id)
	if level <= 0:
		return null
	var colors := [Palette.SEAL_BRONZE, Palette.SEAL_SILVER, Palette.SEAL_GOLD]
	var seal := PanelContainer.new()
	seal.name = "MasteryBadge"
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seal.custom_minimum_size = Vector2(22, 22)
	seal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	seal.add_theme_stylebox_override("panel", UiKit.surface(colors[mini(level, 3) - 1], 11))
	var number := UiKit.short_label(str(level), &"BadgeLabel", Palette.INK)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	seal.add_child(number)
	return seal


## O primeiro ingrediente que falta na mochila (para a marca vermelha do tile); null se tem tudo.
static func missing_icon(recipe_id: String) -> Texture2D:
	var inputs: Dictionary = GameState.recipe_inputs(recipe_id)
	for item_id: String in inputs:
		if GameState.inventory.count(item_id) < int(inputs[item_id]):
			return Database.item_icon(item_id)
	return null


## O destino do Ir vem primeiro; depois a comida do próximo crescimento, abertas e fechadas.
static func recipe_ids(station_id: String, focus: String = "") -> Array[String]:
	var open: Array[String] = []
	var closed: Array[String] = []
	var priority: Array[String] = []
	var foods: Array[String] = []
	for row: Dictionary in GameState.growth_info().requirements:
		if row.type != "feed" or bool(row.done): continue
		var food := str(row.item)
		if food == "favorite":
			if not GameState.favorite_found(): continue
			food = GameState.favorite_food()
		if food != "any": foods.append(food)
	for id in Database.recipes_for(station_id):
		if id == focus:
			priority.push_front(id)
		elif Database.recipe_output(Database.recipes[id]) in foods:
			priority.append(id)
		elif GameState.content_error("recipe", id, Database.recipes[id]) == "":
			open.append(id)
		else:
			closed.append(id)
	return priority + open + closed


static func _first_open(entries: Array[Dictionary]) -> String:
	for entry in entries:
		if str(entry.get("error", "")) == "":
			return str(entry.id)
	return str(entries[0].id) if not entries.is_empty() else ""


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


## Quantidade escolhida para a receita, sempre entre 1 e o máximo possível agora.
static func chosen_count(recipe_id: String) -> int:
	return clampi(int(quantity.get(recipe_id, 1)), 1, maxi(1, GameState.cook_max(recipe_id)))


## Detalhe da receita escolhida: nome + tempo, "entra → sai" e, embaixo (rodapé fixo `Actions`), a quantidade e
## o botão principal. Receita bloqueada ou fila cheia trocam o verde por um `lock_hint`.
static func recipe_detail(station_id: String, recipe_id: String) -> Control:
	var box := UiKit.vbox(10)
	box.name = "RecipeDetail"
	if not Database.recipes.has(recipe_id):
		return box
	var recipe: Dictionary = Database.recipes[recipe_id]
	var output: String = Database.recipe_output(recipe)
	var count := chosen_count(recipe_id)
	var qty := GameState.recipe_quantity(recipe_id) * count
	var heading := UiKit.hbox(8)
	var title := UiKit.fill_label(Database.item_name(output) + (" ×%d" % qty if qty > 1 else ""), &"StrongLabel")
	title.name = "RecipeName"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_child(title)
	var time_chip := UiKit.chip(UiKit.ctl_icon("clock"), TimeText.short(int(recipe.get("seconds", 60)) * count), null, "time")
	time_chip.name = "RecipeTime"
	heading.add_child(time_chip)
	box.add_child(heading)
	# entra → sai
	var flow := UiKit.flow(4)
	flow.name = "Ingredients"
	var inputs: Dictionary = GameState.cook_inputs(recipe_id, count)
	for item_id: String in inputs:
		flow.add_child(ProgressionUi.item_chip(item_id, int(inputs[item_id]), true))
	if not inputs.is_empty():
		flow.add_child(UiKit.ctl("arrow", 20, Palette.INK_FAINT))
	if not recipe.has("output_collection") and qty > 1:
		flow.add_child(UiKit.chip(Database.item_icon(output), "×%d" % qty, null, "prize"))
	for effect in UiKit.effect_chip_list(Database.items.get(output, {}).get("feed", {})):
		flow.add_child(effect)
	box.add_child(flow)
	var actions := UiKit.hbox(8)
	actions.name = "Actions"
	box.add_child(actions)
	var locked := GameState.content_error("recipe", recipe_id, recipe)
	if locked != "":
		actions.add_child(UiKit.lock_hint(locked, TaskHelp.open.bind("recipe", recipe_id, int(recipe.get("qty", 1)))))
		return box
	var most := GameState.cook_max(recipe_id)
	if most > 1:
		var stepper := UiKit.stepper(count, 1, most, func(value: int) -> void: _set_count(recipe_id, value), "Tudo")
		stepper.name = "Quantity"
		stepper.get_child(1).name = "QuantityValue"
		var done := UiKit.short_label("Pronto às %s" % GameState.clock_text(GameState.cook_finish_at(recipe_id, count)), &"SmallLabel")
		done.name = "FinishAt"
		box.add_child(done)
		box.move_child(done, actions.get_index())
		actions.add_child(stepper)
	var error := GameState.cook_many_error(recipe_id, count)
	if error != "":
		var hint := UiKit.lock_hint(error)
		hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(hint)
		return box
	var verb := str(Database.stations.get(station_id, {}).get("action_label", "Fazer"))
	var action := UiKit.primary(verb if count == 1 else "%s ×%d" % [verb, count], func() -> void: _cook(station_id, recipe_id))
	action.name = "Cook"
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(action)
	return box


static func _set_count(recipe_id: String, count: int) -> void:
	quantity[recipe_id] = clampi(count, 1, maxi(1, GameState.cook_max(recipe_id)))
	var tray := ActionTray.current
	if is_instance_valid(tray):
		tray.refresh_detail()


## Põe na fila; a bolinha nova acende e o ícone da receita voa da grade até ela. A receita continua selecionada.
static func _cook(station_id: String, recipe_id: String) -> void:
	var count := chosen_count(recipe_id)
	var before := GameState.station(station_id).queue.size()
	var reason := GameState.cook_many(recipe_id, count)
	if reason != "":
		Events.toast_requested.emit(reason)
		return
	quantity[recipe_id] = 1
	var tray := ActionTray.current
	if not is_instance_valid(tray):
		return
	last_recipe[station_id] = recipe_id
	var icon := Database.item_icon(Database.recipe_output(Database.recipes[recipe_id]))
	var from := tray.item_center(recipe_id)
	for i in count:
		_light_new_slot(tray, station_id, icon, from, before + i)


## O cabeçalho se refaz no fim do quadro: espera e acende a bolinha da vaga `index`.
static func _light_new_slot(tray: ActionTray, station_id: String, icon: Texture2D, from: Vector2, index: int) -> void:
	var tree := tray.get_tree()
	await tree.process_frame
	await tree.process_frame
	if not is_instance_valid(tray) or tray.closing:
		return
	var dot := tray.find_in_panel("Slot_%d" % index) as Control
	if dot == null:
		return
	Motion.pop_in(dot)
	tray.fly_icon(icon, from, dot.global_position + dot.size / 2.0)


# --- Criações (galinheiro, curral) ------------------------------------------------------

## Cada animal tem o próprio espaço; produto, tempo, ingredientes e Alimentar seguem o padrão das estações.
## "Comprar animais" abre a loja diretamente no rodapé, inclusive com o abrigo vazio.
static func animal(room: RoomView, station_id: String, anchor: Dictionary) -> ActionTray:
	var data: Dictionary = Database.stations[station_id]
	var buy := func() -> void: SheetBuilder.open_animal_shop(station_id)
	var shop_footer := {"text": "Comprar animais", "name": "BuyAnimals", "action": buy}
	if GameState.animal_count(station_id) == 0:
		var empty := UiKit.vbox(6)
		empty.name = "EmptyShelter"
		var note := UiKit.label("Abrigo vazio", &"")
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_child(note)
		shop_footer["primary"] = true
		return ActionTray.open(room, anchor.above, [], {"mode": "pick", "title": str(data.name), "icon": station_icon(station_id), "header": empty, "below": anchor.below, "footer_ghost": shop_footer})
	var entries: Array[Dictionary] = []
	for id in recipe_ids(station_id):
		var recipe: Dictionary = Database.recipes[id]
		entries.append({
			"id": id,
			"icon": Database.item_icon(Database.recipe_output(recipe)),
			"caption": TimeText.short(int(recipe.seconds)),
			"error": GameState.content_error("recipe", id, recipe),
			"error_fn": func() -> String: return GameState.content_error("recipe", id, recipe),
			"missing_fn": func() -> Texture2D: return missing_icon(id),
		})
	return ActionTray.open(room, anchor.above, entries, {
		"mode": "pick", "title": str(data.name), "icon": station_icon(station_id), "selected": _first_open(entries),
		"header": _header(station_id),
		"detail": func(id: String) -> Control: return recipe_detail(station_id, id),
		"below": anchor.below, "footer_ghost": shop_footer,
	})


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
		"icon": Database.item_icon(str(data.resources[0])),
		"see_all": func() -> void:
			Events.sheet_requested.emit(str(data.name), NatureUi.panel(site)),
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
		var level_label := UiKit.short_label("Nível %d" % info.level, &"SmallLabel")
		level_label.name = "NatureLevel"
		level_row.add_child(level_label)
		var help := UiKit.ctl_button("help", func() -> void:
			Events.sheet_requested.emit("Evolução · " + str(data.name), NatureUi.levels_panel(site)), 32, "sunken")
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
	_fill_material_detail(box, site, item)
	return box


## Desenha o detalhe da rota escolhida (tempo, saída e XP local); a troca de rota redesenha este mesmo corpo.
static func _fill_material_detail(box: VBoxContainer, site: String, item: String) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
	var route_id := NatureUi.best_route(item)
	var route: Dictionary = Database.progression.activities[route_id]
	var primary := _primary_item(route, item)
	var choice := NatureUi.route_choice(item, func() -> void: _fill_material_detail(box, site, item))
	if choice != null:
		box.add_child(choice)
	var title := UiKit.fill_label("%s ×%d" % [Database.item_name(primary), int(route.rewards.items[primary])], &"StrongLabel")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)
	var chips := UiKit.flow(2)
	chips.add_child(UiKit.chip(UiKit.ctl_icon("clock"), TimeText.short(int(route.seconds))))
	for bonus: String in route.rewards.get("items", {}):
		if bonus != primary:
			chips.add_child(UiKit.chip(Database.item_icon(bonus), "+%d" % int(route.rewards.items[bonus]), UiKit.GOOD))
	chips.add_child(UiKit.chip(UiKit.ui_icon("xp"), "+%d XP" % NatureUi.route_xp(route_id)))
	box.add_child(chips)
	var level := NatureUi.route_level(route_id)
	if GameState.progress.nature_level(site) < level:
		var hint := UiKit.lock_hint("Nível %d" % level)
		hint.name = "RequiredLevel_" + item
		box.add_child(hint)
		return
	var error := GameState.next_gathering_error(site, route_id, item)
	var action := UiKit.primary(error if error != "" else "Buscar", func() -> void:
		var reason := GameState.start_next_gathering(site, route_id, item)
		if reason != "":
			Events.toast_requested.emit(reason))
	action.name = "Material_" + item
	action.disabled = error != ""
	box.add_child(action)
	return
