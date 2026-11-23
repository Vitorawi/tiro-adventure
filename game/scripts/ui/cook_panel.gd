class_name CookPanel
extends Control
## Cozinha nova (fogão), igual ao Figma "FogaoAutDetalhe": alternador Pratos/Inventar, fila de 4 espaços, faixa de
## categorias, filtros, lista de pratos em 2 colunas com barra própria e o detalhe do prato (ingredientes + "Colocar na fila").
## Nenhuma regra nova: usa a fila e as receitas de sempre (`GameState.cook_many`, `collect`, `content_error`...).
##
## O painel inteiro é um Control em UNIDADES DO FIGMA com `scale = s` (s = largura da tela / 710); o quadro começa em
## x = 10·s. As imagens `ck_*.png` (tools/cook_layout_art.py) têm o tamanho do retângulo do Figma × 1,5 e são desenhadas
## nesse retângulo. A altura é variável: tudo com y ≥ 804,67 desce `E` unidades; a faixa do meio (um período do tracejado)
## é LADRILHADA, nunca esticada. Cada tipo de cartão (prato, espaço, categoria, ingrediente) tem UMA função que o monta;
## escolhido × não escolhido só troca a textura do fundo. Os textos usam a fonte da madeira.
##
## Aba Inventar (alternador): `CookInvent` + `CookInventPicker` (ver doc deles); `invent_mode` guarda a aba na sessão.
##
## Nós para teste: `CookPanel`, `CookToggle`, `Slot_<i>` (meta `state`), `CatScroll`, `Cat_<id>` (meta `selected`),
## `CatArrow`, `Filter_can|missing|tiro` (meta `selected`), `DishList`, `Dish_<receita>` (meta `selected`),
## `DishScrollBar`, `DetailEmpty`, `DetailName`, `DetailTime`, `Ingredient_<item>` (meta `ok`), `QueueButton`, `TogetherButton`.

const DIR := "res://assets/sprites/ui/cook_ui/"
const ART_SCALE := 1.5  # os PNGs são o retângulo do Figma × 1,5
const FIG_W := 710.0
const FRAME_W := 691.33
const TOP_Y := 132.67
const MID_Y := 790.0
const BASE_Y := 804.67
const FULL_H := 944.0  # 1076,7 − 132,7: altura do quadro com E = 0
const SLOT_X: Array[float] = [135.5, 275.5, 415.5, 555.5]
const SLOT_BASE := 355.0
const CAT_VIEW := Rect2(32, 388, 573, 81)
const CAT_STEP := 145.0
const CAT_SIZE := Vector2(145.33, 80.0)
const LIST_POS := Vector2(41, 530)
const LIST_W := 323.0
const LIST_H := 492.0
const DISH_SIZE := Vector2(160, 164)
const DISH_COL_X := 163.0
const BAR_POS := Vector2(365.33, 539.67)
const BAR_SIZE := Vector2(32.67, 481.33)
const BAR_ARROW := 34.0
const DETAIL_POS := Vector2(420, 485)
const DETAIL_SIZE := Vector2(237, 550)
const ING_X: Array[float] = [421.0, 498.0, 574.0]
const ING_Y := 731.0
const INK := Palette.WOOD_INK
const GOLD := Color(1.0, 0.86, 0.45)
const ORANGE := Color8(247, 166, 32)
const RING_TRACK := Color8(224, 196, 160)
const TICK := 0.25
const MIN_TAP := 44.0

static var _current: CookPanel
## Aba escolhida no alternador (vale na sessão): false = Pratos, true = Inventar.
static var invent_mode := false

var room: RoomView
var station_id := "stove"
var selected := ""
var filter := ""
var category := "all"
var closing := false

var _host: Control
var _focus := ""
var _s := 1.0
var _e := 0.0
var _layout_key := ""
var _tick := 0.0
var _pop_slot := -1
var _blocked_main: Node
var _catcher: Control
var _backdrop: Control
var _mid: Control
var _bottom: TextureRect
var _top: TextureRect
var _tile: TextureRect
var _toggle_art: TextureRect
var _arrow: Control
var _invent: CookInvent
var _slots: Control
var _cats: CookScroll
var _list: CookScroll
var _close: Button
var _bar: Control
var _thumb: Control
var _track: Control
var _detail: Control
var _dish_nodes: Dictionary = {}
var _cat_nodes: Dictionary = {}
var _filter_nodes: Dictionary = {}
var _list_key := ""
var _slot_key := ""
var _detail_key := ""
var _thumb_drag := false


# --- Abrir / fechar ---------------------------------------------------------------------

## Abre a cozinha do fogão (troca o que estiver aberto). `focus` = receita pedida pelo "Ir" (já escolhida).
static func open(for_room: RoomView, id: String = "stove", focus: String = "") -> CookPanel:
	if is_instance_valid(_current):
		_current.close(true)
	var panel := CookPanel.new()
	panel.name = "CookPanel"
	panel.room = for_room
	panel.station_id = id
	_current = panel
	panel._build(focus)
	return panel


static func current() -> CookPanel:
	return _current if is_instance_valid(_current) and not _current.closing else null


static func is_open_for(for_room: RoomView) -> bool:
	var panel := current()
	return panel != null and panel.room == for_room


static func close_current(immediate: bool = false) -> void:
	var panel := current()
	if panel != null:
		panel.close(immediate)


func close(immediate: bool = false) -> void:
	if closing:
		return
	closing = true

	if _current == self:
		_current = null
	if Events.state_changed.is_connected(_on_state_changed):
		Events.state_changed.disconnect(_on_state_changed)
	if Events.sheet_requested.is_connected(_on_sheet):
		Events.sheet_requested.disconnect(_on_sheet)
	if is_instance_valid(_host) and _host.resized.is_connected(_apply_layout):
		_host.resized.disconnect(_apply_layout)
	if is_instance_valid(_blocked_main):
		_blocked_main.call("set_row2_blocker", "cook_panel", false)
	if is_instance_valid(_catcher):
		_catcher.queue_free()
	if immediate or Motion.reduced or not is_inside_tree():
		queue_free()
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "modulate:a", 0.0, Motion.POP_OUT)
	tween.chain().tween_callback(queue_free)


func _exit_tree() -> void:
	if _current == self:
		_current = null
	if is_instance_valid(_catcher):
		_catcher.queue_free()


func _on_sheet(_title: String, _content: Control) -> void:
	close(true)


# --- Montagem ---------------------------------------------------------------------------

