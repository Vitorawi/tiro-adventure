class_name TrickUi
extends RefCounted
## Listas no Sheet existente (madeira ilustrada); aprendizado só no Treino, execução na tela Tiro.

static func open() -> void:
	Events.sheet_requested.emit("Truques", panel())


static func panel(training: bool = false) -> Control:
	return ProjectUi.wood_sheet(SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.add_theme_constant_override("separation", 8)
		var next_found := false
		for id: String in Database.progression.tricks:
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
			box.add_child(WelcomeSheet._button("Treinar com a Nina", false, 220.0, "TrainWithNina", Places.go.bind({"world": "park", "place": "training"})))))


static func start(id: String) -> void:
	var error := GameState.learn_trick_error(id)
	if error != "":
		Events.toast_requested.emit(error)
		return
	var scene: Control = load("res://scenes/ui/trick_training/trick_training.tscn").instantiate()
	scene.set("trick_id", id)
	Events.sheet_requested.emit(str(Database.progression.tricks[id].name), scene)
