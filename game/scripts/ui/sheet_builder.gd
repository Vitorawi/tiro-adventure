class_name SheetBuilder
extends RefCounted
## Monta o conteúdo dos painéis inferiores (sheets) usados por várias telas.
## Uso: Events.sheet_requested.emit("Título", SheetBuilder.food_picker())
## Peças visuais vêm do UiKit; ícones de itens/necessidades vêm do Database.
## Regra: ícone + número em vez de frase; no máximo uma linha curta de texto.


## Comidas do inventário: ícone, quantidade, efeitos e "Dar".
static func food_picker() -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		var any := false
		var primary_used := false
		# A comida que o Tiro está pedindo (aba Desejos) vem primeiro, com um coração.
		var foods: Array[String] = []
		for id: String in Database.items:
			if Database.items[id].has("feed") and GameState.inventory.count(id) > 0:
				foods.append(id)
		foods.sort_custom(func(a: String, b: String) -> bool:
			return GameState.wish_slot_for_item(a) >= 0 and GameState.wish_slot_for_item(b) < 0)
		for id: String in foods:
			any = true
			var wish_slot := GameState.wish_slot_for_item(id)
			var body := UiKit.card(box)
			var row := UiKit.hbox(10)
			row.add_child(UiKit.icon(Database.item_icon(id), 64))
			var info := UiKit.vbox(4)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if wish_slot >= 0:
				info.add_child(UiKit.chip(UiKit.ui_icon("bond_heart"), "Ele quer!", UiKit.GOOD))
			info.add_child(UiKit.label("x%d" % GameState.inventory.count(id)))
			info.add_child(UiKit.effect_chips(Database.items[id]["feed"]))
			row.add_child(info)
			var on_give := func() -> void:
				# Comida desejada: tocar cumpre o desejo (que já alimenta o Tiro).
				if wish_slot >= 0:
					var error := GameState.fulfill_wish(wish_slot)
					Events.toast_requested.emit(error if error != "" else "Era isso que ele queria!")
					Events.sheet_close_requested.emit()
				elif GameState.feed(id):
					Events.toast_requested.emit("Nhac! %s" % Database.item_name(id))
					Events.sheet_close_requested.emit()
			# Só a comida que o Tiro quer ("Ele quer!") é o botão principal; as outras são secundárias.
			var wanted := wish_slot >= 0 and not primary_used
			primary_used = primary_used or wanted
			var give := UiKit.primary("Dar", on_give) if wanted else UiKit.secondary("Dar", on_give, null, true)
			give.custom_minimum_size = Vector2(76, 52 if wanted else 44)
			give.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(give)
			body.add_child(row)
		if not any:
			_empty_message(box, "Acabou a comida!", "")
			box.add_child(UiKit.button("Pedir à Bloblo", func() -> void:
				var error := GameState.emergency_food()
				Events.toast_requested.emit(error if error != "" else "Comida recebida!"), &"PrimaryButton", ProgressionUi.npc_portrait("bloblo"))))


const CATEGORIES := {"food": "Comidas", "crop": "Colheitas", "material": "Materiais", "product": "Produtos", "find": "Achados", "trail": "Do passeio"}


## Mochila: lugar único com todos os itens e a ocupação de cada depósito ("12/30" ao construir).
## Com `only` (id de depósito: "fridge", "chest", "silo", "warehouse"), só o que mora nele. Ícone + quantidade por
## categoria; tocar abre o detalhe.
static func inventory_view(only: String = "") -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		_storage_bars(box, only)
		var shown: Array[String] = []
		for id: String in GameState.inventory.counts:
			if only == "" or GameState.storage_of(id) == only:
				shown.append(id)
		if shown.is_empty():
			_empty_message(box, "%s vazio." % Database.progression.storage[only].name if only != "" else "Mochila vazia.", "")
			return
		for category: String in CATEGORIES:
			var ids: Array[String] = []
			for id: String in shown:
				if Database.items.get(id, {}).get("category", "product") == category:
					ids.append(id)
			if ids.is_empty():
				continue
			if category == "trail":
				var heading := UiKit.hbox(6)
				heading.add_child(UiKit.icon(UiKit.ui_icon("action_walk"), 32))
				heading.add_child(UiKit.fill_label(CATEGORIES[category], &"SectionLabel"))
				box.add_child(heading)
			else:
				box.add_child(UiKit.label(CATEGORIES[category], &"SectionLabel"))
			var grid := GridContainer.new()
			grid.columns = 4
			grid.mouse_filter = Control.MOUSE_FILTER_PASS
			grid.add_theme_constant_override("h_separation", 6)
			grid.add_theme_constant_override("v_separation", 6)
			for id in ids:
				grid.add_child(_item_tile(id))
			box.add_child(grid))


