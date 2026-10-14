class_name WalkResult
extends CanvasLayer
## Cartão "Volta do passeio": postal, achados em fila (ícone + quantidade, "Novo!" na primeira vez),
## moedas e vínculo. Sem estado: o resumo vem de Events.walk_collected (GameState.collect_walk).

var _panel: PanelContainer
var _box: VBoxContainer


func _ready() -> void:
	get_viewport().size_changed.connect(_resize_panel)


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
	var scroll := ScrollContainer.new()
	scroll.name = "WalkResultScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	panel.add_child(scroll)
	var box := UiKit.vbox(10)
	box.name = "WalkResultBox"
	box.custom_minimum_size.x = 292
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	_panel = panel
	_box = box
	box.minimum_size_changed.connect(_resize_panel)
	var postcard := postcard_texture(str(result.get("postcard", "")))
	if postcard:
		box.add_child(_center(UiKit.icon(postcard, 0)))
		var picture := box.get_child(0) as TextureRect
		picture.custom_minimum_size = Vector2(256, 160)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var title := UiKit.label("De volta! %s" % str(result.get("name", "")), &"TitleLabel")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_center(title))
	if bool(result.get("first", false)):
		var first_label := UiKit.label("Primeira vez!", &"SectionLabel", UiKit.GOOD)
		first_label.name = "FirstTime"
		box.add_child(_center(first_label))
	var rare := str(result.get("rare", ""))
	if rare != "":
		_rare_banner(panel, box, rare)
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
	if bool(result.get("rare_duplicate", false)):
		var duplicate_name := str(Database.collections.get(str(result.get("rare_item", "")), {}).get("name", "apetrecho"))
		var consolation := UiKit.label("Você já tem o %s!" % duplicate_name, &"SmallLabel")
		consolation.name = "Consolation"
		box.add_child(_center(consolation))
	if found.get_child_count() > 0:
		box.add_child(found)
	else:
		found.queue_free()
	box.add_child(chips)
	var close := UiKit.button("Oba!", hide, &"PrimaryButton")
	close.name = "CloseResult"
	box.add_child(close)
	_resize_panel.call_deferred()
	show()


func _resize_panel() -> void:
	if not is_instance_valid(_panel) or not is_instance_valid(_box):
		return
	var frame_height := _panel.get_theme_stylebox("panel").get_minimum_size().y
	_panel.custom_minimum_size.y = minf(_box.get_combined_minimum_size().y + frame_height, maxf(0.0, get_viewport().get_visible_rect().size.y - 32.0))


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


## Festa do raro: moldura dourada, estrela girando atrás do apetrecho, "RARO!" e onde ficou guardado.
func _rare_banner(panel: PanelContainer, box: VBoxContainer, rare: String) -> void:
	var border := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	border.border_color = Color(0.95, 0.72, 0.15)
	border.set_border_width_all(5)
	panel.add_theme_stylebox_override("panel", border)
	var data: Dictionary = Database.collections.get(rare, {})
	var stage := Control.new()
	stage.name = "RareStage"
	stage.custom_minimum_size = Vector2(292, 96)
	var star := UiKit.icon(UiKit.ui_icon(str(Database.walks.get("settings", {}).get("rare_star", "rare_star"))), 96)
	star.name = "RareStar"
	star.position = Vector2(98, 0)
	star.size = Vector2(96, 96)
	star.pivot_offset = Vector2(48, 48)
	star.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage.add_child(star)
	var picture := UiKit.icon(UiKit.ui_icon(str(data.get("icon", ""))), 64)
	picture.name = "RarePicture"
	picture.position = Vector2(114, 16)
	picture.size = Vector2(64, 64)
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stage.add_child(picture)
	box.add_child(stage)
	var tween := create_tween().bind_node(star).set_loops()
	tween.tween_property(star, "rotation", TAU, 6.0).from(0.0)
	var title := UiKit.label("RARO!", &"TitleLabel", Color(0.85, 0.55, 0.05))
	title.name = "RareTitle"
	box.add_child(_center(title))
	box.add_child(_center(UiKit.label(str(data.get("name", rare)), &"SectionLabel")))
	box.add_child(_center(UiKit.label("Guardado na Coleção", &"SmallLabel", UiKit.GOOD)))
	Input.vibrate_handheld(80)
