class_name FishingPanel
extends Control
## Painel de arremesso da lagoa (etapa 02 da pesca): bandeja de madeira presa embaixo, como as das estações.
## Vara (2+), isca, os 3 peixes da isca com o recorde e o botão verde "Arremessar" (segurar = força).
## Só mostra e pede; as regras ficam no GameState (`cast`) e o fluxo no `FishingFlow`.

signal cast_requested(bait: String, zone: int, power: float)
signal closed

const SIDE := 8.0
const MAX_WIDTH := 420.0
const TOP_LIMIT := 120.0
const BOTTOM_LIMIT := 34.0

static var current: FishingPanel

var room: RoomView
## Força fixa (0..1) para teste/captura; negativo = o ponteiro anda sozinho.
var power_override := -1.0

var _box: Control
var _panel: PanelContainer
var _column: VBoxContainer
var _body: VBoxContainer
var _power: PowerBar
var _cast_button: Button
var _holding := false
var _press_time := 0.0
var _closing := false
var _bait := ""
var _signature := ""
var _nav_bar: Control


static func open(for_room: RoomView) -> FishingPanel:
	close_current(for_room, true)
	var panel := FishingPanel.new()
	panel.name = "FishingPanel"
	panel.room = for_room
	for_room.add_child(panel)
	current = panel
	panel._build()
	return panel


static func is_open(for_room: RoomView) -> bool:
	return is_instance_valid(current) and not current._closing and current.room == for_room


static func close_current(for_room: RoomView = null, immediate: bool = false) -> void:
	if is_instance_valid(current) and (for_room == null or current.room == for_room):
		current.close(immediate)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 5
	z_as_relative = false  # acima do mundo, abaixo de abas, HUD e painéis (igual à bandeja de ação)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _exit_tree() -> void:
	if current == self:
		current = null


