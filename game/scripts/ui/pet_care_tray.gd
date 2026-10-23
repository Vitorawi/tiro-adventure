class_name PetCareTray
extends PanelContainer
## Faixa permanente de cuidados. Gestos nunca alteram estado antes de validar o alvo.

const SCRUB_STEP := 260.0
const SCRUB_TOTAL := 800.0
const THROW_SPEED := -180.0
const BRUSH_STEP := 200.0
const BRUSH_TOTAL := 600.0
var pet_screen: Control
var gesture := DragGhost.new()
var _row: HBoxContainer
var _play_hint: Label
var _scroll: ScrollContainer
var _foods: VBoxContainer
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
var _shampoo: Button
var _pointer: Polygon2D
var _pointed_item := ""
static var use_shampoo := false


func _ready() -> void:
	name = "CareTray"
	custom_minimum_size.y = 104
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PET_SURFACE
	style.set_corner_radius_all(26)
	style.shadow_color = Palette.SHADE
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)
	_row = UiKit.hbox(8)
	var care_column := UiKit.vbox(2)
	add_child(care_column)
	care_column.add_child(_row)
	_play_hint = UiKit.label("", &"SmallLabel")
	_play_hint.name = "PlayGrowthTimer"
	_play_hint.add_theme_font_size_override("font_size", 14)
	care_column.add_child(_play_hint)
	_food_button = UiKit.action_tile(Database.item_icon("dog_food"), "Comida", open_food_menu)
	_food_button.name = "FoodButton"
	_row.add_child(_food_button)
	_menu = PanelContainer.new()
	_menu.name = "FoodMenu"
	_menu.theme_type_variation = &"CardPanel"
	_menu.z_index = 4
	_menu.hide()
	pet_screen.add_child(_menu)
	_menu.minimum_size_changed.connect(func() -> void: _place_menu.call_deferred())
	var column := UiKit.vbox(4)
	_menu.add_child(column)
	var header := UiKit.hbox(4)
	header.add_child(UiKit.fill_label("Comidinhas", &"SectionLabel"))
	header.add_child(UiKit.icon_button(UiKit.ui_icon("ui_close"), close_food_menu, 44))
	column.add_child(header)
	_scroll = ScrollContainer.new()
	_scroll.name = "FoodScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	column.add_child(_scroll)
	_foods = UiKit.vbox(4)
	_foods.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_foods)
	for entry: Array in [["sponge", "action_sponge", "Banho"], ["ball", "action_play", "Brincar"]]:
		var item := UiKit.action_tile(UiKit.ui_icon(entry[1]), entry[2], func() -> void: pass)
		item.name = "Care_" + str(entry[0])
		item.mouse_filter = Control.MOUSE_FILTER_STOP
		item.gui_input.connect(_on_item_input.bind(str(entry[0])))
		_items[entry[0]] = item
		_row.add_child(item)
	_sleep = UiKit.action_tile(UiKit.ui_icon("action_sleep"), "Dormir", func() -> void:
		if not GameState.walking(): GameState.set_sleeping(not GameState.dog.sleeping))
	_sleep.name = "SleepButton"
	_row.add_child(_sleep)
	for tile: Control in _row.get_children(): tile.custom_minimum_size.x = 56  # cabem cinco cuidados em 360 px
	_shampoo = UiKit.button("Com xampu", func() -> void: use_shampoo = _shampoo.button_pressed)
	_shampoo.name = "ShampooToggle"
	_shampoo.toggle_mode = true
	_shampoo.button_pressed = use_shampoo
	_shampoo.custom_minimum_size = Vector2(112, 44)
	_shampoo.z_index = 5
	pet_screen.add_child(_shampoo)
	resized.connect(func() -> void: _place_menu.call_deferred())
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
	var tile: Control = pet_screen.find_child("WishBubble", true, false) if id == "wish" else _items.get(id)
	if tile == null or not tile.is_visible_in_tree(): return
	close_food_menu()
	_pointed_item = id
	_pointer = Polygon2D.new()
	_pointer.name = "CarePointer"
	_pointer.z_index = Motion.WORLD_FX_Z
	_pointer.z_as_relative = false
	_pointer.color = Palette.GOLD
	_pointer.polygon = PackedVector2Array([Vector2(-7, -42), Vector2(7, -42), Vector2(7, -25), Vector2(15, -25), Vector2(0, -10), Vector2(-15, -25), Vector2(-7, -25)])
	var outline := Line2D.new()
	outline.points = _pointer.polygon
	outline.closed = true
	outline.width = 2.0
	outline.default_color = Palette.OUTLINE
	_pointer.add_child(outline)
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
		var tile := UiKit.action_tile(UiKit.ui_icon("action_brush"), "Escovar", func() -> void: pass)
		tile.name = "BrushTile"
		tile.mouse_filter = Control.MOUSE_FILTER_STOP
		tile.gui_input.connect(_on_item_input.bind("brush"))
		_items["brush"] = tile
		_row.add_child(tile)
		_row.move_child(tile, (_items.sponge as Control).get_index() + 1)
		tile.custom_minimum_size.x = 56
	elif not owned and _items.has("brush"):
		(_items.brush as Control).queue_free()
		_items.erase("brush")


