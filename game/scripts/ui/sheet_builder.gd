class_name SheetBuilder
extends RefCounted
## Monta o conteúdo dos painéis inferiores (sheets) usados por várias telas.
## Uso: Events.sheet_requested.emit("Título", SheetBuilder.food_picker())
## Peças visuais vêm do UiKit; ícones de itens/necessidades vêm do Database.
## Regra: ícone + número em vez de frase; no máximo uma linha curta de texto.


## Caminho único da comida desejada (o cumprimento já alimenta exatamente uma vez).
static func give_food(id: String) -> String:
	if GameState.walking(): return GameState.away_text()
	if GameState.dog.sleeping: return "Shh... ele está dormindo."
	var slot := GameState.wish_slot_for_item(id)
	if slot >= 0: return GameState.fulfill_wish(slot)
	return "" if GameState.feed(id) else "Você não tem essa comida."


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
			var chips: Array[Control] = []
			if wish_slot >= 0:
				chips.append(UiKit.chip(UiKit.ui_icon("bond_heart"), "Ele quer!", UiKit.GOOD))
			chips.append_array(UiKit.effect_chip_list(Database.items[id]["feed"]))
			var on_give := func() -> void:
				var error := give_food(id)
				var message := error if error != "" else ("Era isso que ele queria!" if wish_slot >= 0 else "")
				if message != "":
					Events.toast_requested.emit(message)
				if error == "":
					Events.sheet_close_requested.emit()
			# Só a comida que o Tiro quer ("Ele quer!") é o botão principal; as outras são secundárias.
			var wanted := wish_slot >= 0 and not primary_used
			primary_used = primary_used or wanted
			var give := UiKit.primary("Dar", on_give) if wanted else UiKit.secondary("Dar", on_give, null, true)
			give.custom_minimum_size = Vector2(76, 52 if wanted else 44)
			box.add_child(UiKit.list_row(Database.item_icon(id), "%s ×%d" % [Database.item_name(id), GameState.inventory.count(id)], chips, give))
		if not any:
			_empty_message(box, "Acabou a comida!", "")
			box.add_child(UiKit.button("Pedir à Bloblo", func() -> void:
				var error := GameState.emergency_food()
				Events.toast_requested.emit(error if error != "" else "Bloblo trouxe comida!"), &"PrimaryButton", ProgressionUi.npc_portrait("bloblo"))))


const CATEGORIES := {"food": "Comidas", "crop": "Colheitas", "material": "Materiais", "product": "Produtos", "find": "Achados", "trail": "Do passeio"}


## Mochila: lugar único com todos os itens e a ocupação de cada depósito ("12/30" ao construir).
## Com `only` (id de depósito: "fridge", "chest", "silo", "warehouse"), só o que mora nele. Ícone + quantidade por
## categoria; tocar abre o detalhe.
static func inventory_view(only: String = "") -> Control:
	return tall(InventoryList.new(only))


## Consulta compartilhada pelos contratos de conteúdo e achados.
static func _fits_fridge(id: String) -> bool:
	return GameState.storage_of(id) == "fridge"


## Marca o conteúdo como painel alto (88% da tela, com rolagem): listas longas e consultas.
static func tall(content: Control) -> Control:
	content.set_meta("sheet_size", "tall")
	return content


