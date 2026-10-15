class_name WalkIndicator
extends WorldBalloon
## Aviso do passeio no portão da Praça.


func active() -> bool:
	return GameState.walking()


func refresh() -> void:
	visible = active()
	if not visible: return
	var entry: Dictionary = GameState.walk_state.current
	var remaining := GameState.walk_remaining()
	state = "ready" if GameState.walk_ready() else "progress"
	texture = UiKit.ui_icon("tab_park")
	progress = clampf(1.0 - remaining / maxf(1, float(entry.ready_at) - float(entry.started_at)), 0, 1)
	caption = TimeText.short(remaining)
	show_caption = state != "ready" and room_zoom >= 1.2
	queue_redraw()
