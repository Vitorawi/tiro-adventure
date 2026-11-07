class_name Notice
extends Node
## Central de avisos (02 §5): uma fila, uma posição, um aviso por vez. Textos usam o nó `Toast` da casca;
## momento usa a pílula `MomentNotice` (e o ícone voa até o avatar). Prioridade: erro > momento > foto > info.
## Erro substitui o que estiver na tela; os outros esperam. Nada aparece com cartão modal aberto.

const KINDS: Array[String] = ["error", "moment", "photo", "info"]
const HOLD := {"error": 2.0, "moment": 1.0, "photo": 2.4, "info": 1.6}
const FADE := 0.3
const SLIDE_FROM := 26.0  # o aviso sobe de baixo: começa tantos px abaixo da posição final
const MAX_WIDTH := 300.0
const MIN_HEIGHT := 44.0
const PAD := 16.0  # folga lateral do texto dentro da pílula de madeira
const FONT_PX := 15

## Chamado pela casca: `true` enquanto um cartão ou a fila de cartões ocupa a tela.
var blocked: Callable = Callable()
## Chamado pela casca: `bottom_y(altura) -> float` = y onde o aviso TERMINA (logo acima da barra de abas, da folha
## ou da bandeja presa embaixo, o que estiver mais alto).
var bottom_y: Callable = Callable()

var _host: Control
var _hud: Hud
var _toast: PanelContainer
var _toast_text: Label
var _toast_icon: TextureRect
var _moment: PanelContainer
var _moment_icon: TextureRect
var _moment_text: Label
var _queue: Array[Dictionary] = []
var _current: Dictionary = {}
var _tween: Tween
var _tap: Callable = Callable()
var _art: NinePatchRect
var _slide_off: float = 0.0  # deslocamento de entrada (px abaixo da posição final); o tween leva a 0


func _init() -> void:
	name = "Notice"
	process_priority = 100


## Acompanha a posição final todo quadro: a folha ou a bandeja que sobe/desce leva o aviso junto.
func _process(_delta: float) -> void:
	if _current.is_empty() or not _on_screen():
		return
	_place(_moment if str(_current.kind) == "moment" else _toast)


## A casca entrega o que o aviso precisa: ela mesma, o HUD e os nós do `Toast`.
func setup(host: Control, hud: Hud, toast: PanelContainer, toast_text: Label, toast_icon: TextureRect) -> void:
	_host = host
	_hud = hud
	_toast = toast
	_toast_text = toast_text
	_toast_icon = toast_icon
	_toast.gui_input.connect(_on_toast_input)
	_build_skin()
	_build_moment()
	Events.toast_requested.connect(func(text: String) -> void: notify("info", text))
	Events.notice_requested.connect(func(kind: String, text: String, item: String) -> void:
		notify(kind, text, Database.item_icon(item) if item != "" else null,
			TaskHelp.open.bind("item", item) if kind == "error" and item != "" else Callable()))
	var timer := Timer.new()
	timer.wait_time = 0.1
	timer.autostart = true
	timer.timeout.connect(_pump)
	add_child(timer)


