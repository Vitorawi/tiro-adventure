class_name WalksUi
extends RefCounted
## Folha "Passeios" (portão da Praça) no visual "madeira ilustrada", no molde da `ItemUi`: moldura `item_frame` com a placa
## "Passeios", o X de madeira e o (i) de madeira, um cartão creme em cima quando o Tiro está passeando (ou com bagagem
## esperando) e, embaixo, uma lista que rola por dentro com um cartão por caminho: foto, nome, chips de tempo e energia,
## a faixa "Pode achar:" com os achados em ÍCONES COLORIDOS (✓ = já tem, ? = ainda não, estrela = raro, dourado = lendário)
## e a ação (verde só no primeiro; os demais em amarelo; bloqueado = cadeado + motivo + "?").
## Só monta; as regras ficam no `GameState`. Nós preservados: `WalksInfo`, `WalkSlot`, `CancelWalk`, `CollectWalk`,
## `BaggageChips`/`Baggage_<item>`, `BaggageBlocked`, `GoDepot`, `WalkDiaryButton`, `WalkCard_<id>`, `StartWalk_<id>`,
## `Locked_StartWalk_<id>`, `WalkExclusives`, `Material_<item>`, `Rare_<coleção>`.

const PAD := 10.0
const PHOTO := Vector2(96, 60)         # 128x80 reduzido a 3/4, sem distorcer
const PHOTO_BORDER := 3.0
const ROW_A := 66.0                    # linha da foto (foto + moldurinha)
const PLATE := 44.0                    # alvo de toque do achado (o pratinho desenhado tem DRAWN)
const DRAWN := 38.0
const LABEL_W := 62.0                  # "Pode achar:"
const ACTION_H := 44.0
const GAP := 6.0
const BTN_W := 150.0
const GUTTER := 8.0
const MIN_LIST := 130.0
const BAND := Color("f3dcb8")
const BAND_EDGE := Color("d9b07a")
const GOLD := Color("e8a33a")
const EDGE := Color("b97a45")

## "Chamar de volta" pede dois toques: vale até este instante (Unix).
static func _armed_until() -> float:
	return float(Engine.get_meta("walks_cancel_armed", 0.0))


static func _arm(value: float) -> void:
	Engine.set_meta("walks_cancel_armed", value)


# --- Entrada -------------------------------------------------------------------------------

static func build() -> Control:
	var model := {"scroll": 0}
	var live := SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.name = "WalksBoard"
		box.add_theme_constant_override("separation", 0)
		# O tempo do passeio anda: só refaz a cada segundo enquanto o Tiro está fora.
		box.set_meta("tick_refresh", GameState.walk_state.active())
		box.add_child(_frame(model, ItemUi.panel_width()))
		var tail := Control.new()
		tail.custom_minimum_size.y = ItemUi.TAIL
		tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(tail))
	live.set_meta("sheet_bare", true)
	live.set_meta("sheet_fit_content", true)
	return live


static func _text_w(text: String, px: int) -> float:
	return ItemUi._text_w(text, px)


## Passeios liberados (do mais curto ao mais longo) e só os 2 próximos bloqueados.
static func _lists() -> Dictionary:
	var open: Array[String] = []
	var closed: Array[String] = []
	for id: String in Database.walks.get("walks", {}):
		if GameState.walk_lock_error(id) == "":
			open.append(id)
		elif closed.size() < 2:
			closed.append(id)
	open.sort_custom(func(a: String, b: String) -> bool:
		return int(Database.walks.walks[a].seconds) < int(Database.walks.walks[b].seconds))
	return {"open": open, "closed": closed}


