class_name NpcFace
extends Button
## Rosto redondo de um personagem do mundo (coluna do canto direito do mapa): círculo de 48 com o
## retrato e borda `PAPER`. Selo no canto: "!" (missão nova) ou o check verde (missão pronta).
## Sem nome escrito: o nome aparece no balão da fala. Tocar abre a conversa (`Places.open_npc`).

const SIZE := 48.0
const PORTRAIT_RADIUS := 21.0
const CIRCLE_POINTS := 40

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
		var check := UiKit.icon(UiKit.ui_icon("ui_check"), 32)
		check.position = Vector2(SIZE - 24.0, -10.0)
		check.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(check)
	if badge == "ready" and not Motion.reduced:
		_start_pulse.call_deferred()  # o pivô no centro só vale depois do layout
	queue_redraw()


func _start_pulse() -> void:
	if is_inside_tree() and _pulse == null:
		_pulse = Motion.pulse(self)


func _draw() -> void:
	var center := Vector2(SIZE, SIZE) / 2.0
	draw_circle(center + Vector2(0, 2), SIZE / 2.0, Palette.SHADE)
	draw_circle(center, SIZE / 2.0, Palette.PAPER)
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
