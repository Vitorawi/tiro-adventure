class_name Popover
extends PanelContainer
## Balão pequeno que abre embaixo de um botão (ex.: o avatar do HUD) e some sozinho em 2 s
## ou ao tocar fora. `seconds = 0` mantém resumos abertos para leitura. Um só por vez.

const LIFETIME := 2.0
const GAP := 6.0
const EDGE := 8.0

var _catcher: Control
var _tween: Tween


## Abre `content` logo abaixo de `anchor`, dentro de `host` (cobre a tela para pegar o toque de fora).
static func open(host: Control, anchor: Control, content: Control, seconds: float = LIFETIME) -> Popover:
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
	popover.theme_type_variation = &"CardPanel"
	popover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popover.add_child(content)
	catcher.add_child(popover)
	catcher.gui_input.connect(func(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click and click.pressed:
			popover.close())
	popover._place(host, anchor)
	popover._settle.call_deferred(host, anchor)
	popover._start(seconds)
	return popover


func _place(host: Control, anchor: Control) -> void:
	reset_size()
	var origin := anchor.global_position - host.global_position
	var x := clampf(origin.x, EDGE, maxf(EDGE, host.size.x - size.x - EDGE))
	position = Vector2(x, origin.y + anchor.size.y + GAP)


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