## Detalhe do item: ícone + quantidade, efeitos, de onde vem e onde usa (tocáveis, com Ir) e preço.
static func item_detail(id: String) -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		var item: Dictionary = Database.items.get(id, {})
		var top := UiKit.hbox(10)
		top.add_child(UiKit.icon(Database.item_icon(id), 64))
		var amount := GameState.inventory.count(id)
		top.add_child(UiKit.fill_label("Você tem %d" % amount if amount > 0 else "Você não tem", &"", Palette.INK if amount > 0 else Palette.INK_SOFT))
		var price := int(item.get("sell_price", 0))
		if price > 0:
			top.add_child(UiKit.chip(UiKit.ui_icon("coin"), str(price)))
		box.add_child(top)
		if item.has("feed"):
			box.add_child(UiKit.effect_chips(item.feed))
			if GameState.inventory.count(id) > 0:
				box.add_child(UiKit.primary("Dar ao Tiro", func() -> void:
					var error := give_food(id)
					if error != "":
						Events.toast_requested.emit(error)))
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
	# Só as estações já liberadas contam: com uma só visível, o título do painel já diz o nome.
	var visible_ids: Array[String] = []
	for id in ids:
		if GameState.requirement_error(Database.stations.get(id, {}).get("requirements", {})) == "":
			visible_ids.append(id)
	for id in visible_ids:
		if visible_ids.size() > 1:
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
			box.add_child(UiKit.label("%d de %d animais" % [GameState.animal_count(station_id), int(data.animal_capacity)], &"SectionLabel"))
			box.add_child(UiKit.button("Comprar animais", open_animal_shop.bind(station_id)))
			if GameState.animal_count(station_id) == 0:
				box.add_child(UiKit.label("Abrigo vazio. Escolha seu primeiro animal.", &"SmallLabel"))
				return

		var slot_row := station_slot_row(station_id)
		var ready := target.ready_count(now)
		box.add_child(slot_strip(slot_row, "Pegar tudo (%d)" % ready if ready > 0 else "", func() -> void:
			var received := GameState.collect(station_id)
			Events.items_gained.emit(received, 0, Vector2(-1.0, -1.0))))

		if data.get("kind", "") == "animal":
			box.add_child(UiKit.label(data.get("recipe_label", "Receitas"), &"SectionLabel"))  # estações comuns: a lista fala por si
		for recipe_id in Database.recipes_for(station_id):
			if focus != "" and recipe_id != focus:
				continue
			_recipe_card(box, recipe_id, full))


## Fileira de bolinhas da estação: um espaço por vaga (vazio, fila, produzindo ou pronto, `Slot_<i>`)
## e, no fim, as ampliações que ainda dá para comprar ("+" e preço, `LockedSlot_<melhoria>`).
## Usada pelo painel (`station_view`) e pela bandeja de estação.
static func station_slot_row(station_id: String) -> HFlowContainer:
	if Database.stations[station_id].get("kind", "") == "animal":
		return _animal_slot_row(station_id)
	var target := GameState.station(station_id)
	var now := GameState.now()
	var row := slot_flow()
	for i in GameState.station_slots(station_id):
		var dot := _slot_card(target.queue[i] if i < target.queue.size() else {}, now)
		dot.name = "Slot_%d" % i
		row.add_child(dot)
	for upgrade_id: String in GameState.pending_slot_upgrades(station_id):
		row.add_child(_locked_slot(upgrade_id))
	return row


## Cada animal fica alinhado ao seu espaço; compras novas não participam do lote antigo.
static func _animal_slot_row(station_id: String) -> HFlowContainer:
	var row := slot_flow()
	row.name = "Herd"
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	var roster := GameState.animal_roster(station_id)
	row.custom_minimum_size.x = roster.size() * SlotDot.DOT + maxi(0, roster.size() - 1) * 8.0
	var queue := GameState.station(station_id).queue
	var entry: Dictionary = queue[0] if not queue.is_empty() else {}
	var fed: Dictionary = {}
	if not entry.is_empty():
		var per_animal := maxi(1, int(Database.recipes[entry.recipe].get("qty", 1)))
		var fallback := roster.slice(0, int(entry.get("qty", per_animal)) / per_animal)
		for id: String in entry.get("animals", fallback):
			fed[id] = int(fed.get(id, 0)) + 1
	for i in roster.size():
		var id: String = roster[i]
		var producing := int(fed.get(id, 0)) > 0
		if producing: fed[id] = int(fed[id]) - 1
		var column := UiKit.vbox(4)
		column.name = "Animal_%d" % i
		var portrait := UiKit.icon(load(Database.animals[id].sprite), 32)
		portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(portrait)
		var dot := _slot_card(entry if producing else {}, GameState.now())
		dot.name = "Slot_%d" % i
		column.add_child(dot)
		row.add_child(column)
	return row


static func _slot_card(entry: Dictionary, now: float) -> Control:
	if entry.is_empty():
		return slot_frame(null, "", 0.0, false, true)
	var recipe: Dictionary = Database.recipes[entry["recipe"]]
	var seconds := float(recipe["seconds"])
	var remaining := float(entry["ready_at"]) - now
	var texture := Database.item_icon(Database.recipe_output(recipe))
	if remaining <= 0.0:
		return slot_frame(texture, "Pronto!", 1.0, true, false)
	if remaining > seconds:
		return slot_frame(texture, "Na fila", 0.0, false, false, true)
	return slot_frame(texture, format_time(int(ceil(remaining))), 1.0 - remaining / seconds, false, false)


