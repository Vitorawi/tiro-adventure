class_name RecipeBookUi
extends RefCounted
## Livro de receitas, tela única dentro do caderninho (novo desenho, 25/11/2026).
## Cartão do cozinheiro no alto, abas por tipo de prato, a Panela (até 3 ingredientes), filtros, a grade de pratos,
## a barra "Meus ingredientes" e, por cima, um painel de baixo (prato, caminho do cozinheiro ou receita secreta).
## O estado (aba, panela, filtro, painel aberto) fica no `model` da folha: `book_type`, `book_pot`, `book_filter`,
## `book_panel` ("", "dish", "chef", "secret"), `book_dish`. Só a grade e a barra de ingredientes rolam.

const PAPER := Color("fffaf0")
const CREAM := Color("f6ebd8")
const LINE := Color("d9b98a")
const MUTED := Color("806345")
const CAN := Color("4fa35b")
const CAN_SOFT := Color("f1faea")
const NEED := Color("fde7cf")
const HAVE := Color("e7f5e1")
const RING_COLORS: Array[Color] = [Color("e5cda6"), Color("d9b98a"), Color("e8a33a"), Color("c98b1e")]
const TYPE_ORDER: Array[String] = ["papinha", "sopinha", "mingau", "petisco", "biscoito"]
const POT_MAX := 3
const COLS := 3
const GAP := 6.0
const GUTTER := 14.0  # coluna da barra de rolagem: os cartões terminam antes dela
const CARD_H := 106.0
const CARD_PAD := 6.0
const CHEF_H := 44.0
const TYPES_H := 52.0
const POT_H := 50.0
const POT_EMPTY_H := 30.0
const FILTERS_H := 44.0
const BAR_H := 62.0
const SEP := 4.0
const TILE_W := 46.0
const FILTERS: Array[Dictionary] = [
	{"id": "all", "text": "Todos"},
	{"id": "can", "text": "Dá pra fazer"},
	{"id": "new", "text": "Não fiz"},
]


## Altura que sobra para a grade depois das faixas fixas (para o corpo reservar o espaço).
static func grid_height(size_y: float, pot_empty: bool = true) -> float:
	return maxf(110.0, size_y - (CHEF_H + TYPES_H + (POT_EMPTY_H if pot_empty else POT_H) + FILTERS_H + BAR_H + SEP * 5.0))


## `size` = área útil do caderninho (o corpo é um Control de tamanho fixo: só a grade e a barra rolam).
static func body(model: Dictionary, refresh: Callable, size: Vector2 = Vector2(290, 440)) -> Control:
	var root := Control.new()
	root.name = "RecipeBook"
	root.custom_minimum_size = size
	root.size = size
	root.clip_contents = true
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	_seed(model)
	_render(root, model, refresh, size)
	return root


static func _seed(model: Dictionary) -> void:
	var types := _types()
	if not model.has("book_type") or str(model.book_type) not in types:
		model["book_type"] = types[0] if not types.is_empty() else "papinha"
	if not model.has("book_pot"):
		model["book_pot"] = []
	if not model.has("book_filter"):
		model["book_filter"] = "all"
	if not model.has("book_panel"):
		model["book_panel"] = ""
	if not model.has("book_grid"):
		model["book_grid"] = {"scroll": 0}
	if not model.has("book_bar"):
		model["book_bar"] = 0


# --- Dados ---------------------------------------------------------------------------------------

static func _types() -> Array[String]:
	var result: Array[String] = []
	var all: Array = DishRules.types()
	for id: String in TYPE_ORDER:
		if id in all and GameState.dish_type_open(id):
			result.append(id)
	for id: Variant in all:
		if str(id) not in result and str(id) not in TYPE_ORDER and GameState.dish_type_open(str(id)):
			result.append(str(id))
	return result


## Ingredientes que o jogador já pode ter visto (abertos no capítulo atual).
static func _shown_ingredients() -> Array:
	var open := DishRules.available(mini(11, GameState.content_day()))
	var result: Array = []
	for id: String in DishRules.order():
		if id in open:
			result.append(id)
	return result


static func _level(key: String) -> int:
	var name := str(GameState.recipe_mastery(key).get("name", ""))
	var rows: Array = Database.recipe_book.mastery
	for i in rows.size():
		if str(rows[i].name) == name:
			return i
	return 0


static func _missing(inputs: Dictionary) -> int:
	var total := 0
	for item: String in inputs:
		total += maxi(0, int(inputs[item]) - GameState.inventory.count(item))
	return total


## Pratos para mostrar: os conhecidos (receitas e pratos feitos) e os com nome ainda não feitos. Com a Panela
## vazia vale só o tipo da aba; com ingredientes na Panela entram os pratos de todos os tipos que levam todos eles.
static func entries(selected: Array, type_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var known_keys := {}
	for row: Dictionary in GameState.recipe_book_rows([]):
		known_keys[GameState.dish_key(str(row.type), row.ingredients)] = true
		if selected.is_empty() and str(row.type) != type_id:
			continue
		if not selected.all(func(id: String) -> bool: return id in row.ingredients):
			continue
		var entry := row.duplicate()
		entry["known"] = true
		entry["level"] = _level(str(row.key))
		result.append(entry)
	var open := _shown_ingredients()
	for named: Dictionary in Database.dishes.named:
		if bool(named.get("secret", false)):
			continue
		var type := str(named.type)
		var key := GameState.dish_key(type, named.ingredients)
		if known_keys.has(key) or not GameState.dish_type_open(type):
			continue
		if selected.is_empty() and type != type_id:
			continue
		if not selected.all(func(id: String) -> bool: return id in named.ingredients):
			continue
		if not named.ingredients.all(func(id: String) -> bool: return id in open):
			continue
		var ingredients := DishRules.canon(named.ingredients)
		var inputs := GameState.dish_inputs(ingredients)
		result.append({"key": key, "type": type, "ingredients": ingredients, "known": false, "level": -1,
			"name": "?", "item": DishRules.icon_item(type, ingredients), "inputs": inputs, "missing": _missing(inputs), "stars": 0})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var can_a := int(a.missing) == 0
		var can_b := int(b.missing) == 0
		if can_a != can_b:
			return can_a
		if bool(a.known) != bool(b.known):
			return bool(a.known)
		return str(a.name).naturalnocasecmp_to(str(b.name)) < 0)
	return result


