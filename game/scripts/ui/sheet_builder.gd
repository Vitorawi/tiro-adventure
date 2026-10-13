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
		for id: String in Database.items:
			if not Database.items[id].has("feed") or GameState.inventory.count(id) == 0:
				continue
			any = true
			var body := UiKit.card(box)
			var row := UiKit.hbox(10)
			row.add_child(UiKit.icon(Database.item_icon(id), 64))
			var info := UiKit.vbox(4)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.add_child(UiKit.label("x%d" % GameState.inventory.count(id)))
			info.add_child(UiKit.effect_chips(Database.items[id]["feed"]))
			row.add_child(info)
			var give := UiKit.button("Dar", func() -> void:
				if GameState.feed(id):
					Events.toast_requested.emit("Nhac! %s" % Database.item_name(id))
					Events.sheet_close_requested.emit(), &"PrimaryButton")
			give.custom_minimum_size = Vector2(76, 52)
			give.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(give)
			body.add_child(row)
		if not any:
			_empty_message(box, "Acabou a comida!", "")
			box.add_child(UiKit.button("Pedir à Bloblo", func() -> void:
				var error := GameState.emergency_food()
				Events.toast_requested.emit(error if error != "" else "Comida recebida!"), &"PrimaryButton", ProgressionUi.npc_portrait("bloblo"))))


const CATEGORIES := {"food": "Comidas", "crop": "Colheitas", "material": "Materiais", "product": "Produtos"}


## Mochila (também é a geladeira): ícone + quantidade por categoria; tocar abre o detalhe.
static func inventory_view() -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		if GameState.inventory.counts.is_empty():
			_empty_message(box, "Mochila vazia.", "")
			return
		for category: String in CATEGORIES:
			var ids: Array[String] = []
			for id: String in GameState.inventory.counts:
				if Database.items.get(id, {}).get("category", "product") == category:
					ids.append(id)
			if ids.is_empty():
				continue
			box.add_child(UiKit.label(CATEGORIES[category], &"SectionLabel"))
			var grid := GridContainer.new()
			grid.columns = 4
			grid.mouse_filter = Control.MOUSE_FILTER_PASS
			grid.add_theme_constant_override("h_separation", 6)
			grid.add_theme_constant_override("v_separation", 6)
			for id in ids:
				grid.add_child(_item_tile(id))
			box.add_child(grid))


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
		_link_section(box, "De onde vem", _sources(id))
		_link_section(box, "Usado em", _uses(id))
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
			links.append({"icon": Database.item_icon(recipe.output), "name": Database.item_name(recipe.output), "target": {"world": location[0], "place": "recipe:" + recipe_id, "spot": location[1]}})
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

		box.add_child(UiKit.label("%s  %d/%d" % [data.get("queue_label", "Preparando"), target.queue.size(), slots], &"SectionLabel"))
		var slot_row := UiKit.hbox(8)
		for i in slots:
			slot_row.add_child(_slot_card(target.queue[i] if i < target.queue.size() else {}, now))
		box.add_child(slot_row)
		var ready := target.ready_count(now)
		if ready > 0:
			box.add_child(UiKit.button("Coletar prontos (%d)" % ready, func() -> void:
				var received := GameState.collect(station_id)
				Events.toast_requested.emit("Recebeu " + Database.describe_amounts(received)), &"PrimaryButton"))

		box.add_child(UiKit.label(data.get("recipe_label", "Receitas"), &"SectionLabel"))
		for recipe_id in Database.recipes_for(station_id):
			if focus != "" and recipe_id != focus:
				continue
			_recipe_card(box, recipe_id, full))


