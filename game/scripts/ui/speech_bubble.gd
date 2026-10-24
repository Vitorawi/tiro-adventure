class_name SpeechBubble
extends HBoxContainer
## Fala de personagem em balão: cartão `CARD` com "rabinho" apontando para o retrato (à esquerda)
## e a etiqueta com o nome sobre o canto de cima. O texto muda por `label.text`.

const TAIL_WIDTH := 10.0
const TAIL_SIZE := 9.0  # meia altura da base do rabinho

## Texto da fala (22), para quem precisa atualizá-lo.
var label: Label
var _tail: Control
var _inside := false


func _init(text: String = "", speaker: String = "", inside_card: bool = false) -> void:
	_inside = inside_card
	name = "SpeechBubble"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", -2)  # o rabinho cobre a borda do cartão
	_tail = Control.new()
	_tail.custom_minimum_size = Vector2(TAIL_WIDTH, 0.0)
	_tail.z_index = 1
	_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tail.draw.connect(_draw_tail)
	_tail.resized.connect(_tail.queue_redraw)
	add_child(_tail)
	var stack := UiKit.vbox(4)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(stack)
	if speaker != "":
		var tag_row := UiKit.hbox(0)
		tag_row.z_index = 1
		var indent := Control.new()
		indent.custom_minimum_size = Vector2(12, 0)
		indent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag_row.add_child(indent)
		var tag := UiKit.short_label(speaker, &"SmallLabel", Palette.INK_SOFT)
		tag.name = "NameTag"
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag_row.add_child(tag)
		stack.add_child(tag_row)
	var card := PanelContainer.new()
	card.theme_type_variation = &"CardPanel"
	var style := UiKit.surface(Palette.PAPER if inside_card else Palette.CARD, 16, not inside_card)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label = UiKit.label(text)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(label)
	stack.add_child(card)


func _draw_tail() -> void:
	var center_y := clampf(_tail.size.y - 32.0, TAIL_SIZE + 6.0, maxf(TAIL_SIZE + 6.0, _tail.size.y - TAIL_SIZE - 6.0))
	var points := PackedVector2Array([
		Vector2(0.0, center_y), Vector2(TAIL_WIDTH + 2.0, center_y - TAIL_SIZE), Vector2(TAIL_WIDTH + 2.0, center_y + TAIL_SIZE)])
	_tail.draw_colored_polygon(points, Palette.PAPER if _inside else Palette.CARD)
