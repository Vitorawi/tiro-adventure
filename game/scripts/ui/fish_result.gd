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


## Tela "Pescaria concluída" = a página PremioPesca do Figma (guia 710×1536). Medidas em unidades do Figma (relativas ao
## canto do guia); `_s`/`_o` levam para a tela, ancorado embaixo como o minigame. O que varia: nome, ícones do peixe, textos e a
## marca vermelha da régua; o resto é imagem fixa.
const UI := "res://assets/sprites/ui/fishing_ui/"
const DESIGN := Vector2(710, 1536)
const R_CARD := Rect2(25, 430, 659, 818)
const R_NAME := Rect2(215, 650, 280, 29)
const R_HERO := Rect2(250, 728, 209, 164)
const R_SIZE_ICON := Rect2(198, 966, 30, 30)
const R_SIZE_TEXT := Rect2(233, 963, 86, 36)       ## centralizados no espaço do quadrado ao lado do ícone
const R_CLASS_TEXT := Rect2(404, 963, 95, 36)
const R_FISH_ICON := Rect2(185, 1026, 40, 31)
const R_QTY_TEXT := Rect2(233, 1024, 87, 36)
const R_XP_ICON := Rect2(383, 1026, 30, 30)
const R_XP_TEXT := Rect2(434, 1024, 61, 36)
const R_MARKER := Rect2(398, 872, 73, 73)         ## o x muda com o tamanho; o centro da marca cai sobre a régua
const RULER_X := Vector2(130, 579)                ## começo e fim da régua
const R_TAG := Rect2(130, 706, 450, 26)           ## "Primeira vez!" / "Novo recorde!" / "Perfeita!"
const R_CHEST := Rect2(130, 932, 450, 22)         ## linha do baú
const R_AGAIN := Rect2(319, 1095, 243, 87)        ## botão (toque); a imagem é o canvas de 243×93 centrado nele
const R_AGAIN_ART := Rect2(319, 1092, 243, 93)
const R_LEAVE := Rect2(143, 1094, 180, 87)
const R_LEAVE_ART := Rect2(143, 1094, 180, 87)
const R_CLOSE := Rect2(587, 526, 70, 70)          ## o X que já vem desenhado no container

var _s := 1.0
var _o := Vector2.ZERO


func _lr(rect: Rect2) -> Rect2:
	return Rect2(rect.position * _s + _o, rect.size * _s)


func _put(node: Control, rect: Rect2) -> Control:
	var r := _lr(rect)
	node.position = r.position
	node.size = r.size
	return node


func _picture(file: String, rect: Rect2, node_name: String) -> TextureRect:
	var picture := TextureRect.new()
	picture.name = node_name
	picture.texture = load(UI + file) as Texture2D
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_put(picture, rect)
	return picture


## Ícone do item dentro de um retângulo, sem distorcer.
func _icon(texture: Texture2D, rect: Rect2, node_name: String, crisp: bool) -> TextureRect:
	var picture := TextureRect.new()
	picture.name = node_name
	picture.texture = texture
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if crisp else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_put(picture, rect)
	return picture


