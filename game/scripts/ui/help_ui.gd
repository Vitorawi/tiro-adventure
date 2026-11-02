class_name HelpUi
extends RefCounted
## Tela "Como fazer" no visual "madeira ilustrada", no mesmo molde do detalhe de item (`ItemUi`): moldura com a placa do
## título e o X de madeira, um cartão creme compacto em cima (pratinho com o ícone, nome, pílula tem/precisa e uma linha
## de detalhe) e, embaixo, um ou mais painéis de madeira ("Onde conseguir", "Passo", "Ingredientes"...) com uma linha por
## passo: pratinho, nome, pílula n/m, texto curto e, à direita, o botão Ir (só o primeiro pendente é verde; os outros são
## o botão amarelo calmo) ou o medalhão de "feito". Cada painel rola por dentro quando não cabe; a folha nunca passa da
## área entre o HUD e a base da tela. Reaproveita as imagens `item_*.png` (`tools/item_art.gd`).
## Só monta; as decisões (o que falta, para onde ir) continuam em `TaskHelp.describe`. Nós preservados: `HelpGo`,
## `ItemSource`, `FoodGuideAction`, `GrowthCare_<id>`; novos: `HelpBack`, `HelpTitle`, `HelpCard`, `HelpSection_<nome>`,
## `HelpRow_<i>`, `HelpDone`.

const SIDE := ItemUi.SIDE
const IN_L := ItemUi.IN_L
const IN_R := ItemUi.IN_R
const TOP := ItemUi.TOP
const BOTTOM := ItemUi.BOTTOM
const GAP := ItemUi.GAP
const TAIL := ItemUi.TAIL
const PANEL_TOP := ItemUi.PANEL_TOP
const PANEL_BOTTOM := ItemUi.PANEL_BOTTOM
const PANEL_SIDE := ItemUi.PANEL_SIDE
const LIST_PAD := ItemUi.LIST_PAD
const GUTTER := ItemUi.GUTTER
const PLATE := ItemUi.PLATE
const CARD_PAD_X := ItemUi.CARD_PAD_X
const CARD_PAD_Y := ItemUi.CARD_PAD_Y
const PILL_H := 28.0
const ROW_PLATE := 44.0
const ROW_PAD_X := 6.0
const ROW_PAD_Y := 7.0
const ROW_GAP := 8.0
const BTN_W := 72.0
const BTN_H := 44.0
const DIVIDER := 2.0
const TITLE_PX := 15
const TEXT_PX := 13
const HEAD_PX := 17
const GREEN_OUTLINE := Color("2b5560")
const LINE_COLOR := Color("e2c08f")


# --- Medidas --------------------------------------------------------------------------------

static func _font(px: int) -> Font:
	return HomeUi.theme(px).default_font

static var _measure_cache: Dictionary = {}


static func _text_w(text: String, px: int) -> float:
	return _font(px).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x


## Label no estilo da madeira (fonte `px`, quebra por palavra, sem espaço extra entre linhas). `_label` completa.
static func _plain_label(text: String, px: int, width: float) -> Label:
	var label := StationWood.text(text, px)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.add_theme_constant_override("line_spacing", 0)
	label.custom_minimum_size = Vector2(width, 0.0)
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return label


## Linhas e altura de um texto quebrado em `width` (no máximo `cap` linhas), medidos num Label de verdade: a altura da
## linha muda com os glifos (a seta "→" e os acentos vêm de outra fonte e deixam a linha mais alta).
static func _measure(text: String, px: int, width: float, cap: int) -> Dictionary:
	if text == "":
		return {"lines": 0, "height": 0.0}
	var key := "%s|%d|%d|%d" % [text, px, int(width * 10.0), cap]
	if _measure_cache.has(key):
		return _measure_cache[key]
	var probe := _plain_label(text, px, width)
	probe.visible = false
	(Engine.get_main_loop() as SceneTree).root.add_child(probe)  # o tema só vale dentro da árvore
	probe.size = Vector2(width, 0.0)
	var lines := clampi(probe.get_line_count(), 1, cap)
	var height := 0.0
	for i in lines:
		height += float(probe.get_line_height(i))
	probe.free()
	var result := {"lines": lines, "height": height}
	_measure_cache[key] = result
	return result

