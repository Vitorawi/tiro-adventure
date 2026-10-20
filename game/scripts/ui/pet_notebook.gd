class_name PetNotebook
extends RefCounted
## Consultas do Tiro reunidas; cada abertura começa no Manual.

static func tabs() -> Array[Dictionary]:
	var result: Array[Dictionary] = [{"id": "manual", "text": "Manual"}]
	if GameState.progress.feature_unlocked("growth_tab"): result.append({"id": "growth", "text": "Crescimento"})
	if GameState.photo_count() > 0: result.append({"id": "album", "text": "Álbum"})
	if not GameState.progress.collection.is_empty() or GameState.progress.feature_unlocked("finds"):
		result.append({"id": "collection", "text": "Coleção"})
	if GameState.progress.feature_unlocked("tricks"):
		result.append({"id": "tricks", "text": "Truques"})
	return result


static func open(section: String = "manual") -> void:
	Events.sheet_requested.emit("Caderninho", panel(section))


static func panel(section: String = "manual") -> Control:
	var entries := tabs()
	var album_section := ""
	if section.begins_with("album:"):
		album_section = section.trim_prefix("album:")
		section = "album"
	if not entries.any(func(entry: Dictionary) -> bool: return entry.id == section): section = "manual"
	var box := UiKit.vbox(8)
	box.name = "PetNotebook"
	box.set_meta("sheet_size", "tall")
	box.add_child(UiKit.segmented(entries, section, open))
	match section:
		"growth":
			box.add_child(PillarUi.panel())
			box.add_child(UiKit.primary("Ver crescimento", GrowthUi.open))
		"collection":
			if GameState.dog_look().body == "puppy":
				box.add_child(UiKit.fill_label("Vai aparecer quando ele crescer", &"SmallLabel"))
			box.add_child(ProgressionUi.collection_panel())
		"album": box.add_child(AlbumView.panel(album_section))
		"tricks": box.add_child(TrickUi.panel())
		_: box.add_child(GameManual.panel())
	return box


static func has_new() -> bool:
	if not GameState.photos_unseen().is_empty():
		return true
	for key in GameState.new_unlocks():
		if key in ["feature:growth_tab", "feature:dress", "feature:finds", "feature:tricks"] or key.begins_with("collection:") or key.begins_with("trick:"):
			return true
	return false
