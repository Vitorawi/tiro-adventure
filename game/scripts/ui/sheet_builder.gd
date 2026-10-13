class_name SheetBuilder
extends RefCounted
## Monta o conteúdo dos painéis inferiores (sheets) usados por várias telas.
## Uso: Events.sheet_requested.emit("Título", SheetBuilder.food_picker())
## Peças visuais vêm do UiKit; ícones de itens/necessidades vêm do Database.


## Comidas do inventário: o que cada uma faz e botão "Dar".
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
			info.add_child(UiKit.label(Database.item_name(id)))
			info.add_child(UiKit.label("Você tem %d" % GameState.inventory.count(id), &"SmallLabel"))
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
			_empty_message(box, "Acabou a comida!", "A Bloblo pode ajudar enquanto você prepara a próxima colheita.")
			box.add_child(UiKit.button("Pedir comida à Bloblo", func() -> void:
				var error := GameState.emergency_food()
				Events.toast_requested.emit(error if error != "" else "Comida recebida!"), &"PrimaryButton")))


const CATEGORIES := {"food": "Comidas", "crop": "Colheitas", "material": "Materiais", "product": "Produtos"}


## Mochila (também é a geladeira): itens por categoria; tocar abre o detalhe do item.
static func inventory_view() -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		if GameState.inventory.counts.is_empty():
			_empty_message(box, "Mochila vazia.", "Plante no Sítio ou passeie na Trilha (aba Mapa).")
			return
		box.add_child(UiKit.label("Toque num item para ver para que ele serve.", &"SmallLabel"))
		for category: String in CATEGORIES:
			var ids: Array[String] = []
			for id: String in GameState.inventory.counts:
				if Database.items.get(id, {}).get("category", "product") == category:
					ids.append(id)
			if ids.is_empty():
				continue
			box.add_child(UiKit.label(CATEGORIES[category], &"SectionLabel"))
			var grid := GridContainer.new()
			grid.columns = 3
			grid.mouse_filter = Control.MOUSE_FILTER_PASS
			grid.add_theme_constant_override("h_separation", 8)
			grid.add_theme_constant_override("v_separation", 8)
			for id in ids:
				grid.add_child(_item_tile(id))
			box.add_child(grid))


static func _item_tile(id: String) -> Button:
	var tile := UiKit.button("%s\nx%d" % [Database.item_name(id), GameState.inventory.count(id)], func() -> void:
		Events.sheet_requested.emit(Database.item_name(id), item_detail(id)), &"", Database.item_icon(id))
	tile.custom_minimum_size = Vector2(0, 112)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.expand_icon = true
	tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	tile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tile.add_theme_constant_override("icon_max_width", 48)
	tile.add_theme_font_size_override("font_size", 16)
	return tile


## Detalhe do item: o que faz, como conseguir, onde usar e quanto vale.
static func item_detail(id: String) -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		var item: Dictionary = Database.items.get(id, {})
		var top := UiKit.hbox(10)
		top.add_child(UiKit.icon(Database.item_icon(id), 64))
		var info := UiKit.vbox(4)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(UiKit.label(Database.item_name(id), &"SectionLabel"))
		info.add_child(UiKit.label("Você tem %d" % GameState.inventory.count(id)))
		top.add_child(info)
		box.add_child(top)
		if item.has("feed"):
			box.add_child(UiKit.effect_chips(item.feed))
			var give := UiKit.button("Dar ao Tiro", func() -> void:
				if GameState.feed(id):
					Events.toast_requested.emit("Nhac! %s" % Database.item_name(id)), &"PrimaryButton")
			give.disabled = GameState.inventory.count(id) == 0
			box.add_child(give)
		_list_section(box, "Como conseguir", Database.sources_of(id))
		_list_section(box, "Usado em", Database.uses_of(id))
		var price := int(item.get("sell_price", 0))
		if price > 0:
			box.add_child(UiKit.label("Vale %d moedas na feira da Vila." % price, &"SmallLabel"))
			var place := Database.place_with_panel("sell")
			if place[0] != "" and GameState.inventory.count(id) > 0:
				box.add_child(UiKit.button("Ir vender", func() -> void:
					Events.sheet_close_requested.emit()
					Events.world_requested.emit(place[0], place[1]), &"", UiKit.ui_icon("coin"))))


