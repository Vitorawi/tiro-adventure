class_name FriendUi
extends RefCounted
## Amigos: petiscos na bandeja do mapa; cartões completos no álbum e na lista de Amigos.

static func open(id: String) -> void:
	if GameState.friend_unlocked(id):
		for room: Node in (Engine.get_main_loop() as SceneTree).get_nodes_in_group("room_views"):
			if room is RoomView and room.is_visible_in_tree() and room.open_friend_tray(id):
				return
		Events.sheet_requested.emit(str(GameState.friend_def(id).name), panel(id))


## Petisco direto no mundo, no mesmo modo de seleção das estações.
static func tray(room: RoomView, id: String, anchor: Vector2) -> ActionTray:
	var def := GameState.friend_def(id)
	var item := str(def.likes)
	var header := SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var row := UiKit.hbox(8)
		row.add_child(UiKit.icon(load(str(def.portrait)), 48))
		var hearts := GameState.friend_hearts(id)
		for i in Database.friends.settings.hearts.size():
			var heart := UiKit.icon(UiKit.ui_icon("heart"), 24)
			if i >= hearts:
				heart.modulate = Palette.SUNKEN
			row.add_child(heart)
		box.add_child(row)
		if hearts < Database.friends.settings.hearts.size():
			box.add_child(UiKit.label("%d/%d petiscos · próximo coração" % [int(GameState.friend_state.entry(id).gifts), int(Database.friends.settings.hearts[hearts])], &"SmallLabel"))
		else:
			box.add_child(UiKit.label("Melhor amigo · Visita a casa", &"SmallLabel")))
	var entries: Array[Dictionary] = [{
		"id": item, "icon": Database.item_icon(item),
		"caption_fn": func() -> String: return "%d/1" % GameState.inventory.count(item),
	}]
	return ActionTray.open(room, anchor - Vector2(0, 28), entries, {
		"mode": "pick", "title": str(def.name), "header": header,
		"selected": item, "below": anchor + Vector2(0, 10),
		"detail": func(_item: String) -> Control: return _treat_detail(id),
	})


static func _treat_detail(id: String) -> Control:
	var box := UiKit.vbox(6)
	var def := GameState.friend_def(id)
	var item := str(def.likes)
	box.add_child(UiKit.label(Database.item_name(item), &"SectionLabel"))
	box.add_child(ProgressionUi.item_chip(item, 1))
	var reason := GameState.give_friend_error(id)
	var give := UiKit.primary("Dar petisco", func() -> void:
		var error := GameState.give_friend(id)
		if error != "":
			Events.toast_requested.emit(error))
	give.name = "GiveTreat"
	give.disabled = reason != ""
	box.add_child(give)
	if reason != "":
		box.add_child(UiKit.label(reason, &"SmallLabel"))
	box.add_child(UiKit.label("Um petisco a cada %d horas" % int(Database.friends.settings.window_hours), &"SmallLabel"))
	return box


static func panel(id: String = "") -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var ids: Array[String] = []
		if id != "":
			ids.append(id)
		else:
			ids = GameState.friends_present()
		for key: String in ids:
			_card(box, key)
		box.add_child(UiKit.label("Um petisco por amigo a cada %d horas" % int(Database.friends.settings.window_hours), &"SmallLabel")))


static func _card(box: VBoxContainer, id: String, album: bool = false) -> void:
	var def := GameState.friend_def(id)
	var hearts := GameState.friend_hearts(id)
	var maximum: int = Database.friends.settings.hearts.size()
	var known := int(GameState.friend_state.entry(id).gifts) > 0
	var card := UiKit.card(box, &"ReadyCardPanel" if hearts == maximum else &"CardPanel")
	var row := UiKit.hbox(12)
	var portrait := UiKit.icon(load(str(def.portrait)), 64)
	if album and not known:
		portrait.modulate = Palette.INK
	row.add_child(portrait)
	var text := UiKit.vbox(4)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(UiKit.label(str(def.name) if known or not album else "?", &"SectionLabel"))
	text.add_child(UiKit.label(str(def.breed) if known or not album else "Amigo da vizinhança", &"SmallLabel"))
	var heart_row := UiKit.hbox(4)
	for i in maximum:
		var heart := UiKit.icon(UiKit.ui_icon("heart"), 24)
		if i >= hearts:
			heart.modulate = Palette.SUNKEN
		heart_row.add_child(heart)
	text.add_child(heart_row)
	row.add_child(text)
	card.add_child(row)
	if album and not known:
		return
	if hearts == maximum:
		card.add_child(UiKit.label("Melhor amigo · Visita a casa", &"SmallLabel"))
	else:
		var threshold := int(Database.friends.settings.hearts[hearts])
		card.add_child(UiKit.label("%d/%d petiscos · próximo coração" % [int(GameState.friend_state.entry(id).gifts), threshold], &"SmallLabel"))
		card.add_child(ProgressionUi.reward_chips(def.heart_rewards[hearts]))
	if hearts >= 2 and def.has("walk_bonus"):
		card.add_child(UiKit.label("Pipoca vai junto · +1 achado", &"SmallLabel"))
	var item := str(def.likes)
	var food := UiKit.hbox(8)
	food.add_child(UiKit.icon(Database.item_icon(item), 48))
	food.add_child(UiKit.fill_label(Database.item_name(item), &"SmallLabel"))
	food.add_child(UiKit.short_label("%d/1" % GameState.inventory.count(item), &"SmallLabel"))
	card.add_child(food)
	var reason := GameState.give_friend_error(id)
	if not album or id in GameState.friends_present():
		var give := UiKit.button("Dar petisco", func() -> void:
			var error := GameState.give_friend(id)
			if error != "":
				Events.toast_requested.emit(error), &"SecondaryButton")
		give.disabled = reason != ""
		card.add_child(give)
	if reason != "":
		card.add_child(UiKit.label(reason, &"SmallLabel"))
		var actions := UiKit.hbox(8)
		if GameState.inventory.count(item) == 0:
			actions.add_child(UiKit.button("Ir", func() -> void: Places.go(Places.goal_target({"type": "have", "key": item}))))
		else:
			actions.add_child(UiKit.button("Ir à praça", func() -> void: Places.go({"world": "park", "place": "friends"})))
		actions.add_child(UiKit.button("?", func() -> void: Events.sheet_requested.emit(Database.item_name(item), TaskHelp.panel("item", item))))
		card.add_child(actions)


static func album() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 4)
		grid.add_theme_constant_override("v_separation", 4)
		var known_count := 0
		for id: String in Database.friends.friends:
			var def := GameState.friend_def(id)
			var known := int(GameState.friend_state.entry(id).gifts) > 0
			known_count += 1 if known else 0
			var tile := UiKit.grid_tile(load(str(def.portrait)), str(def.name) if known else "?", func() -> void:
				Events.sheet_requested.emit(str(def.name) if known else "Amigo da vizinhança", panel(id)), 100, 64)
			tile.name = "Friend_" + id
			tile.custom_minimum_size.y = 120
			if not known:
				tile.get_node("Visual/Picture").modulate = Palette.INK
				tile.modulate.a = 0.55
			grid.add_child(tile)
		box.add_child(UiKit.collection_progress(known_count, Database.friends.friends.size()))
		box.add_child(grid))
