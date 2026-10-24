class_name ActionTray
extends Control
## Bandeja de ação perto do dedo: ícones grandes com legenda curta (tempo, quantidade).
## Toque no ícone = ação no alvo. Arrastar o ícone = repetir a ação em cada alvo por onde o dedo passar.
## Filha da sala (RoomView): não escala com o zoom e fecha se a câmera se mexer.
##
## entry: {
##   "id": String, "icon": Texture2D, "caption": String (tempo/quantidade), "badge": String ("", "!", "♥"),
##   "caption_fn": Callable () -> String (opcional, relida depois de cada ação), "badge_fn" idem para o selo,
##   "error": String ("" = disponível; senão aparece apagado com cadeado e o toque mostra o motivo),
##   "dim_fn": Callable () -> bool (opcional; apaga só o visual, sem cadeado nem bloquear o toque),
##   "help": Callable (opcional, abre "Como fazer" quando bloqueado),
##   "highlight": bool (borda verde: o item pedido pelo "Ir"),
##   "keep_open": bool (o toque deu certo, mas a bandeja continua),
##   "tap": Callable () -> String  ("" = deu certo; senão motivo para toast),
##   "drag": Callable (world_point: Vector2) -> bool  (opcional; true = agiu neste ponto)
## }
##
## Modo "pick" (`options.mode = "pick"`, estações/criações/Natureza): grade de 4 por linha, tocar SELECIONA
## (borda verde) em vez de agir; embaixo fica o detalhe do escolhido (`options.detail: Callable(id) -> Control`,
## refeito sozinho a cada mudança), com o único botão principal. Largura 328, ✕ no canto, não fecha ao agir.
## `options.selected` = id inicial; `options.on_select: Callable(id)` avisa quem lembra a última escolha.
## `recipe_selector` usa faixa horizontal. Corpo rolável respeita HUD/abas; Cook e rodapé ficam fixos.

signal closed
signal selected_changed(id: String)

const TAP_SLOP := 12.0
const ITEM := Vector2(60, 72)
const CIRCLE := 56.0
const ICON_PX := 48.0
const GHOST_PX := 56.0
## O fantasma anda acima do dedo: a ponta de baixo dele (onde a ação acontece) fica 40 px acima.
const GHOST_LIFT := 40.0
const EDGE := 36.0
const EDGE_SPEED := 6.0
const ARROW := 12.0
const SIDE := 8.0
## Sob o HUD e a pílula do mundo: abaixo disso a bandeja não sobe.
const TOP_LIMIT := 120.0
## Folga no fim da sala (a barra de abas cobre 22 px dela).
const BOTTOM_LIMIT := 34.0
const PER_ROW := 5
const SCROLL_FROM := 10
## A bandeja fica translúcida enquanto o item é arrastado (os canteiros atrás dela aparecem).
const DRAG_ALPHA := 0.3
## Modo "pick": largura da bandeja (cabe em 360 com 16 de margem) e itens por linha.
const PICK_WIDTH := 328.0
const PICK_PER_ROW := 4
## Tempo do ícone da receita voando da grade até a bolinha da fila.
const FLY_TIME := 0.3

## Só existe uma bandeja por vez.
static var current: ActionTray

var room: RoomView
var entries: Array[Dictionary] = []
var options: Dictionary = {}
var closing := false
var acted := 0
## Modo "pick": id selecionado na grade ("" = nenhum).
var selected := ""
var pick := false

var _anchor_world := Vector2.ZERO
var _below_world := Vector2.ZERO
var _box: Control
var _panel: PanelContainer
var _arrow: TrayArrow
var _items: Array[Control] = []
var _captions: Array[Label] = []
var _badges: Array[Label] = []
var _hint_label: Label
var _hint_node: Control
var _hint_tween: Tween
var _ghost: Control
var _gesture := DragGhost.new()
var _pressed := -1
var _press_global := Vector2.ZERO
var _recipe_scroll: ScrollContainer
var _recipe_swiping := false
var _recipe_active := false
var _recipe_touch := -1
var _recipe_last := Vector2.ZERO
var _recipe_position := 0.0
var _recipe_velocity := 0.0
var _recipe_sample_usec := 0
var _recipe_motion_usec := 0
var _recipe_mouse_until := 0
var _drag_index := -1
var _finger := Vector2.ZERO
var _idle := 0.0
var _tip := Vector2.ZERO
var _circle_styles: Array[StyleBoxFlat] = []
var _detail: SheetBuilder.LiveBox
var _last_min := Vector2.ZERO
var _body_scroll: ScrollContainer
var _body_column: VBoxContainer
var _actions: VBoxContainer
var _nav_bar: Control
var _reveal_frames := 0


