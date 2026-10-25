class_name FarmDock
extends PanelContainer
## Barra da horta (Interface 2, etapa 07): sementes + Regar (modo `plant`) ou foice + "Colher tudo (N)" (modo
## `harvest`) presas embaixo, logo acima do rodapé. Com a barra aberta, o dedo que COMEÇA num canteiro usa a
## ferramenta escolhida em todo canteiro por onde passar (a `RoomView` entrega o gesto por `press/move/release`).
## As entradas e as regras vêm do `PlotTray` (`seed_entries/water_entry/sickle_entries`) e do `GameState`.

const HINT_KEY := "ui:tray_drag_hint"
const HINT_TIMES := 3
const TILE := Vector2(52, 64)
const EDGE := 36.0
const EDGE_SPEED := 6.0
const TOP_LIMIT := 120.0
## Quanto a câmera sobe para o canteiro tocado ficar acima da barra.
const BAR_LIFT := 70.0

## Mexer na câmera NÃO fecha esta barra (decisão do Vitor, 25/10/2026): ela é presa ao rodapé, não ao objeto, e
## plantar fora da tela pede arrastar a câmera sem perder a semente. Só as bandejas presas ao objeto fecham.
static var _current: FarmDock

var room: RoomView
var mode := "plant"
var plot_index := -1
var closing := false
var entries: Array[Dictionary] = []
var selected := ""

var _host: Control
var _main: Node
var _tiles: Dictionary = {}
var _captions: Dictionary = {}
var _row: HBoxContainer
var _scroll: ScrollContainer
var _hint: PanelContainer
var _signature := ""
var _gesture := DragGhost.new()
var _active := false
var _moved := false
var _press_plot := -1
var _finger := Vector2.ZERO
var _done: Dictionary = {}
var _total := 0
var _layer: GestureLayer
var _token: Control
var _count_label: Label
var _count_disc: PanelContainer


## Abre a barra (troca a que estiver aberta). `plot_index` = canteiro tocado (escolhe as sementes certas, estufa
## incluída); `focus` = semente pedida pelo "Ir" ou "water".
static func open(room: RoomView, mode: String, plot_index: int = -1, focus: String = "") -> FarmDock:
	if is_instance_valid(_current):
		_current.close(true)
	var dock := FarmDock.new()
	dock.name = "FarmDock"
	dock.room = room
	dock.mode = mode
	dock.plot_index = plot_index
	_current = dock
	dock._build(focus)
	return dock


static func current() -> FarmDock:
	return _current if is_instance_valid(_current) and not _current.closing else null


static func is_open_for(for_room: RoomView) -> bool:
	var dock := current()
	return dock != null and dock.room == for_room


func _build(focus: String) -> void:
	_host = _find_host()
	if mode == "harvest":
		entries = PlotTray.sickle_entries(room)
		selected = "sickle"
	else:
		var index := plot_index if plot_index >= 0 else _first_empty()
		entries = PlotTray.seed_entries(room, index, focus if focus != "water" else "")
		entries.append(PlotTray.water_entry(room))
		selected = _initial_selection(focus)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.BASE_GLASS
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.border_color = Palette.BASE_LINE
	style.border_width_top = 1
	style.shadow_color = Color(Palette.SHADOW, 0.35)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, -3)
	style.content_margin_left = 12.0
	style.content_margin_right = 8.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	add_theme_stylebox_override("panel", style)
	z_index = 4
	z_as_relative = false
	set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	_host.add_child(self)
	_row = UiKit.hbox(6)
	_row.name = "DockRow"
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_row)
	_layout()
	_rebuild()
	_host.resized.connect(_layout)
	resized.connect(_place_hint)
	Events.state_changed.connect(_on_state_changed)
	var joined := _find_main()
	if joined:
		joined.call("set_tab_joined", true)
	_show_hint.call_deferred()


func _find_host() -> Control:
	var screen := room.get_tree().root.find_child("WorldsScreen", true, false) as Control
	return screen if screen else room.get_parent() as Control


func _find_main() -> Node:
	var node: Node = room
	while node:
		if node.has_method("set_tab_joined"):
			return node
		node = node.get_parent()
	return null


