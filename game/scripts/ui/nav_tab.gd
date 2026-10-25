class_name NavTab
extends Control
## Rosto de uma aba do rodapé (madeira ilustrada): encaixe creme redondo com o ícone desenhado e a pílula com o nome
## embaixo, sobre a tábua lisa `TabBarArt`. A aba ativa sobe `LIFT` px (o encaixe com o ícone, a "almofada") com
## animação suave, junto com a pílula do nome; as outras ficam na posição normal. Fica dentro de um Button de alternância (TabButton):
## `NavTab.attach(botão)`.

const CUSHION := Vector2(72.0, 72.0)
const CUSHION_TOP := 3.0
const ICON := 46.0
const ICON_CENTER_Y := 36.0  # centro do encaixe (e do ícone) em relação ao topo do encaixe
const LIFT := 12.0
const LABEL := Rect2(-36.0, 70.0, 72.0, 26.0)
## Arte do ícone de cada aba, pelo nome que o botão já tinha.
const ART := {"Tiro": "tab_pet", "Mapa": "tab_map", "Missões": "tab_tasks", "Mochila": "tab_bag"}

var button: Button
var _cushion: Panel  # encaixe + ícone: é o que sobe, pulsa e pula
var _icon: TextureRect
var _title: Label
var _pill: TextureRect
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
	_cushion.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_cushion.anchor_left = 0.5
	_cushion.anchor_right = 0.5
	_cushion.offset_left = -CUSHION.x / 2.0
	_cushion.offset_right = CUSHION.x / 2.0
	_cushion.offset_top = CUSHION_TOP
	_cushion.offset_bottom = CUSHION_TOP + CUSHION.y
	_cushion.resized.connect(func() -> void: _cushion.pivot_offset = _cushion.size / 2.0)
	add_child(_cushion)
	var socket := TextureRect.new()
	socket.name = "Socket"
	socket.texture = _home().call("tex", "tab_socket")
	socket.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	socket.stretch_mode = TextureRect.STRETCH_SCALE
	socket.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	socket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	socket.size = CUSHION
	_cushion.add_child(socket)
	_icon = TextureRect.new()
	_icon.name = "Icon"
	_icon.texture = _home().call("tex", str(ART.get(title, ""))) if ART.has(title) else texture
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.position = _icon_rest()
	_icon.size = Vector2(ICON, ICON)
	_icon.pivot_offset = Vector2(ICON, ICON) / 2.0
	_cushion.add_child(_icon)
	# Pílula do nome: sobe junto com o encaixe na aba ativa.
	var pill := TextureRect.new()
	_pill = pill
	pill.name = "LabelPill"
	pill.texture = _home().call("tex", "tab_label")
	pill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pill.stretch_mode = TextureRect.STRETCH_SCALE
	pill.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.anchor_left = 0.5
	pill.anchor_right = 0.5
	pill.offset_left = LABEL.position.x
	pill.offset_right = LABEL.end.x
	pill.offset_top = LABEL.position.y
	pill.offset_bottom = LABEL.end.y
	add_child(pill)
	_title = Label.new()
	_title.name = "Title"
	_title.text = title
	_title.theme = _home().call("theme", 15, Palette.WOOD_INK)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title.anchor_left = 0.5
	_title.anchor_right = 0.5
	_title.offset_left = LABEL.position.x
	_title.offset_right = LABEL.end.x
	_title.offset_top = LABEL.position.y
	_title.offset_bottom = LABEL.end.y
	add_child(_title)


## `HomeUi` depende de autoloads: carregado por nome, para testes `-s` poderem citar `NavTab` por tipo.
func _home() -> GDScript:
	return load("res://scripts/ui/home_ui.gd") as GDScript


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


## O encaixe (com o ícone dentro): é o que sobe na aba ativa, pulsa (`Motion.pulse`) e pula quando a aba chama atenção.
func lift_node() -> Control:
	return _cushion


## Compatibilidade: opaca (alfa 1) na aba ativa, transparente nas outras.
func cushion_color() -> Color:
	return Color(1, 1, 1, 1.0 if _active else 0.0)


## Centro do encaixe em relação ao botão (o selo fica em centro + (30, −24)).
func icon_center() -> Vector2:
	return Vector2(button.size.x / 2.0, CUSHION_TOP + ICON_CENTER_Y)


## Altura (topo do encaixe) da aba na posição de repouso.
func rest_top() -> float:
	return CUSHION_TOP


func set_active(active: bool, animate: bool) -> void:
	_reset_icon_bounce()
	_active = active
	if _tween:
		_tween.kill()
	var lift := LIFT if active else 0.0
	var target := CUSHION_TOP - lift
	var label_y := LABEL.position.y - lift
	if not animate or Motion.reduced:
		_cushion.position.y = target
		_pill.position.y = label_y
		_title.position.y = label_y
		return
	_tween = create_tween().set_parallel()
	_tween.tween_property(_cushion, "position:y", target, Motion.TAB).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_pill, "position:y", label_y, Motion.TAB).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_title, "position:y", label_y, Motion.TAB).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Chegada de item à Mochila: pulinho do ícone.
func reward_arrived() -> void:
	bounce_icon()
