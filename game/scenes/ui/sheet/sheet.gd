extends Control
## Painel inferior (bottom sheet) para menus de objetos: geladeira, fogão...
## Aberto via Events.sheet_requested(title, content); fecha ao tocar fora, no "X",
## arrastando a alça/título para baixo ou via Events.sheet_close_requested.
##
## Altura: o conteúdo pode pedir `content.set_meta("sheet_size", "half" | "tall")`;
## sem meta = automático (altura do conteúdo se couber em 55% da tela, senão a altura até o HUD, com rolagem).
## O painel fica preso embaixo e a altura muda por `offset_top`.

const HALF := 0.55  # fração da altura útil: "half" e limite do automático
const BOTTOM_GAP := 16.0  # folga fixa no fim da rolagem: a última linha nunca encosta na borda
const MIN := 0.30  # altura mínima do automático
const RESIZE_MIN := 24.0  # só acompanha mudança de conteúdo se passar disso (não "respira")
const DRAG_STRIP := 28.0  # faixa do topo do painel que também arrasta
const CLOSE_FRACTION := 0.25  # arrastou mais que isso da altura: fecha
const FLICK := 900.0  # px/s: puxão rápido fecha (para cima, vira alto)

@onready var _dim: ColorRect = %Dim
@onready var _panel: PanelContainer = %Panel
@onready var _handle: Control = %Handle
@onready var _title: Label = %Title
@onready var _content_holder: VBoxContainer = %ContentHolder

var _fitted := false  # a altura já foi medida depois de abrir
var _open := false  # há conteúdo aberto (falso já ao pedir o fechamento, mesmo deslizando)
var _closing := false  # deslizando para fora
var _height := 0.0  # altura alvo do painel, em px
var _size_meta := "auto"
var _fit_content := false
var _header_actions: Array[Control] = []
var _pulled_tall := false  # o jogador puxou para cima: fica alto até trocar de conteúdo
var _open_id := 0
var _fit_pending := false
var _slide_tween: Tween
var _fade_tween: Tween
var _dragging := false
var _drag_y0 := 0.0
var _drag_top0 := 0.0
var _last_y := 0.0
var _last_msec := 0
var _velocity := 0.0
var _close_button: Button
var _wood := false  # folha em madeira ilustrada (opt-in do conteúdo: meta `sheet_wood`)
var _wood_art: Node2D


func _ready() -> void:
	hide()
	_dim.color = Palette.SCRIM
	_dim.gui_input.connect(_on_dim_input)
	# Botão redondo com o ícone "✕" próprio (a fonte pixel art não tem o glifo).
	_make_close_button()
	_handle.draw.connect(_draw_handle)
	_handle.gui_input.connect(_drag_input)
	_title.gui_input.connect(_drag_input)
	_panel.gui_input.connect(_panel_input)
	_content_holder.minimum_size_changed.connect(_queue_fit)
	resized.connect(_queue_fit)
	Events.sheet_requested.connect(open)
	Events.sheet_close_requested.connect(close)


## Painel aberto (já falso quando pediram para fechar, mesmo que ainda esteja deslizando).
func is_open() -> bool:
	return _open


## Altura alvo atual do painel, em pixels.
func panel_height() -> float:
	return _height


func open(title: String, content: Control) -> void:
	_stop_tweens()
	_closing = false
	_pulled_tall = false
	_open_id += 1
	for child in _content_holder.get_children():
		_content_holder.remove_child(child)
		child.queue_free()
	_clear_actions()
	_set_wood(bool(content.get_meta("sheet_wood", false)))
	_title.text = title
	_fit_content = bool(content.get_meta("sheet_fit_content", false))
	if content.has_meta("sheet_actions"):
		var factory: Callable = content.get_meta("sheet_actions")
		for action: Control in factory.call():
			%Header.add_child(action)
			%Header.move_child(action, _close_button.get_index())
			_header_actions.append(action)
	_size_meta = str(content.get_meta("sheet_size", "auto"))
	_content_holder.add_child(content)
	var gap := Control.new()
	gap.name = "SheetBottom"
	gap.custom_minimum_size.y = BOTTOM_GAP
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_holder.add_child(gap)
	var scroll := _content_holder.get_parent() as ScrollContainer
	if scroll:
		scroll.set_deferred("scroll_vertical", 0)
	var was_open := _open and _fitted
	_open = true
	_fitted = false if not was_open else _fitted
	show()
	if was_open:
		# Conteúdo novo com o painel aberto: a altura acompanha e o conteúdo entra com fade.
		Motion.fade_in(content)
		_queue_fit()
		return
	_panel.modulate.a = 0.0  # escondido até medir o conteúdo (sem pulo de altura no primeiro quadro)
	_dim.modulate.a = 0.0
	_slide_in(_open_id)


