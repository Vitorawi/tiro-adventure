class_name StationWood
extends RefCounted
## Peças da bandeja de estação no visual "madeira ilustrada" (fogão, liquidificador, bancada, criações, Natureza...):
## moldura de madeira com miolo creme, faixa bege dos espaços da fila, grade de cartões creme, caixas de ingredientes e
## resultado, e o rodapé numa tábua com o botão verde. As imagens ficam em `assets/sprites/ui/home/station_*.png` e
## `food_<item>.png` (geradas por `tools/station_art.gd`, ~3x o tamanho final): os NinePatch usam escala 1/3, então moram
## sempre num Control comum (`backing`), nunca direto num container. Estático: só monta; as regras ficam no `GameState`.

const SLOT := 46.0
const SLOT_GAP := 6.0
const TILE_PICTURE := 40.0
const HIT := 44.0
const INSET := Color("f3d3a8")  # fundo bege das caixas de ingrediente/resultado (casa com a bandeja)
const CARD_EDGE := Color("c9935f")


static func tex(file: String) -> Texture2D:
	return load(HomeUi.DIR + "station_" + file + ".png") as Texture2D


## Imagem estática ilustrada (suave) que não pega o toque.
static func pic(file: String, px: Vector2, node_name: String = "", fill: bool = false) -> TextureRect:
	var result := TextureRect.new()
	result.texture = tex(file)
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_SCALE if fill else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.custom_minimum_size = px
	if node_name != "":
		result.name = node_name
	return result


## Comida ilustrada do item (`food_<item>.png`), ou null se ainda só existe o ícone pixel.
static func food_texture(item: String) -> Texture2D:
	var path := HomeUi.DIR + "food_%s.png" % item
	return load(path) as Texture2D if item != "" and ResourceLoader.exists(path) else null


## Ícone do item: a comida ilustrada (suave) quando existe; senão o ícone pixel (nítido), centrado.
static func item_pic(item: String, fallback: Texture2D, px: float, node_name: String = "") -> TextureRect:
	var food := food_texture(item)
	var result := TextureRect.new()
	result.texture = food if food != null else fallback
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if food == null and fallback != null and fallback.get_width() <= int(px):
		result.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED  # pixel: tamanho original (sem escala torta)
	elif food == null and fallback != null:
		# Maior múltiplo inteiro (ou fração limpa) que cabe: evita o borrão de escala quebrada.
		pass
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS if food != null else CanvasItem.TEXTURE_FILTER_NEAREST
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.custom_minimum_size = Vector2(px, px)
	if node_name != "":
		result.name = node_name
	return result


## Fundo NinePatch (escala 1/3) que acompanha o tamanho do host. Num container ele ocupa tudo; num Button/Control
## o chamador ancora (`StepCardUi.stretch`). `drawn` = altura desenhada (0 = a do host); `behind` põe atrás do host.
static func backing(file: String, margin_x: int, margin_y: int, node_name: String = "Art", drawn: float = 0.0, behind: bool = false) -> Control:
	var art := Control.new()
	art.name = node_name
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.show_behind_parent = behind
	var frame := NinePatchRect.new()
	frame.texture = tex(file)
	frame.patch_margin_left = margin_x
	frame.patch_margin_right = margin_x
	frame.patch_margin_top = margin_y
	frame.patch_margin_bottom = margin_y
	frame.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.name = "Frame"
	frame.scale = Vector2.ONE / 3.0
	art.add_child(frame)
	var fit := func() -> void:
		if drawn > 0.0:
			frame.position = Vector2(0.0, (art.size.y - drawn) / 2.0)
			frame.size = Vector2(art.size.x, drawn) * 3.0
		else:
			frame.size = art.size * 3.0
	art.resized.connect(fit)
	return art


## Texto na fonte da madeira (marrom escuro sobre creme; creme com contorno sobre madeira).
static func text(value: String, px: int, color: Color = Palette.WOOD_INK, outline: int = 0) -> Label:
	if outline > 0:
		return MissionUi.text(value, px, color, outline, HORIZONTAL_ALIGNMENT_LEFT)
	return StepCardUi.wood(value, px, color)


## Botão sem fundo com uma imagem centrada (alvo ≥ 44, desenho `shown`).
static func icon_button(file: String, shown: Vector2, on_pressed: Callable, node_name: String, hit_width: float = HIT) -> Button:
	var result := BagUi.plain_button(on_pressed)
	result.name = node_name
	result.custom_minimum_size = Vector2(maxf(hit_width, shown.x), maxf(HIT, shown.y))
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	result.pressed.connect(func() -> void: Motion.bounce(result))
	var picture := pic(file, shown, "Picture")
	result.add_child(picture)
	picture.set_anchors_preset(Control.PRESET_CENTER)
	picture.offset_left = -shown.x / 2.0
	picture.offset_right = shown.x / 2.0
	picture.offset_top = -shown.y / 2.0
	picture.offset_bottom = shown.y / 2.0
	return result


