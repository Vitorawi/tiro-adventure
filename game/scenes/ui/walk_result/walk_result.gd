class_name WalkResult
extends CanvasLayer
## Cartão "Volta do passeio": postal, achados em fila (ícone + quantidade, "Novo!" na primeira vez),
## moedas e vínculo. Sem estado: o resumo vem de Events.walk_collected (GameState.collect_walk).


func show_result(result: Dictionary) -> void:
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
	var box := UiKit.vbox(10)
	box.name = "WalkResultBox"
	box.custom_minimum_size.x = 292
	panel.add_child(box)
	var postcard := postcard_texture(str(result.get("postcard", "")))
	if postcard:
		box.add_child(_center(UiKit.icon(postcard, 0)))
		var picture := box.get_child(0) as TextureRect
		picture.custom_minimum_size = Vector2(256, 160)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var title := UiKit.label("De volta da %s!" % str(result.get("name", "")), &"TitleLabel")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_center(title))
	var found := UiKit.flow(10)
	found.name = "Found"
	found.alignment = FlowContainer.ALIGNMENT_CENTER
	var fresh: Array = result.get("new", [])
	var items: Dictionary = result.get("items", {})
	for id: String in items:
		var cell := UiKit.vbox(2)
		cell.name = "Found_" + id
		cell.add_child(_center(UiKit.icon(Database.item_icon(id), 48)))
		var count := UiKit.label("×%d" % int(items[id]), &"SectionLabel")
		cell.add_child(_center(count))
		if id in fresh:
			cell.add_child(_center(UiKit.label("Novo!", &"SmallLabel", UiKit.GOOD)))
		found.add_child(cell)
	var chips := UiKit.flow()
	chips.alignment = FlowContainer.ALIGNMENT_CENTER
	if int(result.get("coins", 0)) > 0:
		chips.add_child(UiKit.chip(UiKit.ui_icon("coin"), "+%d" % int(result.coins)))
	if int(result.get("affection", 0)) > 0:
		chips.add_child(UiKit.chip(UiKit.ui_icon("bond_heart"), "+%d" % int(result.affection)))
	var needs: Dictionary = result.get("needs", {})
	for need_id: String in needs:
		chips.add_child(UiKit.chip(Database.need_icon(need_id), "%+d" % int(needs[need_id]), UiKit.GOOD if float(needs[need_id]) > 0 else UiKit.BAD))
	if found.get_child_count() > 0:
		box.add_child(found)
	else:
		found.queue_free()
	box.add_child(chips)
	box.add_child(UiKit.button("Oba!", hide, &"PrimaryButton"))
	show()


## Postal do passeio (arquivo em walks.json); null se não existir.
static func postcard_texture(path: String) -> Texture2D:
	if path != "" and ResourceLoader.exists(path):
		return load(path)
	return null


func _center(control: Control) -> Control:
	if control is Label:
		(control as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		control.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return control
