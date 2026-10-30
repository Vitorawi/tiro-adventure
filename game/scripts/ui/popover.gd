class_name Popover
extends PanelContainer
## Balão pequeno que abre embaixo de um botão (ex.: o avatar do HUD) e some sozinho em 2 s
## ou ao tocar fora. `seconds = 0` mantém resumos abertos para leitura. Um só por vez.

const LIFETIME := 2.0
const GAP := 6.0
const EDGE := 8.0

var _catcher: Control
var _tween: Tween
var _bottom_limit := -1.0
var _bare := false


## Abre `content` logo abaixo de `anchor`, dentro de `host` (cobre a tela para pegar o toque de fora).
static func open(host: Control, anchor: Control, content: Control, seconds: float = LIFETIME, bottom_limit: float = -1.0) -> Popover:
	var old := host.get_node_or_null("PopoverCatcher")
	if old:
		old.free()
	var catcher := Control.new()
	catcher.name = "PopoverCatcher"
	catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.z_index = 13
	host.add_child(catcher)
	var popover := Popover.new()
	popover.name = "Popover"
	popover._catcher = catcher
	popover._bottom_limit = bottom_limit
	popover.theme_type_variation = &"CardPanel"
	# `popover_bare`: o conteúdo traz a própria moldura (ex.: o mini-cartão de madeira); sem cartão branco nem rabinho.
	popover._bare = content.has_meta("popover_bare")
	if popover._bare:
		popover.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	else:
		var style := UiKit.surface(Palette.CARD, 16, true)
		style.set_content_margin_all(12)
		popover.add_theme_stylebox_override("panel", style)
	popover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Texto com quebra automática não fornece largura mínima ao PanelContainer.
	popover.custom_minimum_size.x = minf(200.0, maxf(0.0, host.size.x - EDGE * 2.0))
	popover.add_child(content)
	catcher.add_child(popover)
	catcher.gui_input.connect(func(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		# Botões PASS deixam a pressão subir até o fundo; só o lado de fora fecha.
		if click and click.pressed and not popover.get_rect().has_point(click.position):
			popover.close())
	popover._place(host, anchor)
	popover._settle.call_deferred(host, anchor)
	popover._start(seconds)
	return popover


func _place(host: Control, anchor: Control) -> void:
	reset_size()
	var origin := anchor.global_position - host.global_position
	var x := clampf(origin.x, EDGE, maxf(EDGE, host.size.x - size.x - EDGE))
	if _bare:
		x = maxf(EDGE, (host.size.x - size.x) / 2.0)  # cartão com moldura própria e sem rabinho: centralizado na tela
	var y := origin.y + anchor.size.y + GAP
	var bottom := minf(host.size.y - EDGE, _bottom_limit) if _bottom_limit >= 0.0 else host.size.y - EDGE
	# Cuidados ficam no rodapé: sem espaço abaixo, abre acima do botão.
	if y + size.y > bottom:
		y = origin.y - size.y - GAP
	y = clampf(y, EDGE, maxf(EDGE, bottom - size.y))
	position = Vector2(x, y)
	var tip := Vector2(clampf(origin.x + anchor.size.x / 2 - x, 16, maxf(16, size.x - 16)), 0 if y > origin.y else size.y)
	set_meta("tail_tip", tip)
	set_meta("tail_above", y < origin.y)
	queue_redraw()


func _draw() -> void:
	if _bare or not has_meta("tail_tip"): return
	var tip: Vector2 = get_meta("tail_tip")
	var direction := 1.0 if bool(get_meta("tail_above")) else -1.0
	draw_colored_polygon(PackedVector2Array([tip + Vector2(-8, 0), tip + Vector2(0, direction * 8), tip + Vector2(8, 0)]), Palette.CARD)


## Rótulos com quebra de linha só informam a altura correta depois de receber a largura.
func _settle(host: Control, anchor: Control) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(_catcher) and not _catcher.is_queued_for_deletion() and is_instance_valid(host) and is_instance_valid(anchor):
		_place(host, anchor)


func _start(seconds: float) -> void:
	if seconds <= 0:
		if not Motion.reduced: Motion.pop_in(self)
		return  # resumos de leitura ficam até tocar fora ou abrir os detalhes
	if Motion.reduced:
		_tween = create_tween()
	else:
		Motion.pop_in(self)
		_tween = create_tween()
	_tween.tween_interval(seconds)
	_tween.tween_callback(close)


## Fecha com um sumiço curto; o toque de fora também chega aqui.
func close() -> void:
	if not is_instance_valid(_catcher) or _catcher.is_queued_for_deletion():
		return
	var catcher := _catcher
	_catcher = null
	if _tween:
		_tween.kill()
	catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE  # o toque já não fica preso durante o sumiço
	var fade := Motion.pop_out(self, false)
	fade.finished.connect(catcher.queue_free)
	if Motion.reduced:
		catcher.queue_free()
