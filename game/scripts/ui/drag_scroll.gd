extends Node
## Rolagem por arrasto em QUALQUER ScrollContainer visível: o dedo pode cair sobre botões, cartões
## ou ícones e, passando da folga (SLOP), a lista rola com inércia. Um único gestor (instalado pela
## casca, `UiKit.install_drag_scroll`) cobre Sheet, Mochila, Missões, caderninho, bandejas etc.
##
## Como o toque não vira clique:
##  - o gesto só começa quando o ponto de toque cai dentro de um ScrollContainer (teste de "o que está
##    por cima" feito aqui, sem depender de sinais);
##  - depois da folga os ScreenDrag/MouseMotion são consumidos antes dos controles;
##  - o soltar do mouse (real ou emulado do toque) é deslocado para fora da tela: o BaseButton só
##    dispara `pressed` se soltar dentro dele, e `UiKit.on_tap` segue a mesma regra.
## Rolagens com gesto próprio (grade da bandeja, guia de comida) levam a meta `own_drag_scroll`.

const SLOP := 10.0
const DECAY := 7.0
const MAX_SPEED := 2400.0
const GRACE_MSEC := 200
const FAR := Vector2(-100000.0, -100000.0)

enum { IDLE, PENDING, SWIPING }

var _state := IDLE
var _src := -2  # -1 = mouse, >= 0 = índice do dedo
var _chain: Array[ScrollContainer] = []
var _scroll: ScrollContainer
var _axis := 0  # 1 vertical, 2 horizontal
var _start := Vector2.ZERO
var _last := Vector2.ZERO
var _position := 0.0
var _velocity := 0.0
var _sample_usec := 0
var _motion_usec := 0
var _cancel_until := 0
var _coast: ScrollContainer
var _coast_axis := 0
var _injecting := false


static func install(host: Node) -> Node:
	var existing := host.get_node_or_null("DragScroll")
	if existing:
		return existing
	var node: Node = load("res://scripts/ui/drag_scroll.gd").new()
	node.name = "DragScroll"
	host.add_child(node)
	return node


func _input(event: InputEvent) -> void:
	if _injecting:
		return
	var touch := event as InputEventScreenTouch
	var drag := event as InputEventScreenDrag
	var button := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	if touch:
		if touch.pressed:
			_press(touch.position, touch.index)
		elif touch.index == _src:
			_release(touch.canceled)
	elif drag:
		if _state != IDLE and drag.index == _src:
			_move(drag.position)
			get_viewport().set_input_as_handled()
	elif button and button.button_index == MOUSE_BUTTON_LEFT:
		var emulated := button.device == InputEvent.DEVICE_ID_EMULATION
		if button.pressed:
			if emulated:
				_cancel_until = 0
			else:
				_press(button.global_position, -1)
		else:
			var swiping := _state == SWIPING and (_src == -1 or emulated)
			var late := emulated and Time.get_ticks_msec() < _cancel_until
			if not emulated and _src == -1:
				_release(false)
			if swiping or late:
				button.position = FAR
				button.global_position = FAR
				_cancel_until = 0
	elif motion:
		var emulated_motion := motion.device == InputEvent.DEVICE_ID_EMULATION
		if emulated_motion:
			if _state == SWIPING or Time.get_ticks_msec() < _cancel_until:
				get_viewport().set_input_as_handled()
		elif _src == -1 and _state != IDLE and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_move(motion.global_position)
			if _state == SWIPING:
				get_viewport().set_input_as_handled()


func _press(point: Vector2, index: int) -> void:
	if _state != IDLE:
		return
	_velocity = 0.0
	_coast = null
	_cancel_until = 0
	var hit := _topmost(point)
	if hit == null or hit is Range or hit is LineEdit or hit is TextEdit:
		return
	_chain.clear()
	var node: Node = hit
	while node != null:
		var scroll := node as ScrollContainer
		if scroll:
			if scroll.has_meta("own_drag_scroll"):
				_chain.clear()
				return
			_chain.append(scroll)
		node = node.get_parent()
	if _chain.is_empty():
		return
	_state = PENDING
	_src = index
	_start = point
	_last = point


func _move(point: Vector2) -> void:
	if _state == PENDING:
		var d := point - _start
		if d.length() <= SLOP:
			_last = point
			return
		if not _pick(d):
			_state = IDLE
			_src = -2
			return
	if _state != SWIPING:
		return
	var delta := (_last.y - point.y) if _axis == 1 else (_last.x - point.x)
	var now := Time.get_ticks_usec()
	if not is_zero_approx(delta):
		var seconds := maxf(float(now - _sample_usec) / 1000000.0, 0.001)
		_velocity = clampf(delta / seconds, -MAX_SPEED, MAX_SPEED)
		_motion_usec = now
		_set_position(_position + delta)
	_last = point
	_sample_usec = now


