class_name PetNotebook
extends RefCounted
## Consultas do Tiro reunidas; cada abertura começa no Manual.

const TAB_ICONS := {"manual": "ui_notebook", "growth": "item_growth_kibble", "album": "album_story", "collection": "outfit_star_glasses", "tricks": "trick_paw"}


static func tabs() -> Array[Dictionary]:
	var result: Array[Dictionary] = [{"id": "manual", "text": "Manual"}]
	if GameState.progress.feature_unlocked("growth_tab"): result.append({"id": "growth", "text": "Crescimento"})
	if GameState.photo_count() > 0: result.append({"id": "album", "text": "Álbum"})
	if not GameState.progress.collection.is_empty() or GameState.progress.feature_unlocked("finds"):
		result.append({"id": "collection", "text": "Coleção"})
	if GameState.progress.feature_unlocked("tricks"):
		result.append({"id": "tricks", "text": "Truques"})
	for entry: Dictionary in result:
		entry["alert"] = section_has_new(str(entry.id))
	return result


static func open(section: String = "manual") -> void:
	var keys := section_unlocks(section)
	if not keys.is_empty(): GameState.mark_seen(keys)
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
	var tab_margin := MarginContainer.new()
	tab_margin.add_theme_constant_override("margin_top", 8)
	# Opção A: nomes inteiros e ícones 20; o trilho rola quando as cinco abas não cabem.
	var shown: Array[Dictionary] = []
	for entry: Dictionary in entries:
		var copy := entry.duplicate()
		copy["icon"] = UiKit.ui_icon(str(TAB_ICONS.get(str(entry.id), "ui_notebook")))
		copy["icon_px"] = 20
		shown.append(copy)
	var tabs_row := UiKit.segmented(shown, section, open)
	tabs_row.name = "NotebookTabs"
	var strip := ScrollContainer.new()
	strip.name = "NotebookTabScroll"
	strip.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	strip.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip.custom_minimum_size.y = 56 if entries.size() > 1 else 0
	strip.add_child(tabs_row)
	tab_margin.add_child(strip)
	var active := tabs_row.find_child("NotebookTab_" + section, false, false) as Control
	if active: AlbumView._reveal_tab.call_deferred(strip, active)
	box.add_child(tab_margin)
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
	return tabs().any(func(entry: Dictionary) -> bool: return entry.alert)


static func section_has_new(section: String) -> bool:
	if section == "album": return GameState.photo_alerts_enabled() and not GameState.photos_unseen().is_empty()
	return not section_unlocks(section).is_empty()


## Cada aba confirma só suas próprias novidades; fotos são vistas uma a uma.
static func section_unlocks(section: String) -> Array[String]:
	var result: Array[String] = []
	for key in GameState.new_unlocks():
		if (section == "growth" and key == "feature:growth_tab"
			or section == "collection" and (key in ["feature:dress", "feature:finds"] or key.begins_with("collection:"))
			or section == "tricks" and (key == "feature:tricks" or key.begins_with("trick:"))):
			result.append(key)
	return result
