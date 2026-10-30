class_name PetCareTray
extends Control
## Faixa permanente de cuidados. Gestos nunca alteram estado antes de validar o alvo.

const FOOD_COLUMNS := 3
const FOOD_TILE := 56.0
const FOOD_GAP := 6.0
const FOOD_ROWS := 4  # linhas visíveis; o resto rola
const SCRUB_STEP := 260.0
const SCRUB_TOTAL := 800.0
const THROW_SPEED := -180.0
const BRUSH_STEP := 200.0
const BRUSH_TOTAL := 600.0
var pet_screen: Control
var gesture := DragGhost.new()
var _row: Control
var _play_hint: Label
var _scroll: ScrollContainer
var _foods: GridContainer
var _food_button: Button
var _menu: PanelContainer
static var recent_foods: Array[String] = []
var _sleep: Button
var _items: Dictionary = {}
var _food_ids: Array[String] = []
var _pressed := ""
var _dragging := false
var _distance := 0.0
var _bubbles_at := 0.0
var _acted := false
var _scrolling := false
var _foods_ready := false
var _food_phase := ""
var _care_button: Button
var _ask: Button
var _ask_icon: TextureRect
var _pointer: Polygon2D
var _pointed_item := ""

const HEART_SIZE := Vector2(64, 62)
const WHEEL_RADIUS := 190.0
## Lado do cartão ilustrado de cada cuidado na roleta.
const WHEEL_CARD := 66.0
## Cartão de cada cuidado (IUREF/roleta; o Escovar usa o cartão vazio com o ícone por cima).
const WHEEL_CARDS := {"FoodButton": "food", "Care_sponge": "bath", "BrushTile": "blank", "Care_ball": "play", "SleepButton": "sleep"}
## Faixa de madeira atrás dos cartões: contorno, madeira e o filete claro do meio.
const BAND_WIDTH := 84.0
const WOOD_EDGE := Color("6b3a1c")
const WOOD_BAND := Color("c98b4e")
const WOOD_LIGHT := Color("e3ac6c")


func _ready() -> void:
	name = "CareTray"
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_row = Control.new()
	_row.name = "CareWheelOpen"
	_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_row.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_row)
	_row.draw.connect(_draw_wheel)
	_row.gui_input.connect(_on_veil_input)
	_row.hide()
	_care_button = UiKit.care_disc(UiKit.ui_icon("heart"), "Cuidar", _toggle_wheel, 72, true)
	_care_button.name = "CareButton"
	_care_button.custom_minimum_size = Vector2(72, 72)
	_care_button.size = Vector2(72, 72)
	_care_button.z_index = 2
	add_child(_care_button)
	_care_button.custom_minimum_size = HEART_SIZE
	_care_button.size = HEART_SIZE
	_build_care_art()
	var picture := _care_button.find_child("CareIcon", true, false) as TextureRect
	picture.custom_minimum_size = Vector2(42, 42)
	_ask = UiKit.icon_button(null, _asked_care, 44)
	_ask.name = "CareAsk"
	_ask.size = Vector2(44, 44)
	for phase: String in ["normal", "hover", "pressed", "focus"]:
		_ask.add_theme_stylebox_override(phase, StyleBoxEmpty.new())
	var ask_disc := Panel.new()
	ask_disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ask_disc.position = Vector2(7, 7)
	ask_disc.size = Vector2(30, 30)
	var ask_style := UiKit.surface(Palette.ALERT_SOFT, 15)
	ask_style.border_color = Palette.CARD
	ask_style.set_border_width_all(2)
	ask_disc.add_theme_stylebox_override("panel", ask_style)
	ask_disc.visible = false  # o selinho de madeira do coração faz o papel do disco
	_ask.add_child(ask_disc)
	_ask_icon = UiKit.icon(null, 16)
	_ask_icon.name = "CareAskIcon"
	_ask_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ask_icon.position = Vector2(14, 14)
	_ask.add_child(_ask_icon)
	_care_button.add_child(_ask)
	_ask.position = Vector2(36, -16)  # centro no centro do selinho (58, 6)
	_play_hint = UiKit.label("", &"SmallLabel")
	_play_hint.name = "PlayGrowthTimer"
	_play_hint.hide()
	add_child(_play_hint)
	_food_button = UiKit.care_disc(Database.item_icon("dog_food"), "Comida", open_food_menu)
	_food_button.name = "FoodButton"
	_row.add_child(_food_button)
	_wheel_card(_food_button)
	_menu = PanelContainer.new()
	_menu.name = "FoodMenu"
	# Moldura de madeira com miolo creme (a mesma do mini-cartão do próximo passo); o conteúdo é uma grade de quadradinhos.
	_menu.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_menu.z_index = 4
	_menu.hide()
	pet_screen.add_child(_menu)
	_menu.minimum_size_changed.connect(func() -> void: _place_menu.call_deferred())
	var art := Control.new()
	art.name = "Art"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu.add_child(art)
	var frame := StepCardUi.patch("frame", 42, 42)
	frame.name = "Frame"
	frame.scale = Vector2.ONE / 3.0
	art.add_child(frame)
	art.resized.connect(func() -> void:
		frame.position = Vector2.ZERO
		frame.size = art.size.max(Vector2.ONE) * 3.0)
	var body := MarginContainer.new()
	body.name = "Body"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right"]:
		body.add_theme_constant_override("margin_" + side, 20)
	body.add_theme_constant_override("margin_top", 14)
	body.add_theme_constant_override("margin_bottom", 14)
	_menu.add_child(body)
	var column := UiKit.vbox(4)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(column)
	# Sem título, X nem setas: fecha tocando fora ou no botão Comida.
	_scroll = ScrollContainer.new()
	_scroll.name = "FoodScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER  # sem barra: ela deslocaria a grade
	column.add_child(_scroll)
	_foods = GridContainer.new()
	_foods.columns = FOOD_COLUMNS
	_foods.add_theme_constant_override("h_separation", 8)
	_foods.add_theme_constant_override("v_separation", 8)
	_foods.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_scroll.add_child(_foods)
	for entry: Array in [["sponge", "action_sponge", "Banho"], ["ball", "action_play", "Brincar"]]:
		var item := UiKit.care_disc(UiKit.ui_icon(entry[1]), entry[2], func() -> void: pass)
		item.name = "Care_" + str(entry[0])
		item.mouse_filter = Control.MOUSE_FILTER_STOP
		item.gui_input.connect(_on_item_input.bind(str(entry[0])))
		_items[entry[0]] = item
		_row.add_child(item)
		_wheel_card(item)
	_sleep = UiKit.care_disc(UiKit.ui_icon("action_sleep"), "Dormir", func() -> void:
		if not GameState.walking(): GameState.set_sleeping(not GameState.dog.sleeping)
		close_wheel())
	_sleep.name = "SleepButton"
	_row.add_child(_sleep)
	_wheel_card(_sleep)
	resized.connect(func() -> void:
		_refresh_wheel()
		_place_menu.call_deferred())
	Events.state_changed.connect(refresh)
	Events.care_requested.connect(point_at)
	Events.dog_action.connect(func(action: StringName) -> void:
		if (action == &"bathe" and _pointed_item == "sponge") or (action == &"play" and _pointed_item == "ball"):
			clear_pointer())
	visibility_changed.connect(func() -> void:
		if not is_visible_in_tree(): cancel())
	Events.sheet_requested.connect(func(_title: String, _content: Control) -> void: cancel())
	refresh()


