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
		# Só o próximo canteiro fechado tem etiqueta; os outros ficam só com o solo escurecido.
		if plot_index != GameState.accessible_plots():
			return
		var rect := Rect2(-21, -32, 42, 17)
		draw_style_box(_box(Color("73634a")), rect)
		var vovo := not GameState.has_upgrade("farm")
		var caption := "Vovó" if vovo else str(GameState.plot_cost(plot_index))
		var icon := UiKit.ui_icon("tab_farm" if vovo else "coin")
		var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 13.0
		var left := -width / 2.0
		if icon:
			draw_texture_rect(icon, Rect2(left, -29, 11, 11), false)
		draw_string(font, Vector2(left + 13.0, -20), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, cream)
		return
	draw_style_box(_box(dark), hit_rect)
	if _icon:
		draw_texture_rect(_icon, Rect2(-20, -60, 16, 16), false)
	var remaining := maxi(0, int(ceil(float(GameState.plot(plot_index)["ready_at"]) - GameState.now())))
	var caption := "Colher" if status == "ready" else SheetBuilder.format_time(remaining)
	draw_string(font, Vector2(-3, -49), caption, HORIZONTAL_ALIGNMENT_CENTER, 24, 8, cream)
	draw_rect(Rect2(-19, -44, 38, 4), Color("56645a"))
	draw_rect(Rect2(-19, -44, 38 * GameState.plot_progress(plot_index), 4), Color("a8db65") if status == "ready" else Color("efbb55"))
	# Gotinha balançando: planta crescendo ainda sem rega (toque no canteiro rega).
	if GameState.water_error(plot_index) == "":
		var drop := UiKit.ui_icon("action_water")
		if drop:
			var sway := sin(Time.get_ticks_msec() / 220.0) * 2.0
			draw_texture_rect(drop, Rect2(-12 + sway, -86, 24, 24), false)


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
