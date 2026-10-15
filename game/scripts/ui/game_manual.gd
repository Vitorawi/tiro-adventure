class_name GameManual
extends RefCounted
## Manual de consulta: catálogo completo, sem produzir/comprar nem alterar o progresso.
## Recursos, receitas, tempos e destinos são derivados do conteúdo do Database.


static func open(section: String = "resources") -> void:
	Events.sheet_requested.emit("Manual", panel(section))


static func panel(section: String = "resources") -> Control:
	var box := UiKit.vbox(10)
	box.name = "ManualPanel"
	box.add_child(UiKit.label("Toque para ver como conseguir e onde ir.", &"SmallLabel"))
	var tabs := UiKit.hbox(8)
	for entry: Array in [["Recursos", "resources", "tab_bag"], ["Estações", "stations", "item_plank"]]:
		var tab := UiKit.button(entry[0], open.bind(entry[1]), &"PrimaryButton" if section == entry[1] else &"", UiKit.ui_icon(entry[2]))
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(tab)
	box.add_child(tabs)
	if section == "stations":
		_stations(box)
	else:
		_resources(box)
	return box


static func _resources(box: VBoxContainer) -> void:
	var money := UiKit.card(box)
	var row := UiKit.hbox(8)
	row.add_child(UiKit.icon(UiKit.ui_icon("coin"), 32))
	row.add_child(UiKit.fill_label("Moedas: colha, venda e cumpra missões.", &"SmallLabel"))
	money.add_child(row)
	for category: String in SheetBuilder.CATEGORIES:
		box.add_child(UiKit.label(SheetBuilder.CATEGORIES[category], &"SectionLabel"))
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		for id: String in Database.items:
			if Database.items[id].get("category", "product") == category:
				grid.add_child(_tile(id))
		box.add_child(grid)


static func _tile(id: String) -> Button:
	var tile := UiKit.button(Database.item_name(id), open_item.bind(id), &"", Database.item_icon(id))
	tile.name = "Resource_" + id
	tile.custom_minimum_size = Vector2(0, 100)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.expand_icon = true
	tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	tile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tile.add_theme_constant_override("icon_max_width", 36)
	tile.add_theme_font_size_override("font_size", 14)
	return tile


static func open_item(id: String) -> void:
	if Database.collections.has(id):
		Events.sheet_requested.emit("Coleção", ProgressionUi.collection_panel())
		return
	Events.sheet_requested.emit(Database.item_name(id), item_panel(id))


static func _back(box: VBoxContainer, section: String = "resources") -> void:
	box.add_child(UiKit.button("‹ Manual", open.bind(section), &"", UiKit.ui_icon("tab_tasks")))