## Painel sobe de baixo e o fundo escurece.
func _slide_in(open_id: int) -> void:
	# Duas esperas: o texto com quebra de linha só tem a altura certa depois da largura final.
	await get_tree().process_frame
	await get_tree().process_frame
	if open_id != _open_id or not _open:
		return
	_height = _target_height()
	_fitted = true
	_place(_height)
	_panel.modulate.a = 1.0
	if Motion.reduced:
		_dim.modulate.a = 1.0
		return
	_slide_tween = Motion.slide_up(_panel, _height)
	var fade := create_tween()
	fade.tween_property(_dim, "modulate:a", 1.0, Motion.SLIDE)
	_fade_tween = fade


## Fecha na hora (conteúdo some e testes veem `is_open()` falso) e desliza só o fundo para fora.
func close() -> void:
	if not _open and not visible:
		return
	_open = false
	_clear_actions()
	_open_id += 1
	_dragging = false
	for child in _content_holder.get_children():
		_content_holder.remove_child(child)
		child.queue_free()
	Events.sheet_closed.emit()
	if _closing:
		return
	if Motion.reduced or not visible or not is_inside_tree():
		_finish_close()
		return
	_dismiss(_panel.position.y)


## Anima o painel para baixo da tela a partir da posição atual e então esconde tudo.
func _dismiss(from_y: float) -> void:
	_closing = true
	_stop_tweens()
	var tween := create_tween().set_parallel()
	tween.tween_property(_panel, "position:y", size.y, Motion.SHEET_OUT).from(from_y).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_dim, "modulate:a", 0.0, Motion.SHEET_OUT)
	tween.chain().tween_callback(_finish_close)
	_slide_tween = tween


func _clear_actions() -> void:
	for action: Control in _header_actions:
		if is_instance_valid(action):
			action.get_parent().remove_child(action)
			action.queue_free()
	_header_actions.clear()


func _finish_close() -> void:
	_clear_actions()
	_closing = false
	_stop_tweens()
	hide()


func _stop_tweens() -> void:
	for tween: Tween in [_slide_tween, _fade_tween]:
		if tween and tween.is_valid():
			tween.kill()
	_slide_tween = null
	_fade_tween = null


# --- Altura ---------------------------------------------------------------------------

## Altura máxima: o topo da folha nunca sobe acima de `Hud.SHEET_TOP`, para o aviso e a linha 2 ficarem livres.
func _tall_height() -> float:
	return size.y - float((load("res://scripts/ui/hud.gd") as GDScript).get_script_constant_map()["SHEET_TOP"])


## Altura útil do painel (px) para o conteúdo atual: meia, alta ou a do conteúdo.
func _target_height() -> float:
	var usable := size.y
	var tall := _tall_height()
	if _size_meta == "tall" or _pulled_tall:
		return tall
	if _size_meta == "half":
		return usable * HALF
	var scroll := _content_holder.get_parent() as Control
	var chrome := _panel.get_combined_minimum_size().y - scroll.get_combined_minimum_size().y
	var needed := chrome + _content_holder.get_combined_minimum_size().y
	if _fit_content:
		return clampf(needed, usable * MIN, tall)
	if needed <= usable * HALF:
		return maxf(needed, usable * MIN)
	return tall


## Encosta o painel embaixo com a altura `height` (sem animar).
func _place(height: float) -> void:
	_panel.offset_top = -height
	_panel.offset_bottom = 0.0


