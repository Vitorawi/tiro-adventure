class_name UiKit
extends RefCounted
## Peças de interface reutilizáveis, já com as variações do tema
## (assets/theme/main_theme.tres): ícones, chips, cartões e botões.
## Ícones são pixel art de 32 px: usar tamanhos inteiros (32, 64) para ficarem nítidos.

const ICON_DIR := "res://assets/sprites/ui/icons/"
const CTL_DIR := "res://assets/sprites/ui/ctl/"
static var _ctl_cache: Dictionary[String, Texture2D] = {}
const GOOD := Palette.GO_INK
const BAD := Palette.ALERT_INK


static func ui_icon(icon_name: String) -> Texture2D:
	var path := icon_name if icon_name.begins_with("res://") else ICON_DIR + icon_name + ".png"
	return load(path) if ResourceLoader.exists(path) else null


static func icon(texture: Texture2D, px: int = 32) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	if texture and texture.resource_path.begins_with(CTL_DIR):
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		rect.self_modulate = Palette.INK_SOFT
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(px, px)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## Controles lisos: cache próprio, sem mudar a filtragem dos itens pixel.
static func ctl_icon(name: String) -> Texture2D:
	if not _ctl_cache.has(name):
		var path := CTL_DIR + name + ".svg"
		_ctl_cache[name] = load(path) if ResourceLoader.exists(path) else null
	return _ctl_cache[name]


static func ctl(name: String, px: int = 20, color: Color = Palette.INK_SOFT) -> TextureRect:
	var result := icon(ctl_icon(name), px)
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	result.self_modulate = color
	return result


## Bolinha de conclusão: só aparece quando há algo pronto para receber/coletar.
static func ready_dot(px: int = 14) -> Control:
	var dot := Panel.new()
	dot.name = "ReadyDot"
	dot.custom_minimum_size = Vector2(px, px)
	dot.size = dot.custom_minimum_size
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.GO
	style.border_color = Palette.PAPER
	style.set_border_width_all(2)
	style.set_corner_radius_all(px)
	dot.add_theme_stylebox_override("panel", style)
	return dot


## Novidade pendente: o mesmo sinal no atalho, na aba e no conteúdo.
static func alert_badge() -> Label:
	var result := badge(1)
	result.name = "NewBadge"
	result.text = "!"
	return result


static func label(text: String, variation: StringName = &"", color: Variant = null) -> Label:
	var result := Label.new()
	result.text = text
	result.theme_type_variation = variation
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if color is Color:
		result.add_theme_color_override("font_color", color)
	return result


## Etiqueta arredondada com ícone + texto (ex.: ingrediente "2/6", efeito "+20").
static func chip(texture: Texture2D, text: String, color: Variant = null, kind: String = "neutral") -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"ChipPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size.y = 28
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var colors := _chip_colors(kind)
	var style := surface(colors[0], 14)
	style.content_margin_left = 8
	style.content_margin_right = 8
	panel.add_theme_stylebox_override("panel", style)
	var row := hbox(4)
	if texture:
		row.add_child(icon(texture, 24))
	elif kind == "time":
		row.add_child(ctl("clock", 16, Palette.SKY_INK))
	row.add_child(short_label(text, &"ChipLabel", color if color is Color else colors[1]))
	if kind == "have":
		row.add_child(ctl("check", 14, Palette.GO_INK))
	panel.add_child(row)
	return panel


## Chip tocável (ex.: ingrediente que falta: tocar mostra de onde ele vem).
static func postcard_chip(texture: Texture2D, text: String, current: bool = false) -> PanelContainer:
	var ink := Palette.HONEY_INK if current else (Palette.ALERT_INK if text == "!" else Palette.GO_INK)
	var panel := chip(texture, text, ink)
	var style := surface(Palette.HONEY if current else Color(Palette.CARD, 0.94), 14)
	style.content_margin_left = 8
	style.content_margin_right = 8
	panel.add_theme_stylebox_override("panel", style)
	var picture := panel.get_child(0).get_child(0) as TextureRect
	picture.custom_minimum_size = Vector2(20, 20)
	if texture != null and texture.resource_path.begins_with(CTL_DIR): picture.modulate = Palette.HONEY_INK if current else Palette.GO_INK
	return panel


