class_name WalkIndicator
extends WorldBalloon
## Aviso do passeio no portão da Praça: viagem em curso (anel de tempo) ou bagagem esperando (pronto).


func active() -> bool:
	return GameState.walk_state.active() or GameState.walk_ready()


func refresh() -> void:
	visible = active()
	if not visible: return
	texture = UiKit.ui_icon("tab_park")
	if GameState.walk_ready():
		state = "ready"
		progress = 1.0
		caption = ""
		show_caption = false
		super.refresh()
		return
	var entry: Dictionary = GameState.walk_state.current
	var remaining := GameState.walk_remaining()
	state = "ready" if remaining == 0 else "progress"
	progress = clampf(1.0 - remaining / maxf(1, float(entry.ready_at) - float(entry.started_at)), 0, 1)
	caption = TimeText.short(remaining)
	show_caption = state != "ready" and room_zoom >= 1.2
	super.refresh()