## Espaço ainda fechado: "+" e o preço; tocar abre a compra da ampliação.
static func _locked_slot(upgrade_id: String) -> Control:
	var data: Dictionary = Database.progression.upgrades[upgrade_id]
	var ready := GameState.upgrade_error(upgrade_id) == ""
	var cost := int(data.cost)
	var dot := UiKit.slot_dot(SlotDot.BUY, null, 1.0 if ready else 0.0, "Grátis" if cost <= 0 else str(cost),
			UiKit.GOOD if GameState.coins >= cost else UiKit.BAD, UiKit.ui_icon("coin") if cost > 0 else null)
	dot.name = "LockedSlot_" + upgrade_id
	if not ready:
		dot.modulate.a = 0.75
	dot.gui_input.connect(func(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			Events.sheet_requested.emit(str(data.name), ProgressionUi.purchase(upgrade_id)))
	return dot


## Um espaço de produção em bolinha (`SlotDot`): vazio, na fila, produzindo ou pronto.
## `text` é a legenda (tempo, "Na fila", "Pronto!").
static func slot_frame(texture: Texture2D, text: String, progress: float, done: bool, empty: bool, queued: bool = false) -> Control:
	var state := SlotDot.EMPTY if empty else (SlotDot.READY if done else (SlotDot.QUEUED if queued else SlotDot.BUSY))
	return UiKit.slot_dot(state, texture, progress, text, UiKit.GOOD if done else null)


## Fileira de bolinhas (quebra para a linha de baixo se não couber).
static func slot_flow() -> HFlowContainer:
	var row := UiKit.flow(8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return row


## Fileira de espaços e, ao lado, o botão "Pegar tudo (N)" (só aparece com `collect_text`; o único principal do painel).
static func slot_strip(slots: Control, collect_text: String = "", on_collect: Callable = Callable(), collect_name: String = "") -> Control:
	var strip := UiKit.hbox(8)
	strip.add_child(slots)
	if collect_text != "":
		var collect := UiKit.primary(collect_text, on_collect)
		collect.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		if collect_name != "":
			collect.name = collect_name
		strip.add_child(collect)
	return strip


## Linha de receita: o que sai, tempo, o que faz, o que precisa e o botão da estação.
static func _recipe_card(parent: VBoxContainer, recipe_id: String, station_full: bool) -> void:
	var recipe: Dictionary = Database.recipes[recipe_id]
	var locked := GameState.content_error("recipe", recipe_id, recipe)
	var output: String = Database.recipe_output(recipe)
	var inputs: Dictionary = GameState.recipe_inputs(recipe_id)
	var qty := GameState.recipe_quantity(recipe_id)

	# Chips: tempo, efeitos (comidas) e ingredientes (tocáveis quando faltam: mostram de onde vêm).
	var chips: Array[Control] = [UiKit.chip(UiKit.ui_icon("timer"), format_time(int(recipe["seconds"])))]
	chips.append_array(UiKit.effect_chip_list(Database.items.get(output, {}).get("feed", {})))
	var has_all := true
	for item_id: String in inputs:
		has_all = has_all and GameState.inventory.count(item_id) >= int(inputs[item_id])
		chips.append(ProgressionUi.item_chip(item_id, int(inputs[item_id])))

	var action: Button = null
	if locked == "":
		var label: String = Database.stations.get(recipe.station, {}).get("action_label", "Fazer")
		if recipe.has("output_collection") and GameState.cook_error(recipe_id) in ["Você já tem", "Já está sendo costurado"]:
			label = GameState.cook_error(recipe_id)
		action = UiKit.secondary("Fila cheia" if station_full and has_all else label, func() -> void:
			var error := GameState.cook(recipe_id)
			if error != "":
				Events.toast_requested.emit(error), null, true)
		action.disabled = GameState.cook_error(recipe_id) != ""
		action.custom_minimum_size.x = 88
	var row := UiKit.list_row(Database.item_icon(output), Database.item_name(output) + (" ×%d" % qty if qty > 1 else ""), chips, action)
	parent.add_child(row)
	if locked != "":
		# Receita fechada: linha apagada e cadeado com o motivo, no lugar do botão.
		row.modulate.a = 0.55
		(row.get_child(0) as VBoxContainer).add_child(UiKit.lock_hint(locked, TaskHelp.open.bind("recipe", recipe_id, int(recipe.get("qty", 1)))))


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
				if reason != "":
					Events.toast_requested.emit(reason), &"PrimaryButton")
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
			var chips: Array[Control] = [
				UiKit.chip(UiKit.ui_icon("timer"), format_time(int(crop["seconds"]))),
				UiKit.chip(UiKit.ui_icon("coin"), "+%d" % int(crop.get("coins", 0))),
			]
			var harvest: Dictionary = crop.get("yield", {})
			for item_id: String in harvest:
				chips.append(UiKit.chip(Database.item_icon(item_id), "+%d" % int(harvest[item_id]), UiKit.GOOD))
			var plant: Button = null
			if locked == "":
				plant = UiKit.secondary("Plantar", func() -> void:
					var error := GameState.plant(plot_index, crop_id)
					if error != "":
						Events.toast_requested.emit(error)
					Events.sheet_close_requested.emit(), null, true)
				plant.custom_minimum_size.x = 88
			var row := UiKit.list_row(Database.item_icon(crop_id), Database.item_name(crop_id), chips, plant)
			box.add_child(row)
			if locked != "":
				row.modulate.a = 0.6
				(row.get_child(0) as VBoxContainer).add_child(UiKit.lock_hint(locked, TaskHelp.open.bind("crop", crop_id))))


