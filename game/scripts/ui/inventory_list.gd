class_name InventoryList
extends VBoxContainer
## Mochila e depósitos. Filtros nesta instância; selo até a próxima abertura.

const FILTERS := [
	{"id": "all", "text": "Tudo", "icon": "tab_bag"},
	{"id": "food", "text": "Comidas", "icon": "need_hunger"},
	{"id": "crop", "text": "Colheitas", "icon": "item_carrot"},
	{"id": "material", "text": "Materiais", "icon": "item_wood"},
	{"id": "product", "text": "Produtos", "icon": "station_chest"},
	{"id": "find", "text": "Achados", "icon": "find_paw"},
	{"id": "trail", "text": "Passeio", "icon": "action_walk"},
]
var storage: String = ""
var category: String = "all"
var fresh: Dictionary = {}
var _opened := false
var _filter_scroll := 0
var _gifts_open := false
var _body: SheetBuilder.LiveBox


func _init(only: String = "") -> void:
	storage = only
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name = "InventoryList"


func _ready() -> void:
	_body = SheetBuilder.LiveBox.new(_build)
	add_child(_body)
	visibility_changed.connect(_visibility)
	_visibility.call_deferred()


func _visibility() -> void:
	if not is_visible_in_tree():
		_opened = false
		return
	if _opened: return
	_opened = true
	fresh.clear()
	var keys: Array[String] = []
	for id: String in GameState.inventory.counts:
		if GameState.inventory.count(id) > 0 and not GameState.progress.seen.has("ui:bag:" + id):
			fresh[id] = true
			keys.append("ui:bag:" + id)
	if not keys.is_empty(): GameState.mark_seen(keys)
	_body.refresh()


func choose_category(id: String) -> void:
	category = id
	_body.refresh()


func choose_storage(id: String) -> void:
	storage = "" if storage == id else id
	category = "all"
	_body.refresh()


func toggle_gifts() -> void:
	_gifts_open = not _gifts_open
	_body.refresh()


## Guarda o que cabe dos presentes automáticos (nível, capítulo, vínculo). O resto continua esperando.
func store_gifts() -> void:
	var error := GameState.pending_reward_error()
	if error != "":
		Events.toast_requested.emit(error)
		return
	GameState.claim_pending_rewards()


## "Presentes para guardar (N)": só aparece quando há algo esperando; os detalhes ficam recolhidos.
func _gifts_card() -> Control:
	var card := PanelContainer.new()
	card.name = "PendingGifts"
	card.theme_type_variation = &"ReadyCardPanel"
	var inner := UiKit.vbox(6)
	card.add_child(inner)
	var head := UiKit.hbox(8)
	head.add_child(UiKit.icon(UiKit.ui_icon("item_treat_box"), 32))
	var title := UiKit.fill_label("Presentes para guardar (%d)" % GameState.pending_reward_total())
	title.name = "GiftsTitle"
	head.add_child(title)
	var toggle := UiKit.ghost("Ocultar" if _gifts_open else "Ver", toggle_gifts)
	toggle.name = "GiftsToggle"
	head.add_child(toggle)
	inner.add_child(head)
	var summary := {}
	for receipt: Dictionary in GameState.economy.pending.values():
		for item_id: String in receipt.items:
			summary[item_id] = int(summary.get(item_id, 0)) + int(receipt.items[item_id])
	if _gifts_open:
		for id: String in GameState.economy.pending:
			var receipt: Dictionary = GameState.economy.pending[id]
			inner.add_child(UiKit.label(str(receipt.label), &"SmallLabel", Palette.INK_SOFT))
			inner.add_child(_gift_chips(receipt.items))
	else:
		inner.add_child(_gift_chips(summary))
	var hint := GameState.pending_reward_hint()
	if GameState.pending_reward_error() == "":
		var save := UiKit.primary("Guardar", store_gifts)
		save.name = "StoreGifts"
		inner.add_child(save)
		if hint != "":
			inner.add_child(UiKit.label(hint, &"SmallLabel", Palette.INK_SOFT))
	else:
		var lock := UiKit.lock_hint(hint)
		lock.name = "GiftsBlocked"
		inner.add_child(lock)
	return card


## Guarda o que cabe da bagagem do último passeio. O resto continua esperando, sem perder nada.
func store_baggage() -> void:
	var error := GameState.walk_baggage_error()
	if error != "":
		Events.toast_requested.emit(error)
		return
	GameState.claim_walk_baggage()


## "Achados do passeio (N)": o Tiro já voltou; a bagagem espera aqui e na Praça, sem prender nada.
func _baggage_card() -> Control:
	var card := PanelContainer.new()
	card.name = "WalkBaggage"
	card.theme_type_variation = &"ReadyCardPanel"
	var inner := UiKit.vbox(6)
	card.add_child(inner)
	var head := UiKit.hbox(8)
	head.add_child(UiKit.icon(UiKit.ui_icon("action_walk"), 32))
	var title := UiKit.fill_label("Achados do passeio (%d)" % GameState.walk_state.baggage_count())
	title.name = "BaggageTitle"
	head.add_child(title)
	inner.add_child(head)
	inner.add_child(_gift_chips(GameState.walk_state.baggage_left(), "Baggage_"))
	var error := GameState.walk_baggage_error()
	if error == "":
		# Um botão verde por tela: com presentes também esperando, este vira secundário.
		var save := UiKit.secondary("Guardar achados", store_baggage) if GameState.pending_reward_count() > 0 else UiKit.primary("Guardar achados", store_baggage)
		save.name = "StoreBaggage"
		inner.add_child(save)
		var hint := GameState.walk_baggage_hint()
		if hint != "":
			inner.add_child(UiKit.label(hint, &"SmallLabel", Palette.INK_SOFT))
	else:
		var lock := UiKit.lock_hint(error)
		lock.name = "BaggageBlocked"
		inner.add_child(lock)
	return card


