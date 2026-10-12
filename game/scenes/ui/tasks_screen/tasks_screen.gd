extends PanelContainer
## Aba Tarefas: "o que eu faço agora?". Cada item tem um botão "Ir" que leva ao
## lugar certo (Events.world_requested), para ninguém precisar adivinhar onde
## fica cada coisa. Ordem: próximo passo da história, prontos agora, missões,
## atributos e coleção.


func _ready() -> void:
	%Holder.add_child(SheetBuilder.LiveBox.new(_build))


func _build(box: VBoxContainer) -> void:
	_next_step(box)
	_ready_now(box)
	_missions(box)
	_extras(box)


## Capítulo atual + o que falta para a próxima construção.
func _next_step(box: VBoxContainer) -> void:
	var chapter := GameState.current_chapter()
	var card := UiKit.card(box, &"ReadyCardPanel")
	card.add_child(UiKit.label("Próximo passo", &"SmallLabel"))
	card.add_child(UiKit.label(chapter.get("name", ""), &"SectionLabel"))
	card.add_child(UiKit.label(chapter.get("description", ""), &"SmallLabel"))
	var target: String = chapter.get("target", "")
	if target == "":
		return
	var upgrade: Dictionary = Database.progression.upgrades.get(target, {})
	var reason := GameState.upgrade_error(target)
	card.add_child(UiKit.label("Objetivo: %s" % upgrade.get("name", target)))
	card.add_child(UiKit.label("Você já pode comprar!" if reason == "" else "Falta: " + reason, &"SmallLabel", UiKit.GOOD if reason == "" else null))
	var world_id: String = upgrade.get("world", "house")
	card.add_child(_go_button("Ir comprar (%s)" % Database.worlds.get(world_id, {}).get("name", "") if reason == "" else "Ver o que precisa", world_id, "buy:" + target, &"PrimaryButton"))


## Coisas prontas para recolher, em qualquer mundo.
func _ready_now(box: VBoxContainer) -> void:
	var lines := 0
	for world_id: String in Database.worlds:
		for alert in Places.world_alerts(world_id):
			if lines == 0:
				box.add_child(UiKit.label("Prontos agora", &"SectionLabel"))
			lines += 1
			var row := UiKit.hbox(8)
			row.add_child(UiKit.icon(UiKit.ui_icon(Database.worlds[world_id].get("icon", "")), 32))
			var text := UiKit.label(alert, &"SmallLabel")
			text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(text)
			var go := _go_button("Ir", world_id, "", &"PrimaryButton")
			go.custom_minimum_size = Vector2(64, 44)
			row.add_child(go)
			UiKit.card(box, &"ReadyCardPanel").add_child(row)
	var activity: Dictionary = GameState.progress.activity
	if not activity.is_empty() and GameState.activity_remaining() > 0:
		var route: String = Database.progression.activities.get(activity.id, {}).get("name", "")
		box.add_child(UiKit.label("Passeando: %s · volta em %s" % [route, TimeText.short(GameState.activity_remaining())], &"SmallLabel"))


## Missões em andamento, agrupadas por personagem, com atalho até ele.
func _missions(box: VBoxContainer) -> void:
	box.add_child(UiKit.label("Missões", &"SectionLabel"))
	var any := false
	for npc_id: String in Database.npcs:
		for id in Places.npc_active_quests(npc_id):
			any = true
			var quest: Dictionary = Database.quests[id]
			var ready := GameState.quest_error(id) == ""
			var card := UiKit.card(box, &"ReadyCardPanel" if ready else &"CardPanel")
			var row := UiKit.hbox(8)
			row.add_child(UiKit.icon(ProgressionUi.npc_portrait(npc_id), 32))
			var info := UiKit.vbox(2)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.add_child(UiKit.label(quest.name))
			var done := 0
			for goal: Dictionary in quest.goals:
				if GameState.goal_value(goal) >= int(goal.get("target", 1)):
					done += 1
			var status := "Pronta! Fale com %s" % Database.npcs[npc_id].name if ready else "%s · %d de %d objetivos" % [Database.npcs[npc_id].name, done, quest.goals.size()]
			info.add_child(UiKit.label(status, &"SmallLabel", UiKit.GOOD if ready else null))
			row.add_child(info)
			var go := _go_button("Ir", Database.npc_world(npc_id), "npc:" + npc_id, &"PrimaryButton" if ready else &"")
			go.custom_minimum_size = Vector2(64, 44)
			go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(go)
			card.add_child(row)
	if not any:
		box.add_child(UiKit.label("Nenhuma missão agora. Continue o próximo passo!", &"SmallLabel"))


func _extras(box: VBoxContainer) -> void:
	box.add_child(UiKit.label("Sua evolução", &"SectionLabel"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	grid.add_theme_constant_override("h_separation", 8)
	box.add_child(grid)
	for entry: Array in [["Atributos", "xp", ProgressionUi.skills_panel], ["Coleção", "need_happiness", ProgressionUi.collection_panel]]:
		var button := UiKit.button(entry[0], func() -> void:
			Events.sheet_requested.emit(entry[0], (entry[2] as Callable).call()), &"", UiKit.ui_icon(entry[1]))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(button)


func _go_button(text: String, world_id: String, place: String, variation: StringName = &"") -> Button:
	return UiKit.button(text, func() -> void:
		Events.sheet_close_requested.emit()
		Events.world_requested.emit(world_id, place), variation)
