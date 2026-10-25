class_name WorldPill
extends Button
## Pílula do mundo atual sobre o mapa (canto de cima à esquerda): ícone do mundo + nome + seta.
## Disco branco com sombra e controle vetorial. Tocar abre a folha de cartões-postais.

const HEIGHT := 44
const MARGIN_LEFT := 8
const MARGIN_RIGHT := 32  # espaço da seta desenhada à direita

var world_id := ""


func _init() -> void:
	custom_minimum_size = Vector2(0, HEIGHT)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_theme_constant_override("icon_max_width", 32)
	add_theme_constant_override("h_separation", 6)
	theme_type_variation = &"StrongLabel"
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
		add_theme_color_override(color_name, Palette.INK)
	Motion.press(self)
	# O Button toma o MAIOR styleboxe de todos os estados como tamanho mínimo: todos iguais.
	set_world("house")


## Mostra o mundo (nome curto do mapa, ícone e cor da borda).
func set_world(new_world_id: String) -> void:
	world_id = new_world_id
	var world: Dictionary = Database.worlds.get(world_id, {})
	text = str(world.get("map_name", world.get("name", "")))
	icon = UiKit.ui_icon(str(world.get("icon", "tab_map")))
	for state: String in ["normal", "hover", "disabled", "focus"]:
		add_theme_stylebox_override(state, _style(Palette.CARD))
	for state: String in ["pressed", "hover_pressed"]:
		add_theme_stylebox_override(state, _style(Palette.SUNKEN))
	queue_redraw()


func _style(fill: Color) -> StyleBoxFlat:
	var box := UiKit.surface(fill, HEIGHT / 2, true)
	box.content_margin_left = MARGIN_LEFT
	box.content_margin_right = MARGIN_RIGHT
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	box.shadow_color = Palette.SHADE
	box.shadow_size = 3
	box.shadow_offset = Vector2(0, 2)
	return box


## Setinha para baixo ("há outros mundos"), desenhada para não depender de um glifo da fonte.
func _draw() -> void:
	draw_texture_rect(UiKit.ctl_icon("down"), Rect2(Vector2(size.x - 27, (size.y - 18) / 2), Vector2(18, 18)), false, Palette.INK_SOFT)