func _build(focus: String) -> void:
	_host = room.get_tree().root.find_child("WorldsScreen", true, false) as Control
	if _host == null:
		_host = room.get_parent() as Control
	_focus = focus
	if focus != "" and Database.recipes.has(focus) and str(Database.recipes[focus].get("station", "")) == station_id:
		selected = focus
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	z_index = 4
	z_as_relative = false
	# Toque fora do painel só o fecha (o toque é engolido: o mapa não reage).
	_catcher = Control.new()
	_catcher.name = "CookCatcher"
	_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	_catcher.z_index = 4
	_catcher.z_as_relative = false
	_catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_catcher.gui_input.connect(_on_catcher_input)
	_host.add_child(_catcher)
	_host.add_child(self)
	_build_frame()
	_build_toggle()
	_slots = _plain("Slots", Vector2.ZERO, Vector2(FRAME_W, 400))
	add_child(_slots)
	_build_categories()
	_build_filters()
	_build_list()
	_build_bar()
	_detail = _plain("Detail", Vector2.ZERO, Vector2(FIG_W, 1200))
	add_child(_detail)
	_invent = CookInvent.new()
	add_child(_invent)
	_build_close()
	_apply_layout()
	var book_focus := focus.trim_prefix("together:")
	if book_focus.begins_with("recipe:"):
		selected = book_focus.trim_prefix("recipe:")
	elif book_focus.begins_with("dish:"):
		selected = "k_%s_%s" % [book_focus.get_slice(":", 1), book_focus.get_slice(":", 2)]
	_set_mode((focus == "invent" or invent_mode) and GameState.invent_open())
	if focus.begins_with("together:") and selected != "":
		_set_mode(false)
		_together_selected.call_deferred()
	_host.resized.connect(_apply_layout)
	Events.state_changed.connect(_on_state_changed)
	Events.sheet_requested.connect(_on_sheet)
	_refresh_all()
	_blocked_main = _find_main()
	if _blocked_main != null:
		_blocked_main.call("set_row2_blocker", "cook_panel", true)  # a linha 2 do HUD dá lugar ao painel
	if selected != "":
		_scroll_to_selected.call_deferred()
	if not Motion.reduced:
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.14)


func _find_main() -> Node:
	var node: Node = room
	while node:
		if node.has_method("set_row2_blocker"):
			return node
		node = node.get_parent()
	return null


func _on_catcher_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT and not button.pressed:
		var pill := _host.find_child("MapButton", true, false) as Button
		var point := _catcher.get_global_transform() * button.position
		close()
		if pill != null and pill.is_visible_in_tree() and pill.get_global_rect().has_point(point):
			pill.pressed.emit()  # a pílula do mundo continua valendo: fecha o painel e abre o seletor
	_catcher.accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and key.keycode == KEY_ESCAPE:
		if _invent != null and _invent.picker_open():
			_invent.close_picker()
			get_viewport().set_input_as_handled()
			return
		close()
		get_viewport().set_input_as_handled()


func _plain(node_name: String, pos: Vector2, new_size: Vector2) -> Control:
	var node := Control.new()
	node.name = node_name
	node.position = pos
	node.size = new_size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func tex(file: String) -> Texture2D:
	return load(DIR + "ck_" + file + ".png") as Texture2D


## Imagem no retângulo do Figma (suave, sem pegar o toque). `size` vazio = tamanho do PNG ÷ 1,5.
static func pic(file: String, pos: Vector2, node_name: String = "", new_size: Vector2 = Vector2.ZERO) -> TextureRect:
	var result := TextureRect.new()
	result.texture = tex(file)
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_SCALE
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.position = pos
	result.size = new_size if new_size != Vector2.ZERO else result.texture.get_size() / ART_SCALE
	if node_name != "":
		result.name = node_name
	return result


## Arte das estrelas do prato (0 = nunca feito; 1 a 3 = melhores estrelas). O detalhe usa as mesmas, no tamanho dele.
static func stars_texture(count: int, detail: bool) -> Texture2D:
	if count <= 0:
		return tex("stars_0_detail" if detail else "stars_0")
	return tex("stars_%d" % clampi(count, 1, 3))

## Estrelas do prato centradas em `center` (unidades do Figma), na razão da própria arte (0 = nunca feito; as de 1 a 3 têm
## margens diferentes das vazias, por isso o tamanho vem da textura e não de uma caixa fixa).
static func stars_pic(count: int, center: Vector2, detail: bool, node_name: String) -> TextureRect:
	var texture := stars_texture(count, detail)
	var factor := 1.0 if detail and count > 0 else 1.0 / ART_SCALE
	var size := texture.get_size() * factor
	var result := pic("stars_0", center - size / 2.0, node_name, size)
	result.texture = texture
	result.set_meta("count", count)
	return result


## Torna um Control tocável (toque curto, solto dentro dele).
static func tappable(control: Control, action: Callable) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_STOP
	UiKit.on_tap(control, action)


## Aumenta só a área de toque de um Control (sem mudar o desenho): um filho invisível `Hit` que sai `grow` (esq, cima, dir,
## baixo, em unidades) da caixa dele e leva o toque curto (`action`) ou o gesto bruto (`on_input`). O próprio Control deixa
## de pegar o toque.
static func widen(control: Control, grow: Vector4, action: Callable = Callable(), on_input: Callable = Callable()) -> Control:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hit := Control.new()
	hit.name = "Hit"
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	var fit := func() -> void:
		hit.position = Vector2(-grow.x, -grow.y)
		hit.size = control.size + Vector2(grow.x + grow.z, grow.y + grow.w)
	fit.call()
	control.resized.connect(fit)
	control.add_child(hit)
	if action.is_valid():
		UiKit.on_tap(hit, action)
	if on_input.is_valid():
		hit.gui_input.connect(on_input)
	return hit


## Rótulo da fonte da madeira no retângulo `box`: a maior fonte (entre `min_px` e `base_px`) em que o texto cabe em
## `max_lines` linhas dentro da caixa; cortado com reticências se ainda assim não couber.
static func label(value: String, box: Rect2, base_px: int, min_px: int = 12, max_lines: int = 1, color: Color = INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER, fixed_px: int = 0, outline: int = 0) -> Label:
	var result := Label.new()
	result.text = value
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.horizontal_alignment = align
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.position = box.position
	result.size = box.size
	result.clip_text = true
	result.add_theme_constant_override("line_spacing", 0)  # a medida do texto não conta o espaço extra entre linhas
	result.theme = HomeUi.theme(base_px, color)
	var font := result.get_theme_font("font")
	var chosen := min_px
	if fixed_px > 0:
		base_px = fixed_px
		min_px = fixed_px
		chosen = fixed_px
	for px in range(base_px, min_px - 1, -1):
		var measured := font.get_multiline_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, box.size.x, px)
		var lines := int(round(measured.y / maxf(1.0, font.get_height(px))))
		if measured.y <= box.size.y + 0.5 and lines <= max_lines and measured.x <= box.size.x + 0.5:
			chosen = px
			break
	result.theme = HomeUi.theme(chosen, color, INK, outline) if outline > 0 else HomeUi.theme(chosen, color)
	if max_lines > 1:
		result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result.max_lines_visible = max_lines
	result.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return result