func _text(value: String, rect: Rect2, node_name: String, fig_px: float, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var px := maxi(int(round(fig_px * _s)), 10)
	var label := StationWood.text(value, px)
	label.name = node_name
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_put(label, rect)
	while px > 8 and label.get_minimum_size().x > label.size.x:
		px -= 1
		label.add_theme_font_size_override("font_size", px)
	return label


## Botão transparente por cima da imagem; enquanto o dedo está nele a imagem troca pela do clicado (mesmo canvas).
func _art_button(node_name: String, art_file: String, art_rect: Rect2, hit: Rect2, on_press: Callable) -> Control:
	var holder := Control.new()
	holder.name = node_name + "Holder"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := _picture(art_file + ".png", art_rect, node_name + "Art")
	holder.add_child(art)
	var normal := art.texture
	var down := load(UI + art_file + "_down.png") as Texture2D
	var button := BagUi.plain_button(on_press)
	button.name = node_name
	button.button_down.connect(func() -> void:
		art.texture = down
		Haptics.tap())
	button.button_up.connect(func() -> void: art.texture = normal)
	_put(button, hit)
	holder.add_child(button)
	return holder


## `info` = {fish, cm, class, previous_cm, first, qty, xp, perfect, chest}.
func show_caught(info: Dictionary) -> void:
	close()
	var fish_id := str(info.fish)
	var cm := float(info.cm)
	var first := bool(info.get("first", false))
	var record := not first and cm > float(info.get("previous_cm", 0.0))
	var giant := str(info.get("class", "")) == "giant"
	var viewport := get_viewport().get_visible_rect().size
	_s = minf(viewport.x / DESIGN.x, viewport.y / DESIGN.y)
	_o = Vector2((viewport.x - DESIGN.x * _s) / 2.0, viewport.y - DESIGN.y * _s)
	var card := Control.new()
	card.name = "FishCard"
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.mouse_filter = Control.MOUSE_FILTER_STOP  # o mundo atrás não recebe toque
	_card = card
	add_child(card)
	card.add_child(_picture("fp_res_card.png", R_CARD, "FishCardArt"))
	card.add_child(_text(Database.item_name(fish_id), R_NAME, "FishName", 24.0, HORIZONTAL_ALIGNMENT_CENTER))
	var icon := Database.item_icon(fish_id)
	card.add_child(_icon(icon, R_HERO, "FishHero", true))
	var def: Dictionary = Database.fishing.fish.get(fish_id, {})
	var range_cm: Array = def.get("cm", [cm, cm])
	var fraction := clampf((cm - float(range_cm[0])) / maxf(1.0, float(range_cm[1]) - float(range_cm[0])), 0.0, 1.0)
	# régua: só a marca vermelha anda (o centro dela segue o tamanho)
	var ruler := Control.new()
	ruler.name = "FishRuler"
	ruler.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ruler.set_meta("fraction", fraction)
	card.add_child(ruler)
	var marker_rect := R_MARKER
	marker_rect.position.x = RULER_X.x + fraction * (RULER_X.y - RULER_X.x) - R_MARKER.size.x / 2.0
	ruler.add_child(_picture("fp_res_marker.png", marker_rect, "FishMarker"))
	card.add_child(_picture("fp_res_ruler.png", R_SIZE_ICON, "FishSizeIcon"))
	card.add_child(_text(cm_text(cm), R_SIZE_TEXT, "FishSize", 18.0, HORIZONTAL_ALIGNMENT_CENTER))
	card.add_child(_text(str(CLASS_NAMES.get(str(info.get("class", "")), "")), R_CLASS_TEXT, "FishClass", 18.0, HORIZONTAL_ALIGNMENT_CENTER))
	card.add_child(_icon(icon, R_FISH_ICON, "FishChip_" + fish_id, false))
	card.add_child(_text("×%d" % int(info.get("qty", 1)), R_QTY_TEXT, "FishQty", 18.0, HORIZONTAL_ALIGNMENT_CENTER))
	card.add_child(_picture("fp_res_trophy.png", R_XP_ICON, "FishXpIcon"))
	card.add_child(_text("+%d XP" % int(info.get("xp", 0)), R_XP_TEXT, "FishChip_xp", 18.0, HORIZONTAL_ALIGNMENT_CENTER))
	var tags: PackedStringArray = []
	if bool(info.get("perfect", false)):
		tags.append("Perfeita!")
	if first:
		tags.append("Primeira vez!")
	elif record:
		tags.append("Novo recorde!")
	if not tags.is_empty():
		var tag_name := "FishFirst" if first else ("FishRecord" if record else "FishPerfect")
		card.add_child(_text(" · ".join(tags), R_TAG, tag_name, 20.0, HORIZONTAL_ALIGNMENT_CENTER))
	var chest: Dictionary = info.get("chest", {})
	if not chest.is_empty():
		card.add_child(_chest_line(chest))
	card.add_child(_art_button("FishLeave", "fp_res_leave", R_LEAVE_ART, R_LEAVE, func() -> void: leave.emit()))
	card.add_child(_art_button("FishAgain", "fp_res_again", R_AGAIN_ART, R_AGAIN, func() -> void: again.emit()))
	var close_button := BagUi.plain_button(func() -> void: leave.emit())
	close_button.name = "FishClose"
	_put(close_button, R_CLOSE)
	card.add_child(close_button)
	if not Motion.reduced:
		card.modulate.a = 0.0
		create_tween().tween_property(card, "modulate:a", 1.0, 0.18)
	if giant:
		Haptics.big()
	else:
		Haptics.success()
	show()


## Baú: "Baú! +12 moedas · ×2 parafusos" numa linha só, centralizada abaixo da régua.
func _chest_line(chest: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.name = "FishChestChips"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_put(row, R_CHEST)
	var px := maxi(int(round(18.0 * _s)), 10)
	var title := StationWood.text("Baú!", px)
	title.name = "FishChest"
	row.add_child(title)
	if int(chest.get("coins", 0)) > 0:
		var coins := StationWood.text("+%d moedas" % int(chest.coins), px)
		coins.name = "FishChestChip_coins"
		row.add_child(coins)
	for item_id: String in chest.get("items", {}):
		if int(chest.items[item_id]) > 0:
			var line := StationWood.text("×%d %s" % [int(chest.items[item_id]), Database.item_name(item_id)], px)
			line.name = "FishChestChip_" + item_id
			row.add_child(line)
	return row


func _hero(fish_id: String) -> Control:
	var texture := Database.item_icon(fish_id)
	var picture := UiKit.icon(texture, 96)
	picture.name = "FishHero"
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return picture


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
