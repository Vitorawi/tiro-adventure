class_name SheetBuilder
extends RefCounted
## Monta o conteúdo dos painéis inferiores (sheets) usados por várias telas.
## Uso: Events.sheet_requested.emit("Título", SheetBuilder.food_picker())


## Lista de comidas do inventário com botão "Dar".
static func food_picker() -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		var any := false
		for id: String in Database.items:
			if not Database.items[id].has("feed") or GameState.inventory.count(id) == 0:
				continue
			any = true
			var effects := _describe_effects(Database.items[id]["feed"])
			box.add_child(_row("%s  x%d\n%s" % [Database.item_name(id), GameState.inventory.count(id), effects], "Dar",
				func() -> void:
					if GameState.feed(id):
						Events.toast_requested.emit("Nhac! %s" % Database.item_name(id))
						Events.sheet_close_requested.emit()))
		if not any:
			box.add_child(_label("Sem comida. Cozinhe algo no fogão!")))


## Conteúdo da geladeira (inventário completo).
static func inventory_view() -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		if GameState.inventory.counts.is_empty():
			box.add_child(_label("Geladeira vazia."))
		for id: String in GameState.inventory.counts:
			box.add_child(_label("%s  x%d" % [Database.item_name(id), GameState.inventory.count(id)])))


## Receitas e fila de uma estação de produção.
static func station_view(station_id: String) -> Control:
	return LiveBox.new(func(box: VBoxContainer) -> void:
		var target := GameState.station(station_id)
		var now := GameState.now()
		var slots := int(Database.stations.get(station_id, {}).get("slots", 1))

		box.add_child(_header("Fila (%d/%d)" % [target.queue.size(), slots]))
		if target.queue.is_empty():
			box.add_child(_label("Nada cozinhando."))
		for entry in target.queue:
			var remaining := int(ceil(float(entry["ready_at"]) - now))
			var status := "Pronto!" if remaining <= 0 else _format_time(remaining)
			box.add_child(_label("%s — %s" % [Database.item_name(Database.recipes[entry["recipe"]]["output"]), status]))
		if target.ready_count(now) > 0:
			box.add_child(_button("Coletar", func() -> void:
				var received := GameState.collect(station_id)
				Events.toast_requested.emit("Recebeu " + Database.describe_amounts(received))))

		box.add_child(_header("Receitas"))
		for recipe_id in Database.recipes_for(station_id):
			var recipe: Dictionary = Database.recipes[recipe_id]
			var can := GameState.inventory.has_all(recipe["inputs"]) and target.queue.size() < slots
			var text := "%s  (%s)\nPrecisa: %s" % [
				Database.item_name(recipe["output"]),
				_format_time(int(recipe["seconds"])),
				Database.describe_amounts(recipe["inputs"]),
			]
			var row := _row(text, "Cozinhar", func() -> void:
				var error := GameState.cook(recipe_id)
				if error != "":
					Events.toast_requested.emit(error))
			row.get_child(1).disabled = not can
			box.add_child(row))


# --- Helpers ---------------------------------------------------------------

static func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


static func _header(text: String) -> Label:
	var label := _label(text)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	return label


static func _button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(110, 48)
	button.pressed.connect(on_pressed)
	return button


static func _row(text: String, button_text: String, on_pressed: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_child(_label(text))
	row.add_child(_button(button_text, on_pressed))
	return row


static func _describe_effects(effects: Dictionary) -> String:
	var parts: PackedStringArray = []
	for id: String in effects:
		var need_name: String = Database.needs.get(id, {}).get("name", id)
		parts.append("%+d %s" % [int(effects[id]), need_name])
	return ", ".join(parts)


static func _format_time(seconds: int) -> String:
	if seconds >= 60 and seconds % 60 == 0:
		return "%d min" % (seconds / 60)
	if seconds >= 60:
		return "%dm%02ds" % [seconds / 60, seconds % 60]
	return "%ds" % seconds


## Caixa que se reconstrói quando o estado muda e a cada segundo (timers).
class LiveBox extends VBoxContainer:
	var _build: Callable

	func _init(build: Callable) -> void:
		_build = build
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
