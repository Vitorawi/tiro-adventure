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


func _build(box: VBoxContainer) -> void:
	for id: String in Database.progression.storage:
		if not GameState.storage_active(id): continue
		var data: Dictionary = Database.progression.storage[id]
		var building: Dictionary = Database.progression.upgrades.get(str(data.building), {})
		var button := UiKit.ghost("", choose_storage.bind(id))
		button.name = "Storage_" + id
		button.custom_minimum_size.y = 40
		var contents := UiKit.hbox(6)
		contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		contents.add_child(UiKit.icon(UiKit.ui_icon(str(building.get("icon", "station_" + id))), 32))
		contents.add_child(UiKit.fill_label(str(data.name), &"SmallLabel", Palette.GOOD if storage == id else Palette.INK))
		var capacity := GameState.storage_capacity(id)
		var used := GameState.storage_used(id)
		var bar := UiKit.bar(100.0 * used / maxi(1, capacity), Palette.BAD if used >= capacity else Palette.INFO, 8)
		bar.custom_minimum_size.x = 64
		contents.add_child(bar)
		contents.add_child(UiKit.short_label("%d/%d" % [used, capacity], &"SmallLabel"))
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