# --- Entrada --------------------------------------------------------------------------------

## `history` = etapas anteriores, para o botão de voltar.
static func build(kind: String, id: String, amount: int, history: Array[Dictionary]) -> Control:
	var model := {}
	var live := SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.name = "HelpBoard"
		box.add_theme_constant_override("separation", 0)
		box.add_child(_frame(_spec(kind, id, amount, history), history, model, ItemUi.panel_width()))
		var tail := Control.new()
		tail.custom_minimum_size.y = TAIL
		tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(tail))
	live.set_meta("sheet_bare", true)
	live.set_meta("sheet_fit_content", true)
	live.set_meta("tick_refresh", false)  # as listas rolam e os botões não podem sumir sob o dedo
	return live


## Item cuja ilustração (`food_<id>.png`) deve aparecer no lugar do ícone pixel.
static func _food_id(kind: String, id: String) -> String:
	match kind:
		"item", "crop", "produced":
			return id
		"recipe":
			return Database.recipe_output(Database.recipes[id])
	return ""


# --- O que mostrar (decisões; as regras vêm do TaskHelp.describe) --------------------------------

static func _button(caption: String, green: bool, node_name: String, fn: Callable) -> Dictionary:
	return {"caption": caption, "green": green, "name": node_name, "fn": fn}


static func _tone(enough: bool) -> String:
	return "have" if enough else "missing"