## Abre a bandeja apontando para `anchor_world` (ponto da sala). `options`: "title", "header" (Control),
## "footer_ghost" ({"text", "action"}), "auto_close" (segundos), "below" (ponto da sala se for para baixo),
## "hint" ({"key", "icon", "from", "points" (pontos da sala), "caption"}: mãozinha de ensino, uma vez).
static func open(room: RoomView, anchor_world: Vector2, entries: Array[Dictionary], options: Dictionary = {}) -> ActionTray:
	if is_instance_valid(current):
		current.close(true)
	var tray := ActionTray.new()
	tray.name = "ActionTray"
	tray.room = room
	tray.entries = entries
	tray.options = options
	tray._anchor_world = anchor_world
	tray._below_world = options.get("below", anchor_world + Vector2(0, 40))
	room.add_child(tray)
	tray._build()
	current = tray
	return tray


## Há uma bandeja aberta (e não fechando) nesta sala?
static func is_open(for_room: RoomView) -> bool:
	return is_instance_valid(current) and not current.closing and current.room == for_room


static func close_current(immediate: bool = false) -> void:
	if is_instance_valid(current):
		current.close(immediate)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 5
	z_as_relative = false  # acima do mundo e da pílula do mundo, abaixo das abas, do HUD e dos painéis


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build() -> void:
	_box = Control.new()
	_box.name = "Box"
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PAPER
	style.set_corner_radius_all(16)
	style.set_border_width_all(2)
	style.border_color = Palette.CARD_LINE
	style.shadow_color = Palette.SHADE
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	_panel.add_theme_stylebox_override("panel", style)
	_box.add_child(_panel)
	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", 4)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(column)
	_body_column = column
	pick = str(options.get("mode", "")) == "pick"
	if pick:
		_panel.custom_minimum_size.x = PICK_WIDTH
		selected = str(options.get("selected", ""))
		var heading := UiKit.hbox(4)
		var title := UiKit.fill_label(str(options.get("title", "")), &"SectionLabel")
		heading.add_child(title)
		var close_button := UiKit.icon_button(UiKit.ctl_icon("x"), close, 44)
		close_button.name = "CloseTray"
		close_button.mouse_filter = Control.MOUSE_FILTER_STOP
		heading.add_child(close_button)
		column.add_child(heading)
		column.add_theme_constant_override("separation", 8)
		_body_scroll = ScrollContainer.new()
		_body_scroll.name = "TrayBodyScroll"
		_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		var track := StyleBoxFlat.new()
		track.bg_color = Palette.CARD_LINE
		track.content_margin_left = 4
		track.content_margin_right = 4
		track.set_corner_radius_all(4)
		_body_scroll.get_v_scroll_bar().add_theme_stylebox_override("scroll", track)
		column.add_child(_body_scroll)
		_body_column = UiKit.vbox(12)
		_body_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_body_scroll.add_child(_body_column)
		_actions = UiKit.vbox(8)
		_actions.name = "TrayActions"
		column.add_child(_actions)
		_nav_bar = get_tree().root.find_child("TabBar", true, false) as Control
	elif str(options.get("title", "")) != "":
		var title := UiKit.label(str(options.title), &"SmallLabel")
		title.name = "Title"
		title.autowrap_mode = TextServer.AUTOWRAP_OFF
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(title)
	if options.get("header") is Control:
		_body_column.add_child(options.header)
	if not entries.is_empty():
		_body_column.add_child(_build_items())
	if pick and options.get("detail") is Callable:
		_detail = SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
			var detail := (options.detail as Callable).call(selected) as Control
			box.add_child(detail)
			for old in _actions.get_children():
				_actions.remove_child(old)
				old.queue_free()
			var cook := detail.find_child("Cook", true, false) as Button
			if cook:
				cook.get_parent().remove_child(cook)
				_actions.add_child(cook))
		_detail.name = "Detail"
		_body_column.add_child(_detail)
	var hint: Dictionary = options.get("hint", {})
	if not hint.is_empty():
		_hint_label = UiKit.label(str(hint.get("caption", "")), &"SmallLabel")
		_hint_label.name = "HintLabel"
		_hint_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(_hint_label)
	var footer: Dictionary = options.get("footer_ghost", {})
	if not footer.is_empty():
		var action := func() -> void:
			_touched()
			(footer.action as Callable).call()
		var ghost := UiKit.primary(str(footer.text), action) if footer.get("primary", false) else UiKit.ghost(str(footer.text), action)
		ghost.name = str(footer.get("name", "FooterGhost"))
		ghost.mouse_filter = Control.MOUSE_FILTER_STOP
		column.add_child(ghost)
	_arrow = TrayArrow.new()
	_arrow.name = "Arrow"
	_box.add_child(_arrow)
	_panel.reset_size()
	_place()
	_refresh_captions()
	if pick:
		Events.state_changed.connect(_refresh_captions)  # aparência e legendas acompanham a mochila
	_animate_in()
	if not hint.is_empty():
		_start_hint.call_deferred()


