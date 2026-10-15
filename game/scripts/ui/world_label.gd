class_name WorldLabel
extends Label
## Pílula de lugar. Continua sendo Label para preservar as consultas dos testes.

var icon: Texture2D
var important := false
var world_id := "house"
var _fade: Tween
var _appearance: Tween
var _zoom := 1.0


func restyle() -> void:
	add_theme_font_size_override("font_size", 18)
	add_theme_color_override("font_color", Palette.INK)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(Palette.PAPER, 0.9)
	box.border_color = Palette.WORLD.get(world_id, Palette.CARD_LINE) if important else Palette.CARD_LINE
	box.set_border_width_all(2 if important else 0)
	box.set_corner_radius_all(12)
	box.content_margin_left = 26 if icon else 8
	box.content_margin_right = 8
	box.content_margin_top = 3
	box.content_margin_bottom = 3
	add_theme_stylebox_override("normal", box)
	reset_size()
	queue_redraw()


func reveal(value: bool) -> void:
	if value:
		if _fade and _fade.is_running(): _fade.kill()
		modulate.a = 1.0
		if not visible:
			show()
			_appearance = Motion.pop_in(self, Vector2.ONE / _zoom)
	elif visible and (not _fade or not _fade.is_running()):
		if Motion.reduced:
			hide()
		else:
			_fade = create_tween()
			_fade.tween_property(self, "modulate:a", 0.0, Motion.POP_OUT)
			_fade.tween_callback(hide)


func set_world_zoom(value: float) -> void:
	if not is_equal_approx(value, _zoom):
		if _appearance and _appearance.is_running(): _appearance.kill()
	_zoom = value
	if not _appearance or not _appearance.is_running(): scale = Vector2.ONE / value


func _draw() -> void:
	if icon: draw_texture_rect(icon, Rect2(6, (size.y - 16) / 2, 16, 16), false)
