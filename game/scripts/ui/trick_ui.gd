class_name TrickUi
extends RefCounted
## Listas no Sheet existente; aprendizado só no Treino, execução na tela Tiro.

static func open() -> void:
	Events.sheet_requested.emit("Truques", panel())


static func panel(training: bool = false) -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var next_found := false
		var cards: VBoxContainer = null
		for id: String in Database.progression.tricks:
			var def: Dictionary = Database.progression.tricks[id]
			var learned := bool(GameState.progress.tricks.get(id, false))
			if not training and not learned:
				continue
			var reason := GameState.perform_trick_error(id) if learned else GameState.learn_trick_error(id)
			var action: Button
			if learned:
				action = UiKit.small_go("Mostrar", func() -> void:
					var error := GameState.perform_trick(id)
					if error != "":
						Events.toast_requested.emit(error)
					else:
						Events.sheet_close_requested.emit()
						Events.screen_requested.emit(&"pet"))
				action.disabled = reason != ""
			else:
				action = UiKit.soft("Treinar", start.bind(id), null, true)
				action.disabled = reason != "" or next_found
				next_found = true
			var chips: Array[Control] = []
			if learned:
				chips.append(UiKit.chip(null, "Aprendeu", null, "have"))
			if cards == null:
				cards = UiKit.list_card(box)
			var row := UiKit.list_row(UiKit.ui_icon(str(def.icon)), str(def.name), chips, action, Callable(), learned and reason == "")
			row.name = "Trick_" + id
			cards.add_child(row)
			if reason != "":
				cards.add_child(UiKit.lock_hint(reason))  # o motivo quebra de linha; chip comprido alargava o painel
		if not training:
			box.add_child(UiKit.soft("Treinar com a Nina", Places.go.bind({"world": "park", "place": "training"}))))


static func start(id: String) -> void:
	var error := GameState.learn_trick_error(id)
	if error != "":
		Events.toast_requested.emit(error)
		return
	var scene: Control = load("res://scenes/ui/trick_training/trick_training.tscn").instantiate()
	scene.set("trick_id", id)
	Events.sheet_requested.emit(str(Database.progression.tricks[id].name), scene)
