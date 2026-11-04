class_name CodexUi
extends RefCounted
## Caderninho do Tiro (livrinho) no visual "madeira ilustrada": placa "Caderninho" curva sobre a moldura, X de madeira,
## uma coluna de abas coloridas na borda DIREITA (uma por seção: Recursos, Estações, Crescer, Álbum, Coleção, Truques),
## uma fileira de filtros no topo do miolo creme e, embaixo, uma grade de quadradinhos (ícone grande + "×N").
## A aba escolhida avança mais que as outras e fica na frente da moldura; as outras entram por baixo dela.
## As imagens `codex_*.png` vêm de `tools/codex_art.gd` (~3x: os NinePatch usam escala 1/3, então moram em Control comum).
## Só monta; o conteúdo de cada seção vem do `CodexSections` e as regras ficam no `GameState`.
## Nós: `PetNotebook` (raiz), `CodexBoard`, `CodexTitle`, `CloseButton`, `NotebookTab_<seção>` (aba lateral),
## `CodexFilters`/`NotebookTab_<filtro>` (filtros), `CodexScroll`/`CodexBar`, `CodexFoot`, tiles com o nome que a seção der.

const SIDE := 2.0
const MAX_WIDTH := 420.0
const LEFT := 8.0               # folga da madeira até a borda do quadro (as folhas da moldura saem por aí)
const TAB_W := 64.0
const TAB_H := 62.0
const TAB_GAP := 8.0
const TAB_HIDE := 12.0          # parte da aba parada que entra por baixo da moldura
const TAB_OUT := 4.0            # idem da escolhida (sobressai 8 px a mais)
const TAB_EDGE := 4.0           # folga mínima da aba até a borda direita da tela
const TAB_BAR := 104.0          # barra de abas do jogo: o caderninho termina acima dela
const TAB_TOP := 86.0
const FT := 30.0                # topo da madeira (a placa sobe por cima dele)
const ART := Vector4(9.67, 10.0, 2.4, 11.7)   # esq, topo, dir, base: o quanto a imagem passa da madeira visível
const CREAM := Vector4(14.3, 14.3, 14.0, 16.7)  # madeira visível até o creme (esq, topo, dir, base)
const FRAME_MARGINS := Vector4i(190, 190, 190, 190)
const PLATE := Vector2(176.0, 60.4)
const FILTER_H := 44.0         # abinha de filtro (nome escrito)
const FILTER_GAP := 4.0
const FILTER_TOP := 78.0
const SIDE_PAD := 4.0
const FILTER_INSET := 12.0  # o papel tem um filete branco ~9 px para dentro: as abinhas ficam dentro dele
const GUTTER := 6.0
const GAP := 6.0
const TAIL := 6.0
const FOOT_H := 44.0
const BOTTOM_PAD := 8.0
const TILE_MARGINS := Vector4i(62, 62, 62, 75)
const CAPTION_H := 30.0
const TAB_COLORS := {"resources": "red", "stations": "orange", "growth": "purple", "album": "green", "collection": "yellow", "tricks": "blue"}

## Filtro escolhido de cada seção (vale enquanto o jogo está aberto).
static var filters: Dictionary = {}


static func tex(file: String) -> Texture2D:
	return load(HomeUi.DIR + "codex_" + file + ".png") as Texture2D


static func _screen() -> Vector2:
	return (Engine.get_main_loop() as SceneTree).root.get_visible_rect().size


static func board_width() -> float:
	return minf(_screen().x - SIDE * 2.0, MAX_WIDTH)


## Largura da madeira (a coluna de abas fica à direita dela).
static func frame_width() -> float:
	return board_width() - LEFT - (TAB_W - TAB_OUT) - TAB_EDGE + SIDE  # a aba escolhida termina a TAB_EDGE da borda da tela


static func board_height() -> float:
	var top := float((load("res://scripts/ui/hud.gd") as GDScript).get_script_constant_map()["SHEET_TOP"])
	return _screen().y - top - TAIL - TAB_BAR