## Escolhe o ScrollContainer (o mais interno que consegue andar para esse lado) e o eixo.
func _pick(d: Vector2) -> bool:
	var axis := 1 if absf(d.y) >= absf(d.x) else 2
	var toward := -d.y if axis == 1 else -d.x  # sinal em que o conteúdo anda
	for scroll in _chain:
		if not is_instance_valid(scroll):
			continue
		var bar: ScrollBar = scroll.get_v_scroll_bar() if axis == 1 else scroll.get_h_scroll_bar()
		var mode := scroll.vertical_scroll_mode if axis == 1 else scroll.horizontal_scroll_mode
		if mode == ScrollContainer.SCROLL_MODE_DISABLED:
			continue
		var room := bar.max_value - bar.page
		if room < 1.0:
			continue
		if (toward > 0.0 and bar.value >= room - 0.5) or (toward < 0.0 and bar.value <= 0.5):
			continue
		_scroll = scroll
		_axis = axis
		_position = bar.value
		_state = SWIPING
		_velocity = 0.0
		_sample_usec = Time.get_ticks_usec()
		_motion_usec = _sample_usec
		_leave_pressed_control()
		return true
	return false


func _set_position(value: float) -> void:
	var bar: ScrollBar = _scroll.get_v_scroll_bar() if _axis == 1 else _scroll.get_h_scroll_bar()
	_position = clampf(value, 0.0, maxf(0.0, bar.max_value - bar.page))
	if _axis == 1:
		_scroll.scroll_vertical = roundi(_position)
	else:
		_scroll.scroll_horizontal = roundi(_position)


func _release(canceled: bool) -> void:
	var was := _state
	_state = IDLE
	_src = -2
	if was != SWIPING:
		return
	_cancel_until = Time.get_ticks_msec() + GRACE_MSEC
	if canceled or Time.get_ticks_usec() - _motion_usec > 100000:
		_velocity = 0.0
	_coast = _scroll
	_coast_axis = _axis


func _process(delta: float) -> void:
	if _state == SWIPING or _coast == null or is_zero_approx(_velocity):
		return
	if not is_instance_valid(_coast):
		_coast = null
		_velocity = 0.0
		return
	var before := _position
	var decay := exp(-DECAY * delta)
	_scroll = _coast
	_axis = _coast_axis
	_set_position(before + _velocity * (1.0 - decay) / DECAY)
	_velocity *= decay
	if absf(_velocity) < 8.0 or is_equal_approx(before, _position):
		_velocity = 0.0
		_coast = null


# --- "O que está por cima do ponto" (mesma ordem de desenho do Godot, sem z_index) ---------------

func _topmost(point: Vector2) -> Control:
	var layers: Array = []
	var index := [0]
	_collect_layers(get_tree().root, layers, index)
	layers.sort_custom(func(a: Array, b: Array) -> bool:
		return int(a[0]) > int(b[0]) if int(a[0]) != int(b[0]) else int(a[1]) > int(b[1]))
	for entry: Array in layers:
		var layer := entry[2] as CanvasLayer
		if not layer.visible:
			continue
		var found := _hit_in(layer, point)
		if found:
			return found
	return _hit_in(get_tree().root, point)


func _collect_layers(node: Node, out: Array, index: Array) -> void:
	for child in node.get_children():
		if child is CanvasLayer:
			index[0] += 1
			out.append([(child as CanvasLayer).layer, index[0], child])
		_collect_layers(child, out, index)


func _hit_in(node: Node, point: Vector2) -> Control:
	for i in range(node.get_child_count(true) - 1, -1, -1):
		var child := node.get_child(i, true)
		if child is CanvasLayer or child is Window:
			continue
		var item := child as CanvasItem
		if item != null and not item.visible:
			continue
		var control := child as Control
		var inside := false
		if control:
			var local := control.get_global_transform_with_canvas().affine_inverse() * point
			inside = Rect2(Vector2.ZERO, control.size).has_point(local)
			if control.clip_contents and not inside:
				continue
		var found := _hit_in(child, point)
		if found:
			return found
		if control and inside and control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			return control
	return null


## O botão que recebeu o toque só deixa de disparar se achar que o dedo saiu de cima dele (isso é
## calculado nos movimentos). Um movimento para fora da tela, injetado uma vez, desarma o botão.
func _leave_pressed_control() -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = FAR
	motion.global_position = FAR
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	_injecting = true
	get_viewport().push_input(motion)
	_injecting = false