## Uma linha de chips com ícone e usado/capacidade de cada depósito construído (`only` = só ele).
static func _storage_bars(box: VBoxContainer, only: String) -> void:
	var row := HFlowContainer.new()
	for id: String in Database.progression.storage:
		if (only != "" and id != only) or not GameState.storage_active(id):
			continue
		var full := GameState.storage_space(id) == 0
		row.add_child(UiKit.chip(UiKit.ui_icon(str(Database.progression.storage[id].icon)), "%d/%d" % [GameState.storage_used(id), GameState.storage_capacity(id)], UiKit.BAD if full else null))
	if row.get_child_count() > 0:
		box.add_child(row)


static func _fits_fridge(id: String) -> bool:
	return GameState.storage_of(id) == "fridge"


static func _item_tile(id: String) -> Button:
	var tile := UiKit.button("x%d" % GameState.inventory.count(id), func() -> void:
		Events.sheet_requested.emit(Database.item_name(id), item_detail(id)), &"", Database.item_icon(id))
	tile.custom_minimum_size = Vector2(0, 84)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.expand_icon = true
	tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	tile.add_theme_constant_override("icon_max_width", 44)
	tile.add_theme_font_size_override("font_size", 16)
	return tile


## Detalhe do item: ícone + quantidade, efeitos, de onde vem e onde usa (tocáveis, com Ir) e preço.
static func item_detail(id: String) -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		var item: Dictionary = Database.items.get(id, {})
		var top := UiKit.hbox(10)
		top.add_child(UiKit.icon(Database.item_icon(id), 64))
		top.add_child(UiKit.fill_label("x%d" % GameState.inventory.count(id), &"TitleLabel"))
		var price := int(item.get("sell_price", 0))
		if price > 0:
			top.add_child(UiKit.chip(UiKit.ui_icon("coin"), str(price)))
		box.add_child(top)
		if item.has("feed"):
			box.add_child(UiKit.effect_chips(item.feed))
			var give := UiKit.button("Dar ao Tiro", func() -> void:
				if GameState.feed(id):
					Events.toast_requested.emit("Nhac! %s" % Database.item_name(id)), &"PrimaryButton")
			give.disabled = GameState.inventory.count(id) == 0
			box.add_child(give)
		var sources := _sources(id)
		var uses := _uses(id)
		_link_section(box, "De onde vem", sources)
		_link_section(box, "Usado em", uses)
		if uses.is_empty() and str(item.get("note", "")) != "":
			box.add_child(UiKit.label(str(item.note), &"SmallLabel"))
		if price > 0 and GameState.inventory.count(id) > 0:
			var place := Database.place_with_panel("sell")
			if place[0] != "" and Places.world_error(place[0]) == "":
				box.add_child(UiKit.button("Vender", Places.go.bind({"world": place[0], "place": "market:sell"}), &"", UiKit.ui_icon("coin"))))


