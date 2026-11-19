class_name CookInvent
extends Control
## Aba "Inventar" do painel do fogão (Figma FogaoInventar): tipos de prato que rolam, espaços de ingrediente do tipo, cartão
## grande (nada escolhido / prato desconhecido / prato conhecido) e o "Cozinhar junto". Tudo vem de `data/invent.json`
## (tipos de espaço, ingredientes, recomendados, tipos de prato): qualquer número de tipos, 1 a 4 espaços, qualquer quantidade
## de ingredientes. Monta no MESMO Control em unidades do Figma do `CookPanel` (coordenadas relativas ao quadro) e usa os
## auxiliares estáticos dele. A janelinha de ingredientes é o `CookInventPicker`.
##
## Cada tipo de cartão tem UMA função (`_type_card`, `_slot_card`, `_card`); estado só muda fundo/conteúdo, nunca a posição.
## Nós para teste: `InventView`, `InvType_<id>` (meta `selected`), `InvTypeArrow`, `InvSlot_<i>` (meta `item`, `kind`),
## `InvCard` (meta `state`), `InvCardName`, `InvCookButton`, `InvPicker` (ver CookInventPicker).

const TYPE_VIEW := Rect2(72, 240, 534, 130)
const TYPE_STEP := 139.0
const TYPE_TOP := 246.0
const TYPE_SIZE := Vector2(118, 118)
const SLOT_TOP := 389.0
const SLOT_CENTERS_3: Array[float] = [127.5, 352.5, 568.0]
const SLOT_FIRST := 127.5
const SLOT_LAST := 568.0
const CARD_POS := Vector2(31, 572)
const INK := CookPanel.INK

## Escolhas da sessão: id do tipo -> lista de ingredientes por espaço ("" = vazio). Cozinhar esvazia o tipo.
static var chosen: Dictionary = {}
static var type_id := ""

var extra := 0.0
var picker: CookInventPicker

var _types: CookScroll
var _type_nodes: Dictionary = {}
var _slots_box: Control
var _card_box: Control
var _signature_key := ""


func _init() -> void:
	name = "InventView"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(CookPanel.FIG_W, 1300)


func _ready() -> void:
	_build()


# --- Dados ------------------------------------------------------------------------------

static func dish_types() -> Array:
	return Database.invent.get("dish_types", [])


static func type_def(id: String) -> Dictionary:
	for def: Dictionary in dish_types():
		if str(def.id) == id:
			return def
	return {}


## Tipo escolhido (o primeiro aberto se ainda não escolheu nenhum, o id sumiu ou o tipo ainda não abriu no dia).
static func current_def() -> Dictionary:
	var def := type_def(type_id)
	if def.is_empty() or not type_open(str(def.id)):
		def = {}
		for candidate: Dictionary in dish_types():
			if type_open(str(candidate.id)):
				def = candidate
				break
		if def.is_empty() and not dish_types().is_empty():
			def = dish_types()[0]
		type_id = str(def.get("id", ""))
	return def


## O tipo já abriu no dia do jogo (`dishes.json → types.<tipo>.opens`).
static func type_open(id: String) -> bool:
	return GameState.dish_type_open(id)


## Esvazia todas as escolhas (testes/capturas).
func reset_choices() -> void:
	chosen = {}
	type_id = ""
	refresh()


## Quantos espaços a panela mostra no tipo atual: os do tipo, limitados pelo máximo do dia (a 3ª vaga da papinha abre no dia 3).
static func slot_total() -> int:
	var def := current_def()
	return DishRules.slot_count(str(def.get("id", "")), (def.get("slots", []) as Array).size(), GameState.week_day())


## Ingredientes escolhidos no tipo atual, um por espaço ("" = vazio).
static func slot_items() -> Array:
	var def := current_def()
	var id := str(def.get("id", ""))
	var count := slot_total()
	var list: Array = chosen.get(id, [])
	while list.size() < count:
		list.append("")
	if list.size() > count:
		list.resize(count)
	chosen[id] = list
	return list


## Multiconjunto {item: quantidade} do que está nos espaços.
static func multiset() -> Dictionary:
	var result := {}
	for item: String in slot_items():
		if item != "":
			result[item] = int(result.get(item, 0)) + 1
	return result


## Prévia ao vivo do que está na panela (`GameState.dish_preview`).
static func preview() -> Dictionary:
	var picks: Array = []
	for item: String in slot_items():
		if item != "":
			picks.append(item)
	return GameState.dish_preview(str(current_def().get("id", "")), picks)


