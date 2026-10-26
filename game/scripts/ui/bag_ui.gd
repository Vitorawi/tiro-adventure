class_name BagUi
extends RefCounted
## Peças da Mochila "madeira ilustrada": cartão do depósito, tábua dos filtros e quadrado do item.
## As imagens ficam em `assets/sprites/ui/home/bag_*.png` (geradas por `tools/bag_art.gd`, ~3x o tamanho final);
## as molduras são NinePatchRect em escala 1/3, então sempre moram num Control comum (nunca direto num container).

## Ícone ilustrado de cada depósito e de cada filtro (`bag_icon_<id>.png`); o resto cai no ícone pixel do jogo.
const ICONS := ["fridge", "chest", "silo", "warehouse", "all", "food", "crop", "material", "product", "find", "trail", "keepsake"]


static func tex(file: String) -> Texture2D:
	return load(HomeUi.DIR + "bag_" + file + ".png") as Texture2D


static func icon(id: String) -> Texture2D:
	return tex("icon_" + id) if id in ICONS else null


## Moldura NinePatch que acompanha o tamanho de `host`. `margins` (esquerda, cima, direita, baixo) em pixels finais;
## `inset` encolhe/expande a área ocupada (positivo = para dentro).
static func frame(host: Control, file: String, margins: Vector4, node_name: String = "", inset: Vector4 = Vector4.ZERO) -> NinePatchRect:
	var result := NinePatchRect.new()
	result.texture = tex(file)
	result.patch_margin_left = roundi(margins.x * 3.0)
	result.patch_margin_top = roundi(margins.y * 3.0)
	result.patch_margin_right = roundi(margins.z * 3.0)
	result.patch_margin_bottom = roundi(margins.w * 3.0)
	result.scale = Vector2.ONE / 3.0
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if node_name != "":
		result.name = node_name
	host.add_child(result)
	var fit := func() -> void:
		result.position = Vector2(inset.x, inset.y)
		result.size = (host.size - Vector2(inset.x + inset.z, inset.y + inset.w)).max(Vector2.ONE) * 3.0
	host.resized.connect(fit)
	fit.call()
	return result


## Botão sem visual próprio (o desenho vem dos filhos), com o apertar de sempre.
static func plain_button(on_pressed: Callable) -> Button:
	var result := UiKit.button("", on_pressed, &"GhostButton")
	for phase: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		result.add_theme_stylebox_override(phase, StyleBoxEmpty.new())
	return result


