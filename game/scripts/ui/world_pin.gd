class_name WorldPin
extends Node2D
## Alfinete de destino. A origem é a âncora antiga; ground_offset mantém o anel na base real.

var texture: Texture2D:
	set(value):
		texture = value
		if _body != null: _body.queue_redraw()
var ground_offset := Vector2.ZERO:
	set(value):
		if value == ground_offset: return
		ground_offset = value
		queue_redraw()
		if _pulse != null: _pulse.queue_redraw()
var _elapsed := 0.0
var _body := Node2D.new()
var _pulse := Node2D.new()


## O anel base e o balão são desenhados uma vez; o balanço é um tween de posição no `_body`
## e só o anel que se expande (nó `_pulse`, uma polilinha) redesenha a cada quadro.
func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_body.draw.connect(_draw_body)
	_pulse.draw.connect(_draw_pulse)
	add_child(_pulse)
	add_child(_body)
	if not Motion.reduced:
		var bob := _body.create_tween().set_loops()
		bob.tween_property(_body, "position:y", 6.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		bob.tween_property(_body, "position:y", -6.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bob.tween_property(_body, "position:y", 0.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	else:
		set_process(false)


func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	_elapsed += delta
	_pulse.queue_redraw()


func _draw() -> void:
	_ellipse(self, ground_offset, Vector2(44, 16), 1.0, 0.18, 1.0)


func _draw_pulse() -> void:
	if Motion.reduced: return
	var phase := fmod(_elapsed, 1.2) / 1.2
	_ellipse(_pulse, ground_offset, Vector2(44, 16), 1.0 + 0.25 * phase, 0.0, 0.5 * (1.0 - phase))


func _draw_body() -> void:
	var center := Vector2(0, -38)
	_body.draw_circle(center + Vector2(0, 3), 28, Palette.SHADOW)
	_body.draw_colored_polygon(PackedVector2Array([center + Vector2(-9, 20), center + Vector2(0, 38), center + Vector2(9, 20)]), Palette.HONEY)
	_body.draw_circle(center, 26, Palette.CARD)
	_body.draw_arc(center, 24, 0, TAU, 64, Palette.HONEY, 4, true)
	if texture:
		_body.draw_texture_rect(texture, Rect2(center - Vector2(18, 18), Vector2(36, 36)), false)


func _ellipse(canvas: CanvasItem, center: Vector2, radius: Vector2, factor: float, fill: float, alpha: float) -> void:
	var points := PackedVector2Array()
	for i: int in 49:
		var angle := TAU * i / 48.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius * factor)
	if fill > 0: canvas.draw_colored_polygon(points, Color(Palette.HONEY, fill))
	canvas.draw_polyline(points, Color(Palette.HONEY, alpha), 3, true)


static func destination_icon(world: String, action: String) -> Texture2D:
	if action.begins_with("npc:"):
		return ProgressionUi.npc_portrait(action.trim_prefix("npc:"))
	if action.begins_with("buy:"):
		return UiKit.ui_icon(str(Database.progression.upgrades.get(action.trim_prefix("buy:"), {}).get("icon", "")))
	if action == "plot" or action.begins_with("plot:"):
		return UiKit.ui_icon("action_water")
	if action == "find": return UiKit.ui_icon("find_paw")
	return UiKit.ui_icon(str(Database.worlds.get(world, {}).get("places", {}).get(action.trim_prefix("place:"), {}).get("icon", "tab_map")))