## Canteiros: terrenos (barra), próximo terreno e cada canteiro em ícone + estado.
static func farm_view(focus: String = "", greenhouse_only: bool = false) -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		if greenhouse_only:
			box.add_child(UiKit.label("Plantas delicadas · crescem mais rápido", &"SmallLabel"))
			var house_grid := GridContainer.new()
			house_grid.name = "GreenhousePlots"
			house_grid.columns = 2
			house_grid.add_theme_constant_override("h_separation", 6)
			house_grid.add_theme_constant_override("v_separation", 6)
			for index in GameState.usable_plot_indices():
				if GameState.is_greenhouse_plot(index):
					house_grid.add_child(_plot_tile(index, focus))
			box.add_child(house_grid)
			return
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
				Events.sheet_requested.emit("Abrir área", plot_purchase(GameState.unlocked_plots)), &"PrimaryButton" if GameState.coins >= cost else &"", UiKit.ui_icon("coin")))
		var grid := GridContainer.new()
		grid.columns = 3
		grid.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		var garden: Array[int] = []
		for index in GameState.usable_plot_indices():
			if not GameState.is_greenhouse_plot(index):
				garden.append(index)
		for index in garden:
			grid.add_child(_plot_tile(index, focus))
		box.add_child(grid)
	)


## Canteiro: vazio = "+" (plantar); crescendo = planta + %; pronto = planta + "Colher!".
static func _plot_tile(index: int, focus: String) -> Button:
	var status := GameState.plot_status(index)
	var crop: String = GameState.plot(index)["crop"]
	var caption := "Livre" if status == "empty" else ("Colher!" if status == "ready" else "%d%%" % int(GameState.plot_progress(index) * 100))
	# O resumo é só consulta: tocar num canteiro fecha o painel, leva a câmera até ele e abre a bandeja de ação.
	var tile := UiKit.button(caption, func() -> void:
		Events.sheet_close_requested.emit()
		Events.plot_tray_requested.emit(focus, index),
		&"PrimaryButton" if status == "ready" else &"", Database.item_icon(crop) if crop != "" else UiKit.ui_icon("tab_farm"))
	tile.custom_minimum_size = Vector2(0, 84)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.expand_icon = true
	tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	tile.add_theme_constant_override("icon_max_width", 32)
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
			if error != "":
				Events.toast_requested.emit(error)
			if error == "":
				Events.sheet_close_requested.emit(), &"PrimaryButton")
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
		add_theme_constant_override("separation", 8)

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
		if _pending or bool(get_meta("ui_animating", false)):
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