static func find_entry(key: String) -> Dictionary:
	for type_id: String in _types():
		for entry: Dictionary in entries([], type_id):
			if str(entry.key) == key:
				return entry
	return {}


## Pratos com nome (sem os secretos) de um tipo: [feitos, total].
static func type_progress(type_id: String) -> Vector2i:
	var known := {}
	for row: Dictionary in GameState.recipe_book_rows([]):
		known[GameState.dish_key(str(row.type), row.ingredients)] = true
	var done := 0
	var total := 0
	for named: Dictionary in Database.dishes.named:
		if str(named.type) != type_id or bool(named.get("secret", false)):
			continue
		total += 1
		if known.has(GameState.dish_key(type_id, named.ingredients)):
			done += 1
	return Vector2i(done, total)


## Combinações sem nome ainda por inventar (do tipo, ou de todos com a Panela cheia).
static func invent_count(selected: Array, type_id: String) -> int:
	var known := {}
	for row: Dictionary in GameState.recipe_book_rows([]):
		known[GameState.dish_key(str(row.type), row.ingredients)] = true
	var total := 0
	for entry: Dictionary in GameState._recipe_combinations():
		if selected.is_empty() and str(entry.type) != type_id:
			continue
		if not selected.all(func(id: String) -> bool: return id in entry.ingredients):
			continue
		if known.has(GameState.dish_key(str(entry.type), entry.ingredients)):
			continue
		if not DishRules.named(str(entry.type), entry.ingredients).is_empty():
			continue
		total += 1
	return total


# --- Peças ---------------------------------------------------------------------------------------

static func _t(value: String, px: int, color: Color = Palette.WOOD_INK, wrap: bool = false) -> Label:
	var label := StepCardUi.wood(value, px, color)
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