## Fontes completas (inclusive recompensas de missão e ajuda de comida).
static func sources(id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key: String in Database.crops:
		if Database.crops[key].get("yield", {}).has(id):
			result.append({"kind": "crop", "id": key})
	for key: String in Database.recipes:
		if Database.recipe_output(Database.recipes[key]) == id:
			result.append({"kind": "recipe", "id": key})
	for key: String in Database.progression.activities:
		if Database.progression.activities[key].get("rewards", {}).get("items", {}).has(id):
			result.append({"kind": "route", "id": key})
	for key: String in Database.quests:
		if Database.quests[key].get("rewards", {}).get("items", {}).has(id):
			result.append({"kind": "quest", "id": key})
	for world: String in Database.finds.worlds:
		var entry: Dictionary = Database.finds.worlds[world]
		var found := false
		for reward: Dictionary in entry.get("guaranteed", []) + entry.get("table", []):
			found = found or reward.get("items", {}).has(id)
		if found:
			result.append({"kind": "find", "id": world})
	for source: Dictionary in Database.item_sources(id):
		if source.key == "feed":
			result.append({"kind": "care", "id": id})
		elif str(source.key).begins_with("walk:"):
			result.append({"kind": "walk", "id": str(source.key).trim_prefix("walk:")})
	return result


static func item_panel(id: String) -> Control:
	var box := UiKit.vbox(10)
	box.name = "ManualResource_" + id
	_back(box)
	var header := UiKit.hbox(10)
	header.add_child(UiKit.icon(Database.item_icon(id), 64))
	header.add_child(UiKit.fill_label(Database.item_name(id), &"TitleLabel"))
	box.add_child(header)
	box.add_child(UiKit.label("Como conseguir", &"SectionLabel"))
	for source: Dictionary in sources(id):
		_source_card(box, source)
	var uses := UiKit.flow()
	for recipe_id: String in Database.recipes:
		var recipe: Dictionary = Database.recipes[recipe_id]
		if recipe.get("inputs", {}).has(id):
			uses.add_child(_item_chip(Database.recipe_output(recipe), 0))
	for upgrade_id: String in Database.progression.upgrades:
		var upgrade: Dictionary = Database.progression.upgrades[upgrade_id]
		if upgrade.get("materials", {}).has(id):
			uses.add_child(UiKit.chip(UiKit.ui_icon(upgrade.get("icon", "")), upgrade.name))
	var item: Dictionary = Database.items[id]
	if item.has("feed"):
		uses.add_child(UiKit.chip(UiKit.ui_icon("tab_pet"), "Comida do Tiro"))
	if int(item.get("sell_price", 0)) > 0:
		uses.add_child(UiKit.chip(UiKit.ui_icon("coin"), "Venda: %d" % int(item.sell_price)))
	if uses.get_child_count() > 0:
		box.add_child(UiKit.label("Serve para", &"SectionLabel"))
		box.add_child(uses)
	else:
		uses.free()
	return box


static func _item_chip(id: String, amount: int) -> Button:
	return UiKit.tap_chip(Database.item_icon(id), ("%dx " % amount if amount > 0 else "") + Database.item_name(id), open_item.bind(id))


static func _amounts(box: VBoxContainer, amounts: Dictionary) -> void:
	var flow := UiKit.flow()
	for id: String in amounts:
		flow.add_child(_item_chip(id, int(amounts[id])))
	box.add_child(flow)


static func _source_card(box: VBoxContainer, source: Dictionary) -> void:
	var card := UiKit.card(box)
	var id: String = source.id
	match str(source.kind):
		"walk":
			var walk := GameState.walk_def(id)
			card.add_child(UiKit.label(str(walk.name), &"SectionLabel"))
			card.add_child(UiKit.label("Passear → esperar → recolher", &"SmallLabel"))
			card.add_child(UiKit.chip(UiKit.ui_icon("timer"), TimeText.short(int(walk.seconds))))
			_requirements(card, walk)
			_location(card, {"world": "park", "place": "walk"})
		"recipe":
			_recipe(card, id)
		"crop":
			var crop: Dictionary = Database.crops[id]
			card.add_child(UiKit.label("Plantar → esperar → colher", &"SectionLabel"))
			_timer(card, int(crop.seconds))
			_amounts(card, crop.get("yield", {}))
			_requirements(card, crop)
			_location(card, _focused("farm", "crop:" + id))
		"route":
			var route: Dictionary = Database.progression.activities[id]
			card.add_child(UiKit.label(route.name, &"SectionLabel"))
			card.add_child(UiKit.label("Inicie a rota e recolha ao terminar.", &"SmallLabel"))
			_timer(card, int(route.seconds))
			_amounts(card, route.rewards.get("items", {}))
			_requirements(card, route)
			_location(card, _focused("routes:" + str(route.place), "route:" + id))
		"quest":
			card.add_child(UiKit.label("Recompensa de missão", &"SectionLabel"))
			card.add_child(UiKit.label(Database.quests[id].name, &"SmallLabel"))
			card.add_child(UiKit.button("Ver missões", Places.go.bind({"screen": "tasks"})))
		"find":
			card.add_child(UiKit.label("Faro do Tiro", &"SectionLabel"))
			card.add_child(UiKit.label("Toque no montinho onde o Tiro farejou.", &"SmallLabel"))
			var find_world: Dictionary = Database.worlds[id]
			var find_row := UiKit.hbox(8)
			find_row.add_child(UiKit.icon(UiKit.ui_icon(find_world.get("icon", "")), 32))
			find_row.add_child(UiKit.fill_label(find_world.name, &"SmallLabel"))
			card.add_child(find_row)
			var find_error := Places.world_error(id)
			var find_button := UiKit.button("Bloqueado" if find_error != "" else "Ir até lá", Places.go.bind({"world": id, "place": "find"}), &"PrimaryButton")
			find_button.disabled = find_error != ""
			card.add_child(find_button)
		"care":
			card.add_child(UiKit.label("Ajuda da Bloblo", &"SectionLabel"))
			card.add_child(UiKit.label("Sem comida? Abra Comer e peça ajuda.", &"SmallLabel"))
			_location(card, Places.goal_target({"type": "stat", "key": "feed"}))


static func _recipe(box: VBoxContainer, id: String) -> void:
	var recipe: Dictionary = Database.recipes[id]
	var station_id: String = recipe.station
	box.add_child(UiKit.label(Database.stations[station_id].name, &"SectionLabel"))
	if Database.stations[station_id].get("kind", "") == "animal":
		box.add_child(UiKit.label("Compre animais no abrigo. Quantidades abaixo são por animal.", &"SmallLabel"))
	_amounts(box, recipe.get("inputs", {}))
	box.add_child(UiKit.label("↓ Alimentar → esperar → recolher" if Database.stations[station_id].get("kind", "") == "animal" else "↓ Produzir e recolher", &"SmallLabel"))
	_amounts(box, {Database.recipe_output(recipe): int(recipe.get("qty", 1))})
	_timer(box, int(recipe.seconds))
	_requirements(box, recipe)
	_location(box, _focused("station:" + station_id, "recipe:" + id), station_id)


static func _timer(box: VBoxContainer, seconds: int) -> void:
	box.add_child(UiKit.chip(UiKit.ui_icon("timer"), TimeText.short(seconds)))


static func _requirements(box: VBoxContainer, data: Dictionary) -> void:
	var error := GameState.requirement_error(data.get("requirements", {}))
	if error != "":
		box.add_child(UiKit.label("Falta: " + error, &"SmallLabel", UiKit.BAD))


static func _focused(panel_id: String, focus: String = "") -> Dictionary:
	var location := Database.place_with_panel(panel_id)
	if location[0] == "":
		return {}
	return {"world": location[0], "place": focus if focus != "" else location[1], "spot": location[1]}


## Destino legível e atalho: mundos/lugares fechados não permitem navegação.
static func _location(box: VBoxContainer, target: Dictionary, upgrade: String = "") -> void:
	var station_id := upgrade
	upgrade = Database.station_upgrade(upgrade)
	if target.is_empty():
		return
	var world: Dictionary = Database.worlds[target.world]
	var place: Dictionary = world.places[target.get("spot", target.place)]
	var row := UiKit.hbox(8)
	row.add_child(UiKit.icon(UiKit.ui_icon(world.get("icon", "")), 32))
	row.add_child(UiKit.fill_label("%s › %s" % [world.name, place.name], &"SmallLabel"))
	box.add_child(row)
	var error := Places.world_error(target.world)
	if error == "":
		error = Places.place_error(place)
	var needs_buy: bool = upgrade != "" and Database.progression.upgrades.has(upgrade) and not GameState.has_upgrade(upgrade)
	var destination := Places.goal_target({"type": "owned", "key": upgrade}) if needs_buy else target
	var button := UiKit.button("Bloqueado" if error != "" else ("Ver compra" if needs_buy else "Ir até lá"), Places.go.bind(destination), &"PrimaryButton")
	button.disabled = error != ""
	box.add_child(button)
	if error != "":
		box.add_child(UiKit.label(error, &"SmallLabel", UiKit.BAD))
	elif needs_buy:
		box.add_child(UiKit.label("Compre: " + str(Database.stations[station_id].name), &"SmallLabel"))


static func _stations(box: VBoxContainer) -> void:
	box.add_child(UiKit.label("Onde produzir", &"SectionLabel"))
	for id: String in Database.stations:
		var card := UiKit.card(box)
		card.add_child(UiKit.label(Database.stations[id].name, &"SectionLabel"))
		var products := UiKit.flow()
		for recipe_id: String in Database.recipes_for(id):
			products.add_child(_item_chip(Database.recipe_output(Database.recipes[recipe_id]), 0))
		card.add_child(products)
		_location(card, _focused("station:" + id), id)
	box.add_child(UiKit.label("Onde coletar", &"SectionLabel"))
	var crops := UiKit.card(box)
	crops.add_child(UiKit.label("Canteiros", &"SectionLabel"))
	crops.add_child(UiKit.label("Plante uma semente. Espere e toque para colher.", &"SmallLabel"))
	for id: String in Database.crops:
		_amounts(crops, Database.crops[id].get("yield", {}))
	_location(crops, _focused("farm"))
	for id: String in Database.progression.activities:
		_source_card(box, {"kind": "route", "id": id})