static func _frame(model: Dictionary, width: float) -> Control:
	var cw := width - ItemUi.IN_L - ItemUi.IN_R
	var sheet_top := float((load("res://scripts/ui/hud.gd") as GDScript).get_script_constant_map()["SHEET_TOP"])
	var avail := ItemUi._screen().y - sheet_top - ItemUi.TAIL
	var status: Control = null
	if GameState.walk_ready():
		status = _status_baggage(cw)
	elif GameState.walk_state.active():
		status = _status_active(cw)
	var status_h := (status.custom_minimum_size.y + GAP) if status != null else 0.0
	var lists := _lists()
	var card_w := cw - GUTTER
	var holder := VBoxContainer.new()
	holder.name = "WalksList"
	holder.add_theme_constant_override("separation", int(GAP))
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	var natural := 0.0
	var header := _header_row(card_w)
	if header != null:
		holder.add_child(header)
		natural += header.custom_minimum_size.y + GAP
	var first_open := true
	for id: String in lists.open:
		var card := _walk_card(id, card_w, false, first_open)
		first_open = false
		holder.add_child(card)
		natural += card.custom_minimum_size.y + GAP
	for id: String in lists.closed:
		var card := _walk_card(id, card_w, true, false)
		holder.add_child(card)
		natural += card.custom_minimum_size.y + GAP
	natural -= GAP
	var room := avail - ItemUi.TOP - ItemUi.BOTTOM - status_h
	var list_h := clampf(natural, minf(natural, MIN_LIST), maxf(MIN_LIST, room))
	var scrolls := natural > list_h + 0.5
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.custom_minimum_size.x = cw - (GUTTER if scrolls else 0.0)
	var content_h := status_h + list_h
	var total := ItemUi.TOP + content_h + ItemUi.BOTTOM
	var frame := Control.new()
	frame.name = "WalksFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_PASS
	frame.custom_minimum_size = Vector2(width, total)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var art := SellUi.nine("frame", ItemUi.FRAME_MARGINS, "Art", null, "item_")
	frame.add_child(art)
	StepCardUi.stretch(art)
	var body := UiKit.vbox(int(GAP))
	body.name = "Body"
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	frame.add_child(body)
	SellUi.place(body, 0.0, ItemUi.IN_L, 1.0, -ItemUi.IN_R, 0.0, ItemUi.TOP, 0.0, ItemUi.TOP + content_h)
	if status != null:
		body.add_child(status)
	var area := SellUi.scrolled(holder, cw, list_h, scrolls, model, "WalksScroll", "WalksBar", GUTTER)
	body.add_child(area)
	var overlay := ItemUi._overlay(width, "Passeios")
	var info := _info_button()
	overlay.add_child(info)
	SellUi.place(info, 0.0, 2.0, 0.0, 46.0, 0.0, 48.0, 0.0, 92.0)
	frame.add_child(overlay)
	StepCardUi.stretch(overlay)
	return frame


## (i) de madeira: pratinho redondo com o "i" (alvo 44); abre o "Como fazer" dos passeios.
static func _info_button() -> Button:
	var info := BagUi.plain_button(func() -> void: TaskHelp.open("stat", "walk"))
	info.name = "WalksInfo"
	info.custom_minimum_size = Vector2(44, 44)
	var plate := SellUi.soft(TextureRect.new())
	plate.texture = ItemUi.tex("plate")
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode = TextureRect.STRETCH_SCALE
	info.add_child(plate)
	plate.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	plate.offset_left = -19.0
	plate.offset_right = 19.0
	plate.offset_top = -19.0
	plate.offset_bottom = 19.0
	var glyph := UiKit.ctl("info", 22, Palette.WOOD_INK)
	glyph.name = "InfoGlyph"
	info.add_child(glyph)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	glyph.offset_left = -11.0
	glyph.offset_right = 11.0
	glyph.offset_top = -11.0
	glyph.offset_bottom = 11.0
	info.pressed.connect(func() -> void: Motion.bounce(plate))
	return info


# --- Peças ---------------------------------------------------------------------------------

