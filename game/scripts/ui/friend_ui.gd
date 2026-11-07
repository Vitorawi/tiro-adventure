class_name FriendUi
extends RefCounted
## Amigos em madeira ilustrada: petiscos na bandeja do mapa (mesma pele das estações); cartões completos no álbum e na
## lista de Amigos.

static func open(id: String) -> void:
	if GameState.friend_unlocked(id):
		for room: Node in (Engine.get_main_loop() as SceneTree).get_nodes_in_group("room_views"):
			if room is RoomView and room.is_visible_in_tree() and room.open_friend_tray(id):
				return
		Events.sheet_requested.emit(str(GameState.friend_def(id).name), panel(id))


## Corações do amigo (cheios até `hearts`, os outros apagados), na escala de 24 px.
static func _hearts(id: String, size: int = 24) -> HBoxContainer:
	var hearts := GameState.friend_hearts(id)
	var row := UiKit.hbox(4)
	row.name = "Hearts"
	for i in Database.friends.settings.hearts.size():
		var heart := UiKit.icon(UiKit.ui_icon("heart"), size)
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if i >= hearts:
			heart.modulate = Color(1, 1, 1, 0.3)
		row.add_child(heart)
	return row


## "n/m petiscos · próximo coração" ou "Melhor amigo · Visita a casa".
static func _progress_text(id: String) -> String:
	var hearts := GameState.friend_hearts(id)
	if hearts >= Database.friends.settings.hearts.size():
		return "Melhor amigo · Visita a casa"
	return "%d/%d petiscos · próximo coração" % [int(GameState.friend_state.entry(id).gifts), int(Database.friends.settings.hearts[hearts])]


## Petisco direto no mundo, no mesmo modo de seleção das estações (bandeja de madeira).
static func tray(room: RoomView, id: String, anchor: Vector2) -> ActionTray:
	var def := GameState.friend_def(id)
	var item := str(def.likes)
	var header := SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var row := UiKit.hbox(10)
		var face := UiKit.icon(load(str(def.portrait)), 48)
		row.add_child(face)
		var text := UiKit.vbox(2)
		text.alignment = BoxContainer.ALIGNMENT_CENTER
		text.add_child(_hearts(id))
		var progress := StationWood.text(_progress_text(id), 14)
		progress.name = "FriendProgress"
		text.add_child(progress)
		row.add_child(text)
		box.add_child(row))
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
	var name_label := StationWood.text(Database.item_name(item), 17)
	box.add_child(name_label)
	var hint := StationWood.text("Um petisco a cada %d horas" % int(Database.friends.settings.window_hours), 13, Color(Palette.WOOD_INK, 0.8))
	box.add_child(hint)
	# O rodapé da bandeja leva o nó "Actions" (o único botão verde ou o motivo do bloqueio).
	var actions := UiKit.vbox(6)
	actions.name = "Actions"
	var give := ProjectUi.green("Dar petisco", func() -> void:
		var error := GameState.give_friend(id)
		if error != "":
			Events.toast_requested.emit(error))
	give.name = "GiveTreat"
	actions.add_child(ProjectUi.action_or_note(give, GameState.give_friend_error(id), TaskHelp.open.bind("item", item), Database.item_icon(item) if GameState.inventory.count(item) == 0 else null))
	box.add_child(actions)
	return box


static func panel(id: String = "") -> Control:
	return ProjectUi.wood_sheet(SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.add_theme_constant_override("separation", 10)
		var ids: Array[String] = []
		if id != "":
			ids.append(id)
		else:
			ids = GameState.friends_present()
		for key: String in ids:
			_card(box, key)
		var note := StepCardUi.wood("Um petisco por amigo a cada %d horas" % int(Database.friends.settings.window_hours), 14, Color(Palette.WOOD_INK, 0.8))
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(note)))


