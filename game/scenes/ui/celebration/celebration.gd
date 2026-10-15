extends CanvasLayer
## Comemoração modal acima do Sheet, sem estado persistente: capítulo concluído e/ou
## novidades reveladas pela história ("Novo!": ícone + nome + Ir).

var _panel: PanelContainer
var _box: VBoxContainer


func _ready() -> void:
	get_viewport().size_changed.connect(_resize_panel)


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


## Subiu de vínculo com o Tiro: o presente já entrou; o botão só fecha.
func show_bond(level: int, rewards: Dictionary) -> void:
	var box := _open()
	box.add_child(_center(UiKit.icon(UiKit.ui_icon("bond_heart"), 64)))
	box.add_child(_center(UiKit.label("Vínculo %d!" % level, &"TitleLabel")))
	var chips := ProgressionUi.reward_chips(rewards)
	chips.alignment = FlowContainer.ALIGNMENT_CENTER
	box.add_child(chips)
	box.add_child(UiKit.button("Oba!", hide, &"PrimaryButton"))
	show()


## Só novidades (sem fim de capítulo).
func show_find(result: Dictionary) -> void:
	var box := _open()
	var ids: Array = result.get("new", [])
	var item := str(ids[0]) if not ids.is_empty() else ""
	var texture: Texture2D = Database.item_icon(item) if item != "" else UiKit.ui_icon(str(result.get("icon", "find_paw")))
	box.add_child(_center(UiKit.icon(texture, 64)))
	box.add_child(_center(UiKit.label("Novo achado!", &"TitleLabel")))
	box.add_child(_center(UiKit.label(Database.item_name(item) if item != "" else str(result.get("announcement", result.label)), &"SectionLabel")))
	var progress_text := "%d/16" % GameState.find_album_count()
	if item.begins_with("map_piece_"):
		var pieces := 0
		for n in range(1, 5):
			pieces += 1 if GameState.progress.stat("find_item:map_piece_%d" % n) > 0 else 0
		progress_text = "%d/4" % pieces
	elif item == "":
		progress_text = str(result.get("unlock_label", ""))
	box.add_child(_center(UiKit.label(progress_text, &"SmallLabel")))
	box.add_child(UiKit.button("Oba!", hide, &"PrimaryButton"))
	show()

## Baú da Clareira: a festa grande. Os prêmios já entraram; o cartão só mostra o que veio.
func show_treasure(rewards: Dictionary) -> void:
	var def: Dictionary = Database.progression.treasure
	var box := _open()
	box.add_child(_center(UiKit.icon(UiKit.ui_icon(str(def.get("icon", "item_map_piece"))), 64)))
	box.add_child(_center(UiKit.label("Tesouro encontrado!", &"TitleLabel")))
	box.add_child(_center(UiKit.label(str(def.get("name", "")), &"SectionLabel")))
	var chips := UiKit.flow()
	chips.alignment = FlowContainer.ALIGNMENT_CENTER
	if int(rewards.get("coins", 0)) > 0:
		chips.add_child(UiKit.chip(UiKit.ui_icon("coin"), "+%d" % int(rewards.coins)))
	for id: String in rewards.get("items", {}):
		chips.add_child(UiKit.chip(Database.item_icon(id), "+%d" % int(rewards.items[id])))
	for id: String in rewards.get("collections", []):
		chips.add_child(UiKit.chip(UiKit.ui_icon(str(Database.collections.get(id, {}).get("icon", "item_accessory_set"))), "+1"))
	box.add_child(chips)
	for unlock: String in rewards.get("unlocks", []):
		if unlock.begins_with("crop:"):
			var crop := unlock.trim_prefix("crop:")
			box.add_child(_center(UiKit.label("Muda nova: %s" % Database.item_name(crop), &"SmallLabel", UiKit.GOOD)))
	box.add_child(UiKit.button("Oba!", hide, &"PrimaryButton"))
	show()


func show_trick(id: String) -> void:
	var def: Dictionary = Database.progression.tricks[id]
	var box := _open()
	box.add_child(_center(UiKit.icon(UiKit.ui_icon(str(def.icon)), 64)))
	box.add_child(_center(UiKit.label("Novo truque!", &"TitleLabel")))
	box.add_child(_center(UiKit.label(str(def.name), &"SectionLabel")))
	box.add_child(UiKit.button("Oba!", hide, &"PrimaryButton"))
	show()


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
	var scroll := ScrollContainer.new()
	scroll.name = "CelebrationScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	panel.add_child(scroll)
	var box := UiKit.vbox(12)
	box.custom_minimum_size.x = 292
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	_panel = panel
	_box = box
	box.minimum_size_changed.connect(_resize_panel)
	_resize_panel.call_deferred()
	return box


## Cartões curtos ficam centrados; listas longas cabem na tela e rolam até os botões finais.
func _resize_panel() -> void:
	if not is_instance_valid(_panel) or not is_instance_valid(_box):
		return
	var frame_height := _panel.get_theme_stylebox("panel").get_minimum_size().y
	var content_height := _box.get_combined_minimum_size().y + frame_height
	_panel.custom_minimum_size.y = minf(content_height, maxf(0.0, get_viewport().get_visible_rect().size.y - 32.0))


func _center(control: Control) -> Control:
	if control is Label:
		(control as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		control.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return control
