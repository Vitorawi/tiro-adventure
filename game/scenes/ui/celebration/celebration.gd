extends CanvasLayer
## Comemoração modal acima do Sheet, sem estado persistente.

func show_chapter(index: int, worlds: PackedStringArray) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var chapter: Dictionary = Database.progression.chapters[index - 1]
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.12, 0.08, 0.04, 0.72)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	var panel := PanelContainer.new()
	panel.theme = load("res://assets/theme/main_theme.tres")
	panel.theme_type_variation = &"ReadyCardPanel"
	panel.custom_minimum_size.x = 320
	center.add_child(panel)
	var box := UiKit.vbox(12)
	box.custom_minimum_size.x = 292
	panel.add_child(box)
	box.add_child(UiKit.icon(UiKit.ui_icon("xp"), 64))
	box.add_child(UiKit.label("Capítulo concluído!", &"TitleLabel"))
	box.add_child(UiKit.label(chapter.name, &"SectionLabel"))
	box.add_child(UiKit.label("Você e o Tiro chegaram mais longe.", &"SmallLabel"))
	box.add_child(UiKit.label(ProgressionUi.rewards_text(chapter.get("rewards", {}))))
	box.add_child(UiKit.label(chapter.get("unlocks_text", ""), &"SmallLabel", UiKit.GOOD))
	for world in worlds:
		box.add_child(UiKit.label("Novo lugar no Mapa: %s!" % world, &"SmallLabel", UiKit.GOOD))
	box.add_child(UiKit.button("Ver próximo passo", func() -> void:
		hide()
		Events.sheet_close_requested.emit()
		Events.screen_requested.emit(&"tasks"), &"PrimaryButton"))
	box.add_child(UiKit.button("Continuar", hide))
	show()