## Fontes do item: [ícone] nome curto → destino. Ex.: Canteiros, Bancada, Volta pelo bairro.
static func _sources(id: String) -> Array[Dictionary]:
	var links: Array[Dictionary] = []
	for source: Dictionary in Database.item_sources(id):
		var key: String = source.key
		var target := Places.goal_target(source)
		if key.begins_with("activity:"):
			var route: Dictionary = Database.progression.activities.get(key.trim_prefix("activity:"), {})
			links.append({"icon": UiKit.ui_icon(route.get("icon", "")), "name": route.get("name", ""), "target": target})
		elif key.begins_with("walk:"):
			var walk := GameState.walk_def(key.trim_prefix("walk:"))
			links.append({"icon": UiKit.ui_icon("action_walk"), "name": walk.get("name", ""), "target": target})
		elif not target.is_empty() and target.has("world"):
			var place: Dictionary = Database.worlds[target.world].places.get(target.place, {})
			links.append({"icon": UiKit.ui_icon(place.get("icon", "")), "name": place.get("name", ""), "target": target})
	return links


## Onde o item é usado: receitas, construções, encomendas e comida do Tiro.
static func _uses(id: String) -> Array[Dictionary]:
	var links: Array[Dictionary] = []
	for recipe_id: String in Database.recipes:
		var recipe: Dictionary = Database.recipes[recipe_id]
		if recipe.get("inputs", {}).has(id):
			var location := Database.place_with_panel("station:" + str(recipe.station))
			links.append({"icon": Database.item_icon(Database.recipe_output(recipe)), "name": Database.item_name(Database.recipe_output(recipe)), "target": {"world": location[0], "place": "recipe:" + recipe_id, "spot": location[1]}})
	for upgrade_id: String in Database.progression.upgrades:
		var upgrade: Dictionary = Database.progression.upgrades[upgrade_id]
		if upgrade.get("materials", {}).has(id) and not GameState.has_upgrade(upgrade_id):
			links.append({"icon": UiKit.ui_icon(upgrade.get("icon", "")), "name": upgrade.name, "target": Places.goal_target({"type": "owned", "key": upgrade_id})})
	for order_id: String in Database.progression.orders:
		if Database.progression.orders[order_id].get("inputs", {}).has(id):
			links.append({"icon": UiKit.ui_icon("item_treat_box"), "name": Database.progression.orders[order_id].name, "target": Places.goal_target({"type": "stat", "key": "order:" + order_id})})
	return links


## Título curto + botões com ícone que levam ao lugar (fechados ficam apagados).
static func _link_section(box: VBoxContainer, title: String, links: Array[Dictionary]) -> void:
	if links.is_empty():
		return
	box.add_child(UiKit.label(title, &"SectionLabel"))
	var flow := UiKit.flow()
	for link: Dictionary in links:
		var target: Dictionary = link.target
		var chip := UiKit.tap_chip(link.icon, link.name, Places.go.bind(target))
		if target.has("world") and Places.world_error(str(target.world)) != "":
			chip.modulate.a = 0.5
		flow.add_child(chip)
	box.add_child(flow)


## Várias estações num painel (Cozinha = fogão + forno): título com ícone e a estação embaixo.
## Estação ainda não comprada mostra o cartão de compra no lugar.
static func stations_view(ids: PackedStringArray) -> Control:
	var box := UiKit.vbox(12)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	for id in ids:
		if GameState.requirement_error(Database.stations.get(id, {}).get("requirements", {})) != "":
			continue
		if ids.size() > 1:
			var title := UiKit.hbox(8)
			title.add_child(UiKit.icon(UiKit.ui_icon(Database.progression.upgrades.get(id, {}).get("icon", "")), 32))
			title.add_child(UiKit.fill_label(Database.stations.get(id, {}).get("name", id), &"TitleLabel"))
			box.add_child(title)
		box.add_child(station_view(id))
	return box