## Botão de madeira retangular com rótulo creme (Tudo, Pegar tudo, Comprar animais). Alvo ≥ 44, desenho 38.
static func wood_button(caption: String, on_pressed: Callable, px: int = 16, min_width: float = 0.0) -> Button:
	var result := BagUi.plain_button(on_pressed)
	result.custom_minimum_size = Vector2(min_width, HIT)
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	result.pressed.connect(func() -> void: Motion.bounce(result))
	var art := backing("button", 42, 42, "Art", 38.0, true)
	result.add_child(art)
	StepCardUi.stretch(art)
	result.theme = HomeUi.theme(px, Palette.WOOD_CREAM, Palette.WOOD_INK, 3)
	result.text = caption
	result.clip_text = true
	return result


# --- Cabeçalho ----------------------------------------------------------------------------

## Cabeçalho: caixa de madeira com o ícone da estação, nome grande, selo de maestria, engrenagem (Ver tudo) e X.
## `options`: title, icon (Texture2D pixel), art ("stove" usa o fogão ilustrado), badge (Control), see_all (Callable).
static func heading(options: Dictionary, on_see_all: Callable, on_close: Callable) -> HBoxContainer:
	var row := UiKit.hbox(8)
	row.name = "TrayHeading"
	row.custom_minimum_size.y = 44.0
	var box := Control.new()
	box.name = "StationIcon"
	box.custom_minimum_size = Vector2(42, 44)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var illustrated := str(options.get("art", "")) == "stove"
	var frame := pic("stove" if illustrated else "box", Vector2(42, 44 if illustrated else 42), "Box")
	box.add_child(frame)
	if not illustrated and options.get("icon") is Texture2D:
		var icon := UiKit.icon(options.icon as Texture2D, 28)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.position = Vector2(7, 6)
		icon.size = Vector2(28, 28)
		box.add_child(icon)
	var spark := pic("sparkle", Vector2(16, 18), "Spark")
	spark.position = Vector2(31, -4)
	box.add_child(spark)
	row.add_child(box)
	var title_text := str(options.get("title", ""))
	var title := text(title_text, 24 if title_text.length() <= 11 else (20 if title_text.length() <= 14 else 17))
	title.name = "TrayTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	row.add_child(title)
	if options.get("badge") is Control:
		row.add_child(options.badge as Control)
	if on_see_all.is_valid():
		row.add_child(icon_button("gear", Vector2(38, 43), on_see_all, "SeeAll"))
	row.add_child(icon_button("x", Vector2(38, 43), on_close, "CloseTray"))
	return row


# --- Fila de espaços -----------------------------------------------------------------------

## Faixa bege que guarda a fileira de espaços (e o que mais o cabeçalho trouxer).
static func tray_strip(content: Control, node_name: String = "SlotTray", margin_x: int = 10) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel.add_child(backing("tray", 36, 36))
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left", margin_x)
	margin.add_theme_constant_override("margin_right", margin_x)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.add_child(content)
	panel.add_child(margin)
	return panel


## Fileira(s) de espaços de tamanho igual, distribuídos por igual na largura do sulco (até 5 por linha).
static func even_rows(cells: Array[Control], node_name: String = "Slots") -> Control:
	var column := UiKit.vbox(2)
	column.name = node_name
	column.mouse_filter = Control.MOUSE_FILTER_PASS
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var any_caption := false
	for cell in cells:
		any_caption = any_caption or bool(cell.get_meta("has_caption", false))
	if not any_caption:
		for cell in cells:
			var line := cell.get_node_or_null("Caption")
			if line != null:
				cell.remove_child(line)
				line.free()
	var per_row := 5 if cells.size() > 5 else maxi(1, cells.size())
	var row: HBoxContainer = null
	for i in cells.size():
		if i % per_row == 0:
			row = UiKit.hbox(10)
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.mouse_filter = Control.MOUSE_FILTER_PASS
			column.add_child(row)
		cells[i].size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		row.add_child(cells[i])
	return column


static func flow(separation: int = int(SLOT_GAP)) -> HFlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", separation)
	row.add_theme_constant_override("v_separation", 4)
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	return row