func _build_items() -> Control:
	var count := entries.size()
	if pick and bool(options.get("recipe_selector", false)):
		var group := UiKit.vbox(8)
		var hint := UiKit.label("Receitas: deslize para o lado", &"SmallLabel")
		hint.name = "RecipeScrollHint"
		group.add_child(hint)
		var scroll := ScrollContainer.new()
		scroll.name = "RecipeScroll"
		_recipe_scroll = scroll
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.custom_minimum_size.y = ITEM.y + 12
		var row := _row()
		row.alignment = BoxContainer.ALIGNMENT_BEGIN
		row.add_theme_constant_override("separation", 12)
		scroll.add_child(row)
		for i in count: row.add_child(_make_item(i))
		group.add_child(scroll)
		return group
	var holder: Control
	var per_row := PICK_PER_ROW if pick else PER_ROW
	if count > SCROLL_FROM and not pick:
		var scroll := ScrollContainer.new()
		scroll.name = "Scroll"
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.custom_minimum_size = Vector2(PER_ROW * ITEM.x + (PER_ROW - 1) * 4.0, ITEM.y + 8.0)
		var row := _row()
		scroll.add_child(row)
		for i in count:
			row.add_child(_make_item(i))
		return scroll
	var rows := VBoxContainer.new()
	rows.name = "Rows"
	rows.add_theme_constant_override("separation", 4)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder = rows
	var current_row: HBoxContainer = null
	for i in count:
		if i % per_row == 0:
			current_row = _row()
			rows.add_child(current_row)
		current_row.add_child(_make_item(i))
	# Muitas receitas (fogão com 10): mais de duas linhas rolam, para a bandeja caber na sala e abaixo do HUD.
	if pick and count > per_row * 2:
		var group := VBoxContainer.new()
		group.add_theme_constant_override("separation", 4)
		var hint := UiKit.label("Deslize para ver mais ↓", &"SmallLabel")
		hint.name = "RecipeScrollHint"
		group.add_child(hint)
		var scroll := ScrollContainer.new()
		scroll.name = "Scroll"
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.custom_minimum_size = Vector2(0.0, ITEM.y * 1.9 + 8.0 - hint.get_combined_minimum_size().y - 4.0)
		scroll.add_child(rows)
		rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		group.add_child(scroll)
		return group
	return holder


func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return row


func _make_item(index: int) -> Control:
	var entry := entries[index]
	var blocked := str(entry.get("error", "")) != ""
	var item := Control.new()
	item.name = "Item_" + str(entry.get("id", index))
	item.custom_minimum_size = ITEM
	item.mouse_filter = Control.MOUSE_FILTER_STOP
	var body := Control.new()
	body.name = "Body"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.modulate.a = 0.45 if blocked or _entry_dimmed(entry) else 1.0
	item.add_child(body)
	var circle := Panel.new()
	circle.name = "Circle"
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.SUNKEN
	style.set_corner_radius_all(int(CIRCLE / 2.0))
	style.border_color = Palette.PRIMARY
	if bool(entry.get("highlight", false)) or (pick and str(entry.get("id", "")) == selected):
		style.set_border_width_all(3)
	circle.add_theme_stylebox_override("panel", style)
	_circle_styles.append(style)
	circle.position = Vector2((ITEM.x - CIRCLE) / 2.0, 0)
	circle.size = Vector2(CIRCLE, CIRCLE)
	body.add_child(circle)
	var icon := UiKit.icon(entry.get("icon") as Texture2D, int(ICON_PX))
	icon.name = "Icon"
	icon.position = circle.position + (Vector2(CIRCLE, CIRCLE) - Vector2(ICON_PX, ICON_PX)) / 2.0
	icon.size = Vector2(ICON_PX, ICON_PX)
	body.add_child(icon)
	var caption := UiKit.label(str(entry.get("caption", "")), &"SmallLabel")
	caption.name = "Caption"
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.clip_text = true
	caption.position = Vector2(0, CIRCLE - 2.0)
	caption.size = Vector2(ITEM.x, ITEM.y - CIRCLE + 2.0)
	body.add_child(caption)
	_captions.append(caption)
	var badge_text := str(entry.get("badge", ""))
	var badge: Label = null
	if badge_text != "" or entry.has("badge_fn"):
		badge = UiKit.label(badge_text, &"BadgeLabel")
		badge.name = "Badge"
		badge.autowrap_mode = TextServer.AUTOWRAP_OFF
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.reset_size()
		badge.position = Vector2(ITEM.x - badge.size.x - 2.0, 2.0)
		badge.visible = badge_text != ""
		item.add_child(badge)
	_badges.append(badge)
	if blocked or entry.has("error_fn"):
		var lock := UiKit.icon(UiKit.ctl_icon("lock"), 16)
		lock.name = "Lock"
		lock.visible = blocked
		lock.position = circle.position + Vector2(CIRCLE - 18.0, CIRCLE - 18.0)
		lock.size = Vector2(16, 16)
		item.add_child(lock)
	item.gui_input.connect(_on_item_input.bind(index))
	_items.append(item)
	return item


