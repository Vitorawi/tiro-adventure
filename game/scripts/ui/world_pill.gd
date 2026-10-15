class_name WorldPill
extends Button
## Pílula do mundo atual sobre o mapa (canto de cima à esquerda): ícone do mundo + nome + seta.
## Fundo `PAPER` com borda 2 na cor do mundo (`Palette.WORLD`). Tocar abre a lista de mundos.

const HEIGHT := 44
const BORDER := 2
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
	add_theme_font_size_override("font_size", 22)
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
	var line: Color = Palette.WORLD.get(world_id, Palette.CARD_LINE)
	add_theme_stylebox_override("normal", _style(Palette.PAPER, line))
	add_theme_stylebox_override("hover", _style(Palette.PAPER, line))
	add_theme_stylebox_override("pressed", _style(Palette.SUNKEN, line))
	add_theme_stylebox_override("hover_pressed", _style(Palette.SUNKEN, line))
	add_theme_stylebox_override("disabled", _style(Palette.PAPER, line))
	add_theme_stylebox_override("focus", _style(Palette.PAPER, line))
	queue_redraw()


func _style(fill: Color, line: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = line
	box.set_border_width_all(BORDER)
	box.set_corner_radius_all(HEIGHT / 2)
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
	var middle := size.y / 2.0
	var right := size.x - 16.0
	draw_colored_polygon(PackedVector2Array([Vector2(right - 8, middle - 3), Vector2(right + 8, middle - 3), Vector2(right, middle + 5)]), Palette.INK_SOFT)
