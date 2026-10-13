class_name StationIndicator
extends Node2D
## Aviso sobre estações/criações: tempo e barra; lotes prontos mostram Coletar.

var station_id: String = ""
var hit_rect := Rect2(-30, -26, 60, 25)


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	if station_id == "" or not GameState.has_upgrade(station_id):
		return
	var state := GameState.station(station_id)
	if state.queue.is_empty():
		return
	var now := GameState.now()
	var ready := state.ready_count(now)
	var entry: Dictionary = state.queue[0]
	var recipe: Dictionary = Database.recipes.get(entry.recipe, {})
	var remaining := maxi(0, ceili(float(entry.ready_at) - now))
	var seconds := maxf(1.0, float(recipe.get("seconds", 1)))
	var box := StyleBoxFlat.new()
	box.bg_color = Color("52653b") if ready > 0 else Color("29352d")
	box.set_corner_radius_all(3)
	box.set_border_width_all(1)
	box.border_color = Color("edc56b")
	draw_style_box(box, hit_rect)
	var text := "Coletar" if ready > 0 else TimeText.short(remaining)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(font, Vector2(-width / 2.0, -12), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("fff4d5"))
	draw_rect(Rect2(-25, -8, 50, 3), Color("56645a"))
	draw_rect(Rect2(-25, -8, 50 * clampf(1.0 - remaining / seconds, 0, 1), 3), Color("a8db65"))
