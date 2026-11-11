class_name GreenhouseIndicator
extends WorldBalloon
## Balão da estufa: a cultura que termina primeiro (anel e tempo) ou, se há prontas, "×N"; tocar colhe tudo o que está pronto.


func ready_indices() -> Array[int]:
	var result: Array[int] = []
	for index in StationTray.greenhouse_plots():
		if GameState.plot_status(index) == "ready":
			result.append(index)
	return result


func active() -> bool:
	if not GameState.has_upgrade("greenhouse"):
		return false
	for index in StationTray.greenhouse_plots():
		if GameState.plot_status(index) != "empty":
			return true
	return false


func refresh() -> void:
	visible = active()
	if not visible:
		return
	var ready := ready_indices()
	var shown := -1
	for index in StationTray.greenhouse_plots():
		if GameState.plot_status(index) == "empty":
			continue
		if ready.has(index):
			if shown < 0 or not ready.has(shown):
				shown = index
		elif shown < 0 or (not ready.has(shown) and float(GameState.plot(index)["ready_at"]) < float(GameState.plot(shown)["ready_at"])):
			shown = index
	var crop := str(GameState.plot(shown)["crop"])
	var remaining := maxi(0, ceili(float(GameState.plot(shown)["ready_at"]) - GameState.now()))
	state = "ready" if not ready.is_empty() else "progress"
	texture = Database.item_icon(str(Database.crops.get(crop, {}).get("item", crop)))
	progress = 1.0 if not ready.is_empty() else GameState.plot_progress(shown)
	caption = "×%d" % ready.size() if ready.size() > 1 else TimeText.short(remaining)
	show_caption = ready.size() > 1 or (ready.is_empty() and room_zoom >= 1.2)
	super.refresh()