## Estado do cartão grande: empty, incomplete, blocked, gororoba, new ou known.
static func card_state() -> String:
	return str(preview().state)


## Ingrediente já abriu no dia (a lista só mostra o que o jogador já conhece).
static func ingredient_open(item: String) -> bool:
	return DishRules.ingredient_of_item(item) in DishRules.available(GameState.week_day())


## Ingredientes que o jogador ainda pode pôr no espaço `slot` (o que tem menos o que já está nos outros espaços).
static func remaining(item: String, slot: int) -> int:
	var used := 0
	var list := slot_items()
	for j in list.size():
		if j != slot and list[j] == item:
			used += 1
	return GameState.inventory.count(item) - used


## Tipo do espaço `index` do tipo atual.
static func slot_kind(index: int) -> String:
	return str((current_def().get("slots", []) as Array)[index])


## Recomendados do espaço (o tipo de prato pode sobrescrever por posição ou por tipo de espaço).
static func recommended(index: int) -> Array:
	var def := current_def()
	var kind := slot_kind(index)
	var override: Dictionary = def.get("recommended", {})
	var list: Array = Database.invent.get("recommended", {}).get(kind, [])
	if override.has(str(index)):
		list = override[str(index)]
	elif override.has(kind):
		list = override[kind]
	return list.filter(func(item: Variant) -> bool: return ingredient_open(str(item)))


## Ingredientes que combinam com o espaço (free aceita todos).
static func fits(item: String, kind: String) -> bool:
	var kinds: Array = Database.invent.get("items", {}).get(item, [])
	return kind == "free" and not kinds.is_empty() or kind in kinds


# --- Montagem ---------------------------------------------------------------------------

static func _node(node_name: String, pos: Vector2, new_size: Vector2) -> Control:
	var node := Control.new()
	node.name = node_name
	node.position = pos
	node.size = new_size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


func _build() -> void:
	_types = CookScroll.new()
	_types.name = "InvTypes"
	_types.vertical = false
	_types.position = TYPE_VIEW.position
	_types.size = TYPE_VIEW.size
	_types.content.size = Vector2(TYPE_STEP * dish_types().size() + 3.5, TYPE_VIEW.size.y)
	add_child(_types)
	for i in dish_types().size():
		var def: Dictionary = dish_types()[i]
		var card := _type_card(def, i)
		_types.content.add_child(card)
		_type_nodes[str(def.id)] = card
	var arrow := CookPanel.pic("cat_arrow", Vector2(610, 287), "InvTypeArrow")
	CookPanel.widen(arrow, Vector4(8, 14, 6, 14), _scroll_types)
	add_child(arrow)
	_slots_box = _node("InvSlots", Vector2.ZERO, Vector2(CookPanel.FRAME_W, 600))
	add_child(_slots_box)
	_card_box = _node("InvCardBox", CARD_POS, Vector2(634, 459.33))
	add_child(_card_box)
	refresh()


## Cartão de tipo de prato (igual para todos): fundo escolhido/não, prato e nome; só o fundo troca.
func _type_card(def: Dictionary, index: int) -> Control:
	var id := str(def.id)
	var card := _node("InvType_" + id, Vector2(3.5 + TYPE_STEP * index, TYPE_TOP - TYPE_VIEW.position.y), TYPE_SIZE)
	card.add_child(CookPanel.pic("inv_type_off", Vector2.ZERO, "Art"))
	card.add_child(CookPanel.dish_pic(str(def.dish), Rect2(TYPE_SIZE.x / 2.0 - 37.0, 25, 74, 50), "Dish"))
	var title := CookPanel.label(str(def.name), Rect2(TYPE_SIZE.x / 2.0 - 54.0, 76, 108, 22), 14, 10, 1, INK, HORIZONTAL_ALIGNMENT_CENTER, CookPanel.fixed_size("invtype", dish_types().map(func(d: Dictionary) -> String: return str(d.name)), Vector2(108, 22), 14, 1))
	title.name = "Name"
	card.add_child(title)
	card.set_meta("selected", false)
	card.add_child(_lock_icon(Vector2(TYPE_SIZE.x - 30.0, 8.0)))
	card.set_meta("on_tap", choose_type.bind(id))
	card.set_meta("hit_pad", Vector2(0, 6))
	_apply_lock(card, id)
	return card