## Seta junto do botão, sem capturar toque; acompanha o controle em qualquer resolução.
func point_at(id: String) -> void:
	clear_pointer()
	if id != "wish": open_wheel()
	var tile: Control = pet_screen.find_child("WishBubble", true, false) if id == "wish" else _items.get(id)
	if tile == null or not tile.is_visible_in_tree(): return
	close_food_menu()
	_pointed_item = id
	_pointer = Polygon2D.new()
	_pointer.name = "CarePointer"
	_pointer.z_index = Motion.WORLD_FX_Z
	_pointer.z_as_relative = false
	_pointer.color = Palette.HONEY
	_pointer.polygon = PackedVector2Array([Vector2(-8, -16), Vector2(8, -16), Vector2(0, -4)])
	var pin := Panel.new()
	pin.position = Vector2(-20, -52)
	pin.size = Vector2(40, 40)
	pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UiKit.surface(Palette.CARD, 20, true)
	style.border_color = Palette.HONEY
	style.set_border_width_all(3)
	pin.add_theme_stylebox_override("panel", style)
	_pointer.add_child(pin)
	var icon := UiKit.icon(WishUi.icon(GameState.balloon_wish()) if id == "wish" else UiKit.ui_icon({"sponge": "action_sponge", "ball": "action_play", "brush": "action_brush"}.get(id, "heart")), 24)
	icon.position = Vector2(8, 8)
	pin.add_child(icon)
	tile.add_child(_pointer)
	_pointer.position = Vector2(tile.size.x * 0.5, 0)
	tile.resized.connect(func() -> void:
		if is_instance_valid(_pointer) and _pointed_item == id:
			_pointer.position.x = tile.size.x * 0.5)
	if not Motion.reduced:
		var bounce := _pointer.create_tween().set_loops()
		bounce.tween_property(_pointer, "position:y", -6.0, 0.4).set_trans(Tween.TRANS_SINE)
		bounce.tween_property(_pointer, "position:y", 0.0, 0.4).set_trans(Tween.TRANS_SINE)


func clear_pointer() -> void:
	if is_instance_valid(_pointer):
		_pointer.get_parent().remove_child(_pointer)
		_pointer.queue_free()
	_pointer = null
	_pointed_item = ""