static func tap_chip(texture: Texture2D, text: String, on_pressed: Callable, color: Variant = null, kind: String = "") -> Button:
	var result := button(text, on_pressed, &"ChipButton", texture)
	result.custom_minimum_size = Vector2(0, 44)
	result.add_theme_constant_override("icon_max_width", 32)
	if kind != "":
		var colors := _chip_colors(kind)
		var style := surface(colors[0], 22)
		style.content_margin_left = 12
		style.content_margin_right = 12
		for state: String in ["normal", "hover", "pressed", "focus"]: result.add_theme_stylebox_override(state, style)
	if color is Color:
		for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			result.add_theme_color_override(state, color)
	return result


## Botão redondo só com ícone ou um símbolo curto (ex.: "?", "↔"): círculo `CARD` com borda fina.
## Alvo de toque = `px` (o desenho é o círculo inteiro).
static func icon_button(texture: Texture2D, on_pressed: Callable, px: int = 44, text: String = "") -> Button:
	# Compatibilidade com chamadas antigas: símbolos de controle também viram SVG.
	if texture == null:
		var control_name := str({"?": "help", "‹": "back", "›": "chev", "+": "plus", "−": "minus"}.get(text, ""))
		if control_name != "":
			texture = ctl_icon(control_name)
			text = ""
	var result := button(text, on_pressed, &"IconButton", texture)
	result.custom_minimum_size = Vector2(maxi(44, px), maxi(44, px))
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if texture:
		result.expand_icon = true
		result.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result.add_theme_constant_override("icon_max_width", 32)
	return result


## Mesma peça de antes (assinatura antiga), agora um `icon_button`.
static func square_button(text: String, on_pressed: Callable, texture: Texture2D = null, px: int = 52) -> Button:
	if text == "?":
		return icon_button(ctl_icon("help"), on_pressed, px)
	return icon_button(texture, on_pressed, px, text)


## O botão principal da tela/painel (verde). Só um por vez: listas usam `secondary(..., small = true)`.
static func primary(text: String, on_pressed: Callable, texture: Texture2D = null) -> Button:
	return button(text, on_pressed, &"PrimaryButton", texture)


## Apelido compatível de soft. `small` = texto 16 na linha de lista (alvo 44).
static func secondary(text: String, on_pressed: Callable, texture: Texture2D = null, small: bool = false) -> Button:
	return soft(text, on_pressed, texture, small)


## Ação fraca ("Ver tudo", "Cancelar"): sem fundo, texto suave sublinhado.
static func ghost(text: String, on_pressed: Callable) -> Button:
	var result := button(text, on_pressed, &"GhostButton")
	result.custom_minimum_size = Vector2(44, 44)
	return result


## Pílula clara do HUD sobre o mundo: ícone + número.
static func pill(texture: Texture2D, text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"PillPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := hbox(4)
	if texture:
		row.add_child(icon(texture, 32))
	var number := label(text, &"NumberLabel")
	number.name = "Value"
	number.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(number)
	panel.add_child(row)
	return panel


## Cadeado vetorial de 32 px, usado no `lock_hint` e nos cartões fechados.
static func lock_icon(px: int = 32) -> TextureRect:
	var lock := icon(ctl_icon("lock"), px)
	lock.name = "LockIcon"
	return lock


## "Ainda não dá": cadeado + motivo curto (+ "?" se houver `on_help`). Substitui o botão cinza largo.
static func lock_hint(text: String, on_help: Callable = Callable(), missing: Texture2D = null) -> HBoxContainer:
	var row := hbox(8)
	row.name = "LockHint"
	var lock := ctl("lock", 18)
	lock.name = "LockIcon"
	row.add_child(lock)
	if missing:
		row.add_child(disc(missing, 32, 24))
	row.add_child(fill_label(text))
	if on_help.is_valid():
		row.add_child(ctl_button("help", on_help, 32, "sunken"))
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		row.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				on_help.call())
	return row


