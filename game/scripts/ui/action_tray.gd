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
var _pressed := -1
var _press_global := Vector2.ZERO
var _drag_index := -1
var _finger := Vector2.ZERO
var _idle := 0.0
var _tip := Vector2.ZERO
var _circle_styles: Array[StyleBoxFlat] = []
var _detail: SheetBuilder.LiveBox
var _last_min := Vector2.ZERO


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
	pick = str(options.get("mode", "")) == "pick"
	if pick:
		_panel.custom_minimum_size.x = PICK_WIDTH
		selected = str(options.get("selected", ""))
		var heading := UiKit.hbox(4)
		var title := UiKit.fill_label(str(options.get("title", "")), &"SectionLabel")
		heading.add_child(title)
		var close_button := UiKit.icon_button(UiKit.ui_icon("ui_close"), close, 44)
		close_button.name = "CloseTray"
		close_button.mouse_filter = Control.MOUSE_FILTER_STOP
		heading.add_child(close_button)
		column.add_child(heading)
	elif str(options.get("title", "")) != "":
		var title := UiKit.label(str(options.title), &"SmallLabel")
		title.name = "Title"
		title.autowrap_mode = TextServer.AUTOWRAP_OFF
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(title)
	if options.get("header") is Control:
		column.add_child(options.header)
	if not entries.is_empty():
		column.add_child(_build_items())
	if pick and options.get("detail") is Callable:
		_detail = SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
			box.add_child((options.detail as Callable).call(selected)))
		_detail.name = "Detail"
		column.add_child(_detail)
	var hint: Dictionary = options.get("hint", {})
	if not hint.is_empty():
		_hint_label = UiKit.label(str(hint.get("caption", "")), &"SmallLabel")
		_hint_label.name = "HintLabel"
		_hint_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(_hint_label)
	var footer: Dictionary = options.get("footer_ghost", {})
	if not footer.is_empty():
		var ghost := UiKit.ghost(str(footer.text), func() -> void:
			_touched()
			(footer.action as Callable).call())
		ghost.name = "FooterGhost"
		ghost.mouse_filter = Control.MOUSE_FILTER_STOP
		column.add_child(ghost)
	_arrow = TrayArrow.new()
	_arrow.name = "Arrow"
	_box.add_child(_arrow)
	_panel.reset_size()
	_place()
	_refresh_captions()
	if pick:
		Events.state_changed.connect(_refresh_captions)  # selo "!" e legendas acompanham a mochila
	_animate_in()
	if not hint.is_empty():
		_start_hint.call_deferred()


func _build_items() -> Control:
	var count := entries.size()
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
	body.modulate.a = 0.45 if blocked else 1.0
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
		badge.position = circle.position + Vector2(CIRCLE - 14.0, -4.0)
		badge.visible = badge_text != ""
		item.add_child(badge)
	_badges.append(badge)
	if blocked or entry.has("error_fn"):
		var lock := UiKit.icon(UiKit.ui_icon("ui_lock"), 16)
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
	var bottom_limit := room.size.y - BOTTOM_LIMIT - panel_size.y
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
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
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


func _on_item_input(event: InputEvent, index: int) -> void:
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
	_finger = global_point
	_touched()
	_stop_hint()


func move_item(global_point: Vector2) -> void:
	if _pressed < 0 or closing:
		return
	_finger = global_point
	if _drag_index < 0:
		var entry := entries[_pressed]
		if global_point.distance_to(_press_global) <= TAP_SLOP:
			return
		if not entry.has("drag") or str(entry.get("error", "")) != "":
			return
		_begin_drag(_pressed)
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


## Faz o detalhe se refazer já (depois de uma ação que mudou o que ele mostra).
func refresh_detail() -> void:
	if _detail:
		_detail.refresh()


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
	room.tray_dragging = true
	_ghost = _make_token(entries[index].get("icon") as Texture2D)
	_ghost.name = "Ghost"
	add_child(_ghost)
	Motion.pop_in(_ghost)
	_items[index].modulate.a = 0.5
	_fade_box(DRAG_ALPHA)  # a bandeja some um pouco para não esconder os canteiros que estão atrás dela


## Ficha redonda com o ícone (o "fantasma" que o dedo carrega e a mãozinha de ensino).
func _make_token(texture: Texture2D) -> Control:
	var token := Panel.new()
	token.size = Vector2(GHOST_PX, GHOST_PX)
	token.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PAPER
	style.set_corner_radius_all(int(GHOST_PX / 2.0))
	style.set_border_width_all(2)
	style.border_color = Palette.CARD_LINE
	style.shadow_color = Palette.SHADE
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	token.add_theme_stylebox_override("panel", style)
	var icon := UiKit.icon(texture, int(ICON_PX))
	icon.position = (Vector2(GHOST_PX, GHOST_PX) - Vector2(ICON_PX, ICON_PX)) / 2.0
	icon.size = Vector2(ICON_PX, ICON_PX)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	token.add_child(icon)
	return token


func _fade_box(alpha: float) -> void:
	if Motion.reduced or not is_inside_tree():
		_box.modulate.a = alpha
		return
	create_tween().tween_property(_box, "modulate:a", alpha, Motion.FADE)


## Ponto do mundo onde o fantasma (a ponta de baixo dele) está.
func ghost_world_point() -> Vector2:
	return room.screen_to_world(_finger + Vector2(0, -GHOST_LIFT))


func _follow() -> void:
	_ghost.position = _finger - room.global_position - Vector2(GHOST_PX / 2.0, GHOST_PX + GHOST_LIFT)
	_act_here()


## Chama a ação do item no ponto atual do fantasma.
func _act_here() -> void:
	var drag: Callable = entries[_drag_index].get("drag", Callable())
	if not drag.is_valid():
		return
	if drag.call(ghost_world_point()) == true:
		acted += 1
		_note_success()
		_refresh_captions()


func _process(delta: float) -> void:
	if closing:
		return
	if pick or options.get("header") is Control:
		# O detalhe e o cabeçalho mudam de altura: a bandeja acompanha e continua dentro da tela.
		var minimum := _panel.get_combined_minimum_size()
		if not minimum.is_equal_approx(_last_min):
			_last_min = minimum
			_place()
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
	_drag_index = -1
	if is_instance_valid(room):
		room.tray_dragging = false
	if is_instance_valid(_ghost):
		Motion.pop_out(_ghost)
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


func _refresh_captions() -> void:
	for i in entries.size():
		var error_fn: Variant = entries[i].get("error_fn")
		if error_fn is Callable and (error_fn as Callable).is_valid():
			entries[i]["error"] = (error_fn as Callable).call()
			var blocked := str(entries[i].error) != ""
			(_items[i].get_node("Body") as Control).modulate.a = 0.55 if blocked else 1.0
			var lock := _items[i].get_node_or_null("Lock") as Control
			if lock: lock.visible = blocked
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
