class_name TrickUi
extends RefCounted
## Listas no Sheet existente (madeira ilustrada); aprendizado só no Treino, execução na tela Tiro.

static func open() -> void:
	if GameState.farm_week_active():
		open_lessons()
	else:
		Events.sheet_requested.emit("Truques", panel())


static func open_lessons() -> void:
	Events.sheet_requested.emit("Caderno de truques", lesson_panel())


static func lesson_target() -> Dictionary:
	return {"world": "farm", "place": "week_training"}


static func level_name(id: String) -> String:
	var level := GameState.trick_level(id)
	return str(Database.growth.trick_levels.names[level - 1]) if level > 0 else "Aprendendo"


static func level_progress(id: String) -> String:
	var thresholds: Array = Database.growth.trick_levels.thresholds
	var level := GameState.trick_level(id)
	var need := int(thresholds[mini(level, thresholds.size() - 1)])
	var have := mini(GameState.progress.stat("trick:" + id), need)
	return "%d/%d acertos" % [have, need]


static func lesson_panel() -> Control:
	return ProjectUi.wood_sheet(SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.name = "TrickNotebook"
		box.add_theme_constant_override("separation", 8)
		var ribbon := GameState.week_routine_badge("skilled")
		if ribbon != "":
			box.add_child(StepCardUi.wood_chip(UiKit.ctl_icon("check"), ribbon, "have"))
		if GameState.week_day() >= int(Database.progression.trick_settings.show.day) and not GameState.has_upgrade("dairy"):
			var target := {"world": "farm", "place": "week_show"}
			box.add_child(WelcomeSheet._button("Show de truques", false, 220.0, "OpenTrickShow", Places.go.bind(target)))
		var cookies := 0
		for item: String in GameState.trick_lesson_cookies():
			cookies += GameState.inventory.count(item)
		box.add_child(StepCardUi.wood_chip(Database.item_icon("apple_biscuit"), "%d na mochila · 1 por aula" % cookies))
		for id: String in Database.progression.tricks:
			if GameState.trick_is_lesson(id):
				_lesson_card(box, id)
		if not GameState.farm_week_active():
			box.add_child(WelcomeSheet._button("Treinar com a Nina", false, 220.0, "TrainWithNina", Places.go.bind({"world": "park", "place": "training"})))))


static func _lesson_card(box: VBoxContainer, id: String) -> void:
	var def: Dictionary = Database.progression.tricks[id]
	var inner := StepCardUi.inner_card(box, "LessonCard_" + id, Vector4i(10, 8, 10, 8))
	var top := UiKit.hbox(8)
	inner.add_child(top)
	var icon := UiKit.icon(UiKit.ui_icon(str(def.icon)), 36)
	var opened := GameState.week_day() >= int(def.requirements.week_day)
	if not opened:
		icon.modulate = Color("ae9b7e")
	top.add_child(icon)
	var text := UiKit.vbox(1)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(text)
	text.add_child(StepCardUi.wood(str(def.name), 19))
	var thresholds: Array = Database.growth.trick_levels.thresholds
	var need := float(thresholds[mini(GameState.trick_level(id), thresholds.size() - 1)])
	if opened:
		text.add_child(StepCardUi.wood(level_name(id) + " · " + level_progress(id), 15))
		inner.add_child(StepCardUi.bar(float(GameState.progress.stat("trick:" + id)) / need, 10, "LessonProgress_" + id))
	var reason := GameState.trick_lesson_error(id)
	var action := WelcomeSheet._button("Treinar", false, 90.0, "LessonTrain_" + id, start_lesson.bind(id))
	inner.add_child(ProjectUi.action_or_note(action, reason))


static func start_lesson(id: String) -> void:
	var root := GameState.get_tree().root
	var host := root.get_node_or_null("Main")
	TrickLesson.open(host if host != null else root, id)


static func open_show_panel() -> void:
	Events.sheet_requested.emit("Show de truques", show_panel())


static func show_panel() -> Control:
	return ProjectUi.wood_sheet(SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.name = "TrickShowPanel"
		ProgressionUi.npc_header(box, "bloblo", "Eu e a Laís queremos ver seus truques!", false, true)
		var rules: Dictionary = Database.progression.trick_settings.show
		var reason := GameState.trick_show_error(int(rules.min_length))
		if reason != "":
			var note := StepCardUi.wood(reason, 17)
			note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			box.add_child(note)
			return
		var row := UiKit.hbox(6)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_child(row)
		for length in range(int(rules.min_length), int(rules.max_length) + 1):
			row.add_child(WelcomeSheet._button("%d truques" % length, false, 84.0, "ShowLength_%d" % length, _start_show.bind(length)))))


static func _start_show(length: int) -> void:
	var root := GameState.get_tree().root
	var host := root.get_node_or_null("Main")
	TrickLesson.open_show(host if host != null else root, length)


static func panel(training: bool = false) -> Control:
	return ProjectUi.wood_sheet(SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.add_theme_constant_override("separation", 8)
		var next_found := false
		for id: String in Database.progression.tricks:
			if GameState.trick_is_lesson(id):
				continue
			var def: Dictionary = Database.progression.tricks[id]
			var learned := bool(GameState.progress.tricks.get(id, false))
			if not training and not learned:
				continue
			var reason := GameState.perform_trick_error(id) if learned else GameState.learn_trick_error(id)
			var action: Control = null
			if learned:
				action = WelcomeSheet._button("Mostrar", false, 92.0, "Show_" + id, func() -> void:
					var error := GameState.perform_trick(id)
					if error != "":
						Events.toast_requested.emit(error)
					else:
						Events.sheet_close_requested.emit()
						Events.screen_requested.emit(&"pet"))
			elif not next_found:
				action = WelcomeSheet._button("Treinar", false, 92.0, "Train_" + id, start.bind(id))
			if not learned:
				next_found = true
			if reason != "" and action != null:
				action.free()
				action = null
			var chips: Array[Control] = []
			if learned:
				chips.append(StepCardUi.wood_chip(null, "Aprendeu", "have"))
			var line := ProjectUi.row("Trick_" + id, UiKit.ui_icon(str(def.icon)), str(def.name), chips, action, Callable(), not learned and reason != "")
			box.add_child(line)
			if reason != "":
				var hint := StepCardUi.lock_note(reason, TaskHelp.open.bind("stat", "trick:" + id))
				hint.name = "Locked_Trick_" + id
				hint.set_meta("reason", reason)
				box.add_child(hint)
		if not training:
			box.add_child(WelcomeSheet._button("Caderno de truques", false, 220.0, "TrickBook", open_lessons))))


static func start(id: String) -> void:
	var error := GameState.learn_trick_error(id)
	if error != "":
		Events.toast_requested.emit(error)
		return
	var scene: Control = load("res://scenes/ui/trick_training/trick_training.tscn").instantiate()
	scene.set("trick_id", id)
	Events.sheet_requested.emit(str(Database.progression.tricks[id].name), scene)