static func _label(value: String, px: int, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var result := Label.new()
	result.text = value
	result.theme = HomeUi.theme(px)
	result.horizontal_alignment = align
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


## Título de seção sobre o creme ("Depósitos", "Mochila").
static func title(value: String) -> Label:
	var result := _label(value, 19)
	result.custom_minimum_size = Vector2(0, 26)
	return result


## Cartão do depósito: moldura de madeira, ícone ilustrado num fundo afundado, nome, n/m e barra.
## Acima do limite (estoque que já existia) o número fica vermelho; nada some.
static func depot_card(id: String, fallback: Texture2D, caption: String, used: int, capacity: int, selected: bool, on_pressed: Callable) -> Button:
	var result := plain_button(on_pressed)
	result.custom_minimum_size = Vector2(0, 62)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame(result, "depot", Vector4(10, 10, 10, 10))
	var art := tex("depot_" + id) if ResourceLoader.exists(HomeUi.DIR + "bag_depot_" + id + ".png") else null
	var picture := TextureRect.new()
	picture.name = "DepotIcon"
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if art != null:
		# Ícone já com o fundo afundado, recortado do quadro montado do protótipo.
		picture.texture = art
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		picture.position = Vector2(5, 6)
		picture.size = Vector2(56, 50)
	else:
		var inset := Panel.new()
		inset.add_theme_stylebox_override("panel", UiKit.surface(Palette.WOOD_INSET, 9))
		inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inset.position = Vector2(9, 9)
		inset.size = Vector2(44, 44)
		result.add_child(inset)
		picture.texture = fallback
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		picture.position = Vector2(12, 11)
		picture.size = Vector2(38, 40)
	result.add_child(picture)
	var words := Control.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_child(words)
	words.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	words.offset_left = 60.0
	words.offset_right = -9.0
	var name_label := _label(caption, 13)
	name_label.name = "DepotName"
	name_label.clip_text = true
	name_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	name_label.offset_top = 6.0
	name_label.offset_bottom = 23.0
	words.add_child(name_label)
	var amount := _label("%d/%d" % [used, capacity], 16)
	amount.name = "DepotAmount"
	if used > capacity:
		amount.theme = HomeUi.theme(16, Palette.ALERT_INK)
	amount.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	amount.offset_top = 21.0
	amount.offset_bottom = 41.0
	words.add_child(amount)
	var meter := Control.new()
	meter.name = "DepotBar"
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	meter.offset_top = 42.0
	meter.offset_bottom = 53.0
	words.add_child(meter)
	var track := HomeUi.bar(meter, "bar_track", Rect2(), 5, "Track")
	var fill := HomeUi.bar(meter, "bar_fill", Rect2(), 4, "Fill")
	var fraction := clampf(float(used) / maxi(1, capacity), 0.0, 1.0)
	if used >= capacity * 0.9:
		fill.modulate = Color(1.0, 0.55, 0.5)
	var fit := func() -> void:
		HomeUi.resize_bar(track, Vector2(meter.size.x, 11.0))
		fill.position = Vector2(1.0, 1.0)
		fill.visible = fraction > 0.0
		HomeUi.resize_bar(fill, Vector2(maxf((meter.size.x - 2.0) * fraction, 9.0), 9.0))
	meter.resized.connect(fit)
	fit.call()
	if selected:
		var ring := Panel.new()
		ring.name = "Selected"
		var style := StyleBoxFlat.new()
		style.draw_center = false
		style.border_color = Palette.WOOD_PICK
		style.set_border_width_all(3)
		style.set_corner_radius_all(14)
		ring.add_theme_stylebox_override("panel", style)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		result.add_child(ring)
		ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ring.offset_left = -2.0
		ring.offset_top = -2.0
		ring.offset_right = 2.0
		ring.offset_bottom = 2.0
	return result


## Quadrado do item: nome em cima (até duas linhas), ícone no meio, quantidade embaixo à direita e, se `fresh`,
## o selo vermelho no canto (nó `NewBadge`).
static func item_tile(caption: String, texture: Texture2D, quantity: int, fresh: bool, on_pressed: Callable) -> Button:
	var result := plain_button(on_pressed)
	result.custom_minimum_size = Vector2(0, 94)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.pressed.connect(func() -> void: Motion.bounce(result))
	frame(result, "tile", Vector4(11, 11, 11, 14))
	var name_label := _label(caption, 11)
	name_label.name = "ItemName"
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_constant_override("line_spacing", -4)
	name_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	name_label.offset_left = 5.0
	name_label.offset_right = -5.0
	name_label.offset_top = 5.0
	name_label.offset_bottom = 32.0
	result.add_child(name_label)
	var picture := TextureRect.new()
	picture.name = "Picture"
	picture.texture = texture
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_child(picture)
	picture.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	picture.offset_left = -20.0
	picture.offset_right = 20.0
	picture.offset_top = 33.0
	picture.offset_bottom = 73.0
	var amount := _label("×%d" % quantity, 15, HORIZONTAL_ALIGNMENT_RIGHT)
	amount.name = "Quantity"
	result.add_child(amount)
	amount.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	amount.offset_left = 4.0
	amount.offset_right = -9.0
	amount.offset_top = -30.0
	amount.offset_bottom = -12.0
	if fresh:
		var dot := TextureRect.new()
		dot.name = "NewBadge"
		dot.texture = tex("new")
		dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		result.add_child(dot)
		dot.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		dot.offset_left = -12.0
		dot.offset_right = 2.0
		dot.offset_top = -2.0
		dot.offset_bottom = 12.0
	return result


## Tábua dos filtros: folhas, flor e parafusos nas pontas; as categorias rolam de lado no miolo.
## `options` = [{id, text, icon}] (como `UiKit.segmented`); a escolhida vira pílula creme com ícone e nome.
static func filter_plank(options: Array[Dictionary], selected: String, on_pick: Callable) -> Dictionary:
	var result := Control.new()
	result.name = "BagPlank"
	result.custom_minimum_size = Vector2(0, PLANK_HEIGHT)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.mouse_filter = Control.MOUSE_FILTER_PASS
	frame(result, "plank", Vector4(32, 0, 40, 0), "Wood")  # de ponta a ponta da tela, encostando na moldura
	var scroll := ScrollContainer.new()
	scroll.name = "BagFilters"
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	result.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 34.0
	scroll.offset_right = -42.0
	scroll.offset_top = 22.0
	scroll.offset_bottom = -4.0
	var row := HBoxContainer.new()
	row.name = "Options"
	row.add_theme_constant_override("separation", 2)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(row)
	for entry: Dictionary in options:
		var id := str(entry.id)
		var button := plain_button(on_pick.bind(id))
		button.name = "NotebookTab_" + id  # mesmo nome do `UiKit.segmented` (testes e atalhos)
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var art := icon(id)
		var picture := TextureRect.new()
		picture.texture = art if art != null else entry.get("icon")
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if art == null else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		if id == selected:
			var words := str(entry.get("text", ""))
			var width := 34.0 + HomeUi.theme(14).default_font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 12.0
			button.custom_minimum_size = Vector2(width, 36)
			frame(button, "chip", Vector4(9, 9, 9, 9), "Chip", Vector4(0, 2, 0, 2))
			picture.position = Vector2(7, 7)
			picture.size = Vector2(22, 22)
			button.add_child(picture)
			var label := _label(words, 14, HORIZONTAL_ALIGNMENT_LEFT)
			label.position = Vector2(31, 0)
			label.size = Vector2(width - 34.0, 36)
			button.add_child(label)
		else:
			button.custom_minimum_size = Vector2(38, 36)
			picture.position = Vector2(4, 3)
			picture.size = Vector2(30, 30)
			button.add_child(picture)
		row.add_child(button)
	return {"plank": result, "scroll": scroll}


const PLANK_HEIGHT := 66.0
