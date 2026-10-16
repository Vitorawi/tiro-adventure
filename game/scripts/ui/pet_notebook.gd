class_name PetNotebook
extends RefCounted
## Consultas do Tiro reunidas; cada abertura começa no Manual.

static func tabs() -> Array[Dictionary]:
	var result: Array[Dictionary] = [{"id": "manual", "text": "Manual"}]
	if GameState.progress.skills_visible(): result.append({"id": "skills", "text": "Atributos"})
	if not GameState.progress.collection.is_empty() or GameState.progress.feature_unlocked("finds"):
		result.append({"id": "collection", "text": "Coleção"})
	if GameState.progress.feature_unlocked("tricks"):
		result.append({"id": "tricks", "text": "Truques"})
	return result


static func open(section: String = "manual") -> void:
	Events.sheet_requested.emit("Caderninho", panel(section))


static func panel(section: String = "manual") -> Control:
	var entries := tabs()
	if not entries.any(func(entry: Dictionary) -> bool: return entry.id == section): section = "manual"
	var box := UiKit.vbox(8)
	box.name = "PetNotebook"
	box.set_meta("sheet_size", "tall")
	box.add_child(UiKit.segmented(entries, section, open))
	match section:
		"skills": box.add_child(ProgressionUi.skills_panel())
		"collection": box.add_child(ProgressionUi.collection_panel())
		"tricks": box.add_child(TrickUi.panel())
		_: box.add_child(GameManual.panel())
	return box


static func has_new() -> bool:
	for key in GameState.new_unlocks():
		if key in ["feature:skills", "feature:dress", "feature:finds", "feature:tricks"] or key.begins_with("collection:") or key.begins_with("trick:"):
			return true
	return false
