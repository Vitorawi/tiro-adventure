class_name RouteIndicator
extends WorldBalloon
## Coletas do local: produto, anel ou quantidade pronta.

var group: String = ""
var site: String = ""


func jobs() -> Array[Dictionary]:
	if site != "": return GameState.gathering_jobs(site)
	var activity: Dictionary = GameState.progress.activity
	var result: Array[Dictionary] = []
	if not activity.is_empty() and Database.progression.activities.get(activity.id, {}).get("place", "") == group:
		result.append(activity)
	return result


func active() -> bool:
	return not jobs().is_empty()


func refresh() -> void:
	var entries := jobs()
	visible = not entries.is_empty()
	if not visible: return
	var ready := 0
	var entry: Dictionary = entries[0]
	for candidate: Dictionary in entries:
		if float(candidate.ready_at) <= GameState.now(): ready += 1
		if float(candidate.ready_at) < float(entry.ready_at): entry = candidate
	var remaining := maxi(0, ceili(float(entry.ready_at) - GameState.now()))
	state = "ready" if ready > 0 else "progress"
	texture = Database.item_icon(str(entry.get("resource", "")))
	if texture == null:
		var rewards: Dictionary = entry.get("rewards", {}).get("items", {})
		texture = Database.item_icon(str(rewards.keys()[0])) if not rewards.is_empty() else UiKit.ui_icon("action_walk")
	progress = clampf(1.0 - remaining / maxf(1, float(entry.ready_at) - float(entry.started_at)), 0, 1)
	caption = "×%d" % ready if ready > 1 else TimeText.short(remaining)
	show_caption = ready > 1 or (ready == 0 and room_zoom >= 1.2)
	super.refresh()