static func _spec(kind: String, id: String, amount: int, history: Array[Dictionary]) -> Dictionary:
	var data := TaskHelp.describe(kind, id, amount)
	var header := {"texture": TaskHelp.icon_for(kind, id), "food": _food_id(kind, id), "title": str(data.title), "pill": {}, "detail": ""}
	if data.has("progress_text"):
		header.detail = str(data.progress_text)
	elif data.has("stock") or kind == "item":
		var enough := GameState.inventory.count(id) >= amount
		header.pill = {"text": str(data.get("stock", "%d/%d" % [GameState.inventory.count(id), amount])), "tone": _tone(enough)}
	var path: Array[Dictionary] = history.duplicate()
	path.append({"kind": kind, "id": id, "amount": amount})
	var sections: Array[Dictionary] = []
	# Já tem: só leva ao uso.
	if kind == "item" and GameState.inventory.count(id) >= amount:
		var uses := SheetBuilder._uses(id)
		var target: Dictionary = uses[0].target if not uses.is_empty() else data.target
		# Comida usa o mesmo destino da Tigela; os outros usos vêm do catálogo do item.
		if Database.items[id].has("feed"): target = Places.goal_target({"type": "stat", "key": "feed"})
		if str(Database.items[id].get("category", "")) == "keepsake": target = {"growth": true}
		for req: Dictionary in GameState.growth_info().requirements:
			if str(req.type) == "deliver" and str(req.item) == id and not req.done: target = {"growth": true}
		sections.append({"title": "Pronto", "name": "Have", "rows": [{"texture": TaskHelp.icon_for(kind, id), "food": id, "title": "Você já tem.", "button": _button("Ir", false, "HelpGo", TaskHelp._go.bind(target))}]})
		header.detail = ""
		return {"header": header, "sections": sections}
	if data.has("food_guide"):
		var guide: Dictionary = data.food_guide
		var input_rows: Array[Dictionary] = []
		var primary_used := false
		for input: Dictionary in guide.inputs:
			var enough := int(input.have) >= int(input.amount)
			var seek := TaskHelp.open.bind("item", str(input.id), int(input.amount), path)
			var row := {"texture": Database.item_icon(input.id), "food": str(input.id), "title": str(input.label), "pill": {"text": "%d/%d" % [input.have, input.amount], "tone": _tone(enough)}, "text": str(input.where) if not enough else "", "done": enough}
			if not enough:
				row["button"] = _button("Ir", not primary_used, "", seek)
				primary_used = true
			input_rows.append(row)
		var prep_text := str(guide.preparation) + "\n" + str(guide.status)
		if guide.next != "": prep_text += "\n" + str(guide.next)
		var prep := {"texture": TaskHelp.icon_for(kind, id), "food": _food_id(kind, id), "title": str(guide.place), "text": prep_text, "button": _button("Ir", not primary_used and not bool(guide.done), "FoodGuideAction", TaskHelp._go.bind(guide.target))}
		sections.append({"title": "Preparo", "name": "Prep", "rows": [prep]})
		sections.append({"title": "Ingredientes por preparo", "name": "Inputs", "rows": input_rows})
		return {"header": header, "sections": sections}
	if data.has("steps"):
		var care_rows: Array[Dictionary] = []
		var primary_used := false
		for care: Dictionary in data.steps:
			var done := bool(care.done)
			var row := {"texture": UiKit.ui_icon(str(Database.growth.pillars[care.id].icon)), "title": str(care.title), "pill": {"text": str(care.progress), "tone": "have" if done else ""}, "text": "" if done else str(care.hint), "done": done}
			if not done:
				row["button"] = _button("Ir", not primary_used, "GrowthCare_" + str(care.id), TaskHelp._go.bind(care.target))
				primary_used = true
			care_rows.append(row)
		sections.append({"title": "Cuidados", "name": "Care", "rows": care_rows})
		return {"header": header, "sections": sections}
	# Caso geral: onde conseguir, o primeiro passo (HelpGo) e o que falta, item por item.
	var recipe_destination := str(data.target.get("place", "")).begins_with("recipe:")
	var first: Dictionary = {} if recipe_destination else data.get("next_need", {})
	var step_text := str(data.get("next", str(data.detail).trim_prefix(str(data.get("source_text", "")) + "\n")))
	if recipe_destination:
		var recipe: Dictionary = Database.recipes[str(data.target.place).trim_prefix("recipe:")]
		step_text = "%s → %s" % [Database.worlds[str(data.target.world)].name, Database.stations[str(recipe.station)].name]
	if data.has("source_text") and data.has("next"):
		step_text = "Primeiro: " + step_text
		var hint := str(data.get("next_target", {}).get("hint", ""))
		if hint != "": step_text += "\n" + hint
	var visible_needs: Array = data.get("ingredients", data.needs)
	var missing_index := -1
	for index in visible_needs.size():
		if int(visible_needs[index].have) < int(visible_needs[index].amount):
			missing_index = index
			break
	var destination: Dictionary = data.target if recipe_destination else data.get("next_target", data.target)
	if str(data.get("source_text", "")) != "":
		var source_row := {"texture": TaskHelp.icon_for(kind, id), "food": _food_id(kind, id), "title": str(data.title), "text": str(data.source_text), "text_name": "ItemSource"}
		if data.target != destination:
			source_row["button"] = _button("Ir", false, "", TaskHelp._go.bind(data.target))
		sections.append({"title": "Onde conseguir", "name": "Source", "rows": [source_row]})
	var step_row := {"texture": TaskHelp.need_icon(first) if not first.is_empty() else TaskHelp.icon_for(kind, id), "food": str(first.id) if not first.is_empty() and str(first.get("kind", "")) == "item" else _food_id(kind, id), "title": step_text, "button": _button("Ir", missing_index < 0, "HelpGo", TaskHelp._go.bind(destination))}
	sections.append({"title": "Primeiro passo" if data.has("source_text") else "Próximo passo", "name": "Step", "rows": [step_row]})
	if (recipe_destination or data.has("next")) and data.detail != "" and not data.has("source_text"):
		header.detail = str(data.detail)
	if not visible_needs.is_empty():
		var need_rows: Array[Dictionary] = []
		for index in visible_needs.size():
			var need: Dictionary = visible_needs[index]
			var ok := int(need.have) >= int(need.amount)
			var row := {"texture": TaskHelp.need_icon(need), "food": str(need.id) if str(need.kind) == "item" else "", "title": str(need.label), "pill": {"text": "%d/%d" % [int(need.have), int(need.amount)], "tone": _tone(ok)}, "done": ok}
			if not ok:
				row["button"] = _button("Ir", index == missing_index, "", TaskHelp.open.bind(str(need.kind), str(need.id), int(need.amount), path))
			need_rows.append(row)
		sections.append({"title": "Ingredientes", "name": "Needs", "rows": need_rows})
	return {"header": header, "sections": sections}


# --- Moldura --------------------------------------------------------------------------------

static func _screen() -> Vector2:
	return (Engine.get_main_loop() as SceneTree).root.get_visible_rect().size