## Tipo fechado no dia: cartão apagado e cadeado; abre sozinho quando o dia chega.
static func _apply_lock(card: Control, id: String) -> void:
	var locked := not type_open(id)
	card.set_meta("locked", locked)
	for child in card.get_children():
		if child.name != "LockIcon":
			(child as CanvasItem).modulate.a = 0.55 if locked else 1.0
	(card.get_node("LockIcon") as CanvasItem).visible = locked


func _style_types() -> void:
	var current := str(current_def().get("id", ""))
	for id: String in _type_nodes:
		var card: Control = _type_nodes[id]
		var on := id == current
		card.set_meta("selected", on)
		_apply_lock(card, id)
		var art := card.get_node("Art") as TextureRect
		art.texture = CookPanel.tex("inv_type_on" if on else "inv_type_off")
		art.size = art.texture.get_size() / CookPanel.ART_SCALE
		art.position = Vector2((TYPE_SIZE.x - art.size.x) / 2.0, 0.0)


## A seta rola um tipo; no fim, volta ao começo.
func _scroll_types() -> void:
	if _types.offset >= _types.max_offset() - 1.0:
		_types.scroll_to(0.0)
	else:
		_types.scroll_to(minf(_types.offset + TYPE_STEP, _types.max_offset()))


func choose_type(id: String) -> void:
	if not type_open(id):
		Events.toast_requested.emit("%s abre no dia %d" % [str(type_def(id).get("name", "Esse prato")), DishRules.opens(id)])
		return
	type_id = id
	if WeekTutorial.enrolled() and not WeekTutorial.record("invent").get("done", false):
		GameState.week.tutorial.invent_type_chosen = true
		Events.week_tutorial_changed.emit()
	refresh()


## Posição x do centro de cada espaço: os três do Figma com 3; senão espalhados entre o primeiro e o último centro.
static func slot_centers(count: int) -> Array[float]:
	var result: Array[float] = []
	if count == 3:
		return SLOT_CENTERS_3.duplicate()
	if count == 1:
		result.append((SLOT_FIRST + SLOT_LAST) / 2.0)
		return result
	for i in count:
		result.append(SLOT_FIRST + (SLOT_LAST - SLOT_FIRST) * float(i) / float(maxi(count - 1, 1)))
	return result


## Espaço de ingrediente (um só jeito): arte do tipo; preenchido = frente dourada + figura por cima, no centro do corpo.
func _slot_card(index: int, kind: String, item: String, center_x: float) -> Control:
	var art_name := str(Database.invent.get("slot_kinds", {}).get(kind, {}).get("art", "ck_inv_slot_free")).trim_prefix("ck_")
	var art_size := CookPanel.tex(art_name).get_size() / CookPanel.ART_SCALE
	var card := _node("InvSlot_%d" % index, Vector2(center_x - art_size.x / 2.0, SLOT_TOP), art_size)
	card.add_child(CookPanel.pic(art_name, Vector2.ZERO, "Art"))
	if item != "":
		card.add_child(CookPanel.pic("inv_slot_filled", Vector2(art_size.x / 2.0 - 62.0, 57), "Filled"))
		# Janela interna creme da frente dourada (medida no PNG: x 10,67→114,67, y 6,67→89,33), com 6 unidades de folga.
		card.add_child(CookPanel.dish_pic(item, Rect2(art_size.x / 2.0 - 62.0 + 16.67, 57.0 + 12.67, 92.0, 70.67), "Figure"))
	card.set_meta("item", item)
	card.set_meta("kind", kind)
	CookPanel.tappable(card, open_picker.bind(index))
	return card


## Cadeado do tipo que ainda não abriu no dia (o mesmo desenho dos pratos trancados).
static func _lock_icon(pos: Vector2) -> TextureRect:
	var lock := TextureRect.new()
	lock.name = "LockIcon"
	lock.texture = load(HomeUi.DIR + "farm_lock.png") as Texture2D
	lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock.position = pos
	lock.size = Vector2(26, 26)
	return lock


## "Força 2 · Brilho 1" (só o que o prato rende; lanche e prato sem nutriente dizem a verdade em vez de zeros).
static func nutrient_text(values: Dictionary, meal: bool) -> String:
	var parts: PackedStringArray = []
	for key: String in DishRules.nutrient_ids():
		if int(values.get(key, 0)) > 0:
			parts.append("%s %d" % [str(Database.dishes.nutrients[key].name), int(values[key])])
	if parts.is_empty():
		return "Só enche a barriga"
	return ("" if meal else "Lanche · ") + " · ".join(parts)


