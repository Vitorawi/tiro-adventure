class_name StationIndicator
extends WorldBalloon
## Produto do primeiro lote, anel de tempo e quantidade de lotes prontos.

var station_id: String = ""


func refresh() -> void:
	visible = station_id != "" and GameState.has_upgrade(station_id) and not GameState.station(station_id).queue.is_empty()
	if not visible: return
	var production := GameState.station(station_id)
	var ready := production.ready_count(GameState.now())
	var entry: Dictionary = production.queue[0]
	var recipe: Dictionary = Database.recipes.get(entry.recipe, {})
	var remaining := maxi(0, ceili(float(entry.ready_at) - GameState.now()))
	state = "ready" if ready > 0 else "progress"
	texture = Database.item_icon(Database.recipe_output(recipe))
	progress = clampf(1.0 - remaining / maxf(1, float(recipe.get("seconds", 1))), 0, 1)
	caption = "×%d" % ready if ready > 1 else TimeText.short(remaining)
	show_caption = ready > 1 or (ready == 0 and room_zoom >= 1.2)
	queue_redraw()
