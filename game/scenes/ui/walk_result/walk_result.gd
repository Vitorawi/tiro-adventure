class_name WalkResult
extends CanvasLayer
## Cartão "Volta do passeio": postal, achados em fila (ícone + quantidade, "Novo!" na primeira vez),
## moedas e vínculo. Sem estado: o resumo vem de Events.walk_collected (GameState.return_due_walk), UM por viagem.
## O Tiro já está em casa; se sobrou bagagem, o cartão oferece "Guardar achados" (ou "Ver bagagem" quando não cabe).
## Abrir o cartão só marca o resultado como visto (`mark_walk_result_shown`): nunca premia.
## Usa o `ModalCard`; raro e lendário ganham moldura dourada, estrela e confete.

var _panel: PanelContainer
var _box: VBoxContainer


func show_result(result: Dictionary) -> void:
	var rare := str(result.get("rare", ""))
	var legendary := str(result.get("legendary", ""))
	var sewing: bool = result.get("kind", "") == "sewing"
	var title := "Roupa pronta!" if sewing else "De volta! %s" % str(result.get("name", ""))
	var card := ModalCard.open(self, {"title": title, "ribbon": Palette.ACCENT if sewing else Palette.INFO,
		"scroll_name": "WalkResultScroll", "separation": 10,
		"confetti": rare != "" or legendary != "", "haptic": "big" if (rare != "" or legendary != "") else "success"})
	_panel = card.panel
	_box = card.box
	_box.name = "WalkResultBox"
	var postcard := postcard_texture(str(result.get("postcard", "")))
	if postcard:
		var picture := UiKit.icon(postcard, 0)
		picture.custom_minimum_size = Vector2(256, 160)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_box.add_child(_center(picture))
	if bool(result.get("first", false)):
		var first_label := UiKit.label("Primeira vez!", &"SectionLabel", UiKit.GOOD)
		first_label.name = "FirstTime"
		_box.add_child(_center(first_label))
	if rare != "":
		_rare_banner(card, rare)
	if legendary != "":
		_rare_banner(card, legendary)
	var found := UiKit.flow(10)
	found.name = "Found"
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
	if int(result.get("coins", 0)) > 0:
		chips.add_child(UiKit.chip(UiKit.ui_icon("coin"), "+%d" % int(result.coins)))
	if int(result.get("affection", 0)) > 0:
		chips.add_child(UiKit.chip(UiKit.ui_icon("bond_heart"), "+%d" % int(result.affection)))
	var needs: Dictionary = result.get("needs", {})
	for need_id: String in needs:
		chips.add_child(UiKit.chip(Database.need_icon(need_id), "%+d" % int(needs[need_id]), UiKit.GOOD if float(needs[need_id]) > 0 else UiKit.BAD))
	if bool(result.get("rare_duplicate", false)):
		var duplicate_name := str(Database.collections.get(str(result.get("rare_item", "")), {}).get("name", "apetrecho"))
		var consolation := card.add_text("Você já tem o %s!" % duplicate_name, &"SmallLabel")
		consolation.name = "Consolation"
	if found.get_child_count() > 0:
		card.add_chips(found)
	else:
		found.queue_free()
	card.add_chips(chips)
	var clothes: Array = result.get("collections", [])
	if rare != "" and not rare in clothes:
		clothes = clothes.duplicate()
		clothes.append(rare)
	for id: String in clothes:
		var dress := UiKit.secondary("Vestir agora · " + Database.item_name(id), func() -> void:
			var error := GameState.equip(id)
			if error != "":
				Events.toast_requested.emit(error)
			else:
				hide())
		dress.name = "Equip_" + id
		dress.disabled = GameState.equip_error(id) != ""
		card.add(dress)
	var left: Dictionary = GameState.walk_state.baggage_left() if not sewing else {}
	if left.is_empty():
		var close := card.add_primary("Oba!", hide)
		close.name = "CloseResult"
	else:
		var blocked := GameState.walk_baggage_error() != ""
		var store := card.add_primary("Ver bagagem" if blocked else "Guardar achados", func() -> void:
			if blocked:
				var at := Database.place_with_panel("walks")
				hide()
				Events.world_requested.emit(str(at[0]), str(at[1]))
				return
			GameState.claim_walk_baggage()
			var hint := GameState.walk_baggage_hint()
			if hint != "":
				Events.toast_requested.emit(hint)
			hide())
		store.name = "StoreBaggage"
		var later := card.add_ghost("Depois", hide)
		later.name = "CloseResult"
	show()
	if not sewing:
		GameState.mark_walk_result_shown()


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
func _rare_banner(card: ModalCard, rare: String) -> void:
	var border := card.panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	border.border_color = Palette.GOLD
	border.set_border_width_all(5)
	card.panel.add_theme_stylebox_override("panel", border)
	var data: Dictionary = Database.collections.get(rare, {})
	var stage := Control.new()
	stage.name = "RareStage"
	stage.custom_minimum_size = Vector2(ModalCard.INNER, 96)
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
	card.add(stage)
	if not Motion.reduced:
		create_tween().bind_node(star).set_loops().tween_property(star, "rotation", TAU, 6.0).from(0.0)
	var title := UiKit.label("LENDÁRIO!" if data.get("rarity", "") == "legendary" else ("RARO!" if data.get("rarity", "") == "rare" else "ROUPA NOVA!"), &"TitleLabel", Palette.ACCENT_EDGE)
	title.name = "RareTitle"
	card.add(_center(title))
	card.add_text(str(data.get("name", rare)), &"SectionLabel")
	card.add_text("Guardado na Coleção", &"SmallLabel", UiKit.GOOD)
