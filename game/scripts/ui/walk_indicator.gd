class_name WalkIndicator
extends Node2D
## Aviso no portão da Praça: tempo e barra do passeio; pronto mostra "Recolher".

var hit_rect := Rect2(-30, -26, 60, 25)


func active() -> bool:
	return GameState.walking()


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	if not GameState.walking():
		return
	var entry: Dictionary = GameState.walk_state.current
	var remaining := GameState.walk_remaining()
	var ready := GameState.walk_ready()
	var seconds := maxf(1.0, float(entry.ready_at) - float(entry.started_at))
	var box := StyleBoxFlat.new()
	box.bg_color = Color("52653b") if ready else Color("29352d")
	box.set_corner_radius_all(3)
	box.set_border_width_all(1)
	box.border_color = Color("edc56b")
	draw_style_box(box, hit_rect)
	var text := "Recolher" if ready else TimeText.short(remaining)
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(font, Vector2(-width / 2.0, -12), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("fff4d5"))
	draw_rect(Rect2(-25, -8, 50, 3), Color("56645a"))
	draw_rect(Rect2(-25, -8, 50 * clampf(1.0 - remaining / seconds, 0, 1), 3), Color("a8db65"))