## Espaço de produção: quadradinho de madeira afundado com o produto, anel de tempo ou "+", e a legenda embaixo.
## Estados (os mesmos do `SlotDot`): "empty", "queued", "busy", "ready" e "buy" (fechado, abre a compra).
## Criações: "feed" (o animal está livre: a ração aparece apagada, "coloque aqui") e "shop" (lugar livre do abrigo:
## silhueta do animal com moeda e preço, sem cadeado — dá para comprar).
class Slot extends VBoxContainer:
	var state := "empty"
	var icon_rect: TextureRect
	var _dot: Control

	func _init(new_state: String = "empty", item: String = "", fallback: Texture2D = null, progress: float = 0.0, caption: String = "", caption_color: Color = Palette.WOOD_INK, coin: Texture2D = null) -> void:
		state = new_state
		mouse_filter = Control.MOUSE_FILTER_PASS
		add_theme_constant_override("separation", 1)
		custom_minimum_size.x = SLOT + 8.0
		_dot = Control.new()
		_dot.name = "Dot"
		_dot.custom_minimum_size = Vector2(SLOT, SLOT)
		_dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_dot)
		var art: TextureRect
		if state == "buy":
			art = TextureRect.new()
			art.texture = load(HomeUi.DIR + "farm_slot_lock.png") as Texture2D
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_SCALE
			art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		elif state == "ready":
			art = StationWood.pic("card_on", Vector2(SLOT, SLOT), "", true)
		else:
			art = StationWood.pic("slot", Vector2(SLOT, SLOT), "", true)
		art.name = "Art"
		art.size = Vector2(SLOT, SLOT)
		_dot.add_child(art)
		match state:
			"empty":
				var plus := StationWood.pic("add", Vector2(20, 20), "Add")
				plus.position = Vector2((SLOT - 20.0) / 2.0, (SLOT - 20.0) / 2.0 - 1.0)
				plus.size = Vector2(20, 20)
				_dot.add_child(plus)
			"queued":
				_add_icon(item, fallback, 0.55)
			"busy":
				var ring := RingProgress.new()
				ring.name = "Ring"
				ring.thickness = 2.0
				ring.color = Color("f59a23")
				ring.track = Color(0.3, 0.15, 0.05, 0.22)
				ring.custom_minimum_size = Vector2(SLOT - 14.0, SLOT - 14.0)
				ring.size = Vector2(SLOT - 14.0, SLOT - 14.0)
				ring.position = Vector2(7.0, 6.0)
				ring.progress = progress
				_dot.add_child(ring)
				_add_icon(item, fallback, 1.0)
			"ready":
				_add_icon(item, fallback, 1.0)
				var check := StationWood.pic("check", Vector2(14, 12), "Check")
				check.position = Vector2(SLOT - 22.0, 6.0)
				check.size = Vector2(14, 12)
				_dot.add_child(check)
			"feed":
				_add_icon(item, fallback, 0.4)
			"shop":
				_add_icon(item, fallback, 1.0)
				icon_rect.modulate = Color(0.32, 0.22, 0.14, 0.55)  # silhueta do animal que ainda não tem
				icon_rect.position = Vector2((SLOT - 22.0) / 2.0, 3.0)
				icon_rect.size = Vector2(22, 22)
				_add_price(caption, caption_color, coin)
			"buy":
				var lock := TextureRect.new()
				lock.name = "Lock"
				lock.texture = load(HomeUi.DIR + "farm_lock.png") as Texture2D
				lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				lock.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
				lock.position = Vector2((SLOT - 24.0) / 2.0, 2.0 if caption != "" else 11.0)
				lock.size = Vector2(24, 24)
				_dot.add_child(lock)
				if caption != "":
					_add_price(caption, caption_color, coin)  # o preço fica DENTRO do quadradinho, embaixo do cadeado
		var line := UiKit.hbox(2)
		line.name = "Caption"
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		line.custom_minimum_size = Vector2(0, 15)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if state not in ["buy", "shop"] and caption != "":
			line.add_child(StationWood.text(caption, 13, caption_color))
			set_meta("has_caption", true)
		add_child(line)

	func _add_price(caption: String, caption_color: Color, coin: Texture2D) -> void:
		var price := UiKit.hbox(1)
		price.name = "Price"
		price.alignment = BoxContainer.ALIGNMENT_CENTER
		price.mouse_filter = Control.MOUSE_FILTER_IGNORE
		price.position = Vector2(0, SLOT - 19.0)
		price.size = Vector2(SLOT, 16)
		if coin != null:
			var coin_icon := UiKit.icon(coin, 13)
			coin_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS if coin.get_width() > 48 else CanvasItem.TEXTURE_FILTER_NEAREST
			price.add_child(coin_icon)
		price.add_child(StationWood.text(caption, 13 if caption.length() <= 4 else 10, caption_color))  # "Ampliar" cabe no quadradinho
		_dot.add_child(price)

	func _add_icon(item: String, fallback: Texture2D, alpha: float) -> void:
		icon_rect = StationWood.item_pic(item, fallback, 30.0, "Icon")
		icon_rect.position = Vector2((SLOT - 30.0) / 2.0, (SLOT - 30.0) / 2.0 - (3.0 if state == "ready" else 1.0))
		icon_rect.size = Vector2(30, 30)
		icon_rect.modulate.a = alpha
		_dot.add_child(icon_rect)


## Espaço de uma vaga da fila (vazio, na fila, produzindo ou pronto).
static func queue_slot(entry: Dictionary, now: float) -> Slot:
	if entry.is_empty():
		return Slot.new("empty")
	var seconds := Database.entry_seconds(entry)
	var remaining := float(entry["ready_at"]) - now
	var output: String = Database.entry_output(entry)
	var icon := Database.item_icon(output)
	if remaining <= 0.0:
		return Slot.new("ready", output, icon, 1.0)
	if remaining > seconds:
		return Slot.new("queued", output, icon, 0.0, "Na fila")
	return Slot.new("busy", output, icon, 1.0 - remaining / seconds, TimeText.short(int(ceil(remaining))))