static func _frame(spec: Dictionary, history: Array[Dictionary], model: Dictionary, width: float) -> Control:
	var cw := width - IN_L - IN_R
	var card_plan := _card_plan(spec.header, cw)
	var avail := _screen().y - float((load("res://scripts/ui/hud.gd") as GDScript).get_script_constant_map()["SHEET_TOP"]) - TAIL
	var sections: Array[Dictionary] = []
	sections.assign(spec.sections)
	var room := avail - (TOP + float(card_plan.height) + GAP + BOTTOM)
	var stack_plan := _plan_stack(sections, cw, room)
	var total := TOP + float(card_plan.height) + GAP + float(stack_plan.shown) + BOTTOM
	var frame := Control.new()
	frame.name = "HelpFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_PASS
	frame.custom_minimum_size = Vector2(width, total)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.set_meta("est_card_h", float(card_plan.height))
	var art := SellUi.nine("frame", ItemUi.FRAME_MARGINS, "Art", null, "item_")
	frame.add_child(art)
	StepCardUi.stretch(art)
	var card := _card(spec.header, card_plan)
	frame.add_child(card)
	SellUi.place(card, 0.0, IN_L, 1.0, -IN_R, 0.0, TOP, 0.0, TOP + float(card_plan.height))
	var top := TOP + float(card_plan.height) + GAP
	var area := _stack(stack_plan, cw, model)
	frame.add_child(area)
	var bar := GUTTER if bool(stack_plan.scrolls) else 0.0
	SellUi.place(area, 0.0, IN_L, 1.0, -IN_R + bar, 0.0, top, 0.0, top + float(stack_plan.shown))
	var overlay := _overlay(width, history)
	frame.add_child(overlay)
	StepCardUi.stretch(overlay)
	return frame


## Placa "Como fazer" e X (reaproveitados do detalhe de item) mais o voltar de madeira quando há etapa anterior.
static func _overlay(width: float, history: Array[Dictionary]) -> Control:
	var layer := ItemUi._overlay(width, "Como fazer")
	(layer.find_child("ItemTitle", true, false) as Control).name = "HelpTitle"
	if history.is_empty():
		return layer
	var previous: Dictionary = history.back()
	var back := BagUi.plain_button(func() -> void:
		var rest: Array[Dictionary] = history.duplicate()
		rest.pop_back()
		TaskHelp.open(previous.kind, previous.id, previous.amount, rest))
	back.name = "HelpBack"
	back.custom_minimum_size = Vector2(44, 44)
	var plate := SellUi.soft(TextureRect.new())
	plate.texture = ItemUi.tex("plate")
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode = TextureRect.STRETCH_SCALE
	back.add_child(plate)
	plate.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	plate.offset_left = -19.0
	plate.offset_right = 19.0
	plate.offset_top = -19.0
	plate.offset_bottom = 19.0
	var arrow := UiKit.ctl("back", 22, Palette.WOOD_INK)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(arrow)
	arrow.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	arrow.offset_left = -11.0
	arrow.offset_right = 11.0
	arrow.offset_top = -11.0
	arrow.offset_bottom = 11.0
	back.pressed.connect(func() -> void: Motion.bounce(plate))
	layer.add_child(back)
	SellUi.place(back, 0.0, 2.0, 0.0, 46.0, 0.0, 48.0, 0.0, 92.0)
	return layer


# --- Cartão do topo ---------------------------------------------------------------------------

static func _card_plan(header: Dictionary, cw: float) -> Dictionary:
	var inner_w := cw - CARD_PAD_X * 2.0
	var text_w := inner_w - PLATE - 10.0
	var title_m := _measure(str(header.title), HEAD_PX, text_w, 2)
	var detail_m := _measure(str(header.detail), TEXT_PX, text_w, 3)
	var words_h := float(title_m.height)
	if not (header.pill as Dictionary).is_empty():
		words_h += 3.0 + PILL_H
	if int(detail_m.lines) > 0:
		words_h += 3.0 + float(detail_m.height)
	var words := maxf(PLATE, words_h)
	return {"height": CARD_PAD_Y * 2.0 + words, "words_h": words, "title_m": title_m, "detail_m": detail_m, "text_w": text_w}


