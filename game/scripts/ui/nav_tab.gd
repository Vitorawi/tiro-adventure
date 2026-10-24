class_name NavTab
extends Control
## Rosto de uma aba do rodapé (Interface 2): almofada 60×38 com o ícone pixel 32 e o nome embaixo.
## A aba ativa ganha a almofada `TAB_ON` e o nome em `INK`; as outras ficam sem fundo e com `INK_SOFT`.
## Nada sobe nem cresce. Fica dentro de um Button de alternância (TabButton): `NavTab.attach(botão)`.

const CUSHION := Vector2(60.0, 38.0)
const ICON := 32.0
const ICON_CENTER_Y := 19.0  # centro da almofada (e do ícone) em relação ao botão
const TITLE_TOP := 40.0

var button: Button
var _cushion: Panel  # almofada + ícone: é o que pulsa/pula
var _style: StyleBoxFlat
var _icon: TextureRect
var _title: Label
var _active := false
var _tween: Tween
var _icon_bounce: Tween


## Cria o rosto e liga ao botão (o `toggled` do botão anima). Devolve o rosto.
static func attach(button: Button) -> NavTab:
	var face := NavTab.new()
	face.button = button
	var texture := button.icon
	var title := button.text
	button.text = ""
	button.icon = null
	button.add_child(face)
	face._build(texture, title)
	button.toggled.connect(func(pressed: bool) -> void: face.set_active(pressed, true))
	face.set_active(button.button_pressed, false)
	return face


func _build(texture: Texture2D, title: String) -> void:
	name = "Face"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cushion = Panel.new()
	_cushion.name = "Cushion"
	_cushion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style = StyleBoxFlat.new()
	_style.bg_color = Color(Palette.TAB_ON, 0.0)
	_style.set_corner_radius_all(int(CUSHION.y / 2.0))
	_cushion.add_theme_stylebox_override("panel", _style)
	_cushion.anchor_left = 0.5
	_cushion.anchor_right = 0.5
	_cushion.offset_left = -CUSHION.x / 2.0
	_cushion.offset_right = CUSHION.x / 2.0
	_cushion.offset_top = 0.0
	_cushion.offset_bottom = CUSHION.y
	_cushion.resized.connect(func() -> void: _cushion.pivot_offset = _cushion.size / 2.0)
	add_child(_cushion)
	_icon = TextureRect.new()
	_icon.name = "Icon"
	_icon.texture = texture
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.position = _icon_rest()
	_icon.size = Vector2(ICON, ICON)
	_icon.pivot_offset = Vector2(ICON, ICON) / 2.0
	_cushion.add_child(_icon)
	_title = Label.new()
	_title.name = "Title"
	_title.text = title
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_title.theme_type_variation = &"SmallLabel"
	_title.anchor_left = 0.0
	_title.anchor_right = 1.0
	_title.offset_top = TITLE_TOP
	_title.offset_bottom = TITLE_TOP + 18.0
	add_child(_title)


func _icon_rest() -> Vector2:
	return (CUSHION - Vector2(ICON, ICON)) / 2.0


func is_active() -> bool:
	return _active


## O ícone (o selo da aba se alinha a ele).
func icon_node() -> TextureRect:
	return _icon


## Toques rápidos reiniciam o pulinho na posição de repouso, sem acumular altura.
func bounce_icon() -> void:
	_reset_icon_bounce()
	_icon_bounce = Motion.bounce(_icon)


func _reset_icon_bounce() -> void:
	if _icon_bounce:
		_icon_bounce.kill()
	_icon.position = _icon_rest()


## A almofada (com o ícone dentro): é o que pulsa (`Motion.pulse`) e pula quando a aba chama atenção.
func lift_node() -> Control:
	return _cushion


## Cor atual do fundo da almofada (`TAB_ON` na aba ativa, transparente nas outras).
func cushion_color() -> Color:
	return _style.bg_color


## Centro da almofada em relação ao botão (o selo fica em centro + (22, −16)).
func icon_center() -> Vector2:
	return Vector2(button.size.x / 2.0, ICON_CENTER_Y)


func set_active(active: bool, animate: bool) -> void:
	_reset_icon_bounce()
	_active = active
	if _tween:
		_tween.kill()
	var fill := Color(Palette.TAB_ON, 1.0 if active else 0.0)
	var ink := Palette.INK if active else Palette.INK_SOFT
	if not animate or Motion.reduced:
		_style.bg_color = fill
		_title.add_theme_color_override("font_color", ink)
		_cushion.queue_redraw()
		return
	_tween = create_tween().set_parallel()
	_tween.tween_method(func(color: Color) -> void:
		_style.bg_color = color
		_cushion.queue_redraw(), _style.bg_color, fill, Motion.TAB)
	_tween.tween_method(func(color: Color) -> void: _title.add_theme_color_override("font_color", color), _title.get_theme_color("font_color"), ink, Motion.TAB)

## Chegada de item à Mochila: pulinho e almofada mel, voltando à seleção atual.
func reward_arrived() -> void:
	bounce_icon()
	if Motion.reduced: return
	_style.bg_color = Palette.TAB_ON
	_cushion.queue_redraw()
	get_tree().create_timer(0.6).timeout.connect(func() -> void: set_active(_active, false))