## Espaço ainda fechado: cadeado e o preço; tocar abre a compra da ampliação (a mesma ação do painel).
static func locked_slot(upgrade_id: String) -> Control:
	var data: Dictionary = Database.progression.upgrades[upgrade_id]
	var cost := int(data.get("cost", 0))
	var blocked := GameState.requirement_error(data.get("requirements", {})) != ""
	var price := ""
	if not blocked:
		price = "Grátis" if cost <= 0 else str(cost)
	var dot := Slot.new("buy", "", null, 0.0, price, Palette.WOOD_INK if GameState.coins >= cost else Palette.ALERT_INK, UiKit.ui_icon("coin") if price != "" and cost > 0 else null)
	dot.name = "LockedSlot_" + upgrade_id
	if blocked:
		dot.modulate.a = 0.8
	UiKit.on_tap(dot, func() -> void:
		Events.sheet_requested.emit(str(data.name), ProgressionUi.purchase(upgrade_id)))
	return dot


## Espaços da estação comum: um por vaga (`Slot_<i>`) e um bloqueado (`LockedSlot_<melhoria>`) por ampliação que ainda
## dá para comprar. Criação (`kind: "animal"`): um espaço por animal embaixo do retrato (`Herd`).
static func slot_row(station_id: String) -> Control:
	if str(Database.stations[station_id].get("kind", "")) == "animal":
		return herd_row(station_id)
	var target := GameState.station(station_id)
	var now := GameState.now()
	var cells: Array[Control] = []
	for i in GameState.station_slots(station_id):
		var dot := queue_slot(target.queue[i] if i < target.queue.size() else {}, now)
		dot.name = "Slot_%d" % i
		cells.append(dot)
	for upgrade_id: String in GameState.pending_slot_upgrades(station_id):
		cells.append(locked_slot(upgrade_id))
	return even_rows(cells)


## Uma coluna por animal (retrato + o espaço do lote dele: vazio, produzindo ou pronto; tocar num livre alimenta só
## ele), depois um "+ Comprar" com o preço para cada lugar que ainda cabe e, se houver, o espaço trancado "Ampliar".
static func herd_row(station_id: String) -> Control:
	var row := UiKit.hbox(8)
	row.name = "Herd"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var roster := GameState.animal_roster(station_id)
	var now := GameState.now()
	for i in roster.size():
		var column := UiKit.vbox(2)
		column.name = "Animal_%d" % i
		var portrait := UiKit.icon(load(Database.animals[roster[i]].sprite), 30)
		portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(portrait)
		var entry := GameState.animal_batch(station_id, i)
		var dot := queue_slot(entry, now) if not entry.is_empty() else Slot.new("feed", animal_feed_item(station_id), Database.item_icon(animal_feed_item(station_id)))
		dot.name = "Slot_%d" % i
		if entry.is_empty():
			var index := i
			UiKit.on_tap(dot, func() -> void: StationTray.feed_animal(station_id, index))
		column.add_child(dot)
		row.add_child(column)
	var free_places := GameState.animal_capacity(station_id) - roster.size()
	for j in free_places:
		var column := UiKit.vbox(2)
		column.name = "AnimalSpace_%d" % (roster.size() + j)
		var spacer := Control.new()  # no lugar do retrato, para os espaços ficarem na mesma linha
		spacer.custom_minimum_size = Vector2(30, 30)
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(spacer)
		var price := GameState.animal_next_price(station_id, j)
		var silhouette: Texture2D = load(Database.animals[roster[0] if not roster.is_empty() else _first_animal(station_id)].sprite)
		var buy := Slot.new("shop", "", silhouette, 0.0, str(price), Palette.WOOD_INK if GameState.coins >= price else Palette.ALERT_INK, UiKit.ui_icon("coin"))
		buy.name = "AnimalSpaceLocked_%d" % (roster.size() + j)
		UiKit.on_tap(buy, func() -> void: SheetBuilder.open_animal_shop(station_id))
		column.add_child(buy)
		row.add_child(column)
	for upgrade_id: String in GameState.animal_pending_expansions(station_id):
		var column := UiKit.vbox(2)
		column.name = "AnimalExpandColumn"
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(30, 30)
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(spacer)
		var expand := Slot.new("buy", "", null, 0.0, "Ampliar", Palette.WOOD_INK)
		expand.name = "AnimalExpand"
		expand.set_meta("upgrade", upgrade_id)
		var data: Dictionary = Database.progression.upgrades[upgrade_id]
		if GameState.requirement_error(data.get("requirements", {})) != "":
			expand.modulate.a = 0.8
		UiKit.on_tap(expand, func() -> void:
			Events.sheet_requested.emit(str(data.name), ProgressionUi.purchase(upgrade_id)))
		column.add_child(expand)
		row.add_child(column)
		break  # uma ampliação por vez
	return row


# --- Cercadinho das criações (uma ficha por animal / lugar livre / ampliação) -------------------

const PEN_CARD := Vector2(66, 100)
const PEN_PICTURE := Vector2(60, 56)


## Estado visível de um animal dentro da ficha (`Slot_<i>`): "feed" (livre), "busy" (produzindo) ou "ready" (pronto).
class AnimalState extends VBoxContainer:
	var state := "feed"