func _first_empty() -> int:
	for index in room.plot_indices():
		if GameState.plot_status(index) == "empty":
			return index
	var all := room.plot_indices()
	return all[0] if not all.is_empty() else 0


## Foco > última semente usada > a primeira liberada.
func _initial_selection(focus: String) -> String:
	var ids: Array[String] = []
	for entry: Dictionary in entries:
		if str(entry.get("error", "")) == "":
			ids.append(str(entry.id))
	if focus != "" and focus in ids:
		return focus
	if PlotTray.last_crop in ids:
		return PlotTray.last_crop
	for id in ids:
		if id != "water":
			return id
	return "water" if "water" in ids else ""


## Logo acima do rodapé: a base fica no topo da barra de abas (ou 84 px do fim).
func _layout() -> void:
	if not is_instance_valid(_host):
		return
	var nav := _host.get_tree().root.find_child("TabBar", true, false) as Control
	var gap := 84.0
	if nav and nav.is_visible_in_tree():
		gap = maxf(0.0, _host.global_position.y + _host.size.y - nav.global_position.y)
	offset_left = 0.0
	offset_right = 0.0
	offset_bottom = -gap
	_place_hint()


func _place_hint() -> void:
	if not is_instance_valid(_hint):
		return
	_hint.reset_size()
	_hint.position = Vector2((_host.size.x - _hint.size.x) / 2.0, position.y - _hint.size.y - 10.0)


# --- Conteúdo ------------------------------------------------------------------------

func _rebuild() -> void:
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	_tiles.clear()
	_captions.clear()
	if mode == "harvest":
		_build_harvest()
	else:
		_build_plant()
	_signature = _make_signature()


func _build_plant() -> void:
	_scroll = ScrollContainer.new()
	_scroll.name = "SeedScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.custom_minimum_size.y = TILE.y + 4.0
	var hide_bar := StyleBoxEmpty.new()
	for bar: ScrollBar in [_scroll.get_h_scroll_bar(), _scroll.get_v_scroll_bar()]:
		bar.add_theme_stylebox_override("scroll", hide_bar)
		bar.modulate.a = 0.0
	var seeds := UiKit.hbox(6)
	seeds.name = "Seeds"
	_scroll.add_child(seeds)
	for entry: Dictionary in entries:
		if str(entry.id) != "water":
			seeds.add_child(_tile(entry))
	_row.add_child(_scroll)
	var divider := ColorRect.new()
	divider.name = "Divider"
	divider.color = Palette.LINE
	divider.custom_minimum_size = Vector2(1, TILE.y - 12.0)
	divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_row.add_child(divider)
	for entry: Dictionary in entries:
		if str(entry.id) == "water":
			var water := _tile(entry)
			water.name = "Tile_water"
			_row.add_child(water)
	_row.add_child(_close_button())
	_reveal_selected.call_deferred()


func _build_harvest() -> void:
	var sickle: Dictionary = entries[0]
	var sickle_tile := _tile(sickle)
	_row.add_child(sickle_tile)
	var all: Dictionary = entries[1]
	var count := room.ready_plots().size()
	var blocked := _harvest_block()
	var holder := UiKit.hbox(0)
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if blocked != "":
		var hint := UiKit.lock_hint(blocked, Callable(), all.icon as Texture2D)
		hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		holder.add_child(hint)
	else:
		var button := UiKit.primary("Colher tudo (%d)" % count, func() -> void: _harvest_all())
		button.name = "HarvestAll"
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		holder.add_child(button)
	_row.add_child(holder)
	_row.add_child(_close_button())


## Depósito sem lugar para nenhum dos prontos: devolve o motivo; senão "".
func _harvest_block() -> String:
	var ready := room.ready_plots()
	if ready.is_empty():
		return ""
	var first := ""
	for index in ready:
		var error := GameState.harvest_error(index)
		if error == "":
			return ""
		if first == "":
			first = error
	return first


func _harvest_all() -> void:
	var reason := str((entries[1].tap as Callable).call())
	if reason != "":
		Events.toast_requested.emit(reason)


func _close_button() -> Button:
	var button := UiKit.ctl_button("check" if mode == "plant" else "x", func() -> void: close(), 32, "sunken")
	button.name = "CloseDock"
	return button


