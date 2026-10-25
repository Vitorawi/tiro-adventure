class_name RewardSheet
extends Control
## Folha média de prêmio (Interface 2): sobe de baixo, alça para arrastar e fechar, fita-pílula,
## fala opcional (retrato + balão), chips grandes, um bloco livre (`body`) e os botões
## (`soft` + `primary`). Base de QuestReward (passo da história), WelcomeBack, WalkResult comum
## e "Novo!". Quem usa é um CanvasLayer: `RewardSheet.open(self, {...})` troca a folha anterior e
## devolve esta; o fundo, a alça, o X e Escape fecham pelo `on_close` (padrão: esconder o host).
##
## Opções de `open`: title, ribbon (Color, padrão GO), ribbon_icon (nome ctl, "check"; "" sem ícone),
## hero (Control logo abaixo do cabeçalho), speech ({npc, text}), close_button (true), on_close (Callable),
## scroll_name, animate (true; false = folha reaberta sem repetir a entrada), haptic ("success").

const REVEAL_START := 0.28
const REVEAL_GAP := 0.08

var host: Node
var panel: PanelContainer
var scroll: ScrollContainer
var body: VBoxContainer
var dim: ColorRect
var handle: Control
var header: HBoxContainer
var _on_close := Callable()
var _animate := true
var _rest_y := 0.0
var _tween: Tween
var _drag_y := 0.0
var _last_y := 0.0
var _last_ms := 0
var _velocity := 0.0
var _dragging := false


static func open(host_node: Node, options: Dictionary) -> RewardSheet:
	for child: Node in host_node.get_children():
		host_node.remove_child(child)
		child.queue_free()
	var sheet := RewardSheet.new()
	sheet.name = "RewardSheet"
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host_node.add_child(sheet)
	sheet._build(host_node, options)
	return sheet


func _build(host_node: Node, options: Dictionary) -> void:
	host = host_node
	_on_close = options.get("on_close", Callable()) as Callable
	_animate = bool(options.get("animate", true))
	dim = ColorRect.new()
	dim.name = "Dim"
	dim.color = Palette.SCRIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			close())
	panel = PanelContainer.new()
	panel.name = "RewardPanel"
	panel.theme = load("res://assets/theme/main_theme.tres")
	var style := UiKit.surface(Palette.PAPER, 28, true)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	scroll = ScrollContainer.new()
	scroll.name = str(options.get("scroll_name", "RewardScroll"))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	body = UiKit.vbox(12)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	handle = Control.new()
	handle.name = "RewardHandle"
	handle.custom_minimum_size.y = 12
	handle.draw.connect(func() -> void:
		handle.draw_style_box(UiKit.surface(Palette.LINE, 3), Rect2((handle.size.x - 40) / 2, 0, 40, 5)))
	handle.resized.connect(handle.queue_redraw)
	handle.gui_input.connect(_drag_input)
	body.add_child(handle)
	header = UiKit.hbox(8)
	header.gui_input.connect(_drag_input)
	header.add_child(_ribbon(str(options.get("title", "")), options.get("ribbon", Palette.GO) as Color, str(options.get("ribbon_icon", "check"))))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(spacer)
	if bool(options.get("close_button", true)):
		var x := UiKit.ctl_button("x", close, 32, "sunken")
		x.name = "RewardClose"
		header.add_child(x)
	body.add_child(header)
	if options.get("hero") is Control:
		var hero := options.hero as Control
		hero.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		body.add_child(hero)
	var speech: Dictionary = options.get("speech", {})
	if not speech.is_empty():
		body.add_child(_speech(str(speech.get("npc", "lais")), str(speech.get("text", ""))))
	full_resized_connect()
	match str(options.get("haptic", "success")):
		"success":
			Haptics.success()
		"big":
			Haptics.big()


func full_resized_connect() -> void:
	resized.connect(layout)
	minimum_size_changed.connect(layout)
	body.minimum_size_changed.connect(layout)


## Pílula colorida com ícone opcional e título branco (verde = concluído, mel = prêmio, azul = descoberta).
func _ribbon(title: String, color: Color, icon_name: String) -> Control:
	var ribbon := PanelContainer.new()
	ribbon.name = "RewardRibbon"
	var style := UiKit.surface(color, 18)
	style.set_content_margin_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	ribbon.add_theme_stylebox_override("panel", style)
	var row := UiKit.hbox(4)
	if icon_name != "":
		row.add_child(UiKit.ctl(icon_name, 20, Palette.CARD))
	var label := UiKit.short_label(title, &"StrongLabel", Palette.CARD)
	label.name = "RibbonTitle"
	row.add_child(label)
	ribbon.add_child(row)
	return ribbon


func _speech(npc: String, text: String) -> Control:
	var speech := UiKit.hbox(8)
	speech.name = "RewardSpeech"
	speech.add_child(UiKit.disc(ProgressionUi.npc_portrait(npc), 56, 56))
	var bubble := SpeechBubble.new(text)
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speech.add_child(bubble)
	return speech


## Adiciona ao corpo e devolve o próprio controle.
func add(control: Control) -> Control:
	body.add_child(control)
	return control


