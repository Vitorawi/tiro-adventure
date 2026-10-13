class_name UiKit
extends RefCounted
## Peças de interface reutilizáveis, já com as variações do tema
## (assets/theme/main_theme.tres): ícones, chips, cartões e botões.
## Ícones são pixel art de 32 px: usar tamanhos inteiros (32, 64) para ficarem nítidos.

const ICON_DIR := "res://assets/sprites/ui/icons/"
const GOOD := Color(0.24, 0.55, 0.16)
const BAD := Color(0.78, 0.22, 0.18)


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


## Botão quadrado só com ícone ou um símbolo curto (ex.: "?").
static func square_button(text: String, on_pressed: Callable, texture: Texture2D = null, px: int = 52) -> Button:
	var result := button(text, on_pressed, &"", texture)
	result.custom_minimum_size = Vector2(px, px)
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if texture:
		result.expand_icon = true
		result.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result.add_theme_constant_override("icon_max_width", 32)
	return result


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
	for need_id: String in effects:
		var amount := int(effects[need_id])
		row.add_child(chip(Database.need_icon(need_id), "%+d" % amount, GOOD if amount > 0 else BAD))
	return row