## Cartão creme (NinePatch `item_card`) de altura fixa; o conteúdo vai no `Body` (VBox).
static func _shell(node_name: String, height: float) -> Control:
	var card := Control.new()
	card.name = node_name
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.custom_minimum_size.y = height
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var art := SellUi.nine("card", Vector4i(75, 75, 75, 75), "Art", null, "item_")
	card.add_child(art)
	StepCardUi.stretch(art)
	var body := UiKit.vbox(int(GAP))
	body.name = "Body"
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(body)
	StepCardUi.stretch(body)
	body.offset_left = PAD
	body.offset_right = -PAD
	body.offset_top = PAD
	body.offset_bottom = -PAD
	return card


static func _body(card: Control) -> VBoxContainer:
	return card.get_node("Body") as VBoxContainer


## Foto do caminho numa moldurinha de madeira: escala uniforme (96x60 de 128x80), sem distorcer.
static func _photo(path: String) -> Control:
	var holder := Control.new()
	holder.name = "Photo"
	holder.custom_minimum_size = PHOTO + Vector2.ONE * PHOTO_BORDER * 2.0
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("6b4423")
	style.border_color = EDGE
	style.set_border_width_all(int(PHOTO_BORDER))
	style.set_corner_radius_all(7)
	back.add_theme_stylebox_override("panel", style)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(back)
	StepCardUi.stretch(back)
	var picture := TextureRect.new()
	picture.name = "Postcard"
	picture.texture = WalkResult.postcard_texture(path)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(picture)
	SellUi.place(picture, 0.0, PHOTO_BORDER, 1.0, -PHOTO_BORDER, 0.0, PHOTO_BORDER, 1.0, -PHOTO_BORDER)
	return holder