## Label já medido (`m` = resultado de `_measure`): mostra exatamente as linhas previstas, sem cortar no meio.
static func _label(text: String, px: int, m: Dictionary, width: float, node_name: String = "") -> Label:
	var label := _plain_label(text, px, width)
	label.max_lines_visible = int(m.lines)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.custom_minimum_size = Vector2(width, float(m.height))
	if node_name != "":
		label.name = node_name
	return label


static func _card(header: Dictionary, plan: Dictionary) -> Control:
	var card := Control.new()
	card.name = "HelpCard"
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var art := SellUi.nine("card", Vector4i(75, 75, 75, 75), "Art", null, "item_")
	card.add_child(art)
	StepCardUi.stretch(art)
	var body := UiKit.hbox(10)
	body.name = "Body"
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_child(body)
	StepCardUi.stretch(body)
	body.offset_left = CARD_PAD_X
	body.offset_right = -CARD_PAD_X
	body.offset_top = CARD_PAD_Y
	body.offset_bottom = -CARD_PAD_Y
	var hero := _plate(header.texture, str(header.food), PLATE, ItemUi.HERO_ICON, "HelpHero")
	hero.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	body.add_child(hero)
	var words := UiKit.vbox(3)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var text_w := float(plan.text_w)
	words.add_child(_label(str(header.title), HEAD_PX, plan.title_m, text_w, "HelpName"))
	if not (header.pill as Dictionary).is_empty():
		words.add_child(_pill(str(header.pill.text), str(header.pill.tone), "HelpPill"))
	if int((plan.detail_m as Dictionary).lines) > 0:
		words.add_child(_label(str(header.detail), TEXT_PX, plan.detail_m, text_w, "HelpDetail"))
	body.add_child(words)
	return card


## Pratinho redondo com o ícone: pixel em escala inteira e nítido; ilustração reduzida e suave (como no detalhe de item).
static func _plate(texture: Texture2D, food_id: String, plate_px: float, big_px: float, node_name: String) -> Control:
	var hero := Control.new()
	hero.name = node_name
	hero.custom_minimum_size = Vector2(plate_px, plate_px)
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plate := SellUi.soft(TextureRect.new())
	plate.name = "Plate"
	plate.texture = ItemUi.tex("plate")
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode = TextureRect.STRETCH_SCALE
	hero.add_child(plate)
	StepCardUi.stretch(plate)
	var food := StationWood.food_texture(food_id)
	var source: Texture2D = food if food != null else texture
	if source == null:
		return hero
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = source
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var px := big_px
	if source.get_width() <= 32:
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		px = 32.0 if plate_px < 60.0 else big_px  # 32 -> 32 (linha) ou 32 -> 64 (cartão): escala inteira
	else:
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		px = (34.0 if plate_px < 60.0 else big_px - 6.0)
	hero.add_child(icon)
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.offset_left = -px / 2.0
	icon.offset_right = px / 2.0
	icon.offset_top = -px / 2.0
	icon.offset_bottom = px / 2.0
	return hero


## Pílula creme com o texto por cima (n/m); verde se tem, vermelha se falta, marrom no neutro. Largura segue o texto.
static func _pill(text: String, tone: String, node_name: String = "") -> Control:
	var pill := Control.new()
	pill.name = node_name
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	pill.custom_minimum_size = Vector2(maxf(_text_w(text, TITLE_PX) + 28.0, 64.0), PILL_H)
	var art := SellUi.nine("pill", Vector4i(32, 43, 28, 43), "Art", null, "item_")
	pill.add_child(art)
	StepCardUi.stretch(art)
	var ink := Palette.WOOD_INK
	if tone == "have":
		ink = Palette.GO_INK
	elif tone == "missing":
		ink = Palette.ALERT_INK
	var label := StationWood.text(text, TITLE_PX, ink)
	label.name = "PillText"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_child(label)
	StepCardUi.stretch(label)
	return pill


# --- Painéis ----------------------------------------------------------------------------------