## Estação de produção (fogão): espaços de preparo + receitas em cartões.
static func station_view(station_id: String, focus: String = "") -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		if not GameState.has_upgrade(station_id):
			ProgressionUi.upgrade_card(box, station_id)
			return
		var target := GameState.station(station_id)
		var now := GameState.now()
		var slots := GameState.station_slots(station_id)
		var full := target.queue.size() >= slots
		var data: Dictionary = Database.stations[station_id]
		if data.get("instruction", "") != "":
			box.add_child(UiKit.label(data.instruction, &"SmallLabel"))
		if data.get("kind", "") == "animal":
			box.add_child(UiKit.label("Seus animais · %d/%d" % [GameState.animal_count(station_id), int(data.animal_capacity)], &"SectionLabel"))
			var herd := UiKit.flow()
			for animal_id: String in GameState.animal_roster(station_id):
				herd.add_child(UiKit.icon(load(Database.animals[animal_id].sprite), 48))
			box.add_child(herd)
			box.add_child(UiKit.button("Comprar animais", open_animal_shop.bind(station_id)))
			if GameState.animal_count(station_id) == 0:
				box.add_child(UiKit.label("Abrigo vazio. Escolha seu primeiro animal.", &"SmallLabel"))
				return

		box.add_child(UiKit.label("%s  %d/%d" % [data.get("queue_label", "Preparando"), target.queue.size(), slots], &"SectionLabel"))
		var slot_row := UiKit.hbox(8)
		for i in slots:
			slot_row.add_child(_slot_card(target.queue[i] if i < target.queue.size() else {}, now))
		# Espaços que ainda dá para ampliar ficam na mesma fileira, com "+" e o preço.
		for upgrade_id: String in GameState.pending_slot_upgrades(station_id):
			slot_row.add_child(_locked_slot(upgrade_id))
		box.add_child(slot_row)
		var ready := target.ready_count(now)
		if ready > 0:
			box.add_child(UiKit.button("Coletar prontos (%d)" % ready, func() -> void:
				var received := GameState.collect(station_id)
				Events.items_gained.emit(received, 0, Vector2(-1.0, -1.0)), &"PrimaryButton"))

		box.add_child(UiKit.label(data.get("recipe_label", "Receitas"), &"SectionLabel"))
		for recipe_id in Database.recipes_for(station_id):
			if focus != "" and recipe_id != focus:
				continue
			_recipe_card(box, recipe_id, full))


static func _slot_card(entry: Dictionary, now: float) -> Control:
	if entry.is_empty():
		return slot_frame(null, "Livre", 0.0, false, true)
	var recipe: Dictionary = Database.recipes[entry["recipe"]]
	var seconds := float(recipe["seconds"])
	var remaining := float(entry["ready_at"]) - now
	var texture := Database.item_icon(Database.recipe_output(recipe))
	var amount := " · ×%d" % int(entry.get("qty", recipe.get("qty", 1)))
	if remaining <= 0.0:
		return slot_frame(texture, "Pronto!" + amount, 1.0, true, false)
	if remaining > seconds:
		return slot_frame(texture, "Na fila", 0.0, false, false)
	return slot_frame(texture, format_time(int(ceil(remaining))) + amount, 1.0 - remaining / seconds, false, false)