## Pele de madeira ilustrada: pílula creme (NinePatch em escala 1/3, só o miolo liso estica) atrás da linha do texto.
## A folga lateral vem de dois espaçadores na linha (o painel não tem margem, para a arte cobrir tudo).
func _build_skin() -> void:
	_toast.theme_type_variation = &""
	_toast.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_toast.custom_minimum_size.y = MIN_HEIGHT
	_art = NinePatchRect.new()
	_art.name = "PillArt"
	_art.texture = load(HomeUi.DIR + "mission_chapter_pill.png") as Texture2D
	_art.patch_margin_left = 45
	_art.patch_margin_right = 45
	_art.patch_margin_top = 39
	_art.patch_margin_bottom = 39
	_art.scale = Vector2.ONE / 3.0
	_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# O NinePatch mede a soma das margens como mínimo: mora dentro de um Control liso (mínimo 0).
	var holder := Control.new()
	holder.name = "PillHolder"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(_art)
	_toast.add_child(holder)
	_toast.move_child(holder, 0)
	holder.resized.connect(func() -> void: _art.size = holder.size * 3.0)
	var row := _toast_text.get_parent() as HBoxContainer
	for at in 2:
		var gap := Control.new()
		gap.name = "PadLeft" if at == 0 else "PadRight"
		gap.custom_minimum_size.x = PAD - 6.0
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(gap)
		if at == 0:
			row.move_child(gap, 0)
	_toast_text.theme = HomeUi.theme(FONT_PX, Palette.WOOD_INK)
	_toast_text.theme_type_variation = &""
	_toast_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _build_moment() -> void:
	_moment = PanelContainer.new()
	_moment.name = "MomentNotice"
	_moment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moment.visible = false
	_moment.add_theme_stylebox_override("panel", _pill(Palette.WOOD_INSET))
	var row := UiKit.hbox(6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moment_icon = UiKit.icon(null, 28)
	_moment_icon.name = "MomentIcon"
	row.add_child(_moment_icon)
	_moment_text = StepCardUi.wood("", 17)
	_moment_text.name = "MomentText"
	row.add_child(_moment_text)
	_moment.add_child(row)
	_moment.z_index = 12
	_host.add_child(_moment)


func _pill(color: Color) -> StyleBoxFlat:
	var style := UiKit.surface(color, 22)
	style.border_color = Color("c9935f")
	style.set_border_width_all(2)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style


## Põe um aviso na fila. `kind` desconhecido vira "info". `on_tap` só vale para o aviso tocável (foto, erro com item).
func notify(kind: String, text: String, icon: Texture2D = null, on_tap: Callable = Callable()) -> void:
	if kind not in KINDS:
		kind = "info"
	# Sem repetir: o mesmo aviso (tipo + texto) já na fila é descartado; se já está na tela, só renova a espera e dá
	# um pulinho (ex.: colher vários canteiros com o silo cheio avisa uma vez, não uma por canteiro).
	for waiting in _queue:
		if str(waiting.kind) == kind and str(waiting.text) == text:
			return
	if not _current.is_empty() and _on_screen() and str(_current.kind) == kind and str(_current.text) == text:
		_renew_current()
		return
	var entry := {"kind": kind, "text": text, "icon": icon, "tap": on_tap}
	var rank := KINDS.find(kind)
	var at := _queue.size()
	for i in _queue.size():
		if KINDS.find(str(_queue[i].kind)) > rank:
			at = i
			break
	_queue.insert(at, entry)
	# Erro entra na hora no lugar do que estiver na tela.
	if kind == "error" and not _current.is_empty() and str(_current.kind) != "error":
		_replace_current()
	_pump()


func _renew_current() -> void:
	var node: Control = _moment if str(_current.kind) == "moment" else _toast
	_start_hold(node, str(_current.kind), false)
	if str(_current.kind) != "moment" and not Motion.reduced:
		node.pivot_offset = node.size / 2.0
		var pulse := node.create_tween()  # posição é do `_process`: o pulinho é de escala
		pulse.tween_property(node, "scale", Vector2(1.06, 1.06), 0.08)
		pulse.tween_property(node, "scale", Vector2.ONE, 0.12)


## O que está na tela agora, ou "" (para testes).
func showing() -> String:
	return str(_current.get("kind", "")) if not _current.is_empty() and _on_screen() else ""


func queued() -> int:
	return _queue.size()


## Encerra o aviso atual já (a fila anda). Usado pelo teste e quando o aviso some por fora.
func finish_current() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	_toast.hide()
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moment.visible = false
	_current = {}
	_tap = Callable()
	_pump()


func _on_screen() -> bool:
	if _current.is_empty():
		return false
	if str(_current.kind) == "moment":
		return _moment.visible
	return _toast.visible and _toast.modulate.a > 0.0


func _replace_current() -> void:
	var old := _current
	if _tween:
		_tween.kill()
		_tween = null
	_moment.visible = false
	_current = {}
	if str(old.kind) in ["moment", "photo"]:
		_queue.push_front(old)


func _pump() -> void:
	if not _current.is_empty():
		if _on_screen():
			return
		_current = {}
	if _queue.is_empty():
		return
	if blocked.is_valid() and bool(blocked.call()):
		# Cartão aberto: só o erro urgente passa por cima de nada (a regra vale para todos).
		return
	_current = _queue.pop_front()
	if str(_current.kind) == "moment":
		_show_moment()
	else:
		_show_toast()


func _show_toast() -> void:
	var kind := str(_current.kind)
	var text := str(_current.text)
	var icon: Texture2D = _current.icon
	var tap: Callable = _current.tap
	_tap = tap
	var ink := Palette.ALERT_INK if kind == "error" else Palette.WOOD_INK
	# Erro: a mesma pílula com um toque avermelhado; o resto é creme neutro.
	_art.self_modulate = Color(1.0, 0.82, 0.78) if kind == "error" else Color.WHITE
	_toast_text.theme = HomeUi.theme(FONT_PX, ink)
	_toast_icon.visible = true
	if icon != null:
		_toast_icon.texture = icon
		_toast_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_toast_icon.self_modulate = Color.WHITE
	elif kind == "photo":
		_toast_icon.texture = UiKit.ui_icon("album_story")
		_toast_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_toast_icon.self_modulate = Color.WHITE
	elif text.begins_with("Missão concluída"):
		_toast_icon.texture = UiKit.ctl_icon("check")
		_toast_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_toast_icon.self_modulate = Palette.GO_INK
	else:
		_toast_icon.visible = false
	_toast_text.text = text
	# Largura do texto (até 300 com o ícone e a folga); só então a pílula assume o tamanho certo.
	var font := _toast_text.get_theme_font("font")
	var font_size := _toast_text.get_theme_font_size("font_size")
	var limit := MAX_WIDTH - 2.0 * PAD - (38.0 if _toast_icon.visible else 0.0)
	_toast_text.custom_minimum_size.x = minf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 2.0, limit)
	_toast_text.custom_minimum_size.y = 0.0
	_toast.reset_size()
	# Duas linhas pedem mais ar em cima e embaixo; uma linha fica na altura mínima de 44.
	_toast.custom_minimum_size.y = MIN_HEIGHT
	_toast.reset_size()
	if _toast_text.get_line_count() > 1:
		_toast.custom_minimum_size.y = MIN_HEIGHT + 12.0
		_toast.reset_size()
	_toast.pivot_offset = _toast.size / 2.0
	_toast.mouse_filter = Control.MOUSE_FILTER_STOP if _tap.is_valid() else Control.MOUSE_FILTER_IGNORE
	if _tween:
		_tween.kill()
	_toast.show()
	if kind == "error":
		Haptics.error()
	_start_hold(_toast, kind, true)
	_place(_toast)


