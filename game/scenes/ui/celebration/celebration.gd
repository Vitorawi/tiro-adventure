extends CanvasLayer
## Comemoração modal acima do Sheet, sem estado persistente: capítulo concluído e/ou
## novidades reveladas pela história ("Novo!": ícone + nome + Ir).


## Capítulo concluído: recompensas + novidades.
func show_chapter(index: int, unlocks: Array[String]) -> void:
	var chapter: Dictionary = Database.progression.chapters[index - 1]
	var box := _open()
	box.add_child(_center(UiKit.icon(UiKit.ui_icon("xp"), 64)))
	box.add_child(_center(UiKit.label("Capítulo concluído!", &"TitleLabel")))
	box.add_child(_center(UiKit.label(chapter.name, &"SectionLabel")))
	var rewards := ProgressionUi.reward_chips(chapter.get("rewards", {}))
	rewards.alignment = FlowContainer.ALIGNMENT_CENTER
	box.add_child(rewards)
	_unlock_rows(box, unlocks)
	box.add_child(UiKit.button("Próximo passo", func() -> void:
		hide()
		Events.sheet_close_requested.emit()
		Events.screen_requested.emit(&"tasks"), &"PrimaryButton"))
	box.add_child(UiKit.button("Continuar", hide))
	show()


## Subiu de nível: o presente já entrou; o botão só fecha.
func show_level(level: int, rewards: Dictionary) -> void:
	var box := _open()
	box.add_child(_center(UiKit.icon(UiKit.ui_icon("xp"), 64)))
	box.add_child(_center(UiKit.label("Nível %d!" % level, &"TitleLabel")))
	var chips := ProgressionUi.reward_chips(rewards)
	chips.alignment = FlowContainer.ALIGNMENT_CENTER
	box.add_child(chips)
	box.add_child(UiKit.button("Oba!", hide, &"PrimaryButton"))
	show()


## Só novidades (sem fim de capítulo).
func show_unlocks(unlocks: Array[String]) -> void:
	var box := _open()
	box.add_child(_center(UiKit.label("Novo!", &"TitleLabel")))
	_unlock_rows(box, unlocks)
	box.add_child(UiKit.button("Continuar", hide))
	show()


## Uma linha por novidade: [ícone] Nome  [Ir].
func _unlock_rows(box: VBoxContainer, unlocks: Array[String]) -> void:
	for key in unlocks:
		var view := Places.unlock_view(key)
		if view.is_empty():
			continue
		var card := UiKit.card(box, &"CardPanel")
		var row := UiKit.hbox(10)
		row.add_child(UiKit.icon(view.icon, 48))
		var name_box := UiKit.vbox(0)
		name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_box.add_child(UiKit.label("Novo!", &"SmallLabel", UiKit.GOOD))
		name_box.add_child(UiKit.label(view.name, &"SectionLabel"))
		row.add_child(name_box)
		var target: Dictionary = view.target
		var go := UiKit.button("Ir", func() -> void:
			hide()
			Places.go(target), &"PrimaryButton")
		go.custom_minimum_size = Vector2(72, 48)
		go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(go)
		card.add_child(row)


func _open() -> VBoxContainer:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
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
	return box


func _center(control: Control) -> Control:
	if control is Label:
		(control as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		control.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return control