## Medidas de uma linha para a largura útil `width`. O texto vai ao lado do nome quando cabe em até 3 linhas; se for
## longo, passa para baixo, na largura toda da linha ("wide"), e a pilha de painéis rola.
static func _row_plan(row: Dictionary, width: float) -> Dictionary:
	var trailing := BTN_W if row.has("button") or bool(row.get("done", false)) else 0.0
	var body_w := width - ROW_PAD_X * 2.0 - ROW_PLATE - ROW_GAP - (ROW_GAP + trailing if trailing > 0.0 else 0.0)
	var title_m := _measure(str(row.title), TITLE_PX, body_w, 3)
	var text := str(row.get("text", ""))
	var text_m := _measure(text, TEXT_PX, body_w, 99)
	var wide := int(text_m.lines) > 3
	var text_w := body_w
	if wide:
		text_w = width - ROW_PAD_X * 2.0
		text_m = _measure(text, TEXT_PX, text_w, 99)
	var head := float(title_m.height)
	if not (row.get("pill", {}) as Dictionary).is_empty():
		head += 3.0 + PILL_H
	var content := head
	if int(text_m.lines) > 0 and not wide:
		content += 3.0 + float(text_m.height)
	var height := ROW_PAD_Y * 2.0 + maxf(ROW_PLATE, content)
	if wide:
		height += 4.0 + float(text_m.height)
	return {"height": height, "body_w": body_w, "title_m": title_m, "text_m": text_m, "wide": wide, "text_w": text_w}


## Altura natural do painel e das linhas (a pilha só rola por fora; os painéis têm sempre a largura toda).
static func _natural(rows: Array, cw: float) -> Dictionary:
	var row_w := cw - PANEL_SIDE * 2.0 - LIST_PAD * 2.0
	var row_plans: Array[Dictionary] = []
	var list_h := 0.0
	for row: Dictionary in rows:
		var plan := _row_plan(row, row_w)
		row_plans.append(plan)
		list_h += float(plan.height)
	list_h += maxf(0.0, rows.size() - 1.0) * DIVIDER
	return {"rows": row_plans, "row_w": row_w, "list_h": list_h, "height": PANEL_TOP + LIST_PAD * 2.0 + list_h + PANEL_BOTTOM}


## Medidas da pilha de painéis: se couber em `room`, nada rola; senão a pilha inteira rola por dentro de `room`.
static func _plan_stack(sections: Array[Dictionary], cw: float, room: float) -> Dictionary:
	var panels: Array[Dictionary] = []
	var stack := 0.0
	for section in sections:
		var natural := _natural(section.rows, cw)
		panels.append({"section": section, "natural": natural, "height": float(natural.height)})
		stack += float(natural.height)
	stack += maxf(0.0, panels.size() - 1.0) * GAP
	var shown := stack
	var scrolls := stack > room + 0.5
	if scrolls:
		shown = maxf(room, 120.0)
	return {"panels": panels, "stack": stack, "shown": shown, "scrolls": scrolls}


static func _stack(stack_plan: Dictionary, cw: float, model: Dictionary) -> Control:
	var column := UiKit.vbox(int(GAP))
	column.name = "HelpPanels"
	column.mouse_filter = Control.MOUSE_FILTER_PASS
	column.custom_minimum_size.x = cw
	for plan: Dictionary in stack_plan.panels:
		column.add_child(_panel(plan, cw))
	var scrolls := bool(stack_plan.scrolls)
	var area := SellUi.scrolled(column, cw + (GUTTER if scrolls else 0.0), float(stack_plan.shown), scrolls, model.get_or_add("stack_state", {"scroll": 0}), "HelpScroll", "HelpBar", GUTTER)
	area.name = "HelpArea"
	return area


static func _panel(plan: Dictionary, cw: float) -> Control:
	var section: Dictionary = plan.section
	var natural: Dictionary = plan.natural
	var height := float(plan.height)
	var panel := Control.new()
	panel.name = "HelpSection_" + str(section.name)
	panel.custom_minimum_size = Vector2(cw, height)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var art := SellUi.nine("panel", Vector4i(69, 150, 69, 88), "Art", null, "item_")
	panel.add_child(art)
	StepCardUi.stretch(art)
	var heading := MissionUi.text(str(section.title), 17, Palette.WOOD_CREAM, 3)
	heading.name = "PanelTitle"
	heading.clip_text = true
	panel.add_child(heading)
	SellUi.place(heading, 0.0, PANEL_SIDE, 1.0, -PANEL_SIDE, 0.0, 8.0, 0.0, 42.0)
	var row_w := float(natural.row_w)
	var list := UiKit.vbox(0)
	list.name = "HelpList"
	list.mouse_filter = Control.MOUSE_FILTER_PASS
	var rows: Array = section.rows
	for i in rows.size():
		if i > 0:
			list.add_child(_divider(row_w))
		var row := _row(rows[i], natural.rows[i], row_w)
		row.name = "HelpRow_" + str(i)
		list.add_child(row)
	panel.add_child(list)
	SellUi.place(list, 0.0, PANEL_SIDE + LIST_PAD, 0.0, PANEL_SIDE + LIST_PAD + row_w, 0.0, PANEL_TOP + LIST_PAD, 0.0, PANEL_TOP + LIST_PAD + float(natural.list_h))
	return panel