func food_ids() -> Array[String]:
	var result: Array[String] = []
	for id: String in Database.items:
		if Database.items[id].has("feed") and GameState.inventory.count(id) > 0:
			result.append(id)
	result.sort_custom(func(a: String, b: String) -> bool:
		var count_a := GameState.progress.stat("feed:" + a)
		var count_b := GameState.progress.stat("feed:" + b)
		if count_a != count_b: return count_a > count_b
		var recent_a := recent_foods.find(a)
		var recent_b := recent_foods.find(b)
		return recent_a >= 0 and (recent_b < 0 or recent_a < recent_b))
	return result


## O Escovar só existe com a escovinha: o quinto cuidado entra entre o Banho e o Brincar.
func _sync_brush() -> void:
	var owned := GameState.brush_owned()
	if owned and not _items.has("brush"):
		var tile := UiKit.care_disc(UiKit.ui_icon("action_brush"), "Escovar", func() -> void: pass)
		tile.name = "BrushTile"
		tile.mouse_filter = Control.MOUSE_FILTER_STOP
		tile.gui_input.connect(_on_item_input.bind("brush"))
		_items["brush"] = tile
		_row.add_child(tile)
		_row.move_child(tile, (_items.sponge as Control).get_index() + 1)
		_wheel_card(tile, UiKit.ui_icon("action_brush"))
	elif not owned and _items.has("brush"):
		var old := _items.brush as Control
		_row.remove_child(old)
		old.queue_free()
		_items.erase("brush")


## Muda quando a fase ou os sabores provados mudam (selos e "Nova!" da guia).
func _phase_key() -> String:
	return GameState.growth.phase + ":" + str(GameState.growth.tastes.size())


func refresh() -> void:
	visible = not GameState.walking()
	_play_hint.text = str(GameState.play_growth_info().status)
	_play_hint.hide()
	_sync_brush()
	_refresh_wheel()
	var ids := food_ids()
	# Não libera o controle que ainda recebe o gesto; só atualiza as quantidades.
	if (not _foods_ready or ids != _food_ids or _food_phase != _phase_key()) and _pressed == "":
		_food_phase = _phase_key()
		_foods_ready = true
		for id in _food_ids: _items.erase(id)
		for child in _foods.get_children():
			_foods.remove_child(child)
			child.queue_free()
		_food_ids = ids
		for id in ids: _foods.add_child(_food_item(id))
		_scroll.custom_minimum_size = Vector2(FOOD_COLUMNS * (FOOD_TILE + FOOD_GAP) - FOOD_GAP, _food_height())
		_place_menu.call_deferred()
		if ids.is_empty():
			_foods.add_child(SheetBuilder.food_help())
	for id: String in _items:
		var item: Control = _items[id]
		item.modulate.a = 0.45 if GameState.dog.sleeping else 1.0
		var caption := item.find_child("Caption", true, false) as Label
		if Database.items.has(id):
			caption.text = Database.item_name(id)
			(item.find_child("Quantity", true, false) as Label).text = "×%d" % GameState.inventory.count(id)
		else: caption.text = {"sponge": "Banho", "brush": "Escovar"}.get(id, "Brincar")
		if GameState.dog.sleeping: caption.text = "Zzz"
		var badge := item.get_node_or_null("Badge") as Control
		if badge: badge.visible = GameState.wish_wants_item(id)
	_food_button.modulate.a = 0.45 if GameState.dog.sleeping else 1.0
	(_food_button.find_child("Caption", true, false) as Label).text = "Zzz" if GameState.dog.sleeping else "Comida"
	if GameState.dog.sleeping or GameState.walking(): close_food_menu()
	(_sleep.find_child("Caption", true, false) as Label).text = "Acordar" if GameState.dog.sleeping else "Dormir"
	(_sleep.find_child("CareIcon", true, false) as TextureRect).texture = UiKit.ui_icon("action_wake" if GameState.dog.sleeping else "action_sleep")
	_sleep.disabled = GameState.walking()
	_place_menu.call_deferred()


func _item(id: String, texture: Texture2D, caption: String) -> Control:
	var item := Control.new()
	item.name = "Care_" + id
	item.custom_minimum_size = Vector2(56, 76)
	item.mouse_filter = Control.MOUSE_FILTER_STOP
	var icon := UiKit.icon(texture, 48)
	icon.position = Vector2(4, 0)
	icon.name = "CareIcon"
	icon.anchor_left = 0.5
	icon.anchor_right = 0.5
	icon.offset_left = -24
	icon.offset_right = 24
	item.add_child(icon)
	var label := UiKit.short_label(caption, &"SmallLabel")
	label.name = "Caption"
	label.position = Vector2(0, 48)
	label.size = Vector2(56, 24)
	label.anchor_right = 1.0
	label.offset_right = 0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(label)
	var badge := UiKit.icon(UiKit.ui_icon("heart"), 16)
	badge.name = "Badge"
	badge.position = Vector2(40, 0)
	badge.size = Vector2(16, 16)
	badge.hide()
	badge.anchor_left = 0.5
	badge.anchor_right = 0.5
	badge.offset_left = 16
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(badge)
	item.gui_input.connect(_on_item_input.bind(id))
	_items[id] = item
	return item