## Maior fonte (até `base_px`) em que TODOS os textos cabem na caixa em `max_lines` linhas: o mesmo tamanho para todos
## os cartões iguais. Calculado uma vez por caixa e guardado.
static var _fixed: Dictionary = {}


static func fixed_size(key: String, texts: Array, box: Vector2, base_px: int, max_lines: int) -> int:
	if _fixed.has(key):
		return int(_fixed[key])
	var font := HomeUi.theme(base_px, INK).default_font
	var chosen := 8
	for px in range(base_px, 7, -1):
		var fits := true
		for text: String in texts:
			var measured := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, box.x, px)
			var lines := int(round(measured.y / maxf(1.0, font.get_height(px))))
			if measured.y > box.y + 0.5 or lines > max_lines or measured.x > box.x + 0.5:
				fits = false
				break
		if fits:
			chosen = px
			break
	_fixed[key] = chosen
	return chosen


## Nomes de todos os pratos / ingredientes do fogão (para medir o pior caso).
static func stove_output_names() -> Array:
	var result: Array = []
	for id in Database.recipes_for("stove"):
		result.append(Database.item_name(Database.recipe_output(Database.recipes[id])))
	return result


static func stove_input_names() -> Array:
	var result: Array = []
	for id in Database.recipes_for("stove"):
		for item_id: String in GameState.recipe_inputs(id):
			var text := Database.item_name(item_id)
			if not text in result:
				result.append(text)
	return result


## Largura do texto na fonte da madeira.
static func text_width(value: String, px: int) -> float:
	var font := HomeUi.theme(px, INK).default_font
	return font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x


## Comida ilustrada do item; sem ela, o ícone pixel (nítido) centrado na caixa.
static func dish_pic(item: String, box: Rect2, node_name: String = "") -> TextureRect:
	var food := StationWood.food_texture(item)
	var result := TextureRect.new()
	result.texture = food if food != null else Database.item_icon(item)
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS if food != null else CanvasItem.TEXTURE_FILTER_NEAREST
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.position = box.position
	result.size = box.size
	if node_name != "":
		result.name = node_name
	return result


## NinePatch no sistema de unidades do Figma: a textura vale 1,5× o tamanho final, então o desenho é reduzido por 1/1,5
## dentro de um Control comum (só a região lisa do meio estica; as pontas e as setinhas ficam intactas).
class Nine extends Control:
	var inner := NinePatchRect.new()

	func _init(texture: Texture2D, margins: Vector4i) -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.texture = texture
		inner.patch_margin_left = margins.x
		inner.patch_margin_top = margins.y
		inner.patch_margin_right = margins.z
		inner.patch_margin_bottom = margins.w
		inner.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
		inner.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
		inner.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.scale = Vector2.ONE / CookPanel.ART_SCALE
		add_child(inner)
		resized.connect(_fit)

	func _fit() -> void:
		inner.size = size * CookPanel.ART_SCALE


# --- Quadro (moldura, ladrilho do meio, rodapé) --------------------------------------------

func _build_frame() -> void:
	_backdrop = _plain("Backdrop", Vector2(0, TOP_Y), Vector2(FRAME_W, FULL_H))
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP  # o toque dentro do painel nunca chega ao mapa
	add_child(_backdrop)
	_top = pic("panel_top", Vector2(0, TOP_Y), "PanelTop")
	add_child(_top)
	_mid = Control.new()
	_mid.name = "PanelMid"
	_mid.clip_contents = true
	_mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_mid)
	var tile := TextureRect.new()
	tile.name = "Tile"
	tile.texture = tex("panel_mid")
	tile.stretch_mode = TextureRect.STRETCH_TILE
	tile.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.scale = Vector2.ONE / ART_SCALE  # o período do tracejado continua 14,67 unidades
	_mid.add_child(tile)
	_tile = tile
	_bottom = pic("panel_bottom", Vector2(0, BASE_Y), "PanelBottom")
	add_child(_bottom)


func _build_toggle() -> void:
	var toggle := _plain("CookToggle", Vector2(214, 159), Vector2(300, 100))
	_toggle_art = pic("toggle_dishes", Vector2.ZERO, "Art")
	toggle.add_child(_toggle_art)
	var dishes := _plain("DishesHalf", Vector2.ZERO, Vector2(150, 100))
	tappable(dishes, _set_mode.bind(false))
	toggle.add_child(dishes)
	var invent := _plain("InventHalf", Vector2(150, 0), Vector2(150, 100))
	tappable(invent, _open_invent)
	toggle.add_child(invent)
	add_child(toggle)
	var book := label("Ver tudo", Rect2(69, 172, 128, 70), 24, 17, 1, INK)
	book.name = "CookRecipeBook"
	tappable(book, _open_recipe_book)
	add_child(book)


## X de madeira padrão (o mesmo da Venda/Encomendas) no canto de cima à direita; o tamanho acompanha a escala do painel.
func _build_close() -> void:
	_close = BagUi.plain_button(func() -> void: close())
	_close.name = "CloseButton"
	var art := TextureRect.new()
	art.name = "Art"
	art.texture = MissionUi.tex("close")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_close.add_child(art)
	add_child(_close)
	_place_close()


func _place_close() -> void:
	var px := 44.0 / _s
	_close.size = Vector2(px, px)
	_close.position = Vector2(FRAME_W - px - 2.0 / _s, TOP_Y + 2.0 / _s)
	var art := _close.get_node("Art") as Control
	var inset := 3.0 / _s
	art.position = Vector2(inset, inset)
	art.size = Vector2(px - inset * 2.0, px - inset * 2.0)


## A aba Inventar e o Livro de receitas só abrem no capítulo em que a história os apresenta.
func _open_invent() -> void:
	if GameState.invent_open():
		_set_mode(true)
	else:
		Events.toast_requested.emit("Continue a História")


func _open_recipe_book() -> void:
	if GameState.recipe_book_open():
		PetNotebook.open("recipes")
	else:
		Events.toast_requested.emit("Continue a História")


