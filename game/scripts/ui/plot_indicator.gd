class_name PlotIndicator
extends WorldBalloon
## Crescimento e colheita usam o mesmo balão das estações.

var plot_index: int = 0
var _caption_until := 0.0


func reveal_caption() -> void:
	_caption_until = Time.get_ticks_msec() / 1000.0 + Motion.WORLD_CAPTION
	refresh()


func refresh() -> void:
	anchor = Vector2(0, -64)
	var status := GameState.plot_status(plot_index)
	visible = status in ["growing", "ready"]
	if status == "locked" and plot_index == GameState.accessible_plots():
		visible = true
		state = "buy"
		texture = null
		corner_texture = null
		caption = str(GameState.plot_cost(plot_index)) if GameState.has_upgrade("farm") else "Vovó"
		show_caption = true
		queue_redraw()
		return
	if not visible: return
	state = "ready" if status == "ready" else "progress"
	texture = Database.item_icon(GameState.plot(plot_index).crop)
	progress = GameState.plot_progress(plot_index)
	caption = TimeText.short(maxi(0, ceili(float(GameState.plot(plot_index).ready_at) - GameState.now())))
	show_caption = state != "ready" and (room_zoom >= 1.2 or Time.get_ticks_msec() / 1000.0 < _caption_until)
	corner_texture = UiKit.ui_icon("action_water") if GameState.water_error(plot_index) == "" else null
	queue_redraw()
