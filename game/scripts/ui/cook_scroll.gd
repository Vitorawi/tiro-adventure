class_name CookScroll
extends Control
## Rolagem própria (vertical ou horizontal) da cozinha nova: uma janela que recorta o `content` e o move com o dedo.
## Existe porque o `CookPanel` mora num Control com `scale` (unidades do Figma) e o gestor global de arrasto mede em
## pixels de tela: aqui o `relative` do mouse já chega nas unidades do painel, então o conteúdo acompanha o dedo 1:1.
## Toque curto (menos de ~12 px de tela) = `on_tap` do filho sob o dedo (meta `on_tap`, um Callable); arrastar rola com
## inércia. O conteúdo deve ter `size` definido e filhos com `size` (o teste de acerto usa o retângulo deles).

signal scrolled

const SLOP_PX := 12.0
const DECAY := 6.0

var vertical := true
var content := Control.new()
var offset := 0.0

var _pressing := false
var _dragging := false
var _press := Vector2.ZERO
var _velocity := 0.0
var _last_usec := 0
var _tween: Tween


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	content.name = "Content"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	set_process(false)


func content_length() -> float:
	return content.size.y if vertical else content.size.x


func view_length() -> float:
	return size.y if vertical else size.x


func max_offset() -> float:
	return maxf(0.0, content_length() - view_length())


## Muda o deslocamento (cortado entre 0 e o máximo) e avisa quem acompanha (barra de rolagem).
func move_to(value: float) -> void:
	var clamped := clampf(value, 0.0, max_offset())
	var changed := not is_equal_approx(clamped, offset)
	offset = clamped
	content.position = Vector2(0.0, -offset) if vertical else Vector2(-offset, 0.0)
	if changed:
		scrolled.emit()


func scroll_to(value: float, animate: bool = true) -> void:
	if is_instance_valid(_tween):
		_tween.kill()
	_velocity = 0.0
	if not animate or Motion.reduced or not is_inside_tree():
		move_to(value)
		return
	_tween = create_tween()
	_tween.tween_method(move_to, offset, clampf(value, 0.0, max_offset()), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Rola o mínimo para mostrar `rect` (coordenadas do conteúdo) por inteiro.
func scroll_to_show(rect: Rect2, animate: bool = false) -> void:
	var start := rect.position.y if vertical else rect.position.x
	var length := rect.size.y if vertical else rect.size.x
	if start < offset:
		scroll_to(start, animate)
	elif start + length > offset + view_length():
		scroll_to(start + length - view_length(), animate)


## Janela que o conteúdo ocupa agora (em coordenadas do conteúdo): para saber o que está à vista.
func visible_span() -> Vector2:
	return Vector2(offset, offset + view_length())


func _screen_scale() -> float:
	var factor := get_global_transform_with_canvas().get_scale().x
	return factor if factor > 0.0001 else 1.0


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null:
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed:
				_pressing = true
				_dragging = false
				_press = button.position
				_velocity = 0.0
				_last_usec = Time.get_ticks_usec()
				if is_instance_valid(_tween):
					_tween.kill()
			elif _pressing:
				_pressing = false
				if _dragging:
					_dragging = false
					if absf(_velocity) > 20.0 and Time.get_ticks_usec() - _last_usec < 120000:
						set_process(true)
				else:
					tap_at(button.position)
			accept_event()
		elif button.pressed and button.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var step := 40.0 if button.button_index == MOUSE_BUTTON_WHEEL_DOWN else -40.0
			move_to(offset + step)
			accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion != null and _pressing:
		var delta_axis := motion.relative.y if vertical else motion.relative.x
		if not _dragging and (motion.position - _press).length() * _screen_scale() > SLOP_PX:
			_dragging = true
			delta_axis = 0.0  # o primeiro passo só arma o arrasto: o conteúdo não dá um salto
		if _dragging:
			var now := Time.get_ticks_usec()
			var seconds := maxf(float(now - _last_usec) / 1000000.0, 0.001)
			_velocity = lerpf(_velocity, -delta_axis / seconds, 0.5)
			_last_usec = now
			move_to(offset - delta_axis)
		accept_event()


func _process(delta: float) -> void:
	if _pressing or absf(_velocity) < 8.0:
		_velocity = 0.0
		set_process(false)
		return
	var before := offset
	move_to(offset + _velocity * delta)
	_velocity *= exp(-DECAY * delta)
	if is_equal_approx(before, offset):
		_velocity = 0.0
		set_process(false)


## Acha o filho do conteúdo sob o ponto (coordenadas desta janela) e chama o `on_tap` dele.
func tap_at(point: Vector2) -> void:
	var local := point - content.position
	for i in range(content.get_child_count() - 1, -1, -1):
		var child := content.get_child(i) as Control
		if child == null or not child.visible or not child.has_meta("on_tap"):
			continue
		var pad: Vector2 = child.get_meta("hit_pad", Vector2.ZERO)  # área de toque maior que o desenho, sem mudar o visual
		if Rect2(child.position - pad, child.size + pad * 2.0).has_point(local):
			(child.get_meta("on_tap") as Callable).call()
			return
