class_name PlotIndicator
extends Node2D
## Indicador compacto no mundo. Não intercepta o toque/arrasto da sala.

var plot_index: int = 0
var hit_rect := Rect2(-22, -61, 44, 23)
var _icon: Texture2D


func refresh() -> void:
	var crop_id: String = GameState.plot(plot_index)["crop"]
	_icon = Database.item_icon(crop_id) if crop_id != "" else null
	queue_redraw()


func _draw() -> void:
	var status := GameState.plot_status(plot_index)
	if status == "empty":
		return
	var font := ThemeDB.fallback_font
	var dark := Color("29352d")
	var cream := Color("fff4d5")
	if status == "locked":
		var next := plot_index == GameState.unlocked_plots
		var rect := Rect2(-21, -32, 42, 17)
		draw_style_box(_box(Color("73634a") if next else Color("454c48")), rect)
		var caption := "+ %d" % GameState.plot_cost(plot_index) if next else "Depois"
		_center_text(font, caption, -20, cream, 10)
		return
	draw_style_box(_box(dark), hit_rect)
	if _icon:
		draw_texture_rect(_icon, Rect2(-20, -60, 16, 16), false)
	var remaining := maxi(0, int(ceil(float(GameState.plot(plot_index)["ready_at"]) - GameState.now())))
	var caption := "Colher" if status == "ready" else SheetBuilder.format_time(remaining)
	draw_string(font, Vector2(-3, -49), caption, HORIZONTAL_ALIGNMENT_CENTER, 24, 8, cream)
	draw_rect(Rect2(-19, -44, 38, 4), Color("56645a"))
	draw_rect(Rect2(-19, -44, 38 * GameState.plot_progress(plot_index), 4), Color("a8db65") if status == "ready" else Color("efbb55"))


func _center_text(font: Font, text: String, y: float, color: Color, font_size: int) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2(-width / 2.0, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(3)
	box.set_border_width_all(1)
	box.border_color = Color("b8ad88")
	return box