## Altura da área das comidas: até `FOOD_ROWS` linhas de quadradinhos (o resto rola); vazia, o espaço do aviso.
func _food_height() -> float:
	if _food_ids.is_empty(): return 112.0
	var rows := mini(FOOD_ROWS, ceili(float(_food_ids.size()) / FOOD_COLUMNS))
	return rows * FOOD_TILE + (rows - 1) * FOOD_GAP


## Quadradinho de madeira só com o ícone: o ícone é a pega de arrasto até a cabeça. Quantidade embaixo à direita,
## estrela "Nova" (ou coração da favorita) em cima à esquerda, selo da fase embaixo à esquerda, pedido em cima à direita.
func _food_item(id: String) -> Control:
	var item := _item(id, Database.item_icon(id), "")
	item.custom_minimum_size = Vector2(FOOD_TILE, FOOD_TILE)
	item.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var background := MissionUi.tile(null, "", "FoodDisc", Vector2(FOOD_TILE, FOOD_TILE))
	item.add_child(background)
	item.move_child(background, 0)
	StepCardUi.stretch(background)
	var caption := item.get_node("Caption") as Label
	caption.visible = false  # sem nome: o ícone fala por si
	var icon := item.get_node("CareIcon") as Control
	icon.anchor_left = 0.0
	icon.anchor_right = 0.0
	icon.offset_left = 0.0
	icon.offset_right = 0.0
	icon.position = Vector2(8, 6)
	icon.custom_minimum_size = Vector2(40, 40)
	icon.size = Vector2(40, 40)
	var quantity := MissionUi.text("", 14, Palette.WOOD_CREAM, 4, HORIZONTAL_ALIGNMENT_RIGHT)
	quantity.name = "Quantity"
	item.add_child(quantity)
	StepCardUi.stretch(quantity)
	quantity.offset_right = -4.0
	quantity.offset_bottom = -2.0
	quantity.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	var fresh := not GameState.growth.tastes.has(id)
	if fresh:
		item.set_meta("new_taste", true)
		var star := PanelContainer.new()
		star.name = "NewTaste"
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star.add_theme_stylebox_override("panel", UiKit.surface(Palette.HONEY_SOFT, 10))
		star.position = Vector2(2, 2)
		star.add_child(UiKit.ctl("spark", 14, Palette.HONEY_INK))
		item.add_child(star)
	var badge := item.get_node("Badge") as Control
	badge.anchor_left = 0.0
	badge.anchor_right = 0.0
	badge.offset_left = 0.0
	badge.position = Vector2(FOOD_TILE - 20.0, 2)
	var growth: Dictionary = Database.items[id].get("growth", {})
	if GameState.growth.phase in growth.get("phases", []):
		var seal := UiKit.icon(UiKit.ui_icon("pillar_body"), 18)
		seal.name = "GrowthSeal"
		seal.position = Vector2(3, FOOD_TILE - 21.0)
		seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(seal)
	elif not growth.is_empty():
		item.tooltip_text = "Ele prefere outra coisa agora"
	if GameState.favorite_found() and id == GameState.favorite_food():
		var heart := UiKit.icon(UiKit.ui_icon("heart"), 18)
		heart.name = "FavoriteHeart"
		heart.position = Vector2(3, 3)
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(heart)
	return item


func open_food_menu() -> void:
	if GameState.walking() or GameState.dog.sleeping:
		Events.toast_requested.emit(GameState.away_text() if GameState.walking() else "Shh... ele está dormindo.")
		return
	if _menu.visible:
		close_food_menu()
		return
	close_wheel()
	refresh()
	_menu.show()
	_scroll.scroll_vertical = 0
	_place_menu()
	Motion.pop_in(_menu)


func close_food_menu() -> void:
	_menu.hide()


## Base da guia de comidas: logo acima da tábua das abas (o botão Cuidar fica ao lado dela, não embaixo).
func _menu_bottom() -> float:
	var bar := get_tree().root.find_child("TabBar", true, false) as Control if is_inside_tree() else null
	if bar != null and bar.size.y > 0.0:
		return bar.global_position.y - pet_screen.global_position.y - 8.0
	return pet_screen.size.y - 112.0


