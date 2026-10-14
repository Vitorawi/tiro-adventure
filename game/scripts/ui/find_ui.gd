class_name FindUi
extends RefCounted
## Álbum derivado dos contadores: vender não apaga a descoberta.

static func album() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var header := UiKit.hbox(8)
		header.add_child(UiKit.icon(UiKit.ui_icon("find_paw"), 32))
		header.add_child(UiKit.short_label("%d/16" % GameState.find_album_count(), &"SectionLabel"))
		box.add_child(header)
		var map_card := UiKit.card(box)
		var pieces := UiKit.hbox(8)
		var found := 0
		for n in range(1, 5):
			var earned := GameState.progress.stat("find_item:map_piece_%d" % n) > 0
			found += 1 if earned else 0
			var piece := UiKit.vbox(0)
			var icon := UiKit.icon(UiKit.ui_icon("item_map_piece"), 48)
			if not earned:
				icon.modulate = Color(0.12, 0.10, 0.08)
			piece.add_child(icon)
			var number := UiKit.label(str(n), &"SmallLabel")
			number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			piece.add_child(number)
			pieces.add_child(piece)
		map_card.add_child(UiKit.label("Mapa rasgado · %d/4" % found, &"SectionLabel"))
		map_card.add_child(pieces)
		for world: String in Database.finds.album_groups:
			var items: Array = Database.finds.album_groups[world]
			var card := UiKit.card(box)
			card.add_child(UiKit.label(str(Database.finds.album_names[world]), &"SectionLabel"))
			var grid := GridContainer.new()
			grid.columns = 4
			grid.add_theme_constant_override("h_separation", 4)
			for id: String in items:
				var earned := GameState.progress.stat("find_item:" + id) > 0
				var cell := UiKit.vbox(2)
				cell.custom_minimum_size.x = 66
				var icon := UiKit.icon(Database.item_icon(id), 48)
				icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				if not earned:
					icon.modulate = Color(0.12, 0.10, 0.08)
				cell.add_child(icon)
				var label := UiKit.label(Database.item_name(id) if earned else "?", &"SmallLabel")
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				label.custom_minimum_size.x = 66
				cell.add_child(label)
				grid.add_child(cell)
			card.add_child(grid)
			var set_id := world + "_set"
			if Database.finds.sets.has(set_id):
				card.add_child(UiKit.label("%d/4" % GameState.find_set_progress(set_id), &"SmallLabel"))
				var error := GameState.find_set_error(set_id)
				var receive := UiKit.button("Recebido" if set_id in GameState.finds.claimed_sets else "Receber", func() -> void:
					var result := GameState.claim_find_set(set_id)
					if result != "": Events.toast_requested.emit(result), &"PrimaryButton")
				receive.disabled = error != ""
				receive.tooltip_text = error
				card.add_child(receive)
	)