func add_text(text: String, variation: StringName = &"", color: Variant = null) -> Label:
	var label := UiKit.label(text, variation, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(label)
	return label


## Chips grandes centralizados; entram um por um e os números contam.
func add_chips(chips: Container) -> Container:
	if chips.get_child_count() == 0:
		chips.queue_free()
		return chips
	if chips is FlowContainer:
		(chips as FlowContainer).alignment = FlowContainer.ALIGNMENT_CENTER
	for chip: Node in chips.get_children():
		grow_chip(chip as Control)
	body.add_child(chips)
	if _animate:
		reveal_in(chips)
	return chips


## Linha de botões: `soft` (opcional, "Depois") à esquerda e `primary` (um só) ocupando o resto.
func add_actions(soft_text: String, soft_call: Callable, primary_text: String, primary_call: Callable) -> Dictionary:
	var actions := UiKit.hbox(8)
	var soft: Button = null
	if soft_text != "":
		soft = UiKit.soft(soft_text, soft_call)
		actions.add_child(soft)
	var primary: Button = null
	if primary_text != "":
		primary = UiKit.primary(primary_text, primary_call)
		primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(primary)
	elif soft:
		soft.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(actions)
	return {"soft": soft, "primary": primary}


## Mostra a folha (entra subindo de baixo, salvo Menos animação ou `animate` falso).
func present() -> void:
	scroll.scroll_vertical = 0
	layout.call_deferred()
	if not Motion.reduced and _animate:
		_animate_open.call_deferred()


func close() -> void:
	if _tween:
		_tween.kill()
	_dragging = false
	if _on_close.is_valid():
		_on_close.call()
	elif is_instance_valid(host) and host is CanvasLayer:
		(host as CanvasLayer).hide()


func layout() -> void:
	if not is_instance_valid(panel) or not is_inside_tree():
		return
	var area := get_viewport().get_visible_rect().size
	panel.size.x = area.x - 16
	body.custom_minimum_size.x = area.x - 48
	var height := minf(body.get_combined_minimum_size().y + 32, area.y - 32)
	panel.size.y = height
	_rest_y = area.y - height - 8
	if not _dragging and (_tween == null or not _tween.is_running()):
		panel.position = Vector2(8, _rest_y)


func _animate_open() -> void:
	if not is_instance_valid(panel) or not is_inside_tree():
		return
	layout()
	if _tween:
		_tween.kill()
	panel.position = Vector2(8, get_viewport().get_visible_rect().size.y)
	_tween = create_tween()
	_tween.tween_property(panel, "position:y", _rest_y, Motion.SHEET_IN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		close()


func _drag_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_y = event.global_position.y
			_last_y = _drag_y
			_last_ms = Time.get_ticks_msec()
			_velocity = 0
		elif _dragging:
			_dragging = false
			var distance: float = event.global_position.y - _drag_y
			if distance > 8 and (distance > panel.size.y * 0.25 or (Time.get_ticks_msec() - _last_ms < 120 and _velocity > 900)):
				close()
			else:
				panel.position.y = _rest_y
	elif event is InputEventMouseMotion and _dragging:
		var now := Time.get_ticks_msec()
		if now > _last_ms:
			_velocity = (event.global_position.y - _last_y) * 1000 / (now - _last_ms)
		_last_ms = now
		_last_y = event.global_position.y
		panel.position.y = _rest_y + maxf(0, _last_y - _drag_y)


## Chip de prêmio grande: altura 44, ícone 36 (a estrutura é a do `UiKit.chip`: HBox com ícone e rótulo).
static func grow_chip(chip: Control) -> void:
	if chip == null or chip.get_child_count() == 0:
		return
	chip.custom_minimum_size.y = 44
	var row := chip.get_child(0) as HBoxContainer
	if row == null:
		return
	for child: Node in row.get_children():
		if child is TextureRect and (child as TextureRect).custom_minimum_size.x >= 24:
			(child as TextureRect).custom_minimum_size = Vector2(36, 36)
		elif child is Label and (child as Label).theme_type_variation == &"ChipLabel":
			(child as Label).theme_type_variation = &"NumberLabel"


## Chip de prêmio "+N" para a folha (moedas, item); o número conta quando `add_chips` o revela.
static func prize_chip(chip_name: String, texture: Texture2D, amount: int, keepsake: bool = false) -> Control:
	var chip := UiKit.chip(texture, "+%d" % amount, null, "prize")
	chip.name = chip_name
	grow_chip(chip)
	if keepsake:
		(chip.get_child(0) as HBoxContainer).add_child(UiKit.spark())
	return chip


## Os filhos de `container` entram um por um (pop_in, 80 ms entre eles); "+N" e "×N" contam de 0.
## Com Motion.reduced ficam visíveis e com o número final na hora.
static func reveal_in(container: Container) -> void:
	if Motion.reduced:
		return
	var index := 0
	for child: Node in container.get_children():
		var item := child as Control
		if item == null:
			continue
		item.modulate.a = 0.0
		var tween := item.create_tween()
		tween.tween_interval(REVEAL_START + index * REVEAL_GAP)
		tween.tween_callback(_show_item.bind(item))
		index += 1


static func _show_item(item: Control) -> void:
	if not is_instance_valid(item) or not item.is_inside_tree():
		return
	Motion.pop_in(item)
	for label: Node in item.find_children("*", "Label", true, false):
		var text := (label as Label).text
		for prefix: String in ["+", "×"]:
			if text.begins_with(prefix) and text.substr(prefix.length()).is_valid_int():
				Motion.count_up(label as Label, 0, text.substr(prefix.length()).to_int(), prefix + "%d")