static func _box(color: Color, border: Color, radius: int, border_width: int = 1, pad: Vector4 = Vector4(6, 4, 6, 4)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = pad.x
	style.content_margin_top = pad.y
	style.content_margin_right = pad.z
	style.content_margin_bottom = pad.w
	return style


static func _panel(style: StyleBoxFlat, node_name: String = "") -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	if node_name != "":
		panel.name = node_name
	return panel


## Toque que vira ação só se o dedo não arrastou (as listas rolam por baixo). Aceita toque e mouse; o mesmo gesto
## que chega pelos dois (toque + mouse emulado) conta uma vez só.
static func _tap(control: Control, action: Callable) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_PASS
	control.gui_input.connect(func(event: InputEvent) -> void:
		var pressed := false
		var at := Vector2.ZERO
		if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			pressed = (event as InputEventMouseButton).pressed
			at = (event as InputEventMouseButton).position
		elif event is InputEventScreenTouch:
			pressed = (event as InputEventScreenTouch).pressed
			at = (event as InputEventScreenTouch).position
		else:
			return
		var global_at := control.get_global_transform_with_canvas() * at
		if pressed:
			control.set_meta("tap_from", global_at)
		elif control.has_meta("tap_from"):
			var from: Vector2 = control.get_meta("tap_from")
			control.remove_meta("tap_from")
			var now := Time.get_ticks_msec()
			if now - int(control.get_meta("tap_at", -1000)) < 250:
				return
			if from.distance_to(global_at) < 14.0 and Rect2(Vector2.ZERO, control.size).has_point(at):
				control.set_meta("tap_at", now)
				action.call())


static func _ignore(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Control and not (child as Control).has_meta("keep_mouse"):
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore(child)


static func _pic(item: String, px: float) -> TextureRect:
	return StationWood.item_pic(item, Database.item_icon(item), px)


## Ícone reduzido para caber no quadrado (nunca passa dele, ao contrário do pixel em tamanho original).
static func _small_pic(item: String, px: float) -> TextureRect:
	var rect := TextureRect.new()
	var food := StationWood.food_texture(item)
	rect.texture = food if food != null else Database.item_icon(item)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	rect.custom_minimum_size = Vector2(px, px)
	rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## Linha com a mesma folga à direita (a coluna da barra de rolagem fica livre).
static func _row(control: Control) -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_right", int(GUTTER))
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(control)
	return margin


static func _ring(item: String, px: float, color: Color, unknown: bool = false, icon_px: float = 36.0, texture: Texture2D = null) -> Control:
	var ring := PanelContainer.new()
	ring.custom_minimum_size = Vector2(px, px)
	ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ring.add_theme_stylebox_override("panel", _box(Color("e5d6bf") if unknown else Palette.WOOD_INSET, color, int(px / 2.0), 3, Vector4.ZERO))
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var inner: Control
	if unknown:
		inner = _t("?", int(px * 0.46), Color("a08868"))
		(inner as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elif texture != null:
		var plain := TextureRect.new()
		plain.texture = texture
		plain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		plain.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		plain.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		plain.custom_minimum_size = Vector2(icon_px, icon_px)
		inner = plain
	else:
		inner = _pic(item, icon_px)
	inner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inner.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ring.add_child(inner)
	return ring


static func _pips(level: int, color: Color) -> Control:
	var row := UiKit.hbox(3)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 4:
		var pip := Panel.new()
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pip.custom_minimum_size = Vector2(8, 8)
		pip.add_theme_stylebox_override("panel", _box(color if i <= level else Color("ead9ba"), Color("c9a974"), 4, 1, Vector4.ZERO))
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(pip)
	return row


## Nome em até 2 linhas: tenta 12, 11 e 10 px até a palavra mais comprida e o parágrafo caberem.
static func _fit_label(value: String, width: float, lines: int = 2) -> Label:
	var label := _t(value, 12, Palette.WOOD_INK, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size.x = width
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var font := label.get_theme_font("font")
	var chosen := 10
	for px: int in [12, 11, 10]:
		chosen = px
		var paragraph := TextParagraph.new()
		paragraph.add_string(value, font, px)
		paragraph.width = width
		var widest := 0.0
		for word: String in value.split(" "):
			widest = maxf(widest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x)
		if paragraph.get_line_count() <= lines and widest <= width:
			break
	label.theme = HomeUi.theme(chosen, Palette.WOOD_INK)
	label.max_lines_visible = lines
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.custom_minimum_size.y = float(chosen + 4) * lines
	return label


static func _button(caption: String, green: bool, node_name: String, action: Callable) -> Button:
	var button := WelcomeSheet._button(caption, green, 120.0, node_name, action)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.x = 100.0
	return button


# --- Tela ----------------------------------------------------------------------------------------

static func _render(root: Control, model: Dictionary, refresh: Callable, size: Vector2) -> void:
	for child: Node in root.get_children():
		root.remove_child(child)
		child.queue_free()
	var again := _render.bind(root, model, refresh, size)
	var selected: Array = model.book_pot
	var type_id := str(model.book_type)
	var main := UiKit.vbox(int(SEP))
	main.name = "BookMain"
	main.custom_minimum_size = size
	main.size = size
	main.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(main)
	main.add_child(_row(_chef_card(model, again)))
	main.add_child(_row(_type_tabs(model, again, size.x - GUTTER)))
	main.add_child(_row(_pot(model, again)))
	var list := entries(selected, type_id)
	main.add_child(_row(_filters(model, again, list)))
	var filter := str(model.book_filter)
	var shown: Array[Dictionary] = list
	if filter == "can":
		shown = list.filter(func(e: Dictionary) -> bool: return int(e.missing) == 0)
	elif filter == "new":
		shown = list.filter(func(e: Dictionary) -> bool: return not bool(e.known))
	main.add_child(_grid(model, again, shown, selected, type_id, size))
	main.add_child(_row(_ingredient_bar(model, again, size.x - GUTTER)))
	var panel := str(model.book_panel)
	if panel != "":
		_open_panel(root, model, again, size, panel)


static func _close(model: Dictionary, again: Callable) -> void:
	model["book_panel"] = ""
	again.call()


static func _reset_grid(model: Dictionary) -> void:
	model["book_grid"] = {"scroll": 0}


# --- Cartão do cozinheiro ------------------------------------------------------------------------

static func _chef_card(model: Dictionary, again: Callable) -> Control:
	var chef := GameState.chef_info()
	var card := _panel(_box(Color("fff3d6"), Color("e8c98c"), 14, 2, Vector4(8, 3, 10, 3)), "ChefCard")
	card.custom_minimum_size = Vector2(0, CHEF_H)
	var row := UiKit.hbox(8)
	card.add_child(row)
	var skill: Dictionary = chef.skill
	var hat := _ring("", 36.0, Palette.HONEY, false, 26.0, UiKit.ui_icon(str(skill.icon)))
	hat.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(hat)
	var text := UiKit.vbox(1)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var top := UiKit.hbox(4)
	var name := _t(str(chef.name), 15)
	name.name = "ChefName"
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name)
	var next := int(chef.next)
	var count := _t("%d/%d ›" % [int(chef.score), next] if next > 0 else "%d pts ›" % int(chef.score), 12, MUTED)
	count.name = "ChefPoints"
	top.add_child(count)
	text.add_child(top)
	if next > 0:
		var base := int(chef.points)
		text.add_child(UiKit.bar(100.0 * float(int(chef.score) - base) / float(maxi(1, next - base)), Palette.HONEY, 7))
	row.add_child(text)
	_ignore(card)
	_tap(card, func() -> void:
		model["book_panel"] = "chef"
		again.call())
	return card


# --- Abas de tipo --------------------------------------------------------------------------------

static func _type_tabs(model: Dictionary, again: Callable, width: float) -> Control:
	var row := UiKit.hbox(4)
	row.name = "BookTypes"
	row.custom_minimum_size = Vector2(width, TYPES_H)
	for id: String in _types():
		var picked := id == str(model.book_type) and (model.book_pot as Array).is_empty()
		var tab := _panel(_box(Color("ffcf6b") if picked else Color("f1e1c7"), Palette.HONEY_EDGE if picked else LINE, 14, 2 if picked else 1, Vector4(2, 2, 2, 2)), "BookType_" + id)
		tab.custom_minimum_size = Vector2(0, TYPES_H)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var content := UiKit.vbox(0)
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_child(_small_pic(str(DishRules.type_def(id).get("icon_item", "")), 22.0))
		var title := _t(str(DishRules.type_def(id).name), 10)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(title)
		var progress := type_progress(id)
		var count := _t("%d/%d" % [progress.x, progress.y], 10, MUTED)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(count)
		tab.add_child(content)
		_ignore(tab)
		_tap(tab, func() -> void:
			model["book_type"] = id
			model["book_pot"] = []
			model["book_filter"] = "all"
			_reset_grid(model)
			again.call())
		row.add_child(tab)
	return row


# --- Panela --------------------------------------------------------------------------------------

static func _pot(model: Dictionary, again: Callable) -> Control:
	var selected: Array = model.book_pot
	var full := not selected.is_empty()
	var pot := _panel(_box(Color("fff3d6") if full else Color("fbf3e3"), Palette.HONEY_EDGE if full else LINE, 16, 2, Vector4(8, 0, 8, 0)), "BookPot")
	pot.custom_minimum_size = Vector2(0, POT_H if full else POT_EMPTY_H)
	var row := UiKit.hbox(6)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	pot.add_child(row)
	var pan := UiKit.icon(UiKit.ui_icon("station_stove"), 28 if full else 22)
	pan.modulate.a = 1.0 if full else 0.6
	pan.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(pan)
	if not full:
		var hint := _t("Panela vazia: toque nos ingredientes lá embaixo", 11, MUTED, true)
		hint.name = "PotHint"
		hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(hint)
		return pot
	for id: String in selected:
		var slot := Control.new()
		slot.name = "BookPotItem_" + id
		slot.custom_minimum_size = Vector2(44, 44)
		slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var ring := _ring(DishRules.main_item(id), 38.0, Palette.HONEY, false, 28.0)
		ring.position = Vector2(3, 3)
		slot.add_child(ring)
		var badge := Panel.new()
		badge.add_theme_stylebox_override("panel", _box(Color("c0573f"), Color("ffffff"), 8, 1, Vector4.ZERO))
		badge.size = Vector2(16, 16)
		badge.custom_minimum_size = Vector2(16, 16)
		badge.position = Vector2(26, 2)
		var x := _t("×", 12, Color.WHITE)
		x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		x.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_child(x)
		x.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		slot.add_child(badge)
		_ignore(slot)
		_tap(slot, func() -> void:
			(model.book_pot as Array).erase(id)
			_reset_grid(model)
			again.call())
		row.add_child(slot)
	var note := _t("pratos com isso ↓", 12, MUTED, true)
	note.name = "PotNote"
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(note)
	return pot


# --- Filtros -------------------------------------------------------------------------------------

static func _filters(model: Dictionary, again: Callable, list: Array[Dictionary]) -> Control:
	var counts := {
		"all": list.size(),
		"can": list.filter(func(e: Dictionary) -> bool: return int(e.missing) == 0).size(),
		"new": list.filter(func(e: Dictionary) -> bool: return not bool(e.known)).size(),
	}
	var row := UiKit.hbox(5)
	row.name = "BookFilters"
	row.custom_minimum_size = Vector2(0, FILTERS_H)
	for option: Dictionary in FILTERS:
		var id := str(option.id)
		var picked := id == str(model.book_filter)
		var hit := Control.new()
		hit.name = "BookFilter_" + id
		hit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hit.custom_minimum_size = Vector2(0, FILTERS_H)
		var chip := _panel(_box(Color("ffcf6b") if picked else Color("f1e1c7"), Palette.HONEY_EDGE if picked else LINE, 16, 2 if picked else 1, Vector4(8, 2, 8, 2)))
		chip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		chip.offset_top = 5.0
		chip.offset_bottom = -5.0
		hit.add_child(chip)
		var label := _t("%s %d" % [option.text, int(counts[id])], 12)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.add_child(label)
		_ignore(hit)
		_tap(hit, func() -> void:
			model["book_filter"] = id
			_reset_grid(model)
			again.call())
		row.add_child(hit)
	return row


# --- Grade de pratos -----------------------------------------------------------------------------

## Maior fonte (11 a 8 px) em que todos os nomes da grade cabem em 2 linhas: a mesma para todos os cartões.
static func _names_px(shown: Array[Dictionary], width: float) -> int:
	for px: int in [11, 10, 9, 8]:
		var font := HomeUi.theme(px).default_font
		var fits := true
		for entry: Dictionary in shown:
			var text := str(entry.name) if bool(entry.known) else "%s nova" % str(DishRules.type_def(str(entry.type)).name)
			var paragraph := TextParagraph.new()
			paragraph.add_string(text, font, px)
			paragraph.width = width
			var widest := 0.0
			for word: String in text.split(" "):
				widest = maxf(widest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x)
			if paragraph.get_line_count() > 2 or widest > width:
				fits = false
				break
		if fits:
			return px
	return 8


static func _grid(model: Dictionary, again: Callable, shown: Array[Dictionary], selected: Array, type_id: String, size: Vector2) -> Control:
	var width := size.x
	var height := grid_height(size.y, (model.book_pot as Array).is_empty())
	var column := width - GUTTER
	var card_w := floorf((column - GAP * (COLS - 1)) / COLS)
	var holder := VBoxContainer.new()
	holder.name = "BookGridBox"
	holder.add_theme_constant_override("separation", 6)
	holder.custom_minimum_size.x = column
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	var grid := GridContainer.new()
	grid.name = "BookGrid"
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", int(GAP))
	grid.add_theme_constant_override("v_separation", int(GAP))
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	holder.add_child(grid)
	var name_px := _names_px(shown, card_w - CARD_PAD * 2.0)
	for entry: Dictionary in shown:
		grid.add_child(_dish_card(entry, card_w, name_px, model, again))
	if shown.is_empty():
		var empty := _t("Nada com isso ainda.
Que tal inventar?" if not selected.is_empty() else "Nada por aqui ainda.", 13, MUTED, true)
		empty.name = "BookEmpty"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.custom_minimum_size = Vector2(column, 60)
		holder.add_child(empty)
	var more := invent_count(selected, type_id)
	if more > 0:
		var note := _t("+%d combinações para inventar" % more, 12, MUTED, true)
		note.name = "BookInventNote"
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		holder.add_child(note)
	var strip := _secret_strip(model, again)
	if strip != null:
		holder.add_child(strip)
	var area := SellUi.scrolled(holder, width, height, true, model.book_grid, "BookScroll", "BookBar", GUTTER)
	area.name = "BookGridArea"
	area.custom_minimum_size = Vector2(width, height)
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return area


static func _dish_card(entry: Dictionary, width: float, name_px: int, model: Dictionary, again: Callable) -> Control:
	var known := bool(entry.known)
	var can := int(entry.missing) == 0
	var level := int(entry.level)
	var color := RING_COLORS[clampi(level, 0, 3)] if known else Color("d8c7a8")
	var card := _panel(_box(CAN_SOFT if can else PAPER, CAN if can else Color("e5cda6"), 14, 2 if can else 1, Vector4(CARD_PAD, CARD_PAD, CARD_PAD, CARD_PAD)),
		"BookDish_" + str(entry.key).replace(":", "_"))
	card.custom_minimum_size = Vector2(width, CARD_H)
	card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	card.set_meta("known", known)
	card.set_meta("can", can)
	var inner_w := width - CARD_PAD * 2.0
	var layer := Control.new()
	layer.custom_minimum_size = Vector2(inner_w, CARD_H - CARD_PAD * 2.0)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(layer)
	var column := UiKit.vbox(2)
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	layer.add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_child(_ring(str(entry.item), 44.0, color, not known, 32.0))
	var label_text := str(entry.name) if known else "%s nova" % str(DishRules.type_def(str(entry.type)).name)
	var label := _t(label_text, name_px, Palette.WOOD_INK, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(inner_w, float(name_px + 4) * 2.0)
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label.max_lines_visible = 2
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(label)
	var bottom := _pips(level, color) if known else _hint_row(entry)
	bottom.custom_minimum_size = Vector2(inner_w, 16.0)
	column.add_child(bottom)
	if can:
		var tick := Panel.new()
		tick.name = "CanTick"
		tick.add_theme_stylebox_override("panel", _box(CAN, Color.WHITE, 9, 1, Vector4.ZERO))
		tick.size = Vector2(18, 18)
		tick.custom_minimum_size = Vector2(18, 18)
		tick.position = Vector2(inner_w - 18.0, 0.0)
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var check := UiKit.ctl("check", 12, Color.WHITE)
		check.position = Vector2(3, 3)
		check.size = Vector2(12, 12)
		tick.add_child(check)
		layer.add_child(tick)
	_ignore(card)
	_tap(card, func() -> void:
		model["book_dish"] = str(entry.key)
		model["book_panel"] = "dish"
		again.call())
	return card


## Pista do prato "?": o primeiro ingrediente quando o Faro de cozinha está ativo; senão "? + ?".
static func _hint_row(entry: Dictionary) -> Control:
	var row := UiKit.hbox(3)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.name = "DishHint"
	var ingredients: Array = entry.ingredients
	if GameState.chef_skill("sniff") and not ingredients.is_empty():
		row.add_child(_small_pic(DishRules.main_item(str(ingredients[0])), 16.0))
		var plus := _t("+ ?", 11, MUTED)
		plus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(plus)
	else:
		var unknown := _t("? + ?", 11, MUTED)
		unknown.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(unknown)
	return row


# --- Secreta -------------------------------------------------------------------------------------

static func _secret_strip(model: Dictionary, again: Callable) -> Control:
	var secrets: Array = []
	for id: String in Database.recipe_book.secrets:
		secrets.append(GameState.recipe_secret(id))
	if secrets.is_empty():
		return null
	var pending: Dictionary = secrets[0]
	for secret: Dictionary in secrets:
		if secret.state in ["pista", "desconhecida"]:
			pending = secret
			break
	var total := (Database.recipe_book.secrets[str(pending.id)].pieces as Array).size()
	var strip := _panel(_box(Color("f1e1c7"), LINE, 12, 1, Vector4(8, 4, 8, 4)), "BookSecret")
	strip.custom_minimum_size = Vector2(0, 44)
	var row := UiKit.hbox(8)
	strip.add_child(row)
	var icon := UiKit.icon(UiKit.ui_icon("item_map_piece"), 26)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(icon)
	var text := _t("Receita secreta · páginas %d/%d ›" % [(pending.pieces as Array).size(), total], 12, Palette.WOOD_INK, true)
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(text)
	_ignore(strip)
	_tap(strip, func() -> void:
		model["book_panel"] = "secret"
		again.call())
	return strip


# --- Barra de ingredientes -----------------------------------------------------------------------

## Esmaecido na ponta da barra de rolagem lateral (some quando não há mais nada para aquele lado).
static func _fade(left: bool, color: Color) -> TextureRect:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([Color(color, 1.0 if left else 0.0), Color(color, 0.0 if left else 1.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(1, 0)
	texture.width = 16
	texture.height = 4
	var rect := TextureRect.new()
	rect.name = "FadeLeft" if left else "FadeRight"
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.anchor_left = 0.0 if left else 1.0
	rect.anchor_right = 0.0 if left else 1.0
	rect.anchor_bottom = 1.0
	rect.offset_left = 0.0 if left else -16.0
	rect.offset_right = 16.0 if left else 0.0
	return rect


static func _ingredient_bar(model: Dictionary, again: Callable, width: float) -> Control:
	var tray_color := Color("e9d2ac")
	var tray := _panel(_box(tray_color, Color("8a5a32"), 12, 2, Vector4(8, 3, 8, 4)), "BookIngredients")
	tray.custom_minimum_size = Vector2(width, BAR_H)
	var inner := width - 16.0 - 4.0  # margens da bandeja + borda
	var column := UiKit.vbox(2)
	tray.add_child(column)
	var title := UiKit.hbox(6)
	var heading := _t("Meus ingredientes", 12)
	heading.name = "BarTitle"
	title.add_child(heading)
	var hint_text := "toque para pôr na panela"
	var hint_px := 11
	var font := HomeUi.theme(hint_px).default_font
	var needed := HomeUi.theme(12).default_font.get_string_size("Meus ingredientes", HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 12.0 + font.get_string_size(hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, hint_px).x
	if needed <= inner:
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.add_child(spacer)
		title.add_child(_t(hint_text, hint_px, MUTED))
	column.add_child(title)
	var holder := Control.new()
	holder.name = "BookIngredientBox"
	holder.custom_minimum_size = Vector2(inner, 44)
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.clip_contents = true
	column.add_child(holder)
	var scroll := ScrollContainer.new()
	scroll.name = "BookIngredientScroll"
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	holder.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Quadradinhos inteiros: cabem n deles com folgas iguais; o resto rola, com esmaecido na ponta.
	var count := maxi(1, int(floorf((inner + 4.0) / (TILE_W + 4.0))))
	var gap := (inner - count * TILE_W) / float(count - 1) if count > 1 else 0.0
	var row := UiKit.hbox(int(floorf(gap)))
	row.add_theme_constant_override("separation", roundi(gap))
	scroll.add_child(row)
	var selected: Array = model.book_pot
	for id: String in _shown_ingredients():
		var stock := GameState.recipe_ingredient_stock(id)
		var picked := id in selected
		var tile := _panel(_box(Color("ffcf6b") if picked else PAPER, Palette.HONEY_EDGE if picked else LINE, 10, 2 if picked else 1, Vector4(2, 2, 2, 1)), "BookIngredient_" + id)
		tile.custom_minimum_size = Vector2(TILE_W, 44)
		tile.modulate.a = 0.45 if stock == 0 and not picked else 1.0
		var content := UiKit.vbox(0)
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_child(_small_pic(DishRules.main_item(id), 24.0))
		var amount := _t(str(stock), 11, MUTED)
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(amount)
		tile.add_child(content)
		_ignore(tile)
		_tap(tile, func() -> void:
			var pot: Array = model.book_pot
			if id in pot:
				pot.erase(id)
			elif pot.size() < POT_MAX:
				pot.append(id)
			model["book_filter"] = "all"
			_reset_grid(model)
			again.call())
		row.add_child(tile)
	var left := _fade(true, tray_color)
	var right := _fade(false, tray_color)
	holder.add_child(left)
	holder.add_child(right)
	var bar := scroll.get_h_scroll_bar()
	var sync := func() -> void:
		if not is_instance_valid(scroll):
			return
		left.visible = bar.value > 1.0
		right.visible = bar.value + bar.page < bar.max_value - 1.0
	bar.changed.connect(sync)
	bar.value_changed.connect(func(value: float) -> void:
		model["book_bar"] = int(value)
		sync.call())
	var restore := func() -> void:
		var tree := Engine.get_main_loop() as SceneTree
		await tree.process_frame
		await tree.process_frame
		if is_instance_valid(scroll):
			scroll.scroll_horizontal = int(model.book_bar)
			sync.call()
	left.visible = false
	right.visible = false
	restore.call()
	return tray


# --- Painéis de baixo ----------------------------------------------------------------------------

static func _open_panel(root: Control, model: Dictionary, again: Callable, size: Vector2, kind: String) -> void:
	var dim := ColorRect.new()
	dim.name = "BookDim"
	dim.color = Color(0.24, 0.14, 0.04, 0.42)
	dim.size = size
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_tap(dim, _close.bind(model, again))
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	var sheet := PanelContainer.new()
	sheet.add_theme_stylebox_override("panel", _sheet_style())
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	var content: Control
	match kind:
		"chef":
			sheet.name = "ChefPath"
			content = _chef_path(model, again, size)
		"secret":
			sheet.name = "BookSecretSheet"
			content = _secret_sheet(model, again, size)
		_:
			sheet.name = "BookDishSheet"
			content = _dish_sheet(model, again, size)
	sheet.add_child(content)
	sheet.custom_minimum_size.x = size.x
	sheet.size.x = size.x
	root.add_child(sheet)
	# Cola no pé do corpo: a altura vem do conteúdo (mínimo calculado no próximo quadro).
	var place := func() -> void:
		if not is_instance_valid(sheet):
			return
		sheet.size = Vector2(size.x, _sheet_room(size))  # sempre a mesma altura: cobre a Panela, os filtros, a grade e a barra de forma limpa
		sheet.position = Vector2(0, size.y - sheet.size.y)
	place.call()
	sheet.resized.connect(place)
	place.call_deferred()


## Altura máxima do painel de baixo: começa logo abaixo do cartão do cozinheiro e das abas (cobre o resto de forma limpa).
static func _sheet_room(size: Vector2) -> float:
	return size.y - (CHEF_H + TYPES_H + SEP * 2.0)


static func _sheet_style() -> StyleBoxFlat:
	var style := _box(PAPER, Color("8a5a32"), 20, 3, Vector4(12, 10, 12, 10))
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	return style


static func _handle(model: Dictionary, again: Callable) -> Control:
	var bar := Panel.new()
	bar.custom_minimum_size = Vector2(44, 6)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("panel", _box(LINE, LINE, 3, 0, Vector4.ZERO))
	bar.name = "BookHandle"
	return bar


# --- Painel do prato ---------------------------------------------------------------------------

static func _level_gain(index: int) -> String:
	var rows: Array = Database.recipe_book.mastery
	var row: Dictionary = rows[index]
	var before: Dictionary = rows[index - 1]
	var parts: Array[String] = []
	if int(row.stars) > int(before.stars):
		parts.append("%d estrelas" % int(row.stars))
	if float(row.time) < float(before.time):
		parts.append("%d%% menos tempo" % roundi((1.0 - float(row.time)) * 100.0))
	if int(row.get("gift_every", 0)) > 0 and int(row.get("gift_every", 0)) != int(before.get("gift_every", 0)):
		parts.append("porção extra a cada %d" % int(row.gift_every))
	if float(row.get("gesture_scale", 1.0)) > float(before.get("gesture_scale", 1.0)):
		parts.append("Cozinhar junto mais fácil")
	return ", ".join(parts)


static func _dish_sheet(model: Dictionary, again: Callable, size: Vector2) -> Control:
	var entry := find_entry(str(model.book_dish))
	var column := UiKit.vbox(8)
	column.add_child(_handle(model, again))
	if entry.is_empty():
		column.add_child(_t("Prato não encontrado.", 14, MUTED))
		return column
	var known := bool(entry.known)
	var can := int(entry.missing) == 0
	var level := int(entry.level)
	var key := str(entry.key)
	var head := UiKit.hbox(10)
	head.add_child(_ring(str(entry.item), 76.0, RING_COLORS[clampi(level, 0, 3)] if known else Color("d8c7a8"), not known, 48.0))
	var text := UiKit.vbox(2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var name := _t(str(entry.name) if known else "%s ainda não feita" % str(DishRules.type_def(str(entry.type)).name), 17, Palette.WOOD_INK, true)
	name.name = "BookDishName"
	text.add_child(name)
	var taste := _t(_taste_line(entry) if known else "Descubra no Inventar", 12, MUTED, true)
	taste.name = "BookDishTaste"
	text.add_child(taste)
	head.add_child(text)
	column.add_child(head)
	if known:
		column.add_child(_levels(key, level, size.x - 24.0))
	column.add_child(_need_row(entry, known, model, again))
	var actions := UiKit.hbox(8)
	actions.name = "BookActions"
	if can:
		if known:
			actions.add_child(_button("Cozinhar junto", true, "BookCookTogether", open_kitchen.bind("together:" + key)))
			actions.add_child(_button("Pôr na fila", false, "BookQueue", _queue.bind(entry)))
		else:
			actions.add_child(_button("Inventar", true, "BookInvent", open_kitchen.bind("invent")))
	else:
		if not known:
			actions.add_child(_button("Inventar", true, "BookInvent", open_kitchen.bind("invent")))
		actions.add_child(_button("Buscar o que falta", false, "BookFetch", _fetch.bind(entry)))
	column.add_child(actions)
	return column


static func _taste_line(entry: Dictionary) -> String:
	var taste := str(Database.dishes.tastes.get(DishRules.taste(entry.ingredients), ""))
	var tasted := str(GameState.week.recipe_book.get("tasted", {}).get(GameState._book_taste_key(str(entry.key)), ""))
	var reaction := GameState.taste_line(tasted) if tasted != "" else ""
	return "%s · %s" % [taste, reaction] if reaction != "" else taste


static func _levels(key: String, level: int, width: float) -> Control:
	var rows: Array = Database.recipe_book.mastery
	var box := UiKit.vbox(3)
	box.name = "BookLevels"
	var bars := UiKit.hbox(4)
	for i in rows.size():
		var segment := Panel.new()
		segment.custom_minimum_size = Vector2(0, 10)
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.add_theme_stylebox_override("panel", _box(RING_COLORS[i] if i <= level else Color("e5cda6"), Color("c9a974") if i <= level else Color("e5cda6"), 5, 1, Vector4.ZERO))
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bars.add_child(segment)
	box.add_child(bars)
	var names := UiKit.hbox(4)
	var segment := (width - 4.0 * (rows.size() - 1)) / rows.size()
	var level_px := 10
	for candidate: int in [10, 9, 8]:
		level_px = candidate
		var widest := 0.0
		for row: Dictionary in rows:
			widest = maxf(widest, HomeUi.theme(candidate).default_font.get_string_size(str(row.name), HORIZONTAL_ALIGNMENT_LEFT, -1, candidate).x)
		if widest <= segment - 2.0:
			break
	for i in rows.size():
		var label := _t(str(rows[i].name), level_px, Palette.WOOD_INK if i == level else MUTED)
		label.custom_minimum_size.x = segment
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.theme = HomeUi.theme(level_px, Palette.WOOD_INK if i == level else MUTED)
		label.name = "LevelName_%d" % i
		if i == level:
			label.set_meta("current", true)
		names.add_child(label)
	box.add_child(names)
	var mastery := GameState.recipe_mastery(key)
	var next := int(mastery.next)
	var line := "Nível máximo: Especialidade!"
	if next > 0:
		var left := next - int(mastery.score)
		line = "mais %d %s → %s: %s" % [left, "preparo" if left == 1 else "preparos", str(rows[level + 1].name), _level_gain(level + 1)]
	var note := _t(line, 12, MUTED, true)
	note.name = "BookNextLevel"
	box.add_child(note)
	return box


static func _need_row(entry: Dictionary, known: bool, model: Dictionary, again: Callable) -> Control:
	var row := UiKit.hbox(8)
	row.name = "BookNeeds"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var ingredients: Array = entry.ingredients
	var seen := {}
	var distinct: Array[String] = []
	for id: String in ingredients:
		if not seen.has(id):
			seen[id] = true
			distinct.append(id)
	var sniff := GameState.chef_skill("sniff")
	for index in distinct.size():
		var id := distinct[index]
		var need := ingredients.count(id)
		var stock := GameState.recipe_ingredient_stock(id)
		var visible := known or (sniff and index == 0)
		var good := stock >= need
		var tile := _panel(_box(HAVE if good else NEED, Color("9ccf94") if good else Color("e0a96b"), 12, 2, Vector4(4, 4, 4, 4)), "BookNeed_" + id if visible else "BookNeedHidden_%d" % index)
		tile.custom_minimum_size = Vector2(84, 96)
		var content := UiKit.vbox(2)
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		if visible:
			var picture := _pic(DishRules.main_item(id), 48.0)
			picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			content.add_child(picture)
			var label := _t(str(DishRules.ingredient(id).name), 12)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			content.add_child(label)
			var count := _t("%d / %d" % [stock, need], 12, Palette.GO_INK if good else Palette.HONEY_INK)
			count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			content.add_child(count)
		else:
			var mark := _t("?", 38, Color("a08868"))
			mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			mark.custom_minimum_size.y = 48
			content.add_child(mark)
			var hidden_label := _t("descubra", 12, MUTED)
			hidden_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			content.add_child(hidden_label)
		tile.add_child(content)
		_ignore(tile)
		if visible:
			_tap(tile, func() -> void:
				model["book_pot"] = [id]
				model["book_filter"] = "all"
				model["book_panel"] = ""
				_reset_grid(model)
				again.call())
		row.add_child(tile)
		if index < distinct.size() - 1:
			var plus := _t("+", 20, MUTED)
			plus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(plus)
	return row


static func _queue(entry: Dictionary) -> void:
	var recipe := str(entry.get("recipe", ""))
	var error := GameState.cook_known_dish(str(entry.key)) if recipe == "" else GameState.cook(recipe)
	Events.toast_requested.emit("Prato na fila!" if error == "" else error)


## Leva à origem do primeiro ingrediente que falta (ou explica de onde vem).
static func _fetch(entry: Dictionary) -> void:
	var inputs: Dictionary = entry.inputs
	for item: String in inputs:
		if GameState.inventory.count(item) >= int(inputs[item]):
			continue
		var ingredient := DishRules.ingredient_of_item(item)
		var origin: Dictionary = Database.recipe_book.ingredients.get(ingredient, {})
		if not origin.is_empty():
			Places.go(origin.go)
		else:
			TaskHelp.open("item", item)
		return


# --- Caminho do cozinheiro -----------------------------------------------------------------------

## Anel tracejado do próximo nível.
class DashRing extends Control:
	var color := Palette.HONEY_EDGE

	func _draw() -> void:
		var center := size / 2.0
		var radius := minf(size.x, size.y) / 2.0 - 2.0
		var dashes := 16
		for i in dashes:
			var from := TAU * float(i) / dashes
			draw_arc(center, radius, from, from + TAU / dashes * 0.55, 6, color, 2.5, true)


static func _chef_path(model: Dictionary, again: Callable, size: Vector2) -> Control:
	var chef := GameState.chef_info()
	var rows: Array = GameState.chef_levels()
	var level := int(chef.level)
	var column := UiKit.vbox(6)
	column.add_child(_handle(model, again))
	var title := _t("Nível: %s" % str(chef.name), 17)
	title.name = "ChefTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var how := _t("%d pontos · +1 por prato, +2 por prato novo e as estrelas do Cozinhar junto" % int(chef.score), 12, MUTED, true)
	how.name = "ChefHow"
	how.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(how)
	var list := UiKit.vbox(0)
	list.name = "ChefLevels"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.custom_minimum_size.x = size.x - 24.0
	for i in rows.size():
		list.add_child(_chef_row(rows, i, level, int(chef.score), i < rows.size() - 1))
	var scroll := ScrollContainer.new()
	scroll.name = "ChefScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	var room := _sheet_room(size) - 130.0
	scroll.custom_minimum_size = Vector2(size.x - 24.0, minf(room, 9.0 * 62.0))
	scroll.add_child(list)
	column.add_child(scroll)
	return column


static func _chef_row(rows: Array, index: int, level: int, score: int, connect: bool) -> Control:
	var row: Dictionary = rows[index]
	var skill: Dictionary = row.skill
	var got := index <= level
	var next := index == level + 1
	var holder := HBoxContainer.new()
	holder.name = "ChefSkill_" + str(skill.id)
	holder.add_theme_constant_override("separation", 10)
	holder.custom_minimum_size = Vector2(0, 62)
	holder.set_meta("state", "got" if got else ("next" if next else "locked"))
	holder.modulate.a = 1.0 if got or next else 0.6
	var badge_box := Control.new()
	badge_box.custom_minimum_size = Vector2(48, 62)
	badge_box.size_flags_vertical = Control.SIZE_FILL
	# A linha liga os círculos por trás deles, centrada: meia linha em cima e meia embaixo.
	for half: int in [0, 1]:
		if (half == 0 and index == 0) or (half == 1 and not connect):
			continue
		var line := ColorRect.new()
		line.color = Palette.HONEY if (got if half == 0 else index + 1 <= level) else Color("e5cda6")
		line.anchor_left = 0.5
		line.anchor_right = 0.5
		line.anchor_top = 0.0 if half == 0 else 0.5
		line.anchor_bottom = 0.5 if half == 0 else 1.0
		line.offset_left = -2.0
		line.offset_right = 2.0
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_box.add_child(line)
	var disc := _panel(_box(Palette.HONEY if got else (Color("fff3d6") if next else Color("efe6d8")), Palette.HONEY_EDGE if got else Color("efe6d8"), 22, 2 if got else 0, Vector4.ZERO))
	disc.anchor_left = 0.5
	disc.anchor_right = 0.5
	disc.anchor_top = 0.5
	disc.anchor_bottom = 0.5
	disc.offset_left = -22.0
	disc.offset_right = 22.0
	disc.offset_top = -22.0
	disc.offset_bottom = 22.0
	var picture: Control
	if got or next:
		var icon := TextureRect.new()
		icon.texture = UiKit.ui_icon(str(skill.icon))
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.custom_minimum_size = Vector2(32, 32)
		picture = icon
	else:
		picture = UiKit.ctl("lock", 20, Palette.INK_SOFT)
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	disc.add_child(picture)
	badge_box.add_child(disc)
	if next:
		var ring := DashRing.new()
		ring.anchor_left = 0.5
		ring.anchor_right = 0.5
		ring.anchor_top = 0.5
		ring.anchor_bottom = 0.5
		ring.offset_left = -24.0
		ring.offset_right = 24.0
		ring.offset_top = -24.0
		ring.offset_bottom = 24.0
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_box.add_child(ring)
	holder.add_child(badge_box)
	var text := UiKit.vbox(1)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var name := _t(str(skill.name), 13, Palette.WOOD_INK, true)
	text.add_child(name)
	text.add_child(_t(str(skill.text), 11, MUTED, true))
	# O selo (nível ganho ou pontos que faltam) fica em linha própria, sem encostar no nome.
	var tag := _t("✓ %s" % str(row.name) if got else "%d pts" % int(row.points), 11, Palette.GO_INK if got else MUTED, true)
	tag.name = "ChefTag"
	text.add_child(tag)
	if next:
		var base := int(rows[index - 1].points)
		var bar := UiKit.bar(100.0 * float(score - base) / float(maxi(1, int(row.points) - base)), Palette.HONEY, 6)
		bar.name = "ChefNextBar"
		text.add_child(bar)
	holder.add_child(text)
	_ignore(holder)
	return holder


# --- Receitas secretas ---------------------------------------------------------------------------

static func _secret_sheet(model: Dictionary, again: Callable, size: Vector2) -> Control:
	var column := UiKit.vbox(6)
	column.add_child(_handle(model, again))
	var title := _t("Receitas secretas", 17)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var list := UiKit.vbox(6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.custom_minimum_size.x = size.x - 24.0
	for id: String in Database.recipe_book.secrets:
		list.add_child(_secret_card(GameState.recipe_secret(id), model, again))
	var scroll := ScrollContainer.new()
	scroll.name = "SecretScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.custom_minimum_size = Vector2(size.x - 24.0, minf(_sheet_room(size) - 90.0, 4.0 * 108.0))
	scroll.add_child(list)
	column.add_child(scroll)
	return column


static func _secret_card(secret: Dictionary, model: Dictionary, again: Callable) -> Control:
	var card := UiKit.vbox(3)
	var panel := _panel(_box(CREAM, LINE, 12, 1, Vector4(9, 7, 9, 7)), "BookSecret_" + str(secret.id))
	panel.add_child(card)
	var header := UiKit.hbox(6)
	var name := _t(str(secret.name), 14)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name)
	var pieces: Array = secret.pieces
	var total := (Database.recipe_book.secrets[str(secret.id)].pieces as Array).size()
	for i in total:
		var piece := UiKit.icon(UiKit.ui_icon("item_map_piece"), 18)
		piece.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		piece.modulate.a = 1.0 if i in pieces else 0.24
		header.add_child(piece)
	card.add_child(header)
	card.add_child(_t("%d/%d páginas" % [pieces.size(), total], 12, MUTED))
	var waiting: bool = secret.state in ["pista", "desconhecida"]
	if not waiting:
		var see := _button("Ver receita", false, "SecretSee_" + str(secret.id), func() -> void:
			model["book_dish"] = str(secret.key)
			model["book_panel"] = "dish"
			again.call())
		card.add_child(see)
	if not (secret.revealed as Array).is_empty() and waiting:
		var names: Array[String] = []
		for id: String in secret.revealed:
			names.append(str(DishRules.ingredient(id).name))
		card.add_child(_t("Ingredientes da pista · " + ", ".join(names), 12, Palette.WOOD_INK, true))
	var hint: Dictionary = secret.hint
	if bool(secret.hinted):
		card.add_child(_t("“%s”" % str(hint.text), 12, Palette.WOOD_INK, true))
	elif waiting:
		card.add_child(_destination(str(hint.label), hint.go))
	var next: Dictionary = secret.next
	if not next.is_empty():
		card.add_child(_t("Próxima página · faltam %d" % int(next.left), 12, MUTED, true))
		card.add_child(_destination(str(next.label), next.go))
	return panel


static func _destination(title: String, target: Dictionary) -> Control:
	var row := UiKit.hbox(8)
	var label := _t(title, 12, Palette.WOOD_INK, true)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	var go := StepCardUi.go_button("Ir", Places.go.bind(target))
	go.size_flags_horizontal = Control.SIZE_SHRINK_END
	go.custom_minimum_size.x = 64.0
	row.add_child(go)
	return row


static func open_kitchen(focus: String) -> void:
	Places.go({"world": "house", "place": "cookbook:" + focus})