## Troca de aba: Pratos (fila, categorias, filtros, lista e detalhe) × Inventar (`CookInvent`). Troca o fundo e o alternador.
func _set_mode(on: bool) -> void:
	invent_mode = on
	var pratos: Array[Control] = [_slots, _cats, _arrow, _list, _bar, _detail]
	for filter_node: Control in _filter_nodes.values():
		pratos.append(filter_node)
	for node in pratos:
		node.visible = not on
	_invent.visible = on
	_toggle_art.texture = tex("toggle_invent" if on else "toggle_dishes")
	var part := "inv_panel_" if on else "panel_"
	_top.texture = tex(part + "top")
	_tile.texture = tex(part + "mid")
	_bottom.texture = tex(part + "bottom")
	if not on:
		_invent.close_picker()
	else:
		_invent.refresh()


# --- Categorias -------------------------------------------------------------------------

var _category_defs: Array[Dictionary] = []


## Categorias reais: Todos, um por tipo de prato já aberto no dia (`invent.json → dish_types`) e Outros (receitas sem tipo).
func _categories() -> Array[Dictionary]:
	var result: Array[Dictionary] = [{"id": "all", "name": "Todos", "item": ""}]
	for def: Dictionary in CookInvent.dish_types():
		if GameState.dish_type_open(str(def.id)):
			result.append({"id": str(def.id), "name": str(def.get("plural", def.name)), "item": str(def.dish)})
	result.append({"id": "other", "name": "Outros", "item": "treat_box"})
	return result

func _build_categories() -> void:
	_cats = CookScroll.new()
	_cats.name = "CatScroll"
	_cats.vertical = false
	# Janela 3,5 unidades mais alta em cima e embaixo: o cartão (desenho de 80) toca como 88 (~44 px na tela).
	_cats.position = CAT_VIEW.position - Vector2(0, 3.5)
	_cats.size = CAT_VIEW.size + Vector2(0, 7)
	_category_defs = _categories()
	_cats.content.size = Vector2(CAT_STEP * _category_defs.size() + 0.33, CAT_SIZE.y + 7.0)
	add_child(_cats)
	for i in _category_defs.size():
		var card := _category_card(_category_defs[i])
		card.position = Vector2(i * CAT_STEP, 3.5)
		_cats.content.add_child(card)
		_cat_nodes[str(_category_defs[i].id)] = card
	var arrow := pic("cat_arrow", Vector2(610, 405), "CatArrow")
	widen(arrow, Vector4(4, 18, 6, 19), _scroll_categories)
	add_child(arrow)
	_arrow = arrow


## Cartão de categoria (igual para todas): ícone num quadro de 52×52 e o nome em até 2 linhas.
func _category_card(data: Dictionary) -> Control:
	var card := _plain("Cat_" + str(data.id), Vector2.ZERO, CAT_SIZE)
	var art := pic("cat_off", Vector2.ZERO, "Art", CAT_SIZE)
	card.add_child(art)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = Vector2(12, 14)
	icon.size = Vector2(52, 52)
	if str(data.item) == "":
		icon.texture = tex("ico_all")
		icon.position = Vector2(12 + 13.5, 14 + 13.5)  # 25×25 centrado na mesma caixa de 52×52
		icon.size = Vector2(25, 25)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	else:
		icon.texture = Database.item_icon(str(data.item))
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	card.add_child(icon)
	var name_label := label(str(data.name), Rect2(66, 14, 72, 52), 22, 11, 2, INK, HORIZONTAL_ALIGNMENT_CENTER, fixed_size("cat", _category_defs.map(func(c: Dictionary) -> String: return str(c.name)), Vector2(72, 52), 22, 2))
	name_label.name = "Name"
	card.add_child(name_label)
	card.set_meta("selected", false)
	card.set_meta("on_tap", _select_category.bind(str(data.id)))
	card.set_meta("hit_pad", Vector2(0, 3.5))
	return card


func _select_category(id: String) -> void:
	category = id
	_update_categories()
	_refresh_list()


func _update_categories() -> void:
	for id: String in _cat_nodes:
		var card: Control = _cat_nodes[id]
		var on := id == category
		card.set_meta("selected", on)
		(card.get_node("Art") as TextureRect).texture = tex("cat_on" if on else "cat_off")


## A seta ">" rola um cartão; no fim, volta ao começo.
func _scroll_categories() -> void:
	if _cats.offset >= _cats.max_offset() - 1.0:
		_cats.scroll_to(0.0)
	else:
		_cats.scroll_to(minf(_cats.offset + CAT_STEP, _cats.max_offset()))


# --- Filtros ----------------------------------------------------------------------------

func _build_filters() -> void:
	# (id, posição, área de toque extra esq/cima/dir/baixo): sobe/desce até a faixa livre entre categorias e lista e
	# divide a folga com o vizinho.
	var specs := [["can", Vector2(59, 496), Vector4(9, 23, 3, 2)], ["missing", Vector2(183, 496), Vector4(3, 23, 3, 2)], ["tiro", Vector2(281, 498), Vector4(3, 25, 10, 4)]]
	for spec: Array in specs:
		var id: String = spec[0]
		var button := pic("filter_" + id, spec[1] as Vector2, "Filter_" + id)
		button.pivot_offset = button.size / 2.0
		button.set_meta("selected", false)
		widen(button, spec[2] as Vector4, _toggle_filter.bind(id))
		add_child(button)
		_filter_nodes[id] = button


## Um filtro por vez; tocar de novo no escolhido limpa.
func _toggle_filter(id: String) -> void:
	filter = "" if filter == id else id
	_update_filters()
	_refresh_list()


func _update_filters() -> void:
	for id: String in _filter_nodes:
		var button: Control = _filter_nodes[id]
		var on := id == filter
		button.set_meta("selected", on)
		button.modulate = GOLD if on else Color.WHITE
		button.scale = Vector2.ONE * (1.05 if on else 1.0)


# --- Lista de pratos --------------------------------------------------------------------

func _build_list() -> void:
	_list = CookScroll.new()
	_list.name = "DishList"
	_list.position = LIST_POS
	_list.size = Vector2(LIST_W, LIST_H)
	_list.scrolled.connect(_sync_bar)
	add_child(_list)


## Uma linha da lista de pratos: receita fixa do fogão (`kind: recipe`, id = a receita) ou prato do motor já descoberto
## (`kind: dish`, id = "k_<tipo>_<ingredientes>"). Tem item de saída, nome, tempo, estrelas reais (0 = nunca feito), trancado,
## tipo (categoria), ingredientes que pagam, motivo de não dar (`error`) e se é "Para crescer".
func _entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var foods := StationTray.growth_foods()
	for id in StationTray.recipe_ids(station_id, _focus):
		result.append(_recipe_entry(id, foods))
	for known: Dictionary in GameState.known_dishes():
		if GameState.dish_recipe_match(str(known.type), GameState.dish_inputs(known.ingredients)) != "":
			continue  # a receita fixa equivalente já tem o seu cartão
		result.append(_dish_entry(known, foods))
	return result