## Largura útil das grades (dentro do creme, sem as folgas e sem a coluna da barra).
static func content_width() -> float:
	return frame_width() - CREAM.x - CREAM.z - (SIDE_PAD + GUTTER) * 2.0


## Quatro por linha; a seção pode pedir outra conta com `cols` (fotos do álbum: 3).
static func columns(view: Dictionary = {}) -> int:
	return int(view.get("cols", 4))


static func tile_width(view: Dictionary = {}) -> float:
	var cols := columns(view)
	return floorf((content_width() - GAP * (cols - 1)) / cols)


static func _font(px: int) -> Font:
	return HomeUi.theme(px).default_font


static func _text_w(text: String, px: int) -> float:
	return _font(px).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x


## Maior fonte (de `top` até `bottom`) em que `text` cabe em `width`.
static func fit_px(text: String, width: float, top: int, bottom: int) -> int:
	for px in range(top, bottom - 1, -1):
		if _text_w(text, px) <= width:
			return px
	return bottom


# --- Entrada -------------------------------------------------------------------------------

## `section` já normalizada pelo `PetNotebook`; `filter` opcional (senão vale o último da seção).
static func build(section: String, filter: String = "") -> Control:
	if filter != "":
		filters[section] = filter
	var model := {"section": section, "scroll": 0, "noted": ""}
	var live := SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.add_theme_constant_override("separation", 0)
		box.add_child(_board(model, box as SheetBuilder.LiveBox))
		var tail := Control.new()
		tail.custom_minimum_size.y = TAIL + TAB_BAR
		tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(tail))
	live.name = "PetNotebook"
	live.set_meta("sheet_bare", true)
	live.set_meta("sheet_fit_content", true)
	live.set_meta("tick_refresh", false)  # a grade rola: nada de refazer a cada segundo
	return live


static func _board(model: Dictionary, live: SheetBuilder.LiveBox) -> Control:
	var entries := PetNotebook.tabs()
	var section := str(model.section)
	if not entries.any(func(entry: Dictionary) -> bool: return str(entry.id) == section):
		section = "resources"
		model.section = section
	var view := CodexSections.view(section, str(filters.get(section, "")), model)
	filters[section] = str(view.filter)
	var width := board_width()
	var wood_w := frame_width()
	var height := board_height()
	var wood_h := height - FT - ART.w
	var board := Control.new()
	board.name = "CodexBoard"
	board.mouse_filter = Control.MOUSE_FILTER_PASS
	board.custom_minimum_size = Vector2(width, height)
	board.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	board.set_meta("wood", Rect2(LEFT, FT, wood_w, wood_h))
	var selected_tab: Control = null
	for entry: Dictionary in entries:
		var picked := str(entry.id) == section
		var tab := _tab(entry, picked, model, live)
		var index := entries.find(entry)
		tab.position = Vector2(LEFT + wood_w - (TAB_OUT if picked else TAB_HIDE), TAB_TOP + index * (TAB_H + TAB_GAP))
		if picked:
			selected_tab = tab
		else:
			board.add_child(tab)
	# Moldura: a imagem passa da madeira visível (folhas à esquerda), por isso o recuo `ART`.
	var art := SellUi.nine("frame", FRAME_MARGINS, "Art", null, "codex_")
	board.add_child(art)
	art.position = Vector2(LEFT - ART.x, FT - ART.y)
	art.size = Vector2(wood_w + ART.x + ART.z, wood_h + ART.y + ART.w)
	(art.get_child(0) as Control).size = art.size * 3.0  # o quadro ainda não está na árvore: `resized` não dispara
	_add_title(board, wood_w)
	var cream := Rect2(LEFT + CREAM.x, FT + CREAM.y, wood_w - CREAM.x - CREAM.z, wood_h - CREAM.y - CREAM.w)
	var top := FILTER_TOP
	var shown_filters: Array = view.filters
	if shown_filters.size() > 1:
		var strip := _filter_row(shown_filters, str(view.filter), section, model, live, cream.size.x - FILTER_INSET * 2.0)
		board.add_child(strip)
		strip.position = Vector2(cream.position.x + FILTER_INSET, FILTER_TOP)
		top = FILTER_TOP + strip.size.y + 8.0
		# O nome do filtro escolhido também vira o título da grade.
		var blocks: Array = view.get("blocks", [])
		if not blocks.is_empty() and str((blocks[0] as Dictionary).get("title", "")) == "":
			for entry: Dictionary in shown_filters:
				if str(entry.id) == str(view.filter):
					(blocks[0] as Dictionary).title = str(entry.text)
	else:
		top = FILTER_TOP - 6.0
	var foot: Control = view.get("foot")
	var area_bottom := cream.end.y - BOTTOM_PAD
	if foot != null:
		area_bottom -= FOOT_H + 6.0
	var area := _grid_area(view, model, Vector2(cream.size.x - SIDE_PAD * 2.0, area_bottom - top))
	board.add_child(area)
	area.position = Vector2(cream.position.x + SIDE_PAD, top)
	if foot != null:
		foot.name = "CodexFoot"
		board.add_child(foot)
		foot.custom_minimum_size = Vector2(minf(cream.size.x - 24.0, 220.0), FOOT_H)
		foot.size = foot.custom_minimum_size
		foot.position = Vector2(cream.position.x + (cream.size.x - foot.size.x) / 2.0, cream.end.y - BOTTOM_PAD - FOOT_H)
	if selected_tab != null:
		board.add_child(selected_tab)
	return board