func _build() -> void:
	_box = Control.new()
	_box.name = "Box"
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_panel.custom_minimum_size.x = _width()
	_panel.add_child(StationWood.backing("frame", 60, 60, "Frame"))
	var pad := MarginContainer.new()
	pad.name = "Pad"
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right"]:
		pad.add_theme_constant_override("margin_" + side, 26)
	for side: String in ["top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 20)
	_panel.add_child(pad)
	_column = UiKit.vbox(6)
	_column.name = "Column"
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(_column)
	_box.add_child(_panel)
	_nav_bar = get_tree().root.find_child("TabBar", true, false) as Control
	_bait = _default_bait()
	_refresh()
	Events.state_changed.connect(_on_state_changed)
	_place()
	room.resized.connect(_place)
	if not Motion.reduced:
		_box.modulate.a = 0.0
		_box.scale = Vector2.ONE * 0.92
		var tween := create_tween().set_parallel()
		tween.tween_property(_box, "scale", Vector2.ONE, Motion.TRAY_IN).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(_box, "modulate:a", 1.0, Motion.TRAY_IN)


func _width() -> float:
	return minf(room.size.x - SIDE * 2.0, MAX_WIDTH) if room.size.x > 0.0 else 344.0


# --- Dados ---------------------------------------------------------------------------------

func _rod_id() -> String:
	return GameState.current_rod()


func _rod_def(id: String) -> Dictionary:
	return Database.fishing.get("rods", {}).get(id, {})


func _rod_icon(id: String) -> Texture2D:
	var path := str(_rod_def(id).get("icon", ""))
	return load(path) as Texture2D if path != "" else null


## Isca padrão: a última usada se a vara aceita; senão a primeira com estoque; senão a primeira que a vara aceita.
func _default_bait() -> String:
	var accepted: Array = _rod_def(_rod_id()).get("baits", [])
	var saved := GameState.fishing.bait
	if saved != "" and saved in accepted:
		return saved
	for id: String in accepted:
		if GameState.inventory.count(id) > 0:
			return id
	return str(accepted[0]) if not accepted.is_empty() else ""


func selected_bait() -> String:
	return _bait


func _fish_of(bait: String) -> Array[String]:
	var result: Array[String] = []
	var table: Dictionary = Database.fishing.get("fish", {})
	for id: String in table:
		if str(table[id].bait) == bait:
			result.append(id)
	return result


func _on_state_changed() -> void:
	if _closing or not is_instance_valid(_column):
		return
	var signature := _make_signature()
	if signature != _signature:
		_refresh()


func _make_signature() -> String:
	var parts: Array = [_rod_id(), _bait, GameState.fishing.xp, GameState.fishing.rods.size()]
	for id: String in Database.fishing.get("baits", {}):
		parts.append(GameState.inventory.count(id))
	for id: String in Database.fishing.get("fish", {}):
		parts.append(GameState.fishing.record(id).get("best_cm", 0.0))
	return str(parts)


# --- Construção ----------------------------------------------------------------------------

func _refresh() -> void:
	_signature = _make_signature()
	for child in _column.get_children():
		_column.remove_child(child)
		child.queue_free()
	_power = null
	_cast_button = null
	var rod_id := _rod_id()
	var heading := StationWood.heading({
		"title": "Lagoa",
		"icon": _rod_icon(rod_id),
		"badge": _level_badge(),
	}, Callable(), func() -> void: close())
	_column.add_child(heading)
	if GameState.fishing.rods.size() >= 2:
		_column.add_child(_rod_row())
	_column.add_child(_bait_row())
	var fish_row := _fish_row()
	if fish_row != null:
		_column.add_child(fish_row)
	_column.add_child(_board())
	_column.reset_size()
	_panel.reset_size()
	_place()


func _level_badge() -> Control:
	var info := GameState.fishing_info()
	var levels: Array = Database.fishing.get("levels", [0])
	var level := int(info.level)
	var low := float(levels[level - 1]) if level - 1 < levels.size() else 0.0
	var high := float(info.next_xp) if int(info.next_xp) > 0 else low
	var fraction := 1.0 if int(info.next_xp) <= 0 else clampf((float(info.xp) - low) / maxf(1.0, high - low), 0.0, 1.0)
	var box := UiKit.vbox(0)
	box.name = "FishingLevel"
	box.custom_minimum_size.x = 64.0
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := StationWood.text("Nv. %d" % level, 15)
	label.name = "FishingLevelText"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	box.add_child(label)
	box.add_child(StepCardUi.bar(fraction, 12.0, "FishingLevelBar"))
	return box


func _tile_row(node_name: String, title: String) -> VBoxContainer:
	var column := UiKit.vbox(2)
	column.name = node_name
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caption := StationWood.text(title, 14)
	caption.name = "Caption"
	column.add_child(caption)
	return column


func _rod_row() -> Control:
	var column := _tile_row("RodRow", "Vara")
	var row := StationWood.flow(6)
	row.alignment = FlowContainer.ALIGNMENT_BEGIN
	column.add_child(row)
	for id: String in GameState.fishing.rods:
		var def := _rod_def(id)
		var selected := id == _rod_id()
		var tile := StationWood.recipe_tile({"icon": _rod_icon(id), "caption": str(def.get("name", id)).replace("Vara de ", "").replace("Vara do ", "")}, "selected" if selected else "normal", null)
		tile.name = "Rod_" + id
		tile.pressed.connect(_choose_rod.bind(id))
		row.add_child(tile)
	return column


func _bait_row() -> Control:
	var column := _tile_row("BaitRow", "Isca")
	var row := StationWood.flow(6)
	row.alignment = FlowContainer.ALIGNMENT_BEGIN
	column.add_child(row)
	var accepted: Array = _rod_def(_rod_id()).get("baits", [])
	for id: String in accepted:
		var count := GameState.inventory.count(id)
		var state := "selected" if id == _bait else "normal"
		var entry := {"icon": Database.item_icon(id), "caption": "×%d" % count}
		if count <= 0:
			state = "locked" if id != _bait else "selected"
			entry["error"] = "Sem " + Database.item_name(id).to_lower()
		var tile := StationWood.recipe_tile(entry, state, null)
		tile.name = "Bait_" + id
		tile.pressed.connect(_choose_bait.bind(id, count))
		row.add_child(tile)
	return column


func _fish_row() -> Control:
	var fish := _fish_of(_bait)
	if fish.is_empty():
		return null
	var row := UiKit.hbox(6)
	row.name = "BaitFish"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for id in fish:
		var record := GameState.fishing.record(id)
		var cell := UiKit.vbox(0)
		cell.name = "Fish_" + id
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.custom_minimum_size.x = 76.0
		var icon := UiKit.icon(Database.item_icon(id), 32)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var known := not record.is_empty()
		if not known:
			icon.modulate = Color(0, 0, 0, 0.55)  # sombra do que ainda não foi pego
		cell.add_child(icon)
		var text := StationWood.text(record_text(id), 13)
		text.name = "Record"
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.autowrap_mode = TextServer.AUTOWRAP_OFF
		cell.add_child(text)
		row.add_child(cell)
	return row


## "28 cm" (recorde) ou "?" (ainda não pegou).
static func record_text(fish_id: String) -> String:
	var record := GameState.fishing.record(fish_id)
	if record.is_empty():
		return "?"
	return "%s cm" % str(snappedf(float(record.best_cm), 0.5)).replace(".", ",")


func _board() -> Control:
	var content := UiKit.vbox(6)
	content.name = "TrayActions"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var error := _cast_block_reason()
	if error == "":
		_power = PowerBar.new()
		_power.name = "CastPower"
		_power.visible = false
		content.add_child(_power)
		_cast_button = StepCardUi.go_button("Arremessar", func() -> void: pass)
		_cast_button.name = "CastButton"
		_cast_button.set_meta("wood_primary", true)
		_cast_button.button_down.connect(press_cast)
		_cast_button.button_up.connect(release_cast)
		content.add_child(_cast_button)
	else:
		var bait_icon := Database.item_icon(_bait) if _bait != "" else null
		var locked := StepCardUi.locked_button(error, bait_icon, func() -> void:
			if _bait != "":
				TaskHelp.open("item", _bait))
		locked.name = "Locked_CastButton"
		content.add_child(locked)
	return StationWood.board(content)


func _cast_block_reason() -> String:
	if _bait == "":
		return "Sem isca"
	if GameState.inventory.count(_bait) <= 0:
		return "Sem " + Database.item_name(_bait).to_lower()
	var error := GameState.cast_error(_bait, 1)
	return error


func _choose_rod(id: String) -> void:
	var error := GameState.choose_rod(id)
	if error != "":
		Events.toast_requested.emit(error)
		return
	_bait = _default_bait()
	_refresh()


func _choose_bait(id: String, count: int) -> void:
	_bait = id
	if count > 0:
		var error := GameState.choose_bait(id)
		if error != "":
			Events.toast_requested.emit(error)
	_refresh()


# --- Força do arremesso ----------------------------------------------------------------------

## Valor atual do ponteiro (0..1): vai e volta em `cast.power_period`.
func power_value() -> float:
	if power_override >= 0.0:
		return clampf(power_override, 0.0, 1.0)
	var period := maxf(0.2, float(Database.fishing.cast.power_period))
	return pingpong((Time.get_ticks_msec() / 1000.0 - _press_time) / period, 1.0)


## Faixa (1 Perto, 2 Meio, 3 Longe) do valor do ponteiro.
static func zone_of(value: float) -> int:
	var zones := int(Database.fishing.cast.zones)
	return clampi(1 + int(value * zones), 1, zones)


func press_cast() -> void:
	if _closing or _cast_button == null or _holding:
		return
	_holding = true
	_press_time = Time.get_ticks_msec() / 1000.0
	if _power != null:
		_power.visible = true
		_power.value = power_value()
	Haptics.tap()


func release_cast() -> void:
	if not _holding:
		return
	_holding = false
	var value := power_value()
	if _power != null:
		_power.value = value
	var zone := zone_of(value)
	last_zone = zone
	cast_requested.emit(_bait, zone, value)


var last_zone := 0


func _process(_delta: float) -> void:
	if not _closing:
		_place()  # o layout das abas e a altura do conteúdo podem mudar depois da abertura
	if _holding and _power != null and is_instance_valid(_power):
		_power.value = power_value()


# --- Posição e fechamento --------------------------------------------------------------------

func screen_top() -> float:
	return _box.get_global_rect().position.y if is_instance_valid(_box) and _box.is_visible_in_tree() else INF


func _place() -> void:
	if not is_instance_valid(_panel) or room == null:
		return
	var bottom := room.size.y - BOTTOM_LIMIT
	if is_instance_valid(_nav_bar) and _nav_bar.is_visible_in_tree():
		bottom = minf(bottom, _nav_bar.global_position.y - room.global_position.y - 8.0)
	_panel.custom_minimum_size.x = _width()
	var panel_size := _panel.get_combined_minimum_size()
	_panel.size = panel_size
	var top_limit := maxf(TOP_LIMIT, Hud.HEIGHT + 6.0)
	var top := maxf(top_limit, bottom - panel_size.y)
	_box.position = Vector2(roundf((room.size.x - panel_size.x) / 2.0), top)
	_box.size = panel_size
	_box.pivot_offset = Vector2(panel_size.x / 2.0, panel_size.y)


func close(immediate: bool = false) -> void:
	if _closing:
		return
	_closing = true
	_holding = false
	if current == self:
		current = null
	if Events.state_changed.is_connected(_on_state_changed):
		Events.state_changed.disconnect(_on_state_changed)
	closed.emit()
	if immediate or Motion.reduced or not is_inside_tree():
		if is_inside_tree() and get_parent() != null:
			get_parent().remove_child(self)  # sai já da árvore: um painel novo com o mesmo nome não é renomeado
		queue_free()
		return
	var tween := create_tween().set_parallel()
	tween.tween_property(_box, "scale", Vector2.ONE * 0.8, Motion.POP_OUT)
	tween.tween_property(_box, "modulate:a", 0.0, Motion.POP_OUT)
	tween.chain().tween_callback(queue_free)


## Barrinha de força: três faixas (Perto, Meio, Longe) e o ponteiro que vai e volta.
class PowerBar extends Control:
	var value := 0.0:
		set(new_value):
			value = new_value
			queue_redraw()

	func _init() -> void:
		custom_minimum_size = Vector2(0, 26)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_horizontal = Control.SIZE_EXPAND_FILL

	func _draw() -> void:
		var zones := int(Database.fishing.cast.zones)
		var names := ["Perto", "Meio", "Longe"]
		var tones := [Color("e9c07a"), Color("d9983f"), Color("b9692a")]
		var track := Rect2(0, 4, size.x, size.y - 8)
		var width := track.size.x / zones
		var font := get_theme_default_font()
		for i in zones:
			var cell := Rect2(track.position.x + width * i, track.position.y, width, track.size.y)
			draw_rect(cell, tones[mini(i, tones.size() - 1)])
			draw_rect(cell, Palette.WOOD_INK, false, 1.5)
			if font:
				var name_text: String = names[mini(i, names.size() - 1)]
				var text_size := font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
				draw_string(font, Vector2(cell.position.x + (width - text_size.x) / 2.0, cell.position.y + cell.size.y / 2.0 + 4.0), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.WOOD_INK)
		var x := track.position.x + track.size.x * clampf(value, 0.0, 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 6, 0), Vector2(x + 6, 0), Vector2(x, 9)]), Palette.INK)
		draw_line(Vector2(x, 4), Vector2(x, size.y - 2), Palette.INK, 2.5)
