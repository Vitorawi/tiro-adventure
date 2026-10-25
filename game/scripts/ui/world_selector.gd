class_name WorldSelector
extends Control
## Folha com cinco cartões-postais. Um toque viaja; fundo, X e Escape fecham.

signal chosen(world_id: String)
signal closed

const GAP := 12
const TOP := 72.0
var _panel: PanelContainer
var _rows: Control
var _buttons: Array[WorldCard] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Palette.SCRIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_background_input)
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.name = "WorldListPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := UiKit.surface(Palette.PAPER, 28, true)
	style.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var body := UiKit.vbox(8)
	_panel.add_child(body)
	var handle := ColorRect.new()
	handle.color = Palette.LINE
	handle.custom_minimum_size = Vector2(40, 5)
	handle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(handle)
	var header := UiKit.hbox(8)
	var title := UiKit.fill_label("Para onde vamos?", &"TitleLabel")
	title.name = "SelectorTitle"
	header.add_child(title)
	var close_button := UiKit.ctl_button("x", dismiss, 32)
	close_button.name = "CloseSelector"
	header.add_child(close_button)
	body.add_child(header)
	_rows = Control.new()
	_rows.name = "WorldList"
	body.add_child(_rows)
	for world_id: String in Database.worlds:
		var row := WorldCard.new()
		row.setup(world_id)
		row.pressed.connect(_choose.bind(world_id))
		_rows.add_child(row)
		_buttons.append(row)
	resized.connect(func() -> void: _layout.call_deferred())
	_layout.call_deferred()


func _layout() -> void:
	if not is_instance_valid(_panel): return
	var bottom := size.y - 88.0
	var tab_bar := get_tree().root.find_child("TabBar", true, false) as Control
	if is_instance_valid(tab_bar) and tab_bar.size.y > 0:
		bottom = minf(size.y, tab_bar.global_position.y - global_position.y - 8)
	var available := maxf(0, bottom - TOP)
	var width := minf(440, size.x)
	var inner := width - 32
	var column_width := (inner - GAP) / 2
	# A altura das dicas reais decide a linha; nenhum nome de missão é truncado.
	var extras: Array[float] = [56.0, 56.0]
	for i: int in 4:
		var card := _buttons[i]
		card.wide = false
		card.size.x = column_width
		card.call("_layout")
		if card.disabled:
			var hint: Control = card.get_node("WorldHint")
			extras[i / 2] = maxf(extras[i / 2], 48 + hint.size.y + 8)
	var photo := clampf(floorf((available - 97 - 24 - 44 - extras[0] - extras[1]) / 3), 28, 104)
	var y := 0.0
	for i: int in _buttons.size():
		var card := _buttons[i]
		card.wide = i == _buttons.size() - 1 and _buttons.size() % 2 == 1
		card.photo_height = photo - 12 if card.wide else photo
		var height := photo + 44 if card.wide else photo + extras[i / 2]
		card.position = Vector2(0 if card.wide else (i % 2) * (column_width + GAP), y)
		card.size = Vector2(inner if card.wide else column_width, height)
		card.call("_layout")
		if i % 2 == 1 or card.wide: y += height + GAP
	var cards_height := y - GAP
	_rows.custom_minimum_size = Vector2(inner, cards_height)
	_panel.size = Vector2(width, 32 + 5 + 8 + 44 + 8 + cards_height)
	_panel.position = Vector2((size.x - width) / 2, maxf(64, bottom - _panel.size.y))


func open(current: String) -> void:
	show()
	refresh(current)
	_layout.call_deferred()


func refresh(current: String) -> void:
	for row: WorldCard in _buttons:
		row.refresh(current)


func dismiss() -> void:
	hide()
	closed.emit()


func _choose(id: String) -> void:
	if Places.world_error(id) == "":
		chosen.emit(id)


func _on_background_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
		dismiss()
		get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		dismiss()
		get_viewport().set_input_as_handled()