# --- Placa, X ------------------------------------------------------------------------------

static func _add_title(board: Control, wood_w: float) -> void:
	var plate := TextureRect.new()
	plate.name = "CodexPlate"
	plate.texture = tex("plate")
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode = TextureRect.STRETCH_SCALE
	plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.position = Vector2(LEFT + (wood_w - PLATE.x) / 2.0, 0.0)
	plate.size = PLATE
	board.add_child(plate)
	var title := MissionUi.text("Caderninho", 20, Palette.WOOD_CREAM, 3)
	title.name = "CodexTitle"
	title.size = Vector2(PLATE.x - 48.0, 30.0)
	title.position = Vector2(plate.position.x + 24.0, 9.0)
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	board.add_child(title)
	var close := BagUi.plain_button(func() -> void: Events.sheet_close_requested.emit())
	close.name = "CloseButton"
	close.custom_minimum_size = Vector2(44, 44)
	close.size = Vector2(44, 44)
	var picture := SellUi.soft(TextureRect.new())
	picture.texture = MissionUi.tex("close")
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	close.add_child(picture)
	picture.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	picture.offset_left = -19.0
	picture.offset_right = 19.0
	picture.offset_top = -19.0
	picture.offset_bottom = 19.0
	close.pressed.connect(func() -> void: Motion.bounce(picture))
	board.add_child(close)
	close.position = Vector2(LEFT + wood_w - 42.0, 4.0)


# --- Abas laterais ---------------------------------------------------------------------------

