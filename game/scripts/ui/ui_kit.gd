class_name UiKit
extends RefCounted
## Peças de interface reutilizáveis, já com as variações do tema
## (assets/theme/main_theme.tres): ícones, chips, cartões e botões.
## Ícones são pixel art de 32 px: usar tamanhos inteiros (32, 64) para ficarem nítidos.

const ICON_DIR := "res://assets/sprites/ui/icons/"
const GOOD := Palette.GOOD
const BAD := Palette.BAD


static func ui_icon(icon_name: String) -> Texture2D:
	var path := ICON_DIR + icon_name + ".png"
	return load(path) if ResourceLoader.exists(path) else null


static func icon(texture: Texture2D, px: int = 32) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(px, px)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


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
static func chip(texture: Texture2D, text: String, color: Variant = null) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"ChipPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := hbox(2)
	if texture:
		row.add_child(icon(texture, 32))
	var text_label := label(text, &"", color)
	text_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(text_label)
	panel.add_child(row)
	return panel


## Chip tocável (ex.: ingrediente que falta: tocar mostra de onde ele vem).
static func tap_chip(texture: Texture2D, text: String, on_pressed: Callable, color: Variant = null) -> Button:
	var result := button(text, on_pressed, &"ChipButton", texture)
	result.custom_minimum_size = Vector2(0, 44)
	result.add_theme_constant_override("icon_max_width", 32)
	if color is Color:
		for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			result.add_theme_color_override(state, color)
	return result


## Botão redondo só com ícone ou um símbolo curto (ex.: "?", "↔"): círculo `CARD` com borda fina.
## Alvo de toque = `px` (o desenho é o círculo inteiro).
static func icon_button(texture: Texture2D, on_pressed: Callable, px: int = 44, text: String = "") -> Button:
	var result := button(text, on_pressed, &"IconButton", texture)
	result.custom_minimum_size = Vector2(px, px)
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if texture:
		result.expand_icon = true
		result.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result.add_theme_constant_override("icon_max_width", 32)
	return result


## Mesma peça de antes (assinatura antiga), agora um `icon_button`.
static func square_button(text: String, on_pressed: Callable, texture: Texture2D = null, px: int = 52) -> Button:
	return icon_button(texture, on_pressed, px, text)


## O botão principal da tela/painel (verde). Só um por vez: listas usam `secondary(..., small = true)`.
static func primary(text: String, on_pressed: Callable, texture: Texture2D = null) -> Button:
	return button(text, on_pressed, &"PrimaryButton", texture)


## Ação alternativa (mel). `small` = linha de lista (altura 44).
static func secondary(text: String, on_pressed: Callable, texture: Texture2D = null, small: bool = false) -> Button:
	var result := button(text, on_pressed, &"SecondaryButton", texture)
	if small:
		result.custom_minimum_size = Vector2(0, 44)
		result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return result


## Ação fraca ("Ver tudo", "Cancelar"): sem fundo, texto suave sublinhado.
static func ghost(text: String, on_pressed: Callable) -> Button:
	var result := button(text, on_pressed, &"GhostButton")
	result.custom_minimum_size = Vector2(0, 44)
	return result


## Pílula escura do HUD sobre o mundo: ícone + número com contorno.
static func pill(texture: Texture2D, text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"PillPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := hbox(4)
	if texture:
		row.add_child(icon(texture, 32))
	var number := label(text, &"NumberLabel")
	number.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(number)
	panel.add_child(row)
	return panel


## Cadeado de 32 px (`ui_lock`), usado no `lock_hint` e nos cartões fechados.
static func lock_icon(px: int = 32) -> TextureRect:
	var lock := icon(ui_icon("ui_lock"), px)
	lock.name = "LockIcon"
	return lock


## "Ainda não dá": cadeado + motivo curto (+ "?" se houver `on_help`). Substitui o botão cinza largo.
static func lock_hint(text: String, on_help: Callable = Callable()) -> HBoxContainer:
	var row := hbox(8)
	row.name = "LockHint"
	row.add_child(lock_icon())
	row.add_child(fill_label(text, &"SmallLabel"))
	if on_help.is_valid():
		row.add_child(icon_button(null, on_help, 44, "?"))
	return row


## Espaço de produção compacto: bolinha de 56 px + legenda. `state` = SlotDot.EMPTY/QUEUED/BUSY/READY/BUY/LEVEL;
## `progress` 0..1 (em BUY, 1 = dá para comprar agora); `caption_icon` vai antes da legenda (moeda do preço).
static func slot_dot(state: String, texture: Texture2D = null, progress: float = 0.0, caption: String = "", caption_color: Variant = null, caption_icon: Texture2D = null) -> SlotDot:
	return SlotDot.new(state, texture, progress, caption, caption_color, caption_icon)


## Linha baixa de lista: [ícone 48] [título] [ação à direita] e, embaixo, os chips na largura toda (quebram se faltar espaço).
## Toque na linha = `on_tap` (opcional).
## O corpo (VBox, filho 0) aceita rodapés, como o `lock_hint` de uma linha fechada.
static func list_row(texture: Texture2D, title: String, chips: Array[Control], action: Control = null, on_tap: Callable = Callable()) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"RowPanel"  # cartão com margens menores (8 em cima e embaixo)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 64)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var body := vbox(2)
	panel.add_child(body)
	var top := hbox(8)
	top.add_child(icon(texture, 48))
	var name_label := fill_label(title)
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(name_label)
	if action:
		action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		top.add_child(action)
	body.add_child(top)
	if not chips.is_empty():
		var chip_row := flow(2)
		for chip_control: Control in chips:
			chip_row.add_child(chip_control)
		body.add_child(chip_row)
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


static func button(text: String, on_pressed: Callable, variation: StringName = &"", texture: Texture2D = null) -> Button:
	var result := Button.new()
	result.text = text
	result.theme_type_variation = variation
	result.icon = texture
	result.custom_minimum_size = Vector2(0, 52)
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
static func bar(value: float, color: Color, height: int = 14) -> ProgressBar:
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
