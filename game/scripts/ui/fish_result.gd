class_name FishResult
extends CanvasLayer
## Cartões de resultado da pesca (etapa 02): "Pegou!" (folha de madeira; o Gigante usa o cartão grande com confete e
## vibração forte) e "Geladeira cheia". Os botões só emitem sinais; quem decide o que vem depois é o `FishingFlow`.
## Nós: `FishSize` (cm), `FishClass` (selo), `FishRecord` ("Novo recorde!"), `FishFirst` ("Primeira vez!"), `FishRuler`,
## `FishAgain` (verde), `FishLeave` (amarelo); geladeira cheia: `Locked_Fridge`, `FishFreeSpace`, `FishRelease`.

signal again
signal leave
signal free_space
signal release

const CLASS_NAMES := {"small": "Pequeno", "medium": "Médio", "large": "Grande", "giant": "Gigante"}

var _card: Control


func _ready() -> void:
	layer = 24
	name = "FishResult"
	hide()


static func cm_text(cm: float) -> String:
	return ("%s cm" % str(snappedf(cm, 0.5))).replace(".", ",")


func is_showing() -> bool:
	return visible and _card != null and is_instance_valid(_card)


## `info` = {fish, cm, class, previous_cm, first, qty, xp, perfect}.
func show_caught(info: Dictionary) -> void:
	var fish_id := str(info.fish)
	var cm := float(info.cm)
	var giant := str(info.get("class", "")) == "giant"
	var first := bool(info.get("first", false))
	var record := not first and cm > float(info.get("previous_cm", 0.0))
	var hero := _hero(fish_id)
	var title := Database.item_name(fish_id)
	if giant:
		var card := ModalCard.open(self, {"title": title if not bool(info.get("perfect", false)) else "Perfeita!", "hero": hero, "confetti": true, "haptic": "big", "scroll_name": "FishScroll"})
		_card = card
		_fill(card, info, record, first)
		card.add_primary("Pescar de novo", func() -> void: again.emit()).name = "FishAgain"
		card.add_ghost("Sair", func() -> void: leave.emit()).name = "FishLeave"
	else:
		var sheet := RewardSheet.open(self, {"title": title, "hero": hero, "on_close": func() -> void: leave.emit(), "scroll_name": "FishScroll", "haptic": "success"})
		_card = sheet
		_fill(sheet, info, record, first)
		var actions := sheet.add_actions("Sair", func() -> void: leave.emit(), "Pescar de novo", func() -> void: again.emit())
		(actions.soft as Button).name = "FishLeave"
		(actions.primary as Button).name = "FishAgain"
		sheet.present()
	show()


func _hero(fish_id: String) -> Control:
	var texture := Database.item_icon(fish_id)
	var picture := UiKit.icon(texture, 96)
	picture.name = "FishHero"
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return picture


## Régua, selo da classe, recorde/primeira vez e chips (peixes ×N, XP).
func _fill(target: Object, info: Dictionary, record: bool, first: bool) -> void:
	var fish_id := str(info.fish)
	var cm := float(info.cm)
	var def: Dictionary = Database.fishing.fish.get(fish_id, {})
	var range_cm: Array = def.get("cm", [cm, cm])
	var ruler := Ruler.new()
	ruler.name = "FishRuler"
	ruler.fraction = clampf((cm - float(range_cm[0])) / maxf(1.0, float(range_cm[1]) - float(range_cm[0])), 0.0, 1.0)
	target.call("add", ruler)
	var line := UiKit.flow(8)
	line.alignment = FlowContainer.ALIGNMENT_CENTER
	line.add_child(StepCardUi.wood_chip(null, cm_text(cm), "", Callable(), "FishSize"))
	line.add_child(StepCardUi.wood_chip(null, str(CLASS_NAMES.get(str(info.get("class", "")), "")), "have", Callable(), "FishClass"))
	target.call("add", line)
	if first:
		target.call("add", _tag("Primeira vez!", "FishFirst"))
	elif record:
		target.call("add", _tag("Novo recorde!", "FishRecord"))
	var chips := UiKit.flow(8)
	chips.name = "FishChips"
	chips.alignment = FlowContainer.ALIGNMENT_CENTER
	chips.add_child(StepCardUi.wood_chip(Database.item_icon(fish_id), "×%d" % int(info.get("qty", 1)), "", Callable(), "FishChip_" + fish_id))
	if int(info.get("xp", 0)) > 0:
		chips.add_child(StepCardUi.wood_chip(UiKit.ui_icon("xp"), "+%d" % int(info.xp), "", Callable(), "FishChip_xp"))
	target.call("add", chips)


func _tag(text: String, node_name: String) -> Control:
	var label := StationWood.text(text, 20, Palette.WOOD_INK)
	label.name = node_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


## Geladeira cheia: o peixe espera; liberar espaço ou soltar o peixe.
func show_full(fish_id: String) -> void:
	var sheet := RewardSheet.open(self, {"title": "Geladeira cheia", "hero": _hero(fish_id), "on_close": func() -> void: leave.emit(), "scroll_name": "FishScroll", "haptic": ""})
	_card = sheet
	sheet.add_text(Database.item_name(fish_id) + " espera na linha", &"StrongLabel")
	var locked := StepCardUi.locked_button("Geladeira cheia", Database.item_icon(fish_id))
	locked.name = "Locked_Fridge"
	sheet.add(locked)
	var actions := sheet.add_actions("Soltar o peixe", func() -> void: release.emit(), "Liberar espaço", func() -> void: free_space.emit())
	(actions.soft as Button).name = "FishRelease"
	(actions.primary as Button).name = "FishFreeSpace"
	sheet.present()
	show()


func close() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_card = null
	hide()


## Régua de madeira com a marca do tamanho (de pequeno a grande da espécie).
class Ruler extends Control:
	var fraction := 0.5

	func _init() -> void:
		custom_minimum_size = Vector2(0, 26)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_horizontal = Control.SIZE_EXPAND_FILL

	func _draw() -> void:
		var bar := Rect2(4, 10, size.x - 8, 8)
		draw_rect(bar, Palette.WOOD_INSET)
		draw_rect(bar, Color("c9935f"), false, 1.5)
		for i in 11:
			var x := bar.position.x + bar.size.x * (float(i) / 10.0)
			draw_line(Vector2(x, 18), Vector2(x, 18 + (6 if i % 5 == 0 else 3)), Palette.WOOD_INK, 1.5)
		var mark := bar.position.x + bar.size.x * fraction
		draw_colored_polygon(PackedVector2Array([Vector2(mark - 6, 0), Vector2(mark + 6, 0), Vector2(mark, 10)]), Palette.ALERT)