# --- Posição ---------------------------------------------------------------------

## Acima do alvo (a menos que não caiba abaixo do HUD); setinha sempre no alvo, mesmo com a bandeja deslocada.
func _place() -> void:
	var bottom := room.size.y - BOTTOM_LIMIT
	if is_instance_valid(_nav_bar) and _nav_bar.is_visible_in_tree():
		bottom = minf(bottom, _nav_bar.global_position.y - room.global_position.y - 8.0)
	if _body_scroll:
		var fixed := _panel.get_combined_minimum_size().y - _body_scroll.get_combined_minimum_size().y
		var available := maxf(48.0, bottom - TOP_LIMIT - fixed)
		_body_scroll.custom_minimum_size.y = minf(_body_column.get_combined_minimum_size().y, available)
	var panel_size := _panel.get_combined_minimum_size()
	_panel.size = panel_size
	var origin := room.global_position
	var above := room.world_to_screen(_anchor_world) - origin
	var below := room.world_to_screen(_below_world) - origin
	var top := above.y - ARROW - panel_size.y
	var points_up := false  # a ponta da setinha aponta para cima quando a bandeja fica embaixo do alvo
	var tip := above
	if top < TOP_LIMIT:
		top = below.y + ARROW
		tip = below
		points_up = true
	var bottom_limit := bottom - panel_size.y
	top = clampf(top, minf(TOP_LIMIT, bottom_limit), maxf(TOP_LIMIT, bottom_limit))
	var left := clampf(tip.x - panel_size.x / 2.0, SIDE, maxf(SIDE, room.size.x - SIDE - panel_size.x))
	_box.position = Vector2(left, top)
	_box.size = panel_size
	_tip = tip
	var arrow_x := clampf(tip.x - left, 22.0, maxf(22.0, panel_size.x - 22.0))
	_arrow.points_up = points_up
	_arrow.size = Vector2(ARROW * 2.0, ARROW)
	_arrow.position = Vector2(arrow_x - ARROW, -ARROW if points_up else panel_size.y)
	_arrow.queue_redraw()
	_box.pivot_offset = Vector2(arrow_x, -ARROW if points_up else panel_size.y + ARROW)


func _animate_in() -> void:
	if Motion.reduced:
		return
	_box.scale = Vector2.ONE * 0.6
	_box.modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(_box, "scale", Vector2.ONE, Motion.POP_IN).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_box, "modulate:a", 1.0, Motion.POP_IN)


## Fecha sozinha daqui a `seconds` sem toque (ex.: 1,5 s depois de alimentar os animais).
func close_after(seconds: float) -> void:
	options["auto_close"] = seconds
	_idle = 0.0


## Fecha com `pop_out` (ou na hora). Só avisa uma vez.
func close(immediate: bool = false) -> void:
	if closing:
		if immediate:
			queue_free()
		return
	closing = true
	_end_drag(false)
	_stop_hint()
	if current == self:
		current = null
	# O botão pode abrir um Sheet durante o soltar do dedo. Até sair da árvore,
	# o painel ainda precisa consumir esse evento para ele não atingir o mapa atrás.
	closed.emit()
	if immediate or Motion.reduced or not is_inside_tree():
		queue_free()
		return
	var tween := create_tween().set_parallel()
	tween.tween_property(_box, "scale", Vector2.ONE * 0.8, Motion.POP_OUT)
	tween.tween_property(_box, "modulate:a", 0.0, Motion.POP_OUT)
	tween.chain().tween_callback(queue_free)