func _place_menu() -> void:
	# A cabeça é o alvo de soltar a comida: a lista só usa a faixa abaixo dela,
	# terminando acima de Cuidar. O restante continua acessível por rolagem.
	var top := (pet_screen.call("head_rect") as Rect2).end.y - pet_screen.global_position.y + 8.0
	var bottom := _menu_bottom()
	_scroll.custom_minimum_size.y = 0.0
	var chrome := _menu.get_combined_minimum_size().y
	if _food_ids.is_empty():
		_scroll.custom_minimum_size.y = minf(112.0, maxf(0.0, bottom - top - chrome))
	else:
		# Sempre linhas inteiras (nada cortado); passando da janela, rola pelos espaços entre os quadradinhos ou pela roda.
		var total := ceili(float(_food_ids.size()) / FOOD_COLUMNS)
		var row := FOOD_TILE + FOOD_GAP
		var fit := maxi(1, floori((bottom - top - chrome + FOOD_GAP) / row))
		var rows := mini(mini(FOOD_ROWS, total), fit)
		_scroll.custom_minimum_size.y = rows * FOOD_TILE + (rows - 1) * FOOD_GAP
	_menu.size = _menu.get_combined_minimum_size()
	# Centralizada, mas sem passar por cima do botão Cuidar (que mora na borda direita).
	var heart_left := _care_button.global_position.x - pet_screen.global_position.x - 8.0
	_menu.position = Vector2(maxf(minf((pet_screen.size.x - _menu.size.x) * 0.5, heart_left - _menu.size.x), 8.0), bottom - _menu.size.y)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not _menu.visible or _pressed != "": return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _menu.get_global_rect().has_point(event.global_position) and not _care_button.get_global_rect().has_point(event.global_position):
			close_food_menu()
			get_viewport().set_input_as_handled()


func item_center(id: String) -> Vector2:
	var item: Control = _items.get(id)
	return item.global_position + Vector2(28, 28) if item and Database.items.has(id) else (item.global_position + item.size / 2.0 if item else Vector2.ZERO)


func item_node(id: String) -> Control:
	return _items.get(id) as Control


func _on_item_input(event: InputEvent, id: String) -> void:
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		return  # deixa a roda chegar ao ScrollContainer
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: press_item(id, event.global_position)
		else: release_item(event.global_position)
	elif event is InputEventMouseMotion and _pressed == id:
		move_item(event.global_position)
	if _items.has(id): (_items[id] as Control).accept_event()


func press_item(id: String, point: Vector2) -> void:
	if _pressed != "": return
	_pressed = id
	gesture.press(point)
	_distance = 0.0
	_bubbles_at = 0.0
	_acted = false
	_scrolling = false
	var food: Dictionary = Database.items.get(id, {}).get("growth", {})
	if not food.is_empty() and GameState.growth.phase not in food.get("phases", []):
		get_tree().create_timer(0.65).timeout.connect(func() -> void:
			if _pressed == id and not _dragging and not _scrolling:
				Events.toast_requested.emit("Ele prefere outra coisa agora"))


func move_item(point: Vector2) -> void:
	if _pressed == "" or GameState.dog.sleeping or GameState.walking(): return
	var crossed := gesture.move(point)
	if not _dragging and crossed and Database.items.has(_pressed) and gesture.start.x - (_items[_pressed] as Control).global_position.x > 64 and absf(point.y - gesture.start.y) > absf(point.x - gesture.start.x):
		_scrolling = true
	if _scrolling:
		_scroll.scroll_vertical -= roundi(point.y - gesture.previous.y)
		return
	if not _dragging:
		if not crossed: return
		_dragging = true
		var texture := UiKit.ui_icon({"sponge": "action_sponge", "ball": "action_play", "brush": "action_brush"}[_pressed]) if _pressed in ["sponge", "ball", "brush"] else Database.item_icon(_pressed)
		gesture.begin(pet_screen, texture)
		_menu.modulate.a = 0.3
		_row.modulate.a = 0.3
	gesture.follow(pet_screen)
	if _pressed == "brush" and not _acted:
		var back: Rect2 = pet_screen.call("back_rect")
		if back.has_point(gesture.target()) and back.has_point(gesture.previous - Vector2(0, DragGhost.LIFT)):
			_distance += gesture.finger.distance_to(gesture.previous)
			pet_screen.call("brush_stroke")
		if _distance - _bubbles_at >= BRUSH_STEP:
			_bubbles_at = _distance
			pet_screen.call("brush_knot_off", gesture.target())
		if _distance >= BRUSH_TOTAL:
			_acted = true
			_act("brush")
			gesture.finish()
	if _pressed == "sponge" and not _acted:
		var dog: Rect2 = pet_screen.call("dog_rect")
		if dog.has_point(gesture.target()) and dog.has_point(gesture.previous - Vector2(0, DragGhost.LIFT)):
			_distance += gesture.finger.distance_to(gesture.previous)
		if _distance - _bubbles_at >= SCRUB_STEP:
			_bubbles_at = _distance
			pet_screen.call("care_bubbles", gesture.target())
		if _distance >= SCRUB_TOTAL:
			_acted = true
			_act("sponge")
			gesture.finish()