## Itens esperando, tocáveis: levam ao depósito onde vão morar (se ele já tem limite).
func _gift_chips(items: Dictionary, prefix: String = "Gift_") -> Control:
	var row := UiKit.flow(4)
	for item_id: String in items:
		var depot := GameState.storage_of(item_id)
		var chip := UiKit.tap_chip(Database.item_icon(item_id), "×%d" % int(items[item_id]), func() -> void:
			if depot != "" and GameState.storage_active(depot):
				choose_storage(depot)
			else:
				Events.sheet_requested.emit(Database.item_name(item_id), SheetBuilder.item_detail(item_id)))
		chip.name = prefix + item_id
		row.add_child(chip)
	return row


func _build(box: VBoxContainer) -> void:
	if GameState.walk_ready():
		box.add_child(_baggage_card())
	if GameState.pending_reward_count() > 0:
		box.add_child(_gifts_card())
	for id: String in Database.progression.storage:
		if not GameState.storage_active(id) or (not GameState.has_upgrade(str(Database.progression.storage[id].building)) and GameState.storage_used(id) == 0): continue
		var data: Dictionary = Database.progression.storage[id]
		var building: Dictionary = Database.progression.upgrades.get(str(data.building), {})
		var button := UiKit.ghost("", choose_storage.bind(id))
		button.name = "Storage_" + id
		button.custom_minimum_size.y = 40
		var contents := UiKit.hbox(6)
		contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		contents.add_child(UiKit.icon(UiKit.ui_icon(str(building.get("icon", "station_" + id))), 32))
		contents.add_child(UiKit.fill_label(GameState.storage_name(id), &"SmallLabel", Palette.GOOD if storage == id else Palette.INK))
		var capacity := GameState.storage_capacity(id)
		var used := GameState.storage_used(id)
		var bar := UiKit.bar(100.0 * used / maxi(1, capacity), Palette.BAD if used >= capacity else Palette.INFO, 8)
		bar.custom_minimum_size.x = 64
		contents.add_child(bar)
		# Acima do limite (estoque que já existia): o número fica vermelho, nada some.
		contents.add_child(UiKit.short_label("%d/%d" % [used, capacity], &"SmallLabel", Palette.BAD if used > capacity else null))
		button.add_child(contents)
		box.add_child(button)
	var categories: Array[String] = []
	for id: String in GameState.inventory.counts:
		if GameState.inventory.count(id) > 0 and (storage == "" or GameState.storage_of(id) == storage):
			categories.append(str(Database.items.get(id, {}).get("category", "product")))
	if category not in categories: category = "all"
	var options: Array[Dictionary] = []
	for entry: Dictionary in FILTERS:
		if entry.id == "all" or entry.id in categories:
			options.append({"id": entry.id, "text": entry.text, "icon": UiKit.ui_icon(entry.icon)})
	var scroll := ScrollContainer.new()
	scroll.name = "BagFilters"
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.add_child(UiKit.segmented(options, category, choose_category))
	scroll.get_h_scroll_bar().value_changed.connect(func(value: float) -> void: _filter_scroll = int(value))
	scroll.set_deferred("scroll_horizontal", _filter_scroll)
	box.add_child(scroll)
	var grid := GridContainer.new()
	grid.name = "BagGrid"
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	for id: String in GameState.inventory.counts:
		if GameState.inventory.count(id) <= 0: continue
		if storage != "" and GameState.storage_of(id) != storage: continue
		if category != "all" and Database.items.get(id, {}).get("category", "product") != category: continue
		var tile := UiKit.grid_tile(Database.item_icon(id), "", func() -> void:
			Events.sheet_requested.emit(Database.item_name(id), SheetBuilder.item_detail(id)))
		tile.name = "Item_" + id
		tile.tooltip_text = Database.item_name(id)
		var number := UiKit.short_label("×%d" % GameState.inventory.count(id), &"NumberLabel")
		number.name = "Quantity"
		number.add_theme_font_size_override("font_size", 18)
		number.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		number.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		number.grow_vertical = Control.GROW_DIRECTION_BEGIN
		number.position = Vector2(-30, -24)
		tile.add_child(number)
		if fresh.has(id):
			var badge := UiKit.short_label("Novo", &"SmallLabel", Palette.GOOD)
			badge.name = "NewBadge"
			badge.position = Vector2(4, 0)
			tile.add_child(badge)
		grid.add_child(tile)
	box.add_child(grid)
	if grid.get_child_count() == 0:
		box.add_child(UiKit.label("Nada por aqui ainda.", &"SmallLabel"))