func _tile(entry: Dictionary) -> Button:
	var id := str(entry.id)
	var locked := str(entry.get("error", "")) != ""
	var state := "locked" if locked else ("selected" if id == selected else "normal")
	var caption := str(entry.get("caption", ""))
	var caption_fn: Variant = entry.get("caption_fn")
	var count_fn: Variant = entry.get("count_fn")
	if caption_fn is Callable and not count_fn is Callable:
		caption = (caption_fn as Callable).call()
	var tile := UiKit.tile(entry.icon as Texture2D, caption, state)
	tile.name = "Tile_" + id
	tile.custom_minimum_size = TILE
	var visual := tile.get_node("Visual") as VBoxContainer
	visual.offset_top = 4
	visual.offset_bottom = -4
	visual.add_theme_constant_override("separation", 2)
	var picture := visual.get_node("Picture") as TextureRect
	picture.custom_minimum_size = Vector2(36, 36)
	_captions[id] = visual.get_child(1) as Label
	if count_fn is Callable:
		# "Regar" na legenda e a quantidade de canteiros para regar num selo no canto (como a Mochila).
		var seal := UiKit.chip(null, "×%d" % (count_fn as Callable).call())
		seal.name = "Count"
		tile.add_child(seal)
		seal.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		seal.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		seal.offset_left = 2.0
		seal.offset_right = 2.0
		seal.offset_top = -6.0
		seal.offset_bottom = -6.0
		seal.visible = int((count_fn as Callable).call()) > 0
	_tiles[id] = tile
	tile.pressed.connect(func() -> void: _on_tile(id))
	return tile


func _on_tile(id: String) -> void:
	var entry := _entry(id)
	if str(entry.get("error", "")) != "":
		var help: Variant = entry.get("help")
		if help is Callable and (help as Callable).is_valid():
			(help as Callable).call()
		else:
			Events.toast_requested.emit(str(entry.error))
		return
	select.call_deferred(id)


func _entry(id: String) -> Dictionary:
	for entry: Dictionary in entries:
		if str(entry.id) == id:
			return entry
	return {}


# --- API pública (toque, testes e capturas) ------------------------------------------------

func entry_ids() -> Array[String]:
	var ids: Array[String] = []
	for entry: Dictionary in entries:
		ids.append(str(entry.id))
	return ids


func selected_entry() -> Dictionary:
	return _entry(selected)


func tile_node(id: String) -> Control:
	return _tiles.get(id)


func select(id: String) -> void:
	if closing or _entry(id).is_empty() or str(_entry(id).get("error", "")) != "":
		return
	if id != selected:
		selected = id
		_rebuild()


func tap_tile(id: String) -> void:
	_on_tile(id)


func close(immediate: bool = false) -> void:
	if closing:
		return
	closing = true
	_cancel_gesture()
	if _current == self:
		_current = null
	if Events.state_changed.is_connected(_on_state_changed):
		Events.state_changed.disconnect(_on_state_changed)
	if is_instance_valid(_host) and _host.resized.is_connected(_layout):
		_host.resized.disconnect(_layout)
	var main := _find_main() if is_instance_valid(room) else null
	if main:
		main.call("set_tab_joined", false)
	if is_instance_valid(_hint):
		_hint.queue_free()
	if immediate or Motion.reduced or not is_inside_tree():
		queue_free()
		return
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, Motion.POP_OUT)
	tween.tween_callback(queue_free)


func _exit_tree() -> void:
	if _current == self:
		_current = null
	_cancel_gesture()


func _on_state_changed() -> void:
	if closing:
		return
	if mode == "harvest" and room.ready_plots().is_empty():
		close()
		return
	for id: String in _captions:
		var entry := _entry(id)
		var caption_fn: Variant = entry.get("caption_fn")
		var count_fn: Variant = entry.get("count_fn")
		if count_fn is Callable:
			var seal := (_tiles[id] as Control).get_node_or_null("Count") as Control
			if seal != null:
				var amount := int((count_fn as Callable).call())
				seal.visible = amount > 0
				((seal.get_child(0) as Control).get_child(-1) as Label).text = "×%d" % amount
		elif caption_fn is Callable and is_instance_valid(_captions[id]):
			(_captions[id] as Label).text = (caption_fn as Callable).call()
	if _make_signature() != _signature and not _active:
		_rebuild.call_deferred()


