class_name WorldSelector
extends Control
## Cinco destinos juntos, com ícone e avisos. Um toque viaja; fundo ou X fecham.

signal chosen(world_id: String)
signal closed

const GAP := 6
const TOP := 72.0
var _panel: PanelContainer
var _rows: VBoxContainer
var _buttons: Array[WorldCard] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Palette.DIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_background_input)
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.name = "WorldListPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PAPER
	style.border_color = Palette.CARD_LINE
	style.set_border_width_all(2)
	style.set_corner_radius_all(24)
	style.shadow_color = Palette.SHADE
	style.shadow_size = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var body := UiKit.vbox(8)
	_panel.add_child(body)
	var header := UiKit.hbox(8)
	var title := UiKit.fill_label("Para onde vamos?", &"TitleLabel")
	title.name = "SelectorTitle"
	title.add_theme_font_size_override("font_size", 26)
	header.add_child(title)
	var close_button := UiKit.icon_button(UiKit.ctl_icon("x"), dismiss, 44)
	close_button.name = "CloseSelector"
	header.add_child(close_button)
	body.add_child(header)
	_rows = UiKit.vbox(GAP)
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
	var height := WorldCard.ROW_HEIGHT if available >= 460 else WorldCard.COMPACT_HEIGHT
	for row: WorldCard in _buttons:
		row.custom_minimum_size.y = height
	_panel.size = Vector2(minf(440, size.x - 24), 24 + 44 + 8 + _buttons.size() * height + maxi(0, _buttons.size() - 1) * GAP)
	_panel.position = Vector2((size.x - _panel.size.x) * 0.5, TOP + maxf(0, (available - _panel.size.y) * 0.5))


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