## Ficha de madeira do cercadinho: o `Visual` (coluna) recebe o desenho e o estado. Pronta = cartão amarelo.
static func pen_card(node_name: String, ready: bool, on_tap: Callable) -> Button:
	var result := BagUi.plain_button(on_tap)
	result.name = node_name
	result.custom_minimum_size = PEN_CARD
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var art := backing("card_on" if ready else "card", 60 if ready else 50, 60 if ready else 50, "Art", 0.0, true)
	result.add_child(art)
	StepCardUi.stretch(art)
	var body := UiKit.vbox(1)
	body.name = "Visual"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	result.add_child(body)
	StepCardUi.stretch(body)
	body.offset_top = 3.0
	body.offset_bottom = -10.0 if ready else -4.0
	return result


## Desenho do bicho na ficha: escala INTEIRA e nítida quando cabe na caixa; senão a menor redução suave.
static func pen_picture(texture: Texture2D, tint: Color = Color.WHITE) -> Control:
	var zone := CenterContainer.new()
	zone.name = "Figure"
	zone.custom_minimum_size = PEN_PICTURE
	zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var picture := TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.modulate = tint
	if texture != null:
		picture.texture = texture
		var size := Vector2(texture.get_size())
		var fit := minf(PEN_PICTURE.x / size.x, PEN_PICTURE.y / size.y)
		var factor := float(floori(fit)) if fit >= 1.0 else fit
		picture.custom_minimum_size = size * factor
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if fit >= 1.0 else CanvasItem.TEXTURE_FILTER_LINEAR
	zone.add_child(picture)
	return zone


## Parte de baixo da ficha do animal: livre ("Com fome"), produzindo (anel + tempo) ou pronto (produto ×N + ✓).
static func animal_state(state: String, item: String, icon: Texture2D, progress: float, caption: String) -> AnimalState:
	var result := AnimalState.new()
	result.state = state
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.alignment = BoxContainer.ALIGNMENT_CENTER
	result.add_theme_constant_override("separation", 1)
	result.custom_minimum_size = Vector2(PEN_CARD.x - 6.0, 34)
	match state:
		"busy":
			var holder := Control.new()
			holder.name = "RingHolder"
			holder.custom_minimum_size = Vector2(24, 24)
			holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var ring := RingProgress.new()
			ring.name = "Ring"
			ring.thickness = 2.0
			ring.color = Color("f59a23")
			ring.track = Color(0.3, 0.15, 0.05, 0.22)
			ring.custom_minimum_size = Vector2(24, 24)
			ring.size = Vector2(24, 24)
			ring.progress = progress
			holder.add_child(ring)
			var picture := item_pic(item, icon, 16.0, "Icon")
			picture.position = Vector2(4, 4)
			picture.size = Vector2(16, 16)
			holder.add_child(picture)
			result.add_child(holder)
		"ready":
			var picture := item_pic(item, icon, 20.0, "Icon")
			picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			result.add_child(picture)
		_:
			var picture := item_pic(item, icon, 20.0, "Icon")
			picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			picture.modulate.a = 0.4
			result.add_child(picture)
	var line := UiKit.hbox(3)
	line.name = "Caption"
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := text(caption, 11)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	line.add_child(label)
	if state == "ready":
		line.add_child(pic("check", Vector2(12, 11), "Check"))
	result.add_child(line)
	return result


## Linha pequena (moeda/ícone + texto) para a base das fichas de lugar livre e de ampliação.
static func pen_note(caption: String, color: Color = Palette.WOOD_INK, coin: Texture2D = null, px: int = 11) -> Control:
	var result := UiKit.hbox(2)
	result.alignment = BoxContainer.ALIGNMENT_CENTER
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if coin != null:
		var coin_icon := UiKit.icon(coin, 13)
		coin_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS if coin.get_width() > 48 else CanvasItem.TEXTURE_FILTER_NEAREST
		result.add_child(coin_icon)
	var label := text(caption, px, color)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	result.add_child(label)
	return result


