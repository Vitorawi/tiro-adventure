class_name WalkResultSheet
extends WelcomeSheet
## Cartão "Voltou do passeio!" (passeio comum) no visual "madeira ilustrada", no molde da `WelcomeSheet` (herda a moldura, a
## placa, o X, a entrada e a saída): o postal na moldura de madeira do seletor de mundos (pixel em escala INTEIRA, nítido),
## o nome do caminho, o selo "Primeira vez!", os achados em pratinhos bege com "×N" e "Novo!", os ganhos em chips de madeira
## (negativos em vermelho suave) e UM botão verde ("Oba!"). Os achados já foram guardados sozinhos pelo `GameState`; se algo
## não coube, uma linha com cadeado avisa e um botão amarelo leva até o depósito. Raro, lendário e roupa seguem no ModalCard.
## Só monta; nada aqui premia. Nós preservados: `RewardSheet` (esta folha), `WalkResultScroll`, `CloseResult`, `FirstTime`,
## `Found_<item>`; novos: `ResultPostcard`, `ResultName`, `ResultChips`, `LeftoverNote`, `StoreBaggage` (Liberar espaço).

const POST_SCALE := 0.22               # escala do NinePatch `map_frame`
const POST_PAD := Vector4i(24, 30, 24, 20)  # madeira + folga até o postal (esq, topo, dir, base)
const CELL_W := 58.0
const CELL_H := 70.0
const CELL_GAP := 4.0


static func show_for(host_node: Node, result: Dictionary, on_close: Callable, animate: bool = true) -> WalkResultSheet:
	for child: Node in host_node.get_children():
		host_node.remove_child(child)
		child.queue_free()
	var sheet := WalkResultSheet.new()
	sheet.name = "RewardSheet"
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host_node.add_child(sheet)
	sheet._build(host_node, {"result": result, "on_close": on_close, "animate": animate})
	return sheet


## Moldura de madeira + postal no dobro exato (128x80 -> 256x160, NEAREST). Nó `ResultPostcard` é o postal.
static func postcard_frame(texture: Texture2D, node_name: String = "ResultPostcard", factor: float = 2.0) -> Control:
	var frame := Control.new()
	frame.name = "PostcardFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var art := NinePatchRect.new()
	art.name = "Frame"
	art.texture = load(HomeUi.DIR + "map_frame.png") as Texture2D
	art.patch_margin_left = 190
	art.patch_margin_top = 210
	art.patch_margin_right = 190
	art.patch_margin_bottom = 200
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.scale = Vector2.ONE * POST_SCALE
	frame.add_child(art)
	var size := Vector2(128, 80) * factor
	if texture != null:
		size = texture.get_size() * factor
	var outer := size + Vector2(POST_PAD.x + POST_PAD.z, POST_PAD.y + POST_PAD.w)
	frame.custom_minimum_size = outer
	art.size = outer / POST_SCALE
	var picture := TextureRect.new()
	picture.name = node_name
	picture.texture = texture
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.position = Vector2(POST_PAD.x, POST_PAD.y)
	picture.size = size
	frame.add_child(picture)
	return frame


static func _pill(text: String, node_name: String) -> Control:
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = Color("f3cf98")
	style.border_color = Color("c9935f")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	pill.add_theme_stylebox_override("panel", style)
	var label := StationWood.text(text, 14)
	label.name = node_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_child(label)
	return pill