func _make_signature() -> String:
	if mode == "harvest":
		return "h:%d:%s" % [room.ready_plots().size(), _harvest_block()]
	var locks := ""
	for entry: Dictionary in entries:
		locks += "1" if GameState.content_error("crop", str(entry.id), Database.crops.get(str(entry.id), {})) != "" and Database.crops.has(str(entry.id)) else "0"
	return "p:%s:%s" % [selected, locks]


# --- Dica ------------------------------------------------------------------------------

## "Arraste pelos canteiros": só nas três primeiras aberturas em `plant` com 2+ canteiros vazios.
func _show_hint() -> void:
	if closing or mode != "plant":
		return
	var times := 0
	var stored: Variant = GameState.progress.seen.get(HINT_KEY, 0)
	if stored is bool:
		times = HINT_TIMES if stored else 0
	else:
		times = int(stored)
	if times >= HINT_TIMES:
		return
	var empty := 0
	for index in room.plot_indices():
		if GameState.plot_status(index) == "empty":
			empty += 1
	if empty < 2:
		return
	GameState.progress.seen[HINT_KEY] = times + 1
	GameState.mark_seen([] as Array[String])
	_hint = PanelContainer.new()
	_hint.name = "DragHint"
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.z_index = 4
	_hint.z_as_relative = false
	_hint.add_theme_stylebox_override("panel", UiKit.surface(Palette.INK, 20))
	var row := UiKit.hbox(6)
	row.add_child(UiKit.ctl("spark", 18, Palette.HONEY))
	var text := UiKit.short_label("Arraste pelos canteiros", &"SmallLabel", Color.WHITE)
	text.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(text)
	_hint.add_child(row)
	_host.add_child(_hint)
	_place_hint.call_deferred()
	if not Motion.reduced:
		var tween := _hint.create_tween()
		tween.tween_interval(4.0)
		tween.tween_property(_hint, "modulate:a", 0.0, 0.4)
		tween.tween_callback(_hint.queue_free)


func _reveal_selected() -> void:
	if is_instance_valid(_scroll) and _tiles.has(selected) and _scroll.is_ancestor_of(_tiles[selected] as Control):
		_scroll.ensure_control_visible(_tiles[selected] as Control)


# --- Gesto: a ferramenta escolhida começa no canteiro ---------------------------------------

func gesture_active() -> bool:
	return _active


## A `RoomView` chama no `pressed`. Devolve true se o dedo caiu num canteiro (a ferramenta assume o gesto e a
## câmera não mexe); a primeira ação já acontece no canteiro tocado.
func press(global_point: Vector2) -> bool:
	if closing or selected == "":
		return false
	var plot := room.plot_at(room.screen_to_world(global_point))
	if plot < 0:
		return false
	_active = true
	_moved = false
	_press_plot = plot
	_done.clear()
	_total = 0
	_finger = global_point
	_gesture.press(global_point)
	_begin_visuals()
	_act(global_point)
	return true


func move(global_point: Vector2) -> void:
	if not _active:
		return
	if room._is_pinching():  # a pinça tem prioridade: o gesto acaba sem agir mais
		_cancel_gesture()
		return
	_finger = global_point
	if _gesture.move(global_point):
		_moved = true
	_follow()
	_act(global_point)


func release(global_point: Vector2) -> void:
	if not _active:
		return
	var plot := _press_plot
	var plain_tap := not _moved and _total == 0
	_cancel_gesture()
	if plain_tap:
		room.dock_plot_tap(plot, self)


## Para o gesto sem agir (fecha a ficha e o rastro).
func _cancel_gesture() -> void:
	if not _active:
		return
	_active = false
	if is_instance_valid(_token):
		Motion.pop_out(_token)
	_token = null
	if is_instance_valid(_count_disc):
		_count_disc.queue_free()
	_count_disc = null
	if is_instance_valid(_layer):
		_layer.queue_free()
	_layer = null


