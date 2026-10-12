extends PanelContainer
## História principal, ajuda para evoluir e missões opcionais.

var _completed_text: String = ""

func _ready() -> void:
	Events.quest_completed.connect(_on_quest_completed)
	%Holder.add_child(SheetBuilder.LiveBox.new(_build))


func _build(box: VBoxContainer) -> void:
	if _completed_text != "":
		UiKit.card(box, &"ReadyCardPanel").add_child(UiKit.label(_completed_text, &"SmallLabel", UiKit.GOOD))
	_story_card(box)
	_evolve_card(box)
	_ready_now(box)
	_side_quests(box)
	_extras(box)


func _story_card(box: VBoxContainer) -> void:
	var chapter := GameState.current_chapter()
	var index := GameState.progress.chapter_index()
	var card := UiKit.card(box, &"ReadyCardPanel")
	card.name = "StoryCard"
	if index > Database.progression.chapters.size():
		card.add_child(UiKit.label("HISTÓRIA CONCLUÍDA", &"SmallLabel", UiKit.GOOD))
		card.add_child(UiKit.label(chapter.name, &"SectionLabel"))
		card.add_child(UiKit.label(chapter.description, &"SmallLabel"))
	else:
		var ids := GameState.progress.main_quests(index)
		var current := GameState.progress.current_main_quest()
		var done := ids.find(current)
		card.add_child(UiKit.label("HISTÓRIA · Capítulo %d de %d" % [index, Database.progression.chapters.size()], &"SmallLabel"))
		card.add_child(UiKit.label(chapter.name, &"SectionLabel"))
		card.add_child(UiKit.bar(100.0 * done / ids.size(), UiKit.GOOD, 8))
		card.add_child(UiKit.label("%d/%d passos concluídos" % [done, ids.size()], &"SmallLabel"))
		if done > 0:
			card.add_child(UiKit.label("✓ " + str(Database.quests[ids[done - 1]].name), &"SmallLabel", UiKit.GOOD))
		var quest: Dictionary = Database.quests[current]
		card.add_child(UiKit.label("▶ " + str(quest.name), &"SectionLabel"))
		for goal: Dictionary in quest.goals:
			card.add_child(UiKit.label("%s · %d/%d" % [goal.label, mini(GameState.goal_value(goal), int(goal.get("target", 1))), int(goal.get("target", 1))], &"SmallLabel"))
		var target := Places.quest_target(current)
		card.add_child(UiKit.label(target.get("hint", ""), &"SmallLabel"))
		ProgressionUi.quest_action(card, current)
		var future := ids.size() - done - 1
		if future > 0:
			card.add_child(UiKit.label("○ +%d passo(s) · depois: %s" % [future, Database.quests[ids[done + 1]].name], &"SmallLabel", Color("#72756e")))
		card.add_child(UiKit.label("Ao terminar: " + ProgressionUi.rewards_text(chapter.get("rewards", {})), &"SmallLabel"))
		card.add_child(UiKit.label(chapter.get("unlocks_text", ""), &"SmallLabel", UiKit.GOOD))
	card.add_child(UiKit.button("Ver a história completa", func() -> void:
		Events.sheet_requested.emit("História", ProgressionUi.story_panel())))


func _evolve_card(box: VBoxContainer) -> void:
	var current := GameState.progress.current_main_quest()
	if current == "":
		return
	var needs := ProgressionUi.quest_skills(current)
	for skill: String in needs:
		var level := int(needs[skill])
		var info := GameState.skill_info(skill)
		if int(info.level) >= level:
			continue
		var data: Dictionary = Database.progression.skills[skill]
		var card := UiKit.card(box)
		card.add_child(UiKit.label("PARA EVOLUIR", &"SmallLabel"))
		card.add_child(UiKit.label("A história pede %s %d" % [data.name, level], &"SectionLabel"))
		card.add_child(UiKit.label("Você tem nível %d · %d/%d XP" % [info.level, info.xp, info.needed], &"SmallLabel"))
		card.add_child(UiKit.bar(100.0 * float(info.xp) / float(info.needed), Color(data.color), 8))
		card.add_child(UiKit.label(data.get("how_to", ""), &"SmallLabel"))
		card.add_child(UiKit.button("Ir", Places.go.bind(Places.goal_target({"type": "skill", "key": skill})), &"PrimaryButton"))


func _side_quests(box: VBoxContainer) -> void:
	var ids := ProgressionUi.side_quests()
	box.add_child(UiKit.label("Missões secundárias", &"SectionLabel"))
	box.add_child(UiKit.label("1 recomendada" if ids.size() == 1 else "%d recomendadas" % mini(3, ids.size()), &"SmallLabel"))
	for i in mini(3, ids.size()):
		ProgressionUi.side_card(box, ids[i])
	if ids.is_empty():
		box.add_child(UiKit.label("Todas as secundárias concluídas!" if GameState.progress.chapter_index() > Database.progression.chapters.size() else "Novas missões aparecem ao avançar na história.", &"SmallLabel"))
	box.add_child(UiKit.button("Ver todas (%d)" % ids.size(), func() -> void:
		Events.sheet_requested.emit("Missões secundárias", ProgressionUi.side_panel())))


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


func _extras(box: VBoxContainer) -> void:
	box.add_child(UiKit.label("Sua evolução", &"SectionLabel"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	grid.add_theme_constant_override("h_separation", 8)
	box.add_child(grid)
	for entry: Array in [["Atributos", "xp", ProgressionUi.skills_panel], ["Coleção", "need_happiness", ProgressionUi.collection_panel], ["História", "tab_journey", ProgressionUi.story_panel]]:
		var button := UiKit.button(entry[0], func() -> void:
			Events.sheet_requested.emit(entry[0], (entry[2] as Callable).call()), &"", UiKit.ui_icon(entry[1]))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(button)


func _go_button(text: String, world_id: String, place: String, variation: StringName = &"") -> Button:
	return UiKit.button(text, func() -> void:
		Events.sheet_close_requested.emit()
		Events.world_requested.emit(world_id, place), variation)


func _on_quest_completed(id: String) -> void:
	if Database.quests[id].get("kind", "side") != "main":
		return
	var next := GameState.progress.current_main_quest()
	_completed_text = "Missão concluída! Próximo: " + str(Database.quests[next].name) if next != "" else "Missão concluída! História completa!"