static func _slot_card(entry: Dictionary, now: float) -> Control:
	if entry.is_empty():
		return _slot_frame(null, "Livre", 0.0, false, true)
	var recipe: Dictionary = Database.recipes[entry["recipe"]]
	var seconds := float(recipe["seconds"])
	var remaining := float(entry["ready_at"]) - now
	var texture := Database.item_icon(recipe["output"])
	if remaining <= 0.0:
		return _slot_frame(texture, "Pronto!", 1.0, true, false)
	if remaining > seconds:
		return _slot_frame(texture, "Na fila", 0.0, false, false)
	return _slot_frame(texture, format_time(int(ceil(remaining))), 1.0 - remaining / seconds, false, false)


static func _slot_frame(texture: Texture2D, text: String, progress: float, done: bool, empty: bool) -> Control:
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
		box.add_child(UiKit.bar(progress * 100.0, Color(0.96, 0.62, 0.25), 10))
	panel.add_child(box)
	return panel


## Cartão de receita: o que sai, quanto tempo leva, o que faz e o que precisa.
static func _recipe_card(parent: VBoxContainer, recipe_id: String, station_full: bool) -> void:
	var recipe: Dictionary = Database.recipes[recipe_id]
	var locked := GameState.content_error("recipe", recipe_id, recipe)
	var output: String = recipe["output"]
	var inputs: Dictionary = recipe["inputs"]
	var body := UiKit.card(parent)

	var top := UiKit.hbox(10)
	top.add_child(UiKit.icon(Database.item_icon(output), 64))
	var info := UiKit.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var qty := int(recipe.get("qty", 1))
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

	var row := UiKit.hbox(8)
	var action: String = Database.stations.get(recipe.station, {}).get("action_label", "Produzir")
	var cook := UiKit.button("Fila cheia" if station_full and has_all and locked == "" else action, func() -> void:
		var error := GameState.cook(recipe_id)
		Events.toast_requested.emit(error if error != "" else "Preparando %s!" % Database.item_name(output)), &"PrimaryButton")
	cook.disabled = GameState.cook_error(recipe_id) != ""
	cook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cook)
	if not has_all or locked != "":
		row.add_child(UiKit.square_button("?", TaskHelp.open.bind("recipe", recipe_id, int(recipe.get("qty", 1)))))
	body.add_child(row)
	if locked != "":
		body.add_child(UiKit.label(locked, &"SmallLabel"))


## Sementes para um canteiro vazio: [planta] nome · tempo · moedas · colheita · [Plantar].
## Bloqueada: apagada, com "?" que mostra como liberar.
static func seed_picker(plot_index: int, focus: String = "") -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		for crop_id: String in Database.crops:
			if focus != "" and crop_id != focus:
				continue
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
			if locked != "":
				row.add_child(UiKit.square_button("?", TaskHelp.open.bind("crop", crop_id)))
			else:
				var plant := UiKit.button("Plantar", func() -> void:
					var error := GameState.plant(plot_index, crop_id)
					Events.toast_requested.emit(error if error != "" else "Plantou %s!" % Database.item_name(crop_id))
					Events.sheet_close_requested.emit(), &"PrimaryButton")
				plant.custom_minimum_size = Vector2(92, 52)
				plant.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				row.add_child(plant)
			body.add_child(row))


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
		for index in GameState.accessible_plots():
			grid.add_child(_plot_tile(index, focus))
		box.add_child(grid))


## Canteiro: vazio = "+" (plantar); crescendo = planta + %; pronto = planta + "Colher!".
static func _plot_tile(index: int, focus: String) -> Button:
	var status := GameState.plot_status(index)
	var crop: String = GameState.plot(index)["crop"]
	var caption := "Plantar" if status == "empty" else ("Colher!" if status == "ready" else "%d%%" % int(GameState.plot_progress(index) * 100))
	var tile := UiKit.button(caption, func() -> void:
		Events.sheet_requested.emit("Canteiro %d" % (index + 1), seed_picker(index, focus) if GameState.plot_status(index) == "empty" else growing_plot(index)),
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
					Events.toast_requested.emit("Colheu " + Database.describe_amounts(received) + "! +%d moedas" % reward), &"PrimaryButton")))


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