# --- Cartão grande ----------------------------------------------------------------------

## Cartão grande: um só jeito de montar os estados (fundo + ícone + título + estrelas + dica + caixa + botão).
## `GameState.dish_preview` diz qual: empty, incomplete, blocked, gororoba, new ("Prato novo!") ou known.
func _card() -> void:
	for child in _card_box.get_children():
		_card_box.remove_child(child)
		child.queue_free()
	var def := current_def()
	var view := preview()
	var state := str(view.state)
	_card_box.position = CARD_POS + Vector2(0, extra / 2.0)
	_card_box.set_meta("state", state)
	_card_box.name = "InvCard"
	var art_state := "empty" if state == "empty" else ("unknown" if state in ["incomplete", "blocked"] else "known")
	_card_box.add_child(CookPanel.pic("inv_card_" + art_state, Vector2.ZERO, "Art"))
	var title_text := str(def.get("title", ""))
	var small := str(def.get("hint", ""))
	var line1 := str(def.get("hint_long", ""))
	var line2 := ""
	match state:
		"empty":
			_card_box.add_child(CookPanel.pic("inv_ring_empty", Vector2(41, 66), "Ring"))
			small = "Dá para inventar algo novo" if GameState.recipe_can_sniff() else "Toque em um espaço para colocar seus ingredientes"
			_card_box.add_child(CookPanel.pic("inv_box_info", Vector2(17, 176), "Box"))
		"incomplete", "blocked":
			title_text = "Falta pouco" if state == "incomplete" else "Ainda não dá"
			small = str(view.reason)
			_card_box.add_child(CookPanel.pic("inv_bowl_unknown", Vector2(31, 72), "Bowl"))
			_card_box.add_child(CookPanel.pic("inv_box_hint", Vector2(33, 195), "Box"))
		_:
			title_text = str(view.name)
			_card_box.add_child(CookPanel.pic("inv_plate_known", Vector2(44, 67), "Plate"))
			_card_box.add_child(CookPanel.dish_pic(str(view.output), Rect2(59, 100, 90, 60), "Dish"))
			_card_box.add_child(CookPanel.pic("inv_box_known", Vector2(44, 185), "Box"))
			if state == "gororoba":
				small = str(view.reason)
				line1 = "Só enche a barriga: não conta como prato novo."
				for item: String in view.refund:
					line2 = "Devolve %s" % Database.item_name(item)
			else:
				if bool(GameState.chef_info().get("exact_preview", false)):
					small = nutrient_text(view.nutrients, bool(view.meal))
				else:
					var top: Array[String] = []
					for id: String in DishRules.nutrient_ids():
						if int(view.nutrients.get(id, 0)) > 0:
							top.append(str(Database.dishes.nutrients[id].name))
					small = " · ".join(top) if not top.is_empty() else "Lanche"
				line1 = "Prato novo!" if state == "new" else "Prato já conhecido!"
				line2 = str(view.notes[0]) if not (view.notes as Array).is_empty() else ("Refeição" if bool(view.meal) else "Lanche: alegra, mas não é refeição")
				_card_box.add_child(CookPanel.stars_pic(int(view.stars), Vector2(202, 137), false, "InvStars"))
	var title := CookPanel.label(title_text, Rect2(174, 82, 287, 46), 40, 18, 1, INK, HORIZONTAL_ALIGNMENT_LEFT)
	title.name = "InvCardName"
	_card_box.add_child(title)
	var hint := CookPanel.label(small, Rect2(177, 148, 407, 19), 16, 10, 1, INK, HORIZONTAL_ALIGNMENT_LEFT)
	hint.name = "Hint"
	_card_box.add_child(hint)
	var box_y := 251.0 if state == "empty" else (233.0 if art_state == "unknown" else 219.0)
	var box_x := 133.0 if state == "empty" else (129.0 if art_state == "unknown" else 140.0)
	var two := line2 != ""
	var body := CookPanel.label(line1, Rect2(box_x, box_y, 420, 28 if two else 57), 20, 11, 1 if two else 2, CookPanel.ORANGE.darkened(0.35) if state == "new" else INK, HORIZONTAL_ALIGNMENT_LEFT)
	body.name = "BoxText"
	_card_box.add_child(body)
	if two:
		var extra_line := CookPanel.label(line2, Rect2(box_x, box_y + 28.0, 420, 26), 17, 10, 1, INK, HORIZONTAL_ALIGNMENT_LEFT)
		extra_line.name = "BoxNote"
		_card_box.add_child(extra_line)
	if state != "empty":
		var button := CookPanel.pic("inv_btn_together", Vector2(123, 297), "InvCookButton")
		button.modulate.a = 0.6 if state in ["incomplete", "blocked"] else 1.0
		CookPanel.tappable(button, cook_together)
		_card_box.add_child(button)


