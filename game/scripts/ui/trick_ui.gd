class_name TrickUi
extends RefCounted
## Listas no Sheet existente; aprendizado só no Treino, execução na tela Tiro.

static func open() -> void:
	Events.sheet_requested.emit("Truques", panel())


static func panel(training: bool = false) -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var next_found := false
		for id: String in Database.progression.tricks:
			var def: Dictionary = Database.progression.tricks[id]
			var learned := bool(GameState.progress.tricks.get(id, false))
			if not training and not learned:
				continue
			var card := UiKit.card(box)
			var row := UiKit.hbox(8)
			row.add_child(UiKit.icon(UiKit.ui_icon(str(def.icon)), 48))
			row.add_child(UiKit.fill_label(str(def.name) + (" ✓" if learned else ""), &"SectionLabel"))
			card.add_child(row)
			var reason := GameState.perform_trick_error(id) if learned else GameState.learn_trick_error(id)
			if learned:
				var perform := UiKit.button("Mostrar", func() -> void:
					var error := GameState.perform_trick(id)
					if error != "":
						Events.toast_requested.emit(error)
					else:
						Events.sheet_close_requested.emit()
						Events.screen_requested.emit(&"pet"), &"SecondaryButton")
				perform.disabled = reason != ""
				card.add_child(perform)
			else:
				var train := UiKit.button("Treinar", start.bind(id), &"SecondaryButton")
				train.disabled = reason != "" or next_found
				next_found = true
				card.add_child(train)
			if reason != "":
				card.add_child(UiKit.label(reason, &"SmallLabel"))
		if not training:
			box.add_child(UiKit.button("Treinar com a Nina", Places.go.bind({"world": "park", "place": "training"}))))


static func start(id: String) -> void:
	var error := GameState.learn_trick_error(id)
	if error != "":
		Events.toast_requested.emit(error)
		return
	var scene: Control = load("res://scenes/ui/trick_training/trick_training.tscn").instantiate()
	scene.set("trick_id", id)
	Events.sheet_requested.emit(str(Database.progression.tricks[id].name), scene)
