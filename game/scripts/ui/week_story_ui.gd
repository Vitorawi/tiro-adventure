class_name WeekStoryUi
extends RefCounted


static func open_farewell() -> void:
	var body := SheetBuilder.LiveBox.new(_farewell)
	body.name = "WeekFarewell"
	body.set_meta("tick_refresh", false)
	Events.sheet_requested.emit("Almoço de despedida", SheetBuilder._wood_sheet(body))


static func _farewell(box: VBoxContainer) -> void:
	var config: Dictionary = Database.week_story.farewell
	if GameState.week_farewell_complete():
		var photo := PhotoCard.make(str(config.photo), 145)
		photo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(photo)
		box.add_child(_line("A foto de grupo já está no Álbum. Agora veja o que falta para crescer."))
		box.add_child(StepCardUi.go_button("Para crescer", func() -> void:
			Places.go({"growth": true})))
		return
	box.add_child(_line("Prepare uma refeição para cada lugar à mesa."))
	var items: Array[String] = []
	for id: String in GameState.inventory.counts:
		if GameState.is_meal_item(id) and GameState.inventory.count(id) > 0:
			items.append(id)
	items.sort_custom(func(a: String, b: String) -> bool: return Database.item_name(a) < Database.item_name(b))
	for role: String in config.roles:
		var seat := StepCardUi.inner_card(box, "Farewell_" + role)
		var present := str(GameState.week.farewell.get(role, ""))
		seat.add_child(StepCardUi.wood(str(config.roles[role]), 20))
		if present != "":
			seat.add_child(_line("Servido · " + Database.item_name(present)))
			continue
		if items.is_empty():
			seat.add_child(_line("Falta preparar um prato."))
			continue
		var choice := OptionButton.new()
		choice.fit_to_longest_item = false
		choice.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		choice.custom_minimum_size.y = 44
		for id: String in items:
			choice.add_item("%s ×%d" % [Database.item_name(id), GameState.inventory.count(id)])
			choice.set_item_metadata(choice.item_count - 1, id)
		seat.add_child(choice)
		var serve := StepCardUi.go_button("Servir", func() -> void:
			var error := GameState.serve_week_farewell(role, str(choice.get_selected_metadata()))
			if error != "":
				Events.toast_requested.emit(error)
)
		serve.name = "Serve_" + role
		seat.add_child(serve)
	box.add_child(StepCardUi.go_button("Ir ao fogão", func() -> void:
		Places.go({"world": "house", "place": "stove"})))


static func lines_body(model: Dictionary, refresh: Callable) -> Control:
	var box := UiKit.vbox(8)
	box.name = "NotebookMissionLines"
	var current := str(model.get("mission_line", "grandma"))
	for line: String in Database.week_routine.lines:
		var title := str(Database.week_routine.lines[line].title)
		var select := WelcomeSheet._button(title, line == current, 210.0, "NotebookLine_" + line, func() -> void:
			model["mission_line"] = line
			model["scroll"] = 0
			refresh.call())
		select.custom_minimum_size.y = 42
		box.add_child(select)
	var steps := StepCardUi.inner_card(box, "NotebookLineSteps_" + current)
	for step: Dictionary in GameState.week_line_rows(current):
		_routine_row(steps, step, "Line")
	if not GameState.farm_week_active():
		for line: String in GameState.progress.lines():
			var id := GameState.progress.current_line_quest(line)
			if id == "":
				continue
			var quest: Dictionary = Database.quests[id]
			var card := StepCardUi.inner_card(box, "NotebookLine_" + line)
			card.add_child(StepCardUi.wood(str(Database.npcs[quest.npc].name), 17))
			card.add_child(_line(str(quest.name)))
			card.add_child(StepCardUi.action_row(id, "npc"))
	if "recipe_ingredient" in GameState.routine_ids("daily"):
		ProgressionUi.routine_card(box, "daily", "recipe_ingredient")
	if not GameState.routines_unlocked("weekly"):
		box.add_child(_line(str(Database.week_routine.text.closed)))
	return box


static func today(box: VBoxContainer) -> void:
	var daily := GameState.week_daily_rows()
	if daily.is_empty():
		return
	var copy: Dictionary = Database.week_routine.text
	var card := StepCardUi.inner_card(box, "WeekToday")
	var done := daily.filter(func(row: Dictionary) -> bool: return row.done).size()
	card.add_child(StepCardUi.wood(str(copy.list), 20))

	if done == daily.size():
		var seal := StepCardUi.wood_chip(UiKit.ctl_icon("check"), str(copy.seal), "have")
		seal.name = "WeekDailySeal"
		card.add_child(seal)
	else:
		for row: Dictionary in daily:
			_routine_row(card, row, "Daily")


static func next_step(box: VBoxContainer) -> void:
	var step := GameState.week_routine_next_step()
	if step.is_empty():
		return
	var copy: Dictionary = Database.week_routine.text
	var card := StepCardUi.inner_card(box, "WeekLineStep")
	card.add_child(StepCardUi.wood(str(copy.step), 20))
	card.add_child(_line(str(step.line)))
	_routine_row(card, step, "Next")
	card.add_child(MissionUi.link(str(copy.open_lines), func() -> void: PetNotebook.open("missions")))


static func _routine_row(card: VBoxContainer, data: Dictionary, group: String) -> void:
	var copy: Dictionary = Database.week_routine.text
	var row := UiKit.hbox(8)
	row.name = "Week%s_%s" % [group, data.id]
	var words := UiKit.vbox(2)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(words)
	if data.has("name"):
		words.add_child(_line(str(data.name), 17))
	words.add_child(_line(str(data.label)))
	var locked := bool(data.get("locked", false))
	var status := "%d/%d" % [int(data.value), int(data.target)]
	if group == "Daily" and data.done:
		var check := UiKit.icon(UiKit.ctl_icon("check"), 20)
		check.modulate = Palette.GO_INK
		check.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(check)
		card.add_child(row)
		return
	if data.done:
		status = "✓ " + str(data.get("badge", copy.complete))
	elif locked:
		status = str(data.lock_text)
	words.add_child(_line(status))
	if not data.done and not locked:
		var go := StepCardUi.go_button(str(copy.go), Places.go.bind(data.go))
		go.custom_minimum_size = Vector2(72, 54)
		go.size_flags_horizontal = Control.SIZE_SHRINK_END
		go.name = "WeekGo_%s_%s" % [group, data.id]
		go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(go)
	card.add_child(row)


static func _line(value: String, px: int = 16) -> Label:
	var label := StepCardUi.wood(value, px)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
