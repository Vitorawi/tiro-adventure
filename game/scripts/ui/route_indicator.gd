class_name RouteIndicator
extends Node2D
## Tempo/coleta da exploração sobre seu destino no mapa.

var group: String = ""
var hit_rect := Rect2(-34, -29, 68, 28)


func active() -> bool:
	var activity: Dictionary = GameState.progress.activity
	return not activity.is_empty() and Database.progression.activities.get(activity.id, {}).get("place", "") == group


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	if not active():
		return
	var remaining := GameState.activity_remaining()
	var activity: Dictionary = GameState.progress.activity
	var seconds := maxf(1, float(activity.ready_at) - float(activity.started_at))
	var box := StyleBoxFlat.new()
	box.bg_color = Color("52653b") if remaining == 0 else Color("29352d")
	box.set_corner_radius_all(3)
	box.set_border_width_all(1)
	box.border_color = Color("edc56b")
	draw_style_box(box, hit_rect)
	var text := "Recolher" if remaining == 0 else TimeText.short(remaining)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(font, Vector2(-width / 2, -14), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("fff4d5"))
	draw_rect(Rect2(-28, -9, 56, 3), Color("56645a"))
	draw_rect(Rect2(-28, -9, 56 * clampf(1 - remaining / seconds, 0, 1), 3), Color("a8db65"))