static func _divider(width: float) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(width, DIVIDER)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line := ColorRect.new()
	line.color = LINE_COLOR
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(line)
	StepCardUi.stretch(line)
	line.offset_left = 8.0
	line.offset_right = -8.0
	return holder


## Uma linha: pratinho, nome (+ pílula) e o botão Ir / medalhão à direita, tudo centrado na vertical; texto longo desce
## para a largura toda.
static func _row(row: Dictionary, plan: Dictionary, width: float) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(width, float(plan.height))
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	var column := UiKit.vbox(4)
	column.mouse_filter = Control.MOUSE_FILTER_PASS
	holder.add_child(column)
	StepCardUi.stretch(column)
	column.offset_left = ROW_PAD_X
	column.offset_right = -ROW_PAD_X
	column.offset_top = ROW_PAD_Y
	column.offset_bottom = -ROW_PAD_Y
	var wide := bool(plan.wide)
	var box := UiKit.hbox(int(ROW_GAP))
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL if not wide else Control.SIZE_SHRINK_BEGIN
	column.add_child(box)
	var plate := _plate(row.get("texture"), str(row.get("food", "")), ROW_PLATE, 32.0, "RowPlate")
	plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(plate)
	var body := UiKit.vbox(3)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var body_w := float(plan.body_w)
	body.add_child(_label(str(row.title), TITLE_PX, plan.title_m, body_w, "RowName"))
	var pill: Dictionary = row.get("pill", {})
	if not pill.is_empty():
		body.add_child(_pill(str(pill.text), str(pill.tone), "RowPill"))
	var text_name := str(row.get("text_name", "RowText"))
	if int((plan.text_m as Dictionary).lines) > 0 and not wide:
		body.add_child(_label(str(row.text), TEXT_PX, plan.text_m, body_w, text_name))
	box.add_child(body)
	if row.has("button"):
		var info: Dictionary = row.button
		var go := _go_button(str(info.caption), bool(info.green), info.fn)
		if str(info.name) != "":
			go.name = str(info.name)
		box.add_child(go)
	elif bool(row.get("done", false)):
		var slot := Control.new()
		slot.custom_minimum_size = Vector2(BTN_W, 40)
		slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var medal := StepCardUi.done_medal(40.0, "HelpDone")
		slot.add_child(medal)
		medal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		medal.offset_left = -20.0
		medal.offset_right = 20.0
		medal.offset_top = -20.0
		medal.offset_bottom = 20.0
		box.add_child(slot)
	if wide:
		column.add_child(_label(str(row.text), TEXT_PX, plan.text_m, float(plan.text_w), text_name))
	return holder


## Botão de madeira 72x44: verde (o único passo principal) ou amarelo calmo. O texto fica no próprio Button.
static func _go_button(caption: String, green: bool, on_pressed: Callable) -> Button:
	var button := BagUi.plain_button(on_pressed)
	button.custom_minimum_size = Vector2(BTN_W, BTN_H)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var art := SellUi.nine("btn_green" if green else "btn_gold", Vector4i(66, 66, 66, 66), "Art", null, "item_")
	art.show_behind_parent = true
	button.add_child(art)
	StepCardUi.stretch(art)
	button.text = caption
	button.clip_text = true
	button.theme = HomeUi.theme(18, Palette.WOOD_CREAM, GREEN_OUTLINE if green else Palette.WOOD_INK, 3)
	button.add_theme_constant_override("outline_size", 3)
	if green:
		button.set_meta("wood_primary", true)
	button.pressed.connect(func() -> void: Motion.bounce(button))
	return button