static func _list_section(box: VBoxContainer, title: String, lines: PackedStringArray) -> void:
	if lines.is_empty():
		return
	box.add_child(UiKit.label(title, &"SectionLabel"))
	for line in lines:
		box.add_child(UiKit.label("• " + line, &"SmallLabel"))


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

		box.add_child(UiKit.label("Preparando  %d/%d" % [target.queue.size(), slots], &"SectionLabel"))
		var slot_row := UiKit.hbox(8)
		for i in slots:
			slot_row.add_child(_slot_card(target.queue[i] if i < target.queue.size() else {}, now))
		box.add_child(slot_row)
		var ready := target.ready_count(now)
		if ready > 0:
			box.add_child(UiKit.button("Coletar prontos (%d)" % ready, func() -> void:
				var received := GameState.collect(station_id)
				Events.toast_requested.emit("Recebeu " + Database.describe_amounts(received)), &"PrimaryButton"))

		box.add_child(UiKit.label("Receitas", &"SectionLabel"))
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
	var cook := UiKit.button("Fila cheia" if station_full and has_all and locked == "" else "Produzir", func() -> void:
		var error := GameState.cook(recipe_id)
		Events.toast_requested.emit(error if error != "" else "Preparando %s!" % Database.item_name(output)), &"PrimaryButton")
	cook.disabled = not has_all or station_full or locked != ""
	cook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cook)
	if not has_all or locked != "":
		row.add_child(UiKit.square_button("?", TaskHelp.open.bind("recipe", recipe_id, int(recipe.get("qty", 1)))))
	body.add_child(row)
	if locked != "":
		body.add_child(UiKit.label(locked, &"SmallLabel"))


## Sementes para um canteiro vazio: o que nasce, quanto tempo leva e quanto rende.
static func seed_picker(plot_index: int, focus: String = "") -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		box.add_child(UiKit.label("A Bloblo empresta as sementes. Escolha o que plantar:", &"SmallLabel"))
		for crop_id: String in Database.crops:
			if focus != "" and crop_id != focus:
				continue
			var crop: Dictionary = Database.crops[crop_id]
			var locked := GameState.content_error("crop", crop_id, crop)
			var body := UiKit.card(box)
			var row := UiKit.hbox(10)
			row.add_child(UiKit.icon(Database.item_icon(crop_id), 64))
			var info := UiKit.vbox(4)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.add_child(UiKit.label(Database.item_name(crop_id)))
			var details := UiKit.flow()
			details.add_child(UiKit.chip(UiKit.ui_icon("timer"), format_time(int(crop["seconds"]))))
			var harvest: Dictionary = crop.get("yield", {})
			details.add_child(UiKit.chip(UiKit.ui_icon("coin"), "+%d moedas" % int(crop.get("coins", 0))))
			for item_id: String in harvest:
				details.add_child(UiKit.chip(Database.item_icon(item_id), "+%d" % int(harvest[item_id]), UiKit.GOOD))
			info.add_child(details)
			info.add_child(UiKit.label("+%d XP Agricultura" % int(crop.get("skill_xp", 10)), &"SmallLabel"))
			if locked != "":
				info.add_child(UiKit.label(locked, &"SmallLabel"))
			row.add_child(info)
			var plant := UiKit.button("Plantar", func() -> void:
				var error := GameState.plant(plot_index, crop_id)
				Events.toast_requested.emit(error if error != "" else "Plantou %s!" % Database.item_name(crop_id))
				Events.sheet_close_requested.emit(), &"PrimaryButton")
			plant.custom_minimum_size = Vector2(96, 52)
			plant.disabled = locked != ""
			plant.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(plant)
			body.add_child(row))