func _recipe_entry(id: String, foods: Array[String]) -> Dictionary:
	var recipe: Dictionary = Database.recipes[id]
	var output: String = Database.recipe_output(recipe)
	return {"id": id, "kind": "recipe", "output": output, "name": Database.item_name(output), "seconds": int(float(recipe.get("seconds", 60)) * float(GameState.recipe_mastery("recipe:" + id).time)),
		"stars": GameState.recipe_stars(id), "locked": GameState.content_error("recipe", id, recipe) != "",
		"type": str(recipe.get("dish_type", "")), "inputs": GameState.recipe_inputs(id), "error": GameState.cook_many_error(id, 1),
		"grow": output in foods}


func _dish_entry(known: Dictionary, foods: Array[String]) -> Dictionary:
	var groups := GameState.growth_pending_groups()
	var ingredients: Array = known.ingredients
	var type := str(known.type)
	var output := DishRules.make_id(type, ingredients, 1)
	Database.ensure_dish(output)
	var counts := DishRules.counts_as(type, ingredients)
	return {"id": "k_%s_%s" % [type, "+".join(PackedStringArray(ingredients))], "kind": "dish", "key": str(known.key), "output": output,
		"name": DishRules.name_of(type, ingredients), "seconds": int(float(DishRules.type_def(type).get("seconds", 60)) * float(GameState.recipe_mastery(str(known.key)).time)), "stars": int(known.stars),
		"locked": false, "type": type, "inputs": GameState.dish_inputs(ingredients), "error": GameState.cook_known_dish_error(str(known.key)),
		"grow": output in foods or (counts != "" and counts in foods) or GameState.dish_serves_groups(type, ingredients, groups)}


func _entry(id: String) -> Dictionary:
	for entry: Dictionary in _entries():
		if str(entry.id) == id:
			return entry
	return {}


## Categoria (tipo de prato; receita sem tipo = Outros) e filtro aplicados.
func _filtered_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in _entries():
		if category != "all" and (str(entry.type) if str(entry.type) != "" else "other") != category:
			continue
		match filter:
			"can":
				if str(entry.error) != "":
					continue
			"missing":
				# Faltam ingredientes: o que está liberado e não dá para fazer por falta de estoque.
				if bool(entry.locked) or GameState.inventory.has_all(entry.inputs):
					continue
			"tiro":
				if not bool(entry.grow):
					continue
		result.append(entry)
	return result


## Refaz os cartões só quando a lista mudou (filtro, ordem, trancas ou estrelas): a rolagem e a escolha ficam.
func _refresh_list() -> void:
	var entries := _filtered_entries()
	var key := ""
	for entry: Dictionary in entries:
		key += "%s%s%d%s;" % [entry.id, "L" if bool(entry.locked) else "", int(entry.stars), "G" if bool(entry.grow) else ""]
	if key == _list_key:
		return
	_list_key = key
	for child in _list.content.get_children():
		_list.content.remove_child(child)
		child.queue_free()
	_dish_nodes.clear()
	for i in entries.size():
		var card := _dish_card(entries[i])
		card.position = Vector2((i % 2) * DISH_COL_X, (i / 2) * DISH_SIZE.y)
		_list.content.add_child(card)
		_dish_nodes[str(entries[i].id)] = card
	_list.content.size = Vector2(LIST_W, ceilf(entries.size() / 2.0) * DISH_SIZE.y)
	_list.move_to(_list.offset)
	_sync_bar()


## Selo "Para crescer": pílula verde pequena (desenhada por código, provisória) nos pratos que o próximo crescimento pede.
static func grow_badge(pos: Vector2, width: float, name_text: String = "GrowBadge") -> Control:
	var panel := Panel.new()
	panel.name = name_text
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = pos
	panel.size = Vector2(width, 19)
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.GO
	style.set_corner_radius_all(10)
	style.border_color = Palette.WOOD_CREAM
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(label("Para crescer", Rect2(0, 0, width, 19), 13, 9, 1, Palette.WOOD_CREAM, HORIZONTAL_ALIGNMENT_CENTER))
	return panel


## Cartão de prato (igual para todos): prato, nome em até 2 linhas, estrelas, relógio + tempo e, se vale, o selo "Para crescer".
func _dish_card(entry: Dictionary) -> Control:
	var id := str(entry.id)
	var card := _plain("Dish_" + id, Vector2.ZERO, DISH_SIZE)
	var body := _plain("Body", Vector2.ZERO, DISH_SIZE)
	body.add_child(pic("dish_off", Vector2.ZERO, "Art", DISH_SIZE))
	body.add_child(dish_pic(str(entry.output), Rect2(36, 24, 89, 56), "Picture"))
	var title := label(str(entry.name), Rect2(12, 78, 136, 46), 22, 15, 2, INK, HORIZONTAL_ALIGNMENT_CENTER, fixed_size("dish", stove_output_names(), Vector2(136, 46), 22, 2))
	title.name = "Name"
	body.add_child(title)
	body.add_child(stars_pic(int(entry.stars), Vector2(43, 133), false, "DishStars"))
	body.add_child(pic("clock", Vector2(83, 124), "Clock"))
	var time_label := label(TimeText.short(int(entry.seconds)), Rect2(104, 120.5, 52, 24), 20, 12, 1, INK, HORIZONTAL_ALIGNMENT_LEFT)
	time_label.name = "Time"
	body.add_child(time_label)
	card.add_child(body)
	if bool(entry.grow):
		card.add_child(grow_badge(Vector2(10, 4), 90))
	if bool(entry.locked):
		body.modulate.a = 0.55
		var lock := TextureRect.new()
		lock.name = "LockIcon"
		lock.texture = load(HomeUi.DIR + "farm_lock.png") as Texture2D
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock.position = Vector2(DISH_SIZE.x - 38, 10)
		lock.size = Vector2(26, 26)
		card.add_child(lock)
	card.set_meta("selected", id == selected)
	card.set_meta("on_tap", _select_dish.bind(id))
	(body.get_node("Art") as TextureRect).texture = tex("dish_on" if id == selected else "dish_off")
	return card


func _select_dish(id: String) -> void:
	selected = id
	_update_selection()
	_refresh_detail()


func _update_selection() -> void:
	for id: String in _dish_nodes:
		var card: Control = _dish_nodes[id]
		var on := id == selected
		card.set_meta("selected", on)
		(card.get_node("Body/Art") as TextureRect).texture = tex("dish_on" if on else "dish_off")