static func _tab(entry: Dictionary, picked: bool, model: Dictionary, live: SheetBuilder.LiveBox) -> Button:
	var id := str(entry.id)
	var tab := BagUi.plain_button(func() -> void:
		if str(model.section) == id:
			return
		model.section = id
		model.scroll = 0
		model.noted = ""
		PetNotebook.visit(id)
		live.refresh())
	tab.name = "NotebookTab_" + id
	tab.custom_minimum_size = Vector2(TAB_W, TAB_H)
	tab.size = Vector2(TAB_W, TAB_H)
	tab.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tab.set_meta("picked", picked)
	var art := SellUi.nine("tab_" + str(TAB_COLORS.get(id, "orange")), TILE_MARGINS, "Art", null, "codex_")
	tab.add_child(art)
	StepCardUi.stretch(art)
	var hide := TAB_OUT if picked else TAB_HIDE
	var center := (hide + TAB_W - 6.0) / 2.0
	var icon := SellUi.soft(TextureRect.new())
	icon.name = "Icon"
	icon.texture = tex("icon_" + id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = Vector2(32, 32)
	icon.position = Vector2(center - 16.0, 6.0)
	tab.add_child(icon)
	var name_text := str(entry.text)
	var label := MissionUi.text(name_text, 11, Palette.WOOD_CREAM, 1)
	label.name = "Title"
	HomeUi.resize(label, tab_px())
	label.clip_text = true  # antes do tamanho: senão o mínimo do texto segura a largura
	label.size = Vector2(TAB_W - hide - 10.0, 16)
	label.position = Vector2(hide + 2.0, 40.0)
	tab.add_child(label)
	if bool(entry.get("alert", false)):
		tab.add_child(_new_dot(Vector2(TAB_W - 15.0, -3.0)))
	return tab


static func _longest_word(text: String, px: int) -> float:
	var widest := 0.0
	for word: String in text.split(" "):
		widest = maxf(widest, _text_w(word, px))
	return widest


## Mesma fonte em todas as abas: a maior em que o nome mais largo cabe na parte visível da aba parada.
static func tab_px() -> int:
	var px := 12
	for name_text: String in ["Recursos", "Estações", "Crescer", "Álbum", "Coleção", "Truques"]:
		px = mini(px, fit_px(name_text, TAB_W - TAB_HIDE - 14.0, 12, 8))
	return px


static func _new_dot(at: Vector2) -> TextureRect:
	var dot := TextureRect.new()
	dot.name = "NewBadge"
	dot.texture = BagUi.tex("new")
	dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dot.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.size = Vector2(16, 16)
	dot.position = at
	return dot


# --- Filtros -------------------------------------------------------------------------------

## Abinhas com o NOME escrito (ícone sozinho não dava para adivinhar). Fluem em linhas centralizadas, todas à vista.
## Devolve fonte, folga e linhas ([[índices], ...]): tenta 13 px; se passar de duas linhas, 12 px; senão aceita três.
static func filter_layout(options: Array, width: float) -> Dictionary:
	var result := {}
	for step: Vector2i in [Vector2i(13, 20), Vector2i(12, 18)]:  # (fonte, folga): folga menor cola o texto na borda
		var px := step.x
		var pad := float(step.y)
		var rows: Array = [[]]
		var used := 0.0
		for i in options.size():
			var w := filter_width(str((options[i] as Dictionary).text), px, pad)
			if not (rows[-1] as Array).is_empty() and used + FILTER_GAP + w > width:
				rows.append([])
				used = 0.0
			used += (FILTER_GAP if not (rows[-1] as Array).is_empty() else 0.0) + w
			(rows[-1] as Array).append(i)
		result = {"px": px, "pad": pad, "rows": rows}
		if rows.size() <= 2:
			break
	return result


static func filter_width(text: String, px: int, pad: float = 20.0) -> float:
	return maxf(ceilf(_text_w(text, px)) + pad, 48.0)


static func _filter_row(options: Array, picked: String, section: String, model: Dictionary, live: SheetBuilder.LiveBox, width: float) -> Control:
	var fit := filter_layout(options, width)
	var px := int(fit.px)
	var pad := float(fit.pad)
	var rows: Array = fit.rows
	var holder := Control.new()
	holder.name = "CodexFilters"
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	holder.custom_minimum_size = Vector2(width, rows.size() * FILTER_H + (rows.size() - 1) * FILTER_GAP)
	holder.size = holder.custom_minimum_size
	for row in rows.size():
		var line: Array = rows[row]
		var row_w := -FILTER_GAP
		for i: int in line:
			row_w += FILTER_GAP + filter_width(str((options[i] as Dictionary).text), px, pad)
		var x := floorf((width - row_w) / 2.0)  # cada linha centralizada
		for i: int in line:
			var entry: Dictionary = options[i]
			var id := str(entry.id)
			var w := filter_width(str(entry.text), px, pad)
			var button := _filter_tile(entry, id == picked, Vector2(w, FILTER_H), px, func() -> void:
				if id == picked:
					return
				filters[section] = id
				model.scroll = 0
				model.noted = ""
				live.refresh())
			button.position = Vector2(x, row * (FILTER_H + FILTER_GAP))
			holder.add_child(button)
			x += w + FILTER_GAP
	return holder


static func _filter_tile(entry: Dictionary, picked: bool, size: Vector2, px: int, on_pressed: Callable) -> Button:
	var id := str(entry.id)
	var button := BagUi.plain_button(on_pressed)
	button.name = "NotebookTab_" + id  # mesmo nome do `UiKit.segmented` (testes e atalhos)
	button.tooltip_text = str(entry.text)
	button.custom_minimum_size = size
	button.size = size
	button.set_meta("picked", picked)
	# Moldura em 1/4 (não 1/3): os cantos cabem na abinha baixa sem se sobrepor.
	var art := Control.new()
	art.name = "Art"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var patch := NinePatchRect.new()
	patch.name = "Frame"
	patch.texture = tex("tab_orange" if picked else "tile")
	patch.patch_margin_left = TILE_MARGINS.x
	patch.patch_margin_top = TILE_MARGINS.y
	patch.patch_margin_right = TILE_MARGINS.z
	patch.patch_margin_bottom = TILE_MARGINS.w
	patch.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	patch.scale = Vector2.ONE / 4.0
	patch.size = size * 4.0
	art.add_child(patch)
	art.size = size
	button.add_child(art)
	var label := MissionUi.text(str(entry.text), px, Palette.WOOD_CREAM if picked else Palette.WOOD_INK, 3 if picked else 0)
	label.name = "Caption"
	label.size = Vector2(size.x, size.y - 3.0)  # a borda de baixo da moldura é mais grossa
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	if bool(entry.get("alert", false)):
		button.add_child(_new_dot(Vector2(size.x - 12.0, -4.0)))
	return button


# --- Grade ---------------------------------------------------------------------------------

## Área que rola: blocos (título + contagem + grade de quadradinhos iguais). A barra fica numa coluna fixa.
static func _grid_area(view: Dictionary, model: Dictionary, size: Vector2) -> Control:
	var cols := columns(view)
	var tile_w := tile_width(view)
	var grid_w := tile_w * cols + GAP * (cols - 1)
	var left := roundf((size.x - grid_w) / 2.0)  # a barra mora na folga da direita
	var holder := VBoxContainer.new()
	holder.name = str(view.get("name", "CodexGrid"))
	holder.add_theme_constant_override("separation", 10)
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	for block: Dictionary in view.blocks:
		holder.add_child(_block(block, cols, tile_w, grid_w))
	if view.blocks.is_empty():
		var empty := MissionUi.text(str(view.get("empty", "")), 16, Palette.WOOD_INK, 0)
		empty.name = "CodexEmpty"
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size = Vector2(grid_w, 80.0)
		holder.add_child(empty)
	var margin := MarginContainer.new()
	margin.name = "CodexPad"
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left", int(left))
	margin.add_child(holder)
	var wrap := VBoxContainer.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_PASS
	wrap.add_child(margin)
	var pad := Control.new()
	pad.custom_minimum_size.y = 4.0
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(pad)
	var area := SellUi.scrolled(wrap, size.x, size.y, true, model, "CodexScroll", "CodexBar", GUTTER)
	area.custom_minimum_size = size
	area.size = size
	return area


static func _block(block: Dictionary, cols: int, tile_w: float, width: float) -> Control:
	var box := VBoxContainer.new()
	box.name = str(block.get("name", "CodexBlock"))
	box.add_theme_constant_override("separation", 6)
	box.custom_minimum_size.x = width
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	var title := str(block.get("title", ""))
	if title != "":
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var label := MissionUi.text(title, 16, Palette.WOOD_INK, 0, HORIZONTAL_ALIGNMENT_LEFT)
		label.name = "BlockTitle"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(label)
		var count := str(block.get("count", ""))
		if count != "":
			var counter := MissionUi.text(count, 15, Palette.WOOD_INK, 0, HORIZONTAL_ALIGNMENT_RIGHT)
			counter.name = "BlockCount"
			row.add_child(counter)
		var action: Control = block.get("action")
		if action != null:
			row.add_child(action)
		box.add_child(row)
	var lines: Array = block.get("lines", [])
	for line: String in lines:
		var text := MissionUi.text(line, 14, Palette.WOOD_INK, 0, HORIZONTAL_ALIGNMENT_LEFT)
		text.name = "CodexLine"
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size.x = width - 4.0
		box.add_child(text)
	var tiles: Array = block.get("tiles", [])
	if not tiles.is_empty():
		var tile_h := roundf(tile_w * float(block.get("ratio", 1.0)))
		# Com legenda: quadrado do ícone + linha do nome (+ bolinhas), sem esticar o creme.
		var captioned := false
		var dotted := false
		for opts: Dictionary in tiles:
			captioned = captioned or str(opts.get("caption", "")) != ""
			dotted = dotted or int(opts.get("dots_need", 0)) > 0
		if captioned or dotted:
			tile_h = tile_w + (CAPTION_H if captioned else 0.0) + (12.0 if dotted else 0.0)
		var grid := GridContainer.new()
		grid.name = "CodexTiles"
		grid.columns = cols
		grid.add_theme_constant_override("h_separation", int(GAP))
		grid.add_theme_constant_override("v_separation", int(GAP))
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		for opts: Dictionary in tiles:
			grid.add_child(tile(opts, tile_w, tile_h))
		box.add_child(grid)
	return box


## Linhas que `text` ocupa em `width` com a fonte `px`.
static func _line_count(text: String, px: int, width: float) -> int:
	var paragraph := TextParagraph.new()
	paragraph.add_string(text, _font(px), px)
	paragraph.width = width
	return paragraph.get_line_count()


## Maior fonte (11 a 8) em que a legenda cabe em duas linhas de `width`.
static func caption_px(text: String, width: float) -> int:
	for px in range(11, 8, -1):
		if _longest_word(text, px) > width:
			continue
		var paragraph := TextParagraph.new()
		paragraph.add_string(text, _font(px), px)
		paragraph.width = width
		if paragraph.get_line_count() <= 2:
			return px
	return 8


## Quadradinho: ícone grande (pixel em escala inteira, ilustração em escala uniforme), "×N" no canto, legenda opcional
## (até duas linhas) e marcas. `dim` = apagado (cinza). Opções: name, icon, count, caption, dim, selected, mark, badge, card,
## on_tap, tooltip.
static func tile(opts: Dictionary, w: float, h: float) -> Button:
	var dim := bool(opts.get("dim", false))
	var caption := str(opts.get("caption", ""))
	var tap: Callable = opts.get("on_tap", Callable())
	var result := BagUi.plain_button(tap if tap.is_valid() else func() -> void: pass)
	result.name = str(opts.get("name", "Tile"))
	result.custom_minimum_size = Vector2(w, h)
	result.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	result.tooltip_text = str(opts.get("tooltip", ""))
	var art_file := "tile_off" if dim else ("tab_orange" if bool(opts.get("selected", false)) else "tile")
	var dots_need := int(opts.get("dots_need", 0))
	var dots_h := 12.0 if dots_need > 0 else 0.0
	# Com legenda o creme fica quadrado (só o ícone) e o nome mora embaixo, fora dele: nada esticado.
	var art_h := minf(w, h - CAPTION_H - dots_h) if caption != "" or dots_need > 0 else h
	var art := SellUi.nine(art_file, TILE_MARGINS, "Art", null, "codex_")
	result.add_child(art)
	art.position = Vector2((w - art_h) / 2.0, 0.0) if art_h < w else Vector2.ZERO
	art.size = Vector2(art_h if art_h < w else w, art_h)
	(art.get_node("Frame") as Control).size = art.size * 3.0  # fora da árvore o `resized` não chega
	var box := Rect2(art.position + Vector2(4.0, 4.0), art.size - Vector2(8.0, 10.0))
	var card: Callable = opts.get("card", Callable())
	if card.is_valid():
		var shown: Control = card.call(box.size.x)
		if shown.custom_minimum_size.y > box.size.y:  # a foto em pé não pode passar do creme: refaz menor, na mesma proporção
			var width := floorf(box.size.x * box.size.y / shown.custom_minimum_size.y)
			shown.free()
			shown = card.call(width)
		shown.mouse_filter = Control.MOUSE_FILTER_IGNORE
		result.add_child(shown)
		shown.position = box.position + (box.size - shown.custom_minimum_size) / 2.0
	else:
		var texture := opts.get("icon") as Texture2D
		if texture != null:
			var picture := TextureRect.new()
			picture.name = "Picture"
			picture.texture = texture
			picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var side := minf(box.size.x, box.size.y)
			var size := Vector2.ZERO
			if texture.get_width() <= 32:
				picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				var factor := 2.0 if side >= 62.0 else 1.0
				size = Vector2(texture.get_width(), texture.get_height()) * factor
			else:
				picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				size = Vector2(side, side) * 0.84
			picture.size = size
			picture.position = box.position + (box.size - size) / 2.0
			if dim:
				picture.modulate = Color(1, 1, 1, 0.5)
			result.add_child(picture)
	var count := str(opts.get("count", ""))
	if count != "":
		var label := MissionUi.text(count, 13, Palette.WOOD_INK, 0, HORIZONTAL_ALIGNMENT_RIGHT)
		label.name = "Quantity"
		label.size = Vector2(w - 12.0, 16.0)
		label.position = Vector2(6.0, 6.0) if caption != "" else Vector2(6.0, h - 25.0)
		result.add_child(label)
	if caption != "":
		var text := MissionUi.text(caption, 11, Palette.WOOD_INK if not dim else Color(Palette.WOOD_INK, 0.6), 0)
		text.name = "Caption"
		var px := caption_px(caption, w - 8.0)
		HomeUi.resize(text, px)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.max_lines_visible = 2
		text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		text.add_theme_constant_override("line_spacing", -3)
		# Palavra comprida demais ("Liquidificador"): encolhe a legenda por igual em vez de partir a palavra.
		var fit := minf(1.0, (w - 8.0) / (_longest_word(caption, px) + 2.0))
		# Nome comprido demais para duas linhas (ex.: "Mochilinha de explorador"): encolhe mais um pouco.
		while fit > 0.6 and _line_count(caption, px, (w - 8.0) / fit) > 2:
			fit -= 0.04
		text.size = Vector2(w - 8.0, CAPTION_H - 4.0) / fit
		text.scale = Vector2(fit, fit)
		text.position = Vector2(4.0, art_h + dots_h + 1.0 + (CAPTION_H - 4.0) * (1.0 - fit) / 2.0)
		result.add_child(text)
	if dots_need > 0:
		var row := HBoxContainer.new()
		row.name = "Dots"
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 3)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		for i in dots_need:
			var dot := Panel.new()
			dot.custom_minimum_size = Vector2(8, 8)
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var style := UiKit.surface(Palette.HONEY if i < int(opts.get("dots_have", 0)) else Palette.SUNKEN, 4)
			style.border_color = Palette.WOOD_INK
			style.set_border_width_all(1)
			dot.add_theme_stylebox_override("panel", style)
			row.add_child(dot)
		result.add_child(row)
		row.size = Vector2(w - 8.0, 8.0)
		row.position = Vector2(4.0, art_h + 3.0)
	var mark := str(opts.get("mark", ""))
	if mark == "check":
		var medal := StepCardUi.done_medal(22.0, "EquippedCheck")
		result.add_child(medal)
		medal.position = Vector2(w - 28.0, 5.0)
	elif mark == "lock":
		var lock := SellUi.soft(TextureRect.new())
		lock.name = "ClothingLock"
		lock.texture = load(HomeUi.DIR + "farm_lock.png") as Texture2D
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.size = Vector2(22, 22)
		result.add_child(lock)
		lock.position = Vector2(w - 28.0, 5.0)
	elif mark == "heart":
		var heart := UiKit.icon(UiKit.ui_icon("heart"), 18)
		heart.name = "FavoriteHeart"
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		result.add_child(heart)
		heart.position = Vector2(w - 24.0, 4.0)
	if bool(opts.get("badge", false)):
		result.add_child(_new_dot(Vector2(w - 12.0, -4.0)))
	return result