## Linha do topo: foto + (nome, extra) na coluna da direita.
static func _top_row(path: String, title: String, extra: Control, width: float) -> Control:
	var row := UiKit.hbox(10)
	row.name = "TopRow"
	row.custom_minimum_size.y = ROW_A
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(_photo(path))
	var column := UiKit.vbox(4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_PASS
	var avail := width - PAD * 2.0 - PHOTO.x - PHOTO_BORDER * 2.0 - 10.0
	var px := 17
	for candidate in [17, 16, 15, 14, 13]:
		px = candidate
		if _text_w(title, candidate) <= avail:
			break
	var label := StationWood.text(title, px)
	label.name = "WalkName"
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(label)
	if extra != null:
		column.add_child(extra)
	row.add_child(column)
	return row


## Chip de madeira; ilustração (clock) reduzida e suave, pixel nítido.
static func _chip(icon: Texture2D, value: String, tone: String = "", node_name: String = "") -> Control:
	var chip := StepCardUi.wood_chip(icon, value, tone, Callable(), node_name)
	if icon != null and icon.get_width() > 48:
		for node in chip.find_children("*", "TextureRect", true, false):
			(node as TextureRect).texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return chip


static func _clock_icon() -> Texture2D:
	return load(HomeUi.DIR + "station_clock.png") as Texture2D


## Botão de madeira (verde = principal, amarelo = secundário). `Button.text` guarda o texto (testes/consulta) e fica
## transparente: quem aparece é o rótulo da arte.
static func _button(caption: String, gold: bool, width: float, on_pressed: Callable) -> Button:
	var action := on_pressed if on_pressed.is_valid() else func() -> void: pass
	var button := ItemUi._action_button(caption, gold, width, action)
	button.text = caption
	for key: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color", "font_outline_color"]:
		button.add_theme_color_override(key, Color(0, 0, 0, 0))
	button.add_theme_constant_override("outline_size", 0)
	return button


static func _action_row(button: Control) -> Control:
	var row := UiKit.hbox(8)
	row.name = "Actions"
	row.alignment = BoxContainer.ALIGNMENT_END
	row.custom_minimum_size.y = ACTION_H
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(button)
	return row


# --- Cabeçalho da lista --------------------------------------------------------------------

## Bônus ativos (Pipoca, bolsinha) e o Diário; nada disso aparece antes de existir.
static func _header_row(_width: float) -> Control:
	var bonuses: Array[String] = []
	if GameState.friend_walk_bonus() > 0:
		bonuses.append("Com Pipoca · +1")
	if GameState.has_upgrade("walk_bag"):
		bonuses.append("Bolsinha · +1")
	var diary := GameState.progress.feature_unlocked("walk_diary")
	if bonuses.is_empty() and not diary:
		return null
	var row := UiKit.hbox(8)
	row.name = "WalksHeader"
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var chips := UiKit.vbox(4)
	chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chips.mouse_filter = Control.MOUSE_FILTER_PASS
	for text in bonuses:
		var chip := _chip(UiKit.ui_icon("action_walk"), text, "have")
		chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		chips.add_child(chip)
	row.add_child(chips)
	var height := bonuses.size() * 32.0 + maxf(0.0, bonuses.size() - 1.0) * 4.0
	if diary:
		var button := _button("Diário", true, 100.0, func() -> void:
			Events.sheet_requested.emit("Diário de passeios", ProgressionUi.walk_diary()))
		button.name = "WalkDiaryButton"
		row.add_child(button)
		height = maxf(height, ACTION_H)
	row.custom_minimum_size.y = height
	return row


# --- Passeio em andamento / bagagem --------------------------------------------------------

static func _status_active(width: float) -> Control:
	var entry: Dictionary = GameState.walk_state.current
	var id := str(entry.id)
	var remaining := GameState.walk_remaining()
	var seconds := maxf(1.0, float(entry.ready_at) - float(entry.started_at))
	var card := _shell("WalkStatus", PAD * 2.0 + ROW_A + GAP + ACTION_H)
	var timer := UiKit.hbox(8)
	timer.mouse_filter = Control.MOUSE_FILTER_PASS
	var slot := Control.new()
	slot.name = "WalkSlot"
	slot.custom_minimum_size = Vector2(36, 36)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ring := RingProgress.new()
	ring.custom_minimum_size = Vector2(36, 36)
	ring.thickness = 4.0
	ring.color = GOLD
	ring.track = Color("e9cfa6")
	ring.progress = clampf(1.0 - remaining / seconds, 0.0, 1.0)
	slot.add_child(ring)
	StepCardUi.stretch(ring)
	var clock := SellUi.soft(TextureRect.new())
	clock.texture = _clock_icon()
	clock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	clock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.add_child(clock)
	SellUi.place(clock, 0.5, -9.0, 0.5, 9.0, 0.5, -9.0, 0.5, 9.0)
	timer.add_child(slot)
	var time := StationWood.text(TimeText.short(remaining), 20)
	time.name = "WalkTime"
	timer.add_child(time)
	var body := _body(card)
	body.add_child(_top_row(GameState.walk_postcard(id), str(GameState.walk_def(id).get("name", "")), timer, width))
	var armed := GameState.now() < _armed_until()
	var call_back := _button("Toque de novo" if armed else "Chamar de volta", true, 190.0, Callable())
	call_back.name = "CancelWalk"
	call_back.pressed.connect(func() -> void:
		if GameState.now() < _armed_until():
			_arm(0.0)
			GameState.cancel_walk()
			Events.toast_requested.emit("Tiro voltou para casa")
		else:
			_arm(GameState.now() + 4.0)
			var caption := call_back.find_child("Caption", true, false) as Label
			if caption != null:
				caption.text = "Toque de novo"
			Events.toast_requested.emit("Sem prêmio se voltar agora. Toque de novo."))
	body.add_child(_action_row(call_back))
	return card


## O Tiro já voltou: a bagagem espera. Guardar o que cabe é uma ação à parte; o que sobra continua aqui.
static func _status_baggage(width: float) -> Control:
	var view := GameState.walk_result_view()
	var left: Dictionary = GameState.walk_state.baggage_left()
	var inner := width - PAD * 2.0
	var per_row := maxi(1, int(floor((inner + 4.0) / 68.0)))
	var rows := maxi(1, ceili(left.size() / float(per_row)))
	var error := GameState.walk_baggage_error()
	var hint := GameState.walk_baggage_hint() if error == "" else ""
	var depot := GameState.walk_baggage_depot() if error != "" else ""
	var height := PAD * 2.0 + ROW_A + GAP + rows * 32.0 + (rows - 1) * 4.0 + GAP
	if error == "":
		height += ACTION_H + (GAP + 18.0 if hint != "" else 0.0)
	else:
		height += ACTION_H + (GAP + ACTION_H if depot != "" else 0.0)
	var card := _shell("WalkStatus", height)
	var voltou := _chip(UiKit.ui_icon("action_walk"), "Voltou!", "have")
	voltou.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var slot := Control.new()
	slot.name = "WalkSlot"
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.custom_minimum_size.y = 32.0
	slot.add_child(voltou)
	var body := _body(card)
	body.add_child(_top_row(str(view.get("postcard", "")), str(view.get("name", "")), slot, width))
	var chips := UiKit.flow(4)
	chips.name = "BaggageChips"
	chips.mouse_filter = Control.MOUSE_FILTER_PASS
	for item_id: String in left:
		chips.add_child(_chip(Database.item_icon(item_id), "×%d" % int(left[item_id]), "", "Baggage_" + item_id))
	body.add_child(chips)
	if error == "":
		var store := ItemUi._action_button("Guardar achados", false, minf(inner, 220.0), func() -> void: GameState.claim_walk_baggage())
		store.name = "CollectWalk"
		body.add_child(_action_row(store))
		if hint != "":
			var note := StationWood.text(hint, 13)
			note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			note.custom_minimum_size.y = 18.0
			body.add_child(note)
	else:
		var lock := StepCardUi.lock_note(error)
		lock.name = "BaggageBlocked"
		lock.custom_minimum_size.y = ACTION_H
		body.add_child(lock)
		if depot != "":
			var data: Dictionary = Database.progression.storage[depot]
			var go := _button("Abrir " + GameState.storage_name(depot), true, minf(inner, 260.0), func() -> void:
				Events.sheet_close_requested.emit()
				Events.world_requested.emit(str(data.get("world", "house")), str(data.get("place", ""))))
			go.name = "GoDepot"
			body.add_child(_action_row(go))
	return card


# --- Um cartão por caminho -----------------------------------------------------------------

static func _walk_card(id: String, width: float, locked: bool, primary: bool) -> Control:
	var data: Dictionary = Database.walks.walks[id]
	var inner := width - PAD * 2.0
	var finds: Array[Dictionary] = []
	if not locked:
		finds = _finds(id)
	var rows := _strip_rows(finds.size(), inner - 16.0)
	var strip_h := 12.0 + rows * PLATE
	var error := "" if locked else GameState.walk_error(id)
	var height := PAD * 2.0 + ROW_A + GAP + ACTION_H
	if not finds.is_empty():
		height += strip_h + GAP
	var card := _shell("WalkCard_" + id, height)
	if locked:
		card.modulate.a = 0.62
	var extra := UiKit.flow(4)
	extra.mouse_filter = Control.MOUSE_FILTER_PASS
	if locked:
		for chip: Control in _requirement_chips(data.get("requirements", {})):
			extra.add_child(chip)
	else:
		extra.add_child(_chip(_clock_icon(), TimeText.short(int(data.seconds))))
		extra.add_child(_chip(Database.need_icon("energy"), str(int(data.get("energy", 0)))))
	var body := _body(card)
	body.add_child(_top_row(GameState.walk_postcard(id), str(data.name), extra, width))
	if not finds.is_empty():
		body.add_child(_strip(finds))
	if locked:
		var reason := GameState.walk_lock_error(id)
		var note := StepCardUi.lock_note(reason, TaskHelp.open.bind("walk", id))
		note.custom_minimum_size.y = ACTION_H
		body.add_child(note)
		return card
	if error == "":
		var go := _button("Passear", not primary, BTN_W, func() -> void:
			var failure := GameState.start_walk(id)
			if failure != "":
				Events.toast_requested.emit(failure)
			else:
				Events.sheet_close_requested.emit())
		go.name = "StartWalk_" + id
		body.add_child(_action_row(go))
	else:
		var tired := float(GameState.dog.needs.energy) < int(data.get("energy", 0))
		var hint := StepCardUi.lock_note(error, TaskHelp.open.bind("walk", id), Database.need_icon("energy") if tired else null)
		hint.name = "Locked_StartWalk_" + id
		hint.set_meta("reason", error)
		hint.custom_minimum_size.y = ACTION_H
		body.add_child(hint)
	return card


static func _requirement_chips(requirements: Dictionary) -> Array[Control]:
	var chips: Array[Control] = []
	for key: String in requirements.get("stats", {}):
		var need := int(requirements.stats[key])
		var label := "%d/%d" % [mini(GameState.progress.stat(key), need), need]
		chips.append(_chip(UiKit.ui_icon("action_walk"), label + " passeios" if key == "walk" else label))
	for upgrade: String in requirements.get("owned", []):
		var built: Dictionary = Database.progression.upgrades.get(upgrade, {})
		chips.append(_chip(UiKit.ui_icon(str(built.get("icon", "tab_map"))), str(built.get("name", upgrade)).trim_prefix("Desbloquear ")))
	if requirements.has("hours"):
		chips.append(_chip(_clock_icon(), "%dh" % int(requirements.hours[0])))
	if requirements.has("quests") and not requirements.has("stats"):
		chips.append(_chip(UiKit.ui_icon("tab_tasks"), "Missão"))
	return chips


# --- "Pode achar:" -------------------------------------------------------------------------

## Achados possíveis do caminho: materiais, o apetrecho raro e (se liberado) o lendário. `have` = já tem.
static func _finds(id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: String in ProgressionUi.walk_materials(id):
		result.append({"kind": "material", "id": item, "name": Database.item_name(item), "icon": Database.item_icon(item), "have": GameState.progress.stat("walk_item:" + item) > 0})
	var rare := str(GameState.walk_def(id).get("loot", {}).get("rare", {}).get("collection", ""))
	if rare != "":
		result.append({"kind": "rare", "id": rare, "name": Database.item_name(rare), "icon": UiKit.ui_icon(str(Database.collections.get(rare, {}).get("icon", ""))), "have": GameState.progress.collection.has(rare)})
	var legendary: Dictionary = Database.walks.get("legendary", {})
	if not legendary.is_empty() and GameState.progress.feature_unlocked("legendary_walks") and GameState.requirement_error(legendary.get("requirements", {})) == "":
		var pick := ""
		var have := true
		for piece: String in legendary.get("collections", []):
			pick = piece
			if not GameState.progress.collection.has(piece):
				have = false
				break
		if pick != "":
			result.append({"kind": "legend", "id": pick, "name": Database.item_name(pick), "icon": UiKit.ui_icon(str(Database.collections.get(pick, {}).get("icon", ""))), "have": have})
	return result


static func _strip_rows(count: int, width: float) -> int:
	var rows := 1
	var x := LABEL_W
	for i in count:
		if x + PLATE > width:
			rows += 1
			x = 0.0
		x += PLATE
	return rows


static func _strip(finds: Array[Dictionary]) -> Control:
	var band := PanelContainer.new()
	band.name = "WalkFinds"
	band.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = BAND
	style.border_color = BAND_EDGE
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	band.add_theme_stylebox_override("panel", style)
	var flow := HFlowContainer.new()
	flow.name = "WalkExclusives"
	flow.add_theme_constant_override("h_separation", 0)
	flow.add_theme_constant_override("v_separation", 0)
	flow.mouse_filter = Control.MOUSE_FILTER_PASS
	var label := StationWood.text("Pode achar:", 12)
	label.name = "FindsLabel"
	label.custom_minimum_size = Vector2(LABEL_W, PLATE)
	flow.add_child(label)
	for entry in finds:
		flow.add_child(_find_cell(entry))
	band.add_child(flow)
	return band


## Pratinho colorido do achado. ✓ = já tem; "?" = ainda não; estrela = raro; borda dourada = lendário.
static func _find_cell(entry: Dictionary) -> Control:
	var kind := str(entry.kind)
	var have := bool(entry.have)
	var cell := BagUi.plain_button(func() -> void:
		Events.toast_requested.emit("%s · %s" % [str(entry.name), "você já tem" if have else "ainda não achou"]))
	cell.custom_minimum_size = Vector2(PLATE, PLATE)
	cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cell.name = {"material": "Material_", "rare": "Rare_", "legend": "Legend_"}[kind] + str(entry.id)
	var visual := Control.new()
	visual.name = "Visual"
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(visual)
	SellUi.place(visual, 0.5, -DRAWN / 2.0, 0.5, DRAWN / 2.0, 0.5, -DRAWN / 2.0, 0.5, DRAWN / 2.0)
	var plate := SellUi.soft(TextureRect.new())
	plate.texture = ItemUi.tex("plate")
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode = TextureRect.STRETCH_SCALE
	visual.add_child(plate)
	StepCardUi.stretch(plate)
	var icon_texture: Texture2D = entry.icon
	if icon_texture != null:
		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.texture = icon_texture
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var px := 32.0
		if icon_texture.get_width() <= 32:
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # 32 em 32: pixel exato
		else:
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			px = 30.0
		visual.add_child(icon)
		SellUi.place(icon, 0.5, -px / 2.0, 0.5, px / 2.0, 0.5, -px / 2.0, 0.5, px / 2.0)
	if kind != "material":
		var ring := Panel.new()
		ring.name = "Gold"
		var edge := StyleBoxFlat.new()
		edge.bg_color = Color(0, 0, 0, 0)
		edge.border_color = GOLD
		edge.set_border_width_all(3 if kind == "legend" else 2)
		edge.set_corner_radius_all(int(DRAWN / 2.0))
		if kind == "legend":
			edge.shadow_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.6)
			edge.shadow_size = 4
		ring.add_theme_stylebox_override("panel", edge)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.add_child(ring)
		StepCardUi.stretch(ring)
		var star := UiKit.icon(UiKit.ui_icon("rare_star"), 14)
		star.name = "RareStar"
		star.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		visual.add_child(star)
		SellUi.place(star, 0.0, -3.0, 0.0, 11.0, 0.0, -3.0, 0.0, 11.0)
	if have:
		var medal := StepCardUi.done_medal(15.0, "Have")
		visual.add_child(medal)
		SellUi.place(medal, 1.0, -13.0, 1.0, 2.0, 1.0, -13.0, 1.0, 2.0)
	else:
		var mark := PanelContainer.new()
		mark.name = "Unknown"
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dot := StyleBoxFlat.new()
		dot.bg_color = Color("f3cf98")
		dot.border_color = EDGE
		dot.set_border_width_all(1)
		dot.set_corner_radius_all(8)
		mark.add_theme_stylebox_override("panel", dot)
		var question := StationWood.text("?", 11)
		question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.add_child(question)
		visual.add_child(mark)
		SellUi.place(mark, 1.0, -13.0, 1.0, 2.0, 1.0, -13.0, 1.0, 2.0)
	cell.pressed.connect(func() -> void: Motion.bounce(plate))
	return cell