## Espaço ainda fechado: "+" e o preço; tocar abre a compra da ampliação.
static func _locked_slot(upgrade_id: String) -> Control:
	var data: Dictionary = Database.progression.upgrades[upgrade_id]
	var ready := GameState.upgrade_error(upgrade_id) == ""
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"ReadyCardPanel" if ready else &"CardPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.name = "LockedSlot_" + upgrade_id
	if not ready:
		panel.modulate.a = 0.75
	var box := UiKit.vbox(4)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plus := UiKit.label("+", &"TitleLabel", UiKit.GOOD if ready else null)
	plus.add_theme_font_size_override("font_size", 44)
	plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus.custom_minimum_size = Vector2(0, 64)
	plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(plus)
	var price := UiKit.chip(UiKit.ui_icon("coin"), "Grátis" if int(data.cost) <= 0 else str(int(data.cost)), UiKit.GOOD if GameState.coins >= int(data.cost) else UiKit.BAD)
	price.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(price)
	panel.add_child(box)
	panel.gui_input.connect(func(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			Events.sheet_requested.emit(str(data.name), ProgressionUi.purchase(upgrade_id)))
	return panel


static func slot_frame(texture: Texture2D, text: String, progress: float, done: bool, empty: bool) -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"ReadyCardPanel" if done else &"CardPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	if empty:
		panel.modulate.a = 0.5
	var box := UiKit.vbox(4)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var picture := UiKit.icon(texture, 64)
	box.add_child(picture)
	var caption := UiKit.label(text, &"SmallLabel", UiKit.GOOD if done else null)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(caption)
	if not done and not empty:
		box.add_child(UiKit.bar(progress * 100.0, Palette.INFO, 10))
	panel.add_child(box)
	return panel


## Cartão de receita: o que sai, quanto tempo leva, o que faz e o que precisa.
static func _recipe_card(parent: VBoxContainer, recipe_id: String, station_full: bool) -> void:
	var recipe: Dictionary = Database.recipes[recipe_id]
	var locked := GameState.content_error("recipe", recipe_id, recipe)
	var output: String = Database.recipe_output(recipe)
	var inputs: Dictionary = GameState.recipe_inputs(recipe_id)
	var body := UiKit.card(parent)

	var top := UiKit.hbox(10)
	top.add_child(UiKit.icon(Database.item_icon(output), 64))
	var info := UiKit.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var qty := GameState.recipe_quantity(recipe_id)
	info.add_child(UiKit.label(Database.item_name(output) + ("  x%d" % qty if qty > 1 else "")))
	var details := UiKit.flow()
	details.add_child(UiKit.chip(UiKit.ui_icon("timer"), format_time(int(recipe["seconds"]))))
	var feed: Dictionary = Database.items.get(output, {}).get("feed", {})
	for need_id: String in feed:
		details.add_child(UiKit.chip(Database.need_icon(need_id), "%+d" % int(feed[need_id]), UiKit.GOOD))
	info.add_child(details)
	top.add_child(info)
	body.add_child(top)

	# Ingredientes: ícone + tem/precisa; tocar mostra de onde vem.
	var needs_row := UiKit.flow()
	var has_all := true
	for item_id: String in inputs:
		has_all = has_all and GameState.inventory.count(item_id) >= int(inputs[item_id])
		needs_row.add_child(ProgressionUi.item_chip(item_id, int(inputs[item_id])))
	body.add_child(needs_row)

	var help := TaskHelp.open.bind("recipe", recipe_id, int(recipe.get("qty", 1)))
	if locked != "":
		# Receita fechada: cartão apagado e cadeado com o motivo, no lugar do botão.
		body.get_parent().modulate.a = 0.55
		body.add_child(UiKit.lock_hint(locked, help))
		return
	var row := UiKit.hbox(8)
	var action: String = Database.stations.get(recipe.station, {}).get("action_label", "Produzir")
	if recipe.has("output_collection") and GameState.cook_error(recipe_id) in ["Você já tem", "Já está sendo costurado"]:
		action = GameState.cook_error(recipe_id)
	var cook := UiKit.secondary("Fila cheia" if station_full and has_all else action, func() -> void:
		var error := GameState.cook(recipe_id)
		Events.toast_requested.emit(error if error != "" else "Preparando %s!" % Database.item_name(output)), null, true)
	cook.disabled = GameState.cook_error(recipe_id) != ""
	cook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cook)
	if not has_all:
		row.add_child(UiKit.square_button("?", help, null, 44))
	body.add_child(row)


static func open_animal_shop(station_id: String) -> void:
	Events.sheet_requested.emit("Comprar animais", animal_shop(station_id))


static func animal_shop(station_id: String) -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		var data: Dictionary = Database.stations[station_id]
		box.add_child(UiKit.label("%s · %d/%d animais" % [data.name, GameState.animal_count(station_id), int(data.animal_capacity)], &"SectionLabel"))
		box.add_child(UiKit.label("Escolha o visual. Cada animal produz 2 unidades por alimentação.", &"SmallLabel"))
		for id: String in Database.animals:
			var animal: Dictionary = Database.animals[id]
			if animal.station != station_id:
				continue
			var body := UiKit.card(box)
			var row := UiKit.hbox(8)
			row.add_child(UiKit.icon(load(animal.sprite), 64))
			var info := UiKit.vbox(4)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.add_child(UiKit.label(animal.name))
			info.add_child(UiKit.label("Você tem %d" % int(GameState.animals.get(id, 0)), &"SmallLabel"))
			row.add_child(info)
			body.add_child(row)
			var error := GameState.buy_animal_error(id)
			var buy := UiKit.button("Comprar · %d moedas" % int(animal.price), func() -> void:
				var reason := GameState.buy_animal(id)
				Events.toast_requested.emit(reason if reason != "" else "%s chegou ao sítio!" % animal.name), &"PrimaryButton")
			buy.disabled = error != ""
			body.add_child(buy)
			if error != "":
				_animal_missing(body, animal, error)
		box.add_child(UiKit.button("Ver meus animais", func() -> void:
			Events.sheet_requested.emit(data.name, station_view(station_id)))))


