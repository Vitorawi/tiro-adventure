class_name WorldPill
extends Button
## Pílula do mundo atual sobre o mapa (canto de cima à esquerda): ícone do mundo + nome + setinha.
## Madeira ilustrada: aro de madeira com miolo creme (`world_pill.png`, gerado por `tools/world_pill_art.gd`; NinePatch 3x em escala 1/3, só o
## miolo liso estica) atrás do conteúdo; nome marrom na fonte da madeira; setinha desenhada em código.
## Tocar abre a folha de cartões-postais. O ícone do mundo é pixel (NEAREST, 32 px = escala 1).

const HEIGHT := 44
const MARGIN_LEFT := 10
const MARGIN_RIGHT := 34  # espaço da setinha desenhada à direita
const FONT_PX := 18
const ICON_PX := 32
const ART := "world_pill.png"

var world_id := ""
var _art: NinePatchRect


func _init() -> void:
	custom_minimum_size = Vector2(0, HEIGHT)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # o ícone do mundo é pixel; a pele liga o suave só nela
	add_theme_constant_override("icon_max_width", ICON_PX)
	add_theme_constant_override("h_separation", 8)
	theme = HomeUi.theme(FONT_PX)
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
		add_theme_color_override(color_name, Palette.WOOD_INK)
	# Todos os estados iguais e vazios: a madeira é a pele; só as margens mandam no tamanho mínimo.
	for state: String in ["normal", "hover", "disabled", "focus", "pressed", "hover_pressed"]:
		var empty := StyleBoxEmpty.new()
		empty.content_margin_left = MARGIN_LEFT
		empty.content_margin_right = MARGIN_RIGHT
		empty.content_margin_top = 2
		empty.content_margin_bottom = 2
		add_theme_stylebox_override(state, empty)
	_build_skin()
	Motion.press(self)
	set_world("house")


func _build_skin() -> void:
	_art = NinePatchRect.new()
	_art.name = "PillArt"
	_art.texture = load(HomeUi.DIR + ART) as Texture2D
	_art.patch_margin_left = 45
	_art.patch_margin_right = 45
	_art.patch_margin_top = 39
	_art.patch_margin_bottom = 39
	_art.scale = Vector2.ONE / 3.0
	_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# O NinePatch mede a soma das margens como mínimo: mora dentro de um Control liso (mínimo 0) que desenha ATRÁS do botão.
	var holder := Control.new()
	holder.name = "PillHolder"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.show_behind_parent = true
	holder.add_child(_art)
	add_child(holder)
	holder.resized.connect(func() -> void: _art.size = holder.size * 3.0)


## Mostra o mundo (nome curto do mapa e ícone).
func set_world(new_world_id: String) -> void:
	world_id = new_world_id
	var world: Dictionary = Database.worlds.get(world_id, {})
	text = str(world.get("map_name", world.get("name", "")))
	icon = UiKit.ui_icon(str(world.get("icon", "tab_map")))
	queue_redraw()


## Setinha para baixo ("há outros mundos"): chevron arredondado em código, sem depender de glifo da fonte.
func _draw() -> void:
	var center := Vector2(size.x - 19.0, size.y / 2.0 + 1.0)
	var points := PackedVector2Array([center + Vector2(-5.0, -2.5), center + Vector2(0.0, 2.5), center + Vector2(5.0, -2.5)])
	draw_polyline(points, Palette.WOOD_INK, 3.0, true)
	draw_circle(points[0], 1.5, Palette.WOOD_INK)
	draw_circle(points[2], 1.5, Palette.WOOD_INK)