## Muda quando a fase ou os sabores provados mudam (selos e "Nova!" da guia).
func _phase_key() -> String:
	return GameState.growth.phase + ":" + str(GameState.growth.tastes.size())


func refresh() -> void:
	visible = not GameState.walking()
	_play_hint.text = str(GameState.play_growth_info().status)
	_play_hint.visible = not GameState.dog.sleeping
	_sync_brush()
	_row.add_theme_constant_override("separation", 4 if _items.has("brush") else 8)
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
		_scroll.custom_minimum_size = Vector2(204, 112 if ids.is_empty() else mini(5, ids.size()) * 64 - 4)
		_place_menu.call_deferred()
		if ids.is_empty():
			_foods.add_child(SheetBuilder.food_help())
	for id: String in _items:
		var item: Control = _items[id]
		item.modulate.a = 0.45 if GameState.dog.sleeping else 1.0
		var caption := item.find_child("Caption", true, false) as Label
		if Database.items.has(id): caption.text = "%s ×%d" % [Database.item_name(id), GameState.inventory.count(id)]
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
	_shampoo.visible = GameState.inventory.count("herb_shampoo") > 0 and not GameState.dog.sleeping and not _menu.visible and visible
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


## Linhas verticais: o ícone é a pega de arrasto; o nome permite rolar a lista.
func _food_item(id: String) -> Control:
	var item := _item(id, Database.item_icon(id), "")
	item.custom_minimum_size = Vector2(204, 60)
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := item.get_node("Caption") as Label
	label.anchor_right = 0.0
	label.position = Vector2(60, 4)
	label.size = Vector2(136, 52)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var icon := item.get_node("CareIcon") as Control
	icon.anchor_left = 0.0
	icon.anchor_right = 0.0
	icon.position = Vector2(4, 6)
	icon.size = Vector2(48, 48)
	var badge := item.get_node("Badge") as Control
	badge.anchor_left = 0.0
	badge.anchor_right = 0.0
	badge.position = Vector2(36, 2)
	var growth: Dictionary = Database.items[id].get("growth", {})
	if GameState.growth.phase in growth.get("phases", []):
		var seal := UiKit.icon(UiKit.ui_icon("pillar_body"), 20)
		seal.name = "GrowthSeal"
		seal.position = Vector2(34, 38)
		seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(seal)
	elif not growth.is_empty():
		item.tooltip_text = "Ele prefere outra coisa agora"
	if GameState.favorite_found() and id == GameState.favorite_food():
		var heart := UiKit.icon(UiKit.ui_icon("heart"), 20)
		heart.name = "FavoriteHeart"
		heart.position = Vector2(180, 4)
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(heart)
	elif not GameState.growth.tastes.has(id):
		# Etiqueta "Provar" à direita do nome (nunca provou). Texto na cor do tema (branco sobre o fundo do selo).
		var fresh := UiKit.short_label("Provar", &"BadgeLabel")
		fresh.name = "NewTaste"
		fresh.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(fresh)
		fresh.reset_size()
		fresh.position = Vector2(200.0 - fresh.size.x, 4)
		label.size = Vector2(fresh.position.x - 64.0, 52)
	return item