## O que falta para comprar o animal, em ícone + número (pode faltar mais de uma coisa):
## produtos a recolher (ex.: ovos 1/2) e moedas (78/80). Outros motivos continuam em texto.
static func _animal_missing(body: VBoxContainer, animal: Dictionary, error: String) -> void:
	var chips := UiKit.flow(4)
	var produced: Dictionary = animal.get("requirements", {}).get("produced", {})
	for item_id: String in produced:
		var done := GameState.progress.stat("produce:" + item_id)
		if done < int(produced[item_id]):
			chips.add_child(UiKit.chip(Database.item_icon(item_id), "%d/%d" % [done, int(produced[item_id])], UiKit.BAD))
	if GameState.coins < int(animal.price):
		chips.add_child(UiKit.chip(UiKit.ui_icon("coin"), "%d/%d" % [GameState.coins, int(animal.price)], UiKit.BAD))
	if chips.get_child_count() > 0:
		body.add_child(chips)
	else:
		chips.free()
		body.add_child(UiKit.label(error, &"SmallLabel"))


## Sementes para um canteiro vazio: [planta] nome · tempo · moedas · colheita · [Plantar].
## Bloqueada: apagada, com "?" que mostra como liberar.
static func seed_picker(plot_index: int, focus: String = "") -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		var crop_ids: Array = Database.crops.keys()
		crop_ids.sort_custom(func(a: String, b: String) -> bool:
			var a_time := int(Database.crops[a].seconds)
			var b_time := int(Database.crops[b].seconds)
			return a_time < b_time if a_time != b_time else a > b)
		for crop_id: String in crop_ids:
			if focus != "" and crop_id != focus:
				continue
			if GameState.crop_plot_error(plot_index, crop_id) != "":
				continue  # estufa: só plantas delicadas; sítio: sem as que só crescem na estufa
			var crop: Dictionary = Database.crops[crop_id]
			var locked := GameState.content_error("crop", crop_id, crop)
			var body := UiKit.card(box)
			if locked != "":
				body.get_parent().modulate.a = 0.6
			var row := UiKit.hbox(8)
			row.add_child(UiKit.icon(Database.item_icon(crop_id), 48))
			var info := UiKit.vbox(4)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.add_child(UiKit.label(Database.item_name(crop_id)))
			var details := UiKit.flow(4)
			details.add_child(UiKit.chip(UiKit.ui_icon("timer"), format_time(int(crop["seconds"]))))
			details.add_child(UiKit.chip(UiKit.ui_icon("coin"), "+%d" % int(crop.get("coins", 0))))
			var harvest: Dictionary = crop.get("yield", {})
			for item_id: String in harvest:
				details.add_child(UiKit.chip(Database.item_icon(item_id), "+%d" % int(harvest[item_id]), UiKit.GOOD))
			info.add_child(details)
			row.add_child(info)
			if locked == "":
				var plant := UiKit.secondary("Plantar", func() -> void:
					var error := GameState.plant(plot_index, crop_id)
					Events.toast_requested.emit(error if error != "" else "Plantou %s!" % Database.item_name(crop_id))
					Events.sheet_close_requested.emit(), null, true)
				plant.custom_minimum_size.x = 92
				row.add_child(plant)
			body.add_child(row)
			if locked != "":
				body.add_child(UiKit.lock_hint(locked, TaskHelp.open.bind("crop", crop_id))))