## Resumo da expansão e caminho de volta para cada canteiro.
static func farm_view(focus: String = "") -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		var total := int(Database.farm.get("plots", 0))
		if not GameState.has_upgrade("farm"):
			box.add_child(UiKit.label("Um canteiro emprestado", &"SectionLabel"))
			box.add_child(UiKit.label("Plante de graça, colha e junte moedas para comprar seu sítio.", &"SmallLabel"))
			box.add_child(UiKit.button("Comprar o sítio", func() -> void:
				Events.sheet_requested.emit("Escritura do sítio", ProgressionUi.purchase("farm")), &"PrimaryButton"))
			box.add_child(UiKit.button("Conversar com a Bloblo", func() -> void:
				Events.sheet_requested.emit("Bloblo", ProgressionUi.npc_view("bloblo"))))
		box.add_child(UiKit.label("%d de %d terrenos cultiváveis" % [GameState.accessible_plots(), total], &"SectionLabel"))
		box.add_child(UiKit.bar(100.0 * GameState.accessible_plots() / total, UiKit.GOOD))
		box.add_child(UiKit.label("Colha para ganhar moedas e ampliar o sítio. Os terrenos têm lugar certo no mapa.", &"SmallLabel"))
		box.add_child(UiKit.label("Você tem %d moedas" % GameState.coins))
		if GameState.has_upgrade("farm") and GameState.unlocked_plots < total:
			box.add_child(UiKit.button("Próximo terreno · %d moedas" % GameState.plot_cost(GameState.unlocked_plots), func() -> void:
				Events.sheet_requested.emit("Expandir o sítio", plot_purchase(GameState.unlocked_plots)), &"PrimaryButton"))
		elif GameState.has_upgrade("farm"):
			box.add_child(UiKit.label("Sítio completo! Todos os terrenos são seus.", &"SectionLabel", UiKit.GOOD))
		for index in GameState.accessible_plots():
			var status := GameState.plot_status(index)
			var caption := "Terreno %d · Plantar" % (index + 1)
			if status != "empty":
				caption = "%s · %s" % [Database.item_name(GameState.plot(index)["crop"]), "Colher!" if status == "ready" else "%d%%" % int(GameState.plot_progress(index) * 100)]
			box.add_child(UiKit.button(caption, func() -> void:
				Events.sheet_requested.emit("Canteiro %d" % (index + 1), seed_picker(index, focus) if GameState.plot_status(index) == "empty" else growing_plot(index)))))


static func plot_purchase(index: int) -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		var cost := GameState.plot_cost(index)
		box.add_child(UiKit.label("Terreno %d" % (index + 1), &"SectionLabel"))
		box.add_child(UiKit.label("Mais um espaço para plantar, na posição marcada no sítio.", &"SmallLabel"))
		box.add_child(UiKit.label("Preço: %d moedas · Você tem: %d" % [cost, GameState.coins]))
		var available := index == GameState.unlocked_plots
		var owned := index < GameState.unlocked_plots
		if owned:
			box.add_child(UiKit.label("Este terreno já é seu!", &"", UiKit.GOOD))
		elif not available:
			box.add_child(UiKit.label("Compre o terreno %d primeiro." % (GameState.unlocked_plots + 1), &"SmallLabel"))
		elif GameState.coins < cost:
			box.add_child(UiKit.label("Faltam %d moedas. Continue colhendo para juntar!" % (cost - GameState.coins), &"SmallLabel"))
		var buy := UiKit.button("Comprar por %d moedas" % cost, func() -> void:
			var error := GameState.buy_plot(index)
			Events.toast_requested.emit(error if error != "" else "Novo terreno! Já pode plantar.")
			if error == "":
				Events.sheet_requested.emit("Canteiro %d" % (index + 1), seed_picker(index)), &"PrimaryButton")
		buy.disabled = not available or GameState.coins < cost or cost < 0
		box.add_child(buy))


static func growing_plot(index: int) -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		var target := GameState.plot(index)
		if target["crop"] == "":
			box.add_child(UiKit.label("Colheita recolhida!"))
			box.add_child(UiKit.button("Plantar de novo", func() -> void:
				Events.sheet_requested.emit("Canteiro", seed_picker(index)), &"PrimaryButton"))
			return
		var crop_id: String = target["crop"]
		var ready := GameState.plot_status(index) == "ready"
		box.add_child(UiKit.icon(Database.item_icon(crop_id), 64))
		box.add_child(UiKit.label(Database.item_name(crop_id), &"SectionLabel"))
		box.add_child(UiKit.bar(GameState.plot_progress(index) * 100, UiKit.GOOD))
		var remaining := maxi(0, int(ceil(float(target["ready_at"]) - GameState.now())))
		box.add_child(UiKit.label("Pronta para colher!" if ready else "%d%% · Faltam %s" % [int(GameState.plot_progress(index) * 100), format_time(remaining)]))
		var reward := int(Database.crops[crop_id].get("coins", 0))
		box.add_child(UiKit.label("Colheita: %s e %d moedas" % [Database.describe_amounts(Database.crops[crop_id].get("yield", {})), reward], &"SmallLabel"))
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