## Conteúdo ou tela mudou de tamanho: mede de novo depois do layout.
func _queue_fit() -> void:
	if _fit_pending or not visible or not _open or _closing or not _fitted:
		return
	_fit_pending = true
	await get_tree().process_frame
	_fit_pending = false
	if not _open or _closing or _dragging:
		return
	var target := _target_height()
	var scroll := _content_holder.get_parent() as Control
	var overflowing := _content_holder.get_combined_minimum_size().y > scroll.size.y + 1.0
	if absf(target - _height) <= RESIZE_MIN and (target <= _height or not overflowing):
		return  # evita oscilações, mas nunca ignora crescimento que deixa a fala/botão cortados
	_height = target
	_animate_top(-target)


## Leva o `offset_top` ao valor dado (e o `offset_bottom` a 0) com tween curto.
func _animate_top(top: float, back: bool = false) -> void:
	_stop_tweens()
	if Motion.reduced:
		_panel.offset_top = top
		_panel.offset_bottom = 0.0
		_dim.modulate.a = 1.0
		return
	var tween := create_tween().set_parallel()
	var move := tween.tween_property(_panel, "offset_top", top, Motion.RESIZE)
	var settle := tween.tween_property(_panel, "offset_bottom", 0.0, Motion.RESIZE)
	tween.tween_property(_dim, "modulate:a", 1.0, Motion.RESIZE)
	for step: PropertyTweener in [move, settle]:
		if back:
			step.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			step.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_slide_tween = tween


# --- Arrastar para fechar -------------------------------------------------------------

func _draw_handle() -> void:
	_handle.draw_style_box(UiKit.surface(Color(Palette.WOOD_INK, 0.3) if _wood else Palette.LINE, 3), Rect2((_handle.size.x - 40.0) / 2.0, 0.0, 40.0, 5.0))


## O próprio painel só arrasta pela faixa do topo; o resto pertence à rolagem do conteúdo.
func _panel_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouse
	if mouse and (_dragging or mouse.position.y < DRAG_STRIP):
		_drag_input(event)


func _drag_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_drag_begin(button.global_position.y)
		elif _dragging:
			_drag_end(button.global_position.y)
		return
	var motion := event as InputEventMouseMotion
	if motion and _dragging:
		_drag_move(motion.global_position.y)


func _drag_begin(y: float) -> void:
	if not _open or _closing:
		return
	_stop_tweens()
	_dragging = true
	_drag_y0 = y
	_drag_top0 = _panel.offset_top
	_last_y = y
	_last_msec = Time.get_ticks_msec()
	_velocity = 0.0


func _drag_move(y: float) -> void:
	var now := Time.get_ticks_msec()
	if now > _last_msec:
		_velocity = lerpf(_velocity, (y - _last_y) / ((now - _last_msec) / 1000.0), 0.5)
		_last_msec = now
	_last_y = y
	var delta := y - _drag_y0
	if delta >= 0.0:
		# Para baixo: o painel inteiro acompanha o dedo e o fundo clareia.
		_panel.offset_top = _drag_top0 + delta
		_panel.offset_bottom = delta
		_dim.modulate.a = clampf(1.0 - delta / maxf(_height, 1.0), 0.0, 1.0)
	else:
		# Para cima: o painel cresce até a altura alta.
		_panel.offset_bottom = 0.0
		_panel.offset_top = maxf(_drag_top0 + delta, -_tall_height())
		_dim.modulate.a = 1.0


func _drag_end(y: float) -> void:
	_dragging = false
	var delta := y - _drag_y0
	# Dedo parado antes de soltar não é puxão.
	var speed := _velocity if Time.get_ticks_msec() - _last_msec < 120 else 0.0
	if delta > 8.0 and (delta > _height * CLOSE_FRACTION or speed > FLICK):
		_open = false
		_open_id += 1
		for child in _content_holder.get_children():
			_content_holder.remove_child(child)
			child.queue_free()
		if Motion.reduced:
			_finish_close()
		else:
			_dismiss(_panel.position.y)
		return
	if delta < -8.0 and (delta < -_height * 0.1 or speed < -FLICK) and _height < _tall_height() - 1.0:
		_pulled_tall = true
		_height = _target_height()
		_animate_top(-_height, true)
		return
	_animate_top(-_height, true)  # volta ao lugar


