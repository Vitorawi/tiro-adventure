class_name MissionUi
extends RefCounted
## Peças do grupo História da aba Missões no visual "madeira ilustrada": moldura de madeira, cartão do topo com
## retrato, etiqueta laranja e barra, quadradinhos de prêmio, pílulas e botões verde/laranja.
## As imagens ficam em `assets/sprites/ui/home/mission_*.png` (geradas por `tools/mission_art.gd`, ~3x o tamanho
## final): as molduras são NinePatchRect em escala 1/3, então moram sempre num Control comum (nunca direto num container).
## Medidas fixas (pixels finais): botão 104×44, pílula 104×24, quadradinho de passo 48×48, de prêmio 56×56.

const BUTTON := Vector2(104, 44)
const PILL := Vector2(104, 24)
## Janela do retrato dentro de `mission_portrait.png` (229×226 guardados), em pixels do arquivo.
const PORTRAIT_WINDOW := Rect2(33.0, 30.0, 164.0, 163.0)
const PORTRAIT_FILE := Vector2(229.0, 226.0)


static func tex(file: String) -> Texture2D:
	return load(HomeUi.DIR + "mission_" + file + ".png") as Texture2D


## Moldura NinePatch (cantos `margins` em pixels finais: esquerda, cima, direita, baixo). Com `follow` ela acompanha
## o tamanho de `host` (descontado `inset`); sem ele, quem chama posiciona (`position`/`size`, esta em pixels x3).
static func frame(host: Control, file: String, margins: Vector4, node_name: String = "", inset: Vector4 = Vector4.ZERO, follow: bool = true) -> NinePatchRect:
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
	if follow:
		var fit := func() -> void:
			result.position = Vector2(inset.x, inset.y)
			result.size = (host.size - Vector2(inset.x + inset.z, inset.y + inset.w)).max(Vector2.ONE) * 3.0
		host.resized.connect(fit)
		fit.call()
	return result