## Canteiros: terrenos (barra), próximo terreno e cada canteiro em ícone + estado.
static func farm_view(focus: String = "") -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		var total := int(Database.farm.get("plots", 0))
		if not GameState.has_upgrade("farm"):
			# Antes da escritura: um canteiro emprestado e a compra do sítio.
			ProgressionUi.upgrade_card(box, "farm")
		var land := UiKit.hbox(8)
		land.add_child(UiKit.icon(UiKit.ui_icon("tab_farm"), 32))
		var bar := UiKit.bar(100.0 * GameState.accessible_plots() / total, UiKit.GOOD, 12)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		land.add_child(bar)
		land.add_child(UiKit.short_label("%d/%d" % [GameState.accessible_plots(), total]))
		box.add_child(land)
		if GameState.has_upgrade("farm") and GameState.unlocked_plots < total:
			var cost := GameState.plot_cost(GameState.unlocked_plots)
			box.add_child(UiKit.button("+1 terreno · %d" % cost, func() -> void:
				Events.sheet_requested.emit("Expandir o sítio", plot_purchase(GameState.unlocked_plots)), &"PrimaryButton" if GameState.coins >= cost else &"", UiKit.ui_icon("coin")))
		var grid := GridContainer.new()
		grid.columns = 3
		grid.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		var garden: Array[int] = []
		var greenhouse: Array[int] = []
		for index in GameState.usable_plot_indices():
			(greenhouse if GameState.is_greenhouse_plot(index) else garden).append(index)
		for index in garden:
			grid.add_child(_plot_tile(index, focus))
		box.add_child(grid)
		if not greenhouse.is_empty():
			box.add_child(UiKit.label("Estufa · plantas delicadas, crescem mais rápido", &"SectionLabel"))
			var house_grid := GridContainer.new()
			house_grid.columns = 3
			house_grid.mouse_filter = Control.MOUSE_FILTER_PASS
			house_grid.add_theme_constant_override("h_separation", 6)
			for index in greenhouse:
				house_grid.add_child(_plot_tile(index, focus))
			box.add_child(house_grid))


## Canteiro: vazio = "+" (plantar); crescendo = planta + %; pronto = planta + "Colher!".
static func _plot_tile(index: int, focus: String) -> Button:
	var status := GameState.plot_status(index)
	var crop: String = GameState.plot(index)["crop"]
	var caption := "Plantar" if status == "empty" else ("Colher!" if status == "ready" else "%d%%" % int(GameState.plot_progress(index) * 100))
	var tile := UiKit.button(caption, func() -> void:
		Events.sheet_requested.emit("Canteiro da estufa" if GameState.is_greenhouse_plot(index) else "Canteiro %d" % (index + 1), seed_picker(index, focus) if GameState.plot_status(index) == "empty" else growing_plot(index)),
		&"PrimaryButton" if status == "ready" else &"", Database.item_icon(crop) if crop != "" else UiKit.ui_icon("tab_farm"))
	tile.custom_minimum_size = Vector2(0, 84)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.expand_icon = true
	tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	tile.add_theme_constant_override("icon_max_width", 40)
	tile.add_theme_font_size_override("font_size", 16)
	return tile


## Comprar terreno: preço (tem/precisa) e botão.
static func plot_purchase(index: int) -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		var cost := GameState.plot_cost(index)
		var available := index == GameState.unlocked_plots
		if index < GameState.unlocked_plots:
			box.add_child(UiKit.label("Este terreno já é seu!", &"", UiKit.GOOD))
			return
		var row := UiKit.hbox(8)
		row.add_child(UiKit.icon(UiKit.ui_icon("tab_farm"), 48))
		row.add_child(UiKit.fill_label("Terreno %d" % (index + 1), &"SectionLabel"))
		row.add_child(UiKit.chip(UiKit.ui_icon("coin"), "%d/%d" % [mini(GameState.coins, cost), cost], UiKit.GOOD if GameState.coins >= cost else UiKit.BAD))
		box.add_child(row)
		if not available:
			box.add_child(UiKit.label("Compre o terreno %d antes." % (GameState.unlocked_plots + 1), &"SmallLabel"))
		var buy := UiKit.button("Comprar", func() -> void:
			var error := GameState.buy_plot(index)
			Events.toast_requested.emit(error if error != "" else "Novo terreno!")
			if error == "":
				Events.sheet_requested.emit("Canteiro %d" % (index + 1), seed_picker(index)), &"PrimaryButton")
		buy.disabled = not available or GameState.coins < cost or cost < 0
		box.add_child(buy))