func _build(host_node: Node, options: Dictionary) -> void:
	host = host_node
	_on_close = options.get("on_close", Callable()) as Callable
	_animate = bool(options.get("animate", true))
	dim = ColorRect.new()
	dim.name = "Dim"
	dim.color = Palette.SCRIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			close())
	var result: Dictionary = options.get("result", {})
	var items: Dictionary = result.get("items", {})
	var fresh: Array = result.get("new", [])
	var left: Dictionary = GameState.walk_state.baggage_left()
	_width = ItemUi.panel_width()
	var cw := _width - IN_L - IN_R
	var avail := _screen().y - Hud.SHEET_TOP - TAIL
	var texture := WalkResult.postcard_texture(str(result.get("postcard", "")))
	var factor := 2.0
	var post_size := Vector2.ZERO
	# Ganhos (chips de madeira) e quantas fileiras ocupam.
	var chips: Array[Control] = []
	if int(result.get("coins", 0)) > 0:
		chips.append(StepCardUi.wood_chip(UiKit.ui_icon("coin"), "+%d" % int(result.coins), "", Callable(), "GainCoins"))
	var needs: Dictionary = result.get("needs", {})
	for need_id: String in needs:
		var amount := int(needs[need_id])
		chips.append(StepCardUi.wood_chip(Database.need_icon(need_id), "%+d" % amount, "have" if amount > 0 else "missing", Callable(), "Gain_" + need_id))
	var chip_rows := ceili(chips.size() / 3.0)
	var chips_h := chip_rows * 32.0 + maxf(0.0, chip_rows - 1.0) * 4.0
	var first := bool(result.get("first", false))
	var name_h := 26.0 + (4.0 + 26.0 if first else 0.0)
	var leftover_h := 0.0
	if not left.is_empty():
		leftover_h = ACTION_H
	var count := items.size()
	var min_panel := PANEL_TOP + LIST_PAD * 2.0 + CELL_H + 20.0 + PANEL_BOTTOM
	for attempt in 2:
		post_size = (texture.get_size() * factor if texture != null else Vector2(128, 80) * factor) + Vector2(POST_PAD.x + POST_PAD.z, POST_PAD.y + POST_PAD.w)
		var base := TOP + post_size.y + GAP + name_h + ACTION_H + GAP + BOTTOM + (GAP + chips_h if not chips.is_empty() else 0.0) + (GAP + leftover_h if leftover_h > 0.0 else 0.0)
		if factor <= 1.0 or count == 0 or base + GAP + min_panel <= avail:
			break
		factor = 1.0  # postal em escala inteira: se o dobro não cabe com o painel de achados, usa o tamanho original
	var fixed := TOP + post_size.y + GAP + name_h + ACTION_H + GAP + BOTTOM
	if not chips.is_empty():
		fixed += GAP + chips_h
	if leftover_h > 0.0:
		fixed += GAP + leftover_h
	# Painel de achados: altura natural; se não couber, só ele rola por dentro.
	var inner_w := cw - PANEL_SIDE * 2.0
	var cols := maxi(1, floori((inner_w - LIST_PAD * 2.0 - GUTTER) / CELL_W))
	var rows := ceili(count / float(cols))
	var list_h := rows * CELL_H + maxf(0.0, rows - 1.0) * CELL_GAP
	var panel_h := 0.0
	var scrolls := false
	if count > 0:
		panel_h = PANEL_TOP + LIST_PAD * 2.0 + list_h + PANEL_BOTTOM
		var room := avail - fixed - GAP
		if panel_h > room + 0.5:
			scrolls = true
			panel_h = maxf(room, PANEL_TOP + LIST_PAD * 2.0 + CELL_H + 20.0 + PANEL_BOTTOM)
		fixed += GAP + panel_h
	var total := ceilf(fixed)
	frame = Control.new()
	frame.name = "WelcomeFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_STOP
	frame.custom_minimum_size = Vector2(_width, total)
	frame.size = Vector2(_width, total)
	add_child(frame)
	var art := SellUi.nine("frame", ItemUi.FRAME_MARGINS, "Art", null, "item_")
	frame.add_child(art)
	StepCardUi.stretch(art)
	var y := TOP
	var post := postcard_frame(texture, "ResultPostcard", factor)
	frame.add_child(post)
	SellUi.place(post, 0.5, -post_size.x / 2.0, 0.5, post_size.x / 2.0, 0.0, y, 0.0, y + post_size.y)
	y += post_size.y + GAP
	var names := UiKit.vbox(4)
	names.name = "ResultNames"
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := StationWood.text(str(result.get("name", "")), 19)
	title.name = "ResultName"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.clip_text = true
	title.custom_minimum_size.y = 26.0
	names.add_child(title)
	if first:
		names.add_child(_pill("Primeira vez!", "FirstTime"))
	frame.add_child(names)
	SellUi.place(names, 0.0, IN_L, 1.0, -IN_R, 0.0, y, 0.0, y + name_h)
	y += name_h + GAP
	if count > 0:
		var panel := _finds_panel(items, fresh, cw, panel_h, list_h, cols, scrolls)
		frame.add_child(panel)
		SellUi.place(panel, 0.0, IN_L, 1.0, -IN_R, 0.0, y, 0.0, y + panel_h)
		y += panel_h + GAP
	if not chips.is_empty():
		var flow := UiKit.flow(6)
		flow.name = "ResultChips"
		flow.alignment = FlowContainer.ALIGNMENT_CENTER
		flow.add_theme_constant_override("v_separation", 4)
		flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for chip in chips:
			flow.add_child(chip)
		frame.add_child(flow)
		SellUi.place(flow, 0.0, IN_L, 1.0, -IN_R, 0.0, y, 0.0, y + chips_h)
		y += chips_h + GAP
	if leftover_h > 0.0:
		var box := UiKit.hbox(int(GAP))
		box.name = "Leftover"
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var total_left := 0
		for amount: int in left.values():
			total_left += amount
		var note := StepCardUi.lock_note("Sem espaço: %d ficaram na sacola" % total_left)
		note.name = "LeftoverNote"
		note.custom_minimum_size.y = ACTION_H
		note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(note)
		var depot := GameState.walk_baggage_depot()
		var go := _button("Liberar espaço", false, 132.0, "StoreBaggage", func() -> void:
			close()
			if depot != "":
				Places.go({"storage": depot})
			else:
				var at := Database.place_with_panel("walks")
				Events.world_requested.emit(str(at[0]), str(at[1])))
		box.add_child(go)
		frame.add_child(box)
		SellUi.place(box, 0.0, IN_L, 1.0, -IN_R, 0.0, y, 0.0, y + leftover_h)
		y += leftover_h + GAP
	var closing := _button("Oba!", true, 168.0, "CloseResult", close)
	frame.add_child(closing)
	SellUi.place(closing, 0.5, -84.0, 0.5, 84.0, 0.0, y, 0.0, y + ACTION_H)
	var overlay := _overlay(_width, "Voltou do passeio!")
	frame.add_child(overlay)
	StepCardUi.stretch(overlay)
	var plaque := overlay.find_child("WelcomeTitle", true, false)
	if plaque != null:
		plaque.name = "ResultTitle"
	resized.connect(layout)