func _exit_tree() -> void:
	if is_instance_valid(room) and room.tray_dragging and _drag_index >= 0:
		room.tray_dragging = false
	if current == self:
		current = null


# --- Itens: toque e arrasto --------------------------------------------------------

func item_count() -> int:
	return _items.size()


func entry_ids() -> Array[String]:
	var ids: Array[String] = []
	for entry: Dictionary in entries:
		ids.append(str(entry.get("id", "")))
	return ids


func item_node(id: String) -> Control:
	for i in entries.size():
		if str(entries[i].get("id", "")) == id:
			return _items[i]
	return null


func _entry_index(id: String) -> int:
	for i in entries.size():
		if str(entries[i].get("id", "")) == id:
			return i
	return -1


## Ponto da tela (coordenadas globais) no meio do item: serve de origem do arrasto simulado.
func item_center(id: String) -> Vector2:
	var item := item_node(id)
	return item.global_position + item.size / 2.0 if item else Vector2.ZERO


## Captura única: ícones, legendas e vãos seguem o mesmo gesto. Consome o toque
## antes do ScrollContainer; o mouse sintético não pode rolar uma segunda vez.
func _input(event: InputEvent) -> void:
	if closing or not is_visible_in_tree() or not is_instance_valid(_recipe_scroll): return
	var touch := event as InputEventScreenTouch
	var drag := event as InputEventScreenDrag
	var button := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	var point := Vector2.ZERO
	var down := false
	var up := false
	if touch:
		if _recipe_active and touch.index != _recipe_touch: return
		point = touch.position
		down = touch.pressed
		up = not touch.pressed
	elif drag:
		if not _recipe_active or drag.index != _recipe_touch: return
		point = drag.position
	elif button or motion:
		point = button.position if button else motion.position
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			if _recipe_active or Time.get_ticks_msec() < _recipe_mouse_until:
				get_viewport().set_input_as_handled()
			return
		if _recipe_touch >= 0: return
		if button:
			if button.button_index != MOUSE_BUTTON_LEFT: return
			down = button.pressed
			up = not button.pressed
	else:
		return
	if down:
		if _recipe_active or not _recipe_scroll.get_global_rect().has_point(point): return
		_recipe_velocity = 0.0
		# A barra conserva o gesto nativo, inclusive mouse emulado.
		if _recipe_scroll.get_h_scroll_bar().get_global_rect().has_point(point): return
		_recipe_active = true
		_recipe_touch = touch.index if touch else -1
		_recipe_swiping = false
		_press_global = point
		_recipe_last = point
		_recipe_position = _recipe_scroll.scroll_horizontal
		_recipe_sample_usec = Time.get_ticks_usec()
		_recipe_motion_usec = _recipe_sample_usec
		_reveal_frames = 0
		_pressed = -1
		for i in _items.size():
			if _items[i].get_global_rect().has_point(point):
				_pressed = i
				break
		_touched()
		_stop_hint()
	elif not _recipe_active:
		return
	else:
		_recipe_move(point)
		if up:
			var index := _pressed
			_pressed = -1
			_recipe_active = false
			_recipe_touch = -1
			if touch and touch.canceled:
				_recipe_velocity = 0.0
			elif not _recipe_swiping:
				_recipe_velocity = 0.0
				if index >= 0: _tap(index)
			elif Time.get_ticks_usec() - _recipe_motion_usec > 100000:
				_recipe_velocity = 0.0  # soltar depois de uma pausa não é flick
	if touch or drag: _recipe_mouse_until = Time.get_ticks_msec() + 100
	get_viewport().set_input_as_handled()


func _recipe_move(point: Vector2) -> void:
	if point.distance_to(_press_global) > TAP_SLOP: _recipe_swiping = true
	var dx := _recipe_last.x - point.x
	var now := Time.get_ticks_usec()
	if not is_zero_approx(dx):
		var seconds := maxf(float(now - _recipe_sample_usec) / 1000000.0, 0.001)
		_recipe_velocity = clampf(dx / seconds, -2400.0, 2400.0)
		_recipe_motion_usec = now
		_recipe_set_position(_recipe_position + dx)
	_recipe_last = point
	_recipe_sample_usec = now