## Espaço de produção compacto: bolinha de 52 px + legenda. `state` = SlotDot.EMPTY/QUEUED/BUSY/READY/BUY/LEVEL;
## `progress` 0..1 (em BUY, 1 = dá para comprar agora); `caption_icon` vai antes da legenda (moeda do preço).
static func slot_dot(state: String, texture: Texture2D = null, progress: float = 0.0, caption: String = "", caption_color: Variant = null, caption_icon: Texture2D = null) -> SlotDot:
	return SlotDot.new(state, texture, progress, caption, caption_color, caption_icon)


## Linha baixa de lista: [disco 44] [título + chips] [ação à direita]; chips quebram se faltar espaço.
## Toque na linha = `on_tap` (opcional).
## O corpo (VBox, filho 0) aceita rodapés, como o `lock_hint` de uma linha fechada.
static func list_row(texture: Texture2D, title: String, chips: Array[Control], action: Control = null, on_tap: Callable = Callable(), ready: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"RowPanel"
	if ready:
		var style := surface(Palette.GO_SOFT, 16)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 5
		style.content_margin_bottom = 5
		panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 64)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var body := vbox(2)
	panel.add_child(body)
	var top := hbox(8)
	top.add_child(disc(texture, 44, 32))
	var name_label := fill_label(title)
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var text_column := vbox(0)
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_child(name_label)
	top.add_child(text_column)
	if action:
		action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		top.add_child(action)
	body.add_child(top)
	if not chips.is_empty():
		var chip_row := flow(2)
		for chip_control: Control in chips:
			chip_row.add_child(chip_control)
		text_column.add_child(chip_row)
	if on_tap.is_valid():
		panel.gui_input.connect(func(event: InputEvent) -> void:
			var click := event as InputEventMouseButton
			if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
				on_tap.call())
	return panel

## Rótulo curto numa linha (ex.: "3/6"): sem quebra, senão o HBox o espreme letra por letra.
static func short_label(text: String, variation: StringName = &"", color: Variant = null) -> Label:
	var result := label(text, variation, color)
	result.autowrap_mode = TextServer.AUTOWRAP_OFF
	return result


## Rótulo que ocupa o espaço que sobra na linha.
static func fill_label(text: String, variation: StringName = &"", color: Variant = null) -> Label:
	var result := label(text, variation, color)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result


## Cartão (PanelContainer) com um VBox dentro; devolve o VBox para preencher.
static func card(parent: Control, variation: StringName = &"CardPanel") -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = variation
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# PASS: o arrasto do dedo segue para o ScrollContainer do painel (senão não rola).
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var box := vbox(6)
	panel.add_child(box)
	parent.add_child(panel)
	return box


## Ação de cuidado: círculo de 56 px, ícone de 48 e legenda alinhada. Mesma peça nos quatro cuidados.
static func action_tile(texture: Texture2D, caption: String, on_pressed: Callable) -> Button:
	var result := button("", on_pressed, &"GhostButton")
	result.custom_minimum_size = Vector2(72, 80)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.size_flags_vertical = Control.SIZE_FILL
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		result.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var visual := vbox(2)
	visual.name = "Visual"
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_child(visual)
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual.alignment = BoxContainer.ALIGNMENT_CENTER
	var circle := PanelContainer.new()
	circle.name = "Circle"
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.custom_minimum_size = Vector2(56, 56)
	circle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PET_BUTTON
	style.set_corner_radius_all(28)
	circle.add_theme_stylebox_override("panel", style)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var picture := icon(texture, 48)
	picture.name = "CareIcon"
	center.add_child(picture)
	circle.add_child(center)
	visual.add_child(circle)
	var text := short_label(caption, &"SmallLabel")
	text.name = "Caption"
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(text)
	return result


