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
			_empty_message(box, "Acabou a comida!", "Cozinhe algo no fogão da casa."))


## Conteúdo da geladeira (inventário completo) em grade.
static func inventory_view() -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		if GameState.inventory.counts.is_empty():
			_empty_message(box, "Geladeira vazia.", "")
			return
		var grid := GridContainer.new()
		grid.columns = 3
		grid.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		for id: String in GameState.inventory.counts:
			var tile := UiKit.card(grid)
			tile.alignment = BoxContainer.ALIGNMENT_CENTER
			var picture := UiKit.icon(Database.item_icon(id), 64)
			tile.add_child(picture)
			var count := UiKit.label("x%d" % GameState.inventory.count(id))
			count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tile.add_child(count)
			var item_name := UiKit.label(Database.item_name(id), &"SmallLabel")
			item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tile.add_child(item_name)
		box.add_child(grid))


## Estação de produção (fogão): espaços de preparo + receitas em cartões.
static func station_view(station_id: String) -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		var target := GameState.station(station_id)
		var now := GameState.now()
		var slots := int(Database.stations.get(station_id, {}).get("slots", 1))
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
	return _slot_frame(texture, _format_time(int(ceil(remaining))), 1.0 - remaining / seconds, false, false)


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
	details.add_child(UiKit.chip(UiKit.ui_icon("timer"), _format_time(int(recipe["seconds"]))))
	var feed: Dictionary = Database.items.get(output, {}).get("feed", {})
	for need_id: String in feed:
		details.add_child(UiKit.chip(Database.need_icon(need_id), "%+d" % int(feed[need_id]), UiKit.GOOD))
	info.add_child(details)
	top.add_child(info)
	body.add_child(top)

	body.add_child(UiKit.label("Precisa de:", &"SmallLabel"))
	var needs_row := UiKit.flow()
	var has_all := true
	for item_id: String in inputs:
		var need := int(inputs[item_id])
		var have := GameState.inventory.count(item_id)
		has_all = has_all and have >= need
		needs_row.add_child(UiKit.chip(Database.item_icon(item_id), "%d/%d %s" % [have, need, Database.item_name(item_id)],
			UiKit.GOOD if have >= need else UiKit.BAD))
	body.add_child(needs_row)

	var text := "Cozinhar"
	if not has_all:
		text = "Faltam ingredientes"
	elif station_full:
		text = "Fogão cheio"
	var cook := UiKit.button(text, func() -> void:
		var error := GameState.cook(recipe_id)
		Events.toast_requested.emit(error if error != "" else "Cozinhando %s!" % Database.item_name(output)), &"PrimaryButton")
	cook.disabled = not has_all or station_full
	body.add_child(cook)


static func _empty_message(box: VBoxContainer, title: String, hint: String) -> void:
	var body := UiKit.card(box)
	var text := UiKit.label(title)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(text)
	if hint != "":
		var small := UiKit.label(hint, &"SmallLabel")
		small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.add_child(small)


static func _format_time(seconds: int) -> String:
	if seconds >= 60 and seconds % 60 == 0:
		return "%d min" % (seconds / 60)
	if seconds >= 60:
		return "%d:%02d" % [seconds / 60, seconds % 60]
	return "%ds" % seconds


## Caixa que se reconstrói quando o estado muda e a cada segundo (timers).
class LiveBox extends VBoxContainer:
	var _build: Callable

	func _init(build: Callable) -> void:
		_build = build
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_PASS
		add_theme_constant_override("separation", 10)

	func _ready() -> void:
		Events.state_changed.connect(_rebuild)
		var timer := Timer.new()
		timer.wait_time = 1.0
		timer.autostart = true
		timer.timeout.connect(_on_tick)
		add_child(timer)
		_rebuild()

	func _on_tick() -> void:
		# Não reconstrói com o dedo na tela, para não "roubar" um toque em andamento.
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_rebuild()

	func _rebuild() -> void:
		for child in get_children():
			if not child is Timer:
				child.queue_free()
		_build.call(self)
