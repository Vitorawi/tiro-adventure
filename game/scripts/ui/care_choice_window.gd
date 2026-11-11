extends PanelContainer
## Janelinha única dos cuidados: moldura, miolo, tiles e janela de rolagem.
const COLUMNS := 3
const TILE := 56.0
const GAP := 8.0
const ROWS := 2
var scroll: ScrollContainer
var grid: GridContainer
var placeholder_height := 0.0
var _more: Button
var _more_icon: TextureRect
signal layout_requested

func _init() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	z_index = 4
	hide()
	set_meta("care_choice_window", true)
	var art := Control.new()
	art.name = "Art"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	var frame := StepCardUi.patch("frame", 42, 42)
	frame.patch_margin_bottom = 72
	frame.name = "Frame"
	frame.scale = Vector2.ONE / 3.0
	art.add_child(frame)
	art.resized.connect(func() -> void: frame.size = art.size.max(Vector2.ONE) * 3.0)
	var body := MarginContainer.new()
	body.name = "Body"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right", "top"]:
		body.add_theme_constant_override("margin_" + side, 20)
	body.add_theme_constant_override("margin_bottom", 28)
	add_child(body)
	scroll = ScrollContainer.new()
	scroll.name = "FoodScroll"
	scroll.set_meta("own_drag_scroll", true)  # o ícone é a pega de arrastar a comida; o gesto é do PetCareTray
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	body.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", int(GAP))
	grid.add_theme_constant_override("v_separation", int(GAP))
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	scroll.add_child(grid)
	scroll.custom_minimum_size.x = COLUMNS * (TILE + GAP) - GAP
	minimum_size_changed.connect(func() -> void: layout_requested.emit())
	# Há mais comidas do que cabem: o toque no ícone é arrasto de comida, então a rolagem tem botão próprio.
	_more = UiKit.ctl_button("down", _scroll_page, 40)
	_more.name = "MoreFoods"
	_more.hide()
	_more.size = Vector2(40, 40)
	art.add_child(_more)
	_more_icon = _more.find_child("Disc", true, false).get_child(0).get_child(0) as TextureRect
	scroll.get_v_scroll_bar().value_changed.connect(func(_v: float) -> void: _sync_more())

## Desce uma linha; no fim volta ao começo.
func _scroll_page() -> void:
	var bar := scroll.get_v_scroll_bar()
	if scroll.scroll_vertical + scroll.size.y >= bar.max_value - 1.0: scroll.scroll_vertical = 0
	else: scroll.scroll_vertical += int(TILE + GAP)

func _sync_more() -> void:
	if _more == null: return
	var bar := scroll.get_v_scroll_bar()
	var overflow := bar.max_value > scroll.size.y + 1.0 and placeholder_height <= 0.0
	_more.visible = overflow
	if overflow:
		_more_icon.pivot_offset = _more_icon.size / 2.0
		_more_icon.rotation = PI if scroll.scroll_vertical + scroll.size.y >= bar.max_value - 1.0 else 0.0
		_more.position = Vector2(size.x - 52.0, size.y - 30.0)

func place(host: Control, top: float, bottom: float, heart_left: float) -> void:
	scroll.custom_minimum_size.y = 0.0
	var chrome := get_combined_minimum_size().y
	var total := ceili(float(grid.get_child_count()) / COLUMNS)
	var fit := maxi(1, floori((bottom - top - chrome + GAP) / (TILE + GAP)))
	var rows := mini(mini(ROWS, maxi(1, total)), fit)
	scroll.custom_minimum_size.y = rows * TILE + (rows - 1) * GAP
	if placeholder_height > 0.0:
		scroll.custom_minimum_size.y = minf(placeholder_height, maxf(0.0, bottom - top - chrome))
	size = get_combined_minimum_size()
	position = Vector2(maxf(minf((host.size.x - size.x) * 0.5, heart_left - size.x), 8.0), bottom - size.y)
	_sync_more.call_deferred()

## Mesmo tile para comida arrastável e opção tocável. O chamador só acrescenta seus selos/regras.
static func tile(texture: Texture2D, quantity: String = "", on_pressed: Callable = Callable()) -> Control:
	var item: Control = BagUi.plain_button(on_pressed) if on_pressed.is_valid() else Control.new()
	item.custom_minimum_size = Vector2(TILE, TILE)
	item.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	item.mouse_filter = Control.MOUSE_FILTER_STOP
	var background := MissionUi.tile(null, "", "FoodDisc", Vector2(TILE, TILE))
	item.add_child(background)
	StepCardUi.stretch(background)
	var icon := UiKit.icon(texture, 40)
	icon.name = "CareIcon"
	icon.position = Vector2(8, 6)
	icon.size = Vector2(40, 40)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(icon)
	var count := MissionUi.text(quantity, 14, Palette.WOOD_CREAM, 4, HORIZONTAL_ALIGNMENT_RIGHT)
	count.name = "Quantity"
	item.add_child(count)
	StepCardUi.stretch(count)
	count.offset_right = -4.0
	count.offset_bottom = -2.0
	count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	return item