## Disco da roleta de cuidados (Interface 2, etapa 04): 64 px branco 82%, contorno interno claro, nome em pílula
## embaixo (fora do retângulo de toque, que é só o disco). Nós: `Circle`, `CareIcon`, `CaptionPill`/`Caption`.
static func care_disc(texture: Texture2D, caption: String, on_pressed: Callable, px: int = 64, overlap_caption: bool = false) -> Button:
	var result := button("", on_pressed, &"GhostButton")
	result.custom_minimum_size = Vector2(px, px)
	result.size = Vector2(px, px)
	for phase: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		result.add_theme_stylebox_override(phase, StyleBoxEmpty.new())
	var circle := PanelContainer.new()
	circle.name = "Circle"
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.custom_minimum_size = Vector2(px, px)
	var style := surface(Color(Palette.CARD, 0.82), px / 2, true)
	style.shadow_size = 8
	style.border_color = Color(Palette.CARD, 0.9)
	style.set_border_width_all(2)
	circle.add_theme_stylebox_override("panel", style)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var picture := icon(texture, 40)
	picture.name = "CareIcon"
	center.add_child(picture)
	circle.add_child(center)
	result.add_child(circle)
	circle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var pill := PanelContainer.new()
	pill.name = "CaptionPill"
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pill_style := surface(Color(Palette.CARD, 0.8), 12)
	pill_style.content_margin_left = 10.0
	pill_style.content_margin_right = 10.0
	pill_style.content_margin_top = 1.0
	pill_style.content_margin_bottom = 1.0
	pill.add_theme_stylebox_override("panel", pill_style)
	var text := short_label(caption, &"SmallLabel", Palette.INK)
	text.name = "Caption"
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(text)
	result.add_child(pill)
	var place := func() -> void:
		pill.size = pill.get_combined_minimum_size()
		pill.position = Vector2((result.size.x - pill.size.x) / 2.0, result.size.y - 12.0 if overlap_caption else result.size.y + 2.0)
	pill.minimum_size_changed.connect(place)
	result.resized.connect(place)
	place.call_deferred()
	return result


static func button(text: String, on_pressed: Callable, variation: StringName = &"", texture: Texture2D = null) -> Button:
	var result := Button.new()
	result.text = text
	result.theme_type_variation = variation
	result.icon = texture
	if texture and texture.resource_path.begins_with(CTL_DIR):
		result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		for state: String in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
			result.add_theme_color_override(state, Palette.INK_SOFT)
	result.custom_minimum_size = Vector2(44, 44)
	result.mouse_filter = Control.MOUSE_FILTER_PASS  # deixa rolar arrastando em cima do botão
	result.pressed.connect(on_pressed)
	Motion.press(result)
	return result


static func hbox(separation: int = 8) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box


static func vbox(separation: int = 8) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box


## Linha que quebra para a próxima quando não cabe (chips).
static func flow(separation: int = 6) -> HFlowContainer:
	var box := HFlowContainer.new()
	box.add_theme_constant_override("h_separation", separation)
	box.add_theme_constant_override("v_separation", separation)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box


## Barra de progresso com a cor dada.
static func bar(value: float, color: Color, height: int = 8) -> ProgressBar:
	var result := ProgressBar.new()
	result.show_percentage = false
	result.custom_minimum_size = Vector2(0, height)
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	result.value = value
	tint_bar(result, color)
	return result


static func tint_bar(target: ProgressBar, color: Color) -> void:
	var fill := target.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	fill.bg_color = color
	target.add_theme_stylebox_override("fill", fill)


## Chips de efeito numa necessidade: [osso +20] [coração +15].
static func effect_chips(effects: Dictionary) -> HFlowContainer:
	var row := flow()
	for item: Control in effect_chip_list(effects):
		row.add_child(item)
	return row


## Os mesmos chips de efeito, soltos (para entrar nos chips de uma `list_row`).
static func effect_chip_list(effects: Dictionary) -> Array[Control]:
	var chips: Array[Control] = []
	for need_id: String in effects:
		var amount := int(effects[need_id])
		chips.append(chip(Database.need_icon(need_id), "%+d" % amount, GOOD if amount > 0 else BAD))
	return chips


