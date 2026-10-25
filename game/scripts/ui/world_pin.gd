class_name WorldPin
extends Node2D
## Alfinete de destino. A origem é a âncora antiga; ground_offset mantém o anel na base real.

var texture: Texture2D
var ground_offset := Vector2.ZERO
var _elapsed := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	_elapsed += delta
	queue_redraw()


func _draw() -> void:
	var bob := 0.0 if Motion.reduced else sin(_elapsed * TAU / 1.4) * 6.0
	var center := Vector2(0, -38 + bob)
	# As elipses usam pontos próprios: não deformam a espessura do traço.
	_ellipse(ground_offset, Vector2(44, 16), 1.0, 0.18, 1.0)
	if not Motion.reduced:
		var phase := fmod(_elapsed, 1.2) / 1.2
		_ellipse(ground_offset, Vector2(44, 16), 1.0 + 0.25 * phase, 0.0, 0.5 * (1.0 - phase))
	draw_circle(center + Vector2(0, 3), 28, Palette.SHADOW)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-9, 20), center + Vector2(0, 38), center + Vector2(9, 20)]), Palette.HONEY)
	draw_circle(center, 26, Palette.CARD)
	draw_arc(center, 24, 0, TAU, 64, Palette.HONEY, 4, true)
	if texture:
		draw_texture_rect(texture, Rect2(center - Vector2(18, 18), Vector2(36, 36)), false)


func _ellipse(center: Vector2, radius: Vector2, factor: float, fill: float, alpha: float) -> void:
	var points := PackedVector2Array()
	for i: int in 49:
		var angle := TAU * i / 48.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius * factor)
	if fill > 0: draw_colored_polygon(points, Color(Palette.HONEY, fill))
	draw_polyline(points, Color(Palette.HONEY, alpha), 3, true)


static func destination_icon(world: String, action: String) -> Texture2D:
	if action.begins_with("npc:"):
		return ProgressionUi.npc_portrait(action.trim_prefix("npc:"))
	if action.begins_with("buy:"):
		return UiKit.ui_icon(str(Database.progression.upgrades.get(action.trim_prefix("buy:"), {}).get("icon", "")))
	if action == "plot" or action.begins_with("plot:"):
		return UiKit.ui_icon("action_water")
	if action == "find": return UiKit.ui_icon("find_paw")
	return UiKit.ui_icon(str(Database.worlds.get(world, {}).get("places", {}).get(action.trim_prefix("place:"), {}).get("icon", "tab_map")))
