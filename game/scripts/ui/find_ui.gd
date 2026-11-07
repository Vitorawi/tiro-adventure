class_name FindUi
extends RefCounted
## Álbum de achados em madeira ilustrada (aba Achados da Coleção): um cartão de papel por mundo com quadradinhos iguais.
## Derivado dos contadores: vender não apaga a descoberta. Nós: `FindsAlbum`, `FindProgress`, `MapPiece_<n>`, `Find_<item>`,
## `FindSetDone_<set>`, `ClaimFind_<set>`.

const TILE_W := 70.0
const TILE_H := 92.0


static func album() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.name = "FindsAlbum"
		box.add_theme_constant_override("separation", 10)
		var progress := StepCardUi.wood_chip(null, "%d/16" % GameState.find_album_count(), "", Callable(), "FindProgress")
		progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(progress)
		var found := 0
		var pieces: Array[Dictionary] = []
		for n in range(1, 5):
			var earned := GameState.progress.stat("find_item:map_piece_%d" % n) > 0
			found += 1 if earned else 0
			pieces.append({"name": "MapPiece_%d" % n, "icon": UiKit.ui_icon("item_map_piece"), "caption": "Pedaço %d" % n, "dim": not earned, "tooltip": "Mapa rasgado"})
		_block(box, "Mapa rasgado", "%d/4" % found, pieces, null)
		for world: String in Database.finds.album_groups:
			var items: Array = Database.finds.album_groups[world]
			var tiles: Array[Dictionary] = []
			for id: String in items:
				var earned := GameState.progress.stat("find_item:" + id) > 0
				tiles.append({"name": "Find_" + id, "icon": CodexSections.item_icon(id), "caption": Database.item_name(id) if earned else "?", "dim": not earned,
					"tooltip": Database.item_name(id) if earned else "?", "on_tap": CodexSections.open_item.bind(id)})
			var set_id := world + "_set"
			var count := ""
			var action: Control = null
			if Database.finds.sets.has(set_id):
				count = "%d/4" % GameState.find_set_progress(set_id)
				if set_id in GameState.finds.claimed_sets:
					action = StepCardUi.done_medal(28.0, "FindSetDone_" + set_id)
				else:
					var error := GameState.find_set_error(set_id)
					if error == "":
						var claim := StepCardUi.go_button("Pegar", func() -> void:
							var result := GameState.claim_find_set(set_id)
							if result != "":
								Events.toast_requested.emit(result))
						claim.name = "ClaimFind_" + set_id
						claim.custom_minimum_size = Vector2(96, 44)
						action = claim
					else:
						var locked := StepCardUi.locked_button(error, null, TaskHelp.open.bind("item", str(items[0])))
						locked.name = "Locked_ClaimFind_" + set_id
						action = locked
			_block(box, str(Database.finds.album_names[world]), count, tiles, action)
	)


static func _block(box: VBoxContainer, title: String, count: String, tiles: Array[Dictionary], action: Control) -> void:
	var card := StepCardUi.inner_card(box, "FindBlock")
	var head := UiKit.hbox(8)
	var name_label := StepCardUi.wood(title, 18)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_label)
	if count != "":
		head.add_child(StepCardUi.wood_chip(null, count))
	card.add_child(head)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for entry: Dictionary in tiles:
		grid.add_child(CodexUi.tile(entry, TILE_W, TILE_H))
	card.add_child(grid)
	if action != null:
		if not action is LockedButton:
			action.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card.add_child(action)