static func _card(box: VBoxContainer, id: String, album: bool = false) -> void:
	var def := GameState.friend_def(id)
	var hearts := GameState.friend_hearts(id)
	var maximum: int = Database.friends.settings.hearts.size()
	var known := int(GameState.friend_state.entry(id).gifts) > 0
	var inner := StepCardUi.inner_card(box, "FriendCard_" + id)
	var row := UiKit.hbox(12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var face := UiKit.icon(load(str(def.portrait)), 64)
	if album and not known:
		face.modulate = Palette.INK
	row.add_child(StepCardUi.portrait_frame(face, 76.0, "FriendFace"))
	var text := UiKit.vbox(4)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := StepCardUi.wood(str(def.name) if known or not album else "?", 20)
	title.name = "FriendName"
	text.add_child(title)
	text.add_child(StepCardUi.wood(str(def.breed) if known or not album else "Amigo da vizinhança", 14, Color(Palette.WOOD_INK, 0.8)))
	text.add_child(_hearts(id))
	row.add_child(text)
	inner.add_child(row)
	if album and not known:
		return
	var progress := StepCardUi.wood(_progress_text(id), 14, Color(Palette.WOOD_INK, 0.9))
	progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(progress)
	if hearts < maximum:
		inner.add_child(ProjectUi.reward_chips(def.heart_rewards[hearts]))
	if hearts >= 2 and def.has("walk_bonus"):
		inner.add_child(StepCardUi.wood("Pipoca vai junto · +1 achado", 14, Color(Palette.WOOD_INK, 0.9)))
	var item := str(def.likes)
	var have := GameState.inventory.count(item)
	inner.add_child(StepCardUi.wood_chip(Database.item_icon(item), "%s %d/1" % [Database.item_name(item), have], "have" if have >= 1 else "missing", TaskHelp.open.bind("item", item)))
	var reason := GameState.give_friend_error(id)
	if reason == "" and (not album or id in GameState.friends_present()):
		var give := ProjectUi.green("Dar petisco", func() -> void:
			var error := GameState.give_friend(id)
			if error != "":
				Events.toast_requested.emit(error))
		give.name = "GiveTreat_" + id
		inner.add_child(give)
	if reason != "":
		var help := func() -> void: Events.sheet_requested.emit(Database.item_name(item), TaskHelp.panel("item", item))
		inner.add_child(StepCardUi.lock_note(reason, help, Database.item_icon(item) if have == 0 else null))
		if have == 0:
			inner.add_child(WelcomeSheet._button("Ir", false, 120.0, "GoGetTreat", func() -> void: Places.go(Places.goal_target({"type": "have", "key": item}))))
		else:
			inner.add_child(WelcomeSheet._button("Ir à praça", false, 160.0, "GoPark", func() -> void: Places.go({"world": "park", "place": "friends"})))


static func album() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.add_theme_constant_override("separation", 10)
		var grid := HFlowContainer.new()
		grid.alignment = FlowContainer.ALIGNMENT_CENTER
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		var known_count := 0
		for id: String in Database.friends.friends:
			var def := GameState.friend_def(id)
			var known := int(GameState.friend_state.entry(id).gifts) > 0
			known_count += 1 if known else 0
			var tile := CodexUi.tile({
				"name": "Friend_" + id, "icon": load(str(def.portrait)), "caption": str(def.name) if known else "?",
				"dim": not known,
				"on_tap": func() -> void: Events.sheet_requested.emit(str(def.name) if known else "Amigo da vizinhança", panel(id)),
			}, 92.0, 112.0)
			if not known:
				var picture := tile.get_node_or_null("Picture") as CanvasItem
				if picture != null:
					picture.modulate = Color(0, 0, 0, 0.45)
			grid.add_child(tile)
		var progress := StepCardUi.wood_chip(null, "%d/%d" % [known_count, Database.friends.friends.size()])
		progress.name = "CollectionProgress"
		progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(progress)
		box.add_child(grid))