func _on_dim_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.pressed:
		close()


# --- Madeira ilustrada (opt-in) -------------------------------------------------------

const WOOD_SIDE := 6.0  # a moldura passa da borda da tela dos lados e embaixo (some fora), sobra só a madeira de cima
const WOOD_BOTTOM := 64.0
const WOOD_MARGIN := Vector4(24.0, 18.0, 24.0, 14.0)  # espaço do conteúdo: esq, cima, dir, baixo
const WOOD_BORDER := 14.0  # canto do NinePatch, em pixels finais


## Botão de fechar: o redondo liso de sempre ou o X de madeira (`mission_close.png`, alvo 44). Mantém o nome `CloseButton`.
func _make_close_button() -> void:
	var old := _close_button
	var index := -1
	if old != null:
		index = old.get_index()
		%Header.remove_child(old)
		old.free()
	if _wood:
		_close_button = BagUi.plain_button(close)
		_close_button.custom_minimum_size = Vector2(44, 44)
		var art := TextureRect.new()
		art.texture = MissionUi.tex("close")
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_SCALE
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_close_button.add_child(art)
		art.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		art.offset_left = -20.0
		art.offset_right = 20.0
		art.offset_top = -20.0
		art.offset_bottom = 20.0
		_close_button.pressed.connect(func() -> void: Motion.bounce(art))
	else:
		_close_button = UiKit.ctl_button("x", close, 32, "sunken")
	_close_button.name = "CloseButton"
	%Header.add_child(_close_button)
	if index >= 0:
		%Header.move_child(_close_button, index)


## Liga/desliga a madeira: moldura de madeira com papel creme (NinePatch 1/3 desenhado por um Node2D que o
## PanelContainer não organiza), título marrom na fonte da madeira e X de madeira. Folhas comuns ficam como estavam.
func _set_wood(on: bool) -> void:
	if on == _wood:
		return
	_wood = on
	if on:
		var margins := StyleBoxEmpty.new()
		margins.content_margin_left = WOOD_MARGIN.x
		margins.content_margin_top = WOOD_MARGIN.y
		margins.content_margin_right = WOOD_MARGIN.z
		margins.content_margin_bottom = WOOD_MARGIN.w
		_panel.add_theme_stylebox_override("panel", margins)
		_wood_art = Node2D.new()
		_wood_art.name = "WoodArt"
		_wood_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var frame := NinePatchRect.new()
		frame.name = "Frame"
		frame.texture = StepCardUi.tex("frame")
		frame.patch_margin_left = roundi(WOOD_BORDER * 3.0)
		frame.patch_margin_right = roundi(WOOD_BORDER * 3.0)
		frame.patch_margin_top = roundi(WOOD_BORDER * 3.0)
		frame.patch_margin_bottom = roundi(WOOD_BORDER * 3.0)
		frame.scale = Vector2.ONE / 3.0
		_wood_art.add_child(frame)
		_panel.add_child(_wood_art)
		_panel.move_child(_wood_art, 0)
		_panel.resized.connect(_fit_wood)
		_fit_wood()
		_title.theme_type_variation = &""
		_title.theme = HomeUi.theme(26, Palette.WOOD_INK)
	else:
		_panel.remove_theme_stylebox_override("panel")
		if _panel.resized.is_connected(_fit_wood):
			_panel.resized.disconnect(_fit_wood)
		if is_instance_valid(_wood_art):
			_panel.remove_child(_wood_art)
			_wood_art.free()
		_wood_art = null
		_title.theme = null
		_title.theme_type_variation = &"TitleLabel"
	_make_close_button()
	_handle.queue_redraw()


func _fit_wood() -> void:
	if not is_instance_valid(_wood_art):
		return
	var frame := _wood_art.get_child(0) as NinePatchRect
	_wood_art.position = Vector2(-WOOD_SIDE, 0.0)
	frame.size = Vector2(_panel.size.x + WOOD_SIDE * 2.0, _panel.size.y + WOOD_BOTTOM) * 3.0