func _scroll_to_selected() -> void:
	if not is_instance_valid(_list) or not _dish_nodes.has(selected):
		return
	var card: Control = _dish_nodes[selected]
	_list.scroll_to_show(Rect2(card.position, card.size))


# --- Barra de rolagem própria -----------------------------------------------------------

func _build_bar() -> void:
	_bar = _plain("DishScrollBar", BAR_POS, BAR_SIZE)
	_track = Nine.new(tex("scroll_track"), Vector4i(0, 74, 0, 74))
	_track.name = "Track"
	_track.size = BAR_SIZE
	_bar.add_child(_track)
	var thumb_tex := tex("scroll_thumb")
	_thumb = Nine.new(thumb_tex, Vector4i(0, 40, 0, 40))
	_thumb.name = "Thumb"
	widen(_thumb, Vector4(0, 0, 20, 0), Callable(), _on_thumb_input)
	_bar.add_child(_thumb)
	var up := _plain("Up", Vector2.ZERO, Vector2(BAR_SIZE.x, BAR_ARROW))
	widen(up, Vector4(0, 9, 20, 0), func() -> void: _list.scroll_to(_list.offset - DISH_SIZE.y))
	_bar.add_child(up)
	var down := _plain("Down", Vector2(0, BAR_SIZE.y - BAR_ARROW), Vector2(BAR_SIZE.x, BAR_ARROW))
	down.name = "Down"
	widen(down, Vector4(0, 0, 20, 9), func() -> void: _list.scroll_to(_list.offset + DISH_SIZE.y))
	_bar.add_child(down)
	add_child(_bar)


## Região por onde o pegador anda (entre as setinhas) e o tamanho dele, proporcional ao que está à vista.
func _thumb_geometry() -> Rect2:
	var travel_top := BAR_ARROW
	var travel := _bar.size.y - BAR_ARROW * 2.0
	var content := maxf(_list.content_length(), 1.0)
	var view := _list.view_length()
	var height := travel if content <= view else clampf(travel * view / content, 62.0, travel)
	var room_left := travel - height
	var share := 0.0 if _list.max_offset() <= 0.0 else _list.offset / _list.max_offset()
	return Rect2(0, travel_top + room_left * share, BAR_SIZE.x, height)


func _sync_bar() -> void:
	if _thumb == null:
		return
	var rect := _thumb_geometry()
	_thumb.position = rect.position
	_thumb.size = rect.size
	_thumb.visible = _list.max_offset() > 0.0


func _on_thumb_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		_thumb_drag = button.pressed
		_thumb.accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion != null and _thumb_drag:
		var rect := _thumb_geometry()
		var travel := _bar.size.y - BAR_ARROW * 2.0 - rect.size.y
		if travel > 0.0:
			_list.scroll_to(_list.offset + motion.relative.y * _list.max_offset() / travel, false)
		_thumb.accept_event()


# --- Fila (4 espaços) --------------------------------------------------------------------

## Estado de cada espaço pela fila, como a bandeja de madeira: vazio, na fila, produzindo, pronto ou fechado (compra).
func _slot_states() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var target := GameState.station(station_id)
	var now := GameState.now()
	for i in GameState.station_slots(station_id):
		if i >= target.queue.size():
			result.append({"state": "free"})
			continue
		var entry: Dictionary = target.queue[i]
		var seconds := Database.entry_seconds(entry)
		var remaining := float(entry["ready_at"]) - now
		var info := {"output": Database.entry_output(entry), "seconds": seconds, "ready_at": float(entry["ready_at"])}
		if remaining <= 0.0:
			info["state"] = "ready"
		elif remaining > seconds:
			info["state"] = "queued"
		else:
			info["state"] = "busy"
		result.append(info)
	for upgrade_id: String in GameState.pending_slot_upgrades(station_id):
		result.append({"state": "locked", "upgrade": upgrade_id})
	return result


func _refresh_slots() -> void:
	var states := _slot_states()
	var key := ""
	for info in states:
		key += "%s:%s:%s;" % [info.state, info.get("output", ""), info.get("upgrade", "")]
	if key == _slot_key:
		return
	_slot_key = key
	for child in _slots.get_children():
		_slots.remove_child(child)
		child.queue_free()
	for i in mini(states.size(), SLOT_X.size()):
		var slot := _slot_card(i, states[i])
		_slots.add_child(slot)
		if i == _pop_slot and slot.has_node("Dish"):
			Motion.pop_in(slot.get_node("Dish"))
	_pop_slot = -1


## Espaço da fila (um só jeito de montar os cinco estados); centrado no x do espaço, com a base em y = 355.
func _slot_card(index: int, info: Dictionary) -> Control:
	var state: String = info.state
	var art := tex("slot_" + ("busy" if state == "queued" else state))
	var card_size := art.get_size() / ART_SCALE
	var card := _plain("Slot_%d" % index, Vector2(SLOT_X[index] - card_size.x / 2.0, SLOT_BASE - card_size.y), card_size)
	card.set_meta("state", state)
	card.add_child(pic("slot_" + ("busy" if state == "queued" else state), Vector2.ZERO, "Art"))
	match state:
		"ready":
			card.add_child(dish_pic(str(info.output), Rect2(30, 17, 74, 50), "Dish"))
			card.add_child(pic("ready_btn", Vector2(24, 71), "ReadyBadge"))
			tappable(card, _collect_from.bind(card))
		"busy", "queued":
			var ring := RingProgress.new()
			ring.name = "Ring"
			ring.thickness = 8.0
			ring.color = ORANGE
			ring.track = RING_TRACK
			ring.custom_minimum_size = Vector2.ZERO
			ring.size = Vector2(68, 68)
			ring.position = Vector2(66 - 34, 39 - 34)
			card.add_child(ring)
			var dish := dish_pic(str(info.output), Rect2(30, 16, 74, 50), "Dish")
			if state == "queued":
				dish.modulate.a = 0.55
			card.add_child(dish)
			var time := label("", Rect2(48, 75, 38, 17), 16, 11)
			time.name = "Time"
			card.add_child(time)
			card.set_meta("ready_at", float(info.ready_at))
			card.set_meta("seconds", float(info.seconds))
			_update_busy(card)
			tappable(card, _busy_tap.bind(card))
		"locked":
			tappable(card, _open_upgrade.bind(str(info.upgrade)))
	return card


