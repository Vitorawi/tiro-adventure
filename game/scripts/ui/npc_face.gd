class_name NpcFace
extends Button
## Rosto redondo de um personagem do mundo (coluna do canto direito do mapa): bolinha de madeira (`map_disc`) de 48
## com o retrato 40 dentro. Selo no canto: "!" (missão nova) ou o check verde (missão pronta).
## Sem nome escrito: o nome aparece no balão da fala. Tocar abre a conversa (`Places.open_npc`).

const SIZE := 48.0
const PORTRAIT_RADIUS := 20.0
const CIRCLE_POINTS := 40
const DISC := HomeUi.DIR + "map_disc.png"

var npc_id := ""
var badge := ""  # "", "new" ou "ready" (igual a `Places.npc_badge`)

var _portrait: Texture2D
var _pulse: Tween


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	size_flags_horizontal = Control.SIZE_SHRINK_END
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var empty := StyleBoxEmpty.new()
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, empty)
	Motion.press(self)


## Liga o rosto ao personagem e ao estado do selo.
func setup(new_npc_id: String, new_badge: String) -> void:
	npc_id = new_npc_id
	badge = new_badge
	name = "NpcFace_" + npc_id
	_portrait = ProgressionUi.npc_portrait(npc_id)
	for child: Node in get_children():
		child.queue_free()
	if badge == "new":
		var mark := Label.new()
		mark.theme_type_variation = &"BadgeLabel"
		mark.text = "!"
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.position = Vector2(SIZE - 18.0, -6.0)
		add_child(mark)
	elif badge == "ready":
		var check := UiKit.disc(UiKit.ctl_icon("check"), 20, 16)
		check.add_theme_stylebox_override("panel", UiKit.surface(Palette.GO, 10))
		check.position = Vector2(SIZE - 16, -4)
		check.get_child(0).modulate = Palette.CARD
		add_child(check)
	queue_redraw()


## Botão de ícone na mesma bolinha de madeira dos rostos (ex.: Lugares).
static func wood_button(icon_name: String, on_pressed: Callable) -> Button:
	var result := BagUi.plain_button(on_pressed)
	result.custom_minimum_size = Vector2(SIZE, SIZE)
	Motion.press(result)
	var disc := TextureRect.new()
	disc.name = "Disc"
	disc.texture = load(DISC) as Texture2D
	disc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	disc.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_child(disc)
	disc.set_anchors_preset(Control.PRESET_FULL_RECT)
	var icon := UiKit.ctl(icon_name, 24, Palette.WOOD_INK)
	result.add_child(icon)
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.offset_left = -12.0
	icon.offset_right = 12.0
	icon.offset_top = -12.0
	icon.offset_bottom = 12.0
	return result


func _start_pulse() -> void:
	if is_inside_tree() and _pulse == null:
		_pulse = Motion.pulse(self)


func _draw() -> void:
	var center := Vector2(SIZE, SIZE) / 2.0
	draw_texture_rect(load(DISC) as Texture2D, Rect2(Vector2.ZERO, Vector2(SIZE, SIZE)), false)
	if _portrait == null:
		return
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in CIRCLE_POINTS:
		var angle := TAU * i / CIRCLE_POINTS
		var unit := Vector2(cos(angle), sin(angle))
		points.append(center + unit * PORTRAIT_RADIUS)
		uvs.append(Vector2(0.5, 0.5) + unit * 0.5)
	draw_colored_polygon(points, Color.WHITE, uvs, _portrait)
