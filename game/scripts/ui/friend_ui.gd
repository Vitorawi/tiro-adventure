class_name FriendUi
extends RefCounted
## Cartões dentro do Sheet existente: mantém a rolagem e a fila de cartões modais.

static func open(id: String) -> void:
	if GameState.friend_unlocked(id):
		Events.sheet_requested.emit(str(GameState.friend_def(id).name), panel(id))


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
		portrait.modulate = Color(0, 0, 0)
	row.add_child(portrait)
	var text := UiKit.vbox(4)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(UiKit.label(str(def.name) if known or not album else "?", &"SectionLabel"))
	text.add_child(UiKit.label(str(def.breed) if known or not album else "Amigo da vizinhança", &"SmallLabel"))
	var heart_row := UiKit.hbox(4)
	for i in maximum:
		var heart := UiKit.icon(UiKit.ui_icon("bond_heart"), 24)
		if i >= hearts:
			heart.modulate = Color(0.4, 0.4, 0.4, 0.35)
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
		for id: String in Database.friends.friends:
			_card(box, id, true))
