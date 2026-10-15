class_name NavTab
extends Control
## Rosto de uma aba da barra inferior: ícone + nome. A aba ativa ganha um círculo `PAPER` atrás do
## ícone, que cresce (32 → 36) e sobe 6 px; o nome fica em 100% (as outras, em 70%).
## Fica dentro de um Button de alternância (TabButton): `NavTab.attach(botão, ícone, nome)`.

const CIRCLE := 52.0
const ICON_BASE := 32.0
const ICON_ACTIVE := 36.0
const LIFT := 6.0
const ICON_CENTER_Y := 30.0  # centro do ícone com a aba em repouso
const TEXT_CENTER_Y := 60.0
const FADED := 0.7

var button: Button
var _lift: Control  # círculo + ícone: sobe junto
var _circle: Panel
var _icon: TextureRect
var _title: Label
var _active := false
var _tween: Tween


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
	_lift = Control.new()
	_lift.name = "Lift"
	_lift.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lift.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lift.resized.connect(func() -> void: _lift.pivot_offset = _lift.size / 2.0)  # o pulso gira pelo centro da aba
	add_child(_lift)
	_circle = Panel.new()
	_circle.name = "Circle"
	_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PAPER
	style.set_corner_radius_all(int(CIRCLE / 2.0))
	_circle.add_theme_stylebox_override("panel", style)
	_circle.modulate.a = 0.0
	_center_at(_circle, CIRCLE, ICON_CENTER_Y)
	_lift.add_child(_circle)
	_icon = TextureRect.new()
	_icon.name = "Icon"
	_icon.texture = texture
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center_at(_icon, ICON_ACTIVE, ICON_CENTER_Y)
	_icon.pivot_offset = Vector2(ICON_ACTIVE, ICON_ACTIVE) / 2.0
	_icon.scale = Vector2.ONE * (ICON_BASE / ICON_ACTIVE)
	_lift.add_child(_icon)
	_title = Label.new()
	_title.name = "Title"
	_title.text = title
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 18)
	_title.add_theme_color_override("font_color", Palette.INK_ON_DARK)
	_title.anchor_left = 0.0
	_title.anchor_right = 1.0
	_title.offset_top = TEXT_CENTER_Y - 12.0
	_title.offset_bottom = TEXT_CENTER_Y + 12.0
	_title.modulate.a = FADED
	add_child(_title)


## Caixa de `px` pixels centrada na horizontal da aba, com o centro vertical em `center_y`.
func _center_at(node: Control, px: float, center_y: float) -> void:
	node.anchor_left = 0.5
	node.anchor_right = 0.5
	node.offset_left = -px / 2.0
	node.offset_right = px / 2.0
	node.offset_top = center_y - px / 2.0
	node.offset_bottom = center_y + px / 2.0


func is_active() -> bool:
	return _active


## O ícone (o selo da aba se alinha a ele).
func icon_node() -> TextureRect:
	return _icon


## Círculo + ícone, que sobem juntos: é o que pulsa (`Motion.pulse`) quando a aba chama atenção.
func lift_node() -> Control:
	return _lift


## Centro do ícone em relação ao botão (o selo fica em centro + (14, −20)).
func icon_center() -> Vector2:
	return Vector2(button.size.x / 2.0, ICON_CENTER_Y - (LIFT if _active else 0.0))


func set_active(active: bool, animate: bool) -> void:
	var changed := active != _active
	_active = active
	if _tween:
		_tween.kill()
	var lift_y := -LIFT if active else 0.0
	var icon_scale := Vector2.ONE * (1.0 if active else ICON_BASE / ICON_ACTIVE)
	var alpha := 1.0 if active else 0.0
	var text_alpha := 1.0 if active else FADED
	if not animate or Motion.reduced:
		_lift.position.y = lift_y
		_icon.scale = icon_scale
		_circle.modulate.a = alpha
		_title.modulate.a = text_alpha
		return
	_tween = create_tween().set_parallel()
	_tween.tween_property(_lift, "position:y", lift_y, Motion.TAB).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_icon, "scale", icon_scale, Motion.TAB)
	_tween.tween_property(_circle, "modulate:a", alpha, Motion.TAB)
	_tween.tween_property(_title, "modulate:a", text_alpha, Motion.TAB)
	if active and changed:
		_tween.chain().tween_callback(func() -> void: Motion.bounce(_icon))