func _recipe_set_position(value: float) -> void:
	var bar := _recipe_scroll.get_h_scroll_bar()
	_recipe_position = clampf(value, 0.0, maxf(0.0, bar.max_value - bar.page))
	_recipe_scroll.scroll_horizontal = roundi(_recipe_position)


func _on_item_input(event: InputEvent, index: int) -> void:
	if is_instance_valid(_recipe_scroll): return
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			press_item(index, button.global_position)
		else:
			release_item(button.global_position)
		accept_event_for(index)
		return
	var motion := event as InputEventMouseMotion
	if motion and _pressed == index:
		move_item(motion.global_position)
		accept_event_for(index)


func accept_event_for(index: int) -> void:
	if index >= 0 and index < _items.size():
		_items[index].accept_event()


func press_item(index: int, global_point: Vector2) -> void:
	if closing:
		return
	_pressed = index
	_press_global = global_point
	_gesture.press(global_point)
	_finger = global_point
	_touched()
	_stop_hint()


func move_item(global_point: Vector2) -> void:
	if _pressed < 0 or closing:
		return
	_finger = global_point
	if _drag_index < 0:
		var entry := entries[_pressed]
		if not _gesture.move(global_point):
			return
		if not entry.has("drag") or str(entry.get("error", "")) != "":
			return
		_begin_drag(_pressed)
	else:
		_gesture.move(global_point)
	_follow()


func release_item(global_point: Vector2) -> void:
	if _pressed < 0:
		return
	var index := _pressed
	_pressed = -1
	if _drag_index >= 0:
		_finger = global_point
		_end_drag(true)
		return
	if not closing:
		_tap(index)


## Toque simples no item (também usado pelos testes).
func tap_item(id: String) -> void:
	var index := _entry_index(id)
	if index >= 0:
		_tap(index)


func _tap(index: int) -> void:
	var entry := entries[index]
	if pick:
		select(str(entry.get("id", "")))  # ver o motivo do bloqueio é no detalhe, não num aviso
		return
	var error := str(entry.get("error", ""))
	if error != "":
		Events.toast_requested.emit(error)
		Motion.shake(_items[index])
		var help: Variant = entry.get("help")
		if help is Callable and (help as Callable).is_valid():
			(help as Callable).call()
		return
	var tap: Variant = entry.get("tap")
	if not (tap is Callable) or not (tap as Callable).is_valid():
		return
	var reason: String = (tap as Callable).call()
	if reason != "":
		Events.toast_requested.emit(reason)
		Motion.shake(_items[index])
		return
	Motion.bounce(_items[index])
	_note_success()
	if bool(entry.get("keep_open", false)):
		_refresh_captions()
	else:
		close()


## Modo "pick": seleciona um item da grade (borda, pulinho) e refaz o detalhe.
func select(id: String) -> void:
	var index := _entry_index(id)
	if index < 0:
		return
	var changed := id != selected
	selected = id
	for i in _circle_styles.size():
		_circle_styles[i].set_border_width_all(3 if i == index else 0)
	Motion.bounce(_items[index])
	if changed:
		if options.get("on_select") is Callable:
			(options.on_select as Callable).call(id)
		selected_changed.emit(id)
		if _detail:
			_detail.refresh()
			_reveal_frames = 3


## Faz o detalhe se refazer já (depois de uma ação que mudou o que ele mostra).
func refresh_detail() -> void:
	if _detail:
		_detail.refresh()
		_reveal_frames = 3