func _begin_visuals() -> void:
	_layer = GestureLayer.new()
	_layer.name = "FarmGesture"
	room.add_child(_layer)
	_token = _gesture.begin(_layer, selected_entry().get("icon") as Texture2D)
	_count_disc = PanelContainer.new()
	_count_disc.name = "GestureCount"
	_count_disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count_disc.add_theme_stylebox_override("panel", UiKit.surface(Palette.GO, 12))
	_count_label = UiKit.short_label("0", &"BadgeLabel", Color.WHITE)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_disc.add_child(_count_label)
	_count_disc.custom_minimum_size = Vector2(24, 24)
	_layer.add_child(_count_disc)
	_refresh_visuals()


func _follow() -> void:
	_gesture.finger = _finger
	if is_instance_valid(_layer):
		_gesture.follow(_layer)
		_refresh_visuals()


func _refresh_visuals() -> void:
	if not is_instance_valid(_layer):
		return
	if is_instance_valid(_count_label):
		_count_label.text = str(_total)
	if is_instance_valid(_token):
		_count_disc.position = _token.position + Vector2(_token.size.x - 14.0, -8.0)
	_layer.targets.clear()
	for index in room.plot_indices():
		if _accepts(index) and not _done.has(index):
			_layer.targets.append(_screen_polygon(index))
	_layer.queue_redraw()


func _screen_polygon(index: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in room.plot_diamond(index):
		result.append(room.world_to_screen(point) - room.global_position)
	return result


## Este canteiro ainda aceita a ferramenta escolhida?
func _accepts(index: int) -> bool:
	match selected:
		"water":
			return GameState.water_error(index) == ""
		"sickle":
			return GameState.plot_status(index) == "ready" and GameState.harvest_error(index) == ""
		_:
			return GameState.plot_status(index) == "empty" and GameState.plant_error(index, selected) == ""


func _act(global_point: Vector2) -> void:
	var world := room.screen_to_world(global_point)
	var index := room.plot_at(world)
	if index < 0 or _done.has(index):
		return
	var drag: Variant = selected_entry().get("drag")
	if not (drag is Callable) or not (drag as Callable).is_valid():
		return
	if (drag as Callable).call(world) == true:
		_done[index] = true
		_total += 1
		Haptics.tap()
		if is_instance_valid(_layer):
			_layer.trail.append(room.world_to_screen(room.plot_center(index)) - room.global_position)
		_refresh_visuals()


func _process(delta: float) -> void:
	if not _active or closing:
		return
	# Rolagem na borda: o dedo perto da lateral/embaixo (ou a ficha perto do HUD) anda a câmera.
	var local := _finger - room.global_position
	var top := local.y - DragGhost.LIFT - DragGhost.PX
	var direction := Vector2.ZERO
	if local.x < EDGE:
		direction.x = -1.0
	elif local.x > room.size.x - EDGE:
		direction.x = 1.0
	if global_position.y - room.global_position.y - local.y < EDGE:
		direction.y = 1.0
	elif top < TOP_LIMIT - EDGE:
		direction.y = -1.0
	if direction != Vector2.ZERO:
		room.scroll_by(direction * EDGE_SPEED)
		_follow()
		_act(_finger)


## Simulação de gesto (testes e capturas): começa no centro do primeiro canteiro, passa pelos demais e solta.
func drag_plots(indices: Array, release_at_end: bool = true) -> void:
	var points: Array[Vector2] = []
	for index: int in indices:
		points.append(room.world_to_screen(room.plot_center(index)))
	drag_points(points, release_at_end)


func drag_points(points: Array[Vector2], release_at_end: bool = true) -> void:
	if points.is_empty():
		return
	press(points[0])
	for i in range(1, points.size()):
		move(points[i])
	if release_at_end:
		release(points[points.size() - 1])


func release_drag() -> void:
	release(_finger)


## Rastro claro e losangos tracejados dos canteiros que ainda aceitam a ferramenta (coordenadas locais da sala).
class GestureLayer extends Control:
	var trail := PackedVector2Array()
	var targets: Array[PackedVector2Array] = []

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		z_index = 5
		z_as_relative = false

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		if trail.size() >= 2:
			draw_polyline(trail, Color(Palette.HONEY_SOFT, 0.55), 14.0, true)
		for polygon in targets:
			for i in polygon.size():
				draw_dashed_line(polygon[i], polygon[(i + 1) % polygon.size()], Color.WHITE, 2.0, 6.0)
