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


## Tipo escolhido (o primeiro se ainda não escolheu nenhum ou o id sumiu).
static func current_def() -> Dictionary:
	var def := type_def(type_id)
	if def.is_empty() and not dish_types().is_empty():
		def = dish_types()[0]
		type_id = str(def.id)
	return def


## Esvazia todas as escolhas (testes/capturas).
func reset_choices() -> void:
	chosen = {}
	type_id = ""
	refresh()


## Ingredientes escolhidos no tipo atual, um por espaço ("" = vazio).
static func slot_items() -> Array:
	var def := current_def()
	var id := str(def.get("id", ""))
	var count := (def.get("slots", []) as Array).size()
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


## "empty", "unknown" ou "known" (os ingredientes são exatamente os de uma receita do fogão liberada).
static func card_state() -> String:
	var items := multiset()
	if items.is_empty():
		return "empty"
	return "known" if GameState.invent_match(items) != "" else "unknown"


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
	if override.has(str(index)):
		return override[str(index)]
	if override.has(kind):
		return override[kind]
	return Database.invent.get("recommended", {}).get(kind, [])


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
	card.set_meta("on_tap", choose_type.bind(id))
	card.set_meta("hit_pad", Vector2(0, 6))
	return card


func _style_types() -> void:
	var current := str(current_def().get("id", ""))
	for id: String in _type_nodes:
		var card: Control = _type_nodes[id]
		var on := id == current
		card.set_meta("selected", on)
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
	type_id = id
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


# --- Cartão grande ----------------------------------------------------------------------

## Cartão grande: um só jeito de montar os três estados (fundo + ícone + título + dica + caixa + botão).
func _card() -> void:
	for child in _card_box.get_children():
		_card_box.remove_child(child)
		child.queue_free()
	var def := current_def()
	var state := card_state()
	_card_box.position = CARD_POS + Vector2(0, extra / 2.0)
	_card_box.set_meta("state", state)
	_card_box.name = "InvCard"
	var art := CookPanel.pic("inv_card_" + state, Vector2.ZERO, "Art")
	_card_box.add_child(art)
	var recipe_id := GameState.invent_match(multiset()) if state == "known" else ""
	var title_text := str(def.get("title", ""))
	var small := str(def.get("hint", ""))
	var long_text := str(def.get("hint_long", ""))
	var box_text := long_text
	match state:
		"empty":
			_card_box.add_child(CookPanel.pic("inv_ring_empty", Vector2(41, 66), "Ring"))
			small = "Toque em um espaço para colocar seus ingredientes"
			_card_box.add_child(CookPanel.pic("inv_box_info", Vector2(17, 176), "Box"))
		"unknown":
			title_text = "Prato desconhecido"
			_card_box.add_child(CookPanel.pic("inv_bowl_unknown", Vector2(31, 72), "Bowl"))
			_card_box.add_child(CookPanel.pic("inv_box_hint", Vector2(33, 195), "Box"))
		"known":
			var output := Database.recipe_output(Database.recipes[recipe_id])
			title_text = Database.item_name(output)
			_card_box.add_child(CookPanel.pic("inv_plate_known", Vector2(44, 67), "Plate"))
			_card_box.add_child(CookPanel.dish_pic(output, Rect2(59, 100, 90, 60), "Dish"))
			_card_box.add_child(CookPanel.pic("inv_box_known", Vector2(44, 185), "Box"))
			box_text = "Prato já conhecido!"
	var title := CookPanel.label(title_text, Rect2(174, 82, 287, 48), 40, 20, 1, INK, HORIZONTAL_ALIGNMENT_LEFT)
	title.name = "InvCardName"
	_card_box.add_child(title)
	var hint := CookPanel.label(small, Rect2(177, 148, 407, 19), 16, 10, 1, INK, HORIZONTAL_ALIGNMENT_LEFT)
	hint.name = "Hint"
	_card_box.add_child(hint)
	var box_y := 251.0 if state == "empty" else (233.0 if state == "unknown" else 219.0)
	var box_x := 133.0 if state == "empty" else (129.0 if state == "unknown" else 140.0)
	var body := CookPanel.label(box_text, Rect2(box_x, box_y, 420, 57), 20, 11, 2, INK, HORIZONTAL_ALIGNMENT_LEFT)
	body.name = "BoxText"
	_card_box.add_child(body)
	if state != "empty":
		var button := CookPanel.pic("inv_btn_together", Vector2(123, 297), "InvCookButton")
		CookPanel.tappable(button, cook_together)
		_card_box.add_child(button)


## "Cozinhar junto": prato conhecido = a receita de sempre (1 lote); desconhecido = prato surpresa provisório.
## Devolve "" ou o motivo (que também vira aviso). Depois de entrar na fila, os espaços do tipo esvaziam.
func cook_together() -> String:
	var items := multiset()
	if items.is_empty():
		return ""
	var recipe_id := GameState.invent_match(items)
	var failed := GameState.cook_many(recipe_id, 1) if recipe_id != "" else GameState.cook_invented(items)
	if failed != "":
		Events.toast_requested.emit(failed)
		var button := _card_box.get_node_or_null("InvCookButton") as CanvasItem
		if button != null:
			Motion.shake(button)
		return failed
	chosen[str(current_def().get("id", ""))] = []
	refresh()
	return ""


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
	var centers := slot_centers(kinds.size())
	for i in kinds.size():
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
	return key + "%d|%d" % [GameState.station("stove").queue.size(), GameState.station_slots("stove")]


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
