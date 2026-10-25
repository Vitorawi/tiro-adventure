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
	# Uma única compra na ponta da frente da horta, sem cobrir o canteiro de trás.
	if status == "locked" and plot_index == int(Database.farm.plots) - 1:
		visible = true
		anchor = Vector2(0, -16)
		state = "buy"
		texture = null
		corner_texture = null
		caption = str(GameState.plot_cost(GameState.unlocked_plots)) if GameState.has_upgrade("farm") else ""
		show_caption = caption != ""
		super.refresh()
		return
	if not visible: return
	state = "ready" if status == "ready" else "progress"
	texture = Database.item_icon(GameState.plot(plot_index).crop)
	progress = GameState.plot_progress(plot_index)
	caption = TimeText.short(maxi(0, ceili(float(GameState.plot(plot_index).ready_at) - GameState.now())))
	show_caption = state != "ready" and (room_zoom >= 1.2 or Time.get_ticks_msec() / 1000.0 < _caption_until)
	corner_texture = UiKit.ui_icon("action_water") if GameState.water_error(plot_index) == "" else null
	super.refresh()