## Cercadinho: uma ficha por animal (`Animal_<i>`, com o `Slot_<i>` dentro), uma por lugar livre
## (`AnimalSpaceLocked_<i>`, compra) e a da próxima ampliação (`AnimalExpand`). Até 4 por linha, sem rolagem lateral.
static func animal_pen(station_id: String, on_tap: Callable, on_buy: Callable) -> Control:
	var roster := GameState.animal_roster(station_id)
	var now := GameState.now()
	var feed_item := animal_feed_item(station_id)
	var cards: Array[Control] = []
	for i in roster.size():
		var entry := GameState.animal_batch(station_id, i)
		var is_ready := not entry.is_empty() and float(entry["ready_at"]) <= now
		var index := i
		var card := pen_card("Animal_%d" % i, is_ready, func() -> void: on_tap.call(index))
		var body := card.get_node("Visual") as Control
		body.add_child(pen_picture(load(Database.animals[roster[i]].sprite) as Texture2D))
		var slot: AnimalState
		if entry.is_empty():
			slot = animal_state("feed", feed_item, Database.item_icon(feed_item), 0.0, "Com fome")
		else:
			var output: String = Database.entry_output(entry)
			if is_ready:
				slot = animal_state("ready", output, Database.item_icon(output), 1.0, "×%d" % int(entry.get("qty", 1)))
			else:
				var seconds := Database.entry_seconds(entry)
				var left := float(entry["ready_at"]) - now
				slot = animal_state("busy", output, Database.item_icon(output), clampf(1.0 - left / maxf(seconds, 1.0), 0.0, 1.0), TimeText.short(int(ceil(left))))
		slot.name = "Slot_%d" % i
		body.add_child(slot)
		cards.append(card)
	var free_places := GameState.animal_capacity(station_id) - roster.size()
	var silhouette: Texture2D = load(Database.animals[roster[0] if not roster.is_empty() else _first_animal(station_id)].sprite) as Texture2D
	for j in free_places:
		var price := GameState.animal_next_price(station_id, j)
		var card := pen_card("AnimalSpaceLocked_%d" % (roster.size() + j), false, on_buy)
		card.modulate.a = 0.9
		var body := card.get_node("Visual") as Control
		body.add_child(pen_picture(silhouette, Color(0.32, 0.22, 0.14, 0.55)))
		var note := UiKit.vbox(0)
		note.mouse_filter = Control.MOUSE_FILTER_IGNORE
		note.alignment = BoxContainer.ALIGNMENT_CENTER
		note.custom_minimum_size = Vector2(PEN_CARD.x - 6.0, 34)
		note.add_child(pen_note(str(price), Palette.WOOD_INK if GameState.coins >= price else Palette.ALERT_INK, UiKit.ui_icon("coin"), 13))
		note.add_child(pen_note("Comprar"))
		body.add_child(note)
		cards.append(card)
	for upgrade_id: String in GameState.animal_pending_expansions(station_id):
		var data: Dictionary = Database.progression.upgrades[upgrade_id]
		var card := pen_card("AnimalExpand", false, func() -> void:
			Events.sheet_requested.emit(str(data.name), ProgressionUi.purchase(upgrade_id)))
		card.set_meta("upgrade", upgrade_id)
		if GameState.requirement_error(data.get("requirements", {})) != "":
			card.modulate.a = 0.8
		var body := card.get_node("Visual") as Control
		var lock := TextureRect.new()
		lock.name = "Lock"
		lock.texture = load(HomeUi.DIR + "farm_lock.png") as Texture2D
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock.custom_minimum_size = Vector2(34, 34)
		var lock_zone := CenterContainer.new()
		lock_zone.custom_minimum_size = PEN_PICTURE
		lock_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_zone.add_child(lock)
		body.add_child(lock_zone)
		var note := UiKit.vbox(0)
		note.mouse_filter = Control.MOUSE_FILTER_IGNORE
		note.alignment = BoxContainer.ALIGNMENT_CENTER
		note.custom_minimum_size = Vector2(PEN_CARD.x - 6.0, 34)
		note.add_child(pen_note("Ampliar", Palette.WOOD_INK, null, 12))
		note.add_child(pen_note("+%d lugares" % int(Database.stations[station_id].get("capacity_upgrades", {}).get(upgrade_id, 0))))
		body.add_child(note)
		cards.append(card)
		break  # uma ampliação por vez
	var grid := GridContainer.new()
	grid.name = "AnimalPen"
	grid.columns = clampi(cards.size(), 1, 4)
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	for card in cards:
		grid.add_child(card)
	return grid


## Ração do abrigo (o primeiro ingrediente da primeira receita dele): aparece apagada no espaço do animal livre.
static func animal_feed_item(station_id: String) -> String:
	for id: String in Database.recipes:
		var recipe: Dictionary = Database.recipes[id]
		if str(recipe.get("station", "")) == station_id:
			var inputs: Dictionary = recipe.get("week_inputs", recipe.get("inputs", {})) if GameState.farm_week_active() else recipe.get("inputs", {})
			for item: String in inputs:
				return item
	return ""


static func _first_animal(station_id: String) -> String:
	for id: String in Database.animals:
		if str(Database.animals[id].station) == station_id:
			return id
	return ""


## Faixa dos espaços da estação (nas criações, `slot_row` já traz os lugares a comprar e a ampliação).
static func station_strip(station_id: String) -> Control:
	return tray_strip(slot_row(station_id))


# --- Detalhe da receita --------------------------------------------------------------------

