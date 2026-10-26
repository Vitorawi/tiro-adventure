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


## Tábua dos filtros (só a madeira): as categorias se espalham pela tábua
## (rolam de lado só se não couberem). `options` = [{id, text, icon}] (como `UiKit.segmented`); a escolhida
## vira pílula creme ("Tudo" só com o nome, as outras com ícone + nome). Ícones e pílula com sombra na madeira.
static func filter_plank(options: Array[Dictionary], selected: String, on_pick: Callable) -> Dictionary:
	var result := Control.new()
	result.name = "BagPlank"
	result.custom_minimum_size = Vector2(0, PLANK_HEIGHT)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.mouse_filter = Control.MOUSE_FILTER_PASS
	frame(result, "plank", Vector4(14, 14, 14, 14), "Wood")
	var scroll := ScrollContainer.new()
	scroll.name = "BagFilters"
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	result.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 8.0
	scroll.offset_right = -8.0
	scroll.offset_top = 4.0
	scroll.offset_bottom = -6.0
	var row := HBoxContainer.new()
	row.name = "Options"
	row.add_theme_constant_override("separation", 0)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(row)
	for entry: Dictionary in options:
		var id := str(entry.id)
		var button := plain_button(on_pick.bind(id))
		button.name = "NotebookTab_" + id  # mesmo nome do `UiKit.segmented` (testes e atalhos)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var art := icon(id) if icon(id) != null else entry.get("icon") as Texture2D
		var pixel := icon(id) == null
		if id == selected:
			var words := str(entry.get("text", ""))
			# "Tudo" é só o nome; as outras viram pílula só com o ícone (as oito cabem na tábua de 360).
			var with_icon := id != "all"
			if with_icon:
				words = ""
			var text_width := HomeUi.theme(16).default_font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			var width := 42.0 if with_icon else text_width + 30.0
			button.custom_minimum_size = Vector2(width + 4.0, 44)
			var chip := Control.new()
			chip.name = "Chip"
			chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(chip)
			chip.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
			chip.offset_left = -width / 2.0
			chip.offset_right = width / 2.0
			chip.offset_top = -20.0
			chip.offset_bottom = 20.0
			var shadow := Panel.new()
			shadow.name = "ChipShadow"
			shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			shadow.add_theme_stylebox_override("panel", _soft_shadow(12))
			chip.add_child(shadow)
			shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			shadow.offset_left = 2.0
			shadow.offset_right = -2.0
			shadow.offset_top = 4.0
			shadow.offset_bottom = -2.0
			frame(chip, "chip", Vector4(10, 10, 10, 10))
			var left := 14.0
			if with_icon:
				_shadowed_icon(chip, art, Rect2(8, 6, 26, 26), pixel)
				left = 38.0
			var label := _label(words, 16, HORIZONTAL_ALIGNMENT_LEFT)
			label.position = Vector2(left, 0)
			label.size = Vector2(text_width + 4.0, 39)
			chip.add_child(label)
		else:
			button.custom_minimum_size = Vector2(32, 44)
			var holder := Control.new()
			holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(holder)
			holder.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
			holder.offset_left = -14.0
			holder.offset_right = 14.0
			holder.offset_top = -16.0
			holder.offset_bottom = 12.0
			_shadowed_icon(holder, art, Rect2(0, 0, 28, 28), pixel)
		row.add_child(button)
	return {"plank": result, "scroll": scroll}


const PLANK_HEIGHT := 56.0
static var _shadow_shader: Shader


## Ícone com sombra macia embaixo (silhueta escura, borrada, deslocada para baixo), como no protótipo.
static func _shadowed_icon(host: Control, texture: Texture2D, rect: Rect2, pixel: bool) -> TextureRect:
	if _shadow_shader == null:
		_shadow_shader = Shader.new()
		_shadow_shader.code = """shader_type canvas_item;
uniform vec4 tint : source_color = vec4(0.22, 0.1, 0.03, 0.55);
uniform float spread = 2.0;
void fragment() {
	vec2 step_uv = TEXTURE_PIXEL_SIZE * spread * 8.0;
	float a = 0.0;
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			a += texture(TEXTURE, UV + vec2(float(x), float(y)) * step_uv * 0.5).a;
		}
	}
	COLOR = vec4(tint.rgb, tint.a * a / 25.0);
}"""
	var shadow := TextureRect.new()
	shadow.name = "IconShadow"
	shadow.texture = texture
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = _shadow_shader
	material.set_shader_parameter("spread", 0.25 if pixel else 1.0)
	shadow.material = material
	shadow.position = rect.position + Vector2(1.5, 3.5)
	shadow.size = rect.size
	host.add_child(shadow)
	var picture := TextureRect.new()
	picture.name = "Picture"
	picture.texture = texture
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if pixel else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	picture.position = rect.position
	picture.size = rect.size
	host.add_child(picture)
	return picture


## Sombra macia de uma peça (só a sombra; o centro fica transparente).
static func _soft_shadow(radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.1, 0.03, 0.35)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.22, 0.1, 0.03, 0.3)
	style.shadow_size = 5
	return style