func release_item(point: Vector2) -> void:
	if _pressed == "": return
	var id := _pressed
	# Marca como consumido antes da ação: state_changed pode reconstruir a faixa.
	var dragged := _dragging
	var acted := _acted
	var scrolling := _scrolling
	_pressed = ""
	_dragging = false
	if not acted and not scrolling:
		if not dragged:
			if id == "brush": Events.toast_requested.emit("Passe a escova nas costas dele")
			else: choose_care(id)
		elif id == "ball":
			if gesture.release_velocity().y < THROW_SPEED and point.y < gesture.start.y - DragGhost.SLOP:
				_act(id)
		elif id not in ["sponge", "brush"]:
			var head: Rect2 = pet_screen.call("head_rect")
			if head.has_point(point - Vector2(0, DragGhost.LIFT)): _act(id)
	close_wheel()
	gesture.finish()
	if id == "brush": pet_screen.call("brush_cleanup")
	_menu.modulate.a = 1.0
	refresh()


func cancel() -> void:
	close_wheel()
	clear_pointer()
	_pressed = ""
	_dragging = false
	gesture.finish()
	_menu.modulate.a = 1.0
	close_food_menu()


func _act(id: String, with_shampoo: bool = false) -> void:
	var error := ""
	if GameState.walking(): error = GameState.away_text()
	elif GameState.dog.sleeping: error = "Shh... ele está dormindo."
	elif id == "sponge":
		close_food_menu()
		GameState.bathe(with_shampoo)
		pet_screen.call("care_bubbles", (pet_screen.call("dog_rect") as Rect2).get_center())
	elif id == "brush":
		close_food_menu()
		error = GameState.brush()
		pet_screen.call("brush_cleanup")
	elif id == "ball":
		close_food_menu()
		var before := GameState.play_growth_info()
		if GameState.play():
			pet_screen.call("throw_ball")
			pet_screen.call("play_growth_feedback", before, GameState.play_growth_info())
		else: error = "Tiro está cansado demais para brincar."
	else:
		error = SheetBuilder.give_food(id)
		if error == "":
			recent_foods.erase(id)
			recent_foods.push_front(id)
			pet_screen.call("food_effects", id)
	if error != "":
		Events.toast_requested.emit(error)
		if _items.has(id): Motion.shake(_items[id])


## Catálogo único: todo cuidado com mais de uma opção usa o mesmo Popover.
## O arrasto mantém o gesto direto (banho comum / bola); o toque permite escolher.
func care_options(id: String) -> Array[Dictionary]:
	match id:
		"sponge":
			return [
				{"name": "BathPlain", "label": "Sem xampu", "icon": UiKit.ui_icon("action_sponge"), "action": _act.bind("sponge", false)},
				{"name": "BathShampoo", "label": "Com xampu", "icon": Database.item_icon("herb_shampoo"), "action": _act.bind("sponge", true), "locked": "Falta xampu" if GameState.inventory.count("herb_shampoo") < 1 else ""},
			]
		"ball":
			var options: Array[Dictionary] = [{"name": "PlayBall", "label": "Bola", "icon": UiKit.ui_icon("action_play"), "action": _act.bind("ball")}]
			if GameState.hide_unlocked():
				var treats := GameState.hide_treats()
				options.append({"name": "PlayCups", "label": "Copinhos", "icon": Database.item_icon(treats[0]) if not treats.is_empty() else null, "action": start_hide_and_seek.bind(treats[0] if not treats.is_empty() else ""), "locked": "Copinhos: falta um petisco" if treats.is_empty() else ""})
			return options
	return []


func choose_care(id: String) -> void:
	if GameState.dog.sleeping or GameState.walking():
		_act(id)
		return
	var options := care_options(id)
	if options.size() > 1:
		_open_care_choice(id, options)
	else:
		_act(id)


func _open_care_choice(id: String, options: Array[Dictionary]) -> void:
	close_food_menu()
	close_wheel()
	var box := UiKit.vbox(6)
	box.name = "BathChoice" if id == "sponge" else "PlayChoice" if id == "ball" else "CareChoice_" + id
	var holder: Array[Popover] = []
	var choose := func(action: Callable) -> void:
		if not holder.is_empty() and is_instance_valid(holder[0]): holder[0].close()
		action.call()
	for option: Dictionary in options:
		var button: Control
		if str(option.get("locked", "")) != "":
			button = UiKit.lock_hint(str(option.locked))
			button.name = str(option.name) + "Locked"
		else:
			button = UiKit.soft(str(option.label), choose.bind(option.action), option.icon)
			button.name = str(option.name)
		box.add_child(button)
	# O popup fica acima de Cuidar e das abas, inclusive no cartão baixo do banho.
	var bottom := _care_button.global_position.y - pet_screen.global_position.y - Popover.GAP
	holder.append(Popover.open(pet_screen, _items[id], box, 0.0, bottom))


func open_play_choice() -> void:
	choose_care("ball")


func start_hide_and_seek(treat: String) -> void:
	var game := HideSeekUi.new()
	game.name = "HideSeek"
	Events.sheet_requested.emit("Esconde-esconde", game)
	var error := game.start(treat)
	if error != "":
		Events.toast_requested.emit(error)
		Events.sheet_close_requested.emit()