## Anel e tempo restante, em cima do que já existe (sem refazer o painel).
func _update_busy(card: Control) -> void:
	var seconds := float(card.get_meta("seconds"))
	var remaining := float(card.get_meta("ready_at")) - GameState.now()
	var ring := card.get_node("Ring") as RingProgress
	var time := card.get_node("Time") as Label
	if str(card.get_meta("state")) == "queued":
		ring.progress = 0.0
		time.text = TimeText.short(int(seconds))
	else:
		ring.progress = clampf(1.0 - remaining / maxf(1.0, seconds), 0.0, 1.0)
		time.text = TimeText.short(int(ceil(maxf(0.0, remaining))))


func _collect_from(card: Control) -> void:
	var origin := card.get_global_transform_with_canvas() * (card.size / 2.0)
	var got := GameState.collect(station_id)
	if not got.is_empty():
		Events.items_gained.emit(got, 0, origin)


func _busy_tap(card: Control) -> void:
	var remaining := int(ceil(float(card.get_meta("ready_at")) - GameState.now()))
	if str(card.get_meta("state")) == "busy":
		Events.toast_requested.emit("Faltam %s" % TimeText.short(maxi(remaining, 0)))
	else:
		Events.toast_requested.emit("Espera a vez na fila")


## Espaço fechado: abre a compra da ampliação (a mesma ação da bandeja de madeira).
func _open_upgrade(upgrade_id: String) -> void:
	var data: Dictionary = Database.progression.upgrades[upgrade_id]
	Events.sheet_requested.emit(str(data.name), ProgressionUi.purchase(upgrade_id))


# --- Detalhe ----------------------------------------------------------------------------

func _detail_error(id: String) -> String:
	return str(_entry(id).get("error", "Receita desconhecida"))


func _refresh_detail() -> void:
	var key := "%s|%s|%s" % [selected, _e, _detail_inputs_key()]
	if key == _detail_key:
		return
	_detail_key = key
	for child in _detail.get_children():
		_detail.remove_child(child)
		child.queue_free()
	var entry := _entry(selected) if selected != "" else {}
	if entry.is_empty():
		var empty := pic("empty_detail", Vector2.ZERO, "DetailEmpty")
		empty.position = Vector2(DETAIL_POS.x + (DETAIL_SIZE.x - empty.size.x) / 2.0, DETAIL_POS.y + (DETAIL_SIZE.y + _e - empty.size.y) / 2.0)
		_detail.add_child(empty)
		return
	_detail.add_child(dish_pic(str(entry.output), Rect2(455, 503, 167, 112), "DetailPicture"))
	if bool(entry.grow):
		_detail.add_child(grow_badge(Vector2(438, 510), 104, "DetailGrowBadge"))
	var title := label(str(entry.name), Rect2(432, 612, 213, 52), 28, 18, 2, INK, HORIZONTAL_ALIGNMENT_CENTER, fixed_size("detail", stove_output_names(), Vector2(213, 52), 28, 2))
	title.name = "DetailName"
	_detail.add_child(title)
	var time := TimeText.short(int(entry.seconds))
	_detail.add_child(stars_pic(int(entry.stars), Vector2(471.5, 687.5), true, "DetailStars"))
	var divider := ColorRect.new()
	divider.name = "DetailDivider"
	divider.color = INK
	divider.position = Vector2(534, 676)
	divider.size = Vector2(2, 24)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail.add_child(divider)
	_detail.add_child(pic("clock_detail", Vector2(565, 674), "DetailClock"))
	var time_label := label(time, Rect2(595, 673, 62, 32), 24, 14, 1, INK, HORIZONTAL_ALIGNMENT_LEFT)
	time_label.name = "DetailTime"
	_detail.add_child(time_label)
	var inputs: Dictionary = entry.inputs
	var n := 0
	for item_id: String in inputs:
		if n >= ING_X.size():
			break
		_detail.add_child(_ingredient_card(item_id, int(inputs[item_id]), ING_X[n]))
		n += 1
	var queue := pic("btn_queue", Vector2(419, 886 + _e), "QueueButton")
	queue.modulate.a = 0.6 if str(entry.error) != "" else 1.0
	if together_first():
		queue.modulate = Color(1, 1, 1, 0.35)  # na primeira papinha só vale Cozinhar junto
	tappable(queue, _queue_selected)
	_detail.add_child(queue)
	var together := pic("btn_together", Vector2(414, 953 + _e), "TogetherButton")
	together.modulate.a = 0.6 if str(entry.error) != "" else 1.0
	tappable(together, _together_selected)
	_detail.add_child(together)


## Parte do estado que muda o detalhe sem mudar a escolha: o que tem na mochila dos ingredientes e se dá para fazer.
func _detail_inputs_key() -> String:
	var entry := _entry(selected) if selected != "" else {}
	if entry.is_empty():
		return ""
	var key := str(entry.error) + "|%d|%s" % [int(entry.stars), "G" if bool(entry.grow) else ""]
	var inputs: Dictionary = entry.inputs
	for item_id: String in inputs:
		key += "|%s:%d" % [item_id, GameState.inventory.count(item_id)]
	return key


## Cartão de ingrediente (igual para todos): ícone, nome, pílula verde (tem) ou vermelha (falta) com ✓ / ! e "tem/precisa".
func _ingredient_card(item_id: String, need: int, x: float) -> Control:
	var have := GameState.inventory.count(item_id)
	var ok := have >= need
	var card := _plain("Ingredient_" + item_id, Vector2(x, ING_Y), Vector2(82, 148))
	card.set_meta("ok", ok)
	card.add_child(pic("ingredient", Vector2.ZERO, "Art"))
	card.add_child(dish_pic(item_id, Rect2(24, 10, 34, 34), "Icon"))
	var name_label := label(Database.item_name(item_id), Rect2(4, 48, 74, 56), 20, 18, 3, INK, HORIZONTAL_ALIGNMENT_CENTER, maxi(18, fixed_size("ingredient", stove_input_names(), Vector2(74, 56), 20, 3)))
	name_label.name = "Name"
	card.add_child(name_label)
	card.add_child(pic("qty_ok" if ok else "qty_missing", Vector2(10, 107), "Pill"))
	card.add_child(pic("mark_ok" if ok else "mark_missing", Vector2(44, 108), "Mark"))
	var count := label("%d/%d" % [have, need], Rect2(11, 112, 36, 22), 22, 11, 1, Palette.WOOD_CREAM, HORIZONTAL_ALIGNMENT_CENTER, fixed_size("count", ["30/2"], Vector2(36, 22), 22, 1), 3)
	count.name = "Count"
	card.add_child(count)
	tappable(card, TaskHelp.open.bind("item", item_id, need))
	return card


## Passo "Cozinhar junto" da história ainda aberto: a fila espera, o caminho é o minigame.
static func together_first() -> bool:
	var quest := "first_kitchen"
	return Database.quests.has(quest) and not GameState.progress.claimed_quests.has(quest) \
		and GameState.progress.current_main_quest() == quest


