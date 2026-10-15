class_name WorldSelector
extends Control
## Seletor sobre o mundo: arrasto horizontal com encaixe e arrasto para baixo para fechar.

signal chosen(world_id: String)
signal closed

const GAP := 16
const STEP := 256.0
const DRAG_SLOP := 10.0
var centered_world: String = "house"
var _scroll: ScrollContainer
var _cards: HBoxContainer
var _left: Control
var _right: Control
var _buttons: Array[WorldCard] = []
var _snap: Tween
var _pressed: bool = false
var _dragging: bool = false
var _start: Vector2
var _initial_scroll: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Palette.DIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var title := UiKit.label("Para onde vamos?", &"TitleLabel", Palette.INK_ON_DARK)
	title.name = "SelectorTitle"
	title.position = Vector2(16, 112)
	title.anchor_right = 1
	title.offset_right = -72
	title.offset_bottom = 152
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.add_theme_color_override("font_outline_color", Palette.INK)
	title.add_theme_constant_override("outline_size", 4)
	add_child(title)
	var close_button := UiKit.icon_button(UiKit.ui_icon("ui_close"), dismiss, 44)
	close_button.name = "CloseSelector"
	close_button.anchor_left = 1
	close_button.anchor_right = 1
	close_button.offset_left = -60
	close_button.offset_right = -16
	close_button.offset_top = 108
	close_button.offset_bottom = 152
	add_child(close_button)
	_scroll = ScrollContainer.new()
	_scroll.name = "WorldCarousel"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_scroll)
	_cards = UiKit.hbox(GAP)
	_cards.name = "Cards"
	_scroll.add_child(_cards)
	_left = Control.new()
	_cards.add_child(_left)
	for world_id: String in Database.worlds:
		var holder := Control.new()
		holder.custom_minimum_size = WorldCard.CARD_SIZE
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var card := WorldCard.new()
		card.setup(world_id)
		card.pressed.connect(_choose.bind(world_id))
		holder.add_child(card)
		_cards.add_child(holder)
		_buttons.append(card)
	_right = Control.new()
	_cards.add_child(_right)
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	if not is_instance_valid(_scroll):
		return
	_scroll.position = Vector2(0, maxf(170, (size.y - WorldCard.CARD_SIZE.y) / 2))
	_scroll.size = Vector2(size.x, WorldCard.CARD_SIZE.y + 16)
	var margin := maxf(0, (size.x - WorldCard.CARD_SIZE.x) / 2 - GAP)
	_left.custom_minimum_size.x = margin
	_right.custom_minimum_size.x = margin
	center_on.call_deferred(centered_world, false)


func open(current: String) -> void:
	show()
	refresh(current)
	center_on.call_deferred(current, false)


func refresh(current: String) -> void:
	for card: WorldCard in _buttons:
		card.refresh(current)


func dismiss() -> void:
	_pressed = false
	_dragging = false
	if _snap: _snap.kill()
	hide()
	closed.emit()


func center_on(world_id: String, animate: bool = true) -> void:
	var index := Database.worlds.keys().find(world_id)
	if index < 0:
		return
	centered_world = world_id
	if _snap: _snap.kill()
	var target := roundi(index * STEP)
	if animate and not Motion.reduced:
		_snap = create_tween()
		_snap.tween_property(_scroll, "scroll_horizontal", target, Motion.SETTLE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_scroll.scroll_horizontal = target


func snap_nearest() -> void:
	var index := clampi(roundi(float(_scroll.scroll_horizontal) / STEP), 0, _buttons.size() - 1)
	center_on(_buttons[index].world_id)


func _choose(id: String) -> void:
	if _dragging:
		return
	if Places.world_error(id) != "":
		return
	if centered_world != id:
		center_on(id)
	else:
		chosen.emit(id)


func _process(_delta: float) -> void:
	if not visible: return
	for card: WorldCard in _buttons:
		var distance := absf(card.get_parent().position.x - _scroll.scroll_horizontal - (size.x - WorldCard.CARD_SIZE.x) / 2)
		var weight := clampf(distance / STEP, 0, 1)
		card.pivot_offset = WorldCard.CARD_SIZE / 2
		card.scale = Vector2.ONE * lerpf(1, 0.92, weight)
		card.modulate.a = lerpf(1, 0.85, weight)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed and get_global_rect().has_point(button.position):
			if _snap: _snap.kill()
			_pressed = true
			_dragging = false
			_start = button.position
			_initial_scroll = _scroll.scroll_horizontal
		elif not button.pressed and _pressed:
			_pressed = false
			var movement := button.position - _start
			if _dragging:
				get_viewport().set_input_as_handled()
				for card: WorldCard in _buttons:
					card.set_pressed_no_signal(false)
				if movement.y > 64 and movement.y > absf(movement.x):
					dismiss()
				else:
					snap_nearest()
			elif not _over_card(button.position):
				# O botão de fechar tem seu próprio callback; os demais espaços fecham também.
				dismiss()
			else:
				for card: WorldCard in _buttons:
					if card.disabled and card.get_global_rect().has_point(button.position):
						Motion.shake(card)
		return
	var motion := event as InputEventMouseMotion
	if motion and _pressed:
		var movement := motion.position - _start
		if movement.length() > DRAG_SLOP: _dragging = true
		if _dragging:
			if absf(movement.x) >= absf(movement.y):
				_scroll.scroll_horizontal = _initial_scroll - roundi(movement.x)
			get_viewport().set_input_as_handled()


func _over_card(point: Vector2) -> bool:
	if not _scroll.get_global_rect().has_point(point): return false
	for card: WorldCard in _buttons:
		if card.get_global_rect().has_point(point): return true
	return false