func open_food_menu() -> void:
	if GameState.walking() or GameState.dog.sleeping:
		Events.toast_requested.emit(GameState.away_text() if GameState.walking() else "Shh... ele está dormindo.")
		return
	if _menu.visible:
		close_food_menu()
		return
	refresh()
	_menu.show()
	_shampoo.hide()
	_scroll.scroll_vertical = 0
	_place_menu()
	Motion.pop_in(_menu)


func close_food_menu() -> void:
	_menu.hide()
	if _shampoo: _shampoo.visible = GameState.inventory.count("herb_shampoo") > 0 and not GameState.dog.sleeping and visible


func _place_menu() -> void:
	_menu.size = _menu.get_combined_minimum_size()
	_menu.position = Vector2(12, global_position.y - pet_screen.global_position.y - _menu.size.y - 8)
	if _shampoo and _items.has("sponge"):
		_shampoo.size = _shampoo.get_combined_minimum_size()
		_shampoo.position = Vector2(clampf((_items.sponge as Control).get_global_rect().get_center().x - pet_screen.global_position.x - _shampoo.size.x / 2.0, 8, pet_screen.size.x - _shampoo.size.x - 8), global_position.y - pet_screen.global_position.y - _shampoo.size.y - 4)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not _menu.visible or _pressed != "": return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _menu.get_global_rect().has_point(event.global_position) and not get_global_rect().has_point(event.global_position):
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
			elif id == "ball" and GameState.hide_unlocked(): open_play_choice()
			else: _act(id)
		elif id == "ball":
			if gesture.release_velocity().y < THROW_SPEED and point.y < gesture.start.y - DragGhost.SLOP:
				_act(id)
		elif id not in ["sponge", "brush"]:
			var head: Rect2 = pet_screen.call("head_rect")
			if head.has_point(point - Vector2(0, DragGhost.LIFT)): _act(id)
	gesture.finish()
	if id == "brush": pet_screen.call("brush_cleanup")
	_menu.modulate.a = 1.0
	refresh()


func cancel() -> void:
	clear_pointer()
	_pressed = ""
	_dragging = false
	gesture.finish()
	_menu.modulate.a = 1.0
	close_food_menu()


func _act(id: String) -> void:
	var error := ""
	if GameState.walking(): error = GameState.away_text()
	elif GameState.dog.sleeping: error = "Shh... ele está dormindo."
	elif id == "sponge":
		close_food_menu()
		GameState.bathe(use_shampoo and GameState.inventory.count("herb_shampoo") > 0)
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


## Brincar com um toque, desde o Aventureiro: bola (arremessar continua pelo arrasto) ou copinhos.
func open_play_choice() -> void:
	close_food_menu()
	var box := UiKit.vbox(6)
	box.name = "PlayChoice"
	var holder: Array[Popover] = []
	var choose := func(action: Callable) -> void:
		if not holder.is_empty() and is_instance_valid(holder[0]): holder[0].close()
		action.call()
	var ball := UiKit.secondary("Bola", choose.bind(func() -> void: _act("ball")), UiKit.ui_icon("action_play"))
	ball.name = "PlayBall"
	box.add_child(ball)
	var treats := GameState.hide_treats()
	if treats.is_empty():
		var hint := UiKit.lock_hint("Copinhos: falta um petisco")
		hint.name = "PlayCupsLocked"
		box.add_child(hint)
	else:
		var treat: String = treats[0]
		var cups := UiKit.secondary("Copinhos", choose.bind(func() -> void: start_hide_and_seek(treat)), Database.item_icon(treat))
		cups.name = "PlayCups"
		box.add_child(cups)
	holder.append(Popover.open(pet_screen, _items["ball"], box, 0.0))


func start_hide_and_seek(treat: String) -> void:
	var game := HideSeekUi.new()
	game.name = "HideSeek"
	Events.sheet_requested.emit("Esconde-esconde", game)
	var error := game.start(treat)
	if error != "":
		Events.toast_requested.emit(error)
		Events.sheet_close_requested.emit()