## "Cozinhar junto": abre o minigame (Picar, Mexer e Servir) com o prato da panela; os ingredientes só saem no fim dele
## e os espaços esvaziam quando o prato entra na fila. Gororoba não tem minigame: cozinha direto (devolve o ingrediente).
## Devolve "" ou o motivo (que também vira aviso).
func cook_together() -> String:
	var items := multiset()
	if items.is_empty():
		return ""
	var type := str(current_def().get("id", ""))
	var view := preview()
	var failed := GameState.cook_invented_error(items, type)
	if failed == "" and str(view.state) != "gororoba":
		var picks: Array[String] = []
		for item: String in slot_items():
			if item != "":
				picks.append(item)
		var chosen_now := items.duplicate()
		var spec := {"name": str(view.name), "output": str(view.output), "items": picks,
			"check": func() -> String: return GameState.cook_invented_error(chosen_now, type),
			"cook": func(stars: int, together: bool) -> String: return GameState.cook_invented(chosen_now, type, stars, together),
			"on_done": _cooked.bind(type),
			"mastery_key": str(view.mastery_key)}
		var panel := CookPanel.current()
		if panel != null:
			panel.start_together(spec)  # se não abrir, o motivo já virou aviso
			return ""
	if failed == "":
		failed = GameState.cook_invented(items, type)
	if failed != "":
		Events.toast_requested.emit(failed)
		var button := _card_box.get_node_or_null("InvCookButton") as CanvasItem
		if button != null:
			Motion.shake(button)
		return failed
	_cooked(type)
	return ""


## Depois de cozinhar: os espaços do tipo esvaziam.
func _cooked(type: String) -> void:
	chosen[type] = []
	refresh()


# --- Janelinha de ingredientes ----------------------------------------------------------

func open_picker(index: int) -> void:
	close_picker()
	picker = CookInventPicker.new(self, index)
	add_child(picker)


func close_picker() -> void:
	if is_instance_valid(picker):
		picker.close()
	picker = null


func picker_open() -> bool:
	return is_instance_valid(picker) and not picker.is_queued_for_deletion()


## Põe (ou, com "", tira) o ingrediente do espaço.
func set_slot(index: int, item: String) -> void:
	var list := slot_items()
	if index >= 0 and index < list.size():
		list[index] = item
	refresh()


# --- Atualização ------------------------------------------------------------------------

## Refaz espaços e cartão (e a janelinha, se aberta) para o estado de agora.
func refresh() -> void:
	if _slots_box == null:
		return
	_style_types()
	for child in _slots_box.get_children():
		_slots_box.remove_child(child)
		child.queue_free()
	var def := current_def()
	var kinds: Array = def.get("slots", [])
	var items := slot_items()
	var total := items.size()
	var centers := slot_centers(total)
	for i in total:
		_slots_box.add_child(_slot_card(i, str(kinds[i]), str(items[i]), centers[i]))
	_card()
	_signature_key = _signature()
	if picker_open():
		picker.refresh()


## Assinatura do que muda a tela sem mudar a escolha: o que tem de cada ingrediente e a escolha do tipo.
func _signature() -> String:
	var key := str(current_def().get("id", "")) + "|" + ",".join(PackedStringArray(slot_items())) + "|"
	for item: String in Database.invent.get("items", {}):
		key += "%d," % GameState.inventory.count(item)
	return key + "%d|%d|%d|%d" % [GameState.station("stove").queue.size(), GameState.station_slots("stove"), GameState.week_day(), GameState.week.dishes.size()]


## Chamado a cada `state_changed`: só refaz se algo mudou.
func on_state_changed() -> void:
	if _signature() != _signature_key:
		refresh()


func set_extra(value: float) -> void:
	if is_equal_approx(extra, value):
		return
	extra = value
	if _card_box != null:
		_card_box.position = CARD_POS + Vector2(0, extra / 2.0)
	if picker_open():
		picker.set_extra(extra)
