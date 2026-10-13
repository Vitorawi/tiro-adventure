class_name RouteIndicator
extends Node2D
## Coletas do local: contador de prontos ou tempo do primeiro espaço.

var group: String = ""
var site: String = ""
var hit_rect := Rect2(-36, -29, 72, 28)


func jobs() -> Array[Dictionary]:
	if site != "":
		return GameState.gathering_jobs(site)
	var activity: Dictionary = GameState.progress.activity
	var result: Array[Dictionary] = []
	if not activity.is_empty() and Database.progression.activities.get(activity.id, {}).get("place", "") == group:
		result.append(activity)
	return result


func active() -> bool:
	return not jobs().is_empty()


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	var entries := jobs()
	if entries.is_empty():
		return
	var ready := 0
	var entry: Dictionary = entries[0]
	for candidate: Dictionary in entries:
		if float(candidate.ready_at) <= GameState.now():
			ready += 1
		if float(candidate.ready_at) < float(entry.ready_at):
			entry = candidate
	var remaining := maxi(0, ceili(float(entry.ready_at) - GameState.now()))
	var seconds := maxf(1, float(entry.ready_at) - float(entry.started_at))
	var box := StyleBoxFlat.new()
	box.bg_color = Color("52653b") if ready > 0 else Color("29352d")
	box.set_corner_radius_all(3)
	box.set_border_width_all(1)
	box.border_color = Color("edc56b")
	draw_style_box(box, hit_rect)
	var text := "Recolher %d" % ready if ready > 0 else TimeText.short(remaining)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(font, Vector2(-width / 2, -14), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("fff4d5"))
	draw_rect(Rect2(-28, -9, 56, 3), Color("56645a"))
	draw_rect(Rect2(-28, -9, 56 * clampf(1 - remaining / seconds, 0, 1), 3), Color("a8db65"))