## Ícone voando de um ponto da tela a outro (a receita indo da grade para a bolinha da fila).
func fly_icon(texture: Texture2D, from_global: Vector2, to_global: Vector2) -> void:
	if Motion.reduced or not is_inside_tree() or closing:
		return
	var token := _make_token(texture)
	token.name = "FlyingIcon"
	add_child(token)
	var half := Vector2(GHOST_PX, GHOST_PX) / 2.0
	token.position = from_global - room.global_position - half
	var tween := create_tween()
	tween.tween_property(token, "position", to_global - room.global_position - half, FLY_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(token.queue_free)


## Dentro do painel, o nó do detalhe/cabeçalho que tiver este nome (testes e animações).
func find_in_panel(node_name: String) -> Node:
	return _box.find_child(node_name, true, false)


func _begin_drag(index: int) -> void:
	_drag_index = index
	if str(entries[index].get("id", "")) == "water": GameState.begin_album_water_drag()
	room.tray_dragging = true
	_ghost = _gesture.begin(self, entries[index].get("icon") as Texture2D)
	_items[index].modulate.a = 0.5
	_fade_box(DRAG_ALPHA)  # a bandeja some um pouco para não esconder os canteiros que estão atrás dela


## Ficha redonda com o ícone (o "fantasma" que o dedo carrega e a mãozinha de ensino).
func _make_token(texture: Texture2D) -> Control:
	return DragGhost.make_token(texture)


func _fade_box(alpha: float) -> void:
	if Motion.reduced or not is_inside_tree():
		_box.modulate.a = alpha
		return
	create_tween().tween_property(_box, "modulate:a", alpha, Motion.FADE)


## Ponto do mundo onde o fantasma (a ponta de baixo dele) está.
func ghost_world_point() -> Vector2:
	return room.screen_to_world(_gesture.target())


func _follow() -> void:
	_gesture.finger = _finger
	_gesture.follow(self)
	_act_here()


## Chama a ação do item no ponto atual do fantasma.
func _act_here() -> void:
	var drag: Callable = entries[_drag_index].get("drag", Callable())
	if not drag.is_valid():
		return
	if drag.call(ghost_world_point()) == true:
		acted += 1
		Haptics.tap()
		_note_success()
		_refresh_captions()


func _process(delta: float) -> void:
	if closing:
		return
	if is_instance_valid(_recipe_scroll) and not _recipe_active and not is_zero_approx(_recipe_velocity):
		var before := _recipe_position
		var decay := exp(-7.0 * delta)
		_recipe_set_position(before + _recipe_velocity * (1.0 - decay) / 7.0)
		_recipe_velocity *= decay
		if absf(_recipe_velocity) < 8.0 or is_equal_approx(before, _recipe_position):
			_recipe_velocity = 0.0
	if pick or options.get("header") is Control:
		# O detalhe e o cabeçalho mudam de altura: a bandeja acompanha e continua dentro da tela.
		var minimum := _panel.get_combined_minimum_size()
		if pick or not minimum.is_equal_approx(_last_min):
			_last_min = minimum
			_place()
	if pick and _reveal_frames > 0:
		_reveal_frames -= 1
		if _reveal_frames == 0 and is_instance_valid(_detail):
			_body_scroll.ensure_control_visible(_detail)
			var recipes := find_in_panel("RecipeScroll") as ScrollContainer
			var item := item_node(selected)
			if recipes and item: recipes.ensure_control_visible(item)
	if _drag_index >= 0:
		# Rolagem na borda: o dedo perto da lateral/embaixo (ou o fantasma perto do HUD) anda a câmera.
		var local := _finger - room.global_position
		var ghost_top := local.y - GHOST_LIFT - GHOST_PX
		var direction := Vector2.ZERO
		if local.x < EDGE: direction.x = -1.0
		elif local.x > room.size.x - EDGE: direction.x = 1.0
		if local.y > room.size.y - EDGE - 22.0: direction.y = 1.0
		elif ghost_top < TOP_LIMIT - EDGE: direction.y = -1.0
		if direction != Vector2.ZERO:
			room.scroll_by(direction * EDGE_SPEED)
			_follow()
		return
	var auto_close := float(options.get("auto_close", 0.0))
	if auto_close > 0.0 and _pressed < 0:
		_idle += delta
		if _idle >= auto_close:
			close()


## Termina o arrasto. Se agiu em pelo menos um alvo, a bandeja fecha; senão volta ao normal.
func _end_drag(allow_close: bool) -> void:
	if _drag_index < 0:
		return
	var index := _drag_index
	if str(entries[index].get("id", "")) == "water": GameState.end_album_water_drag()
	_drag_index = -1
	if is_instance_valid(room):
		room.tray_dragging = false
	_gesture.finish()
	_ghost = null
	if not closing:
		_fade_box(1.0)
	if index < _items.size() and is_instance_valid(_items[index]):
		_items[index].modulate.a = 1.0
	_idle = 0.0
	if allow_close and acted > 0:
		close()


## Simulação de arrasto (testes e capturas): começa no item, passa pelos pontos (coordenadas globais) e solta.
func drag_through(id: String, global_points: Array[Vector2], release: bool = true) -> void:
	var index := _entry_index(id)
	if index < 0:
		return
	var start := item_center(id)
	press_item(index, start)
	for point in global_points:
		move_item(point)
	if release:
		release_item(global_points[global_points.size() - 1] if not global_points.is_empty() else start)


func is_dragging() -> bool:
	return _drag_index >= 0


func _touched() -> void:
	_idle = 0.0


func _note_success() -> void:
	var key := str(options.get("hint", {}).get("key", ""))
	if key != "" and not bool(GameState.progress.seen.get(key, false)):
		var keys: Array[String] = [key]
		GameState.mark_seen(keys)


func _entry_dimmed(entry: Dictionary) -> bool:
	var dim_fn: Variant = entry.get("dim_fn")
	return dim_fn is Callable and (dim_fn as Callable).is_valid() and bool((dim_fn as Callable).call())


func _refresh_captions() -> void:
	for i in entries.size():
		var error_fn: Variant = entries[i].get("error_fn")
		if error_fn is Callable and (error_fn as Callable).is_valid():
			entries[i]["error"] = (error_fn as Callable).call()
			var blocked := str(entries[i].error) != ""
			var lock := _items[i].get_node_or_null("Lock") as Control
			if lock: lock.visible = blocked
		(_items[i].get_node("Body") as Control).modulate.a = 0.45 if str(entries[i].get("error", "")) != "" or _entry_dimmed(entries[i]) else 1.0
		var fn: Variant = entries[i].get("caption_fn")
		if fn is Callable and (fn as Callable).is_valid():
			_captions[i].text = (fn as Callable).call()
		var badge_fn: Variant = entries[i].get("badge_fn")
		if badge_fn is Callable and (badge_fn as Callable).is_valid() and _badges[i]:
			var text: String = (badge_fn as Callable).call()
			_badges[i].text = text
			_badges[i].visible = text != ""


# --- Mãozinha de ensino ------------------------------------------------------------

## A semente (ou foice) sai do item e desliza por dois alvos, em loop, até o jogador mexer em algo.
func _start_hint() -> void:
	await get_tree().process_frame  # espera o layout dos itens para saber de onde a mãozinha sai
	var hint: Dictionary = options.get("hint", {})
	if closing or not is_inside_tree() or hint.is_empty() or bool(GameState.progress.seen.get(str(hint.get("key", "")), false)):
		if is_instance_valid(_hint_label):
			_hint_label.modulate.a = 0.0
		return
	var points: Array = hint.get("points", [])
	var from_index := clampi(int(hint.get("from", 0)), 0, maxi(0, _items.size() - 1))
	if points.size() < 1 or _items.is_empty():
		return
	var start := _items[from_index].global_position + _items[from_index].size / 2.0 - room.global_position
	_hint_node = _make_token(hint.get("icon") as Texture2D)
	_hint_node.name = "HintHand"
	_hint_node.modulate.a = 0.0
	add_child(_hint_node)
	var offset := Vector2(GHOST_PX / 2.0, GHOST_PX)
	if Motion.reduced:
		# Sem animação: a semente fica parada sobre o primeiro canteiro, mostrando onde soltar.
		_hint_node.position = room.world_to_screen(points[0]) - room.global_position - offset + Vector2(0, GHOST_LIFT * 0.5)
		_hint_node.modulate.a = 0.85
		return
	_hint_tween = create_tween().set_loops()
	_hint_tween.tween_callback(func() -> void: _hint_node.position = start - offset / 2.0)
	_hint_tween.tween_property(_hint_node, "modulate:a", 0.85, 0.2)
	for point: Vector2 in points:
		var target := room.world_to_screen(point) - room.global_position - offset + Vector2(0, GHOST_LIFT * 0.5)
		_hint_tween.tween_property(_hint_node, "position", target, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_hint_tween.tween_interval(0.15)
	_hint_tween.tween_property(_hint_node, "modulate:a", 0.0, 0.2)
	_hint_tween.tween_interval(0.4)


func _stop_hint() -> void:
	if _hint_tween and _hint_tween.is_valid():
		_hint_tween.kill()
	if is_instance_valid(_hint_node):
		_hint_node.queue_free()
	_hint_node = null
	if is_instance_valid(_hint_label):
		_hint_label.modulate.a = 0.0


## Setinha de 12 px na borda da bandeja, apontando para o alvo.
class TrayArrow extends Control:
	var points_up := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var tip := Vector2(w / 2.0, 0.0) if points_up else Vector2(w / 2.0, h)
		var base_y := h if points_up else 0.0
		var left := Vector2(0.0, base_y)
		var right := Vector2(w, base_y)
		draw_colored_polygon(PackedVector2Array([left, right, tip]), Palette.PAPER)
		draw_line(left, tip, Palette.CARD_LINE, 2.0)
		draw_line(right, tip, Palette.CARD_LINE, 2.0)
		# Cobre a borda da bandeja sob a base da setinha.
		draw_line(left + Vector2(2, 0), right - Vector2(2, 0), Palette.PAPER, 3.0)