## Painel de madeira "Achados": um pratinho bege por item, com "×N" embaixo e o selo "Novo!" na primeira vez.
func _finds_panel(items: Dictionary, fresh: Array, cw: float, height: float, list_h: float, cols: int, scrolls: bool) -> Control:
	var panel := Control.new()
	panel.name = "ResultFinds"
	panel.custom_minimum_size = Vector2(cw, height)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var art := SellUi.nine("panel", Vector4i(69, 150, 69, 88), "Art", null, "item_")
	panel.add_child(art)
	StepCardUi.stretch(art)
	var heading := MissionUi.text("Achados", 17, Palette.WOOD_CREAM, 3)
	heading.name = "PanelTitle"
	panel.add_child(heading)
	SellUi.place(heading, 0.0, PANEL_SIDE, 1.0, -PANEL_SIDE, 0.0, 8.0, 0.0, 42.0)
	var inner_w := cw - PANEL_SIDE * 2.0
	var area_h := height - PANEL_TOP - PANEL_BOTTOM
	var flow := HFlowContainer.new()
	flow.name = "Found"
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", int(CELL_GAP))
	flow.add_theme_constant_override("v_separation", int(CELL_GAP))
	flow.mouse_filter = Control.MOUSE_FILTER_PASS
	flow.custom_minimum_size.x = cols * CELL_W + (cols - 1) * CELL_GAP
	flow.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for id: String in items:
		flow.add_child(_found_cell(id, int(items[id]), id in fresh))
	var holder := MarginContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	holder.add_theme_constant_override("margin_top", int(LIST_PAD))
	holder.add_theme_constant_override("margin_bottom", int(LIST_PAD))
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(flow)
	holder.add_child(center)
	var area := SellUi.scrolled(holder, inner_w, area_h if scrolls else list_h + LIST_PAD * 2.0, scrolls, {"scroll": 0}, "WalkResultScroll", "WalkResultBar", GUTTER)
	panel.add_child(area)
	SellUi.place(area, 0.0, PANEL_SIDE, 0.0, PANEL_SIDE + inner_w, 0.0, PANEL_TOP, 0.0, PANEL_TOP + (area_h if scrolls else list_h + LIST_PAD * 2.0))
	return panel


func _found_cell(id: String, amount: int, is_new: bool) -> Control:
	var cell := Control.new()
	cell.name = "Found_" + id
	cell.custom_minimum_size = Vector2(CELL_W, CELL_H)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plate := _plate(46.0, Database.item_icon(id), "Plate", 32.0)
	cell.add_child(plate)
	SellUi.place(plate, 0.5, -23.0, 0.5, 23.0, 0.0, 0.0, 0.0, 46.0)
	var count := StationWood.text("×%d" % amount, 16)
	count.name = "Amount"
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.add_child(count)
	SellUi.place(count, 0.0, 0.0, 1.0, 0.0, 0.0, 47.0, 0.0, 69.0)
	if is_new:
		var badge := PanelContainer.new()
		badge.name = "NewBadge"
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color("59b34a")
		style.border_color = Color("2f7a2c")
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		style.content_margin_left = 4.0
		style.content_margin_right = 4.0
		style.content_margin_top = 0.0
		style.content_margin_bottom = 0.0
		badge.add_theme_stylebox_override("panel", style)
		var label := StationWood.text("Novo!", 10, Palette.WOOD_CREAM, 2)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.add_child(label)
		cell.add_child(badge)
		SellUi.place(badge, 1.0, -34.0, 1.0, 0.0, 0.0, -2.0, 0.0, 14.0)
	return cell