## Texto na fonte da madeira (creme com contorno escuro por padrão); nunca pega o toque.
static func text(value: String, px: int, color: Color = Palette.WOOD_CREAM, outline: int = 3, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var result := Label.new()
	result.text = value
	result.theme = HomeUi.theme(px, color, Palette.WOOD_INK, outline)
	result.horizontal_alignment = align
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


static func _fill(node: Control) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Cartão de papel (`card` ou `hero`): fundo ilustrado atrás, conteúdo num `Body` com a folga `pad` (esq, cima, dir, baixo).
## A altura vem do conteúdo (ou de `min_height`); o fundo acompanha. Use `body(card)` para pôr os filhos.
static func card(file: String, pad: Vector4i, node_name: String = "", margin: int = 10, min_height: float = 0.0) -> PanelContainer:
	var result := PanelContainer.new()
	result.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.custom_minimum_size = Vector2(0, min_height)
	if node_name != "":
		result.name = node_name
	var art := Control.new()
	art.name = "Art"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_child(art)
	frame(art, file, Vector4(margin, margin, margin, margin), "Frame")
	var inner := MarginContainer.new()
	inner.name = "Body"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override("margin_left", pad.x)
	inner.add_theme_constant_override("margin_top", pad.y)
	inner.add_theme_constant_override("margin_right", pad.z)
	inner.add_theme_constant_override("margin_bottom", pad.w)
	result.add_child(inner)
	return result


static func body(card_node: Control) -> MarginContainer:
	return card_node.get_node("Body") as MarginContainer


## Pílula com texto ("2/3"): `green` quando completa, `brown` senão. Tamanho fixo (padrão 104×24).
static func pill(kind: String, value: String, node_name: String = "", size: Vector2 = PILL) -> Control:
	var result := Control.new()
	result.custom_minimum_size = size
	result.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if node_name != "":
		result.name = node_name
	frame(result, "pill_" + kind, Vector4(10, 0, 10, 0), "Pill")
	var label := text(value, 13, Palette.WOOD_CREAM, 3)
	label.name = "PillText"
	result.add_child(label)
	_fill(label)
	return result


## Botão de madeira, SEMPRE `BUTTON` (104×44). `kind`: "claim" (verde) ou "go" (laranja, 39 desenhados num alvo de 44).
## `width` só muda em botões de rodapé (ex.: Álbum).
static func button(kind: String, caption: String, on_pressed: Callable, width: float = BUTTON.x, px: int = 16) -> Button:
	var result := BagUi.plain_button(on_pressed)
	result.custom_minimum_size = Vector2(width, BUTTON.y)
	result.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	result.pressed.connect(func() -> void: Motion.bounce(result))
	var drawn := 39.0 if kind == "go" else 44.0
	var gap := (BUTTON.y - drawn) / 2.0
	var art := frame(result, kind, Vector4(12, 0, 12, 0), "Frame", Vector4(0, gap, 0, gap))
	# A arte desenha ATRÁS do botão: o rótulo é o próprio texto dele (creme, contorno escuro, fonte da madeira).
	art.show_behind_parent = true
	result.text = caption
	result.clip_text = true
	result.theme = HomeUi.theme(px, Palette.WOOD_CREAM, Palette.WOOD_INK, 3)
	return result


## Estado plano no espaço do Ir: texto/ícone à direita, sem fundo ou entrada.
static func done_status() -> Control:
	var result := Control.new()
	result.custom_minimum_size = BUTTON
	result.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := UiKit.hbox(4)
	row.name = "StatusRow"
	row.alignment = BoxContainer.ALIGNMENT_END
	result.add_child(row)
	_fill(row)
	row.add_child(UiKit.ctl("check", 14, Palette.GO))
	var caption := text("Concluído", 14, Palette.GO, 0)
	caption.name = "DoneText"
	caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(caption)
	return result


## Link de texto creme sublinhado (sem fundo), centralizado.
static func link(caption: String, on_pressed: Callable) -> LinkButton:
	var result := LinkButton.new()
	result.text = caption
	result.underline = LinkButton.UNDERLINE_MODE_ALWAYS
	result.theme = HomeUi.theme(15, Palette.WOOD_CREAM, Palette.WOOD_INK, 3)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		result.add_theme_color_override(state, Palette.WOOD_CREAM)
	result.add_theme_color_override("font_outline_color", Palette.WOOD_INK)
	result.add_theme_constant_override("outline_size", 3)
	result.custom_minimum_size = Vector2(0, BUTTON.y)
	result.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	result.pressed.connect(on_pressed)
	return result


## Quadradinho bege com o ícone e, se `amount` não for vazio, o "+N" no canto de baixo à direita.
static func tile(icon: Texture2D, amount: String = "", node_name: String = "", size: Vector2 = Vector2(48, 48)) -> Control:
	var result := Control.new()
	result.custom_minimum_size = size
	result.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if node_name != "":
		result.name = node_name
	var art := TextureRect.new()
	art.name = "Tile"
	art.texture = tex("tile")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_child(art)
	_fill(art)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_child(center)
	_fill(center)
	if icon != null:
		var picture := UiKit.icon(icon, int(size.x * 0.62))
		picture.name = "Picture"
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		center.add_child(picture)
	if amount != "":
		var count := text(amount, 12, Palette.WOOD_CREAM, 4, HORIZONTAL_ALIGNMENT_RIGHT)
		count.name = "Amount"
		result.add_child(count)
		_fill(count)
		count.offset_right = -3.0
		count.offset_bottom = -1.0
		count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	return result


## Retrato quadrado `px`×`px` dentro da moldura de madeira (o miolo da moldura é vazado; a imagem passa por baixo).
static func portrait(picture: Texture2D, px: float = 84.0) -> Control:
	var result := Control.new()
	result.name = "Portrait"
	result.custom_minimum_size = Vector2(px, px)
	result.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var scale := Vector2(px, px) / PORTRAIT_FILE
	var window := Control.new()
	window.clip_contents = true
	window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	window.position = PORTRAIT_WINDOW.position * scale - Vector2(2, 2)
	window.size = PORTRAIT_WINDOW.size * scale + Vector2(4, 4)
	result.add_child(window)
	var face := TextureRect.new()
	face.name = "Face"
	face.texture = picture
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	window.add_child(face)
	_fill(face)
	var wood := TextureRect.new()
	wood.name = "Wood"
	wood.texture = tex("portrait")
	wood.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wood.stretch_mode = TextureRect.STRETCH_SCALE
	wood.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	wood.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_child(wood)
	_fill(wood)
	return result


## Etiqueta laranja com o título (uma linha; reticências se faltar espaço).
static func title_tag(value: String) -> Control:
	var result := Control.new()
	result.name = "TitleTag"
	result.custom_minimum_size = Vector2(0, 26)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame(result, "label", Vector4(8, 0, 8, 0), "Frame")
	var label := text(value, 13, Palette.WOOD_CREAM, 3, HORIZONTAL_ALIGNMENT_LEFT)
	label.name = "TitleText"
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	result.add_child(label)
	_fill(label)
	label.offset_left = 7.0
	label.offset_right = -3.0
	return result


## Barra laranja (trilho + preenchimento) de 20 px com "n/m" no meio.
static func bar(fraction: float, caption: String) -> Control:
	var meter := Control.new()
	meter.name = "StoryBar"
	meter.custom_minimum_size = Vector2(0, 20)
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track := frame(meter, "bar_track", Vector4(8, 0, 8, 0), "Track", Vector4.ZERO, false)
	var fill := frame(meter, "bar_fill", Vector4(8, 0, 8, 0), "Fill", Vector4.ZERO, false)
	var amount := clampf(fraction, 0.0, 1.0)
	var fit := func() -> void:
		track.size = Vector2(meter.size.x, 20.0) * 3.0
		fill.visible = amount > 0.0
		fill.size = Vector2(maxf(meter.size.x * amount, 16.0), 20.0) * 3.0
	meter.resized.connect(fit)
	fit.call()
	var label := text(caption, 12, Palette.WOOD_CREAM, 4)
	label.name = "BarText"
	meter.add_child(label)
	_fill(label)
	return meter


## Placa do título sobre a borda de cima da moldura: largura `width`; fonte 20 que encolhe até 15; se ainda
## não couber, quebra em 2 linhas e a placa cresce. Devolve o Control já com o tamanho final.
static func plaque(value: String, width: float) -> Control:
	var font := load(HomeUi.FONT) as Font
	var wood_width := width * 0.64
	var px := 20
	while px > 15 and font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > wood_width:
		px -= 1
	var lines := 1
	if font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > wood_width:
		lines = 2
	var height := width * 184.0 / 690.0 * (1.0 if lines == 1 else 1.3)
	var result := Control.new()
	result.name = "ChapterPlaque"
	result.custom_minimum_size = Vector2(width, height)
	result.size = Vector2(width, height)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := TextureRect.new()
	art.texture = tex("plaque")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_child(art)
	_fill(art)
	var label := text(value, px, Palette.WOOD_CREAM, 4)
	label.name = "ChapterTitle"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.max_lines_visible = lines
	result.add_child(label)
	_fill(label)
	label.offset_left = width * 0.17
	label.offset_right = -width * 0.17
	label.offset_top = height * 0.12
	label.offset_bottom = -height * 0.12
	return result


## Plaquinha marrom de seção ("Recompensas"), centralizada.
static func tag(value: String, node_name: String = "") -> Control:
	return pill("brown", value, node_name, Vector2(120, 24))


## Título solto sobre a madeira escura ("Passos"), centralizado.
static func heading(value: String, node_name: String = "") -> Label:
	var result := text(value, 18, Palette.WOOD_CREAM, 4, HORIZONTAL_ALIGNMENT_CENTER)
	result.custom_minimum_size = Vector2(0, 26)
	if node_name != "":
		result.name = node_name
	return result


## "?" de 28 px (alvo de 36) que abre o "Como fazer".
static func help_button(on_pressed: Callable) -> Button:
	var result := BagUi.plain_button(on_pressed)
	result.name = "QuestHelp"
	result.custom_minimum_size = Vector2(36, 36)
	var disc := Panel.new()
	var style := UiKit.surface(Palette.WOOD_INSET, 14)
	style.border_color = Palette.WOOD_INK
	style.set_border_width_all(2)
	disc.add_theme_stylebox_override("panel", style)
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_child(disc)
	disc.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	disc.offset_left = -14.0
	disc.offset_right = 14.0
	disc.offset_top = -14.0
	disc.offset_bottom = 14.0
	var mark := text("?", 16, Palette.WOOD_INK, 0)
	disc.add_child(mark)
	_fill(mark)
	return result