## Planta crescendo: ícone, barra com tempo e o que vai render.
static func growing_plot(index: int) -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		var target := GameState.plot(index)
		if target["crop"] == "":
			box.add_child(UiKit.button("Plantar de novo", func() -> void:
				Events.sheet_requested.emit("Canteiro", seed_picker(index)), &"PrimaryButton", UiKit.ui_icon("tab_farm")))
			return
		var crop_id: String = target["crop"]
		var ready := GameState.plot_status(index) == "ready"
		var top := UiKit.hbox(10)
		top.add_child(UiKit.icon(Database.item_icon(crop_id), 64))
		var info := UiKit.vbox(6)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var line := UiKit.hbox(6)
		var bar := UiKit.bar(GameState.plot_progress(index) * 100, UiKit.GOOD, 14)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(bar)
		var remaining := maxi(0, int(ceil(float(target["ready_at"]) - GameState.now())))
		line.add_child(UiKit.short_label("Pronta!" if ready else format_time(remaining), &"", UiKit.GOOD if ready else null))
		info.add_child(line)
		var reward := int(Database.crops[crop_id].get("coins", 0))
		var gains := UiKit.flow(4)
		gains.add_child(UiKit.chip(UiKit.ui_icon("coin"), "+%d" % reward))
		var harvest: Dictionary = Database.crops[crop_id].get("yield", {})
		for item_id: String in harvest:
			gains.add_child(UiKit.chip(Database.item_icon(item_id), "+%d" % int(harvest[item_id]), UiKit.GOOD))
		info.add_child(gains)
		top.add_child(info)
		box.add_child(top)
		if ready:
			box.add_child(UiKit.button("Colher", func() -> void:
				var received := GameState.harvest(index)
				if not received.is_empty():
					Events.items_gained.emit(received, reward, Vector2(-1.0, -1.0)), &"PrimaryButton")))


static func _empty_message(box: VBoxContainer, title: String, hint: String) -> void:
	var body := UiKit.card(box)
	var text := UiKit.label(title)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(text)
	if hint != "":
		var small := UiKit.label(hint, &"SmallLabel")
		small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.add_child(small)


static func format_time(seconds: int) -> String:
	return TimeText.short(seconds)


## Caixa que se reconstrói quando o estado muda e a cada segundo (timers).
class LiveBox extends VBoxContainer:
	var _build: Callable
	var _pending: bool = false

	func _init(build: Callable) -> void:
		_build = build
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_PASS
		add_theme_constant_override("separation", 10)

	func _ready() -> void:
		Events.state_changed.connect(_schedule_rebuild)
		var timer := Timer.new()
		timer.wait_time = 1.0
		timer.autostart = true
		timer.timeout.connect(_on_tick)
		add_child(timer)
		_rebuild()

	## Reconstrói no fim do frame (ex.: troca de aba dentro do painel).
	func refresh() -> void:
		_schedule_rebuild()

	func _on_tick() -> void:
		# Não reconstrói com o dedo na tela, para não "roubar" um toque em andamento.
		if is_visible_in_tree() and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_schedule_rebuild()

	func _schedule_rebuild() -> void:
		if _pending:
			return
		_pending = true
		_rebuild.call_deferred()

	func _rebuild() -> void:
		_pending = false
		if is_queued_for_deletion() or not is_inside_tree():
			return
		for child in get_children():
			if not child is Timer:
				remove_child(child)
				child.queue_free()
		_build.call(self)