## Abas num trilho afundado; seleção branca com sombra, sem botão principal.
static func segmented(entries: Array[Dictionary], selected: String, choose: Callable) -> HBoxContainer:
	var row := hbox(0)
	row.custom_minimum_size.y = 48
	row.draw.connect(func() -> void: row.draw_style_box(surface(Palette.SUNKEN, 22), Rect2(Vector2.ZERO, row.size)))
	row.resized.connect(row.queue_redraw)
	for entry: Dictionary in entries:
		var id := str(entry.id)
		var tab := ghost(str(entry.text), choose.bind(id))
		tab.name = "NotebookTab_" + id
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tab.theme_type_variation = &"SmallButton"
		var active := id == selected
		var style := surface(Palette.CARD if active else Palette.SUNKEN, 22, active)
		style.set_content_margin_all(4)
		style.expand_margin_left = -4
		style.expand_margin_right = -4
		for phase: String in ["normal", "hover", "pressed", "hover_pressed"]:
			tab.add_theme_stylebox_override(phase, style)
		for phase: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			tab.add_theme_color_override(phase, Palette.INK if active else Palette.INK_SOFT)
		if entry.get("icon") is Texture2D and not entry.get("inline_icon", false):
			tab.icon = entry.icon
			tab.expand_icon = true
			tab.add_theme_constant_override("icon_max_width", 24)
		if entry.get("inline_icon", false):
			tab.text = ""
			var inline := hbox(4)
			inline.mouse_filter = Control.MOUSE_FILTER_IGNORE
			inline.alignment = BoxContainer.ALIGNMENT_CENTER
			inline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			inline.add_child(disc(entry.icon, 24, 24))
			inline.add_child(short_label(str(entry.text), &"ChipLabel", Palette.INK if active else Palette.INK_SOFT))
			tab.add_child(inline)
			tab.custom_minimum_size.x = inline.get_combined_minimum_size().x + 8
		row.add_child(tab)
		if entry.has("count") or entry.get("alert", false):
			var mark := badge(int(entry.get("count", 0)))
			mark.name = "NewBadge"
			tab.add_child(mark)
			mark.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			mark.position += Vector2(-12, -2)
	return row


## Quadrado neutro de inventário/álbum. Conteúdo ignora o mouse para manter toque e rolagem.
static func grid_tile(texture: Texture2D, title: String, action: Callable, px: int = 76, icon_px: int = 48) -> Button:
	var tile := button("", action, &"GhostButton")
	tile.custom_minimum_size = Vector2(px, px)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.CARD
	style.border_color = Palette.LINE
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	for state: String in ["normal", "hover", "pressed"]:
		tile.add_theme_stylebox_override(state, style)
	var body := vbox(0)
	body.name = "Visual"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 4
	body.offset_right = -4
	body.offset_top = 4
	body.offset_bottom = -4
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	var picture := icon(texture, icon_px)
	picture.name = "Picture"
	body.add_child(picture)
	if title != "":
		var caption := label(title, &"SmallLabel")
		caption.name = "Caption"
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(caption)
	tile.add_child(body)
	tile.pressed.connect(func() -> void: Motion.bounce(tile))
	return tile


## Progresso fino dos álbuns.
static func collection_progress(count: int, total: int) -> HBoxContainer:
	var row := hbox(8)
	var progress := bar(100.0 * count / maxi(1, total), Palette.GO, 8)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(progress)
	row.add_child(short_label("%d/%d" % [count, total], &"SmallLabel"))
	return row