## A roleta é só apresentação: as ações continuam nos mesmos métodos do motor.
func _toggle_wheel() -> void:
	if GameState.dog.sleeping:
		GameState.set_sleeping(false)
	elif _row.visible: close_wheel()
	else: open_wheel()


func open_wheel() -> void:
	if GameState.dog.sleeping or GameState.walking(): return
	var popover := pet_screen.get_node_or_null("PopoverCatcher")
	if popover: popover.free()
	close_food_menu()
	_row.show()
	_row.modulate.a = 1.0
	_refresh_wheel()
	Motion.stagger_in(_row.get_children())
	if not Motion.reduced:
		var center := _care_button.position + _care_button.size / 2.0
		for disc: Control in _row.get_children():
			var target := disc.position
			disc.position = center - disc.size / 2.0
			disc.scale = Vector2.ONE * 0.6
			var tween := disc.create_tween().set_parallel()
			tween.tween_property(disc, "position", target, Motion.POP_IN).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(disc, "scale", Vector2.ONE, Motion.POP_IN).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pet_screen.call("wheel_changed", true)


func close_wheel() -> void:
	_row.hide()
	_row.modulate.a = 1.0
	_refresh_wheel()
	pet_screen.call("wheel_changed", false)


func _on_veil_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_wheel()
		_row.accept_event()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT and event.relative.y > 0:
		close_wheel()
		_row.accept_event()


func _asked_care() -> void:
	match GameState.asking_need():
		"hunger": open_food_menu()
		"hygiene": choose_care("sponge")
		"happiness": choose_care("ball")
		"energy": GameState.set_sleeping(true)
	close_wheel()


## Desenha o coração de madeira do botão Cuidar (arte do protótipo): selinho com a tigela e a etiqueta "Cuidar".
func _build_care_art() -> void:
	HomeUi.pic(_care_button, "care_heart", Rect2(Vector2.ZERO, HEART_SIZE), "CareHeartArt")
	HomeUi.pic(_care_button, "badge", Rect2(46, -6, 24, 24), "CareBadge")
	HomeUi.pic(_care_button, "care_label", Rect2(-4, 64, 72, 24), "CareLabelArt")


## Troca o disco do cuidado pelo cartão ilustrado (sem legenda: o desenho já diz o que é).
func _wheel_card(disc: Button, icon: Texture2D = null) -> void:
	(disc.find_child("Circle", true, false) as Control).hide()
	(disc.find_child("CaptionPill", true, false) as Control).hide()
	disc.custom_minimum_size = Vector2(WHEEL_CARD, WHEEL_CARD)
	disc.size = Vector2(WHEEL_CARD, WHEEL_CARD)
	var card := _wheel_picture(load(HomeUi.DIR + "wheel_%s.png" % WHEEL_CARDS[str(disc.name)]) as Texture2D, "WheelCard")
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	disc.add_child(card)
	disc.move_child(card, 0)
	if icon != null:
		var picture := _wheel_picture(icon, "WheelIcon")
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
		card.add_child(picture)


func _wheel_picture(texture: Texture2D, node_name: String) -> TextureRect:
	var result := TextureRect.new()
	result.name = node_name
	result.texture = texture
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


## Onde o botão fica: borda direita, acima da tábua das abas (protótipo: coração a 218 px do fim em 780 de altura).
func _care_spot() -> Vector2:
	var bar := get_tree().root.find_child("TabBar", true, false) as Control if is_inside_tree() else null
	var extra := (bar.size.y - 104.0) if bar != null and bar.size.y > 0.0 else 0.0
	return Vector2(size.x - 14.0 - HEART_SIZE.x, size.y - 218.0 - extra)