## "Cozinhar junto" do prato escolhido: abre o minigame (os ingredientes só saem no fim). Mesmos motivos do "Colocar na fila".
func _together_selected() -> void:
	var entry := _entry(selected) if selected != "" else {}
	if entry.is_empty():
		Events.toast_requested.emit("Escolha um prato")
		return
	var id := str(entry.id)
	var reason := str(entry.error)
	if reason != "":
		if str(entry.kind) == "recipe" and bool(entry.locked):
			TaskHelp.open("recipe", id, int(Database.recipes[id].get("qty", 1)))
			return
		Events.toast_requested.emit(reason)
		var node := _detail.get_node_or_null("TogetherButton") as CanvasItem
		if node != null:
			Motion.shake(node)
		return
	var items: Array[String] = []
	var inputs: Dictionary = entry.inputs
	for item_id: String in inputs:
		for i in int(inputs[item_id]):
			items.append(item_id)
	var spec := {"name": str(entry.name), "output": str(entry.output), "items": items}
	if str(entry.kind) == "recipe":
		spec["mastery_key"] = "recipe:" + id
		spec["check"] = func() -> String: return GameState.cook_many_error(id, 1)
		spec["cook"] = func(stars: int, together: bool) -> String: return GameState.cook_many(id, 1, stars, together)
	else:
		var key := str(entry.key)
		var parsed := DishRules.parse_key(key.trim_prefix("dish:"))
		var picks: Array = GameState._expand_picks(GameState.dish_inputs(parsed.ingredients))
		spec["mastery_key"] = key
		spec["check"] = func() -> String: return GameState.cook_known_dish_error(key)
		spec["cook"] = func(stars: int, together: bool) -> String: return GameState.cook_dish(str(parsed.type), picks, stars, together)
	start_together(spec)


## Abre o minigame por cima de tudo (filho da casca) e deixa a cozinha atualizar quando o prato entrar na fila.
func start_together(spec: Dictionary) -> CookTogether:
	var host: Node = _find_main()
	if host == null:
		host = room.get_tree().root
	return CookTogether.open(host, spec)


func _queue_selected() -> void:
	var entry := _entry(selected) if selected != "" else {}
	if entry.is_empty():
		return
	var id := str(entry.id)
	var reason := str(entry.error)
	if together_first():
		Events.toast_requested.emit("Na primeira papinha, cozinhe junto com a vovó!")
		var together := _detail.get_node_or_null("TogetherButton") as CanvasItem
		if together != null:
			Motion.pulse(together)
		return
	if reason != "":
		var node := _detail.get_node_or_null("QueueButton") as CanvasItem
		if str(entry.kind) == "recipe" and bool(entry.locked):
			TaskHelp.open("recipe", id, int(Database.recipes[id].get("qty", 1)))
			return
		Events.toast_requested.emit(reason)
		if node != null:
			Motion.shake(node)
		return
	_pop_slot = GameState.station(station_id).queue.size()
	var failed := GameState.cook_many(id, 1) if str(entry.kind) == "recipe" else GameState.cook_known_dish(str(entry.key))
	if failed != "":
		_pop_slot = -1
		Events.toast_requested.emit(failed)


# --- Atualização e posição --------------------------------------------------------------

func _refresh_all() -> void:
	_update_categories()
	_update_filters()
	_refresh_slots()
	_refresh_list()
	_update_selection()
	_refresh_detail()
	_sync_bar()


func _on_state_changed() -> void:
	if closing:
		return
	_refresh_slots()
	_refresh_list()
	_refresh_detail()
	if _invent != null:
		_invent.on_state_changed()


func _process(delta: float) -> void:
	if closing:
		return
	if not is_instance_valid(room) or not room.is_visible_in_tree() or not GameState.has_upgrade(station_id) or _selector_open():
		close(true)
		return
	_tick += delta
	if _tick < TICK:
		return
	_tick = 0.0
	_apply_layout()
	var flipped := false
	for card in _slots.get_children():
		if str(card.get_meta("state", "")) in ["busy", "queued"]:
			if float(card.get_meta("ready_at")) - GameState.now() <= 0.0:
				flipped = true
			else:
				_update_busy(card as Control)
	if flipped:
		_refresh_slots()


func _selector_open() -> bool:
	return _host != null and _host.has_method("is_map_open") and bool(_host.call("is_map_open")) \
		or _host != null and _host.has_method("is_traveling") and bool(_host.call("is_traveling"))


## Topo = logo abaixo da pílula do mundo; fundo = 8 px acima da barra de abas. Calcula `s` e a altura extra `E`.
func _apply_layout() -> void:
	if closing or not is_instance_valid(_host):
		return
	var host_origin := _host.get_global_rect().position
	var pill := _host.find_child("MapButton", true, false) as Control
	var top := (pill.get_global_rect().end.y + 2.0 if pill != null and pill.is_visible_in_tree() else 130.0) - host_origin.y
	var tab_art := _host.get_tree().root.find_child("TabBarArt", true, false) as Control
	var bottom := (tab_art.get_global_rect().position.y - 8.0 if tab_art != null else _host.get_global_rect().end.y - 112.0) - host_origin.y
	var width := _host.size.x
	var key := "%.1f|%.1f|%.1f" % [top, bottom, width]
	if key == _layout_key:
		return
	_layout_key = key
	var full := width / FIG_W
	var avail := maxf(bottom - top, 200.0)
	var extra := avail / full - FULL_H
	var factor := full
	var left := 10.0 * full
	if extra < 0.0:
		extra = 0.0
		factor = avail / FULL_H
		left = (width - FRAME_W * factor) / 2.0
	_s = factor
	_e = extra
	scale = Vector2(factor, factor)
	position = Vector2(left, top - TOP_Y * factor)
	_backdrop.size.y = FULL_H + extra
	_mid.position = Vector2(0, MID_Y)
	_mid.size = Vector2(FRAME_W, BASE_Y - MID_Y + extra)
	(_mid.get_node("Tile") as TextureRect).size = _mid.size * ART_SCALE
	_bottom.position.y = BASE_Y + extra
	_list.size = Vector2(LIST_W, LIST_H + extra)
	_list.move_to(_list.offset)
	_bar.size = Vector2(BAR_SIZE.x, BAR_SIZE.y + extra)
	_track.size = _bar.size
	(_bar.get_node("Down") as Control).position.y = _bar.size.y - BAR_ARROW
	_detail_key = ""
	_place_close()
	_sync_bar()
	_refresh_detail()
	if _invent != null:
		_invent.set_extra(extra)