## Entrada (sobe de baixo com fade), espera e saída; `enter` falso só renova a espera (aviso repetido).
func _start_hold(node: Control, kind: String, enter: bool) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	if enter and not Motion.reduced:
		_slide_off = SLIDE_FROM
		node.modulate.a = 0.0
		_tween.tween_property(self, "_slide_off", 0.0, Motion.SLIDE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.parallel().tween_property(node, "modulate:a", 1.0, Motion.SLIDE)
	else:
		_slide_off = 0.0
		node.modulate.a = 1.0
	_tween.tween_interval(float(HOLD[kind]))
	_tween.tween_property(node, "modulate:a", 0.0, FADE)
	_tween.tween_callback(finish_current)


## Centraliza o aviso e o põe com a base em `bottom_y` (acima da barra de abas/folha/bandeja).
func _place(node: Control) -> void:
	node.position.x = roundf((_host.size.x - node.size.x) / 2.0)
	node.position.y = roundf(_target_y(node.size.y) + _slide_off)


## O HUD, a folha ou a bandeja mudou: o aviso que já está na tela acompanha a nova posição.
func retarget() -> void:
	if _current.is_empty() or not _on_screen():
		return
	_place(_moment if str(_current.kind) == "moment" else _toast)


func _target_y(height: float) -> float:
	var bottom := float(bottom_y.call(height)) if bottom_y.is_valid() else _host.size.y - 100.0
	return bottom - height


func _show_moment() -> void:
	_moment_icon.texture = _current.icon
	_moment_text.text = str(_current.text)
	_moment.visible = true
	_moment.modulate.a = 1.0
	_moment.reset_size()
	_slide_off = 0.0
	_place(_moment)
	Motion.pop_in(_moment)
	Haptics.success()
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_interval(0.0 if Motion.reduced else float(HOLD.moment))
	_tween.tween_callback(func() -> void:
		_fly_moment_icon()
		finish_current())

## O ícone do momento voa até o avatar, que dá um pulinho.
func _fly_moment_icon() -> void:
	if Motion.reduced or not is_instance_valid(_hud):
		return
	var target := _hud.avatar_button.get_global_rect().get_center()
	var token := UiKit.icon(_moment_icon.texture, 28)
	token.name = "FlyingMoment"
	token.mouse_filter = Control.MOUSE_FILTER_IGNORE
	token.z_index = 20
	_host.add_child(token)
	token.global_position = _moment_icon.get_global_rect().position
	var tween := token.create_tween()
	tween.tween_property(token, "global_position", target - token.size / 2.0, Motion.SLIDE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		token.queue_free()
		Motion.bounce(_hud.avatar_button))


func _on_toast_input(event: InputEvent) -> void:
	if not _tap.is_valid() or not (event is InputEventMouseButton and event.pressed):
		return
	var tap := _tap
	_tap = Callable()
	finish_current()
	tap.call()