func _refresh_wheel() -> void:
	_care_button.position = _care_spot()
	var sleeping := GameState.dog.sleeping
	(_care_button.find_child("CareIcon", true, false) as TextureRect).texture = UiKit.ui_icon("action_wake" if sleeping else "heart")
	(_care_button.find_child("Caption", true, false) as Label).text = "Acordar" if sleeping else "Cuidar"
	# Acordado: coração de madeira e "Cuidar" desenhado; dormindo: o disco antigo com o ícone de acordar.
	(_care_button.find_child("CaptionPill", true, false) as Control).visible = sleeping and not _row.visible
	for art_name: String in ["CareHeartArt", "CareLabelArt"]:
		(_care_button.find_child(art_name, true, false) as Control).visible = not sleeping
	(_care_button.find_child("CareIcon", true, false) as Control).visible = sleeping
	var style := UiKit.surface(Color(Palette.CARD, 0.9), 36, true)
	style.border_color = Palette.HONEY
	style.set_border_width_all(4)
	style.shadow_color = Color(Palette.HONEY, 0.22) if _row.visible else Palette.SHADOW
	style.shadow_size = 12 if _row.visible else 8
	if not sleeping:
		style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
	(_care_button.find_child("Circle", true, false) as PanelContainer).add_theme_stylebox_override("panel", style)
	var need := GameState.asking_need()
	_ask.visible = need != "" and not sleeping
	# O selinho só existe quando o Tiro pede algo (e mostra o ícone do pedido, o mesmo do CareAsk).
	(_care_button.find_child("CareBadge", true, false) as Control).visible = _ask.visible
	_ask_icon.texture = Database.item_icon("dog_food") if need == "hunger" else UiKit.ui_icon({"hygiene": "action_sponge", "happiness": "action_play", "energy": "action_sleep"}.get(need, "heart"))
	# O botão Cuidar mora na borda direita: os cuidados abrem em leque para cima e para a esquerda (190° a 90°).
	var angles: Array = [190, 165, 140, 115, 90] if _items.has("brush") else [190, 160, 130, 100]
	var center := _care_button.position + _care_button.size / 2.0
	var discs := _row.get_children()
	for i in discs.size():
		var disc := discs[i] as Control
		disc.position = center + Vector2(cos(deg_to_rad(angles[i])), -sin(deg_to_rad(angles[i]))) * WHEEL_RADIUS - disc.size / 2.0
		var asking: bool = {"FoodButton": "hunger", "Care_sponge": "hygiene", "Care_ball": "happiness", "SleepButton": "energy"}.get(str(disc.name), "") == need and need != ""
		var circle := disc.find_child("Circle", true, false) as PanelContainer
		var surface := UiKit.surface(Color(Palette.ALERT_SOFT, 0.92) if asking else Color(Palette.CARD, 0.82), 32, true)
		surface.border_color = Palette.CARD
		surface.set_border_width_all(2)
		circle.add_theme_stylebox_override("panel", surface)
		var dot := disc.get_node_or_null("AskDot") as Control
		if dot == null:
			# Tamanho fixo: o Label de UiKit.dot cresce com a fonte do tema.
			dot = Panel.new()
			dot.name = "AskDot"
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dot.size = Vector2(16, 16)
			dot.position = Vector2(WHEEL_CARD - 20.0, 4.0)
			dot.z_index = 2
			var dot_style := UiKit.surface(Palette.ALERT, 8)
			dot_style.border_color = Palette.CARD
			dot_style.set_border_width_all(2)
			dot.add_theme_stylebox_override("panel", dot_style)
			disc.add_child(dot)
		dot.visible = asking
		# Comida usa só o pedido vermelho, sem o brilho que o cobria.
		if disc == _food_button: continue
		var spark := disc.get_node_or_null("MomentSpark") as Control
		if spark == null:
			spark = UiKit.spark()
			spark.name = "MomentSpark"
			spark.position = Vector2(4, 4)
			disc.add_child(spark)
		var pillar: String = {"Care_sponge": "coat", "Care_ball": "smart"}.get(str(disc.name), "")
		spark.visible = (asking and GameState.need_pillar(need) == pillar and pillar != "")
	_row.queue_redraw()


func _draw_wheel() -> void:
	var center := _care_button.position + _care_button.size / 2.0
	_row.draw_rect(Rect2(Vector2.ZERO, size), Color(Palette.INK, 0.18 if Motion.reduced else 0.10))
	if not Motion.reduced:
		for i in 20:
			_row.draw_circle(center, 320.0 - i * 16.0, Color(Palette.INK, 0.008), true, -1, true)
	# Faixa de madeira lisa em volta do coração, com pontas arredondadas e tachinhas douradas entre os cartões.
	var from := deg_to_rad(-190.0)
	var to := deg_to_rad(-80.0 if _items.has("brush") else -84.0)
	for layer: Array in [[WOOD_EDGE, BAND_WIDTH + 6.0], [WOOD_BAND, BAND_WIDTH - 2.0], [WOOD_LIGHT, BAND_WIDTH - 22.0], [WOOD_BAND, BAND_WIDTH - 30.0]]:
		_row.draw_arc(center, WHEEL_RADIUS, from, to, 96, layer[0], layer[1], true)
		for end: float in [from, to]:
			_row.draw_circle(center + Vector2(cos(end), sin(end)) * WHEEL_RADIUS, layer[1] / 2.0, layer[0], true, -1, true)
	var angles: Array = [177.5, 152.5, 127.5, 102.5] if _items.has("brush") else [175.0, 145.0, 115.0]
	for angle: float in angles:
		for edge: float in [-1.0, 1.0]:
			var at := center + Vector2(cos(deg_to_rad(angle)), -sin(deg_to_rad(angle))) * (WHEEL_RADIUS + edge * (BAND_WIDTH / 2.0 - 7.0))
			_row.draw_circle(at, 3.5, Palette.WOOD_GLOW, true, -1, true)


## O fundo PASS não deve impedir o carinho ou o balão, que são irmãos.
func _has_point(_point: Vector2) -> bool:
	return false