## Pílula de madeira com relógio e o tempo (cabeçalho do detalhe).
static func time_pill(value: String, node_name: String = "RecipeTime") -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.WOOD_INSET
	style.border_color = CARD_EDGE
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 8.0
	style.content_margin_right = 11.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	panel.add_theme_stylebox_override("panel", style)
	var row := UiKit.hbox(5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(pic("clock", Vector2(18, 18), "Clock"))
	row.add_child(text(value, 16))
	panel.add_child(row)
	return panel


## Caixa bege (ingredientes ou resultado) com folga.
static func inset_box(node_name: String, pad: Vector4 = Vector4(8, 4, 8, 4)) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = INSET
	style.border_color = CARD_EDGE
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = pad.x
	style.content_margin_top = pad.y
	style.content_margin_right = pad.z
	style.content_margin_bottom = pad.w
	panel.add_theme_stylebox_override("panel", style)
	return panel


## Cartãozinho creme de ingrediente: ícone, "tem/precisa" e ✓ verde quando tem; vermelho e tocável quando falta
## (abre o "Como fazer"). Sempre um Button, para o toque funcionar igual.
static func ingredient_card(item_id: String, need: int, small: bool = false) -> Button:
	var have := GameState.inventory.count(item_id)
	var ok := have >= need
	var result := BagUi.plain_button(TaskHelp.open.bind("item", item_id, need))
	result.name = "Ingredient_" + item_id
	result.custom_minimum_size = Vector2(50, 50) if small else Vector2(60, 56)
	var face := Panel.new()
	face.name = "Art"
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var face_style := StyleBoxFlat.new()
	face_style.bg_color = Color("fbe5c8")
	face_style.border_color = Color("6e3a1a")
	face_style.set_border_width_all(2)
	face_style.border_width_bottom = 3
	face_style.set_corner_radius_all(13)
	face.add_theme_stylebox_override("panel", face_style)
	face.show_behind_parent = true
	result.add_child(face)
	StepCardUi.stretch(face)
	var column := UiKit.vbox(0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	result.add_child(column)
	StepCardUi.stretch(column)
	var picture := item_pic(item_id, Database.item_icon(item_id), 24.0 if small else 30.0, "Picture")
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(picture)
	var count := text("%d/%d" % [have, need], 12 if small else 14, Palette.GO_INK if ok else Palette.ALERT_INK)
	count.name = "Count"
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(count)
	if ok:
		var check := pic("check", Vector2(16, 14), "Check")
		result.add_child(check)
		check.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		check.offset_left = -22.0
		check.offset_right = -6.0
		check.offset_top = 6.0
		check.offset_bottom = 20.0
	return result


## Caixa do resultado: efeitos da comida (ícone + "+N") ou, sem efeitos, o produto com "×N".
static func result_box(output: String, qty: int, collection: bool) -> Control:
	var box := inset_box("ResultBox", Vector4(10, 4, 10, 4))
	box.custom_minimum_size.x = 104.0
	var column := UiKit.vbox(3)
	column.name = "Effects"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(column)
	var feed: Dictionary = Database.items.get(output, {}).get("feed", {})
	if not collection and (qty > 1 or feed.is_empty()):
		var line := UiKit.hbox(5)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(item_pic(output, Database.item_icon(output), 28.0))
		line.add_child(text("×%d" % qty, 18))
		column.add_child(line)
	elif collection:
		var line := UiKit.hbox(5)
		line.add_child(item_pic(output, Database.item_icon(output), 28.0))
		line.add_child(text("×1", 18))
		column.add_child(line)
	for need_id: String in feed:
		var amount := int(feed[need_id])
		var line := UiKit.hbox(5)
		line.name = "Effect_" + need_id
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := UiKit.icon(Database.need_icon(need_id), 22)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		line.add_child(icon)
		line.add_child(text("%+d" % amount, 16, Palette.GO_INK if amount > 0 else Palette.ALERT_INK))
		column.add_child(line)
	return box


# --- Rodapé --------------------------------------------------------------------------------

## Tábua de madeira do rodapé; `content` (a coluna de ações) fica dentro, com folga.
static func board(content: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "Board"
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel.add_child(backing("board", 70, 60))
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.add_child(content)
	panel.add_child(margin)
	return panel


## Seletor de quantidade na tábua: − ×N + e "Tudo". Nós `Quantity`, `Minus`, `QuantityValue`, `Plus`, `QuantityMax`.
static func stepper(value: int, max_value: int, on_change: Callable) -> HBoxContainer:
	var row := UiKit.hbox(0)
	row.name = "Quantity"
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var minus := icon_button("minus", Vector2(36, 40), func() -> void: on_change.call(clampi(value - 1, 1, max_value)), "Minus")
	minus.disabled = value <= 1
	minus.modulate.a = 0.5 if minus.disabled else 1.0
	row.add_child(minus)
	var amount := text("×%d" % value, 19, Palette.WOOD_CREAM, 4)
	amount.name = "QuantityValue"
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount.custom_minimum_size.x = 26.0
	row.add_child(amount)
	var plus := icon_button("plus", Vector2(36, 40), func() -> void: on_change.call(clampi(value + 1, 1, max_value)), "Plus")
	plus.disabled = value >= max_value
	plus.modulate.a = 0.5 if plus.disabled else 1.0
	row.add_child(plus)
	var all := wood_button("Tudo", func() -> void: on_change.call(max_value), 15, 46.0)
	all.name = "QuantityMax"
	if value >= max_value:
		all.modulate.a = 0.5
		all.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(all)
	return row


## Aviso de bloqueio sobre a tábua: o mesmo botão bloqueado de madeira das demais telas (`StepCardUi.lock_note`, nó `LockHint`).
static func board_note(reason: String, on_help: Callable = Callable(), missing: Texture2D = null) -> HBoxContainer:
	return StepCardUi.lock_note(reason, on_help, missing)


## Barra de rolagem vertical de madeira (trilho bege, pegador marrom) para as rolagens da bandeja.
static func style_scrollbar(scroll: ScrollContainer) -> void:
	var bar := scroll.get_v_scroll_bar()
	var track := StyleBoxFlat.new()
	track.bg_color = Color("ecc79a")
	track.set_corner_radius_all(5)
	track.content_margin_left = 2.0
	track.content_margin_right = 2.0
	bar.add_theme_stylebox_override("scroll", track)
	for key: String in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var grabber := StyleBoxFlat.new()
		grabber.bg_color = Color("c8672f")
		grabber.border_color = Color("7a3a10")
		grabber.set_border_width_all(1)
		grabber.set_corner_radius_all(5)
		bar.add_theme_stylebox_override(key, grabber)
	bar.custom_minimum_size.x = 10.0


# --- Cartão da grade -----------------------------------------------------------------------

## Cartão da grade (modo pick): creme com a comida e o tempo; amarelo com brilhos quando escolhido; cadeado quando
## bloqueado; marquinha do ingrediente que falta. `entry`: icon, item (comida ilustrada), caption, clock, highlight, error.
## Nós preservados: `Visual/Picture`, `CaptionLabel`, `Missing`, `LockIcon`.
static func recipe_tile(entry: Dictionary, state: String, missing: Texture2D) -> Button:
	var result := BagUi.plain_button(func() -> void: pass)
	result.custom_minimum_size = Vector2(60, 72)
	var selected := state == "selected"
	var margin := 60 if selected else 50
	var art := backing("card_on" if selected else "card", margin, margin, "Art", 0.0, true)
	result.add_child(art)
	StepCardUi.stretch(art)
	var body := UiKit.vbox(1)
	body.name = "Visual"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	result.add_child(body)
	StepCardUi.stretch(body)
	body.offset_top = 2.0 if selected else 3.0
	body.offset_bottom = -11.0 if selected else -4.0  # o cartão amarelo tem a borda de baixo grossa e curva: o texto sobe
	var picture := item_pic(str(entry.get("item", "")), entry.get("icon") as Texture2D, TILE_PICTURE - (4.0 if selected else 0.0), "Picture")
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	picture.modulate.a = 0.45 if state == "missing" else (0.35 if state == "locked" else 1.0)
	if missing != null and state != "missing":
		picture.modulate.a = 0.45  # escolhida e faltando: ainda apagada
	body.add_child(picture)
	var caption := HBoxContainer.new()
	caption.name = "Caption"
	caption.alignment = BoxContainer.ALIGNMENT_CENTER
	caption.add_theme_constant_override("separation", 3)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.custom_minimum_size.y = 15.0
	if bool(entry.get("clock", false)):
		caption.add_child(pic("clock", Vector2(14, 14), "Clock"))
	var label := text(str(entry.get("caption", "")), 13)
	label.name = "CaptionLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Folga na largura medida: em telas maiores que 360 a fonte é rasterizada em outro tamanho e o fim do texto cortava.
	var font := label.get_theme_font("font")
	label.custom_minimum_size.x = ceilf(font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x) + 5.0
	caption.add_child(label)
	body.add_child(caption)
	if selected:
		var spark := pic("sparkle", Vector2(14, 15), "Spark")
		result.add_child(spark)
		spark.position = Vector2(2, 1)
	if str(entry.get("error", "")) != "":
		var lock := TextureRect.new()
		lock.name = "LockIcon"
		lock.texture = load(HomeUi.DIR + "farm_lock.png") as Texture2D
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock.custom_minimum_size = Vector2(24, 24)
		result.add_child(lock)
		lock.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		lock.offset_left = -27.0
		lock.offset_right = -3.0
		lock.offset_top = 3.0
		lock.offset_bottom = 27.0
	if bool(entry.get("highlight", false)) and not selected:
		var ring := Panel.new()
		ring.name = "Highlight"
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		style.border_color = Palette.GO
		style.set_border_width_all(3)
		style.set_corner_radius_all(14)
		ring.add_theme_stylebox_override("panel", style)
		result.add_child(ring)
		StepCardUi.stretch(ring)
	return result


## Espaço de coleta da Natureza (vazio, produzindo, pronto ou fechado: abre usando, com o nível na legenda).
static func nature_slot(site: String, index: int) -> Control:
	if index >= GameState.gathering_slots(site):
		var level := GameState.progress.nature_slot_level(site, index - 1) if index > 0 else 1
		return Slot.new("buy", "", null, 0.0, "Nível %d" % level)
	var entry := GameState.gathering_entry(site, index)
	if entry.is_empty():
		return Slot.new("empty")
	var remaining := GameState.gathering_remaining(site, index)
	var route: Dictionary = Database.progression.activities[str(entry.id)]
	var items: Dictionary = entry.get("rewards", route.rewards).get("items", {})
	var item := str(entry.get("resource", ""))
	if not items.has(item):
		item = str(items.keys()[0])
	var duration := maxf(1.0, float(entry.ready_at) - float(entry.started_at))
	var slot: Slot
	if remaining == 0:
		slot = Slot.new("ready", item, Database.item_icon(item), 1.0)
	else:
		slot = Slot.new("busy", item, Database.item_icon(item), 1.0 - remaining / duration, TimeText.short(remaining))
	slot.icon_rect.name = "GatherItem_%s_%d" % [site, index]
	return slot