## Superfície lisa compartilhada: nenhuma tela precisa montar um StyleBoxFlat.
static func surface(color: Color, radius: int, shadow: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	if shadow:
		style.shadow_color = Palette.SHADOW
		style.shadow_size = 4
		style.shadow_offset = Vector2(0, 2)
	return style


static func disc(texture: Texture2D, px: int = 44, icon_px: int = 32) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(px, px)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", surface(Palette.SUNKEN, px / 2))
	panel.add_child(icon(texture, icon_px))
	return panel


static func soft(text: String, on_pressed: Callable, texture: Texture2D = null, small: bool = false) -> Button:
	var result := button(text, on_pressed, &"SecondaryButton", texture)
	result.custom_minimum_size = Vector2(44, 44)
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return result


static func small_go(text: String, on_pressed: Callable) -> Button:
	var result := button(text, on_pressed, &"SmallGoButton")
	result.custom_minimum_size = Vector2(44, 44)
	return result


## O botão conserva 44 px de toque; a superfície menor é desenhada ao centro.
static func ctl_button(name: String, on_pressed: Callable, px: int = 40, surface_name: String = "card") -> Button:
	var result := button("", on_pressed, &"IconButton" if surface_name == "card" else &"CloseButton")
	for phase: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		result.add_theme_stylebox_override(phase, StyleBoxEmpty.new())
	var visual := PanelContainer.new()
	visual.name = "Disc"
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_theme_stylebox_override("panel", surface(Palette.CARD if surface_name == "card" else Palette.SUNKEN, px / 2, surface_name == "card"))
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(ctl(name, 22 if px >= 40 else 18))
	visual.add_child(center)
	result.add_child(visual)
	# Centralizado por âncoras (sem lambda em `resized`: ele disparava "Lambda capture was freed" ao recarregar painéis).
	visual.set_anchors_preset(Control.PRESET_CENTER)
	visual.offset_left = -px / 2.0
	visual.offset_right = px / 2.0
	visual.offset_top = -px / 2.0
	visual.offset_bottom = px / 2.0
	result.custom_minimum_size = Vector2(maxi(44, px), maxi(44, px))
	return result


static func list_card(parent: Control) -> VBoxContainer:
	var box := card(parent)
	box.add_theme_constant_override("separation", 0)
	var style := surface(Palette.CARD, 20, true)
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	(box.get_parent() as PanelContainer).add_theme_stylebox_override("panel", style)
	box.child_entered_tree.connect(func(child: Node) -> void:
		if child is Control and not child.has_meta("divider") and box.get_child_count() > 1:
			# Só ids atravessam o diferido: capturar nós liberados dispara "Lambda capture was freed".
			_add_divider.bind(box.get_instance_id(), child.get_instance_id()).call_deferred())
	return box


static func _add_divider(box_id: int, child_id: int) -> void:
	var box := instance_from_id(box_id) as Container
	var child := instance_from_id(child_id) as Control
	if box == null or child == null or child.get_parent() != box:
		return
	var line := ColorRect.new()
	line.name = "Divider"
	line.set_meta("divider", true)
	line.color = Palette.LINE
	line.custom_minimum_size.y = 1
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(line, true)
	box.move_child(line, child.get_index())


static func section(text: String, right: Control = null) -> HBoxContainer:
	var row := hbox(8)
	var title := fill_label(text, &"SmallLabel", Palette.INK_SOFT)
	title.uppercase = true
	title.add_theme_font_override("font", preload("res://assets/fonts/font_caption_spaced.tres"))
	row.add_child(title)
	if right:
		row.add_child(right)
	return row


static func _chip_colors(kind: String) -> Array[Color]:
	match kind:
		"prize": return [Palette.HONEY_SOFT, Palette.HONEY_INK]
		"time": return [Palette.SKY_SOFT, Palette.SKY_INK]
		"have": return [Palette.GO_SOFT, Palette.GO_INK]
		"missing": return [Palette.ALERT_SOFT, Palette.ALERT_INK]
	return [Palette.SUNKEN, Palette.INK]


static func badge(count: int, edge: Color = Palette.CARD) -> Label:
	var mark := short_label(str(count) if count > 0 else "", &"BadgeLabel", Palette.CARD)
	mark.custom_minimum_size = Vector2(20, 20) if count > 0 else Vector2(12, 12)
	mark.size = mark.custom_minimum_size
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := surface(Palette.ALERT, 12)
	style.border_color = edge
	style.set_border_width_all(2)
	mark.add_theme_stylebox_override("normal", style)
	if count <= 0:
		# Label preserva a altura da fonte mesmo vazio; o pontinho desenha só 12 px no centro.
		mark.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		mark.draw.connect(func() -> void:
			mark.draw_circle(mark.size / 2, 6, edge, true, -1, true)
			mark.draw_circle(mark.size / 2, 4, Palette.ALERT, true, -1, true))
		mark.resized.connect(mark.queue_redraw)
	return mark


static func dot() -> Control:
	return badge(0)


static func spark() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(22, 22)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", surface(Palette.HONEY, 11))
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(ctl("spark", 13, Palette.CARD))
	panel.add_child(center)
	return panel


static func ring(texture: Texture2D, progress: float, color: Color = Palette.SKY, px: int = 44) -> RingProgress:
	var result := RingProgress.new()
	result.custom_minimum_size = Vector2(px, px)
	result.texture = texture
	result.progress = progress
	result.color = color
	result.done_color = color
	return result


static func steps(total: int, current: int) -> HBoxContainer:
	var row := hbox(3)
	for i in total:
		var dash := Panel.new()
		dash.custom_minimum_size = Vector2(12, 6)
		dash.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dash.add_theme_stylebox_override("panel", surface(Palette.GO if i < current else (Palette.HONEY if i == current else Palette.SUNKEN), 3))
		row.add_child(dash)
	return row


static func stepper(value: int, min_value: int, max_value: int, on_change: Callable) -> HBoxContainer:
	var row := hbox(4)
	row.custom_minimum_size.y = 44
	row.draw.connect(func() -> void: row.draw_style_box(surface(Palette.SUNKEN, 22), Rect2(Vector2.ZERO, row.size)))
	row.resized.connect(row.queue_redraw)
	for delta: int in [-1, 1]:
		if delta == 1:
			row.add_child(short_label("×%d" % value, &"NumberLabel"))
		var control := ctl_button("minus" if delta < 0 else "plus", func() -> void: on_change.call(clampi(value + delta, min_value, max_value)), 36)
		control.name = "Minus" if delta < 0 else "Plus"
		control.disabled = value <= min_value if delta < 0 else value >= max_value
		if control.disabled:
			control.get_node("Disc").hide()
			var sign := ctl("minus" if delta < 0 else "plus", 20, Palette.INK_FAINT)
			control.add_child(sign)
			sign.position = Vector2(12, 12)
		row.add_child(control)
	return row


static func tile(texture: Texture2D, caption: String, state: String = "normal", missing: Texture2D = null) -> Button:
	var result := button("", func() -> void: pass, &"GhostButton")
	result.custom_minimum_size = Vector2(72, 76)
	# "sunken" = afundado sobre papel (Mochila); "worn" = vestido (Coleção): contorno de tinta sem sombra.
	var style := surface(Palette.CARD if state in ["selected", "worn"] else (Palette.SUNKEN if state == "sunken" else Palette.PAPER), 16, state == "selected")
	if state == "selected" or state == "worn":
		style.border_color = Palette.INK
		style.set_border_width_all(2)
		style.border_blend = true
	for phase: String in ["normal", "hover", "pressed", "hover_pressed"]:
		result.add_theme_stylebox_override(phase, style)
	var body := vbox(4)
	body.name = "Visual"
	result.add_child(body)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_top = 8
	body.offset_bottom = -8
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	var picture := icon(texture, 40)
	picture.name = "Picture"
	picture.modulate.a = 0.45 if state == "missing" else (0.35 if state == "locked" else 1.0)
	body.add_child(picture)
	var title := short_label(caption, &"SmallLabel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title)
	if state == "missing" and missing:
		var mark := disc(missing, 22, 16)
		mark.name = "Missing"
		mark.add_theme_stylebox_override("panel", surface(Palette.ALERT_SOFT, 11))
		result.add_child(mark)
		mark.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		mark.offset_left = -24.0
		mark.offset_right = -2.0
		mark.offset_top = 2.0
		mark.offset_bottom = 24.0
	if state == "locked":
		var lock := ctl("lock", 18)
		lock.name = "LockIcon"
		result.add_child(lock)
		lock.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lock.position -= Vector2(9, 9)
	return result


## Mini-cartão de depósito da Mochila (64 de altura): ícone, nome, `usado/limite` e barrinha de 6 px.
## Cheio (≥ 90%) = barra `ALERT`; acima do limite = número vermelho; filtrado = contorno de tinta.
static func depot_card(texture: Texture2D, caption: String, used: int, capacity: int, selected: bool, on_pressed: Callable) -> Button:
	var result := button("", on_pressed, &"GhostButton")
	result.custom_minimum_size = Vector2(0, 64)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := surface(Palette.CARD, 16, true)
	if selected:
		style.border_color = Palette.INK
		style.set_border_width_all(2)
		style.border_blend = true
	for phase: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		result.add_theme_stylebox_override(phase, style)
	var body := vbox(4)
	body.name = "Visual"
	result.add_child(body)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 10
	body.offset_right = -10
	body.offset_top = 6
	body.offset_bottom = -8
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	var top := hbox(8)
	top.add_child(icon(texture, 32))
	var words := vbox(0)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := label(caption, &"SmallLabel", Palette.INK_SOFT)
	name_label.name = "DepotName"
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.clip_text = true
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_child(name_label)
	var amount := short_label("%d/%d" % [used, capacity], &"NumberLabel", Palette.ALERT_INK if used > capacity else Palette.INK)
	amount.name = "DepotAmount"
	words.add_child(amount)
	top.add_child(words)
	body.add_child(top)
	var meter := bar(100.0 * used / maxi(1, capacity), Palette.ALERT if used >= capacity * 0.9 else Palette.SKY, 6)
	meter.name = "DepotBar"
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(meter)
	return result


## Quadrado de item da Mochila: ícone 40, quantidade num chip `×9` no canto de baixo e, se `fresh`,
## um pontinho mel no canto de cima (nó `NewBadge`). Sem texto de legenda.
static func bag_tile(texture: Texture2D, quantity: int, fresh: bool, on_pressed: Callable) -> Button:
	var result := tile(texture, "", "sunken")
	result.custom_minimum_size = Vector2(76, 76)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.pressed.connect(on_pressed)
	result.pressed.connect(func() -> void: Motion.bounce(result))
	var body := result.get_node("Visual") as Control
	body.offset_top = 6
	body.offset_bottom = -22
	body.get_child(1).visible = false
	var amount := chip(null, "×%d" % quantity)
	amount.name = "Quantity"
	result.add_child(amount)
	amount.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	amount.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	amount.grow_vertical = Control.GROW_DIRECTION_BEGIN
	amount.offset_left = -4.0
	amount.offset_right = -4.0
	amount.offset_top = -4.0
	amount.offset_bottom = -4.0
	if fresh:
		var dot := Panel.new()
		dot.name = "NewBadge"
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.custom_minimum_size = Vector2(10, 10)
		dot.size = Vector2(10, 10)
		dot.add_theme_stylebox_override("panel", surface(Palette.HONEY, 5))
		result.add_child(dot)
		dot.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		dot.offset_left = -16.0
		dot.offset_right = -6.0
		dot.offset_top = 6.0
		dot.offset_bottom = 16.0
	return result


static func toggle(on: bool, on_change: Callable) -> Button:
	var result := button("", func() -> void: pass, &"GhostButton")
	result.custom_minimum_size = Vector2(48, 44)
	result.toggle_mode = true
	result.button_pressed = on
	for phase: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		result.add_theme_stylebox_override(phase, StyleBoxEmpty.new())
	var track := Panel.new()
	track.name = "Track"
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.size = Vector2(48, 28)
	result.add_child(track)
	var knob := Panel.new()
	knob.name = "Knob"
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	knob.size = Vector2(22, 22)
	knob.add_theme_stylebox_override("panel", surface(Palette.CARD, 11, true))
	track.add_child(knob)
	var update := func(animate: bool) -> void:
		track.add_theme_stylebox_override("panel", surface(Palette.GO if result.button_pressed else Palette.SUNKEN, 14))
		var target := Vector2(23 if result.button_pressed else 3, 3)
		if result.has_meta("tween"):
			(result.get_meta("tween") as Tween).kill()
		if animate and not Motion.reduced:
			var tween := result.create_tween()
			tween.tween_property(knob, "position", target, 0.15)
			result.set_meta("tween", tween)
		else:
			knob.position = target
	result.resized.connect(func() -> void: track.position = (result.size - track.size) / 2)
	result.toggled.connect(func(value: bool) -> void:
		update.call(true)
		on_change.call(value))
	update.call(false)
	return result
